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
                                                 unsigned issuer_lane) {
  __shared__ __align__(128) int tile[32];
  __shared__ uint64_t barrier;
  const unsigned rank = blockIdx.x % 2;
  tile[threadIdx.x] = -1;
  if (threadIdx.x == 0) {
    mbar_init(&barrier, 1);
    mbar_arrive_expect_tx(&barrier, sizeof(tile));
  }
  asm volatile("barrier.cluster.arrive.aligned; barrier.cluster.wait.aligned;" ::: "memory");
  const unsigned issue = (threadIdx.x == issuer_lane) & (rank == 1);
#if defined(__clang__) && defined(__CUDA_ARCH__)
  if (input == TensorNVVM || input == RawNVVM) {
    if (issue) {
      if (input == TensorNVVM)
        tensor_multicast((Shared *)tile, (Shared *)&barrier, &map, 0, 3, 0, true, false);
      else
        raw_multicast((Shared *)tile, (Shared *)&barrier, (Global *)src, sizeof(tile), 3, 0, true, false);
    }
  } else
#endif
  if (input == RawPTX || input == RawNVVM) {
    asm volatile("{ .reg .pred p; setp.ne.u32 p, %3, 0; "
                 "@p cp.async.bulk.shared::cluster.global.mbarrier::complete_tx::bytes.multicast::cluster "
                 "[%0], [%1], 128, [%2], %4; }"
                 :: "r"(smem_u32(tile)), "l"(src), "r"(smem_u32(&barrier)), "r"(issue),
                    "h"(uint16_t(3)) : "memory");
  } else {
    asm volatile("{ .reg .pred p; setp.ne.u32 p, %4, 0; "
                 "@p cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.multicast::cluster "
                 "[%0], [%1, {%2}], [%3], %5; }"
                 :: "r"(smem_u32(tile)), "l"(&map), "r"(0), "r"(smem_u32(&barrier)), "r"(issue),
                    "h"(uint16_t(3)) : "memory");
  }
  mbar_wait(&barrier, 0);
  out[blockIdx.x * 32 + threadIdx.x] = tile[threadIdx.x];
}

int main() {
  int *src, *dst, values[32], result[128];
  for (int i = 0; i < 32; ++i) values[i] = i * 7 + 3;
  ASYNC_CHECK(cudaMalloc(&src, sizeof(values)));
  ASYNC_CHECK(cudaMalloc(&dst, sizeof(result)));
  ASYNC_CHECK(cudaMemcpy(src, values, sizeof(values), cudaMemcpyHostToDevice));
  CUtensorMap map;
  cuuint64_t extent[] = {32};
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
  for (unsigned test = 0; test < 5; ++test) {
    // The fifth launch exercises the peer-copy fallback with elected lane 7.
    unsigned lane = test == 4 ? 7 : 0;
    void *args[] = {&dst, &src, &map, &lane};
    ASYNC_CHECK(cudaLaunchKernelExC(&cfg, kernels[test == 4 ? RawNVVM : test], args));
    ASYNC_CHECK(cudaMemcpy(result, dst, sizeof(result), cudaMemcpyDeviceToHost));
    for (int i = 0; i < 128; ++i) if (result[i] != values[i % 32]) {
      printf("FAIL input %u word %d: got %d expected %d\n", test, i, result[i], values[i % 32]);
      return 1;
    }
  }
  ASYNC_CHECK(cudaFree(src));
  ASYNC_CHECK(cudaFree(dst));
  puts("PASSED! multicast to four blocks");
}
