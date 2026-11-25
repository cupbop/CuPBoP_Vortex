#include "../tcgen05_test.h"
#include <vector>

constexpr unsigned rows = 128, cols = 16, stride = cols + 8;

// The MMA consumes one byte in each scale word. The post-MMA reads also check
// the untouched bytes, every replicated warp and the unused B scale rows.
__host__ __device__ static unsigned scale_word(unsigned row, bool b) {
  unsigned exponent = (row / 7 + 2 * row + unsigned(b)) % 3 + 126;
  return b ? (exponent << 24) | 0x379400 | row : 0x93520040 | (exponent << 8) | (row << 16);
}

// Use distinct signs along M, N and K so a swapped row or 16-byte core vector
// alters the dot product. Both FP8 formats represent +1 and -1 exactly.
__host__ __device__ static int element(unsigned row, unsigned k, bool b) {
  return ((row * (b ? 5 : 3) + k * (b ? 3 : 5) + k / 4) % (b ? 11 : 13)) < 3 ? -1 : 1;
}

__device__ static unsigned packed_word(unsigned i, bool b, unsigned dtype) {
  unsigned row = i / 64 * 8 + i % 32 / 4, k = i / 32 % 2 * 16 + i % 4 * 4, word = 0;
  for (unsigned byte = 0; byte < 4; ++byte) {
    unsigned raw = (dtype ? 0x3cu : 0x38u) | (element(row, k + byte, b) < 0 ? 0x80u : 0);
    word |= raw << (byte * 8);
  }
  return word;
}

__device__ static uint64_t tile_desc(const void *p, unsigned bytes) {
  return ((smem_u32(p) >> 4) & 16383u) | (8ull << 16) | (uint64_t(bytes / 2) << 32) | (1ull << 46);
}

template <bool publish_copies, unsigned atype, unsigned btype>
__global__ void scale_placement(unsigned *out, unsigned b_offset) {
  __shared__ __align__(128) unsigned a[rows * 32 / 4], b[cols * 32 / 4];
  __shared__ __align__(128) unsigned scale_a[32][4], scale_b[32][4];
  __shared__ uint64_t done, copies_done;
  __shared__ unsigned base;
  const unsigned row = threadIdx.x;
  for (unsigned i = row; i < rows * 32 / 4; i += rows) a[i] = packed_word(i, false, atype);
  b[row] = packed_word(row, true, btype);
  if (row < 32) {
    for (unsigned c = 0; c < 4; ++c) {
      scale_a[row][c] = scale_word(row + 32 * c, false);
      scale_b[row][c] = scale_word(row + 32 * c, true);
    }
    asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0],32;"
                 :: "r"(smem_u32(&base)) : "memory");
  }
  if (!row) {
    mbar_init(&done, 1);
    if (publish_copies) mbar_init(&copies_done, 1);
  }
  __syncthreads();
  tcgen_after_sync();
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  if (!row) {
    const unsigned sfa = base + 16, sfb = base + b_offset;
    asm volatile("tcgen05.cp.cta_group::1.32x128b.warpx4 [%0], %1;"
                 :: "r"(sfa), "l"(tile_desc(scale_a, 16)) : "memory");
    asm volatile("tcgen05.cp.cta_group::1.32x128b.warpx4 [%0], %1;"
                 :: "r"(sfb), "l"(tile_desc(scale_b, 16)) : "memory");
    if (publish_copies) {
      asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];"
                   :: "r"(smem_u32(&copies_done)) : "memory");
      mbar_wait(&copies_done, 0);
      // The completed copies have captured the old values. A fusion that
      // defers either shared-memory read across this point produces bad scales.
      for (unsigned c = 0; c < 4; ++c) scale_a[0][c] = scale_b[0][c] = 0;
      asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
    }
    constexpr unsigned desc = (atype << 7) | (btype << 10) | (atype << 13) | (8u << 24) | (2u << 17)
                              | (1u << 23) | (1u << 29) | (3u << 4);
    asm volatile("{ .reg .pred p; setp.ne.u32 p,0,0;"
                 " tcgen05.mma.cta_group::1.kind::mxf8f6f4.block_scale.scale_vec::1X "
                 "[%0],%1,%2,%3,[%4],[%5],p; }"
                 :: "r"(base), "l"(tile_desc(a, 32)), "l"(tile_desc(b, 32)), "r"(desc),
                    "r"(sfa), "r"(sfb) : "memory");
    asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];"
                 :: "r"(smem_u32(&done)) : "memory");
  }
  __syncthreads();
  mbar_wait(&done, 0);
  tcgen_after_sync();
  unsigned addr = base + ((row & ~31u) << 16);
  for (unsigned c = 0; c < stride; c += 4) {
    const unsigned source = addr + (c == cols + 4 ? b_offset : c);
    unsigned v[4];
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3},[%4]; "
                 "tcgen05.wait::ld.sync.aligned;"
                 : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3]) : "r"(source) : "memory");
    for (unsigned i = 0; i < 4; ++i) out[row * stride + c + i] = v[i];
  }
  __syncthreads();
  if (row < 32) asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0,32;"
                             :: "r"(base) : "memory");
}

template <bool publish_copies, unsigned atype = 0, unsigned btype = atype>
static int check(unsigned *out, unsigned b_offset) {
  scale_placement<publish_copies, atype, btype><<<1, rows>>>(out, b_offset);
  std::vector<unsigned> words(rows * stride);
  ASYNC_CHECK(cudaMemcpy(words.data(), out, words.size() * sizeof(unsigned), cudaMemcpyDeviceToHost));
  unsigned errors = 0;
  for (unsigned r = 0; r < rows; ++r) {
    for (unsigned c = 0; c < cols; ++c) {
      unsigned a_exp = (scale_word(r, false) >> 8) & 255, b_exp = scale_word(c, true) >> 24;
      int dot = 0;
      for (unsigned k = 0; k < 32; ++k) dot += element(r, k, false) * element(c, k, true);
      const float value = (atype ? -dot : dot) * 0.25f * float(1u << (a_exp + b_exp - 252));
      unsigned expected;
      memcpy(&expected, &value, sizeof(expected));
      errors += words[r * stride + c] != expected;
    }
    for (unsigned c = 0; c < 8; ++c)
      errors += words[r * stride + cols + c] != scale_word(r % 32 + c % 4 * 32, c >= 4);
  }
  printf("%sx%s SFB=%u intervening_commit=%d mismatches=%u/%u\n", atype ? "E5M2" : "E4M3",
         btype ? "E5M2" : "E4M3", b_offset, int(publish_copies), errors, rows * stride);
  return errors != 0;
}

int main() {
  unsigned *out;
  ASYNC_CHECK(cudaMalloc(&out, rows * stride * sizeof(unsigned)));
  int failed = check<false>(out, 20);
  failed |= check<false>(out, 24);
  failed |= check<true>(out, 20);
  failed |= check<false, 1>(out, 20);
  failed |= check<false, 0, 1>(out, 20);
  ASYNC_CHECK(cudaFree(out));
  return failed;
}
