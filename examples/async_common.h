// PTX helpers for the async examples (examples/async_*; experiments/async_design/corpus): device side written
// the way CUTLASS / cute spell them, plus small host helpers. Valid for nvcc (sm_90a, sm_80 for the cp.async
// mbarrier example) and for CuPBoP (clang CUDA front end -> translator lower_async_ptx).
#pragma once
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
__device__ __forceinline__ uint32_t smem_u32(const void *p) { return (uint32_t)__cvta_generic_to_shared(p); }
__device__ __forceinline__ void mbar_init(uint64_t *b, uint32_t cnt) {
  asm volatile("mbarrier.init.shared::cta.b64 [%0], %1;" ::"r"(smem_u32(b)), "r"(cnt) : "memory");
}
__device__ __forceinline__ void mbar_init_fence() { asm volatile("fence.mbarrier_init.release.cluster;" ::: "memory"); }
__device__ __forceinline__ void mbar_arrive(uint64_t *b) {
  asm volatile("{ .reg .b64 st; mbarrier.arrive.shared::cta.b64 st, [%0]; }" ::"r"(smem_u32(b)) : "memory");
}
__device__ __forceinline__ void mbar_arrive_expect_tx(uint64_t *b, uint32_t bytes) {
  asm volatile("mbarrier.arrive.expect_tx.shared::cta.b64 _, [%0], %1;" ::"r"(smem_u32(b)), "r"(bytes) : "memory");
}
__device__ __forceinline__ void mbar_wait(uint64_t *b, uint32_t parity) { // sm_90 try_wait loop
  asm volatile("{ .reg .pred p; WAIT_%=: mbarrier.try_wait.parity.shared::cta.b64 p, [%0], %1; @!p bra WAIT_%=; }"
               ::"r"(smem_u32(b)), "r"(parity) : "memory");
}
__device__ __forceinline__ void mbar_wait_test(uint64_t *b, uint32_t parity) { // sm_80 test_wait loop
  asm volatile("{ .reg .pred p; WAIT_%=: mbarrier.test_wait.parity.shared.b64 p, [%0], %1; @!p bra WAIT_%=; }"
               ::"r"(smem_u32(b)), "r"(parity) : "memory");
}
// exact small-integer test data (float sums stay exact)
static inline float async_val(int i) { return (float)((i * 7 + 3) % 13) - 6.0f; }
#define ASYNC_CHECK(call)                                                                  \
  do {                                                                                     \
    if ((call) != 0) { printf("FAILED! %s returned an error\n", #call); return 1; }        \
  } while (0)
