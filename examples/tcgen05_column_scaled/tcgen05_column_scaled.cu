#include "../tcgen05_test.h"
#include <cmath>
#include <vector>

constexpr unsigned M = 128, N = 16, aBytes = M * 64, bBytes = N * 64;
#ifdef CUPBOP_TEST_SCALED_TMEM_A
constexpr unsigned rowWords = 18, allocCols = 64;
#else
constexpr unsigned rowWords = 10, allocCols = 32;
#endif
constexpr unsigned words = (aBytes + bBytes) / 4 + M * rowWords;
enum Case { F6_F4, F4_F6, MX_F6, MX_BF8, MX_F4, NV_F4, SP_F4 };
template <Case C> struct Shape {
  static constexpr bool compact = C >= MX_F4;
  static constexpr unsigned a = C == F6_F4 || C == MX_F6 ? 3 : C == F4_F6 ? 5 : C == MX_BF8 ? 1 : 5;
  static constexpr unsigned b = C == F4_F6 || C == MX_BF8 ? 4 : 5;
  static constexpr unsigned vec = C == NV_F4 || C == SP_F4 ? 4 : C == MX_F4 ? 2 : 1;
  static constexpr unsigned aid = vec == 4   ? 0
                                  : vec == 2 ? 2
                                             : 1,
                            bid = vec == 4   ? 0
                                  : vec == 2 ? 0
                                             : 3;
  static constexpr unsigned k = compact ? (C == SP_F4 ? 128 : 64) : 32;
  static constexpr unsigned desc =
      (8u << 24) | (2u << 17) | ((compact ? 1u : a) << 7) | ((compact ? 1u : b) << 10) |
      (C >= MX_F6 ? ((C == NV_F4 || C == SP_F4 ? 0u : 1u) << 23) | (aid << 29) | (bid << 4) : 16u) |
      (C == SP_F4 ? 4u : 0u);
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
  __shared__ uint64_t barrier;
  __shared__ unsigned slot;
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
  unsigned addr = slot + ((row & ~31u) << 16);
  const unsigned *scales = input + (aBytes + bBytes) / 4 + row * rowWords;
#define STORE4(off, x, y, z, w)                                                                        \
  asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0],{%1,%2,%3,%4};" ::"r"(addr + off), "r"(x),  \
               "r"(y), "r"(z), "r"(w)                                                                  \
               : "memory")
#ifdef CUPBOP_TEST_SCALED_TMEM_A
  STORE4(32, scales[10], scales[11], scales[12], scales[13]);
  STORE4(36, scales[14], scales[15], scales[16], scales[17]);
  asm volatile("tcgen05.wait::st.sync.aligned;" ::: "memory");
#define SOURCE_A "[%1]"
#define ARG_A "r"(slot + 32)
#else
#define SOURCE_A "%1"
#define ARG_A "l"(ad)
#endif
  if (C >= MX_F6) {
#ifdef CUPBOP_TEST_SCALE_COPY
    if (row < 32) {
      for (unsigned c = 0; c < 4; ++c) {
        scaleA[row][c] = scales[c];
        scaleB[row][c] = scales[4 + c];
      }
    }
#else
    STORE4(16, scales[0], scales[1], scales[2], scales[3]);
    STORE4(20, scales[4], scales[5], scales[6], scales[7]);
#endif
    if (C == SP_F4)
      STORE4(24, scales[8], scales[9], 0, 0);
    asm volatile("tcgen05.wait::st.sync.aligned;" ::: "memory");
  }
#undef STORE4
  __syncthreads();
  tcgen_after_sync();
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  if (!row) {
#ifdef CUPBOP_TEST_SCALE_COPY
    asm volatile("tcgen05.cp.cta_group::1.32x128b.warpx4 [%0], %1;"
                 :: "r"(slot + 16), "l"(tile_desc(scaleA, 16)) : "memory");
    asm volatile("tcgen05.cp.cta_group::1.32x128b.warpx4 [%0], %1;"
                 :: "r"(slot + 20), "l"(tile_desc(scaleB, 16)) : "memory");
#endif
    uint64_t ad = tile_desc(a, 32), bd = tile_desc(b, C == SP_F4 ? 64 : 32);
#define SCALED(kind)                                                                                   \
  asm volatile("{ .reg .pred p; setp.ne.u32 p,0,0; tcgen05.mma.cta_group::1.kind::" kind               \
               " [%0]," SOURCE_A ",%2,%3,[%4],[%5],p; }" ::"r"(slot),                                  \
               ARG_A, "l"(bd), "r"(S::desc), "r"(slot + 16), "r"(slot + 20)                            \
               : "memory")
    if (C == SP_F4) {
      asm volatile("{ .reg .pred p; setp.ne.u32 p,0,0; "
                   "tcgen05.mma.sp.cta_group::1.kind::mxf4nvf4.block_scale.scale_vec::4X [%0]," SOURCE_A
                   ",%2,[%3],%4,[%5],[%6],p; }" ::"r"(slot),
                   ARG_A, "l"(bd), "r"(slot + 24), "r"(S::desc), "r"(slot + 16), "r"(slot + 20)
                   : "memory");
    } else if (C == NV_F4) {
      SCALED("mxf4nvf4.block_scale.scale_vec::4X");
    } else if (C == MX_F4) {
      SCALED("mxf4.block_scale.scale_vec::2X");
    } else if (C >= MX_F6) {
      SCALED("mxf8f6f4.block_scale.scale_vec::1X");
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
  __syncthreads();
  mbar_wait(&barrier, 0);
  tcgen_after_sync();
  for (unsigned j = 0; j < N; j += 4) {
    unsigned v[4];
    asm volatile(
        "tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3},[%4]; tcgen05.wait::ld.sync.aligned;"
        : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3])
        : "r"(addr + j)
        : "memory");
    for (unsigned i = 0; i < 4; ++i)
      out[row * N + j + i] = v[i];
  }
  __syncthreads();
  if (row < 32)
    asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0,%1;" ::"r"(slot), "n"(allocCols)
                 : "memory");
}

static unsigned width(unsigned t) { return t <= 1 ? 8 : t == 5 ? 4 : 6; }
static unsigned raw(unsigned row, unsigned k, unsigned type, bool b) {
  unsigned v = row * (b ? 5 : 7) + k * (b ? 3 : 5) + k / 3 + row / 5 + int(b);
  if (type == 1) {
    const unsigned e5[] = {0x3c, 0x32, 0xb6, 0xc1, 0x40, 0xba, 0x3a};
    return e5[v % 7];
  }
  return v & ((1u << width(type)) - 1);
}
static float decode(unsigned raw, unsigned t) {
  unsigned m = t == 3 ? 3 : t == 5 ? 1 : 2, e = width(t) - m - 1;
  unsigned exp = raw >> m & ((1u << e) - 1), mant = raw & ((1u << m) - 1);
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
  std::vector<unsigned> data(words), result(M * N);
  for (unsigned b = 0; b < 2; ++b) {
    unsigned type = b ? S::b : S::a, rows = b ? N : M;
    unsigned K = S::k / (!b && C == SP_F4 ? 2 : 1);
    unsigned stride = S::compact ? K / 2 : K;
    unsigned char *dst = reinterpret_cast<unsigned char *>(data.data()) + b * aBytes;
    for (unsigned r = 0; r < rows; ++r)
      for (unsigned k = 0; k < K; ++k) {
        unsigned field = S::compact ? k * 4 : (k / 16) * 128 + (k % 16) * width(type);
        for (unsigned j = 0; j < width(type); ++j) {
          unsigned offset = (field + j) / 8, bit = (field + j) % 8;
          unsigned address = (r / 8) * stride * 8 + (offset / 16) * 128 + (r % 8) * 16 + offset % 16;
          dst[address] |= ((raw(r, k, type, b) >> j) & 1) << bit;
        }
      }
  }
  for (unsigned r = 0; r < M; ++r) {
    unsigned *v = data.data() + (aBytes + bBytes) / 4 + rowWords * r;
    for (unsigned c = 0; c < 4; ++c)
      for (unsigned s = 0; s < S::vec; ++s) {
        unsigned row = r % 32 + c * 32;
        v[c] |= scale_code(row, s, false, C >= NV_F4) << (8 * (s + S::aid));
        v[4 + c] |= scale_code(row, s, true, C >= NV_F4) << (8 * (s + S::bid));
      }
#ifdef CUPBOP_TEST_SCALED_TMEM_A
    unsigned extent = S::k / (C == SP_F4 ? 2 : 1);
    for (unsigned k = 0; k < extent; ++k) {
      unsigned bits = raw(r, k, S::a, false);
      unsigned width = S::compact ? 4 : 8;
      if (!S::compact && S::a == 5)
        bits <<= 2;
      v[10 + k * width / 32] |= bits << (k * width % 32);
    }
#endif
    if (C == SP_F4)
      for (unsigned k = 0; k < S::k; k += 8)
        v[8 + k / 64] |= selection(r, k / 8) << (4 * ((k / 8) % 8));
  }
  ASYNC_CHECK(cudaMemcpy(input, data.data(), words * 4, cudaMemcpyHostToDevice));
  column_scaled<C><<<1, M>>>(input, output);
  ASYNC_CHECK(cudaMemcpy(result.data(), output, M * N * 4, cudaMemcpyDeviceToHost));
  unsigned errors = 0;
  for (unsigned r = 0; r < M; ++r)
    for (unsigned n = 0; n < N; ++n) {
      float sum = 0;
      for (unsigned k = 0; k < S::k; ++k) {
        unsigned ak = k;
        if (C == SP_F4) {
          unsigned sel = selection(r, k / 8), p = k / 2 % 4;
          if (p != (sel & 3) && p != (sel >> 2))
            continue;
          ak = k / 8 * 4 + 2 * (p == (sel >> 2)) + k % 2;
        }
        float a = decode(raw(r, ak, S::a, false), S::a), b = decode(raw(n, k, S::b, true), S::b);
        if (C >= MX_F6) {
          unsigned s = k / (S::k / S::vec);
          a *= scale_value(r, s, false, C >= NV_F4);
          b *= scale_value(n, s, true, C >= NV_F4);
        }
        sum += a * b;
      }
      float got;
      memcpy(&got, &result[r * N + n], 4);
      if (got != sum && ++errors < 3)
        printf("case=%u row=%u col=%u got=%g expected=%g\n", unsigned(C), r, n, got, sum);
    }
  printf("case=%u mismatches=%u/%u\n", unsigned(C), errors, M * N);
  return errors != 0;
}
int main() {
  unsigned *in, *out;
  ASYNC_CHECK(cudaMalloc(&in, words * 4));
  ASYNC_CHECK(cudaMalloc(&out, M * N * 4));
#ifdef CUPBOP_TEST_SCALE_COPY
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
