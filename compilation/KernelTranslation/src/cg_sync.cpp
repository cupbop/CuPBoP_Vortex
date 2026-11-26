#include "cg_sync.h"
#include <llvm/IR/InlineAsm.h>
#include <llvm/IR/IRBuilder.h>

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

void lower_grid_workspace_registers(llvm::Module *module) {
  // CUDA's cooperative_groups driver ABI exposes the workspace pointer in
  // envreg1 (high word) and envreg2 (low word) on SM80/SM90.
  llvm::SmallVector<llvm::CallInst *> reads;
  for (llvm::Function &function : *module)
    for (llvm::BasicBlock &block : function)
      for (llvm::Instruction &inst : block)
        if (auto *call = llvm::dyn_cast<llvm::CallInst>(&inst); call && call->isInlineAsm() &&
            call->arg_empty() && call->getType()->isIntegerTy(32)) {
          auto *assembly = llvm::cast<llvm::InlineAsm>(call->getCalledOperand());
          llvm::StringRef body = assembly->getAsmString();
          if (body == "mov.u32 $0, %envreg1;" || body == "mov.u32 $0, %envreg2;")
            reads.push_back(call);
        }
  for (auto *read : reads) {
    const auto *assembly = llvm::cast<llvm::InlineAsm>(read->getCalledOperand());
    llvm::IRBuilder<> b(read);
    auto workspace = module->getOrInsertFunction("__cupbop_grid_workspace", b.getPtrTy());
    llvm::Value *address = b.CreatePtrToInt(b.CreateCall(workspace), b.getInt64Ty());
    if (llvm::StringRef(assembly->getAsmString()).ends_with("%envreg1;"))
      address = b.CreateLShr(address, 32);
    read->replaceAllUsesWith(b.CreateTrunc(address, b.getInt32Ty()));
    read->eraseFromParent();
  }
}
