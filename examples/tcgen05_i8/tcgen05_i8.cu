// Two full m128n256k32 operations, the second accumulating into the first.
// Test both the interleaved layout and the library's 128-byte swizzle.
#include "../tcgen05_test.h"

static __host__ __device__ int av(int block, int r, int k) {
  return r == 0 ? -128 : (r * 31 + k * 53 + block) % 256 - 128;
}
static __host__ __device__ int bv(int block, int c, int k) {
  if (c == 0) return -128;
  if (c == 255) return 127;
  return (c * 41 + k * 23 + block * 2) % 256 - 128;
}

static __device__ unsigned index_in_smem(int row, int k, bool swizzled) {
  if (!swizzled) return (row / 8) * 256 + (k / 16) * 128 + (row % 8) * 16 + k % 16;
  return row * 128 + (k ^ ((row % 8) * 16));
}
static __device__ uint64_t descriptor(int8_t *base, bool swizzled) {
  uint64_t d = (smem_u32(base) >> 4) & 0x3fff;
  return d | (8ull << 16) | ((swizzled ? 64ull : 16ull) << 32) | (1ull << 46) | (swizzled ? 2ull << 61 : 0);
}

__global__ void test_tile(int *out, int swizzled) {
  extern __shared__ __align__(16) int8_t arena[];
  // Base-offset zero in the 128B descriptor requires a 1024-byte swizzle pattern boundary.
  auto *smem = reinterpret_cast<int8_t *>((reinterpret_cast<uintptr_t>(arena) + 1023) & ~uintptr_t(1023));
  __shared__ uint32_t slot;
  __shared__ uint64_t barrier;
  int8_t *a = smem, *b = smem + (swizzled ? 128 * 128 : 128 * 32);
  const unsigned r = threadIdx.x;
  for (int k = 0; k < 32; ++k) {
    a[index_in_smem(r, k, swizzled)] = av(blockIdx.x, r, k);
    for (unsigned col : {r, r + 128})
      b[index_in_smem(col, k, swizzled)] = bv(blockIdx.x, col, k);
  }
  if (r == 0) mbar_init(&barrier, 1);
  if (r < 32)
    asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0], 512;" ::"r"(smem_u32(&slot))
                 : "memory");
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  __syncthreads();
  tcgen_after_sync();
  const uint32_t taddr = slot;
  for (int iteration = 0; iteration < 2; ++iteration) {
    if (r == 0) {
      asm volatile(
          "{ .reg .pred p; setp.ne.u32 p, %3, 0; tcgen05.mma.cta_group::1.kind::i8 [%0], %1, %2, 0x084004a0, p; }" ::
              "r"(taddr),
          "l"(descriptor(a, swizzled)), "l"(descriptor(b, swizzled)), "r"(iteration)
          : "memory");
      asm volatile(
          "tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];" ::"r"(smem_u32(&barrier))
          : "memory");
    }
    // Park the other warps while the single issuer computes the software tile.
    // The TMA example independently tests waiting for producers in other warps.
    __syncthreads();
    mbar_wait(&barrier, iteration);
    tcgen_after_sync();
    for (unsigned col = 0; col < 256; col += 4) {
      const uint32_t p = taddr + ((r & ~31u) << 16) + col;
      uint32_t v[4];
      if (iteration) {
        asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                     : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3])
                     : "r"(p)
                     : "memory");
      } else {
        for (int j = 0; j < 4; j += 2)
          asm volatile("tcgen05.ld.sync.aligned.32x32b.x2.b32 {%0,%1}, [%2]; tcgen05.wait::ld.sync.aligned;"
                       : "=r"(v[j]), "=r"(v[j + 1])
                       : "r"(p + j)
                       : "memory");
      }
      for (unsigned j = 0; j < 4; ++j)
        out[((blockIdx.x * 2 + iteration) * 128 + r) * 256 + col + j] = v[j];
    }
    tcgen_before_sync();
    __syncthreads();
  }
  if (r < 32)
    asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0, 512; "
                 "tcgen05.relinquish_alloc_permit.cta_group::1.sync.aligned;" ::"r"(taddr)
                 : "memory");
}
int main(int argc, char **argv) {
  int mode = argc > 1 ? atoi(argv[1]) : 1;
  const int blocks = 2, elements = blocks * 2 * 128 * 256;
  int *dev, *host = (int *)malloc(elements * sizeof(int));
  ASYNC_CHECK(cudaMalloc(&dev, elements * sizeof(int)));
  ASYNC_CHECK(cudaMemset(dev, 0xa5, elements * sizeof(int)));
  unsigned dynamic = (mode ? 49152 : 12288) + 1023;
#ifdef __NVCC__
  ASYNC_CHECK(cudaFuncSetAttribute(test_tile, cudaFuncAttributeMaxDynamicSharedMemorySize, dynamic));
#endif
  test_tile<<<blocks, 128, dynamic>>>(dev, mode);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(host, dev, elements * sizeof(int), cudaMemcpyDeviceToHost));
  int errors = 0;
  int *reference = (int *)malloc(elements * sizeof(int));
  for (int block = 0; block < blocks; ++block)
    for (int r = 0; r < 128; ++r)
      for (int c = 0; c < 256; ++c) {
        int dot = 0;
        for (int k = 0; k < 32; ++k)
          dot += av(block, r, k) * bv(block, c, k);
        for (int i = 0; i < 2; ++i) {
          int offset = ((block * 2 + i) * 128 + r) * 256 + c;
          reference[offset] = (i + 1) * dot;
          int v = host[offset];
          if (v != (i + 1) * dot && errors++ < 4)
            printf("block=%d row=%d col=%d iter=%d expected=%d got=%d\n", block, r, c, i, (i + 1) * dot, v);
        }
      }
  printf("swizzle=%d elements=%d mismatches=%d\n", mode, elements, errors);
  int io_error = dump_tcgen_words("cpu.i32", reference, elements) | dump_tcgen_words("vortex.i32", host, elements);
  free(reference);
  free(host);
  cudaFree(dev);
  return errors != 0 || io_error;
}
