#include "../async_common.h"

// lift.mk supplies the device definition recovered from cluster_raw.ptx.
extern "C" __global__ void cluster_raw(const int *source, int *output) {}

int main() {
  constexpr int lanes = 32, blocks = 4;
  int input[lanes], result[blocks * lanes];
  for (int i = 0; i < lanes; ++i) input[i] = 333 + 87 * i;
  int *source, *output;
  ASYNC_CHECK(cudaMalloc(&source, sizeof(input)));
  ASYNC_CHECK(cudaMalloc(&output, sizeof(result)));
  ASYNC_CHECK(cudaMemcpy(source, input, sizeof(input), cudaMemcpyHostToDevice));

  cudaLaunchAttribute attribute{};
  attribute.id = cudaLaunchAttributeClusterDimension;
  attribute.val.clusterDim = {2, 1, 1};
  cudaLaunchConfig_t config{};
  config.gridDim = dim3(blocks);
  config.blockDim = dim3(lanes);
  config.attrs = &attribute;
  config.numAttrs = 1;
  void *arguments[] = {&source, &output};
  ASYNC_CHECK(cudaLaunchKernelExC(&config, (const void *)cluster_raw, arguments));
  ASYNC_CHECK(cudaMemcpy(result, output, sizeof(result), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(output));
  ASYNC_CHECK(cudaFree(source));
  for (int i = 0; i < blocks * lanes; ++i) {
    if (result[i] != input[i % lanes]) {
      printf("word %d: got %d, expected %d\n", i, result[i], input[i % lanes]);
      return 1;
    }
  }
  puts("PASS lifted raw multicast 128 values");
}
