#pragma once

#include <stddef.h>
namespace cupbop {
namespace tcgen05 {

namespace detail {

template <unsigned Bits, unsigned SourceBits>
__device__ __forceinline__ void pack_a(unsigned dst, const void *src, unsigned lda) {
  static_assert(Bits == 4 || Bits == 8 || Bits == 16 || Bits == 32, "unsupported TMEM element width");
  const unsigned row = threadIdx.x + blockDim.x * (threadIdx.y + blockDim.y * threadIdx.z);
  const unsigned address = dst + ((row & ~31u) << 16);
  const unsigned char *bytes = static_cast<const unsigned char *>(src);
  constexpr unsigned perWord = 32 / Bits;
#pragma unroll
  for (unsigned col = 0; col < 8; col += 4) {
    unsigned words[4] = {};
#pragma unroll
    for (unsigned w = 0; w < 4; ++w) {
#pragma unroll
      for (unsigned e = 0; e < perWord; ++e) {
        const unsigned k = (col + w) * perWord + e;
        const size_t index = size_t(k) * lda + row;
        unsigned bits = 0;
        if (SourceBits == 4)
          bits = (bytes[index / 2] >> (4 * (index & 1))) & 15;
        else
          __builtin_memcpy(&bits, bytes + index * (SourceBits / 8), SourceBits / 8);
        words[w] |= (bits & (~0u >> (32 - Bits))) << (e * Bits);
      }
    }
    asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0], {%1,%2,%3,%4};"
                 :: "r"(address + col), "r"(words[0]), "r"(words[1]), "r"(words[2]), "r"(words[3])
                 : "memory");
  }
  asm volatile("tcgen05.wait::st.sync.aligned; tcgen05.fence::before_thread_sync;" ::: "memory");
}

} // namespace detail

// Store a logical column-major A tile as 128 rows of eight K-major TMEM
// words. Four full warps participate, one thread per row. The source is an
// ordinary array in shared or global memory; lda counts *elements* and may
// exceed 128. Bits is the physical width of a CUDA TMEM element/container.
// For packed FP4, even source element indices select the low nibble.
//
// Call before the CTA (or CTA pair) synchronizes to issue its MMA. Keep the
// instruction descriptor's transpose-A bit clear for a TMEM A operand.
template <unsigned Bits>
__device__ __forceinline__ void store_mn_major_a(unsigned dst, const void *src, unsigned lda) {
  detail::pack_a<Bits, Bits>(dst, src, lda);
}

// Transpose the first K rows of a 128-column row-major TMEM accumulator
// into K-major TMEM A, where K = 256 / Bits. Each source word must already
// contain the desired element encoding in its low Bits. All 128 threads
// participate. Supply K * 128 shared scratch words and wait for the
// producer before entry. All input reads finish before writing dst.
template <unsigned Bits>
__device__ __forceinline__ void transpose_tmem_a(unsigned dst, unsigned src, unsigned *scratch) {
  constexpr unsigned kExtent = 256 / Bits;
  const unsigned row = threadIdx.x + blockDim.x * (threadIdx.y + blockDim.y * threadIdx.z);
  if ((row & ~31u) < kExtent) {
    const unsigned address = src + ((row & ~31u) << 16);
#pragma unroll 1
    for (unsigned col = 0; col < 128; col += 4) {
      unsigned words[4];
      asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                   : "=r"(words[0]), "=r"(words[1]), "=r"(words[2]), "=r"(words[3]) : "r"(address + col) : "memory");
      if (row < kExtent) {
#pragma unroll
        for (unsigned i = 0; i < 4; ++i) scratch[row * 128 + col + i] = words[i];
      }
    }
  }
  asm volatile("tcgen05.fence::before_thread_sync;" ::: "memory");
  __syncthreads();
  asm volatile("tcgen05.fence::after_thread_sync;" ::: "memory");
  detail::pack_a<Bits, 32>(dst, scratch, 128);
}

} // namespace tcgen05
} // namespace cupbop
