#include "../tcgen05_test.h"
#include <vector>

constexpr unsigned rows = 128, cases = 5;
__host__ __device__ static unsigned element(unsigned row, unsigned k, unsigned bits) {
  return (row * 13 + k * 19 + 3) & ((1u << bits) - 1);
}

__global__ void copy_formats(unsigned *out, unsigned columns) {
  __shared__ __align__(128) unsigned char tile[4096];
  __shared__ unsigned slot;
  __shared__ uint64_t bar;
  unsigned row = threadIdx.x;
  if (!row) mbar_init(&bar, 1);
  if (row < 32)
    asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0], %1;"
                 :: "r"(smem_u32(&slot)), "r"(columns) : "memory");
  __syncthreads();
  for (unsigned mode = 0; mode < cases; ++mode) {
    unsigned bits = mode == 0 || mode == 3 ? 4 : 6;
    for (unsigned half = 0; half < 2; ++half) {
      unsigned char *dst = tile + ((row / 8 * 2 + half) * 8 + row % 8) * 16;
      // Each 16-byte shared record has 16 packed values followed by padding.
      for (unsigned byte = 0; byte < 16; ++byte) dst[byte] = byte >= bits * 2 ? 0xcf : 0;
      for (unsigned k = 0; k < 16; ++k) {
        unsigned v = element(row, half * 16 + k, bits);
        for (unsigned b = 0; b < bits; ++b)
          dst[(k * bits + b) / 8] |= ((v >> b) & 1) << ((k * bits + b) % 8);
      }
    }
    __syncthreads();
    tcgen_after_sync();
    if (!row) {
      uint64_t desc = ((smem_u32(tile) >> 4) & 16383) | (8ull << 16) | (16ull << 32) | (1ull << 46);
#define COPY(shape) asm volatile("tcgen05.cp.cta_group::1." shape " [%0], %1;" :: "r"(slot), "l"(desc) : "memory")
      switch (mode) {
        case 0: COPY("128x256b.b8x16.b4x16_p64"); break;
        case 1: COPY("128x128b.b8x16.b6x16_p32"); break;
        case 2: COPY("64x128b.warpx2::01_23.b8x16.b6x16_p32"); break;
        case 3: COPY("64x128b.warpx2::02_13.b8x16.b4x16_p64"); break;
        case 4: COPY("32x128b.warpx4.b8x16.b6x16_p32"); break;
      }
#undef COPY
      asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];"
                   :: "r"(smem_u32(&bar)) : "memory");
    }
    mbar_wait(&bar, mode & 1);
    unsigned addr = slot + ((row & ~31u) << 16);
    for (unsigned half = 0; half < (mode ? 1u : 2u); ++half) {
      unsigned v[4];
      asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3},[%4]; tcgen05.wait::ld.sync.aligned;"
                   : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3]) : "r"(addr + 4 * half) : "memory");
      for (unsigned j = 0; j < 4; ++j) out[(mode * rows + row) * 8 + 4 * half + j] = v[j];
    }
    __syncthreads();
  }
  if (row < 32) {
    asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0, %1;" :: "r"(slot), "r"(columns) : "memory");
    asm volatile("tcgen05.relinquish_alloc_permit.cta_group::1.sync.aligned;" ::: "memory");
  }
}

int main() {
  std::vector<unsigned> result(cases * rows * 8);
  unsigned *out;
  ASYNC_CHECK(cudaMalloc(&out, result.size() * sizeof(unsigned)));
  unsigned errors = 0, checked = 0;
  for (unsigned columns : {32u, 128u}) {
    copy_formats<<<1, rows>>>(out, columns);
    ASYNC_CHECK(cudaDeviceSynchronize());
    ASYNC_CHECK(cudaMemcpy(result.data(), out, result.size() * sizeof(unsigned), cudaMemcpyDeviceToHost));
    for (unsigned mode = 0; mode < cases; ++mode) {
      for (unsigned row = 0; row < rows; ++row) {
        unsigned src = mode < 2 ? row : mode == 2 ? row % 64 : mode == 3 ? row / 64 * 32 + row % 32 : row % 32;
        unsigned bits = mode == 0 || mode == 3 ? 4 : 6;
        for (unsigned j = 0; j < (mode ? 4u : 8u); ++j) {
          unsigned expected = 0;
          for (unsigned b = 0; b < 4; ++b)
            expected |= element(src, 4*j + b, bits) << (8*b + (bits == 4 ? 2 : 0));
          unsigned got = result[(mode * rows + row) * 8 + j];
          if (got != expected && ++errors < 6)
            printf("mode=%u row=%u word=%u expected=%x got=%x\n", mode, row, j, expected, got);
          ++checked;
        }
      }
    }
  }
  ASYNC_CHECK(cudaFree(out));
  printf("TMEM compressed copy: %u mismatches in %u words\n", errors, checked);
  return errors != 0;
}
