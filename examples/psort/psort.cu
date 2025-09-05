// psort.cu
// nvcc -O2 psort.cu -o psort
#include <cstdio>
#include <cstdlib>
#include <cassert>
#include <cmath>
#include <chrono>
#include <cstring>
#include <unistd.h>

#include <cuda_runtime.h>

#define KERNEL0_NAME "psorti"
#define KERNEL1_NAME "psortf"

#define CUDA_CHECK(expr)                                                     \
  do {                                                                       \
    cudaError_t _err = (expr);                                               \
    if (_err != cudaSuccess) {                                               \
      fprintf(stderr, "CUDA Error: %s returned %d (%s)\n", #expr,            \
              (int)_err, cudaGetErrorString(_err));                          \
      cleanup();                                                             \
      exit(-1);                                                              \
    }                                                                        \
  } while (0)

static int size_ = 64;
static bool float_enable = false;

// Host buffers
static int*   h_ai = nullptr;   // used for int mode
static int*   h_ci = nullptr;
static float* h_af = nullptr;   // used for float mode
static float* h_cf = nullptr;

// Device buffers
static int*   d_ai = nullptr;
static int*   d_ci = nullptr;
static float* d_af = nullptr;
static float* d_cf = nullptr;

static void cleanup() {
  if (d_ai) CUDA_CHECK(cudaFree(d_ai));
  if (d_ci) CUDA_CHECK(cudaFree(d_ci));
  if (d_af) CUDA_CHECK(cudaFree(d_af));
  if (d_cf) CUDA_CHECK(cudaFree(d_cf));

  if (h_ai) free(h_ai);
  if (h_ci) free(h_ci);
  if (h_af) free(h_af);
  if (h_cf) free(h_cf);
}

static void show_usage() {
  printf("Usage: [-f] [-n size] [-h]\n");
}

static void parse_args(int argc, char** argv) {
  int c;
  while ((c = getopt(argc, argv, "fn:h")) != -1) {
    switch (c) {
      case 'f': float_enable = true; break;
      case 'n': size_ = atoi(optarg); break;
      case 'h': show_usage(); exit(0);
      default: show_usage(); exit(-1);
    }
  }
  printf("Workload size=%d, mode=%s\n", size_, float_enable ? "float" : "int");
}

// -------------------- CUDA kernels --------------------
__global__ void psorti_kernel(const int* __restrict__ in,
                              int* __restrict__ out,
                              int n) {
  int gid = blockIdx.x * blockDim.x + threadIdx.x;
  if (gid >= n) return;

  int ref = in[gid];
  int pos = 0;
  // same logic as OpenCL: pos += (cur < ref) || ((cur == ref) && (i < gid));
  for (int i = 0; i < n; ++i) {
    int cur = in[i];
    pos += (cur < ref) || ((cur == ref) && (i < gid));
  }
  out[pos] = ref;
}

__global__ void psortf_kernel(const float* __restrict__ in,
                              float* __restrict__ out,
                              int n) {
  int gid = blockIdx.x * blockDim.x + threadIdx.x;
  if (gid >= n) return;

  float ref = in[gid];
  int pos = 0;
  for (int i = 0; i < n; ++i) {
    float cur = in[i];
    pos += (cur < ref) || ((cur == ref) && (i < gid));
  }
  out[pos] = ref;
}

// -------------------- main --------------------
int main(int argc, char** argv) {
  parse_args(argc, argv);

  // Allocate & initialize host data (match OpenCL behavior)
  if (float_enable) {
    size_t nbytes = size_ * sizeof(float);
    h_af = (float*)malloc(nbytes);
    h_cf = (float*)malloc(nbytes);
    if (!h_af || !h_cf) { fprintf(stderr, "Host alloc failed\n"); cleanup(); return -1; }

    for (int i = 0; i < size_; ++i) {
      float value = sinf(i) * sinf(i);
      h_af[i] = value;
      printf("*** [%d]: %f\n", i, value);
    }
  } else {
    size_t nbytes = size_ * sizeof(int);
    h_ai = (int*)malloc(nbytes);
    h_ci = (int*)malloc(nbytes);
    if (!h_ai || !h_ci) { fprintf(stderr, "Host alloc failed\n"); cleanup(); return -1; }

    for (int i = 0; i < size_; ++i) {
      int value = (int)(size_ * sinf(i)); // identical to given OpenCL code
      h_ai[i] = value;
      printf("*** [%d]: %d\n", i, value);
    }
  }

  // Device alloc & upload
  if (float_enable) {
    size_t nbytes = size_ * sizeof(float);
    CUDA_CHECK(cudaMalloc((void**)&d_af, nbytes));
    CUDA_CHECK(cudaMalloc((void**)&d_cf, nbytes));
    CUDA_CHECK(cudaMemcpy(d_af, h_af, nbytes, cudaMemcpyHostToDevice));
  } else {
    size_t nbytes = size_ * sizeof(int);
    CUDA_CHECK(cudaMalloc((void**)&d_ai, nbytes));
    CUDA_CHECK(cudaMalloc((void**)&d_ci, nbytes));
    CUDA_CHECK(cudaMemcpy(d_ai, h_ai, nbytes, cudaMemcpyHostToDevice));
  }

  // Launch
  int block = 256;
  int grid  = (size_ + block - 1) / block;

  printf("Execute the kernel\n");
  printf("Workload size=%d\n", size_);

  auto time_start = std::chrono::high_resolution_clock::now();
  if (float_enable) {
    psortf_kernel<<<grid, block>>>(d_af, d_cf, size_);
  } else {
    psorti_kernel<<<grid, block>>>(d_ai, d_ci, size_);
  }
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto time_end = std::chrono::high_resolution_clock::now();
  double elapsed =
      std::chrono::duration_cast<std::chrono::milliseconds>(time_end - time_start).count();
  printf("Elapsed time: %lg ms\n", elapsed);

  // Download
  if (float_enable) {
    size_t nbytes = size_ * sizeof(float);
    CUDA_CHECK(cudaMemcpy(h_cf, d_cf, nbytes, cudaMemcpyDeviceToHost));
  } else {
    size_t nbytes = size_ * sizeof(int);
    CUDA_CHECK(cudaMemcpy(h_ci, d_ci, nbytes, cudaMemcpyDeviceToHost));
  }

  // Print results (like OpenCL host code)
  printf("Verify result\n");
  if (float_enable) {
    for (int i = 0; i < size_; ++i) {
      printf("*** [%d]: %f\n", i, h_cf[i]);
    }
  } else {
    for (int i = 0; i < size_; ++i) {
      printf("*** [%d]: %d\n", i, h_ci[i]);
    }
  }

  // Verify correctness (1:1 with original logic)
  int errors = 0;
  if (float_enable) {
    for (int i = 0; i < size_; ++i) {
      int pos = 0;
      float ref = h_af[i];
      for (int j = 0; j < size_; ++j) {
        float cur = h_af[j];
        pos += (cur < ref) || (cur == ref && j < i);
      }
      float value = h_cf[pos];
      if (value != ref) {
        if (errors < 100) {
          printf("*** error: [%d] expected=%f, actual=%f\n", pos, ref, value);
        }
        ++errors;
      }
    }
  } else {
    for (int i = 0; i < size_; ++i) {
      int pos = 0;
      int ref = h_ai[i];
      for (int j = 0; j < size_; ++j) {
        int cur = h_ai[j];
        pos += (cur < ref) || (cur == ref && j < i);
      }
      int value = h_ci[pos];
      if (value != ref) {
        if (errors < 100) {
          printf("*** error: [%d] expected=%d, actual=%d\n", pos, ref, value);
        }
        ++errors;
      }
    }
  }

  if (errors == 0) {
    printf("PASSED!\n");
  } else {
    printf("FAILED! - %d errors\n", errors);
  }

  cleanup();
  return errors;
}