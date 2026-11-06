#ifndef __NVVM2x86_TRITON_IR__
#define __NVVM2x86_TRITON_IR__
#include "llvm/IR/Module.h"

// Stock Triton LLVM IR (TRITON_CUPBOP=1) -> the NVVM form the rest of the translator reads. See triton_ir.cpp.
void lower_triton_input(llvm::Module *M);
// Threads per warp the Triton module was generated for: TRITON_CUPBOP_WARP_SIZE, else 32.
int triton_warp_size();

#endif
