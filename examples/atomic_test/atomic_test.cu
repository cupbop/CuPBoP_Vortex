#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda.h>

// Test: Integer atomicAdd — each thread adds tid+1, result should be N*(N+1)/2
__global__ void atomic_add_kernel(int *counter, int N) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid < N) {
        atomicAdd(counter, tid + 1);
    }
}

// Test: atomicMax — find max value in array
__global__ void atomic_max_kernel(int *result, int *data, int N) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid < N) {
        atomicMax(result, data[tid]);
    }
}

int main() {
    cudaSetDevice(0);
    int N = 64;
    int errors = 0;

    // Test 1: atomicAdd — sum 1+2+...+64 = 2080
    {
        int *d_counter;
        cudaMalloc(&d_counter, sizeof(int));
        int zero = 0;
        cudaMemcpy(d_counter, &zero, sizeof(int), cudaMemcpyHostToDevice);
        atomic_add_kernel<<<1, 64>>>(d_counter, N);
        cudaDeviceSynchronize();
        int result;
        cudaMemcpy(&result, d_counter, sizeof(int), cudaMemcpyDeviceToHost);
        int expected = N * (N + 1) / 2;
        if (result != expected) {
            printf("FAIL test1: atomicAdd expected %d, got %d\n", expected, result);
            errors++;
        } else {
            printf("test1 atomicAdd: PASS (%d)\n", result);
        }
        cudaFree(d_counter);
    }

    // Test 2: atomicMax
    {
        int *d_result, *d_data;
        cudaMalloc(&d_result, sizeof(int));
        cudaMalloc(&d_data, N * sizeof(int));
        int zero = 0;
        cudaMemcpy(d_result, &zero, sizeof(int), cudaMemcpyHostToDevice);
        int *h_data = (int*)malloc(N * sizeof(int));
        srand(42);
        int expected_max = 0;
        for (int i = 0; i < N; i++) {
            h_data[i] = rand() % 1000;
            if (h_data[i] > expected_max) expected_max = h_data[i];
        }
        cudaMemcpy(d_data, h_data, N * sizeof(int), cudaMemcpyHostToDevice);
        atomic_max_kernel<<<1, 64>>>(d_result, d_data, N);
        cudaDeviceSynchronize();
        int result;
        cudaMemcpy(&result, d_result, sizeof(int), cudaMemcpyDeviceToHost);
        if (result != expected_max) {
            printf("FAIL test2: atomicMax expected %d, got %d\n", expected_max, result);
            errors++;
        } else {
            printf("test2 atomicMax: PASS (%d)\n", result);
        }
        cudaFree(d_result);
        cudaFree(d_data);
        free(h_data);
    }

    printf("%s\n", errors ? "FAILED" : "PASSED");
    return errors;
}
