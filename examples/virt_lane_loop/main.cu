#include <cstdio>
#include <cuda_runtime.h>

constexpr int threads = 64;
constexpr int rounds = 4;
constexpr int fields = rounds * rounds + 2;

// The first eight lanes and the entire second logical warp do no work.
// Other groups finish on different outer
// iterations, and individual lanes can finish the inner loop early.
__global__ void lane_loops(unsigned *out) {
  int t = threadIdx.x, lane = t & 31;
  unsigned *row = out + t * fields;
  int groups = t < 32 ? lane / 8 : 0;
  int visits = 0;
  for (int i = 0; i < groups; ++i) {
    for (int j = 0; j <= ((lane + i) & 3); ++j) {
      row[i * rounds + j] = __ballot_sync(__activemask(), (lane & 1) == (i & 1));
      ++visits;
      if (j == 0 && (lane & 4)) break;
    }
  }
  row[fields - 2] = visits;
  row[fields - 1] = __ballot_sync(0xffffffffu, groups == 0);
}

// The two exits have different continuations. The early return must retain
// the mask observed on that iteration while other lanes finish the loop.
__global__ void separate_exits(unsigned *out) {
  int t = threadIdx.x, lane = t & 31;
  unsigned seen = 0;
  for (int i = 0; ; ++i) {
    seen ^= __ballot_sync(__activemask(), true);
    if (i == lane / 8) break;
    if (i == 1 && (lane & 1)) {
      out[t] = ~seen;
      return;
    }
  }
  out[t] = seen;
}

// The limit is chosen by control flow. Only the first iteration contains
// a full-mask shuffle, which every CUDA lane reaches.
__global__ void branch_bounds(unsigned *out) {
  int t = threadIdx.x, lane = t & 31;
  volatile int limit = 1;
  if (lane >= 16) limit = 3;
  unsigned value = 0;
  for (int i = 0; i < limit; ++i) {
    if (i == 0) value = __shfl_xor_sync(0xffffffffu, lane, 8);
    value += i + 1;
  }
  out[t] = value;
}

// A vote is uniform within its member mask. Adjacent 8-lane groups use
// different masks at the same instruction and compute different loop bounds.
__global__ void vote_bounds(unsigned *out) {
  int t = threadIdx.x, lane = t & 31;
  unsigned members = 0xffu << (lane & 24);
  int bound = __ballot_sync(members, lane >= 8) ? 3 : 1;
  unsigned value = 0;
  for (int i = 0; i < bound; ++i)
    value ^= __ballot_sync(__activemask(), true) + i;
  out[t] = value;
}

int main() {
  unsigned result[threads * fields], expected[threads * fields] = {};
  unsigned *device;
  if (cudaMalloc(&device, sizeof(result)) != cudaSuccess) return 1;
  if (cudaMemset(device, 0, sizeof(result)) != cudaSuccess) return 1;
  lane_loops<<<1, threads>>>(device);
  if (cudaMemcpy(result, device, sizeof(result), cudaMemcpyDeviceToHost) != cudaSuccess) return 1;

  for (int i = 0; i < rounds; ++i) {
    for (int j = 0; j < rounds; ++j) {
      unsigned active = 0;
      for (int l = 0; l < 32; ++l)
        if (i < l / 8 && j <= ((l + i) & 3) && (j == 0 || !(l & 4))) active |= 1u << l;
      for (int t = 0; t < 32; ++t)
        if (active & (1u << t)) {
          expected[t * fields + i * rounds + j] = active & (i & 1 ? 0xaaaaaaaau : 0x55555555u);
          ++expected[t * fields + fields - 2];
        }
    }
  }
  for (int t = 0; t < threads; ++t) expected[t * fields + fields - 1] = t < 32 ? 0xffu : 0xffffffffu;
  for (int k = 0; k < threads * fields; ++k)
    if (result[k] != expected[k]) {
      std::printf("FAIL thread %d field %d got %08x expected %08x\n",
                  k / fields, k % fields, result[k], expected[k]);
      return 1;
    }
  separate_exits<<<1, threads>>>(device);
  if (cudaMemcpy(result, device, threads * sizeof(unsigned), cudaMemcpyDeviceToHost) != cudaSuccess) return 1;
  unsigned active = 0xffffffffu, seen = 0;
  for (int i = 0; i < rounds; ++i) {
    seen ^= active;
    for (int l = 0; l < 32; ++l) {
      if (!(active & (1u << l))) continue;
      bool early = i == 1 && (l & 1) && i < l / 8;
      if (i != l / 8 && !early) continue;
      for (int t = l; t < threads; t += 32)
        if (result[t] != (early ? ~seen : seen)) {
          std::printf("FAIL exit thread %d got %08x expected %08x\n", t, result[t], early ? ~seen : seen);
          return 1;
        }
      active &= ~(1u << l);
    }
  }
  branch_bounds<<<1, threads>>>(device);
  if (cudaMemcpy(result, device, threads * sizeof(unsigned), cudaMemcpyDeviceToHost) != cudaSuccess) return 1;
  for (int t = 0; t < threads; ++t) {
    unsigned want = ((t & 31) ^ 8) + ((t & 16) ? 6 : 1);
    if (result[t] != want) {
      std::printf("FAIL trip count thread %d got %u expected %u\n", t, result[t], want);
      return 1;
    }
  }
  vote_bounds<<<1, threads>>>(device);
  if (cudaMemcpy(result, device, threads * sizeof(unsigned), cudaMemcpyDeviceToHost) != cudaSuccess) return 1;
  cudaFree(device);
  for (int t = 0; t < threads; ++t) {
    unsigned want = 0xffffffffu;
    if ((t & 31) >= 8) want ^= 0xffffff01u ^ 0xffffff02u;
    if (result[t] != want) {
      std::printf("FAIL subgroup ballot thread %d got %08x expected %08x\n", t, result[t], want);
      return 1;
    }
  }
  std::puts("PASSED");
  return 0;
}
