#include <cuda.h>
#include <cupbop_dxa.h>
#include "../async_common.h"

namespace {

constexpr unsigned InputN = 96;
constexpr unsigned InputK = 155;
constexpr unsigned BoxN = 32;
constexpr unsigned BoxK = 64;
constexpr unsigned TileElements = BoxN * BoxK;
constexpr unsigned Tiles = 2;
constexpr unsigned TensorCoreN = 8;
constexpr unsigned BlockK = 16;
constexpr unsigned WordElements = 4 / sizeof(uint16_t);
constexpr unsigned FlatBlockK = 2 * TensorCoreN * WordElements;

struct LayoutCase {
  uint32_t layout;
  const char *name;
  uint32_t tc_n;
  uint32_t block_k;
  bool set_layout;
};

constexpr LayoutCase Cases[] = {
  {CUPBOP_DXA_LAYOUT_ROW_MAJOR, "row-major", 0, 0, true},
  {CUPBOP_DXA_LAYOUT_K_MAJOR, "K-major", 0, 0, true},
  {CUPBOP_DXA_LAYOUT_FLAT, "Flat", TensorCoreN, 0, true},
  {CUPBOP_DXA_LAYOUT_BLOCK_MAJOR, "BlockMajor", TensorCoreN, BlockK, true},
  {CUPBOP_DXA_LAYOUT_ROW_MAJOR, "original map after custom layouts", 0, 0, false},
};

__host__ __device__ unsigned first_n(unsigned tile) { return (tile + 1) * BoxN; }
__host__ __device__ unsigned first_k(unsigned tile) { return tile == 0 ? 5 : InputK - BoxK + 5; }

__global__ void read_layout(const __grid_constant__ CUtensorMap map, uint16_t *output) {
  __shared__ __align__(128) uint16_t tile[TileElements];
  __shared__ __align__(8) uint64_t full;
  if (threadIdx.x == 0) {
    mbar_init(&full, 1);
    mbar_init_fence();
  }
  __syncthreads();
  if (threadIdx.x == 0) {
    mbar_arrive_expect_tx(&full, sizeof(tile));
    asm volatile("cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes "
                 "[%0], [%1, {%3, %4}], [%2];"
                 :: "r"(smem_u32(tile)), "l"((uint64_t)&map), "r"(smem_u32(&full)),
                    "r"(first_n(blockIdx.x)), "r"(first_k(blockIdx.x)) : "memory");
  }
  mbar_wait(&full, 0);
  // Export physical SMEM order so the CUDA kernel does not share the host's reference permutation.
  for (unsigned i = threadIdx.x; i < TileElements; i += blockDim.x)
    output[blockIdx.x * TileElements + i] = tile[i];
}

void expected_tile(uint16_t *out, const uint16_t *source, uint32_t layout, unsigned tile) {
  auto append = [&](unsigned k, unsigned n) {
    const unsigned row = first_k(tile) + k;
    *out++ = row < InputK ? source[row * InputN + first_n(tile) + n] : 0;
  };
  if (layout == CUPBOP_DXA_LAYOUT_ROW_MAJOR) {
    for (unsigned k = 0; k < BoxK; ++k)
      for (unsigned n = 0; n < BoxN; ++n)
        append(k, n);
  } else if (layout == CUPBOP_DXA_LAYOUT_K_MAJOR) {
    for (unsigned n = 0; n < BoxN; ++n)
      for (unsigned k = 0; k < BoxK; ++k)
        append(k, n);
  } else if (layout == CUPBOP_DXA_LAYOUT_FLAT) {
    for (unsigned bk = 0; bk < BoxK; bk += FlatBlockK)
      for (unsigned bn = 0; bn < BoxN; bn += TensorCoreN)
        for (unsigned k = bk; k < bk + FlatBlockK; k += WordElements)
          for (unsigned n = bn; n < bn + TensorCoreN; ++n)
            for (unsigned e = 0; e < WordElements; ++e)
              append(k + e, n);
  } else {
    for (unsigned bk = 0; bk < BoxK; bk += BlockK)
      for (unsigned bn = 0; bn < BoxN; bn += TensorCoreN)
        for (unsigned n = bn; n < bn + TensorCoreN; ++n)
          for (unsigned k = bk; k < bk + BlockK; ++k)
            append(k, n);
  }
}

} // namespace

int main() {
  uint16_t source[InputN * InputK], actual[Tiles * TileElements], expected[Tiles * TileElements];
  for (unsigned i = 0; i < InputN * InputK; ++i)
    source[i] = i + 1;

  uint16_t *device_source, *device_output;
  ASYNC_CHECK(cudaMalloc(&device_source, sizeof(source)));
  ASYNC_CHECK(cudaMalloc(&device_output, sizeof(actual)));
  ASYNC_CHECK(cudaMemcpy(device_source, source, sizeof(source), cudaMemcpyHostToDevice));
  const cuuint64_t dims[] = {InputN, InputK}, stride[] = {InputN * sizeof(uint16_t)};
  const cuuint32_t box[] = {BoxN, BoxK}, element_stride[] = {1, 1};
  CUtensorMap standard;
  ASYNC_CHECK(cuTensorMapEncodeTiled(&standard, CU_TENSOR_MAP_DATA_TYPE_UINT16, 2, device_source,
                                    dims, stride, box, element_stride, CU_TENSOR_MAP_INTERLEAVE_NONE,
                                    CU_TENSOR_MAP_SWIZZLE_NONE, CU_TENSOR_MAP_L2_PROMOTION_NONE,
                                    CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
  if (cudaDxaSetTensorMapLayout(&standard, CUPBOP_DXA_LAYOUT_FLAT, 3, 0) == 0 ||
      cudaDxaSetTensorMapLayout(&standard, CUPBOP_DXA_LAYOUT_BLOCK_MAJOR, TensorCoreN, 0) == 0) {
    puts("FAILED!: invalid layout geometry was accepted");
    return 1;
  }

  unsigned errors = 0;
  for (const auto &test : Cases) {
    CUtensorMap map = standard;
    if (test.set_layout)
      ASYNC_CHECK(cudaDxaSetTensorMapLayout(&map, test.layout, test.tc_n, test.block_k));
    ASYNC_CHECK(cudaMemset(device_output, 0xff, sizeof(actual)));
    read_layout<<<Tiles, 128>>>(map, device_output);
    ASYNC_CHECK(cudaDeviceSynchronize());
    ASYNC_CHECK(cudaMemcpy(actual, device_output, sizeof(actual), cudaMemcpyDeviceToHost));
    for (unsigned tile = 0; tile < Tiles; ++tile)
      expected_tile(expected + tile * TileElements, source, test.layout, tile);
    unsigned mismatches = 0;
    for (unsigned i = 0; i < Tiles * TileElements; ++i) {
      if (actual[i] != expected[i] && mismatches++ == 0)
        printf("%s: first mismatch at tile %u element %u, got %u expected %u\n",
               test.name, i / TileElements, i % TileElements, actual[i], expected[i]);
    }
    errors += mismatches;
    printf("%s: %u/%u physical elements match\n", test.name, Tiles * TileElements - mismatches,
           Tiles * TileElements);
  }
  ASYNC_CHECK(cudaFree(device_source));
  ASYNC_CHECK(cudaFree(device_output));
  puts(errors ? "FAILED!" : "PASSED!");
  return errors != 0;
}
