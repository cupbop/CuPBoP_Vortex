// lodq.cpp (2026-11-04, experiments/p4): IDEAS 54. p2c-fold at S' = 1 delays every copy by d iterations through a per-thread queue on the stack: (source, size, guard) packed in an i64 per
// site, one load and one store per site and trip. A site whose source in the main loop is an add recurrence (SCEV: start A, loop invariant step s) needs no queue for trips t >= d:
//  - trip t >= d pops the entry of trip t - d, whose source is A + (t - d) s: a pointer D of its own, D += s behind the copy.
//  - guard and "not zero fill" of each trip go through one i64 shift register (a row per entry, one shift per trip): the same delay, in a register.
// What happens for t < d depends on how much the prologue is known:
//  - NOQ, the queue goes away. Every site's prologue entries continue the recurrence (SCEV): straight line: entry t+1 - entry t == s and A - last entry == s; prologue loop: the round is an add recurrence
//    of the same s. D starts at entry 0. A prologue loop has a run-time number of rounds, possibly fewer than d: entries t < rounds - Tn are D0 + t s, the rest are empty (bits 0, source unused), entry d
//    is A: at t = d - 1 the step is x = A - D0 - (d - 1) s (= s when the ring is full). Exact for any number of rounds. Sites with the same step and the same A - B (B: round 0) share G = A - D0.
//  - STEADY, the proof covers the main loop only (residue tiles, 32-bit halves the prologue keeps). Entries t < d stay in the stack queue, written by the prologue as before and only read: two copy
//    paths chosen by t < d, a uniform branch.
// SCEV runs on a clone of the function in which reads of read-only allocas (the parameter block) and of special registers are one value per location and identical pure instructions are merged: the
// real function keeps its loads where they are (hoisting them spills, seed g32 t4). Steps are expanded back in the preheader, A is rebuilt there from the phis' preheader values.
#include "lodq.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include <cstdlib>
#include <map>
#include <set>
#include <string>
#include <tuple>
using namespace llvm;
namespace {
int envI(const char *n, int d) { const char *e = getenv(n); return e && *e ? atoi(e) : d; }
struct SiteInfo {
  LoDqSite s; bool affine = false, hasG = false;
  int word = -1, off = 0;                  // bits in the shift register: off = nz, off + 1 = g
  Value *step = nullptr, *A = nullptr;     // in the preheader
  Value *D0 = nullptr;                     // NOQ, prologue loop: entry 0 when the loop runs far enough, built in the prologue's preheader
  int cls = -1;                            // NOQ, prologue loop: sites sharing G
  AllocaInst *D = nullptr; Value *cur = nullptr;
};
struct Word { AllocaInst *a = nullptr, *row = nullptr; int w = 0, d = 0, Tn = 1; Value *cur = nullptr; };
struct AClass { int rep = -1; Value *step = nullptr, *x = nullptr, *now = nullptr, *G = nullptr; };
struct CanonKey { Value *base; int64_t off; Type *ty; bool operator<(const CanonKey &o) const { return std::tie(base, off, ty) < std::tie(o.base, o.off, o.ty); } };
}
struct LoDq::Impl {
  std::vector<SiteInfo> S; std::vector<Word> W; std::vector<AClass> AC; bool needG = false, noq = false; AllocaInst *T = nullptr; Value *t = nullptr;
  Value *bits(IRBuilder<> &B, SiteInfo &s, Value *sz, Value *g) {
    Type *I64 = B.getInt64Ty();
    Value *n = sz ? B.CreateZExt(B.CreateICmpNE(sz, ConstantInt::get(sz->getType(), 0)), I64) : (Value *)B.getInt64(1);
    return s.hasG ? B.CreateOr(n, B.CreateShl(g ? B.CreateZExt(g, I64) : (Value *)B.getInt64(1), 1)) : n;
  }
  void orIn(IRBuilder<> &B, Word &w, Value *v, uint64_t sh) { B.CreateStore(B.CreateOr(B.CreateLoad(B.getInt64Ty(), w.a), B.CreateShl(v, B.getInt64(sh))), w.a); }
  std::vector<AllocaInst *> allocas;
  AllocaInst *mk(IRBuilder<> &EB, Type *Ty, const char *n) { AllocaInst *a = EB.CreateAlloca(Ty, nullptr, n); EB.CreateStore(Constant::getNullValue(Ty), a); allocas.push_back(a); return a; }
};
LoDq::LoDq() : I(new Impl) {}
LoDq::~LoDq() {}

// ---- analysis on a clone ---------------------------------------------------------------------------------------------------------------------------
namespace {
struct Clone {
  Function *G = nullptr; ValueToValueMapTy VM; DenseMap<Value *, Value *> back;   // clone value -> real value
  std::map<CanonKey, Value *> canon; DenseMap<Value *, CanonKey> canonOf; DenseMap<Value *, CallInst *> sregOf;   // canonical value -> how to read it again in the real function
  DenseMap<Value *, Value *> realBase;
};
bool isSreg(CallInst *C) { Function *f = C->getCalledFunction(); return f && f->getName().starts_with("llvm.nvvm.read.ptx.sreg."); }
// loads of an alloca written only in the entry block, without its address escaping: one value per (offset, type). The real alloca is found through the map.
void canonLoads(Clone &X) {
  Function &G = *X.G; BasicBlock &E = G.getEntryBlock(); const DataLayout &DL = G.getDataLayout();
  std::vector<AllocaInst *> As; for (Instruction &I : E) if (auto *A = dyn_cast<AllocaInst>(&I)) As.push_back(A);
  for (AllocaInst *A : As) {
    std::vector<Value *> w{A}; SmallPtrSet<Value *, 32> seen{A}; std::vector<LoadInst *> L; Instruction *last = nullptr; bool ok = true;
    while (!w.empty() && ok) { Value *V = w.back(); w.pop_back();
      for (User *U : V->users()) { auto *I = cast<Instruction>(U);
        if (isa<GetElementPtrInst>(I) || isa<BitCastInst>(I)) { if (seen.insert(I).second) w.push_back(I); }
        else if (auto *Ld = dyn_cast<LoadInst>(I)) { if (Ld->isSimple()) L.push_back(Ld); else ok = false; }
        else if (auto *St = dyn_cast<StoreInst>(I)) { if (St->getPointerOperand() != V || St->getParent() != &E) ok = false; else if (!last || last->comesBefore(St)) last = St; }
        else if (auto *II = dyn_cast<IntrinsicInst>(I)) { if (!II->isLifetimeStartOrEnd()) ok = false; }
        else ok = false; } }
    if (!ok || !last) continue;
    for (LoadInst *Ld : L) {
      if (Ld->getParent() == &E && Ld->comesBefore(last)) continue;
      int64_t off = 0; Value *b = GetPointerBaseWithConstantOffset(Ld->getPointerOperand(), off, DL);
      if (b != A) continue;
      CanonKey k{A, off, Ld->getType()};
      auto it = X.canon.find(k);
      if (it == X.canon.end()) {
        IRBuilder<> B(last->getNextNode());
        Value *p = B.CreateConstGEP1_64(B.getInt8Ty(), A, off);
        LoadInst *N = B.CreateLoad(Ld->getType(), p);
        it = X.canon.insert({k, N}).first; X.canonOf.insert({N, k});
      }
      Ld->replaceAllUsesWith(it->second); Ld->eraseFromParent();
    }
  }
}
void canonSregs(Clone &X) {
  Function &G = *X.G; std::map<Function *, Instruction *> first; std::vector<CallInst *> L;
  for (BasicBlock &B : G) for (Instruction &I : B) if (auto *C = dyn_cast<CallInst>(&I)) if (isSreg(C)) L.push_back(C);
  Instruction *At = &*G.getEntryBlock().getFirstInsertionPt();
  std::map<Function *, CallInst *> N;
  for (CallInst *C : L) { Function *f = C->getCalledFunction(); auto it = N.find(f);
    if (it == N.end()) { auto *K = cast<CallInst>(C->clone()); K->insertBefore(At->getIterator()); it = N.insert({f, K}).first; X.sregOf.insert({K, K}); }
    C->replaceAllUsesWith(it->second); C->eraseFromParent(); }
}
// identical pure instructions, the later one replaced when the earlier dominates it. Full-mask shuffles count: same operands, same lanes.
void mergePure(Clone &X, DominatorTree &DT) {
  typedef std::tuple<unsigned, Type *, std::vector<Value *>, unsigned> K;
  std::map<K, std::vector<Instruction *>> seen;
  ReversePostOrderTraversal<Function *> RPO(X.G);
  for (BasicBlock *B : RPO) for (Instruction &I : make_early_inc_range(*B)) {
    bool pure = isa<BinaryOperator>(I) || isa<CastInst>(I) || isa<CmpInst>(I) || isa<SelectInst>(I) || isa<GetElementPtrInst>(I);
    if (auto *C = dyn_cast<CallInst>(&I)) { Function *f = C->getCalledFunction(); pure = f && (f->getName().starts_with("llvm.nvvm.shfl.sync.") || f->getName().starts_with("llvm.smin") || f->getName().starts_with("llvm.smax") || f->getName().starts_with("llvm.umin") || f->getName().starts_with("llvm.umax")); }
    if (!pure) continue;
    std::vector<Value *> ops(I.op_begin(), I.op_end());
    unsigned ex = 0; if (auto *C = dyn_cast<CmpInst>(&I)) ex = C->getPredicate();
    auto &v = seen[K{I.getOpcode(), I.getType(), ops, ex}];
    Instruction *hit = nullptr; for (Instruction *P : v) if (DT.dominates(P, &I)) { hit = P; break; }
    if (hit) { hit->dropPoisonGeneratingFlags(); I.replaceAllUsesWith(hit); I.eraseFromParent(); } else v.push_back(&I);
  }
}
struct Exp {   // SCEV of the clone -> instructions of the real function at PT, or nullptr
  Clone &X; DominatorTree &DT; Instruction *PT; IRBuilder<> B; DenseMap<Value *, Value *> &realOf; std::map<const SCEV *, Value *> memo;
  Exp(Clone &X, DominatorTree &DT, Instruction *PT, DenseMap<Value *, Value *> &r) : X(X), DT(DT), PT(PT), B(PT), realOf(r) {}
  Value *fit(Value *v, Type *t) { return v->getType() == t ? v : B.CreateZExtOrTrunc(v, t); }
  Value *go(const SCEV *S) {
    auto m = memo.find(S); if (m != memo.end()) return m->second;
    Value *r = comp(S); memo[S] = r; return r;
  }
  Value *comp(const SCEV *S) {
    if (auto *C = dyn_cast<SCEVConstant>(S)) return C->getValue();
    if (auto *A = dyn_cast<SCEVAddExpr>(S)) { Value *r = nullptr; for (const SCEV *o : A->operands()) { Value *v = go(o); if (!v) return nullptr; r = r ? B.CreateAdd(r, v) : v; } return r; }
    if (auto *A = dyn_cast<SCEVMulExpr>(S)) { Value *r = nullptr; for (const SCEV *o : A->operands()) { Value *v = go(o); if (!v) return nullptr; r = r ? B.CreateMul(r, v) : v; } return r; }
    if (auto *A = dyn_cast<SCEVZeroExtendExpr>(S)) { Value *v = go(A->getOperand()); return v ? B.CreateZExt(v, A->getType()) : nullptr; }
    if (auto *A = dyn_cast<SCEVSignExtendExpr>(S)) { Value *v = go(A->getOperand()); return v ? B.CreateSExt(v, A->getType()) : nullptr; }
    if (auto *A = dyn_cast<SCEVTruncateExpr>(S)) { Value *v = go(A->getOperand()); return v ? B.CreateTrunc(v, A->getType()) : nullptr; }
    if (auto *A = dyn_cast<SCEVUDivExpr>(S)) { Value *l = go(A->getLHS()), *r = go(A->getRHS()); return l && r ? B.CreateUDiv(l, r) : nullptr; }
    if (auto *U = dyn_cast<SCEVUnknown>(S)) {
      Value *V = U->getValue();
      auto c = X.canonOf.find(V);
      if (c != X.canonOf.end()) { Value *ra = realOf.lookup(c->second.base); if (!ra) return nullptr; return B.CreateLoad(c->second.ty, B.CreateConstGEP1_64(B.getInt8Ty(), ra, c->second.off)); }
      if (auto *C = dyn_cast<CallInst>(V)) if (isSreg(C)) return B.CreateCall(C->getFunctionType(), C->getCalledOperand());
      Value *R = realOf.lookup(V);
      if (!R) return isa<Constant>(V) ? V : nullptr;
      if (auto *I = dyn_cast<Instruction>(R)) if (!DT.dominates(I, PT)) return nullptr;
      return R;
    }
    return nullptr;
  }
};
}

// value of V at the first iteration of Lm, built at PT: header phis take their preheader value, pure instructions and reads of read-only allocas are rebuilt
static Value *firstValue(Value *V, Loop *Lm, BasicBlock *Pre, Instruction *PT, DominatorTree &DT, const std::set<Value *> &ro, DenseMap<Value *, Value *> &memo, int depth = 0) {
  auto *I = dyn_cast<Instruction>(V);
  if (!I || !Lm->contains(I)) { if (I && !DT.dominates(I, PT)) return nullptr; return V; }
  auto m = memo.find(V); if (m != memo.end()) return m->second;
  if (depth > 200) return nullptr;
  if (auto *P = dyn_cast<PHINode>(I)) { if (P->getParent() != Lm->getHeader()) return nullptr; return firstValue(P->getIncomingValueForBlock(Pre), Lm, Pre, PT, DT, ro, memo, depth + 1); }
  if (auto *L = dyn_cast<LoadInst>(I)) { int64_t off = 0; Value *b = GetPointerBaseWithConstantOffset(L->getPointerOperand(), off, I->getDataLayout()); if (!ro.count(b) || !L->isSimple()) return nullptr; }
  else if (!(isa<BinaryOperator>(I) || isa<CastInst>(I) || isa<CmpInst>(I) || isa<SelectInst>(I) || isa<GetElementPtrInst>(I))) return nullptr;
  Instruction *C = I->clone();
  for (unsigned i = 0; i < C->getNumOperands(); ++i) { Value *o = firstValue(I->getOperand(i), Lm, Pre, PT, DT, ro, memo, depth + 1); if (!o) { C->deleteValue(); return nullptr; } C->setOperand(i, o); }
  C->insertBefore(PT->getIterator());
  memo[V] = C; return C;
}

std::unique_ptr<LoDq> LoDq::build(Function &F, DominatorTree &DT, Loop *Lm, Loop *Lp, BasicBlock *Pre, const std::vector<LoDqSite> &Sites, bool needG) {
  const int diag = envI("LO_DQ_DIAG", 0);
  std::string nm = F.getName().str().substr(0, 40);
  Clone X; X.G = CloneFunction(&F, X.VM);
  DenseMap<Value *, Value *> realOf;
  for (auto kv : X.VM) if (kv.second && !isa<GlobalValue>(kv.first)) realOf[(Value *)kv.second] = const_cast<Value *>(kv.first);
  auto mapV = [&](Value *v) -> Value * { return isa<Constant>(v) ? v : (Value *)X.VM[v]; };
  struct Q { WeakTrackingVH main, pl; std::map<int, WeakTrackingVH> ev; };
  std::vector<Q> qv(Sites.size());
  for (size_t i = 0; i < Sites.size(); ++i) { const LoDqSite &s = Sites[i]; qv[i].main = mapV(s.C->getArgOperand(1)); if (s.pl) qv[i].pl = mapV(s.pl->getArgOperand(1)); for (auto &e : s.ev) qv[i].ev[e.first] = mapV(e.second->getArgOperand(1)); }
  BasicBlock *Hc = cast<BasicBlock>((Value *)X.VM[Lm->getHeader()]), *Pc = Lp ? cast<BasicBlock>((Value *)X.VM[Lp->getHeader()]) : nullptr;
  canonSregs(X); canonLoads(X);
  { DominatorTree D(*X.G); mergePure(X, D); }
  std::unique_ptr<LoDq> R(new LoDq); Impl &M = *R->I; M.needG = needG; M.S.resize(Sites.size());
  int na = 0, np = 0; std::vector<const SCEV *> st(Sites.size()), gap(Sites.size());
  {
    DominatorTree D2(*X.G); LoopInfo L2(D2); TargetLibraryInfoImpl TI{Triple(F.getParent()->getTargetTriple())}; TargetLibraryInfo TL(TI); AssumptionCache AC(*X.G);
    ScalarEvolution SE(*X.G, TL, AC, D2, L2);
    Loop *Lmc = L2.getLoopFor(Hc), *Lpc = Pc ? L2.getLoopFor(Pc) : nullptr;
    Instruction *PT = Pre->getTerminator(); Exp E(X, DT, PT, realOf);
    BasicBlock *PP = Lp ? Lp->getLoopPreheader() : nullptr; Instruction *PPT = PP ? PP->getTerminator() : nullptr;
    std::unique_ptr<Exp> E2; if (Lp) E2.reset(new Exp(X, DT, PPT, realOf));
    std::set<Value *> ro; for (auto &kv : X.canon) if (Value *r = realOf.lookup(kv.first.base)) ro.insert(r);
    DenseMap<Value *, Value *> fv, fvp;
    auto sc = [&](Value *v) -> const SCEV * { return v && SE.isSCEVable(v->getType()) ? SE.getSCEV(v) : nullptr; };
    for (size_t i = 0; i < Sites.size(); ++i) {
      SiteInfo &s = M.S[i]; s.s = Sites[i]; s.hasG = needG; const char *why = "", *pro = "";
      auto *AR = dyn_cast_or_null<SCEVAddRecExpr>(sc(qv[i].main));
      if (!AR || AR->getLoop() != Lmc || !AR->isAffine()) why = "not an add recurrence of the loop";
      else if (!SE.isLoopInvariant(AR->getStepRecurrence(SE), Lmc)) why = "step varies";
      else if (!(s.step = E.go(AR->getStepRecurrence(SE)))) why = "step not expandable";
      else if (!(s.A = firstValue(s.s.C->getArgOperand(1), Lm, Pre, PT, DT, ro, fv))) why = "first value not rebuilt";
      else {
        s.affine = true; na++; const SCEV *step = st[i] = AR->getStepRecurrence(SE), *A = AR->getStart();
        if (s.s.pl) {
          auto *PR = dyn_cast_or_null<SCEVAddRecExpr>(sc(qv[i].pl));
          if (!PR || PR->getLoop() != Lpc || !PR->isAffine()) pro = "round not an add recurrence";
          else if (PR->getStepRecurrence(SE) != step) pro = "round's step differs";
          else { Value *b = firstValue(s.s.pl->getArgOperand(1), Lp, PP, PPT, DT, ro, fvp), *s2 = E2->go(step);
            if (!b || !s2) pro = "entry 0 not rebuilt";
            else { IRBuilder<> Q2(PPT); s.D0 = s.s.Tn ? Q2.CreateAdd(b, Q2.CreateMul(s2, Q2.getInt64(s.s.Tn))) : b; gap[i] = SE.getMinusSCEV(A, PR->getStart()); np++; } }
        } else {
          for (int t = 0; t < s.s.d && !*pro; ++t) { const SCEV *e = qv[i].ev.count(t) ? sc(qv[i].ev[t]) : nullptr, *nx = t + 1 < s.s.d ? (qv[i].ev.count(t + 1) ? sc(qv[i].ev[t + 1]) : nullptr) : A;
            if (!e || !nx || SE.getMinusSCEV(nx, e) != step) pro = "entries do not continue the recurrence"; }
          if (!*pro) np++;
        }
      }
      if (diag) errs() << "[lo-dq] site " << i << " d=" << s.s.d << " " << (s.affine ? "affine" : why) << " " << pro << "\n";
    }
  }
  X.G->eraseFromParent();
  if (!na) { errs() << "[lo-dq] " << nm << ": no affine site, queue stays\n"; return nullptr; }
  M.noq = np == (int)M.S.size() && envI("LO_DQ_NOQ", 1);
  // LO_DQ_STEADY=0 (schedule 1): the first-trips path reads the queue at a run-time index that is the same for every trip of the warp loop; O3 splits that GEP off the slot GEP and virt_ctx_to_scratch then
  // lays the two out inconsistently (cuBLAS hgemm s1p1 reads 0xbaadf00d...). Translator fault, see the report.
  if (!M.noq && !envI("LO_DQ_STEADY", 1)) { errs() << "[lo-dq] " << nm << ": prologue not proved, queue stays (LO_DQ_STEADY=0)\n"; return nullptr; }
  if (M.noq && Lp) for (size_t i = 0; i < M.S.size(); ++i) {   // sites sharing G
    SiteInfo &s = M.S[i]; int c = -1;
    for (size_t j = 0; j < M.AC.size(); ++j) { int r = M.AC[j].rep; if (st[r] == st[i] && gap[r] == gap[i] && M.S[r].s.d == s.s.d) c = j; }
    if (c < 0) { c = M.AC.size(); M.AC.push_back({}); M.AC[c].rep = i; M.AC[c].step = s.step; }
    s.cls = c;
  }
  // shift registers: rows of the sites of one depth, at most 64 bits a word
  std::map<int, std::vector<int>> byD; for (size_t i = 0; i < M.S.size(); ++i) if (M.S[i].affine) byD[M.S[i].s.d].push_back(i);
  for (auto &kv : byD) { int d = kv.first, w = -1;
    for (int i : kv.second) { SiteInfo &s = M.S[i]; int nb = s.hasG ? 2 : 1;
      if (w < 0 || (M.W[w].w + nb) * d > 64) { w = M.W.size(); M.W.push_back({}); M.W[w].d = d; }
      s.word = w; s.off = M.W[w].w; M.W[w].w += nb; M.W[w].Tn = s.s.Tn; } }
  IRBuilder<> EB(&*F.getEntryBlock().getFirstInsertionPt()); Type *I64 = EB.getInt64Ty();
  for (Word &w : M.W) { w.a = M.mk(EB, I64, "dq.w"); if (M.noq && Lp) w.row = M.mk(EB, I64, "dq.row"); }
  if (!M.noq || !M.AC.empty()) M.T = M.mk(EB, EB.getInt32Ty(), "dq.t");
  for (size_t i = 0; i < M.S.size(); ++i) { SiteInfo &s = M.S[i]; if (!s.affine) continue;
    s.D = M.mk(EB, I64, "dq.d");
    if (!M.noq) { IRBuilder<> P(Pre->getTerminator()); P.CreateStore(s.A, s.D); }
    else if (s.D0 && M.AC[s.cls].rep == (int)i) { IRBuilder<> P(Lp->getLoopPreheader()->getTerminator()); P.CreateStore(s.D0, s.D); } }
  errs() << "[lo-dq] " << nm << ": " << M.S.size() << " sites, " << na << " affine, " << np << " with their prologue: " << (M.noq ? "no queue" : "queue for the first trips only") << ", " << M.W.size() << " shift registers\n";
  return R;
}

bool LoDq::affine(int k) { return I->S[k].affine; }
bool LoDq::noq() { return I->noq; }
void LoDq::pushEvent(IRBuilder<> &B, int k, int t, Value *src, Value *sz) {
  Impl &M = *I; SiteInfo &s = M.S[k]; Word &w = M.W[s.word];
  M.orIn(B, w, M.bits(B, s, sz, nullptr), (uint64_t)t * w.w + s.off);
  if (t == 0) B.CreateStore(src, s.D);
}
void LoDq::pushLoop(IRBuilder<> &B, int k, Value *sz) {
  Impl &M = *I; SiteInfo &s = M.S[k]; Word &w = M.W[s.word]; Type *I64 = B.getInt64Ty();
  B.CreateStore(B.CreateOr(B.CreateLoad(I64, w.row), B.CreateShl(M.bits(B, s, sz, nullptr), B.getInt64(s.off))), w.row);
}
void LoDq::loopEnd(IRBuilder<> &B, Value *c) {
  Impl &M = *I; Type *I64 = B.getInt64Ty();
  for (Word &w : M.W) {
    Value *on = B.CreateICmpSGE(c, B.getInt32(w.Tn));   // rounds before Tn copy, they queue nothing. The shift count stays in range for them too (a shift by 64 or more is poison)
    Value *rw = B.CreateZExt(B.CreateSelect(on, B.CreateSub(c, B.getInt32(w.Tn)), B.getInt32(0)), I64);
    Value *r = B.CreateSelect(on, B.CreateLoad(I64, w.row), B.getInt64(0));
    B.CreateStore(B.CreateOr(B.CreateLoad(I64, w.a), B.CreateShl(r, B.CreateMul(rw, B.getInt64(w.w)))), w.a);
    B.CreateStore(B.getInt64(0), w.row);
  }
}
void LoDq::preheader(Instruction *PT) {
  Impl &M = *I; IRBuilder<> B(PT); Type *I64 = B.getInt64Ty();
  for (AClass &c : M.AC) { SiteInfo &r = M.S[c.rep]; int d = r.s.d;
    c.G = B.CreateSub(r.A, B.CreateLoad(I64, r.D));
    c.x = B.CreateSub(c.G, B.CreateMul(c.step, B.getInt64(d - 1)));
    for (SiteInfo &s : M.S) if (s.cls >= 0 && &M.AC[s.cls] == &c && &s != &r) B.CreateStore(B.CreateSub(s.A, c.G), s.D); }
}
void LoDq::header(IRBuilder<> &B) {
  Impl &M = *I; Type *I64 = B.getInt64Ty();
  for (Word &w : M.W) { w.cur = B.CreateLoad(I64, w.a, "dq.cur"); B.CreateStore(B.CreateLShr(w.cur, B.getInt64(w.w)), w.a); }
  if (M.T) { M.t = B.CreateLoad(B.getInt32Ty(), M.T, "dq.t"); B.CreateStore(B.CreateAdd(M.t, B.getInt32(1)), M.T); }
}
Value *LoDq::trip() { return I->t; }
void LoDq::pushMain(IRBuilder<> &B, int k, Value *sz, Value *g) { Impl &M = *I; SiteInfo &s = M.S[k]; Word &w = M.W[s.word]; M.orIn(B, w, M.bits(B, s, sz, g), (uint64_t)(w.d - 1) * w.w + s.off); }
Value *LoDq::addr(IRBuilder<> &B, int k) { SiteInfo &s = I->S[k]; return s.cur = B.CreateLoad(B.getInt64Ty(), s.D, "dq.a"); }
Value *LoDq::go(IRBuilder<> &B, int k) { Impl &M = *I; SiteInfo &s = M.S[k]; return B.CreateICmpNE(B.CreateAnd(M.W[s.word].cur, B.getInt64(2ull << s.off)), B.getInt64(0)); }
Value *LoDq::nz(IRBuilder<> &B, int k) { Impl &M = *I; SiteInfo &s = M.S[k]; return B.CreateICmpNE(B.CreateAnd(M.W[s.word].cur, B.getInt64(1ull << s.off)), B.getInt64(0)); }
void LoDq::step(IRBuilder<> &B, int k) { SiteInfo &s = I->S[k]; B.CreateStore(B.CreateAdd(B.CreateLoad(B.getInt64Ty(), s.D), s.step), s.D); }
// noq, prologue loop: behind every site's step. At t = d - 1 the pointers jump to the loop's first value: nothing happens when the ring was full (x = s). A uniform branch: two instructions a trip.
void LoDq::fixup(Instruction *At) {
  Impl &M = *I; Type *I64 = Type::getInt64Ty(At->getContext());
  for (AClass &c : M.AC) { int d = M.S[c.rep].s.d; IRBuilder<> B(At);
    Instruction *T = SplitBlockAndInsertIfThen(B.CreateICmpEQ(M.t, B.getInt32(d - 1)), At->getIterator(), false);
    IRBuilder<> Q(T); Value *y = Q.CreateSub(c.x, c.step);
    for (SiteInfo &s : M.S) if (s.cls >= 0 && &M.AC[s.cls] == &c) Q.CreateStore(Q.CreateAdd(Q.CreateLoad(I64, s.D), y), s.D); }
}
void LoDq::finish(Function &F) { DominatorTree DT(F); PromoteMemToReg(I->allocas, DT); }
