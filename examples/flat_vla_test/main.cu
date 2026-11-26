#include <cuda_runtime.h>
#include <cstdio>

__global__ void small_allocation(unsigned *result, unsigned count) {
  volatile unsigned *values =
      static_cast<volatile unsigned *>(__builtin_alloca(count * sizeof(unsigned)));
  for (unsigned i = 0; i < count; ++i)
    values[i] = threadIdx.x + i;
  result[threadIdx.x] = values[count - 1];
}

int main() {
  constexpr unsigned threads = 8, elements = 5;
  unsigned output[threads], *device;
  if (cudaMalloc(&device, sizeof(output)) != cudaSuccess)
    return 1;
  small_allocation<<<1, threads>>>(device, elements);
  if (cudaDeviceSynchronize() != cudaSuccess ||
      cudaMemcpy(output, device, sizeof(output), cudaMemcpyDeviceToHost) != cudaSuccess)
    return 1;
  cudaFree(device);

  for (unsigned i = 0; i < threads; ++i) {
    if (output[i] != i + elements - 1) {
      std::fprintf(stderr, "lane %u: expected %u, got %u\n", i,
                   i + elements - 1, output[i]);
      return 1;
    }
  }
  std::puts("PASSED");
}
