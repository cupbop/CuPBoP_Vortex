// parallel_sum.cu
// nvcc -O2 -std=c++17 parallel_sum.cu -o parallel_sum
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cassert>
#include <cmath>
#include <cstring>
#include <chrono>
#include <vector>
#include <algorithm>
#include <numeric>
#include <unistd.h>   // getopt

#include <cuda_runtime.h>

#define FLOAT_ULP 16

#define CUDA_CHECK(expr)                                                         \
  do {                                                                           \
    cudaError_t _err = (expr);                                                   \
    if (_err != cudaSuccess) {                                                   \
      fprintf(stderr, "CUDA Error: %s -> %d (%s)\n", #expr, (int)_err,           \
              cudaGetErrorString(_err));                                         \
      std::exit(-1);                                                             \
    }                                                                            \
  } while (0)

static inline bool compare_equal(float a, float b) {
  union fi_t { float f; int32_t i; };
  fi_t fa{.f=a}, fb{.f=b};
  auto d = std::abs(fa.i - fb.i);
  return (d/fa.i) <= 1e-3;
}

static float computeParallelSumCPU(const float* A, int N) {
  float sum = 0.f;
  for (int i = 0; i < N; ++i) sum += A[i];
  return sum;
}

// ---------------- CUDA kernel: 1:1 대응 ----------------
__global__ void parallelSumKernel(const float* __restrict__ input,
                                  float* __restrict__ output,
                                  int N) {
  extern __shared__ float temp[];  // dynamic shared memory (OpenCL __local)
  int local_id   = threadIdx.x;               // get_local_id(0)
  int local_size = blockDim.x;                // get_local_size(0)
  int global_id  = blockIdx.x * blockDim.x + threadIdx.x; // get_global_id(0)

  // Load into shared (local) memory
  if (global_id < N) {
    temp[local_id] = input[global_id];
  } else {
    temp[local_id] = 0.0f;
  }
  __syncthreads(); // barrier(CLK_LOCAL_MEM_FENCE)

  // Reduction in shared memory
  for (unsigned int stride = local_size >> 1; stride > 0; stride >>= 1) {
    if (local_id < (int)stride) {
      temp[local_id] += temp[local_id + stride];
    }
    __syncthreads();
  }

  // Write per-block result
  if (local_id == 0) {
    // get_group_id(0) == blockIdx.x
    output[blockIdx.x] = temp[0];
  }
}

// ---------------- Host main ----------------
int main(int argc, char** argv) {
  // Default params match the OpenCL host
  size_t size = 16;       // total inputs (N)
  size_t local_size = 8;  // block size

  // Parse args: -n size, -l local_size, -h
  int c;
  while ((c = getopt(argc, argv, "n:l:h")) != -1) {
    switch (c) {
      case 'n': size = std::max(1, atoi(optarg)); break;
      case 'l': local_size = std::max(1, atoi(optarg)); break;
      case 'h':
      default:
        printf("Usage: [-n size] [-l local_size] [-h]\n");
        return 0;
    }
  }

  printf("input size=%zu, local size=%zu\n", size, local_size);
  if ((size / local_size) * local_size != size) {
    printf("Error: input size must be a multiple of %zu\n", local_size);
    return -1;
  }

  const uint32_t num_inputs  = static_cast<uint32_t>(size);
  const uint32_t num_outputs = static_cast<uint32_t>(size / local_size);

  // Show device
  cudaDeviceProp prop{};
  int device = 0;
  CUDA_CHECK(cudaGetDevice(&device));
  CUDA_CHECK(cudaGetDeviceProperties(&prop, device));
  printf("Using device: %s\n", prop.name);

  // Host buffers
  std::vector<float> h_a(num_inputs);
  std::vector<float> h_c(num_outputs);

  // Random inputs (OpenCL 코드와 동치의 임의값 생성)
  for (uint32_t i = 0; i < num_inputs; ++i) {
    h_a[i] = static_cast<float>(rand()) / RAND_MAX;
  }

  // Device buffers
  float *d_a = nullptr, *d_c = nullptr;
  size_t i_nbytes = num_inputs * sizeof(float);
  size_t o_nbytes = num_outputs * sizeof(float);
  CUDA_CHECK(cudaMalloc((void**)&d_a, i_nbytes));
  CUDA_CHECK(cudaMalloc((void**)&d_c, o_nbytes));

  // Upload
  CUDA_CHECK(cudaMemcpy(d_a, h_a.data(), i_nbytes, cudaMemcpyHostToDevice));

  // Grid/block & dynamic shared mem size
  dim3 block(static_cast<unsigned int>(local_size), 1, 1);
  dim3 grid (static_cast<unsigned int>(num_outputs), 1, 1); // size/local_size
  size_t smemSize = local_size * sizeof(float);             // __local float* temp

  // Launch + timing (NDRange: global=size, local=local_size 동일하게 매핑)
  auto t0 = std::chrono::high_resolution_clock::now();
  parallelSumKernel<<<grid, block, smemSize>>>(d_a, d_c, (int)num_inputs);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double elapsed_ms =
      std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  printf("Elapsed time: %lg ms\n", elapsed_ms);

  // Download
  CUDA_CHECK(cudaMemcpy(h_c.data(), d_c, o_nbytes, cudaMemcpyDeviceToHost));

  // Verify (OpenCL 호스트와 동일한 검증 방식)
  int errors = 0;
  float result = computeParallelSumCPU(h_c.data(), num_outputs);
  float gold   = computeParallelSumCPU(h_a.data(), num_inputs);

  if (!compare_equal(result, gold)) {
    printf("*** error: expected=%f, actual=%f", gold, result);
    for (uint32_t i = 0; i < num_outputs; ++i) {
      printf(", output[%u]=%f", i, h_c[i]);
    }
    printf("\n");
    errors = 1;
  }

  if (errors != 0) printf("FAILED! - %d errors\n", errors);
  else             printf("PASSED!\n");

  // Cleanup
  CUDA_CHECK(cudaFree(d_a));
  CUDA_CHECK(cudaFree(d_c));
  return errors;
}