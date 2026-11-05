// lopred.cpp: lo-pred, merge guarded regions that test the same predicate.
// lift turns every @P instruction group into its own small if; between two such ifs there is often only code that does not care.
// X: if (c) T;  M..Y: other code;  Y: if (c) T2  ==>  X, M..Y (T gone), T2 = T + T2. Phis of M move to the merge of T2.
// Legal when the in-between code neither reads the phis of M nor conflicts with the memory operations of T; no barrier or convergent call in between.
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include <set>
#include <vector>
using namespace llvm;
namespace {
static Value *base(Value *V, bool &neg) {
  neg = false;
  for (int i = 0; i < 8; ++i) {
    if (auto *Z = dyn_cast<ZExtInst>(V)) if (Z->getSrcTy()->isIntegerTy(1)) { V = Z->getOperand(0); continue; }
    if (auto *B = dyn_cast<BinaryOperator>(V)) if (B->getOpcode() == Instruction::Xor && V->getType()->isIntegerTy(1)) if (auto *C = dyn_cast<ConstantInt>(B->getOperand(1))) if (C->isOne()) { neg = !neg; V = B->getOperand(0); continue; }
    if (auto *I = dyn_cast<ICmpInst>(V)) if (auto *C = dyn_cast<ConstantInt>(I->getOperand(1))) if (C->isZero() && (I->getPredicate() == ICmpInst::ICMP_NE || I->getPredicate() == ICmpInst::ICMP_EQ)) if (auto *Z = dyn_cast<ZExtInst>(I->getOperand(0))) if (Z->getSrcTy()->isIntegerTy(1)) { if (I->getPredicate() == ICmpInst::ICMP_EQ) neg = !neg; V = Z->getOperand(0); continue; }
    break;
  }
  return V;
}
static bool triangle(BasicBlock *X, BasicBlock *&T, BasicBlock *&M, bool &whenTrue, bool strict = true) {
  auto *Br = dyn_cast<BranchInst>(X->getTerminator()); if (!Br || !Br->isConditional()) return false;
  for (int s = 0; s < 2; ++s) { BasicBlock *A = Br->getSuccessor(s), *O = Br->getSuccessor(1 - s);
    if (A->getSinglePredecessor() == X && A->getSingleSuccessor() == O && A != O) { unsigned np = pred_size(O); if (strict && np != 2) continue; T = A; M = O; whenTrue = s == 0; return true; } }
  return false;
}
static bool blocker(Instruction &I) { if (auto *C = dyn_cast<CallBase>(&I)) { if (C->isConvergent()) return true; if (C->mayHaveSideEffects()) return true; } return false; }
struct LoPred : PassInfoMixin<LoPred> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    unsigned n = 0; bool ch = true; int rounds = 0;
    while (ch && rounds++ < 64) { ch = false;
      for (auto &XB : F) { BasicBlock *X = &XB, *T, *M; bool wt;
        if (!triangle(X, T, M, wt)) continue;
        bool neg; Value *C = base(cast<BranchInst>(X->getTerminator())->getCondition(), neg); bool act = wt ^ neg;   // T runs when C == act
        std::vector<BasicBlock *> Mid; BasicBlock *Y = M; bool ok = true; std::set<BasicBlock *> Seen;
        for (;;) { if (!Seen.insert(Y).second) { ok = false; break; } Mid.push_back(Y); auto *Br = dyn_cast<BranchInst>(Y->getTerminator()); if (!Br) { ok = false; break; } if (Br->isConditional()) break; BasicBlock *N = Br->getSuccessor(0); if (N->getSinglePredecessor() != Y) { ok = false; break; } Y = N; }
        if (!ok) continue;
        BasicBlock *T2, *M2; bool wt2; if (!triangle(Y, T2, M2, wt2, false)) continue;
        bool neg2; Value *C2 = base(cast<BranchInst>(Y->getTerminator())->getCondition(), neg2); if (C2 != C || (wt2 ^ neg2) != act) continue;
        if (M2 == M || T2 == T) continue;
        // legality of moving T over the blocks in between
        bool tSt = false, tLd = false; for (auto &I : *T) { if (blocker(I)) ok = false; if (I.mayWriteToMemory()) tSt = true; if (I.mayReadFromMemory()) tLd = true; if (auto *L = dyn_cast<LoadInst>(&I)) if (L->isVolatile()) tSt = true; if (auto *S = dyn_cast<StoreInst>(&I)) if (S->isVolatile()) tSt = true; }
        std::set<Instruction *> Ph; for (auto &P : M->phis()) { Ph.insert(&P); if (P.getNumIncomingValues() != 2) ok = false; }
        for (BasicBlock *B : Mid) for (auto &I : *B) { if (isa<PHINode>(&I) && B == M) continue; if (blocker(I)) ok = false; if (I.isTerminator() && B != Y) continue;
          if (I.mayWriteToMemory() && (tSt || tLd)) ok = false; if (I.mayReadFromMemory() && tSt) ok = false;
          for (Value *O : I.operands()) if (auto *OI = dyn_cast<Instruction>(O)) { if (Ph.count(OI)) ok = false; if (OI->getParent() == T) ok = false; } }
        if (pred_size(M2) != 2) for (auto &P : M->phis()) for (Use &U : P.uses()) { auto *I = cast<Instruction>(U.getUser()); if (I->getParent() == T2) continue; if (auto *R = dyn_cast<PHINode>(I)) if (R->getParent() == M2) { BasicBlock *In = R->getIncomingBlock(U); if (In == T2 || In == Y) continue; } ok = false; }
        if (!ok) continue;
        // the condition itself must be available at Y (it is: Y tests the same value)
        for (PHINode *P : [&] { std::vector<PHINode *> V; for (auto &Q : M->phis()) V.push_back(&Q); return V; }()) {
          Value *vT = P->getIncomingValueForBlock(T), *vE = P->getIncomingValueForBlock(X);
          PHINode *Q = nullptr; if (pred_size(M2) == 2) { Q = PHINode::Create(P->getType(), 2, P->getName() + ".m", M2->begin()); Q->addIncoming(vT, T2); Q->addIncoming(vE, Y); }
          std::vector<Use *> Us; for (Use &U : P->uses()) Us.push_back(&U);
          for (Use *U : Us) { auto *I = cast<Instruction>(U->getUser()); if (I == Q) continue;
            if (auto *R = dyn_cast<PHINode>(I)) if (R->getParent() == M2) { BasicBlock *In = R->getIncomingBlock(*U); U->set(In == T2 ? vT : vE); continue; }
            if (I->getParent() == T2) U->set(vT); else U->set(Q); }   // Q exists: checked below
          P->eraseFromParent();
        }
        auto It = T2->getFirstNonPHIIt(); std::vector<Instruction *> Mv; for (auto &I : *T) if (!I.isTerminator()) Mv.push_back(&I);
        for (auto *I : Mv) I->moveBefore(*T2, It);
        auto *Old = X->getTerminator(); IRBuilder<> B(Old); B.CreateBr(M); Old->eraseFromParent();
        T->getTerminator()->eraseFromParent(); new UnreachableInst(F.getContext(), T); T->eraseFromParent();
        ++n; ch = true; break;
      }
    }
    if (getenv("LO_PRED_V") && n) errs() << "lo-pred " << F.getName().substr(0, 40) << ": " << n << " merges\n";
    if (n && verifyFunction(F, &errs())) errs() << "lo-pred: broken " << F.getName() << "\n";
    return n ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
}
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "lopred", "0.1", [](PassBuilder &PB) {
    PB.registerPipelineParsingCallback([](StringRef N, FunctionPassManager &FPM, ArrayRef<PassBuilder::PipelineElement>) {
      if (N == "lo-pred") { FPM.addPass(LoPred()); return true; }
      return false; });
  }};
}
