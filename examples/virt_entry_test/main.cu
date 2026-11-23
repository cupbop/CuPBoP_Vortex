#include <algorithm>
#include <cstdio>
#include <cuda_runtime.h>

constexpr int blocks = 2;
constexpr int threads = 64;

// Even and odd CTAs enter the same loop through different blocks. The
// shuffles exchange values between the 8-lane sub-passes of a CUDA warp.
__global__ void two_entries(int *out, int trips) {
  int lane = threadIdx.x;
  int value = lane;
  int iteration = 0;
  __syncthreads();
  if (blockIdx.x & 1) goto xor8;
xor16:
  value = __shfl_xor_sync(0xffffffffu, value, 16) + lane;
  if (++iteration == trips) goto done;
xor8:
  value = __shfl_xor_sync(0xffffffffu, value, 8) + 3;
  if (iteration < trips) goto xor16;
done:
  out[blockIdx.x * blockDim.x + lane] = value;
}

int main() {
  constexpr int trips = 3;
  int result[blocks * threads];
  int *device;
  if (cudaMalloc(&device, sizeof(result)) != cudaSuccess) return 1;
  two_entries<<<blocks, threads>>>(device, trips);
  if (cudaMemcpy(result, device, sizeof(result), cudaMemcpyDeviceToHost) != cudaSuccess) return 1;
  cudaFree(device);

  for (int block = 0; block < blocks; ++block) {
    int current[threads], next[threads];
    for (int lane = 0; lane < threads; ++lane) current[lane] = lane;
    for (int i = 0; i < trips; ++i) {
      if (block == 1 || i > 0) {
        for (int lane = 0; lane < threads; ++lane) next[lane] = current[lane ^ 8] + 3;
        std::copy(next, next + threads, current);
      }
      for (int lane = 0; lane < threads; ++lane) next[lane] = current[lane ^ 16] + lane;
      std::copy(next, next + threads, current);
    }
    for (int lane = 0; lane < threads; ++lane) {
      int actual = result[block * threads + lane];
      if (actual != current[lane]) {
        std::printf("FAIL block %d thread %d: got %d, expected %d\n", block, lane, actual, current[lane]);
        return 1;
      }
    }
  }
  std::puts("PASSED");
  return 0;
}
