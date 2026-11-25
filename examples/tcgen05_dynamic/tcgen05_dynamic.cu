#include "../tcgen05_test.h"

constexpr unsigned rows = 128, maxColumns = 32, untouched = 0x41300000u;

#ifdef CUPBOP_TEST_NAMED_MMA
using taddr = unsigned __attribute__((address_space(6))) *;
extern "C" __device__ void named_half(taddr, uint64_t, uint64_t, unsigned, bool, unsigned, unsigned, unsigned)
    asm("llvm.nvvm.tcgen05.mma.shared");
extern "C" __device__ void named_mx(taddr, uint64_t, uint64_t, unsigned, bool, taddr, taddr, unsigned, unsigned)
    asm("llvm.nvvm.tcgen05.mma.shared.mxf8f6f4.block_scale");
#endif

// Each CUDA row contains 32 bytes of A or B, independent of the instruction
// descriptor selected by the host. N=16 leaves the other 16 D columns intact.
template <bool scaled>
__global__ void dynamic_mma(unsigned desc, unsigned *out) {
  __shared__ __align__(128) unsigned a[rows * 8], b[maxColumns * 8];
  __shared__ unsigned slot;
  __shared__ uint64_t barrier;
  unsigned row = threadIdx.x;
  for (unsigned i = row; i < rows * 8; i += rows) a[i] = scaled ? 0x3c3c3c3c : 0x3f803f80;
  for (unsigned i = row; i < maxColumns * 8; i += rows) b[i] = scaled ? 0x40404040 : 0x40004000;
  if (!row) mbar_init(&barrier, 1);
  if (row < 32) asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0], 64;" ::
                             "r"(smem_u32(&slot)) : "memory");
  __syncthreads();
  unsigned addr = slot + ((row & ~31u) << 16);
  for (unsigned col = 0; col < maxColumns; col += 4)
    asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0], {%1,%1,%1,%1};" ::
                 "r"(addr + col), "r"(untouched) : "memory");
  if (scaled) {
    // Distinct E8M0 scale-factor bytes make each selector observable.
    asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0], {%1,%1,%1,%1};" ::
                 "r"(addr + 32), "r"(0x81807f7eu) : "memory");
    asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0], {%1,%1,%1,%1};" ::
                 "r"(addr + 36), "r"(0x7e7f8081u) : "memory");
  }
  asm volatile("tcgen05.wait::st.sync.aligned;" ::: "memory");
  __syncthreads();
  tcgen_after_sync();
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  if (!row) {
    uint64_t layout = (8ull << 16) | (16ull << 32) | (1ull << 46);
    uint64_t ad = layout | ((smem_u32(a) >> 4) & 0x3fff);
    uint64_t bd = layout | ((smem_u32(b) >> 4) & 0x3fff);
#ifdef CUPBOP_TEST_NAMED_MMA
    if (scaled) named_mx((taddr)(uintptr_t)slot, ad, bd, desc, false,
                         (taddr)(uintptr_t)(slot + 32), (taddr)(uintptr_t)(slot + 36), 1, 0);
    else named_half((taddr)(uintptr_t)slot, ad, bd, desc, false, 0, 1, 0);
#else
    if (scaled)
      asm volatile("{ .reg .pred p; setp.ne.u32 p,0,0; tcgen05.mma.cta_group::1.kind::mxf8f6f4.block_scale.scale_vec::1X "
                   "[%0],%1,%2,%3,[%4],[%5],p; }" :: "r"(slot), "l"(ad), "l"(bd), "r"(desc),
                   "r"(slot + 32), "r"(slot + 36) : "memory");
    else
      asm volatile("{ .reg .pred p; setp.ne.u32 p,0,0; tcgen05.mma.cta_group::1.kind::f16 [%0],%1,%2,%3,p; }" ::
                   "r"(slot), "l"(ad), "l"(bd), "r"(desc) : "memory");
#endif
    asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];" ::
                 "r"(smem_u32(&barrier)) : "memory");
  }
  __syncthreads();
  mbar_wait(&barrier, 0);
  tcgen_after_sync();
  for (unsigned col = 0; col < maxColumns; col += 4) {
    unsigned v[4];
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3},[%4]; tcgen05.wait::ld.sync.aligned;"
                 : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3]) : "r"(addr + col) : "memory");
    for (unsigned j = 0; j < 4; ++j) out[row * maxColumns + col + j] = v[j];
  }
  __syncthreads();
  if (row < 32) asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0,64;" ::
                             "r"(slot) : "memory");
}

int main(int argc, char **argv) {
  unsigned *device, out[rows * maxColumns];
  ASYNC_CHECK(cudaMalloc(&device, sizeof(out)));
  if (argc > 1 && !strcmp(argv[1], "invalid")) {
    dynamic_mma<false><<<1, rows>>>(0, device); // invalid dimensions
    ASYNC_CHECK(cudaDeviceSynchronize());
    puts("invalid descriptor completed without a device trap");
    return 0; // A negative-test harness expects the device to have stopped.
  }
  // Reuse the lifted half kernel on targets with FP16 but without TF32.
  // A mixed F16/BF16 descriptor specifically needs the TF32 conversion path.
  const bool mixedHalf = argc > 1 && !strcmp(argv[1], "mixed");
  unsigned tests = mixedHalf ? 1 : argc > 1 && !strcmp(argv[1], "half") ? 2 : 4;
  unsigned errors = 0;
  for (unsigned test = 0; test < tests; ++test) {
    bool scaled = test >= 2;
    unsigned n = test & 1 ? 32 : 16;
    unsigned desc = (8u << 24) | (n / 8 << 17);
    if (scaled) {
      desc |= 1u << 23;
      if (test & 1) desc |= (1u << 7) | (1u << 10) | (3u << 29) | (1u << 4);
      dynamic_mma<true><<<1, rows>>>(desc, device);
    } else {
      desc |= 0x10;
      if (mixedHalf) desc |= 1u << 10;
      if (test & 1) desc |= (1u << 7) | (1u << 10) | (1u << 13);
      dynamic_mma<false><<<1, rows>>>(desc, device);
    }
    ASYNC_CHECK(cudaMemcpy(out, device, sizeof(out), cudaMemcpyDeviceToHost));
    // FP16: 1.875*2*16. BF16: -1*2*16. MXFP8: (1.5*.5)*(2*4)*32.
    // MXBF8: (1*4)*(2*2)*32.
    const float values[] = {60.f, -32.f, 192.f, 512.f};
    unsigned product;
    memcpy(&product, &values[test], sizeof(product));
    for (unsigned i = 0; i < rows * maxColumns; ++i)
      errors += out[i] != (i % maxColumns < n ? product : untouched);
  }
  ASYNC_CHECK(cudaFree(device));
  printf("dynamic descriptor mismatches=%u/%u\n", errors, tests * rows * maxColumns);
  return errors != 0;
}
