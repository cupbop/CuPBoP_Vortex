// Lowerings for CuLifter-lifted library kernels (cuBLAS / cuDNN / CUTLASS NVVM IR). 2026-10-29.
#include "lifted_ir.h"
#include "tool.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include <cstdio>
#include <vector>

using namespace llvm;

// __syncthreads_and(p) / _or(p) / _count(p) == llvm.nvvm.barrier0.{and,or,popc}(i32 p) -> i32
//
//   barrier0                                   B1: every thread is past the previous reduction's read
//   if (tid == (0,0,0)) xchg red, init         init: and -> 1, or / popc -> 0
//   barrier0                                   B2
//   atomicrmw {and, or, add} red, (p != 0)     monotonic, shared memory (Vortex local memory AMOs)
//   barrier0                                   B3
//   r = load atomic red                        and/or: 0/1, popc: count
//
// `red` is one i32 in shared memory (@__cupbop_bar_red, an addrspace(3) global that mem_share2local places in the
// CTA's shared-memory area), reused by every reduction of the kernel: B1 of the next reduction orders its
// initialisation after this one's reads. The barriers are ordinary llvm.nvvm.barrier0 calls, so the 1:1, core
// mapping and flat schedules split warp loops at them as for __syncthreads. Three barriers instead of the one
// BAR.RED: the lifted kernels use it in prologues (CUTLASS pipelines' "any k-tile left" vote).
void lower_barrier_reductions(Module *M) {
  std::vector<CallInst *> calls;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *C = dyn_cast<CallInst>(&I))
          if (Function *Fn = C->getCalledFunction()) {
            StringRef n = Fn->getName();
            if (n == "llvm.nvvm.barrier0.and" || n == "llvm.nvvm.barrier0.or" || n == "llvm.nvvm.barrier0.popc")
              calls.push_back(C);
          }
  if (calls.empty()) return;
  LLVMContext &C = M->getContext();
  Type *I32 = Type::getInt32Ty(C);
  GlobalVariable *Red = M->getGlobalVariable("__cupbop_bar_red");
  if (!Red)
    Red = new GlobalVariable(*M, I32, false, GlobalValue::InternalLinkage, UndefValue::get(I32), "__cupbop_bar_red",
                             nullptr, GlobalValue::NotThreadLocal, 3);
  Red->setAlignment(Align(4));
  FunctionCallee Bar = M->getOrInsertFunction("llvm.nvvm.barrier0", FunctionType::get(Type::getVoidTy(C), false));
  if (auto *BF = dyn_cast<Function>(Bar.getCallee())) BF->addFnAttr(Attribute::Convergent);
  auto sreg = [&](const char *n) { return M->getOrInsertFunction(n, FunctionType::get(I32, false)); };
  FunctionCallee Tx = sreg("llvm.nvvm.read.ptx.sreg.tid.x"), Ty = sreg("llvm.nvvm.read.ptx.sreg.tid.y"),
                 Tz = sreg("llvm.nvvm.read.ptx.sreg.tid.z");
  unsigned n_and = 0, n_or = 0, n_popc = 0;
  for (CallInst *CI : calls) {
    StringRef n = CI->getCalledFunction()->getName();
    const bool isAnd = n.ends_with(".and"), isOr = n.ends_with(".or");
    (isAnd ? n_and : isOr ? n_or : n_popc)++;
    Value *P = CI->getArgOperand(0);
    IRBuilder<> B(CI);
    B.CreateCall(Bar);                                                     // B1
    Value *t = B.CreateOr(B.CreateOr(B.CreateCall(Tx), B.CreateCall(Ty)), B.CreateCall(Tz));
    Value *isT0 = B.CreateICmpEQ(t, ConstantInt::get(I32, 0), "bar_red.t0");
    Instruction *Then = SplitBlockAndInsertIfThen(isT0, CI->getIterator(), false);
    {
      // an atomic exchange, not a store: insert_warp_loop's divergence analysis marks the pointer operand of a
      // store under a divergent branch as divergent, and the shared-memory base pointer then became a per-lane
      // context copy that only slot 0 of the core mapping ever wrote (s1, trips > 1: 0xbaadf00d addresses)
      IRBuilder<> TB(Then);
      TB.CreateAtomicRMW(AtomicRMWInst::Xchg, Red, ConstantInt::get(I32, isAnd ? 1 : 0), Align(4), AtomicOrdering::Monotonic);
    }
    B.SetInsertPoint(CI);
    B.CreateCall(Bar);                                                     // B2
    Value *bit = B.CreateZExt(B.CreateICmpNE(P, Constant::getNullValue(P->getType())), I32, "bar_red.bit");
    B.CreateAtomicRMW(isAnd ? AtomicRMWInst::And : isOr ? AtomicRMWInst::Or : AtomicRMWInst::Add, Red, bit, Align(4),
                      AtomicOrdering::Monotonic);
    B.CreateCall(Bar);                                                     // B3
    LoadInst *R = B.CreateLoad(I32, Red, "bar_red");
    R->setAtomic(AtomicOrdering::Monotonic);
    R->setAlignment(Align(4));
    Value *Res = R;
    if (CI->getType() != I32) Res = B.CreateZExtOrTrunc(R, CI->getType());
    CI->replaceAllUsesWith(Res);
    CI->eraseFromParent();
  }
  fprintf(stderr, "[CuPBoP] barrier reductions lowered to barrier + shared word: %u and, %u or, %u popc\n", n_and, n_or,
          n_popc);
}
