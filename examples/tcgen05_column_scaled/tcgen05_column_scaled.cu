#include "../tcgen05_test.h"
#include <cmath>
#include <vector>

constexpr unsigned M = 128, N = 16, aBytes = M * 64, bBytes = N * 64;
#ifdef CUPBOP_TEST_SCALED_TMEM_A
constexpr unsigned rowWords = 18;
#else
constexpr unsigned rowWords = 10;
#endif
#ifdef CUPBOP_TEST_SPLIT_MX
constexpr unsigned allocCols = 32, outStride = N + 8;
#elif defined(CUPBOP_TEST_FULL_MX)
constexpr unsigned allocCols = 512, outStride = N + 8;
#else
constexpr unsigned allocCols = rowWords == 18 ? 64 : 32, outStride = N;
#endif
#ifdef CUPBOP_TEST_SPLIT_MX
constexpr unsigned scaleOffset = 0, aOffset = 16, opaqueColumns = 32;
#elif defined(CUPBOP_TEST_UPPER_MX)
constexpr unsigned scaleOffset = 256, aOffset = 272, opaqueColumns = 256;
#else
constexpr unsigned scaleOffset = 16, aOffset = 32, opaqueColumns = 0;
#endif
constexpr unsigned nativeGuardCols = opaqueColumns ? opaqueColumns - N : 0;
constexpr unsigned resultStride = outStride + nativeGuardCols;
constexpr unsigned words = (aBytes + bBytes) / 4 + M * rowWords;
enum Case { F6_F4, F4_F6, MX_F6, MX_BF8, MX_F4, NV_F4, SP_F4, E5_E4, E4_E5, E5_E2, E2_E5, SP_E5_E4 };
template <Case C> struct Shape {
  static constexpr bool compact = C == MX_F4 || C == NV_F4 || C == SP_F4;
  static constexpr bool nvScale = C == NV_F4 || C == SP_F4;
  static constexpr bool sparse = C == SP_F4 || C == SP_E5_E4;
  static constexpr bool accumulate = C == E5_E2 || C == E2_E5;
  static constexpr unsigned a = C == F6_F4 || C == MX_F6 || C == E2_E5 ? 3
                              : C == MX_BF8 || C == E5_E4 || C == E5_E2 || C == SP_E5_E4 ? 1
                              : C == E4_E5 ? 0 : 5;
  static constexpr unsigned b = C == F4_F6 || C == MX_BF8 ? 4 : C == E5_E2 ? 3
                              : C == E2_E5 || C == E4_E5 ? 1 : C == E5_E4 || C == SP_E5_E4 ? 0 : 5;
  static constexpr unsigned vec = C == NV_F4 || C == SP_F4 ? 4 : C == MX_F4 ? 2 : 1;
  static constexpr unsigned aid = vec == 4   ? 0
                                  : vec == 2 ? 2
                                             : 1,
                            bid = vec == 4   ? 0
                                  : vec == 2 ? 0
                                             : 3;
  static constexpr unsigned k = (compact ? 64 : 32) * (sparse ? 2 : 1);
  static constexpr unsigned desc =
      (8u << 24) | (2u << 17) | ((compact ? 1u : a) << 7) | ((compact ? 1u : b) << 10) |
      (C >= MX_F6 ? ((C == NV_F4 || C == SP_F4 ? 0u : 1u) << 23) | (aid << 29) | (bid << 4) : 16u) |
      (sparse ? 4u : 0u);
};
__device__ uint64_t tile_desc(const void *p, unsigned bytes) {
  return ((smem_u32(p) >> 4) & 16383u) | (8ull << 16) | (uint64_t(bytes / 2) << 32) | (1ull << 46);
}
template <Case C> __global__ void column_scaled(const unsigned *input, unsigned *out) {
  typedef Shape<C> S;
  __shared__ __align__(128) unsigned a[aBytes / 4], b[bBytes / 4];
#ifdef CUPBOP_TEST_SCALE_COPY
  __shared__ __align__(128) unsigned scaleA[32][4], scaleB[32][4];
#endif
#if defined(CUPBOP_TEST_UPPER_MX) || defined(CUPBOP_TEST_SPLIT_MX)
  __shared__ __align__(128) unsigned guardB[opaqueColumns * 32 / 4];
  for (unsigned i = threadIdx.x; i < opaqueColumns * 32 / 4; i += M)
    guardB[i] = input[aBytes / 4 + i % (N * 32 / 4)];
#endif
  __shared__ uint64_t barrier;
  __shared__ unsigned slot;
#ifdef CUPBOP_TEST_SPLIT_MX
  __shared__ unsigned other[4];
#endif
  unsigned row = threadIdx.x;
  for (unsigned i = row; i < aBytes / 4; i += M)
    a[i] = input[i];
  for (unsigned i = row; i < bBytes / 4; i += M)
    b[i] = input[aBytes / 4 + i];
  if (!row)
    mbar_init(&barrier, 1);
  if (row < 32)
    asm volatile(
        "tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0],%1;" ::"r"(smem_u32(&slot)),
        "n"(allocCols)
        : "memory");
  __syncthreads();
#ifdef CUPBOP_TEST_SPLIT_MX
  if (row < 32) {
#define ALLOC_OTHER(i, size) asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0],%1;" :: "r"(smem_u32(other+i)), "n"(size) : "memory")
    ALLOC_OTHER(0, 32);
    ALLOC_OTHER(1, 64);
    ALLOC_OTHER(2, 128);
    ALLOC_OTHER(3, 256);
#undef ALLOC_OTHER
  }
  __syncthreads();
  unsigned sideOffset = other[0] - slot;
#else
  constexpr unsigned sideOffset = 0;
#endif
  unsigned addr = slot + ((row & ~31u) << 16);
  const unsigned *scales = input + (aBytes + bBytes) / 4 + row * rowWords;
#define STORE4(off, x, y, z, w)                                                                        \
  asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0],{%1,%2,%3,%4};" ::"r"(addr + off), "r"(x),  \
               "r"(y), "r"(z), "r"(w)                                                                  \
               : "memory")
#ifdef CUPBOP_TEST_SCALED_TMEM_A
  STORE4(sideOffset + aOffset, scales[10], scales[11], scales[12], scales[13]);
  STORE4(sideOffset + aOffset + 4, scales[14], scales[15], scales[16], scales[17]);
  asm volatile("tcgen05.wait::st.sync.aligned;" ::: "memory");
#define SOURCE_A "[%1]"
#define ARG_A "r"(slot + sideOffset + aOffset)
#else
#define SOURCE_A "%1"
#define ARG_A "l"(ad)
#endif
  if (C >= MX_F6) {
    if (S::accumulate)
      for (unsigned j = 0; j < N; j += 4)
        STORE4(j, 0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u);
#ifdef CUPBOP_TEST_SCALE_COPY
    if (row < 32) {
      for (unsigned c = 0; c < 4; ++c) {
        scaleA[row][c] = scales[c];
        scaleB[row][c] = scales[4 + c];
      }
    }
#else
    STORE4(sideOffset + scaleOffset, scales[0], scales[1], scales[2], scales[3]);
    STORE4(sideOffset + scaleOffset + 4, scales[4], scales[5], scales[6], scales[7]);
#endif
    if (S::sparse)
      STORE4(sideOffset + scaleOffset + 8, scales[8], scales[9], 0, 0);
    asm volatile("tcgen05.wait::st.sync.aligned;" ::: "memory");
  }
#undef STORE4
  __syncthreads();
  tcgen_after_sync();
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  if (!row) {
#ifdef CUPBOP_TEST_SCALE_COPY
    asm volatile("tcgen05.cp.cta_group::1.32x128b.warpx4 [%0], %1;"
                 :: "r"(slot + sideOffset + scaleOffset), "l"(tile_desc(scaleA, 16)) : "memory");
    asm volatile("tcgen05.cp.cta_group::1.32x128b.warpx4 [%0], %1;"
                 :: "r"(slot + sideOffset + scaleOffset + 4), "l"(tile_desc(scaleB, 16)) : "memory");
#endif
    uint64_t ad = tile_desc(a, 32), bd = tile_desc(b, S::sparse ? 64 : 32);
#if defined(CUPBOP_TEST_UPPER_MX) || defined(CUPBOP_TEST_SPLIT_MX)
    // Fill the destination run/window with opaque native accumulator bits.
    // The MX must preserve the other accumulator tile(s) and the side inputs.
    constexpr unsigned guardDesc =
        (8u << 24) | ((opaqueColumns / 8) << 17) | (S::a << 7) | (S::b << 10) | 16u;
    asm volatile("{ .reg .pred p; setp.ne.u32 p,0,0; "
                 "tcgen05.mma.cta_group::1.kind::f8f6f4 [%0]," SOURCE_A ",%2,%3,p; }"
                 :: "r"(slot), ARG_A, "l"(tile_desc(guardB, 32)), "r"(guardDesc) : "memory");
#endif
#define SCALED(kind)                                                                                   \
  asm volatile("{ .reg .pred p; setp.ne.u32 p,%6,0; tcgen05.mma.cta_group::1.kind::" kind              \
               " [%0]," SOURCE_A ",%2,%3,[%4],[%5],p; }" ::"r"(slot),                                  \
               ARG_A, "l"(bd), "r"(S::desc), "r"(slot + sideOffset + scaleOffset), "r"(slot + sideOffset + scaleOffset + 4), "n"(S::accumulate)       \
               : "memory")
    if (C == SP_E5_E4) {
      asm volatile("{ .reg .pred p; setp.ne.u32 p,0,0; "
                   "tcgen05.mma.sp.cta_group::1.kind::mxf8f6f4.block_scale.scale_vec::1X [%0]," SOURCE_A
                   ",%2,[%3],%4,[%5],[%6],p; }" :: "r"(slot), ARG_A, "l"(bd), "r"(slot + sideOffset + scaleOffset + 8),
                   "r"(S::desc), "r"(slot + sideOffset + scaleOffset), "r"(slot + sideOffset + scaleOffset + 4) : "memory");
    } else if (C == SP_F4) {
      asm volatile("{ .reg .pred p; setp.ne.u32 p,0,0; "
                   "tcgen05.mma.sp.cta_group::1.kind::mxf4nvf4.block_scale.scale_vec::4X [%0]," SOURCE_A
                   ",%2,[%3],%4,[%5],[%6],p; }" ::"r"(slot),
                   ARG_A, "l"(bd), "r"(slot + sideOffset + scaleOffset + 8), "r"(S::desc), "r"(slot + sideOffset + scaleOffset), "r"(slot + sideOffset + scaleOffset + 4)
                   : "memory");
    } else if (C == NV_F4) {
      SCALED("mxf4nvf4.block_scale.scale_vec::4X");
    } else if (C == MX_F4) {
      SCALED("mxf4.block_scale.scale_vec::2X");
    } else if (C >= MX_F6) {
      SCALED("mxf8f6f4.block_scale.scale_vec::1X");
#ifdef CUPBOP_TEST_FULL_MX
      // The second operation consumes the first native result in place.
      asm volatile("{ .reg .pred p; setp.eq.u32 p,0,0; "
                   "tcgen05.mma.cta_group::1.kind::mxf8f6f4.block_scale.scale_vec::1X [%0],"
                   SOURCE_A ",%2,%3,[%4],[%5],p; }" :: "r"(slot), ARG_A, "l"(bd), "r"(S::desc),
                   "r"(slot + sideOffset + scaleOffset), "r"(slot + sideOffset + scaleOffset + 4) : "memory");
#endif
    } else
      asm volatile(
          "{ .reg .pred p; setp.ne.u32 p,0,0; tcgen05.mma.cta_group::1.kind::f8f6f4 [%0]," SOURCE_A
          ",%2,%3,p; }" ::"r"(slot),
          ARG_A, "l"(bd), "r"(S::desc)
          : "memory");
#undef SCALED
#undef SOURCE_A
#undef ARG_A
    asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];" ::"r"(
                     smem_u32(&barrier))
                 : "memory");
  }
#ifdef CUPBOP_TEST_SPLIT_MX
  // Other issuing warps may read the CUDA scales while warp zero has an MX
  // outstanding. They must never observe the temporary Vortex byte layout.
  bool observedTemporary = false;
  if (row >= 32) {
    for (unsigned sample = 0; sample < 3; ++sample)
      for (unsigned j = 0; j < 8; j += 4) {
        unsigned v[4];
        asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3},[%4]; "
                     "tcgen05.wait::ld.sync.aligned;"
                     : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3])
                     : "r"(addr + sideOffset + scaleOffset + j) : "memory");
        for (unsigned i = 0; i < 4; ++i) observedTemporary |= v[i] != scales[j + i];
      }
  }
#endif
  __syncthreads();
  mbar_wait(&barrier, 0);
  tcgen_after_sync();
  for (unsigned j = 0; j < resultStride; j += 4) {
    unsigned offset = j < N ? j : j < outStride ? sideOffset + scaleOffset + j - N : N + j - outStride;
    unsigned v[4];
    asm volatile(
        "tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3},[%4]; tcgen05.wait::ld.sync.aligned;"
        : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3])
        : "r"(addr + offset)
        : "memory");
    for (unsigned i = 0; i < 4; ++i)
      out[row * resultStride + j + i] = v[i];
  }
#ifdef CUPBOP_TEST_SPLIT_MX
  if (observedTemporary) out[row * resultStride + N] = ~scales[0];
#endif
  __syncthreads();
  if (row < 32)
    asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0,%1;" ::"r"(slot), "n"(allocCols)
                 : "memory");
#ifdef CUPBOP_TEST_SPLIT_MX
  if (row < 32) {
#define FREE_OTHER(i, size) asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0,%1;" :: "r"(other[i]), "n"(size) : "memory")
    FREE_OTHER(0, 32);
    FREE_OTHER(1, 64);
    FREE_OTHER(2, 128);
    FREE_OTHER(3, 256);
#undef FREE_OTHER
  }
#endif
}

static unsigned width(unsigned t) { return t <= 1 ? 8 : t == 5 ? 4 : 6; }
template <Case C> static unsigned raw(unsigned row, unsigned k, unsigned type, bool b) {
  unsigned v = row * (b ? 5 : 7) + k * (b ? 3 : 5) + k / 3 + row / 5 + int(b);
  if (C >= E5_E4) {
    // Exercise odd significands, both range limits and signed subnormals.
    // Restrict E5M2 magnitude per row so all finite reference sums are exact.
    if (type == 1) {
      if (!Shape<C>::sparse && row % 16 >= 13 && k == 0)
        return row % 16 == 13 ? 0x7c : row % 16 == 14 ? 0xfc : 0x7e;
      const unsigned e5[] = {0x01, 0x7b, 0xf8, 0x38, 0xc0, 0x80, 0x24, 0};
      return k % 4 == 0 ? e5[row % 8] : 0;
    }
    if (type == 0) {
      if (!Shape<C>::sparse && row == 12 && k == 1)
        return 0x7f;
      const unsigned e4[] = {0x01, 0x83, 0x3b, 0xbd, 0x7e, 0xf7, 0x02, 0x80};
      return e4[(row + k / 4) % 8];
    }
    return v & 63;
  }
  if (type == 1) {
    const unsigned e5[] = {0x3c, 0x32, 0xb6, 0xc1, 0x40, 0xba, 0x3a};
    return e5[v % 7];
  }
  return v & ((1u << width(type)) - 1);
}
static float decode(unsigned raw, unsigned t) {
  unsigned m = t == 0 || t == 3 ? 3 : t == 5 ? 1 : 2, e = width(t) - m - 1;
  unsigned exp = raw >> m & ((1u << e) - 1), mant = raw & ((1u << m) - 1);
  if (t == 0 && (raw & 127) == 127) return NAN;
  if (t == 1 && (raw & 124) == 124) return mant ? NAN : (raw & 128 ? -INFINITY : INFINITY);
  int bias = (1 << (e - 1)) - 1;
  return std::ldexp(float(mant + (exp ? 1u << m : 0)), (exp ? int(exp) : 1) - bias - int(m)) *
         (raw >> (m + e) ? -1 : 1);
}
static unsigned scale_code(unsigned row, unsigned s, bool b, bool nv) {
  unsigned i = (row + (b ? 2 : 1) * s + row / 3 + int(b)) % 3;
  return nv ? 0x30 + 8 * i : 126 + i;
}
static float scale_value(unsigned row, unsigned s, bool b, bool nv) {
  unsigned code = scale_code(row, s, b, nv);
  return std::ldexp(1.f, nv ? int(code >> 3) - 7 : int(code) - 127);
}
static unsigned selection(unsigned row, unsigned group) {
  const unsigned choices[] = {4, 8, 12, 9, 13, 14};
  return choices[(row + 5 * group) % 6];
}
template <Case C> static int check(unsigned *input, unsigned *output) {
  typedef Shape<C> S;
  std::vector<unsigned> data(words), result(M * resultStride);
  for (unsigned b = 0; b < 2; ++b) {
    unsigned type = b ? S::b : S::a, rows = b ? N : M;
    unsigned K = S::k / (!b && S::sparse ? 2 : 1);
    unsigned stride = S::compact ? K / 2 : K;
    unsigned char *dst = reinterpret_cast<unsigned char *>(data.data()) + b * aBytes;
    for (unsigned r = 0; r < rows; ++r)
      for (unsigned k = 0; k < K; ++k) {
        unsigned field = S::compact ? k * 4 : (k / 16) * 128 + (k % 16) * width(type);
        for (unsigned j = 0; j < width(type); ++j) {
          unsigned offset = (field + j) / 8, bit = (field + j) % 8;
          unsigned address = (r / 8) * stride * 8 + (offset / 16) * 128 + (r % 8) * 16 + offset % 16;
          dst[address] |= ((raw<C>(r, k, type, b) >> j) & 1) << bit;
        }
      }
  }
  for (unsigned r = 0; r < M; ++r) {
    unsigned *v = data.data() + (aBytes + bBytes) / 4 + rowWords * r;
    for (unsigned c = 0; c < 4; ++c)
      for (unsigned s = 0; s < S::vec; ++s) {
        unsigned row = r % 32 + c * 32;
        v[c] |= scale_code(row, s, false, S::nvScale) << (8 * (s + S::aid));
        v[4 + c] |= scale_code(row, s, true, S::nvScale) << (8 * (s + S::bid));
      }
#ifdef CUPBOP_TEST_SCALED_TMEM_A
    unsigned extent = S::k / (S::sparse ? 2 : 1);
    for (unsigned k = 0; k < extent; ++k) {
      unsigned bits = raw<C>(r, k, S::a, false);
      unsigned width = S::compact ? 4 : 8;
      if (!S::compact && S::a == 5)
        bits <<= 2;
      v[10 + k * width / 32] |= bits << (k * width % 32);
    }
#endif
    if (S::sparse) {
      unsigned groupSize = S::compact ? 8 : 4;
      for (unsigned g = 0; g < S::k / groupSize; ++g)
        v[8 + g / 8] |= selection(r, g) << (4 * (g % 8));
    }
  }
  ASYNC_CHECK(cudaMemcpy(input, data.data(), words * 4, cudaMemcpyHostToDevice));
  column_scaled<C><<<1, M>>>(input, output);
  ASYNC_CHECK(cudaMemcpy(result.data(), output, M * resultStride * 4, cudaMemcpyDeviceToHost));
  unsigned errors = 0;
#ifdef CUPBOP_TEST_FULL_MX
  unsigned guardErrors = 0;
#endif
  for (unsigned r = 0; r < M; ++r)
    for (unsigned n = 0; n < N; ++n) {
      float sum = S::accumulate ? 4.f : 0.f;
#if defined(CUPBOP_TEST_UPPER_MX) || defined(CUPBOP_TEST_SPLIT_MX)
      float nativeGuard = 0;
#endif
      for (unsigned k = 0; k < S::k; ++k) {
        unsigned ak = k;
        if (S::sparse) {
          unsigned unit = S::compact ? 2 : 1, group = k / (4 * unit);
          unsigned sel = selection(r, group), p = k / unit % 4;
          if (p != (sel & 3) && p != (sel >> 2))
            continue;
          ak = (2 * group + (p == (sel >> 2))) * unit + k % unit;
        }
        float a = decode(raw<C>(r, ak, S::a, false), S::a), b = decode(raw<C>(n, k, S::b, true), S::b);
#if defined(CUPBOP_TEST_UPPER_MX) || defined(CUPBOP_TEST_SPLIT_MX)
        nativeGuard += a * b;
#endif
        if (C >= MX_F6) {
          unsigned s = k / (S::k / S::vec);
          a *= scale_value(r, s, false, S::nvScale);
          b *= scale_value(n, s, true, S::nvScale);
        }
        sum += a * b;
      }
#ifdef CUPBOP_TEST_FULL_MX
      sum += sum - (S::accumulate ? 4.f : 0.f);
#endif
#if defined(CUPBOP_TEST_UPPER_MX) || defined(CUPBOP_TEST_SPLIT_MX)
      for (unsigned j = N; j < opaqueColumns; j += N) {
        float guard;
        memcpy(&guard, &result[r * resultStride + outStride + j - N + n], 4);
        if (guard != nativeGuard) ++guardErrors;
      }
#endif
      float got;
      memcpy(&got, &result[r * resultStride + n], 4);
      if (got != sum && !(std::isnan(got) && std::isnan(sum)) && ++errors < 3)
        printf("case=%u row=%u col=%u got=%g expected=%g\n", unsigned(C), r, n, got, sum);
    }
#ifdef CUPBOP_TEST_FULL_MX
  // The borrowed eight columns hold the CUDA scale words, including bytes
  // that no scale selector consumes. Check every bit in both row panels.
  for (unsigned r = 0; r < M; ++r) {
    const unsigned *scale = data.data() + (aBytes + bBytes) / 4 + r * rowWords;
    for (unsigned j = 0; j < 8; ++j)
      if (result[r * resultStride + N + j] != scale[j]) ++guardErrors;
  }
  printf("case=%u guard_mismatches=%u/%u\n", unsigned(C), guardErrors, M * (8 + nativeGuardCols));
#endif
  printf("case=%u mismatches=%u/%u\n", unsigned(C), errors, M * N);
#ifdef CUPBOP_TEST_FULL_MX
  errors += guardErrors;
#endif
  return errors != 0;
}
int main() {
  unsigned *in, *out;
  ASYNC_CHECK(cudaMalloc(&in, words * 4));
  ASYNC_CHECK(cudaMalloc(&out, M * resultStride * 4));
#ifdef CUPBOP_TEST_FULL_MX
  int failed = check<MX_F6>(in, out) | check<MX_BF8>(in, out);
#elif defined(CUPBOP_TEST_MIXED_MX)
  int failed = check<E5_E4>(in, out) | check<E4_E5>(in, out) | check<E5_E2>(in, out) |
               check<E2_E5>(in, out) | check<SP_E5_E4>(in, out);
#elif defined(CUPBOP_TEST_SCALE_COPY)
  int failed = check<MX_F6>(in, out) | check<NV_F4>(in, out);
#else
  int failed = check<F6_F4>(in, out) | check<F4_F6>(in, out) | check<MX_F6>(in, out) |
               check<MX_BF8>(in, out) | check<MX_F4>(in, out) | check<NV_F4>(in, out) |
               check<SP_F4>(in, out);
#endif
  ASYNC_CHECK(cudaFree(in));
  ASYNC_CHECK(cudaFree(out));
  return failed;
}
