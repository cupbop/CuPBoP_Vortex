// sgemm2.cu
// nvcc -O2 -std=c++17 sgemm2.cu -o sgemm2
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cassert>
#include <cstring>
#include <cmath>
#include <vector>
#include <chrono>
#include <unistd.h>   // getopt

#include <cuda_runtime.h>

// ---- [common.h] 통합 ----
#define TILE_SIZE 16
#ifndef TYPE
#define TYPE float
#endif
// -------------------------

#define FLOAT_ULP 6

#define CUDA_CHECK(expr)                                                         \
  do {                                                                           \
    cudaError_t _err = (expr);                                                   \
    if (_err != cudaSuccess) {                                                   \
      fprintf(stderr, "CUDA Error: %s -> %d (%s)\n", #expr, (int)_err,           \
              cudaGetErrorString(_err));                                         \
      std::exit(-1);                                                             \
    }                                                                            \
  } while (0)

// OpenCL 호스트 코드와 동일 로직의 비교/생성 유틸
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
    fi_t fa, fb;
    fa.f = a; fb.f = b;
    auto d = std::abs(fa.i - fb.i);
    if (d > FLOAT_ULP) {
      if (errors < 100)
        std::printf("*** error: [%d] expected=%f, actual=%f\n", index, a, b);
      return false;
    }
    return true;
  }
};

// CPU 참조(SGEMM) — 제공된 OpenCL 호스트 코드의 인덱싱을 그대로 사용
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

// ---------------- CUDA Kernel: OpenCL sgemm2와 1:1 논리 ----------------
__global__ void sgemm2_kernel(const TYPE* __restrict__ A,
                              const TYPE* __restrict__ B,
                              TYPE* __restrict__ C,
                              unsigned int N)
{
  // OpenCL 매핑:
  // globalCol = get_global_id(0)  == blockIdx.x * blockDim.x + threadIdx.x
  // globalRow = get_global_id(1)  == blockIdx.y * blockDim.y + threadIdx.y
  // localCol  = get_local_id(0)   == threadIdx.x
  // localRow  = get_local_id(1)   == threadIdx.y
  int globalCol = blockIdx.x * blockDim.x + threadIdx.x;
  int globalRow = blockIdx.y * blockDim.y + threadIdx.y;
  int localCol  = threadIdx.x;
  int localRow  = threadIdx.y;

  // __local TYPE localA[TILE_SIZE][TILE_SIZE];
  // __local TYPE localB[TILE_SIZE][TILE_SIZE];
  __shared__ TYPE localA[TILE_SIZE][TILE_SIZE];
  __shared__ TYPE localB[TILE_SIZE][TILE_SIZE];

  TYPE sum = 0;

  // for (int k = 0; k < N; k += TILE_SIZE)
  for (int k = 0; k < (int)N; k += TILE_SIZE) {
    // localA[localRow][localCol] = A[globalRow * N + (k + localCol)];
    // localB[localRow][localCol] = B[(k + localRow) * N + globalCol];
    // localA[localRow][localCol] = A[globalRow * N + (k + localCol)];
    // localB[localRow][localCol] = B[(k + localRow) * N + globalCol];
    // A 타일: 행 m = globalRow, 열 k = k0 + localCol  → A[(k0+localCol)*M + globalRow]
    localA[localRow][localCol] = A[(k + localCol) * N + globalRow];

    // B 타일: 행 k = k0 + localRow, 열 n = globalCol → B[globalCol*K + (k0+localRow)]
    localB[localRow][localCol] = B[globalCol * N + (k + localRow)];

    __syncthreads(); // barrier(CLK_LOCAL_MEM_FENCE)

    // for (int j = 0; j < TILE_SIZE; j++) sum += localA[localRow][j] * localB[j][localCol];
    #pragma unroll
    for (int j = 0; j < TILE_SIZE; ++j) {
      sum += localA[localRow][j] * localB[j][localCol];
    }

    __syncthreads(); // barrier(CLK_LOCAL_MEM_FENCE) — Deadlock case 방지 코드 위치 동일
  }

  // C[globalRow * N + globalCol] = sum;
  //임시
  // C[globalRow * N + globalCol] = sum;
  C[globalCol * N + globalRow] = sum;
}

// ---------------- Host main (OpenCL 호스트 로직 1:1 매핑) ----------------
int main(int argc, char** argv) {
  std::srand(0xC0FFEE);

  uint32_t size = 16; // N
  // 옵션 파싱: -n size
  int opt;
  while ((opt = ::getopt(argc, argv, "n:h")) != -1) {
    switch (opt) {
      case 'n': size = std::max(1, atoi(optarg)); break;
      case 'h':
      default:
        std::printf("Usage: [-n size] [-h]\n");
        return 0;
    }
  }

  // TILE_SIZE 배수 체크 (OpenCL 호스트와 동일)
  std::printf("Matrix size=%ux%u, tile size=%dx%d\n",
              size, size, TILE_SIZE, TILE_SIZE);
  if ((size / TILE_SIZE) * TILE_SIZE != size) {
    std::printf("Error: matrix size must be a multiple of %d\n", TILE_SIZE);
    return -1;
  }

  const uint32_t N = size;
  const uint32_t size_sq = N * N;
  const size_t nbytes = size_sq * sizeof(TYPE);

  // 디바이스 정보 출력
  int dev = 0;
  CUDA_CHECK(cudaGetDevice(&dev));
  cudaDeviceProp prop{};
  CUDA_CHECK(cudaGetDeviceProperties(&prop, dev));
  std::printf("Using device: %s\n", prop.name);

  // 호스트 버퍼
  std::vector<TYPE> h_a(size_sq), h_b(size_sq), h_c(size_sq), h_ref(size_sq);

  // 입력 생성 (OpenCL Comparator.generate() 동등)
  for (uint32_t i = 0; i < size_sq; ++i) {
    h_a[i] = Comparator<TYPE>::generate();
    h_b[i] = Comparator<TYPE>::generate();
  }

  // 디바이스 메모리
  TYPE *d_a = nullptr, *d_b = nullptr, *d_c = nullptr;
  CUDA_CHECK(cudaMalloc((void**)&d_a, nbytes));
  CUDA_CHECK(cudaMalloc((void**)&d_b, nbytes));
  CUDA_CHECK(cudaMalloc((void**)&d_c, nbytes));

  // 업로드
  std::printf("Upload source buffers\n");
  CUDA_CHECK(cudaMemcpy(d_a, h_a.data(), nbytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_b, h_b.data(), nbytes, cudaMemcpyHostToDevice));

  // 실행 파라미터 (OpenCL: global={N,N}, local={TILE_SIZE,TILE_SIZE})
  dim3 block(TILE_SIZE, TILE_SIZE);
  dim3 grid (N / TILE_SIZE, N / TILE_SIZE);
  std::printf("global_work_size=%ux%u, local_work_size=%dx%d\n",
              N, N, TILE_SIZE, TILE_SIZE);

  // 커널 실행 & 타이밍
  auto t0 = std::chrono::high_resolution_clock::now();
  sgemm2_kernel<<<grid, block>>>(d_a, d_b, d_c, N);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double elapsed_ms =
      std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  std::printf("Elapsed time: %lg ms\n", elapsed_ms);

  // 다운로드
  std::printf("Download destination buffer\n");
  CUDA_CHECK(cudaMemcpy(h_c.data(), d_c, nbytes, cudaMemcpyDeviceToHost));

  // 검증 (OpenCL 호스트와 동일한 CPU sgemm)
  std::printf("Verify result\n");
  sgemm_cpu(h_ref.data(), h_a.data(), h_b.data(), N, N, N);
  int errors = 0;
  for (uint32_t i = 0; i < size_sq; ++i) {
    if (!Comparator<TYPE>::compare(h_c[i], h_ref[i], i, errors)) {
      ++errors;
    }
  }
  if (errors != 0) std::printf("FAILED! - %d errors\n", errors);
  else             std::printf("PASSED!\n");

  // 정리
  CUDA_CHECK(cudaFree(d_a));
  CUDA_CHECK(cudaFree(d_b));
  CUDA_CHECK(cudaFree(d_c));
  return errors;
}