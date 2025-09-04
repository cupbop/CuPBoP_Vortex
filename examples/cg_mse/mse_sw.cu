#include <cuda_runtime.h>
#include <cooperative_groups.h>
#include <stdio.h>
#include <random>
#include <iostream>
#include <cassert>

#define THREADS_PER_BLOCK 256

namespace cg = cooperative_groups;

#define CUDA_CHECK(call) \
    do { \
        cudaError_t error = call; \
        if (error != cudaSuccess) { \
            fprintf(stderr, "CUDA error at %s:%d: %s\n", \
                    __FILE__, __LINE__, cudaGetErrorString(error)); \
            exit(EXIT_FAILURE); \
        } \
    } while(0)


// https://github.com/clu0/unet.cu/blob/1b59e9c074c3516a3286f2c7d27c9d679dc6d042/dev/mse.cu#L8
__global__ void mse_forward_kernel(
    const float* inp, const float* y, float* loss, int N
) {
    int cg_group_size = 32;

    __shared__ float shared_sum[32]; // max 32 warps

    __shared__ int num_warps_array[THREADS_PER_BLOCK];
    __shared__ int warp_id_array[THREADS_PER_BLOCK];
    __shared__ int lane_id_array[THREADS_PER_BLOCK];
    __shared__ float thread_sum_array[THREADS_PER_BLOCK];
    
    // Parallel region #1
    for (int tid = 0; tid < THREADS_PER_BLOCK; tid++) {
        num_warps_array[tid] = THREADS_PER_BLOCK / 32;
        warp_id_array[tid] = tid / 32;
        lane_id_array[tid] = tid % 32;
        thread_sum_array[tid] = 0.0f;

        for (int i = tid; i < N; i += THREADS_PER_BLOCK) {
            float diff = inp[i] - y[i];
            thread_sum_array[tid] += diff * diff;
        }
    }

    // Parallel region #2 (hierarchical collapsing)
    __shared__ float cg_reduce_temp_array[THREADS_PER_BLOCK / 32];
    for (int i = 0; i < THREADS_PER_BLOCK / cg_group_size; i++) {
        float cg_reduce_temp = 0.0f;
        for (int j = 0; j < cg_group_size; j++) {
            int tid = i * cg_group_size + j;
            cg_reduce_temp += thread_sum_array[tid];
        }
        cg_reduce_temp_array[i] = cg_reduce_temp;
    }

    // Parallel region #3 (hierarchical collapsing)
    __shared__ float warp_sum_array[THREADS_PER_BLOCK];
    for (int i = 0; i < THREADS_PER_BLOCK / cg_group_size; i++) {
        for (int j = 0; j < cg_group_size; j++) {
            int tid = i * cg_group_size + j;
            warp_sum_array[tid] = cg_reduce_temp_array[i];

            shared_sum[warp_id_array[tid]] = warp_sum_array[tid];
        }
    }

    // Parallel region #4 (hierarchical collapsing)
    __shared__ float cg_reduce_temp2_array[THREADS_PER_BLOCK / 32];
    for (int i = 0; i < THREADS_PER_BLOCK / cg_group_size; i++) {
        float cg_reduce_temp2 = 0.0f;
        for (int j = 0; j < cg_group_size; j++) {
            int tid = i * cg_group_size + j;
            warp_sum_array[tid] = (lane_id_array[tid] < num_warps_array[tid]) ? shared_sum[lane_id_array[tid]] : 0.0f;
            cg_reduce_temp2 += warp_sum_array[tid];
        }
        cg_reduce_temp2_array[i] = cg_reduce_temp2;
    }

    // Parallel region #5 (hierarchical collapsing)
    __shared__ float block_sum_array[THREADS_PER_BLOCK];
    for (int i = 0; i < THREADS_PER_BLOCK / cg_group_size; i++) {
        for (int j = 0; j < cg_group_size; j++) {
            int tid = i * cg_group_size + j;
            block_sum_array[tid] = cg_reduce_temp2_array[i];

            if (tid == 0) {
                loss[0] = block_sum_array[tid] / N;
            }
        }
    }
}

float compute_mse_cpu(const float* inp, const float* y, int N) {
    float sum = 0.0f;
    for (int i = 0; i < N; i++) {
        float diff = inp[i] - y[i];
        sum += diff * diff;
    }
    return sum / N;
}

void generate_random_data(float* data, int size, float min = -1.0f, float max = 1.0f) {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<float> dis(min, max);
    
    for (int i = 0; i < size; i++) {
        data[i] = dis(gen);
    }
}

int main() {
    const int N = 1024 * 1024;  // 1M elements
    const int threads_per_block = 256;
    
    float *h_input = new float[N];
    float *h_target = new float[N];
    float h_loss = 0.0f;
    
    generate_random_data(h_input, N);
    generate_random_data(h_target, N);
    
    float *d_input, *d_target, *d_loss;
    CUDA_CHECK(cudaMalloc(&d_input, N * sizeof(float)));
    CUDA_CHECK(cudaMalloc(&d_target, N * sizeof(float)));
    CUDA_CHECK(cudaMalloc(&d_loss, sizeof(float)));
    
    CUDA_CHECK(cudaMemcpy(d_input, h_input, N * sizeof(float), cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_target, h_target, N * sizeof(float), cudaMemcpyHostToDevice));
    
    mse_forward_kernel<<<32, 1>>>(d_input, d_target, d_loss, N);
    CUDA_CHECK(cudaGetLastError());
    
    CUDA_CHECK(cudaMemcpy(&h_loss, d_loss, sizeof(float), cudaMemcpyDeviceToHost));
    
    float cpu_loss = compute_mse_cpu(h_input, h_target, N);
    
    printf("GPU MSE Loss: %f\n", h_loss);
    printf("CPU MSE Loss: %f\n", cpu_loss);
    printf("Relative difference: %f%%\n", 100.0f * fabsf(h_loss - cpu_loss) / cpu_loss);
    
    const float tolerance = 1e-3;
    assert(fabsf(h_loss - cpu_loss) / cpu_loss < tolerance && "GPU and CPU results differ too much!");
    printf("Verification passed!\n");
    
    delete[] h_input;
    delete[] h_target;
    CUDA_CHECK(cudaFree(d_input));
    CUDA_CHECK(cudaFree(d_target));
    CUDA_CHECK(cudaFree(d_loss));
    
    return 0;
}