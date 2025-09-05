// nvcc -O2 -std=c++17 transpose.cu -o transpose
#include <cuda_runtime.h>

#include <cassert>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <unistd.h>
#include <vector>

#ifndef TYPE
#define TYPE float
#endif

#ifndef FLOAT_ULP
#define FLOAT_ULP 6
#endif

#define CUDA_CHECK(expr)                                                        \
  do {                                                                          \
    cudaError_t _err = (expr);                                                  \
    if (_err == cudaSuccess) break;                                             \
    fprintf(stderr, "CUDA Error: %s returned %d (%s) at %s:%d\n", #expr,        \
            (int)_err, cudaGetErrorString(_err), __FILE__, __LINE__);           \
    std::exit(EXIT_FAILURE);                                                    \
  } while (0)

static inline bool almost_equal(float a, float b, int ulp = FLOAT_ULP) {
  union { float f; int i; } fa{a}, fb{b};
  return std::abs(fa.i - fb.i) <= ulp;
}

// CPU reference for non-square transpose
// A is width x height, row-major: A[x + y*width]
// B is height x width, row-major: B[y + x*height] = A[x + y*width]
static void transpose_cpu(TYPE* __restrict__ B,
                          const TYPE* __restrict__ A,
                          int width, int height) {
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      B[y + x * height] = A[x + y * width];
    }
  }
}

// Kernel maps get_global_id(0/1) -> (x,y) with arbitrary block size.
// Guards handle non-square sizes.
__global__ void transpose_naive(TYPE* __restrict__ dst,
                                const TYPE* __restrict__ src,
                                int width, int height) {
  const int x = blockIdx.x * blockDim.x + threadIdx.x; // get_global_id(0)
  const int y = blockIdx.y * blockDim.y + threadIdx.y; // get_global_id(1)
  if (x < width && y < height) {
    dst[y + x * height] = src[x + y * width];
  }
}

// ------------------------------------------
// Host utils
// ------------------------------------------
static void show_usage(const char* prog) {
  printf("Usage: %s [-w width] [-H height] [-b block] [-h]\n"
         "  -w  matrix width  (default 1024)\n"
         "  -H  matrix height (default 1024)\n"
         "  -b  block size (square: b x b, default 1)\n"
         "  -h  show this help\n", prog);
}

static int gWidth  = 1024;
static int gHeight = 1024;
static int gBlock  = 1;

static void parse_args(int argc, char** argv) {
  int c;
  while ((c = getopt(argc, argv, "w:H:b:h")) != -1) {
    switch (c) {
      case 'w': gWidth  = std::atoi(optarg); break;
      case 'H': gHeight = std::atoi(optarg); break;
      case 'b': gBlock  = std::atoi(optarg); break;
      case 'h': show_usage(argv[0]); std::exit(0); break;
      default : show_usage(argv[0]); std::exit(EXIT_FAILURE);
    }
  }
  if (gWidth <= 0 || gHeight <= 0) {
    fprintf(stderr, "Error: width/height must be > 0\n");
    std::exit(EXIT_FAILURE);
  }
  if (gBlock <= 0) {
    fprintf(stderr, "Error: block must be > 0\n");
    std::exit(EXIT_FAILURE);
  }
  // Basic safety: threads per block must not exceed device limit (commonly 1024)
  if (1LL * gBlock * gBlock > 1024) {
    fprintf(stderr, "Error: block*bock=%d exceeds 1024 threads per block\n", gBlock * gBlock);
    std::exit(EXIT_FAILURE);
  }
  printf("Matrix: %d x %d, block=%d x %d\n", gWidth, gHeight, gBlock, gBlock);
}

int main(int argc, char** argv) {
  parse_args(argc, argv);
  const int width  = gWidth;
  const int height = gHeight;
  const size_t elems  = size_t(width) * size_t(height);
  const size_t nbytes = elems * sizeof(TYPE);

  // Host memory
  std::vector<TYPE> h_src(elems);
  std::vector<TYPE> h_dst(elems, TYPE(0));
  std::vector<TYPE> h_ref(elems, TYPE(0));

  // Init input
  std::srand(50);
  for (size_t i = 0; i < elems; ++i) {
    h_src[i] = static_cast<float>(std::rand()) / RAND_MAX;
  }

  // Device buffers
  TYPE *d_src = nullptr, *d_dst = nullptr;
  CUDA_CHECK(cudaMalloc(&d_src, nbytes));
  CUDA_CHECK(cudaMalloc(&d_dst, nbytes));

  // Upload
  CUDA_CHECK(cudaMemcpy(d_src, h_src.data(), nbytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemset(d_dst, 0, nbytes));

  // Kernel launch params from user
  dim3 block(gBlock, gBlock, 1);
  dim3 grid( (width  + block.x - 1) / block.x,
             (height + block.y - 1) / block.y,
             1 );

  printf("grid=(%d,%d,%d), block=(%d,%d,%d)\n",
         grid.x, grid.y, grid.z, block.x, block.y, block.z);

  // Launch & time
  auto t0 = std::chrono::high_resolution_clock::now();
  transpose_naive<<<grid, block>>>(d_dst, d_src, width, height);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double ms =
      std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  printf("Elapsed time: %g ms\n", ms);

  // Download
  CUDA_CHECK(cudaMemcpy(h_dst.data(), d_dst, nbytes, cudaMemcpyDeviceToHost));

  // Reference & verify
  transpose_cpu(h_ref.data(), h_src.data(), width, height);
  int errors = 0;
  for (size_t i = 0; i < elems; ++i) {
    if (!almost_equal(h_dst[i], h_ref[i])) {
      if (errors < 100) {
        printf("*** error: [%zu] expected=%f, actual=%f\n",
               i, (double)h_ref[i], (double)h_dst[i]);
      }
      ++errors;
    }
  }
  if (errors == 0) {
    printf("PASSED!\n");
  } else {
    printf("FAILED! - %d errors\n", errors);
  }

  CUDA_CHECK(cudaFree(d_src));
  CUDA_CHECK(cudaFree(d_dst));
  return errors;
}