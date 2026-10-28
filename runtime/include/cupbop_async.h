// Records shared by the CuPBoP host runtime and the device runtime for the async-copy family
// (TMA tensor maps, mbarriers). See compilation/KernelTranslation/src/async_ptx.cpp.
#ifndef CUPBOP_ASYNC_H
#define CUPBOP_ASYNC_H

#include <stdint.h>

// ---- tensor map (CUtensorMap, 128 bytes) -------------------------------------------------------
// cuTensorMapEncodeTiled (host shim, cudaRuntimeImpl.cpp) writes this record into the user's 128-byte
// CUtensorMap and uploads a copy to device memory. `self` is the device address of that copy and is the
// first 8 bytes on both sides: the launch packs only 8 bytes per kernel argument, so a by-value
// CUtensorMap reaches the kernel as its first 8 bytes, and a device-side tensor-map address (source:
// &param, lifted: the cvta.param image) always holds `self` in its first 8 bytes. Device helpers read the
// record through it.
#define CUPBOP_TMAP_MAGIC 0x504D4154u /* 'TMAP' */
#define CUPBOP_TMAP_MODE_SW 0u
#define CUPBOP_TMAP_MODE_DXA 1u
typedef struct cupbop_tmap {
  uint64_t self;       // device address of the device copy of this record
  uint32_t magic;      // CUPBOP_TMAP_MAGIC
  uint32_t rank;       // 1..5
  uint64_t gaddr;      // global base address (device)
  uint32_t elem;       // bytes per element: 1, 2, 4, 8
  uint32_t mode;       // CUPBOP_TMAP_MODE_*
  uint32_t dim[5];     // tensor size per dimension (elements), innermost first
  uint32_t box[5];     // box size per dimension (elements)
  uint64_t stride[4];  // byte stride of dimensions 1..rank-1
  uint32_t oob_nan;    // 1: out-of-bounds elements read as NaN (floating types, OOB_FILL_NAN_REQUEST_ZERO_FMA)
  uint32_t dxa_slot;   // DXA descriptor slot (mode DXA)
  uint32_t dtype;      // CUtensorMapDataType (informational)
  uint32_t swizzle;    // CUtensorMapSwizzle (only NONE is accepted)
} cupbop_tmap;

// ---- mbarrier record (the 8-byte mbarrier word in shared memory) -------------------------------------
// low 32 bits: [2:0] Vortex barrier number 1..7 (translator-assigned), [3] the hardware barrier's phase at
// init (the phase bit persists across CTAs that reuse the CTA slot), [23:4] expected thread arrivals N,
// [31:24] CUPBOP_MBAR_MAGIC. High 32 bits: CUPBOP_MBAR_TAG.
#define CUPBOP_MBAR_MAGIC 0xA5u
#define CUPBOP_MBAR_TAG 0x4D424152u /* 'MBAR' */

#endif
