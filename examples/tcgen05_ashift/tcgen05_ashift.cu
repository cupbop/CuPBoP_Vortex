#include "../tcgen05_test.h"
#include <vector>

#ifdef CUPBOP_TEST_COLUMN_PAIR
#include <cooperative_groups.h>
#define GROUP "cta_group::2"
#define CLUSTER __cluster_dims__(2,1,1)
constexpr unsigned ctas = 2;
#else
#define GROUP "cta_group::1"
#define CLUSTER
constexpr unsigned ctas = 1;
#endif
constexpr unsigned n = 16 * ctas, outputStride = 2 * n + 8;
#ifdef CUPBOP_TEST_SHIFT_NATIVE_A
constexpr unsigned initialA = 2 * n + 16, allocated = 128;
#else
constexpr unsigned initialA = 2 * n, allocated = 64 * ctas;
#endif

__host__ __device__ static unsigned a_byte(unsigned row, unsigned k) {
  return 1 + (row * 31 + k * 13 + row / 4) % 103;
}
__host__ __device__ static unsigned a_word(unsigned row, unsigned word) {
  unsigned bits = 0;
  for (unsigned i = 0; i < 4; ++i) bits |= a_byte(row, 4 * word + i) << (8 * i);
  return bits;
}

__global__ void CLUSTER run(unsigned *out) {
  __shared__ __align__(128) unsigned b[16 * 8];
  __shared__ uint64_t barrier;
  __shared__ unsigned slot;
  unsigned row = threadIdx.x, rank = blockIdx.x;
  b[row] = 0x01010101u * (rank + 1);
  if (!row) {
    mbar_init(&barrier, 1);
#ifdef CUPBOP_TEST_COLUMN_PAIR
    mbar_init_fence();
#endif
  }
  if (row < 32)
    asm volatile("tcgen05.alloc." GROUP ".sync.aligned.shared::cta.b32 [%0], %1;"
                 :: "r"(smem_u32(&slot)), "n"(allocated) : "memory");
  __syncthreads();
  unsigned addr = slot + ((row & ~31u) << 16);
  for (unsigned j = 0; j < 8; j += 4) {
    unsigned r = rank * 128 + row;
    asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0], {%1,%2,%3,%4};"
                 :: "r"(addr + initialA + j), "r"(a_word(r,j)), "r"(a_word(r,j+1)),
                    "r"(a_word(r,j+2)), "r"(a_word(r,j+3)) : "memory");
  }
  asm volatile("tcgen05.wait::st.sync.aligned;" ::: "memory");
  __syncthreads();
  tcgen_after_sync();
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
#ifdef CUPBOP_TEST_COLUMN_PAIR
  auto cluster = cooperative_groups::this_cluster();
  cluster.sync();
#endif
  if (!rank && !row) {
    uint64_t bd = (uint64_t(smem_u32(b) >> 4) & 0x3fff) | (8ull << 16) | (16ull << 32) | (1ull << 46);
    constexpr unsigned id = ((ctas * 8) << 24) | ((n / 8) << 17) | 0x4a0;
#define ISSUE(mod, dest, source, acc) asm volatile("{ .reg .pred p; setp.ne.u32 p, %4, 0; " \
        "tcgen05.mma." GROUP ".kind::i8" mod " [%0], [%1], %2, %3, p; }" \
        :: "r"(dest), "r"(source), "l"(bd), "r"(id), "r"(acc) : "memory")
    unsigned operand = slot + 2 * n;
#ifdef CUPBOP_TEST_SHIFT_NATIVE_A
    // This writes all of A from the native TCU without a software store image.
    ISSUE("", operand, slot + initialA, 0);
#endif
    ISSUE(".collector::a::fill", slot, operand, 0);
    ISSUE(".collector::a::use", slot, operand, 1);
    ISSUE(".ashift.collector::a::lastuse", slot, operand, 1);
    ISSUE("", slot + n, operand, 0);
#undef ISSUE
#ifdef CUPBOP_TEST_COLUMN_PAIR
    asm volatile("tcgen05.commit." GROUP ".mbarrier::arrive::one.shared::cluster.multicast::cluster.b64 [%0], %1;"
                 :: "r"(smem_u32(&barrier)), "h"(uint16_t(3)) : "memory");
#else
    asm volatile("tcgen05.commit." GROUP ".mbarrier::arrive::one.shared::cluster.b64 [%0];"
                 :: "r"(smem_u32(&barrier)) : "memory");
#endif
  }
  __syncthreads();
  if (!row) mbar_wait(&barrier, 0);
  __syncthreads();
  tcgen_after_sync();
  for (unsigned j = 0; j < outputStride; j += 4) {
    unsigned a,b,c,d;
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                 : "=r"(a), "=r"(b), "=r"(c), "=r"(d) : "r"(addr+j) : "memory");
    unsigned *dst = out + (rank * 128 + row) * outputStride + j;
    dst[0]=a; dst[1]=b; dst[2]=c; dst[3]=d;
  }
  __syncthreads();
#ifdef CUPBOP_TEST_COLUMN_PAIR
  cluster.sync();
#endif
  if (row < 32)
    asm volatile("tcgen05.dealloc." GROUP ".sync.aligned.b32 %0,%1;" :: "r"(slot), "n"(allocated) : "memory");
}

static unsigned input_word(unsigned row, unsigned word) {
#ifdef CUPBOP_TEST_SHIFT_NATIVE_A
  // Every column of B is all ones, so every native D word is the row sum.
  unsigned sum = 0;
  for (unsigned k = 0; k < 32; ++k) sum += a_byte(row, k);
  return sum;
#else
  return a_word(row, word);
#endif
}

int main() {
  std::vector<unsigned> got(ctas * 128 * outputStride);
  unsigned *device;
  ASYNC_CHECK(cudaMalloc((void **)&device, got.size()*4));
  run<<<ctas,128>>>(device);
  ASYNC_CHECK(cudaMemcpy(got.data(), device, got.size()*4, cudaMemcpyDeviceToHost));
  unsigned bad = 0;
  for (unsigned row = 0; row < 128 * ctas; ++row) {
    unsigned next = row + unsigned(row % 32 != 31);
    for (unsigned j = 0; j < outputStride; ++j) {
      unsigned expected = 0;
      if (j >= 2*n) expected = input_word(next, j - 2*n);
      else {
        for (unsigned k = 0; k < 32; ++k) {
          unsigned bits = input_word(j < n ? row : next, k / 4);
          expected += int8_t(bits >> (8 * (k % 4)));
        }
        expected *= (j % n / 16 + 1) * (j<n ? 3 : 1);
      }
      if (got[row*outputStride+j] != expected && ++bad <= 3)
        fprintf(stderr, "row %u col %u got %u expected %u\n",row,j,got[row*outputStride+j],expected);
    }
  }
  ASYNC_CHECK(cudaFree(device));
  printf("collector chain, original D, shifted D and A: %u/%zu mismatches\n",bad,got.size());
  return bad != 0;
}
