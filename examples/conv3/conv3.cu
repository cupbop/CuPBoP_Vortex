// cuda_conv3_blockcfg.cu
// Build: nvcc -O3 -std=c++17 cuda_conv3_blockcfg.cu -o cuda_conv3
// Run examples:
//   ./cuda_conv3 -n 32                    # block=(1,1) (기본값)
//   ./cuda_conv3 -n 256 -bx 16 -by 16     # block=(16,16)
//   ./cuda_conv3 -n 1024 -bx 32 -by 8     # block=(32,8)

#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cassert>
#include <cstring>
#include <cmath>
#include <chrono>
#include <vector>
#include <unistd.h>   // getopt
#include <cuda_runtime.h>

#define FLOAT_ULP 6
#define KERNEL_NAME "conv3"

static void cleanup();

// CUDA error handling
#define CUDA_CHECK(_expr)                                                         \
  do {                                                                            \
    cudaError_t _err = (_expr);                                                   \
    if (_err == cudaSuccess) break;                                               \
    fprintf(stderr, "CUDA Error: '%s' returned %d (%s)!\n",                       \
            #_expr, (int)_err, cudaGetErrorString(_err));                         \
    cleanup();                                                                    \
    std::exit(-1);                                                                \
  } while (0)

static bool compare_equal(float a, float b) {
  union fi_t { float f; int32_t i; };
  fi_t fa, fb;
  fa.f = a; fb.f = b;
  return std::abs(fa.i - fb.i) <= FLOAT_ULP;
}

static void convolution_cpu(float *O, const float *I, const float *W, int32_t width, int32_t height) {
  int paddedWidth = width + 2;
  for (int32_t y = 0; y < height; ++y) {
    for (int32_t x = 0; x < width; ++x) {
      int paddedY = y + 1;
      int paddedX = x + 1;
      float sum = 0.0f;
      for (int32_t ky = -1; ky <= 1; ++ky) {
        for (int32_t kx = -1; kx <= 1; ++kx) {
          int32_t iy = paddedY + ky;
          int32_t ix = paddedX + kx;
          float value = I[iy * paddedWidth + ix];
          float weight = W[(ky + 1) * 3 + (kx + 1)];
          sum += value * weight;
        }
      }
      O[y * width + x] = sum;
    }
  }
}

__global__ void conv3(float* __restrict__ output,
                      const float* __restrict__ input,
                      const float* __restrict__ weights,
                      int width,
                      int height)
{
  int x = blockIdx.x * blockDim.x + threadIdx.x;
  int y = blockIdx.y * blockDim.y + threadIdx.y;
  if (x >= width || y >= height) return;

  const int paddedWidth = width + 2;
  const int px = x + 1;
  const int py = y + 1;

  float sum = 0.0f;
  sum += input[(py - 1) * paddedWidth + (px - 1)] * weights[0];
  sum += input[(py - 1) * paddedWidth +  px      ] * weights[1];
  sum += input[(py - 1) * paddedWidth + (px + 1)] * weights[2];
  sum += input[ py      * paddedWidth + (px - 1)] * weights[3];
  sum += input[ py      * paddedWidth +  px      ] * weights[4];
  sum += input[ py      * paddedWidth + (px + 1)] * weights[5];
  sum += input[(py + 1) * paddedWidth + (px - 1)] * weights[6];
  sum += input[(py + 1) * paddedWidth +  px      ] * weights[7];
  sum += input[(py + 1) * paddedWidth + (px + 1)] * weights[8];

  output[y * width + x] = sum;
}

// --- Globals / CLI ---
static int g_size = 32;
static int g_bx = 1;
static int g_by = 1;

static float* d_i = nullptr;
static float* d_w = nullptr;
static float* d_o = nullptr;

static bool is_number(const char* s) {
  if (!s || !*s) return false;
  char* end = nullptr;
  long v = strtol(s, &end, 10);
  (void)v;
  return end && *end == '\0';
}

static void show_usage() {
  printf("Usage: [-n size] [-bx X] [-by Y] [-h]\n");
  printf("  examples:\n");
  printf("    ./prog -n 256 -bx 32 -by 16\n");
  printf("    ./prog -n 1024 -bx32 -by16\n");
}

static void parse_args(int argc, char** argv) {
  for (int i = 1; i < argc; ++i) {
    const char* a = argv[i];

    if (!strcmp(a, "-h") || !strcmp(a, "--help")) {
      show_usage(); exit(0);
    }
    else if (!strcmp(a, "-n")) {
      if (i + 1 >= argc || !is_number(argv[i+1])) {
        fprintf(stderr, "Error: -n requires an integer value\n");
        exit(1);
      }
      g_size = atoi(argv[++i]);
    }
    else if (!strcmp(a, "-bx")) {
      if (i + 1 >= argc || !is_number(argv[i+1])) {
        fprintf(stderr, "Error: -bx requires an integer value\n");
        exit(1);
      }
      g_bx = atoi(argv[++i]);
    }
    else if (!strcmp(a, "-by")) {
      if (i + 1 >= argc || !is_number(argv[i+1])) {
        fprintf(stderr, "Error: -by requires an integer value\n");
        exit(1);
      }
      g_by = atoi(argv[++i]);
    }
    // support attached forms: -bx32 / -by16
    else if (!strncmp(a, "-bx", 3) && is_number(a + 3)) {
      g_bx = atoi(a + 3);
    }
    else if (!strncmp(a, "-by", 3) && is_number(a + 3)) {
      g_by = atoi(a + 3);
    }
    else {
      fprintf(stderr, "Unknown option or bad value: %s\n", a);
      show_usage(); exit(1);
    }
  }

  // basic validation
  if (g_size <= 0 || g_bx <= 0 || g_by <= 0) {
    fprintf(stderr, "Error: size and block dims must be positive\n");
    exit(1);
  }

  printf("Parsed: size=%d, bx=%d, by=%d\n", g_size, g_bx, g_by);
}

static void cleanup() {
  if (d_i) { cudaError_t e = cudaFree(d_i); if (e != cudaSuccess) std::fprintf(stderr, "cudaFree(d_i): %s\n", cudaGetErrorString(e)); d_i = nullptr; }
  if (d_w) { cudaError_t e = cudaFree(d_w); if (e != cudaSuccess) std::fprintf(stderr, "cudaFree(d_w): %s\n", cudaGetErrorString(e)); d_w = nullptr; }
  if (d_o) { cudaError_t e = cudaFree(d_o); if (e != cudaSuccess) std::fprintf(stderr, "cudaFree(d_o): %s\n", cudaGetErrorString(e)); d_o = nullptr; }
  cudaDeviceReset();
}

int main(int argc, char** argv) {
  parse_args(argc, argv);

  const int width  = g_size;
  const int height = g_size;
  const uint32_t o_points = (uint32_t)width * height;
  const uint32_t i_points = (uint32_t)(width + 2) * (height + 2);
  const uint32_t w_points = 9;

  std::printf("Create context\n");
  CUDA_CHECK(cudaSetDevice(0));
  cudaDeviceProp prop{}; CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
  std::printf("Using device: %s\n", prop.name);

  const size_t i_nbytes = i_points * sizeof(float);
  const size_t w_nbytes = w_points * sizeof(float);
  const size_t o_nbytes = o_points * sizeof(float);
  CUDA_CHECK(cudaMalloc(&d_i, i_nbytes));
  CUDA_CHECK(cudaMalloc(&d_w, w_nbytes));
  CUDA_CHECK(cudaMalloc(&d_o, o_nbytes));

  std::vector<float> h_i(i_points);
  std::vector<float> h_w(w_points);
  std::vector<float> h_o(o_points, 0.0f);

  for (int32_t y = -1; y < height + 1; ++y) {
    for (int32_t x = -1; x < width + 1; ++x) {
      float v = (x >= 0 && x < width && y >= 0 && y < height)
                ? static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX)
                : 0.0f;
      h_i[(y + 1) * (width + 2) + (x + 1)] = v;
    }
  }
  for (uint32_t i = 0; i < w_points; ++i)
    h_w[i] = static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX);

  CUDA_CHECK(cudaMemcpy(d_i, h_i.data(), i_nbytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_w, h_w.data(), w_nbytes, cudaMemcpyHostToDevice));

  // Launch config: block=(bx,by), grid=(ceil(width/bx), ceil(height/by))
  dim3 block((unsigned)g_bx, (unsigned)g_by, 1);
  dim3 grid( (width  + g_bx - 1) / g_bx,
             (height + g_by - 1) / g_by,
             1 );
  std::printf("Launch grid=(%u,%u,1), block=(%u,%u,1)\n", grid.x, grid.y, block.x, block.y);

  auto t0 = std::chrono::high_resolution_clock::now();
  conv3<<<grid, block>>>(d_o, d_i, d_w, width, height);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  std::printf("Elapsed time: %lg ms\n", elapsed);

  CUDA_CHECK(cudaMemcpy(h_o.data(), d_o, o_nbytes, cudaMemcpyDeviceToHost));

  std::vector<float> ref(o_points);
  convolution_cpu(ref.data(), h_i.data(), h_w.data(), width, height);

  int errors = 0;
  for (uint32_t i = 0; i < o_points; ++i) {
    if (!compare_equal(h_o[i], ref[i])) {
      if (errors < 100)
        std::printf("*** error: [%u] expected=%f, actual=%f\n", i, ref[i], h_o[i]);
      ++errors;
    }
  }
  if (errors) std::printf("FAILED! - %d errors\n", errors);
  else        std::printf("PASSED!\n");

  cleanup();
  return errors;
}