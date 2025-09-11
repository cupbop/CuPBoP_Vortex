// sfilter_cuda.cu
// CUDA port that mirrors the provided OpenCL sfilter example (with tunable block size)
// Build: nvcc -O3 -std=c++17 -o sfilter_cuda sfilter_cuda.cu
// Run:   ./sfilter_cuda -n 16 -b16x16   (or -bx 16 -by 16)

#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <chrono>
#include <unistd.h>
#include <cmath>

#define CUDA_CHECK(expr) do {                                     \
  cudaError_t _err = (expr);                                      \
  if (_err != cudaSuccess) {                                      \
    fprintf(stderr, "CUDA Error: %s at %s:%d\n",                  \
            cudaGetErrorString(_err), __FILE__, __LINE__);        \
    std::abort();                                                 \
  }                                                               \
} while (0)

static bool almost_equal(float a, float b, int ulp = 4) {
  union fi_t { int i; float f; };
  fi_t fa, fb;
  fa.f = a;
  fb.f = b;
  return std::abs(fa.i - fb.i) <= ulp;
}

static void show_usage() {
  printf("Usage: sfilter_cuda [-n size] [-b WxH | -bx W -by H] [-h]\n");
  printf("  -n   : matrix size (N x N), N >= 3 (default 16)\n");
  printf("  -b   : block size in 'WxH' format (e.g., -b32x8)\n");
  printf("  -bx  : blockDim.x (e.g., -bx 32)\n");
  printf("  -by  : blockDim.y (e.g., -by 8)\n");
  printf("  -h   : help\n");
}

static int size_ = 16;
static int block_x = 16;
static int block_y = 16;

static void parse_b_arg(const char* s) {
  // parse "WxH"
  int w = 0, h = 0;
  if (std::sscanf(s, "%dx%d", &w, &h) == 2 && w > 0 && h > 0) {
    block_x = w; block_y = h;
  } else {
    fprintf(stderr, "Invalid -b format. Use -b32x8\n");
    std::exit(-1);
  }
}

static void parse_args(int argc, char **argv) {
  int c;
  // getopt string includes options with arguments: n:, b: and long-ish bx/by handled manually
  while ((c = getopt(argc, argv, "n:b:h")) != -1) {
    switch (c) {
      case 'n':
        size_ = std::atoi(optarg);
        break;
      case 'b':
        parse_b_arg(optarg);
        break;
      case 'h':
        show_usage();
        std::exit(0);
      default:
        show_usage();
        std::exit(-1);
    }
  }
  // handle -bx and -by if present (manual scan)
  for (int i = 1; i < argc; ++i) {
    if (std::strcmp(argv[i], "-bx") == 0 && i + 1 < argc) {
      block_x = std::atoi(argv[i + 1]);
    }
    if (std::strcmp(argv[i], "-by") == 0 && i + 1 < argc) {
      block_y = std::atoi(argv[i + 1]);
    }
  }
  if (size_ < 3) {
    fprintf(stderr, "Error: input size must be >= 3\n");
    std::exit(-1);
  }
  if (block_x <= 0 || block_y <= 0) {
    fprintf(stderr, "Error: invalid block size (%d x %d)\n", block_x, block_y);
    std::exit(-1);
  }
}

// m0 m1 m2
// m3 m4 m5
// m6 m7 m8
// __global__ void sfilter_kernel(const float* src, //(removed __restrict__)
//                                float* dst, //(removed __restrict__)
//                                long long ldc,
//                                float m0,float m1,float m2,
//                                float m3,float m4,float m5,
//                                float m6,float m7,float m8)
// {
//   // Emulate OpenCL's global_offset = {1,1} with +1 here
//   const long long x0 = blockIdx.x * blockDim.x + threadIdx.x;
//   const long long y0 = blockIdx.y * blockDim.y + threadIdx.y;
//   const long long x = x0 + 1;
//   const long long y = y0 + 1;

//   // Only compute interior pixels [1..ldc-2] just like global size {size-2,size-2}
//   if (x >= ldc - 1 || y >= ldc - 1) return;

//   const long long addr = x + y * ldc;

//   float i0 = src[addr-1-1*ldc]*m0;
//   float i1 = src[addr+0-1*ldc]*m1;
//   float i2 = src[addr+1-1*ldc]*m2;
//   float i3 = src[addr-1+0*ldc]*m3;
//   float i4 = src[addr+0+0*ldc]*m4;
//   float i5 = src[addr+1+0*ldc]*m5;
//   float i6 = src[addr-1+1*ldc]*m6;
//   float i7 = src[addr+0+1*ldc]*m7;
//   float i8 = src[addr+1+1*ldc]*m8;

//   dst[addr] = i0 + i1 + i2 + i3 + i4 + i5 + i6 + i7 + i8;
// }

__global__ void sfilter_kernel(const float* __restrict__ src,
                               float* __restrict__ dst,
                               int ldc,           // int로 충분
                               float m0,float m1,float m2,
                               float m3,float m4,float m5,
                               float m6,float m7,float m8)
{
  // 작업 영역 크기 (내부만 계산)
  const int work_x = ldc - 2;
  const int work_y = ldc - 2;

  // 오프셋 적용 전의 “작업 좌표”
  // blockidx.y 0-61 
  // threadidx.x 0-63

  const int x0 = blockIdx.x * blockDim.x + threadIdx.x; // x0(0-64)
  const int y0 = blockIdx.y * blockDim.y + threadIdx.y; // y0(62)

    // 실제 좌표 = 내부 시작점 (1,1) 에서 오프셋 +1
  const int x = x0 + 1;
  const int y = y0 + 1;

  const int addr = x + y * ldc;
  if (x0 == 0)
  {
    printf("blockidx.y= %d", blockIdx.y);
  }
  //printf("blockdim.x: %d, blockDim.y: %d", blockDim.x, blockDim.y);
  //printf("griddim.x: %d griddim.y:  %d", gridDim.x, gridDim.y);
  // if (y0 == 16)
  // {
  //      printf("blockIdx.x: %d, threadIdx.x: %d", blockIdx.x, threadIdx.x);
  //       printf("blockIdx.y: %d, threadIdx.y: %d", blockIdx.y, threadIdx.y);
  //       printf("x0=%d, y0=%d", x0, y0); 
  // }
  // if (addr > 1089 && addr <1150)
  // {
  //   printf("blockIdx.x: %d, threadIdx.x: %d", blockIdx.x, threadIdx.x);
  //   printf("blockIdx.y: %d, threadIdx.y: %d", blockIdx.y, threadIdx.y);
  //   printf("x0=%d, y0=%d", x0, y0);
  // }

  // work 범위 밖이면 리턴 (오프셋 적용 前 기준)
  if (x0 >= work_x || y0 >= work_y) return;




  float i0 = src[addr-1-1*ldc]*m0;
  float i1 = src[addr+0-1*ldc]*m1;
  float i2 = src[addr+1-1*ldc]*m2;
  float i3 = src[addr-1+0*ldc]*m3;
  float i4 = src[addr+0+0*ldc]*m4;
  float i5 = src[addr+1+0*ldc]*m5;
  float i6 = src[addr-1+1*ldc]*m6;
  float i7 = src[addr+0+1*ldc]*m7;
  float i8 = src[addr+1+1*ldc]*m8;

  dst[addr] = i0 + i1 + i2 + i3 + i4 + i5 + i6 + i7 + i8;
}

int main(int argc, char** argv) {
  parse_args(argc, argv);

  printf("input size=%d\n", size_);
  printf("block size=%dx%d\n", block_x, block_y);

  const long long ldc = size_;
  const size_t n = (size_t)size_ * size_;
  const size_t nbytes = n * sizeof(float);

  // Host buffers
  std::vector<float> src_h(n);
  std::vector<float> dst_h(n, 0.0f);
  std::vector<float> ref_vec(n, 0.0f);

  // Init host input
  for (size_t i = 0; i < n; ++i) {
    src_h[i] = static_cast<float>(rand()) / RAND_MAX * 100.0f;
  }

  // Masks (same defaults as OpenCL host)
  float m0 = 1.0f, m1 = 1.0f, m2 = 1.0f;
  float m3 = 1.0f, m4 = 1.0f, m5 = 1.0f;
  float m6 = 1.0f, m7 = 1.0f, m8 = 1.0f;

  // Reference computation (OpenCL style launch mapping)
  {
    const size_t global_offset[2]    = {1, 1};
    const size_t global_work_size[2] = {(size_t)(size_ - 2), (size_t)(size_ - 2)};
    const size_t local_work_size[2]  = {1, 1};

    size_t num_groups_y = global_work_size[1] / local_work_size[1];
    size_t num_groups_x = global_work_size[0] / local_work_size[0];
    for (size_t workgroup_id_y = 0; workgroup_id_y < num_groups_y; ++workgroup_id_y) {
      for (size_t workgroup_id_x = 0; workgroup_id_x < num_groups_x; ++workgroup_id_x) {
        for (size_t local_id_y = 0; local_id_y < local_work_size[1]; ++local_id_y) {
          for (size_t local_id_x = 0; local_id_x < local_work_size[0]; ++local_id_x) {
            int x = global_offset[0] + local_work_size[0] * workgroup_id_x + local_id_x;
            int y = global_offset[1] + local_work_size[1] * workgroup_id_y + local_id_y;
            long long addr = x + (long long)y * ldc;
            float i0 = src_h.at(addr-1-1*ldc)*m0;
            float i1 = src_h.at(addr+0-1*ldc)*m1;
            float i2 = src_h.at(addr+1-1*ldc)*m2;
            float i3 = src_h.at(addr-1+0*ldc)*m3;
            float i4 = src_h.at(addr+0+0*ldc)*m4;
            float i5 = src_h.at(addr+1+0*ldc)*m5;
            float i6 = src_h.at(addr-1+1*ldc)*m6;
            float i7 = src_h.at(addr+0+1*ldc)*m7;
            float i8 = src_h.at(addr+1+1*ldc)*m8;
            float v = i0 + i1 + i2 + i3 + i4 + i5 + i6 + i7 + i8;
            ref_vec.at(addr) = v;
          }
        }
      }
    }
  }

  // Device buffers
  float *src_d = nullptr, *dst_d = nullptr;
  CUDA_CHECK(cudaMalloc(&src_d, nbytes));
  CUDA_CHECK(cudaMalloc(&dst_d, nbytes));

  // Upload
  CUDA_CHECK(cudaMemcpy(src_d, src_h.data(), nbytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemset(dst_d, 0, nbytes));

  // Launch config:
  // domain = interior region size_ - 2 by size_ - 2 (because of +1 offset in kernel)
  const int work_x = size_ - 2;
  const int work_y = size_ - 2;

  dim3 block(block_x, block_y, 1);
  dim3 grid((work_x + block_x - 1) / block_x,
            (work_y + block_y - 1) / block_y,
            1);

  printf("enqueue kernel\n");
  printf("global_work_size=[%d, %d]  block=[%d, %d]  grid=[%d, %d]\n",
         work_x, work_y, block_x, block_y, grid.x, grid.y);

  auto t0 = std::chrono::high_resolution_clock::now();
  sfilter_kernel<<<grid, block>>>(src_d, dst_d, size_,
                                  m0,m1,m2,m3,m4,m5,m6,m7,m8);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  printf("Elapsed time: %g ms\n", elapsed_ms);

  // Download
  CUDA_CHECK(cudaMemcpy(dst_h.data(), dst_d, nbytes, cudaMemcpyDeviceToHost));

  // Verify
  int errors = 0;
  for (size_t i = 0; i < n; ++i) {
    if (!almost_equal(dst_h[i], ref_vec[i])) {
      if (errors < 100) {
        printf("*** error: [%zu] expected=%f, actual=%f\n", i, ref_vec[i], dst_h[i]);
      }
      ++errors;
    }
  }
  if (errors == 0) {
    printf("PASSED!\n");
  } else {
    printf("FAILED! - %d errors\n", errors);
  }

  // Cleanup
  cudaFree(src_d);
  cudaFree(dst_d);
  return errors;
}