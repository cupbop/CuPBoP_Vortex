#include "generate_wrapper.h"
#include "base_address.h"
#include "tool.h"
#include "cg_sync.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <iostream>
#include <sstream>
#include <fstream>
#include <cstdlib>
#include <map>
#include <set>
#include <algorithm>
#include <cstdio>

#include <cstdlib>
#include <cstring>
#include <string>

// Software stack (CUPBOP_BIG_STACK=<bytes per hardware thread>, set by examples/stack_fallback.sh when a kernel
// function's static frame does not fit the 8 KB hardware stack, VX_MEM_STACK_LOG2_SIZE=13): kernel_main calls the
// translated kernel on a stack of that size in device memory instead. A frame beyond 8 KB writes into the next
// hardware thread's stack: lifted kernels whose register spills alone are 10-30 KB (CUTLASS/cuDNN tensor-op GEMM
// and conv mainloops, the 128-accumulator conv2d at s2) crashed with misaligned accesses. The host allocates
// (device hardware threads, rounded up to 16) x <bytes> (cupbop_big_stack.txt) and stores the base in
// __cupbop_big_stack; hardware thread h's stack top is base + (h+1) x <bytes> (h = (core x NW + warp) x NT + lane,
// physical ids, so h stays below that count with the RT_NW/NC/NT caps too; <bytes> is a 4 KB multiple + 64 so that
// one frame slot of neighbouring lanes falls into different cache sets). The trampoline keeps the old sp and ra
// on the new stack, so the hardware stack is untouched below kernel_main. Without the variable set by the host
// (base 0) the kernel runs on the hardware stack as before. Unset: the wrapper is exactly the old one.
static long big_stack_bytes() {
  const char *e = std::getenv("CUPBOP_BIG_STACK");
  long v = e ? std::atol(e) : 0;
  return v > 0 ? (v + 15) / 16 * 16 : 0;
}
static std::string big_stack_prelude() {
  const long n = big_stack_bytes();
  if (!n) return "";
  return "// Software stack, " + std::to_string(n) + " bytes per hardware thread (CUPBOP_BIG_STACK; see generate_wrapper.cpp)\n"
         "#include <VX_config.h>\n"
         "extern \"C\" { char *__cupbop_big_stack = 0; }\n"
         "extern \"C\" void __cupbop_stack_call(vx_kernel_func_cb fn, void *arg, char *top);\n"
         "asm(\".text\\n.p2align 2\\n.globl __cupbop_stack_call\\n.type __cupbop_stack_call,@function\\n\"\n"
         "    \"__cupbop_stack_call:\\n\"\n"
         "    \"  addi a2, a2, -16\\n  sd ra, 8(a2)\\n  sd sp, 0(a2)\\n  mv sp, a2\\n\"\n"
         "    \"  mv t0, a0\\n  mv a0, a1\\n  jalr t0\\n\"\n"
         "    \"  ld ra, 8(sp)\\n  ld sp, 0(sp)\\n  ret\\n.size __cupbop_stack_call, .-__cupbop_stack_call\\n\");\n"
         "static inline __attribute__((always_inline)) void __cupbop_call_kernel(vx_kernel_func_cb fn, void *arg) {\n"
         "    char *base = *(char *volatile *)&__cupbop_big_stack;\n"
         "    if (!base) { fn(arg); return; }\n"
         "    const uint64_t h = ((uint64_t)vx_core_id() * VX_CFG_NUM_WARPS + (uint64_t)vx_warp_id()) * VX_CFG_NUM_THREADS\n"
         "                       + (uint64_t)vx_thread_id();\n"
         "    __cupbop_stack_call(fn, arg, base + (h + 1) * " + std::to_string(n) + "ull);\n"
         "}\n\n";
}
// Kernel ABI call and per-warp stack-pointer skew (2026-10-30, experiments/stack_native and experiments/kabi).
// The hardware stack interleave (VX_CFG_LSU_STACK_INTERLEAVE) stores one frame word of a warp's NT stacks as NT
// consecutive words and XORs the word index with the warp's stack group, so the hot top of every warp's frame lands in
// the same 64-word window of its 8 KB stack: with 64 warps all those frame tops fall into 1/8 of the L2 sets, and once
// resident warps x hot words / 64 exceeds the 8 L2 ways the cycles jump (hotspot s2 3.1x, btree s2 7x). What pushes the
// translated kernels over that threshold is mostly needless stack traffic: kernel_main called them as ordinary
// functions, so every thread saved and restored up to 13 integer and 12 FP callee-saved registers at the frame top.
//  * CUPBOP_KABI (1 = on, 0 = off; default KABI_DEFAULT below): the translated kernels and their wrappers get the
//    Vortex kernel calling convention (annotation "vortex.kernel", Vortex LLVM's RISCVVortexKEntryPass: no callee-saved register is saved;
//    the backend also emits a __vx_kentry_<name> alias that vxbin.py lists in the .vxbin symbol footer, next to
//    "main" = kernel_main), and kernel_main calls the kernel through inline asm that clobbers every register except
//    sp, gp, tp and its operands, so it keeps nothing live in a callee-saved register across the call (the compiler
//    spills what it needs, e.g. the lane gate's join tokens). The annotated functions are listed in cupbop_kabi.txt;
//    examples/abi_check.py checks the kernel ELF after every build that has the list (examples/stack_fallback.sh) and
//    fails the build if a caller of such a function may read a callee-saved register after the call before writing
//    it (annotation without the asm call: vx_join read s0/s1 after the call and s1 FAILed; an alloca-based skew made
//    kernel_main's frame pointer s0 live across the call and hung).
//  * CUPBOP_SP_SKEW (auto = 8, 0 = off, 1/2/4/8 = upper bound; default SP_SKEW_DEFAULT below): kernel_main lowers sp
//    by (global warp % M) x __CUPBOP_SP_SKEW_STEP bytes (CUPBOP_SP_SKEW_STEP, default 512 = the 64-word XOR window of
//    64 warps) around the call, so the frame tops of different warps fall into M different windows (L2 set groups).
//    The skew is computed inside the asm from mhartid / NT before the call and recomputed after it (nothing has to
//    survive the call); mhartid is the physical (core x NW + warp) x NT + lane, so it stays constant per thread under
//    the RT_NW / RT_NC / RT_NT caps and the skew is always within (M-1) x STEP. It costs (M-1) x STEP bytes of the 8 KB
//    stack: examples/stack_fallback.sh rewrites the __CUPBOP_SP_SKEW_M line of kernel_wrapper.cpp to the largest
//    M in {8,4,2,1} with max frame + (M-1) x STEP <= CUPBOP_FRAME_LIMIT (7168) after the build and rebuilds when it
//    changed. A software-stack build (CUPBOP_BIG_STACK: no hardware interleave there) gets M = 1.
//  * CUPBOP_KABI=0 CUPBOP_SP_SKEW=0: the wrapper is exactly the previous one (same machine code). CUPBOP_KABI=0 with the
//    skew on keeps the ordinary calling convention and only skews (asm call); the kernel ABI with CUPBOP_SP_SKEW=0
//    calls through the asm without the skew.
// Defaults when the variable is unset or empty: both on since 2026-10-30 (the user's decision). The skew was off for a
// day (2026-10-31, c22327a): the frame check of stack_fallback.sh did not count the run-time sized allocas (core-mapping
// context arrays), so M = 8 overflowed the 8 KB stack (CUTLASS basic_gemm s1p1, prod curlcurl s1p2); since f77b52a such
// kernels get M = 1. Cycle numbers from before 2026-10-30 are reproduced with CUPBOP_KABI=0 CUPBOP_SP_SKEW=0.
static const char *const KABI_DEFAULT = "1", *const SP_SKEW_DEFAULT = "auto";
static const char *env_or(const char *name, const char *dflt) {
  const char *e = std::getenv(name);
  return e && *e ? e : dflt;
}
static bool is_off(const char *v) { return !std::strcmp(v, "0") || !std::strcmp(v, "off"); }
static bool kabi_on() { return !is_off(env_or("CUPBOP_KABI", KABI_DEFAULT)); }
static bool sp_skew_req() { return !is_off(env_or("CUPBOP_SP_SKEW", SP_SKEW_DEFAULT)); }
static int sp_skew_m() {
  if (big_stack_bytes() || !sp_skew_req()) return 1;   // the software stack is not interleaved (own 64-byte stride skew)
  const char *e = env_or("CUPBOP_SP_SKEW", SP_SKEW_DEFAULT);
  if (!std::strcmp(e, "auto")) return 8;
  int v = std::atoi(e), m = 1;
  while (m * 2 <= v && m < 8) m *= 2;
  return m;
}
static int sp_skew_step() {
  const char *e = std::getenv("CUPBOP_SP_SKEW_STEP");
  int v = e ? std::atoi(e) : 512, s = 8;
  while (s * 2 <= v && s < 2048) s *= 2;
  return s;
}
// the asm call: the kernel ABI, or the skew (kept when the build-time frame check later sets M to 1)
static bool asm_call_on() { return kabi_on() || (sp_skew_req() && !big_stack_bytes()); }
static std::string kabi_prelude() {
  if (!asm_call_on()) return "";
  const long bs = big_stack_bytes();
  std::string s =
      "// Kernel call through inline asm (CUPBOP_KABI / CUPBOP_SP_SKEW; see generate_wrapper.cpp kabi_prelude).\n"
      "// Kernel ABI " + std::string(kabi_on() ? "on" : "off") + ". __CUPBOP_SP_SKEW_M: the warps' sp skew modulus "
      "(1 = none); examples/stack_fallback.sh rewrites that line to fit the frame.\n"
      "#include <VX_config.h>\n"
      "#define __CUPBOP_SP_SKEW_M " + std::to_string(sp_skew_m()) + "\n"
      "#define __CUPBOP_SP_SKEW_STEP " + std::to_string(sp_skew_step()) + "\n"
      "static constexpr int __cupbop_log2(unsigned v) { return v <= 1 ? 0 : 1 + __cupbop_log2(v >> 1); }\n"
      "static_assert((__CUPBOP_SP_SKEW_M & (__CUPBOP_SP_SKEW_M - 1)) == 0 && __CUPBOP_SP_SKEW_M <= 8, \"skew modulus\");\n"
      "static_assert((VX_CFG_NUM_THREADS & (VX_CFG_NUM_THREADS - 1)) == 0, \"NT\");\n"
      "static inline __attribute__((always_inline)) void __cupbop_kcall(vx_kernel_func_cb fn, void *arg) {\n"
      "    register void *__a0 asm(\"a0\") = arg;\n"
      "    register void *__t2 asm(\"t2\") = (void *)fn;\n";
  if (bs)
    s += "    // software stack (CUPBOP_BIG_STACK): the old sp is kept on the new stack, as __cupbop_stack_call does\n"
         "    char *__base = *(char *volatile *)&__cupbop_big_stack;\n"
         "    const uint64_t __h = ((uint64_t)vx_core_id() * VX_CFG_NUM_WARPS + (uint64_t)vx_warp_id()) * VX_CFG_NUM_THREADS\n"
         "                         + (uint64_t)vx_thread_id();\n"
         "    register char *__t1 asm(\"t1\") = __base ? __base + (__h + 1) * " + std::to_string(bs) + "ull : (char *)0;\n";
  s += "    __asm__ volatile(\n";
  if (bs)
    s += "        \"beqz t1, 1f\\n\\taddi t1, t1, -16\\n\\tsd sp, 0(t1)\\n\\tmv sp, t1\\n\\tjalr ra, 0(t2)\\n\\tld sp, 0(sp)\\n\\tj 2f\\n1:\\n\\t\"\n";
  s += "#if __CUPBOP_SP_SKEW_M > 1\n"
       "        // sp -= (mhartid / NT % M) * STEP before the call, += the same after it\n"
       "        \"csrr t0, mhartid\\n\\tsrli t0, t0, %[nt]\\n\\tandi t0, t0, %[m]\\n\\tslli t0, t0, %[st]\\n\\tsub sp, sp, t0\\n\\t\"\n"
       "        \"jalr ra, 0(t2)\\n\\t\"\n"
       "        \"csrr t0, mhartid\\n\\tsrli t0, t0, %[nt]\\n\\tandi t0, t0, %[m]\\n\\tslli t0, t0, %[st]\\n\\tadd sp, sp, t0\"\n"
       "#else\n"
       "        \"jalr ra, 0(t2)\"\n"
       "#endif\n";
  if (bs) s += "        \"\\n2:\"\n";
  s += std::string("        : \"+r\"(__a0), \"+r\"(__t2)") + (bs ? ", \"+r\"(__t1)" : "") + "\n"
       "        : [nt] \"i\"(__cupbop_log2(VX_CFG_NUM_THREADS)), [m] \"i\"(__CUPBOP_SP_SKEW_M - 1),\n"
       "          [st] \"i\"(__cupbop_log2(__CUPBOP_SP_SKEW_STEP))\n"
       "        : \"ra\", \"t0\"" + std::string(bs ? "" : ", \"t1\"") + ", \"t3\", \"t4\", \"t5\", \"t6\",\n"
       "          \"a1\", \"a2\", \"a3\", \"a4\", \"a5\", \"a6\", \"a7\",\n"
       "          \"s0\", \"s1\", \"s2\", \"s3\", \"s4\", \"s5\", \"s6\", \"s7\", \"s8\", \"s9\", \"s10\", \"s11\",\n"
       "          \"ft0\", \"ft1\", \"ft2\", \"ft3\", \"ft4\", \"ft5\", \"ft6\", \"ft7\", \"ft8\", \"ft9\", \"ft10\", \"ft11\",\n"
       "          \"fa0\", \"fa1\", \"fa2\", \"fa3\", \"fa4\", \"fa5\", \"fa6\", \"fa7\",\n"
       "          \"fs0\", \"fs1\", \"fs2\", \"fs3\", \"fs4\", \"fs5\", \"fs6\", \"fs7\", \"fs8\", \"fs9\", \"fs10\", \"fs11\", \"memory\");\n"
       "}\n\n";
  return s;
}

static std::string big_stack_call() {
  if (asm_call_on()) return "    __cupbop_kcall(callbacks[kernel_arg->kernel_idx], (void *)args);\n";
  return big_stack_bytes() ? "    __cupbop_call_kernel(callbacks[kernel_arg->kernel_idx], (void *)args);\n"
                           : "    callbacks[kernel_arg->kernel_idx](args);\n";
}

// The functions that get the kernel ABI (CUPBOP_KABI): decode_input records every kernel and its <name>_wrapper,
// create_kernel_wrapper_function the schedule 0/1 cuda_<name>_wrapper (annotated in kernel_wrapper.cpp), and
// annotate_kernel_abi (end of the translation) annotates the IR ones and writes cupbop_kabi.txt for abi_check.py.
static std::vector<std::pair<std::string, std::string>> g_kabi_kernels;   // (kernel, wrapper) in the IR
static std::vector<std::string> g_kabi_cxx_wrappers;                      // cuda_* in kernel_wrapper.cpp

using namespace llvm;


void set_meta_data(llvm::Module *M) {
  const char *arch_env = std::getenv("VORTEX_ARCHITECTURE");
  std::string arch = arch_env ? arch_env : "";

  if (arch == "64") {
    M->setTargetTriple("riscv64-unknown-unknown-elf");
    M->setDataLayout("e-m:e-p:64:64-i64:64-i128:128-n32:64-S128");
  } else {
    // this is an unverified guess for 32-bit RISC-V
    M->setTargetTriple("riscv32-unknown-unknown-elf");
    M->setDataLayout("e-m:e-p:32:32-i64:64-n32-S128"); 
  }
}

// Kernel-argument ABI for parameters wider than one launch slot (CuLifter: the whole cuBLAS / cuDNN / CUTLASS
// parameter struct as one `[N x i8] %arg_<cbank offset>`, or i128 members). cudaLaunchKernel_vortex packs 8 bytes
// per slot; a host that launches such a kernel passes the parameter's bytes in ceil(N/8) consecutive slots (the
// argument list of the lifted signature, in order, each parameter starting a new slot). The formal becomes a pointer
// to those slots (attribute "cupbop-arg-slots"="<k>", decode_input passes the slot address) and the body loads the
// old value from it: a first-class aggregate by value would otherwise be split into N scalar arguments of the
// non-inlined kernel call (registers + several KB of stack). This includes CuLifter's [N/64 x <8 x i64>] form of a
// 64-byte-multiple parameter struct; a CUtensorMap parameter (cvta.param) was already narrowed to its one slot by
// lower_async_ptx (narrowWideKernelArgs) and is no longer wide here. Before 2026-10-29 only the first 8 bytes of
// every such parameter reached the kernel (narrowWideKernelArgs, when the module had async intrinsics) or the
// parameter overlapped the slots of the following ones.
void pass_wide_kernel_args_by_slot(llvm::Module *M) {
  if (std::getenv("CUPBOP_WIDE_ARGS_BYVAL")) return; // debug: the old by-value aggregate (slots must still be consecutive)
  const DataLayout &DL = M->getDataLayout();
  LLVMContext &ctx = M->getContext();
  auto wide = [&](Argument &A) {
    Type *T = A.getType();
    return !T->isPointerTy() && !T->isVectorTy() && DL.getTypeStoreSize(T) > 8;
  };
  std::vector<Function *> todo;
  for (auto &F : *M)
    if (!F.isDeclaration() && isKernelFunction(M, &F))
      for (auto &A : F.args())
        if (wide(A)) { todo.push_back(&F); break; }
  Type *PtrT = PointerType::get(ctx, 0);
  for (Function *F : todo) {
    std::vector<Type *> params;
    std::vector<unsigned> slots;
    for (auto &A : F->args()) {
      unsigned k = wide(A) ? (unsigned)((DL.getTypeStoreSize(A.getType()) + 7) / 8) : 0;
      slots.push_back(k);
      params.push_back(k ? PtrT : A.getType());
    }
    FunctionType *FT = FunctionType::get(F->getReturnType(), params, F->isVarArg());
    Function *NF = Function::Create(FT, F->getLinkage(), F->getAddressSpace(), "", M);
    NF->copyAttributesFrom(F);
    AttributeList AL = F->getAttributes();
    for (unsigned i = 0; i < slots.size(); ++i)
      if (slots[i]) {
        AL = AL.removeParamAttributes(ctx, i);
        AL = AL.addParamAttribute(ctx, i, Attribute::get(ctx, "cupbop-arg-slots", std::to_string(slots[i])));
        AL = AL.addParamAttribute(ctx, i, Attribute::NoAlias);
        AL = AL.addParamAttribute(ctx, i, Attribute::get(ctx, Attribute::Alignment, 8));
      }
    NF->setAttributes(AL);
    NF->setCallingConv(F->getCallingConv());
    NF->takeName(F);
    NF->splice(NF->begin(), F);
    IRBuilder<> B(&*NF->getEntryBlock().getFirstInsertionPt());
    for (unsigned i = 0; i < slots.size(); ++i) {
      Argument *OA = F->getArg(i), *NA = NF->getArg(i);
      if (!slots[i]) { NA->takeName(OA); OA->replaceAllUsesWith(NA); continue; }
      NA->setName(OA->getName() + ".slots");
      Value *v = B.CreateAlignedLoad(OA->getType(), NA, Align(8), OA->getName());
      OA->replaceAllUsesWith(v);
      if (cupbop_debug())
        fprintf(stderr, "[CuPBoP] %s: parameter %u (%u bytes) passed in %u launch slots\n", NF->getName().str().c_str(),
                i, (unsigned)DL.getTypeStoreSize(OA->getType()), slots[i]);
    }
    F->replaceAllUsesWith(NF);
    F->eraseFromParent();
  }
}

// By-value struct parameters of CUDA source kernels (clang: `ptr byval(%struct.T) align A`). The launch passes all
// bytes of such a parameter in ceil(size/8) consecutive 8-byte slots (cudaLaunchKernel_vortex, cupbop_byval_args.txt
// written by decode_input), shared by every thread of the launch. Here, before the warp / thread loops are built:
//  - a parameter the kernel may write (byval_may_write) gets a private copy at entry, so each CUDA thread writes its
//    own (the flat schedule runs all threads of a block in one hardware thread);
//  - `byval` is replaced by the marker "cupbop-byval-bytes"="<size>" (+ readonly noalias): the kernel then reads the
//    slots through a plain pointer, like any pointer argument, and decode_input passes the slot address. Keeping
//    `byval` makes the wrapper call copy the struct to the stack and blocks inlining (E10 hotspot +36% cycles).
// A CUtensorMap parameter keeps its old one-slot form (decode_input). CUPBOP_BYVAL_ARGS=0: none of this (before
// 2026-10-31: the wrapper loaded the first slot as the struct's address and the host copied only 8 bytes).
// May the kernel write through (or let escape) pointer P? Loads and memcpy/memmove sources are reads; GEPs and casts
// are followed; anything else counts as a write.
static bool byval_may_write(Value *P) {
  SmallVector<Value *, 16> work{P};
  SmallPtrSet<Value *, 16> seen;
  while (!work.empty()) {
    Value *V = work.pop_back_val();
    if (!seen.insert(V).second) continue;
    for (User *U : V->users()) {
      if (isa<LoadInst>(U)) continue;
      if (isa<GetElementPtrInst>(U) || isa<BitCastInst>(U) || isa<AddrSpaceCastInst>(U)) { work.push_back(U); continue; }
      if (auto *MT = dyn_cast<MemTransferInst>(U))
        if (MT->getRawSource() == V && MT->getRawDest() != V) continue;
      if (auto *II = dyn_cast<IntrinsicInst>(U))
        if (II->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(II)) continue;
      return true;
    }
  }
  return false;
}
static bool cupbop_byval_on() {
  const char *e = std::getenv("CUPBOP_BYVAL_ARGS");
  return !(e && std::string(e) == "0");
}
static bool is_tensor_map_type(Type *T) {
  auto *ST = dyn_cast<StructType>(T);
  return ST && ST->hasName() && ST->getName().starts_with("struct.CUtensorMap");
}
void prepare_byval_args(llvm::Module *M) {
  if (!cupbop_byval_on()) return;
  const DataLayout &DL = M->getDataLayout();
  LLVMContext &ctx = M->getContext();
  for (auto &F : *M) {
    if (F.isDeclaration() || !isKernelFunction(M, &F)) continue;
    for (auto &A : F.args()) {
      if (!A.hasByValAttr() || is_tensor_map_type(A.getParamByValType())) continue;
      Type *T = A.getParamByValType();
      const uint64_t bytes = DL.getTypeAllocSize(T);
      if (!A.use_empty() && !A.onlyReadsMemory() && byval_may_write(&A)) {
        IRBuilder<> B(&*F.getEntryBlock().getFirstInsertionPt());
        AllocaInst *Copy = B.CreateAlloca(T, nullptr, A.getName() + ".priv");
        const Align Al = A.getParamAlign().valueOrOne();
        Copy->setAlignment(Al);
        A.replaceAllUsesWith(Copy);
        B.CreateMemCpy(Copy, Al, &A, Al, bytes);
        if (cupbop_debug())
          fprintf(stderr, "[CuPBoP] %s: by-value parameter %u may be written: private copy\n", F.getName().str().c_str(), A.getArgNo());
      }
      const unsigned i = A.getArgNo();
      F.removeParamAttr(i, Attribute::ByVal);
      F.addParamAttr(i, Attribute::get(ctx, "cupbop-byval-bytes", std::to_string(bytes ? bytes : 1)));
      F.addParamAttr(i, Attribute::ReadOnly);
      F.addParamAttr(i, Attribute::NoAlias);
    }
  }
}

// as pthread only accept a single void* for input
// we have to decode this input inside the kernel
void decode_input(llvm::Module *M) {

  std::set<llvm::Function *> need_remove;

  LLVMContext *C = &M->getContext();
  llvm::Type *Int32T = Type::getInt32Ty(*C);
  llvm::Type *Int8T = Type::getInt8Ty(*C);

  llvm::FunctionType *LauncherFuncT = FunctionType::get(
    Type::getVoidTy(*C), {PointerType::get(Int8T, 0)}, false);

  std::set<GlobalVariable *> dynmaic_memory;

  std::map<GlobalVariable *, Value *> corres_dynamic_memory_load_address;

  // by-value struct parameters (prepare_byval_args) -> cupbop_byval_args.txt for cudaLaunchKernel_vortex
  std::ofstream byval_file("cupbop_byval_args.txt", std::ios::out | std::ios::trunc);
  byval_file << "# CuPBoP by-value struct kernel parameters (translator -> cudaLaunchKernel_vortex): <kernel as in "
                "lookup.txt> <parameters> <bytes of each by-value parameter, 0 = not by-value>\n";

  // generate Wrapper Function type
  // now we only support a single int32*
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    if (!isKernelFunction(M, F))
      continue;

    auto func_name = F->getName().str();
    if (cupbop_debug()) printf("function name: %s\n", func_name.c_str());
    
    // remove mangle prefix
    // remove _Z24
    // this only applies for nvcc compiled kernel (pass for triton)
    bool triton_enabled = triton_cupbop_enabled();
    if ((triton_enabled && func_name[0] == '_') || (!triton_enabled)) {
      for (int pos = 2; pos < func_name.length(); pos++) {
      if (func_name[pos] >= '0' && func_name[pos] <= '9')
        continue;
      func_name = func_name.substr(pos);
      break;
    } 
    }
    llvm::IRBuilder<> Builder(M->getContext());

    FunctionCallee fc =
        M->getOrInsertFunction(func_name + "_wrapper", LauncherFuncT);
    g_kabi_kernels.emplace_back(F->getName().str(), func_name + "_wrapper");
    Function *WorkGroup = dyn_cast<Function>(fc.getCallee());

    BasicBlock *Block = BasicBlock::Create(M->getContext(), "", WorkGroup);
    Builder.SetInsertPoint(Block);

    // get the wrapper kernel arguments
    Function::arg_iterator ai = WorkGroup->arg_begin();

    SmallVector<Value *, 8> Arguments;
    Value *input_arg = &*ai;
    // convert to int**
    input_arg = Builder.CreateBitOrPointerCast(
        input_arg, PointerType::get(PointerType::get(Int32T, 0), 0));

    // dynamic memory load in the wrapper function
    GlobalVariable *share_memory = M->getGlobalVariable("wrapper_global_data");
    if (share_memory != NULL) {
      dynmaic_memory.insert(share_memory);
      llvm::GlobalVariable *global_mem = new llvm::GlobalVariable(
          *M, Int32T, false, llvm::GlobalValue::ExternalLinkage, NULL,
          "thread_memory_size", NULL, llvm::GlobalValue::GeneralDynamicTLSModel,
          0, false);
      Value *loadedValue = createLoad(Builder, global_mem);

      llvm::FunctionType *LaunchFun2 = FunctionType::get(PointerType::get(PointerType::get(Int32T, 0), 0), false);
      // Triton version
      // llvm::FunctionType *LaunchFun2 = FunctionType::get(
          // PointerType::get(PointerType::get(Int32T, 0), 0), NULL);

      FunctionCallee fc2 =
          M->getOrInsertFunction("_wrapper_global_data", LaunchFun2);

      Function *WorkGroup2 = dyn_cast<Function>(fc2.getCallee());

      WorkGroup2->setLinkage(GlobalValue::WeakODRLinkage);
      WorkGroup2->setVisibility(GlobalValue::HiddenVisibility);
      Comdat *co = M->getOrInsertComdat("_wrapper_global_data");
      co->setSelectionKind(Comdat::SelectionKind::Any);
      WorkGroup2->setComdat(co);

      BasicBlock *Block2 = BasicBlock::Create(M->getContext(), "", WorkGroup2);

      llvm::IRBuilder<> Builder2(M->getContext());
      Builder2.SetInsertPoint(Block2);
      Builder2.CreateRet(share_memory);

      auto PT = dyn_cast<PointerType>(share_memory->getType());

      //LLVM 18 changes
      //auto element_type = PT->getElementType();
      // LLVM 17+: pointers are opaque; the pointee is the global's value type.
      [[maybe_unused]] auto element_type = share_memory->getValueType();
      (void)PT;

      // std::cout << element_type->getTypeID()  << " Got global memor $$$$$$"
      // << share_memory->getName().str() << std::endl;

      AllocaInst *new_arr = Builder.CreateAlloca(Int8T, loadedValue, "new_arr");
      // new_arr->setAlignment(llvm::MaybeAlign(16));
      Value *new_ar = new_arr;
      Value *gptr = Builder.CreateBitOrPointerCast(
          share_memory, PointerType::get(PointerType::get(Int8T, 0), 0));

      Builder.CreateStore(new_ar, gptr);
    }

    size_t idx = 0;
    std::vector<uint64_t> byval_bytes;
    for (Function::const_arg_iterator ii = F->arg_begin(), ee = F->arg_end();
         ii != ee; ++ii) {
      Type *ArgType = ii->getType();
      // A by-value struct parameter (prepare_byval_args: marker "cupbop-byval-bytes"): pass the address of its
      // first slot (an aligned copy when it needs more than the slots' 8-byte alignment). A CUtensorMap
      // (`const __grid_constant__ CUtensorMap`) keeps the old one-slot form below: the host's 8 first bytes are the
      // device address of its record (cuTensorMapEncodeTiled shim, cupbop_async.h), which the kernel reads.
      if (F->getAttributes().hasParamAttr(ii->getArgNo(), "cupbop-byval-bytes")) {
        uint64_t bytes = 0;
        F->getAttributes().getParamAttr(ii->getArgNo(), "cupbop-byval-bytes").getValueAsString().getAsInteger(10, bytes);
        const uint64_t nslots = (bytes + 7) / 8;
        Value *SlotP = Builder.CreateGEP(PointerType::get(Int32T, 0), input_arg, ConstantInt::get(Int32T, idx));
        const MaybeAlign A = ii->getParamAlign();
        if (A && A->value() > 8) { // slots are 8-byte aligned: give the callee an aligned copy
          AllocaInst *Copy = Builder.CreateAlloca(ArrayType::get(Int8T, bytes), nullptr, "byval.copy");
          Copy->setAlignment(*A);
          Builder.CreateMemCpy(Copy, *A, SlotP, Align(8), bytes);
          SlotP = Copy;
        }
        Arguments.push_back(SlotP);
        byval_bytes.push_back(bytes);
        idx += nslots;
        continue;
      }
      byval_bytes.push_back(0);
      // A wide by-value parameter (pass_wide_kernel_args_by_slot) arrives in consecutive 8-byte slots: pass the
      // address of its first slot and skip the rest.
      if (F->getAttributes().hasParamAttr(ii->getArgNo(), "cupbop-arg-slots")) {
        unsigned nslots = 0;
        F->getAttributes().getParamAttr(ii->getArgNo(), "cupbop-arg-slots").getValueAsString().getAsInteger(10, nslots);
        Value *SlotP = Builder.CreateGEP(PointerType::get(Int32T, 0), input_arg, ConstantInt::get(Int32T, idx));
        Arguments.push_back(SlotP);
        idx += nslots;
        continue;
      }

      // calculate addr
      // LLVM 18 changes
      //Value *GEP = createGEP(Builder, input_arg, ConstantInt::get(Int32T, idx));
      Value *GEP = Builder.CreateGEP(PointerType::get(Int32T, 0), input_arg,
                                     ConstantInt::get(Int32T, idx));
      // load corresponding int*
      //GEP = Builder.CreateLoad(GEP);
      // bitcast
      GEP = Builder.CreateBitOrPointerCast(GEP, PointerType::get(ArgType, 0));
      Value *Arg = Builder.CreateLoad(ArgType, GEP);
      Arguments.push_back(Arg);
      ++idx;
    }

    Builder.CreateCall(F, ArrayRef<llvm::Value *>(Arguments));
    Builder.CreateRetVoid();
    if (std::any_of(byval_bytes.begin(), byval_bytes.end(), [](uint64_t b) { return b != 0; })) {
      // the struct's slot pointer makes the inliner's cost model keep the kernel out of line (E10 hotspot: +7.5%
      // cycles, a call per thread); a kernel with scalar parameters is inlined into its wrapper anyway
      if (!F->hasFnAttribute(Attribute::NoInline)) F->addFnAttr(Attribute::AlwaysInline);
      byval_file << func_name << " " << byval_bytes.size();
      for (uint64_t b : byval_bytes) byval_file << " " << b;
      byval_file << "\n";
      if (cupbop_debug())
        fprintf(stderr, "[CuPBoP] %s: by-value struct parameters passed in launch slots (%zu slots)\n", func_name.c_str(), idx);
    }
  }

  for (auto f : need_remove) {
    f->dropAllReferences();
    f->eraseFromParent();
  }
}

void remove_barrier(llvm::Module *M) {
  std::vector<Instruction *> need_remove;
  for (auto F = M->begin(); F != M->end(); ++F)
    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->isInlineAsm())
            continue;
          auto func_name = Call->getCalledOperand()->getName().str();
          if (isWarpSync(func_name) ||
              func_name == "llvm.nvvm.barrier0" ||
              func_name == "llvm.nvvm.barrier.sync") {
            need_remove.push_back(Call);
          }
        }
      }
    }
  for (auto inst : need_remove) {
    inst->eraseFromParent();
  }
}

void remove_useless_var(llvm::Module *M) {
    M->getGlobalVariable("intra_warp_index")->eraseFromParent();
    M->getGlobalVariable("inter_warp_index")->eraseFromParent();
}

std::string converttostring(const char* a) {
    std::string s = a;
    return s;
}

void create_kernel_wrapper_function(llvm::Module *M){

    auto ALIGNED_CTX_SIZE = 100;

    std::string kernel_name_tmp;
    std::vector<std::string> wrapper_name;
    //std::vector<int> kernel_idx;

    int schedule = 0;
    if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
      schedule = std::stoi(std::string(env));
    }
    // The legacy vx_spawn TLS copies (threadIdx/blockIdx/__local_group_id, block_index_*, thread_id_*) are made only
    // where something reads them: the flat schedule (one CUDA block per hardware thread, block index computed
    // below) or CUPBOP_SREG_TLS=1. Otherwise translated kernels and the device runtime read the CTA CSRs, the
    // kernel has no TLS at all, and the start code has nothing to zero per hardware thread.
    const bool tls_copies = schedule == 0 || !sreg_from_csr();

    
    std::fstream outfile;
    outfile.open("lookup.txt", std::ios::out);
    outfile.close();
    
    ///////////////// Temporarily not using (.txt) //////////////////
    /*
    while(readfile >> kernel_idx_tmp)
    {
      readfile >> kernel_name_tmp;
      kernel_idx.push_back(kernel_idx_tmp);
      std::cout << "looking for kernel name " << kernel_name_tmp << " with " << kernel_idx_tmp << std::endl;
      readfile.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
      wrapper_name.push_back(kernel_name_tmp + "_wrapper");
    }
    readfile.close();
    */

    int kernel_idx = 0;
    bool triton_enabled = triton_cupbop_enabled();

    for (auto F = M->begin(); F != M->end(); ++F) {
      for (auto BB = F->begin(); BB != F->end(); ++BB) {
        for (auto BI = BB->begin(); BI != BB->end(); BI++) {
          if (auto Call = dyn_cast<CallInst>(BI)) {
            if (!Call->getCalledFunction())
              continue;

            auto func_name = Call->getCalledOperand()->getName().str();
            auto func_arg_size = Call->getCalledFunction()->arg_size();
            if (cupbop_debug()) std::cout << "currently looking function is " << func_name << std::endl;

            // Find the kernel function name
            if(isKernelFunction(M, Call->getCalledFunction()) && std::find(wrapper_name.begin(), wrapper_name.end(), func_name+"_wrapper") == wrapper_name.end())
            {
              if (cupbop_debug()) std::cout << "Found the kernel name for the kernel_wrapper.cpp, it is " << func_name << "with number of arg "<< func_arg_size << " kernel_idx: " << std::to_string(kernel_idx) << std::endl;
              
              // remove _Z24, covers triton as well
              if ((triton_enabled && func_name[0] == '_') || (!triton_enabled)) {
                for (int i = 2; i < func_name.length(); i++) {
                  if (func_name[i] >= '0' && func_name[i] <= '9')
                    continue;
                  func_name = func_name.substr(i);
                  break;
                }
              }

              
              wrapper_name.push_back(func_name + "_wrapper");
              outfile.open("lookup.txt", std::ios::app);
              outfile << kernel_idx << " " << func_name << " " << func_arg_size << "\n";
              outfile.close();
              kernel_idx++;
            }
          }
        }
      }
    }

    // Read __device__ variable info from kernel_meta.log
    struct DeviceVarInfo { std::string name; uint64_t size; };
    std::vector<DeviceVarInfo> device_vars;
    {
      std::ifstream meta("kernel_meta.log");
      std::string line;
      bool in_device_section = false;
      while (std::getline(meta, line)) {
        if (line == "DeviceVariables") { in_device_section = true; continue; }
        if (line == "END_DeviceVariables") { in_device_section = false; continue; }
        if (in_device_section) {
          std::istringstream iss(line);
          DeviceVarInfo info;
          iss >> info.name >> info.size;
          device_vars.push_back(info);
        }
      }
    }

    std::stringstream ss;

    ss << "#include <stdint.h>\n"
          "#include <vx_print.h>\n"
          "#include <vx_intrinsics.h>\n"
          "#include <vx_spawn.h>\n"
          "#include <stdint.h>\n"
          "#include <string.h>\n"
          "\n"

          "#define KERNEL_ARG_BASE_ADDR "
          << KERNEL_ARG_BASE_ADDR <<
          "\n"
          //memcpytosymbol: Implementation updated, we will not use the additional info base addr for now, but we can keep this macro for future use if needed
          //"#define KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR "
          //<< KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR <<
          "\n"
          "\n"

          "void (* volatile vx_barrier_dummy)(int, int) = vx_barrier;\n"
          // "int (* volatile vx_vote_all_dummy)(int) = vx_vote_all;\n"
          // "int (* volatile vx_vote_any_dummy)(int) = vx_vote_any;\n"
          // "int (* volatile vx_vote_uni_dummy)(int) = vx_vote_uni;\n"
          // "int (* volatile vx_vote_ballot_dummy)(int) = vx_vote_ballot;\n"
          // "int (* volatile vx_shfl_up_dummy)(size_t, int, int, int) = vx_shfl_up;\n"
          // "int (* volatile vx_shfl_down_dummy)(size_t, int, int, int) = vx_shfl_down;\n"
          // "int (* volatile vx_shfl_bfly_dummy)(size_t, int, int, int) = vx_shfl_bfly;\n"
          // "int (* volatile vx_shfl_idx_dummy)(size_t, int, int, int) = vx_shfl_idx;\n"
          "\n"
          "\n"

      "struct alignas(8) context_t { \n"
      "uint32_t num_groups[3]; \n"
      "uint32_t global_offset[3]; \n"
      "uint32_t local_size[3]; \n"
      "char * printf_buffer; \n"
      "uint32_t printf_buffer_position; \n"
      "uint32_t printf_buffer_capacity; \n"
      "uint32_t work_dim; \n"
      "uint32_t dyn_shared_mem_size; \n"
      "}; \n"
      "\n"

          "typedef struct {\n"
          "    context_t ctx;\n"
          "    int kernel_idx;\n"
          "    int num_args;\n"
          "    uint64_t args[0];\n"
          "} kernel_arg_t;\n"
          "\n";

    if (schedule != 2) {
      // Schedule 0/1: CuPBoP's own globals (populated by cuda_*_wrapper)
      ss << "int grid_size_x;\n"
            "int grid_size_y;\n"
            "int grid_size_z;\n"
            "\n"

            "int block_size_x;\n"
            "int block_size_y;\n"
            "int block_size_z;\n"
            "\n"

            "int block_size;\n"
            "\n"

            "__attribute__((used)) int __thread block_index_x;\n"
            "__attribute__((used)) int __thread block_index_y;\n"
            "__attribute__((used)) int __thread block_index_z;\n"

            "__attribute__((used)) int __thread *dynamic_shared_memory = NULL;\n"


            "__attribute__((used)) int __thread thread_id_x;\n"
            "__attribute__((used)) int __thread thread_id_y;\n"
            "__attribute__((used)) int __thread thread_id_z;\n"
            "\n"
            "#include <VX_config.h>\n"
            "__attribute__((used)) int __thread warp_shfl[NUM_WARPS * NUM_THREADS] = {0};\n"
            "__attribute__((used)) char __thread warp_vote[32] = {0};\n"
            "__attribute__((used)) int __thread vote_count = 0;\n"
            "\n";
    }

    ss << "char *__ctx_pool = 0;\n"
          "int dyn_shared_mem_size;\n\n";

    // __device__ variables are preserved across kernel launches by the host
    // runtime (cudaRuntimeImpl.cpp) using the cudaMemcpyToSymbol mechanism.
    // No device-side scratch needed.

    ss << "// Vortex 3.0 KMU launch (CUPBOP_LAUNCH2): the CTA dispatcher hands each CTA its own\n"
          "// local-memory window (VX_CSR_CTA_LMEM_ADDR, stride = lmem_size of the launch), so the\n"
          "// legacy __local_mem(size) = base + group_id*size carve is no longer needed.\n"
          "extern \"C\" void* vx_local_alloc(uint32_t size) {\n"
            "(void)size;\n"
            "void* p = (void*)csr_read_nv(VX_CSR_CTA_LMEM_ADDR);\n"
            //"vx_printf(\"local memory allocation with %d bytes, add 0x%p\\n\", size, p);\n"
            // "void* csr_read = (void*)csr_read(VX_CSR_LOCAL_MEM_BASE);\n"
            // "vx_printf(\"csr_parameter: %d\\n\", VX_CSR_LOCAL_MEM_BASE);\n"
            // "vx_printf(\"csr_read_value: %p\\n\", csr_read);\n"
            // "vx_printf(\"local_group_id: %d\\n\", __local_group_id);\n"
            "return p;\n"
          "}\n"


          "\n";


    ss <<  "\n extern \"C\" {\n";

    for (auto f : wrapper_name) {
        ss << "    extern void " + f + "(void *args);\n";
    }

    ss << "}\n"
          "\n";

    if (schedule != 2) {
      // Schedule 0/1: generate cuda_*_wrapper that copies vx_spawn TLS → CuPBoP TLS
      for (auto f : wrapper_name) {
        if (kabi_on()) g_kabi_cxx_wrappers.push_back("cuda_" + f);
        ss << (kabi_on() ? "extern \"C\" __attribute__((annotate(\"vortex.kernel\"))) " : "") << "void cuda_" << f << "(void* args) {\n"
                  "    // block_index_{x,y,z} were set by the KMU entry (one CUDA block per hardware thread)\n"
           << (schedule == 0 || tls_copies ?
                  "    thread_id_x = 0;\n"
                  "    thread_id_y = 0;\n"
                  "    thread_id_z = 0;\n" : "") <<
                  "\n"
                  "//    vx_printf(\"kernel_warpper: group=(%d, %d) thread=(%d, %d)\\n\", blockIdx.x, blockIdx.y, thread_id_x, thread_id_y);\n"
                  "\n"
              "    " << f << "((void **)args);\n"
                "}\n"
                "\n";
      }
    }

    ss << "vx_kernel_func_cb callbacks[] = {\n";

    for (auto f : wrapper_name) {
      if (schedule == 2) {
        // Schedule 2: call kernel wrapper directly — no TLS copy layer
        ss << "    (vx_kernel_func_cb)" << f << ", \n";
      } else {
        ss << "    cuda_" << f << ", \n";
      }
    }

    ss << "};\n"
          "\n";

    // FIX (huffman SCHE_2 LMEM=1 wrap bug, May 13 2026): emit per-kernel static
    // lmem size table. Built from kernel_lmem.log written by mem_share2local.
    // main() reads this to set __vx_lmem_per_cta_bytes before vx_spawn_threads
    // so groups_per_core can be clamped to avoid lmem wraparound.
    {
      // Apply the same Itanium-ABI demangling-prefix strip that CuPBoP uses for
      // wrapper_name: strip "_Z" and any subsequent length digits. See
      // lines 262-266 above for the original logic.
      auto strip_mangling_prefix = [](std::string s) -> std::string {
        if (s.size() < 2 || s[0] != '_' || s[1] != 'Z') return s;
        size_t i = 2;
        while (i < s.size() && s[i] >= '0' && s[i] <= '9') ++i;
        return s.substr(i);
      };
      std::map<std::string, uint32_t> kernel_to_lmem;
      std::ifstream lmem_log("kernel_lmem.log");
      if (lmem_log.is_open()) {
        std::string raw_kname;
        uint32_t bytes;
        while (lmem_log >> raw_kname >> bytes) {
          std::string kname = strip_mangling_prefix(raw_kname);
          // Keep the maximum across multiple entries (passes may log the same
          // kernel more than once; we want the final layout size).
          auto it = kernel_to_lmem.find(kname);
          if (it == kernel_to_lmem.end() || it->second < bytes) {
            kernel_to_lmem[kname] = bytes;
          }
        }
      }
      ss << "// Per-kernel __shared__ static byte count (index = kernel_idx).\n";
      ss << "// Set to 0 if unknown; vx_spawn_threads then skips its lmem clamp.\n";
      // Provide a WEAK fallback definition so that linking succeeds against
      // older libvortex.a builds that don't yet define this global (no
      // vx_spawn lmem-clamp fix). In that case main() still writes to this
      // variable but no one reads it — harmless. When linking against a new
      // libvortex.a, both weak symbols merge and vx_spawn_threads reads the
      // value main() stores.
      ss << "extern \"C\" __attribute__((weak)) uint32_t __vx_lmem_per_cta_bytes = 0;\n";
      ss << "static const uint32_t kernel_static_lmem_bytes[] = {\n";
      for (auto f : wrapper_name) {
        // Strip the "_wrapper" suffix to get the kernel symbol name used by
        // mem_share2local for its log entries.
        std::string kname = f;
        const std::string suffix = "_wrapper";
        if (kname.size() >= suffix.size() &&
            kname.compare(kname.size() - suffix.size(), suffix.size(), suffix) == 0) {
          kname.resize(kname.size() - suffix.size());
        }
        uint32_t bytes = 0;
        // Map keys are pre-normalized to the same demangled form as kname
        // (see strip_mangling_prefix above).
        auto it = kernel_to_lmem.find(kname);
        if (it != kernel_to_lmem.end()) {
          bytes = it->second;
        }
        ss << "    " << bytes << "u, // " << kname << "\n";
      }
      ss << "};\n\n";
    }

    ss <<
          "// ─── Vortex 3.0 KMU entry (CUPBOP_LAUNCH2) ─────────────────────────────────\n"
          "// The host launches this entry with the real CUDA grid/block geometry\n"
          "// (vx_enqueue_launch); the hardware CTA dispatcher places one CTA per core slot and\n"
          "// every thread of every CTA starts here with the kernel-arg pointer in MSCRATCH.\n"
          "// We fill the legacy vx_spawn globals (threadIdx/blockIdx TLS, blockDim/gridDim,\n"
          "// __local_group_id, __warps_per_group) from the CTA CSRs so the translated kernel IR\n"
          "// and the device runtime keep working unchanged.\n"
          "static inline __attribute__((always_inline)) void __cupbop_fill_spawn_globals() {\n"
          << (tls_copies ?
          "    threadIdx.x = (uint32_t)csr_read_nv(VX_CSR_CTA_THREAD_ID_X);\n"
          "    threadIdx.y = (uint32_t)csr_read_nv(VX_CSR_CTA_THREAD_ID_Y);\n"
          "    threadIdx.z = (uint32_t)csr_read_nv(VX_CSR_CTA_THREAD_ID_Z);\n"
          "    blockIdx.x  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_ID_X);\n"
          "    blockIdx.y  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_ID_Y);\n"
          "    blockIdx.z  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_ID_Z);\n"
          "    __local_group_id = (uint32_t)csr_read_nv(VX_CSR_CTA_ID);\n" : "") <<
          "    blockDim.x  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_DIM_X);\n"
          "    blockDim.y  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_DIM_Y);\n"
          "    blockDim.z  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_DIM_Z);\n"
          "    gridDim.x   = (uint32_t)csr_read_nv(VX_CSR_CTA_GRID_DIM_X);\n"
          "    gridDim.y   = (uint32_t)csr_read_nv(VX_CSR_CTA_GRID_DIM_Y);\n"
          "    gridDim.z   = (uint32_t)csr_read_nv(VX_CSR_CTA_GRID_DIM_Z);\n"
          "    __warps_per_group = (uint32_t)csr_read_nv(VX_CSR_CTA_SIZE);\n"
          "}\n"
          "\n"
          "// Service launches (grid 1, block 1): kernel_idx == -1 applies the cudaMemcpyToSymbol\n"
          "// list [count | dst, size, inline data...]*; kernel_idx == -2 performs device->device\n"
          "// copies [count | dst, src, size]* (device-variable read-back into a staging buffer).\n"
          "static void __cupbop_service(int kernel_idx, uint64_t* list) {\n"
          "    if (kernel_idx == -1) {\n"
          "        uint64_t* slot = &list[1];\n"
          "        for (int i = 0; i < (int)list[0]; i++) {\n"
          "            auto dst_addr = (void*)slot[0];\n"
          "            auto size = (size_t)slot[1];\n"
          "            auto src_data = (void*)&slot[2];\n"
          "            memcpy(dst_addr, src_data, size);\n"
          "            size_t data_slots = (size + sizeof(uint64_t) - 1) / sizeof(uint64_t);\n"
          "            slot += 2 + data_slots;\n"
          "        }\n"
          "    } else if (kernel_idx == -2) {\n"
          "        uint64_t* slot = &list[1];\n"
          "        for (int i = 0; i < (int)list[0]; i++) {\n"
          "            memcpy((void*)slot[0], (const void*)slot[1], (size_t)slot[2]);\n"
          "            slot += 3;\n"
          "        }\n"
          "    }\n"
          "}\n"
          "\n"
          << big_stack_prelude() << kabi_prelude() <<
          "extern \"C\" __attribute__((annotate(\"vortex.kernel\"), used, retain, noinline))\n"
          << (kabi_on() ? "void kernel_main(kernel_arg_t* __UNIFORM__ kernel_arg) {\n" : "void kernel_main(kernel_arg_t* kernel_arg) {\n") <<
          "    auto ctx = &kernel_arg->ctx; \n"
          "    auto num_args = kernel_arg->num_args;\n"
          "    auto args = (uint64_t*)kernel_arg->args;\n"
          "    if (kernel_arg->kernel_idx < 0) { __cupbop_service(kernel_arg->kernel_idx, args + num_args); return; }\n"
          "    __cupbop_fill_spawn_globals();\n"
          "    dyn_shared_mem_size = ctx->dyn_shared_mem_size;\n"
;
    if (schedule == 0) {
      ss <<           "    // Flat schedule: one CUDA block per hardware thread. The host launched\n"
          "    // ceil(num_blocks / NT) CTAs of NT threads; recover the CUDA block index.\n"
          "    grid_size_x = ctx->num_groups[0];\n"
          "    grid_size_y = ctx->num_groups[1];\n"
          "    grid_size_z = ctx->num_groups[2];\n"
          "    block_size_x = ctx->local_size[0];\n"
          "    block_size_y = ctx->local_size[1];\n"
          "    block_size_z = ctx->local_size[2];\n"
          "    block_size = ctx->local_size[0] * ctx->local_size[1] * ctx->local_size[2];\n"
          "    uint32_t linear = blockIdx.x * blockDim.x + threadIdx.x;\n"
          "    uint32_t total = ctx->num_groups[0] * ctx->num_groups[1] * ctx->num_groups[2];\n"
          "    if (linear >= total) return;\n"
          "    block_index_x = linear % ctx->num_groups[0];\n"
          "    block_index_y = (linear / ctx->num_groups[0]) % ctx->num_groups[1];\n"
          "    block_index_z = linear / (ctx->num_groups[0] * ctx->num_groups[1]);\n"
          << big_stack_call() <<
          "}\n"
;
    } else if (schedule == 1) {
      // Core mapping (virt): CTA == CUDA block but only P physical warps; the
      // translated kernel loops over logical warps rank, rank+P, ... (insert_warp_loop)
      // and __syncthreads is a real CTA barrier. Logical geometry comes from ctx.
      {
      int vl = getVirtGeom().lanes;
      extern int need_nested_loop; // set by insert_warp_loop (sub-pass form)
      const int own_stride = need_nested_loop ? 32 : vl; // logical threads a physical warp owns per pass
      ss << "    const bool getenv_dbg_virt = " << (std::getenv("CUPBOP_VIRT_DEBUG_PRINT") ? "true" : "false") << ";\n";
      ss << "    const uint32_t __bs = ctx->local_size[0] * ctx->local_size[1] * ctx->local_size[2];\n"
            "    const uint32_t __L = " << (std::to_string(vl) + "u") << "; // lanes per warp: CUPBOP_VIRT_LANES at translation, else NT\n"
            "    const uint32_t __lane = (uint32_t)vx_thread_id();\n"
            "    const uint32_t __rank = (uint32_t)csr_read_nv(VX_CSR_CTA_RANK);\n"
            "    // Grid constants are plain globals the translated kernel reads. No fence here: on the\n"
            "    // Vortex RTL a fence is a whole-cache flush (L1 and L2 written back and invalidated),\n"
            "    // per CTA. Each hardware thread stores them only when what it reads differs (in practice\n"
            "    // the first CTAs of a launch) and afterwards reads its own store or a value it has just\n"
            "    // checked; every writer stores the same values, so program order on one thread suffices.\n"
            "    // (Storing from every thread unconditionally cost small kernels more than their body:\n"
            "    // nn stores 2.4x of 1:1.)\n"
            "    if (getenv_dbg_virt && __lane == 0 && __rank == 0 && csr_read_nv(VX_CSR_CTA_BLOCK_ID_X) == 0 && csr_read_nv(VX_CSR_CTA_BLOCK_ID_Y) == 0) vx_printf(\"[virt] L=%d bs=%d nt=%d\\n\", (int)__L, (int)__bs, (int)vx_num_threads());\n"
            "    {\n"
            "        const int __gx = (int)ctx->num_groups[0], __gy = (int)ctx->num_groups[1], __gz = (int)ctx->num_groups[2];\n"
            "        const int __lx = (int)ctx->local_size[0], __ly = (int)ctx->local_size[1], __lz = (int)ctx->local_size[2];\n"
            "        if (grid_size_x != __gx || grid_size_y != __gy || grid_size_z != __gz ||\n"
            "            block_size_x != __lx || block_size_y != __ly || block_size_z != __lz || block_size != (int)__bs) {\n"
            "            grid_size_x = __gx; grid_size_y = __gy; grid_size_z = __gz;\n"
            "            block_size_x = __lx; block_size_y = __ly; block_size_z = __lz;\n"
            "            block_size = (int)__bs;\n"
            "        }\n"
            "    }\n"
            << (tls_copies ?
            "    block_index_x = blockIdx.x;\n"
            "    block_index_y = blockIdx.y;\n"
            "    block_index_z = blockIdx.z;\n" : "") <<
            "    // Lane gating and partial blocks: hardware thread (rank, lane) owns logical\n"
            "    // threads rank*L + lane + k*(P*L); one without any (lane >= L, or beyond the\n"
            "    // block) leaves now, before the kernel's uniform control flow reads its\n"
            "    // per-thread scalars. The warp keeps its other lanes, so CTA barriers\n"
            "    // (counted per warp) are unaffected; the host guarantees every warp owns\n"
            "    // at least one logical thread (P <= ceil(block/L)).\n"
            "    if (__lane >= __L || __rank * " << own_stride << "u + __lane >= __bs) return;\n"
            << big_stack_call() <<
            "}\n";
      }
    } else {
      ss << big_stack_call() <<
          "}\n"
;
    }
    ss << "\n";

    auto content = ss.str();

    std::ofstream ofs;

    //NOTE: was ../vortex_debug/kernel_wrapper.cpp — changed to cwd for per-example build
    ofs.open("kernel_wrapper.cpp");
    ofs << ss.rdbuf();
    ofs.close();

    return;
}

void generate_wrapper(llvm::Module *M) {
  // change metadata
  set_meta_data(M);
  // decode argument
  decode_input(M);
  // remove barrier
  remove_barrier(M);
  // remove useless func/variable
  remove_useless_var(M);
  // create kernel wraper function  // Hyesoon 6-7-202 
  create_kernel_wrapper_function(M);
}

// CUPBOP_KABI (see kabi_prelude): at the end of the translation, give every kernel wrapper <name>_wrapper and the
// kernel it calls the Vortex kernel calling convention (@llvm.global.annotations entry "vortex.kernel", read by Vortex
// LLVM's RISCVVortexKEntryPass when the cell compiles the kernel), and list them with the schedule 0/1 cuda_* wrappers
// in cupbop_kabi.txt (examples/abi_check.py checks every caller in the kernel ELF). Off: no annotation, and a stale
// cupbop_kabi.txt from an earlier translation in the same directory is removed.
void annotate_kernel_abi(llvm::Module *M) {
  std::remove("cupbop_kabi.txt");
  if (!kabi_on() || g_kabi_kernels.empty()) return;
  LLVMContext &C = M->getContext();
  auto *PtrTy = PointerType::getUnqual(C);
  auto *I32 = Type::getInt32Ty(C);
  auto *ElemTy = StructType::get(C, {PtrTy, PtrTy, PtrTy, I32, PtrTy});
  auto str = [&](const std::string &v, const char *name) {
    auto *Init = ConstantDataArray::getString(C, v);
    auto *G = new GlobalVariable(*M, Init->getType(), true, GlobalValue::PrivateLinkage, Init, name);
    G->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
    G->setSection("llvm.metadata");
    return G;
  };
  std::vector<Constant *> elems;
  if (GlobalVariable *GA = M->getNamedGlobal("llvm.global.annotations")) {
    if (auto *CA = dyn_cast<ConstantArray>(GA->getInitializer()))
      for (auto &op : CA->operands()) elems.push_back(cast<Constant>(op));
    GA->eraseFromParent();
  }
  Constant *Note = str("vortex.kernel", ".cupbop.kabi.note");
  Constant *File = str("cupbop", ".cupbop.kabi.file");
  std::vector<std::string> names;
  auto add = [&](Function *F) {
    if (!F || F->isDeclaration() || std::find(names.begin(), names.end(), F->getName().str()) != names.end()) return;
    names.push_back(F->getName().str());
    elems.push_back(ConstantStruct::get(ElemTy, {F, Note, File, ConstantInt::get(I32, 0), ConstantPointerNull::get(PtrTy)}));
  };
  for (auto &kw : g_kabi_kernels) {
    Function *W = M->getFunction(kw.second);
    if (!W || W->isDeclaration()) continue;
    add(W);
    // the kernel itself when the wrapper still calls it (not inlined)
    for (auto &BB : *W)
      for (auto &I : BB)
        if (auto *CI = dyn_cast<CallBase>(&I))
          if (Function *Callee = CI->getCalledFunction())
            if (Callee->getName() == kw.first) add(Callee);
  }
  if (!names.empty()) {
    auto *AT = ArrayType::get(ElemTy, elems.size());
    auto *GA = new GlobalVariable(*M, AT, false, GlobalValue::AppendingLinkage, ConstantArray::get(AT, elems),
                                  "llvm.global.annotations");
    GA->setSection("llvm.metadata");
  }
  std::ofstream f("cupbop_kabi.txt");
  f << "# functions with the Vortex kernel ABI (CUPBOP_KABI, generate_wrapper.cpp annotate_kernel_abi); "
       "checked by examples/abi_check.py\n";
  for (auto &n : names) f << n << "\n";
  for (auto &n : g_kabi_cxx_wrappers) f << n << "\n";
}
