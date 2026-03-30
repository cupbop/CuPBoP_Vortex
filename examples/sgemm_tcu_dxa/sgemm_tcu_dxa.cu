// sgemm_tcu_dxa.cu — SGEMM with DXA tile loading + TCU WGMMA compute
//
// Full hardware-accelerated GEMM pipeline:
//   DXA: global → shared memory tile transfer (hardware DMA)
//   WGMMA: TCU reads data from memory using descriptor metadata (not register loads)
//
// A: M×K (fp16), B: K×N (fp16), C: M×N (fp32)
// Tile: 16×16×16 (wmma m16n16k16)

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <cuda_runtime.h>
#include <mma.h>

using namespace nvcuda;

#define WMMA_M 16
#define WMMA_N 16
#define WMMA_K 16

// Host-side DXA descriptor programming
extern "C" void cudaDxaProgramDesc2D(unsigned int slot, unsigned long long base_addr,
                                      unsigned int size0, unsigned int size1,
                                      unsigned int stride0_bytes,
                                      unsigned int tile0, unsigned int tile1,
                                      unsigned int elem_bytes);

// DXA device-side API stubs
__device__ void __vx_dxa_issue_2d(unsigned int, unsigned int, void*, unsigned int, unsigned int) {}
__device__ void __vx_barrier_arrive_and_wait(unsigned int, unsigned int) {}
__device__ unsigned int __vx_dxa_barrier_id(unsigned int) { return 0; }
__device__ void* __vx_local_mem_offset(unsigned int) { return nullptr; }
__device__ unsigned int __vx_warps_per_group(void) { return 1; }

// WGMMA device-side API stubs
__device__ unsigned int __vx_wgmma_encode_desc(unsigned long long, unsigned int, unsigned int,
                                                unsigned int, unsigned int, unsigned int, unsigned int) { return 0; }
__device__ void __vx_wgmma_mma_ss(float*, float*, float*) {}

// WGMMA store result helper (same as wmma store but called from WGMMA kernel)
__device__ void __vx_wgmma_store_c(float* C, float* fragC, int N) {
    // This uses the same wmma::store pattern — will be translated by CuPBoP
    // For the stub, just do nothing
}

#define DXA_DESC_A  0
#define DXA_DESC_B  1

// TCU+DXA kernel using WGMMA path (SS mode: both A,B from descriptors)
// Double-buffered: two DXA barrier IDs overlap prefetch with compute
__global__ void sgemm_tcu_dxa_kernel(const half *A, const half *B, float *C,
                                      int M, int N, int K,
                                      unsigned long long A_desc_packed,
                                      unsigned long long B_desc_packed) {
    int tile_row = blockIdx.y * WMMA_M;
    int tile_col = blockIdx.x * WMMA_N;

    // Unpack descriptor fields
    unsigned int a_base = (unsigned int)(A_desc_packed & 0xffffffffull);
    unsigned int a_leading = (unsigned int)((A_desc_packed >> 32) & 0x3fff);
    unsigned int a_stride = (unsigned int)((A_desc_packed >> 46) & 0x3fff);

    unsigned int b_base = (unsigned int)(B_desc_packed & 0xffffffffull);
    unsigned int b_leading = (unsigned int)((B_desc_packed >> 32) & 0x3fff);
    unsigned int b_stride = (unsigned int)((B_desc_packed >> 46) & 0x3fff);

    // Accumulator (8 floats per thread)
    float fragC[8] = {0, 0, 0, 0, 0, 0, 0, 0};

    unsigned int tile_row_idx = tile_row / WMMA_M;
    unsigned int tile_col_idx = tile_col / WMMA_N;

    // Double-buffer setup: two barrier IDs, two prefetch buffer stages
    unsigned int bar[2];
    bar[0] = __vx_dxa_barrier_id(0);
    bar[1] = __vx_dxa_barrier_id(1);
    unsigned int num_warps = __vx_warps_per_group();

    // Double-buffer shared memory: 2 stages, each holds A tile + B tile
    // Stage 0: shmem[0 .. 1023]   Stage 1: shmem[1024 .. 2047]
    half* shmem = (half*)__vx_local_mem_offset(2 * 2 * WMMA_M * WMMA_K * sizeof(half));
    half* prefetch_buf[2];
    prefetch_buf[0] = shmem;
    prefetch_buf[1] = shmem + 2 * WMMA_M * WMMA_K;  // offset by 1024 bytes = 512 halfs

    // Prologue: issue DXA prefetch for first tile on bar[0]
    unsigned int cur = 0;
    unsigned int nxt = 1;
    __vx_dxa_issue_2d(DXA_DESC_A, bar[cur], prefetch_buf[cur], 0, tile_row);
    __vx_dxa_issue_2d(DXA_DESC_B, bar[cur], prefetch_buf[cur] + WMMA_M*WMMA_K, tile_col, 0);

    for (int k = 0; k < K; k += WMMA_K) {
        unsigned int k_idx = k / WMMA_K;
        int next_k = k + WMMA_K;

        // Issue DXA prefetch for NEXT tile on bar[nxt] (overlaps with compute)
        if (next_k < K) {
            __vx_dxa_issue_2d(DXA_DESC_A, bar[nxt], prefetch_buf[nxt], next_k, tile_row);
            __vx_dxa_issue_2d(DXA_DESC_B, bar[nxt], prefetch_buf[nxt] + WMMA_M*WMMA_K, tile_col, next_k);
        }

        // Wait for CURRENT tile prefetch to complete
        __vx_barrier_arrive_and_wait(bar[cur], num_warps);

        // Encode A descriptor metadata into fragment registers
        unsigned int a_word = __vx_wgmma_encode_desc(
            (unsigned long long)a_base, a_leading, a_stride,
            tile_row_idx, k_idx, K, 0);
        float fragA[8];
        float meta_f;
        *(unsigned int*)&meta_f = a_word;
        for (int i = 0; i < 8; i++) fragA[i] = meta_f;

        // Encode B descriptor metadata into fragment registers
        unsigned int b_word = __vx_wgmma_encode_desc(
            (unsigned long long)b_base, b_leading, b_stride,
            tile_col_idx, k_idx, N, 0);
        float fragB[8];
        *(unsigned int*)&meta_f = b_word;
        for (int i = 0; i < 8; i++) fragB[i] = meta_f;

        // WGMMA: TCU hardware fetches from memory using descriptor metadata
        // Data should be in cache thanks to DXA prefetch
        __vx_wgmma_mma_ss(fragC, fragA, fragB);

        // Post-compute sync on current barrier
        __vx_barrier_arrive_and_wait(bar[cur], num_warps);

        // Swap cur/nxt for next iteration
        unsigned int tmp = cur;
        cur = nxt;
        nxt = tmp;
    }

    // Store result using wmma::store_matrix_sync (CuPBoP translates this correctly)
    {
        wmma::fragment<wmma::accumulator, WMMA_M, WMMA_N, WMMA_K, float> fragC_wmma;
        for (int i = 0; i < 8; i++)
            fragC_wmma.x[i] = fragC[i];
        float *tileC = C + tile_row * N + tile_col;
        wmma::store_matrix_sync(tileC, fragC_wmma, N, wmma::mem_row_major);
    }
}

// CPU reference
void gemm_cpu(const half *A, const half *B, float *C, int M, int N, int K) {
    for (int i = 0; i < M; i++)
        for (int j = 0; j < N; j++) {
            float sum = 0.0f;
            for (int k = 0; k < K; k++)
                sum += __half2float(A[i * K + k]) * __half2float(B[k * N + j]);
            C[i * N + j] = sum;
        }
}

int main(int argc, char **argv) {
    int M = WMMA_M, N = WMMA_N, K = WMMA_K;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-n") == 0 && i + 1 < argc) {
            int n = atoi(argv[++i]);
            if (n > 0 && n % WMMA_M == 0) { M = N = K = n; }
            else { fprintf(stderr, "Size must be multiple of %d\n", WMMA_M); return -1; }
        }
    }
    printf("SGEMM TCU+DXA (WGMMA SS): M=%d, N=%d, K=%d\n", M, N, K);

    size_t sizeA = M * K * sizeof(half);
    size_t sizeB = K * N * sizeof(half);
    size_t sizeC = M * N * sizeof(float);

    half *h_A = (half *)malloc(sizeA);
    half *h_B = (half *)malloc(sizeB);
    float *h_C = (float *)malloc(sizeC);
    float *h_C_ref = (float *)malloc(sizeC);

    srand(42);
    for (int i = 0; i < M * K; i++) h_A[i] = __float2half((float)(rand() % 5) / 5.0f);
    for (int i = 0; i < K * N; i++) h_B[i] = __float2half((float)(rand() % 5) / 5.0f);
    memset(h_C, 0, sizeC);
    gemm_cpu(h_A, h_B, h_C_ref, M, N, K);

    half *d_A, *d_B; float *d_C;
    cudaMalloc(&d_A, sizeA);
    cudaMalloc(&d_B, sizeB);
    cudaMalloc(&d_C, sizeC);
    cudaMemcpy(d_A, h_A, sizeA, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, sizeB, cudaMemcpyHostToDevice);
    cudaMemset(d_C, 0, sizeC);

    // Build WGMMA smem descriptors
    uint64_t a_leading = WMMA_K * sizeof(half);
    uint64_t a_stride  = WMMA_M * K * sizeof(half);
    uint64_t a_desc = ((uint64_t)(uintptr_t)d_A & 0xffffffffull)
                    | ((a_leading & 0x3fff) << 32)
                    | ((a_stride & 0x3fff) << 46);

    uint64_t b_leading = WMMA_K * N * sizeof(half);
    uint64_t b_stride  = WMMA_N * sizeof(half);
    uint64_t b_desc = ((uint64_t)(uintptr_t)d_B & 0xffffffffull)
                    | ((b_leading & 0x3fff) << 32)
                    | ((b_stride & 0x3fff) << 46);

    dim3 grid(N / WMMA_N, M / WMMA_M);
    dim3 block(32, 1);
    // Shared memory for double-buffered DXA prefetch: 2 stages * (A tile + B tile) = 2 * 1024 = 2048 bytes
    size_t sharedMem = 2 * 2 * WMMA_M * WMMA_K * sizeof(half);
    sgemm_tcu_dxa_kernel<<<grid, block, sharedMem>>>(d_A, d_B, d_C, M, N, K, a_desc, b_desc);

    cudaMemcpy(h_C, d_C, sizeC, cudaMemcpyDeviceToHost);

    int errors = 0;
    for (int i = 0; i < M * N; i++) {
        float diff = fabsf(h_C[i] - h_C_ref[i]);
        if (diff / fmaxf(fabsf(h_C_ref[i]), 1.0f) > 1e-2f) {
            if (errors < 10) printf("Mismatch [%d]: got %f, expected %f\n", i, h_C[i], h_C_ref[i]);
            errors++;
        }
    }
    printf("%s: %d/%d\n", errors ? "FAILED!" : "PASSED!", M * N - errors, M * N);

    cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);
    free(h_A); free(h_B); free(h_C); free(h_C_ref);
    return errors ? 1 : 0;
}
