// lomm.cpp (2026-11-04, experiments/p4): IDEAS 56, 57, 61 (seed g32 sd-minmax, sd-cvtphi). No kernel constants.
//  lo-mm: llvm.maximum/minimum.f32 (FMNMX.NAN) expand to one select per NaN test and a branch each on this target, with split/join on Vortex. A run of such calls in one block moves down to just before
//    the first instruction that uses one of them from outside (the calls are pure), and gets one test:
//      all leaf operands ordered -> llvm.maxnum/minnum (fmax.s/fmin.s); else the original calls. For non-NaN operands fmax.s gives the same value, signed zeros included (it orders -0 < +0).
//    IDEAS 57: LO_MM_CLAMP=1 (default): chains minimum(maximum(x, lo), hi) with lo = -inf and hi = +inf at run time return x (for x = NaN too: the original returns x, NaN). The bounds are usually launch
//    parameters, so the test is uniform.
//  lo-cvtphi: fpext half of a phi whose other inputs are constant zero, through bitcast, trunc, lshr by constant: the conversion moves onto the one non-constant edge and the phi becomes a float phi
//    (+0.0 on the constant edges, what fpext gives for bits 0). Runs before lo-hext. Only pays when the constant edge really runs.
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include <cstdlib>
using namespace llvm;
namespace {
int envI(const char *n, int d) { const char *e = getenv(n); return e && *e ? atoi(e) : d; }
static bool isMM(Instruction *I) { if (auto *C = dyn_cast<IntrinsicInst>(I)) return (C->getIntrinsicID() == Intrinsic::maximum || C->getIntrinsicID() == Intrinsic::minimum) && C->getType()->isFloatTy(); return false; }
struct LoMM : PassInfoMixin<LoMM> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    unsigned runs = 0, calls = 0; bool again = true; SmallPtrSet<BasicBlock *, 8> done; const bool clamp = envI("LO_MM_CLAMP", 1);
    while (again) { again = false;
      for (auto &B : F) { if (done.count(&B)) continue;
        Instruction *c0 = nullptr; for (auto &I : B) if (isMM(&I)) { c0 = &I; break; }
        if (!c0) continue;
        SmallVector<Instruction *, 16> R; SmallPtrSet<Value *, 16> S; Instruction *U = nullptr;
        for (auto It = c0->getIterator(); It != B.end(); ++It) { Instruction *I = &*It;
          if (isMM(I)) { R.push_back(I); S.insert(I); continue; }
          bool uses = false; for (Value *O : I->operands()) if (S.count(O)) uses = true;
          if (uses || I->isTerminator()) { U = I; break; } }
        for (auto *I : R) I->moveBefore(U->getIterator());
        // the operands of a call may be defined between the calls: moved down they still dominate; the test goes in front of the first call, behind everything
        IRBuilder<> b(R[0]); Value *ok = nullptr; SmallPtrSet<Value *, 16> seen;
        for (auto *I : R) for (unsigned k = 0; k < 2; ++k) { Value *O = I->getOperand(k); if (S.count(O) || isa<ConstantFP>(O) || !seen.insert(O).second) continue;
          Value *c = b.CreateFCmpORD(O, O); ok = ok ? b.CreateAnd(ok, c) : c; }
        if (!ok) continue;
        // clamp: every call of the run is max(x, lo) of a leaf or min(max, hi); all lo = -inf, all hi = +inf
        Value *id = nullptr; bool chain = clamp;
        if (chain) { SmallPtrSet<Value *, 16> b2;
          for (auto *I : R) { bool mx = cast<IntrinsicInst>(I)->getIntrinsicID() == Intrinsic::maximum; Value *x = I->getOperand(0), *O = I->getOperand(1);
            if (S.count(O) || mx == S.count(x) > 0) { chain = false; break; }
            if (b2.insert(O).second) { Value *c = b.CreateFCmpOEQ(O, ConstantFP::getInfinity(O->getType(), mx)); id = id ? b.CreateAnd(id, c) : c; } } }
        if (!chain) id = nullptr;
        BasicBlock *Mid = nullptr; Instruction *ThI = nullptr, *ElI = nullptr, *Th = nullptr, *El = nullptr;
        DenseMap<Value *, Value *> MI, M;
        if (id) { SplitBlockAndInsertIfThenElse(id, R[0]->getIterator(), &ThI, &ElI); }
        Value *ok2 = ok;
        { Instruction *At = id ? ElI : R[0]; SplitBlockAndInsertIfThenElse(ok2, At->getIterator(), &Th, &El); }
        // R[0] sits in the join block now
        IRBuilder<> t(Th);
        for (auto *I : R) { Value *x = I->getOperand(0), *y = I->getOperand(1); if (M.count(x)) x = M[x]; if (M.count(y)) y = M[y];
          auto *C = cast<IntrinsicInst>(I); M[I] = t.CreateBinaryIntrinsic(C->getIntrinsicID() == Intrinsic::maximum ? Intrinsic::maxnum : Intrinsic::minnum, x, y); }
        for (auto *I : R) I->moveBefore(El->getIterator());
        BasicBlock *Tail = El->getParent()->getSingleSuccessor();   // join of the ok diamond
        IRBuilder<> p(&*Tail->begin());
        DenseMap<Value *, Value *> J;
        for (auto *I : R) { PHINode *P = p.CreatePHI(I->getType(), 2); P->addIncoming(M[I], Th->getParent()); P->addIncoming(I, El->getParent()); J[I] = P; }
        Value *fin = nullptr; DenseMap<Value *, Value *> Fin = J;
        if (id) { BasicBlock *Join = R.back()->getParent(); (void)Join; BasicBlock *T2 = ThI->getParent(), *E2 = Tail;
          BasicBlock *JB = T2->getSingleSuccessor(); IRBuilder<> q(&*JB->begin());
          for (auto *I : R) { Value *x = I->getOperand(0); while (S.count(x)) x = cast<Instruction>(x)->getOperand(0); PHINode *P = q.CreatePHI(I->getType(), 2); P->addIncoming(x, T2); P->addIncoming(J[I], E2); Fin[I] = P; } }
        (void)fin; (void)Mid;
        for (auto *I : R) { SmallVector<Use *, 4> ext; for (Use &u : I->uses()) if (!S.count(u.getUser()) && u.getUser() != J[I]) ext.push_back(&u); for (Use *u : ext) u->set(Fin[I]); }
        runs++; calls += R.size(); done.insert(Th->getParent()); done.insert(El->getParent()); if (id) done.insert(ThI->getParent()); again = true; break; }
    }
    if (runs) errs() << "lo-mm: " << F.getName().substr(0, 40) << ": " << calls << " calls in " << runs << " runs\n";
    return runs ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
struct LoCvtPhi : PassInfoMixin<LoCvtPhi> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    SmallVector<FPExtInst *, 32> L; for (auto &B : F) for (auto &I : B) if (auto *E = dyn_cast<FPExtInst>(&I)) if (E->getSrcTy()->isHalfTy()) L.push_back(E);
    unsigned n = 0;
    for (auto *E : L) { SmallVector<Instruction *, 4> ch; Value *V = E->getOperand(0);
      while (auto *I = dyn_cast<Instruction>(V)) { if (isa<PHINode>(I)) break; if (!(isa<BitCastInst>(I) || isa<TruncInst>(I) || (I->getOpcode() == Instruction::LShr && isa<ConstantInt>(I->getOperand(1))))) { V = nullptr; break; } ch.push_back(I); V = I->getOperand(0); }
      auto *P = dyn_cast_or_null<PHINode>(V); if (!P) continue;
      BasicBlock *In = nullptr; Value *X = nullptr; bool ok = true;
      for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) { Value *v = P->getIncomingValue(i); if (auto *C = dyn_cast<ConstantInt>(v)) { if (!C->isZero()) ok = false; } else if (!X) { X = v; In = P->getIncomingBlock(i); } else ok = false; }
      if (!ok || !X || !In->getSingleSuccessor()) continue;
      IRBuilder<> b(In->getTerminator()); Value *c = X; for (int i = ch.size() - 1; i >= 0; --i) { Instruction *K = ch[i]->clone(); K->setOperand(0, c); b.Insert(K); c = K; }
      Value *fx = b.CreateFPExt(c, E->getType());
      PHINode *N = PHINode::Create(E->getType(), P->getNumIncomingValues(), "lo.cvt", P->getIterator());
      for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) N->addIncoming(P->getIncomingBlock(i) == In ? fx : ConstantFP::get(E->getType(), 0.0), P->getIncomingBlock(i));
      E->replaceAllUsesWith(N); E->eraseFromParent(); n++; }
    if (n) errs() << "lo-cvtphi: " << n << " of " << L.size() << " fpext\n";
    return n ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
}
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "lomm", "0.1", [](PassBuilder &PB) {
    PB.registerPipelineParsingCallback([](StringRef N, FunctionPassManager &FPM, ArrayRef<PassBuilder::PipelineElement>) {
      if (N == "lo-mm") { FPM.addPass(LoMM()); return true; }
      if (N == "lo-cvtphi") { FPM.addPass(LoCvtPhi()); return true; }
      return false; });
  }};
}
