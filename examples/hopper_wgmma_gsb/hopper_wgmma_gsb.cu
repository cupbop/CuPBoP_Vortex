#include "../async_common.h"

__device__ __forceinline__ uint64_t descriptor(const uint16_t *tile) {
  return ((uint64_t)smem_u32(tile) >> 4) | (8ull << 16) | (8ull << 32);
}

template <bool Accumulate>
__device__ __forceinline__ void issue(float (&d)[4], uint64_t a, uint64_t b) {
  asm volatile("{ .reg .pred p; setp.ne.b32 p, %6, 0; "
               "wgmma.mma_async.sync.aligned.m64n8k16.f32.f16.f16 "
               "{%0, %1, %2, %3}, %4, %5, p, 1, 1, 0, 0; }"
               : "+f"(d[0]), "+f"(d[1]), "+f"(d[2]), "+f"(d[3])
               : "l"(a), "l"(b), "r"(int(Accumulate)) : "memory");
}

__device__ __forceinline__ void commit() {
  asm volatile("wgmma.commit_group.sync.aligned;" ::: "memory");
}

template <int Pending>
__device__ __forceinline__ void wait() {
  asm volatile("wgmma.wait_group.sync.aligned %0;" :: "n"(Pending) : "memory");
}

__device__ __forceinline__ void store(float *out, const float (&d)[4]) {
  asm volatile("st.global.v4.f32 [%0], {%1, %2, %3, %4};" ::
               "l"(out), "f"(d[0]), "f"(d[1]), "f"(d[2]), "f"(d[3]) : "memory");
}

extern "C" __global__ void hopper_wgmma_gsb(float *out) {
  __shared__ __align__(128) uint16_t a[2][64 * 16], b[2][8 * 16];
  const unsigned lane = threadIdx.x;
  for (unsigned i = lane; i < 64 * 16; i += 128) {
    a[0][i] = 0x3c00;
    a[1][i] = 0x4200;
  }
  b[0][lane] = 0x4000;
  b[1][lane] = 0x4400;
  __syncthreads();

  const auto a0 = descriptor(a[0]), a1 = descriptor(a[1]);
  const auto b0 = descriptor(b[0]), b1 = descriptor(b[1]);
  float left[4] = {}, right[4] = {};
  asm volatile("wgmma.fence.sync.aligned;" ::: "memory");
  // The first and third groups accumulate into the same registers. The partial
  // wait covers the intervening chain's store, while the last group may be live.
  issue<false>(left, a0, b0);
  commit();
  issue<false>(right, a1, b1);
  commit();
  issue<true>(left, a0, b1);
  commit();
  wait<1>();
  store(out + lane * 8, right);
  wait<0>();
  store(out + lane * 8 + 4, left);
}

int main() {
  constexpr int threads = 128, total = threads * 8;
  float *device, actual[total];
  ASYNC_CHECK(cudaMalloc(&device, sizeof(actual)));
  ASYNC_CHECK(cudaMemset(device, 0, sizeof(actual)));
  hopper_wgmma_gsb<<<1, threads>>>(device);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(actual, device, sizeof(actual), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device));
  int matches = 0;
  for (int i = 0; i != total; ++i)
    matches += actual[i] == ((i & 7) < 4 ? 192.0f : 96.0f);
  printf("%s: %d/%d\n", matches == total ? "PASSED!" : "FAILED!", matches, total);
  return matches != total;
}
