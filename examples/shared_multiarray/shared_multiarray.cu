#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda.h>

#define BLOCK_SIZE 256

// Kernel using 3 different shared arrays (float[], int[], float[])
__global__ void shared_multiarray_kernel(float *fdata, float *fdata2, float *output, int N) {
    __shared__ float sf[256];
    __shared__ float sg[256];

    int tid = threadIdx.x;
    int gid = blockIdx.x * blockDim.x + threadIdx.x;

    // Load data into 2 shared float arrays
    if (gid < N) {
        sf[tid] = fdata[gid];
        sg[tid] = fdata2[gid];
    } else {
        sf[tid] = 0.0f;
        sg[tid] = 0.0f;
    }
    __syncthreads();

    // Compute using both shared arrays
    if (gid < N) {
        float result = sf[tid] + sg[tid];
        output[gid] = result;
    }
}

int main() {
    cudaSetDevice(0);

    const int N = 512;
    int numBlocks = (N + BLOCK_SIZE - 1) / BLOCK_SIZE;

    float *h_fdata = (float *)malloc(N * sizeof(float));
    float *h_fdata2 = (float *)malloc(N * sizeof(float));
    float *h_output = (float *)malloc(N * sizeof(float));
    float *h_ref = (float *)malloc(N * sizeof(float));

    srand(42);
    for (int i = 0; i < N; i++) {
        h_fdata[i] = (float)(rand() % 100) / 10.0f;
        h_fdata2[i] = (float)(rand() % 100) / 10.0f;
    }

    // CPU reference
    for (int b = 0; b < numBlocks; b++) {
        int start = b * BLOCK_SIZE;
        for (int tid = 0; tid < BLOCK_SIZE; tid++) {
            int gid = start + tid;
            if (gid >= N) continue;

            float result = h_fdata[gid] + h_fdata2[gid];
            h_ref[gid] = result;
        }
    }

    float *d_fdata, *d_fdata2, *d_output;
    cudaMalloc(&d_fdata, N * sizeof(float));
    cudaMalloc(&d_fdata2, N * sizeof(float));
    cudaMalloc(&d_output, N * sizeof(float));

    cudaMemcpy(d_fdata, h_fdata, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_fdata2, h_fdata2, N * sizeof(float), cudaMemcpyHostToDevice);

    shared_multiarray_kernel<<<numBlocks, BLOCK_SIZE>>>(d_fdata, d_fdata2, d_output, N);
    cudaDeviceSynchronize();

    cudaMemcpy(h_output, d_output, N * sizeof(float), cudaMemcpyDeviceToHost);

    int passed = 1;
    for (int i = 0; i < N; i++) {
        float diff = fabsf(h_output[i] - h_ref[i]);
        float mag = fabsf(h_ref[i]) > 1.0f ? fabsf(h_ref[i]) : 1.0f;
        if (diff / mag > 0.1f) {  // 10% relative tolerance for cross-arch FP differences
            printf("FAILED at index %d: expected=%f got=%f (diff=%f)\n", i, h_ref[i], h_output[i], diff);
            passed = 0;
            break;
        }
    }
    if (passed) {
        printf("PASSED\n");
    }

    cudaFree(d_fdata);
    cudaFree(d_fdata2);
    cudaFree(d_output);
    free(h_fdata);
    free(h_fdata2);
    free(h_output);
    free(h_ref);

    return 0;
}
