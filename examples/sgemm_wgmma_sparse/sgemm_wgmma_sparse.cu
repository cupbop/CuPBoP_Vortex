#include <cuda_bf16.h>
#include <cuda_fp16.h>
#include <cuda_runtime.h>

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>

constexpr int M = 64, K = 32, MaxN = 24, Threads = 128;
#ifndef CUPBOP_SPARSE_WGMMA_SWIZZLE
#define CUPBOP_SPARSE_WGMMA_SWIZZLE 0
#endif
constexpr int BSwizzle = CUPBOP_SPARSE_WGMMA_SWIZZLE;
static_assert(BSwizzle == 0 || BSwizzle == 32 || BSwizzle == 64 || BSwizzle == 128, "unsupported B swizzle");
constexpr int BPhase = BSwizzle ? 3 : 0;
constexpr int BPatternPhase = BSwizzle ? 2 : 0;
constexpr int BAtomBytes = BSwizzle ? BSwizzle : 2 * K;
constexpr int BStride = 8 * (BSwizzle > 2 * K ? BSwizzle : 2 * K);
constexpr int BLeading = BSwizzle == 32 ? 8 * BAtomBytes : 16;

#define CUDA_CHECK(call) do { \
  cudaError_t error = (call); \
  if (error != cudaSuccess) { \
    fprintf(stderr, "%s failed (%d): %s\n", #call, int(error), cudaGetErrorString(error)); \
    exit(1); \
  } \
} while (0)

__device__ __forceinline__ int core_offset(int row, int k, int width) {
  return (row / 8) * (8 * width) + (k / 8) * 64 + (row % 8) * 8 + (k % 8);
}

__device__ __forceinline__ uint64_t descriptor(const void *p, int width) {
  const auto address = static_cast<uint32_t>(__cvta_generic_to_shared(p));
  return ((address & 0x3ffffu) >> 4) | (8ull << 16) | (uint64_t(width) << 32);
}

__device__ __forceinline__ int b_offset(int col, int k) {
  if (!BSwizzle) return core_offset(col, k, K);
  const unsigned byte = (col / 8) * BStride + (2 * k / BAtomBytes) * BLeading
                        + (col % 8) * BAtomBytes + (2 * k) % BAtomBytes;
  return (byte ^ ((((byte >> 7) + BPhase - BPatternPhase) & (BAtomBytes / 16 - 1)) << 4)) / 2;
}

__device__ __forceinline__ uint64_t b_descriptor(const void *p) {
  if (!BSwizzle) return descriptor(p, K);
  constexpr uint64_t mode = BSwizzle == 128 ? 1 : BSwizzle == 64 ? 2 : 3;
  const auto address = static_cast<uint32_t>(__cvta_generic_to_shared(p));
  return ((address & 0x3ffffu) >> 4) | (uint64_t(BLeading / 16) << 16) | (uint64_t(BStride / 16) << 32)
         | (uint64_t(BPatternPhase) << 49) | (mode << 62);
}

#define D8 "{%0,%1,%2,%3}"
#define D24 "{%0,%1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11}"
#define OUT8(d) "+f"(d[0]), "+f"(d[1]), "+f"(d[2]), "+f"(d[3])
#define OUT24(d) OUT8(d), "+f"(d[4]), "+f"(d[5]), "+f"(d[6]), "+f"(d[7]), \
                 "+f"(d[8]), "+f"(d[9]), "+f"(d[10]), "+f"(d[11])
#define SS8 "%4, %5, %6, %7, %8, %9, %10, 0, 0;"
#define SS24 "%12, %13, %14, %15, %16, %17, %18, 0, 0;"
#define RS8 "{%4,%5,%6,%7}, %8, %9, %10, %11, %12, %13, 0;"
#define RS24 "{%12,%13,%14,%15}, %16, %17, %18, %19, %20, %21, 0;"

template <int N, bool BF16> struct SparseMma;

#define SPARSE_MMA(N, BF16, TYPE) \
template <> struct SparseMma<N, BF16> { \
  template <int Selector, int ScaleD, int ScaleA, int ScaleB> \
  static __device__ __forceinline__ void ss(float *d, uint64_t a, uint64_t b, uint32_t meta) { \
    asm volatile("wgmma.mma_async.sp.sync.aligned.m64n" #N "k32.f32." TYPE " " D##N ", " SS##N \
                 : OUT##N(d) : "l"(a), "l"(b), "r"(meta), "n"(Selector), "n"(ScaleD), \
                                "n"(ScaleA), "n"(ScaleB) : "memory"); \
  } \
  template <int Selector, int ScaleD, int ScaleA, int ScaleB> \
  static __device__ __forceinline__ void rs(float *d, const uint32_t *a, uint64_t b, uint32_t meta) { \
    asm volatile("wgmma.mma_async.sp.sync.aligned.m64n" #N "k32.f32." TYPE " " D##N ", " RS##N \
                 : OUT##N(d) : "r"(a[0]), "r"(a[1]), "r"(a[2]), "r"(a[3]), "l"(b), "r"(meta), \
                                "n"(Selector), "n"(ScaleD), "n"(ScaleA), "n"(ScaleB) : "memory"); \
  } \
}

SPARSE_MMA(8, false, "f16.f16");
SPARSE_MMA(24, false, "f16.f16");
SPARSE_MMA(8, true, "bf16.bf16");
SPARSE_MMA(24, true, "bf16.bf16");

__device__ __forceinline__ uint32_t packed_pair(const uint16_t *row, int k) {
  return uint32_t(row[k]) | (uint32_t(row[k + 1]) << 16);
}

template <int N>
__device__ __forceinline__ void store_fragment(float *out, const float *values, int row, int lane) {
  for (int j = 0; j < N / 8; ++j) {
    const int col = j * 8 + lane * 2;
    out[row * N + col] = values[4 * j];
    out[row * N + col + 1] = values[4 * j + 1];
    out[(row + 8) * N + col] = values[4 * j + 2];
    out[(row + 8) * N + col + 1] = values[4 * j + 3];
  }
}

template <int N, bool BF16, bool RegisterA, int Selector>
__global__ void sparse_gemm(const uint16_t *a, const uint16_t *b, const uint32_t *metadata, float *out) {
  __shared__ __align__(128) uint16_t shared_a[M * K / 2];
  __shared__ __align__(1024) uint16_t storage_b[(N / 8) * BStride / 2 + 64 * BPhase];
  uint16_t *shared_b = storage_b + 64 * BPhase;
  const int tid = threadIdx.x;
  for (int i = tid; i < N * K; i += Threads)
    shared_b[b_offset(i / K, i % K)] = b[i];
  if (!RegisterA)
    for (int i = tid; i < M * K / 2; i += Threads)
      shared_a[core_offset(i / (K / 2), i % (K / 2), K / 2)] = a[i];
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  __syncthreads();
  const int row = (tid / 32) * 16 + (tid % 32) / 4;
  const int lane = tid % 4;
  const uint64_t da = RegisterA ? 0 : descriptor(shared_a, K / 2);
  const uint64_t db = b_descriptor(shared_b);
  const uint32_t meta = metadata[Selector * Threads + tid];
  uint32_t registers[4];
  if (RegisterA) {
    registers[0] = packed_pair(a + row * (K / 2), lane * 2);
    registers[1] = packed_pair(a + (row + 8) * (K / 2), lane * 2);
    registers[2] = packed_pair(a + row * (K / 2), lane * 2 + 8);
    registers[3] = packed_pair(a + (row + 8) * (K / 2), lane * 2 + 8);
  }
  float d[N / 2];
  for (int i = 0; i < N / 2; ++i) d[i] = 37.0f;
  asm volatile("wgmma.fence.sync.aligned;" ::: "memory");
  if (RegisterA)
    SparseMma<N, BF16>::template rs<Selector, 0, -1, 1>(d, registers, db, meta);
  else
    SparseMma<N, BF16>::template ss<Selector, 0, -1, 1>(d, da, db, meta);
  asm volatile("wgmma.commit_group.sync.aligned;" ::: "memory");
  asm volatile("wgmma.wait_group.sync.aligned 0;" ::: "memory");
  store_fragment<N>(out, d, row, lane);
  asm volatile("wgmma.fence.sync.aligned;" ::: "memory");
  if (RegisterA)
    SparseMma<N, BF16>::template rs<Selector, 1, 1, -1>(d, registers, db, meta);
  else
    SparseMma<N, BF16>::template ss<Selector, 1, 1, -1>(d, da, db, meta);
  asm volatile("wgmma.commit_group.sync.aligned;" ::: "memory");
  asm volatile("wgmma.wait_group.sync.aligned 0;" ::: "memory");
  store_fragment<N>(out + M * N, d, row, lane);
}

template <int N, bool BF16, bool RegisterA, int Selector>
bool run_case(const uint16_t *a, const uint16_t *b, const uint32_t *metadata, float *output, const int *reference) {
  sparse_gemm<N, BF16, RegisterA, Selector><<<1, Threads>>>(a, b, metadata, output);
  CUDA_CHECK(cudaDeviceSynchronize());
  float result[2 * M * N];
  CUDA_CHECK(cudaMemcpy(result, output, sizeof(result), cudaMemcpyDeviceToHost));
  unsigned errors = 0;
  for (int pass = 0; pass < 2; ++pass)
    for (int row = 0; row < M; ++row)
      for (int col = 0; col < N; ++col) {
        const int expected = -(pass + 1) * reference[row * MaxN + col];
        const float got = result[(pass * M + row) * N + col];
        if (got != expected && ++errors <= 4)
          printf("Mismatch pass=%d [%d,%d]: got %.6g expected %d\n", pass, row, col, got, expected);
      }
  printf("%s %s N%d selector=%d: %d values, %u mismatches\n", BF16 ? "BF16" : "FP16",
         RegisterA ? "RS" : "SS", N, Selector, 2 * M * N, errors);
  return errors == 0;
}

template <typename T>
uint16_t bits(int value) {
  const T converted = T(float(value));
  static_assert(sizeof(T) == sizeof(uint16_t), "expected a 16-bit CUDA operand");
  uint16_t result;
  memcpy(&result, &converted, sizeof(result));
  return result;
}

int main() {
  int dense_a[M][K] = {}, compressed_a[M][K / 2], b[MaxN][K], reference[M * MaxN] = {};
  unsigned pattern[M][K / 4];
  const unsigned pairs[] = {0x4, 0x8, 0xc, 0x9, 0xd, 0xe};
  for (int row = 0; row < M; ++row)
    for (int group = 0; group < K / 4; ++group) {
      const unsigned code = pairs[(row * 3 + group * 5 + row * group) % 6];
      pattern[row][group] = code;
      for (int j = 0; j < 2; ++j) {
        int v = (row * 11 + group * 3 + row * group + j * 4) % 7 - 3;
        if (v == 0) v = (row % 2) ? 1 : -1;
        compressed_a[row][2 * group + j] = v;
        dense_a[row][4 * group + ((code >> (2 * j)) & 3)] = v;
      }
    }
  for (int col = 0; col < MaxN; ++col)
    for (int k = 0; k < K; ++k) {
      b[col][k] = (col * 13 + k * 7 + col * k * 3) % 11 - 5;
      for (int row = 0; row < M; ++row) reference[row * MaxN + col] += dense_a[row][k] * b[col][k];
    }
  uint32_t metadata[2][Threads];
  for (int selector = 0; selector < 2; ++selector)
    for (int tid = 0; tid < Threads; ++tid) {
      const int lane = tid % 4;
      const int row = (tid / 32) * 16 + (tid % 32) / 4;
      uint32_t word = 0;
      for (int group = 0; group < 4; ++group) {
        const int chunk = 4 * (lane % 2) + group;
        const bool selected = lane / 2 == selector;
        word |= (selected ? pattern[row][chunk] : (pattern[row][chunk] == 0x4 ? 0xe : 0x4)) << (group * 4);
        word |= (selected ? pattern[row + 8][chunk] : (pattern[row + 8][chunk] == 0xe ? 0x4 : 0xe)) << (16 + group * 4);
      }
      metadata[selector][tid] = word;
    }
  uint16_t *a_dev, *b_dev;
  uint32_t *metadata_dev;
  float *output;
  CUDA_CHECK(cudaMalloc(&a_dev, M * (K / 2) * sizeof(uint16_t)));
  CUDA_CHECK(cudaMalloc(&b_dev, MaxN * K * sizeof(uint16_t)));
  CUDA_CHECK(cudaMalloc(&metadata_dev, sizeof(metadata)));
  CUDA_CHECK(cudaMalloc(&output, 2 * M * MaxN * sizeof(float)));
  CUDA_CHECK(cudaMemcpy(metadata_dev, metadata, sizeof(metadata), cudaMemcpyHostToDevice));
  bool pass = true;
  for (int bf16 = 0; bf16 < 2; ++bf16) {
    uint16_t a_bits[M][K / 2], b_bits[MaxN][K];
    for (int row = 0; row < M; ++row)
      for (int k = 0; k < K / 2; ++k)
        a_bits[row][k] = bf16 ? bits<__nv_bfloat16>(compressed_a[row][k]) : bits<__half>(compressed_a[row][k]);
    for (int col = 0; col < MaxN; ++col)
      for (int k = 0; k < K; ++k)
        b_bits[col][k] = bf16 ? bits<__nv_bfloat16>(b[col][k]) : bits<__half>(b[col][k]);
    CUDA_CHECK(cudaMemcpy(a_dev, a_bits, sizeof(a_bits), cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(b_dev, b_bits, sizeof(b_bits), cudaMemcpyHostToDevice));
#define RUN(N, BF16, RS) \
    pass &= run_case<N, BF16, RS, 0>(a_dev, b_dev, metadata_dev, output, reference); \
    pass &= run_case<N, BF16, RS, 1>(a_dev, b_dev, metadata_dev, output, reference)
    if (bf16) {
      RUN(8, true, false);
      RUN(8, true, true);
      RUN(24, true, false);
      RUN(24, true, true);
    } else {
      RUN(8, false, false);
      RUN(8, false, true);
      RUN(24, false, false);
      RUN(24, false, true);
    }
#undef RUN
  }
  CUDA_CHECK(cudaFree(a_dev));
  CUDA_CHECK(cudaFree(b_dev));
  CUDA_CHECK(cudaFree(metadata_dev));
  CUDA_CHECK(cudaFree(output));
  printf("%s\n", pass ? "PASSED! 16 sparse warpgroup cases" : "FAILED!");
  return pass ? 0 : 1;
}
