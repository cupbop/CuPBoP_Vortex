// hg_params.h: the 368-byte Params block of the lifted hgemm kernel (CUTLASS GemmUniversal, h16816 64x64x64 tile, 3 stages, nn, align8; experiments/e10k).
// cuBLAS NN column-major C = alpha*A*B + beta*C runs as the row-major problem (M' = N, N' = M, K): A' = B (ld K), B' = A (ld M), C' = C (ld M).
// Needs M, N, K multiples of 64. Identity swizzle (swizzle_log_tile 0), grid N/64 x M/64. The block sits at c[0x0][0x160] = the IR argument [368 x i8] %arg_352.
// Byte offsets: 0 problem (N, M, K) | 12 grid_tiled_shape (N/64, M/64, 1) | 24 swizzle_log_tile | 28 mode | 32 batch | 36 gemm_k_size K | 40 batch_stride_D
//   56 params_A (A' = B): K, 8K, 128-24K, 128 | 88 params_B (B' = A): M, 8M, 128M-24M, 128M | 120 params_C, 184 params_D: s, 4s, s, s, 8s, 32s, 64s, 16s with s = 2M
//   248 alpha, beta as f16 | 288 ptr_A (= B) | 296 ptr_B (= A) | 304 ptr_C | 312 ptr_D (= C) | 320 batch_stride_A N*K, 328 batch_stride_B K*M, 336 batch_stride_C N*M
#pragma once
#include <cstdint>
#include <cstring>
namespace hgp {
static const int BASE = 0x160, SIZE = 368;
template <class T> static inline void put(uint8_t *b, int off, T v) { memcpy(b + off, &v, sizeof(T)); }
// b = SIZE bytes, zero-filled by this function; a_half, b_half = alpha, beta as IEEE half bits
static inline void fill(uint8_t *b, int M, int N, int K, uint16_t a_half, uint16_t b_half, const void *A, const void *B, const void *C) {
  memset(b, 0, SIZE);
  const int32_t i3[9] = {N, M, K, N / 64, M / 64, 1, 0, 0, 1};
  memcpy(b, i3, sizeof i3); put<int32_t>(b, 36, K); put<int64_t>(b, 40, (int64_t)N * M);
  const int64_t k = K, m = M, s = 2 * m;
  const int64_t pa[4] = {k, 8 * k, 128 - 24 * k, 128}, pb[4] = {m, 8 * m, 128 * m - 24 * m, 128 * m}, ep[8] = {s, 4 * s, s, s, 8 * s, 32 * s, 64 * s, 16 * s};
  memcpy(b + 56, pa, sizeof pa); memcpy(b + 88, pb, sizeof pb); memcpy(b + 120, ep, sizeof ep); memcpy(b + 184, ep, sizeof ep);
  put<uint16_t>(b, 248, a_half); put<uint16_t>(b, 250, b_half);
  put<const void *>(b, 288, B); put<const void *>(b, 296, A); put<const void *>(b, 304, C); put<const void *>(b, 312, C);
  put<int64_t>(b, 320, (int64_t)N * K); put<int64_t>(b, 328, (int64_t)K * M); put<int64_t>(b, 336, (int64_t)N * M);
}
}  // namespace hgp
