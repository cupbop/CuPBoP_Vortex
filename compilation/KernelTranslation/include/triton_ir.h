#ifndef __NVVM2x86_TRITON_IR__
#define __NVVM2x86_TRITON_IR__
#include "llvm/IR/Module.h"

// Stock Triton LLVM IR (TRITON_CUPBOP=1) -> the NVVM form the rest of the translator reads. See triton_ir.cpp.
void lower_triton_input(llvm::Module *M);

#endif
