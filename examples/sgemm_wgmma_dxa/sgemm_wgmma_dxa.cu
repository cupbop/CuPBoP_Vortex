// sgemm_wgmma_dxa.cu - Hopper warpgroup GEMM with the operand tiles staged by the Vortex DXA engine
//
// Same compute as sgemm_wgmma (one warpgroup per 64x64 tile, wgmma.mma_async.m64n64k16 on shared
// memory descriptors), but the global->shared staging is a tile-copy engine instead of per-thread
// loads: on Vortex the DXA (CuPBoP's explicit API, as in sgemm_dxa), on Hopper it would be TMA.
// TN GEMM: C(MxN) = A(MxK, row-major) * B^T with B stored N x K row-major, so both operands are
// K-major and each is fetched as two 2-D boxes of 8 k x 64 rows per k-step. A box lands in local
// memory as 64 rows of 16 bytes, i.e. exactly the canonical no-swizzle K-major core-matrix layout
// with LBO = 1024 B (next K half) and SBO = 128 B (next 8-row group) -- the wgmma descriptor says so
// and nothing else changes. Double-buffered by default (DXA_STAGES=2). Vortex-only example (the DXA
// host/device API has no GPU counterpart).
#include <cuda_fp16.h>
#include <cuda_runtime.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

// -- DXA host-side API (CuPBoP runtime) --------------------------------------------------------
extern "C" void cudaDxaProgramDesc2D(unsigned int slot, unsigned long long base_addr,
                                      unsigned int size0, unsigned int size1,
                                      unsigned int stride0_bytes,
                                      unsigned int tile0, unsigned int tile1,
                                      unsigned int elem_bytes);
// -- DXA device-side API (resolved from cudaKernelImpl.cpp on Vortex; stubs for CUDA builds) ----
__device__ void __vx_dxa_issue_2d(unsigned int, unsigned int, void *, unsigned int, unsigned int) {}
__device__ void __vx_barrier_arrive_and_wait(unsigned int, unsigned int) {}
__device__ unsigned int __vx_dxa_barrier_id(unsigned int) { return 0; }
__device__ int __vx_is_dxa_warp(void) { return 0; }
__device__ unsigned int __vx_warps_per_group(void) { return 1; }

#define DXA_DESC_A 0
#define DXA_DESC_B 1

#define WG_M 64
#define WG_N 64
#define WG_K 16
#define WG_THREADS 128
#define WG_ACC (WG_N / 2)
#define DXA_BOX_K 8   // inner box dimension: 8 fp16 = 16 bytes = one core-matrix row
#define DXA_BOX_ROWS 64
// Pipeline depth (lowering-recipe knob, -DDXA_STAGES=1|2 via EXTRA_CLANG_FLAGS):
//   1: issue, wait, compute, sync per k-step (DXA latency exposed)
//   2: the next k-step's boxes are issued into the other buffer while this one is computed
#ifndef DXA_STAGES
#define DXA_STAGES 2
#endif

#define CUDA_CHECK(_expr)                                                      \
  do {                                                                         \
    cudaError_t _err = (_expr);                                                \
    if (_err != cudaSuccess) {                                                 \
      fprintf(stderr, "CUDA Error: '%s' returned %d (%s)!\n", #_expr, (int)_err, \
              cudaGetErrorString(_err));                                       \
      exit(1);                                                                 \
    }                                                                          \
  } while (0)

// Layout produced by the two 8x64 boxes: element (r, k) at (k>>3)*1024 + r*16 + (k&7)*2 bytes
#define SMEM_LBO_BYTES 1024
#define SMEM_SBO_BYTES 128

__device__ __forceinline__ uint32_t smem_u32(const void *p) {
  uint32_t a;
  asm volatile("{ .reg .u64 t; cvta.to.shared.u64 t, %1; cvt.u32.u64 %0, t; }" : "=r"(a) : "l"(p));
  return a;
}
__device__ __forceinline__ uint64_t make_desc(const void *smem_ptr) {
  uint64_t d = (uint64_t)((smem_u32(smem_ptr) & 0x3FFFFu) >> 4);
  d |= (uint64_t)(SMEM_LBO_BYTES >> 4) << 16;
  d |= (uint64_t)(SMEM_SBO_BYTES >> 4) << 32;
  return d;
}
__device__ __forceinline__ void wgmma_m64n64k16(float *d, uint64_t desc_a, uint64_t desc_b) {
  asm volatile(
      "{\n"
      ".reg .pred p;\n"
      "setp.ne.b32 p, %34, 0;\n"
      "wgmma.mma_async.sync.aligned.m64n64k16.f32.f16.f16 "
      "{%0, %1, %2, %3, %4, %5, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, "
      "%16, %17, %18, %19, %20, %21, %22, %23, %24, %25, %26, %27, %28, %29, %30, %31}, "
      "%32, %33, p, 1, 1, 0, 0;\n"
      "}\n"
      : "+f"(d[0]), "+f"(d[1]), "+f"(d[2]), "+f"(d[3]), "+f"(d[4]), "+f"(d[5]), "+f"(d[6]), "+f"(d[7]),
        "+f"(d[8]), "+f"(d[9]), "+f"(d[10]), "+f"(d[11]), "+f"(d[12]), "+f"(d[13]), "+f"(d[14]), "+f"(d[15]),
        "+f"(d[16]), "+f"(d[17]), "+f"(d[18]), "+f"(d[19]), "+f"(d[20]), "+f"(d[21]), "+f"(d[22]), "+f"(d[23]),
        "+f"(d[24]), "+f"(d[25]), "+f"(d[26]), "+f"(d[27]), "+f"(d[28]), "+f"(d[29]), "+f"(d[30]), "+f"(d[31])
      : "l"(desc_a), "l"(desc_b), "r"(1));
}

__global__ void __launch_bounds__(WG_THREADS)
sgemm_wgmma_dxa_kernel(const half *A, const half *Bt, float *C, int M, int N, int K) {
  __shared__ __align__(1024) half sA[DXA_STAGES][WG_M * WG_K]; // 2 KB each: two 1 KB K-halves of 64 x 16 B rows
  __shared__ __align__(1024) half sB[DXA_STAGES][WG_N * WG_K];
  const int tile_m = blockIdx.y * WG_M, tile_n = blockIdx.x * WG_N;
  const int tid = threadIdx.x;
  const unsigned int bar[2] = {__vx_dxa_barrier_id(0), __vx_dxa_barrier_id(1)};
  const int is_dxa = __vx_is_dxa_warp();
  const unsigned int nwarps = __vx_warps_per_group();
  float d[WG_ACC];
#pragma unroll
  for (int i = 0; i < WG_ACC; i++) d[i] = 0.f;

  // one warp issues the four boxes of a k-step into buffer `buf`; each adds one transaction to bar[buf]
#define ISSUE_KSTEP(buf, kk)                                                              \
  do {                                                                                    \
    __vx_dxa_issue_2d(DXA_DESC_A, bar[buf], sA[buf], (kk), tile_m);                       \
    __vx_dxa_issue_2d(DXA_DESC_A, bar[buf], sA[buf] + 8 * DXA_BOX_ROWS, (kk) + DXA_BOX_K, tile_m); \
    __vx_dxa_issue_2d(DXA_DESC_B, bar[buf], sB[buf], (kk), tile_n);                       \
    __vx_dxa_issue_2d(DXA_DESC_B, bar[buf], sB[buf] + 8 * DXA_BOX_ROWS, (kk) + DXA_BOX_K, tile_n); \
  } while (0)

#if DXA_STAGES == 2
  if (is_dxa) ISSUE_KSTEP(0, 0);
  int s = 0;
  for (int k0 = 0; k0 < K; k0 += WG_K, s ^= 1) {
    // prefetch the next k-step into the other buffer: its readers finished at the previous __syncthreads
    if (is_dxa && k0 + WG_K < K) ISSUE_KSTEP(s ^ 1, k0 + WG_K);
    __vx_barrier_arrive_and_wait(bar[s], nwarps); // this k-step's tiles landed
    asm volatile("fence.proxy.async.shared::cta;\n" ::: "memory");
    const uint64_t da = make_desc(sA[s]), db = make_desc(sB[s]);
    asm volatile("wgmma.fence.sync.aligned;\n" ::: "memory");
    wgmma_m64n64k16(d, da, db);
    asm volatile("wgmma.commit_group.sync.aligned;\n" ::: "memory");
    asm volatile("wgmma.wait_group.sync.aligned 0;\n" ::: "memory");
    __syncthreads(); // all warps done reading buffer s before it is refilled two steps later
  }
#else
  for (int k0 = 0; k0 < K; k0 += WG_K) {
    if (is_dxa) ISSUE_KSTEP(0, k0);
    __vx_barrier_arrive_and_wait(bar[0], nwarps); // all warps: tiles landed
    asm volatile("fence.proxy.async.shared::cta;\n" ::: "memory");
    const uint64_t da = make_desc(sA[0]), db = make_desc(sB[0]);
    asm volatile("wgmma.fence.sync.aligned;\n" ::: "memory");
    wgmma_m64n64k16(d, da, db);
    asm volatile("wgmma.commit_group.sync.aligned;\n" ::: "memory");
    asm volatile("wgmma.wait_group.sync.aligned 0;\n" ::: "memory");
    __syncthreads(); // before the next boxes overwrite the tiles
  }
#endif
#undef ISSUE_KSTEP

  const int warp = tid >> 5, lane = tid & 31, g = lane >> 2, t = lane & 3;
  const int row = tile_m + 16 * warp + g;
#pragma unroll
  for (int j = 0; j < WG_N / 8; j++) {
    const int col = tile_n + 8 * j + 2 * t;
    C[(size_t)row * N + col] = d[4 * j + 0];
    C[(size_t)row * N + col + 1] = d[4 * j + 1];
    C[(size_t)(row + 8) * N + col] = d[4 * j + 2];
    C[(size_t)(row + 8) * N + col + 1] = d[4 * j + 3];
  }
}

// C = A * B^T with B stored N x K
static void gemm_cpu_tn(const half *A, const half *Bt, float *C, int M, int N, int K) {
  for (int i = 0; i < M; i++)
    for (int j = 0; j < N; j++) {
      float sum = 0.f;
      for (int k = 0; k < K; k++)
        sum += __half2float(A[(size_t)i * K + k]) * __half2float(Bt[(size_t)j * K + k]);
      C[(size_t)i * N + j] = sum;
    }
}

int main(int argc, char **argv) {
  int M = WG_M, N = WG_N, K = WG_K;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-n") == 0 && i + 1 < argc) {
      int n = atoi(argv[++i]);
      if (n > 0 && n % WG_M == 0) {
        M = N = K = n;
      } else {
        fprintf(stderr, "Size must be a positive multiple of %d\n", WG_M);
        return 1;
      }
    }
  }
  printf("SGEMM WGMMA+DXA Test (TN): M=%d, N=%d, K=%d\n", M, N, K);
  size_t sizeA = (size_t)M * K * sizeof(half), sizeB = (size_t)N * K * sizeof(half), sizeC = (size_t)M * N * sizeof(float);
  half *h_A = (half *)malloc(sizeA), *h_B = (half *)malloc(sizeB);
  float *h_C = (float *)malloc(sizeC), *h_C_ref = (float *)malloc(sizeC);
  srand(42);
  for (size_t i = 0; i < (size_t)M * K; i++) h_A[i] = __float2half((float)(rand() % 17 - 8) / 8.0f);
  for (size_t i = 0; i < (size_t)N * K; i++) h_B[i] = __float2half((float)(rand() % 17 - 8) / 8.0f);
  gemm_cpu_tn(h_A, h_B, h_C_ref, M, N, K);

  half *d_A, *d_B; float *d_C;
  CUDA_CHECK(cudaMalloc(&d_A, sizeA));
  CUDA_CHECK(cudaMalloc(&d_B, sizeB));
  CUDA_CHECK(cudaMalloc(&d_C, sizeC));
  CUDA_CHECK(cudaMemcpy(d_A, h_A, sizeA, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_B, h_B, sizeB, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemset(d_C, 0, sizeC));
  // DXA descriptors: 2-D views of A (M rows x K) and Bt (N rows x K), fp16, box = 8 k x 64 rows
  cudaDxaProgramDesc2D(DXA_DESC_A, (unsigned long long)d_A, K, M, K * sizeof(half), DXA_BOX_K, DXA_BOX_ROWS, sizeof(half));
  cudaDxaProgramDesc2D(DXA_DESC_B, (unsigned long long)d_B, K, N, K * sizeof(half), DXA_BOX_K, DXA_BOX_ROWS, sizeof(half));
  dim3 grid(N / WG_N, M / WG_M);
  dim3 block(WG_THREADS, 1);
  sgemm_wgmma_dxa_kernel<<<grid, block>>>(d_A, d_B, d_C, M, N, K);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  CUDA_CHECK(cudaMemcpy(h_C, d_C, sizeC, cudaMemcpyDeviceToHost));

  int errors = 0;
  for (int i = 0; i < M * N; i++) {
    float diff = fabsf(h_C[i] - h_C_ref[i]);
    if (diff / fmaxf(fabsf(h_C_ref[i]), 1.0f) > 1e-2f) {
      if (errors < 10)
        printf("Mismatch [%d]: got %f, expected %f\n", i, h_C[i], h_C_ref[i]);
      errors++;
    }
  }
  printf("%s: %d/%d\n", errors ? "FAILED!" : "PASSED!", M * N - errors, M * N);
  CUDA_CHECK(cudaFree(d_A)); CUDA_CHECK(cudaFree(d_B)); CUDA_CHECK(cudaFree(d_C));
  free(h_A); free(h_B); free(h_C); free(h_C_ref);
  return errors ? 1 : 0;
}
