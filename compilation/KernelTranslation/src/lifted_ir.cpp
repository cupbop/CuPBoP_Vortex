// Lowerings for CuLifter-lifted library kernels (cuBLAS / cuDNN / CUTLASS NVVM IR). 2026-10-29.
#include "lifted_ir.h"
#include "tool.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Operator.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Passes/PassBuilder.h"
#include <algorithm>
#include <cstdio>
#include <functional>
#include <memory>
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

// llvm.nvvm.{round,trunc,ceil,floor}[.ftz].{f,d} (CuLifter: FRND / DRND [.TRUNC/.CEIL/.FLOOR]; round = to nearest
// even, as cvt.rni) -> branch-free IR: |x| >= 2^p (p = 23 / 52, also NaN / inf) is returned as is, otherwise rint is
// (|x| + 2^p) - 2^p with x's sign and trunc goes through a 64-bit integer; ceil / floor adjust trunc by one. The
// llvm.rint/round/... intrinsics would reach the RISC-V PseudoFROUND inserter, a branch the Vortex backend rejects
// ("unimplemented divergent codegen").
void lower_nvvm_rounding(Module *M) {
  std::vector<CallInst *> calls;
  for (auto &F : M->functions())
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *Fn = CI->getCalledFunction()) {
            StringRef n = Fn->getName();
            if (n.starts_with("llvm.nvvm.round.") || n.starts_with("llvm.nvvm.trunc.") || n.starts_with("llvm.nvvm.ceil.") ||
                n.starts_with("llvm.nvvm.floor."))
              calls.push_back(CI);
          }
  if (calls.empty()) return;
  Type *I64 = Type::getInt64Ty(M->getContext());
  for (CallInst *CI : calls) {
    StringRef n = CI->getCalledFunction()->getName();
    Value *X = CI->getArgOperand(0);
    Type *T = X->getType();
    IRBuilder<> B(CI);
    const double two_p = T->isDoubleTy() ? 4503599627370496.0 : 8388608.0;
    Value *A = B.CreateUnaryIntrinsic(Intrinsic::fabs, X);
    Value *Big = B.CreateFCmpUGE(A, ConstantFP::get(T, two_p)); // also NaN
    Value *R;
    if (n.starts_with("llvm.nvvm.round.")) {
      Value *Rr = B.CreateFSub(B.CreateFAdd(A, ConstantFP::get(T, two_p)), ConstantFP::get(T, two_p));
      R = B.CreateBinaryIntrinsic(Intrinsic::copysign, Rr, X);
    } else {
      // |x| < 2^p here (Big selects x otherwise): the conversion is exact; inputs >= 2^p are replaced by 0 so that
      // fptosi never sees an out-of-range value
      Value *Xs = B.CreateSelect(Big, ConstantFP::get(T, 0.0), X);
      Value *Tr = B.CreateBinaryIntrinsic(Intrinsic::copysign, B.CreateSIToFP(B.CreateFPToSI(Xs, I64), T), Xs);
      if (n.starts_with("llvm.nvvm.trunc.")) R = Tr;
      else if (n.starts_with("llvm.nvvm.ceil.")) R = B.CreateSelect(B.CreateFCmpOLT(Tr, Xs), B.CreateFAdd(Tr, ConstantFP::get(T, 1.0)), Tr);
      else R = B.CreateSelect(B.CreateFCmpOGT(Tr, Xs), B.CreateFSub(Tr, ConstantFP::get(T, 1.0)), Tr);
    }
    R = B.CreateSelect(Big, X, R);
    CI->replaceAllUsesWith(R);
    CI->eraseFromParent();
  }
  fprintf(stderr, "[CuPBoP] nvvm round/trunc/ceil/floor lowered: %zu\n", calls.size());
}

// CuLifter allocates the per-thread local window as `alloca [32768 x i8] %local_mem` in every function, whatever the
// SASS frame size (CULIFTER_FIXES #9). Vortex stacks are 8 KB per thread, so a surviving 32 KB frame overflows into
// the neighbour's stack at run time (or stops the RISC-V back end: "Incomplete scavenging"). After folding the
// integer arithmetic (the lifted stack pointer is R1 = frame size - frame size + offset), every access is a
// constant offset; the alloca is shrunk to the largest accessed byte, rounded up to 16. A non-constant offset keeps
// the 32 KB array and is reported (CUPBOP_KEEP_LOCAL_MEM=1 keeps it always).
// C plan stage 2 (2026-10-29): a non-constant offset is bounded with ScalarEvolution (on the folded IR, nothing else is
// changed). CUTLASS reference / fill kernels (BlockForEach, TensorForEach, GemmComplex: 30 modules kept 32 KB) index
// a small per-thread array with a loop counter, e.g. local_mem[36 + 4 i] for i < 5: SCEV gives the AddRec's range from
// the loop's exit count. The extent is the largest signed-range maximum + access size; an unbounded range, a possibly
// negative offset or an extent beyond the array keeps the 32 KB array as before. CUPBOP_LOCAL_MEM_SCEV=0 or
// CUPBOP_UNIFORM_NOREPL=0: constant offsets only (11770fc).
void shrink_lifter_local_mem(Module *M) {
  if (std::getenv("CUPBOP_KEEP_LOCAL_MEM")) return;
  auto off_env = [](const char *n) { const char *e = std::getenv(n); return e && std::atoi(e) == 0; };
  const bool use_scev = !off_env("CUPBOP_LOCAL_MEM_SCEV") && !off_env("CUPBOP_UNIFORM_NOREPL");
  // analysis managers built on the first non-constant offset only: nothing else allocates here, so the translator's
  // heap layout (which some of its pointer-keyed containers' iteration order follows) is unchanged for other kernels
  struct Analyses {
    PassBuilder PB;
    LoopAnalysisManager LAM; FunctionAnalysisManager FAM; CGSCCAnalysisManager CGAM; ModuleAnalysisManager MAM;
    Analyses() {
      PB.registerModuleAnalyses(MAM); PB.registerCGSCCAnalyses(CGAM); PB.registerFunctionAnalyses(FAM);
      PB.registerLoopAnalyses(LAM); PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);
    }
  };
  std::unique_ptr<Analyses> AN;
  unsigned scev_shrunk = 0;
  const DataLayout &DL = M->getDataLayout();
  unsigned shrunk = 0, kept = 0;
  for (auto &F : M->functions()) {
    if (F.isDeclaration()) continue;
    AllocaInst *AI = nullptr;
    for (auto &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (A->getName() == "local_mem" && A->getAllocatedType()->isArrayTy()) { AI = A; break; }
    if (!AI) continue;
    const uint64_t full = DL.getTypeAllocSize(AI->getAllocatedType());
    // fold integer constants (the address arithmetic) in this function
    for (bool changed = true; changed;) {
      changed = false;
      for (auto &BB : F)
        for (auto It = BB.begin(); It != BB.end();) {
          Instruction *I = &*It++;
          if (!I->getType()->isIntegerTy() || isa<CallBase>(I) || isa<LoadInst>(I) || isa<PHINode>(I)) continue;
          if (Constant *K = ConstantFoldInstruction(I, DL))
            if (isa<ConstantInt>(K)) { I->replaceAllUsesWith(K); I->eraseFromParent(); changed = true; }
        }
    }
    uint64_t extent = 0;
    bool ok = true, scev_used = false;
    std::vector<std::pair<Value *, int64_t>> work{{AI, 0}};
    std::string why;
    while (!work.empty() && ok) {
      auto [V, base] = work.back();
      work.pop_back();
      for (User *U : V->users()) {
        if (auto *G = dyn_cast<GEPOperator>(U)) {
          APInt off(DL.getIndexTypeSizeInBits(G->getType()), 0);
          if (!G->accumulateConstantOffset(DL, off)) {
            // the largest offset from the alloca that this GEP can produce (ScalarEvolution)
            auto *GI = dyn_cast<GetElementPtrInst>(G);
            if (!use_scev || !GI) { ok = false; why = "non-constant offset"; break; }
            if (!AN) AN = std::make_unique<Analyses>();
            ScalarEvolution &SE = AN->FAM.getResult<ScalarEvolutionAnalysis>(F);
            const SCEV *O = SE.getMinusSCEV(SE.getSCEV(GI), SE.getSCEV(AI));
            if (isa<SCEVCouldNotCompute>(O) || !O->getType()->isIntegerTy()) { ok = false; why = "non-constant offset (no SCEV)"; break; }
            ConstantRange R = SE.getSignedRange(O);
            if (R.isFullSet() || R.getSignedMin().isNegative() || R.getSignedMax().sgt(APInt(R.getBitWidth(), full))) {
              ok = false; why = "non-constant offset (unbounded)"; break;
            }
            work.push_back({G, R.getSignedMax().getSExtValue()});
            scev_used = true;
            continue;
          }
          work.push_back({G, base + off.getSExtValue()});
        } else if (isa<BitCastOperator>(U) || isa<AddrSpaceCastOperator>(U)) {
          work.push_back({U, base});
        } else if (auto *L = dyn_cast<LoadInst>(U)) {
          extent = std::max<int64_t>(extent, base + (int64_t)DL.getTypeStoreSize(L->getType()));
        } else if (auto *S = dyn_cast<StoreInst>(U)) {
          if (S->getValueOperand() == V) { ok = false; why = "address stored"; break; }
          extent = std::max<int64_t>(extent, base + (int64_t)DL.getTypeStoreSize(S->getValueOperand()->getType()));
        } else if (auto *II = dyn_cast<IntrinsicInst>(U)) {
          if (II->isLifetimeStartOrEnd()) continue;
          auto *Len = dyn_cast<ConstantInt>(II->getNumOperands() > 2 ? II->getArgOperand(2) : nullptr);
          if ((II->getIntrinsicID() == Intrinsic::memcpy || II->getIntrinsicID() == Intrinsic::memset ||
               II->getIntrinsicID() == Intrinsic::memmove) && Len)
            extent = std::max<int64_t>(extent, base + (int64_t)Len->getZExtValue());
          else { ok = false; why = "intrinsic use"; break; }
        } else { ok = false; why = "other use"; break; }
        if (base < 0) { ok = false; why = "negative offset"; break; }
      }
    }
    if (!ok || extent > full) {
      kept++;
      fprintf(stderr, "[CuPBoP] %s: local_mem kept at %llu bytes (%s); the Vortex stack is 8 KB per thread\n",
              F.getName().str().c_str(), (unsigned long long)full, why.c_str());
      continue;
    }
    const uint64_t n = std::max<uint64_t>(16, (extent + 15) / 16 * 16);
    AI->setAllocatedType(ArrayType::get(Type::getInt8Ty(M->getContext()), n));
    shrunk++;
    if (scev_used) {
      // A window indexed with a variable offset stays memory (SROA cannot split it). The Vortex back end's divergence
      // analysis takes a load from a stack slot at a thread-uniform address for uniform, although every hardware
      // thread has its own copy: in the 1:1 schedule the BlockForEach random fills got 126 instead of 280 split/join
      // and groups of lanes one lane's values (a "divergence" metadata on the loads did not survive). Such an array
      // goes to the frame scratch (frame_alloca_to_scratch, whatever its size), where its address depends on the
      // hardware-thread number. (The 32 KB array never got that far: it overflowed the 8 KB stack.)
      AI->setMetadata("cupbop.frame_scratch", MDNode::get(M->getContext(), {}));
      scev_shrunk++;
      fprintf(stderr, "[CuPBoP] %s: local_mem %llu -> %llu bytes (non-constant offsets bounded by SCEV)\n",
              F.getName().str().c_str(), (unsigned long long)full, (unsigned long long)n);
    } else if (cupbop_debug())
      fprintf(stderr, "[CuPBoP] %s: local_mem %llu -> %llu bytes\n", F.getName().str().c_str(), (unsigned long long)full, (unsigned long long)n);
    if (AN) AN->FAM.clear(F, F.getName());
  }
  if (shrunk || kept) fprintf(stderr, "[CuPBoP] local_mem frames: %u shrunk to their accessed extent (%u with SCEV bounds), %u kept\n", shrunk, scev_shrunk, kept);
}

// llvm.nvvm.redux.sync.{add,umin,umax,min,max,and,or,xor}(i32 v, i32 membermask) (redux.sync.op.b32/.u32/.s32, sm_80+)
// -> __cupbop_redux_sync(v, mask, op): the lanes of the mask, gathered with index shuffles (any mask; the lanes in it
// are active by the PTX contract). Software, hardware warp (1:1 / core mapping with 32 hardware lanes).
void lower_redux_sync(Module *M) {
  std::vector<CallInst *> calls;
  for (auto &F : M->functions())
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *Fn = CI->getCalledFunction())
            if (Fn->getName().starts_with("llvm.nvvm.redux.sync.")) calls.push_back(CI);
  if (calls.empty()) return;
  LLVMContext &C = M->getContext();
  Type *I32 = Type::getInt32Ty(C);
  FunctionCallee H = M->getOrInsertFunction("__cupbop_redux_sync", FunctionType::get(I32, {I32, I32, I32}, false));
  if (auto *Fn = dyn_cast<Function>(H.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  static const char *ops[] = {"add", "umin", "umax", "min", "max", "and", "or", "xor"};
  for (CallInst *CI : calls) {
    StringRef n = CI->getCalledFunction()->getName().drop_front(strlen("llvm.nvvm.redux.sync."));
    int op = -1;
    for (int i = 0; i < 8; ++i) if (n == ops[i]) op = i;
    if (op < 0 || CI->arg_size() != 2) {
      fprintf(stderr, "error: unsupported %s\n", CI->getCalledFunction()->getName().str().c_str());
      exit(1);
    }
    IRBuilder<> B(CI);
    CallInst *R = B.CreateCall(H, {CI->getArgOperand(0), CI->getArgOperand(1), ConstantInt::get(I32, op)});
    R->addFnAttr(Attribute::Convergent);
    CI->replaceAllUsesWith(R);
    CI->eraseFromParent();
  }
  fprintf(stderr, "[CuPBoP] redux.sync lowered: %zu\n", calls.size());
}

// llvm.bitreverse.i1(x) == x. InstCombine makes it from lifted predicate shuffling; the RISC-V back end cannot type-
// legalize it ("Do not know how to promote this operator!", CUTLASS 58_ada_fp8_gemm).
void fold_bitreverse_i1(Module *M) {
  std::vector<CallInst *> calls;
  for (auto &F : M->functions())
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *II = dyn_cast<IntrinsicInst>(&I))
          if (II->getIntrinsicID() == Intrinsic::bitreverse && II->getType()->isIntOrIntVectorTy(1)) calls.push_back(II);
  for (CallInst *CI : calls) { CI->replaceAllUsesWith(CI->getArgOperand(0)); CI->eraseFromParent(); }
}

// llvm.nvvm.read.ptx.sreg.lanemask.{eq,le,lt,ge,gt} -> masks of llvm.nvvm.read.ptx.sreg.laneid (lowered later with
// the other special registers). Left in place they reach the RISC-V back end, which crashed in
// lowerGetVectorLength on the unknown intrinsic id (CUTLASS 41_fused_multi_head_attention_backward).
void lower_lanemask(Module *M) {
  std::vector<CallInst *> calls;
  for (auto &F : M->functions())
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *Fn = CI->getCalledFunction())
            if (Fn->getName().starts_with("llvm.nvvm.read.ptx.sreg.lanemask.")) calls.push_back(CI);
  if (calls.empty()) return;
  Type *I32 = Type::getInt32Ty(M->getContext());
  FunctionCallee Lane = M->getOrInsertFunction("llvm.nvvm.read.ptx.sreg.laneid", FunctionType::get(I32, false));
  for (CallInst *CI : calls) {
    StringRef k = CI->getCalledFunction()->getName().drop_front(strlen("llvm.nvvm.read.ptx.sreg.lanemask."));
    IRBuilder<> B(CI);
    Value *L = B.CreateCall(Lane);
    Value *Bit = B.CreateShl(ConstantInt::get(I32, 1), L);              // 1 << lane
    Value *R;
    if (k == "eq") R = Bit;
    else if (k == "lt") R = B.CreateSub(Bit, ConstantInt::get(I32, 1));
    else if (k == "le") R = B.CreateOr(B.CreateSub(Bit, ConstantInt::get(I32, 1)), Bit);
    else if (k == "gt") R = B.CreateNot(B.CreateOr(B.CreateSub(Bit, ConstantInt::get(I32, 1)), Bit));
    else if (k == "ge") R = B.CreateNot(B.CreateSub(Bit, ConstantInt::get(I32, 1)));
    else { fprintf(stderr, "error: unsupported %s\n", CI->getCalledFunction()->getName().str().c_str()); exit(1); }
    CI->replaceAllUsesWith(R);
    CI->eraseFromParent();
  }
}

// C plan (2026-10-29): CuLifter copies every kernel parameter into a per-thread byte buffer at the entry (`param_local`,
// `vx_params`: a store of each parameter at its constant-bank offset) and reads the parameters back with loads at
// constant offsets (LDC). Every thread holds the same bytes, but the buffer is an alloca: one copy per hardware thread
// in every schedule (cuDNN's tensor descriptors: 340 byte loads + byte stores at the entry, the loaded bytes spilled),
// and under the core mapping one more per logical-warp slot (insert_warp_loop replicates an alloca whose stores it
// cannot prove uniform, 805137e then makes the entry region a warp loop so that every slot's copy is written).
// Each load whose bytes lie inside one parameter's copy reads the parameter instead:
//   - a parameter passed in launch slots (pass_wide_kernel_args_by_slot, "cupbop-arg-slots"): a load of the same type
//     from the slots, i.e. from the kernel-argument buffer (read only, not written while the kernel runs);
//   - a scalar parameter: its bits (lshr + trunc, then bitcast / inttoptr to the loaded type).
// The copies and the alloca go when no load of it is left. Conditions, otherwise the alloca is left alone: it is a
// static alloca of the entry block; every use is reached through constant-offset GEPs / bitcasts and is a simple load,
// a simple store into it or a lifetime marker (no escaping pointer, call, memcpy, variable index); every store is in
// the entry block and stores a kernel argument or a load (in the entry block, from the argument pointer itself) of a
// slots argument; the stored ranges do not overlap. A load that is in the entry block before its covering store, that
// is not inside one store's range (uninitialised bytes), or whose type is not an integer / floating-point / pointer
// keeps reading the alloca (the copies stay then). Only byte-array allocas ([N x i8], the lifter's buffers) are
// considered: the typed per-argument spill slots of CUDA-source kernels (clang -O0) are left to the translator's -O3,
// so the CI examples keep their code. Runs before every schedule-specific pass, so the 1:1, core-mapping
// and flat schedules all see the parameters directly; the warp-loop pass then finds nothing to replicate.
// CUPBOP_UNIFORM_NOREPL=0 (or CUPBOP_PARAM_FORWARD=0): off, the 11770fc code; CUPBOP_PARAM_FORWARD=s1: the core
// mapping only (in the 1:1 schedule a few kernels lose the shrink-wrapped prologue, see ctx_c README).
// CUPBOP_PARAM_FORWARD_WHY=1: decisions.
void forward_param_buffer_copies(Module *M) {
  auto off_env = [](const char *n) { const char *e = std::getenv(n); return e && std::atoi(e) == 0 && std::string(e) != "s1"; };
  if (off_env("CUPBOP_UNIFORM_NOREPL") || off_env("CUPBOP_PARAM_FORWARD")) return;
  if (const char *e = std::getenv("CUPBOP_PARAM_FORWARD"); e && std::string(e) == "s1") {   // core mapping only
    const char *sf = std::getenv("VORTEX_SCHEDULE_FLAG");
    if (!sf || std::atoi(sf) != 1) return;
  }
  const bool why = std::getenv("CUPBOP_PARAM_FORWARD_WHY") != nullptr;
  const DataLayout &DL = M->getDataLayout();
  LLVMContext &C = M->getContext();
  unsigned n_fwd = 0, n_kept = 0, n_removed = 0, n_partial = 0, n_skipped = 0;
  for (Function &F : *M) {
    if (F.isDeclaration() || !isKernelFunction(M, &F)) continue;
    BasicBlock &Entry = F.getEntryBlock();
    std::vector<AllocaInst *> allocas;
    for (Instruction &I : Entry)
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (A->isStaticAlloca() && A->getAllocatedType()->isArrayTy() &&
            A->getAllocatedType()->getArrayElementType()->isIntegerTy(8))
          allocas.push_back(A);   // byte buffers only: not clang -O0's per-argument spill slots of CUDA-source kernels
    for (AllocaInst *AI : allocas) {
      struct Src { int64_t off, size; StoreInst *S; Argument *slots; Value *scalar; };
      std::vector<Src> srcs;
      std::vector<std::pair<LoadInst *, int64_t>> loads;
      std::vector<Instruction *> markers;
      std::string bad;
      std::vector<std::pair<Value *, int64_t>> work{{AI, 0}};
      while (!work.empty() && bad.empty()) {
        auto [V, base] = work.back();
        work.pop_back();
        for (User *U : V->users()) {
          if (auto *G = dyn_cast<GEPOperator>(U)) {
            APInt off(DL.getIndexTypeSizeInBits(G->getType()), 0);
            if (!isa<Instruction>(G) || !G->accumulateConstantOffset(DL, off)) { bad = "non-constant GEP"; break; }
            work.push_back({G, base + off.getSExtValue()});
          } else if (isa<BitCastInst>(U) || isa<AddrSpaceCastInst>(U)) {
            work.push_back({U, base});
          } else if (auto *L = dyn_cast<LoadInst>(U)) {
            if (!L->isSimple()) { bad = "volatile/atomic load"; break; }
            loads.push_back({L, base});
          } else if (auto *S = dyn_cast<StoreInst>(U)) {
            if (S->getValueOperand() == V) { bad = "address stored"; break; }
            if (!S->isSimple()) { bad = "volatile/atomic store"; break; }
            if (S->getParent() != &Entry) { bad = "store outside the entry block"; break; }
            Value *X = S->getValueOperand();
            Src s{base, (int64_t)DL.getTypeStoreSize(X->getType()), S, nullptr, nullptr};
            if (auto *A = dyn_cast<Argument>(X)) {
              Type *T = A->getType();
              if (!(T->isIntegerTy() || T->isFloatingPointTy() || T->isPointerTy()) || s.size > 8) {
                bad = "stored argument of an unhandled type"; break;
              }
              s.scalar = A;
            } else if (auto *LS = dyn_cast<LoadInst>(X)) {
              auto *A = dyn_cast<Argument>(LS->getPointerOperand());
              if (!A || !LS->isSimple() || LS->getParent() != &Entry ||
                  !F.getAttributes().hasParamAttr(A->getArgNo(), "cupbop-arg-slots")) { bad = "stored value is not a parameter"; break; }
              s.slots = A;
            } else { bad = "stored value is not a parameter"; break; }
            srcs.push_back(s);
          } else if (auto *II = dyn_cast<IntrinsicInst>(U)) {
            if (!II->isLifetimeStartOrEnd()) { bad = "intrinsic use"; break; }
            markers.push_back(II);
          } else { bad = "other use"; break; }
          if (base < 0) { bad = "negative offset"; break; }
        }
      }
      if (bad.empty() && srcs.empty()) bad = "no parameter stored";
      if (bad.empty()) {
        std::sort(srcs.begin(), srcs.end(), [](const Src &a, const Src &b) { return a.off < b.off; });
        for (size_t i = 1; i < srcs.size(); ++i)
          if (srcs[i].off < srcs[i - 1].off + srcs[i - 1].size) { bad = "overlapping stores"; break; }
      }
      if (!bad.empty()) {
        if (!srcs.empty() || why) {   // report buffers that looked like parameter copies
          n_skipped++;
          if (why) fprintf(stderr, "[param-fwd] %s: %s kept (%s)\n", F.getName().str().c_str(), AI->getName().str().c_str(), bad.c_str());
        }
        continue;
      }
      unsigned fwd = 0, kept = 0;
      for (auto [L, off] : loads) {
        const int64_t size = (int64_t)DL.getTypeStoreSize(L->getType());
        const Src *s = nullptr;
        for (const Src &x : srcs)
          if (off >= x.off && off + size <= x.off + x.size) { s = &x; break; }
        Type *LT = L->getType();
        const bool type_ok = LT->isIntegerTy() || LT->isFloatingPointTy() || LT->isPointerTy();
        if (!s || !type_ok || (L->getParent() == &Entry && !s->S->comesBefore(L)) ||
            (s->scalar && DL.getTypeSizeInBits(LT) != (uint64_t)size * 8)) {
          kept++;
          if (why) fprintf(stderr, "[param-fwd] %s: %s load at %lld (%lld bytes) kept (%s)\n", F.getName().str().c_str(),
                           AI->getName().str().c_str(), (long long)off, (long long)size,
                           !s ? "not inside one parameter" : !type_ok ? "type" : "before its store / size");
          continue;
        }
        IRBuilder<> B(L);
        const int64_t d = off - s->off;
        Value *R;
        if (s->slots) {
          Value *P = d ? B.CreateConstInBoundsGEP1_64(Type::getInt8Ty(C), s->slots, d) : (Value *)s->slots;
          LoadInst *NL = B.CreateAlignedLoad(LT, P, commonAlignment(Align(8), d), L->getName() + ".arg");
          R = NL;
        } else {
          Value *X = s->scalar;
          Type *XT = X->getType();
          const unsigned xb = DL.getTypeSizeInBits(XT);
          Type *XI = IntegerType::get(C, xb);
          if (XT->isPointerTy()) X = B.CreatePtrToInt(X, XI);
          else if (!XT->isIntegerTy()) X = B.CreateBitCast(X, XI);
          if (d) X = B.CreateLShr(X, (uint64_t)d * 8);
          Type *LI = IntegerType::get(C, size * 8);
          if (size * 8 < (int64_t)xb) X = B.CreateTrunc(X, LI);
          if (LT->isPointerTy()) X = B.CreateIntToPtr(X, LT);
          else if (!LT->isIntegerTy()) X = B.CreateBitCast(X, LT);
          R = X;
        }
        L->replaceAllUsesWith(R);
        L->eraseFromParent();
        fwd++;
      }
      n_fwd += fwd;
      n_kept += kept;
      if (kept) {
        n_partial++;
        fprintf(stderr, "[param-fwd] %s: %s: %u loads read the parameters directly, %u still read the buffer\n",
                F.getName().str().c_str(), AI->getName().str().c_str(), fwd, kept);
        continue;
      }
      // no load left: drop the copies, the address arithmetic and the alloca
      for (const Src &x : srcs) {
        Value *X = x.S->getValueOperand();
        x.S->eraseFromParent();
        if (auto *LS = dyn_cast<LoadInst>(X))
          if (LS->use_empty()) LS->eraseFromParent();
      }
      for (Instruction *I : markers) I->eraseFromParent();
      std::vector<Instruction *> dead;
      std::function<void(Value *)> collect = [&](Value *V) {
        for (User *U : V->users()) collect(U);
        if (V != AI) dead.push_back(cast<Instruction>(V));
      };
      collect(AI);
      for (Instruction *I : dead) { if (I->use_empty()) I->eraseFromParent(); }
      if (AI->use_empty()) { AI->eraseFromParent(); n_removed++; }
      else { n_partial++; fprintf(stderr, "[param-fwd] %s: buffer has uses left after forwarding\n", F.getName().str().c_str()); }
      if (why || cupbop_debug())
        fprintf(stderr, "[param-fwd] %s: parameter buffer removed (%u loads read the parameters directly)\n",
                F.getName().str().c_str(), fwd);
    }
  }
  if (n_fwd || n_skipped || n_partial)
    fprintf(stderr, "[CuPBoP] parameter buffers: %u removed, %u partly forwarded, %u kept; %u loads read the parameters "
                    "directly, %u read a buffer\n", n_removed, n_partial, n_skipped, n_fwd, n_kept);
}
