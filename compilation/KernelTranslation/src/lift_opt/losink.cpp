// losink.cpp (2026-11-04, experiments/p3): pass `lo-sink`, the sink half of lo-rfx (experiments/p2g/tools/lorfx.cpp) without the RFX slots. Runs after lo-mma, needs loop-simplify.
// Pure code that reads the last accumulators of a loop-carried WMMA chain, with all its results used after the loop (LO_F16_ACC=2 leaves the f16 pack there), moves to the exit block.
// A loop or chain that does not fit stays as it is. Env: LO_SINK=0 turns it off.
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/LoopIterator.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Local.h"
#include <algorithm>
#include <cstdlib>
#include <set>
#include <vector>
using namespace llvm;
namespace {
constexpr unsigned C0 = 17;   // lo.wmma(ptr frag, a0..7, b0..7, c0..7): first C argument
bool isW(const Value *V) { auto *C = dyn_cast<CallInst>(V); return C && C->getCalledFunction() && C->getCalledFunction()->getName() == "lo.wmma"; }
bool isZero(Value *V) { auto *C = dyn_cast<Constant>(V); return C && C->isNullValue(); }
SmallVector<ExtractValueInst *, 2> ds(CallInst *W, unsigned i) {
  SmallVector<ExtractValueInst *, 2> r;
  for (User *U : W->users()) if (auto *E = dyn_cast<ExtractValueInst>(U)) if (E->getIndices()[0] == i) r.push_back(E);
  return r;
}
bool isD(Value *V, CallInst *W, unsigned i) { auto *E = dyn_cast<ExtractValueInst>(V); return E && E->getAggregateOperand() == W && E->getIndices()[0] == i; }
struct Chain { std::vector<CallInst *> ws; PHINode *ph[8] = {}; unsigned mask = 0; };
bool closure(Instruction *I, Loop *L, std::set<Instruction *> &S) {
  if (S.count(I)) return true;
  if (isa<PHINode>(I) || I->isTerminator()) return false;
  if (auto *C = dyn_cast<CallInst>(I)) { Function *F = C->getCalledFunction(); if (!F || !F->getName().starts_with("lo.cvt.")) return false; }
  else if (I->mayHaveSideEffects() || I->mayReadFromMemory()) return false;
  S.insert(I);
  for (User *U : I->users()) { auto *J = cast<Instruction>(U); if (L->contains(J->getParent()) && !closure(J, L, S)) return false; }
  return true;
}
bool buildChain(CallInst *W, Loop *L, BasicBlock *LT, LoopInfo &LI, Chain &c) {
  BasicBlock *H = L->getHeader();
  for (unsigned i = 0; i < 8; ++i) {
    Value *V = W->getArgOperand(C0 + i);
    if (auto *P = dyn_cast<PHINode>(V)) { if (P->getParent() != H) return false; c.ph[i] = P; c.mask |= 1u << i; }
    else if (!isZero(V)) return false;
  }
  if (!c.mask) return false;
  c.ws.push_back(W);
  for (CallInst *cur = W;;) {
    CallInst *next = nullptr;
    for (unsigned i = 0; i < 8; ++i) if (c.mask >> i & 1) for (auto *E : ds(cur, i)) for (User *U : E->users()) if (isW(U) && LI.getLoopFor(cast<Instruction>(U)->getParent()) == L) {
      auto *N = cast<CallInst>(U);
      if (next && next != N) return false;
      next = N;
    }
    if (!next) break;
    for (unsigned i = 0; i < 8; ++i) { Value *V = next->getArgOperand(C0 + i); if ((c.mask >> i & 1) ? !isD(V, cur, i) : !isZero(V)) return false; }
    if (std::find(c.ws.begin(), c.ws.end(), next) != c.ws.end()) return false;
    c.ws.push_back(next); cur = next;
  }
  for (unsigned i = 0; i < 8; ++i) if (c.mask >> i & 1) if (!isD(c.ph[i]->getIncomingValueForBlock(LT), c.ws.back(), i)) return false;
  return true;
}
void runOn(Function &F) {
  std::vector<CallInst *> ws;
  for (auto &BB : F) for (auto &I : BB) if (isW(&I)) ws.push_back(cast<CallInst>(&I));
  if (ws.empty()) return;
  DominatorTree DT(F); LoopInfo LI(DT); unsigned moved = 0;
  for (Loop *L : LI.getLoopsInPreorder()) {
    std::vector<CallInst *> mine;
    for (CallInst *W : ws) if (LI.getLoopFor(W->getParent()) == L) mine.push_back(W);
    if (mine.empty()) continue;
    BasicBlock *PH = L->getLoopPreheader(), *LT = L->getLoopLatch(), *X = L->getExitingBlock(), *EX = L->getUniqueExitBlock();
    if (!PH || !LT || !X || !EX || EX->getSinglePredecessor() != X) continue;
    FoldSingleEntryPHINodes(EX);
    std::vector<Chain> cs; std::set<CallInst *> seen;
    for (CallInst *W : mine) {
      if (seen.count(W)) continue;
      bool head = false; for (unsigned i = 0; i < 8; ++i) if (isa<PHINode>(W->getArgOperand(C0 + i))) head = true;
      if (!head) continue;
      Chain c; if (!buildChain(W, L, LT, LI, c)) continue;
      bool ok = true;
      for (CallInst *w : c.ws) { seen.insert(w); if (!DT.dominates(w->getParent(), LT) || !DT.dominates(w->getParent(), X)) ok = false; }
      if (ok) cs.push_back(std::move(c));
    }
    std::set<Instruction *> S;
    for (Chain &c : cs) {
      std::set<Instruction *> Sc; bool ok = true;
      for (unsigned i = 0; i < 8 && ok; ++i) if (c.mask >> i & 1) for (auto *E : ds(c.ws.back(), i)) for (User *U : E->users()) {
        auto *J = cast<Instruction>(U);
        if (J == c.ph[i] || !L->contains(J->getParent())) continue;
        if (!closure(J, L, Sc)) ok = false;
      }
      for (Instruction *I : Sc) {
        if (!DT.dominates(I->getParent(), X)) ok = false;   // it must run in the exiting iteration, else the exit block would see newer operands
        for (Value *V : I->operands()) if (auto *D = dyn_cast<Instruction>(V)) if (!Sc.count(D) && L->contains(D->getParent()) && !DT.dominates(D, X->getTerminator())) ok = false;
      }
      if (ok) S.insert(Sc.begin(), Sc.end());
    }
    if (!S.empty()) {
      LoopBlocksRPO R(L); R.perform(&LI); Instruction *at = &*EX->getFirstInsertionPt();
      for (BasicBlock *B : R) for (Instruction &I : make_early_inc_range(*B)) if (S.count(&I)) { I.moveBefore(at); moved++; }
    }
  }
  if (moved) errs() << "lo-sink: " << F.getName().substr(0, 40) << ": " << moved << " instructions moved to the exit\n";
}
struct LoSink : PassInfoMixin<LoSink> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    const char *e = getenv("LO_SINK"); if (e && atoi(e) == 0) return PreservedAnalyses::all();
    std::vector<Function *> fs; for (auto &F : M) if (!F.isDeclaration() && !F.getName().starts_with("lo.")) fs.push_back(&F);
    for (Function *F : fs) runOn(*F);
    return PreservedAnalyses::none();
  }
};
} // namespace

void p3RegisterSink(PassBuilder &PB) {
  PB.registerPipelineParsingCallback([](StringRef N, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
    if (N == "lo-sink") { MPM.addPass(LoSink()); return true; }
    return false; });
}
