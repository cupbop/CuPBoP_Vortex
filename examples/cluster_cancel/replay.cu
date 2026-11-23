#include <cuda_runtime.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <algorithm>
#include <vector>

// Only the host registration stub is compiled from CUDA. The device entry is lifted.
extern "C" __global__ void cancel_probe(unsigned*, unsigned, unsigned) {}

#define CHECK(call) do { if ((call) != cudaSuccess) { fprintf(stderr, "%s failed\n", #call); return 1; } } while (0)

struct Sample {
  unsigned own_value, ready, success, x, y, z, values[2], raw[4];
};
static_assert(sizeof(Sample) == 48, "PTX output layout");

static int fail(unsigned id, const Sample& s) {
  fprintf(stderr, "bad CTA %u own=%u ready=%u success=%u xyz=(%u,%u,%u) values=(%u,%u) raw=%08x:%08x:%08x:%08x\n",
          id, s.own_value, s.ready, s.success, s.x, s.y, s.z, s.values[0], s.values[1],
          s.raw[0], s.raw[1], s.raw[2], s.raw[3]);
  return 1;
}

static int run(dim3 grid, dim3 cluster, bool expect_decline) {
  const unsigned count = grid.x * grid.y * grid.z;
  const unsigned members = cluster.x * cluster.y;
  const unsigned init[] = {0x11223344, 0x55667788, 0xaabbccdd, 0xeeff0011};
  std::vector<Sample> rows(count);
  unsigned* device;
  const size_t bytes = count * sizeof(Sample);
  CHECK(cudaMalloc(&device, bytes));
  CHECK(cudaMemset(device, 0xff, bytes));
  cudaLaunchAttribute attr{};
  attr.id = cudaLaunchAttributeClusterDimension;
  attr.val.clusterDim = {cluster.x, cluster.y, 1};
  cudaLaunchConfig_t cfg{};
  cfg.gridDim = grid;
  cfg.blockDim = dim3(1);
  cfg.dynamicSmemBytes = 8192;
  cfg.attrs = &attr;
  cfg.numAttrs = 1;
  CHECK(cudaLaunchKernelEx(&cfg, cancel_probe, device, cluster.x - 1, cluster.y - 1));
  CHECK(cudaDeviceSynchronize());
  CHECK(cudaMemcpy(rows.data(), device, bytes, cudaMemcpyDeviceToHost));
  CHECK(cudaFree(device));

  unsigned normal = 0, claimed = 0, declined = 0, nonzero_axes = 0;
  std::vector<unsigned> owners(count);
  for (unsigned i = 0; i < count; ++i) {
    const unsigned dx = (i % grid.x) % cluster.x, dy = (i / grid.x % grid.y) % cluster.y;
    const unsigned offset = dx + grid.x * dy, rank = dx + cluster.x * dy;
    const unsigned issuer_id = i - offset + (cluster.x > 1 ? 1 : grid.x);
    const Sample& here = rows[i];
    const Sample& issuer = rows[issuer_id];
    if (issuer.own_value == UINT32_MAX && here.own_value == UINT32_MAX) continue;
    if (here.own_value != 7 * i + 3) return fail(i, here);
    ++owners[i];
    if (issuer.ready != 1 || issuer.success > 1) return fail(issuer_id, issuer);
    if (rank == 1) {
      ++normal;
      claimed += issuer.success;
      declined += !issuer.success;
    }
    if (MULTICAST || rank == 1) {
      if (here.ready != 1 || here.success != issuer.success ||
          !std::equal(here.raw, here.raw + 4, issuer.raw)) return fail(i, here);
    } else if (here.ready != 0 || here.success != UINT32_MAX ||
               !std::equal(here.raw, here.raw + 4, init)) return fail(i, here);
    if (!issuer.success) continue;
    if (issuer.x % cluster.x || issuer.y % cluster.y ||
        issuer.x >= grid.x || issuer.y >= grid.y || issuer.z >= grid.z) return fail(issuer_id, issuer);
    const unsigned origin = issuer.x + grid.x * (issuer.y + grid.y * issuer.z);
    ++owners[origin + offset];
    nonzero_axes |= unsigned(issuer.x != 0) | (unsigned(issuer.y != 0) << 1) | (unsigned(issuer.z != 0) << 2);
    if (MULTICAST) {
      if (here.x != issuer.x || here.y != issuer.y || here.z != issuer.z ||
          here.values[0] != 7 * origin + 3 || here.values[1] != 7 * (origin + offset) + 3)
        return fail(i, here);
    } else if (issuer.values[rank] != 7 * (origin + offset) + 3) return fail(issuer_id, issuer);
  }
  for (unsigned i = 0; i < count; ++i) {
    if (owners[i] != 1) {
      fprintf(stderr, "tile %u has %u owners\n", i, owners[i]);
      return 1;
    }
  }
  const unsigned varying_axes = unsigned(grid.x > cluster.x) | (unsigned(grid.y > cluster.y) << 1) |
                                (unsigned(grid.z > 1) << 2);
  const bool invalid = expect_decline || count == members
      ? claimed != 0 || declined != count / members
      : claimed == 0 || nonzero_axes != varying_axes;
  if (invalid) {
    fprintf(stderr, "grid size %u, claims %u, declines %u, nonzero axes mask %u\n", count, claimed, declined, nonzero_axes);
    return 1;
  }
  printf("PASSED! %s grid=%ux%ux%u cluster=%ux%u normal=%u claimed=%u declined=%u CPU tiles=%u/%u\n",
         MULTICAST ? "multicast" : "selfcast", grid.x, grid.y, grid.z, cluster.x, cluster.y,
         normal, claimed, declined, count, count);
  return 0;
}

int main(int argc, char** argv) {
  bool expect_decline = argc == 2 && strcmp(argv[1], "--expect-decline") == 0;
  if (argc != 1 && !expect_decline) {
    fprintf(stderr, "usage: %s [--expect-decline]\n", argv[0]);
    return 1;
  }
  const dim3 shapes[] = {dim3(2,1)
#if EXTENDED_MULTICAST
    , dim3(1,2), dim3(2,2), dim3(1,4)
#endif
  };
  for (dim3 cluster : shapes)
    if (run(cluster, cluster, expect_decline) || run(dim3(8,4,4), cluster, expect_decline)) return 1;
  return 0;
}
