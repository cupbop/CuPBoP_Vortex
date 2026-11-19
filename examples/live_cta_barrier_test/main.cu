#include <cstdio>
#include <cuda_runtime.h>

constexpr int BLOCK = 128;
constexpr int BLOCKS = 15;

__global__ void reduce_after_exit(int *out) {
  __shared__ int initial[BLOCK];
  __shared__ int partial[BLOCK];
  int tid = threadIdx.x;
  int base = blockIdx.x * BLOCK;
  initial[tid] = base + tid;
  __syncthreads();

  int surviving = 32 * (1 + blockIdx.x % 3);
  if (tid >= surviving) return;

  partial[tid] = 3 * initial[BLOCK - 1 - tid];
  __syncthreads();
  int next = (tid + 32) % surviving;
  int value = partial[tid] + partial[next];
  __syncthreads();
  out[base + tid] = value;
}

int main() {
  int *device = nullptr;
  int actual[BLOCKS * BLOCK];
  if (cudaMalloc(&device, sizeof(actual)) != cudaSuccess ||
      cudaMemset(device, 0, sizeof(actual)) != cudaSuccess)
    return 1;
  reduce_after_exit<<<BLOCKS, BLOCK>>>(device);
  cudaError_t status = cudaMemcpy(actual, device, sizeof(actual), cudaMemcpyDeviceToHost);
  cudaFree(device);
  if (status != cudaSuccess) return 1;

  for (int block = 0; block < BLOCKS; ++block) {
    int surviving = 32 * (1 + block % 3);
    for (int tid = 0; tid < BLOCK; ++tid) {
      int base = block * BLOCK;
      int next = (tid + 32) % surviving;
      int expected = tid < surviving ? 3 * (2 * (base + BLOCK - 1) - tid - next) : 0;
      if (actual[base + tid] != expected) {
        std::printf("FAIL block=%d thread=%d got=%d expected=%d\n",
                    block, tid, actual[base + tid], expected);
        return 1;
      }
    }
  }
  std::puts("PASSED");
  return 0;
}
