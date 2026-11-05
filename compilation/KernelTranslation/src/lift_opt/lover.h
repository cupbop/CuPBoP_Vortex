// lover.h (2026-11-04, experiments/p4): a function's body in two versions behind a CTA-uniform condition.
//   Version V(F, at);   entry block is split at `at` (default: behind the allocas); what comes before stays shared
//   ... rewrite F ...; V.commit(cond builder)   the rewritten body runs when cond is true, the untouched copy otherwise.
//   V.drop()                                    nothing happened (the split stays, a plain branch).
// The barriers of both bodies are reached by the whole CTA: the condition must be uniform.
#pragma once
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include <functional>
#include <vector>
struct Version {
  llvm::Function &F; llvm::Function *G = nullptr; llvm::ValueToValueMapTy VM; llvm::BasicBlock *E = nullptr, *Start = nullptr;
  Version(llvm::Function &F, llvm::Instruction *at = nullptr) : F(F) {
    using namespace llvm;
    E = &F.getEntryBlock();
    // behind the allocas and the stores that fill them (the parameter block): the translator forwards a buffer written once, a second copy of those stores would keep it on the stack
    if (!at) { at = &*E->getFirstNonPHIOrDbg(); while (isa<AllocaInst>(at)) at = at->getNextNode();
      for (Instruction &I : *E) if (auto *S = dyn_cast<StoreInst>(&I)) if (isa<AllocaInst>(getUnderlyingObject(S->getPointerOperand()))) if (at->comesBefore(S) || at == S) at = S->getNextNode(); }
    Start = E->splitBasicBlock(at, "ver.fast");
    G = CloneFunction(&F, VM);
  }
  void drop() { if (G) { G->eraseFromParent(); G = nullptr; } }
  void commit(const std::function<llvm::Value *(llvm::IRBuilder<> &)> &cond) {
    using namespace llvm;
    BasicBlock *Ec = cast<BasicBlock>((Value *)VM[E]), *Sc = cast<BasicBlock>((Value *)VM[Start]);
    for (Instruction &I : *E) if (auto it = VM.find(&I); it != VM.end() && it->second) cast<Instruction>((Value *)it->second)->replaceAllUsesWith(&I);
    for (auto a = F.arg_begin(), b = G->arg_begin(); a != F.arg_end(); ++a, ++b) b->replaceAllUsesWith(&*a);
    Ec->dropAllReferences(); Ec->eraseFromParent();
    std::vector<BasicBlock *> Bs; for (BasicBlock &B : *G) Bs.push_back(&B);
    for (BasicBlock *B : Bs) { B->removeFromParent(); B->insertInto(&F); }
    E->getTerminator()->eraseFromParent();
    IRBuilder<> Q(E);
    Q.CreateCondBr(cond(Q), Start, Sc);
    G->eraseFromParent(); G = nullptr;
  }
};
