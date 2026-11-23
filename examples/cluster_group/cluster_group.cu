#include "../async_common.h"
#include <cooperative_groups.h>

__global__ void exchange(int *out) {
  __shared__ int mailbox;
  auto cg = cooperative_groups::this_cluster();
  unsigned r = cg.block_rank(), neighbor = (r + 1) % cg.num_blocks();
  if (threadIdx.x == 0)
    mailbox = blockIdx.x + 19;
  cg.sync();
  int *address = cg.map_shared_rank(&mailbox, neighbor);
  if (threadIdx.x == 0)
    out[blockIdx.x] = cg.query_shared_rank(address) == neighbor ? *address : -1;
  // Rank one waits for a signal issued by rank zero *after* its arrive.
  // Implementing arrive as a blocking rendezvous would deadlock this launch.
  int *signal = out + gridDim.x + blockIdx.x / cg.num_blocks();
  if (r == 1)
    while (!atomicAdd(signal, 0)) {
    }
  auto token = cg.barrier_arrive();
  if (r == 0 && threadIdx.x == 0)
    atomicExch(signal, 1);
  cg.barrier_wait(static_cast<decltype(token) &&>(token));
}

__global__ void __cluster_dims__(2, 1, 1) fixed_cluster(int *out) {
  auto cg = cooperative_groups::this_cluster();
  if (threadIdx.x == 0)
    out[blockIdx.x] = cg.num_blocks() * 10 + cg.block_rank();
}

int main(int argc, char **argv) {
  int *d, host[12];
  ASYNC_CHECK(cudaMalloc(&d, sizeof(host) + 3 * sizeof(int)));
  ASYNC_CHECK(cudaMemset(d, 0, sizeof(host) + 3 * sizeof(int)));
  cudaLaunchAttribute attr{};
  attr.id = cudaLaunchAttributeClusterDimension;
  attr.val.clusterDim = {4, 1, 1};
  cudaLaunchConfig_t cfg{};
  cfg.gridDim = dim3(11);
  cfg.blockDim = dim3(32);
  cfg.attrs = &attr;
  cfg.numAttrs = 1;
  if (cudaLaunchKernelEx(&cfg, exchange, d) != cudaErrorInvalidConfiguration)
    return 1;
  cfg.gridDim = dim3(12);
  // Optional bound from the simulator configuration: one CTA fits, four cannot.
  if (argc > 1) {
    cfg.dynamicSmemBytes = strtoul(argv[1], nullptr, 0);
    if (cudaLaunchKernelEx(&cfg, exchange, d) != cudaErrorInvalidConfiguration)
      return 1;
    cfg.dynamicSmemBytes = 0;
  }
  ASYNC_CHECK(cudaLaunchKernelEx(&cfg, exchange, d));
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(host, d, sizeof(host), cudaMemcpyDeviceToHost));
  for (unsigned i = 0; i < 12; ++i)
    if (host[i] != int(19 + (i / 4) * 4 + (i + 1) % 4)) {
      printf("FAIL CTA %u received %d\n", i, host[i]);
      return 1;
    }
  if (cudaLaunchKernelEx(&cfg, fixed_cluster, d) == cudaSuccess)
    return 1;
  fixed_cluster<<<4, 32>>>(d);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(host, d, 4 * sizeof(int), cudaMemcpyDeviceToHost));
  for (int i = 0; i < 4; ++i)
    if (host[i] != 20 + i % 2)
      return 1;
  cudaFree(d);
  puts("PASSED! cooperative_groups and templated cluster launch, 12 CTAs");
  return 0;
}
