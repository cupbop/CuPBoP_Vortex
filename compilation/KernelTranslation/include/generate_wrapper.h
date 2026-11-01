#ifndef __NVVM2x86_GENERATE_X86_FORMAT__
#define __NVVM2x86_GENERATE_X86_FORMAT__

#include "llvm/IR/Module.h"

void generate_wrapper(llvm::Module *M);

// wide by-value kernel parameters -> pointer to their consecutive launch slots (see generate_wrapper.cpp)
void pass_wide_kernel_args_by_slot(llvm::Module *M);
// by-value struct parameters -> pointer to their launch slots, a private copy where written (generate_wrapper.cpp)
void prepare_byval_args(llvm::Module *M);

void set_meta_data(llvm::Module *M);

// CUPBOP_KABI: Vortex kernel calling convention for the kernels and their wrappers, cupbop_kabi.txt (see generate_wrapper.cpp)
void annotate_kernel_abi(llvm::Module *M);

// CUPBOP_SP_SKEW: launch-time bounds of the run-time sized stack allocas -> cupbop_dyn_stack.txt (see generate_wrapper.cpp)
void describe_dyn_stack(llvm::Module *M);

#endif
