#include "../tcgen05_test.h"
#include <vector>
#ifdef CUPBOP_TEST_COPY_PAIR
#include <cooperative_groups.h>
#define COPY_CTA_GROUP "cta_group::2"
#define COPY_CLUSTER __cluster_dims__(2,1,1)
constexpr unsigned members = 2;
#else
#define COPY_CTA_GROUP "cta_group::1"
#define COPY_CLUSTER
constexpr unsigned members = 1;
#endif

constexpr unsigned rows = 128, cases = 9, outputWords = 12;
__host__ __device__ static unsigned words(unsigned mode) {
  return mode == 8 ? outputWords : mode > 0 && mode < 5 ? 4 : 8;
}
__host__ __device__ static unsigned tag(unsigned rank, unsigned row, unsigned offset) {
  return 0xe0000000u + (rank * rows + row) * outputWords + offset;
}

__host__ __device__ static unsigned element(unsigned row, unsigned k, unsigned bits) {
  return (row * 13 + k * 19 + 3) & ((1u << bits) - 1);
}

__global__ void COPY_CLUSTER copy_formats(unsigned *out, unsigned columns) {
  __shared__ __align__(128) unsigned char tile[4096];
  __shared__ unsigned slot;
  __shared__ uint64_t bar;
  unsigned row = threadIdx.x;
#ifdef CUPBOP_TEST_COPY_PAIR
  auto cluster = cooperative_groups::this_cluster();
  unsigned rank = cluster.block_rank();
#else
  constexpr unsigned rank = 0;
#endif
  if (!row) {
    mbar_init(&bar, 1);
#ifdef CUPBOP_TEST_COPY_PAIR
    mbar_init_fence();
#endif
  }
  if (row < 32)
    asm volatile("tcgen05.alloc." COPY_CTA_GROUP ".sync.aligned.shared::cta.b32 [%0], %1;"
                 :: "r"(smem_u32(&slot)), "r"(columns) : "memory");
  __syncthreads();
  for (unsigned mode = 0; mode < cases; ++mode) {
    unsigned bits = mode == 5 ? 8 : mode == 0 || mode == 3 || mode == 6 ? 4 : 6;
    for (unsigned half = 0; half < 2; ++half) {
      unsigned char *dst = tile + ((row / 8 * 2 + half) * 8 + row % 8) * 16;
      // Each 16-byte shared record has 16 packed values followed by padding.
      for (unsigned byte = 0; byte < 16; ++byte) dst[byte] = byte >= bits * 2 ? 0xcf : 0;
      for (unsigned k = 0; k < 16; ++k) {
        unsigned v = element(row + rank * 7, half * 16 + k, bits);
        for (unsigned b = 0; b < bits; ++b)
          dst[(k * bits + b) / 8] |= ((v >> b) & 1) << ((k * bits + b) % 8);
      }
    }
    unsigned addr = slot + ((row & ~31u) << 16) + (mode == 8 ? 12 : 0);
    if (mode >= 5) {
      for (unsigned j = 0; j < words(mode); j += 4) {
        unsigned value = tag(rank, row, j);
        asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0],{%1,%2,%3,%4}; tcgen05.wait::st.sync.aligned;"
                     :: "r"(addr+j), "r"(value), "r"(value+1), "r"(value+2), "r"(value+3) : "memory");
      }
    }
    __syncthreads();
    tcgen_after_sync();
#ifdef CUPBOP_TEST_COPY_PAIR
    cluster.sync();
#endif
    if (!row && !rank) {
      uint64_t desc = ((smem_u32(tile) >> 4) & 16383) | (8ull << 16) | (16ull << 32) | (1ull << 46);
      unsigned origin = mode == 5 ? 3 : mode == 6 ? 16 : mode == 7 ? 31 : 0;
      unsigned destination = slot + (origin << 16);
#define COPY(shape) asm volatile("tcgen05.cp." COPY_CTA_GROUP "." shape " [%0], %1;" :: "r"(destination), "l"(desc) : "memory")
      switch (mode) {
        case 0: COPY("128x256b.b8x16.b4x16_p64"); break;
        case 1: COPY("128x128b.b8x16.b6x16_p32"); break;
        case 2: COPY("64x128b.warpx2::01_23.b8x16.b6x16_p32"); break;
        case 3: COPY("64x128b.warpx2::02_13.b8x16.b4x16_p64"); break;
        case 4: COPY("32x128b.warpx4.b8x16.b6x16_p32"); break;
        case 5: COPY("4x256b"); break;
        case 6: COPY("4x256b.b8x16.b4x16_p64"); break;
        case 7: COPY("4x256b.b8x16.b6x16_p32"); break;
        case 8: asm volatile("tcgen05.shift." COPY_CTA_GROUP ".down [%0];"
                             :: "r"(slot + (64u << 16) + 15) : "memory"); break;
      }
#undef COPY
#ifdef CUPBOP_TEST_COPY_PAIR
      asm volatile("tcgen05.commit.cta_group::2.mbarrier::arrive::one.shared::cluster.multicast::cluster.b64 [%0],%1;"
                   :: "r"(smem_u32(&bar)), "h"(uint16_t(3)) : "memory");
#else
      asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];"
                   :: "r"(smem_u32(&bar)) : "memory");
#endif
    }
#ifdef CUPBOP_TEST_COPY_PAIR
    if (!row) mbar_wait(&bar, mode & 1);
    __syncthreads();
#else
    mbar_wait(&bar, mode & 1);
#endif
    for (unsigned half = 0; half < words(mode) / 4; ++half) {
      unsigned v[4];
      asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3},[%4]; tcgen05.wait::ld.sync.aligned;"
                   : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3]) : "r"(addr + 4 * half) : "memory");
      for (unsigned j = 0; j < 4; ++j) out[((rank * cases + mode) * rows + row) * outputWords + 4 * half + j] = v[j];
    }
    __syncthreads();
#ifdef CUPBOP_TEST_COPY_PAIR
    cluster.sync();
#endif
  }
  if (row < 32) {
    asm volatile("tcgen05.dealloc." COPY_CTA_GROUP ".sync.aligned.b32 %0, %1;" :: "r"(slot), "r"(columns) : "memory");
    asm volatile("tcgen05.relinquish_alloc_permit." COPY_CTA_GROUP ".sync.aligned;" ::: "memory");
  }
}

int main() {
  std::vector<unsigned> result(members * cases * rows * outputWords);
  unsigned *out;
  ASYNC_CHECK(cudaMalloc(&out, result.size() * sizeof(unsigned)));
  unsigned errors = 0, checked = 0;
  for (unsigned columns : {32u, 128u}) {
    copy_formats<<<members, rows>>>(out, columns);
    ASYNC_CHECK(cudaDeviceSynchronize());
    ASYNC_CHECK(cudaMemcpy(result.data(), out, result.size() * sizeof(unsigned), cudaMemcpyDeviceToHost));
    for (unsigned slot = 0; slot < members * cases; ++slot) {
      unsigned rank = slot / cases, mode = slot % cases;
      for (unsigned row = 0; row < rows; ++row) {
        unsigned src = mode < 2 ? row : mode == 3 ? row % 64 : mode == 2 ? row / 64 * 32 + row % 32 : mode == 4 ? row % 32 : row / 32;
        unsigned bits = mode == 5 ? 8 : mode == 0 || mode == 3 || mode == 6 ? 4 : 6;
        for (unsigned j = 0; j < words(mode); ++j) {
          unsigned expected = 0;
          for (unsigned b = 0; b < 4; ++b)
            expected |= element(src + rank * 7, 4*j + b, bits) << (8*b + (bits == 4 ? 2 : 0));
          if (mode >= 5 && row % 32 != (mode == 5 ? 3u : mode == 6 ? 16u : 31u))
            expected = tag(rank, row, j);
          if (mode == 8) {
            bool moved = row >= 64 && row < 95 && j >= 3 && j < 11;
            expected = tag(rank, row + unsigned(moved), j);
          }
          unsigned got = result[(slot * rows + row) * outputWords + j];
          if (got != expected && ++errors < 6)
            printf("mode=%u row=%u word=%u expected=%x got=%x\n", mode, row, j, expected, got);
          ++checked;
        }
      }
    }
  }
  ASYNC_CHECK(cudaFree(out));
  printf("TMEM copy and shift: %u mismatches in %u words\n", errors, checked);
  return errors != 0;
}
