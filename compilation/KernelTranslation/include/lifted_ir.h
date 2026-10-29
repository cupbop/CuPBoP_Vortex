#ifndef __CUPBOP_LIFTED_IR__
#define __CUPBOP_LIFTED_IR__

#include "llvm/IR/Module.h"

// Lowerings for constructs that CuLifter-lifted library kernels (cuBLAS / cuDNN / CUTLASS NVVM IR) contain and
// CUDA-source kernels rarely do. See lifted_ir.cpp.

// llvm.nvvm.barrier0.and / .or / .popc (__syncthreads_and / _or / _count, SASS BAR.RED) -> plain CTA barriers around
// a reduction in a shared-memory word, so that every schedule's barrier handling applies.
void lower_barrier_reductions(llvm::Module *M);

#endif
