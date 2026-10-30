#ifndef __NVVM2x86_INSERT_WARP_LOOP__
#define __NVVM2x86_INSERT_WARP_LOOP__

#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

using namespace llvm;

void insert_warp_loop(llvm::Module *M);
// core mapping: move the context arrays to the host-allocated scratch buffer (after the translator's -O3)
void virt_ctx_to_scratch(llvm::Module *M);

#endif