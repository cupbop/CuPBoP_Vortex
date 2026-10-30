#ifndef __CUPBOP_LIFTED_IR__
#define __CUPBOP_LIFTED_IR__

#include "llvm/IR/Module.h"

// Lowerings for constructs that CuLifter-lifted library kernels (cuBLAS / cuDNN / CUTLASS NVVM IR) contain and
// CUDA-source kernels rarely do. See lifted_ir.cpp.

// llvm.nvvm.barrier0.and / .or / .popc (__syncthreads_and / _or / _count, SASS BAR.RED) -> plain CTA barriers around
// a reduction in a shared-memory word, so that every schedule's barrier handling applies.
void lower_barrier_reductions(llvm::Module *M);

// ldmatrix / stmatrix .m8n8.b16 inline asm (CuLifter LDSM / STSM, integer shared-window address) -> runtime
// helpers over hardware shuffles
void lower_ldmatrix_asm(llvm::Module *M);

// llvm.nvvm.{round,trunc,ceil,floor}.{f,d} -> branch-free IR
void lower_nvvm_rounding(llvm::Module *M);

// CuLifter's 32 KB `local_mem` alloca -> its accessed extent (constant offsets after integer folding)
void shrink_lifter_local_mem(llvm::Module *M);

// CuLifter's per-thread parameter buffer (param_local / vx_params, a copy of the kernel parameters at the entry): loads
// at constant offsets read the parameters instead, the buffer goes when no load of it is left (C plan, 2026-10-29)
void forward_param_buffer_copies(llvm::Module *M);

// llvm.nvvm.redux.sync.* -> shuffle-based runtime helper
void lower_redux_sync(llvm::Module *M);

// llvm.bitreverse.i1(x) -> x (the RISC-V back end cannot legalize it)
void fold_bitreverse_i1(llvm::Module *M);

// llvm.nvvm.read.ptx.sreg.lanemask.* -> masks of %laneid
void lower_lanemask(llvm::Module *M);

#endif
