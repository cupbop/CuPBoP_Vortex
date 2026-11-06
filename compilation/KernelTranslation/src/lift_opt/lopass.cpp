// lopass.cpp (2026-11-05): two steps of lo-mma as passes of their own, for modules with no mma as well. Both change what lo-mma does at that step, so a lifted module keeps lo-mma's own steps
// unless CUPBOP_LIFT_LOPASS=1 (lift_opt_driver.cpp); stock Triton input takes these. Reasons and measurements: experiments/triton_why/REPORT_KO.md, experiments/lopass.
//   lo-sched : lo-mma's list scheduler (liftopt.cpp) on a block where more values are live at one point than there are registers of their class, and with barriers and calls with side effects
//              held in place. Below that nothing spills, and the new order only moves live ranges around (softmax 1024: frame accesses 8 -> 22). A new order goes back when it lowers neither the
//              sum over the block of the values with no register nor the peak of a class over its registers: values live through the block are no matter of order, and it gives up the independent ops of the
//              old order for nothing (LayerNorm 32x1000). The sum alone is too strict: a block of WMMA chains can gain with a sum a little up, one class traded for the other (lifted fa2). LO_SCHED=0 turns it off, LO_SCHED_MIN as in lo-mma.
//   lo-f16   : lo-mma's fptrunc float->half fast path with +0 and -0 inside the window. Outside it one lane sends the warp through both paths: 1% zeros made the fast path a loss. LO_F16=0 turns it off.
// LO_DEBUG=1 prints the decision of each block.
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <cstdlib>
#include <map>
#include <vector>
using namespace llvm;

void loScheduleBlock(BasicBlock &BB, bool hold);   // liftopt.cpp
void loLowerF16(Function &F, bool zero);

// lo-mma<lane-eval> (liftopt.cpp, Lanes::row): an ldmatrix takes the address of a row from the lane that holds it. In a lifted module that is a register, so it takes a shuffle, one per row and
// fragment word, in the main loop. Stock Triton computes the addresses from tid.x with integer arithmetic, and the shuffle is that arithmetic at another tid. Without the shuffle nothing keeps it in
// the loop: the addresses are loop invariant for num_stages=1 and leave it. Null: V depends on tid.x through something that is not plain arithmetic, or on a value that may differ between the lanes.
namespace {
bool isSreg(const Value *V, StringRef prefix) { auto *C = dyn_cast<CallInst>(V); return C && C->getCalledFunction() && C->getCalledFunction()->getName().starts_with(prefix); }
bool isTid(const Value *V) { return isSreg(V, "llvm.nvvm.read.ptx.sreg.tid.x"); }
bool sameInAllLanes(Value *V, SmallPtrSetImpl<Value *> &seen) {   // of a warp, and no tid.x in it
  if (isa<Constant>(V) || isa<Argument>(V)) return true;
  if (isSreg(V, "llvm.nvvm.read.ptx.sreg.ctaid") || isSreg(V, "llvm.nvvm.read.ptx.sreg.nctaid") || isSreg(V, "llvm.nvvm.read.ptx.sreg.ntid")) return true;
  auto *I = dyn_cast<Instruction>(V);
  if (!I || !(isa<BinaryOperator>(I) || isa<CastInst>(I) || isa<SelectInst>(I) || isa<ICmpInst>(I) || isa<PHINode>(I) || isa<GetElementPtrInst>(I))) return false;
  if (!seen.insert(V).second) return true;
  for (Value *O : I->operands()) if (!sameInAllLanes(O, seen)) return false;
  return true;
}
Value *evalAt(IRBuilder<> &Q, Value *V, Value *tid, DenseMap<Value *, Value *> &memo) {
  if (isTid(V)) return tid;
  { SmallPtrSet<Value *, 16> seen; if (sameInAllLanes(V, seen)) return V; }
  auto it = memo.find(V); if (it != memo.end()) return it->second;
  auto *I = dyn_cast<Instruction>(V);
  if (!I || !(isa<BinaryOperator>(I) || isa<CastInst>(I) || isa<SelectInst>(I) || isa<ICmpInst>(I))) return nullptr;
  SmallVector<Value *, 3> ops;
  for (Value *O : I->operands()) { Value *E = evalAt(Q, O, tid, memo); if (!E) return nullptr; ops.push_back(E); }
  Instruction *C = I->clone();
  for (unsigned k = 0; k < ops.size(); ++k) C->setOperand(k, ops[k]);
  Q.Insert(C);
  return memo[V] = C;
}
}
Value *loLaneEval(IRBuilder<> &Q, Value *V, Value *tid) { DenseMap<Value *, Value *> memo; return evalAt(Q, V, tid, memo); }

namespace {
int envI(const char *n, int d) { const char *e = getenv(n); return e && *e ? atoi(e) : d; }

// Registers of the target (RV64 with F and D): 32 float registers; 32 integer registers less zero, sp, gp, tp. LO_SCHED_FREGS, LO_SCHED_XREGS change them for measurements.
constexpr int FLOAT_REGS = 32, INT_REGS = 28;

struct Peak { int fl = 0, in = 0; long over = 0; };   // over: per point of the block, the live values with no register, summed

// The peak of live SSA values per class at any point of each block: backward over the block from its live-out set. Constants and allocas (a frame offset) hold no register.
struct Pressure {
  DenseMap<Value *, unsigned> id; std::vector<char> isF; DenseMap<BasicBlock *, BitVector> in, out; const int fregs, xregs;
  Pressure(Function &F, int fregs, int xregs) : fregs(fregs), xregs(xregs) {
    auto add = [&](Value *V) { if (id.try_emplace(V, id.size()).second) isF.push_back(V->getType()->isFloatingPointTy()); };
    for (Argument &A : F.args()) add(&A);
    for (BasicBlock &B : F) for (Instruction &I : B) if (!I.getType()->isVoidTy() && !isa<AllocaInst>(I)) add(&I);
    const unsigned n = id.size();
    for (BasicBlock &B : F) { in[&B] = BitVector(n); out[&B] = BitVector(n); }
    std::vector<BasicBlock *> blocks; for (BasicBlock &B : F) blocks.push_back(&B);
    for (bool again = true; again;) {   // live-in = (live-out - defs) + uses; phi operands are live out of their predecessor
      again = false;
      for (BasicBlock *B : llvm::reverse(blocks)) {
        BitVector o(n);
        for (BasicBlock *S : successors(B)) {
          o |= in[S];
          for (PHINode &P : S->phis()) if (int k = num(P.getIncomingValueForBlock(B)); k >= 0) o.set(k);
        }
        BitVector l = o; walk(*B, l, nullptr);
        if (l != in[B] || o != out[B]) { in[B] = std::move(l); out[B] = std::move(o); again = true; }
      }
    }
  }
  int num(Value *V) { auto it = id.find(V); return it == id.end() ? -1 : (int)it->second; }
  void walk(BasicBlock &B, BitVector &l, Peak *p) {
    auto count = [&] { if (!p) return; int f = 0, i = 0; for (unsigned k : l.set_bits()) (isF[k] ? f : i)++; p->fl = std::max(p->fl, f); p->in = std::max(p->in, i); p->over += std::max(f - fregs, 0) + std::max(i - xregs, 0); };
    count();
    for (Instruction &I : llvm::reverse(B)) {
      if (int k = num(&I); k >= 0) l.reset(k);
      if (isa<PHINode>(I)) continue;
      for (Value *V : I.operands()) if (int k = num(V); k >= 0) l.set(k);
      count();
    }
    for (PHINode &P : B.phis()) l.set(num(&P));   // phi results are all defined on entry
    count();
    for (PHINode &P : B.phis()) l.reset(num(&P));
  }
  Peak peak(BasicBlock &B) { Peak p; BitVector l = out[&B]; walk(B, l, &p); return p; }
};

struct LoSched : PassInfoMixin<LoSched> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    const char *e = getenv("LO_SCHED"); if (e && atoi(e) == 0) return PreservedAnalyses::all();
    const int minN = envI("LO_SCHED_MIN", 64), fregs = envI("LO_SCHED_FREGS", FLOAT_REGS), xregs = envI("LO_SCHED_XREGS", INT_REGS); const bool dbg = envI("LO_DEBUG", 0); bool changed = false;
    for (Function &F : M) {
      if (F.isDeclaration()) continue;
      bool big = false; for (BasicBlock &B : F) big |= (int)B.size() >= minN;
      if (!big) continue;
      Pressure P(F, fregs, xregs);
      for (BasicBlock &B : F) {
        if ((int)B.size() < minN) continue;
        const Peak k = P.peak(B); Peak a = k; bool kept = false;
        if (k.over) {
          SmallVector<Instruction *, 256> order;
          for (Instruction &I : B) if (!isa<PHINode>(I) && !I.isTerminator() && !isa<AllocaInst>(I)) order.push_back(&I);
          loScheduleBlock(B, true); a = P.peak(B); kept = a.over < k.over || (k.fl > fregs && a.fl < k.fl) || (k.in > xregs && a.in < k.in);
          if (!kept) for (Instruction *I : order) I->moveBefore(B.getTerminator());
          changed |= kept;
        }
        if (dbg) errs() << "lo-sched: " << F.getName().substr(0, 30) << ": " << B.size() << " instrs, live float " << k.fl << " int " << k.in << " over " << k.over << (k.over ? kept ? ": scheduled, now float " : ": no better, kept as it was, float " : ": left, float ") << a.fl << " int " << a.in << " over " << a.over << "\n";
      }
    }
    return changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

// lo-saddr: a loop with many shared-memory accesses has as many addresses, each a function of tid.x. LLVM hoists them all, and they spill: one frame load per address, in a loop that is short of
// everything but registers for addresses. Two addresses at a constant distance need one register. Which ones are is a question about integers on a known range of tid.x (the block size is in
// nvvm.reqntid), so it is answered by evaluating the addresses for every tid, swizzle or not. Each class gets one pointer in the entry block, its members an immediate offset (window of +-2047).
// LO_SADDR=0 turns it off.
struct SAddr {
  Instruction *mem; unsigned op; GlobalVariable *G; SmallVector<Value *, 3> idx; int64_t k = 0; std::vector<int64_t> tab;
};
struct NumEval {
  uint64_t tid; DenseMap<Value *, uint64_t> memo;
  static uint64_t mask(uint64_t x, unsigned w) { return w >= 64 ? x : x & ((1ull << w) - 1); }
  static int64_t sx(uint64_t x, unsigned w) { return w >= 64 ? (int64_t)x : (int64_t)(x << (64 - w)) >> (64 - w); }
  bool get(Value *V, uint64_t &o) {
    if (isTid(V)) { o = tid; return true; }
    if (auto *C = dyn_cast<ConstantInt>(V)) { if (C->getBitWidth() > 64) return false; o = C->getZExtValue(); return true; }
    auto *I = dyn_cast<Instruction>(V); if (!I) return false;
    auto it = memo.find(V); if (it != memo.end()) { o = it->second; return true; }
    if (!I->getType()->isIntegerTy() || I->getType()->getIntegerBitWidth() > 64) return false;
    unsigned w = I->getType()->getIntegerBitWidth(); uint64_t a = 0, b = 0, r = 0;
    if (auto *B = dyn_cast<BinaryOperator>(I)) {
      if (!get(B->getOperand(0), a) || !get(B->getOperand(1), b)) return false;
      switch (B->getOpcode()) {
      case Instruction::Add: r = a + b; break;
      case Instruction::Sub: r = a - b; break;
      case Instruction::Mul: r = a * b; break;
      case Instruction::And: r = a & b; break;
      case Instruction::Or: r = a | b; break;
      case Instruction::Xor: r = a ^ b; break;
      case Instruction::Shl: if (b >= w) return false; r = a << b; break;
      case Instruction::LShr: if (b >= w) return false; r = a >> b; break;
      case Instruction::AShr: if (b >= w) return false; r = (uint64_t)(sx(a, w) >> b); break;
      default: return false;
      }
    } else if (auto *C = dyn_cast<CastInst>(I)) {
      if (!C->getSrcTy()->isIntegerTy() || !get(C->getOperand(0), a)) return false;
      unsigned sw = C->getSrcTy()->getIntegerBitWidth();
      if (isa<ZExtInst>(C) || isa<TruncInst>(C)) r = a; else if (isa<SExtInst>(C)) r = (uint64_t)sx(a, sw); else return false;
    } else if (auto *S = dyn_cast<SelectInst>(I)) {
      uint64_t c; if (!get(S->getCondition(), c)) return false;
      if (!get(c ? S->getTrueValue() : S->getFalseValue(), r)) return false;
    } else if (auto *Q = dyn_cast<ICmpInst>(I)) {
      if (!Q->getOperand(0)->getType()->isIntegerTy() || !get(Q->getOperand(0), a) || !get(Q->getOperand(1), b)) return false;
      unsigned ow = Q->getOperand(0)->getType()->getIntegerBitWidth(); int64_t x = sx(a, ow), y = sx(b, ow);
      switch (Q->getPredicate()) {
      case ICmpInst::ICMP_EQ: r = a == b; break;
      case ICmpInst::ICMP_NE: r = a != b; break;
      case ICmpInst::ICMP_ULT: r = a < b; break;
      case ICmpInst::ICMP_ULE: r = a <= b; break;
      case ICmpInst::ICMP_UGT: r = a > b; break;
      case ICmpInst::ICMP_UGE: r = a >= b; break;
      case ICmpInst::ICMP_SLT: r = x < y; break;
      case ICmpInst::ICMP_SLE: r = x <= y; break;
      case ICmpInst::ICMP_SGT: r = x > y; break;
      case ICmpInst::ICMP_SGE: r = x >= y; break;
      default: return false;
      }
    } else return false;
    o = memo[V] = mask(r, w);
    return true;
  }
};
// the same expression again in front of Q; leaves are constants and tid
Value *cloneAt(IRBuilder<> &Q, Value *V, Value *tid, DenseMap<Value *, Value *> &memo) {
  if (isTid(V)) return tid;
  if (isa<Constant>(V)) return V;
  auto it = memo.find(V); if (it != memo.end()) return it->second;
  auto *I = cast<Instruction>(V); Instruction *C = I->clone();
  for (unsigned k = 0; k < I->getNumOperands(); ++k) C->setOperand(k, cloneAt(Q, I->getOperand(k), tid, memo));
  Q.Insert(C);
  return memo[V] = C;
}
struct LoSAddr : PassInfoMixin<LoSAddr> {
  // V = G + constant + sum of integer terms, through byte GEPs
  static bool decompose(Value *V, SAddr &A) {
    Type *I8 = Type::getInt8Ty(V->getContext());
    while (!isa<GlobalVariable>(V)) {
      auto *G = dyn_cast<GEPOperator>(V);
      if (!G || G->getSourceElementType() != I8 || G->getNumIndices() != 1) return false;
      Value *I = G->getOperand(1);
      if (auto *K = dyn_cast<ConstantInt>(I)) A.k += K->getSExtValue(); else A.idx.push_back(I);
      V = G->getPointerOperand();
    }
    A.G = cast<GlobalVariable>(V);
    return A.G->getAddressSpace() == 3 && !A.idx.empty();
  }
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    const char *e = getenv("LO_SADDR"); if (e && atoi(e) == 0) return PreservedAnalyses::all();
    bool changed = false; const bool dbg = envI("LO_DEBUG", 0);
    for (Function &F : M) {
      if (F.isDeclaration()) continue;
      unsigned ntid = 0;
      if (F.hasFnAttribute("nvvm.reqntid")) F.getFnAttribute("nvvm.reqntid").getValueAsString().getAsInteger(10, ntid);
      if (!ntid || ntid > 1024) continue;
      DominatorTree DT(F); LoopInfo LI(DT);
      std::vector<SAddr> as;
      for (BasicBlock &B : F) {
        if (!LI.getLoopFor(&B)) continue;
        for (Instruction &I : B) {
          SAddr A; A.mem = &I;
          if (auto *L = dyn_cast<LoadInst>(&I)) A.op = L->getPointerOperandIndex(); else if (auto *S = dyn_cast<StoreInst>(&I)) A.op = S->getPointerOperandIndex(); else continue;
          if (I.getOperand(A.op)->getType()->getPointerAddressSpace() != 3 || !decompose(I.getOperand(A.op), A)) continue;
          bool ok = true; A.tab.resize(ntid);
          for (unsigned t = 0; t < ntid && ok; ++t) { NumEval E; E.tid = t; int64_t sum = 0;
            for (Value *x : A.idx) { uint64_t v; if (!E.get(x, v)) { ok = false; break; } sum += NumEval::sx(v, x->getType()->getIntegerBitWidth()); }
            A.tab[t] = sum; }
          if (ok) as.push_back(std::move(A));
        }
      }
      // classes: same table up to a constant
      std::map<std::vector<int64_t>, std::vector<SAddr *>> cls; std::vector<std::vector<int64_t>> order;
      for (SAddr &A : as) { std::vector<int64_t> d(ntid); for (unsigned t = 0; t < ntid; ++t) d[t] = A.tab[t] - A.tab[0]; if (!cls.count(d)) order.push_back(d); cls[d].push_back(&A); }
      if (cls.empty()) continue;
      Type *I8 = Type::getInt8Ty(M.getContext()), *I32 = Type::getInt32Ty(M.getContext());
      BasicBlock &En = F.getEntryBlock(); Instruction *tid = nullptr;
      for (Instruction &I : En) if (isTid(&I)) { tid = &I; break; }
      if (!tid) { IRBuilder<> Q(&*En.getFirstInsertionPt()); tid = Q.CreateCall(M.getOrInsertFunction("llvm.nvvm.read.ptx.sreg.tid.x", FunctionType::get(I32, false)), {}, "lo.tid"); }
      unsigned ptrs = 0;
      for (auto &d : order) {
        auto &ms = cls[d];
        SAddr *R = ms[0]; IRBuilder<> Q(tid->getNextNode()); DenseMap<Value *, Value *> memo;
        Value *base = nullptr;
        for (Value *x : R->idx) { Value *c = cloneAt(Q, x, tid, memo); if (c->getType() != I32) c = Q.CreateSExtOrTrunc(c, I32); base = base ? Q.CreateAdd(base, c) : c; }
        // offsets from R's value at tid 0 upwards: windows that an immediate reaches from one pointer
        std::vector<std::pair<int64_t, SAddr *>> os; for (SAddr *m : ms) os.push_back({m->tab[0] - R->tab[0] + m->k, m});
        std::stable_sort(os.begin(), os.end(), [](auto &a, auto &b) { return a.first < b.first; });
        if (envI("LO_SADDR_DBG", 0)) { errs() << "  class of " << os.size() << ":"; for (auto &o : os) errs() << " " << o.first << (isa<LoadInst>(o.second->mem) ? "l" : "s"); errs() << "\n"; }
        for (size_t i = 0; i < os.size();) {
          size_t j = i; while (j < os.size() && os[j].first - os[i].first < 4000) ++j;
          int64_t mid = (os[i].first + os[j - 1].first) / 2 / 8 * 8;
          // Through integers: as a GEP instcombine folds mid back into the offsets, and what is left are constants no immediate reaches, one register or frame slot for each
          Type *I64 = Type::getInt64Ty(M.getContext());
          Value *p = Q.CreateInBoundsGEP(I8, R->G, {Q.CreateSExt(base, I64)}, "lo.sa"); ptrs++;
          if (mid) p = Q.CreateIntToPtr(Q.CreateAdd(Q.CreatePtrToInt(p, I64), ConstantInt::get(I64, mid)), p->getType(), "lo.sa");
          for (; i < j; ++i) { SAddr *m = os[i].second; IRBuilder<> U(m->mem); int64_t off = os[i].first - mid; m->mem->setOperand(m->op, off ? U.CreateInBoundsGEP(I8, p, {ConstantInt::get(I64, off)}) : p); }
        }
      }
      errs() << "lo-saddr: " << F.getName().substr(0, 30) << ": " << as.size() << " shared accesses in loops, " << cls.size() << " classes, " << ptrs << " pointers\n";
      changed = true;
    }
    return changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

struct LoF16 : PassInfoMixin<LoF16> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    const char *e = getenv("LO_F16"); if (e && atoi(e) == 0) return PreservedAnalyses::all();
    std::vector<Function *> fs;   // helpers appear while this runs, and their slow path is the real fptrunc
    for (Function &F : M) if (!F.isDeclaration() && !F.getName().starts_with("lo.cvt.")) fs.push_back(&F);
    for (Function *F : fs) loLowerF16(*F, true);
    return PreservedAnalyses::none();
  }
};
} // namespace

void loTritonRegister(PassBuilder &PB);   // lotriton.cpp

void p3RegisterPasses(PassBuilder &PB) {
  loTritonRegister(PB);
  PB.registerPipelineParsingCallback([](StringRef N, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
    if (N == "lo-sched") { MPM.addPass(LoSched()); return true; }
    if (N == "lo-saddr") { MPM.addPass(LoSAddr()); return true; }
    if (N == "lo-f16") { MPM.addPass(LoF16()); return true; }
    return false; });
}
