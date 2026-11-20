// sgemm_wgmma.cu - Hopper warpgroup GEMM for CuPBoP -> Vortex (TCU + DXA) lowering
//
// One warpgroup (128 threads) per block computes a 64x64 tile of C = A * B with
// wgmma.mma_async.m64n64k16.f32.f16.f16, A (MxK) and B (KxN) staged in shared memory
// in the canonical no-swizzle K-major core-matrix layout that the wgmma descriptors
// describe (8-row x 16-byte core matrices). The test variants use swizzled layouts,
// including two stages populated by 128B-swizzled TMA. Requires sm_90a.
//
// Build/run on a GPU: nvcc -arch=sm_90a sgemm_wgmma.cu -o sgemm_wgmma && ./sgemm_wgmma -n 256
#include <cuda_fp16.h>
#include <cuda_runtime.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef CUPBOP_HOPPER_TMA_PIPELINE
#include <cuda.h>
#include "../async_common.h"
#include <vector>
#endif

#define WG_M 64
#ifndef CUPBOP_WGMMA_N
#define CUPBOP_WGMMA_N 64
#endif
#ifndef CUPBOP_WGMMA_TRANS_A
#define CUPBOP_WGMMA_TRANS_A 0
#endif
#ifndef CUPBOP_WGMMA_TRANS_B
#define CUPBOP_WGMMA_TRANS_B 0
#endif
#define WG_N CUPBOP_WGMMA_N
#define WG_K 16
#define WG_THREADS 128
#define WG_ACC (WG_N / 2) // fp32 accumulators per thread for m64n64

#define CUDA_CHECK(_expr)                                                      \
  do {                                                                         \
    cudaError_t _err = (_expr);                                                \
    if (_err != cudaSuccess) {                                                 \
      fprintf(stderr, "CUDA Error: '%s' returned %d (%s)!\n", #_expr, (int)_err, \
              cudaGetErrorString(_err));                                       \
      exit(1);                                                                 \
    }                                                                          \
  } while (0)

#ifndef CUPBOP_WGMMA_SWIZZLE
#define CUPBOP_WGMMA_SWIZZLE 0
#endif
#ifndef CUPBOP_WGMMA_SWIZZLE_PHASE
#define CUPBOP_WGMMA_SWIZZLE_PHASE 0
#endif

#if defined(CUPBOP_HOPPER_TMA_PIPELINE) && CUPBOP_WGMMA_SWIZZLE != 128
#error The TMA pipeline test uses 128B swizzled tensor maps
#endif

#if CUPBOP_WGMMA_SWIZZLE
#define WG_SMEM_ALIGNMENT 1024
#define WG_STORAGE_K (CUPBOP_WGMMA_SWIZZLE / sizeof(half))
#define SMEM_LBO_BYTES 16
#define SMEM_SBO_BYTES (8 * CUPBOP_WGMMA_SWIZZLE)
__device__ __forceinline__ int core_off(int r, int k) {
  const unsigned byte = r * CUPBOP_WGMMA_SWIZZLE + k * sizeof(half);
  const unsigned mask = CUPBOP_WGMMA_SWIZZLE / 16 - 1;
  return (byte ^ (((byte >> 7) & mask) << 4)) / sizeof(half);
}
#else
#define WG_SMEM_ALIGNMENT 128
#define WG_STORAGE_K WG_K
#define SMEM_LBO_BYTES 128
#define SMEM_SBO_BYTES 256
__device__ __forceinline__ int core_off(int r, int k) { // element offset in the tile
  return (r >> 3) * (SMEM_SBO_BYTES / 2) + (k >> 3) * (SMEM_LBO_BYTES / 2) + (r & 7) * 8 + (k & 7);
}
#endif

#define WG_STR_IMPL(x) #x
#define WG_STR(x) WG_STR_IMPL(x)

static __device__ constexpr int matrix_storage(int rows, bool mn_major) {
#if CUPBOP_WGMMA_SWIZZLE
  if (mn_major) {
    constexpr int atom_rows = CUPBOP_WGMMA_SWIZZLE / sizeof(half);
    return ((rows + atom_rows - 1) / atom_rows) * atom_rows * WG_K;
  }
#endif
  return rows * WG_STORAGE_K;
}

__device__ __forceinline__ int matrix_off(int r, int k, int rows, bool mn_major) {
  if (!mn_major) return core_off(r, k);
#if CUPBOP_WGMMA_SWIZZLE
  constexpr int width = CUPBOP_WGMMA_SWIZZLE;
  constexpr int atom_rows = width / sizeof(half);
  const unsigned strips = (rows + atom_rows - 1) / atom_rows;
  const unsigned byte = ((k / 8) * strips + r / atom_rows) * 8 * width +
                        (k % 8) * width + (r % atom_rows) * sizeof(half);
  return (byte ^ (((byte >> 7) & (width / 16 - 1)) << 4)) / sizeof(half);
#else
  return ((k / 8) * (rows / 8) + r / 8) * 64 + (k % 8) * 8 + r % 8;
#endif
}

#ifndef CUPBOP_HOPPER_TMA_PIPELINE
__device__ __forceinline__ uint32_t smem_u32(const void *p) {
  uint32_t a;
  asm volatile("{ .reg .u64 t; cvta.to.shared.u64 t, %1; cvt.u32.u64 %0, t; }" : "=r"(a) : "l"(p));
  return a;
}
#endif
// wgmma shared-memory matrix descriptor (PTX ISA "Matrix Descriptor Format"):
//   [13:0] start address >> 4, [29:16] LBO >> 4, [45:32] SBO >> 4, [51:49] base offset, [63:62] swizzle (0 = none)
__device__ __forceinline__ uint64_t make_desc(const void *smem_ptr, int rows, bool mn_major) {
  const uint32_t addr = smem_u32(smem_ptr);
  uint64_t d = (uint64_t)((addr & 0x3FFFFu) >> 4);
  uint32_t lbo = SMEM_LBO_BYTES, sbo = SMEM_SBO_BYTES;
  if (mn_major) {
#if CUPBOP_WGMMA_SWIZZLE
    lbo = 8 * CUPBOP_WGMMA_SWIZZLE;
    sbo = matrix_storage(rows, true) * sizeof(half) / 2;
#else
    lbo = (rows / 8) * 128;
    sbo = 128;
#endif
  }
  d |= (uint64_t)(lbo >> 4) << 16;
  d |= (uint64_t)(sbo >> 4) << 32;
#if CUPBOP_WGMMA_SWIZZLE
  d |= (uint64_t)((addr >> 7) & 7) << 49;
  d |= (CUPBOP_WGMMA_SWIZZLE == 128 ? 1ull : CUPBOP_WGMMA_SWIZZLE == 64 ? 2ull : 3ull) << 62;
#endif
  return d;
}

__device__ __forceinline__ void wgmma_tile(float *d, uint64_t desc_a, uint64_t desc_b) {
#if WG_N == 8
  asm volatile(
      "{ .reg .pred p; setp.ne.b32 p, %6, 0; "
      "wgmma.mma_async.sync.aligned.m64n8k16.f32.f16.f16 {%0,%1,%2,%3}, %4, %5, p, 1, 1, "
      WG_STR(CUPBOP_WGMMA_TRANS_A) ", " WG_STR(CUPBOP_WGMMA_TRANS_B) "; }"
      : "+f"(d[0]), "+f"(d[1]), "+f"(d[2]), "+f"(d[3])
      : "l"(desc_a), "l"(desc_b), "r"(1));
#elif WG_N == 24
  asm volatile(
      "{ .reg .pred p; setp.ne.b32 p, %14, 0; "
      "wgmma.mma_async.sync.aligned.m64n24k16.f32.f16.f16 {%0,%1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11}, "
      "%12, %13, p, 1, 1, " WG_STR(CUPBOP_WGMMA_TRANS_A) ", " WG_STR(CUPBOP_WGMMA_TRANS_B) "; }"
      : "+f"(d[0]), "+f"(d[1]), "+f"(d[2]), "+f"(d[3]), "+f"(d[4]), "+f"(d[5]),
        "+f"(d[6]), "+f"(d[7]), "+f"(d[8]), "+f"(d[9]), "+f"(d[10]), "+f"(d[11])
      : "l"(desc_a), "l"(desc_b), "r"(1));
#else
  static_assert(WG_N == 64);
  asm volatile(
      "{\n"
      ".reg .pred p;\n"
      "setp.ne.b32 p, %34, 0;\n"
      "wgmma.mma_async.sync.aligned.m64n64k16.f32.f16.f16 "
      "{%0, %1, %2, %3, %4, %5, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, "
      "%16, %17, %18, %19, %20, %21, %22, %23, %24, %25, %26, %27, %28, %29, %30, %31}, "
      "%32, %33, p, 1, 1, " WG_STR(CUPBOP_WGMMA_TRANS_A) ", " WG_STR(CUPBOP_WGMMA_TRANS_B) ";\n"
      "}\n"
      : "+f"(d[0]), "+f"(d[1]), "+f"(d[2]), "+f"(d[3]), "+f"(d[4]), "+f"(d[5]), "+f"(d[6]), "+f"(d[7]),
        "+f"(d[8]), "+f"(d[9]), "+f"(d[10]), "+f"(d[11]), "+f"(d[12]), "+f"(d[13]), "+f"(d[14]), "+f"(d[15]),
        "+f"(d[16]), "+f"(d[17]), "+f"(d[18]), "+f"(d[19]), "+f"(d[20]), "+f"(d[21]), "+f"(d[22]), "+f"(d[23]),
        "+f"(d[24]), "+f"(d[25]), "+f"(d[26]), "+f"(d[27]), "+f"(d[28]), "+f"(d[29]), "+f"(d[30]), "+f"(d[31])
      : "l"(desc_a), "l"(desc_b), "r"(1));
#endif
}

__device__ __forceinline__ void accumulate_tile(float *d, const half *a, const half *b) {
  const uint64_t da = make_desc(a, WG_M, CUPBOP_WGMMA_TRANS_A), db = make_desc(b, WG_N, CUPBOP_WGMMA_TRANS_B);
  asm volatile("wgmma.fence.sync.aligned;\n" ::: "memory");
  wgmma_tile(d, da, db);
  asm volatile("wgmma.commit_group.sync.aligned;\n" ::: "memory");
  asm volatile("wgmma.wait_group.sync.aligned 0;\n" ::: "memory");
}

__device__ __forceinline__ void store_tile(float *C, int N, const float *d) {
  const int tile_m = blockIdx.y * WG_M, tile_n = blockIdx.x * WG_N;
  const int tid = threadIdx.x;
  // accumulator fragment: warp w owns rows 16w..16w+15; for each 8-column group j:
  //   d[4j+0] = (16w+g, 8j+2t)  d[4j+1] = (16w+g, 8j+2t+1)  d[4j+2] = (16w+g+8, 8j+2t)  d[4j+3] = (16w+g+8, 8j+2t+1)
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

#ifdef CUPBOP_HOPPER_TMA_PIPELINE
__device__ __forceinline__ void load_tile(half *dst, const CUtensorMap *map, uint64_t *bar, int row, int stage) {
  asm volatile("cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes "
               "[%0], [%1, {0, %3, %4}], [%2];"
               :: "r"(smem_u32(dst)), "l"(map), "r"(smem_u32(bar)), "r"(row), "r"(stage) : "memory");
}

__device__ __forceinline__ void load_pair(half *a, half *b, const CUtensorMap *a_map, const CUtensorMap *b_map,
                                         uint64_t *bar, int stage) {
  mbar_arrive_expect_tx(bar, (WG_M + WG_N) * WG_STORAGE_K * sizeof(half));
  load_tile(a, a_map, bar, blockIdx.y * WG_M, stage);
  load_tile(b, b_map, bar, blockIdx.x * WG_N, stage);
}

__global__ void __launch_bounds__(WG_THREADS)
sgemm_wgmma_kernel(const __grid_constant__ CUtensorMap a_map, const __grid_constant__ CUtensorMap b_map,
                   float *C, int N, int K) {
  __shared__ __align__(WG_SMEM_ALIGNMENT) half sA[2][WG_M * WG_STORAGE_K];
  __shared__ __align__(WG_SMEM_ALIGNMENT) half sB[2][WG_N * WG_STORAGE_K];
  __shared__ __align__(8) uint64_t full[2];
  const int tiles = K / WG_K;
  const bool producer = threadIdx.x == 0;
  if (producer) {
    mbar_init(&full[0], 1);
    mbar_init(&full[1], 1);
    mbar_init_fence();
  }
  __syncthreads();
  if (producer)
    load_pair(sA[0], sB[0], &a_map, &b_map, &full[0], 0);
  __syncthreads();
  if (producer && tiles > 1)
    load_pair(sA[1], sB[1], &a_map, &b_map, &full[1], 1);
  float d[WG_ACC] = {};
  for (int tile = 0; tile < tiles; ++tile) {
    const int slot = tile & 1;
    mbar_wait(&full[slot], (tile >> 1) & 1);
    accumulate_tile(d, sA[slot], sB[slot]);
    __syncthreads();
    if (producer && tile + 2 < tiles)
      load_pair(sA[slot], sB[slot], &a_map, &b_map, &full[slot], tile + 2);
  }
  store_tile(C, N, d);
}

static bool encode_map(CUtensorMap *map, void *device, int rows, int stages) {
  const cuuint64_t dims[3] = {WG_STORAGE_K, (cuuint64_t)rows, (cuuint64_t)stages};
  const cuuint64_t strides[2] = {WG_STORAGE_K * sizeof(half), WG_STORAGE_K * sizeof(half) * rows};
  const cuuint32_t box[3] = {WG_STORAGE_K, WG_M, 1};
  const cuuint32_t element_strides[3] = {1, 1, 1};
  return cuTensorMapEncodeTiled(map, CU_TENSOR_MAP_DATA_TYPE_FLOAT16, 3, device, dims, strides, box,
      element_strides, CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_128B,
      CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE) == CUDA_SUCCESS;
}
#else
__global__ void __launch_bounds__(WG_THREADS)
sgemm_wgmma_kernel(const half *A, const half *B, float *C, int M, int N, int K) {
  constexpr unsigned a_pad = 64 * CUPBOP_WGMMA_SWIZZLE_PHASE;
  constexpr unsigned b_pad = 64 * (CUPBOP_WGMMA_SWIZZLE_PHASE ? ((CUPBOP_WGMMA_SWIZZLE_PHASE + 1) & 7) : 0);
  __shared__ __align__(WG_SMEM_ALIGNMENT) half a_storage[matrix_storage(WG_M, CUPBOP_WGMMA_TRANS_A) + a_pad];
  __shared__ __align__(WG_SMEM_ALIGNMENT) half b_storage[matrix_storage(WG_N, CUPBOP_WGMMA_TRANS_B) + b_pad];
  half *sA = a_storage + a_pad;
  half *sB = b_storage + b_pad;
  const int tile_m = blockIdx.y * WG_M, tile_n = blockIdx.x * WG_N;
  const int tid = threadIdx.x;
  float d[WG_ACC] = {};
  for (int k0 = 0; k0 < K; k0 += WG_K) {
    for (int i = tid; i < WG_M * WG_K; i += WG_THREADS) {
      int m = i / WG_K, k = i % WG_K;
      sA[matrix_off(m, k, WG_M, CUPBOP_WGMMA_TRANS_A)] = A[(size_t)(tile_m + m) * K + k0 + k];
    }
    for (int i = tid; i < WG_N * WG_K; i += WG_THREADS) {
      int n = i / WG_K, k = i % WG_K;
      sB[matrix_off(n, k, WG_N, CUPBOP_WGMMA_TRANS_B)] = B[(size_t)(k0 + k) * N + tile_n + n];
    }
    __syncthreads();
    asm volatile("fence.proxy.async.shared::cta;\n" ::: "memory");
    accumulate_tile(d, sA, sB);
    __syncthreads();
  }
  store_tile(C, N, d);
}
#endif

static void gemm_cpu(const half *A, const half *B, float *C, int M, int N, int K) {
  for (int i = 0; i < M; i++)
    for (int j = 0; j < N; j++) {
      float sum = 0.f;
      for (int k = 0; k < K; k++)
        sum += __half2float(A[(size_t)i * K + k]) * __half2float(B[(size_t)k * N + j]);
      C[(size_t)i * N + j] = sum;
    }
}

int main(int argc, char **argv) {
  int M = WG_M, N = WG_N, K = WG_K;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-n") == 0 && i + 1 < argc) {
      int n = atoi(argv[++i]);
      if (n > 0 && n % WG_M == 0 && n % WG_N == 0) {
        M = N = K = n;
      } else {
        fprintf(stderr, "Size must be a positive multiple of %d and %d\n", WG_M, WG_N);
        return 1;
      }
    }
  }
  printf("SGEMM WGMMA Test: M=%d, N=%d, K=%d\n", M, N, K);
  size_t sizeA = (size_t)M * K * sizeof(half), sizeB = (size_t)K * N * sizeof(half), sizeC = (size_t)M * N * sizeof(float);
  half *h_A = (half *)malloc(sizeA), *h_B = (half *)malloc(sizeB);
  float *h_C = (float *)malloc(sizeC), *h_C_ref = (float *)malloc(sizeC);
  srand(42);
  for (size_t i = 0; i < (size_t)M * K; i++) h_A[i] = __float2half((float)(rand() % 17 - 8) / 8.0f);
  for (size_t i = 0; i < (size_t)K * N; i++) h_B[i] = __float2half((float)(rand() % 17 - 8) / 8.0f);
  gemm_cpu(h_A, h_B, h_C_ref, M, N, K);

  const half *upload_A = h_A, *upload_B = h_B;
#ifdef CUPBOP_HOPPER_TMA_PIPELINE
  const int stages = K / WG_K;
  std::vector<half> packed_A((size_t)stages * M * WG_STORAGE_K, __float2half(0.f));
  std::vector<half> packed_B((size_t)stages * N * WG_STORAGE_K, __float2half(0.f));
  for (int k = 0; k < K; ++k) {
    const int stage = k / WG_K, col = k % WG_K;
    for (int m = 0; m < M; ++m)
      packed_A[((size_t)stage * M + m) * WG_STORAGE_K + col] = h_A[(size_t)m * K + k];
    for (int n = 0; n < N; ++n)
      packed_B[((size_t)stage * N + n) * WG_STORAGE_K + col] = h_B[(size_t)k * N + n];
  }
  upload_A = packed_A.data();
  upload_B = packed_B.data();
  sizeA = packed_A.size() * sizeof(half);
  sizeB = packed_B.size() * sizeof(half);
#endif

  half *d_A, *d_B; float *d_C;
  CUDA_CHECK(cudaMalloc(&d_A, sizeA));
  CUDA_CHECK(cudaMalloc(&d_B, sizeB));
  CUDA_CHECK(cudaMalloc(&d_C, sizeC));
  CUDA_CHECK(cudaMemcpy(d_A, upload_A, sizeA, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_B, upload_B, sizeB, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemset(d_C, 0, sizeC));
  dim3 grid(N / WG_N, M / WG_M);
  dim3 block(WG_THREADS, 1);
#ifdef CUPBOP_HOPPER_TMA_PIPELINE
  CUtensorMap a_map, b_map;
  if (!encode_map(&a_map, d_A, M, stages) || !encode_map(&b_map, d_B, N, stages)) {
    fprintf(stderr, "tensor map encoding failed\n");
    return 1;
  }
  sgemm_wgmma_kernel<<<grid, block>>>(a_map, b_map, d_C, N, K);
#else
  sgemm_wgmma_kernel<<<grid, block>>>(d_A, d_B, d_C, M, N, K);
#endif
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  CUDA_CHECK(cudaMemcpy(h_C, d_C, sizeC, cudaMemcpyDeviceToHost));

  int errors = 0;
  for (int i = 0; i < M * N; i++) {
    if (h_C[i] != h_C_ref[i]) {
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
