#ifndef __CUPBOP_ASYNC_PTX__
#define __CUPBOP_ASYNC_PTX__

#include "llvm/IR/Module.h"

// Hopper / Ampere asynchronous PTX -> CuPBoP internal calls, software mode (async design, stages 1-2).
// Runs first in the translator (before lower_named_barriers and lower_cp_async), on CUDA-source inline asm,
// the NVVM mbarrier intrinsics and CuLifter's asm forms. The asm is parsed statement by statement (labels,
// predicates, { } scopes, .reg declarations), and each statement is lowered:
//   mbarrier.init / arrive[.expect_tx] / try_wait[.parity] / test_wait[.parity] / inval / expect_tx /
//     complete_tx                       -> __cupbop_mbar_* (cudaKernelImpl_async.inc), Vortex HW barriers
//   cp.async.mbarrier.arrive[.noinc]    -> nothing (net zero with synchronous cp.async) / a thread arrival
//   cp.async.bulk.tensor.Nd (load, store), cp.async.bulk (g2s, s2s, s2g)
//                                       -> __cupbop_tma_load / __cupbop_tma_store / __cupbop_bulk_copy
//   commit_group / wait_group[.read], prefetch, fence.proxy.*, fence.mbarrier_init, setmaxnreg,
//     griddepcontrol, barrier.cluster.arrive  -> nothing;  barrier.cluster.wait -> llvm.nvvm.barrier0
//   elect.sync, activemask, mov/setp/selp, %cluster_ctarank (0), %cluster_nctarank (1), mapa (identity, a
//     rank other than 0 traps), cvta.param (the CuLifter param image)
// An arrive that is followed, in the same thread and before any wait, by bulk / TMA copies completing on an
// mbarrier is moved after them (design §5.3): the synchronous copies then precede the arrival. Refused with a
// translation error, never dropped: any other async form, a moved arrive that would cross a wait or leave its
// loop, an arrive.expect_tx without its copies, sm_80 CuLifter mbarrier forms, the flat schedule, the core
// mapping unless it is de facto 1:1 (checked again at launch), warps narrower than 32 lanes.
void lower_async_ptx(llvm::Module *M);

// Vortex barrier numbers for the mbarriers (after lower_named_barriers, whose ids must not be reused):
// an mbarrier.init at a constant shared-memory offset gets its own number; a __shared__ variable initialized
// at a computed offset gets one number per 8-byte word. Numbers 1..NUM_BARRIERS-1; too many is an error.
void finalize_mbarrier_ids(llvm::Module *M);

#endif
