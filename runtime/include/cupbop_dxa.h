#ifndef CUPBOP_DXA_H
#define CUPBOP_DXA_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum cupbop_dxa_layout {
  CUPBOP_DXA_LAYOUT_ROW_MAJOR = 0,
  CUPBOP_DXA_LAYOUT_K_MAJOR = 1,
  CUPBOP_DXA_LAYOUT_FLAT = 2,
  CUPBOP_DXA_LAYOUT_BLOCK_MAJOR = 3,
};

// Configure a map encoded by CuPBoP's cuTensorMapEncodeTiled. Each layout
// change allocates a device record so other copies keep their layout. Create
// the desired views once and reuse them across launches. Returns 0 on success.
// CUPBOP_TMA_DXA=1 enables hardware transfers for eligible maps; software
// copies use the same shared-memory layout.
//
// Row-major and K-major take tc_n=block_k=0. Flat (sparse B) and block-major
// (dense B) expect box[0]=N, box[1]=K, with complete blocks and a power-of-two
// box width. Supply the consumer's N block width in tc_n. For block-major
// also pass its K block height in block_k; for Flat use 0.
// Non-row-major tensor maps require CU_TENSOR_MAP_SWIZZLE_NONE.
int cudaDxaSetTensorMapLayout(void *tensor_map, uint32_t layout, uint32_t tc_n, uint32_t block_k);

// Program a native DXA descriptor for the next launch, with explicit tile geometry.
int cudaDxaProgramDescNdTiled(uint32_t slot, uint64_t base_addr, uint32_t rank,
                             const uint32_t *sizes, const uint32_t *strides_bytes,
                             const uint32_t *box, uint32_t elem_bytes, uint32_t layout,
                             uint32_t smem_stride_bytes, uint32_t fill, uint32_t tc_n, uint32_t block_k);

#ifdef __cplusplus
}
#endif

#endif
