#include <cuda_runtime.h>
#include <cstdio>

constexpr int threads = 1024;
constexpr int modes = 4;

__global__ void shuffle(int *out) {
  const int tid = threadIdx.x;
  const int value = tid + 1;
  const unsigned mask = 0xffffffffu;

  // Every logical warp has distinct inputs, including warps 16 through 31
  // that exceed the CI target's physical warp count.
  out[tid * modes + 0] = __shfl_sync(mask, value, 7, 8);
  out[tid * modes + 1] = __shfl_up_sync(mask, value, 3, 8);
  out[tid * modes + 2] = __shfl_down_sync(mask, value, 2, 16);
  out[tid * modes + 3] = __shfl_xor_sync(mask, value, 3, 8);
}

int main() {
  int output[threads * modes], *device;
  if (cudaMalloc(reinterpret_cast<void **>(&device), sizeof(output)) != cudaSuccess)
    return 1;
  shuffle<<<1, threads>>>(device);
  if (cudaMemcpy(output, device, sizeof(output), cudaMemcpyDeviceToHost) != cudaSuccess)
    return 1;
  cudaFree(device);

  int mismatches = 0;
  for (int tid = 0; tid < threads; ++tid) {
    const int input = tid + 1;
    const int expected[modes] = {
        (tid | 7) + 1,
        (tid % 8 >= 3) ? input - 3 : input,
        (tid % 16 < 14) ? input + 2 : input,
        (tid ^ 3) + 1,
    };
    for (int mode = 0; mode < modes; ++mode) {
      const int actual = output[tid * modes + mode];
      if (actual != expected[mode]) {
        if (!mismatches)
          std::printf("Thread %d, mode %d: expected %d, got %d\n", tid, mode, expected[mode], actual);
        ++mismatches;
      }
    }
  }
  std::printf("%s %d/%d shuffle mismatches\n", mismatches ? "FAILED!" : "PASSED!", mismatches, threads * modes);
  return mismatches != 0;
}
