// Exercise the two 4D loads, 0xc000-byte barrier and swizzled SMEM/SMEM
// MMA together at the first pipeline stage offsets used by SM100a DGEMM.
#include <cuda.h>
#include <vector>
#include "../tcgen05_test.h"

constexpr unsigned m = 128, n = 256, k = 32, pitch = 128;
constexpr unsigned a_start = 0x400, b_start = 0x10400;

static __device__ __forceinline__ void load4(int8_t *tile, const CUtensorMap *map, uint64_t *bar, unsigned batch = 0) {
  asm volatile("cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes "
               "[%0], [%1, {0, 0, 0, %3}], [%2];" ::"r"(smem_u32(tile)),
               "l"((uint64_t)map), "r"(smem_u32(bar)), "r"(batch)
               : "memory");
}

static __device__ uint64_t smem_descriptor(const int8_t *tile) {
  return 0x4000404000080000ull | ((smem_u32(tile) >> 4) & 0x3fff);
}

__global__ void tma_mma(const __grid_constant__ CUtensorMap a_map, const __grid_constant__ CUtensorMap b_map,
                        int *out) {
  extern __shared__ __align__(16) int8_t arena[];
  auto *base = (int8_t *)(((uintptr_t)arena + 1023) & ~uintptr_t(1023));
  auto *slot = (uint32_t *)base;
  auto *loaded = (uint64_t *)(base + 8), *computed = (uint64_t *)(base + 16);
  int8_t *a = base + a_start, *b = base + b_start;
  unsigned r = threadIdx.x, rank, members;
  asm("mov.u32 %0, %%cluster_ctarank;" : "=r"(rank));
  asm("mov.u32 %0, %%cluster_nctarank;" : "=r"(members));
  if (r < 32)
    asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0], 512;" ::"r"(smem_u32(slot)) : "memory");
  if (!r) {
    mbar_init(loaded, 1);
    mbar_init(computed, 1);
    mbar_init_fence();
    mbar_arrive_expect_tx(loaded, (m + n) * pitch);
  }
  __syncthreads();
  if (members == 1) {
    if (r == 32) load4(a, &a_map, loaded);
  } else {
    asm volatile("barrier.cluster.arrive.release.aligned; barrier.cluster.wait.acquire.aligned;" ::: "memory");
    if (r == 32 && rank+1 == members)
      asm volatile("cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.multicast::cluster"
                   " [%0], [%1, {0,0,0,0}], [%2], %3;" :: "r"(smem_u32(a)), "l"((uint64_t)&a_map),
                   "r"(smem_u32(loaded)), "h"((uint16_t)((1u<<members)-1)) : "memory");
  }
  if (r == 64) load4(b, &b_map, loaded, rank);
  __syncthreads();
  mbar_wait(loaded, 0);
  tcgen_after_sync();
  uint32_t taddr = *slot;
  if (!r) {
    asm volatile("{ .reg .pred p; setp.ne.u32 p, 0, 0; "
                 "tcgen05.mma.cta_group::1.kind::i8 [%0], %1, %2, 0x084004a0, p; }" ::"r"(taddr),
                 "l"(smem_descriptor(a)), "l"(smem_descriptor(b))
                 : "memory");
    asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];" ::"r"(smem_u32(computed))
                 : "memory");
  }
  __syncthreads();
  mbar_wait(computed, 0);
  tcgen_after_sync();
  for (unsigned col = 0; col < n; col += 4) {
    uint32_t address = taddr + ((r & ~31u) << 16) + col, v[4];
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4];tcgen05.wait::ld.sync.aligned;"
                 : "=r"(v[0]), "=r"(v[1]), "=r"(v[2]), "=r"(v[3])
                 : "r"(address)
                 : "memory");
    for (unsigned j = 0; j < 4; ++j)
      out[(rank * m + r) * n + col + j] = v[j];
  }
  tcgen_before_sync();
  __syncthreads();
  if (r < 32)
    asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0, 512;"
                 "tcgen05.relinquish_alloc_permit.cta_group::1.sync.aligned;" ::"r"(taddr)
                 : "memory");
}

static int encode(CUtensorMap *map, int8_t *data, unsigned rows, unsigned batches = 1) {
  cuuint64_t dim[] = {pitch, 8, rows / 8, batches}, stride[] = {pitch, 8 * pitch, rows * pitch};
  cuuint32_t box[] = {pitch, 8, rows / 8, 1}, step[] = {1, 1, 1, 1};
  return cuTensorMapEncodeTiled(map, CU_TENSOR_MAP_DATA_TYPE_UINT8, 4, data, dim, stride, box, step,
                                CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_128B,
                                CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE);
}

int main(int argc, char **argv) {
  unsigned members = argc == 2 && !strcmp(argv[1], "--cluster") ? 4 : 1;
  std::vector<int8_t> a(m * pitch, 85), b(members * n * pitch, -67);
  std::vector<int> actual(members * m * n), cpu(members * m * n);
  for (unsigned r = 0; r < m; ++r)
    for (unsigned h = 0; h < k; ++h)
      a[r * pitch + h] = int((r * 31 + h * 53) % 256) - 128;
  for (unsigned c = 0; c < members*n; ++c)
    for (unsigned h = 0; h < k; ++h)
      b[c * pitch + h] = int((c * 41 + h * 23 + c/n * 11) % 256) - 128;
  int8_t *da, *db;
  int *d;
  CUtensorMap am, bm;
  ASYNC_CHECK(cudaMalloc(&da, a.size()));
  ASYNC_CHECK(cudaMalloc(&db, b.size()));
  ASYNC_CHECK(cudaMalloc(&d, actual.size() * sizeof(int)));
  ASYNC_CHECK(cudaMemcpy(da, a.data(), a.size(), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(db, b.data(), b.size(), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemset(d, 0xa5, actual.size() * sizeof(int)));
  ASYNC_CHECK(encode(&am, da, m));
  ASYNC_CHECK(encode(&bm, db, n, members));
  constexpr unsigned dynamic = b_start + n * pitch + 1023;
#ifdef __NVCC__
  ASYNC_CHECK(cudaFuncSetAttribute(tma_mma, cudaFuncAttributeMaxDynamicSharedMemorySize, members == 1 ? dynamic : (dynamic + 1023) & ~1023u));
#endif
  if (members == 1) {
    tma_mma<<<1, m, dynamic>>>(am, bm, d);
  } else {
    cudaLaunchAttribute attr{};
    attr.id = cudaLaunchAttributeClusterDimension;
    attr.val.clusterDim = {2,2,1};
    cudaLaunchConfig_t cfg{};
    cfg.gridDim = dim3(2,2);
    cfg.blockDim = dim3(m);
    // Each CTA's TMA tile begins at the same 1024-byte swizzle phase.
    cfg.dynamicSmemBytes = (dynamic + 1023) & ~1023u;
    cfg.attrs = &attr;
    cfg.numAttrs = 1;
    void *args[] = {&am,&bm,&d};
    ASYNC_CHECK(cudaLaunchKernelExC(&cfg,(const void *)tma_mma,args));
  }
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(actual.data(), d, actual.size() * sizeof(int), cudaMemcpyDeviceToHost));
  unsigned errors = 0;
  for (unsigned r = 0; r < members*m; ++r)
    for (unsigned c = 0; c < n; ++c) {
      int dot = 0;
      for (unsigned h = 0; h < k; ++h)
        dot += int(a[(r % m) * pitch + h]) * int(b[((r / m) * n + c) * pitch + h]);
      cpu[r * n + c] = dot;
      errors += actual[r * n + c] != dot;
    }
  printf("TMA -> MMA stage A=0x%x B=0x%x bytes=%u elements=%u mismatches=%u\n", a_start, b_start, (m + n) * pitch,
         members * m * n, errors);
  int io_error = dump_tcgen_words("cpu.i32", cpu.data(), cpu.size()) |
                 dump_tcgen_words("vortex.i32", actual.data(), actual.size());
  cudaFree(d);
  cudaFree(db);
  cudaFree(da);
  return errors != 0 || io_error;
}
