// The TMEM issuer and the TMA producer can be different warps in a single CTA.
// Check both posting orders and every swizzled word, including out-of-bounds rows.
#include <cuda.h>
#include "../tcgen05_test.h"

constexpr unsigned width = 32, height = 4, depth = 2, batches = 2, rows = 3;
constexpr unsigned words = width * rows * depth * batches;

__global__ void tma_phases(const __grid_constant__ CUtensorMap map, int *out) {
  extern __shared__ __align__(16) unsigned char arena[];
  // Start one 128-byte row into an aligned swizzle pattern.
  int *tile = (int *)(((uintptr_t(arena) + 1023) & ~uintptr_t(1023)) + 128);
  __shared__ uint32_t slot;
  __shared__ uint64_t bar;
  unsigned tid = threadIdx.x;
  if (tid < 32)
    asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0], 512;" ::"r"(smem_u32(&slot))
                 : "memory");
  if (!tid) {
    mbar_init(&bar, 1);
    mbar_init_fence();
  }
  __syncthreads();
  for (int phase = 0; phase < 2; ++phase) {
    if (!phase && !tid) mbar_arrive_expect_tx(&bar, 4 * words);
    __syncthreads();
    if (tid == 32)
      asm volatile("cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes "
                   "[%0], [%1, {0, %2, 0, 0}], [%3];" ::"r"(smem_u32(tile)),
                   "l"((uint64_t)&map), "r"(1 + phase), "r"(smem_u32(&bar))
                   : "memory");
    __syncthreads();
    if (phase && !tid) mbar_arrive_expect_tx(&bar, 4 * words);
    mbar_wait(&bar, phase);
    for (unsigned i = tid; i < words; i += blockDim.x) {
      const unsigned row = i / width;
      unsigned bank = (i % width) ^ (((row + 1) % 8) * 4);
      out[phase * words + i] = tile[row * width + bank];
    }
    __syncthreads();
  }
  // This launch has one CTA, so cancellation must decline and complete 16 bytes.
  __shared__ __align__(16) uint32_t response[4];
  __shared__ uint64_t work_bar;
  // This is the literal STS.64 initialization emitted by SM100 ptxas for
  // expected-count 1. The archive writes it without a PTX mbarrier.init.
  if (!tid) {
    work_bar = 0x7ffff800001ffffeull;
    mbar_init_fence();
  }
  __syncthreads();
  if (!tid) {
    for (int i = 0; i < 4; ++i)
      response[i] = ~0u;
    mbar_arrive_expect_tx(&work_bar, 16);
    asm volatile("clusterlaunchcontrol.try_cancel.async.mbarrier::complete_tx::bytes.multicast::cluster::all.b128 "
                 "[%0], [%1];" ::"r"(smem_u32(response)),
                 "r"(smem_u32(&work_bar))
                 : "memory");
  }
  mbar_wait(&work_bar, 0);
  // The library also initializes barriers with expected-count 256. Check that
  // 192 arrivals from two warps leave the phase open, then finish the phase.
  __shared__ uint64_t participants;
  if (!tid) {
    constexpr uint64_t biased = (1u << 20) - 256;
    participants = (biased << 1) | (biased << 43);
    mbar_init_fence();
  }
  __syncthreads();
  for (int i = 0; i < 3; ++i) mbar_arrive(&participants);
  __syncthreads();
  unsigned early = 0;
  if (!tid)
    asm volatile("{ .reg .pred p; mbarrier.test_wait.parity.shared::cta.b64 p, [%1], 0; selp.u32 %0, 1, 0, p; }"
                 : "=r"(early) : "r"(smem_u32(&participants)) : "memory");
  __syncthreads();
  mbar_arrive(&participants);
  mbar_wait(&participants, 0);
  if (!tid) out[2 * words] = (response[2] & 1u) | (early << 1);
  if (tid < 32)
    asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0, 512; "
                 "tcgen05.relinquish_alloc_permit.cta_group::1.sync.aligned;" ::"r"(slot)
                 : "memory");
}

int main() {
  int input[width * height * depth * batches], actual[2 * words + 1], *src, *dst;
  for (unsigned i = 0; i < sizeof(input) / sizeof(int); ++i)
    input[i] = 11 * i - 237;
  ASYNC_CHECK(cudaMalloc(&src, sizeof(input)));
  ASYNC_CHECK(cudaMalloc(&dst, sizeof(actual)));
  ASYNC_CHECK(cudaMemcpy(src, input, sizeof(input), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemset(dst, 0xa5, sizeof(actual)));
  CUtensorMap map;
  cuuint64_t dims[] = {width, height, depth, batches}, strides[] = {128, 128 * height, 128 * height * depth};
  cuuint32_t box[] = {width, rows, depth, batches}, step[] = {1, 1, 1, 1};
  ASYNC_CHECK(cuTensorMapEncodeTiled(&map, CU_TENSOR_MAP_DATA_TYPE_INT32, 4, src, dims, strides, box, step,
                                     CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_128B,
                                     CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
  tma_phases<<<1, 64, 1024 + 128 + 4 * words>>>(map, dst);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(actual, dst, sizeof(actual), cudaMemcpyDeviceToHost));
  int reference[2 * words + 1] = {};
  unsigned errors = actual[2 * words] != 0;
  for (unsigned phase = 0; phase < 2; ++phase)
    for (unsigned i = 0; i < words; ++i) {
      unsigned y = i / width % rows + 1 + phase;
      int expected = y < height ? input[(i / (width * rows) * height + y) * width + i % width] : 0;
      reference[phase * words + i] = expected;
      if (expected != actual[phase * words + i]) ++errors;
    }
  printf("TMA 4D phases=2 words=%u cancellation=%d mismatches=%u\n", 2 * words, actual[2 * words], errors);
  int io_error = dump_tcgen_words("cpu.i32", reference, 2 * words + 1) | dump_tcgen_words("vortex.i32", actual, 2 * words + 1);
  cudaFree(dst);
  cudaFree(src);
  return errors != 0 || io_error;
}
