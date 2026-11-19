#include <cuda.h>
#include "../async_common.h"

// Clang generates the launch stub from this declaration. The implementation is in tma_nvvm_3d.ll.in.
extern "C" __global__ void tma_nvvm_3d(const __grid_constant__ CUtensorMap map, float *out) {
  if (threadIdx.x == 0) out[0] = 0;
}

int main() {
  constexpr int width = 32, height = 8, depth = 2;
  constexpr int elements = width * height * depth;
  float source[elements], actual[elements];
  for (int i = 0; i < elements; ++i) source[i] = static_cast<float>(3 * i - 100);

  float *gpu_source, *gpu_actual;
  ASYNC_CHECK(cudaMalloc(&gpu_source, sizeof(source)));
  ASYNC_CHECK(cudaMalloc(&gpu_actual, sizeof(actual)));
  ASYNC_CHECK(cudaMemcpy(gpu_source, source, sizeof(source), cudaMemcpyHostToDevice));

  CUtensorMap map;
  const cuuint64_t dims[] = {width, height, depth};
  const cuuint64_t strides[] = {width * sizeof(float), width * height * sizeof(float)};
  const cuuint32_t box[] = {width, height, depth};
  const cuuint32_t elem_strides[] = {1, 1, 1};
  ASYNC_CHECK(cuTensorMapEncodeTiled(&map, CU_TENSOR_MAP_DATA_TYPE_FLOAT32, 3, gpu_source, dims, strides, box,
                                    elem_strides, CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_NONE,
                                    CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
  tma_nvvm_3d<<<1, 32>>>(map, gpu_actual);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(actual, gpu_actual, sizeof(actual), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(gpu_actual));
  ASYNC_CHECK(cudaFree(gpu_source));

  int matches = 0;
  for (int i = 0; i < elements; ++i) matches += source[i] == actual[i];
  printf("%s: %d/%d\n", matches == elements ? "PASSED!" : "FAILED!", matches, elements);
  return matches != elements;
}
