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
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include <cstdlib>
#include <vector>
using namespace llvm;

void loScheduleBlock(BasicBlock &BB, bool hold);   // liftopt.cpp
void loLowerF16(Function &F, bool zero);

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

void p3RegisterPasses(PassBuilder &PB) {
  PB.registerPipelineParsingCallback([](StringRef N, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
    if (N == "lo-sched") { MPM.addPass(LoSched()); return true; }
    if (N == "lo-f16") { MPM.addPass(LoF16()); return true; }
    return false; });
}
