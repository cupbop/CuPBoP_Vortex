#include "../async_common.h"
#include <vector>

constexpr unsigned threads = 64, blocks = 4, words = threads * blocks;

__host__ __device__ static unsigned pattern(unsigned i, unsigned round) {
  return (i * 0x10001u) ^ (round * 0x5a3c832du) ^ 0x7f0009u;
}

__global__ void publish(unsigned *mailbox, unsigned round) {
  __shared__ __align__(16) unsigned tile[threads];
  unsigned lane = threadIdx.x, base = blockIdx.x * threads;
  tile[lane] = pattern(base + lane, round);
  asm volatile("fence.proxy.async::generic.release.sync_restrict::shared::cta.cluster;" ::: "memory");
  __syncthreads();
  if (lane == 0) {
    asm volatile("fence.proxy.async::generic.acquire.sync_restrict::shared::cluster.cluster;" ::: "memory");
    asm volatile("cp.async.bulk.global.shared::cta.bulk_group [%0], [%1], %2;"
                 "cp.async.bulk.commit_group; cp.async.bulk.wait_group 0;"
                 :: "l"(mailbox + base), "r"(smem_u32(tile)), "n"(sizeof(tile)) : "memory");
  }
  __syncthreads();
  asm volatile("griddepcontrol.launch_dependents;" ::: "memory");
}

__global__ void consume(const unsigned *mailbox, unsigned *result) {
  asm volatile("griddepcontrol.wait;" ::: "memory");
  unsigned i = blockIdx.x * threads + threadIdx.x;
  // Each CTA reads the tile published by a different CTA.
  result[i] = mailbox[(i + threads) % words] ^ (i * 3);
}

int main() {
  constexpr unsigned rounds = 3;
  std::vector<unsigned> actual(rounds * words);
  unsigned *mailbox, *result;
  ASYNC_CHECK(cudaMalloc((void **)&mailbox, words * sizeof(unsigned)));
  ASYNC_CHECK(cudaMalloc((void **)&result, actual.size() * sizeof(unsigned)));
  for (unsigned round = 0; round < rounds; ++round) {
    publish<<<blocks, threads>>>(mailbox, round);
    consume<<<blocks, threads>>>(mailbox, result + round * words);
  }
  ASYNC_CHECK(cudaMemcpy(actual.data(), result, actual.size() * sizeof(unsigned), cudaMemcpyDeviceToHost));
  unsigned bad = 0;
  for (unsigned round = 0; round < rounds; ++round)
    for (unsigned i = 0; i < words; ++i) {
      unsigned want = pattern((i + threads) % words, round) ^ (i * 3);
      if (actual[round * words + i] != want) ++bad;
    }
  ASYNC_CHECK(cudaFree(result));
  ASYNC_CHECK(cudaFree(mailbox));
  printf("Directional proxy fences and dependent launches: %u/%zu mismatches\n", bad, actual.size());
  return bad != 0;
}
