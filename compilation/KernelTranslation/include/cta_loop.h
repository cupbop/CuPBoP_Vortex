#ifndef __CUPBOP_CTA_LOOP__
#define __CUPBOP_CTA_LOOP__

#include "llvm/IR/Module.h"

// CUPBOP_CTA_LOOP (default off; 2026-11-04, experiments/ctaloop): one hardware CTA runs several CUDA blocks. See cta_loop.cpp.
void cta_loop_transform(llvm::Module *M);   // after generate_wrapper, before the optimizer
void cta_loop_finalize_wrapper();           // end of the translation: kernel_main takes the wrapper with the loop
void cta_empty_exit(llvm::Module *M);       // CUPBOP_CTA_EMPTY (default off): blocks past a range guard skip the kernel

#endif
