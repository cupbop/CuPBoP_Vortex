#include <cuda.h>
#include "../async_common.h"

#if defined(__clang__) && defined(__CUDA_ARCH__)
using SharedWord = unsigned __attribute__((address_space(3)));
extern "C" __device__ void tensor_add(SharedWord *, const void *, int, unsigned long long,
                                      bool) asm("llvm.nvvm.cp.async.bulk.tensor.reduce.add.tile.1d");
#endif

// Four CTAs reduce into the same global words and rank zero's DSM. The
// tensor box starts before the global allocation; only three words are in bounds.
__global__ void reduce_test(unsigned *out, const __grid_constant__ CUtensorMap map) {
  __shared__ __align__(16) unsigned src[8], sum[4];
  __shared__ __align__(8) uint64_t bar;
  unsigned rank;
  asm("mov.u32 %0, %%cluster_ctarank;" : "=r"(rank));
  unsigned lane = threadIdx.x;
  if (lane < 4) {
    src[lane] = rank + lane + 1;
    sum[lane] = 10;
    src[4 + lane] = rank + lane + 5;
  }
  if (lane == 0) {
    mbar_init(&bar, 1);
    mbar_init_fence();
    if (rank == 0)
      mbar_arrive_expect_tx(&bar, 4 * sizeof(sum));
  }
  asm volatile("barrier.cluster.arrive.release.aligned; barrier.cluster.wait.acquire.aligned;" ::: "memory");
  if (lane == 0) {
    unsigned remote, completion;
    asm("mapa.shared::cluster.u32 %0, %1, 0;" : "=r"(remote) : "r"(smem_u32(sum)));
    asm("mapa.shared::cluster.u32 %0, %1, 0;" : "=r"(completion) : "r"(smem_u32(&bar)));
    asm volatile("cp.reduce.async.bulk.shared::cluster.shared::cta.mbarrier::complete_tx::bytes.add.u32"
                 " [%0], [%1], 16, [%2];" ::"r"(remote),
                 "r"(smem_u32(src)), "r"(completion)
                 : "memory");
    asm volatile("cp.reduce.async.bulk.global.shared::cta.bulk_group.add.u32 [%0], [%1], 16;" ::"l"(out),
                 "r"(smem_u32(src))
                 : "memory");
#if defined(__clang__) && defined(__CUDA_ARCH__)
    if (rank & 1)
      tensor_add((SharedWord *)src, &map, -4, 0, false);
    else
#endif
      asm volatile("cp.reduce.async.bulk.tensor.1d.global.shared::cta.add.tile.bulk_group [%0, {%1}], [%2];" ::"l"(
                       (uint64_t)&map),
                   "r"(-4), "r"(smem_u32(src))
                   : "memory");
    asm volatile("cp.async.bulk.commit_group; cp.async.bulk.wait_group 0;" ::: "memory");
  }
  if (rank == 0) {
    mbar_wait(&bar, 0);
    if (lane < 4)
      out[8 + lane] = sum[lane];
  }
  asm volatile("barrier.cluster.arrive.release.aligned; barrier.cluster.wait.acquire.aligned;" ::: "memory");
}

// All four CTAs update the same destinations. These inputs distinguish signed
// minimum, XOR, bounded decrement, a 64-bit carry, and a subnormal FP16 add.
__global__ void reduce_types(unsigned *out) {
  __shared__ __align__(16) unsigned src[20];
  auto rank = blockIdx.x;
  auto i = threadIdx.x;
  if (i < 4) {
    src[i] = unsigned(-int(rank + i + 1));
    src[4+i] = (1u << rank) << i;
    src[8+i] = 6;
    src[12+i] = i % 2 ? 0 : 0xffffffffu;
    src[16+i] = 0x00010001u;
  }
  __syncthreads();
  if (i == 0) {
    asm volatile("cp.reduce.async.bulk.global.shared::cta.bulk_group.min.s32 [%0], [%1], 16;"
                 :: "l"(out), "r"(smem_u32(src)) : "memory");
    asm volatile("cp.reduce.async.bulk.global.shared::cta.bulk_group.xor.b32 [%0], [%1], 16;"
                 :: "l"(out + 4), "r"(smem_u32(src + 4)) : "memory");
    asm volatile("cp.reduce.async.bulk.global.shared::cta.bulk_group.dec.u32 [%0], [%1], 16;"
                 :: "l"(out + 8), "r"(smem_u32(src + 8)) : "memory");
    asm volatile("cp.reduce.async.bulk.global.shared::cta.bulk_group.add.u64 [%0], [%1], 16;"
                 :: "l"(out + 12), "r"(smem_u32(src + 12)) : "memory");
    asm volatile("cp.reduce.async.bulk.global.shared::cta.bulk_group.add.noftz.f16 [%0], [%1], 16;"
                 :: "l"(out + 16), "r"(smem_u32(src + 16)) : "memory");
    asm volatile("cp.async.bulk.commit_group; cp.async.bulk.wait_group 0;" ::: "memory");
  }
}

int main() {
  unsigned *out;
  unsigned result[12] = {};
  ASYNC_CHECK(cudaMalloc(&out, sizeof(result)));
  ASYNC_CHECK(cudaMemset(out, 0, sizeof(result)));
  CUtensorMap map;
  cuuint64_t extent[] = {3};
  cuuint32_t box[] = {8}, step[] = {1};
  ASYNC_CHECK(cuTensorMapEncodeTiled(&map, CU_TENSOR_MAP_DATA_TYPE_UINT32, 1, out + 4, extent, nullptr, box, step,
                                     CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_NONE,
                                     CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
  cudaLaunchAttribute attr{};
  attr.id = cudaLaunchAttributeClusterDimension;
  attr.val.clusterDim = {2, 2, 1};
  cudaLaunchConfig_t cfg{};
  cfg.gridDim = dim3(2, 2);
  cfg.blockDim = dim3(48);
  cfg.attrs = &attr;
  cfg.numAttrs = 1;
  void *args[] = {&out, &map};
  ASYNC_CHECK(cudaLaunchKernelExC(&cfg, (const void *)reduce_test, args));
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(result, out, sizeof(result), cudaMemcpyDeviceToHost));
  for (unsigned i = 0; i < 4; ++i) {
    unsigned expected = 0;
    for (unsigned r = 0; r < 4; ++r)
      expected += r + i + 1;
    if (result[i] != expected || result[4 + i] != (i == 3 ? 0 : expected + 16) || result[8 + i] != expected + 10) {
      printf("FAIL word %u linear=%u tensor=%u remote=%u\n", i, result[i], result[4 + i], result[8 + i]);
      return 1;
    }
  }
  ASYNC_CHECK(cudaFree(out));
  unsigned typed[20];
  ASYNC_CHECK(cudaMalloc(&out, sizeof(typed)));
  ASYNC_CHECK(cudaMemset(out, 0, sizeof(typed)));
  attr.val.clusterDim = {4,1,1};
  cfg.gridDim = dim3(4);
  void *type_args[] = {&out};
  ASYNC_CHECK(cudaLaunchKernelExC(&cfg, (const void *)reduce_types, type_args));
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(typed, out, sizeof(typed), cudaMemcpyDeviceToHost));
  for (unsigned i = 0; i < 4; ++i) {
    if (typed[i] != unsigned(-int(i + 4)) || typed[4+i] != (15u << i) ||
        typed[8+i] != 3 || typed[12+i] != (i % 2 ? 3u : 0xfffffffcu) ||
        typed[16+i] != 0x00040004u) {
      printf("FAIL typed word %u min=%x xor=%x dec=%x add64=%x add16=%x\n",
             i, typed[i], typed[4+i], typed[8+i], typed[12+i], typed[16+i]);
      return 1;
    }
  }
  ASYNC_CHECK(cudaFree(out));
  puts("PASSED! bulk reduction: global, out-of-bounds tensor box, remote DSM and byte-counted completion");
  return 0;
}
