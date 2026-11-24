#ifndef __CUPBOP_ASYNC_DIRECT__
#define __CUPBOP_ASYNC_DIRECT__

#include "llvm/IR/Module.h"

// The direct DXA form of an elected TMA pipeline (CUPBOP_TMA_DIRECT=1, default 0; schedule 2). See async_direct.cpp.
// Runs right before lower_async_ptx and rewrites only the kernels whose whole use of mbarriers and TMA has the shape
// below; every other kernel is left to lower_async_ptx as it is, with one line in the build log saying why.
//   one thread:    mbarrier.init [mb], 1  /  mbarrier.arrive.expect_tx _, [mb], bytes  /  mbarrier.inval [mb]
//   one thread:    cp.async.bulk.tensor.Nd.shared::cta.global.mbarrier::complete_tx::bytes [smem], [map, {c...}], [mb]
//   every thread:  the mbarrier.try_wait.parity loop on [mb]
// becomes
//   every thread:  __cupbop_tma_direct(when, slot, bar, smem, map, rank, c...)   (the CTA's first warp issues the transfer)
//   every thread:  __vx_dxa_wait(bar)
// with bar a Vortex barrier number the translator fixes (1 + the index of the 8-byte mbarrier word): nothing reads or
// writes the mbarrier words in shared memory any more.
void lower_tma_direct(llvm::Module *M);

#endif
