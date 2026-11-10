// Uniform branch marking (CUPBOP_UNIFORM_BR, default 0; 2026-11-04, experiments/p2b). Schedule 2 only.
//
// Why: the Vortex backend's divergence analysis treats a function's arguments, loads through them, inline asm (the CTA
// CSRs) and most intrinsics (smin, ...) as divergent. A translated kernel is one function called by every thread, so
// each branch on a kernel parameter or blockIdx gets split/join, or a vx_pred on a loop, although all lanes agree
// (experiments/p2b/micro/u.ll). Agents wrapped such values in llvm.riscv.vx.uniform by hand.
//
// What: a divergence analysis of the kernel function, seeded with what can differ between the lanes of a warp, and
// propagated the way LLVM's UniformityAnalysis does:
//  - seeds: threadIdx CSRs and other asm, allocas (every hardware thread has its own stack), thread-local globals,
//    atomics, calls that are not on the list of pure intrinsics, `!divergence` values;
//  - data: any user of a divergent value (a load through a divergent pointer too). A load through a uniform pointer
//    is uniform: one warp instruction, one address;
//  - control: for a divergent branch, every phi in the blocks between it and its immediate post-dominator; for a loop
//    such a branch can leave, every value of the loop used outside it.
// Kernel arguments and the CTA CSRs (block id, block size, grid size, CTA id and size) are uniform. The condition of
// each conditional branch left uniform is wrapped in llvm.riscv.vx.uniform.i1.i1; nothing else changes.
//
// At the end of the translation: the optimizer has run, only the kernel compile sees the wrappers.
#include "tool.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/IntrinsicsRISCV.h"
#include "llvm/IR/Module.h"
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

using namespace llvm;

const std::vector<std::pair<std::string, std::string>> &kabi_kernel_list(); // generate_wrapper.cpp

namespace {

int level() {
  static const int l = [] { const char *e = std::getenv("CUPBOP_UNIFORM_BR"); return e ? std::atoi(e) : 0; }();
  return l;
}

// the CSR number of a `csrr $0, 0x...` asm call, -1 for anything else
int csrOf(const CallBase &C) {
  auto *IA = dyn_cast<InlineAsm>(C.getCalledOperand());
  if (!IA) return -1;
  const std::string &s = IA->getAsmString();
  if (s.rfind("csrr $0, 0x", 0) != 0) return -1;
  return (int)std::strtol(s.c_str() + 9, nullptr, 16);
}
bool ctaUniformCsr(int c) {
  return c == 0xCD0 || c == 0xCD2 || (c >= 0xCD6 && c <= 0xCD8) || (c >= 0xCD9 && c <= 0xCDB) || (c >= 0xCDC && c <= 0xCDE);
}
bool pureIntrinsic(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::smin: case Intrinsic::smax: case Intrinsic::umin: case Intrinsic::umax: case Intrinsic::abs:
  case Intrinsic::fshl: case Intrinsic::fshr: case Intrinsic::ctpop: case Intrinsic::ctlz: case Intrinsic::cttz:
  case Intrinsic::bswap: case Intrinsic::bitreverse: case Intrinsic::uadd_sat: case Intrinsic::usub_sat:
  case Intrinsic::sadd_sat: case Intrinsic::ssub_sat: case Intrinsic::uadd_with_overflow:
  case Intrinsic::usub_with_overflow: case Intrinsic::sadd_with_overflow: case Intrinsic::ssub_with_overflow:
  case Intrinsic::umul_with_overflow: case Intrinsic::smul_with_overflow: case Intrinsic::fabs: case Intrinsic::fma:
  case Intrinsic::fmuladd: case Intrinsic::minnum: case Intrinsic::maxnum: case Intrinsic::sqrt: case Intrinsic::floor:
  case Intrinsic::ceil: case Intrinsic::trunc: case Intrinsic::rint: case Intrinsic::copysign: case Intrinsic::expect:
    return true;
  default:
    return false;
  }
}

class Divergence {
public:
  explicit Divergence(Function &F) : F(F), DT(F), PDT(F), LI(DT) {}
  void run() {
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (seed(I)) mark(&I);
    while (!work.empty()) {
      Value *V = work.back();
      work.pop_back();
      for (User *U : V->users()) {
        auto *I = dyn_cast<Instruction>(U);
        if (!I) continue;
        if (auto *II = dyn_cast<IntrinsicInst>(I))
          if (II->getIntrinsicID() == Intrinsic::riscv_vx_uniform) continue;
        if (I->isTerminator()) { branch(I->getParent()); continue; }
        if (!I->getType()->isVoidTy()) mark(I);
      }
    }
  }
  bool divergent(Value *V) const { return !isa<Constant>(V) && D.count(V); }
  // x30 / x31 clobbers around Call and around the divergent regions it sits in (protect_dxa_operand_registers)
  void clobberAround(CallInst *Call, Value *IA, FunctionType *FT) {
    auto at = [&](Instruction *I) { CallInst::Create(FT, IA, {}, "", I->getIterator())->addFnAttr(Attribute::NoUnwind); };
    at(Call);
    at(Call->getNextNode());
    for (auto *N = DT.getNode(Call->getParent()); N; N = N->getIDom()) {
      BasicBlock *B = N->getBlock();
      auto *Br = dyn_cast<BranchInst>(B->getTerminator());
      if (!Br || !Br->isConditional() || !divergent(Br->getCondition())) continue;
      at(Br);
      if (auto *PN = PDT.getNode(B))
        if (auto *Id = PN->getIDom())
          if (BasicBlock *P = Id->getBlock()) at(&*P->getFirstInsertionPt());
    }
  }

private:
  Function &F;
  DominatorTree DT;
  PostDominatorTree PDT;
  LoopInfo LI;
  DenseSet<Value *> D;
  DenseSet<BasicBlock *> doneBranch;
  std::vector<Value *> work;

  void mark(Value *V) {
    if (isa<Constant>(V) || isa<Argument>(V)) return;
    if (D.insert(V).second) work.push_back(V);
  }
  bool privatePointer(Value *P) {
    const Value *O = getUnderlyingObject(P, 0);
    if (isa<AllocaInst>(O)) return true;
    if (auto *G = dyn_cast<GlobalVariable>(O)) return G->isThreadLocal();
    return false;
  }
  bool seed(Instruction &I) {
    if (I.getMetadata("divergence") && !I.getType()->isVoidTy()) return true;
    if (isa<AllocaInst>(I) || isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I)) return true;
    if (auto *L = dyn_cast<LoadInst>(&I)) return L->isAtomic() || privatePointer(L->getPointerOperand());
    if (auto *C = dyn_cast<CallBase>(&I)) {
      if (C->getType()->isVoidTy()) return false;
      if (C->isInlineAsm()) {
        const int c = csrOf(*C);
        return !ctaUniformCsr(c);
      }
      if (auto *II = dyn_cast<IntrinsicInst>(C)) {
        if (II->getIntrinsicID() == Intrinsic::riscv_vx_uniform) return false;
        return !pureIntrinsic(II->getIntrinsicID());
      }
      return true;
    }
    return false;
  }
  void branch(BasicBlock *B) {
    if (!doneBranch.insert(B).second) return;
    Instruction *T = B->getTerminator();
    if (T->getNumSuccessors() < 2) return;
    BasicBlock *P = nullptr;
    if (auto *N = PDT.getNode(B))
      if (auto *Id = N->getIDom()) P = Id->getBlock();
    DenseSet<BasicBlock *> R;
    std::vector<BasicBlock *> st;
    for (BasicBlock *S : successors(B))
      if (S != P && R.insert(S).second) st.push_back(S);
    while (!st.empty()) {
      BasicBlock *X = st.back();
      st.pop_back();
      for (BasicBlock *S : successors(X))
        if (S != P && R.insert(S).second) st.push_back(S);
    }
    if (P) R.insert(P);
    for (BasicBlock *X : R)
      for (PHINode &Ph : X->phis()) mark(&Ph);
    for (Loop *L = LI.getLoopFor(B); L; L = L->getParentLoop()) {
      bool exits = false;
      for (BasicBlock *X : R) exits |= !L->contains(X);
      if (!exits) continue;
      for (BasicBlock *X : L->blocks())
        for (Instruction &I : *X) {
          if (I.getType()->isVoidTy()) continue;
          for (User *U : I.users())
            if (auto *UI = dyn_cast<Instruction>(U))
              if (!L->contains(UI->getParent())) { mark(&I); break; }
        }
    }
  }
};

} // namespace

// The DXA operands of a TMA copy are gathered into lanes 0-3 of x31 (x30 for rank > 2) by vx_wgather, whatever the
// thread mask (cudaKernelImpl_async.inc cupbop_tma_dxa_issue). The issuing code runs on one lane, so lanes 1-3 of those
// registers are overwritten while those lanes are masked off, and the compiler's save around the asm only runs on the
// active lane: a value that lives in t5 / t6 across the copy is lost in lanes 1-3. This stayed hidden while a real
// barrier call in the loop pushed long-lived values into callee-saved registers (lifted tg_tma with
// CUPBOP_BAR_INLINE=1: misaligned stack access, only with CUPBOP_TMA_DXA=1). An empty asm clobbering x30 / x31 at
// points every lane passes (around the call and around each divergent region holding it) keeps such values in other
// registers; no instruction is added. -ffixed-x30/x31 is no way out: LTO's fastcc helpers take those as argument
// registers. Runs with CUPBOP_BAR_INLINE or CUPBOP_DXA_CLOBBER, schedule 2.
// The queued copies of a moved arrive (__cupbop_tma_load_qi) no longer issue under the elected thread's mask: the
// converged warp issues them after the region (__cupbop_txq_issue, async_ptx.cpp placeIssue), which needs no clobber. Only
// the unqueued load, which issues in place (no arrive moved after it: CUPBOP_ASYNC_NO_MOVE), is left here.
void protect_dxa_operand_registers(Module *M) {
  auto on = [](const char *n) { const char *e = std::getenv(n); return e && std::atoi(e) != 0; };
  if (!bar_inline_on() && !on("CUPBOP_DXA_CLOBBER")) return;
  const char *sc = std::getenv("VORTEX_SCHEDULE_FLAG");
  if (!sc || std::atoi(sc) != 2) return;
  auto *FT = FunctionType::get(Type::getVoidTy(M->getContext()), false);
  auto *IA = InlineAsm::get(FT, "", "~{x30},~{x31}", /*hasSideEffects=*/true);
  for (auto &kw : kabi_kernel_list()) {
    Function *F = M->getFunction(kw.first);
    if (!F || F->isDeclaration()) continue;
    std::vector<CallInst *> calls;
    for (BasicBlock &BB : *F)
      for (Instruction &I : BB)
        if (auto *C = dyn_cast<CallInst>(&I))
          if (Function *G = C->getCalledFunction())
            if (G->getName() == "__cupbop_tma_load") calls.push_back(C);
    if (calls.empty()) continue;
    Divergence A(*F);
    A.run();
    for (CallInst *C : calls) A.clobberAround(C, IA, FT);
    fprintf(stderr, "[CuPBoP] dxa clobber: %s: %zu DXA calls\n", kw.first.c_str(), calls.size());
  }
}

// CUPBOP_ARG_SIGNEXT=1 (default 0): i32 kernel parameters are `signext` on the kernel and in its wrapper's call. The
// wrapper's `lw` already gives the RV64 form the attribute promises, and the kernel drops its own sext.w copies.
void sign_extend_kernel_args(Module *M) {
  const char *e = std::getenv("CUPBOP_ARG_SIGNEXT");
  if (!e || std::atoi(e) == 0) return;
  for (auto &kw : kabi_kernel_list()) {
    Function *F = M->getFunction(kw.first);
    if (!F || F->isDeclaration()) continue;
    for (Argument &A : F->args()) {
      if (!A.getType()->isIntegerTy(32) || A.hasZExtAttr()) continue;
      A.addAttr(Attribute::SExt);
      for (User *U : F->users())
        if (auto *C = dyn_cast<CallBase>(U))
          if (C->getCalledFunction() == F) C->addParamAttr(A.getArgNo(), Attribute::SExt);
    }
  }
}

void mark_uniform_branches(Module *M) {
  if (level() <= 0) return;
  const char *sc = std::getenv("VORTEX_SCHEDULE_FLAG");
  if (!sc || std::atoi(sc) != 2) return;
  for (auto &kw : kabi_kernel_list()) {
    Function *F = M->getFunction(kw.first);
    if (!F || F->isDeclaration()) continue;
    Divergence A(*F);
    A.run();
    unsigned marked = 0, left = 0;
    Function *U = Intrinsic::getDeclaration(M, Intrinsic::riscv_vx_uniform,
                                            {Type::getInt1Ty(M->getContext()), Type::getInt1Ty(M->getContext())});
    for (BasicBlock &BB : *F) {
      auto *Br = dyn_cast<BranchInst>(BB.getTerminator());
      if (!Br || !Br->isConditional() || isa<Constant>(Br->getCondition())) continue;
      if (A.divergent(Br->getCondition())) { left++; continue; }
      auto *C = CallInst::Create(U, {Br->getCondition()}, "br.u", Br->getIterator());
      Br->setCondition(C);
      marked++;
    }
    unsigned lmemUniform = 0, lmemAll = 0;   // statistics: LMEM reads with a uniform address (all lanes on one word)
    for (BasicBlock &BB : *F)
      for (Instruction &I : BB)
        if (auto *L = dyn_cast<LoadInst>(&I)) {
          const Value *O = getUnderlyingObject(L->getPointerOperand(), 0);
          if (auto *C = dyn_cast<CallBase>(O))
            if (C->getCalledFunction() && C->getCalledFunction()->getName().contains("vx_local_alloc")) {
              lmemAll++;
              lmemUniform += !A.divergent(L->getPointerOperand());
            }
        }
    fprintf(stderr, "[CuPBoP] uniform: %s: %u of %u LMEM loads have a uniform address\n", kw.first.c_str(), lmemUniform, lmemAll);
    fprintf(stderr, "[CuPBoP] uniform: %s: %u branches marked uniform, %u left divergent\n", kw.first.c_str(), marked, left);
  }
}
