#include "../async_common.h"

// The implementation comes from alloc.ptx assembled for SM100a and lifted.
extern "C" __global__ void serial(unsigned *out, unsigned columns) {}

int main(int argc, char **) {
  unsigned *device, result[32];
  ASYNC_CHECK(cudaMalloc(&device, sizeof(result)));
  if (argc > 1) {
    serial<<<1, 32>>>(device, 48);
    ASYNC_CHECK(cudaDeviceSynchronize());
    return 1;
  }
  for (unsigned columns = 32; columns <= 512; columns *= 2) {
    ASYNC_CHECK(cudaMemset(device, 0xff, sizeof(result)));
    serial<<<1, 32>>>(device, columns);
    ASYNC_CHECK(cudaGetLastError());
    ASYNC_CHECK(cudaMemcpy(result, device, sizeof(result), cudaMemcpyDeviceToHost));
    for (unsigned lane = 0; lane != 32; ++lane) {
      // The only live allocation on this core must start at column zero.
      if (result[lane] != columns) {
        printf("columns=%u lane=%u expected=%u got=%u\n", columns, lane, columns, result[lane]);
        return 1;
      }
    }
  }
  ASYNC_CHECK(cudaFree(device));
  puts("TMEM runtime allocation size passed 160/160");
  return 0;
}
