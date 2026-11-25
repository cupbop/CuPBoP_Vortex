// Grid order (CUPBOP_GRID_ORDER=1, default 0; schedule 2). grid_order.h has the contract.
//
// Why: the dispatcher (KMU) walks a launch's grid x fast. A GEMM-like kernel whose grid x picks one operand's tile
// then re-reads that whole operand for every row of y; when it does not fit the L2 the re-reads go to DRAM, and on a
// build whose DXA engine has one worker per core the transfers queue behind those misses. Walking R rows of y per
// column turns most of them into L2 hits (experiments/cluster README 1h-1o: the gain is the order, not where the CTAs
// sit). The walk is a bijection of the (x, y) grid, so the kernel computes the same thing.
//
// A kernel qualifies when (each refusal is one line in the build log):
//   - it reads the block index y (a 1-D grid has no rows to group),
//   - every block-index read is in the kernel itself (a device function shared with other kernels is not rewritten),
//   - it has no global atomic, no PTX atom/red asm: a kernel whose blocks wait on each other (decoupled look-back,
//     a counter another block sets) may need lower block indices to run first.
// The host sets R only for kernels the translator marked (cupbop_launch_fix.txt key grid_order=1).
// Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
#include "grid_order.h"
#include "launch_fix.h"
#include "tool.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/IntrinsicsNVPTX.h"

#include <cstdio>
#include <cstdlib>
#include <set>
#include <string>
#include <vector>

using namespace llvm;

namespace {

bool enabled() {
  const char *e = std::getenv("CUPBOP_GRID_ORDER");
  return e && std::atoi(e) != 0;
}

// 0 = ctaid.x, 1 = ctaid.y, 2 = ctaid.z, -1 = not a block-index read
int ctaid_axis(const Instruction &I) {
  auto *C = dyn_cast<CallInst>(&I);
  Function *F = C ? C->getCalledFunction() : nullptr;
  if (!F) return -1;
  StringRef n = F->getName();
  if (!n.consume_front("llvm.nvvm.read.ptx.sreg.ctaid.")) return -1;
  return n == "x" ? 0 : n == "y" ? 1 : n == "z" ? 2 : -1;
}

bool is_atomic(const Instruction &I) {
  if (auto *A = dyn_cast<AtomicRMWInst>(&I)) return A->getPointerAddressSpace() != 3;
  if (auto *X = dyn_cast<AtomicCmpXchgInst>(&I)) return X->getPointerAddressSpace() != 3;
  if (auto *C = dyn_cast<CallBase>(&I)) {
    if (auto *IA = dyn_cast<InlineAsm>(C->getCalledOperand())) {
      const std::string &s = IA->getAsmString();
      if (s.find("atom.") != std::string::npos || s.find("red.") != std::string::npos) return true;
    }
    if (Function *F = C->getCalledFunction()) {
      StringRef n = F->getName();
      if (n.contains("atomic") && !n.contains(".shared")) return true;
    }
  }
  return false;
}

void reachable(Function *F, std::set<Function *> &out) {
  if (!F || F->isDeclaration() || !out.insert(F).second) return;
  for (Instruction &I : instructions(*F))
    if (auto *C = dyn_cast<CallBase>(&I)) reachable(C->getCalledFunction(), out);
}

bool rewrite(Module *M, Function &K, std::string &why, std::string &done) {
  std::set<Function *> fs;
  reachable(&K, fs);
  std::vector<CallInst *> reads;
  bool has_y = false;
  for (Function *F : fs)
    for (Instruction &I : instructions(*F)) {
      if (is_atomic(I)) { why = "it has a global atomic (blocks may wait on each other)"; return false; }
      const int a = ctaid_axis(I);
      if (a < 0) continue;
      if (F != &K) { why = "the block index is read in " + F->getName().str() + ", not in the kernel"; return false; }
      if (a == 1) has_y = true;
      if (a <= 1) reads.push_back(cast<CallInst>(&I));
    }
  if (!has_y) { why = "it does not read the block index y"; return false; }

  LLVMContext &C = M->getContext();
  Type *I32 = Type::getInt32Ty(C);
  FunctionCallee helper = M->getOrInsertFunction("__cupbop_grid_order_xy", FunctionType::get(I32, {I32, I32, I32, I32, I32}, false));
  // after the entry block's allocas: one remap per kernel entry, shared by every read
  BasicBlock &E = K.getEntryBlock();
  IRBuilder<> B(&*E.getFirstInsertionPt());
  while (isa<AllocaInst>(&*B.GetInsertPoint())) B.SetInsertPoint(B.GetInsertPoint()->getNextNode());
  auto sreg = [&](Intrinsic::ID id, const char *name) { return B.CreateCall(Intrinsic::getDeclaration(M, id), {}, name); };
  Value *bx = sreg(Intrinsic::nvvm_read_ptx_sreg_ctaid_x, "go.bx");
  Value *by = sreg(Intrinsic::nvvm_read_ptx_sreg_ctaid_y, "go.by");
  Value *gx = sreg(Intrinsic::nvvm_read_ptx_sreg_nctaid_x, "go.gx");
  Value *gy = sreg(Intrinsic::nvvm_read_ptx_sreg_nctaid_y, "go.gy");
  Value *nx = B.CreateCall(helper, {bx, by, gx, gy, B.getInt32(0)}, "go.x");
  Value *ny = B.CreateCall(helper, {bx, by, gx, gy, B.getInt32(1)}, "go.y");
  for (CallInst *R : reads) {
    R->replaceAllUsesWith(ctaid_axis(*R) == 0 ? nx : ny);
    R->eraseFromParent();
  }
  launch_fix_note(M, K.getName(), "grid_order", 1);
  done = std::to_string(reads.size()) + " block-index read(s) of x and y go through __cupbop_grid_order_xy (R at launch)";
  return true;
}

}  // namespace

void lower_grid_order(Module *M) {
  if (!enabled()) return;
  const char *sc = std::getenv("VORTEX_SCHEDULE_FLAG");
  if (!sc || std::atoi(sc) != 2) {
    fprintf(stderr, "[CuPBoP] grid order: schedule %s: only the 1:1 schedule (2), nothing changed\n", sc ? sc : "0");
    return;
  }
  const char *cl = std::getenv("CUPBOP_CTA_LOOP");
  if (cl && std::atoi(cl) != 0) {
    fprintf(stderr, "[CuPBoP] grid order: CUPBOP_CTA_LOOP is on (it walks the grid itself), nothing changed\n");
    return;
  }
  std::vector<Function *> kernels;
  for (Function &F : *M)
    if (!F.isDeclaration() && isKernelFunction(M, &F)) kernels.push_back(&F);
  for (Function *F : kernels) {
    std::string why, done;
    if (rewrite(M, *F, why, done))
      fprintf(stderr, "[CuPBoP] grid order: %s: %s\n", F->getName().str().c_str(), done.c_str());
    else
      fprintf(stderr, "[CuPBoP] grid order: %s: not applied: %s\n", F->getName().str().c_str(), why.c_str());
  }
}
