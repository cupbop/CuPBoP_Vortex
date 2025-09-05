// sgemm3.cu
// nvcc -O2 -std=c++17 sgemm3.cu -o sgemm3
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cassert>
#include <cstring>
#include <cmath>
#include <vector>
#include <chrono>
#include <unistd.h>     // getopt
#include <cuda_runtime.h>

// ===== [common.h] 통합 =====
#ifndef TYPE
#define TYPE float
#endif
// ===========================
 
#define FLOAT_ULP 6

#define CUDA_CHECK(expr)                                                         \
  do {                                                                           \
    cudaError_t _err = (expr);                                                   \
    if (_err != cudaSuccess) {                                                   \
      std::fprintf(stderr, "CUDA Error: %s -> %d (%s)\n", #expr, (int)_err,      \
                   cudaGetErrorString(_err));                                    \
      std::exit(-1);                                                             \
    }                                                                            \
  } while (0)

// ---- OpenCL 호스트 코드와 동등한 Comparator/검증 유틸 ----
template <typename T> struct Comparator {};

template <> struct Comparator<int> {
  static const char* type_str() { return "integer"; }
  static int generate() { return std::rand(); }
  static bool compare(int a, int b, int index, int errors) {
    if (a != b) {
      if (errors < 100)
        std::printf("*** error: [%d] expected=%d, actual=%d\n", index, a, b);
      return false;
    }
    return true;
  }
};

template <> struct Comparator<float> {
  static const char* type_str() { return "float"; }
  static float generate() { return static_cast<float>(std::rand()) / RAND_MAX; }
  static bool compare(float a, float b, int index, int errors) {
    union fi_t { float f; int32_t i; };
    fi_t fa, fb; fa.f = a; fb.f = b;
    auto d = std::abs(fa.i - fb.i);
    if (d > FLOAT_ULP) {
      if (errors < 100)
        std::printf("*** error: [%d] expected=%f, actual=%f\n", index, a, b);
      return false;
    }
    return true;
  }
};

// ---- CPU ref (OpenCL 호스트의 sgemm_cpu와 동일) ----
// 주의: column-major 인덱싱 (C[n*M+m] = Σ A[k*M+m]*B[n*K+k])
static void sgemm_cpu(TYPE *C, const TYPE* A, const TYPE *B, int M, int N, int K) {
  for (int m = 0; m < M; ++m) {
    for (int n = 0; n < N; ++n) {
      TYPE acc = 0;
      for (int k = 0; k < K; ++k) {
        acc += A[k * M + m] * B[n * K + k];
      }
      C[n * M + m] = acc;
    }
  }
}

// ===== CUDA Kernel (OpenCL sgemm3와 1:1 논리) =====
// OpenCL 커널의 __local TYPE *localA, *localB 를 CUDA에선
// dynamic shared memory로 합쳐서 할당 -> [localA | localB]
__global__ void sgemm3_kernel(const TYPE* __restrict__ A,
                              const TYPE* __restrict__ B,
                              TYPE* __restrict__ C,
                              unsigned int N)
{
  // 스레드/블록 인덱스 매핑 (OpenCL과 동일 의미)
  int globalCol = blockIdx.x * blockDim.x + threadIdx.x; // get_global_id(0)
  int globalRow = blockIdx.y * blockDim.y + threadIdx.y; // get_global_id(1)
  int localCol  = threadIdx.x;                           // get_local_id(0)
  int localRow  = threadIdx.y;                           // get_local_id(1)
  int localSize = blockDim.x;                            // get_local_size(0) == tile_size

  extern __shared__ TYPE smem[];
  TYPE* localA = smem;                                   // size: localSize*localSize
  TYPE* localB = smem + localSize * localSize;           // size: localSize*localSize

  TYPE sum = 0;

  // for (int k = 0; k < N; k += localSize)
  for (int k = 0; k < (int)N; k += localSize) {
    // localA[localRow * localSize + localCol] = A[globalRow * N + (k + localCol)];
    // localB[localRow * localSize + localCol] = B[(k + localRow) * N + globalCol];
    localA[localRow * localSize + localCol] = A[(k + localCol) * N + globalRow];
    localB[localRow * localSize + localCol] = B[globalCol * N + (k + localRow)];

    __syncthreads(); // barrier(CLK_LOCAL_MEM_FENCE)

    // for (int j = 0; j < localSize; j++)
    //   sum += localA[localRow*localSize + j] * localB[j*localSize + localCol];
    for (int j = 0; j < localSize; ++j) {
      sum += localA[localRow * localSize + j] * localB[j * localSize + localCol];
    }

    __syncthreads(); // barrier(CLK_LOCAL_MEM_FENCE)
  }

  // C[globalRow * N + globalCol] = sum;   (row-major 스타일, OpenCL 커널과 동일)
  C[globalCol * N + globalRow] = sum;
}

// ===================== Host (OpenCL 호스트 로직 매핑) =====================
int main(int argc, char** argv) {
  std::srand(0xC0FFEE);

  uint32_t size = 16;      // N
  uint32_t tile_size = 4;  // local_size

  // 옵션 파싱: -n size, -t tile_size
  int opt;
  while ((opt = ::getopt(argc, argv, "n:t:h")) != -1) {
    switch (opt) {
      case 'n': size = std::max(1, atoi(optarg)); break;
      case 't': tile_size = std::max(1, atoi(optarg)); break;
      case 'h':
      default:
        std::printf("Usage: [-n size] [-t tile_size] [-h]\n");
        return 0;
    }
  }

  uint32_t size_sq = size * size;

  std::printf("Matrix size=%ux%u, tile size=%ux%u\n", size, size, tile_size, tile_size);
  if ((size / tile_size) * tile_size != size) {
    std::printf("Error: matrix size must be a multiple of %u\n", tile_size);
    return -1;
  }

  // 디바이스 정보
  int dev = 0;
  CUDA_CHECK(cudaGetDevice(&dev));
  cudaDeviceProp prop{};
  CUDA_CHECK(cudaGetDeviceProperties(&prop, dev));
  std::printf("Using device: %s\n", prop.name);

  // 호스트 버퍼
  std::vector<TYPE> h_a(size_sq), h_b(size_sq), h_c(size_sq);

  for (uint32_t i = 0; i < size_sq; ++i) {
    h_a[i] = Comparator<TYPE>::generate();
    h_b[i] = Comparator<TYPE>::generate();
  }

  // 디바이스 버퍼
  TYPE *d_a = nullptr, *d_b = nullptr, *d_c = nullptr;
  size_t nbytes = size_sq * sizeof(TYPE);
  CUDA_CHECK(cudaMalloc((void**)&d_a, nbytes));
  CUDA_CHECK(cudaMalloc((void**)&d_b, nbytes));
  CUDA_CHECK(cudaMalloc((void**)&d_c, nbytes));

  // 업로드
  std::printf("Upload source buffers\n");
  CUDA_CHECK(cudaMemcpy(d_a, h_a.data(), nbytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_b, h_b.data(), nbytes, cudaMemcpyHostToDevice));

  // 런치 파라미터 (OpenCL: global={size,size}, local={tile_size,tile_size})
  dim3 block(tile_size, tile_size, 1);
  dim3 grid (size / tile_size, size / tile_size, 1);
  std::printf("global_size=%u, %u\n", size, size);
  std::printf("local_size=%u, %u\n", tile_size, tile_size);

  // Dynamic shared memory: localA + localB
  size_t smem_bytes = 2ull * tile_size * tile_size * sizeof(TYPE);

  // 실행 & 타이밍
  auto t0 = std::chrono::high_resolution_clock::now();
  sgemm3_kernel<<<grid, block, smem_bytes>>>(d_a, d_b, d_c, size);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  std::printf("Elapsed time: %lg ms\n", elapsed_ms);

  // 다운로드
  std::printf("Download destination buffer\n");
  CUDA_CHECK(cudaMemcpy(h_c.data(), d_c, nbytes, cudaMemcpyDeviceToHost));

  // 검증 (OpenCL 호스트와 동일 sgemm_cpu 사용 — column-major ref)
  std::printf("Verify result\n");
  std::vector<TYPE> h_ref(size_sq);
  sgemm_cpu(h_ref.data(), h_a.data(), h_b.data(), size, size, size);
  int errors = 0;
  for (uint32_t i = 0; i < size_sq; ++i) {
    if (!Comparator<TYPE>::compare(h_c[i], h_ref[i], i, errors)) {
      ++errors;
    }
  }
  if (errors != 0) {
    std::printf("FAILED! - %d errors\n", errors);
  } else {
    std::printf("PASSED!\n");
  }

  // 정리
  CUDA_CHECK(cudaFree(d_a));
  CUDA_CHECK(cudaFree(d_b));
  CUDA_CHECK(cudaFree(d_c));
  return errors;
}