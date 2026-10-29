// Lowerings for CuLifter-lifted library kernels (cuBLAS / cuDNN / CUTLASS NVVM IR). 2026-10-29.
#include "lifted_ir.h"
#include "tool.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/IR/InlineAsm.h"
#include <cstdio>
#include <regex>
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

// ldmatrix / stmatrix inline asm (.m8n8 .b16, x1/x2/x4, optional .trans), the forms CuLifter emits for LDSM / STSM:
//   "ldmatrix.sync.aligned.x4.m8n8[.trans].shared.b16 {$0,$1,$2,$3}, [$4];"  "=r,=r,=r,=r,r"     (32-bit address)
//   "ldmatrix.sync.aligned.m8n8.x4[.trans].shared.b16 {...}, [$4];"          "=r,..,l,~{memory}" (64-bit address)
//   "stmatrix.sync.aligned.x4.m8n8[.trans].shared.b16 [$0], {$1,..};"        "l|r,r,..[,~{memory}]"
// -> __cupbop_ldmatrix_m8n8_b16(i32 a, i32 num, i32 trans, ptr d) / __cupbop_stmatrix_m8n8_b16(i32 a, num, trans, ptr v)
// (cudaKernelImpl_dtypes.inc). Only integer address operands: Triton's ldmatrix (a ptr addrspace(3) operand) is left
// to replace_asm_call's TCU path.
void lower_ldmatrix_asm(Module *M) {
  static const std::regex ld(R"(^\s*ldmatrix\.sync\.aligned\.(?:x([124])\.m8n8|m8n8\.x([124]))(\.trans)?\.shared(?:::cta)?\.b16\s*\{([^}]*)\}\s*,\s*\[\s*\$(\d+)\s*\]\s*;?\s*$)");
  static const std::regex st(R"(^\s*stmatrix\.sync\.aligned\.(?:x([124])\.m8n8|m8n8\.x([124]))(\.trans)?\.shared(?:::cta)?\.b16\s*\[\s*\$(\d+)\s*\]\s*,\s*\{([^}]*)\}\s*;?\s*$)");
  LLVMContext &C = M->getContext();
  Type *I32 = Type::getInt32Ty(C), *PtrT = PointerType::get(C, 0), *VoidT = Type::getVoidTy(C);
  auto helper = [&](const char *name) { // declared only when used: modules without these asm stay unchanged
    FunctionCallee FC = M->getOrInsertFunction(name, FunctionType::get(VoidT, {I32, I32, I32, PtrT}, false));
    if (auto *Fn = dyn_cast<Function>(FC.getCallee())) Fn->addFnAttr(Attribute::Convergent);
    return FC;
  };
  std::vector<CallInst *> calls;
  for (auto &F : M->functions())
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (CI->isInlineAsm()) {
            const std::string a = cast<InlineAsm>(CI->getCalledOperand())->getAsmString();
            if (a.find("ldmatrix") != std::string::npos || a.find("stmatrix") != std::string::npos) calls.push_back(CI);
          }
  unsigned nld = 0, nst = 0;
  for (CallInst *CI : calls) {
    const std::string a = cast<InlineAsm>(CI->getCalledOperand())->getAsmString();
    std::smatch m;
    const bool isLd = std::regex_match(a, m, ld);
    if (!isLd && !std::regex_match(a, m, st)) continue; // other forms: replace_asm_call (Triton) / reported there
    const int num = std::stoi(m[1].matched ? m[1].str() : m[2].str());
    const bool trans = m[3].matched;
    // operand numbering: outputs first, then inputs (the CuLifter forms list the registers in order)
    const int addrOp = std::stoi(isLd ? m[5].str() : m[4].str());
    const int nOut = isLd ? num : 0;
    if (CI->arg_size() != (unsigned)(isLd ? 1 : 1 + num) || addrOp != (isLd ? num : 0)) {
      fprintf(stderr, "error: %s asm with unexpected operands: %s\n", isLd ? "ldmatrix" : "stmatrix", a.c_str());
      exit(1);
    }
    Value *Addr = CI->getArgOperand(isLd ? 0 : 0);
    if (!Addr->getType()->isIntegerTy()) continue; // Triton: ptr addrspace(3)
    IRBuilder<> B(CI);
    Value *A32 = B.CreateZExtOrTrunc(Addr, I32, "smem.win");
    IRBuilder<> AB(&CI->getFunction()->getEntryBlock().front());
    AllocaInst *Buf = AB.CreateAlloca(ArrayType::get(I32, num), nullptr, isLd ? "ldsm.d" : "stsm.v");
    if (isLd) {
      B.CreateCall(helper("__cupbop_ldmatrix_m8n8_b16"), {A32, ConstantInt::get(I32, num), ConstantInt::get(I32, trans), Buf});
      Type *RT = CI->getType();
      Value *R;
      if (auto *ST = dyn_cast<StructType>(RT)) {
        R = UndefValue::get(ST);
        for (int j = 0; j < num; ++j) {
          Value *V = B.CreateLoad(I32, B.CreateConstInBoundsGEP2_32(Buf->getAllocatedType(), Buf, 0, j));
          if (ST->getElementType(j) != I32) V = B.CreateBitCast(V, ST->getElementType(j));
          R = B.CreateInsertValue(R, V, j);
        }
      } else {
        R = B.CreateLoad(I32, Buf);
        if (RT != I32) R = B.CreateBitCast(R, RT);
      }
      CI->replaceAllUsesWith(R);
      nld++;
    } else {
      for (int j = 0; j < num; ++j) {
        Value *V = CI->getArgOperand(1 + j);
        if (V->getType() != I32) V = B.CreateBitCast(V, I32);
        B.CreateStore(V, B.CreateConstInBoundsGEP2_32(Buf->getAllocatedType(), Buf, 0, j));
      }
      B.CreateCall(helper("__cupbop_stmatrix_m8n8_b16"), {A32, ConstantInt::get(I32, num), ConstantInt::get(I32, trans), Buf});
      nst++;
    }
    (void)nOut;
    CI->eraseFromParent();
  }
  if (nld || nst) fprintf(stderr, "[CuPBoP] ldmatrix / stmatrix asm lowered: %u / %u\n", nld, nst);
}
