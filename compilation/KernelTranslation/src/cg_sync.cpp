#include "cg_sync.h"

bool isCGThreadBlockSync(const std::string &FuncNameStr) {
    // cg::
    bool hasCgnamespace = FuncNameStr.find("cooperative_groups") != FuncNameStr.npos;
    // synchronize(thread_block) or sync(thread_block)
    bool hasBlockSynchronize = (FuncNameStr.find("synchronize") != FuncNameStr.npos || FuncNameStr.find("sync") != FuncNameStr.npos) && FuncNameStr.find("thread_block") != FuncNameStr.npos;
    // thread_block::sync()
    bool hasBlockSync = FuncNameStr.find("sync") != FuncNameStr.npos && FuncNameStr.find("thread_block") != FuncNameStr.npos;

    return (hasCgnamespace && (hasBlockSynchronize || hasBlockSync));
}

bool isCGThreadGroupSync(const std::string &FuncNameStr) {
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
    bool state = isCGThreadBlockSync(name) || isCGThreadGroupSync(name);
    if (state)
      printf("Found CG Sync: %s\n", name.c_str());
    return state;
}


// @_Z10__syncwarpj(i32 noundef -1) or llvm.nvvm.bar.warp.sync
bool isWarpSync(const std::string &FuncNameStr) {
    return FuncNameStr.find("syncwarp") != FuncNameStr.npos || FuncNameStr == "llvm.nvvm.bar.warp.sync";
}

bool has_cg_group_sync(llvm::Module *M) {
  for (auto F = M->begin(); F != M->end(); ++F)
    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = llvm::dyn_cast<llvm::CallInst>(BI)) {
          if (Call->isInlineAsm())
            continue;

          if (isCGThreadGroupSync(Call->getCalledOperand()->getName().str())) {
            return true;
          }
        }
      }
    }
  return false;
}