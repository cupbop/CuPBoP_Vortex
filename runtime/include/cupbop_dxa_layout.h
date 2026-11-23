// Shared validation for the DXA descriptor META layout and ESTRIDE2 geometry.
#ifndef CUPBOP_DXA_LAYOUT_H
#define CUPBOP_DXA_LAYOUT_H

#include "cupbop_dxa.h"
#include <string.h>

static inline int cupbop_dxa_parse_layout(const char *name) {
  static const char *const names[] = {"row", "kmajor", "flat", "blockmajor"};
  for (int layout = 0; layout < 4; ++layout)
    if (strcmp(name, names[layout]) == 0) return layout;
  return -1;
}

static inline bool cupbop_dxa_power_of_two(uint32_t value) {
  return value && !(value & (value - 1));
}

// Flat and block-major index B[k][n] in complete WGMMA B blocks. RTL
// computes log2(tile_n/tc_n), log2(tc_n) and log2(block_k) with shifts.
static inline const char *cupbop_dxa_check_layout(uint32_t layout, uint32_t rank, uint32_t elem,
                                                 uint32_t tile_n, uint32_t tile_k,
                                                 uint32_t tc_n, uint32_t block_k) {
  if (layout > CUPBOP_DXA_LAYOUT_BLOCK_MAJOR) return "layout must be row, kmajor, flat or blockmajor";
  if (layout <= CUPBOP_DXA_LAYOUT_K_MAJOR) {
    if (tc_n || block_k) return "row and kmajor take no tile geometry";
    if (layout == CUPBOP_DXA_LAYOUT_K_MAJOR && rank > 2) return "kmajor needs rank <= 2";
    if (layout == CUPBOP_DXA_LAYOUT_K_MAJOR && rank == 2 && (uint64_t)tile_k * elem > 0xffffu)
      return "kmajor destination byte stride must fit in 16 bits";
    return nullptr;
  }
  if (rank != 2) return "flat and blockmajor need a rank-2 B tile";
  if (!cupbop_dxa_power_of_two(tc_n) || tc_n > 0xffffu ||
      !cupbop_dxa_power_of_two(tile_n) || tile_n < tc_n)
    return "tc_n and box[0] must be powers of two with tc_n <= box[0]";
  if ((block_k || layout == CUPBOP_DXA_LAYOUT_BLOCK_MAJOR) && (!cupbop_dxa_power_of_two(block_k) || block_k > 0xffffu))
    return "block_k must be a power of two within 16 bits";
  // RTL's destination-index shifts within each B block have a 4-bit shift count.
  const uint64_t block_units = layout == CUPBOP_DXA_LAYOUT_FLAT ? 2ull * tc_n * tc_n : (uint64_t)tc_n * block_k;
  if (block_units > 0xffffu) return "B block geometry exceeds the DXA destination shift range";
  if (!elem) return "element size must be positive";
  const uint32_t ratio = elem < 4 ? 4 / elem : 1;
  const uint32_t k_extent = layout == CUPBOP_DXA_LAYOUT_FLAT ? 2 * tc_n * ratio : block_k;
  if (!tile_k || tile_k % k_extent) return "box[1] must contain complete B blocks";
  return nullptr;
}

#endif
