// Run with at least 512 KiB of LMEM per core. Four resident CTAs must span
// two 18-bit CUDA shared-address windows for this regression to be meaningful.
#include "../async_common.h"

__global__ __cluster_dims__(4, 1, 1) void window(unsigned *out, unsigned long long *bases) {
  extern __shared__ __align__(16) unsigned tile[];
  const unsigned lane = threadIdx.x, block = blockIdx.x;
  tile[lane] = 1 + lane + (block << 16);
  tile[32 + lane] = 0;
  asm volatile("barrier.cluster.arrive.aligned; barrier.cluster.wait.aligned;" ::: "memory");

  const unsigned row = 4 * (lane & 7);
  unsigned word;
  asm volatile("ldmatrix.sync.aligned.m8n8.x1.shared.b16 {%0}, [%1];"
               : "=r"(word) : "r"(smem_u32(tile + row)) : "memory");
  asm volatile("stmatrix.sync.aligned.m8n8.x1.shared.b16 [%0], {%1};"
               :: "r"(smem_u32(tile + 32 + row)), "r"(word + 0x10000) : "memory");
  __syncwarp();
  out[block * 64 + lane] = word;
  out[block * 64 + 32 + lane] = tile[32 + lane];
  if (!lane) bases[block] = reinterpret_cast<unsigned long long>(tile);
}

int main() {
  unsigned *device, result[256];
  unsigned long long *deviceBases, bases[4];
  ASYNC_CHECK(cudaMalloc(&device, sizeof(result)));
  ASYNC_CHECK(cudaMalloc(&deviceBases, sizeof(bases)));
  window<<<4, 32, 112 * 1024>>>(device, deviceBases);
  ASYNC_CHECK(cudaMemcpy(result, device, sizeof(result), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaMemcpy(bases, deviceBases, sizeof(bases), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device));
  ASYNC_CHECK(cudaFree(deviceBases));

  unsigned errors = 0;
  bool crossedWindow = false;
  for (unsigned block = 0; block < 4; ++block) {
    for (auto base : bases) crossedWindow |= bases[block] >= base + (1u << 18);
    for (unsigned i = 0; i < 64; ++i) {
      unsigned expected = 1 + i % 32 + (block << 16) + (i / 32) * 0x10000;
      errors += result[block * 64 + i] != expected;
    }
  }
  printf("cross_window=%d mismatches=%u/256\n", crossedWindow, errors);
  return !crossedWindow || errors;
}
