#include <cuda_runtime.h>
#include <cstdio>

#include "../huffman/scanLargeArray_kernel.cu"

int main() {
  constexpr unsigned blocks = 2, threads = 256;
  constexpr unsigned per_block = 2 * threads, count = blocks * per_block;
  unsigned input[count], output[count];
  for (unsigned i = 0; i < count; ++i)
    input[i] = 1 + i % 11;

  unsigned *src, *dst;
  if (cudaMalloc(&src, sizeof(input)) != cudaSuccess ||
      cudaMalloc(&dst, sizeof(output)) != cudaSuccess ||
      cudaMemcpy(src, input, sizeof(input), cudaMemcpyHostToDevice) != cudaSuccess ||
      cudaMemset(dst, 0xff, sizeof(output)) != cudaSuccess)
    return 1;

  prescan<false, false><<<blocks, threads>>>(dst, src, nullptr, per_block, 0, 0);
  if (cudaDeviceSynchronize() != cudaSuccess ||
      cudaMemcpy(output, dst, sizeof(output), cudaMemcpyDeviceToHost) != cudaSuccess)
    return 1;
  cudaFree(src);
  cudaFree(dst);

  for (unsigned b = 0; b < blocks; ++b) {
    unsigned prefix = 0;
    for (unsigned j = 0; j < per_block; ++j) {
      const unsigned index = b * per_block + j;
      if (output[index] != prefix) {
        std::fprintf(stderr, "block %u index %u: expected %u, got %u\n",
                     b, j, prefix, output[index]);
        return 1;
      }
      prefix += input[index];
    }
  }
  std::puts("PASSED");
}
