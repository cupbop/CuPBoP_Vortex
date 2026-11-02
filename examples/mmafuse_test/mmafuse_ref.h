// Host-side model of mmafuse_kernel (PTX ISA m16n8k16 / m16n8k8 fragment layouts, double precision) and the golden
// file format, shared by mmafuse.cu (Vortex test) and experiments/mmafuse/unit/mmaf_gpu.cu (NVIDIA generator).
// Every reference value carries mag = sum |a*b| + |c| over its whole k-chain, the scale of an fp32 rounding error.
#pragma once
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include "mmafuse_kernel.cuh"
#define MMAF_WARPS 2
#define MMAF_LANES (32 * MMAF_WARPS)
struct MmafRef { double v[32][4], m[32][4]; };
static double mmaf_h2d(uint32_t h) {
  h &= 0xffffu; const int s = h >> 15, e = (h >> 10) & 31, m = h & 0x3ff;
  double v = e == 0 ? std::ldexp((double)m, -24) : std::ldexp(1.0 + m / 1024.0, e - 15);
  return s ? -v : v;
}
static double mmaf_bf2d(uint32_t b) { uint32_t u = (b & 0xffffu) << 16; float f; memcpy(&f, &u, 4); return f; }
static uint32_t mmaf_h2bf_host(uint32_t w) {
  uint32_t r = 0;
  for (int h = 0; h < 2; ++h) {
    const uint32_t x = (w >> (16 * h)) & 0xffffu, s = x & 0x8000u, e = (x >> 10) & 31u, m = x & 0x3ffu;
    const uint32_t f = e == 0 ? 0u : ((e + 112u) << 23) | (m << 13);
    r |= ((f >> 16) | s) << (16 * h);
  }
  return r;
}
// D = A(16xK) B(Kx8) + C ; a[l][nA], b[l][nB] fragment words of the 32 lanes; K = 16 (nA 4) or 8 (nA 2)
static void mmaf_ref_mma(int K, bool bf, const uint32_t a[32][4], const uint32_t b[32][2], const MmafRef &C, MmafRef &D) {
  double Am[16][16] = {}, Bm[16][8] = {}, Cv[16][8], Cm[16][8];
  auto el = [&](uint32_t w, int h) { return bf ? mmaf_bf2d(w >> (16 * h)) : mmaf_h2d(w >> (16 * h)); };
  for (int l = 0; l < 32; ++l) {
    const int g = l >> 2, t = l & 3;
    for (int h = 0; h < 2; ++h) {
      Am[g][2 * t + h] = el(a[l][0], h); Am[g + 8][2 * t + h] = el(a[l][1], h);
      if (K == 16) { Am[g][2 * t + 8 + h] = el(a[l][2], h); Am[g + 8][2 * t + 8 + h] = el(a[l][3], h); }
      Bm[2 * t + h][g] = el(b[l][0], h);
      if (K == 16) Bm[2 * t + 8 + h][g] = el(b[l][1], h);
    }
    const int rr[4] = {g, g, g + 8, g + 8}, cc[4] = {2 * t, 2 * t + 1, 2 * t, 2 * t + 1};
    for (int i = 0; i < 4; ++i) { Cv[rr[i]][cc[i]] = C.v[l][i]; Cm[rr[i]][cc[i]] = C.m[l][i]; }
  }
  for (int l = 0; l < 32; ++l) {
    const int g = l >> 2, t = l & 3, rr[4] = {g, g, g + 8, g + 8}, cc[4] = {2 * t, 2 * t + 1, 2 * t, 2 * t + 1};
    for (int i = 0; i < 4; ++i) {
      double s = Cv[rr[i]][cc[i]], m = Cm[rr[i]][cc[i]];
      for (int k = 0; k < K; ++k) { s += Am[rr[i]][k] * Bm[k][cc[i]]; m += std::fabs(Am[rr[i]][k] * Bm[k][cc[i]]); }
      D.v[l][i] = s; D.m[l][i] = m;
    }
  }
}
// reference of every output word of one warp: ref[l][o], mag[l][o]
static void mmaf_ref_warp(const uint32_t in[32][MMAF_NIN], int flag, double ref[32][MMAF_NOUT], double mag[32][MMAF_NOUT]) {
  static uint32_t A16[2][32][4], B16[2][2][32][2], A8[4][32][4], B8[2][4][32][2], AB[2][32][4], BB[2][2][32][2];
  MmafRef C[2];
  for (int l = 0; l < 32; ++l) {
    for (int s = 0; s < 2; ++s) for (int i = 0; i < 4; ++i) { A16[s][l][i] = in[l][4 * s + i]; AB[s][l][i] = mmaf_h2bf_host(A16[s][l][i]); }
    for (int u = 0; u < 2; ++u) for (int s = 0; s < 2; ++s) for (int i = 0; i < 2; ++i) { B16[u][s][l][i] = in[l][8 + 4 * u + 2 * s + i]; BB[u][s][l][i] = mmaf_h2bf_host(B16[u][s][l][i]); }
    for (int u = 0; u < 2; ++u) for (int i = 0; i < 4; ++i) { float f; memcpy(&f, &in[l][16 + 4 * u + i], 4); C[u].v[l][i] = f; C[u].m[l][i] = std::fabs(f); }
    for (int s = 0; s < 4; ++s) for (int i = 0; i < 2; ++i) A8[s][l][i] = in[l][24 + 2 * s + i];
    for (int u = 0; u < 2; ++u) for (int s = 0; s < 4; ++s) B8[u][s][l][0] = in[l][32 + 4 * u + s];
  }
  for (int l = 0; l < 32; ++l) for (int o = 0; o < MMAF_NOUT; ++o) { ref[l][o] = 0; mag[l][o] = 0; }
  auto put = [&](int o, const MmafRef &D) { for (int l = 0; l < 32; ++l) for (int i = 0; i < 4; ++i) { ref[l][o + i] = D.v[l][i]; mag[l][o + i] = D.m[l][i]; } };
  MmafRef d0, d1, t0, t1, t2, e;
  mmaf_ref_mma(16, false, A16[0], B16[0][0], C[0], d0); mmaf_ref_mma(16, false, A16[0], B16[1][0], C[1], d1); put(0, d0); put(4, d1);
  mmaf_ref_mma(16, false, A16[0], B16[0][0], C[0], t0); mmaf_ref_mma(16, false, A16[1], B16[0][1], t0, d0); put(8, d0);
  mmaf_ref_mma(16, false, A16[0], B16[1][0], C[1], t1); mmaf_ref_mma(16, false, A16[1], B16[1][1], t1, d1); put(12, d0); put(16, d1);
  mmaf_ref_mma(8, false, A8[0], B8[0][0], C[0], t0); mmaf_ref_mma(8, false, A8[0], B8[1][0], C[1], t1);
  mmaf_ref_mma(8, false, A8[1], B8[0][1], t0, t2); mmaf_ref_mma(8, false, A8[1], B8[1][1], t1, e);
  mmaf_ref_mma(8, false, A8[2], B8[0][2], t2, t0); mmaf_ref_mma(8, false, A8[2], B8[1][2], e, t1);
  mmaf_ref_mma(8, false, A8[3], B8[0][3], t0, d0); mmaf_ref_mma(8, false, A8[3], B8[1][3], t1, d1); put(20, d0); put(24, d1);
  mmaf_ref_mma(8, false, A8[0], B8[0][0], C[0], t0); mmaf_ref_mma(8, false, A8[1], B8[0][1], t0, t1); mmaf_ref_mma(8, false, A8[2], B8[0][2], t1, d0);
  mmaf_ref_mma(8, false, A8[3], B8[1][3], C[1], d1); put(28, d0); put(32, d1);
  mmaf_ref_mma(16, false, A16[0], B16[0][0], C[0], d0);
  for (int l = 0; l < 32; ++l) for (int i = 0; i < 4; ++i) { e.v[l][i] = d0.v[l][i] * 0.5; e.m[l][i] = d0.m[l][i] * 0.5; }
  mmaf_ref_mma(16, false, A16[0], B16[1][0], e, d1); put(36, d0); put(40, d1);
  mmaf_ref_mma(16, false, A16[0], B16[0][0], C[0], d0);
  if (flag) mmaf_ref_mma(16, false, A16[0], B16[1][0], C[1], d1); else d1 = C[1];
  put(44, d0); put(48, d1);
  mmaf_ref_mma(16, false, A16[0], B16[0][0], C[0], d0); mmaf_ref_mma(16, false, A16[0], B16[1][0], C[1], d1); put(52, d0); put(56, d1);
  for (int l = 0; l < 32; ++l) { ref[l][60] = C[1].v[l ^ 1][0]; mag[l][60] = std::fabs(ref[l][60]); }
  mmaf_ref_mma(16, false, A16[0], B16[0][0], C[0], t0); mmaf_ref_mma(16, false, A16[1], B16[0][1], t0, d0); put(64, t0); put(68, d0);
  mmaf_ref_mma(16, true, AB[0], BB[0][0], C[0], t0); mmaf_ref_mma(16, true, AB[0], BB[1][0], C[1], t1);
  mmaf_ref_mma(16, true, AB[1], BB[0][1], t0, d0); mmaf_ref_mma(16, true, AB[1], BB[1][1], t1, d1); put(72, d0); put(76, d1);
}
static const char *mmaf_test_name(int o) {
  static const int first[] = {0, 8, 12, 20, 28, 36, 44, 52, 64, 72, 80};
  static const char *names[] = {"T1 n2k1", "T2 n1k2", "T3 n2k2", "T4 n2k4(k8)", "T5 n1k3(k8)+1", "T6 dep", "T7 branch", "T8 shfl", "T9 mid-use", "T10 bf16 n2k2", "pad"};
  for (int i = 10; i >= 0; --i) if (o >= first[i]) return names[i];
  return "?";
}
static int mmaf_test_index(int o) {
  static const int first[] = {0, 8, 12, 20, 28, 36, 44, 52, 64, 72, 80};
  for (int i = 10; i >= 0; --i) if (o >= first[i]) return i;
  return 0;
}
