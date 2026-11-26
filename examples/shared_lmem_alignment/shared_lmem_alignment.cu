#include "../async_common.h"

__global__ void aligned_windows(unsigned *out) {
  __shared__ volatile unsigned prefix;
  __shared__ __align__(128) volatile unsigned payload;
  extern __shared__ __align__(256) unsigned char dynamic[];
  if (!threadIdx.x) {
    prefix = blockIdx.x;
    payload = 3 + blockIdx.x;
    dynamic[4] = static_cast<unsigned char>(payload);
    unsigned base = smem_u32((void *)&payload), dyn = smem_u32(dynamic);
    out[blockIdx.x] = (base & 127) | (dyn & 255) | (dynamic[4] ^ (3 + prefix));
  }
}

int main() {
  constexpr unsigned blocks = 8;
  unsigned *device, observed[blocks];
  ASYNC_CHECK(cudaMalloc(&device, sizeof(observed)));
  aligned_windows<<<blocks,32,5>>>(device);
  ASYNC_CHECK(cudaMemcpy(observed, device, sizeof(observed), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device));
  unsigned errors = 0;
  for (unsigned i = 0; i < blocks; ++i) errors += observed[i] != 0;
  printf("shared alignment mismatches=%u/%u\n", errors, blocks);
  return errors != 0;
}
