#include "../async_common.h"
#include <vector>
#if defined(__clang__) && defined(__CUDA_ARCH__)
using Shared = void __attribute__((address_space(3)));
using Global = const void __attribute__((address_space(1)));
extern "C" __device__ void copy_cluster(Shared *, Shared *, Global *, unsigned, unsigned short, unsigned long long,
                                        bool, bool) asm("llvm.nvvm.cp.async.bulk.global.to.shared.cluster");
#endif

__device__ __forceinline__ void cluster_sync() {
  asm volatile("barrier.cluster.arrive.release.aligned; barrier.cluster.wait.acquire.aligned;" ::: "memory");
}
__device__ __forceinline__ unsigned peer(unsigned ptr, unsigned rank) {
  unsigned address;
  asm("mapa.shared::cluster.u32 %0, %1, %2;" : "=r"(address) : "r"(ptr), "r"(rank));
  return address;
}
__global__ void cluster_test(int *out, const int *global, const __grid_constant__ CUtensorMap input) {
  __shared__ __align__(16) int tile[4], copied[4], total[4], bulk[4];
  __shared__ __align__(8) uint64_t bar, second;
  __shared__ unsigned received;
  unsigned r, n, cx, cy;
  asm("mov.u32 %0, %%cluster_ctarank;" : "=r"(r));
  asm("mov.u32 %0, %%cluster_nctarank;" : "=r"(n));
  asm("mov.u32 %0, %%cluster_nctaid.x;" : "=r"(cx));
  asm("mov.u32 %0, %%cluster_nctaid.y;" : "=r"(cy));
  unsigned block = blockIdx.x + gridDim.x * blockIdx.y;
  unsigned group = blockIdx.x / cx + (gridDim.x / cx) * (blockIdx.y / cy);
  if (threadIdx.x < 4) {
    tile[threadIdx.x] = 10000 * group + 100 * r + threadIdx.x;
    copied[threadIdx.x] = -7;
    total[threadIdx.x] = 0;
  }
  if (threadIdx.x == 0) {
    mbar_init(&bar, 1);
    mbar_init(&second, 1);
    mbar_init_fence();
  }
  // This warp exits before the first rendezvous.
  if (threadIdx.x >= 32)
    return;
  cluster_sync();
  unsigned other = (r + 1) % n;
  if (threadIdx.x < 4) {
    unsigned addr = peer(smem_u32(tile + threadIdx.x), other), value;
    if (cx == 2) {
      unsigned v[4];
      asm volatile("ld.shared::cluster.v4.u32 {%0,%1,%2,%3}, [%4];"
                   : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3])
                   : "r"(peer(smem_u32(tile),other)) : "memory");
      value = v[threadIdx.x];
    } else {
      asm volatile("ld.shared::cluster.u32 %0, [%1];" : "=r"(value) : "r"(addr) : "memory");
    }
    out[block * 17 + threadIdx.x] = value;
    unsigned dst = peer(smem_u32(total + threadIdx.x), other);
    asm volatile("st.shared::cluster.u32 [%0], %1;" ::"r"(dst), "r"(r + 1) : "memory");
  }
  cluster_sync();
  if (threadIdx.x < 4)
    out[block * 17 + 4 + threadIdx.x] = total[threadIdx.x];
  // Deliberately exclude rank zero; a nonzero issuer sends to all selected ranks.
  unsigned mask = n == 1 ? 1 : ((1u << n) - 2);
  if (threadIdx.x == 0 && ((mask >> r) & 1))
    mbar_arrive_expect_tx(&bar, 16);
  if (threadIdx.x == 0 && r == n - 1) {
    asm volatile("cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.multicast::cluster "
                 "[%0], [%1, {%2}], [%3], %4;" ::"r"(smem_u32(copied)),
                 "l"((uint64_t)&input), "r"(0), "r"(smem_u32(&bar)), "h"((uint16_t)mask)
                 : "memory");
  }
  if ((mask >> r) & 1)
    mbar_wait(&bar, 0);
  if (threadIdx.x < 4)
    out[block * 17 + 8 + threadIdx.x] = copied[threadIdx.x];
  if (threadIdx.x == 0) {
    mbar_arrive_expect_tx(&second, 20);
    unsigned target = peer(smem_u32(&received), other), mb = peer(smem_u32(&second), other);
    asm volatile("st.async.weak.shared::cluster.mbarrier::complete_tx::bytes.b32 [%0], %1, [%2];" ::"r"(target),
                 "r"(700 + r), "r"(mb)
                 : "memory");
    if (r == n - 1) {
#if defined(__clang__) && defined(__CUDA_ARCH__)
      if (cx == 2)
        copy_cluster((Shared *)bulk, (Shared *)&second, (Global *)global, 16, (1u << n) - 1, 0, true, false);
      else
#endif
        asm volatile("cp.async.bulk.shared::cluster.global.mbarrier::complete_tx::bytes.multicast::cluster"
                     " [%0], [%1], 16, [%2], %3;" ::"r"(smem_u32(bulk)),
                     "l"(global), "r"(smem_u32(&second)), "h"((uint16_t)((1u << n) - 1))
                     : "memory");
    }
  }
  mbar_wait(&second, 0);
  if (threadIdx.x < 4)
    out[block * 17 + 12 + threadIdx.x] = bulk[threadIdx.x];
  if (threadIdx.x == 0)
    out[block * 17 + 16] = received;
  cluster_sync();
}
int main() {
  int *d, *data;
  const int values[] = {21, -301, 0, 993};
  ASYNC_CHECK(cudaMalloc(&d, 64 * 17 * 4));
  ASYNC_CHECK(cudaMalloc(&data, sizeof(values)));
  ASYNC_CHECK(cudaMemcpy(data, values, sizeof(values), cudaMemcpyHostToDevice));
  CUtensorMap input;
  cuuint64_t extent[] = {4};
  cuuint32_t box[] = {4}, step[] = {1};
  ASYNC_CHECK(cuTensorMapEncodeTiled(&input, CU_TENSOR_MAP_DATA_TYPE_INT32, 1, data, extent, nullptr, box, step,
                                     CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_NONE,
                                     CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
  void *args[] = {&d, &data, &input};
  for (dim3 shape : {dim3(1, 1), dim3(1, 2), dim3(2, 1), dim3(2, 2), dim3(1, 4), dim3(4, 1)}) {
    cudaLaunchAttribute attr{};
    attr.id = cudaLaunchAttributeClusterDimension;
    attr.val.clusterDim = {shape.x, shape.y, 1};
    cudaLaunchConfig_t cfg{};
    cfg.gridDim = dim3(2 * shape.x, 2 * shape.y);
    cfg.blockDim = dim3(64);
    cfg.attrs = &attr;
    cfg.numAttrs = 1;
    ASYNC_CHECK(cudaLaunchKernelExC(&cfg, (const void *)cluster_test, args));
    ASYNC_CHECK(cudaDeviceSynchronize());
    int n = shape.x * shape.y, count = cfg.gridDim.x * cfg.gridDim.y;
    std::vector<int> host(count * 17);
    ASYNC_CHECK(cudaMemcpy(host.data(), d, host.size() * 4, cudaMemcpyDeviceToHost));
    for (unsigned y = 0; y < cfg.gridDim.y; ++y)
      for (unsigned x = 0; x < cfg.gridDim.x; ++x) {
        int group = x / shape.x + 2 * (y / shape.y), r = x % shape.x + shape.x * (y % shape.y);
        auto *v = host.data() + 17 * (x + cfg.gridDim.x * y);
        for (int i = 0; i < 4; ++i)
          if (v[i] != 10000 * group + 100 * ((r + 1) % n) + i || v[4 + i] != (r + n - 1) % n + 1 ||
              v[8 + i] != (r || n == 1 ? values[i] : -7) || v[12 + i] != values[i] || v[16] != 700 + (r + n - 1) % n) {
            printf("FAIL shape=%ux%u block=%u,%u word=%d got %d %d %d\n", shape.x, shape.y, x, y, i, v[i], v[4 + i],
                   v[8 + i]);
            return 1;
          }
      }
    printf("PASS cluster=(%u,%u,1) blocks=%d words=%d\n", shape.x, shape.y, count, count * 17);
  }
  puts("PASSED!");
  cudaFree(data);
  cudaFree(d);
  return 0;
}
