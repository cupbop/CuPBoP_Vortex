// sgemm_wgmma_bf16.cu - sgemm_wgmma with bf16 inputs (wgmma ... .f32.bf16.bf16); see sgemm_wgmma.cu
//
// One warpgroup (128 threads) per block computes a 64x64 tile of C = A * B with
// wgmma.mma_async.m64n64k16.f32.bf16.bf16, A (MxK) and B (KxN) staged in shared memory
// in the canonical no-swizzle K-major core-matrix layout that the wgmma descriptors
// describe (8-row x 16-byte core matrices; LBO = next core matrix along K, SBO = next
// 8-row group). Plain loads/stores do the staging; the DXA variant swaps them for
// cp.async / TMA. Requires sm_90a.
//
// Build/run on a GPU: nvcc -arch=sm_90a sgemm_wgmma_bf16.cu -o sgemm_wgmma && ./sgemm_wgmma -n 256
#include <cuda_bf16.h>
#include <cuda_runtime.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define WG_M 64
#define WG_N 64
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

// Canonical no-swizzle K-major layout of a (rows x 16) fp16 tile:
//   core matrix (rg, kg) = rows 8rg..8rg+7, k 8kg..8kg+7, 128 B contiguous (row r at +16r B)
//   LBO (K-adjacent core matrices) = 128 B, SBO (next 8-row group) = 256 B
#define SMEM_LBO_BYTES 128
#define SMEM_SBO_BYTES 256
__device__ __forceinline__ int core_off(int r, int k) { // element offset in the tile
  return (r >> 3) * (SMEM_SBO_BYTES / 2) + (k >> 3) * (SMEM_LBO_BYTES / 2) + (r & 7) * 8 + (k & 7);
}

__device__ __forceinline__ uint32_t smem_u32(const void *p) {
  uint32_t a;
  asm volatile("{ .reg .u64 t; cvta.to.shared.u64 t, %1; cvt.u32.u64 %0, t; }" : "=r"(a) : "l"(p));
  return a;
}
// wgmma shared-memory matrix descriptor (PTX ISA "Matrix Descriptor Format"):
//   [13:0] start address >> 4, [29:16] LBO >> 4, [45:32] SBO >> 4, [51:49] base offset, [63:62] swizzle (0 = none)
__device__ __forceinline__ uint64_t make_desc(const void *smem_ptr) {
  uint64_t d = (uint64_t)((smem_u32(smem_ptr) & 0x3FFFFu) >> 4);
  d |= (uint64_t)(SMEM_LBO_BYTES >> 4) << 16;
  d |= (uint64_t)(SMEM_SBO_BYTES >> 4) << 32;
  return d;
}

// D(64x64,f32) += A(64x16,f16,K-major) * B(16x64,f16,K-major i.e. stored N x K)
__device__ __forceinline__ void wgmma_m64n64k16(float *d, uint64_t desc_a, uint64_t desc_b) {
  asm volatile(
      "{\n"
      ".reg .pred p;\n"
      "setp.ne.b32 p, %34, 0;\n"
      "wgmma.mma_async.sync.aligned.m64n64k16.f32.bf16.bf16 "
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
sgemm_wgmma_bf16_kernel(const __nv_bfloat16 *A, const __nv_bfloat16 *B, float *C, int M, int N, int K) {
  __shared__ __align__(128) __nv_bfloat16 sA[WG_M * WG_K]; // 2 KB, core-matrix layout
  __shared__ __align__(128) __nv_bfloat16 sB[WG_N * WG_K]; // 2 KB, core-matrix layout (B^T: n rows, k cols)
  const int tile_m = blockIdx.y * WG_M, tile_n = blockIdx.x * WG_N;
  const int tid = threadIdx.x;
  float d[WG_ACC];
#pragma unroll
  for (int i = 0; i < WG_ACC; i++) d[i] = 0.f;

  for (int k0 = 0; k0 < K; k0 += WG_K) {
    for (int i = tid; i < WG_M * WG_K; i += WG_THREADS) {
      int m = i / WG_K, k = i % WG_K;
      sA[core_off(m, k)] = A[(size_t)(tile_m + m) * K + k0 + k];
    }
    for (int i = tid; i < WG_N * WG_K; i += WG_THREADS) {
      int n = i / WG_K, k = i % WG_K;
      sB[core_off(n, k)] = B[(size_t)(k0 + k) * N + tile_n + n];
    }
    __syncthreads();
    asm volatile("fence.proxy.async.shared::cta;\n" ::: "memory"); // generic-proxy stores -> async proxy reads
    const uint64_t da = make_desc(sA), db = make_desc(sB);
    asm volatile("wgmma.fence.sync.aligned;\n" ::: "memory");
    wgmma_m64n64k16(d, da, db);
    asm volatile("wgmma.commit_group.sync.aligned;\n" ::: "memory");
    asm volatile("wgmma.wait_group.sync.aligned 0;\n" ::: "memory");
    __syncthreads(); // smem is reused by the next k-step
  }

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

static void gemm_cpu(const __nv_bfloat16 *A, const __nv_bfloat16 *B, float *C, int M, int N, int K) {
  for (int i = 0; i < M; i++)
    for (int j = 0; j < N; j++) {
      float sum = 0.f;
      for (int k = 0; k < K; k++)
        sum += __bfloat162float(A[(size_t)i * K + k]) * __bfloat162float(B[(size_t)k * N + j]);
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
  printf("SGEMM WGMMA BF16 Test: M=%d, N=%d, K=%d\n", M, N, K);
  size_t sizeA = (size_t)M * K * sizeof(__nv_bfloat16), sizeB = (size_t)K * N * sizeof(__nv_bfloat16), sizeC = (size_t)M * N * sizeof(float);
  __nv_bfloat16 *h_A = (__nv_bfloat16 *)malloc(sizeA), *h_B = (__nv_bfloat16 *)malloc(sizeB);
  float *h_C = (float *)malloc(sizeC), *h_C_ref = (float *)malloc(sizeC);
  srand(42);
  for (size_t i = 0; i < (size_t)M * K; i++) h_A[i] = __float2bfloat16((float)(rand() % 17 - 8) / 8.0f);
  for (size_t i = 0; i < (size_t)K * N; i++) h_B[i] = __float2bfloat16((float)(rand() % 17 - 8) / 8.0f);
  gemm_cpu(h_A, h_B, h_C_ref, M, N, K);

  __nv_bfloat16 *d_A, *d_B; float *d_C;
  CUDA_CHECK(cudaMalloc(&d_A, sizeA));
  CUDA_CHECK(cudaMalloc(&d_B, sizeB));
  CUDA_CHECK(cudaMalloc(&d_C, sizeC));
  CUDA_CHECK(cudaMemcpy(d_A, h_A, sizeA, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_B, h_B, sizeB, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemset(d_C, 0, sizeC));
  dim3 grid(N / WG_N, M / WG_M);
  dim3 block(WG_THREADS, 1);
  sgemm_wgmma_bf16_kernel<<<grid, block>>>(d_A, d_B, d_C, M, N, K);
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
