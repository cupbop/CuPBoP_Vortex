// lostale.cpp: lo-stale, "path-contradicted phi incoming" removal.
// A phi incoming (P, edge e) carries a value only for paths through e. If every real use of P sits behind a branch
// condition that contradicts a condition known on e (same pure expression over the same SSA leaves), that value is
// never observed, so the incoming becomes poison. Phi uses are handled by a greatest fixed point (a use by (Q, f)
// is fine when f contradicts e, or when (Q, f) is itself dropped). Removes stale values that lift keeps alive in
// register-slot phis around "guard chain" code (loop-carried slots, 33-way merges).
// Soundness argument: every leaf of a fact on e must dominate the phi block M; then the leaf instance at the last
// entry to M equals the instance at any later use dominated by M. Facts are about pure expressions only.
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/CFG.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Module.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include <map>
#include <set>
#include <string>
#include <vector>
using namespace llvm;
namespace {
struct KeyInfo { std::string s; std::set<Value *> leaves; };
struct Cx {
  std::map<std::string, int> ids;
  std::vector<std::set<Value *>> leaves;   // per key id
  // entry-only allocas (lift's param_local): a load at constant offset is the same value wherever it sits
  std::map<AllocaInst *, bool> ro;
  bool roAlloca(AllocaInst *A) {
    auto it = ro.find(A); if (it != ro.end()) return it->second;
    bool ok = true; SmallVector<Value *, 16> W{A};
    while (!W.empty() && ok) { Value *V = W.pop_back_val();
      for (User *U : V->users()) {
        if (isa<GetElementPtrInst>(U)) { W.push_back(U); continue; }
        if (isa<LoadInst>(U)) continue;
        if (auto *St = dyn_cast<StoreInst>(U)) { if (St->getPointerOperand() == V && St->getParent()->isEntryBlock()) continue; }
        ok = false; break; } }
    return ro[A] = ok;
  }
  // value = bytes [off, off+size) of an entry-only alloca
  bool slot(Value *V, AllocaInst *&A, int64_t &off, unsigned &size) {
    if (auto *T = dyn_cast<TruncInst>(V)) {
      unsigned sz = T->getType()->getIntegerBitWidth(); if (sz % 8) return false;
      Value *X = T->getOperand(0); int64_t sh = 0;
      if (auto *B = dyn_cast<BinaryOperator>(X)) if (B->getOpcode() == Instruction::LShr) if (auto *C = dyn_cast<ConstantInt>(B->getOperand(1))) { sh = C->getZExtValue(); X = B->getOperand(0); }
      if (sh % 8 || !slot(X, A, off, size)) return false;
      off += sh / 8; size = sz / 8; return true;
    }
    auto *Ld = dyn_cast<LoadInst>(V); if (!Ld || !Ld->getType()->isIntegerTy()) return false;
    Value *P = Ld->getPointerOperand(); off = 0;
    const DataLayout &DL = Ld->getDataLayout();
    APInt O(64, 0); Value *Base = P->stripAndAccumulateConstantOffsets(DL, O, false);
    A = dyn_cast<AllocaInst>(Base); if (!A || !roAlloca(A)) return false;
    off = O.getSExtValue(); size = Ld->getType()->getIntegerBitWidth() / 8; return true;
  }
  bool expr(Value *V, std::string &s, std::set<Value *> &L, int d) {
    { AllocaInst *A; int64_t off; unsigned sz; if (slot(V, A, off, sz)) { char b[64]; snprintf(b, 64, "slot%p+%ld:%u ", (void *)A, (long)off, sz); s += b; return true; } }
    if (auto *C = dyn_cast<ConstantInt>(V)) { SmallString<32> T; C->getValue().toStringSigned(T); s += "c" + std::to_string(C->getBitWidth()) + ":" + std::string(T) + " "; return true; }
    if (d < 6) if (auto *I = dyn_cast<Instruction>(V)) {
      if (isa<BinaryOperator>(I) && !I->getType()->isFPOrFPVectorTy()) {
        s += std::string(I->getOpcodeName()) + "("; expr(I->getOperand(0), s, L, d + 1); expr(I->getOperand(1), s, L, d + 1); s += ")"; return true;
      }
      if (isa<ZExtInst>(I) || isa<SExtInst>(I) || isa<TruncInst>(I)) {
        s += std::string(I->getOpcodeName()) + std::to_string(I->getType()->getScalarSizeInBits()) + "("; expr(I->getOperand(0), s, L, d + 1); s += ")"; return true;
      }
    }
    if (isa<Constant>(V)) { char b[32]; snprintf(b, 32, "k%p ", (void *)V); s += b; return true; }
    char b[32]; snprintf(b, 32, "v%p ", (void *)V); s += b; L.insert(V); return true;
  }
  // canonical condition: returns key id, sets neg when the value is the negation of the key
  int cond(Value *V, bool &neg) {
    neg = false;
    for (int it = 0; it < 8; ++it) {
      if (auto *Z = dyn_cast<ZExtInst>(V)) { if (Z->getSrcTy()->isIntegerTy(1)) { V = Z->getOperand(0); continue; } }
      if (auto *B = dyn_cast<BinaryOperator>(V)) if (B->getOpcode() == Instruction::Xor && V->getType()->isIntegerTy(1))
        if (auto *C = dyn_cast<ConstantInt>(B->getOperand(1))) { if (C->isOne()) neg = !neg; V = B->getOperand(0); continue; }
      if (auto *I = dyn_cast<ICmpInst>(V)) {
        auto *C = dyn_cast<ConstantInt>(I->getOperand(1));
        if (C && C->isZero() && (I->getPredicate() == ICmpInst::ICMP_NE || I->getPredicate() == ICmpInst::ICMP_EQ)) {
          auto *Z = dyn_cast<ZExtInst>(I->getOperand(0));
          if (Z && Z->getSrcTy()->isIntegerTy(1)) { if (I->getPredicate() == ICmpInst::ICMP_EQ) neg = !neg; V = Z->getOperand(0); continue; }
        }
      }
      break;
    }
    std::string s; std::set<Value *> L;
    if (auto *I = dyn_cast<ICmpInst>(V)) {
      auto P = I->getPredicate(); Value *A = I->getOperand(0), *B = I->getOperand(1);
      switch (P) {   // sle/sge/ule/uge/ne -> negation of a strict form or eq
      case ICmpInst::ICMP_SGE: P = ICmpInst::ICMP_SLT; neg = !neg; break;
      case ICmpInst::ICMP_SLE: P = ICmpInst::ICMP_SGT; neg = !neg; break;
      case ICmpInst::ICMP_UGE: P = ICmpInst::ICMP_ULT; neg = !neg; break;
      case ICmpInst::ICMP_ULE: P = ICmpInst::ICMP_UGT; neg = !neg; break;
      case ICmpInst::ICMP_NE: P = ICmpInst::ICMP_EQ; neg = !neg; break;
      default: break; }
      if (P == ICmpInst::ICMP_SGT) { P = ICmpInst::ICMP_SLT; std::swap(A, B); }
      if (P == ICmpInst::ICMP_UGT) { P = ICmpInst::ICMP_ULT; std::swap(A, B); }
      s = "icmp" + std::to_string((int)P) + "("; expr(A, s, L, 0); expr(B, s, L, 0); s += ")";
    } else if (auto *F = dyn_cast<FCmpInst>(V)) {
      s = "fcmp" + std::to_string((int)F->getPredicate()) + "("; 
      char b[64]; snprintf(b, 64, "v%p v%p", (void *)F->getOperand(0), (void *)F->getOperand(1)); s += b; s += ")";
      L.insert(F->getOperand(0)); L.insert(F->getOperand(1));
    } else { char b[32]; snprintf(b, 32, "b%p", (void *)V); s = b; L.insert(V); }
    auto it = ids.find(s);
    if (it != ids.end()) return it->second;
    int id = ids.size(); ids[s] = id; leaves.push_back(L); return id;
  }
};
using Facts = std::map<int, bool>;
struct LoStale : PassInfoMixin<LoStale> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM) {
    auto &DT = AM.getResult<DominatorTreeAnalysis>(F);
    Cx X;
    std::map<BasicBlock *, Facts> BF;
    auto addEdge = [&](Facts &R, BasicBlock *I, BasicBlock *S) {   // edge I->S taken
      auto *Br = dyn_cast<BranchInst>(I->getTerminator());
      if (!Br || !Br->isConditional() || Br->getSuccessor(0) == Br->getSuccessor(1)) return;
      bool neg; int k = X.cond(Br->getCondition(), neg);
      bool val = (S == Br->getSuccessor(0)) ^ neg;   // value of the key on this edge
      R[k] = val;
    };
    for (auto &B : F) {
      if (!DT.isReachableFromEntry(&B)) continue;
      Facts R;
      for (auto *N = DT.getNode(&B); N && N->getIDom(); N = N->getIDom()) {
        BasicBlock *X0 = N->getBlock();
        for (auto *A = N->getIDom(); A; A = A->getIDom()) {
          auto *Br = dyn_cast<BranchInst>(A->getBlock()->getTerminator());
          if (Br && Br->isConditional()) for (unsigned s = 0; s < 2; ++s) {
            BasicBlockEdge E(A->getBlock(), Br->getSuccessor(s));
            if (E.isSingleEdge() && DT.dominates(E, &B)) addEdge(R, A->getBlock(), Br->getSuccessor(s));
          }
        }
        (void)X0; break;
      }
      BF[&B] = R;
    }
    struct Pair { PHINode *P; unsigned i; };
    std::map<std::pair<PHINode *, BasicBlock *>, bool> S;   // candidate drop set
    std::vector<PHINode *> Phis;
    for (auto &B : F) if (DT.isReachableFromEntry(&B)) for (auto &P : B.phis()) {
      Phis.push_back(&P);
      for (unsigned i = 0; i < P.getNumIncomingValues(); ++i) S[{&P, P.getIncomingBlock(i)}] = true;
    }
    auto factsOnEdge = [&](BasicBlock *Pred, BasicBlock *M) { Facts R = BF[Pred]; addEdge(R, Pred, M); return R; };
    auto valid = [&](int k, BasicBlock *M) {
      for (Value *L : X.leaves[k]) if (auto *I = dyn_cast<Instruction>(L)) {
        if (I->getParent() == M || !DT.dominates(I->getParent(), M)) return false;
      }
      return true;
    };
    auto contra = [&](const Facts &A, const Facts &B, BasicBlock *M) {
      for (auto &kv : A) { auto it = B.find(kv.first); if (it != B.end() && it->second != kv.second && valid(kv.first, M)) return true; }
      return false;
    };
    std::map<std::pair<BasicBlock *, BasicBlock *>, Facts> EF;
    auto ef = [&](BasicBlock *Pred, BasicBlock *M) -> const Facts & {
      auto key = std::make_pair(Pred, M); auto it = EF.find(key);
      if (it != EF.end()) return it->second;
      return EF[key] = factsOnEdge(Pred, M);
    };
    bool ch = true; int rounds = 0;
    while (ch) { ch = false; ++rounds;
      for (auto *P : Phis) { BasicBlock *M = P->getParent();
        for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) {
          BasicBlock *E = P->getIncomingBlock(i); auto key = std::make_pair(P, E);
          if (!S[key]) continue;
          const Facts &FE = ef(E, M); bool ok = true; Instruction *Why = nullptr;
          for (User *U : P->users()) { auto *UI = cast<Instruction>(U);
            if (auto *Q = dyn_cast<PHINode>(UI)) {
              for (unsigned j = 0; j < Q->getNumIncomingValues() && ok; ++j) if (Q->getIncomingValue(j) == P) {
                BasicBlock *Fb = Q->getIncomingBlock(j);
                if (!DT.dominates(M, Fb)) { ok = false; Why = Q; break; }   // loop-carried first use: value crosses M, keep it simple
                if (contra(FE, ef(Fb, Q->getParent()), M)) continue;
                if (!S[{Q, Fb}]) { ok = false; Why = Q; }
              }
            } else {
              if (!DT.dominates(M, UI->getParent()) || !contra(FE, BF[UI->getParent()], M)) { ok = false; Why = UI; }
            }
            if (!ok) break;
          }
          if (!ok) { S[key] = false; ch = true;
            if (getenv("LO_STALE_D")) { errs() << "fail " << P->getName() << " in " << M->getName() << " edge " << E->getName() << " round " << rounds << " why: "; if (Why) Why->print(errs()); errs() << "\n"; } }
        }
      }
    }
    unsigned n = 0, nall = 0;
    for (auto *P : Phis) {
      for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) {
        if (!S[{P, P->getIncomingBlock(i)}]) continue;
        Value *V = P->getIncomingValue(i);
        if (isa<PoisonValue>(V) || isa<UndefValue>(V) || (getenv("LO_STALE_ZERO") && isa<Constant>(V) && cast<Constant>(V)->isNullValue())) continue;
        P->setIncomingValue(i, getenv("LO_STALE_ZERO") ? Constant::getNullValue(P->getType()) : (Constant *)PoisonValue::get(P->getType())); ++n;
      }
    }
    (void)nall;
    if (getenv("LO_STALE_V")) errs() << "lo-stale " << F.getName().substr(0, 40) << ": " << Phis.size() << " phis, dropped " << n << " incomings, rounds " << rounds << "\n";
    return n ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
}
namespace {
// lo-nolicm: attach llvm.licm.disable to loops (all, or those over LO_NOLICM_MIN instructions) so O3 LICM leaves their invariants inside
struct LoNoLicm : PassInfoMixin<LoNoLicm> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM) {
    auto &LI = AM.getResult<LoopAnalysis>(F);
    unsigned mn = getenv("LO_NOLICM_MIN") ? atoi(getenv("LO_NOLICM_MIN")) : 0; unsigned n = 0;
    for (Loop *L : LI.getLoopsInPreorder()) {
      unsigned sz = 0; for (auto *B : L->blocks()) sz += B->size();
      if (sz < mn) continue;
      if (getenv("LO_NOLICM_GRID")) {   // only grid-stride loops: an induction stepped by nctaid.*, body with a barrier
        bool bar = false, grid = false;
        for (auto *B : L->blocks()) for (auto &I : *B) if (auto *C = dyn_cast<CallInst>(&I)) if (auto *Fn = C->getCalledFunction()) if (Fn->getName().starts_with("llvm.nvvm.barrier")) bar = true;
        for (auto &P : L->getHeader()->phis()) for (Value *In : P.incoming_values()) if (auto *A = dyn_cast<BinaryOperator>(In)) if (A->getOpcode() == Instruction::Add) for (Value *O : A->operands()) if (auto *C = dyn_cast<CallInst>(O)) if (auto *Fn = C->getCalledFunction()) if (Fn->getName().contains("sreg.nctaid")) grid = true;
        if (!bar || !grid) continue;
      }
      LLVMContext &C = F.getContext();
      SmallVector<Metadata *, 4> Ops; Ops.push_back(nullptr);
      if (MDNode *Old = L->getLoopID()) for (unsigned i = 1; i < Old->getNumOperands(); ++i) Ops.push_back(Old->getOperand(i));
      Ops.push_back(MDNode::get(C, {MDString::get(C, "llvm.licm.disable")}));
      MDNode *ID = MDNode::getDistinct(C, Ops); ID->replaceOperandWith(0, ID);
      L->setLoopID(ID); ++n;
    }
    if (getenv("LO_STALE_V")) errs() << "lo-nolicm " << F.getName().substr(0, 40) << ": " << n << " loops\n";
    return PreservedAnalyses::all();
  }
};
}
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "lostale", "0.1", [](PassBuilder &PB) {
    PB.registerPipelineParsingCallback([](StringRef N, FunctionPassManager &FPM, ArrayRef<PassBuilder::PipelineElement>) {
      if (N == "lo-stale") { FPM.addPass(LoStale()); return true; }
      if (N == "lo-nolicm") { FPM.addPass(LoNoLicm()); return true; }
      return false; });
  }};
}
