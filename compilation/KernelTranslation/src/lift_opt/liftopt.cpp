// liftopt.cpp (2026-11-03): LLVM 20 pass plugin for lifted NVVM IR, run BEFORE CuPBoP (opt -load-pass-plugin=libliftopt.so).
// General rewrites of what the lift leaves behind; no kernel constants. Passes (registered names):
//   lo-mma   : mma.sync m16n8k16 (f16 in, f32 or f16 accumulators) -> Vortex NT32 WMMA (m16n16k32), several mma per WMMA,
//              NO accumulator shuffles: the tile columns are the PTX columns under a lane permutation of the B operand
//   lo-ldsm  : ldmatrix asm -> plain LMEM loads (B-only results take the lane permutation for free, in the address)
//   lo-f16   : fptrunc float->half : exact integer RNE fast path, the real fptrunc outside the range
// Layouts (runtime/src/vortex/kernel/cudaKernelImpl.cpp), lane l, g = l>>2, t = l&3, tile m16n16k32:
//   A reg r : row g + 8(r>>2), k = 8(r&3) + 2t + {0,1}     B reg r : k = 8(r>>1) + 2t + {0,1}, n = g + 8(r&1)
//   C reg r : row g + 8(r>>2), col t + 4(r&3)
// PTX m16n8k16: a0=(g,2t) a1=(g+8,2t) a2=(g,2t+8) a3=(g+8,2t+8), b0=(2t,g) b1=(2t+8,g), c0=(g,2t) c1=(g,2t+1) c2=(g+8,2t) c3=(g+8,2t+1).
// A and B map register for register. C differs only by a column permutation inside each group of 8 columns: put actual column
// rho(c) = 2(c&3) + (c>>2) into tile column c (n-half u: 8u + c). Then reg 2u = c0, 2u+1 = c1, 4+2u = c2, 5+2u = c3 of n-half u
// exactly. "Tile column c holds actual rho(c)" means lane group g of B holds the B data of PTX lane group rho(g):
// one index shuffle per B register (src lane 4 rho(g) + t), or none when B comes from ldmatrix (the row address / column offset
// of that lane is permuted instead). Every output element is the same dot product in the same k order: bit exact.
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"
#include <algorithm>
#include <cstdlib>
#include <functional>
#include <map>
#include <set>
#include <string>
#include <vector>
using namespace llvm;

static bool envOn(const char *n, bool def) { const char *e = getenv(n); return e ? atoi(e) != 0 : def; }
static int envInt(const char *n, int def) { const char *e = getenv(n); return e ? atoi(e) : def; }
static bool dbg() { static bool d = envOn("LO_DEBUG", false); return d; }

static Value *peel(Value *V) { while (auto *B = dyn_cast<BitCastInst>(V)) V = B->getOperand(0); return V; }
static bool isConstZero(Value *V) { auto *C = dyn_cast<Constant>(peel(V)); return C && C->isNullValue(); }

// ---- per-function lane context: lane-derived values, built once per basic block ---------------------------------------
Value *loLaneEval(IRBuilder<> &Q, Value *V, Value *tid);   // lopass.cpp
static bool loLaneMode = false;   // lo-mma<lane-eval>: an ldmatrix row address is a function of tid.x, not of what another lane loaded (stock Triton)
struct Lanes {
  Module *M; Type *I32; FunctionCallee LaneFn, Shfl; Value *tid = nullptr;
  struct PerBB { Value *lane = nullptr, *g = nullptr, *t = nullptr, *rg = nullptr, *bsrc = nullptr, *t4 = nullptr, *t2 = nullptr, *col = nullptr, *colp = nullptr, *t8 = nullptr, *th = nullptr; std::map<std::pair<Value *, Value *>, Instruction *> shfl, rowp; std::map<std::pair<Value *, Value *>, Value *> rows; std::map<int, Value *> src; std::map<std::tuple<int, int, int, int>, Value *> ksrc; };
  // lane index for ldmatrix rows, one value per kind and j and block: kind 0 g | 8j, 1 rho(g) | 8j, 2 2t | 8j, 3 2t+1 | 8j
  Value *srcIdx(BasicBlock *B, int kind, int j) {
    PerBB &P = get(B); int key = kind * 8 + j;
    auto it = P.src.find(key); if (it != P.src.end()) return it->second;
    IRBuilder<> Q(cast<Instruction>(P.t4)->getNextNode());
    Value *base = kind == 0 ? P.g : kind == 1 ? P.rg : P.t2;
    Value *v = Q.CreateOr(base, ConstantInt::get(I32, 8 * j + (kind == 3 ? 1 : 0)));
    return P.src[key] = v;
  }
  // k-slot permutation: row source lane of a word: matrix m0 for lanes t < 2, m1 for t >= 2; kind 0: row g, 1: row rho(g), 2: row 4(t&1) + 2q + hi (trans; add = 2q + hi)
  Value *kIdx(BasicBlock *B, int m0, int m1, int kind, int add) {
    PerBB &P = get(B); auto key = std::make_tuple(m0, m1, kind, add);
    auto it = P.ksrc.find(key); if (it != P.ksrc.end()) return it->second;
    IRBuilder<> Q(cast<Instruction>(P.th)->getNextNode());
    Value *sel = Q.CreateSelect(P.th, ConstantInt::get(I32, 8 * m1), ConstantInt::get(I32, 8 * m0));
    Value *base = kind == 0 ? P.g : kind == 1 ? P.rg : Q.CreateAdd(Q.CreateLShr(P.t8, 1), ConstantInt::get(I32, add));
    return P.ksrc[key] = Q.CreateOr(sel, base);
  }
  std::map<BasicBlock *, PerBB> bb;
  explicit Lanes(Module *M_) : M(M_), I32(Type::getInt32Ty(M_->getContext())) {
    LaneFn = M->getOrInsertFunction("llvm.nvvm.read.ptx.sreg.laneid", FunctionType::get(I32, false));
    Shfl = M->getOrInsertFunction("llvm.nvvm.shfl.sync.idx.i32", FunctionType::get(I32, {I32, I32, I32, I32}, false));
    if (auto *F = dyn_cast<Function>(Shfl.getCallee())) F->addFnAttr(Attribute::Convergent);
  }
  // lane-derived values are inserted at the top of the block (after phis): available to every position in it
  PerBB &get(BasicBlock *B) {
    PerBB &P = bb[B];
    if (P.lane) return P;
    if (loLaneMode && !tid) { IRBuilder<> E(&*B->getParent()->getEntryBlock().getFirstInsertionPt()); tid = E.CreateCall(M->getOrInsertFunction("llvm.nvvm.read.ptx.sreg.tid.x", FunctionType::get(I32, false)), {}, "lo.tid"); }
    IRBuilder<> Q(loLaneMode && cast<Instruction>(tid)->getParent() == B ? cast<Instruction>(tid)->getNextNode() : &*B->getFirstInsertionPt());
    P.lane = loLaneMode ? Q.CreateAnd(tid, 31, "lo.lane") : (Value *)Q.CreateCall(LaneFn, {}, "lo.lane");
    P.g = Q.CreateLShr(P.lane, 2, "lo.g"); P.t = Q.CreateAnd(P.lane, 3, "lo.t");
    P.rg = Q.CreateOr(Q.CreateShl(Q.CreateAnd(P.g, 3), 1), Q.CreateLShr(P.g, 2), "lo.rho");   // rho(g)
    P.bsrc = Q.CreateOr(Q.CreateShl(P.rg, 2), P.t, "lo.bsrc");                                 // 4 rho(g) + t
    P.t2 = Q.CreateShl(P.t, 1, "lo.t2"); P.col = Q.CreateShl(P.g, 1, "lo.col"); P.colp = Q.CreateShl(P.rg, 1, "lo.colp");
    P.t4 = Q.CreateShl(P.t, 2, "lo.t4");
    P.t8 = Q.CreateShl(Q.CreateAnd(P.t, 1), 3, "lo.t8"); P.th = Q.CreateICmpNE(Q.CreateAnd(P.t, 2), ConstantInt::get(I32, 0), "lo.th");
    return P;
  }
  // an ldmatrix row address of lane src: computed here from the lane number when lo-mma<lane-eval> and the address allow it, else the shuffle
  Value *row(IRBuilder<> &Q, Value *L, Value *src) {
    if (loLaneMode) {
      auto &R = bb[Q.GetInsertBlock()].rows; auto key = std::make_pair(L, src);
      auto it = R.find(key);
      if (it != R.end() && (!isa<Instruction>(it->second) || cast<Instruction>(it->second)->comesBefore(&*Q.GetInsertPoint()))) return it->second;
      Value *t = Q.CreateOr(Q.CreateAnd(tid, ~31u), src);
      if (Value *v = loLaneEval(Q, L, t)) return R[key] = v;
    }
    return shfl(Q, L, src);
  }
  // index shuffle, cached per block: reused only if the cached copy is before the insertion point
  Value *shfl(IRBuilder<> &Q, Value *v, Value *src) {
    PerBB &P = get(Q.GetInsertBlock());
    auto key = std::make_pair(v, src);
    auto it = P.shfl.find(key);
    static const bool useCache = envOn("LO_SHFL_CACHE", true);
    if (useCache && it != P.shfl.end() && it->second->comesBefore(&*Q.GetInsertPoint())) return it->second;
    auto *C = Q.CreateCall(Shfl, {ConstantInt::getAllOnesValue(I32), v, src, ConstantInt::get(I32, 31)}, "lo.shfl");
    C->addFnAttr(Attribute::Convergent);
    P.shfl[key] = C;
    return C;
  }
};

// a fragment word of an ldmatrix, as lowered by lowerLdsm: enough to load it again next to its WMMA
struct FragInfo { GlobalVariable *G; Value *L; int64_t C; bool trans, perm; int j; Instruction *at; int m0 = -1, m1 = -1, q = 0; };
static std::map<Value *, FragInfo> fragOf;
// ---- ldmatrix ------------------------------------------------------------------------------------------------------------
struct Ldsm { CallInst *CI; int num; bool trans; Value *addr; };
static bool parseLdsm(CallInst *CI, Ldsm &L) {
  auto *IA = dyn_cast<InlineAsm>(CI->getCalledOperand());
  if (!IA) return false;
  StringRef s = IA->getAsmString();
  if (!s.starts_with("ldmatrix.sync")) return false;
  L.CI = CI; L.trans = s.contains(".trans"); L.num = s.contains(".x4") ? 4 : s.contains(".x2") ? 2 : 1;
  L.addr = CI->getArgOperand(0);
  return true;
}

// is V (through bitcasts) used only as a B operand of an mma the pass will lower?
static bool isMma(CallInst *C) { Function *F = C->getCalledFunction(); if (!F) return false; StringRef n = F->getName();
  return (loLaneMode && n == "llvm.nvvm.mma.m16n8k16.row.col.bf16") || n == "llvm.nvvm.mma.m16n8k16.row.col.f32.f32" || n == "llvm.nvvm.mma.m16n8k16.row.col.f16.f16" || n == "llvm.nvvm.mma.m16n8k8.row.col.f32.f32" || n == "llvm.nvvm.mma.m16n8k8.row.col.f16.f16"; }
// k-blocks of 8 in one mma: m16n8k16 = 2 (args a0..a3, b0, b1, c...), m16n8k8 = 1 (args a0, a1, b0, c...)
static int mmaKb(CallInst *C) { return C->getCalledFunction()->getName().contains("m16n8k16") ? 2 : 1; }
// An ldmatrix row offset: E = window mask of (L + C). The mask (shared window < 16 MB; row addresses are 16-byte aligned for
// ldmatrix) never changes a valid address and is dropped; C rides on the load's GEP; only L is shuffled: shfl(L + C) = shfl(L) + C.
static void splitOffset(Value *E, Value *&L, int64_t &C) {
  C = 0;
  for (;;) {
    auto *BO = dyn_cast<BinaryOperator>(E);
    if (!BO) break;
    auto *K = dyn_cast<ConstantInt>(BO->getOperand(1));
    if (!K) break;
    if (BO->getOpcode() == Instruction::And && (K->getZExtValue() & 0xFFFFF0u) == 0xFFFFF0u) { E = BO->getOperand(0); continue; }
    if (BO->getOpcode() == Instruction::Add) { C += K->getSExtValue(); E = BO->getOperand(0); continue; }
    break;
  }
  L = E;
}

// addr: ptrtoint(gep [N x i8] @g, 0, zext(off)) -> (base, off i32)
static bool smemOffset(Value *A, GlobalVariable *&G, Value *&off) {
  auto *P = dyn_cast<PtrToIntInst>(A);
  if (!P) return false;
  auto *GEP = dyn_cast<GetElementPtrInst>(P->getOperand(0));
  if (!GEP) return false;
  G = dyn_cast<GlobalVariable>(GEP->getPointerOperand());
  if (!G || GEP->getNumIndices() != 2 || !isConstZero(GEP->getOperand(1))) return false;
  Value *I = GEP->getOperand(2);
  if (auto *Z = dyn_cast<ZExtInst>(I)) I = Z->getOperand(0);
  else if (auto *CI = dyn_cast<ConstantInt>(I)) I = ConstantInt::get(Type::getInt32Ty(A->getContext()), CI->getZExtValue());
  else return false;
  if (!I->getType()->isIntegerTy(32)) return false;
  off = I;
  return true;
}

// instcombine packs two halves as insertelement <2 x half>: back to integer form (zext, shl, or), which the f16 fast path feeds without any half value
static void canonPacks(Function &F) {
  LLVMContext &Ctx = F.getContext(); Type *I16 = Type::getInt16Ty(Ctx), *I32 = Type::getInt32Ty(Ctx);
  for (auto &BB : F) for (Instruction &I : make_early_inc_range(BB)) {
    auto *E1 = dyn_cast<InsertElementInst>(&I);
    if (!E1 || !E1->getType()->getElementType()->isHalfTy() || cast<FixedVectorType>(E1->getType())->getNumElements() != 2) continue;
    auto *E0 = dyn_cast<InsertElementInst>(E1->getOperand(0));
    auto *i1 = dyn_cast<ConstantInt>(E1->getOperand(2));
    if (!E0 || !i1 || i1->getZExtValue() != 1 || !isa<PoisonValue>(E0->getOperand(0)) && !isa<UndefValue>(E0->getOperand(0))) continue;
    auto *i0 = dyn_cast<ConstantInt>(E0->getOperand(2));
    if (!i0 || i0->getZExtValue() != 0) continue;
    IRBuilder<> Q(E1);
    Value *lo = Q.CreateZExt(Q.CreateBitCast(E0->getOperand(1), I16), I32), *hi = Q.CreateZExt(Q.CreateBitCast(E1->getOperand(1), I16), I32);
    E1->replaceAllUsesWith(Q.CreateBitCast(Q.CreateOr(Q.CreateShl(hi, 16), lo), E1->getType()));
    E1->eraseFromParent();
    if (E0->use_empty()) E0->eraseFromParent();
  }
}

// instcombine turns phis of extractvalues into a phi of the ldmatrix struct: split it again (scalars per element)
static void splitAggPhis(Function &F) {
  for (bool again = true; again;) {
    again = false;
    for (auto &BB : F) for (PHINode &P : make_early_inc_range(BB.phis())) {
      auto *ST = dyn_cast<StructType>(P.getType());
      if (!ST) continue;
      bool ok = true; for (User *U : P.users()) if (!isa<ExtractValueInst>(U)) ok = false;
      if (!ok) continue;
      std::vector<PHINode *> ph;
      for (unsigned i = 0; i < ST->getNumElements(); ++i) {
        PHINode *N = PHINode::Create(ST->getElementType(i), P.getNumIncomingValues(), P.getName() + ".e", P.getIterator());
        for (unsigned k = 0; k < P.getNumIncomingValues(); ++k) {
          IRBuilder<> Q(P.getIncomingBlock(k)->getTerminator());
          N->addIncoming(Q.CreateExtractValue(P.getIncomingValue(k), i), P.getIncomingBlock(k));
        }
        ph.push_back(N);
      }
      for (User *U : make_early_inc_range(P.users())) { auto *E = cast<ExtractValueInst>(U); E->replaceAllUsesWith(ph[E->getIndices()[0]]); E->eraseFromParent(); }
      P.eraseFromParent(); again = true;
    }
  }
}
// which ldmatrix calls feed only mma B operands (through bitcasts and phis); calls joined by a phi share the verdict
static void findBOnly(Function &F, std::set<CallInst *> &good, std::set<Value *> &goodPhis) {
  std::map<CallInst *, CallInst *> parent; std::set<CallInst *> bad; std::map<PHINode *, CallInst *> phiOf;
  std::function<CallInst *(CallInst *)> find = [&](CallInst *c) { return parent[c] == c ? c : parent[c] = find(parent[c]); };
  auto unite = [&](CallInst *a, CallInst *b) { parent[find(a)] = find(b); };
  std::vector<CallInst *> calls;
  for (auto &BB : F) for (auto &I : BB) if (auto *C = dyn_cast<CallInst>(&I)) { Ldsm L; if (parseLdsm(C, L)) { calls.push_back(C); parent[C] = C; } }
  for (CallInst *C : calls) {
    std::vector<Value *> work; std::set<Value *> seen;
    for (User *U : C->users()) { if (isa<ExtractValueInst>(U)) work.push_back(U); else bad.insert(C); }
    while (!work.empty()) {
      Value *V = work.back(); work.pop_back();
      if (!seen.insert(V).second) continue;
      for (User *U : V->users()) {
        if (isa<BitCastInst>(U)) { work.push_back(U); continue; }
        if (auto *P = dyn_cast<PHINode>(U)) {
          if (phiOf.count(P)) unite(phiOf[P], C); else phiOf[P] = C;
          work.push_back(P); continue;
        }
        auto *M = dyn_cast<CallInst>(U);
        if (!M || !isMma(M)) { bad.insert(C); continue; }
        { unsigned b0 = 2 * mmaKb(M), b1 = 3 * mmaKb(M); for (unsigned i = 0; i < M->arg_size(); ++i) if (M->getArgOperand(i) == V && !(i >= b0 && i < b1)) bad.insert(C); }
      }
    }
  }
  for (auto &kv : phiOf) for (Value *In : kv.first->incoming_values()) {
    Value *V = peel(In);
    if (auto *E = dyn_cast<ExtractValueInst>(V)) { auto *C = dyn_cast<CallInst>(E->getAggregateOperand()); if (C && parent.count(C)) { unite(C, kv.second); continue; } }
    if (auto *P = dyn_cast<PHINode>(V)) if (phiOf.count(P)) continue;
    if (isa<UndefValue>(V)) continue;
    bad.insert(kv.second);
  }
  std::set<CallInst *> badRoots; for (CallInst *c : bad) badRoots.insert(find(c));
  for (CallInst *c : calls) if (!badRoots.count(find(c))) good.insert(c);
  for (auto &kv : phiOf) if (!badRoots.count(find(kv.second))) goodPhis.insert(kv.first);
}

// ---- k-slot permutation ---------------------------------------------------------------------------------------------------
// LMEM banks are 8 bytes wide: the 4 lanes of a row reading 4 consecutive words share 2 banks. A WMMA only needs the same k order in A and B, so inside each k16
// slot (reg q, lane t) can take word 2(t&1)+q of the 16-byte chunk t>>1: the lanes of a row then read words 8 bytes apart, the two regs of a pair come from one row
// pointer (one shuffle for two words). Applied to a set of ldmatrix joined by mma operands, only when every operand of those mma comes from them in pairs.
struct KPerm { int m0[4], m1[4], q[4]; };
static std::map<CallInst *, KPerm> kperm;
static void findKPerm(Function &F) {
  kperm.clear(); if (!envOn("LO_KPERM", true)) return;
  std::map<CallInst *, CallInst *> par; std::set<CallInst *> bad; std::map<CallInst *, std::map<int, std::pair<int, int>>> part;   // result index -> (partner index, q)
  std::function<CallInst *(CallInst *)> find = [&](CallInst *c) { return par[c] == c ? c : par[c] = find(par[c]); };
  auto root = [&](Value *V, CallInst *&C, int &i) { auto *E = dyn_cast<ExtractValueInst>(peel(V)); C = E ? dyn_cast<CallInst>(E->getAggregateOperand()) : nullptr; Ldsm L; if (!C || !parseLdsm(C, L)) { C = nullptr; return false; } i = E->getIndices()[0]; if (!par.count(C)) par[C] = C; return true; };
  std::vector<std::vector<CallInst *>> sets; std::vector<CallInst *> badm;
  auto pairUp = [&](Value *x, Value *y, std::vector<CallInst *> &cs) {
    CallInst *c0, *c1; int i0, i1; bool ok0 = root(x, c0, i0), ok1 = root(y, c1, i1);
    if (ok0) cs.push_back(c0); if (ok1) cs.push_back(c1);
    if (!ok0 || !ok1 || c0 != c1) return false;
    auto &m = part[c0]; bool ok = true;
    if (m.count(i0) && m[i0] != std::make_pair(i1, 0)) ok = false; if (m.count(i1) && m[i1] != std::make_pair(i0, 1)) ok = false;
    m[i0] = {i1, 0}; m[i1] = {i0, 1}; return ok; };
  for (auto &BB : F) for (auto &I : BB) if (auto *C = dyn_cast<CallInst>(&I)) if (isMma(C)) {
    std::vector<CallInst *> cs; bool ok = mmaKb(C) == 2;
    if (ok) { for (int r = 0; r < 2; ++r) ok &= pairUp(C->getArgOperand(r), C->getArgOperand(2 + r), cs); ok &= pairUp(C->getArgOperand(4), C->getArgOperand(5), cs); }
    else for (Value *V : C->args()) { CallInst *c; int i; if (root(V, c, i)) cs.push_back(c); }
    for (size_t k = 1; k < cs.size(); ++k) par[find(cs[k])] = find(cs[0]);
    if (!ok) for (CallInst *c : cs) bad.insert(c);
  }
  // an ldmatrix that stays asm has the plain k order, and all of a set must agree: one with an address form lowerLdsm does not read takes its set out (Triton: 8 of 40 lowered, the words of the rest in another order)
  for (auto &kv : par) { Ldsm L; GlobalVariable *G; Value *o; if (!parseLdsm(kv.first, L) || !smemOffset(L.addr, G, o)) bad.insert(kv.first); }
  // an ldmatrix read by anything else than an mma stays as it is
  for (auto &kv : par) { CallInst *C = kv.first; for (User *U : C->users()) { auto *E = dyn_cast<ExtractValueInst>(U); if (!E) { bad.insert(C); continue; } std::function<void(Value *)> w = [&](Value *V) { for (User *X : V->users()) { if (isa<BitCastInst>(X)) { w(X); continue; } auto *M = dyn_cast<CallInst>(X); if (!M || !isMma(M)) bad.insert(C); } }; w(E); } }
  std::set<CallInst *> badRoot; for (CallInst *c : bad) badRoot.insert(find(c));
  unsigned n = 0;
  for (auto &kv : par) { CallInst *C = kv.first; if (badRoot.count(find(C))) continue; KPerm K; for (int i = 0; i < 4; ++i) K.m0[i] = -1;
    for (auto &pr : part[C]) { int i = pr.first, o = pr.second.first, q = pr.second.second; K.q[i] = q; K.m0[i] = q ? o : i; K.m1[i] = q ? i : o; }
    kperm[C] = K; n++; }
  if (n) errs() << "lo-kperm: " << F.getName().substr(0, 30) << ": " << n << " of " << par.size() << " ldmatrix with the k-slot permutation\n";
}

static void lowerLdsm(Function &F, Lanes &LN, std::set<Value *> &bPermuted) {
  if (dbg()) for (auto &BB : F) for (auto &I : BB) if (auto *C = dyn_cast<CallInst>(&I)) { Ldsm L; if (parseLdsm(C, L)) { GlobalVariable *G; Value *o; if (!smemOffset(L.addr, G, o)) { errs() << "ldsm addr: "; L.addr->print(errs()); errs() << "\n"; if (auto *P = dyn_cast<User>(L.addr)) for (Value *V : P->operands()) { errs() << "   op: "; V->print(errs()); errs() << "\n"; } } } }
  std::vector<Ldsm> todo;
  for (auto &BB : F) for (auto &I : BB) if (auto *C = dyn_cast<CallInst>(&I)) { Ldsm L; if (parseLdsm(C, L)) todo.push_back(L); }
  findKPerm(F);
  const bool fold = envOn("LO_LDSM_FOLD", true);
  std::set<CallInst *> goodCalls; std::set<Value *> goodPhis; findBOnly(F, goodCalls, goodPhis);
  if (fold) bPermuted.insert(goodPhis.begin(), goodPhis.end());
  LLVMContext &Ctx = F.getContext(); Type *I32 = Type::getInt32Ty(Ctx), *I16 = Type::getInt16Ty(Ctx), *F32 = Type::getFloatTy(Ctx), *I8 = Type::getInt8Ty(Ctx);
  unsigned nDone = 0, nPerm = 0;
  for (Ldsm &L : todo) {
    GlobalVariable *G; Value *off;
    if (!smemOffset(L.addr, G, off)) { if (dbg()) errs() << "lo-ldsm: address form not understood, asm kept\n"; continue; }
    IRBuilder<> Q(L.CI);
    auto &P = LN.get(L.CI->getParent());
    // uses of the result: extractvalue only
    SmallVector<ExtractValueInst *, 4> ev; bool allB = goodCalls.count(L.CI), simple = true;
    for (User *U : L.CI->users()) {
      auto *E = dyn_cast<ExtractValueInst>(U);
      if (!E) { simple = false; break; }
      ev.push_back(E);
    }
    if (!simple) { if (dbg()) errs() << "lo-ldsm: result used other than by extractvalue, asm kept\n"; continue; }
    const bool perm = fold && allB && !ev.empty();
    Value *Lf; int64_t Co; splitOffset(off, Lf, Co);
    if (envOn("LO_LDSM_DUMP", false)) { errs() << "ldsm " << L.CI->getParent()->getName() << (L.trans ? " T " : " N ") << "C=" << Co << " L="; Lf->printAsOperand(errs(), false); if (auto *I = dyn_cast<Instruction>(Lf)) { errs() << " : "; I->print(errs()); } errs() << "\n"; }
    Type *I64 = Type::getInt64Ty(Ctx);
    auto rowLoad = [&](Type *T, Value *row, Value *lanePart, unsigned al, int64_t Cx = 0) {   // @G + sext(shfl(L) + lane part) + C (offsets are < 2^24)
      auto &PB = LN.get(Q.GetInsertBlock()); auto key = std::make_pair(row, lanePart);
      Value *p = nullptr; auto it = PB.rowp.find(key);
      if (it != PB.rowp.end() && it->second->comesBefore(&*Q.GetInsertPoint())) p = it->second;
      else { auto *gp = cast<Instruction>(Q.CreateGEP(I8, G, {Q.CreateSExt(Q.CreateAdd(row, lanePart), I64)})); PB.rowp[key] = gp; p = gp; }
      if (Co + Cx) p = Q.CreateGEP(I8, p, {ConstantInt::get(I64, Co + Cx)});
      return Q.CreateAlignedLoad(T, p, Align(al));
    };
    SmallVector<Value *, 4> res;
    auto kit = kperm.find(L.CI);
    for (int j = 0; j < L.num; ++j) {
      Value *d;
      const bool kp = kit != kperm.end() && kit->second.m0[j] >= 0;
      int m0 = 0, m1 = 0, kq = 0; if (kp) { m0 = kit->second.m0[j]; m1 = kit->second.m1[j]; kq = kit->second.q[j]; }
      if (kp && !L.trans) {
        Value *row = LN.row(Q, Lf, LN.kIdx(L.CI->getParent(), m0, m1, perm ? 1 : 0, 0));
        d = Q.CreateBitCast(rowLoad(F32, row, P.t8, 4, 4 * kq), I32);
      } else if (kp) {
        Value *r0 = LN.row(Q, Lf, LN.kIdx(L.CI->getParent(), m0, m1, 2, 2 * kq)), *r1 = LN.row(Q, Lf, LN.kIdx(L.CI->getParent(), m0, m1, 2, 2 * kq + 1));
        Value *col = perm ? P.colp : P.col;
        Value *lo = rowLoad(I16, r0, col, 2), *hi = rowLoad(I16, r1, col, 2);
        d = Q.CreateOr(Q.CreateZExt(lo, I32), Q.CreateShl(Q.CreateZExt(hi, I32), 16));
      } else if (!L.trans) {
        Value *rowLane = LN.srcIdx(L.CI->getParent(), perm ? 1 : 0, j);
        Value *row = LN.row(Q, Lf, rowLane);
        d = Q.CreateBitCast(rowLoad(F32, row, P.t4, 4), I32);
      } else {
        Value *s0 = LN.srcIdx(L.CI->getParent(), 2, j), *s1 = LN.srcIdx(L.CI->getParent(), 3, j);
        Value *col = perm ? P.colp : P.col;
        Value *r0 = LN.row(Q, Lf, s0), *r1 = LN.row(Q, Lf, s1);
        Value *lo = rowLoad(I16, r0, col, 2), *hi = rowLoad(I16, r1, col, 2);
        d = Q.CreateOr(Q.CreateZExt(lo, I32), Q.CreateShl(Q.CreateZExt(hi, I32), 16));
      }
      res.push_back(d);
      { FragInfo fi{G, Lf, Co, L.trans, perm, j, cast<Instruction>(peel(d))}; if (kp) { fi.m0 = m0; fi.m1 = m1; fi.q = kq; } fragOf[peel(d)] = fi; }
    }
    for (auto *E : ev) {
      unsigned i = E->getIndices()[0];
      E->replaceAllUsesWith(res[i]);
      if (perm) bPermuted.insert(peel(res[i]));
      E->eraseFromParent();
    }
    L.CI->eraseFromParent();
    nDone++; nPerm += perm;
  }
  if (nDone) errs() << "lo-ldsm: " << F.getName().substr(0, 30) << ": " << nDone << " of " << todo.size() << " ldmatrix -> loads, " << nPerm << " with the B lane permutation in the address\n";
}

// ---- mma.sync -> WMMA ---------------------------------------------------------------------------------------------------
struct Op { CallInst *CI; Value *A[4], *B[2]; SmallVector<Value *, 4> C; bool f16, bf16 = false; int kb = 2; Op *prev = nullptr, *next = nullptr; bool used = false; int chainPos = 0; };
struct Group { std::vector<Op *> st[2]; int nn = 1, L = 1; };   // st[u][s]: n-half u, k-step s

static void readOp(CallInst *C, Op &o) {
  o.CI = C; o.f16 = C->getCalledFunction()->getName().ends_with("f16.f16"); o.bf16 = C->getCalledFunction()->getName().ends_with(".bf16"); o.kb = mmaKb(C);
  for (int i = 0; i < 2 * o.kb; ++i) o.A[i] = peel(C->getArgOperand(i));
  for (int i = 0; i < o.kb; ++i) o.B[i] = peel(C->getArgOperand(2 * o.kb + i));
  for (unsigned i = 3 * o.kb; i < C->arg_size(); ++i) o.C.push_back(C->getArgOperand(i));
}
// the op whose whole result feeds y's accumulators (and nothing else), or null
static CallInst *chainPred(Op &y) {
  CallInst *X = nullptr;
  for (unsigned i = 0; i < y.C.size(); ++i) {
    auto *E = dyn_cast<ExtractValueInst>(peel(y.C[i]));
    if (!E || E->getIndices()[0] != i) return nullptr;
    auto *C = dyn_cast<CallInst>(E->getAggregateOperand());
    if (!C || !isMma(C)) return nullptr;
    if (X && X != C) return nullptr;
    X = C;
  }
  if (!X) return nullptr;
  // every result element of X goes to y only (bitcasts allowed)
  std::function<bool(Value *)> only = [&](Value *V) {
    for (User *U : V->users()) {
      if (auto *B = dyn_cast<BitCastInst>(U)) { if (!only(B)) return false; continue; }
      if (U != y.CI) return false;
    }
    return true;
  };
  for (User *U : X->users()) { auto *E = dyn_cast<ExtractValueInst>(U); if (!E || !only(E)) return nullptr; }
  return X;
}


// ---- census (LO_CENSUS=1): every mma of a block with its A / B identity, accumulator source and result users ------------------
static void census(Function &F) {
  std::map<Value *, int> an, bn; int nb = 0;
  for (auto &BB : F) {
    std::vector<CallInst *> ms; for (auto &I : BB) if (auto *C = dyn_cast<CallInst>(&I)) if (isMma(C)) ms.push_back(C);
    if (ms.empty()) continue;
    std::map<CallInst *, int> idx; for (size_t i = 0; i < ms.size(); ++i) idx[ms[i]] = i;
    std::map<std::string, int> as, bs;
    errs() << "block " << nb++ << " " << BB.getName() << " mma=" << ms.size() << " insts=" << BB.size() << "\n";
    for (size_t i = 0; i < ms.size(); ++i) {
      Op o; readOp(ms[i], o);
      std::string ka, kb; raw_string_ostream sa(ka), sb(kb);
      for (int q = 0; q < 2 * o.kb; ++q) sa << (void *)o.A[q] << ","; for (int q = 0; q < o.kb; ++q) sb << (void *)o.B[q] << ",";
      if (!as.count(ka)) { int n = as.size(); as[ka] = n; } if (!bs.count(kb)) { int n = bs.size(); bs[kb] = n; }
      // accumulator sources
      std::string src; raw_string_ostream sc(src); std::set<std::string> ss;
      for (unsigned c = 0; c < o.C.size(); ++c) { Value *V = peel(o.C[c]); std::string t; raw_string_ostream st(t);
        if (auto *E = dyn_cast<ExtractValueInst>(V)) { auto *X = dyn_cast<CallInst>(E->getAggregateOperand()); if (X && idx.count(X)) st << "op" << idx[X]; else if (X && isMma(X)) st << "other-bb-mma"; else st << "ev?"; }
        else if (isa<PHINode>(V)) st << "phi"; else if (isConstZero(V)) st << "0"; else { st << "val:"; st << (isa<Instruction>(V) ? cast<Instruction>(V)->getOpcodeName() : "const"); }
        ss.insert(t); }
      for (auto &t : ss) sc << t << " ";
      // users
      std::map<std::string, int> us; std::function<void(Value *)> walk = [&](Value *V) { for (User *U : V->users()) { if (isa<BitCastInst>(U) || isa<ExtractValueInst>(U)) { walk(U); continue; } std::string t; raw_string_ostream st(t);
        if (auto *X = dyn_cast<CallInst>(U)) { if (idx.count(X)) st << "op" << idx[X]; else st << "call"; } else if (auto *P = dyn_cast<PHINode>(U)) st << "phi@" << (P->getParent() == &BB ? "self" : "next"); else st << cast<Instruction>(U)->getOpcodeName();
        us[t]++; } };
      walk(ms[i]);
      errs() << "  op" << i << " A" << as[ka] << " B" << bs[kb] << " C<-" << src << " ->"; for (auto &kv : us) errs() << " " << kv.first << "x" << kv.second; errs() << (o.f16 ? " f16" : "") << "\n";
    }
  }
}

struct Lower {
  Function &F; Lanes &LN; std::set<Value *> &bPerm; Module *M; LLVMContext &Ctx; Type *I32, *F32, *H16, *V2H;
  FunctionCallee W, Wb; DominatorTree *DTp = nullptr;
  unsigned nW = 0, nOps = 0;
  // f16 accumulators stay f32 values that are exactly f16 (fpext(fptrunc(x))): a packed register -> its two halves as floats
  std::map<Value *, std::pair<Value *, Value *>> wide; std::vector<std::tuple<PHINode *, PHINode *, PHINode *>> widePhis;
  std::vector<Value *> wideKeys;
  Value *unpackHalf(IRBuilder<> &Q, Value *w, int hi) {
    Value *x = hi ? Q.CreateLShr(w, 16) : w;
    return Q.CreateFPExt(Q.CreateBitCast(Q.CreateTrunc(x, Type::getInt16Ty(Ctx)), H16), F32);
  }
  std::pair<Value *, Value *> wideFor(IRBuilder<> &Q, Value *V) {   // V peeled
    auto it = wide.find(V); if (it != wide.end()) return it->second;
    if (auto *P = dyn_cast<PHINode>(V)) {
      PHINode *lo = PHINode::Create(F32, P->getNumIncomingValues(), "lo.acc", P->getIterator()), *hi = PHINode::Create(F32, P->getNumIncomingValues(), "lo.acc", P->getIterator());
      widePhis.push_back({P, lo, hi});
      wideKeys.push_back(V); return wide[V] = {lo, hi};
    }
    Value *w = asI(Q, V);
    return {unpackHalf(Q, w, 0), unpackHalf(Q, w, 1)};
  }
  void finishPhis() {
    for (size_t i = 0; i < widePhis.size(); ++i) {   // widePhis can grow (a phi of a phi)
      auto [P, lo, hi] = widePhis[i];
      for (unsigned k = 0; k < P->getNumIncomingValues(); ++k) {
        BasicBlock *B = P->getIncomingBlock(k); IRBuilder<> Q(B->getTerminator());
        auto pr = wideFor(Q, peel(P->getIncomingValue(k)));
        lo->addIncoming(pr.first, B); hi->addIncoming(pr.second, B);
      }
    }
    // other users of the packed phi: pack the exact halves where they are used
    auto pack = [&](IRBuilder<> &Q, Value *a, Value *b, Type *T) {
      Value *l = Q.CreateBitCast(Q.CreateFPTrunc(a, H16), Type::getInt16Ty(Ctx)), *h = Q.CreateBitCast(Q.CreateFPTrunc(b, H16), Type::getInt16Ty(Ctx));
      Value *w = Q.CreateOr(Q.CreateZExt(l, I32), Q.CreateShl(Q.CreateZExt(h, I32), 16));
      return Q.CreateBitCast(w, T);
    };
    for (auto &t : widePhis) {
      auto [P, lo, hi] = t;
      for (Use &U : make_early_inc_range(P->uses())) {
        auto *I = cast<Instruction>(U.getUser());
        if (auto *Q2 = dyn_cast<PHINode>(I)) { bool isWide = false; for (auto &t2 : widePhis) if (std::get<0>(t2) == Q2) isWide = true; if (isWide) continue;
          IRBuilder<> Q(Q2->getIncomingBlock(U)->getTerminator()); U.set(pack(Q, lo, hi, P->getType())); }
        else { IRBuilder<> Q(I); U.set(pack(Q, lo, hi, P->getType())); }
      }
    }
    for (auto &t : widePhis) { PHINode *P = std::get<0>(t); P->replaceAllUsesWith(PoisonValue::get(P->getType())); }
    for (auto &t : widePhis) { wide.erase(std::get<0>(t)); std::get<0>(t)->eraseFromParent(); }   // p3: the keys must go too, repack below reads them
    // users of a packed result that are not f32 accumulator inputs (the epilogue, after the loop): pack again at the use, so that
    // the loop body keeps only the floats. fptrunc of an f16-exact float is exact.
    std::function<void(Value *, std::pair<Value *, Value *> &)> repack = [&](Value *V, std::pair<Value *, Value *> &pr) {
      for (Use &U : make_early_inc_range(V->uses())) {
        auto *I = cast<Instruction>(U.getUser());
        if (isa<BitCastInst>(I)) { repack(I, pr); continue; }
        if (auto *Ph = dyn_cast<PHINode>(I)) { IRBuilder<> Q(Ph->getIncomingBlock(U)->getTerminator()); U.set(pack(Q, pr.first, pr.second, V->getType())); }
        else { IRBuilder<> Q(I); U.set(pack(Q, pr.first, pr.second, V->getType())); }
      }
    };
    for (Value *k : wideKeys) { auto kv = wide.find(k); if (kv != wide.end() && !isa<PHINode>(k)) repack(k, kv->second); }   // p3: insertion order, not pointer order
  }
  Lower(Function &F_, Lanes &L, std::set<Value *> &bp) : F(F_), LN(L), bPerm(bp), M(F_.getParent()), Ctx(F_.getContext()) {
    I32 = Type::getInt32Ty(Ctx); F32 = Type::getFloatTy(Ctx); H16 = Type::getHalfTy(Ctx); V2H = FixedVectorType::get(H16, 2);
    SmallVector<Type *, 24> pa(24, F32);
    Type *RT = StructType::get(Ctx, SmallVector<Type *, 8>(8, F32));
    W = M->getOrInsertFunction("__lo_wmma", FunctionType::get(RT, pa, false));   // pseudo op, expanded by expandWmma
    if (auto *Fn = dyn_cast<Function>(W.getCallee())) { Fn->addFnAttr(Attribute::Convergent); Fn->setDoesNotAccessMemory(); Fn->setDoesNotThrow(); }
    if (loLaneMode) { Wb = M->getOrInsertFunction("__lo_wmma_bf16", FunctionType::get(RT, pa, false)); if (auto *Fn = dyn_cast<Function>(Wb.getCallee())) { Fn->addFnAttr(Attribute::Convergent); Fn->setDoesNotAccessMemory(); Fn->setDoesNotThrow(); } }
  }
  // load the word again here when the epoch check allowed it (placeFrag): the fragment does not stay live between its ldmatrix and the WMMA.
  // volatile: otherwise GVN merges the loads and the live range is back
  std::set<Value *> remat;
  // lo-mma<lane-eval>: the words of the WMMA just before, at the same place with no epoch end between (emit): a word both read stays in its register
  std::map<Value *, Value *> held, heldNext; Instruction *heldAt = nullptr;
  Value *frag(IRBuilder<> &Q, Value *v) {
    if (!remat.count(v)) return v;
    static const bool reuse = envOn("LO_REUSE", true);
    if (loLaneMode && reuse) { auto it = held.find(v); if (it != held.end()) return heldNext[v] = it->second; }
    Value *r = fragLoad(Q, v);
    if (loLaneMode && reuse) heldNext[v] = r;
    return r;
  }
  Value *fragLoad(IRBuilder<> &Q, Value *v) {
    FragInfo &f = fragOf[v]; BasicBlock *B = Q.GetInsertBlock(); auto &P = LN.get(B); Type *I8 = Type::getInt8Ty(Ctx), *I16 = Type::getInt16Ty(Ctx), *I64 = Type::getInt64Ty(Ctx);
    auto rowLoad = [&](Type *T, Value *row, Value *lanePart, unsigned al, int64_t Cx = 0) {
      Value *p = Q.CreateGEP(I8, f.G, {Q.CreateSExt(Q.CreateAdd(row, lanePart), I64)});
      if (f.C + Cx) p = Q.CreateGEP(I8, p, {ConstantInt::get(I64, f.C + Cx)});
      auto *L = Q.CreateAlignedLoad(T, p, Align(al)); L->setVolatile(true); return L; };
    if (f.m0 >= 0 && !f.trans) return rowLoad(F32, LN.row(Q, f.L, LN.kIdx(B, f.m0, f.m1, f.perm ? 1 : 0, 0)), P.t8, 4, 4 * f.q);
    if (f.m0 >= 0) {
      Value *r0 = LN.row(Q, f.L, LN.kIdx(B, f.m0, f.m1, 2, 2 * f.q)), *r1 = LN.row(Q, f.L, LN.kIdx(B, f.m0, f.m1, 2, 2 * f.q + 1)); Value *col = f.perm ? P.colp : P.col;
      Value *lo = rowLoad(I16, r0, col, 2), *hi = rowLoad(I16, r1, col, 2);
      return Q.CreateOr(Q.CreateZExt(lo, I32), Q.CreateShl(Q.CreateZExt(hi, I32), 16));
    }
    if (!f.trans) return rowLoad(F32, LN.row(Q, f.L, LN.srcIdx(B, f.perm ? 1 : 0, f.j)), P.t4, 4);
    Value *r0 = LN.row(Q, f.L, LN.srcIdx(B, 2, f.j)), *r1 = LN.row(Q, f.L, LN.srcIdx(B, 3, f.j)); Value *col = f.perm ? P.colp : P.col;
    Value *lo = rowLoad(I16, r0, col, 2), *hi = rowLoad(I16, r1, col, 2);
    return Q.CreateOr(Q.CreateZExt(lo, I32), Q.CreateShl(Q.CreateZExt(hi, I32), 16));
  }
  Value *asF(IRBuilder<> &Q, Value *V) { return V->getType() == F32 ? V : Q.CreateBitCast(V, F32); }
  Value *asI(IRBuilder<> &Q, Value *V) { return V->getType() == I32 ? V : Q.CreateBitCast(V, I32); }
  // one WMMA: st[u][s] for k-steps [s0, s0+L); acc[u] = the 4 f32 accumulators of n-half u (null: zero) -> out[u]
  void wmma(IRBuilder<> &Q, Group &G, int s0, int L, Value *acc[2][4], Value *out[2][4]) {
    Value *zero = ConstantFP::get(F32, 0.0);
    auto &P = LN.get(Q.GetInsertBlock());
    Value *av[8], *bv[8];
    for (int i = 0; i < 8; ++i) av[i] = bv[i] = zero;
    int j = -1;   // k-block
    for (int s = 0; s < L; ++s) for (int q = 0; q < G.st[0][s0 + s]->kb; ++q) {
      ++j;
      Op *o = G.st[0][s0 + s];
      av[j] = asF(Q, frag(Q, o->A[2 * q])); av[4 + j] = asF(Q, frag(Q, o->A[2 * q + 1]));
      for (int u = 0; u < G.nn; ++u) {
        Value *b = G.st[u][s0 + s]->B[q];
        if (bPerm.count(b)) bv[2 * j + u] = asF(Q, frag(Q, b));
        else if (isConstZero(b)) bv[2 * j + u] = zero;
        else bv[2 * j + u] = asF(Q, LN.shfl(Q, asI(Q, b), P.bsrc));
      }
    }
    Value *cv[8];
    for (int i = 0; i < 8; ++i) cv[i] = zero;
    for (int u = 0; u < G.nn; ++u) if (acc[u][0]) {
      cv[2 * u] = acc[u][0]; cv[2 * u + 1] = acc[u][1]; cv[4 + 2 * u] = acc[u][2]; cv[5 + 2 * u] = acc[u][3];
    }
    SmallVector<Value *, 24> args; for (int i = 0; i < 8; ++i) args.push_back(av[i]); for (int i = 0; i < 8; ++i) args.push_back(bv[i]); for (int i = 0; i < 8; ++i) args.push_back(cv[i]);
    auto *C = Q.CreateCall(G.st[0][s0]->bf16 ? Wb : W, args, "lo.w"); C->addFnAttr(Attribute::Convergent);
    for (int u = 0; u < G.nn; ++u) {
      out[u][0] = Q.CreateExtractValue(C, 2 * u); out[u][1] = Q.CreateExtractValue(C, 2 * u + 1);
      out[u][2] = Q.CreateExtractValue(C, 4 + 2 * u); out[u][3] = Q.CreateExtractValue(C, 5 + 2 * u);
    }
    nW++;
  }
  // accumulators of op o as 4 floats; f16 accumulators: unpack with fpext (exact)
  void accIn(IRBuilder<> &Q, Op *o, Value *acc[4]) {
    bool zero = true;
    for (Value *c : o->C) if (!isConstZero(c)) zero = false;
    if (zero) { for (int i = 0; i < 4; ++i) acc[i] = nullptr; return; }
    if (!o->f16) { for (int i = 0; i < 4; ++i) acc[i] = asF(Q, o->C[i]); return; }   // o->C refreshed by emit()
    for (int r = 0; r < 2; ++r) { auto pr = wideFor(Q, peel(o->C[r])); acc[2 * r] = pr.first; acc[2 * r + 1] = pr.second; }
  }
  // result of op o: replaces its call. f32: {d0..d3}; f16: 2 x <2 x half> packed by fptrunc (RNE)
  void finish(IRBuilder<> &Q, Op *o, Value *d[4]) {
    auto *RT = cast<StructType>(o->CI->getType()); Value *el[4] = {};
    if (!o->f16) { for (unsigned i = 0; i < 4; ++i) el[i] = Q.CreateBitCast(d[i], RT->getElementType(i)); }
    else for (unsigned r = 0; r < 2; ++r) {
      // scalar fptruncs (lo-f16 turns them into the fast path): low half = d[2r], high half = d[2r+1]
      Value *tl = Q.CreateFPTrunc(d[2 * r], H16), *th = Q.CreateFPTrunc(d[2 * r + 1], H16);
      Value *lo = Q.CreateBitCast(tl, Type::getInt16Ty(Ctx)), *hi = Q.CreateBitCast(th, Type::getInt16Ty(Ctx));
      Value *w = Q.CreateOr(Q.CreateZExt(lo, I32), Q.CreateShl(Q.CreateZExt(hi, I32), 16));
      static const int f16Acc = envInt("LO_F16_ACC", 0);
      if (f16Acc >= 2) wide[w] = {d[2 * r], d[2 * r + 1]};            // option: the loop-carried value stays f32, the only rounding is at the epilogue
      else wide[w] = {Q.CreateFPExt(tl, F32), Q.CreateFPExt(th, F32)};
      wideKeys.push_back(w);
      el[r] = Q.CreateBitCast(w, RT->getElementType(r));
    }
    // the group may sit later than this op: uses of its extractvalues (all after the group, checked by placeGroups) take the values directly;
    // bitcasts of them are free and may sit before the group: they move to the group
    Instruction *at = &*Q.GetInsertPoint();
    for (User *U : make_early_inc_range(o->CI->users())) {
      auto *E = cast<ExtractValueInst>(U);
      std::vector<Instruction *> bc; std::function<void(Value *)> walk = [&](Value *V) { for (User *W : V->users()) if (auto *B = dyn_cast<BitCastInst>(W)) { bc.push_back(B); walk(B); } };
      walk(E);
      E->replaceAllUsesWith(el[E->getIndices()[0]]); E->eraseFromParent();
      for (Instruction *B : bc) if (B->getParent() == at->getParent() ? B->comesBefore(at) : !DTp->dominates(at->getParent(), B->getParent())) B->moveBefore(at);
    }
  }
  void emit(Group &G, Instruction *at) {
    IRBuilder<> Q(at);
    if (at != heldAt) heldNext.clear();
    held.swap(heldNext); heldNext.clear(); heldAt = at;
    for (int u = 0; u < G.nn; ++u) for (Op *o : G.st[u]) { o->C.clear(); readOp(o->CI, *o); }
    Value *acc[2][4] = {}, *out[2][4] = {};
    for (int u = 0; u < G.nn; ++u) accIn(Q, G.st[u][0], acc[u]);
    wmma(Q, G, 0, G.L, acc, out);   // a group is at most one k32 and two n-halves
    for (int u = 0; u < G.nn; ++u) finish(Q, G.st[u][G.L - 1], out[u]);
    for (int u = 0; u < G.nn; ++u) for (Op *o : G.st[u]) nOps++;
  }
};

// ---- grouping across blocks ------------------------------------------------------------------------------------------------
// The k-steps of one accumulator chain are often in different blocks: the lift turns predicated cp.async, spin waits and barriers into
// branches, and they cut the body of the main loop. mma only reads registers (no memory), so it can move down to a later block when
//   X dominates Y, Y post-dominates X and both are in the same innermost loop: Y runs exactly once for every run of X, and with all the lanes
// that ran X (they are reconverged at the post-dominator). Groups are placed at their latest member; dependent groups never before their source.
static bool regionOK(BasicBlock *X, BasicBlock *Y, DominatorTree &DT, PostDominatorTree &PDT, LoopInfo &LI) {
  if (X == Y) return true;
  static const bool xb = envOn("LO_MMA_XBLOCK", true);
  return xb && DT.dominates(X, Y) && PDT.dominates(Y, X) && LI.getLoopFor(X) == LI.getLoopFor(Y);
}
// later of two instructions on one dominance path, or null when neither block dominates the other
static Instruction *laterOf(Instruction *a, Instruction *b, DominatorTree &DT) {
  if (a == b) return a;
  if (a->getParent() == b->getParent()) return a->comesBefore(b) ? b : a;
  if (DT.dominates(a->getParent(), b->getParent())) return b;
  if (DT.dominates(b->getParent(), a->getParent())) return a;
  return nullptr;
}
static Instruction *lastOf(Group &G, DominatorTree &DT) {
  Instruction *L = nullptr;
  for (int u = 0; u < G.nn; ++u) for (Op *o : G.st[u]) { L = L ? laterOf(L, o->CI, DT) : o->CI; if (!L) return nullptr; }
  return L;
}
// is the use U of a value dominated by "just before P" ?
static bool afterP(Use &U, Instruction *P, DominatorTree &DT) {
  auto *I = cast<Instruction>(U.getUser());
  if (auto *Ph = dyn_cast<PHINode>(I)) { BasicBlock *B = Ph->getIncomingBlock(U); return B == P->getParent() || DT.dominates(P->getParent(), B); }
  if (I->getParent() == P->getParent()) return I == P || P->comesBefore(I);
  return DT.dominates(P->getParent(), I->getParent());
}
struct Place { std::vector<int> order; std::vector<Instruction *> P; std::vector<char> bad; };
// dependence order and insertion points of the groups; bad[i]: group i cannot be placed (its caller splits it)
static Place placeGroups(std::vector<Group> &gs, DenseMap<CallInst *, Op *> &byCall, DominatorTree &DT, PostDominatorTree &PDT, LoopInfo &LI, std::map<Op *, Instruction *> *at = nullptr) {
  const int n = gs.size(); Place R; R.P.assign(n, nullptr); R.bad.assign(n, 0);
  std::map<Op *, int> gof; for (int i = 0; i < n; ++i) for (int u = 0; u < gs[i].nn; ++u) for (Op *o : gs[i].st[u]) gof[o] = i;
  std::vector<std::set<int>> dep(n), sub(n);
  auto srcOf = [&](Value *V) -> int { V = peel(V); auto *E = dyn_cast<ExtractValueInst>(V); if (!E) return -1; auto *C = dyn_cast<CallInst>(E->getAggregateOperand()); if (!C) return -1; auto it = byCall.find(C); return it == byCall.end() ? -1 : gof[it->second]; };
  for (int i = 0; i < n; ++i) for (int u = 0; u < gs[i].nn; ++u) for (Op *o : gs[i].st[u]) for (Value *V : o->CI->args()) { int h = srcOf(V); if (h >= 0 && h != i) { dep[i].insert(h); sub[h].insert(i); } }
  std::vector<int> nd(n); std::vector<Instruction *> own(n);
  for (int i = 0; i < n; ++i) { nd[i] = dep[i].size(); own[i] = lastOf(gs[i], DT); if (at) { auto it = at->find(gs[i].st[0][0]); if (it != at->end()) own[i] = it->second; } if (!own[i]) R.bad[i] = 1; }
  std::vector<int> ready; for (int i = 0; i < n; ++i) if (!nd[i]) ready.push_back(i);
  std::vector<char> done(n, 0);
  while (!ready.empty()) {
    int b = 0;   // earliest first: dominance order, then position; at the same position the next step of the chain just placed (the accumulators stay in the WMMA registers)
    for (size_t k = 1; k < ready.size(); ++k) { Instruction *x = own[ready[k]], *y = own[ready[b]]; if (x && y && laterOf(x, y, DT) == y && x != y) b = k; }
    if (!R.order.empty()) for (size_t k = 0; k < ready.size(); ++k) if (dep[ready[k]].count(R.order.back()) && own[ready[k]] == own[ready[b]]) { b = k; break; }
    int i = ready[b]; ready.erase(ready.begin() + b); done[i] = 1; R.order.push_back(i);
    Instruction *P = own[i];
    for (int h : dep[i]) { if (!P || !R.P[h]) { P = nullptr; break; } P = laterOf(P, R.P[h], DT); if (!P) break; }
    R.P[i] = P; if (!P) R.bad[i] = 1;
    for (int s : sub[i]) if (--nd[s] == 0) ready.push_back(s);
  }
  for (int i = 0; i < n; ++i) if (!done[i]) R.bad[i] = 1;   // a cycle
  for (int i : R.order) {
    Instruction *P = R.P[i]; if (R.bad[i]) continue;
    Group &G = gs[i];
    for (int u = 0; u < G.nn; ++u) for (Op *o : G.st[u]) {
      if (!regionOK(o->CI->getParent(), P->getParent(), DT, PDT, LI) && !regionOK(P->getParent(), o->CI->getParent(), DT, PDT, LI)) R.bad[i] = 1;
      std::function<void(Value *)> walk = [&](Value *V) {
        for (Use &U : V->uses()) {
          auto *I = cast<Instruction>(U.getUser());
          if (isa<BitCastInst>(I) || isa<ExtractValueInst>(I)) { walk(I); continue; }
          if (auto *C = dyn_cast<CallInst>(I)) if (byCall.count(C)) continue;   // an mma: its group comes later (or this one)
          if (!afterP(U, P, DT)) R.bad[i] = 1;
        }
      };
      walk(o->CI);
    }
  }
  return R;
}

// ---- fragment direct path ---------------------------------------------------------------------------------------------------
// A WMMA can read its operand words from LMEM right before it, instead of keeping them from the ldmatrix on (they spill: 32 accumulators + 24 pinned
// registers leave no room). Allowed when nothing can change the words between the two points. Epoch = stretch without a block barrier, mbarrier,
// unknown call or asm, or plain store that may reach shared memory. Inside an epoch a race-free program has no writer of words other warps read; cp.async
// is asynchronous, so a cp.async of the same thread to words it is reading in the same epoch would be a race too. cp.async, cp.async commit/wait and warp syncs do not end it.
static bool endsEpoch(Instruction *I) {
  if (auto *S = dyn_cast<StoreInst>(I)) { Value *U = getUnderlyingObject(S->getPointerOperand()); return !isa<AllocaInst>(U) && S->getPointerAddressSpace() != 1; }
  if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I)) return true;
  auto *C = dyn_cast<CallInst>(I); if (!C) return false;
  if (auto *IA = dyn_cast<InlineAsm>(C->getCalledOperand())) { StringRef a = IA->getAsmString(); return !(a.starts_with("cp.async.c") || a.starts_with("cp.async.w") || a.starts_with("ldmatrix.sync") || a.starts_with("activemask")); }
  Function *F = C->getCalledFunction(); if (!F) return true;
  StringRef n = F->getName();
  if (n.starts_with("llvm.nvvm.mma.") || n == "__lo_wmma" || n == "__lo_wmma_bf16" || n.starts_with("llvm.nvvm.shfl.sync") || n.starts_with("llvm.nvvm.read.ptx.sreg") || n.starts_with("llvm.nvvm.bar.warp.sync") || n.starts_with("llvm.nvvm.ex2") ||
      n.starts_with("llvm.fma") || n.starts_with("llvm.maxnum") || n.starts_with("llvm.minnum") || n.starts_with("llvm.abs") || n.starts_with("llvm.lifetime") || n.starts_with("llvm.umin") || n.starts_with("llvm.umax") || n.starts_with("llvm.smin") || n.starts_with("llvm.smax") || n.starts_with("llvm.fshl") || n.starts_with("llvm.fshr")) return false;
  return true;
}
// no epoch end on any path from a (exclusive) to b (exclusive); a's block dominates b's block
static bool epochClear(Instruction *a, Instruction *b) {
  BasicBlock *A = a->getParent(), *B = b->getParent();
  if (A == B && a->comesBefore(b)) { for (Instruction *I = a->getNextNode(); I != b; I = I->getNextNode()) if (endsEpoch(I)) return false; return true; }
  for (Instruction *I = a->getNextNode(); I; I = I->getNextNode()) if (endsEpoch(I)) return false;
  for (Instruction *I = &B->front(); I != b; I = I->getNextNode()) if (endsEpoch(I)) return false;
  std::set<BasicBlock *> seen{A, B}; std::vector<BasicBlock *> w(pred_begin(B), pred_end(B));
  while (!w.empty()) { BasicBlock *X = w.back(); w.pop_back(); if (!seen.insert(X).second) continue;
    for (auto &I : *X) if (endsEpoch(&I)) return false;
    for (BasicBlock *Pd : predecessors(X)) w.push_back(Pd); }
  return true;
}
// first epoch end after `from` on the post-dominator path inside the loop; else the end of the last block reached
static Instruction *epochEnd(Instruction *from, DominatorTree &DT, PostDominatorTree &PDT, LoopInfo &LI) {
  BasicBlock *B = from->getParent(); Loop *L0 = LI.getLoopFor(B); Instruction *I = from->getNextNode();
  for (;;) {
    for (; I; I = I->getNextNode()) if (endsEpoch(I)) return I;
    auto *n = PDT.getNode(B); n = n ? n->getIDom() : nullptr;
    BasicBlock *N = n ? n->getBlock() : nullptr;
    if (!N || !DT.dominates(B, N) || LI.getLoopFor(N) != L0 || !epochClear(B->getTerminator(), &*N->getFirstInsertionPt())) return B->getTerminator();
    B = N; I = &B->front();
  }
}

// Groups placed at one point: the next one is a group whose chain predecessor is done, first the next step of the chain just emitted (its accumulators stay in the WMMA registers), then the one with
// the most operand words in common with it (a snake through the tiles reads each fragment once instead of once per WMMA).
static void orderForReuse(std::vector<Group> &gs, Place &R) {
  std::vector<int> out; std::map<Op *, int> gof;
  for (int i : R.order) for (int u = 0; u < gs[i].nn; ++u) for (Op *o : gs[i].st[u]) gof[o] = i;
  auto words = [&](int i) { std::set<Value *> w; Group &g = gs[i]; for (int u = 0; u < g.nn; ++u) for (Op *o : g.st[u]) { for (int k = 0; k < 2 * o->kb; ++k) w.insert(o->A[k]); for (int k = 0; k < o->kb; ++k) w.insert(o->B[k]); } return w; };
  for (size_t a = 0; a < R.order.size();) {
    size_t b = a; while (b < R.order.size() && R.P[R.order[b]] == R.P[R.order[a]]) ++b;
    std::vector<int> left(R.order.begin() + a, R.order.begin() + b); std::set<int> done; int last = -1;
    auto ready = [&](int i) { Group &g = gs[i]; for (int u = 0; u < g.nn; ++u) for (Op *o : g.st[u]) if (o->prev && gof.count(o->prev) && gof[o->prev] != i && std::find(left.begin(), left.end(), gof[o->prev]) != left.end()) return false; return true; };
    while (!left.empty()) {
      int best = -1, bs = -1;
      for (int i : left) { if (!ready(i)) continue; int sc = 0;
        if (last >= 0) { Group &g = gs[i]; bool chain = false; for (int u = 0; u < g.nn; ++u) for (Op *o : g.st[u]) if (o->prev && gof.count(o->prev) && gof[o->prev] == last) chain = true;
          auto w = words(i), l = words(last); for (Value *v : w) sc += l.count(v); if (chain) sc += 1000; }
        if (sc > bs) { bs = sc; best = i; } }
      if (best < 0) best = left[0];
      left.erase(std::find(left.begin(), left.end(), best)); out.push_back(best); last = best;
    }
    a = b;
  }
  R.order = out;
}

static void lowerMma(Function &F, Lanes &LN, std::set<Value *> &bPerm) {
  Lower Lw(F, LN, bPerm);
  const bool doN = envOn("LO_MMA_N", true), doK = envOn("LO_MMA_K", true); const int f16Acc = envInt("LO_F16_ACC", 0);
  DominatorTree DT(F); PostDominatorTree PDT(F); LoopInfo LI(DT); Lw.DTp = &DT;
  std::vector<std::unique_ptr<Op>> ops; DenseMap<CallInst *, Op *> byCall;
  for (auto &BB : F) for (auto &I : BB) if (auto *C = dyn_cast<CallInst>(&I)) if (isMma(C)) { auto o = std::make_unique<Op>(); readOp(C, *o); byCall[C] = o.get(); ops.push_back(std::move(o)); }
  unsigned total = ops.size(), groups = 0;
  if (!total) return;
  std::map<int, unsigned> shapes;
  for (auto &o : ops) if (CallInst *X = chainPred(*o)) if (byCall.count(X) && regionOK(X->getParent(), o->CI->getParent(), DT, PDT, LI)) { Op *p = byCall[X]; if (!p->next && p->kb == o->kb && p->f16 == o->f16) { o->prev = p; p->next = o.get(); } }
  // k-groups along chains: up to 4 k-blocks of 8 (f16 accumulators keep their per-step rounding unless the option asks otherwise)
  std::vector<Group> kg;
  for (auto &o : ops) {
    if (o->prev) continue;
    std::vector<Op *> chain; for (Op *p = o.get(); p; p = p->next) chain.push_back(p);
    if ((o->f16 && !f16Acc) || !doK) { for (Op *p : chain) { Group g; g.st[0] = {p}; g.L = 1; kg.push_back(g); } continue; }
    int unit = 4 / o->kb;
    for (size_t i = 0; i < chain.size(); i += unit) { Group g; for (size_t j = i; j < std::min(chain.size(), i + unit); ++j) g.st[0].push_back(chain[j]); g.L = g.st[0].size(); kg.push_back(g); }
  }
  // n-pairs: same A in every step, same length
  std::vector<Group> gs; std::vector<char> taken(kg.size(), 0);
  auto sameA = [](Group &a, Group &b) {
    if (a.L != b.L) return false;
    for (int s = 0; s < a.L; ++s) { if (a.st[0][s]->kb != b.st[0][s]->kb) return false; for (int i = 0; i < 2 * a.st[0][s]->kb; ++i) if (a.st[0][s]->A[i] != b.st[0][s]->A[i]) return false; }
    return true;
  };
  for (size_t i = 0; i < kg.size(); ++i) {
    if (taken[i]) continue;
    taken[i] = 1; Group g = kg[i];
    if (doN) for (size_t j = i + 1; j < kg.size(); ++j) if (!taken[j] && sameA(g, kg[j])) {
      Group t = g; t.nn = 2; t.st[1] = kg[j].st[0];
      if (t.st[1][0]->prev == t.st[0].back() || t.st[0][0]->prev == t.st[1].back()) continue;
      Instruction *P = lastOf(t, DT); if (!P) continue;
      bool ok = true; for (int u = 0; u < 2; ++u) for (Op *o : t.st[u]) if (!regionOK(o->CI->getParent(), P->getParent(), DT, PDT, LI)) ok = false;
      if (!ok) continue;
      g = t; taken[j] = 1; break;
    }
    gs.push_back(g);
  }
  // place; a group that cannot be placed is split (n-pair, then k-steps, then its sources), which ends at the original program
  Place R; unsigned splits = 0;
  for (;;) {
    R = placeGroups(gs, byCall, DT, PDT, LI);
    bool any = false; std::vector<Group> ng; std::vector<char> splitAll(gs.size(), 0);
    for (size_t i = 0; i < gs.size(); ++i) if (R.bad[i]) any = true;
    if (!any) break;
    for (size_t i = 0; i < gs.size(); ++i) {
      Group &g = gs[i];
      if (!R.bad[i]) { ng.push_back(g); continue; }
      splits++;
      if (g.nn == 2) { Group a, b; a.st[0] = g.st[0]; b.st[0] = g.st[1]; a.L = b.L = g.L; ng.push_back(a); ng.push_back(b); }
      else if (g.L > 1) for (Op *o : g.st[0]) { Group a; a.st[0] = {o}; ng.push_back(a); }
      else {   // a single op that must wait for a later source: split the sources
        ng.push_back(g);
        Op *h = g.st[0][0]; for (Value *V : h->CI->args()) { auto *E = dyn_cast<ExtractValueInst>(peel(V)); if (!E) continue; auto *C = dyn_cast<CallInst>(E->getAggregateOperand()); if (C && byCall.count(C)) for (size_t k = 0; k < gs.size(); ++k) if (k != i && (gs[k].nn > 1 || gs[k].L > 1)) for (int u = 0; u < gs[k].nn; ++u) for (Op *o : gs[k].st[u]) if (o->CI == C) splitAll[k] = 1; }
      }
    }
    if (std::find(splitAll.begin(), splitAll.end(), 1) != splitAll.end()) {
      std::vector<Group> mg; std::set<Op *> tosplit;
      for (size_t k = 0; k < gs.size(); ++k) if (splitAll[k]) for (int u = 0; u < gs[k].nn; ++u) for (Op *o : gs[k].st[u]) tosplit.insert(o);
      for (Group &g : ng) { bool sp = false; for (int u = 0; u < g.nn; ++u) for (Op *o : g.st[u]) if (tosplit.count(o)) sp = true;
        if (!sp) { mg.push_back(g); continue; }
        for (int u = 0; u < g.nn; ++u) for (Op *o : g.st[u]) { Group a; a.st[0] = {o}; mg.push_back(a); } }
      ng = mg;
    }
    gs = ng;
  }
  // fragment direct path: move a group to the end of the epoch of its operands when all its fragment words can be read there
  unsigned moved = 0, words = 0;
  if (envOn("LO_FRAG", true)) {
    std::map<Op *, Instruction *> at; std::map<Op *, std::vector<Value *>> ws;
    auto args = [&](Group &g, std::function<void(Value *)> f) { for (int u = 0; u < g.nn; ++u) for (Op *o : g.st[u]) { for (int i = 0; i < 2 * o->kb; ++i) f(o->A[i]); for (int i = 0; i < o->kb; ++i) f(o->B[i]); } };
    for (Group &g : gs) {
      for (int u = 0; u < g.nn; ++u) for (Op *o : g.st[u]) { o->C.clear(); readOp(o->CI, *o); }
      Instruction *E = nullptr; bool ok = true;
      args(g, [&](Value *v) { auto *I = dyn_cast<Instruction>(v); if (!I) return; if (isa<CallInst>(I) && false) return; E = E ? laterOf(E, I, DT) : I; if (!E) ok = false; });
      if (!ok || !E) continue;
      Instruction *S = epochEnd(E, DT, PDT, LI);
      if (isa<PHINode>(S)) continue;
      std::vector<Value *> v; bool all = true; std::set<Value *> seen;
      static const bool fragTrans = envOn("LO_FRAG_TRANS", loLaneMode);   // a .trans word is two 16-bit loads: it stays where it is
      args(g, [&](Value *x) { if (!seen.insert(x).second) return; auto it = fragOf.find(x); if (it == fragOf.end()) return;
        if (!DT.dominates(it->second.at, S) || !epochClear(it->second.at, S)) all = false; if (fragTrans || !it->second.trans) v.push_back(x); });
      if (!all || v.empty()) continue;
      at[g.st[0][0]] = S; ws[g.st[0][0]] = v;
    }
    for (;;) {
      Place R2 = placeGroups(gs, byCall, DT, PDT, LI, &at);
      bool any = false; for (size_t i = 0; i < gs.size(); ++i) if (R2.bad[i] && at.count(gs[i].st[0][0])) { at.erase(gs[i].st[0][0]); any = true; }
      if (any) continue;
      bool bad = false; for (char c : R2.bad) bad |= c;
      if (bad) { at.clear(); continue; }   // a group without a move became illegal: keep the first placement
      R = R2; break;
    }
    for (auto &kv : at) { moved++; for (Value *v : ws[kv.first]) { Lw.remat.insert(v); words++; } }
  }
  if (loLaneMode && envOn("LO_REUSE", true)) orderForReuse(gs, R);
  for (int i : R.order) { Group &g = gs[i]; Lw.emit(g, R.P[i]); groups++; int kbs = 0; for (Op *o : g.st[0]) kbs += o->kb; shapes[g.nn * 100 + kbs]++; }
  for (Group &g : gs) for (int u = 0; u < g.nn; ++u) for (int s = (int)g.st[u].size() - 1; s >= 0; --s) {
    Op *o = g.st[u][s];
    if (!o->CI->use_empty()) {   // chain interior: its extractvalues now feed nothing live
      for (User *U : make_early_inc_range(o->CI->users())) if (auto *I = dyn_cast<Instruction>(U)) { I->replaceAllUsesWith(PoisonValue::get(I->getType())); I->eraseFromParent(); }
    }
    o->CI->eraseFromParent();
  }
  Lw.finishPhis();
  errs() << "lo-mma: " << F.getName().substr(0, 30) << ": " << total << " mma -> " << groups << " groups, " << Lw.nW << " WMMA (" << splits << " splits, " << moved << " groups to the epoch end, " << words << " fragment words read there);";
  for (auto &kv : shapes) errs() << " n" << kv.first / 100 << "kb" << kv.first % 100 << "=" << kv.second;
  errs() << "\n";
}


// ---- f32 -> f16 fast path ---------------------------------------------------------------------------------------------
// fptrunc float->half is a software call on Vortex (no Zfhmin: __truncsfhf2, ~40 instructions + the caller-saved spills).
// A run of N fptruncs in one block shares one range test; inside the window (|x| in [2^-14, 65520); for exp2 results x in [2^-14, 4):
// a negative value then just takes the real path) the result is a normal f16 and exact integer RNE gives the same bits as
// fptrunc; any lane with a value outside the window takes the real fptrunc for the whole run.
//   a = |x| bits; h = (a + 0xC8000FFF + ((a >> 13) & 1)) >> 13     (0xC8000000 = (15 - 127) << 23)
// Checked against all 2^32 inputs (tools/f16check.c). Pure users (bitcast, zext, shl, or) of the results move after the join.
static bool purePack(Instruction *I) { return isa<BitCastInst>(I) || isa<FPExtInst>(I) || isa<ZExtInst>(I) || (I->getOpcode() == Instruction::Shl) || (I->getOpcode() == Instruction::Or) || (I->getOpcode() == Instruction::And); }
static void pureClosure(Instruction *F, BasicBlock *BB, std::vector<Instruction *> &pure, Instruction *&firstHard) {
  std::vector<Instruction *> work{F}; std::set<Instruction *> seen;
  while (!work.empty()) {
    Instruction *I = work.back(); work.pop_back();
    for (User *U : I->users()) {
      auto *J = cast<Instruction>(U);
      if (J->getParent() != BB || isa<PHINode>(J)) continue;
      if (!seen.insert(J).second) continue;
      if (purePack(J)) { pure.push_back(J); work.push_back(J); }
      else if (!firstHard || J->comesBefore(firstHard)) firstHard = J;
    }
  }
}
static bool expLike(Value *V) {
  auto *C = dyn_cast<CallInst>(peel(V));
  if (!C || !C->getCalledFunction()) return false;
  StringRef n = C->getCalledFunction()->getName();
  return n.starts_with("llvm.nvvm.ex2.approx") || n.starts_with("llvm.exp2");
}
// helpers, inlined by run_trial's always-inline step: @lo.cvt.<family><n>(float x n)
//   family e: exp2 results (x itself in [2^-14, 4), two ops per value for the test); a: any value (|x| in [2^-14, 65520)); both return {i32 x n} = zext(f16 bits)
//   family r: f16 accumulators kept as floats: fpext(fptrunc(x)) as float (same window as a)
// zero (lo-f16, name lo.cvt.<family><n>z): +0 and -0 are inside the window, so a warp with exact zeros stays on the fast path. Family a and e: one select in the test (t = 0 for x = 0) and one
// in the result; both are a czero on Zicond, no branch. Family r needs none in the result: a = 0 gives 0 and the sign goes back on. Family e tests the value with its sign: -0 stays outside.
static Function *getCvt(Module *M, char fam, unsigned n, bool zero = false) {
  std::string name = std::string("lo.cvt.") + fam + std::to_string(n) + (zero ? "z" : "");
  if (Function *F = M->getFunction(name)) return F;
  LLVMContext &Ctx = M->getContext(); Type *I32 = Type::getInt32Ty(Ctx), *F32 = Type::getFloatTy(Ctx), *H = Type::getHalfTy(Ctx), *I16 = Type::getInt16Ty(Ctx);
  Type *RE = fam == 'r' ? F32 : I32;
  auto *RT = StructType::get(Ctx, SmallVector<Type *, 8>(n, RE));
  auto *F = Function::Create(FunctionType::get(RT, SmallVector<Type *, 8>(n, F32), false), GlobalValue::InternalLinkage, name, M);
  F->addFnAttr(Attribute::AlwaysInline);
  BasicBlock *E = BasicBlock::Create(Ctx, "entry", F), *Fa = BasicBlock::Create(Ctx, "fast", F), *Sl = BasicBlock::Create(Ctx, "slow", F), *J = BasicBlock::Create(Ctx, "join", F);
  IRBuilder<> Q(E), QF(Fa), QS(Sl), QJ(J);
  std::vector<Value *> us(n), a(n); Value *acc = nullptr, *ok = nullptr;
  for (unsigned i = 0; i < n; ++i) {
    us[i] = Q.CreateBitCast(F->getArg(i), I32); a[i] = fam == 'e' ? us[i] : Q.CreateAnd(us[i], 0x7fffffff);
    Value *t = Q.CreateSub(a[i], ConstantInt::get(I32, 0x38800000));
    if (zero) t = Q.CreateSelect(Q.CreateICmpEQ(a[i], ConstantInt::get(I32, 0)), ConstantInt::get(I32, 0), t);
    if (fam == 'e') acc = acc ? Q.CreateOr(acc, t) : t;
    else { Value *c = Q.CreateICmpULT(t, ConstantInt::get(I32, 0x0EFFF000)); ok = ok ? Q.CreateAnd(ok, c) : c; }
  }
  if (fam == 'e') ok = Q.CreateICmpULT(acc, ConstantInt::get(I32, 0x08000000));
  Q.CreateCondBr(ok, Fa, Sl);
  Value *R = PoisonValue::get(RT); std::vector<PHINode *> ph(n);
  for (unsigned i = 0; i < n; ++i) {
    Value *m = QF.CreateAnd(QF.CreateLShr(a[i], 13), 1), *fv, *sv;
    Value *S = QS.CreateFPTrunc(F->getArg(i), H);
    if (fam == 'r') {
      Value *r = QF.CreateAnd(QF.CreateAdd(QF.CreateAdd(a[i], ConstantInt::get(I32, 0xFFF)), m), ConstantInt::get(I32, 0xFFFFE000u));
      r = QF.CreateOr(r, QF.CreateAnd(us[i], ConstantInt::get(I32, 0x80000000u)));
      fv = QF.CreateBitCast(r, F32); sv = QS.CreateFPExt(S, F32);
    } else {
      Value *h = QF.CreateLShr(QF.CreateAdd(QF.CreateAdd(a[i], ConstantInt::get(I32, 0xC8000FFFu)), m), 13);
      if (zero) h = QF.CreateSelect(QF.CreateICmpEQ(a[i], ConstantInt::get(I32, 0)), ConstantInt::get(I32, 0), h);
      fv = fam == 'e' ? h : QF.CreateOr(h, QF.CreateAnd(QF.CreateLShr(us[i], 16), 0x8000));
      sv = QS.CreateZExt(QS.CreateBitCast(S, I16), I32);
    }
    ph[i] = QJ.CreatePHI(RE, 2); ph[i]->addIncoming(fv, Fa); ph[i]->addIncoming(sv, Sl);
  }
  QF.CreateBr(J); QS.CreateBr(J);
  for (unsigned i = 0; i < n; ++i) R = QJ.CreateInsertValue(R, ph[i], i);
  QJ.CreateRet(R);
  return F;
}
void loLowerF16(Function &F, bool zero) {
  const unsigned N = envInt("LO_F16_N", 4);
  LLVMContext &Ctx = F.getContext(); Type *I32 = Type::getInt32Ty(Ctx), *I16 = Type::getInt16Ty(Ctx), *H = Type::getHalfTy(Ctx);
  unsigned total = 0, groups = 0;
  for (BasicBlock &BB : F) {
    if (BB.getParent() != &F) continue;
    for (;;) {
      std::vector<FPTruncInst *> fts;
      for (auto &I : BB) if (auto *T = dyn_cast<FPTruncInst>(&I)) if (T->getType()->isHalfTy() && T->getOperand(0)->getType()->isFloatTy()) fts.push_back(T);
      if (fts.empty()) break;
      auto kind = [](FPTruncInst *T) { for (User *U : T->users()) if (!isa<FPExtInst>(U)) return 0; return T->use_empty() ? 0 : 1; };   // 1: every user is an fpext
      std::vector<FPTruncInst *> g{fts[0]}; Instruction *hard = nullptr; const int k0 = kind(fts[0]);
      { std::vector<Instruction *> p; pureClosure(fts[0], &BB, p, hard); }
      for (size_t j = 1; j < fts.size() && g.size() < N; ++j) {
        if (kind(fts[j]) != k0 || (hard && hard->comesBefore(fts[j]))) { if (dbg() && hard) { errs() << "f16 break at member " << g.size() << ": hard user "; hard->print(errs()); errs() << "\n"; } break; }
        g.push_back(fts[j]);
        std::vector<Instruction *> p; pureClosure(fts[j], &BB, p, hard);
      }
      bool allExp = true; for (auto *T : g) if (!expLike(T->getOperand(0))) allExp = false;
      Function *C = getCvt(F.getParent(), k0 ? 'r' : allExp ? 'e' : 'a', g.size(), zero);
      Instruction *last = g.back(); Instruction *next = last->getNextNode();
      IRBuilder<> Q(next); SmallVector<Value *, 8> args; for (auto *T : g) args.push_back(T->getOperand(0));
      auto *R = Q.CreateCall(C, args);
      std::vector<Instruction *> dead; std::set<Instruction *> mvs; std::vector<Instruction *> mv;
      auto collect = [&](Value *V) { std::vector<Value *> w{V}; while (!w.empty()) { Value *X = w.back(); w.pop_back();
        for (User *U : X->users()) { auto *J = cast<Instruction>(U); if (J->getParent() == &BB && !isa<PHINode>(J) && J->comesBefore(R) && mvs.insert(J).second) { mv.push_back(J); w.push_back(J); } } } };
      for (size_t i = 0; i < g.size(); ++i) {
        FPTruncInst *T = g[i]; Value *E = Q.CreateExtractValue(R, i);
        if (k0) {
          std::vector<FPExtInst *> fe; for (User *U : T->users()) fe.push_back(cast<FPExtInst>(U));
          for (FPExtInst *X : fe) { X->replaceAllUsesWith(E); dead.push_back(X); }
          collect(E);
        } else {
          Instruction *ZE = nullptr, *BC = nullptr;
          if (T->hasOneUse()) if (auto *B1 = dyn_cast<BitCastInst>(*T->user_begin())) if (B1->getType()->isIntegerTy(16) && B1->hasOneUse())
            if (auto *Z = dyn_cast<ZExtInst>(*B1->user_begin())) if (Z->getType()->isIntegerTy(32)) { ZE = Z; BC = B1; }
          if (ZE) { ZE->replaceAllUsesWith(E); dead.push_back(ZE); dead.push_back(BC); collect(E); }
          else { Value *hv = Q.CreateBitCast(Q.CreateTrunc(E, I16), H); T->replaceAllUsesWith(hv); collect(hv); }
        }
        dead.push_back(T); total++;
      }
      // pure users before the call (they were placed right after their fptrunc) move behind it, in order
      std::sort(mv.begin(), mv.end(), [](Instruction *x, Instruction *y) { return x->comesBefore(y); });
      Instruction *anchor = cast<Instruction>(Q.GetInsertPoint() != BB.end() ? &*Q.GetInsertPoint() : nullptr);
      for (Instruction *I : mv) if (std::find(dead.begin(), dead.end(), I) == dead.end()) I->moveBefore(anchor);
      for (Instruction *I : dead) I->eraseFromParent();
      groups++;
    }
  }
  (void)I32;
  if (total) errs() << "lo-f16: " << F.getName().substr(0, 30) << ": " << total << " fptrunc in " << groups << " groups\n";
}

// ---- reductions next to their producers ----------------------------------------------------------------------------------
// maxnum chains over values of an earlier block (row max of the block S = Q K^T) run in that block, while the values are in
// registers: a pure op moved to the end of the latest block defining its operands, when that block dominates this one.
static void hoistReductions(Function &F) {
  DominatorTree DT(F); unsigned n = 0;
  for (BasicBlock &BB : F) for (Instruction &I : make_early_inc_range(BB)) {
    auto *II = dyn_cast<IntrinsicInst>(&I);
    if (!II || II->getIntrinsicID() != Intrinsic::maxnum) continue;
    BasicBlock *T = nullptr; bool ok = true;
    for (Value *V : II->args()) {
      auto *D = dyn_cast<Instruction>(V);
      if (!D) continue;
      if (D->getParent() == &BB) { ok = false; break; }
      if (!T || DT.dominates(T, D->getParent())) T = D->getParent();
    }
    if (!ok || !T || !DT.dominates(T, &BB)) continue;
    for (Value *V : II->args()) if (auto *D = dyn_cast<Instruction>(V)) if (!DT.dominates(D->getParent(), T)) ok = false;
    if (!ok) continue;
    I.moveBefore(T->getTerminator()); n++;
  }
  if (n) errs() << "lo-hoist: " << F.getName().substr(0, 30) << ": " << n << " maxnum moved to their producers' block\n";
}

// ---- per-block list scheduler ---------------------------------------------------------------------------------------------
// The lifted order is ptxas's, tuned for 255 registers; Vortex has 32 + 32. Forward list scheduling for short live ranges:
//   free ops (extractvalue, bitcast) at once; then ops that end more live values than they start; then ops that keep the count
//   and use a value made just before; otherwise the next target (WMMA, or anything with side effects, original order; the next
//   step of a WMMA chain first) pulls its operands.
// Dependences: SSA in the block; memory: reads and writes of one alloca in order, everything else (shared, global, calls, asm)
// in order against writers. Pure convergent ops (shuffles, the WMMA pseudo op) have no order among themselves: all lanes of a
// warp run the same straight-line block.
static bool isWmmaName(StringRef n) { return n == "__lo_wmma" || n == "lo.wmma" || n == "__lo_wmma_bf16" || n == "lo.wmma.bf16"; }   // lo.wmma: the same op behind defineWmma, what lo-sched sees
static bool isPseudoW(Instruction *I) { auto *C = dyn_cast<CallInst>(I); return C && C->getCalledFunction() && isWmmaName(C->getCalledFunction()->getName()); }
static bool isPureCall(CallInst *C) {
  Function *F = C->getCalledFunction();
  if (!F) return false;
  StringRef n = F->getName();
  if (isWmmaName(n) || n.starts_with("llvm.nvvm.shfl.sync") || n.starts_with("llvm.nvvm.read.ptx.sreg") || n.starts_with("llvm.nvvm.ex2") || n.starts_with("llvm.nvvm.lg2") ||
      n.starts_with("llvm.nvvm.rcp") || n.starts_with("llvm.nvvm.mma.") || n.starts_with("llvm.fma") || n.starts_with("llvm.maxnum") || n.starts_with("llvm.minnum") || n.starts_with("llvm.abs")) return true;
  return false;
}
// hold (lo-sched): a barrier or a call with side effects does not move up: all that stood before it stays before it. Moved up, it takes the values of what it passed across a real call
// (LayerNorm 32x1000: floats across the first barrier 8 -> 24). What stood behind it may still go in front when it touches no memory: softmax's sum sits behind a barrier, its adds join the exps that way.
void loScheduleBlock(BasicBlock &BB, bool hold) {
  std::vector<Instruction *> nodes;
  for (Instruction &I : BB) if (!isa<PHINode>(I) && !I.isTerminator() && !isa<AllocaInst>(I)) nodes.push_back(&I);
  const int N = nodes.size();
  if (N < envInt("LO_SCHED_MIN", 64)) return;
  DenseMap<Instruction *, int> id; for (int i = 0; i < N; ++i) id[nodes[i]] = i;
  std::vector<std::vector<int>> succ(N), pred(N); std::vector<int> npred(N, 0);
  auto edge = [&](int a, int b) { if (a == b) return; succ[a].push_back(b); pred[b].push_back(a); npred[b]++; };
  std::map<Value *, int> lastW; std::map<Value *, std::vector<int>> readers;   // key: an alloca with no escaping address, or null for all other memory
  std::map<Value *, bool> privateA;
  auto keyOf = [&](Value *P) -> Value * {
    Value *K = getUnderlyingObject(P);
    if (!isa<AllocaInst>(K)) return nullptr;
    auto it = privateA.find(K); if (it != privateA.end()) return it->second ? K : nullptr;
    bool ok = true; std::vector<Value *> w{K}; std::set<Value *> seen;
    while (!w.empty() && ok) { Value *V = w.back(); w.pop_back(); if (!seen.insert(V).second) continue;
      for (User *U : V->users()) {
        if (isa<GetElementPtrInst>(U) || isa<BitCastInst>(U)) w.push_back(U);
        else if (isa<LoadInst>(U)) {}
        else if (auto *S = dyn_cast<StoreInst>(U)) { if (S->getValueOperand() == V) ok = false; }
        else ok = false;
      } }
    privateA[K] = ok; return ok ? K : nullptr;
  };
  for (int i = 0; i < N; ++i) {
    Instruction *I = nodes[i];
    for (Value *V : I->operands()) if (auto *D = dyn_cast<Instruction>(V)) { auto it = id.find(D); if (it != id.end()) edge(it->second, i); }
    Value *key = nullptr; bool rd = false, wr = false;
    if (auto *L = dyn_cast<LoadInst>(I)) { rd = true; key = keyOf(L->getPointerOperand()); }
    else if (auto *S = dyn_cast<StoreInst>(I)) { wr = true; key = keyOf(S->getPointerOperand()); }
    else if (auto *C = dyn_cast<CallInst>(I)) { if (!isPureCall(C)) wr = true; }
    if (rd) { auto w = lastW.find(key); if (w != lastW.end()) edge(w->second, i); readers[key].push_back(i); }
    if (wr) {
      auto w = lastW.find(key); if (w != lastW.end()) edge(w->second, i);
      for (int r : readers[key]) edge(r, i);
      readers[key].clear(); lastW[key] = i;
    }
  }
  std::vector<char> held(N, 0);
  if (hold) {
    int last = -1;
    for (int i = 0; i < N; ++i) {
      auto *C = dyn_cast<CallInst>(nodes[i]);
      if (!C || isPureCall(C) || !(C->mayHaveSideEffects() || C->isConvergent())) continue;
      for (int j = last + 1; j < i; ++j) edge(j, i);
      if (last >= 0) edge(last, i);
      last = i; held[i] = 1;
    }
  }
  // live values: uses left in the block; a value also used elsewhere never dies here
  std::map<Value *, int> left; std::set<Value *> outside;
  for (Instruction *I : nodes) for (Value *V : I->operands()) if (isa<Instruction>(V) || isa<Argument>(V)) left[V]++;
  for (auto &kv : left) { Value *V = kv.first;
    for (User *U : V->users()) { auto *J = dyn_cast<Instruction>(U); if (!J || !id.count(J)) { outside.insert(V); break; } } }
  for (Instruction *I : nodes) for (User *U : I->users()) { auto *J = dyn_cast<Instruction>(U); if (!J || !id.count(J)) { outside.insert(I); break; } }
  auto isFree = [](Instruction *I) { return isa<ExtractValueInst>(I) || isa<BitCastInst>(I); };
  auto outs = [&](Instruction *I) { if (I->getType()->isVoidTy()) return 0; return isPseudoW(I) ? 8 : 1; };
  auto delta = [&](Instruction *I) {
    int d = outs(I); std::set<Value *> seen;
    for (Value *V : I->operands()) { if (!(isa<Instruction>(V) || isa<Argument>(V)) || !seen.insert(V).second) continue;
      int c = 0; for (Value *W : I->operands()) if (W == V) c++;
      if (!outside.count(V) && left[V] == c) d -= 1; }
    return d;
  };
  std::vector<int> order; order.reserve(N); std::vector<char> done(N, 0); std::vector<int> seq(N, -1);
  std::vector<int> ready; for (int i = 0; i < N; ++i) if (!npred[i]) ready.push_back(i);
  std::vector<int> targets;
  // a held call is no target: it only waits for what stood before it, while the next target pulls its operands in use order, past the call
  for (int i = 0; i < N; ++i) { Instruction *I = nodes[i]; if (!held[i] && (isPseudoW(I) || isa<StoreInst>(I) || (isa<CallInst>(I) && !isPureCall(cast<CallInst>(I))))) targets.push_back(i); }
  size_t tpos = 0; int prefer = -1;
  const int recent = envInt("LO_SCHED_RECENT", 16);
  auto commit = [&](int i) {
    Instruction *I = nodes[i]; done[i] = 1; seq[i] = order.size(); order.push_back(i);
    ready.erase(std::find(ready.begin(), ready.end(), i));
    for (int s : succ[i]) if (--npred[s] == 0) ready.push_back(s);
    for (Value *V : I->operands()) { auto it = left.find(V); if (it != left.end()) it->second--; }
  };
  std::function<int(int, std::set<int> &)> pull = [&](int t, std::set<int> &seen) -> int {
    if (!seen.insert(t).second) return -1;
    if (done[t]) return -1;
    if (npred[t] == 0) return t;
    for (int p : pred[t]) { if (done[p]) continue; int r = pull(p, seen); if (r >= 0) return r; }
    return -1;
  };
  while ((int)order.size() < N) {
    int best = -1; long bestKey = 0;
    for (int i : ready) {
      Instruction *I = nodes[i];
      int d = delta(I), cat, age = 1 << 20;
      for (int p : pred[i]) if (seq[p] >= 0) age = std::min(age, (int)order.size() - seq[p]);
      if (isFree(I)) cat = 0;
      else if (d < 0) cat = 1;
      else if (d == 0 && age <= recent) cat = 2;
      else continue;
      if (isPseudoW(I) && i != prefer && cat > 1) continue;
      long key = (long)cat * (1L << 40) + (long)std::min(age, 1 << 19) * (1L << 20) + i;
      if (best < 0 || key < bestKey) { best = i; bestKey = key; }
    }
    if (best < 0) {
      if (prefer >= 0 && done[prefer]) prefer = -1;
      int t = prefer;
      if (t < 0) { while (tpos < targets.size() && done[targets[tpos]]) tpos++; if (tpos < targets.size()) t = targets[tpos]; }
      if (t >= 0) { std::set<int> seen; best = pull(t, seen); }
      if (best < 0) { best = *std::min_element(ready.begin(), ready.end()); }
    }
    commit(best);
    if (isPseudoW(nodes[best])) {   // the next step of the chain: the WMMA whose accumulators are this one's result
      prefer = -1;
      for (User *U : nodes[best]->users()) for (User *V : U->users()) if (auto *J = dyn_cast<Instruction>(V)) if (isPseudoW(J) && id.count(J) && !done[id[J]] && prefer < 0) prefer = id[J];
    }
  }
  Instruction *term = BB.getTerminator();
  for (int i : order) nodes[i]->moveBefore(term);
}

// ---- wgmma ------------------------------------------------------------------------------------------------------------------
// wgmma.mma_async m64nNk16 f32 f16 f16, A and B in shared memory through descriptors (no swizzle, the form the runtime's wgmma supports): for the warp w of the
// warpgroup this is N/8 mma m16n8k16 on rows 16w.., and acc[4j..4j+3] is exactly the accumulator of n-tile j. Written as mma calls on loads, it goes through the same
// grouping as lifted mma.sync: k32, no accumulator shuffles (the B lane permutation sits in the load address), one WMMA per 2 n-tiles and 2 k-steps.
// Same address formula as __cupbop_core_ld; the k slots use the same permutation in A and B (the WMMA is free to take k in any order).
static void lowerWgmma(Function &F, Lanes &LN, std::set<Value *> &bPerm) {
  Module *M = F.getParent(); LLVMContext &Ctx = F.getContext(); Type *I32 = Type::getInt32Ty(Ctx), *I64 = Type::getInt64Ty(Ctx), *F32 = Type::getFloatTy(Ctx), *I8 = Type::getInt8Ty(Ctx);
  GlobalVariable *G = M->getGlobalVariable("shared_mem", true); if (!G) return;
  std::vector<CallInst *> todo;
  for (auto &BB : F) for (auto &I : BB) if (auto *C = dyn_cast<CallInst>(&I)) if (auto *IA = dyn_cast<InlineAsm>(C->getCalledOperand())) {
    StringRef a = IA->getAsmString(); if (!a.starts_with("wgmma.mma_async.sync.aligned.m64n")) continue;
    if (a.contains(".f32.f16.f16 ") && a.contains("k16.") && a.ends_with("1, 1, 1, 0, 0;") && C->arg_size() >= 3) todo.push_back(C);
  }
  if (todo.empty()) return;
  Type *V2H = FixedVectorType::get(Type::getHalfTy(Ctx), 2); Type *ST = StructType::get(Ctx, SmallVector<Type *, 4>(4, F32));
  SmallVector<Type *, 10> pa(6, V2H); pa.append(4, F32);
  FunctionCallee Mma = M->getOrInsertFunction("llvm.nvvm.mma.m16n8k16.row.col.f32.f32", FunctionType::get(ST, pa, false));
  auto sreg = [&](IRBuilder<> &Q, const char *n) -> Value * { return Q.CreateCall(M->getOrInsertFunction(n, FunctionType::get(I32, false)), {}); };
  unsigned n = 0;
  for (CallInst *W : todo) {
    const unsigned nacc = W->arg_size() - 2, N = 2 * nacc; if (N % 16) continue;
    IRBuilder<> Q(W); auto &P = LN.get(W->getParent());
    Value *tx = sreg(Q, "llvm.nvvm.read.ptx.sreg.tid.x"), *nx = sreg(Q, "llvm.nvvm.read.ptx.sreg.ntid.x"), *ny = sreg(Q, "llvm.nvvm.read.ptx.sreg.ntid.y");
    Value *lin = Q.CreateAdd(tx, Q.CreateMul(sreg(Q, "llvm.nvvm.read.ptx.sreg.tid.y"), nx)); lin = Q.CreateAdd(lin, Q.CreateMul(sreg(Q, "llvm.nvvm.read.ptx.sreg.tid.z"), Q.CreateMul(nx, ny)));
    Value *wig = Q.CreateAnd(Q.CreateLShr(lin, 5), 3, "lo.wig");
    Value *gw = Q.CreateAnd(Q.CreatePtrToInt(G, I32), 0x3FFFF);
    auto dec = [&](Value *d, Value *&off, Value *&lbo, Value *&sbo) {
      Value *lo = Q.CreateTrunc(d, I32);
      off = Q.CreateAnd(Q.CreateSub(Q.CreateShl(Q.CreateAnd(lo, 0x3FFF), 4), gw), 0x3FFFF);
      lbo = Q.CreateShl(Q.CreateAnd(Q.CreateLShr(lo, 16), 0x3FFF), 4);
      sbo = Q.CreateShl(Q.CreateAnd(Q.CreateTrunc(Q.CreateLShr(d, 32), I32), 0x3FFF), 4); };
    Value *oa, *la, *sa, *ob, *lb, *sb; dec(W->getArgOperand(0), oa, la, sa); dec(W->getArgOperand(1), ob, lb, sb);
    Value *kpart = P.t8, *laneA = Q.CreateAdd(Q.CreateShl(P.g, 4), kpart), *laneB = Q.CreateAdd(Q.CreateShl(P.rg, 4), kpart);
    Value *chA = Q.CreateSelect(P.th, la, ConstantInt::get(I32, 0)), *chB = Q.CreateSelect(P.th, lb, ConstantInt::get(I32, 0));
    Value *baseA = Q.CreateAdd(Q.CreateAdd(oa, chA), laneA), *baseB = Q.CreateAdd(Q.CreateAdd(ob, chB), laneB);
    auto word = [&](Value *off, int c) { Value *p = Q.CreateGEP(I8, G, {Q.CreateSExt(off, I64)}); if (c) p = Q.CreateGEP(I8, p, {ConstantInt::get(I64, c)}); return Q.CreateAlignedLoad(F32, p, Align(4)); };
    Value *av[4];
    for (int rh = 0; rh < 2; ++rh) { Value *off = Q.CreateAdd(baseA, Q.CreateMul(Q.CreateAdd(Q.CreateShl(wig, 1), ConstantInt::get(I32, rh)), sa)); for (int q = 0; q < 2; ++q) av[2 * q + rh] = word(off, 4 * q); }
    SmallVector<Value *, 8> res;
    for (unsigned j = 0; j < N / 8; ++j) {
      Value *off = Q.CreateAdd(baseB, Q.CreateMul(ConstantInt::get(I32, j), sb));
      Value *b0 = word(off, 0), *b1 = word(off, 4); bPerm.insert(b0); bPerm.insert(b1);
      SmallVector<Value *, 10> args; for (int i = 0; i < 4; ++i) args.push_back(Q.CreateBitCast(av[i], V2H)); args.push_back(Q.CreateBitCast(b0, V2H)); args.push_back(Q.CreateBitCast(b1, V2H));
      for (int i = 0; i < 4; ++i) { Value *c = W->getArgOperand(2 + 4 * j + i); args.push_back(c->getType() == F32 ? c : Q.CreateBitCast(c, F32)); }
      auto *C = Q.CreateCall(Mma, args); C->addFnAttr(Attribute::Convergent); res.push_back(C);
    }
    for (User *U : make_early_inc_range(W->users())) { auto *E = dyn_cast<ExtractValueInst>(U); if (!E) continue; unsigned i = E->getIndices()[0]; Q.SetInsertPoint(E); Value *v = Q.CreateExtractValue(res[i / 4], i % 4); E->replaceAllUsesWith(v); E->eraseFromParent(); }
    if (W->use_empty()) { W->eraseFromParent(); n++; } else errs() << "lo-wgmma: result used other than by extractvalue\n";
  }
  if (n) errs() << "lo-wgmma: " << F.getName().substr(0, 30) << ": " << n << " wgmma -> mma on loads\n";
}

// ---- wide shared loads --------------------------------------------------------------------------------------------------------
// LDS.128 is lifted as load volatile i128 + trunc / lshr + trunc: on RV64 that is 2 ld, shifts and fmv.w.x. Four 32-bit loads give the same words, straight into f registers when
// the words are floats. They stay volatile: the lift marks every shared access volatile, which keeps them in program order against each other; a warp-synchronous SASS
// sequence (STS by one lane, LDS by another, no barrier) depends on that order. Only the width changes. LO_WIDE=2: no volatile (measurement only).
static void splitWide(Function &F) {
  LLVMContext &Ctx = F.getContext(); Type *I32 = Type::getInt32Ty(Ctx), *F32 = Type::getFloatTy(Ctx), *I8 = Type::getInt8Ty(Ctx), *I64 = Type::getInt64Ty(Ctx); unsigned n = 0;
  const int mode = envInt("LO_WIDE", 0);
  std::vector<LoadInst *> ls;
  for (auto &BB : F) for (auto &I : BB) if (auto *L = dyn_cast<LoadInst>(&I)) if (L->getType()->isIntegerTy(128) && L->getPointerAddressSpace() == 3) ls.push_back(L);
  for (LoadInst *L : ls) {
    std::map<int, std::vector<TruncInst *>> w; bool ok = true; std::vector<Instruction *> mid;
    auto use = [&](Value *V, int k) { for (User *U : V->users()) { auto *T = dyn_cast<TruncInst>(U); if (T && T->getType() == I32) w[k].push_back(T); else ok = false; } };
    for (User *U : L->users()) {
      if (auto *T = dyn_cast<TruncInst>(U)) { if (T->getType() == I32) w[0].push_back(T); else ok = false; continue; }
      auto *S = dyn_cast<BinaryOperator>(U); auto *C = S && S->getOpcode() == Instruction::LShr ? dyn_cast<ConstantInt>(S->getOperand(1)) : nullptr;
      if (!C || C->getZExtValue() % 32 || C->getZExtValue() >= 128) { ok = false; continue; }
      use(S, C->getZExtValue() / 32); mid.push_back(S);
    }
    if (!ok) continue;
    IRBuilder<> Q(L);
    for (auto &kv : w) {
      bool allF = true; for (TruncInst *T : kv.second) for (User *U : T->users()) { auto *B = dyn_cast<BitCastInst>(U); if (!B || B->getType() != F32) allF = false; }
      Value *p = L->getPointerOperand(); if (kv.first) p = Q.CreateGEP(I8, p, {ConstantInt::get(I64, 4 * kv.first)});
      auto *X = Q.CreateAlignedLoad(allF ? F32 : I32, p, Align(4)); X->setVolatile(mode == 1 && L->isVolatile());
      for (TruncInst *T : kv.second) {
        if (allF) for (User *U : make_early_inc_range(T->users())) { U->replaceAllUsesWith(X); cast<Instruction>(U)->eraseFromParent(); }
        else T->replaceAllUsesWith(X);
        T->eraseFromParent();
      }
    }
    for (Instruction *S : mid) S->eraseFromParent();
    L->eraseFromParent(); n++;
  }
  if (n) errs() << "lo-wide: " << F.getName().substr(0, 30) << ": " << n << " 128-bit shared loads -> 32-bit loads\n";
}

// ---- body of the WMMA op (one definition; call sites stay one line): @lo.wmma(a0..7, b0..7, c0..7) -> {d0..7}; fragment arrays + the runtime's
// WMMA helper, always_inline here and inlined again by CuPBoP's LTO, the arrays become registers (fixed f0-f23 of the asm)
static void defineWmma(Module &M, const char *pseudo = "__lo_wmma", const char *body = "lo.wmma", const char *rt = "__vx_wmma_mma_m16n16k16_row_row_f16_f16_f32") {
  Function *L = M.getFunction(pseudo);
  if (!L || !L->isDeclaration()) return;
  LLVMContext &Ctx = M.getContext(); Type *F32 = Type::getFloatTy(Ctx), *P = PointerType::getUnqual(Ctx);
  if (L->use_empty()) { L->eraseFromParent(); return; }
  FunctionCallee W = M.getOrInsertFunction(rt, FunctionType::get(Type::getVoidTy(Ctx), {P, P, P, P}, false));
  if (auto *Fn = dyn_cast<Function>(W.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  SmallVector<Type *, 25> pa{P}; pa.append(24, F32);
  auto *N = Function::Create(FunctionType::get(L->getReturnType(), pa, false), GlobalValue::InternalLinkage, body, &M);
  N->addFnAttr(Attribute::AlwaysInline); N->addFnAttr(Attribute::Convergent);
  // one fragment scratch per kernel (first argument): per-call-site arrays would survive into the frame when CuPBoP's LTO keeps a helper out of line
  BasicBlock *E = BasicBlock::Create(Ctx, "entry", N); IRBuilder<> Q(E);
  Type *T32 = ArrayType::get(F32, 32);
  Value *base = N->getArg(0);
  auto slot = [&](int arr, int i) { return Q.CreateConstInBoundsGEP2_32(T32, base, 0, 8 * arr + i); };
  for (int i = 0; i < 8; ++i) { Q.CreateStore(N->getArg(1 + i), slot(0, i)); Q.CreateStore(N->getArg(9 + i), slot(1, i)); Q.CreateStore(N->getArg(17 + i), slot(2, i)); }
  auto *R = Q.CreateCall(W, {slot(3, 0), slot(0, 0), slot(1, 0), slot(2, 0)}); R->addFnAttr(Attribute::Convergent);
  Value *V = PoisonValue::get(L->getReturnType());
  for (unsigned i = 0; i < 8; ++i) V = Q.CreateInsertValue(V, Q.CreateLoad(F32, slot(3, i)), i);
  Q.CreateRet(V);
  std::map<Function *, AllocaInst *> scratch;
  for (User *U : make_early_inc_range(L->users())) {
    auto *C = cast<CallInst>(U); Function *F = C->getFunction();
    AllocaInst *&A = scratch[F];
    if (!A) { IRBuilder<> B(&*F->getEntryBlock().getFirstInsertionPt()); A = B.CreateAlloca(T32, nullptr, "lo.frag"); }
    IRBuilder<> B(C); SmallVector<Value *, 25> args{A}; for (unsigned i = 0; i < 24; ++i) args.push_back(C->getArgOperand(i));
    auto *D = B.CreateCall(N, args); D->addFnAttr(Attribute::Convergent); D->takeName(C);
    C->replaceAllUsesWith(D); C->eraseFromParent();
  }
  L->eraseFromParent();
}

// ldmatrix results that reach a loop through phis (software pipelining: the first fragment of the next iteration is loaded at the end of this one): load in the
// block of the phi instead, from a phi of the addresses, when nothing in the epoch can change the words on the way. Then the fragment is not live across the back edge.
static void sinkLdsmPhis(Function &F) {
  DominatorTree DT(F); unsigned n = 0;
  for (BasicBlock &BB : F) {
    if (pred_size(&BB) < 2) continue;
    std::map<std::vector<CallInst *>, std::vector<std::pair<PHINode *, unsigned>>> sets;
    std::vector<std::vector<CallInst *>> keyOrder;
    for (PHINode &P : BB.phis()) {
      std::vector<CallInst *> cs; int idx = -1; bool ok = true;
      for (unsigned k = 0; k < P.getNumIncomingValues() && ok; ++k) {
        auto *E = dyn_cast<ExtractValueInst>(peel(P.getIncomingValue(k))); auto *C = E ? dyn_cast<CallInst>(E->getAggregateOperand()) : nullptr; Ldsm L;
        if (!C || !parseLdsm(C, L) || (idx >= 0 && (int)E->getIndices()[0] != idx)) { ok = false; break; }
        idx = E->getIndices()[0]; cs.push_back(C);
      }
      if (dbg() && !ok) { errs() << "phi not ldsm: "; P.print(errs()); errs() << "\n"; }
      if (ok && idx >= 0) { if (!sets.count(cs)) keyOrder.push_back(cs); sets[cs].push_back({&P, (unsigned)idx}); }
    }
    for (auto &ko : keyOrder) { auto &kv = *sets.find(ko);
      auto &cs = kv.first; PHINode *P0 = kv.second[0].first; Ldsm L0; parseLdsm(cs[0], L0); GlobalVariable *G0 = nullptr; bool ok = true; std::vector<Value *> offs;
      for (unsigned k = 0; k < cs.size() && ok; ++k) {
        Ldsm L; parseLdsm(cs[k], L); GlobalVariable *G; Value *o; BasicBlock *In = P0->getIncomingBlock(k);
        if (!smemOffset(L.addr, G, o) || L.num != L0.num || L.trans != L0.trans || (G0 && G != G0)) { ok = false; break; }
        G0 = G; offs.push_back(o);
        if (!DT.dominates(cs[k]->getParent(), In) || !epochClear(cs[k], In->getTerminator())) { ok = false; if (dbg()) { errs() << "ldsm phi sink: " << BB.getName() << " in " << In->getName() << " dom " << DT.dominates(cs[k]->getParent(), In) << "\n";
          for (Instruction *I = cs[k]->getNextNode(); I; I = I->getNextNode()) if (endsEpoch(I)) { errs() << "   ends: "; I->print(errs()); errs() << "\n"; break; }
          for (Instruction &I : *In) if (endsEpoch(&I)) { errs() << "   ends(in): "; I.print(errs()); errs() << "\n"; break; } } }
      }
      if (!ok) continue;
      IRBuilder<> Q(&*BB.getFirstInsertionPt());
      PHINode *O = PHINode::Create(Type::getInt32Ty(F.getContext()), cs.size(), "lo.fragoff", BB.begin());
      for (unsigned k = 0; k < cs.size(); ++k) O->addIncoming(offs[k], P0->getIncomingBlock(k));
      auto *P2I = cast<PtrToIntInst>(L0.addr); auto *GEP = cast<GetElementPtrInst>(P2I->getOperand(0));
      auto *G2 = cast<GetElementPtrInst>(GEP->clone()); auto *Z = Q.CreateZExt(O, GEP->getOperand(2)->getType()); G2->setOperand(2, Z); Q.Insert(G2);
      auto *A2 = cast<PtrToIntInst>(P2I->clone()); A2->setOperand(0, G2); Q.Insert(A2);
      auto *N = cast<CallInst>(cs[0]->clone()); N->setArgOperand(0, A2); Q.Insert(N);
      for (auto &pr : kv.second) { Value *E = Q.CreateExtractValue(N, pr.second); if (E->getType() != pr.first->getType()) E = Q.CreateBitCast(E, pr.first->getType()); pr.first->replaceAllUsesWith(E); pr.first->eraseFromParent(); }
      n++;
    }
  }
  // the old ldmatrix calls are side-effect asm: erase the ones nothing reads any more
  std::vector<CallInst *> calls; for (BasicBlock &BB : F) for (Instruction &I : BB) if (auto *C = dyn_cast<CallInst>(&I)) { Ldsm L; if (parseLdsm(C, L)) calls.push_back(C); }
  for (CallInst *C : calls) {
    std::function<bool(Value *)> used = [&](Value *V) { for (User *U : V->users()) { if (isa<ExtractValueInst>(U) || isa<BitCastInst>(U)) { if (used(U)) return true; } else return true; } return false; };
    if (used(C)) continue;
    std::function<void(Value *)> del = [&](Value *V) { for (User *U : make_early_inc_range(V->users())) { del(U); cast<Instruction>(U)->eraseFromParent(); } };
    del(C); C->eraseFromParent(); }
  if (n) errs() << "lo-frag: " << F.getName().substr(0, 30) << ": " << n << " ldmatrix moved through phis\n";
}

void p3PromoteHalf(Function &F);
struct LoMma : PassInfoMixin<LoMma> {
  bool hoist = true, sched = true, f16 = true, fp = true;   // lo-mma<no-hoist;no-sched;no-f16;no-fp>: without that step, whatever LO_HOIST, LO_SCHED, LO_F16, LO_FP say
  bool laneEval = false;   // lo-mma<lane-eval>: see loLaneMode
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    loLaneMode = laneEval && envOn("LO_LANE_EVAL", true);
    Lanes LN(&M); std::vector<Function *> fs; for (auto &F : M) if (!F.isDeclaration()) fs.push_back(&F);
    for (Function *F : fs) {
      LN.bb.clear(); LN.tid = nullptr; fragOf.clear();
      std::set<Value *> bp;
      splitAggPhis(*F); canonPacks(*F);
      if (envOn("LO_CENSUS", false)) census(*F);
      if (envOn("LO_FRAG", true) && envOn("LO_FRAG_PHI", true)) sinkLdsmPhis(*F);
      if (envInt("LO_WIDE", 0)) splitWide(*F);   // off: no gain, the loads are in the epilogue (see report)
      if (envOn("LO_WGMMA", true)) lowerWgmma(*F, LN, bp);
      if (envOn("LO_LDSM", true)) lowerLdsm(*F, LN, bp);
      if (envOn("LO_MMA", true)) lowerMma(*F, LN, bp);
      for (bool again = true; again;) { again = false;
        for (auto &BB : *F) for (Instruction &I : make_early_inc_range(llvm::reverse(BB))) if (isInstructionTriviallyDead(&I)) { I.eraseFromParent(); again = true; } }
      if (hoist && envOn("LO_HOIST", true)) hoistReductions(*F);
      if (sched && envOn("LO_SCHED", true)) for (BasicBlock &BB : *F) loScheduleBlock(BB, false);
      p3PromoteHalf(*F);   // p3: half arithmetic -> float + fptrunc (lonext.cpp), before lo-f16 sees the fptruncs
      if (f16 && envOn("LO_F16", true)) loLowerF16(*F, false);
      // Frames over 2 KB: LLVM lays spill slots out from the top of the frame, sp-relative offsets of the early (hot) slots do not fit a
      // 12-bit immediate and every access costs lui + add. fp-relative addressing reaches them directly.
      if (fp && envOn("LO_FP", true)) F->addFnAttr("frame-pointer", "all");
    }
    defineWmma(M);
    defineWmma(M, "__lo_wmma_bf16", "lo.wmma.bf16", "__vx_wmma_mma_m16n16k16_row_row_bf16_bf16_f32");
    return PreservedAnalyses::none();
  }
};

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "liftopt", "0.1", [](PassBuilder &PB) {
    PB.registerPipelineParsingCallback([](StringRef N, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
      if (N == "lo-mma") { MPM.addPass(LoMma()); return true; }
      if (N.consume_front("lo-mma<") && N.consume_back(">")) {
        LoMma P; SmallVector<StringRef, 4> opts; N.split(opts, ';');
        for (StringRef o : opts) {
          if (o == "no-hoist") P.hoist = false;
          else if (o == "no-sched") P.sched = false;
          else if (o == "no-f16") P.f16 = false;
          else if (o == "no-fp") P.fp = false;
          else if (o == "lane-eval") P.laneEval = true;
          else return false;
        }
        MPM.addPass(std::move(P)); return true;
      }
      return false; }); }};
}
