#ifndef __CUPBOP_ASYNC_COPY__
#define __CUPBOP_ASYNC_COPY__

#include "llvm/IR/Module.h"

// cp.async family (Ampere async global->shared copies; CUDA __pipeline_memcpy_async, inline PTX,
// llvm.nvvm.cp.async.* and CuLifter's LDGSTS lift) lowered to synchronous copies: a global load and a
// shared store at the issue point, src-size zero-fill included; commit_group / wait_group / wait_all
// become no-ops (a compiler-only fence for the waits). This is correct whatever the waits say, so it
// also holds for lifted IR, where the lifter drops LDGDEPBAR/DEPBAR. Refused with a translation error
// instead of being dropped: cp.async.mbarrier.arrive*, cp.async.bulk*, mbarrier* and any other cp.async
// form the parser does not understand. Runs before init_block (replace_asm_call would drop the asm).
void lower_cp_async(llvm::Module *M);

// DXA waits: a call __vx_barrier_arrive_and_wait(id, n) whose barrier id comes from __vx_dxa_barrier_id()
// waits for DXA transfers. Retarget it to __cupbop_dxa_wait(id, n) (same operation in the device runtime) so
// the core-mapping pass below can tell it from an ordinary barrier. Run early (before init_block).
void mark_dxa_waits(llvm::Module *M);

// Core mapping (schedule 1): a DXA issue is a CTA-collective operation (exactly one transfer per CTA) and a
// DXA wait is once per hardware warp. Inside a warp loop (one pass per logical warp of this hardware warp)
// guard both with "first pass" (intra_warp_slot == 0, and the first sub-pass in the sub-pass form). The
// device helper already filters the issuing hardware warp (VX_CSR_CTA_RANK == 0). A warp loop whose body
// can issue again after a wait within one pass (a pipeline loop without __syncthreads) keeps the
// per-pass issue (correct, repeated) and the translator says so. Run after insert_warp_loop and before
// replace_built_in_function (which localizes intra_warp_slot). CUPBOP_DXA_PER_PASS=1 turns it off.
void virt_dxa_cta_once(llvm::Module *M);

// !vx.dxa.desc named metadata in the kernel IR -> dxa_descriptors.txt (v2 "desc" lines) next to the
// translated kernel, which the host runtime reads at launch: an IR-only DXA user needs no host change.
void emit_dxa_desc_sidecar(llvm::Module *M);

// The pointer an address operand (integer or pointer) was computed from: integer casts, ptrtoint, address-
// space casts, NVVM / -O0 cvta helpers and single-store -O0 locals are looked through. nullptr if none.
llvm::Value *cupbop_trace_pointer(llvm::Value *V);

#endif
