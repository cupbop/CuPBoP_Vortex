#include <cuda.h>
#include "../async_common.h"

#if defined(__clang__) && defined(__CUDA_ARCH__)
using Shared = void __attribute__((address_space(3)));
using Global = const void __attribute__((address_space(1)));
extern "C" __device__ void raw_multicast(Shared *, Shared *, Global *, unsigned, unsigned short,
    unsigned long long, bool, bool) asm("llvm.nvvm.cp.async.bulk.global.to.shared.cluster");
extern "C" __device__ void tensor_multicast(Shared *, Shared *, const void *, int, unsigned short,
    unsigned long long, bool, bool) asm("llvm.nvvm.cp.async.bulk.tensor.g2s.tile.1d");
#endif

enum Input { TensorPTX, RawPTX, TensorNVVM, RawNVVM };
template <Input input> __global__ void multicast(int *out, const int *src, const __grid_constant__ CUtensorMap map,
                                                 unsigned issuer_lane, unsigned short recipients) {
  __shared__ __align__(128) int tile[32];
  __shared__ uint64_t barrier;
  const unsigned rank = blockIdx.x % 2;
  tile[threadIdx.x] = -1;
  if (threadIdx.x == 0) {
    mbar_init(&barrier, 1);
    if (recipients & (1u << rank)) mbar_arrive_expect_tx(&barrier, sizeof(tile));
  }
  asm volatile("barrier.cluster.arrive.aligned; barrier.cluster.wait.aligned;" ::: "memory");
  const int source_offset = (threadIdx.x & 1) * 32;
  const unsigned issue = (threadIdx.x == issuer_lane) & (rank == 1);
#if defined(__clang__) && defined(__CUDA_ARCH__)
  if (input == TensorNVVM || input == RawNVVM) {
    if (issue) {
      if (input == TensorNVVM)
        tensor_multicast((Shared *)tile, (Shared *)&barrier, &map, source_offset, recipients, 0, true, false);
      else
        raw_multicast((Shared *)tile, (Shared *)&barrier, (Global *)(src + source_offset), sizeof(tile), recipients, 0, true, false);
    }
  } else
#endif
  if (input == RawPTX || input == RawNVVM) {
    asm volatile("{ .reg .pred p; setp.ne.u32 p, %3, 0; "
                 "@p cp.async.bulk.shared::cluster.global.mbarrier::complete_tx::bytes.multicast::cluster "
                 "[%0], [%1], 128, [%2], %4; }"
                 :: "r"(smem_u32(tile)), "l"(src + source_offset), "r"(smem_u32(&barrier)), "r"(issue),
                    "h"(recipients) : "memory");
  } else {
    asm volatile("{ .reg .pred p; setp.ne.u32 p, %4, 0; "
                 "@p cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.multicast::cluster "
                 "[%0], [%1, {%2}], [%3], %5; }"
                 :: "r"(smem_u32(tile)), "l"(&map), "r"(source_offset), "r"(smem_u32(&barrier)), "r"(issue),
                    "h"(recipients) : "memory");
  }
  if (recipients & (1u << rank)) mbar_wait(&barrier, 0);
  out[blockIdx.x * 32 + threadIdx.x] = tile[threadIdx.x];
}

int main() {
  int *src, *dst, values[64], result[128];
  for (int i = 0; i < 64; ++i) values[i] = i * 7 + 3;
  ASYNC_CHECK(cudaMalloc(&src, sizeof(values)));
  ASYNC_CHECK(cudaMalloc(&dst, sizeof(result)));
  ASYNC_CHECK(cudaMemcpy(src, values, sizeof(values), cudaMemcpyHostToDevice));
  CUtensorMap map;
  cuuint64_t extent[] = {64};
  cuuint32_t box[] = {32}, step[] = {1};
  ASYNC_CHECK(cuTensorMapEncodeTiled(&map, CU_TENSOR_MAP_DATA_TYPE_INT32, 1, src, extent, nullptr, box, step,
                                    CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_NONE,
                                    CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
  cudaLaunchAttribute attr{};
  attr.id = cudaLaunchAttributeClusterDimension;
  attr.val.clusterDim = {2, 1, 1};
  cudaLaunchConfig_t cfg{};
  cfg.gridDim = dim3(4);
  cfg.blockDim = dim3(32);
  cfg.attrs = &attr;
  cfg.numAttrs = 1;
  const void *kernels[] = {(const void *)multicast<TensorPTX>, (const void *)multicast<RawPTX>,
                           (const void *)multicast<TensorNVVM>, (const void *)multicast<RawNVVM>};
  struct Case { Input input; unsigned lane; unsigned short recipients; };
  Case cases[] = {{TensorPTX, 0, 3}, {RawPTX, 0, 3}, {TensorNVVM, 0, 3}, {RawNVVM, 0, 3},
                  {RawNVVM, 7, 3}, {TensorPTX, 31, 3}, {RawPTX, 23, 1}, {TensorNVVM, 5, 2}};
  for (auto test : cases) {
    void *args[] = {&dst, &src, &map, &test.lane, &test.recipients};
    ASYNC_CHECK(cudaLaunchKernelExC(&cfg, kernels[test.input], args));
    ASYNC_CHECK(cudaMemcpy(result, dst, sizeof(result), cudaMemcpyDeviceToHost));
    for (int i = 0; i < 128; ++i) {
      bool receives = test.recipients & (1u << ((i / 32) % 2));
      int expected = receives ? values[(test.lane & 1) * 32 + i % 32] : -1;
      if (result[i] != expected) {
        printf("FAIL input %u lane %u mask %u word %d: got %d expected %d\n",
               unsigned(test.input), test.lane, unsigned(test.recipients), i, result[i], expected);
        return 1;
      }
    }
  }
  ASYNC_CHECK(cudaFree(src));
  ASYNC_CHECK(cudaFree(dst));
  puts("PASSED! multicast to four blocks");
}
