// sgemm_dxa.cu — Tiled SGEMM using Vortex DXA for global→shared memory transfer
//
// DXA functions are declared as extern "C" __device__ stubs here.
// On NVPTX they compile to empty functions (unused).
// On Vortex, cudaKernelImpl.cpp provides the real implementations.

#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cuda.h>

// ── DXA host-side API (Vortex-specific, resolved from CuPBoP runtime) ──────
extern "C" void cudaDxaProgramDesc2D(unsigned int slot, unsigned long long base_addr,
                                      unsigned int size0, unsigned int size1,
                                      unsigned int stride0_bytes,
                                      unsigned int tile0, unsigned int tile1,
                                      unsigned int elem_bytes);

// ── DXA device-side API (Vortex-specific) ──────────────────────────────────
// These are resolved at link time from cudaKernelImpl.cpp on Vortex.
// For CUDA GPU compilation they are stubs (the DXA kernel is not used on GPU).
__device__ void __vx_dxa_issue_2d(unsigned int, unsigned int, void*, unsigned int, unsigned int) {}
__device__ void __vx_barrier_arrive_and_wait(unsigned int, unsigned int) {}
__device__ unsigned int __vx_dxa_barrier_id(unsigned int) { return 0; }
__device__ int __vx_is_dxa_warp(void) { return 0; }
__device__ void* __vx_local_mem_offset(unsigned int) { return nullptr; }
__device__ unsigned int __vx_warps_per_group(void) { return 1; }

// ── Configuration ──────────────────────────────────────────────────────────
#ifndef TILE_SIZE
#define TILE_SIZE 8
#endif

#ifndef MATRIX_SIZE
#define MATRIX_SIZE 32
#endif

// DXA descriptor slots (must match host-side programming)
#define DXA_DESC_A  0
#define DXA_DESC_B  1

// Number of warps per CTA (must match Vortex HW config)
#ifndef NUM_WARPS_PER_GROUP
#define NUM_WARPS_PER_GROUP 2
#endif

// ── DXA Kernel (double-buffered) ───────────────────────────────────────────
__global__ void sgemm_dxa_kernel(const float* __restrict__ A,
                                  const float* __restrict__ B,
                                  float* __restrict__ C,
                                  int N) {
    const int tile = TILE_SIZE;
    const int row_base = blockIdx.x * tile;
    const int col_base = blockIdx.y * tile;
    const int l_row = threadIdx.x;
    const int l_col = threadIdx.y;
    const int g_row = row_base + l_row;
    const int g_col = col_base + l_col;

    float sum = 0.0f;

    // Get shared memory from Vortex local memory (per-CTA offset)
    // Double-buffer: 2 stages × (shA + shB) = 4 × tile × tile
    const unsigned int smem_size = 4 * tile * tile * sizeof(float);
    float* shmem = (float*)__vx_local_mem_offset(smem_size);

    // Stage 0: shA[0] at shmem, shB[0] at shmem + tile*tile
    // Stage 1: shA[1] at shmem + 2*tile*tile, shB[1] at shmem + 3*tile*tile
    float* shA[2] = { shmem,                    shmem + 2 * tile * tile };
    float* shB[2] = { shmem + tile * tile,       shmem + 3 * tile * tile };

    // Two barrier ids for double-buffered DXA synchronization
    unsigned int bar[2] = { __vx_dxa_barrier_id(0), __vx_dxa_barrier_id(1) };
    int is_dxa = __vx_is_dxa_warp();
    unsigned int num_warps = __vx_warps_per_group();

    unsigned int cur = 0;

    // Prologue: issue DXA for first tiles into buffer 0 on bar[0]
    if (is_dxa) {
        __vx_dxa_issue_2d(DXA_DESC_A, bar[0], shA[0], 0, row_base);
        __vx_dxa_issue_2d(DXA_DESC_B, bar[0], shB[0], col_base, 0);
    }

    // K-loop: issue next on bar[nxt] → wait current on bar[cur] → compute
    for (int k_base = 0; k_base < N; k_base += tile) {
        const int next_k    = k_base + tile;
        const bool has_next = (next_k < N);
        const unsigned int nxt = cur ^ 1u;

        // (1) Issue DXA for next iteration's tiles on bar[nxt]
        if (has_next && is_dxa) {
            __vx_dxa_issue_2d(DXA_DESC_A, bar[nxt], shA[nxt], next_k, row_base);
            __vx_dxa_issue_2d(DXA_DESC_B, bar[nxt], shB[nxt], col_base, next_k);
        }

        // (2) Wait for current tiles on bar[cur] (DXA completion + CTA sync)
        __vx_barrier_arrive_and_wait(bar[cur], num_warps);

        // (3) Compute partial sum from current shared memory tiles
        for (int k = 0; k < tile; ++k) {
            sum += shA[cur][l_row * tile + k] * shB[cur][k * tile + l_col];
        }

        // (4) Sync before buffer can be reused
        __vx_barrier_arrive_and_wait(bar[cur], num_warps);

        // Swap buffers
        cur = nxt;
    }

    // Store result
    if (g_row < N && g_col < N) {
        C[g_row * N + g_col] = sum;
    }
}

// ── Fallback: standard shared memory kernel (for CUDA GPU golden ref) ──────
__global__ void sgemm_ref_kernel(const float* __restrict__ A,
                                  const float* __restrict__ B,
                                  float* __restrict__ C,
                                  int N) {
    __shared__ float shA[TILE_SIZE][TILE_SIZE];
    __shared__ float shB[TILE_SIZE][TILE_SIZE];

    const int row = blockIdx.x * TILE_SIZE + threadIdx.x;
    const int col = blockIdx.y * TILE_SIZE + threadIdx.y;

    float sum = 0.0f;

    for (int k_base = 0; k_base < N; k_base += TILE_SIZE) {
        if (row < N && (k_base + threadIdx.y) < N)
            shA[threadIdx.x][threadIdx.y] = A[row * N + k_base + threadIdx.y];
        else
            shA[threadIdx.x][threadIdx.y] = 0.0f;

        if ((k_base + threadIdx.x) < N && col < N)
            shB[threadIdx.x][threadIdx.y] = B[(k_base + threadIdx.x) * N + col];
        else
            shB[threadIdx.x][threadIdx.y] = 0.0f;

        __syncthreads();

        for (int k = 0; k < TILE_SIZE; ++k)
            sum += shA[threadIdx.x][k] * shB[k][threadIdx.y];

        __syncthreads();
    }

    if (row < N && col < N)
        C[row * N + col] = sum;
}

// ── Host ───────────────────────────────────────────────────────────────────
void matmul_cpu(float* C, const float* A, const float* B, int N) {
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++) {
            float s = 0;
            for (int k = 0; k < N; k++)
                s += A[i * N + k] * B[k * N + j];
            C[i * N + j] = s;
        }
}

int main(int argc, char** argv) {
    int N = MATRIX_SIZE;
    if (argc > 1) N = atoi(argv[1]);

    if (N % TILE_SIZE != 0) {
        printf("N=%d must be divisible by TILE_SIZE=%d\n", N, TILE_SIZE);
        return 1;
    }

    printf("sgemm_dxa: N=%d, TILE_SIZE=%d\n", N, TILE_SIZE);

    size_t bytes = N * N * sizeof(float);

    // Host arrays
    float* h_A = (float*)malloc(bytes);
    float* h_B = (float*)malloc(bytes);
    float* h_C = (float*)malloc(bytes);
    float* h_ref = (float*)malloc(bytes);

    srand(42);
    for (int i = 0; i < N * N; i++) {
        h_A[i] = (float)rand() / RAND_MAX;
        h_B[i] = (float)rand() / RAND_MAX;
    }

    // Device arrays
    float *d_A, *d_B, *d_C;
    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes);

    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice);

    // Program DXA descriptors (Vortex-specific, no-op on real GPU)
    // Descriptor A: 2D, dim0=K columns, dim1=rows, tile=(TILE_SIZE, TILE_SIZE)
    // Descriptor B: 2D, dim0=columns, dim1=K rows, tile=(TILE_SIZE, TILE_SIZE)
    cudaDxaProgramDesc2D(DXA_DESC_A, (unsigned long long)(uintptr_t)d_A,
                         N, N, N * sizeof(float),
                         TILE_SIZE, TILE_SIZE, sizeof(float));
    cudaDxaProgramDesc2D(DXA_DESC_B, (unsigned long long)(uintptr_t)d_B,
                         N, N, N * sizeof(float),
                         TILE_SIZE, TILE_SIZE, sizeof(float));

    dim3 grid(N / TILE_SIZE, N / TILE_SIZE);
    dim3 block(TILE_SIZE, TILE_SIZE);

    // Launch DXA kernel (on Vortex) or ref kernel (on GPU)
    // Use DXA kernel (Vortex). For GPU golden ref, use: make cuda-run
    sgemm_dxa_kernel<<<grid, block>>>(d_A, d_B, d_C, N);

    cudaMemcpy(h_C, d_C, bytes, cudaMemcpyDeviceToHost);

    // CPU reference
    matmul_cpu(h_ref, h_A, h_B, N);

    // Verify
    int errors = 0;
    for (int i = 0; i < N * N; i++) {
        if (fabsf(h_C[i] - h_ref[i]) > 1e-3f * fmaxf(1.0f, fabsf(h_ref[i]))) {
            if (errors < 10)
                printf("MISMATCH [%d]: got %f, expected %f\n", i, h_C[i], h_ref[i]);
            errors++;
        }
    }

    if (errors == 0)
        printf("PASSED!\n");
    else
        printf("FAILED! %d/%d mismatches\n", errors, N * N);

    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    free(h_A);
    free(h_B);
    free(h_C);
    free(h_ref);

    return errors ? 1 : 0;
}
