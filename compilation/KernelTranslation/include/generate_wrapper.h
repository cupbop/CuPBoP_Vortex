#ifndef __NVVM2x86_GENERATE_X86_FORMAT__
#define __NVVM2x86_GENERATE_X86_FORMAT__

#include "llvm/IR/Module.h"

void generate_wrapper(llvm::Module *M);

// wide by-value kernel parameters -> pointer to their consecutive launch slots (see generate_wrapper.cpp)
void pass_wide_kernel_args_by_slot(llvm::Module *M);

void set_meta_data(llvm::Module *M);

#endif
