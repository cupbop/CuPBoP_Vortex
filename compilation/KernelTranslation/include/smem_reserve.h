#ifndef __CUPBOP_SMEM_RESERVE__
#define __CUPBOP_SMEM_RESERVE__

#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Module.h"
#include <cstdint>
#include <utility>
#include <vector>

// Shared-memory reserve drop (CUPBOP_SMEM_RESERVE_DROP, default 0; see smem_reserve.cpp).
//
// sm_90 / sm_100 lifts address their user shared memory 1 KB above the CTA's shared-window base (the driver's
// reserved shared memory sits at window offsets 0..0x3ff), so the CTA area carries 1 KB that the kernel never
// touches. With the switch on, the translator proves the lowest byte of the area that each kernel can touch and
// mem_share2local places the area that many bytes (rounded down to 64) lower; the host then reserves that much less
// local memory per CTA. Not proven: the layout stays as it is.

bool smem_reserve_drop_enabled();

// Runs the analysis when the switch is on (before init_block, while the kernels are SSA); nothing otherwise.
void analyze_smem_reserve(llvm::Module *M);

// Bytes mem_share2local may drop below F's CTA shared area: statics = (global, byte offset in the area), dynamics
// (the [0 x T] markers) start at staticAligned. 0 when the switch is off or a used global is not proven.
uint32_t smem_reserve_drop_for(llvm::Function &F,
                               const std::vector<std::pair<llvm::GlobalVariable *, uint32_t>> &statics,
                               const std::vector<llvm::GlobalVariable *> &dynamics, uint32_t staticAligned);

#endif
