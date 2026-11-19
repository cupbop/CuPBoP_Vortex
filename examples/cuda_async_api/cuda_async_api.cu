#include "../async_common.h"
#include <cooperative_groups.h>
#define CG_COPY 0
#define BLOCK_BARRIER 1
#define BLOCK_PIPE 2
#define THREAD_PIPE 3
#define PARTITIONED_PIPE 4
#ifndef ASYNC_API
#define ASYNC_API CG_COPY
#endif
#if ASYNC_API == CG_COPY
#include <cooperative_groups/memcpy_async.h>
#elif ASYNC_API == BLOCK_BARRIER
#include <cuda/barrier>
#else
#include <cuda/pipeline>
#endif

namespace cg = cooperative_groups;
constexpr unsigned blocks = 2, threads = 64, depth = 3, tiles = 7, width = threads * 4;
constexpr unsigned count = blocks * tiles * width;

__global__ void copy_tiles(const int *src, int *out) {
  __shared__ __align__(16) int buf[depth][width];
  auto group = cg::this_thread_block();
  const unsigned tid = threadIdx.x;
  const unsigned base = blockIdx.x * tiles * width;
#if ASYNC_API == PARTITIONED_PIPE
  __shared__ cuda::pipeline_shared_state<cuda::thread_scope_block, depth> state;
  const bool producer = tid < threads / 2;
  auto pipe = cuda::make_pipeline(group, &state, producer ? cuda::pipeline_role::producer : cuda::pipeline_role::consumer);
  for (unsigned t = 0; t < tiles; ++t) {
    int *stage = buf[t % depth];
    if (producer) {
      pipe.producer_acquire();
      for (unsigned j = 4 * tid; j < width; j += 4 * (threads / 2))
        cuda::memcpy_async(stage + j, src + base + t * width + j, cuda::aligned_size_t<16>(16), pipe);
      pipe.producer_commit();
    } else {
      pipe.consumer_wait();
      for (unsigned j = tid - threads / 2; j < width; j += threads / 2)
        out[base + t * width + j] = stage[(j + 17) % width];
      pipe.consumer_release();
    }
  }
#else
#if ASYNC_API == BLOCK_BARRIER
  __shared__ cuda::barrier<cuda::thread_scope_block> bar;
  if (tid == 0) init(&bar, threads);
  group.sync();
#elif ASYNC_API == BLOCK_PIPE
  __shared__ cuda::pipeline_shared_state<cuda::thread_scope_block, depth> state;
  auto pipe = cuda::make_pipeline(group, &state);
#elif ASYNC_API == THREAD_PIPE
  auto pipe = cuda::make_pipeline();
#endif
  unsigned fetched = 0;
  for (unsigned t = 0; t < tiles; ++t) {
#if ASYNC_API == BLOCK_PIPE || ASYNC_API == THREAD_PIPE
    while (fetched < tiles && fetched < t + depth) {
      int *stage = buf[fetched % depth];
      const int *input = src + base + fetched * width;
      pipe.producer_acquire();
#if ASYNC_API == BLOCK_PIPE
      cuda::memcpy_async(group, stage, input, cuda::aligned_size_t<16>(sizeof(buf[0])), pipe);
#else
      cuda::memcpy_async(stage + 4 * tid, input + 4 * tid, cuda::aligned_size_t<16>(16), pipe);
#endif
      pipe.producer_commit();
      ++fetched;
    }
    pipe.consumer_wait();
    group.sync();
#elif ASYNC_API == BLOCK_BARRIER
    cuda::memcpy_async(group, buf[t % depth], src + base + t * width, cuda::aligned_size_t<16>(sizeof(buf[0])), bar);
    bar.arrive_and_wait();
#else
    cg::memcpy_async(group, buf[t % depth], src + base + t * width, sizeof(buf[0]));
    cg::wait(group);
#endif
    for (unsigned j = tid; j < width; j += threads)
      out[base + t * width + j] = buf[t % depth][(j + 17) % width];
    group.sync();
#if ASYNC_API == BLOCK_PIPE || ASYNC_API == THREAD_PIPE
    pipe.consumer_release();
#endif
  }
#endif
}

#if ASYNC_API == BLOCK_PIPE
// Exercise both match widths used for warp aggregation in the CUDA headers.
// The keys agree in their low 32 bits; the 64-bit result must also compare hi.
__global__ void match_keys(unsigned *masks) {
  unsigned lane = threadIdx.x;
  unsigned members = __activemask();
  unsigned low = lane % 3;
  unsigned long long key = (static_cast<unsigned long long>(lane % 2) << 32) | low;
  masks[lane] = __match_any_sync(members, low);
  masks[32 + lane] = __match_any_sync(members, key);
}

static int check_matches() {
  constexpr unsigned active = 27;
  unsigned *device, host[64] = {};
  ASYNC_CHECK(cudaMalloc(&device, sizeof(host)));
  match_keys<<<1, active>>>(device);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(host, device, sizeof(host), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device));
  for (unsigned lane = 0; lane < active; ++lane) {
    unsigned low = 0, both = 0;
    for (unsigned other = 0; other < active; ++other) {
      if (lane % 3 == other % 3) {
        low |= 1u << other;
        if (lane % 2 == other % 2) both |= 1u << other;
      }
    }
    if (host[lane] != low || host[32 + lane] != both) {
      printf("FAIL match lane %u, masks %x %x, expected %x %x\n", lane, host[lane], host[32 + lane], low, both);
      return 1;
    }
  }
  return 0;
}
#endif

int main() {
#if ASYNC_API == BLOCK_PIPE
  if (check_matches()) return 1;
#endif
  int input[count], actual[count], *src, *dst;
  for (unsigned i = 0; i < count; ++i) input[i] = 19 * i + 3;
  ASYNC_CHECK(cudaMalloc(&src, sizeof(input)));
  ASYNC_CHECK(cudaMalloc(&dst, sizeof(actual)));
  ASYNC_CHECK(cudaMemcpy(src, input, sizeof(input), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemset(dst, 0, sizeof(actual)));
  copy_tiles<<<blocks, threads>>>(src, dst);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(actual, dst, sizeof(actual), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(dst));
  ASYNC_CHECK(cudaFree(src));
  for (unsigned i = 0; i < count; ++i) {
    int expected = input[(i / width) * width + (i % width + 17) % width];
    if (actual[i] != expected) {
      printf("FAIL mode=%d word=%u device=%d cpu=%d\n", ASYNC_API, i, actual[i], expected);
      return 1;
    }
  }
  printf("PASSED! async mode=%d, %u words, %u tiles per CTA\n", ASYNC_API, count, tiles);
  return 0;
}
