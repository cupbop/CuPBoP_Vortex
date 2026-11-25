#include "../tcgen05_test.h"
#include "cupbop_tcgen05.cuh"
#include <vector>

constexpr unsigned rows = 128, inner = 8, cols = 16, nibbleStride = 139;
constexpr unsigned matrixWords = rows * inner, nibbleWords = (64 * nibbleStride + 7) / 8;
constexpr unsigned inputWords = 2 * matrixWords + cols * inner + nibbleWords;
constexpr unsigned resultWords = rows * (cols + 8);

__device__ uint64_t k_descriptor(const unsigned *ptr) {
  return ((smem_u32(ptr) >> 4) & 0x3fffu) | (8ull << 16) | (16ull << 32) | (1ull << 46);
}

__device__ void commit(uint64_t *barrier) {
  asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];"
               :: "r"(smem_u32(barrier)) : "memory");
}

__global__ void transpose_chain(const unsigned *input, unsigned *out) {
  __shared__ __align__(128) unsigned q[matrixWords], r[matrixWords], b[cols * inner];
  __shared__ unsigned scratch[inner * rows];
  __shared__ uint64_t barrier;
  __shared__ unsigned slot;
  const unsigned row = threadIdx.x;
  for (unsigned i = row; i < matrixWords; i += rows) {
    q[i] = input[i];
    r[i] = input[matrixWords + i];
  }
  b[row] = input[2 * matrixWords + row];
  if (!row) mbar_init(&barrier, 1);
  if (row < 32)
    asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0], 256;" :: "r"(smem_u32(&slot)) : "memory");
  __syncthreads();
  tcgen_after_sync();
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  if (!row) {
    asm volatile("{ .reg .pred p; setp.ne.u32 p, 0, 0; tcgen05.mma.cta_group::1.kind::tf32 [%0], %1, %2, %3, p; }"
                 :: "r"(slot), "l"(k_descriptor(q)), "l"(k_descriptor(r)), "r"(0x08200910) : "memory");
    commit(&barrier);
  }
  mbar_wait(&barrier, 0);
  tcgen_after_sync();
  cupbop::tcgen05::transpose_tmem_a<32>(slot + 128, slot, scratch);
  __syncthreads();
  tcgen_after_sync();
  if (!row) {
    asm volatile("{ .reg .pred p; setp.ne.u32 p, 0, 0; tcgen05.mma.cta_group::1.kind::tf32 [%0], [%1], %2, %3, p; }"
                 :: "r"(slot + 144), "r"(slot + 128), "l"(k_descriptor(b)), "r"(0x08040910) : "memory");
    commit(&barrier);
  }
  mbar_wait(&barrier, 1);
  tcgen_after_sync();

  const unsigned *nibbles = input + 2 * matrixWords + cols * inner;
  cupbop::tcgen05::store_mn_major_a<4>(slot + 128, nibbles, nibbleStride);
  __syncthreads();
  tcgen_after_sync();
  for (unsigned i = 0; i < cols + 8; i += 4) {
    const unsigned col = i < cols ? 144 + i : 128 + i - cols;
    unsigned v[4];
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                 : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3])
                 : "r"(slot + ((row & ~31u) << 16) + col) : "memory");
    for (unsigned j = 0; j < 4; ++j) out[row * (cols + 8) + i + j] = v[j];
  }
  tcgen_before_sync();
  __syncthreads();
  if (row < 32)
    asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0, 256;" :: "r"(slot) : "memory");
}

static int value(unsigned matrix, unsigned row, unsigned k) {
  return int(((row * (matrix + 3) + k * 7) ^ (row >> 2) ^ (k * (row % 5))) % 9) - 4;
}
static unsigned nibble(unsigned row, unsigned k) { return ((row * 3 + k * 7) ^ (k >> 1) ^ (row >> 3)) & 15; }
static unsigned float_bits(int n) {
  float f = float(n);
  unsigned bits;
  memcpy(&bits, &f, sizeof(bits));
  return bits;
}

int main() {
  std::vector<unsigned> input(inputWords), got(resultWords);
  for (unsigned m = 0; m < 3; ++m)
    for (unsigned row = 0; row < (m == 2 ? cols : rows); ++row)
      for (unsigned k = 0; k < inner; ++k) {
        unsigned atom = (row / 8) * 64 + (k / 4) * 32 + (row % 8) * 4 + k % 4;
        input[m * matrixWords + atom] = float_bits(value(m, row, k));
      }
  for (unsigned k = 0; k < 64; ++k)
    for (unsigned row = 0; row < rows; ++row) {
      unsigned index = k * nibbleStride + row;
      input[2 * matrixWords + cols * inner + index / 8] |= nibble(row, k) << (4 * (index % 8));
    }
  unsigned *device, *result;
  ASYNC_CHECK(cudaMalloc(&device, inputWords * 4));
  ASYNC_CHECK(cudaMalloc(&result, resultWords * 4));
  ASYNC_CHECK(cudaMemcpy(device, input.data(), inputWords * 4, cudaMemcpyHostToDevice));
  transpose_chain<<<1, rows>>>(device, result);
  ASYNC_CHECK(cudaMemcpy(got.data(), result, resultWords * 4, cudaMemcpyDeviceToHost));
  unsigned errors = 0;
  for (unsigned row = 0; row < rows; ++row)
    for (unsigned n = 0; n < cols + 8; ++n) {
      unsigned expected = 0;
      if (n < cols) {
        int sum = 0;
        for (unsigned k = 0; k < inner; ++k)
          for (unsigned t = 0; t < inner; ++t)
            sum += value(0, k, t) * value(1, row, t) * value(2, n, k);
        expected = float_bits(sum);
      } else {
        for (unsigned e = 0; e < 8; ++e)
          expected |= nibble(row, (n - cols) * 8 + e) << (e * 4);
      }
      unsigned actual = got[row * (cols + 8) + n];
      if (actual != expected && ++errors <= 3)
        printf("row=%u col=%u expected=%08x got=%08x\n", row, n, expected, actual);
    }
  printf("transposed accumulator and packed FP4 mismatches=%u/%u\n", errors, resultWords);
  ASYNC_CHECK(cudaFree(result));
  ASYNC_CHECK(cudaFree(device));
  return errors != 0;
}
