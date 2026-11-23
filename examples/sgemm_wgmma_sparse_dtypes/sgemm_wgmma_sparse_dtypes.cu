#include <cuda_fp16.h>
#include <cuda_runtime.h>
#include <climits>
#include <type_traits>

#include "../async_common.h"

constexpr int M = 64, N = 8, Threads = 128;
enum Format { tf32, e4m3, e5m2, s8, u8 };
template <Format F> using Bits = typename std::conditional<F == tf32, uint32_t, uint8_t>::type;

// Select TF32 (1), FP8 (2), INT8 (4), INT8 saturation (8), mixed-sign INT8 (16), or packed FP16 output (32).
#ifndef CUPBOP_SPARSE_DTYPE_MASK
#define CUPBOP_SPARSE_DTYPE_MASK 15
#endif

template <typename T>
__device__ __forceinline__ int core_offset(int row, int k, int width) {
  constexpr int atom = 16 / sizeof(T);
  return (row / 8) * (8 * width) + (k / atom) * (8 * atom) + (row % 8) * atom + (k % atom);
}

template <typename T>
__device__ __forceinline__ uint64_t descriptor(const T *p, int width) {
  return ((smem_u32(p) & 0x3ffffu) >> 4) | (8ull << 16) | (uint64_t(width * sizeof(T) / 2) << 32);
}

template <typename T>
__device__ __forceinline__ uint32_t packed_word(const T *p) {
  uint32_t word = 0;
  for (unsigned i = 0; i < 4 / sizeof(T); ++i) word |= uint32_t(p[i]) << (8 * sizeof(T) * i);
  return word;
}

template <Format A, Format B> struct SparseMma;

#define DEFINE_MMA(A, B, K, DT, CXX, CONSTRAINT, SCALES) \
template <> struct SparseMma<A, B> { \
  using Acc = CXX; \
  template <int Selector, int ScaleD> \
  static __device__ __forceinline__ void ss(Acc *d, uint64_t a, uint64_t b, uint32_t meta) { \
    asm volatile("wgmma.mma_async.sp.sync.aligned.m64n8k" #K "." #DT "." #A "." #B \
                 " {%0,%1,%2,%3}, %4, %5, %6, %7, %8" SCALES ";" \
                 : CONSTRAINT(d[0]), CONSTRAINT(d[1]), CONSTRAINT(d[2]), CONSTRAINT(d[3]) \
                 : "l"(a), "l"(b), "r"(meta), "n"(Selector), "n"(ScaleD) : "memory"); \
  } \
  template <int Selector, int ScaleD> \
  static __device__ __forceinline__ void rs(Acc *d, const uint32_t *a, uint64_t b, uint32_t meta) { \
    asm volatile("wgmma.mma_async.sp.sync.aligned.m64n8k" #K "." #DT "." #A "." #B \
                 " {%0,%1,%2,%3}, {%4,%5,%6,%7}, %8, %9, %10, %11" SCALES ";" \
                 : CONSTRAINT(d[0]), CONSTRAINT(d[1]), CONSTRAINT(d[2]), CONSTRAINT(d[3]) \
                 : "r"(a[0]), "r"(a[1]), "r"(a[2]), "r"(a[3]), "l"(b), "r"(meta), "n"(Selector), "n"(ScaleD) : "memory"); \
  } \
}

DEFINE_MMA(tf32, tf32, 16, f32, float, "+f", ", 1, 1");
DEFINE_MMA(e4m3, e4m3, 64, f32, float, "+f", ", 1, 1");
DEFINE_MMA(e4m3, e5m2, 64, f32, float, "+f", ", 1, 1");
DEFINE_MMA(e5m2, e4m3, 64, f32, float, "+f", ", 1, 1");
DEFINE_MMA(e5m2, e5m2, 64, f32, float, "+f", ", 1, 1");
DEFINE_MMA(s8, s8, 64, s32, int32_t, "+r", "");
DEFINE_MMA(u8, u8, 64, s32, int32_t, "+r", "");
DEFINE_MMA(s8, u8, 64, s32, int32_t, "+r", "");
DEFINE_MMA(u8, s8, 64, s32, int32_t, "+r", "");
#undef DEFINE_MMA

template <typename Acc>
__device__ __forceinline__ void store(Acc *out, const Acc *d, int row, int lane) {
  out[row * N + 2 * lane] = d[0];
  out[row * N + 2 * lane + 1] = d[1];
  out[(row + 8) * N + 2 * lane] = d[2];
  out[(row + 8) * N + 2 * lane + 1] = d[3];
}

template <Format A, Format B, bool RegisterA, int Selector>
__global__ void sparse_gemm(const Bits<A> *a, const Bits<B> *b, const uint32_t *metadata,
                            typename SparseMma<A, B>::Acc *out) {
  constexpr int K = A == tf32 ? 16 : 64;
  __shared__ __align__(128) Bits<A> shared_a[M * K / 2];
  __shared__ __align__(128) Bits<B> shared_b[N * K];
  const int tid = threadIdx.x, lane = tid % 4;
  const int row = (tid / 32) * 16 + (tid % 32) / 4;
  for (int i = tid; i < N * K; i += Threads)
    shared_b[core_offset<Bits<B>>(i / K, i % K, K)] = b[i];
  if (!RegisterA)
    for (int i = tid; i < M * K / 2; i += Threads)
      shared_a[core_offset<Bits<A>>(i / (K / 2), i % (K / 2), K / 2)] = a[i];
  __syncthreads();

  uint32_t words[4];
  if (RegisterA) {
    const int offset = lane * (4 / sizeof(Bits<A>));
    words[0] = packed_word(a + row * (K / 2) + offset);
    words[1] = packed_word(a + (row + 8) * (K / 2) + offset);
    words[2] = packed_word(a + row * (K / 2) + offset + K / 4);
    words[3] = packed_word(a + (row + 8) * (K / 2) + offset + K / 4);
  }
  const uint64_t da = RegisterA ? 0 : descriptor(shared_a, K / 2);
  const uint64_t db = descriptor(shared_b, K);
  const uint32_t meta = metadata[Selector * Threads + tid];
  typename SparseMma<A, B>::Acc d[4] = {17, 17, 17, 17};
#define RUN_MMA(Scale) \
  asm volatile("wgmma.fence.sync.aligned;" ::: "memory"); \
  if (RegisterA) SparseMma<A, B>::template rs<Selector, Scale>(d, words, db, meta); \
  else SparseMma<A, B>::template ss<Selector, Scale>(d, da, db, meta); \
  asm volatile("wgmma.commit_group.sync.aligned;" ::: "memory"); \
  asm volatile("wgmma.wait_group.sync.aligned 0;" ::: "memory");
  RUN_MMA(0)
  store(out, d, row, lane);
  RUN_MMA(1)
  store(out + M * N, d, row, lane);
#undef RUN_MMA
}

template <Format F> Bits<F> bits(int value) {
  if (F == tf32) {
    const float f = static_cast<float>(value);
    uint32_t result;
    memcpy(&result, &f, sizeof(result));
    return result;
  }
  if (F == e4m3 || F == e5m2) {
    constexpr uint8_t e4m3_bits[] = {0, 0x38, 0x40, 0x44, 0x48};
    constexpr uint8_t e5m2_bits[] = {0, 0x3c, 0x40, 0x42, 0x44};
    const auto *encoding = F == e4m3 ? e4m3_bits : e5m2_bits;
    return encoding[abs(value)] | (value < 0 ? 0x80 : 0);
  }
  return static_cast<uint8_t>(value);
}

template <Format F> int value(int seed) {
  if (F == u8) return 1 + seed % 251;
  if (F == s8) return 1 + seed % 127 - (seed % 2 ? 128 : 0);
  return (1 + seed % 4) * (seed % 7 < 3 ? -1 : 1);
}

template <Format A, Format B, bool RegisterA, int Selector>
bool check(const Bits<A> *a, const Bits<B> *b, const uint32_t *meta, typename SparseMma<A, B>::Acc *out,
           const int *reference, const char *label) {
  sparse_gemm<A, B, RegisterA, Selector><<<1, Threads>>>(a, b, meta, out);
  ASYNC_CHECK(cudaDeviceSynchronize());
  typename SparseMma<A, B>::Acc actual[2 * M * N];
  ASYNC_CHECK(cudaMemcpy(actual, out, sizeof(actual), cudaMemcpyDeviceToHost));
  int mismatches = 0;
  for (int i = 0; i < 2 * M * N; ++i) {
    const int expected = reference[i % (M * N)] * (1 + i / (M * N));
    if (actual[i] != expected && ++mismatches <= 3)
      printf("result[%d]: %.9g expected %d\n", i, double(actual[i]), expected);
  }
  printf("%s %s selector=%d: %d values, %d mismatches\n", label, RegisterA ? "RS" : "SS", Selector,
         2 * M * N, mismatches);
  return mismatches != 0;
}

template <Format A, Format B> int run(const char *label) {
  constexpr int K = A == tf32 ? 16 : 64, chunk_width = A == tf32 ? 2 : 4;
  constexpr int chunks = K / chunk_width;
  const unsigned pairs[] = {0x4, 0x8, 0xc, 0x9, 0xd, 0xe};
  int dense[M][K] = {}, reference[M * N] = {};
  unsigned pattern[M][chunks];
  Bits<A> a[M * K / 2];
  Bits<B> b[N * K];
  for (int row = 0; row < M; ++row)
    for (int group = 0; group < chunks; ++group) {
      const int seed = row * 3 + group * 5 + row * group + row / 8 + group / 4;
      const unsigned code = A == tf32 ? (seed % 2 == 0 ? 0x4 : 0xe) : pairs[seed % 6];
      pattern[row][group] = code;
      for (int j = 0; j < chunk_width / 2; ++j) {
        const int pos = A == tf32 ? (code == 0xe) : ((code >> (2 * j)) & 3);
        const int v = value<A>(row * 11 + group * 7 + row * group + j * 13);
        dense[row][group * chunk_width + pos] = v;
        a[row * (K / 2) + group * (chunk_width / 2) + j] = bits<A>(v);
      }
    }
  for (int col = 0; col < N; ++col)
    for (int k = 0; k < K; ++k) {
      const int v = value<B>(col * 43 + k * 13 + col * k + k / 4);
      b[col * K + k] = bits<B>(v);
      for (int row = 0; row < M; ++row) reference[row * N + col] += dense[row][k] * v;
    }

  // PTX ISA figures 181, 183 and 184 assign TF32 to the selected lane pair and
  // the byte formats to one row and half-K quadrant per lane.
  uint32_t metadata[2][Threads] = {};
  for (int selector = 0; selector < (A == tf32 ? 2 : 1); ++selector)
    for (int tid = 0; tid < Threads; ++tid) {
      const int lane = tid % 4, row = (tid / 32) * 16 + (tid % 32) / 4;
      auto &word = metadata[selector][tid];
      if (A == tf32) {
        for (int j = 0; j < 8; ++j) {
          const unsigned code = pattern[row + 8 * (j / 4)][4 * (lane % 2) + j % 4];
          word |= (lane / 2 == selector ? code : (code == 0x4 ? 0xe : 0x4)) << (4 * j);
        }
      } else {
        for (int j = 0; j < 8; ++j) word |= pattern[row + 8 * (lane % 2)][8 * (lane / 2) + j] << (4 * j);
      }
    }

  Bits<A> *gpu_a;
  Bits<B> *gpu_b;
  uint32_t *gpu_meta;
  typename SparseMma<A, B>::Acc *gpu_out;
  ASYNC_CHECK(cudaMalloc(&gpu_a, sizeof(a)));
  ASYNC_CHECK(cudaMalloc(&gpu_b, sizeof(b)));
  ASYNC_CHECK(cudaMalloc(&gpu_meta, sizeof(metadata)));
  ASYNC_CHECK(cudaMalloc(&gpu_out, 2 * M * N * sizeof(*gpu_out)));
  ASYNC_CHECK(cudaMemcpy(gpu_a, a, sizeof(a), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(gpu_b, b, sizeof(b), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(gpu_meta, metadata, sizeof(metadata), cudaMemcpyHostToDevice));
  int failures = check<A, B, false, 0>(gpu_a, gpu_b, gpu_meta, gpu_out, reference, label);
  failures += check<A, B, true, 0>(gpu_a, gpu_b, gpu_meta, gpu_out, reference, label);
  if (A == tf32) {
    failures += check<A, B, false, (A == tf32 ? 1 : 0)>(gpu_a, gpu_b, gpu_meta, gpu_out, reference, label);
    failures += check<A, B, true, (A == tf32 ? 1 : 0)>(gpu_a, gpu_b, gpu_meta, gpu_out, reference, label);
  }
  ASYNC_CHECK(cudaFree(gpu_a));
  ASYNC_CHECK(cudaFree(gpu_b));
  ASYNC_CHECK(cudaFree(gpu_meta));
  ASYNC_CHECK(cudaFree(gpu_out));
  return failures;
}

#if CUPBOP_SPARSE_DTYPE_MASK & 8
__host__ __device__ static int saturation_b(int col, int k) {
  switch (col % 4) {
    case 0: return k < 16 ? 10 : (k < 32 ? -10 : 0);
    case 1: return k < 32 ? 10 : -10;
    case 2: return 10;
    default: return -10;
  }
}

template <bool RegisterA>
__global__ void sparse_satfinite(int32_t *out) {
  __shared__ __align__(128) uint8_t a[M * 32], b[N * 64];
  const int tid = threadIdx.x, lane = tid % 4;
  const int row = (tid / 32) * 16 + (tid % 32) / 4;
  const bool positive = row < M / 2;
  if (!RegisterA)
    for (int i = tid; i < M * 32; i += Threads)
      a[core_offset<uint8_t>(i / 32, i % 32, 32)] = i / 32 < M / 2 ? 1 : 255;
  for (int i = tid; i < N * 64; i += Threads)
    b[core_offset<uint8_t>(i / 64, i % 64, 64)] = uint8_t(saturation_b(i / 64, i % 64));
  __syncthreads();

  const auto db = descriptor(b, 64);
  const int initial = positive ? INT_MAX - 4 : INT_MIN + 4;
  int32_t d[4] = {initial, initial, initial, initial};
  asm volatile("wgmma.fence.sync.aligned;" ::: "memory");
  if (RegisterA) {
    const uint32_t word = positive ? 0x01010101 : 0xffffffff;
    asm volatile("wgmma.mma_async.sp.sync.aligned.m64n8k64.satfinite.s32.s8.s8 "
                 "{%0,%1,%2,%3}, {%4,%5,%6,%7}, %8, %9, 0, 1;"
                 : "+r"(d[0]), "+r"(d[1]), "+r"(d[2]), "+r"(d[3])
                 : "r"(word), "r"(word), "r"(word), "r"(word), "l"(db), "r"(0x44444444u) : "memory");
  } else {
    asm volatile("wgmma.mma_async.sp.sync.aligned.m64n8k64.satfinite.s32.s8.s8 "
                 "{%0,%1,%2,%3}, %4, %5, %6, 0, 1;"
                 : "+r"(d[0]), "+r"(d[1]), "+r"(d[2]), "+r"(d[3])
                 : "l"(descriptor(a, 32)), "l"(db), "r"(0x44444444u) : "memory");
  }
  asm volatile("wgmma.commit_group.sync.aligned;" ::: "memory");
  asm volatile("wgmma.wait_group.sync.aligned 0;" ::: "memory");
  store(out, d, row, lane);
}

template <bool RegisterA> bool check_satfinite(int32_t *gpu) {
  int32_t actual[M * N];
  sparse_satfinite<RegisterA><<<1, Threads>>>(gpu);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(actual, gpu, sizeof(actual), cudaMemcpyDeviceToHost));
  int mismatches = 0;
  for (int i = 0; i < M * N; ++i) {
    const bool positive = i / N < M / 2;
    int64_t expected = positive ? INT_MAX - 4 : INT_MIN + 4;
    for (int k = 0; k < 64; ++k)
      if ((k & 3) < 2) expected += (positive ? 1 : -1) * saturation_b(i % N, k);
    if (expected > INT_MAX) expected = INT_MAX;
    if (expected < INT_MIN) expected = INT_MIN;
    if (actual[i] != expected && ++mismatches <= 3)
      printf("result[%d]: %d expected %lld\n", i, actual[i], static_cast<long long>(expected));
  }
  printf("S8×S8 satfinite %s: %d values, %d mismatches\n", RegisterA ? "RS" : "SS", M * N, mismatches);
  return mismatches != 0;
}

static int run_satfinite() {
  int32_t *gpu;
  ASYNC_CHECK(cudaMalloc(&gpu, M * N * sizeof(*gpu)));
  int failures = check_satfinite<false>(gpu);
  failures += check_satfinite<true>(gpu);
  ASYNC_CHECK(cudaFree(gpu));
  return failures;
}
#endif

#if CUPBOP_SPARSE_DTYPE_MASK & 32
template <bool FP8> using PackedInput = typename std::conditional<FP8, uint8_t, uint16_t>::type;

template <bool FP8>
__global__ void packed_gemm(const PackedInput<FP8> *a, const PackedInput<FP8> *b, uint16_t *out) {
  using Input = PackedInput<FP8>;
  constexpr int K = FP8 ? 64 : 32;
  __shared__ __align__(128) Input shared_a[M * K / 2], shared_b[N * K];
  const int tid = threadIdx.x, lane = tid % 4;
  const int row = (tid / 32) * 16 + (tid % 32) / 4;
  for (int i = tid; i < M * K / 2; i += Threads)
    shared_a[core_offset<Input>(i / (K / 2), i % (K / 2), K / 2)] = a[i];
  for (int i = tid; i < N * K; i += Threads)
    shared_b[core_offset<Input>(i / K, i % K, K)] = b[i];
  __syncthreads();

  const auto da = descriptor(shared_a, K / 2), db = descriptor(shared_b, K);
  uint32_t low = 0, high = 0;
  const uint32_t meta = 0x44444444u;
  asm volatile("wgmma.fence.sync.aligned;" ::: "memory");
  if (FP8) {
    asm volatile("wgmma.mma_async.sp.sync.aligned.m64n8k64.f16.e4m3.e5m2 {%0,%1}, %2, %3, %4, 0, 0, 1, 1;"
                 : "+r"(low), "+r"(high) : "l"(da), "l"(db), "r"(meta) : "memory");
  } else {
    asm volatile("wgmma.mma_async.sp.sync.aligned.m64n8k32.f16.f16.f16 {%0,%1}, %2, %3, %4, 0, 0, 1, 1, 0, 0;"
                 : "+r"(low), "+r"(high) : "l"(da), "l"(db), "r"(meta) : "memory");
  }
  asm volatile("wgmma.commit_group.sync.aligned;" ::: "memory");
  asm volatile("wgmma.wait_group.sync.aligned 0;" ::: "memory");
  uint16_t result[4] = {uint16_t(low), uint16_t(low >> 16), uint16_t(high), uint16_t(high >> 16)};
  store(out, result, row, lane);
}

static uint16_t half_bits(int value) {
  const __half half = __float2half_rn(static_cast<float>(value));
  uint16_t result;
  memcpy(&result, &half, sizeof(result));
  return result;
}

template <bool FP8> int check_packed() {
  constexpr int K = FP8 ? 64 : 32;
  PackedInput<FP8> a[M * K / 2], b[N * K];
  int dense[M][K] = {}, reference[M * N] = {};
  for (int row = 0; row < M; ++row)
    for (int k = 0; k < K / 2; ++k) {
      const int v = value<e4m3>(row * 17 + k * 3 + row * k);
      a[row * K / 2 + k] = FP8 ? bits<e4m3>(v) : half_bits(v);
      dense[row][4 * (k / 2) + k % 2] = v;
    }
  for (int col = 0; col < N; ++col)
    for (int k = 0; k < K; ++k) {
      const int v = value<e5m2>(col * 31 + k * 13 + col * k + k / 4);
      b[col * K + k] = FP8 ? bits<e5m2>(v) : half_bits(v);
      for (int row = 0; row < M; ++row) reference[row * N + col] += dense[row][k] * v;
    }
  PackedInput<FP8> *gpu_a, *gpu_b;
  uint16_t *gpu_out, actual[M * N];
  ASYNC_CHECK(cudaMalloc(&gpu_a, sizeof(a)));
  ASYNC_CHECK(cudaMalloc(&gpu_b, sizeof(b)));
  ASYNC_CHECK(cudaMalloc(&gpu_out, sizeof(actual)));
  ASYNC_CHECK(cudaMemcpy(gpu_a, a, sizeof(a), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(gpu_b, b, sizeof(b), cudaMemcpyHostToDevice));
  packed_gemm<FP8><<<1, Threads>>>(gpu_a, gpu_b, gpu_out);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(actual, gpu_out, sizeof(actual), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(gpu_a));
  ASYNC_CHECK(cudaFree(gpu_b));
  ASYNC_CHECK(cudaFree(gpu_out));
  int mismatches = 0;
  for (int i = 0; i < M * N; ++i) {
    const uint16_t expected = half_bits(reference[i]);
    if (actual[i] != expected && ++mismatches <= 3)
      printf("result[%d]: 0x%04x expected 0x%04x\n", i, unsigned(actual[i]), unsigned(expected));
  }
  printf("%s→FP16 packed SS: %d values, %d mismatches\n", FP8 ? "E4M3×E5M2" : "FP16×FP16", M * N, mismatches);
  return mismatches != 0;
}
#endif

int main() {
  int failures = 0;
#if CUPBOP_SPARSE_DTYPE_MASK & 1
  failures += run<tf32, tf32>("TF32×TF32");
#endif
#if CUPBOP_SPARSE_DTYPE_MASK & 2
  failures += run<e4m3, e4m3>("E4M3×E4M3");
  failures += run<e4m3, e5m2>("E4M3×E5M2");
  failures += run<e5m2, e4m3>("E5M2×E4M3");
  failures += run<e5m2, e5m2>("E5M2×E5M2");
#endif
#if CUPBOP_SPARSE_DTYPE_MASK & 4
  failures += run<s8, s8>("S8×S8");
  failures += run<u8, u8>("U8×U8");
#endif
#if CUPBOP_SPARSE_DTYPE_MASK & 8
  failures += run_satfinite();
#endif
#if CUPBOP_SPARSE_DTYPE_MASK & 16
  failures += run<s8, u8>("S8×U8");
  failures += run<u8, s8>("U8×S8");
#endif
#if CUPBOP_SPARSE_DTYPE_MASK & 32
  failures += check_packed<false>();
  failures += check_packed<true>();
#endif
  puts(failures ? "FAILED!" : "PASSED!");
  return failures != 0;
}
