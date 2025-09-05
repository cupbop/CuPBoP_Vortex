// saxpy_cuda.cu
// CUDA version of the provided OpenCL SAXPY sample (1:1 behavior)
// Build: nvcc -O3 -std=c++17 -o saxpy_cuda saxpy_cuda.cu
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <chrono>
#include <vector>
#include <iostream>

#ifndef BLOCK_SIZE
// Match the OpenCL sample's local_work_size = 1 for strict 1:1 behavior.
// You can -DBLOCK_SIZE=256 for faster runs if desired.
#define BLOCK_SIZE 512
#endif

#define CUDA_CHECK(expr)                                                     \
  do {                                                                       \
    cudaError_t _err = (expr);                                               \
    if (_err == cudaSuccess) break;                                          \
    fprintf(stderr, "CUDA Error: %s returned %d (%s) at %s:%d\n",            \
            #expr, int(_err), cudaGetErrorString(_err), __FILE__, __LINE__); \
    std::abort();                                                            \
  } while (0)

#define CUDA_CHECK_LAST()                                                    \
  do {                                                                       \
    cudaError_t _err = cudaGetLastError();                                   \
    if (_err == cudaSuccess) break;                                          \
    fprintf(stderr, "CUDA Kernel Error: %s at %s:%d\n",                      \
            cudaGetErrorString(_err), __FILE__, __LINE__);                   \
    std::abort();                                                            \
  } while (0)

static bool almost_equal(float a, float b, int ulp = 4) {
  union fi_t { int i; float f; };
  fi_t fa, fb;
  fa.f = a;
  fb.f = b;
  return std::abs(fa.i - fb.i) <= ulp;
}

__global__ void saxpy_kernel(const float* __restrict__ src,
                             float* __restrict__ dst,
                             float factor, int n)
{
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) {
    dst[i] += src[i] * factor;
  }
}

static void show_usage() {
  std::printf("Usage: [-n size] [-h: help]\n");
}

int main(int argc, char** argv) {
  int size = 1024;

  // parse args (same flags as OpenCL sample)
  int c;
  while ((c = getopt(argc, argv, "n:h")) != -1) {
    switch (c) {
      case 'n': size = std::atoi(optarg); break;
      case 'h': show_usage(); return 0;
      default: show_usage(); return -1;
    }
  }
  std::printf("Workload size=%d\n", size);

  // Print device info (rough equivalent to clGetDeviceInfo)
  int dev = 0;
  CUDA_CHECK(cudaGetDevice(&dev));
  cudaDeviceProp prop{};
  CUDA_CHECK(cudaGetDeviceProperties(&prop, dev));
  std::printf("Using device: %s (SM %d.%d)\n", prop.name, prop.major, prop.minor);

  size_t nbytes = sizeof(float) * size;

  // Host buffers (same init flow as OpenCL sample)
  std::vector<float> src_vec(size), dst_vec(size, 0.0f), ref_vec(size, 0.0f);
  float factor = (float(rand()) / float(RAND_MAX)) * 100.0f;
  for (int i = 0; i < size; ++i) {
    src_vec[i] = (float(rand()) / float(RAND_MAX)) * 100.0f;
  }

  // Reference computation: identical math as the OpenCL host-side loop with local_work_size=1
  for (int i = 0; i < size; ++i) {
    ref_vec[i] += src_vec[i] * factor;
  }

  // Device buffers (equivalent to clCreateBuffer + clEnqueueWriteBuffer)
  float *d_src = nullptr, *d_dst = nullptr;
  CUDA_CHECK(cudaMalloc(&d_src, nbytes));
  CUDA_CHECK(cudaMalloc(&d_dst, nbytes));
  CUDA_CHECK(cudaMemcpy(d_src, src_vec.data(), nbytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_dst, dst_vec.data(), nbytes, cudaMemcpyHostToDevice));

  // Launch (equivalent to clEnqueueNDRangeKernel with global=size and local=1 by default)
  dim3 block(BLOCK_SIZE);
  dim3 grid((size + block.x - 1) / block.x);

  std::printf("enqueue kernel\n");
  std::printf("global_work_size=%d\n", size);
  auto t0 = std::chrono::high_resolution_clock::now();
  saxpy_kernel<<<grid, block>>>(d_src, d_dst, factor, size);
  CUDA_CHECK_LAST();
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  std::printf("Elapsed time: %lg ms\n", elapsed);

  // Read back and verify (equivalent to clEnqueueReadBuffer + comparison)
  CUDA_CHECK(cudaMemcpy(dst_vec.data(), d_dst, nbytes, cudaMemcpyDeviceToHost));

  int errors = 0;
  for (int i = 0; i < size; ++i) {
    if (!almost_equal(dst_vec[i], ref_vec[i])) {
      if (errors < 100) {
        std::printf("*** error: [%d] expected=%f, actual=%f, factor=%f\n",
                    i, ref_vec[i], dst_vec[i], factor);
      }
      ++errors;
    }
  }
  if (errors == 0) std::puts("PASSED!");
  else std::printf("FAILED! - %d errors\n", errors);

  // Cleanup
  CUDA_CHECK(cudaFree(d_src));
  CUDA_CHECK(cudaFree(d_dst));
  return errors;
}
