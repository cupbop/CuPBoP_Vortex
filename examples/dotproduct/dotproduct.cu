// dotproduct_cuda.cu
// nvcc -O3 -std=c++17 dotproduct_cuda.cu -o dotproduct_cuda
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <cassert>
#include <vector>
#include <chrono>

#ifndef BLOCK_SIZE
#define BLOCK_SIZE 256
#endif

#define FLOAT_ULP 6

#define CUDA_CHECK(expr)                                                          \
  do {                                                                            \
    cudaError_t _err = (expr);                                                    \
    if (_err != cudaSuccess) {                                                    \
      fprintf(stderr, "CUDA Error: %s (%d) at %s:%d\n",                           \
              cudaGetErrorString(_err), (int)_err, __FILE__, __LINE__);           \
      exit(EXIT_FAILURE);                                                         \
    }                                                                             \
  } while (0)

static bool compare_equal(float a, float b) {
  union fi_t { float f; int32_t i; };
  fi_t fa, fb;
  fa.f = a;
  fb.f = b;
  auto d = std::abs(fa.i - fb.i);
  return d <= FLOAT_ULP;
}

__global__ void dotProductKernel(const float* __restrict__ a,
                                 const float* __restrict__ b,
                                 float* __restrict__ partialSums,
                                 int n)
{
  // OpenCL의 gid, global_size와 동일한 개념을 grid-stride로 구현
  int gid = blockIdx.x * blockDim.x + threadIdx.x;
  int global_size = gridDim.x * blockDim.x;

  float sum = 0.0f;
  for (int i = gid; i < n; i += global_size) {
    sum += a[i] * b[i];
  }

  // 블록 내부 리덕션 (OpenCL의 __local + barrier와 동일)
  __shared__ float sdata[BLOCK_SIZE];
  sdata[threadIdx.x] = sum;
  __syncthreads();

  // 트리 감산
  for (int s = blockDim.x / 2; s > 0; s >>= 1) {
    if (threadIdx.x < s) {
      sdata[threadIdx.x] += sdata[threadIdx.x + s];
    }
    __syncthreads();
  }

  // 블록 리더가 partialSums에 기록
  if (threadIdx.x == 0) {
    partialSums[blockIdx.x] = sdata[0];
  }
}

static void show_usage() {
  printf("Usage: [-n size] [-h]\n");
}

int main(int argc, char** argv) {
  // ---- parse args ----
  int n = 1 << 20; // default
  int opti = 1;
  while (opti < argc) {
    if (!strcmp(argv[opti], "-n") && opti + 1 < argc) {
      n = std::atoi(argv[++opti]);
      ++opti;
    } else if (!strcmp(argv[opti], "-h")) {
      show_usage();
      return 0;
    } else {
      show_usage();
      return 1;
    }
  }

  // ---- device info ----
  int dev = 0;
  CUDA_CHECK(cudaSetDevice(dev));
  cudaDeviceProp prop{};
  CUDA_CHECK(cudaGetDeviceProperties(&prop, dev));
  printf("Using device: %s\n", prop.name);
  printf("Vector size n=%d\n", n);

  // ---- host buffers ----
  std::vector<float> h_a(n), h_b(n);

  // 입력 데이터 생성 (OpenCL 버전과 동일한 랜덤 생성)
  std::srand(0xC0FFEE);
  for (int i = 0; i < n; ++i) {
    h_a[i] = static_cast<float>(std::rand()) / RAND_MAX;
    h_b[i] = static_cast<float>(std::rand()) / RAND_MAX;
  }

  // ---- device buffers ----
  float *d_a = nullptr, *d_b = nullptr, *d_partial = nullptr;

  // 그리드/블록 구성 (OpenCL의 글로벌/로컬 크기 대응)
  int block = BLOCK_SIZE;
  // OpenCL처럼 "글로벌 사이즈 = 블록*그리드"로 잡되,
  // 너무 많은 블록을 만들지 않도록 디바이스 멀티프로세서 수를 고려
  //int maxBlocks = prop.multiProcessorCount * 32; // 적당한 상한
  int grid = (n + block - 1) / block;
  //if (grid > maxBlocks) grid = maxBlocks;
  if (grid < 1) grid = 1;

  size_t bytes = sizeof(float) * n;
  size_t partial_bytes = sizeof(float) * grid;

  CUDA_CHECK(cudaMalloc(&d_a, bytes));
  CUDA_CHECK(cudaMalloc(&d_b, bytes));
  CUDA_CHECK(cudaMalloc(&d_partial, partial_bytes));

  // ---- upload ----
  CUDA_CHECK(cudaMemcpy(d_a, h_a.data(), bytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_b, h_b.data(), bytes, cudaMemcpyHostToDevice));

  // ---- run kernel ----
  printf("Launch kernel: grid=%d block=%d\n", grid, block);
  auto t0 = std::chrono::high_resolution_clock::now();
  dotProductKernel<<<grid, block>>>(d_a, d_b, d_partial, n);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double ms = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  printf("Elapsed time: %g ms\n", ms);

  // ---- read back partial sums ----
  std::vector<float> h_partial(grid);
  CUDA_CHECK(cudaMemcpy(h_partial.data(), d_partial, partial_bytes, cudaMemcpyDeviceToHost));

  // ---- final reduce on host (OpenCL와 동일한 2-pass) ----
  float gpu_result = 0.0f;
  for (int i = 0; i < grid; ++i) gpu_result += h_partial[i];

  // ---- CPU reference ----
  double cpu_result = 0.0;
  for (int i = 0; i < n; ++i) cpu_result += static_cast<double>(h_a[i]) * static_cast<double>(h_b[i]);

  printf("GPU result: %.9g\n", gpu_result);
  printf("CPU result: %.9g\n", cpu_result);

  // ---- check ----
  bool ok = compare_equal(gpu_result, static_cast<float>(cpu_result));
  if (!ok) {
    // 허용 오차 조금 넉넉히 보기
    float diff = std::abs(gpu_result - static_cast<float>(cpu_result));
    float rel  = diff / (std::abs(static_cast<float>(cpu_result)) + 1e-7f);
    ok = (rel < 1e-5f);
  }
  if (ok) {
    printf("PASSED!\n");
  } else {
    printf("FAILED!\n");
  }

  // ---- cleanup ----
  CUDA_CHECK(cudaFree(d_a));
  CUDA_CHECK(cudaFree(d_b));
  CUDA_CHECK(cudaFree(d_partial));
  return ok ? 0 : 1;
}