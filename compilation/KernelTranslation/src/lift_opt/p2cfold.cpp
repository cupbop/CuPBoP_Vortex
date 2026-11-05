// p2cfold.cpp (2026-11-04): LLVM 20 pass plugin for lifted NVVM IR, run BEFORE CuPBoP (opt -load-pass-plugin=libp2cfold.so).
// Pass p2c-fold: fold a cp.async multistage ring from S stages to S' stages (P2C_STAGES, default 2).
//
// Why: CuPBoP lowers cp.async to a synchronous copy, so the S-1 tiles in flight only cost local memory. Fewer stages = smaller CTA
// area = more CTAs (warps) per core. Nothing here names a kernel or uses a kernel's constants: the ring is recovered from the IR and
// every fact the rewrite relies on is checked by evaluating the address slices for every thread of the block; on any doubt the
// function stays as it is.
//
// What is recognised (all by value, not by shape):
//  - main loop: the loop with cp.async + ldmatrix + one barrier0; prologue: cp.async before it, straight line or one loop
//  - ring phis: header phis whose update depends only on constants and other such phis, whose simulated sequence is periodic with
//    step a: x_t = base + ((t + o) mod S) a (a stage index, a read offset, a write offset, ...). No syntactic form is assumed
//  - classes: stage-0 addresses of a stride a group: x = base + row P + c, P = S a, c < a (stages interleaved in a row when
//    rows > 1, e.g. CUTLASS A; contiguous when one row; two tensors with the same a are two rows)
//  - copies: chunk vector (stage-0 address for every thread); a prologue event and a loop site with the same vector are the same
//    site at another tile; the prologue event's stage is its tile; site k first writes tile T_k in the loop
//
// The rewrite (retiming + fold):
//  - delta = S - S'. Site k keeps its place but runs the copy of delta iterations ago: the (src, size, guard) of each site goes through
//    a per-thread queue q[k][delta]. Tile tau of site k now runs at iteration tau - T'_k, T'_k = T_k - delta; prologue events with
//    tau >= T'_k are not run, their (src, size, guard) initialise the queue. Pointers, predicates, k-tile counters are untouched,
//    so the rewrite needs no knowledge of the iterators (residue tiles, filter positions, split-K ...). Events still in the queue
//    at loop exit are tiles >= the number of tiles read, as in the original program where the last S-1 iterations copy nothing used.
//  - new layout: base' + row (S' a) + stage' a + c, stage' = tile mod S'. The stage-0 part is loop invariant, computed once before the loop.
//  - hazards (checked): reads before the barrier are tile t, after it tile t+1; a site before the barrier writes stage (t+T') mod S'
//    with T' mod S' != 0, a site after it with T' mod S' != 1; every tile's copies finish before the barrier that precedes its reads.
//  - barrier0.and/or/popc lowering needs one word of shared memory (@__cupbop_bar_red, 4 B after the shared area, which puts a 2^k
//    budget one stride over): lowered here with word 0 of @shared_mem saved and restored around the reduction (two more barriers;
//    the split-K semaphore path, not taken by split-K 1 launches).
//  - @shared_mem shrinks to the new footprint; the launch must pass dyn_smem = 0 (printed in the log line).
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
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
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include <cstdlib>
#include <functional>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <vector>
using namespace llvm;

namespace {
typedef std::optional<uint64_t> OV;
static int envInt(const char *n, int d) { const char *e = getenv(n); return e && *e ? atoi(e) : d; }

static bool asmHas(const CallInst *C, const char *s) {
  auto *IA = dyn_cast<InlineAsm>(C->getCalledOperand());
  return IA && IA->getAsmString().find(s) != std::string::npos;
}
static bool isCp(const CallInst *C) { return asmHas(C, "cp.async.cg.shared.global") || asmHas(C, "cp.async.ca.shared.global"); }
static bool isLdsm(const CallInst *C) { return asmHas(C, "ldmatrix.sync"); }
static bool isIntr(const CallInst *C, StringRef n) { Function *F = C->getCalledFunction(); return F && F->getName() == n; }
static bool isBar(const Instruction *I) { auto *C = dyn_cast<CallInst>(I); return C && isIntr(C, "llvm.nvvm.barrier0"); }
static bool isBarRed(const CallInst *C) {
  Function *F = C->getCalledFunction();
  if (!F) return false;
  StringRef n = F->getName();
  return n == "llvm.nvvm.barrier0.and" || n == "llvm.nvvm.barrier0.or" || n == "llvm.nvvm.barrier0.popc";
}

// ---- concrete evaluation of an integer slice for one thread ---------------------------------------------------------------------
struct Eval {
  uint32_t tid = 0;
  const DenseMap<Value *, uint64_t> *env = nullptr;   // ring phis -> their value at the iteration being evaluated
  const std::map<int64_t, uint64_t> *params = nullptr; // kernel parameter loads (offset in the parameter block) -> sample value
  int64_t missing = -1;                                // the parameter offset last needed and not in params
  const std::map<std::pair<Value *, int64_t>, Value *> *slots = nullptr;   // stack slots written by exactly one store (lifted LDL/STL spills)
  DenseMap<Value *, OV> memo;
  SmallPtrSet<Value *, 16> open;
  static uint64_t mask(unsigned w) { return w >= 64 ? ~0ull : ((1ull << w) - 1); }
  static int64_t sx(uint64_t v, unsigned w) { return w >= 64 ? (int64_t)v : (int64_t)(v << (64 - w)) >> (64 - w); }
  OV get(Value *V) {
    if (auto *K = dyn_cast<ConstantInt>(V)) { if (K->getBitWidth() > 64) return {}; return K->getZExtValue(); }
    if (isa<UndefValue>(V) || isa<PoisonValue>(V)) return {};
    if (env) { auto it = env->find(V); if (it != env->end()) return it->second; }
    auto m = memo.find(V);
    if (m != memo.end()) return m->second;
    if (!open.insert(V).second) return {};
    OV r = comp(V);
    open.erase(V);
    memo[V] = r;
    return r;
  }
  OV comp(Value *V) {
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !V->getType()->isIntegerTy()) return {};
    unsigned w = V->getType()->getIntegerBitWidth();
    if (w > 64) return {};
    uint64_t M = mask(w);
    if (auto *L = dyn_cast<LoadInst>(I)) {
      int64_t off = 0;
      Value *base = GetPointerBaseWithConstantOffset(L->getPointerOperand(), off, I->getDataLayout());
      if (!base || !isa<AllocaInst>(base)) return {};
      if (slots) { auto q = slots->find({base, off}); if (q != slots->end()) return get(q->second); }
      if (!params) return {};
      auto it = params->find(off);
      if (it == params->end()) { missing = off; return {}; }
      return it->second & M;
    }
    if (auto *C = dyn_cast<CallInst>(I)) {
      Function *F = C->getCalledFunction();
      if (!F) return {};
      StringRef n = F->getName();
      if (n == "llvm.nvvm.read.ptx.sreg.tid.x") return tid;
      if (n == "llvm.nvvm.read.ptx.sreg.laneid") return tid & 31;
      if (n == "llvm.nvvm.read.ptx.sreg.cluster.ctarank") return 0;   // no clusters on this target: every CTA is rank 0 of its own
      if (n == "llvm.nvvm.shfl.sync.idx.i32") {   // a broadcast inside the warp: the operand as another lane computes it
        OV l = get(C->getArgOperand(2)), c = get(C->getArgOperand(3));
        if (!l || !c || *c != 31) return {};
        Eval o; o.tid = (tid & ~31u) | (*l & 31); o.env = env;
        return o.get(C->getArgOperand(1));
      }
      if (n == "llvm.smin.i32" || n == "llvm.smax.i32" || n == "llvm.umin.i32" || n == "llvm.umax.i32") {
        OV a = get(C->getArgOperand(0)), b = get(C->getArgOperand(1));
        if (!a || !b) return {};
        bool lt = n.contains("smin") || n.contains("smax") ? sx(*a, 32) < sx(*b, 32) : *a < *b;
        bool wantMin = n.contains("min");
        return (lt == wantMin) ? *a : *b;
      }
      return {};
    }
    if (auto *B = dyn_cast<BinaryOperator>(I)) {
      OV a = get(B->getOperand(0)), b = get(B->getOperand(1));
      if (!a || !b) return {};
      uint64_t x = *a, y = *b;
      switch (B->getOpcode()) {
      case Instruction::Add: return (x + y) & M;
      case Instruction::Sub: return (x - y) & M;
      case Instruction::Mul: return (x * y) & M;
      case Instruction::And: return x & y;
      case Instruction::Or: return x | y;
      case Instruction::Xor: return x ^ y;
      case Instruction::Shl: return y >= w ? OV() : OV((x << y) & M);
      case Instruction::LShr: return y >= w ? OV() : OV(x >> y);
      case Instruction::AShr: return y >= w ? OV() : OV((uint64_t)(sx(x, w) >> y) & M);
      case Instruction::UDiv: return y ? OV(x / y) : OV();
      case Instruction::URem: return y ? OV(x % y) : OV();
      default: return {};
      }
    }
    if (auto *Z = dyn_cast<ZExtInst>(I)) return get(Z->getOperand(0));
    if (auto *S = dyn_cast<SExtInst>(I)) {
      OV a = get(S->getOperand(0));
      if (!a) return {};
      return (uint64_t)sx(*a, S->getOperand(0)->getType()->getIntegerBitWidth()) & M;
    }
    if (auto *T = dyn_cast<TruncInst>(I)) { OV a = get(T->getOperand(0)); if (!a) return {}; return *a & M; }
    if (auto *F = dyn_cast<FreezeInst>(I)) return get(F->getOperand(0));
    if (auto *S = dyn_cast<SelectInst>(I)) {
      OV c = get(S->getCondition());
      if (!c) {
        OV a = get(S->getTrueValue()), b = get(S->getFalseValue());
        if (a && b && *a == *b) return a;
        return {};
      }
      return get(*c ? S->getTrueValue() : S->getFalseValue());
    }
    if (auto *C = dyn_cast<ICmpInst>(I)) {
      OV a = get(C->getOperand(0)), b = get(C->getOperand(1));
      if (!a || !b || !C->getOperand(0)->getType()->isIntegerTy()) return {};
      unsigned ow = C->getOperand(0)->getType()->getIntegerBitWidth();
      int64_t sa = sx(*a, ow), sb = sx(*b, ow);
      switch (C->getPredicate()) {
      case CmpInst::ICMP_EQ: return *a == *b;
      case CmpInst::ICMP_NE: return *a != *b;
      case CmpInst::ICMP_ULT: return *a < *b;
      case CmpInst::ICMP_ULE: return *a <= *b;
      case CmpInst::ICMP_UGT: return *a > *b;
      case CmpInst::ICMP_UGE: return *a >= *b;
      case CmpInst::ICMP_SLT: return sa < sb;
      case CmpInst::ICMP_SLE: return sa <= sb;
      case CmpInst::ICMP_SGT: return sa > sb;
      case CmpInst::ICMP_SGE: return sa >= sb;
      default: return {};
      }
    }
    if (auto *P = dyn_cast<PHINode>(I)) {   // a phi outside the ring: known only when every way in gives the same value
      OV r;
      for (Value *In : P->incoming_values()) {
        OV a = get(In);
        if (!a) return {};
        if (r && *r != *a) return {};
        r = a;
      }
      return r;
    }
    return {};
  }
};

static bool pureOp(Instruction *I) {
  if (isa<BinaryOperator>(I) || isa<CastInst>(I) || isa<SelectInst>(I) || isa<ICmpInst>(I) || isa<FreezeInst>(I)) return true;
  if (auto *C = dyn_cast<CallInst>(I)) {
    Function *F = C->getCalledFunction();
    if (!F) return false;
    StringRef n = F->getName();
    return n == "llvm.nvvm.read.ptx.sreg.tid.x" || n == "llvm.nvvm.read.ptx.sreg.laneid" || n.starts_with("llvm.smin") || n.starts_with("llvm.smax") ||
           n.starts_with("llvm.umin") || n.starts_with("llvm.umax") || n.starts_with("llvm.fshl") || n.starts_with("llvm.fshr");
  }
  return false;
}

// clone the slice of V in front of At; subst replaces values (ring phis); nullptr when a leaf is not available there
static Value *cloneSlice(Value *V, Instruction *At, DenseMap<Value *, Value *> &subst, DominatorTree &DT, int depth = 0) {
  auto it = subst.find(V);
  if (it != subst.end()) return it->second;
  auto *I = dyn_cast<Instruction>(V);
  if (!I) return V;
  if (DT.dominates(I, At)) return I;
  if (depth > 200 || !pureOp(I)) return nullptr;
  Instruction *C = I->clone();
  for (unsigned i = 0; i < C->getNumOperands(); ++i) {
    Value *O = I->getOperand(i);
    if (isa<Function>(O) || isa<BasicBlock>(O)) continue;
    Value *N = cloneSlice(O, At, subst, DT, depth + 1);
    if (!N) { C->deleteValue(); return nullptr; }
    C->setOperand(i, N);
  }
  C->dropPoisonGeneratingFlags();
  C->insertBefore(At->getIterator());
  subst[V] = C;
  return C;
}

// ---- model ----------------------------------------------------------------------------------------------------------------------
enum Region { PRO, PLOOP, MAIN, POST };
struct Acc {
  Instruction *I = nullptr;     // ldmatrix / cp.async call, load, store
  GetElementPtrInst *G = nullptr;
  Value *idx = nullptr;
  bool write = false, cp = false;
  unsigned bytes = 0;
  Region reg = POST;
  int o = -1;                   // main loop / prologue loop: stage at t = 0 (mod S)
  int64_t a = 0;
  int cls = -1;
  std::vector<uint64_t> x0;     // stage-0 address for every thread
  int stage = -1;               // straight-line prologue: stage
  bool before = false;          // main loop: before the barrier
};
struct Site {                   // one copy site in the main loop (or a prologue event / prologue-loop site)
  Acc *A = nullptr;
  CallInst *C = nullptr;
  BasicBlock *guardPred = nullptr, *guardJoin = nullptr;   // triangle guardPred -> block(C) -> guardJoin
  bool guardTrueIsCopy = true;
  Value *guardCond = nullptr;
  int T = -1, Tn = -1;          // first tile in the loop, old / new
  int d = 0, q0 = 0;            // queue depth (iterations), first slot
  int k = -1;
};
struct RingVar { PHINode *phi; int64_t a; int o; };
struct Class { int64_t a, P, base, basen = 0; int rows = 1; std::set<uint64_t> chunks; };

struct Ctx {
  Function &F; DominatorTree DT; LoopInfo LI; GlobalVariable *GV; std::string why;
  Ctx(Function &F, GlobalVariable *G) : F(F), DT(F), LI(DT), GV(G) {}
};

static bool isZeroC(Value *V) { auto *K = dyn_cast<ConstantInt>(V); return K && K->isZero(); }
static bool idxOf(Value *P, GlobalVariable *GV, GetElementPtrInst *&G, Value *&idx) {
  G = dyn_cast<GetElementPtrInst>(P);
  if (!G || G->getPointerOperand() != GV) return false;
  if (G->getNumIndices() == 2 && isZeroC(G->getOperand(1))) { idx = G->getOperand(2); return true; }
  if (G->getNumIndices() == 1) { idx = G->getOperand(1); return true; }
  return false;
}

// all accesses to the shared area; false when something else touches it
static bool collect(Ctx &X, std::vector<Acc> &A, std::vector<CallInst *> &barred) {
  for (BasicBlock &BB : X.F) for (Instruction &I : BB) {
    if (auto *C = dyn_cast<CallInst>(&I)) {
      if (isBarRed(C)) { barred.push_back(C); continue; }
      if (isCp(C) || isLdsm(C)) {
        unsigned ai = isCp(C) ? 0 : C->arg_size() - 1;
        auto *PI = dyn_cast<PtrToIntInst>(C->getArgOperand(ai));
        Acc a; a.I = C; a.cp = isCp(C); a.write = a.cp; a.bytes = 16;
        if (!PI || !idxOf(PI->getOperand(0), X.GV, a.G, a.idx)) { X.why = "asm address is not ptrtoint(gep @shared_mem)"; return false; }
        if (a.cp && !asmHas(C, ", 16")) { X.why = "cp.async of a size other than 16"; return false; }
        A.push_back(a);
      } else if (isa<InlineAsm>(C->getCalledOperand()) && (asmHas(C, ".shared") || asmHas(C, "stmatrix"))) { X.why = "other shared asm"; return false; }
      continue;
    }
    Value *P = nullptr; bool w = false; unsigned b = 0;
    const DataLayout &DL = X.F.getDataLayout();
    if (auto *L = dyn_cast<LoadInst>(&I)) { P = L->getPointerOperand(); b = DL.getTypeStoreSize(L->getType()); }
    else if (auto *S = dyn_cast<StoreInst>(&I)) { P = S->getPointerOperand(); w = true; b = DL.getTypeStoreSize(S->getValueOperand()->getType()); }
    else if (isa<AtomicRMWInst>(&I) || isa<AtomicCmpXchgInst>(&I)) { if (I.getOperand(0)->getType()->getPointerAddressSpace() == 3) { X.why = "shared atomic"; return false; } continue; }
    else continue;
    if (P->getType()->getPointerAddressSpace() != 3) continue;
    Acc a; a.I = &I; a.write = w; a.bytes = b;
    if (!idxOf(P, X.GV, a.G, a.idx)) { X.why = "shared load/store not through gep @shared_mem"; return false; }
    A.push_back(a);
  }
  return true;
}

// xmma form: the prologue loop runs min(tiles, S-1) rounds and a padding loop advances the write ring by the rest, so the ring
// value at main-loop entry is a constant although it flows through two loops whose trip counts depend on a kernel parameter. Walk
// the blocks from the prologue loop's guard to the main loop's preheader for every value of that one parameter in a range: the
// main-loop header phis that come out the same every time are constants. More than one parameter in the branches: no result.
static void ringInit(Ctx &X, Loop *Lm, Loop *Lp, DenseMap<PHINode *, uint64_t> &ov) {
  BasicBlock *PP = Lp->getLoopPreheader(), *Pre = Lm->getLoopPreheader();
  if (!PP || !Pre) return;
  auto *N = X.DT.getNode(PP)->getIDom();
  if (!N) return;
  BasicBlock *St = N->getBlock();
  std::vector<int64_t> ps;
  for (int64_t p = -8; p < 600; ++p) ps.push_back(p);
  for (int64_t p = 1024; p < (1 << 24); p *= 2) { ps.push_back(p - 1); ps.push_back(p); }
  std::map<int64_t, uint64_t> par; int64_t off = -1;
  DenseMap<PHINode *, OV> res; bool first = true;
  SmallPtrSet<BasicBlock *, 32> reach;   // a sample that leaves these blocks never enters the main loop
  { SmallVector<BasicBlock *, 16> w{Pre}; while (!w.empty()) { BasicBlock *q = w.pop_back_val(); if (reach.insert(q).second) for (BasicBlock *u : predecessors(q)) w.push_back(u); } }
  for (size_t ip2 = 0; ip2 < 2 * ps.size(); ++ip2) {
    size_t ip = ip2 / 2; unsigned pol = ip2 & 1;   // a branch on anything else goes one way, then the other: the result must not change
    if (off >= 0) par[off] = (uint64_t)ps[ip];
    DenseMap<Value *, uint64_t> env;
    BasicBlock *cur = St, *prev = nullptr;
    int steps = 0;
    while (cur != Pre) {
      if (++steps > 40000) return;
      if (prev) {
        DenseMap<Value *, uint64_t> nv; std::vector<Value *> gone;
        Eval e; e.env = &env; e.params = &par;
        for (PHINode &Ph : cur->phis()) {
          if (!Ph.getType()->isIntegerTy()) continue;
          OV v = e.get(Ph.getIncomingValueForBlock(prev));
          if (v) nv[&Ph] = *v; else gone.push_back(&Ph);
        }
        for (Value *g : gone) env.erase(g);
        for (auto &kv : nv) env[kv.first] = kv.second;
      }
      auto *T = cur->getTerminator();
      auto *Br = dyn_cast<BranchInst>(T);
      if (!Br) return;
      BasicBlock *nx;
      if (!Br->isConditional()) nx = Br->getSuccessor(0);
      else {
        Eval e; e.env = &env; e.params = &par;
        OV c = e.get(Br->getCondition());
        if (!c) {
          if (e.missing >= 0 && off < 0) { off = e.missing; par[off] = (uint64_t)ps[ip]; ip2 -= 1; goto again; }
          c = pol;
        }
        nx = Br->getSuccessor(*c ? 0 : 1);
      }
      if (!reach.count(nx)) goto again;
      prev = cur; cur = nx;
    }
    {
      Eval e; e.env = &env; e.params = &par;
      for (PHINode &Ph : Lm->getHeader()->phis()) {
        if (!Ph.getType()->isIntegerTy()) continue;
        OV v = e.get(Ph.getIncomingValueForBlock(Pre));
        if (first) res[&Ph] = v;
        else if (res[&Ph] != v) res[&Ph] = std::nullopt;
      }
      first = false;
    }
    again:;
  }
  for (auto &kv : res) if (kv.second) ov[kv.first] = *kv.second;
}

struct Sim {
  std::vector<RingVar> ring; int S = 0;
  std::vector<std::vector<DenseMap<Value *, uint64_t>>> env;   // [t][tid]
};
// recover the ring of loop L for n threads; len = iterations to tabulate after S is known
static bool simulate(Ctx &X, Loop *L, unsigned n, Sim &R, const DenseMap<PHINode *, uint64_t> *ov = nullptr) {
  BasicBlock *H = L->getHeader(), *pre = L->getLoopPreheader(), *latch = L->getLoopLatch();
  if (!pre || !latch) { X.why = "loop without preheader or single latch"; return false; }
  std::vector<PHINode *> cand;
  for (PHINode &P : H->phis()) if (P.getType()->isIntegerTy() && P.getType()->getIntegerBitWidth() <= 64) cand.push_back(&P);
  const int N = 48, SMAX = 16;
  std::vector<std::vector<std::vector<int64_t>>> seq;    // [tid][phi][t]
  for (;;) {                                              // drop the phis that cannot be simulated, until the rest closes
    seq.assign(n, {});
    PHINode *bad = nullptr;
    for (unsigned tid = 0; tid < n && !bad; ++tid) {
      DenseMap<Value *, uint64_t> st;
      { Eval e; e.tid = tid; for (PHINode *P : cand) { OV v = e.get(P->getIncomingValueForBlock(pre)); if (!v && ov) { auto q = ov->find(P); if (q != ov->end()) v = q->second; } if (!v) { bad = P; if (getenv("P2C_DEBUG")) { std::function<void(Value *, int)> w = [&](Value *q, int d) { if (e.get(q) || d > 14) return; errs() << "  init unknown: " << *q << "\n"; if (auto *I = dyn_cast<Instruction>(q)) if (!isa<PHINode>(I)) for (Value *o : I->operands()) w(o, d + 1); }; w(P->getIncomingValueForBlock(pre), 0); } break; } st[P] = *v; } }
      if (bad) break;
      auto &sq = seq[tid]; sq.assign(cand.size(), std::vector<int64_t>(N));
      for (int t = 0; t < N && !bad; ++t) {
        Eval e; e.tid = tid; e.env = &st;
        DenseMap<Value *, uint64_t> nx;
        for (size_t i = 0; i < cand.size(); ++i) {
          sq[i][t] = Eval::sx(st[cand[i]], cand[i]->getType()->getIntegerBitWidth());
          OV v = e.get(cand[i]->getIncomingValueForBlock(latch));
          if (!v) { bad = cand[i]; break; }
          nx[cand[i]] = *v;
        }
        st = nx;
      }
    }
    if (!bad) break;
    cand.erase(std::find(cand.begin(), cand.end(), bad));
    if (cand.empty()) { X.why = "no simulated phi in the loop"; return false; }
  }
  // periodic arithmetic rings
  std::vector<int> per(cand.size(), 0);
  std::map<int, int> votes;
  for (size_t i = 0; i < cand.size(); ++i) {
    auto &q = seq[0][i];
    for (int p = 2; p <= SMAX; ++p) {
      bool ok = true;
      for (int t = 0; t + p < N; ++t) if (q[t + p] != q[t]) { ok = false; break; }
      if (ok) { per[i] = p; votes[p]++; break; }
    }
  }
  if (votes.empty()) { X.why = "no periodic phi"; return false; }
  int S = 0, best = 0;
  for (auto &v : votes) if (v.second >= best) { best = v.second; S = v.first; }
  R.S = S; R.ring.clear();
  for (size_t i = 0; i < cand.size(); ++i) {
    if (per[i] != S) continue;
    std::set<int64_t> vals(seq[0][i].begin(), seq[0][i].begin() + S);
    if ((int)vals.size() != S) continue;
    std::vector<int64_t> v(vals.begin(), vals.end());
    int64_t a = v[1] - v[0]; bool ok = true;
    for (int j = 1; j < S; ++j) if (v[j] - v[j - 1] != a) ok = false;
    if (!ok) continue;
    int o = (seq[0][i][0] - v[0]) / a;
    for (unsigned tid = 0; tid < n && ok; ++tid) {
      int64_t base = *std::min_element(seq[tid][i].begin(), seq[tid][i].begin() + S);
      for (int t = 0; t < S; ++t) if (seq[tid][i][t] != base + ((t + o) % S) * a) ok = false;
    }
    if (ok) R.ring.push_back({cand[i], a, o});
  }
  if (R.ring.empty()) { X.why = "no arithmetic ring"; return false; }
  R.env.assign(S, std::vector<DenseMap<Value *, uint64_t>>(n));
  for (int t = 0; t < S; ++t) for (unsigned tid = 0; tid < n; ++tid) for (size_t i = 0; i < cand.size(); ++i) {
    unsigned w = cand[i]->getType()->getIntegerBitWidth();
    R.env[t][tid][cand[i]] = (uint64_t)seq[tid][i][t] & Eval::mask(w);
  }
  return true;
}

// ---- the plan -------------------------------------------------------------------------------------------------------------------
struct Plan {
  int S = 0, Sn = 0, delta = 0; unsigned n = 0; Loop *Lm = nullptr, *Lp = nullptr; Sim sm, sp;
  std::vector<Class> cls; std::vector<Site> sites; std::vector<Acc *> mainReads;
  struct Ev { Acc *A; int k; int tile; };
  std::vector<Ev> events;       // straight-line prologue events
  std::vector<Acc *> proReads;
  std::vector<std::pair<Acc *, int>> ploop;   // prologue-loop site, its k
  Instruction *bar = nullptr;
  uint64_t epiMax = 0, foot = 0, N = 0;
  bool needG = false;
  DenseMap<PHINode *, uint64_t> ov;   // main-loop phis constant at entry through the prologue loop
};

static bool guardOf(Ctx &X, Site &s) {
  BasicBlock *B = s.C->getParent(), *P = B->getSinglePredecessor();
  if (!P) return false;
  auto *T = dyn_cast<BranchInst>(P->getTerminator()), *E = dyn_cast<BranchInst>(B->getTerminator());
  if (!T || !T->isConditional() || !E || E->isConditional()) return false;
  BasicBlock *J = E->getSuccessor(0);
  if (T->getSuccessor(0) == B && T->getSuccessor(1) == J) s.guardTrueIsCopy = true;
  else if (T->getSuccessor(1) == B && T->getSuccessor(0) == J) s.guardTrueIsCopy = false;
  else return false;
  s.guardPred = P; s.guardJoin = J; s.guardCond = T->getCondition();
  return true;
}

// class of a stage-s address: returns class index and sets s, x0; -1 when it is in no class
static int classify(std::vector<Class> &cls, uint64_t x, int &s, uint64_t &x0) {
  for (size_t i = 0; i < cls.size(); ++i) {
    Class &c = cls[i];
    if ((int64_t)x < c.base) continue;
    uint64_t y = x - c.base, row = y / c.P, col = y % c.P;
    int st = col / c.a; uint64_t cc = col % c.a, z = c.base + row * c.P + cc;
    if (c.chunks.count(z & ~15ull)) { s = st; x0 = z; return i; }
  }
  return -1;
}

static bool analyse(Ctx &X, std::vector<Acc> &A, Plan &P, unsigned n, int Sn) {
  P = Plan(); P.n = n; P.Sn = Sn;
  // main loop and prologue loop
  std::set<Loop *> withAll, withCp;
  for (Loop *L : X.LI.getLoopsInPreorder()) {
    bool cp = false, ld = false, ba = false;
    for (BasicBlock *B : L->blocks()) for (Instruction &I : *B) {
      if (auto *C = dyn_cast<CallInst>(&I)) { cp |= isCp(C); ld |= isLdsm(C); ba |= isBar(C); }
      if (auto *Lq = dyn_cast<LoadInst>(&I)) ld |= Lq->getPointerAddressSpace() == 3;
    }
    if (cp) withCp.insert(L);
    if (cp && ld && ba) withAll.insert(L);
  }
  for (Loop *L : withAll) { bool inner = true; for (Loop *Q : withAll) if (Q != L && L->contains(Q)) inner = false; if (inner) { if (P.Lm) { X.why = "two main loops"; return false; } P.Lm = L; } }
  if (!P.Lm) { X.why = "no loop with cp.async, shared reads and a barrier"; return false; }
  for (Loop *L : withCp) if (L != P.Lm && !L->contains(P.Lm) && !P.Lm->contains(L)) { if (P.Lp) { X.why = "two prologue loops"; return false; } P.Lp = L; }
  Loop *Lm = P.Lm; BasicBlock *H = Lm->getHeader();
  if (!Lm->getSubLoops().empty()) { X.why = "main loop has a subloop"; return false; }
  // what the main loop may contain
  for (BasicBlock *B : Lm->blocks()) for (Instruction &I : *B) {
    if (isBar(&I)) { if (P.bar) { X.why = "two barriers in the main loop"; return false; } P.bar = &I; continue; }
    if (auto *C = dyn_cast<CallInst>(&I)) {
      if (isCp(C) || isLdsm(C) || isa<IntrinsicInst>(C)) { if (isBarRed(C)) { X.why = "barrier reduction in the main loop"; return false; } continue; }
      if (asmHas(C, "activemask")) continue;
      if (!C->onlyReadsMemory() && !C->doesNotAccessMemory()) { X.why = "call with side effects in the main loop"; return false; }
    } else if (auto *S = dyn_cast<StoreInst>(&I)) {
      if (!isa<AllocaInst>(getUnderlyingObject(S->getPointerOperand()))) { X.why = "store in the main loop"; return false; }
    }
  }
  if (!P.bar) { X.why = "no barrier in the main loop"; return false; }
  if (P.Lp) ringInit(X, Lm, P.Lp, P.ov);
  if (!simulate(X, Lm, n, P.sm, &P.ov)) return false;
  int S = P.S = P.sm.S;
  if (Sn >= S) { X.why = "already at or below the target stage count"; return false; }
  P.delta = S - Sn;
  if (Sn < 1) { X.why = "bad target stage count"; return false; }
  if (P.Lp && !simulate(X, P.Lp, n, P.sp)) return false;
  if (P.Lp && P.sp.S != S) { X.why = "prologue loop has another period"; return false; }
  // regions
  BasicBlock *Lat = Lm->getLoopLatch();
  for (Acc &a : A) {
    BasicBlock *B = a.I->getParent();
    if (Lm->contains(B)) a.reg = MAIN;
    else if (P.Lp && P.Lp->contains(B)) a.reg = PLOOP;
    else if (X.DT.dominates(B, H)) a.reg = PRO;
    else {
      SmallVector<BasicBlock *, 8> work{B}; SmallPtrSet<BasicBlock *, 32> seen;
      while (!work.empty()) { BasicBlock *Q = work.pop_back_val(); if (Q == H) { X.why = "access before the main loop that does not dominate it"; return false; } if (seen.insert(Q).second) for (BasicBlock *U : successors(Q)) work.push_back(U); }
      a.reg = POST;
    }
    if (a.reg == MAIN && a.write && !a.cp) { X.why = "plain shared store in the main loop"; return false; }
    if (a.cp && a.reg == POST) { X.why = "cp.async after the main loop"; return false; }
  }
  // main-loop addresses at every stage
  for (Acc &a : A) if (a.reg == MAIN) a.x0.assign(n, 0);
  std::vector<std::vector<std::vector<uint64_t>>> val(A.size());
  for (size_t i = 0; i < A.size(); ++i) if (A[i].reg == MAIN) val[i].assign(S, std::vector<uint64_t>(n));
  for (int t = 0; t < S; ++t) for (unsigned tid = 0; tid < n; ++tid) {
    Eval e; e.tid = tid; e.env = &P.sm.env[t][tid];
    for (size_t i = 0; i < A.size(); ++i) if (A[i].reg == MAIN) {
      OV v = e.get(A[i].idx);
      if (!v) { X.why = "main-loop address not a function of the thread and the ring"; if (getenv("P2C_DEBUG")) { std::function<void(Value *, int)> w = [&](Value *q, int d) { if (e.get(q) || d > 12) return; errs() << "  unknown: " << *q << "\n"; if (auto *I = dyn_cast<Instruction>(q)) if (!isa<PHINode>(I)) for (Value *o : I->operands()) w(o, d + 1); }; w(A[i].idx, 0); } return false; }
      val[i][t][tid] = *v;
    }
  }
  for (size_t i = 0; i < A.size(); ++i) if (A[i].reg == MAIN) {
    Acc &a = A[i];
    for (unsigned tid = 0; tid < n; ++tid) {
      std::vector<uint64_t> v; for (int t = 0; t < S; ++t) v.push_back(val[i][t][tid]);
      std::vector<uint64_t> w = v; std::sort(w.begin(), w.end());
      if (w[0] == w[S - 1]) { X.why = "main-loop access outside the ring"; return false; }
      int64_t d = w[1] - w[0]; int t0 = std::find(v.begin(), v.end(), w[0]) - v.begin(), o = (S - t0) % S;
      for (int t = 0; t < S; ++t) if ((int64_t)(v[t] - w[0]) != ((t + o) % S) * d) { X.why = "main-loop access not periodic in the ring"; return false; }
      if (tid == 0) { a.a = d; a.o = o; } else if (a.a != d || a.o != o) { X.why = "stage stride differs across threads"; return false; }
      a.x0[tid] = w[0];
    }
  }
  // classes
  std::map<int64_t, std::vector<Acc *>> byA;
  for (Acc &a : A) if (a.reg == MAIN) byA[a.a].push_back(&a);
  for (auto &g : byA) {
    Class c; c.a = g.first; c.P = (int64_t)S * c.a; c.base = INT64_MAX;
    for (Acc *a : g.second) for (uint64_t x : a->x0) c.base = std::min<int64_t>(c.base, x);
    int rows = 0;
    for (Acc *a : g.second) for (uint64_t x : a->x0) {
      uint64_t y = x - c.base;
      if ((int64_t)(y % c.P) >= c.a) { X.why = "address outside the stage-0 slice of its row"; return false; }
      rows = std::max<int>(rows, y / c.P + 1);
      if (a->cp) { if (x & 15) { X.why = "unaligned chunk"; return false; } if (!c.chunks.insert(x).second) { X.why = "two copies write one chunk"; return false; } }
    }
    c.rows = rows;
    if ((int64_t)c.chunks.size() * 16 != (int64_t)rows * c.a) { X.why = "copies do not fill the stage"; return false; }
    for (Acc *a : g.second) if (!a->cp) for (uint64_t x : a->x0) if (!c.chunks.count(x & ~15ull)) { X.why = "a read outside what the copies write"; return false; }
    for (Acc *a : g.second) a->cls = P.cls.size();
    P.cls.push_back(c);
  }
  // main-loop reads and sites around the barrier
  BasicBlock *Bb = P.bar->getParent();
  auto beforeBar = [&](Instruction *I, BasicBlock *Blk, int &res) {
    if (Blk == Bb) { res = I->comesBefore(P.bar); return true; }
    if (X.DT.dominates(Blk, Bb)) { res = 1; return true; }
    if (X.DT.dominates(Bb, Blk)) { res = 0; return true; }
    return false;
  };
  for (Acc &a : A) if (a.reg == MAIN) {
    int bf = 0;
    if (a.cp) {
      Site s; s.A = &a; s.C = cast<CallInst>(a.I); s.k = P.sites.size();
      BasicBlock *B = s.C->getParent();
      if (!X.DT.dominates(B, Lat)) { if (!guardOf(X, s) || !X.DT.dominates(s.guardPred, Lat) || !Lm->contains(s.guardPred)) { X.why = "copy site not run once per iteration"; return false; } P.needG = true; B = s.guardPred; }
      if (!beforeBar(s.guardPred ? s.guardPred->getTerminator() : a.I, B, bf)) { X.why = "copy site not ordered with the barrier"; return false; }
      a.before = bf;
      P.sites.push_back(s);
    } else {
      if (!X.DT.dominates(a.I->getParent(), Lat) || !beforeBar(a.I, a.I->getParent(), bf)) { X.why = "read not run once per iteration"; return false; }
      a.before = bf;
      if ((bf && a.o != 0) || (!bf && a.o != 1 % S)) { X.why = "read of a stage other than the current one"; return false; }
      P.mainReads.push_back(&a);
    }
  }
  if (P.sites.empty()) { X.why = "no copy site"; return false; }
  std::map<std::vector<uint64_t>, int> byVec;
  for (Site &s : P.sites) { if (byVec.count(s.A->x0)) { X.why = "two sites with one chunk vector"; return false; } byVec[s.A->x0] = s.k; }
  // prologue
  std::vector<std::vector<int>> tiles(P.sites.size());
  std::vector<int> evK; 
  for (Acc &a : A) if (a.reg == PRO) {
    a.x0.assign(n, 0); int st = -1, cl = -1;
    for (unsigned tid = 0; tid < n; ++tid) {
      Eval e; e.tid = tid; OV v = e.get(a.idx);
      if (!v) { X.why = "prologue address not a function of the thread"; return false; }
      int s2 = 0; uint64_t z = 0; int c2 = classify(P.cls, *v, s2, z);
      if (c2 < 0) { X.why = "prologue address outside the classes"; return false; }
      if ((st >= 0 && st != s2) || (cl >= 0 && cl != c2)) { X.why = "prologue access mixes stages"; return false; }
      st = s2; cl = c2; a.x0[tid] = z;
    }
    a.stage = st; a.cls = cl;
    if (a.cp) {
      auto it = byVec.find(a.x0);
      if (it == byVec.end()) { X.why = "prologue copy matches no loop site"; return false; }
      if (!X.DT.dominates(a.I->getParent(), H)) { X.why = "guarded prologue copy"; return false; }
      tiles[it->second].push_back(st);
      P.events.push_back({&a, it->second, st});
    } else {
      if (st != 0) { X.why = "prologue read of a stage other than 0"; return false; }
      P.proReads.push_back(&a);
    }
  }
  if (P.Lp) {
    for (Acc &a : A) if (a.reg == PLOOP) {
      if (!a.cp) { X.why = "prologue loop reads shared memory"; return false; }
      a.x0.assign(n, 0);
      for (unsigned tid = 0; tid < n; ++tid) {
        std::vector<uint64_t> z(S - 1);
        for (int c = 0; c < S - 1; ++c) {
          Eval e; e.tid = tid; e.env = &P.sp.env[c][tid];
          OV v = e.get(a.idx);
          if (!v) { X.why = "prologue-loop address not a function of the thread and the ring"; return false; }
          int s2 = 0; uint64_t x0 = 0; int c2 = classify(P.cls, *v, s2, x0);
          if (c2 < 0 || s2 != c) { X.why = "prologue-loop round is not its stage"; return false; }
          if (c == 0) { a.x0[tid] = x0; a.cls = c2; } else if (a.x0[tid] != x0 || a.cls != c2) { X.why = "prologue-loop chunk moves"; return false; }
        }
      }
      auto it = byVec.find(a.x0);
      if (it == byVec.end()) { X.why = "prologue-loop copy matches no loop site"; return false; }
      for (int c = 0; c < S - 1; ++c) tiles[it->second].push_back(c);
      P.ploop.push_back({&a, it->second});
    }
  }
  for (Site &s : P.sites) {
    auto &t = tiles[s.k]; std::sort(t.begin(), t.end());
    for (size_t i = 0; i < t.size(); ++i) if (t[i] != (int)i) { X.why = "prologue tiles of a site are not 0..m-1"; return false; }
    s.T = t.size();
    if (s.T % S != s.A->o) { X.why = "site's first loop tile does not match its stage"; return false; }
    if (Sn == 1) {   // all copies of tile t+1 move between a new barrier and the loop's barrier
      s.Tn = 1; s.d = s.T - 1;
      if (s.d < 1) { X.why = "site without a tile in flight"; return false; }
      continue;
    }
    s.Tn = s.T - P.delta; s.d = P.delta;
    if (s.Tn < 1) { X.why = "site would have no prologue tile"; return false; }
    bool bf = s.A->before;
    if (bf ? (s.Tn % Sn == 0) : (s.Tn % Sn == 1 % Sn)) { X.why = "write stage would collide with the read stage"; return false; }
    if (!bf && s.Tn < 2) { X.why = "tile written after the barrier that precedes its reads"; return false; }
  }
  for (auto &e : P.events) if (e.tile >= P.sites[e.k].T) { X.why = "event beyond the site's first tile"; return false; }
  // sizes; rest of the function
  P.foot = 0; 
  { std::vector<size_t> ord(P.cls.size()); for (size_t i = 0; i < ord.size(); ++i) ord[i] = i;
    std::sort(ord.begin(), ord.end(), [&](size_t a, size_t b) { return P.cls[a].base < P.cls[b].base; });
    for (size_t i : ord) { P.cls[i].basen = P.foot; P.foot += (uint64_t)P.cls[i].rows * Sn * P.cls[i].a; } }
  for (Acc &a : A) if (a.reg == POST) {
    for (unsigned tid = 0; tid < n; ++tid) {
      Eval e; e.tid = tid; OV v = e.get(a.idx);
      if (!v) { X.why = "epilogue address unknown"; return false; }
      P.epiMax = std::max<uint64_t>(P.epiMax, *v + a.bytes);
    }
  }
  P.N = (std::max(P.foot, P.epiMax) + 15) & ~15ull;
  // ring phis may only feed the ring and the addresses
  SmallPtrSet<Value *, 32> dead;
  for (RingVar &r : P.sm.ring) dead.insert(r.phi);
  for (RingVar &r : P.sm.ring) for (User *U : r.phi->users()) if (auto *I = dyn_cast<Instruction>(U)) if (!Lm->contains(I->getParent()) && !isa<PHINode>(I)) { X.why = "ring value used after the loop"; return false; }
  return true;
}

// ---- rewrite --------------------------------------------------------------------------------------------------------------------
struct FCache { int cls; std::vector<uint64_t> f; Value *v; };

static uint64_t Fof(Class &c, int Sn, uint64_t x0) { uint64_t y = x0 - c.base; return c.basen + (y / c.P) * (uint64_t)Sn * c.a + y % c.P; }

// F(x) for a stage-0 address x (i32, at B's insertion point); reuses an earlier F in reach when they differ by a constant for every thread
static Value *emitF(IRBuilder<> &B, Ctx &X, Plan &P, std::vector<FCache> &cache, int ci, Value *x, const std::vector<uint64_t> &x0) {
  Class &c = P.cls[ci];
  std::vector<uint64_t> f; for (uint64_t v : x0) f.push_back(Fof(c, P.Sn, v));
  Instruction *At = &*B.GetInsertPoint();
  for (FCache &e : cache) {
    if (e.cls != ci) continue;
    auto *EI = dyn_cast<Instruction>(e.v);
    if (EI && !X.DT.dominates(EI, At)) continue;
    int64_t d = f[0] - e.f[0]; bool ok = true;
    for (size_t i = 0; i < f.size(); ++i) if ((int64_t)(f[i] - e.f[i]) != d) ok = false;
    if (ok) return d ? B.CreateAdd(e.v, B.getInt32(d), "p2c.f") : e.v;
  }
  bool same = true; uint64_t r0 = (x0[0] - c.base) / c.P;
  for (uint64_t v : x0) if ((v - c.base) / c.P != r0) same = false;
  Value *r;
  if (same) r = B.CreateAdd(x, B.getInt32((int64_t)(c.basen + r0 * P.Sn * c.a) - (int64_t)(c.base + r0 * c.P)), "p2c.f");
  else {
    Value *y = B.CreateSub(x, B.getInt32(c.base));
    Value *row = B.CreateUDiv(y, B.getInt32(c.P)), *col = B.CreateURem(y, B.getInt32(c.P));
    r = B.CreateAdd(B.CreateAdd(B.CreateMul(row, B.getInt32(P.Sn * c.a)), col), B.getInt32(c.basen), "p2c.f");
  }
  cache.push_back({ci, f, r});
  return r;
}

static void setAddr(Acc &a, Value *newIdx) {   // same shape as the original: gep [N x i8], ptr @shared_mem, 0, idx
  IRBuilder<> B(a.I);
  SmallVector<Value *, 2> ix;
  if (a.G->getNumIndices() == 2) ix.push_back(a.G->getOperand(1));
  ix.push_back(B.CreateZExt(newIdx, B.getInt64Ty()));
  Value *G = B.CreateGEP(a.G->getSourceElementType(), a.G->getPointerOperand(), ix, "p2c.sm");
  if (auto *C = dyn_cast<CallInst>(a.I)) {
    unsigned ai = isCp(C) ? 0 : C->arg_size() - 1;
    C->setArgOperand(ai, B.CreatePtrToInt(G, B.getInt64Ty(), "p2c.smp"));
  } else if (auto *L = dyn_cast<LoadInst>(a.I)) L->setOperand(0, G);
  else cast<StoreInst>(a.I)->setOperand(1, G);
}

// queue entry. No guard anywhere: 0 = zero fill, else the source. With guards: 0 = no copy, 1 = zero fill, else the source. (A valid source is never 0 or 1.)
static Value *pack(IRBuilder<> &B, Plan &P, Value *src, Value *sz, Value *g) {
  Value *e = src;
  if (sz) e = B.CreateSelect(B.CreateICmpNE(sz, ConstantInt::get(sz->getType(), 0)), e, B.getInt64(P.needG ? 1 : 0), "p2c.q");
  if (g) e = B.CreateSelect(g, e, B.getInt64(0), "p2c.q");
  return e;
}

static CallInst *emitCp(IRBuilder<> &B, Module &M, GlobalVariable *GV, Value *idx, Value *src, Value *szBit) {
  Value *G = B.CreateGEP(GV->getValueType(), GV, {B.getInt64(0), B.CreateZExt(idx, B.getInt64Ty())}, "p2c.sm");
  Value *dp = B.CreatePtrToInt(G, B.getInt64Ty(), "p2c.smp");
  Value *sz = B.CreateSelect(szBit, B.getInt32(16), B.getInt32(0), "p2c.sz");
  FunctionType *FT = FunctionType::get(B.getVoidTy(), {B.getInt64Ty(), B.getInt64Ty(), B.getInt32Ty()}, false);
  InlineAsm *IA = InlineAsm::get(FT, "cp.async.cg.shared.global [$0], [$1], 16, $2;", "l,l,r,~{memory}", true);
  return B.CreateCall(FT, IA, {dp, src, sz});
}

static void lowerBarRed(Function &F, GlobalVariable *GV, std::vector<CallInst *> &barred) {
  Module &M = *F.getParent(); LLVMContext &Cx = M.getContext();
  FunctionCallee Bar = M.getOrInsertFunction("llvm.nvvm.barrier0", FunctionType::get(Type::getVoidTy(Cx), false));
  FunctionCallee Tx = M.getOrInsertFunction("llvm.nvvm.read.ptx.sreg.tid.x", FunctionType::get(Type::getInt32Ty(Cx), false));
  Type *I32 = Type::getInt32Ty(Cx);
  for (CallInst *CI : barred) {
    StringRef n = CI->getCalledFunction()->getName();
    bool isAnd = n.ends_with(".and"), isOr = n.ends_with(".or");
    Value *Pd = CI->getArgOperand(0);
    IRBuilder<> B(CI);
    B.CreateCall(Bar);                                                   // every thread is past whatever used the word
    Value *t0 = B.CreateICmpEQ(B.CreateCall(Tx), B.getInt32(0), "p2c.t0");
    Instruction *Th = SplitBlockAndInsertIfThen(t0, CI->getIterator(), false);
    BasicBlock *ThB = Th->getParent(), *Pre = ThB->getSinglePredecessor();
    Value *old;
    { IRBuilder<> T(Th); old = T.CreateAtomicRMW(AtomicRMWInst::Xchg, GV, B.getInt32(isAnd ? 1 : 0), Align(4), AtomicOrdering::Monotonic); }
    BasicBlock *Cont = CI->getParent();
    IRBuilder<> C(&Cont->front());
    PHINode *Ph = C.CreatePHI(I32, 2, "p2c.saved"); Ph->addIncoming(old, ThB); Ph->addIncoming(UndefValue::get(I32), Pre);
    B.SetInsertPoint(CI);
    B.CreateCall(Bar);
    Value *bit = B.CreateZExt(B.CreateICmpNE(Pd, Constant::getNullValue(Pd->getType())), I32);
    B.CreateAtomicRMW(isAnd ? AtomicRMWInst::And : isOr ? AtomicRMWInst::Or : AtomicRMWInst::Add, GV, bit, Align(4), AtomicOrdering::Monotonic);
    B.CreateCall(Bar);
    LoadInst *R = B.CreateLoad(I32, GV, "p2c.red"); R->setAtomic(AtomicOrdering::Monotonic); R->setAlignment(Align(4));
    B.CreateCall(Bar);                                                   // every thread has read the result
    Instruction *Th2 = SplitBlockAndInsertIfThen(t0, CI->getIterator(), false);
    { IRBuilder<> T(Th2); T.CreateAtomicRMW(AtomicRMWInst::Xchg, GV, Ph, Align(4), AtomicOrdering::Monotonic); }
    B.SetInsertPoint(CI);
    B.CreateCall(Bar);                                                   // the word is back before anyone touches it again
    CI->replaceAllUsesWith(R);
    CI->eraseFromParent();
  }
}

static bool foldFunction(Function &F, GlobalVariable *GV, int Sn) {
  Ctx X(F, GV);
  std::vector<Acc> A; std::vector<CallInst *> barred;
  bool any = false;
  for (BasicBlock &BB : F) for (Instruction &I : BB) if (auto *C = dyn_cast<CallInst>(&I)) any |= isCp(C);
  std::string nm = F.getName().str().substr(0, 60);
  if (!any) { errs() << "[p2c-fold] " << nm << ": no cp.async, left as it is\n"; return false; }
  if (!collect(X, A, barred)) { errs() << "[p2c-fold] " << nm << ": left as it is: " << X.why << "\n"; return false; }
  // block size: the kernel's maxntidx, the launch's (P2C_BLOCK), or the smallest that fills the stages
  std::vector<unsigned> ns;
  unsigned ann = 0;
  if (NamedMDNode *NM = F.getParent()->getNamedMetadata("nvvm.annotations"))
    for (MDNode *Md : NM->operands()) if (Md->getNumOperands() >= 3) {
      auto *K = dyn_cast_or_null<MDString>(Md->getOperand(1)); auto *V = dyn_cast_or_null<ConstantAsMetadata>(Md->getOperand(2));
      if (K && V && K->getString() == "maxntidx") if (auto *CI = dyn_cast<ConstantInt>(V->getValue())) ann = CI->getZExtValue();
    }
  if (int e = envInt("P2C_BLOCK", 0)) ns = {(unsigned)e};
  else if (ann) ns = {ann};
  else ns = {32, 64, 128, 256, 512, 1024};
  Plan P; bool ok = false;
  for (unsigned n : ns) { X.why.clear(); if (analyse(X, A, P, n, Sn)) { ok = true; break; } }
  if (!ok) { errs() << "[p2c-fold] " << nm << ": left as it is: " << X.why << "\n"; return false; }
  { std::string s; raw_string_ostream os(s);
    os << "[p2c-fold] " << nm << ": ring S=" << P.S << " -> " << Sn << ", block " << P.n << ", sites " << P.sites.size() << ", prologue events " << P.events.size() << " loop-sites " << P.ploop.size() << ", guarded " << P.needG << ", classes:";
    for (Class &c : P.cls) os << " (a=" << c.a << " P=" << c.P << " base=" << c.base << " rows=" << c.rows << " -> " << c.basen << ")";
    os << ", ring footprint " << P.foot << ", epilogue top " << P.epiMax << ", @shared_mem " << P.N << " B, launch dyn_smem=0\n";
    errs() << s; }
  if (getenv("P2C_DRY")) return false;

  Module &M = *F.getParent(); LLVMContext &Cx = F.getContext();
  Loop *Lm = P.Lm; BasicBlock *H = Lm->getHeader(), *Pre = Lm->getLoopPreheader(), *Lat = Lm->getLoopLatch();
  int S = P.S; unsigned J = P.sites.size();
  Type *I64 = Type::getInt64Ty(Cx), *I32 = Type::getInt32Ty(Cx);
  IRBuilder<> EB(&*F.getEntryBlock().getFirstInsertionPt());
  // p3: S' = 1 keeps the queue as rows of d + 1 entries (row r, one column per site of that depth): a copy pops its entry where it runs, so nothing is loaded at the header and
  // spilled until the copy; each access is a row pointer + immediate. P2C_QROW=1 turns it on.
  const bool rowQ = Sn == 1 && envInt("P2C_QROW", 0);   // measured: conv +4.8%, cuBLAS -2.1%, the rest +-1%: off
  std::map<int, int> gBase, gCols; std::map<int, Value *> popP, pushP; unsigned nq = 0;
  if (rowQ) {
    for (Site &st : P.sites) { st.q0 = gCols[st.d]++; }
    for (auto &kv : gCols) { gBase[kv.first] = nq; nq += (kv.first + 1) * kv.second; }
  } else for (Site &st : P.sites) { st.q0 = nq; nq += st.d; }
  auto qEntry = [&](Site &st, int row) -> int { return gBase[st.d] + row * gCols[st.d] + st.q0; };
  AllocaInst *Q = EB.CreateAlloca(I64, EB.getInt32(nq), "p2c.q");
  if (P.Lp) for (unsigned i = 0; i < nq; ++i) EB.CreateStore(EB.getInt64(0), EB.CreateConstGEP1_32(I64, Q, i));
  // queue index per depth in the main loop
  IRBuilder<> LB(Lat->getTerminator());
  std::map<int, PHINode *> qis;
  for (Site &st : P.sites) if ((st.d > 1 || rowQ) && !qis.count(st.d)) {
    PHINode *ph = PHINode::Create(I32, 2, "p2c.qi", H->begin());
    Value *nx = LB.CreateAdd(ph, LB.getInt32(1));
    nx = LB.CreateSelect(LB.CreateICmpEQ(nx, LB.getInt32(st.d + (rowQ ? 1 : 0))), LB.getInt32(0), nx);
    ph->addIncoming(LB.getInt32(0), Pre); ph->addIncoming(nx, Lat);
    qis[st.d] = ph;
  }
  if (rowQ) {
    IRBuilder<> HB(&*H->getFirstNonPHIIt());
    for (auto &kv : qis) { int d = kv.first, c = gCols[d]; Value *qi = kv.second;
      popP[d] = HB.CreateGEP(I64, Q, HB.CreateAdd(HB.CreateMul(qi, HB.getInt32(c)), HB.getInt32(gBase[d])), "p2c.qpop");
      Value *row = HB.CreateSelect(HB.CreateICmpEQ(qi, HB.getInt32(0)), HB.getInt32(d), HB.CreateSub(qi, HB.getInt32(1)));
      pushP[d] = HB.CreateGEP(I64, Q, HB.CreateAdd(HB.CreateMul(row, HB.getInt32(c)), HB.getInt32(gBase[d])), "p2c.qpush"); }
  }
  auto slotOf = [&](IRBuilder<> &B, Site &st) -> Value * {
    if (rowQ) return B.CreateConstGEP1_32(I64, pushP[st.d], st.q0);
    if (st.d == 1) return B.CreateGEP(I64, Q, B.getInt32(st.q0));
    return B.CreateGEP(I64, Q, B.CreateAdd(qis[st.d], B.getInt32(st.q0)));
  };
  std::map<std::pair<int, int>, Value *> offs;
  auto stageOff = [&](int ci, int tile) -> Value * {   // ((t + tile) mod S') a, as i32, at iteration t
    if (Sn == 1) return ConstantInt::get(I32, 0);
    auto key = std::make_pair(ci, tile % Sn);
    auto it = offs.find(key);
    if (it != offs.end()) return it->second;
    int64_t a = P.cls[ci].a;
    PHINode *ph = PHINode::Create(I32, 2, "p2c.st", H->begin());
    IRBuilder<> L2(Lat->getTerminator());
    Value *nx = L2.CreateAdd(ph, L2.getInt32(a));
    nx = L2.CreateSelect(L2.CreateICmpEQ(nx, L2.getInt32(a * Sn)), L2.getInt32(0), nx);
    ph->addIncoming(ConstantInt::get(I32, (tile % Sn) * a), Pre); ph->addIncoming(nx, Lat);
    return offs[key] = ph;
  };
  // stage-0 slice of a main-loop address, in the preheader
  std::vector<FCache> cache;
  Instruction *PT = Pre->getTerminator();
  auto hoist = [&](Acc &a) -> Value * {
    DenseMap<Value *, Value *> subst;
    IRBuilder<> B(PT);
    int t0 = (S - a.o) % S;
    for (RingVar &r : P.sm.ring) {
      Value *init = r.phi->getIncomingValueForBlock(Pre);
      auto q = P.ov.find(r.phi);
      if (q != P.ov.end()) init = ConstantInt::get(r.phi->getType(), q->second);
      int64_t d = ((int64_t)((t0 + r.o) % S) - r.o) * r.a;
      subst[r.phi] = d ? B.CreateAdd(init, ConstantInt::get(init->getType(), d)) : init;
    }
    Value *x = cloneSlice(a.idx, PT, subst, X.DT);
    if (!x) report_fatal_error("p2c-fold: slice not clonable after the checks");
    x = B.CreateZExtOrTrunc(x, I32);
    return emitF(B, X, P, cache, a.cls, x, a.x0);
  };
  // main-loop reads
  for (Acc *a : P.mainReads) {
    Value *f = hoist(*a);
    IRBuilder<> B(a->I);
    setAddr(*a, B.CreateAdd(f, stageOff(a->cls, a->o), "p2c.a"));
  }
  // main-loop sites
  std::vector<Value *> popped(J, nullptr), hoisted(J, nullptr);
  IRBuilder<> HB2(&*H->getFirstNonPHIIt());
  if (Sn == 1 && !rowQ) for (Site &st : P.sites) popped[st.k] = HB2.CreateLoad(I64, slotOf(HB2, st), "p2c.qo");   // the slot is free for this iteration's push
  for (Site &st : P.sites) {
    Acc &a = *st.A; CallInst *C = st.C;
    hoisted[st.k] = hoist(a);
    Instruction *At = st.guardPred ? st.guardPred->getTerminator() : C;
    DenseMap<Value *, Value *> none;
    Value *src = cloneSlice(C->getArgOperand(1), At, none, X.DT);
    Value *sz = C->arg_size() == 3 ? cloneSlice(C->getArgOperand(2), At, none, X.DT) : nullptr;
    if (!src || (C->arg_size() == 3 && !sz)) report_fatal_error("p2c-fold: copy source not available at the guard");
    IRBuilder<> B(At);
    Value *g = nullptr;
    if (st.guardPred) g = st.guardTrueIsCopy ? st.guardCond : B.CreateNot(st.guardCond);
    Value *en = pack(B, P, src, sz, g);
    Value *sl = slotOf(B, st);
    if (Sn == 1) {
      B.CreateStore(en, sl);
      if (st.guardPred) {
        BasicBlock *Blk = C->getParent();
        BranchInst::Create(st.guardJoin, st.guardPred);
        cast<Instruction>(At)->eraseFromParent();
        C->eraseFromParent();
        DeleteDeadBlock(Blk);
      } else C->eraseFromParent();
      a.I = nullptr;
      continue;
    }
    Value *eo = B.CreateLoad(I64, sl, "p2c.qo");
    B.CreateStore(en, sl);
    Value *nzO = P.needG ? B.CreateICmpNE(eo, B.getInt64(1)) : B.CreateICmpNE(eo, B.getInt64(0));
    if (st.guardPred) {
      Value *gO = B.CreateICmpNE(eo, B.getInt64(0));
      auto *T = cast<BranchInst>(At);
      BasicBlock *Blk = C->getParent();
      BranchInst::Create(Blk, st.guardJoin, gO, st.guardPred);
      T->eraseFromParent();
    }
    IRBuilder<> CB(C);
    Value *idx = CB.CreateAdd(hoisted[st.k], stageOff(a.cls, st.Tn), "p2c.a");
    if (!st.guardPred && P.needG) { // unguarded site in a function with guards: an entry can be 0 only through a guarded event
      emitCp(CB, M, GV, idx, eo, nzO);
    } else emitCp(CB, M, GV, idx, eo, nzO);
    C->eraseFromParent(); a.I = nullptr;
  }
  // straight-line prologue reads and events
  for (Acc *a : P.proReads) {
    IRBuilder<> B(a->I);
    Value *x = B.CreateZExtOrTrunc(a->idx, I32);
    setAddr(*a, emitF(B, X, P, cache, a->cls, x, a->x0));
  }
  for (auto &e : P.events) {
    Acc &a = *e.A; Site &s = P.sites[e.k]; CallInst *C = cast<CallInst>(a.I);
    IRBuilder<> B(C);
    Value *x = B.CreateZExtOrTrunc(a.idx, I32);
    int64_t sh = (int64_t)a.stage * P.cls[a.cls].a;   // the event's stage part
    Value *x0 = sh ? B.CreateSub(x, B.getInt32(sh)) : x;
    if (e.tile < s.Tn) {
      Value *f = emitF(B, X, P, cache, a.cls, x0, a.x0);
      int ns = e.tile % P.Sn;
      setAddr(a, ns ? B.CreateAdd(f, B.getInt32(ns * P.cls[a.cls].a)) : f);
    } else {
      int t = e.tile - s.Tn;                       // popped by site k at iteration t
      Value *sz = C->arg_size() == 3 ? C->getArgOperand(2) : nullptr;
      Value *en = pack(B, P, C->getArgOperand(1), sz, nullptr);
      B.CreateStore(en, B.CreateGEP(I64, Q, B.getInt32(rowQ ? qEntry(s, t % s.d) : s.q0 + t % s.d)));
      C->eraseFromParent(); a.I = nullptr;
    }
  }
  // prologue loop: round c < T'_k copies, later rounds go to the queue
  if (P.Lp) {
    Loop *Lp = P.Lp; BasicBlock *PH = Lp->getHeader(), *PP = Lp->getLoopPreheader(), *PL = Lp->getLoopLatch();
    PHINode *c = PHINode::Create(I32, 2, "p2c.c", PH->begin());
    { IRBuilder<> B(PL->getTerminator()); Value *nx = B.CreateAdd(c, B.getInt32(1)); c->addIncoming(B.getInt32(0), PP); c->addIncoming(nx, PL); }
    Instruction *PPT = PP->getTerminator();
    std::vector<std::tuple<Acc *, int, Value *>> pl;
    for (auto &pr : P.ploop) {
      Acc &a = *pr.first;
      DenseMap<Value *, Value *> subst;
      IRBuilder<> B(PPT);
      for (RingVar &r : P.sp.ring) { Value *init = r.phi->getIncomingValueForBlock(PP); int64_t d = (0 - 0) * r.a; (void)d; subst[r.phi] = init; }
      Value *x = cloneSlice(a.idx, PPT, subst, X.DT);
      if (!x) report_fatal_error("p2c-fold: prologue-loop slice not clonable");
      x = B.CreateZExtOrTrunc(x, I32);
      pl.emplace_back(&a, pr.second, emitF(B, X, P, cache, a.cls, x, a.x0));
    }
    for (auto &tp : pl) {
      Acc &a = *std::get<0>(tp); int k = std::get<1>(tp); Value *f = std::get<2>(tp);
      Site &s = P.sites[k]; CallInst *C = cast<CallInst>(a.I);
      IRBuilder<> B(C);
      Value *run = B.CreateICmpSLT(c, B.getInt32(s.Tn));
      Instruction *Th = nullptr, *El = nullptr;
      SplitBlockAndInsertIfThenElse(run, C->getIterator(), &Th, &El);
      Value *sz = C->arg_size() == 3 ? C->getArgOperand(2) : nullptr;
      { IRBuilder<> T(Th);
        Value *cm = P.Sn > 1 ? T.CreateURem(c, T.getInt32(P.Sn)) : (Value *)T.getInt32(0);
        Value *idx = T.CreateAdd(f, T.CreateMul(cm, T.getInt32(P.cls[a.cls].a)), "p2c.a");
        Value *nz = sz ? T.CreateICmpNE(sz, ConstantInt::get(sz->getType(), 0)) : (Value *)T.getTrue();
        emitCp(T, M, GV, idx, C->getArgOperand(1), nz); }
      { IRBuilder<> E(El);
        Value *en = pack(E, P, C->getArgOperand(1), sz, nullptr);
        Value *rw = E.CreateSub(c, E.getInt32(s.Tn));
        E.CreateStore(en, E.CreateGEP(I64, Q, rowQ ? E.CreateAdd(E.CreateMul(rw, E.getInt32(gCols[s.d])), E.getInt32(qEntry(s, 0))) : E.CreateAdd(rw, E.getInt32(s.q0)))); }
      C->eraseFromParent(); a.I = nullptr;
    }
  }
  if (Sn == 1) {
    Module &Mm = M;
    FunctionCallee Bar = Mm.getOrInsertFunction("llvm.nvvm.barrier0", FunctionType::get(Type::getVoidTy(Cx), false));
    if (rowQ && envInt("P2C_QEARLY", 1)) for (Site &st : P.sites) { IRBuilder<> B(P.bar); popped[st.k] = B.CreateLoad(I64, B.CreateConstGEP1_32(I64, popP[st.d], st.q0), "p2c.qo"); }   // in flight during the barrier
    if (!getenv("P2C_NOBAR")) { IRBuilder<> B(P.bar); B.CreateCall(Bar); }   // P2C_NOBAR: measurement only (cost of this barrier), wrong results
    for (Site &st : P.sites) {
      Acc &a = *st.A;
      Value *eo = popped[st.k];
      if (rowQ && !eo) { IRBuilder<> B(P.bar); eo = B.CreateLoad(I64, B.CreateConstGEP1_32(I64, popP[st.d], st.q0), "p2c.qo"); }
      if (P.needG) {
        IRBuilder<> B(P.bar);
        Value *go = B.CreateICmpNE(eo, B.getInt64(0));
        Instruction *Th = SplitBlockAndInsertIfThen(go, P.bar->getIterator(), false);
        IRBuilder<> T(Th);
        emitCp(T, M, GV, hoisted[st.k], eo, T.CreateICmpNE(eo, T.getInt64(1)));
      } else {
        IRBuilder<> B(P.bar);
        emitCp(B, M, GV, hoisted[st.k], eo, B.CreateICmpNE(eo, B.getInt64(0)));
      }
      (void)a;
    }
  }
  if (!barred.empty()) lowerBarRed(F, GV, barred);
  // the shared area
  Type *NT = ArrayType::get(Type::getInt8Ty(Cx), P.N);
  auto *NG = new GlobalVariable(M, NT, false, GV->getLinkage(), nullptr, "", GV, GlobalValue::NotThreadLocal, 3);
  NG->setAlignment(GV->getAlign()); NG->takeName(GV);
  GV->replaceAllUsesWith(NG); GV->eraseFromParent();
  for (User *U : NG->users()) if (auto *G = dyn_cast<GetElementPtrInst>(U)) if (G->getSourceElementType()->isArrayTy()) { G->setSourceElementType(NT); }
  return true;
}


static bool isPotentiallyReachableHeader(BasicBlock *B, BasicBlock *H) {
  SmallVector<BasicBlock *, 8> w{B}; SmallPtrSet<BasicBlock *, 32> seen;
  while (!w.empty()) { BasicBlock *Q = w.pop_back_val(); if (Q == H) return true; if (seen.insert(Q).second) for (BasicBlock *U : successors(Q)) w.push_back(U); }
  return false;
}

// ---- p2c-alias: two single-buffered tiles that alternate between barriers share one area -------------------------------------------
// FlashAttention form: per block, barrier; copy V; read K (QK^T); barrier; copy next K; read V (PV). The copies only overlap the reads on
// real cp.async. CuPBoP copies synchronously, so V's copy can run after the K reads and the next K's after the V reads: with a barrier
// in front of the moved copies K and V never hold data at the same time and V can live on K's bytes (CTA area -1 tile).
// Checked: every access is a function of the thread; the two copy groups of the loop write disjoint, equal, dense ranges X and Y; in
// every barrier interval (blocks in reverse post order, back edge ignored) there is no read of both, no write of a tile together with a
// read of it, no write of both. Moved copies go in front of the interval's closing barrier or to the end of the last block that reads
// the other tile, with their guard. Everything else stays.
struct AEv { Acc *A; int tile; };   // tile 0 other, 1 X (stays), 2 Y (moves onto X)
static bool aliasFunction(Function &F, GlobalVariable *GV) {
  Ctx X(F, GV);
  std::string nm = F.getName().str().substr(0, 60);
  std::vector<Acc> A; std::vector<CallInst *> barred;
  auto no = [&](const char *w) { errs() << "[p2c-alias] " << nm << ": left as it is: " << w << "\n"; return false; };
  if (!collect(X, A, barred)) return no(X.why.c_str());
  if (!barred.empty()) return no("barrier reduction");
  unsigned n = envInt("P2C_BLOCK", 128);
  // stack slots with one store, same type and offset for every load; the alloca's address may go nowhere else
  std::map<std::pair<Value *, int64_t>, Value *> slots;
  { const DataLayout &DL = F.getDataLayout(); std::map<Value *, std::vector<std::tuple<int64_t, unsigned, Value *>>> st; std::set<Value *> esc;
    for (BasicBlock &BB : F) for (Instruction &I : BB) {
      if (auto *S = dyn_cast<StoreInst>(&I)) {
        int64_t off = 0; Value *b = GetPointerBaseWithConstantOffset(S->getPointerOperand(), off, DL);
        if (b && isa<AllocaInst>(b)) st[b].emplace_back(off, (unsigned)DL.getTypeStoreSize(S->getValueOperand()->getType()), S->getValueOperand());
        else if (auto *O = dyn_cast<AllocaInst>(getUnderlyingObject(S->getPointerOperand()))) esc.insert(O);   // a store at an unknown offset
        if (auto *O = dyn_cast<AllocaInst>(getUnderlyingObject(S->getValueOperand()))) esc.insert(O);
      } else if (auto *C = dyn_cast<CallBase>(&I)) { for (Value *O : C->args()) if (O->getType()->isPointerTy()) if (auto *Al = dyn_cast<AllocaInst>(getUnderlyingObject(O))) esc.insert(Al); }
    }
    auto reload = [&](Value *v, Value *b, int64_t o) {   // a value just read back from the slot and stored again (a spill that survives a loop)
      auto *Ph = dyn_cast<PHINode>(v);
      if (!Ph) return false;
      for (Value *in : Ph->incoming_values()) {
        auto *Ld = dyn_cast<LoadInst>(in); int64_t q = 0;
        if (!Ld || GetPointerBaseWithConstantOffset(Ld->getPointerOperand(), q, DL) != b || q != o) return false;
      }
      return true;
    };
    for (auto &kv : st) if (!esc.count(kv.first)) for (auto &e : kv.second) {
      int64_t o = std::get<0>(e); unsigned z = std::get<1>(e); bool one = !reload(std::get<2>(e), kv.first, o);
      for (auto &f : kv.second) if (&f != &e && o < std::get<0>(f) + (int64_t)std::get<1>(f) && std::get<0>(f) < o + (int64_t)z && !(std::get<0>(f) == o && reload(std::get<2>(f), kv.first, o))) one = false;
      if (one) slots[{kv.first, o}] = std::get<2>(e);
    } }
  Loop *Lm = nullptr;
  for (Loop *L : X.LI.getLoopsInPreorder()) {
    int bars = 0; bool cp = false;
    for (BasicBlock *B : L->blocks()) for (Instruction &I : *B) { bars += isBar(&I); if (auto *C = dyn_cast<CallInst>(&I)) cp |= isCp(C); }
    if (cp && bars == 2) { if (Lm) return no("two candidate loops"); Lm = L; }
  }
  if (!Lm) return no("no loop with cp.async and two barriers");
  BasicBlock *H = Lm->getHeader();
  // addresses
  for (Acc &a : A) {
    a.x0.assign(n, 0);
    for (unsigned t = 0; t < n; ++t) { Eval e; e.tid = t; e.slots = &slots; OV v = e.get(a.idx); if (!v) { if (getenv("P2C_DEBUG")) { std::function<void(Value *, int)> w = [&](Value *q, int d) { if (e.get(q) || d > 14) return; errs() << "  unknown: " << *q << " in " << a.I->getParent()->getName() << "\n"; if (auto *I = dyn_cast<Instruction>(q)) if (!isa<PHINode>(I)) for (Value *o : I->operands()) w(o, d + 1); }; w(a.idx, 0); } return no("address not a function of the thread"); } a.x0[t] = *v; }
  }
  // blocks in reverse post order, loop latch back edge ignored; barriers split them into intervals
  std::vector<BasicBlock *> rpo;
  { SmallPtrSet<BasicBlock *, 32> seen; std::function<void(BasicBlock *)> dfs = [&](BasicBlock *B) { if (!seen.insert(B).second) return; for (BasicBlock *U : successors(B)) if (!X.DT.dominates(U, B)) dfs(U); rpo.push_back(B); }; dfs(&F.getEntryBlock()); std::reverse(rpo.begin(), rpo.end()); }
  DenseMap<Instruction *, Acc *> accOf; for (Acc &a : A) accOf[a.I] = &a;
  // copy groups of the loop: between its two barriers, and after them
  std::vector<Acc *> g1, g2; int seenBar = 0;
  for (BasicBlock *B : rpo) if (Lm->contains(B)) for (Instruction &I : *B) {
    if (isBar(&I)) { ++seenBar; continue; }
    auto it = accOf.find(&I);
    if (it == accOf.end()) continue;
    if (it->second->cp) { if (seenBar == 1) g1.push_back(it->second); else if (seenBar == 2) g2.push_back(it->second); else return no("copy before the loop's first barrier"); }
  }
  if (g1.empty() || g2.empty()) return no("two copy groups not found");
  auto range = [&](std::vector<Acc *> &g, std::set<uint64_t> &ch) { for (Acc *a : g) for (uint64_t x : a->x0) { if (x & 15) return false; if (!ch.insert(x).second) return false; } return true; };
  std::set<uint64_t> c1, c2;
  if (!range(g1, c1) || !range(g2, c2)) return no("copies overlap or are unaligned");
  uint64_t b1 = *c1.begin(), b2 = *c2.begin(), e1 = *c1.rbegin() + 16, e2 = *c2.rbegin() + 16;
  if (e1 - b1 != c1.size() * 16 || e2 - b2 != c2.size() * 16 || e1 - b1 != e2 - b2 || (b1 < e2 && b2 < e1)) return no("tiles are not two disjoint dense ranges of one size");
  uint64_t lowB = std::min(b1, b2), hiB = std::max(b1, b2), sz = e1 - b1;
  auto tileOf = [&](Acc &a) { int t = -1; for (uint64_t x : a.x0) { int u = (x >= lowB && x < lowB + sz) ? 1 : (x >= hiB && x < hiB + sz) ? 2 : 0; if (t >= 0 && t != u) return -1; t = u; } return t; };
  for (Acc &a : A) { a.cls = tileOf(a); }
  // intervals; only accesses before the end of the loop count (what follows the loop is another layout: the footprint check below)
  bool afterLoop = false;
  struct Iv { bool r[3] = {false, false, false}, w[3] = {false, false, false}; Instruction *lastRead[3] = {nullptr, nullptr, nullptr}; Instruction *close = nullptr; std::vector<Acc *> cps; };
  std::vector<Iv> ivs(1);
  for (BasicBlock *B : rpo) {
    if (!afterLoop && !X.DT.dominates(B, H) && !Lm->contains(B) && !isPotentiallyReachableHeader(B, H)) afterLoop = true;
    if (afterLoop) break;
    for (Instruction &I : *B) {
      if (isBar(&I)) { ivs.back().close = &I; ivs.emplace_back(); continue; }
      auto it = accOf.find(&I);
      if (it == accOf.end()) continue;
      Acc &a = *it->second;
      if (a.cls < 0) return no("access spans two tiles");
      Iv &v = ivs.back();
      if (a.write) { if (!a.cp) { if (a.cls) return no("plain store to a tile"); continue; } v.w[a.cls] = true; if (a.cls) v.cps.push_back(&a); }
      else { v.r[a.cls] = true; v.lastRead[a.cls] = &I; }
    }
  }
  for (Iv &v : ivs) {
    if (v.r[1] && v.r[2]) return no("both tiles read in one interval");
    if ((v.w[1] && v.r[1]) || (v.w[2] && v.r[2])) return no("a tile written and read in one interval");
    if (v.w[1] && v.w[2]) return no("both tiles written in one interval");
  }
  // footprint
  uint64_t top = 0;
  for (Acc &a : A) if (a.cls != 2) for (uint64_t x : a.x0) top = std::max<uint64_t>(top, x + a.bytes);
  uint64_t N = (top + 15) & ~15ull;
  errs() << "[p2c-alias] " << nm << ": tiles [" << lowB << ",+" << sz << ") and [" << hiB << ",+" << sz << ") share the first, intervals " << ivs.size() << ", @shared_mem " << N << " B, launch dyn_smem=0\n";
  if (getenv("P2C_DRY")) return false;
  Module &M = *F.getParent(); LLVMContext &Cx = F.getContext(); Type *I32 = Type::getInt32Ty(Cx);
  int64_t shift = (int64_t)hiB - (int64_t)lowB;
  FunctionCallee Bar = M.getOrInsertFunction("llvm.nvvm.barrier0", FunctionType::get(Type::getVoidTy(Cx), false));
  // reads of the upper tile move down
  for (Acc &a : A) if (a.cls == 2 && !a.cp) { IRBuilder<> B(a.I); setAddr(a, B.CreateAdd(B.CreateZExtOrTrunc(a.idx, I32), B.getInt32(-shift), "p2c.a")); }
  // copies: per interval, those followed by a read of the other tile move behind a new barrier
  unsigned nmv = 0, nb = 0;
  for (Iv &v : ivs) {
    std::vector<Acc *> mv;
    for (Acc *a : v.cps) if (v.r[3 - a->cls]) mv.push_back(a);
    Instruction *last = nullptr;
    if (!mv.empty()) {
      int other = 3 - mv[0]->cls;
      last = v.lastRead[other];
      Instruction *At = v.close && last->getParent() == v.close->getParent() ? v.close : last->getParent()->getTerminator();
      { IRBuilder<> B(At); B.CreateCall(Bar); ++nb; }
      MapVector<BasicBlock *, std::vector<Acc *>> byGuard;   // guard block -> its copies (nullptr: unguarded); insertion order: the guards' code must not follow heap addresses
      for (Acc *a : mv) {
        Site st; st.C = cast<CallInst>(a->I);
        BasicBlock *key = nullptr;
        if (!X.DT.dominates(st.C->getParent(), At->getParent())) { if (!guardOf(X, st)) report_fatal_error("p2c-alias: copy neither dominates its new place nor sits in a guard"); key = st.C->getParent(); }
        byGuard[key].push_back(a);
      }
      for (auto &g : byGuard) {
        Value *cond = nullptr; Site st;
        struct Op { Acc *a; Value *src, *sz, *ix; };
        std::vector<Op> ops;
        if (g.first) { st.C = cast<CallInst>(g.second[0]->I); guardOf(X, st); }
        for (Acc *a : g.second) {     // operands stay where they are computed (they may read spill slots); a guarded one reaches the new place through a phi
          CallInst *C = cast<CallInst>(a->I);
          auto through = [&](Value *v) -> Value * {
            if (!g.first) return v;
            PHINode *ph = PHINode::Create(v->getType(), 2, "p2c.m", st.guardJoin->begin());
            ph->addIncoming(v, g.first); ph->addIncoming(UndefValue::get(v->getType()), st.guardPred);
            return ph;
          };
          ops.push_back({a, through(C->getArgOperand(1)), C->arg_size() == 3 ? through(C->getArgOperand(2)) : nullptr, through(a->idx)});
        }
        Instruction *Pt = At;
        if (g.first) {
          IRBuilder<> B(At);
          cond = st.guardTrueIsCopy ? st.guardCond : B.CreateNot(st.guardCond);
          if (!X.DT.dominates(st.guardPred->getTerminator(), At)) report_fatal_error("p2c-alias: guard does not reach the new place");
          Pt = SplitBlockAndInsertIfThen(cond, At->getIterator(), false);
        }
        for (Op &o : ops) {
          CallInst *C = cast<CallInst>(o.a->I);
          IRBuilder<> B(Pt);
          Value *x = B.CreateZExtOrTrunc(o.ix, I32);
          if (o.a->cls == 2) x = B.CreateAdd(x, B.getInt32(-shift), "p2c.a");
          Value *nz = o.sz ? B.CreateICmpNE(o.sz, ConstantInt::get(o.sz->getType(), 0)) : (Value *)B.getTrue();
          emitCp(B, M, GV, x, o.src, nz);
          C->eraseFromParent(); o.a->I = nullptr; ++nmv;
        }
      }
    }
    for (Acc *a : v.cps) if (a->I && a->cls == 2) { IRBuilder<> B(a->I); setAddr(*a, B.CreateAdd(B.CreateZExtOrTrunc(a->idx, I32), B.getInt32(-shift), "p2c.a")); }
  }
  errs() << "[p2c-alias] " << nm << ": moved " << nmv << " copies behind " << nb << " new barriers\n";
  Type *NT = ArrayType::get(Type::getInt8Ty(Cx), N);
  auto *NG = new GlobalVariable(M, NT, false, GV->getLinkage(), nullptr, "", GV, GlobalValue::NotThreadLocal, 3);
  NG->setAlignment(GV->getAlign()); NG->takeName(GV);
  GV->replaceAllUsesWith(NG); GV->eraseFromParent();
  for (User *U : NG->users()) if (auto *G = dyn_cast<GetElementPtrInst>(U)) if (G->getSourceElementType()->isArrayTy()) G->setSourceElementType(NT);
  return true;
}

struct AliasPass : PassInfoMixin<AliasPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    GlobalVariable *GV = M.getGlobalVariable("shared_mem");
    if (!GV || GV->getAddressSpace() != 3) return PreservedAnalyses::all();
    std::set<Function *> users;
    SmallVector<User *, 64> w(GV->users().begin(), GV->users().end());
    while (!w.empty()) { User *U = w.pop_back_val(); if (auto *I = dyn_cast<Instruction>(U)) users.insert(I->getFunction()); else for (User *V : U->users()) w.push_back(V); }
    if (users.size() != 1) return PreservedAnalyses::all();
    return aliasFunction(**users.begin(), GV) ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

struct FoldPass : PassInfoMixin<FoldPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    GlobalVariable *GV = M.getGlobalVariable("shared_mem");
    if (!GV || GV->getAddressSpace() != 3) return PreservedAnalyses::all();
    int Sn = envInt("P2C_STAGES", 2);
    std::set<Function *> users;
    SmallVector<User *, 64> w(GV->users().begin(), GV->users().end());
    while (!w.empty()) { User *U = w.pop_back_val(); if (auto *I = dyn_cast<Instruction>(U)) users.insert(I->getFunction()); else for (User *V : U->users()) w.push_back(V); }
    if (users.size() != 1) {   // one global for several kernels: the shared area cannot shrink for one of them; the analysis still runs in a dry run (coverage)
      errs() << "[p2c-fold] @shared_mem used by " << users.size() << " functions, left as it is\n";
      if (getenv("P2C_DRY")) for (Function *F : users) foldFunction(*F, GV, Sn);
      return PreservedAnalyses::all();
    }
    bool ch = foldFunction(**users.begin(), GV, Sn);
    return ch ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "p2cfold", "0.1", [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback([](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
              if (Name == "p2c-fold") { MPM.addPass(FoldPass()); return true; }
              if (Name == "p2c-alias") { MPM.addPass(AliasPass()); return true; }
              return false;
            });
          }};
}
