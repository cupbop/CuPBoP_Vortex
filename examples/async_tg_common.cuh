// One TN GEMM with four generation-native global->shared staging / MMA pairs (E12 stage 2, async_tg1..4):
//   C (M x N, row-major fp32) = A (M x K, row-major fp16) * B^T, B stored N x K row-major: both operands K-major.
//   CTA tile 64 x 64, k-step 16, 128 threads (4 warps = one warpgroup). Every stage holds each operand as two
//   8-k chunks of 64 rows x 16 B, the canonical no-swizzle K-major core-matrix layout:
//     element (r, k) at (k >> 3) * 1024 + r * 16 + (k & 7) * 2 bytes  (wgmma descriptor LBO = 1024, SBO = 128)
//   TG_V 1 (sm_75 style): LDG.128 -> registers -> STS, 2 stages (register prefetch), ldmatrix + mma.m16n8k8 x2
//   TG_V 2 (sm_80 style): cp.async.cg 16 B, 4 stages (wait_group 2), ldmatrix + mma.m16n8k16
//   TG_V 3 (sm_90a)     : TMA 2-D boxes (8 k x 64 rows, 4 per stage) completing on an mbarrier, 4 stages, wgmma m64n64k16
//   TG_V 4 (sm_90a)     : TMA as in 3, ldmatrix + mma.m16n8k16 (decouples the copy engine from the MMA)
// The 4 boxes of a stage share one arrive.expect_tx (CuPBoP's DXA issue queue holds 4). Stage loops are unrolled
// so every mbarrier / stage address is a constant offset (K must be a multiple of 64). Inputs are small integers,
// so every result is exact in fp32: the host compares against a CPU GEMM bit for bit and prints PASSED!/FAILED!.
// usage: <prog> [-m M] [-n N] [-k K]   (M, N multiples of 64, K multiple of 64)
#pragma once
#include <cuda.h>
#include <cuda_runtime.h>
#include <cuda_fp16.h>
#include <stdint.h>
#include "async_common.h"
#ifndef TG_V
#error "define TG_V: 1 ldg+mma1688, 2 cp.async+mma16816, 3 tma+wgmma, 4 tma+mma16816"
#endif
#define TG_BM 64
#define TG_BN 64
#define TG_BK 16
#define TG_THREADS 128
#define TG_STAGE_H 1024 // halves per operand stage (2 chunks x 64 rows x 8)
#if TG_V == 1
#define TG_STAGES 2
#else
#define TG_STAGES 4
#endif

__device__ __forceinline__ void tg_ldsm_x4(uint32_t &r0, uint32_t &r1, uint32_t &r2, uint32_t &r3, const void *p) {
  asm volatile("ldmatrix.sync.aligned.m8n8.x4.shared.b16 {%0, %1, %2, %3}, [%4];"
               : "=r"(r0), "=r"(r1), "=r"(r2), "=r"(r3) : "r"(smem_u32(p)));
}
__device__ __forceinline__ void tg_mma16816(float *c, const uint32_t *a, uint32_t b0, uint32_t b1) {
  asm volatile("mma.sync.aligned.m16n8k16.row.col.f32.f16.f16.f32 {%0, %1, %2, %3}, {%4, %5, %6, %7}, {%8, %9}, "
               "{%0, %1, %2, %3};"
               : "+f"(c[0]), "+f"(c[1]), "+f"(c[2]), "+f"(c[3])
               : "r"(a[0]), "r"(a[1]), "r"(a[2]), "r"(a[3]), "r"(b0), "r"(b1));
}
__device__ __forceinline__ void tg_mma1688(float *c, uint32_t a0, uint32_t a1, uint32_t b0) {
  asm volatile("mma.sync.aligned.m16n8k8.row.col.f32.f16.f16.f32 {%0, %1, %2, %3}, {%4, %5}, {%6}, {%0, %1, %2, %3};"
               : "+f"(c[0]), "+f"(c[1]), "+f"(c[2]), "+f"(c[3])
               : "r"(a0), "r"(a1), "r"(b0));
}

#if TG_V == 3
// ---- wgmma m64n64k16 f32 += f16 * f16, both operands K-major in shared memory (no swizzle)
__device__ __forceinline__ uint64_t tg_desc(const void *p) {
  uint64_t d = (uint64_t)((smem_u32(p) & 0x3FFFFu) >> 4);
  d |= (uint64_t)(1024 >> 4) << 16; // LBO: next 8-k chunk
  d |= (uint64_t)(128 >> 4) << 32;  // SBO: next 8-row group
  return d;
}
__device__ __forceinline__ void tg_wgmma(float *d, uint64_t da, uint64_t db) {
  asm volatile("{\n.reg .pred p;\nsetp.ne.b32 p, %34, 0;\n"
               "wgmma.mma_async.sync.aligned.m64n64k16.f32.f16.f16 "
               "{%0, %1, %2, %3, %4, %5, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, "
               "%16, %17, %18, %19, %20, %21, %22, %23, %24, %25, %26, %27, %28, %29, %30, %31}, "
               "%32, %33, p, 1, 1, 0, 0;\n}\n"
               : "+f"(d[0]), "+f"(d[1]), "+f"(d[2]), "+f"(d[3]), "+f"(d[4]), "+f"(d[5]), "+f"(d[6]), "+f"(d[7]),
                 "+f"(d[8]), "+f"(d[9]), "+f"(d[10]), "+f"(d[11]), "+f"(d[12]), "+f"(d[13]), "+f"(d[14]),
                 "+f"(d[15]), "+f"(d[16]), "+f"(d[17]), "+f"(d[18]), "+f"(d[19]), "+f"(d[20]), "+f"(d[21]),
                 "+f"(d[22]), "+f"(d[23]), "+f"(d[24]), "+f"(d[25]), "+f"(d[26]), "+f"(d[27]), "+f"(d[28]),
                 "+f"(d[29]), "+f"(d[30]), "+f"(d[31])
               : "l"(da), "l"(db), "r"(1));
}
#define TG_ACC 32
#else
#define TG_ACC 32 // 2 (m16) x 4 (n8) x 4 per thread: warp tile 32 x 32
#endif

#if TG_V >= 3
__device__ __forceinline__ void tg_tma2d(void *dst, const CUtensorMap *map, uint64_t *bar, int x, int y) {
  asm volatile("cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [%0], [%1, {%3, %4}], [%2];"
               ::"r"(smem_u32(dst)), "l"((uint64_t)map), "r"(smem_u32(bar)), "r"(x), "r"(y) : "memory");
}
#endif
#if TG_V == 2
__device__ __forceinline__ void tg_cp16(void *dst, const void *src) {
  asm volatile("cp.async.cg.shared.global [%0], [%1], 16;" ::"r"(smem_u32(dst)), "l"(src) : "memory");
}
__device__ __forceinline__ void tg_commit() { asm volatile("cp.async.commit_group;" ::: "memory"); }
__device__ __forceinline__ void tg_wait2() { asm volatile("cp.async.wait_group 2;" ::: "memory"); }
#endif

#if TG_V != 3
// warp (wm, wn) of the 2 x 2 warp grid computes rows 32 wm .. +32, cols 32 wn .. +32 of the CTA tile
__device__ __forceinline__ void tg_compute_mma(const half *sa, const half *sb, float (*acc)[4][4], int warp, int lane) {
  const int wm = warp >> 1, wn = warp & 1;
  uint32_t a[2][4], b[4][2];
#pragma unroll
  for (int i = 0; i < 2; ++i) {
    const int row = wm * 32 + i * 16 + (lane & 7) + ((lane >> 3) & 1) * 8, kc = lane >> 4;
    tg_ldsm_x4(a[i][0], a[i][1], a[i][2], a[i][3], sa + kc * 512 + row * 8);
  }
#pragma unroll
  for (int p = 0; p < 2; ++p) {
    const int n = wn * 32 + p * 16 + (lane & 7) + (lane >> 4) * 8, kc = (lane >> 3) & 1;
    tg_ldsm_x4(b[2 * p][0], b[2 * p][1], b[2 * p + 1][0], b[2 * p + 1][1], sb + kc * 512 + n * 8);
  }
#pragma unroll
  for (int i = 0; i < 2; ++i)
#pragma unroll
    for (int j = 0; j < 4; ++j) {
#if TG_V == 1
      tg_mma1688(acc[i][j], a[i][0], a[i][1], b[j][0]);
      tg_mma1688(acc[i][j], a[i][2], a[i][3], b[j][1]);
#else
      tg_mma16816(acc[i][j], a[i], b[j][0], b[j][1]);
#endif
    }
}
__device__ __forceinline__ void tg_store_mma(float (*acc)[4][4], float *C, int N, int m0, int n0, int warp, int lane) {
  const int wm = warp >> 1, wn = warp & 1, g = lane >> 2, t = lane & 3;
#pragma unroll
  for (int i = 0; i < 2; ++i)
#pragma unroll
    for (int j = 0; j < 4; ++j) {
      const int r = m0 + wm * 32 + i * 16 + g, c = n0 + wn * 32 + j * 8 + 2 * t;
      C[(size_t)r * N + c] = acc[i][j][0];
      C[(size_t)r * N + c + 1] = acc[i][j][1];
      C[(size_t)(r + 8) * N + c] = acc[i][j][2];
      C[(size_t)(r + 8) * N + c + 1] = acc[i][j][3];
    }
}
#endif

#if TG_V == 1
__global__ void __launch_bounds__(TG_THREADS) tg_ldg(const half *A, const half *B, float *C, int M, int N, int K) {
  __shared__ __align__(1024) half sA[TG_STAGES][TG_STAGE_H];
  __shared__ __align__(1024) half sB[TG_STAGES][TG_STAGE_H];
  const int tid = threadIdx.x, warp = tid >> 5, lane = tid & 31;
  const int m0 = blockIdx.y * TG_BM, n0 = blockIdx.x * TG_BN, KT = K / TG_BK;
  const int row = tid >> 1, kc = tid & 1; // one 16-byte chunk of A and of B per thread and stage
  const half *ga = A + (size_t)(m0 + row) * K + kc * 8, *gb = B + (size_t)(n0 + row) * K + kc * 8;
  const int so = kc * 512 + row * 8;
  float acc[2][4][4];
#pragma unroll
  for (int i = 0; i < 2; ++i)
#pragma unroll
    for (int j = 0; j < 4; ++j)
#pragma unroll
      for (int q = 0; q < 4; ++q) acc[i][j][q] = 0.f;
  uint4 ra = *(const uint4 *)ga, rb = *(const uint4 *)gb;
  *(uint4 *)(sA[0] + so) = ra;
  *(uint4 *)(sB[0] + so) = rb;
  __syncthreads();
  for (int kt = 0; kt < KT; ++kt) {
    const int s = kt & 1;
    if (kt + 1 < KT) { ra = *(const uint4 *)(ga + (kt + 1) * TG_BK); rb = *(const uint4 *)(gb + (kt + 1) * TG_BK); }
    tg_compute_mma(sA[s], sB[s], acc, warp, lane);
    if (kt + 1 < KT) { *(uint4 *)(sA[s ^ 1] + so) = ra; *(uint4 *)(sB[s ^ 1] + so) = rb; }
    __syncthreads();
  }
  tg_store_mma(acc, C, N, m0, n0, warp, lane);
}
#define TG_KERNEL_NAME "tg_ldg"
#endif

#if TG_V == 2
__global__ void __launch_bounds__(TG_THREADS) tg_cpa(const half *A, const half *B, float *C, int M, int N, int K) {
  __shared__ __align__(1024) half sA[TG_STAGES][TG_STAGE_H];
  __shared__ __align__(1024) half sB[TG_STAGES][TG_STAGE_H];
  const int tid = threadIdx.x, warp = tid >> 5, lane = tid & 31;
  const int m0 = blockIdx.y * TG_BM, n0 = blockIdx.x * TG_BN, KT = K / TG_BK;
  const int row = tid >> 1, kc = tid & 1;
  const half *ga = A + (size_t)(m0 + row) * K + kc * 8, *gb = B + (size_t)(n0 + row) * K + kc * 8;
  const int so = kc * 512 + row * 8;
  float acc[2][4][4];
#pragma unroll
  for (int i = 0; i < 2; ++i)
#pragma unroll
    for (int j = 0; j < 4; ++j)
#pragma unroll
      for (int q = 0; q < 4; ++q) acc[i][j][q] = 0.f;
#pragma unroll
  for (int s = 0; s < TG_STAGES - 1; ++s) {
    if (s < KT) { tg_cp16(sA[s] + so, ga + s * TG_BK); tg_cp16(sB[s] + so, gb + s * TG_BK); }
    tg_commit();
  }
  for (int kt0 = 0; kt0 < KT; kt0 += TG_STAGES) {
#pragma unroll
    for (int s = 0; s < TG_STAGES; ++s) {
      tg_wait2();
      __syncthreads();
      tg_compute_mma(sA[s], sB[s], acc, warp, lane);
      const int nk = kt0 + s + TG_STAGES - 1, ns = (s + TG_STAGES - 1) % TG_STAGES;
      if (nk < KT) { tg_cp16(sA[ns] + so, ga + nk * TG_BK); tg_cp16(sB[ns] + so, gb + nk * TG_BK); }
      tg_commit();
    }
  }
  tg_store_mma(acc, C, N, m0, n0, warp, lane);
}
#define TG_KERNEL_NAME "tg_cpa"
#endif

#if TG_V >= 3
// thread 0 arms full[s] for the 4 boxes (4 KB) of k-step kt and issues them
// One tensor map covers A and B, stored back to back (rows 0..M-1 = A, rows M..M+N-1 = B): CuLifter addresses
// every __grid_constant__ tensor map relative to parameter 0, and CuPBoP narrows only the parameters a cvta.param
// names, so a second CUtensorMap parameter would keep its 128 bytes and shift the later arguments.
__device__ __forceinline__ void tg_issue(const CUtensorMap *t, half *sa, half *sb, uint64_t *bar, int kt, int m0, int nb0) {
  mbar_arrive_expect_tx(bar, 4 * 1024);
  tg_tma2d(sa, t, bar, kt * TG_BK, m0);
  tg_tma2d(sa + 512, t, bar, kt * TG_BK + 8, m0);
  tg_tma2d(sb, t, bar, kt * TG_BK, nb0);
  tg_tma2d(sb + 512, t, bar, kt * TG_BK + 8, nb0);
}
__global__ void __launch_bounds__(TG_THREADS)
#if TG_V == 3
tg_tma(const __grid_constant__ CUtensorMap tmAB, float *C, int M, int N, int K) {
#else
tg_tmamma(const __grid_constant__ CUtensorMap tmAB, float *C, int M, int N, int K) {
#endif
  __shared__ __align__(1024) half sA[TG_STAGES][TG_STAGE_H];
  __shared__ __align__(1024) half sB[TG_STAGES][TG_STAGE_H];
  __shared__ __align__(8) uint64_t full[TG_STAGES];
  const int tid = threadIdx.x, warp = tid >> 5, lane = tid & 31;
  const int m0 = blockIdx.y * TG_BM, n0 = blockIdx.x * TG_BN, KT = K / TG_BK;
  if (tid == 0) {
#pragma unroll
    for (int s = 0; s < TG_STAGES; ++s) mbar_init(&full[s], 1);
    mbar_init_fence();
  }
  __syncthreads();
  // prologue: fill all stages (K >= 64, so KT >= TG_STAGES). A CTA barrier after each stage keeps every
  // arrive.expect_tx in its own wait-free region with exactly its 4 boxes (CuPBoP orders an arrive after the
  // copies that follow it before the next wait; its DXA issue queue holds 4)
#pragma unroll
  for (int s = 0; s < TG_STAGES; ++s) {
    if (tid == 0) tg_issue(&tmAB, sA[s], sB[s], &full[s], s, m0, M + n0);
    __syncthreads();
  }
#if TG_V == 3
  float d[TG_ACC];
#pragma unroll
  for (int i = 0; i < TG_ACC; ++i) d[i] = 0.f;
#else
  float acc[2][4][4];
#pragma unroll
  for (int i = 0; i < 2; ++i)
#pragma unroll
    for (int j = 0; j < 4; ++j)
#pragma unroll
      for (int q = 0; q < 4; ++q) acc[i][j][q] = 0.f;
#endif
  for (int kt0 = 0; kt0 < KT; kt0 += TG_STAGES) {
    const uint32_t par = (uint32_t)(kt0 / TG_STAGES) & 1u;
#pragma unroll
    for (int s = 0; s < TG_STAGES; ++s) {
      mbar_wait(&full[s], par);
#if TG_V == 3
      const uint64_t da = tg_desc(sA[s]), db = tg_desc(sB[s]);
      asm volatile("wgmma.fence.sync.aligned;\n" ::: "memory");
      tg_wgmma(d, da, db);
      asm volatile("wgmma.commit_group.sync.aligned;\n" ::: "memory");
      asm volatile("wgmma.wait_group.sync.aligned 0;\n" ::: "memory");
#else
      tg_compute_mma(sA[s], sB[s], acc, warp, lane);
#endif
      __syncthreads(); // every warp is done with stage s before it is refilled
      if (tid == 0 && kt0 + s + TG_STAGES < KT) tg_issue(&tmAB, sA[s], sB[s], &full[s], kt0 + s + TG_STAGES, m0, M + n0);
    }
  }
#if TG_V == 3
  { // accumulator layout of m64nN: warp w owns rows 16w + g (+8); d[4j + q] at col 8j + 2t (+1)
    const int g = lane >> 2, t = lane & 3;
#pragma unroll
    for (int j = 0; j < 8; ++j) {
      const int r = m0 + 16 * warp + g, c = n0 + 8 * j + 2 * t;
      C[(size_t)r * N + c] = d[4 * j + 0];
      C[(size_t)r * N + c + 1] = d[4 * j + 1];
      C[(size_t)(r + 8) * N + c] = d[4 * j + 2];
      C[(size_t)(r + 8) * N + c + 1] = d[4 * j + 3];
    }
  }
#else
  tg_store_mma(acc, C, N, m0, n0, warp, lane);
#endif
}
#if TG_V == 3
#define TG_KERNEL_NAME "tg_tma"
#else
#define TG_KERNEL_NAME "tg_tmamma"
#endif
#endif

// ---------------------------------------------------------------- host
static inline uint16_t tg_f2h(int v) { // exact for |v| <= 2048
  if (v == 0) return 0;
  uint32_t s = v < 0 ? 0x8000u : 0u, a = (uint32_t)(v < 0 ? -v : v);
  int e = 31 - __builtin_clz(a);                       // a = 1.m * 2^e
  uint32_t mant = (uint32_t)(((uint64_t)a << 10) >> e) & 0x3FFu;
  return (uint16_t)(s | ((uint32_t)(e + 15) << 10) | mant);
}
static inline int tg_val(size_t i, int salt) { return (int)((i * 7 + 3 + (size_t)salt * 5) % 9) - 4; }

int main(int argc, char **argv) {
  int M = 512, N = 256, K = 128;
  for (int i = 1; i + 1 < argc; i += 2) {
    if (!strcmp(argv[i], "-m")) M = atoi(argv[i + 1]);
    if (!strcmp(argv[i], "-n")) N = atoi(argv[i + 1]);
    if (!strcmp(argv[i], "-k")) K = atoi(argv[i + 1]);
  }
  if (M % TG_BM || N % TG_BN || K % 64) { printf("FAILED! M, N must be multiples of 64 and K of 64\n"); return 1; }
  printf("async_tg%d (%s): M=%d N=%d K=%d tile %dx%dx%d stages %d, %d CTAs\n", TG_V, TG_KERNEL_NAME, M, N, K, TG_BM, TG_BN,
         TG_BK, TG_STAGES, (M / TG_BM) * (N / TG_BN));
  const size_t na = (size_t)M * K, nb = (size_t)N * K, nc = (size_t)M * N;
  uint16_t *hA = (uint16_t *)malloc(na * 2), *hB = (uint16_t *)malloc(nb * 2);
  float *hC = (float *)malloc(nc * 4);
  for (size_t i = 0; i < na; ++i) hA[i] = tg_f2h(tg_val(i, 0));
  for (size_t i = 0; i < nb; ++i) hB[i] = tg_f2h(tg_val(i, 1));
  half *dA, *dB; // one allocation: B follows A (the TMA members read both through one tensor map)
  float *dC;
  ASYNC_CHECK(cudaMalloc(&dA, (na + nb) * 2));
  dB = dA + na;
  ASYNC_CHECK(cudaMalloc(&dC, nc * 4));
  ASYNC_CHECK(cudaMemcpy(dA, hA, na * 2, cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(dB, hB, nb * 2, cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemset(dC, 0, nc * 4));
  const dim3 grid(N / TG_BN, M / TG_BM), block(TG_THREADS);
#if TG_V >= 3
  CUtensorMap tmAB;
  {
    cuuint64_t dims[2] = {(cuuint64_t)K, (cuuint64_t)(M + N)}, st[1] = {(cuuint64_t)K * 2};
    cuuint32_t box[2] = {8, 64}, es[2] = {1, 1};
    ASYNC_CHECK(cuTensorMapEncodeTiled(&tmAB, CU_TENSOR_MAP_DATA_TYPE_FLOAT16, 2, dA, dims, st, box, es,
                                       CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_NONE,
                                       CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
  }
#if TG_V == 3
  tg_tma<<<grid, block>>>(tmAB, dC, M, N, K);
#else
  tg_tmamma<<<grid, block>>>(tmAB, dC, M, N, K);
#endif
#elif TG_V == 2
  tg_cpa<<<grid, block>>>(dA, dB, dC, M, N, K);
#else
  tg_ldg<<<grid, block>>>(dA, dB, dC, M, N, K);
#endif
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(hC, dC, nc * 4, cudaMemcpyDeviceToHost));
  long errors = 0;
  for (int i = 0; i < M; ++i)
    for (int j = 0; j < N; ++j) {
      long s = 0;
      for (int k = 0; k < K; ++k) s += (long)tg_val((size_t)i * K + k, 0) * tg_val((size_t)j * K + k, 1);
      if (hC[(size_t)i * N + j] != (float)s) {
        if (errors < 8) printf("MISMATCH C[%d][%d]: got %f, expected %ld\n", i, j, hC[(size_t)i * N + j], s);
        errors++;
      }
    }
  printf("%ld errors of %zu\n%s\n", errors, nc, errors ? "FAILED!" : "PASSED!");
  return errors ? 1 : 0;
}
