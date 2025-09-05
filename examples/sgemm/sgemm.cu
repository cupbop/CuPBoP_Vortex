// sgemm_cuda.cu - CUDA counterpart of the provided OpenCL SGEMM sample (block size tunable)
// Build: nvcc -O3 -std=c++17 -o sgemm_cuda sgemm_cuda.cu
// Run  : ./sgemm_cuda -n 32 -b16x16   (or -bx 16 -by 16)

#include <cstdio>
#include <cstdlib>
#include <cassert>
#include <cstdint>
#include <cstring>
#include <unistd.h>
#include <chrono>
#include <vector>
#include <cmath>
#include <cuda_runtime.h>

#ifndef TYPE
#define TYPE float
#endif

#define FLOAT_ULP 6

// CUDA error check macro
#define CUDA_CHECK(_expr)                                                     \
  do {                                                                        \
    cudaError_t _err = (_expr);                                               \
    if (_err == cudaSuccess) break;                                           \
    fprintf(stderr, "CUDA Error: '%s' returned %d (%s)!\n",                   \
            #_expr, (int)_err, cudaGetErrorString(_err));                     \
    cleanup();                                                                \
    exit(-1);                                                                 \
  } while (0)

// ---------- Comparator ----------
template <typename T>
class Comparator {};

template <>
class Comparator<int> {
public:
  static const char* type_str() { return "integer"; }
  static int generate() { return rand(); }
  static bool compare(int a, int b, int index, int errors) {
    if (a != b) {
      if (errors < 100) {
        printf("*** error: [%d] expected=%d, actual=%d\n", index, a, b);
      }
      return false;
    }
    return true;
  }
};

template <>
class Comparator<float> {
public:
  static const char* type_str() { return "float"; }
  static float generate() { return static_cast<float>(rand()) / RAND_MAX; }
  static bool compare(float a, float b, int index, int errors) {
    union fi_t { float f; int32_t i; };
    fi_t fa, fb;
    fa.f = a; fb.f = b;
    auto d = std::abs(fa.i - fb.i);
    if (d > FLOAT_ULP) {
      if (errors < 100) {
        printf("*** error: [%d] expected=%f, actual=%f\n", index, a, b);
      }
      return false;
    }
    return true;
  }
};

// ---------- CPU reference (column-major, identical indexing) ----------
static void sgemm_cpu(TYPE* C, const TYPE* A, const TYPE* B, int M, int N, int K) {
  for (int m = 0; m < M; ++m) {
    for (int n = 0; n < N; ++n) {
      TYPE acc = 0;
      for (int k = 0; k < K; ++k) {
        acc += A[k * M + m] * B[n * K + k]; // A(r,k) * B(k,n) in column-major
      }
      C[n * M + m] = acc; // C(r,n) in column-major
    }
  }
}

// ---------- CUDA kernel ----------
template <typename T>
__global__ void sgemm_kernel(const T* __restrict__ A,
                             const T* __restrict__ B,
                             T* __restrict__ C,
                             int N)
{
  const int r = blockIdx.x * blockDim.x + threadIdx.x; // row id
  const int c = blockIdx.y * blockDim.y + threadIdx.y; // col id
  if (r >= N || c >= N) return;

  T acc = 0;
  for (int k = 0; k < N; ++k) {
    acc += A[k * N + r] * B[c * N + k];
  }
  C[c * N + r] = acc;
}

// ---------- Globals for cleanup ----------
static TYPE* d_A = nullptr;
static TYPE* d_B = nullptr;
static TYPE* d_C = nullptr;

static void cleanup() {
  if (d_A) { cudaFree(d_A); d_A = nullptr; }
  if (d_B) { cudaFree(d_B); d_B = nullptr; }
  if (d_C) { cudaFree(d_C); d_C = nullptr; }
}

// ---------- CLI ----------
static void show_usage() {
  printf("Usage: sgemm_cuda [-n size] [-b WxH | -bx W -by H] [-h]\n");
  printf("  -n   : matrix size (N x N), N >= 2 (default 32)\n");
  printf("  -b   : block size in 'WxH' format (e.g., -b32x8)\n");
  printf("  -bx  : blockDim.x (e.g., -bx 32)\n");
  printf("  -by  : blockDim.y (e.g., -by 8)\n");
  printf("  -h   : help\n");
}

static int sizeN = 32;
static int block_x = 16;
static int block_y = 16;

static void parse_b_arg(const char* s) {
  int w = 0, h = 0;
  if (std::sscanf(s, "%dx%d", &w, &h) == 2 && w > 0 && h > 0) {
    block_x = w; block_y = h;
  } else {
    fprintf(stderr, "Invalid -b format. Use -b32x8\n");
    std::exit(-1);
  }
}

static void parse_args(int argc, char** argv) {
  int c;
  while ((c = getopt(argc, argv, "n:b:h")) != -1) {
    switch (c) {
      case 'n': sizeN = std::atoi(optarg); break;
      case 'b': parse_b_arg(optarg); break;
      case 'h': show_usage(); std::exit(0);
      default : show_usage(); std::exit(-1);
    }
  }
  // Optional -bx / -by support
  for (int i = 1; i < argc; ++i) {
    if (std::strcmp(argv[i], "-bx") == 0 && i + 1 < argc) block_x = std::atoi(argv[i + 1]);
    if (std::strcmp(argv[i], "-by") == 0 && i + 1 < argc) block_y = std::atoi(argv[i + 1]);
  }
  if (sizeN < 2) {
    fprintf(stderr, "Error: invalid size!\n");
    std::exit(-1);
  }
  if (block_x <= 0 || block_y <= 0) {
    fprintf(stderr, "Error: invalid block size (%d x %d)\n", block_x, block_y);
    std::exit(-1);
  }
  printf("Workload size=%d, block=%dx%d\n", sizeN, block_x, block_y);
}

// ---------- main ----------
int main(int argc, char** argv) {
  parse_args(argc, argv);

  const int N = sizeN;
  const size_t size_sq = static_cast<size_t>(N) * N;
  const size_t nbytes = size_sq * sizeof(TYPE);

  // Host buffers
  std::vector<TYPE> h_A(size_sq);
  std::vector<TYPE> h_B(size_sq);
  std::vector<TYPE> h_C(size_sq, 0);
  std::vector<TYPE> h_ref(size_sq, 0);

  // Init inputs
  for (size_t i = 0; i < size_sq; ++i) {
    h_A[i] = Comparator<TYPE>::generate();
    h_B[i] = Comparator<TYPE>::generate();
  }

  // Device buffers
  CUDA_CHECK(cudaMalloc(&d_A, nbytes));
  CUDA_CHECK(cudaMalloc(&d_B, nbytes));
  CUDA_CHECK(cudaMalloc(&d_C, nbytes));

  // Upload
  CUDA_CHECK(cudaMemcpy(d_A, h_A.data(), nbytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_B, h_B.data(), nbytes, cudaMemcpyHostToDevice));

  // Launch config (tunable)
  const dim3 block(block_x, block_y, 1);
  const dim3 grid((N + block_x - 1) / block_x,
                  (N + block_y - 1) / block_y,
                  1);

  auto t0 = std::chrono::high_resolution_clock::now();
  sgemm_kernel<TYPE><<<grid, block>>>(d_A, d_B, d_C, N);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  printf("Elapsed time: %lg ms (grid=%dx%d, block=%dx%d)\n",
         elapsed_ms, grid.x, grid.y, block.x, block.y);

  // Download
  CUDA_CHECK(cudaMemcpy(h_C.data(), d_C, nbytes, cudaMemcpyDeviceToHost));

  // Reference & verify
  sgemm_cpu(h_ref.data(), h_A.data(), h_B.data(), N, N, N);
  int errors = 0;
  for (size_t i = 0; i < size_sq; ++i) {
    if (!Comparator<TYPE>::compare(h_C[i], h_ref[i], static_cast<int>(i), errors)) {
      ++errors;
    }
  }
  if (errors) {
    printf("FAILED! - %d errors\n", errors);
  } else {
    printf("PASSED!\n");
  }

  cleanup();
  return errors;
}