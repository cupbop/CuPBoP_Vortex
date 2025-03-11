#ifndef __NVVM2x86_INSERT_WARP_LOOP__
#define __NVVM2x86_INSERT_WARP_LOOP__

#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <set>

using namespace llvm;

void insert_warp_loop(llvm::Module *M);


// The declarations below are for sharing the functions with warp_func.cpp
// Might be refactored later for better code organization

struct ParallelRegion {
    std::set<llvm::BasicBlock *> wrapped_block;
    llvm::BasicBlock *successor_block;
    llvm::BasicBlock *start_block;
    llvm::BasicBlock *end_block;
    bool inst_in_region(llvm::Instruction *inst);
    bool inst_used_in_region(llvm::Instruction *inst);
};

llvm::Instruction *GetCachedIntrawarpThreadIdx(llvm::Instruction *instruction, std::vector<ParallelRegion> &PRs);

llvm::Instruction *GetCachedBlockSize(llvm::Function *F);

#endif
