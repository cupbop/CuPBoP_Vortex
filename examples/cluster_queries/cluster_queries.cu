#include "../async_common.h"
#include <cooperative_groups.h>
#include <vector>

namespace cg = cooperative_groups;
struct Sample {
  uint3 relative, blocks, threads, cluster, clusters;
  unsigned block_rank, thread_rank, num_blocks, num_threads, size, cluster_rank, num_clusters;
  unsigned owner, address_flags, explicit_dim;
  int peer_value;
};

__host__ __device__ static unsigned linear(uint3 p, dim3 shape) {
  return p.x + shape.x * (p.y + shape.y * p.z);
}

__global__ void inspect(Sample *out) {
  __shared__ int mailbox;
  auto group = cg::this_cluster();
  unsigned block = linear(blockIdx, gridDim);
  unsigned tid = linear(threadIdx, blockDim);
  if (tid == 0) mailbox = block + 37;
  group.sync();
  unsigned peer = (group.block_rank() + 1) % group.num_blocks();
  auto *remote = group.map_shared_rank(&mailbox, peer);
  Sample &s = out[block * blockDim.x * blockDim.y * blockDim.z + tid];
  s.relative = group.block_index();
  s.blocks = group.dim_blocks();
  s.threads = group.dim_threads();
  s.cluster = cg::grid_group::cluster_index();
  s.clusters = cg::grid_group::dim_clusters();
  s.block_rank = group.block_rank();
  s.thread_rank = group.thread_rank();
  s.num_blocks = group.num_blocks();
  s.num_threads = group.num_threads();
  s.size = group.size();
  s.cluster_rank = cg::grid_group::cluster_rank();
  s.num_clusters = cg::grid_group::num_clusters();
  s.owner = group.query_shared_rank(remote);
  s.address_flags = (__isShared(&mailbox) ? 1 : 0) | (__isShared(remote) ? 2 : 0) |
                    (__isClusterShared(remote) ? 4 : 0) | (__isGlobal(out) ? 8 : 0) |
                    (__isClusterShared(out) ? 16 : 0) | (__isGlobal(remote) ? 32 : 0);
  s.explicit_dim = __clusterDimIsSpecified();
  s.peer_value = *remote;
  group.barrier_arrive();
  group.barrier_wait();
}

static bool same(uint3 actual, dim3 expected) {
  return actual.x == expected.x && actual.y == expected.y && actual.z == expected.z;
}

static int check(dim3 c, bool explicit_dim) {
  const dim3 block(4, 4, 2), groups(2, 1, 2), grid(c.x * groups.x, c.y * groups.y, c.z * groups.z);
  const unsigned members = c.x * c.y * c.z, threads = block.x * block.y * block.z;
  std::vector<Sample> host(grid.x * grid.y * grid.z * threads);
  Sample *device;
  ASYNC_CHECK(cudaMalloc(&device, host.size() * sizeof(Sample)));
  if (explicit_dim) {
    cudaLaunchAttribute attrs[2]{};
    attrs[0].id = cudaLaunchAttributeClusterDimension;
    attrs[0].val.clusterDim = {c.x, c.y, c.z};
    attrs[1].id = cudaLaunchAttributeClusterSchedulingPolicyPreference;
    cudaLaunchConfig_t cfg{};
    cfg.gridDim = grid;
    cfg.blockDim = block;
    cfg.attrs = attrs;
    cfg.numAttrs = 2;
    // A preference is optional, but the enum must still be valid.
    attrs[1].val.clusterSchedulingPolicyPreference = static_cast<cudaClusterSchedulingPolicy>(99);
    if (cudaLaunchKernelEx(&cfg, inspect, device) != cudaErrorInvalidValue) return 1;
    attrs[1].val.clusterSchedulingPolicyPreference = cudaClusterSchedulingPolicySpread;
    ASYNC_CHECK(cudaLaunchKernelEx(&cfg, inspect, device));
  } else {
    inspect<<<grid, block>>>(device);
  }
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(host.data(), device, host.size() * sizeof(Sample), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device));
  for (unsigned i = 0; i < host.size(); ++i) {
    const unsigned b = i / threads, tid = i % threads;
    const dim3 pos(b % grid.x, (b / grid.x) % grid.y, b / (grid.x * grid.y));
    const dim3 local(pos.x % c.x, pos.y % c.y, pos.z % c.z);
    const dim3 idx(pos.x / c.x, pos.y / c.y, pos.z / c.z);
    const unsigned rank = linear(local, c), peer = (rank + 1) % members;
    const dim3 neighbor(idx.x * c.x + peer % c.x, idx.y * c.y + peer / c.x % c.y,
                        idx.z * c.z + peer / (c.x * c.y));
    const Sample &s = host[i];
    if (!same(s.relative, local) || !same(s.blocks, c) || !same(s.cluster, idx) || !same(s.clusters, groups) ||
        !same(s.threads, dim3(c.x * block.x, c.y * block.y, c.z * block.z)) || s.block_rank != rank ||
        s.thread_rank != rank * threads + tid || s.num_blocks != members || s.num_threads != members * threads ||
        s.size != members * threads || s.cluster_rank != linear(idx, groups) ||
        s.num_clusters != groups.x * groups.y * groups.z || s.owner != peer ||
        s.address_flags != (members == 1 ? 15u : 13u) || s.explicit_dim != unsigned(explicit_dim) ||
        s.peer_value != int(37 + linear(neighbor, grid))) {
      printf("FAIL cluster %ux%ux%u sample %u rank=%u thread=%u owner=%u flags=%u explicit=%u peer=%d\n",
             c.x, c.y, c.z, i, s.block_rank, s.thread_rank, s.owner, s.address_flags, s.explicit_dim, s.peer_value);
      return 1;
    }
  }
  printf("PASSED! %ux%ux%u explicit=%d, %zu thread records\n", c.x, c.y, c.z, explicit_dim, host.size());
  return 0;
}

int main() {
  int supported = 0;
  cudaDeviceProp prop{};
  ASYNC_CHECK(cudaGetDeviceProperties(&prop, 0));
  ASYNC_CHECK(cudaDeviceGetAttribute(&supported, cudaDevAttrClusterLaunch, 0));
  if (!supported || supported != prop.clusterLaunch) return 1;
  if (check(dim3(1), false)) return 1;
  for (dim3 c : {dim3(1), dim3(1,2), dim3(2,1), dim3(2,2), dim3(1,4), dim3(4,1), dim3(1,2,2)})
    if (check(c, true)) return 1;
  return 0;
}
