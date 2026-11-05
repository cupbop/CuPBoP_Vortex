// lonext.cpp (2026-11-04, experiments/p3): passes of step 2. No kernel constants; a pattern that does not match stays as it is.
//  half arithmetic (p3PromoteHalf, called by lo-mma before lo-f16): Vortex has no half arithmetic, the backend promotes each half op with __extendhfsf2 / __truncsfhf2 calls.
//    half and <N x half> fmul, fadd, fsub, fneg, fcmp, nvvm fmax, fmin (+ maxnum, minnum) become float ops, each result rounded with fptrunc: the same rounding as the
//    backend's promotion (float holds a product of two halves exactly and p = 24 >= 2 * 11 + 2 for add and sub, so double rounding cannot happen). fptrunc then goes through lo-f16.
//  lo-hext: fpext half -> float without a call. b = (h & 0x7fff) << 13 is the half bit pattern at float position: as a float it is the value * 2^-112 for every finite half,
//    subnormals included; multiplying by 2^112 is exact. Inf and NaN: the float exponent is set first, x * 2^112 keeps them. Sign by copysign. Branch free.
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/ADT/DepthFirstIterator.h"
#include <algorithm>
#include <cstdlib>
#include <functional>
#include <map>
#include <string>
#include <vector>
using namespace llvm;
namespace {
int envI(const char *n, int d) { const char *e = getenv(n); return e && *e ? atoi(e) : d; }
struct Half {
  Function &F; LLVMContext &C; Type *F32, *H, *I16, *I32; unsigned ops = 0;
  std::map<std::pair<Value *, unsigned>, Value *> memo;
  Half(Function &F_) : F(F_), C(F_.getContext()) { F32 = Type::getFloatTy(C); H = Type::getHalfTy(C); I16 = Type::getInt16Ty(C); I32 = Type::getInt32Ty(C); }
  static bool isH(Type *T) { return T->getScalarType()->isHalfTy(); }
  static unsigned nl(Type *T) { auto *V = dyn_cast<FixedVectorType>(T); return V ? V->getNumElements() : 1; }
  // the point that dominates every use of V
  Instruction *after(Value *V) {
    if (auto *I = dyn_cast<Instruction>(V)) { if (isa<PHINode>(I)) return &*I->getParent()->getFirstInsertionPt(); return I->getNextNode(); }
    return &*F.getEntryBlock().getFirstInsertionPt();
  }
  Value *lane(Value *V, unsigned i) {   // lane i of a half or <N x half> value, as an f16-exact float
    if (auto *CF = dyn_cast<ConstantFP>(V)) { bool l; APFloat a = CF->getValueAPF(); a.convert(APFloat::IEEEsingle(), APFloat::rmNearestTiesToEven, &l); return ConstantFP::get(F32, a); }
    if (auto *CD = dyn_cast<ConstantDataVector>(V)) return lane(CD->getElementAsConstant(i), 0);
    if (isa<ConstantAggregateZero>(V)) return ConstantFP::get(F32, 0.0);
    auto key = std::make_pair(V, i); auto it = memo.find(key); if (it != memo.end()) return it->second;
    Value *r = nullptr;
    if (auto *S = dyn_cast<ShuffleVectorInst>(V)) {
      int m = S->getMaskValue(i); unsigned n0 = nl(S->getOperand(0)->getType());
      if (m >= 0) r = (unsigned)m < n0 ? lane(S->getOperand(0), m) : lane(S->getOperand(1), m - n0);
    } else if (auto *E = dyn_cast<ExtractElementInst>(V)) {
      if (auto *CI = dyn_cast<ConstantInt>(E->getIndexOperand())) r = lane(E->getVectorOperand(), CI->getZExtValue());
    } else if (auto *In = dyn_cast<InsertElementInst>(V)) {
      if (auto *CI = dyn_cast<ConstantInt>(In->getOperand(2))) r = CI->getZExtValue() == i ? lane(In->getOperand(1), 0) : lane(In->getOperand(0), i);
    } else if (auto *B = dyn_cast<BitCastInst>(V)) {
      if (B->getSrcTy()->isIntegerTy(32) && nl(V->getType()) == 2) { IRBuilder<> Q(after(V)); Value *w = B->getOperand(0); if (i) w = Q.CreateLShr(w, 16);
        r = Q.CreateFPExt(Q.CreateBitCast(Q.CreateTrunc(w, I16), H), F32); }
    }
    if (!r) { IRBuilder<> Q(after(V)); Value *e = V->getType()->isVectorTy() ? Q.CreateExtractElement(V, (uint64_t)i) : V; r = Q.CreateFPExt(e, F32); }
    return memo[key] = r;
  }
  // replaces I by float lanes t[i] (half values after the rounding), or keeps the rounded float when the op result is exact
  void result(Instruction *I, SmallVector<Value *, 4> &t, SmallVector<Value *, 4> &fl) {
    IRBuilder<> Q(I); unsigned n = t.size();
    for (unsigned i = 0; i < n; ++i) memo[{I, i}] = fl[i];
    Value *R;
    if (n == 2) {
      Value *lo = Q.CreateZExt(Q.CreateBitCast(t[0], I16), I32), *hi = Q.CreateZExt(Q.CreateBitCast(t[1], I16), I32);
      Value *W = Q.CreateOr(lo, Q.CreateShl(hi, 16));
      R = Q.CreateBitCast(W, I->getType());
      for (User *U : make_early_inc_range(I->users())) if (auto *B = dyn_cast<BitCastInst>(U)) if (B->getType() == I32) { B->replaceAllUsesWith(W); B->eraseFromParent(); }
    } else if (n == 1) R = t[0];
    else { R = PoisonValue::get(I->getType()); for (unsigned i = 0; i < n; ++i) R = Q.CreateInsertElement(R, t[i], (uint64_t)i); }
    memoCopy(I, R, n);
    I->replaceAllUsesWith(R); I->eraseFromParent(); ops += n;
  }
  void memoCopy(Value *from, Value *to, unsigned n) { for (unsigned i = 0; i < n; ++i) memo[{to, i}] = memo[{from, i}]; }
  void run() {
    std::vector<Instruction *> w;
    { DominatorTree DT(F); for (auto *N : depth_first(DT.getRootNode())) for (Instruction &I : *N->getBlock()) w.push_back(&I); }   // defs before uses (phis aside)
    for (Instruction *I : w) {
      if (auto *B = dyn_cast<BinaryOperator>(I)) {
        unsigned op = B->getOpcode();
        if (!isH(I->getType()) || (op != Instruction::FMul && op != Instruction::FAdd && op != Instruction::FSub)) continue;
        unsigned n = nl(I->getType()); SmallVector<Value *, 4> t, fl; IRBuilder<> Q(I);
        for (unsigned i = 0; i < n; ++i) { Value *a = lane(I->getOperand(0), i), *b = lane(I->getOperand(1), i);
          Value *x = Q.CreateBinOp((Instruction::BinaryOps)op, a, b); Value *h = Q.CreateFPTrunc(x, H); t.push_back(h); fl.push_back(Q.CreateFPExt(h, F32)); }
        result(I, t, fl);
      } else if (auto *N = dyn_cast<UnaryOperator>(I)) {
        if (!isH(I->getType()) || N->getOpcode() != Instruction::FNeg) continue;
        unsigned n = nl(I->getType()); SmallVector<Value *, 4> t, fl; IRBuilder<> Q(I);
        for (unsigned i = 0; i < n; ++i) { Value *x = Q.CreateFNeg(lane(I->getOperand(0), i)); t.push_back(Q.CreateFPTrunc(x, H)); fl.push_back(x); }
        result(I, t, fl);
      } else if (auto *Cm = dyn_cast<FCmpInst>(I)) {
        if (!isH(Cm->getOperand(0)->getType())) continue;
        unsigned n = nl(Cm->getOperand(0)->getType()); IRBuilder<> Q(I); Value *R = n > 1 ? (Value *)PoisonValue::get(I->getType()) : nullptr;
        for (unsigned i = 0; i < n; ++i) { Value *c = Q.CreateFCmp(Cm->getPredicate(), lane(Cm->getOperand(0), i), lane(Cm->getOperand(1), i)); R = n > 1 ? Q.CreateInsertElement(R, c, (uint64_t)i) : c; }
        I->replaceAllUsesWith(R); I->eraseFromParent(); ops += n;
      } else if (auto *Ca = dyn_cast<CallInst>(I)) {
        Function *G = Ca->getCalledFunction(); if (!G || !isH(I->getType())) continue;
        StringRef nm = G->getName(); Intrinsic::ID id = Intrinsic::not_intrinsic;
        if (nm == "llvm.nvvm.fmax.f16x2" || nm == "llvm.nvvm.fmax.f16" || nm.starts_with("llvm.maxnum.")) id = Intrinsic::maxnum;
        else if (nm == "llvm.nvvm.fmin.f16x2" || nm == "llvm.nvvm.fmin.f16" || nm.starts_with("llvm.minnum.")) id = Intrinsic::minnum;
        if (id == Intrinsic::not_intrinsic) continue;
        unsigned n = nl(I->getType()); SmallVector<Value *, 4> t, fl; IRBuilder<> Q(I);
        for (unsigned i = 0; i < n; ++i) { Value *x = Q.CreateBinaryIntrinsic(id, lane(Ca->getArgOperand(0), i), lane(Ca->getArgOperand(1), i)); t.push_back(Q.CreateFPTrunc(x, H)); fl.push_back(x); }
        result(I, t, fl);
      } else if (auto *X = dyn_cast<FPExtInst>(I)) {
        if (!X->getSrcTy()->isHalfTy() || !X->getType()->isFloatTy() || !memo.count({X->getOperand(0), 0})) continue;
        X->replaceAllUsesWith(memo[{X->getOperand(0), 0}]); X->eraseFromParent();
      }
    }
    for (bool again = true; again;) { again = false;
      for (auto &BB : F) for (Instruction &I : make_early_inc_range(llvm::reverse(BB))) if (isInstructionTriviallyDead(&I)) { I.eraseFromParent(); again = true; } }
    if (ops) errs() << "lo-half: " << F.getName().substr(0, 40) << ": " << ops << " half lanes\n";
  }
};
struct LoHext : PassInfoMixin<LoHext> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    if (!envI("LO_HEXT", 2)) return PreservedAnalyses::all();
    unsigned n = 0; LLVMContext &C = M.getContext(); Type *F32 = Type::getFloatTy(C), *I16 = Type::getInt16Ty(C), *I32 = Type::getInt32Ty(C);
    for (Function &F : M) { if (F.isDeclaration() || F.getName().starts_with("lo.")) continue;
      for (BasicBlock &BB : F) for (Instruction &I : make_early_inc_range(BB)) if (auto *X = dyn_cast<FPExtInst>(&I)) if (X->getSrcTy()->isHalfTy() && X->getType()->isFloatTy()) {
        IRBuilder<> Q(X); const int mode = envI("LO_HEXT", 2);
        Value *z = Q.CreateZExt(Q.CreateBitCast(X->getOperand(0), I16), I32), *t = Q.CreateShl(z, 16), *r;
        auto K = [&](uint32_t v) { return ConstantInt::get(I32, v); };
        if (mode == 1) {   // needs f32 subnormal inputs in fmul: true on SimX and RTL simulation, not on the FPGA flows (VX_fpu_dsp FPU_SNORM=0, flush to zero)
          Value *b = Q.CreateLShr(Q.CreateAnd(t, 0x7fffffff), 3);
          Value *sp = Q.CreateICmpUGE(b, K(0x0f800000));
          b = Q.CreateOr(b, Q.CreateSelect(sp, K(0x7f800000), K(0)));
          Value *f = Q.CreateFMul(Q.CreateBitCast(b, F32), ConstantFP::get(F32, 0x1p112));
          r = Q.CreateBinaryIntrinsic(Intrinsic::copysign, f, Q.CreateBitCast(t, F32));
        } else {   // no subnormal on the FPU: exponent rebias in integers; 2: half subnormals by uitofp * 2^-24 (normal operands, normal result); 3: integers only
          Value *x = Q.CreateAnd(z, 0x7fff), *n = Q.CreateAdd(Q.CreateShl(x, 13), K(0x38000000));
          n = Q.CreateAdd(n, Q.CreateSelect(Q.CreateICmpUGE(x, K(0x7c00)), K(0x38000000), K(0)));
          Value *sb;
          if (mode == 2) sb = Q.CreateBitCast(Q.CreateFMul(Q.CreateUIToFP(x, F32), ConstantFP::get(F32, 0x1p-24)), I32);
          else {
            Value *m = x, *s = K(0);
            for (auto [lim, sh] : {std::pair<uint32_t, uint32_t>{0x4, 8}, {0x40, 4}, {0x100, 2}, {0x200, 1}}) { Value *c = Q.CreateICmpULT(m, K(lim)); m = Q.CreateSelect(c, Q.CreateShl(m, sh), m); s = Q.CreateSelect(c, Q.CreateAdd(s, K(sh)), s); }
            m = Q.CreateShl(m, 1); s = Q.CreateAdd(s, K(1));
            Value *e = Q.CreateShl(Q.CreateSub(K(113), s), 23);
            sb = Q.CreateSelect(Q.CreateICmpEQ(x, K(0)), K(0), Q.CreateOr(e, Q.CreateShl(Q.CreateAnd(m, 0x3ff), 13)));
          }
          Value *v = Q.CreateSelect(Q.CreateICmpULT(x, K(0x400)), sb, n);
          r = Q.CreateBitCast(Q.CreateOr(v, Q.CreateAnd(t, K(0x80000000u))), F32);
        }
        X->replaceAllUsesWith(r); X->eraseFromParent(); n++;
      } }
    if (n) errs() << "lo-hext: " << n << " fpext half inlined\n";
    return n ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
// lo-shfl: warp shuffles of loop invariant values (full mask, invariant index) leave the loop: the lift's ldmatrix lowering leaves them in the main loop and shuffles are convergent,
// so LICM does not touch them. Every lane that runs the loop body runs the preheader, the mask says all lanes do. LO_SHFL_FAKE=1 (measurement only, wrong results): the shuffle is removed.
struct LoShfl : PassInfoMixin<LoShfl> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    if (!envI("LO_SHFL", 0)) return PreservedAnalyses::all();   // measured: every kernel slower (conv +12.5%, FA2 +10.7%, tg sm80 +9%): reloads cost more than the shuffles
    unsigned n = 0, kept = 0;
    for (Function &F : M) { if (F.isDeclaration() || F.getName().starts_with("lo.")) continue;
      DominatorTree DT(F); LoopInfo LI(DT);
      for (Loop *L : LI.getLoopsInPreorder()) { BasicBlock *PH = L->getLoopPreheader(); if (!PH) continue;
        for (BasicBlock *B : L->blocks()) { if (LI.getLoopFor(B) != L) continue;
          for (Instruction &I : make_early_inc_range(*B)) { auto *C = dyn_cast<CallInst>(&I); if (!C || !C->getCalledFunction() || !C->getCalledFunction()->getName().starts_with("llvm.nvvm.shfl.sync.idx")) continue;
            auto *Mk = dyn_cast<ConstantInt>(C->getArgOperand(0)); if (!Mk || !Mk->isAllOnesValue()) continue;
            // the invariant slice of the index: pure code in the loop moves with the shuffle
            std::vector<Instruction *> mv; std::function<bool(Value *)> inv = [&](Value *V) -> bool { auto *J = dyn_cast<Instruction>(V); if (!J || !L->contains(J->getParent())) return true;
              if (J->mayHaveSideEffects() || J->mayReadFromMemory() || isa<PHINode>(J) || J->isTerminator()) return false; if (std::find(mv.begin(), mv.end(), J) != mv.end()) return true;
              for (Value *O : J->operands()) if (!inv(O)) return false; mv.push_back(J); return true; };
            bool ok = inv(C->getArgOperand(1)) && inv(C->getArgOperand(2)) && inv(C->getArgOperand(3));
            if (!ok) { kept++; continue; }
            for (Instruction *J : mv) J->moveBefore(PH->getTerminator());
            C->moveBefore(PH->getTerminator()); n++; } } } }
    if (n || kept) errs() << "lo-shfl: " << n << " shuffles left their loop, " << kept << " stayed\n";
    return n ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
// lo-diag: for the loop with the most WMMA of each function: what is live through it (diagnosis only, changes nothing)
struct LoDiag : PassInfoMixin<LoDiag> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    for (Function &F : M) { if (F.isDeclaration() || F.getName().starts_with("lo.")) continue;
      DominatorTree DT(F); LoopInfo LI(DT); Loop *best = nullptr; int bw = 0;
      for (Loop *L : LI.getLoopsInPreorder()) { int w = 0; for (BasicBlock *B : L->blocks()) for (Instruction &I : *B) if (auto *C = dyn_cast<CallInst>(&I)) if (C->getCalledFunction() && C->getCalledFunction()->getName().starts_with("lo.wmma")) w++; if (w > bw) { bw = w; best = L; } }
      if (!best) continue;
      int ph[3] = {0, 0, 0}; for (PHINode &P : best->getHeader()->phis()) ph[P.getType()->isIntegerTy() || P.getType()->isPointerTy() ? 0 : P.getType()->isFloatTy() ? 1 : 2]++;
      std::map<Value *, int> li; int ninst = 0; for (BasicBlock *B : best->blocks()) for (Instruction &I : *B) { ninst++; for (Value *V : I.operands()) if (auto *D = dyn_cast<Instruction>(V)) { if (!best->contains(D->getParent())) li[D]++; } else if (isa<Argument>(V)) li[V]++; }
      std::map<std::string, int> kind; int cheap = 0, uses = 0;
      for (auto &kv : li) { Value *V = kv.first; std::function<int(Value *, int)> sz = [&](Value *X, int d) -> int { auto *I = dyn_cast<Instruction>(X); if (!I) return 0; if (d > 6) return 100; if (isa<PHINode>(I) || isa<LoadInst>(I) || isa<AllocaInst>(I)) return 100; if (auto *C = dyn_cast<CallInst>(I)) { if (C->isInlineAsm() || (C->getCalledFunction() && C->getCalledFunction()->getName().contains("sreg"))) return 1; return 100; } int n = 1; for (Value *O : I->operands()) n += sz(O, d + 1); return n; };
        auto *I = dyn_cast<Instruction>(V); std::string k = I ? I->getOpcodeName() : "arg"; if (auto *C = I ? dyn_cast<CallInst>(I) : nullptr) k = C->isInlineAsm() ? "asm" : (C->getCalledFunction() ? C->getCalledFunction()->getName().substr(0, 18).str() : "call"); kind[k]++; int s = sz(V, 0); if (s <= 4) cheap++; uses += kv.second; }
      if (envI("LO_DIAG", 0)) for (auto &kv : li) { errs() << "  uses " << kv.second << ":"; kv.first->print(errs()); errs() << "\n"; }
      errs() << "lo-diag: " << F.getName().substr(0, 30) << ": loop " << ninst << " instrs, " << bw << " WMMA, phis int " << ph[0] << " float " << ph[1] << " other " << ph[2] << ", live-in " << li.size() << " (uses " << uses << ", slice <= 4 ops " << cheap << ") ";
      for (auto &kv : kind) errs() << kv.first << "=" << kv.second << " "; errs() << "\n";
    }
    return PreservedAnalyses::all();
  }
};
} // namespace
void p3PromoteHalf(Function &F) { if (envI("LO_HALF", 1)) Half(F).run(); }
void p3RegisterNext(PassBuilder &PB) {
  PB.registerPipelineParsingCallback([](StringRef N, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
    if (N == "lo-hext") { MPM.addPass(LoHext()); return true; }
    if (N == "lo-shfl") { MPM.addPass(LoShfl()); return true; }
    if (N == "lo-diag") { MPM.addPass(LoDiag()); return true; }
    return false; });
}
