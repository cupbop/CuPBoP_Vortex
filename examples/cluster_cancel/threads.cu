#include "../async_common.h"
#include <vector>

struct alignas(16) Response {
  uint64_t lo, hi;
};

struct Claim {
  uint32_t success, x, y, z, value;
};

struct Tile {
  uint32_t value;
  Claim claims[2];
};

__host__ __device__ static uint32_t tile_value(uint32_t x, uint32_t y, uint32_t z) {
  return 3 + x * 13 + y * 577 + z * 65537;
}

// Use the two b64 register operands and predicate conversion of the CCCL wrappers.
__device__ static __forceinline__ uint32_t succeeded(uint64_t lo, uint64_t hi) {
  uint32_t result;
  asm("{ .reg .b128 resp; .reg .pred p; mov.b128 resp, {%1, %2}; "
      "clusterlaunchcontrol.query_cancel.is_canceled.pred.b128 p, resp; selp.b32 %0, 1, 0, p; }"
      : "=r"(result) : "l"(lo), "l"(hi));
  return result;
}

__device__ static __forceinline__ void read_coords(Claim& c, uint64_t lo, uint64_t hi) {
  asm("{ .reg .b128 resp; mov.b128 resp, {%3, %4}; "
      "clusterlaunchcontrol.query_cancel.get_first_ctaid::x.b32.b128 %0, resp; "
      "clusterlaunchcontrol.query_cancel.get_first_ctaid::y.b32.b128 %1, resp; "
      "clusterlaunchcontrol.query_cancel.get_first_ctaid::z.b32.b128 %2, resp; }"
      : "=r"(c.x), "=r"(c.y), "=r"(c.z) : "l"(lo), "l"(hi));
}

__global__ void thread_requests(Tile* rows, int expect_first) {
  __shared__ Response responses[2];
  __shared__ uint64_t barriers[2];
  if (threadIdx.x != 3 && threadIdx.x != 21) return;
  unsigned slot = threadIdx.x == 3 ? 0 : 1;
  auto& row = rows[blockIdx.x + gridDim.x * (blockIdx.y + gridDim.y * blockIdx.z)];
  if (slot == 0) row.value = tile_value(blockIdx.x, blockIdx.y, blockIdx.z);

  auto& response = responses[slot];
  auto* bar = &barriers[slot];
  response.lo = UINT64_MAX;
  response.hi = UINT64_MAX;
  mbar_init(bar, 1);
  mbar_init_fence();
  if (expect_first) mbar_arrive_expect_tx(bar, 16);
  asm volatile("clusterlaunchcontrol.try_cancel.async.shared::cta.mbarrier::complete_tx::bytes.b128 [%0], [%1];"
               :: "r"(smem_u32(&response)), "r"(smem_u32(bar)) : "memory");
  if (!expect_first) mbar_arrive_expect_tx(bar, 16);
  mbar_wait(bar, 0);

  auto& claim = row.claims[slot];
  uint64_t lo = response.lo, hi = response.hi;
  claim.success = succeeded(lo, hi);
  if (claim.success) {
    read_coords(claim, lo, hi);
    claim.value = tile_value(claim.x, claim.y, claim.z);
  }
}

static int run(dim3 grid, int expect_first) {
  unsigned count = grid.x * grid.y * grid.z;
  size_t bytes = count * sizeof(Tile);
  Tile* device;
  std::vector<Tile> rows(count);
  ASYNC_CHECK(cudaMalloc(&device, bytes));
  ASYNC_CHECK(cudaMemset(device, 0xff, bytes));
  thread_requests<<<grid, 32, 4096>>>(device, expect_first);
  ASYNC_CHECK(cudaGetLastError());
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(rows.data(), device, bytes, cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device));

  std::vector<unsigned> owners(count);
  unsigned successes[2]{}, physical = 0, declines = 0;
  for (unsigned i = 0; i < count; ++i) {
    const Tile& row = rows[i];
    if (row.value == UINT32_MAX) continue;
    ++physical;
    ++owners[i];
    if (row.value != tile_value(i % grid.x, i / grid.x % grid.y, i / (grid.x * grid.y))) {
      fprintf(stderr, "incorrect local tile %u\n", i);
      return 1;
    }
    for (unsigned lane = 0; lane < 2; ++lane) {
      const Claim& c = row.claims[lane];
      if (!c.success) {
        if (c.value != UINT32_MAX) return 1;
        ++declines;
        continue;
      }
      if (c.success != 1 || c.x >= grid.x || c.y >= grid.y || c.z >= grid.z ||
          c.value != tile_value(c.x, c.y, c.z)) {
        fprintf(stderr, "invalid claim from CTA %u, request %u (%u,%u,%u)\n", i, lane, c.x, c.y, c.z);
        return 1;
      }
      ++successes[lane];
      ++owners[c.x + grid.x * (c.y + grid.y * c.z)];
    }
  }
  for (unsigned i = 0; i < count; ++i) {
    if (owners[i] != 1) { fprintf(stderr, "tile %u has %u owners\n", i, owners[i]); return 1; }
  }
  if (count == 1 ? declines != 2 : !successes[0] || !successes[1]) {
    fprintf(stderr, "unexpected request counts %u/%u successful, %u declined\n", successes[0], successes[1], declines);
    return 1;
  }
  printf("PASSED! direct CUDA %s grid=%ux%ux%u physical=%u lane3=%u lane21=%u declined=%u CPU tiles=%u/%u\n",
         expect_first ? "expect-first" : "issue-first", grid.x, grid.y, grid.z,
         physical, successes[0], successes[1], declines, count, count);
  return 0;
}

int main() {
  for (int first = 0; first <= 1; ++first) {
    if (run(dim3(1), first) || run(dim3(8, 4, 4), first)) return 1;
  }
  return 0;
}
