#include "../tcgen05_test.h"
#include <cooperative_groups.h>
#include <vector>

namespace {
constexpr int rows = 256, cols = 256, inner = 32;
constexpr int rows_per_cta = rows / 2, cols_per_cta = cols / 2;
constexpr int passes = 2;

__host__ __device__ int a_value(int row, int k) {
  return (row * 31 + (row / 128) * 19 + k * 53) % 256 - 128;
}

__host__ __device__ int b_value(int col, int k) {
  return (col * 41 + (col / 128) * 11 + k * 23) % 256 - 128;
}

__device__ unsigned packed_offset(int row, int k) {
  return (row / 8) * 256 + (k / 16) * 128 + (row % 8) * 16 + k % 16;
}

__device__ uint64_t descriptor(const int8_t *base) {
  return ((smem_u32(base) >> 4) & 0x3fff) | (8ull << 16) | (16ull << 32) | (1ull << 46);
}
} // namespace

__global__ void __cluster_dims__(2, 1, 1) paired_gemm(int *out) {
  __shared__ __align__(16) int8_t a[rows_per_cta * inner], b[cols_per_cta * inner];
  __shared__ uint32_t slot;
  __shared__ uint64_t barrier;
  const unsigned tid = threadIdx.x;
  const auto cluster = cooperative_groups::this_cluster();
  const unsigned rank = cluster.block_rank();
  const unsigned row = rank * rows_per_cta + tid;
  for (int k = 0; k < inner; ++k) {
    a[packed_offset(tid, k)] = a_value(row, k);
    b[packed_offset(tid, k)] = b_value(rank * cols_per_cta + tid, k);
  }
  if (!tid) {
    mbar_init(&barrier, 1);
    mbar_init_fence();
  }
  if (tid < 32)
    asm volatile("tcgen05.alloc.cta_group::2.sync.aligned.shared::cta.b32 [%0], 512;"
                 :: "r"(smem_u32(&slot)) : "memory");
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  cluster.sync();
  tcgen_after_sync();
  const uint32_t taddr = slot;

  for (int pass = 0; pass < passes; ++pass) {
    if (!rank && !tid) {
      asm volatile(
          "{ .reg .pred p; setp.ne.u32 p, %3, 0; "
          "tcgen05.mma.cta_group::2.kind::i8 [%0], %1, %2, 0x104004a0, p; }"
          :: "r"(taddr), "l"(descriptor(a)), "l"(descriptor(b)), "r"(pass) : "memory");
      asm volatile("tcgen05.commit.cta_group::2.mbarrier::arrive::one.shared::cluster.multicast::cluster.b64 [%0], %1;"
                   :: "r"(smem_u32(&barrier)), "h"(uint16_t(3)) : "memory");
    }
    if (!tid)
      mbar_wait(&barrier, pass);
    __syncthreads();
    tcgen_after_sync();
    for (unsigned col = 0; col < cols; col += 4) {
      const uint32_t address = taddr + ((row & ~31u) << 16) + col;
      uint32_t x[4];
      asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                   : "=r"(x[0]), "=r"(x[1]), "=r"(x[2]), "=r"(x[3]) : "r"(address) : "memory");
      for (unsigned i = 0; i < 4; ++i)
        out[(pass * rows + row) * cols + col + i] = x[i];
    }
    tcgen_before_sync();
    cluster.sync();
  }
  if (tid < 32)
    asm volatile("tcgen05.dealloc.cta_group::2.sync.aligned.b32 %0, 512; "
                 "tcgen05.relinquish_alloc_permit.cta_group::2.sync.aligned;"
                 :: "r"(taddr) : "memory");
}

int main() {
  constexpr int elements = passes * rows * cols;
  std::vector<int> got(elements);
  int *dev;
  ASYNC_CHECK(cudaMalloc(&dev, elements * sizeof(int)));
  ASYNC_CHECK(cudaMemset(dev, 0xa5, elements * sizeof(int)));
  paired_gemm<<<2, rows_per_cta>>>(dev);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(got.data(), dev, elements * sizeof(int), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(dev));
  unsigned bad = 0;
  for (int row = 0; row < rows; ++row) {
    for (int col = 0; col < cols; ++col) {
      int dot = 0;
      for (int k = 0; k < inner; ++k)
        dot += a_value(row, k) * b_value(col, k);
      for (int pass = 0; pass < passes; ++pass) {
        const int expected = (pass + 1) * dot;
        const int value = got[(pass * rows + row) * cols + col];
        if (value != expected && bad++ < 8)
          printf("row=%d col=%d pass=%d expected=%d got=%d\n", row, col, pass, expected, value);
      }
    }
  }
  printf("%s: %u/%d INT32 results match\n", bad ? "FAILED!" : "PASSED!", elements - bad, elements);
  return bad != 0;
}
