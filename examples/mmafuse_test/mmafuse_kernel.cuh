// mmafuse_test kernel (CUPBOP_MMA_FUSE unit test), shared by the Vortex test (mmafuse.cu) and the NVIDIA golden
// generator (experiments/mmafuse/unit/mmaf_gpu.cu). Each lane of each warp reads NIN input words and writes NOUT
// output words; the tests are groups of PTX mma.sync ops that the fusion pass may or may not merge:
//   T1 n-pair m16n8k16 (same A, two B/C)        -> n2k1      T2 k-chain m16n8k16 x2              -> n1k2
//   T3 n-pair of k-chains m16n8k16              -> n2k2      T4 n-pair of k-chains m16n8k8 x4    -> n2k4
//   T5 k-chain m16n8k8 x3 + an unrelated op     -> n1k3 + 1  T6 second op's C depends on the first -> not fused
//   T7 second op under a branch                 -> not fused T8 shuffle between the two ops      -> not fused
//   T9 chain whose middle result is also stored -> not k-fused  T10 T3 with bf16 inputs          -> n2k2 bf16
#pragma once
#include <cstdint>
#define MMAF_NIN 40
#define MMAF_NOUT 88
#define MMA16(D, A, B, C) asm volatile("mma.sync.aligned.m16n8k16.row.col.f32.f16.f16.f32 {%0,%1,%2,%3}, {%4,%5,%6,%7}, {%8,%9}, {%10,%11,%12,%13};" \
  : "=f"((D)[0]), "=f"((D)[1]), "=f"((D)[2]), "=f"((D)[3]) : "r"((A)[0]), "r"((A)[1]), "r"((A)[2]), "r"((A)[3]), "r"((B)[0]), "r"((B)[1]), \
    "f"((C)[0]), "f"((C)[1]), "f"((C)[2]), "f"((C)[3]))
#define MMA16BF(D, A, B, C) asm volatile("mma.sync.aligned.m16n8k16.row.col.f32.bf16.bf16.f32 {%0,%1,%2,%3}, {%4,%5,%6,%7}, {%8,%9}, {%10,%11,%12,%13};" \
  : "=f"((D)[0]), "=f"((D)[1]), "=f"((D)[2]), "=f"((D)[3]) : "r"((A)[0]), "r"((A)[1]), "r"((A)[2]), "r"((A)[3]), "r"((B)[0]), "r"((B)[1]), \
    "f"((C)[0]), "f"((C)[1]), "f"((C)[2]), "f"((C)[3]))
#define MMA8(D, A, B, C) asm volatile("mma.sync.aligned.m16n8k8.row.col.f32.f16.f16.f32 {%0,%1,%2,%3}, {%4,%5}, {%6}, {%7,%8,%9,%10};" \
  : "=f"((D)[0]), "=f"((D)[1]), "=f"((D)[2]), "=f"((D)[3]) : "r"((A)[0]), "r"((A)[1]), "r"((B)[0]), \
    "f"((C)[0]), "f"((C)[1]), "f"((C)[2]), "f"((C)[3]))
// f16x2 -> bf16x2 by truncation of the exact f32 value (integer ops only, same bits on every target; normal numbers)
__device__ __forceinline__ uint32_t mmaf_h2bf(uint32_t w) {
  uint32_t r = 0;
  for (int h = 0; h < 2; ++h) {
    const uint32_t x = (w >> (16 * h)) & 0xffffu, s = x & 0x8000u, e = (x >> 10) & 31u, m = x & 0x3ffu;
    const uint32_t f = e == 0 ? 0u : ((e + 112u) << 23) | (m << 13);
    r |= ((f >> 16) | s) << (16 * h);
  }
  return r;
}
__global__ void mmafuse_kernel(const uint32_t *io, uint32_t *out, int flag) {
  const int tid = blockIdx.x * blockDim.x + threadIdx.x, lane = threadIdx.x & 31;
  const uint32_t *in = io + tid * MMAF_NIN;
  uint32_t a16[2][4], b16[2][2][2], a8[4][2], b8[2][4][1];
  float c[2][4];
  for (int s = 0; s < 2; ++s) for (int i = 0; i < 4; ++i) a16[s][i] = in[4 * s + i];
  for (int u = 0; u < 2; ++u) for (int s = 0; s < 2; ++s) for (int i = 0; i < 2; ++i) b16[u][s][i] = in[8 + 4 * u + 2 * s + i];
  for (int u = 0; u < 2; ++u) for (int i = 0; i < 4; ++i) c[u][i] = __uint_as_float(in[16 + 4 * u + i]);
  for (int s = 0; s < 4; ++s) for (int i = 0; i < 2; ++i) a8[s][i] = in[24 + 2 * s + i];
  for (int u = 0; u < 2; ++u) for (int s = 0; s < 4; ++s) b8[u][s][0] = in[32 + 4 * u + s];
  float o[MMAF_NOUT];
  for (int i = 0; i < MMAF_NOUT; ++i) o[i] = 0.f;
  float d0[4], d1[4], t0[4], t1[4], t2[4], e[4];
  // T1
  MMA16(d0, a16[0], b16[0][0], c[0]); MMA16(d1, a16[0], b16[1][0], c[1]);
  for (int i = 0; i < 4; ++i) { o[0 + i] = d0[i]; o[4 + i] = d1[i]; }
  // T2
  MMA16(t0, a16[0], b16[0][0], c[0]); MMA16(d0, a16[1], b16[0][1], t0);
  for (int i = 0; i < 4; ++i) o[8 + i] = d0[i];
  // T3
  MMA16(t0, a16[0], b16[0][0], c[0]); MMA16(t1, a16[0], b16[1][0], c[1]);
  MMA16(d0, a16[1], b16[0][1], t0); MMA16(d1, a16[1], b16[1][1], t1);
  for (int i = 0; i < 4; ++i) { o[12 + i] = d0[i]; o[16 + i] = d1[i]; }
  // T4
  MMA8(t0, a8[0], b8[0][0], c[0]); MMA8(t1, a8[0], b8[1][0], c[1]);
  MMA8(t2, a8[1], b8[0][1], t0); MMA8(e, a8[1], b8[1][1], t1);
  MMA8(t0, a8[2], b8[0][2], t2); MMA8(t1, a8[2], b8[1][2], e);
  MMA8(d0, a8[3], b8[0][3], t0); MMA8(d1, a8[3], b8[1][3], t1);
  for (int i = 0; i < 4; ++i) { o[20 + i] = d0[i]; o[24 + i] = d1[i]; }
  // T5
  MMA8(t0, a8[0], b8[0][0], c[0]); MMA8(t1, a8[1], b8[0][1], t0); MMA8(d0, a8[2], b8[0][2], t1);
  MMA8(d1, a8[3], b8[1][3], c[1]);
  for (int i = 0; i < 4; ++i) { o[28 + i] = d0[i]; o[32 + i] = d1[i]; }
  // T6
  MMA16(d0, a16[0], b16[0][0], c[0]);
  for (int i = 0; i < 4; ++i) e[i] = d0[i] * 0.5f;
  MMA16(d1, a16[0], b16[1][0], e);
  for (int i = 0; i < 4; ++i) { o[36 + i] = d0[i]; o[40 + i] = d1[i]; }
  // T7
  MMA16(d0, a16[0], b16[0][0], c[0]);
  if (flag) { MMA16(d1, a16[0], b16[1][0], c[1]); } else { for (int i = 0; i < 4; ++i) d1[i] = c[1][i]; }
  for (int i = 0; i < 4; ++i) { o[44 + i] = d0[i]; o[48 + i] = d1[i]; }
  // T8
  MMA16(d0, a16[0], b16[0][0], c[0]);
  const float x = __shfl_sync(0xffffffffu, c[1][0], lane ^ 1);
  MMA16(d1, a16[0], b16[1][0], c[1]);
  for (int i = 0; i < 4; ++i) { o[52 + i] = d0[i]; o[56 + i] = d1[i]; }
  o[60] = x;
  // T9
  MMA16(t0, a16[0], b16[0][0], c[0]); MMA16(d0, a16[1], b16[0][1], t0);
  for (int i = 0; i < 4; ++i) { o[64 + i] = t0[i]; o[68 + i] = d0[i]; }
  // T10
  uint32_t ab[2][4], bb[2][2][2];
  for (int s = 0; s < 2; ++s) for (int i = 0; i < 4; ++i) ab[s][i] = mmaf_h2bf(a16[s][i]);
  for (int u = 0; u < 2; ++u) for (int s = 0; s < 2; ++s) for (int i = 0; i < 2; ++i) bb[u][s][i] = mmaf_h2bf(b16[u][s][i]);
  MMA16BF(t0, ab[0], bb[0][0], c[0]); MMA16BF(t1, ab[0], bb[1][0], c[1]);
  MMA16BF(d0, ab[1], bb[0][1], t0); MMA16BF(d1, ab[1], bb[1][1], t1);
  for (int i = 0; i < 4; ++i) { o[72 + i] = d0[i]; o[76 + i] = d1[i]; }
  for (int i = 0; i < MMAF_NOUT; ++i) out[tid * MMAF_NOUT + i] = __float_as_uint(o[i]);
  (void)lane;
}
