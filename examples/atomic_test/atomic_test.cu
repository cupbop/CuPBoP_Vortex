#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda.h>

// Test 1: Integer atomicAdd — each thread adds 1 to a counter
__global__ void atomic_int_add(int *counter, int N) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid < N) {
        atomicAdd(counter, 1);
    }
}

// Test 2: Float atomicAdd — each thread adds its value to accumulator
__global__ void atomic_float_add(float *accum, float *values, int N) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid < N) {
        atomicAdd(accum, values[tid]);
    }
}

// Test 3: atomicMax — find max value
__global__ void atomic_max_kernel(int *result, int *data, int N) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid < N) {
        atomicMax(result, data[tid]);
    }
}

// Test 4: atomicCAS — conditional swap
__global__ void atomic_cas_kernel(int *data, int old_val, int new_val, int N) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid < N) {
        atomicCAS(&data[tid], old_val, new_val);
    }
}

int main() {
    cudaSetDevice(0);
    int N = 64;
    int errors = 0;

    // Test 1: Integer atomicAdd
    {
        int *d_counter;
        cudaMalloc(&d_counter, sizeof(int));
        int zero = 0;
        cudaMemcpy(d_counter, &zero, sizeof(int), cudaMemcpyHostToDevice);

        atomic_int_add<<<1, 64>>>(d_counter, N);
        cudaDeviceSynchronize();

        int result;
        cudaMemcpy(&result, d_counter, sizeof(int), cudaMemcpyDeviceToHost);
        if (result != 64) {
            printf("FAIL test1: atomicAdd(int) expected 64, got %d\n", result);
            errors++;
        } else {
            printf("test1 atomicAdd(int): PASS (result=%d)\n", result);
        }
        cudaFree(d_counter);
    }

    // Test 2: Float atomicAdd
    {
        float *d_accum, *d_values;
        cudaMalloc(&d_accum, sizeof(float));
        cudaMalloc(&d_values, N * sizeof(float));

        float zero_f = 0.0f;
        cudaMemcpy(d_accum, &zero_f, sizeof(float), cudaMemcpyHostToDevice);

        float *h_values = (float*)malloc(N * sizeof(float));
        float expected = 0.0f;
        for (int i = 0; i < N; i++) {
            h_values[i] = (float)(i + 1);
            expected += h_values[i];
        }
        cudaMemcpy(d_values, h_values, N * sizeof(float), cudaMemcpyHostToDevice);

        atomic_float_add<<<1, 64>>>(d_accum, d_values, N);
        cudaDeviceSynchronize();

        float result;
        cudaMemcpy(&result, d_accum, sizeof(float), cudaMemcpyDeviceToHost);
        if (fabsf(result - expected) > 0.1f) {
            printf("FAIL test2: atomicAdd(float) expected %f, got %f\n", expected, result);
            errors++;
        } else {
            printf("test2 atomicAdd(float): PASS (result=%f)\n", result);
        }
        cudaFree(d_accum);
        cudaFree(d_values);
        free(h_values);
    }

    // Test 3: atomicMax
    {
        int *d_result, *d_data;
        cudaMalloc(&d_result, sizeof(int));
        cudaMalloc(&d_data, N * sizeof(int));

        int min_val = 0;
        cudaMemcpy(d_result, &min_val, sizeof(int), cudaMemcpyHostToDevice);

        int *h_data = (int*)malloc(N * sizeof(int));
        int expected_max = 0;
        srand(42);
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
            printf("FAIL test3: atomicMax expected %d, got %d\n", expected_max, result);
            errors++;
        } else {
            printf("test3 atomicMax: PASS (result=%d)\n", result);
        }
        cudaFree(d_result);
        cudaFree(d_data);
        free(h_data);
    }

    // Test 4: atomicCAS
    {
        int *d_data;
        cudaMalloc(&d_data, N * sizeof(int));

        int *h_data = (int*)malloc(N * sizeof(int));
        for (int i = 0; i < N; i++) h_data[i] = (i % 2 == 0) ? 42 : 99;
        cudaMemcpy(d_data, h_data, N * sizeof(int), cudaMemcpyHostToDevice);

        // Replace all 42s with 100
        atomic_cas_kernel<<<1, 64>>>(d_data, 42, 100, N);
        cudaDeviceSynchronize();

        cudaMemcpy(h_data, d_data, N * sizeof(int), cudaMemcpyDeviceToHost);
        int cas_errors = 0;
        for (int i = 0; i < N; i++) {
            int expected = (i % 2 == 0) ? 100 : 99;
            if (h_data[i] != expected) cas_errors++;
        }
        if (cas_errors) {
            printf("FAIL test4: atomicCAS %d errors\n", cas_errors);
            errors++;
        } else {
            printf("test4 atomicCAS: PASS\n");
        }
        cudaFree(d_data);
        free(h_data);
    }

    printf(errors ? "FAILED\n" : "PASSED\n");
    return errors;
}
