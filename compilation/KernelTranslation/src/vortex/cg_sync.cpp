#include "cg_sync.h"

#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"


bool isCGThreadBlockSync(const std::string &FuncNameStr) {
    // cg::
    bool hasCgnamespace = FuncNameStr.find("cooperative_groups") != FuncNameStr.npos;
    // synchronize(thread_block) or sync(thread_block)
    bool hasBlockSynchronize = (FuncNameStr.find("synchronize") != FuncNameStr.npos || FuncNameStr.find("sync") != FuncNameStr.npos) && FuncNameStr.find("thread_block") != FuncNameStr.npos;
    // thread_block::sync()
    bool hasBlockSync = FuncNameStr.find("sync") != FuncNameStr.npos && FuncNameStr.find("thread_block") != FuncNameStr.npos;

    return (hasCgnamespace && (hasBlockSynchronize || hasBlockSync));
}

bool isThreadGroupSync(const std::string &FuncNameStr) {
    // cg::
    bool hasCgnamespace = FuncNameStr.find("cooperative_groups") != FuncNameStr.npos;
    // synchronize(thread_block) or sync(thread_block)
    bool hasBlockSynchronize = (FuncNameStr.find("sync") != FuncNameStr.npos || FuncNameStr.find("synchronize") != FuncNameStr.npos) && FuncNameStr.find("thread_group") != FuncNameStr.npos;
    // thread_block::sync()
    bool hasBlockSync = FuncNameStr.find("sync") != FuncNameStr.npos && FuncNameStr.find("thread_group") != FuncNameStr.npos;

    return hasCgnamespace && (hasBlockSynchronize || hasBlockSync);
}

// Check if the given call instruction is a cooperative group symchronization related calls
// @_ZN18cooperative_groups11synchronizeENS_12thread_blockE
// @_ZNK18cooperative_groups12thread_group4syncEv(
bool isCGSync(const std::string &name) {
    bool state = isCGThreadBlockSync(name) || isThreadGroupSync(name);
    if (state)
      printf("Found CG Sync: %s\n", name.c_str());
    return state;
}
