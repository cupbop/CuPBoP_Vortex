// lotree.cpp: lo-tree, block-reduction tail rewrite for lifted kernels (unrolled LMEM tree).
// Finds a chain   barrier; if (tid<c1) {stage}; barrier; if (tid<c2) {stage}; ...  with c1>=c2>=...  and
//  (1) narrows each barrier to the warps that can touch LMEM around it (llvm.nvvm.barrier.sync.cnt) and lets the other warps jump to the chain end,
//  (2) promotes the tail stages (c<=32, neighbour reads inside warp 0) from LMEM cells to registers + shfl.down, without any barrier.
// No kernel constants: the stage constants come from the guards, element size from the address.
// LO_TREE_NOSKIP=1: no skip/narrowing (schedules that cannot express counted barriers). LO_TREE_NOSHFL=1: no promotion.
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "lover.h"
#include <map>
#include <set>
#include <string>
#include <vector>
using namespace llvm;
namespace {
static bool isCallTo(const Instruction *I, StringRef N) { if (auto *C = dyn_cast<CallInst>(I)) if (auto *F = C->getCalledFunction()) return F->getName() == N; return false; }
static bool isBar(const Instruction *I) { return isCallTo(I, "llvm.nvvm.barrier0"); }
static bool isWarpNoop(const Instruction *I) { return isCallTo(I, "llvm.nvvm.activemask") || isCallTo(I, "llvm.nvvm.bar.warp.sync"); }
static bool pureI(const Instruction *I) { return !I->mayHaveSideEffects() && !I->mayReadFromMemory() && !I->isTerminator() && !isa<PHINode>(I) && !isa<AllocaInst>(I); }
struct Lin { int64_t a = 0, k = 0; std::map<Value *, int64_t> t; bool ok = true;
  bool sameBase(const Lin &o) const { return a == o.a && t == o.t; } };
struct Stage { BasicBlock *G = nullptr, *T = nullptr, *M = nullptr; int c = 0; std::vector<BasicBlock *> R; CallInst *BarBefore = nullptr, *BarAfter = nullptr; };
struct Arr { Value *Own = nullptr; Lin L; Type *Ty = nullptr; PHINode *dummy = nullptr; Value *Cur = nullptr; };
struct Tree {
  Function &F; DominatorTree &DT; Value *Tid = nullptr; bool V;
  Tree(Function &F, DominatorTree &DT) : F(F), DT(DT) { V = getenv("LO_TREE_V"); }
  bool isTid(Value *X) { if (X == Tid) return true; if (auto *C = dyn_cast<CallInst>(X)) if (auto *Fn = C->getCalledFunction()) return Fn->getName() == "llvm.nvvm.read.ptx.sreg.tid.x"; return false; }
  Lin lin(Value *X, int d = 0) {
    Lin R; if (d > 24) { R.ok = false; return R; }
    if (auto *C = dyn_cast<ConstantInt>(X)) { R.k = C->getSExtValue(); return R; }
    if (isTid(X)) { R.a = 1; return R; }
    if (auto *I = dyn_cast<Instruction>(X)) switch (I->getOpcode()) {
    case Instruction::ZExt: case Instruction::SExt: case Instruction::Trunc: return lin(I->getOperand(0), d + 1);
    case Instruction::Add: case Instruction::Sub: { Lin A = lin(I->getOperand(0), d + 1), B = lin(I->getOperand(1), d + 1); int s = I->getOpcode() == Instruction::Add ? 1 : -1;
      A.ok &= B.ok; A.a += s * B.a; A.k += s * B.k; for (auto &kv : B.t) A.t[kv.first] += s * kv.second; return A; }
    case Instruction::Shl: if (auto *C = dyn_cast<ConstantInt>(I->getOperand(1))) { Lin A = lin(I->getOperand(0), d + 1); int64_t m = 1ll << C->getZExtValue(); A.a *= m; A.k *= m; for (auto &kv : A.t) kv.second *= m; return A; } break;
    case Instruction::Mul: if (auto *C = dyn_cast<ConstantInt>(I->getOperand(1))) { Lin A = lin(I->getOperand(0), d + 1); int64_t m = C->getSExtValue(); A.a *= m; A.k *= m; for (auto &kv : A.t) kv.second *= m; return A; } break;
    case Instruction::And: if (auto *C = dyn_cast<ConstantInt>(I->getOperand(1))) if ((C->getZExtValue() & 0xffffffffu) == 0xffffffffu) return lin(I->getOperand(0), d + 1); break;
    default: break; }
    R.t[X] = 1; return R;
  }
  Lin ptrLin(Value *P) {   // gep shared_mem, 0, idx -> linear idx
    Lin R; auto *G = dyn_cast<GetElementPtrInst>(P); if (!G || G->getNumIndices() != 2 || !isa<GlobalVariable>(G->getPointerOperand())) { R.ok = false; return R; }
    return lin(G->getOperand(2));
  }
  // guard: returns active successor and threshold; cond may be wrapped
  bool guard(BranchInst *Br, BasicBlock *&A, BasicBlock *&O, int &c) {
    Value *V = Br->getCondition(); bool neg = false;
    for (int i = 0; i < 6; ++i) {
      if (auto *Z = dyn_cast<ZExtInst>(V)) { V = Z->getOperand(0); continue; }
      if (auto *B = dyn_cast<BinaryOperator>(V)) if (B->getOpcode() == Instruction::Xor) if (auto *C = dyn_cast<ConstantInt>(B->getOperand(1))) if (C->isOne()) { neg = !neg; V = B->getOperand(0); continue; }
      if (auto *I = dyn_cast<ICmpInst>(V)) if (auto *C = dyn_cast<ConstantInt>(I->getOperand(1))) if (C->isZero() && isa<ZExtInst>(I->getOperand(0)) && (I->getPredicate() == ICmpInst::ICMP_NE || I->getPredicate() == ICmpInst::ICMP_EQ)) { if (I->getPredicate() == ICmpInst::ICMP_EQ) neg = !neg; V = I->getOperand(0); continue; }
      break;
    }
    auto *I = dyn_cast<ICmpInst>(V); if (!I) return false;
    auto P = I->getPredicate(); Value *X = I->getOperand(0); auto *C = dyn_cast<ConstantInt>(I->getOperand(1));
    if (!C) { C = dyn_cast<ConstantInt>(X); X = I->getOperand(1); P = ICmpInst::getSwappedPredicate(P); }
    if (!C || !isTid(X)) return false;
    int64_t k = C->getSExtValue(); bool actT;   // true successor (of the unwrapped icmp) active?
    switch (P) {
    case ICmpInst::ICMP_SLT: case ICmpInst::ICMP_ULT: c = k; actT = true; break;
    case ICmpInst::ICMP_SLE: case ICmpInst::ICMP_ULE: c = k + 1; actT = true; break;
    case ICmpInst::ICMP_SGT: case ICmpInst::ICMP_UGT: c = k + 1; actT = false; break;
    case ICmpInst::ICMP_SGE: case ICmpInst::ICMP_UGE: c = k; actT = false; break;
    case ICmpInst::ICMP_EQ: if (k != 0) return false; c = 1; actT = true; break;
    case ICmpInst::ICMP_NE: if (k != 0) return false; c = 1; actT = false; break;
    default: return false; }
    if (neg) actT = !actT;
    A = Br->getSuccessor(actT ? 0 : 1); O = Br->getSuccessor(actT ? 1 : 0); return c > 0;
  }
  // from a block position walk to the next guard. returns false when anything but pure/noop is in the way
  bool walkPure(BasicBlock::iterator It, BasicBlock *B, BasicBlock *&G) {
    for (;;) {
      for (auto E = B->end(); It != E; ++It) { Instruction *I = &*It;
        if (I->isTerminator()) break;
        if (isa<PHINode>(I) || pureI(I) || isWarpNoop(I)) continue;
        return false; }
      auto *Br = dyn_cast<BranchInst>(B->getTerminator()); if (!Br) return false;
      if (Br->isConditional()) { G = B; return true; }
      BasicBlock *N = Br->getSuccessor(0); if (!N->getSinglePredecessor()) return false;
      B = N; It = B->begin();
    }
  }
  bool parseStage(CallInst *Bar, Stage &S) {
    S.BarBefore = Bar; BasicBlock *G;
    if (!walkPure(std::next(Bar->getIterator()), Bar->getParent(), G)) return false;
    auto *Br = cast<BranchInst>(G->getTerminator()); BasicBlock *A, *O; int c;
    if (!guard(Br, A, O, c)) return false;
    S.G = G; S.T = A; S.M = O; S.c = c;
    std::set<BasicBlock *> Seen; std::vector<BasicBlock *> W{A}; Seen.insert(A);
    while (!W.empty()) { BasicBlock *B = W.back(); W.pop_back();
      if (B->getTerminator()->getNumSuccessors() == 0) return false;
      S.R.push_back(B);
      for (auto &I : *B) if (isBar(&I)) return false;
      for (BasicBlock *X : successors(B)) if (X != O && Seen.insert(X).second) W.push_back(X); }
    for (BasicBlock *B : S.R) for (BasicBlock *P : predecessors(B)) if (!Seen.count(P) && P != G) return false;
    return true;
  }
  void mergeScan(Stage &S) {   // barrier in the merge block, only pure things around it
    S.BarAfter = nullptr; for (auto &I : *S.M) { if (isBar(&I)) { S.BarAfter = cast<CallInst>(&I); break; } if (!(isa<PHINode>(&I) || pureI(&I) || isWarpNoop(&I))) break; }
  }
  Value *shfl(IRBuilder<> &B, Value *V, int d) {
    Module *Mod = F.getParent(); Type *Ty = V->getType(); LLVMContext &C = F.getContext(); auto *I32 = Type::getInt32Ty(C);
    auto call = [&](Value *X) { bool fl = X->getType()->isFloatTy();
      auto Fn = Mod->getOrInsertFunction(fl ? "llvm.nvvm.shfl.sync.down.f32" : "llvm.nvvm.shfl.sync.down.i32", FunctionType::get(X->getType(), {I32, X->getType(), I32, I32}, false));
      return B.CreateCall(Fn, {ConstantInt::getSigned(I32, -1), X, ConstantInt::get(I32, d), ConstantInt::get(I32, 31)}); };
    if (Ty->isFloatTy() || Ty->isIntegerTy(32)) return call(V);
    if (Ty->isDoubleTy() || Ty->isIntegerTy(64)) { auto *I64 = Type::getInt64Ty(C); Value *X = B.CreateBitCast(V, I64);
      Value *lo = call(B.CreateTrunc(X, I32)), *hi = call(B.CreateTrunc(B.CreateLShr(X, 32), I32));
      Value *R = B.CreateOr(B.CreateZExt(lo, I64), B.CreateShl(B.CreateZExt(hi, I64), 32)); return B.CreateBitCast(R, Ty); }
    return nullptr;
  }
  // value of phi-defined V for a thread that fails every guard from stage index s on
  Value *allFalse(Value *V, std::vector<Stage> &Ch, size_t s) {
    for (int it = 0; it < 64; ++it) { auto *P = dyn_cast<PHINode>(V); if (!P) return V; bool f = false;
      for (size_t i = s; i < Ch.size(); ++i) if (P->getParent() == Ch[i].M) { V = P->getIncomingValueForBlock(Ch[i].G); f = true; break; }
      if (!f) return V; }
    return nullptr;
  }
  bool dry = false;
  bool any() { dry = true; bool r = run(); dry = false; return r; }
  bool run() {
    std::vector<CallInst *> Bars; for (auto &B : F) for (auto &I : B) if (isBar(&I)) Bars.push_back(cast<CallInst>(&I));
    for (auto &B : F) for (auto &I : B) if (auto *C = dyn_cast<CallInst>(&I)) if (auto *Fn = C->getCalledFunction()) { if (Fn->getName() == "llvm.nvvm.read.ptx.sreg.tid.y" || Fn->getName() == "llvm.nvvm.read.ptx.sreg.tid.z") return false; if (Fn->getName() == "llvm.nvvm.read.ptx.sreg.tid.x" && !Tid) Tid = C; }
    if (!Tid) return false;
    std::set<CallInst *> Used; bool any = false;
    for (CallInst *B0 : Bars) { if (Used.count(B0)) continue;
      std::vector<Stage> Ch; CallInst *Cur = B0; int last = 1 << 30;
      std::set<CallInst *> InCh; while (Cur && InCh.insert(Cur).second) { Stage S; if (!parseStage(Cur, S) || S.c > last) break; mergeScan(S); Ch.push_back(S); last = S.c; Used.insert(Cur); Cur = S.BarAfter; }
      if (Cur && InCh.count(Cur) && Cur == B0) continue;   // loop-form tree: not this pass
      if (Ch.size() < 2) continue;
      if (V) { errs() << "lo-tree " << F.getName().substr(0, 30) << ": chain"; for (auto &S : Ch) errs() << " " << S.c; errs() << "\n"; }
      if (dry) return true;
      if (apply(Ch)) any = true; DT.recalculate(F);
    }
    return any;
  }
  bool apply(std::vector<Stage> &Ch) {
    size_t n = Ch.size(); bool noskip = getenv("LO_TREE_NOSKIP"), noshfl = getenv("LO_TREE_NOSHFL");
    // ---- promotable tail: stages k..n-1
    size_t k = n; std::vector<Arr> As;
    if (!noshfl) for (size_t i = n; i-- > 0;) {
      Stage &S = Ch[i]; if (S.c > 32) break;
      std::vector<Arr> A2 = As; bool ok = true;
      std::vector<std::pair<LoadInst *, Lin>> Lds;
      for (BasicBlock *B : S.R) for (auto &I : *B) {
        if (isWarpNoop(&I)) continue;
        if (auto *St = dyn_cast<StoreInst>(&I)) { if (St->getPointerAddressSpace() != 3) { ok = false; break; }
          Lin L = ptrLin(St->getPointerOperand()); if (!L.ok || L.a <= 0) { ok = false; break; }
          if (!DT.dominates(St->getParent(), S.R.back()) && S.R.size() > 1) { /* checked below */ }
          bool f = false; for (auto &A : A2) if (A.L.sameBase(L) && A.L.k == L.k) f = true;
          if (!f) { Arr A; A.Own = St->getPointerOperand(); A.L = L; A.Ty = St->getValueOperand()->getType(); A2.push_back(A); }
        } else if (auto *Ld = dyn_cast<LoadInst>(&I)) { if (Ld->getPointerAddressSpace() != 3) { continue; } Lin L = ptrLin(Ld->getPointerOperand()); if (!L.ok || L.a <= 0) { ok = false; break; } Lds.push_back({Ld, L}); }
        else if (I.mayHaveSideEffects() && !isa<IntrinsicInst>(&I) && !isa<CallInst>(&I)) { ok = false; break; }
      }
      if (ok) for (auto &pr : Lds) { bool f = false; for (auto &A : A2) { if (!A.L.sameBase(pr.second)) continue; int64_t dk = pr.second.k - A.L.k, w = A.L.a; if (dk % w) continue; int64_t d = dk / w; if (d < 0 || d + S.c > 32) continue; f = true; } if (!f) ok = false; }
      if (!ok) break;
      As = A2; k = i;
    }
    for (auto &A : As) { auto *I = dyn_cast<Instruction>(A.Own); if (I && !DT.dominates(I, Ch[k].BarBefore)) { if (V) errs() << "  own pointer not available\n"; k = n; As.clear(); break; } }
    if (k < n && Ch[k].c + 0 > 32) { k = n; As.clear(); }
    // p4: nothing to promote, nothing to do: narrowing and skipping alone only pay behind a promoted tail (softmax 128 64 32, the tail in another form: +6.3%; snrm2 with a tail: -5.3%)
    if (k == n || As.empty()) return false;   // a stage without a shared store (a tid < 1 guard around TMA code, chain 1 1 1 1) has no cell to promote: LastSt below stayed null
    // later reads of the cells: only cell 0 -> guards of promoted stages can go, write back from lane 0
    Value *TidV = Tid; LLVMContext &C = F.getContext(); auto *I32 = Type::getInt32Ty(C); Module *Mod = F.getParent();
    if (V) errs() << "  promote from stage " << k << " of " << n << "\n";
    // ---- hoist pure code of the chain spine in front of the first barrier involved
    // (idle threads skip these blocks; values used after the chain must stay defined)
    CallInst *First = Ch[0].BarBefore;
    { std::vector<BasicBlock *> Sp; for (auto &S : Ch) { std::set<BasicBlock *> X; BasicBlock *B = S.BarBefore->getParent(); for (;;) { if (!X.insert(B).second) break; Sp.push_back(B); if (B == S.G) break; B = B->getSingleSuccessor(); if (!B) break; } Sp.push_back(S.M); }
      for (BasicBlock *B : Sp) for (auto It = B->begin(); It != B->end();) { Instruction *I = &*It++; if (!pureI(I) || DT.dominates(I, First)) continue; bool ok = true; for (Value *O : I->operands()) if (auto *OI = dyn_cast<Instruction>(O)) if (!DT.dominates(OI, First)) ok = false; if (ok) I->moveBefore(First->getIterator()); } }
    // ---- promotion
    BasicBlock *SkipTo = Ch[n - 1].M;
    if (k < n) {
      // entry: load the cells right before guard of stage k; barrier before it goes (same-lane read of warp 0, all later traffic is in registers)
      Stage &S0 = Ch[k]; IRBuilder<> B(S0.G->getTerminator());
      for (auto &A : As) { auto *L = B.CreateLoad(A.Ty, A.Own, true, "tree.v"); A.Cur = L; }
      for (size_t i = k; i < n; ++i) { Stage &S = Ch[i]; IRBuilder<> Bg(S.G->getTerminator());
        std::map<StoreInst *, int> Sts; std::vector<std::pair<LoadInst *, Value *>> Rep;
        for (BasicBlock *Bk : S.R) for (auto &I : *Bk) {
          if (auto *Ld = dyn_cast<LoadInst>(&I)) { if (Ld->getPointerAddressSpace() != 3) continue; Lin L = ptrLin(Ld->getPointerOperand());
            for (auto &A : As) { if (!A.L.sameBase(L)) continue; int64_t dk = L.k - A.L.k, w = A.L.a; if (dk % w) continue; int64_t d = dk / w; if (d < 0 || d + S.c > 32) continue;
              Value *X = A.Cur; if (d) X = shfl(Bg, A.Cur, (int)d); if (X->getType() != Ld->getType()) { IRBuilder<> Bl(Ld); X = Bl.CreateBitCast(X, Ld->getType()); } Rep.push_back({Ld, X}); break; } }
        }
        for (auto &pr : Rep) { pr.first->replaceAllUsesWith(pr.second); pr.first->eraseFromParent(); }
        std::vector<StoreInst *> Del;
        std::vector<PHINode *> New(As.size(), nullptr);
        for (size_t a = 0; a < As.size(); ++a) { Arr &A = As[a]; Value *Nv = nullptr; BasicBlock *Pred = nullptr;
          for (BasicBlock *Bk : S.R) for (auto &I : *Bk) if (auto *St = dyn_cast<StoreInst>(&I)) if (St->getPointerAddressSpace() == 3) { Lin L = ptrLin(St->getPointerOperand()); if (L.sameBase(A.L) && L.k == A.L.k) { Nv = St->getValueOperand(); Del.push_back(St); } }
          if (Nv) { if (Nv->getType() != A.Ty) { auto *St = Del.back(); IRBuilder<> Bs(St); Nv = Bs.CreateBitCast(Nv, A.Ty); }
            for (BasicBlock *P : predecessors(S.M)) if (P != S.G) Pred = P;
            PHINode *P = PHINode::Create(A.Ty, 2, "tree.p", S.M->getFirstNonPHIIt()); P->addIncoming(Nv, Pred); P->addIncoming(A.Cur, S.G); A.Cur = P; } }
        for (auto *St : Del) St->eraseFromParent();
        for (auto It = S.M->begin(); It != S.M->end();) { Instruction *I = &*It++; if (isWarpNoop(I) && I->use_empty()) I->eraseFromParent(); }
        for (auto It = S.M->begin(); It != S.M->end();) { Instruction *I = &*It++; if (isWarpNoop(I) && I->use_empty()) I->eraseFromParent(); }
        if (i + 1 < n || true) if (S.BarAfter && i + 1 < n) { S.BarAfter->eraseFromParent(); S.BarAfter = nullptr; }
      }
      if (Ch[k].BarBefore != First || true) { /* barrier in front of the tail */ }
      // write back all cells from warp 0 at the chain end
      Stage &SL = Ch[n - 1]; IRBuilder<> Be(&*SL.M->getFirstNonPHIIt());
      StoreInst *LastSt = nullptr; for (auto &A : As) LastSt = Be.CreateStore(A.Cur, A.Own, true);
      // idle warps must not write back: they rejoin behind the stores
      BasicBlock *Mn = SL.M; BasicBlock *Cont = SplitBlock(Mn, LastSt->getNextNode(), &DT);
      std::vector<PHINode *> Ps; for (auto &P : Mn->phis()) if (!P.getName().starts_with("tree.")) Ps.push_back(&P);
      for (PHINode *P : Ps) { bool out = false; for (User *U : P->users()) if (cast<Instruction>(U)->getParent() != Mn) out = true; if (!out) continue;
        PHINode *Q = PHINode::Create(P->getType(), 2, P->getName() + ".c", Cont->begin()); Q->addIncoming(P, Mn);
        P->replaceUsesWithIf(Q, [&](Use &U) { auto *I = cast<Instruction>(U.getUser()); return I != Q && I->getParent() != Mn; }); }
      SkipTo = Cont;
    }
    // ---- barriers and idle-warp skip
    if (!noskip) {
      auto *NT = Mod->getOrInsertFunction("llvm.nvvm.read.ptx.sreg.ntid.x", FunctionType::get(I32, {}, false)).getCallee();
      // walk stages front to back; a stage i>k has no barrier left in front of it
      for (size_t i = 0; i < n; ++i) { Stage &S = Ch[i]; if (i > k) break; int live = (S.c + 31) & ~31; int prevLive = i ? ((Ch[i - 1].c + 31) & ~31) : (1 << 30);
        if (i == k && i > 0 && prevLive <= 32) { S.BarBefore->eraseFromParent(); S.BarBefore = nullptr; continue; }   // same-lane reads only, nothing to order
        IRBuilder<> Bb(S.BarBefore);
        if (i > 0) {   // narrow: only the warps of stage i-1 can arrive here
          auto *CB = Mod->getOrInsertFunction("llvm.nvvm.barrier.sync.cnt", FunctionType::get(Type::getVoidTy(C), {I32, I32}, false)).getCallee();
          Value *N = Bb.CreateCall(FunctionType::get(I32, {}, false), NT);
          Value *Nr = Bb.CreateAnd(Bb.CreateAdd(N, ConstantInt::get(I32, 31)), ConstantInt::get(I32, ~31u));
          Value *L = ConstantInt::get(I32, prevLive); Value *Cn = Bb.CreateSelect(Bb.CreateICmpULT(Nr, L), Nr, L);
          auto *NB = Bb.CreateCall(FunctionType::get(Type::getVoidTy(C), {I32, I32}, false), CB, {ConstantInt::get(I32, 1), Cn});
          S.BarBefore->eraseFromParent(); S.BarBefore = NB;
        }
        if (live < prevLive) {
          Instruction *After = S.BarBefore->getNextNode(); BasicBlock *Hd = S.BarBefore->getParent();
          BasicBlock *Rest = SplitBlock(Hd, After, &DT); Hd->getTerminator()->eraseFromParent();
          IRBuilder<> Bs(Hd); Value *Idle = Bs.CreateICmpUGE(TidV, ConstantInt::get(TidV->getType(), live));
          BasicBlock *X = SkipTo;
          for (auto &P : X->phis()) { if (P.getBasicBlockIndex(Hd) >= 0) continue; Value *St = X == Ch[n - 1].M ? (Value *)&P : P.getIncomingValueForBlock(Ch[n - 1].M); Value *Vf = allFalse(St, Ch, i); if (!Vf) return false; P.addIncoming(Vf, Hd); }
          Bs.CreateCondBr(Idle, X, Rest);
          if (S.G == Hd) S.G = Rest;
          DT.recalculate(F);
        }
      }
    }
    return true;
  }
};
// p4: the promotion needs warp 0 full and lane == tid.x: ntid.x >= 32, tid.y and tid.z unused and ntid.y = ntid.z = 1. The block shape is a launch fact the IR does not hold (maxntid is an upper bound):
// the rewritten body runs behind that test, the original body otherwise. maxntidx < 32 proves the test false: nothing to do.
static unsigned annot(Function &F, StringRef key) {
  NamedMDNode *NM = F.getParent()->getNamedMetadata("nvvm.annotations"); if (!NM) return 0;
  for (MDNode *Md : NM->operands()) if (Md->getNumOperands() >= 3) {
    auto *K = dyn_cast_or_null<MDString>(Md->getOperand(1)); auto *V = dyn_cast_or_null<ConstantAsMetadata>(Md->getOperand(2)); auto *G = dyn_cast_or_null<ConstantAsMetadata>(Md->getOperand(0));
    if (K && V && G && K->getString() == key && G->getValue()->stripPointerCasts() == &F) if (auto *CI = dyn_cast<ConstantInt>(V->getValue())) return CI->getZExtValue(); }
  return 0;
}
struct LoTree : PassInfoMixin<LoTree> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM) {
    if (F.isDeclaration()) return PreservedAnalyses::all();
    unsigned mx = annot(F, "maxntidx"); if (mx && mx < 32) return PreservedAnalyses::all();
    { DominatorTree D(F); Tree T(F, D); if (!T.any()) return PreservedAnalyses::all(); }
    Version Vr(F);
    { DominatorTree D(F); Tree T(F, D); if (!T.run()) { Vr.drop(); return PreservedAnalyses::all(); } }
    Module *M = F.getParent(); LLVMContext &C = F.getContext(); auto *I32 = Type::getInt32Ty(C);
    auto sreg = [&](IRBuilder<> &B, const char *n) { return B.CreateCall(M->getOrInsertFunction(n, FunctionType::get(I32, {}, false))); };
    if (!getenv("LO_TREE_NOVERSION")) Vr.commit([&](IRBuilder<> &B) -> Value * {
      Value *c = B.CreateICmpUGE(sreg(B, "llvm.nvvm.read.ptx.sreg.ntid.x"), ConstantInt::get(I32, 32));
      if (annot(F, "maxntidy") != 1) c = B.CreateAnd(c, B.CreateICmpEQ(sreg(B, "llvm.nvvm.read.ptx.sreg.ntid.y"), ConstantInt::get(I32, 1)));
      if (annot(F, "maxntidz") != 1) c = B.CreateAnd(c, B.CreateICmpEQ(sreg(B, "llvm.nvvm.read.ptx.sreg.ntid.z"), ConstantInt::get(I32, 1)));
      return c; });
    else Vr.drop();
    if (verifyFunction(F, &errs())) errs() << "lo-tree: broken function " << F.getName() << "\n";
    return PreservedAnalyses::none();
  }
};
}
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "lotree", "0.1", [](PassBuilder &PB) {
    PB.registerPipelineParsingCallback([](StringRef N, FunctionPassManager &FPM, ArrayRef<PassBuilder::PipelineElement>) {
      if (N == "lo-tree") { FPM.addPass(LoTree()); return true; }
      return false; });
  }};
}
