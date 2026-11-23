#include <cuda.h>
#include "../async_common.h"

#ifdef CUPBOP_CHECK_PUBLISHED_MAP
#include "../../runtime/include/cupbop_async.h"
#endif

constexpr int words = 32;

__global__ void publish_map(const CUtensorMap *source, CUtensorMap *published) {
  __shared__ __align__(128) volatile uint32_t scratch[words];
  const int lane = threadIdx.x;
  scratch[lane] = reinterpret_cast<const uint32_t *>(source)[lane];
  __syncthreads();
  const uint32_t src = smem_u32(const_cast<uint32_t *>(scratch));
  const uint64_t dst = __cvta_generic_to_global(published);
  asm volatile("tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [%0], [%1], 128;"
               :: "l"(dst), "r"(src) : "memory");
  // Reuse the source shared memory immediately after the warp publication.
  scratch[lane] = 0;
}

__global__ void store_through_map(const CUtensorMap *map, uint32_t bias) {
  __shared__ __align__(128) uint32_t tile[words];
  const int lane = threadIdx.x;
  tile[lane] = bias + lane * 3;
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  __syncthreads();
  if (lane == 0) {
    const uint64_t addr = __cvta_generic_to_global(map);
    asm volatile("fence.proxy.tensormap::generic.acquire.gpu [%0], 128;" :: "l"(addr) : "memory");
    asm volatile("cp.async.bulk.tensor.1d.global.shared::cta.bulk_group [%0, {0}], [%1];"
                 :: "l"(addr), "r"(smem_u32(tile)) : "memory");
    asm volatile("cp.async.bulk.commit_group;" ::: "memory");
    asm volatile("cp.async.bulk.wait_group.read 0;" ::: "memory");
  }
}

int main() {
  CUtensorMap *source, *published;
  ASYNC_CHECK(cudaMalloc(&source, sizeof(CUtensorMap)));
  ASYNC_CHECK(cudaMalloc(&published, sizeof(CUtensorMap)));
  ASYNC_CHECK(cudaMemset(published, 0, sizeof(CUtensorMap)));
  uint32_t *output;
  ASYNC_CHECK(cudaMalloc(&output, 2 * words * sizeof(uint32_t)));
  ASYNC_CHECK(cudaMemset(output, 0, 2 * words * sizeof(uint32_t)));

  const cuuint64_t dims[] = {words};
  const cuuint32_t box[] = {words}, strides[] = {1};
  for (unsigned pass = 0; pass < 2; ++pass) {
    CUtensorMap map;
    ASYNC_CHECK(cuTensorMapEncodeTiled(&map, CU_TENSOR_MAP_DATA_TYPE_UINT32, 1, output + pass * words, dims, nullptr,
                                      box, strides, CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_NONE,
                                      CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
    ASYNC_CHECK(cudaMemcpy(source, &map, sizeof(map), cudaMemcpyHostToDevice));
    publish_map<<<1, words>>>(source, published);
    ASYNC_CHECK(cudaDeviceSynchronize());
    ASYNC_CHECK(cudaMemset(source, 0, sizeof(CUtensorMap)));

    CUtensorMap snapshot;
    ASYNC_CHECK(cudaMemcpy(&snapshot, published, sizeof(snapshot), cudaMemcpyDeviceToHost));
#ifdef CUPBOP_CHECK_PUBLISHED_MAP
    cupbop_tmap record;
    memcpy(&record, &map, sizeof(record));
    record.self = reinterpret_cast<uintptr_t>(published);
    record.mode = CUPBOP_TMAP_MODE_SW;
    record.dxa_slot = UINT32_MAX;
    memcpy(&map, &record, sizeof(map));
#endif
    if (memcmp(&map, &snapshot, sizeof(map))) {
      printf("FAILED! pass %u published record differs from its source\n", pass);
      return 1;
    }
    store_through_map<<<1, words>>>(published, 100 + pass * 200);
    ASYNC_CHECK(cudaDeviceSynchronize());
  }

  uint32_t result[2 * words];
  ASYNC_CHECK(cudaMemcpy(result, output, sizeof(result), cudaMemcpyDeviceToHost));
  for (unsigned i = 0; i < 2 * words; ++i) {
    const uint32_t want = 100 + (i / words) * 200 + (i % words) * 3;
    if (result[i] != want) {
      printf("FAILED! result[%u]: got %u, expected %u\n", i, result[i], want);
      return 1;
    }
  }
  ASYNC_CHECK(cudaFree(source));
  ASYNC_CHECK(cudaFree(published));
  ASYNC_CHECK(cudaFree(output));
  printf("64 matching values across two tensor-map publications\nPASSED!\n");
  return 0;
}
