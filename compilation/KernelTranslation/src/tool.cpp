#include "tool.h"
#include "warp_func.h"
#include "flag.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Demangle/Demangle.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include <cctype>
#include <cstring>
#include <cstdlib>
#include <vector>
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FileSystem.h"

// LLVM 18
// #include "llvm/Support/ManagedStatic.h"
// #include "llvm/Support/MemoryBuffer.h"
#include "llvm/IR/Type.h"
#include "llvm/Pass.h"
#include "llvm/Support/SourceMgr.h"

#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/Analysis/ValueTracking.h"

#include "cg_sync.h"
#include "llvm_type_utils.h"

#include <fstream>
#include <iostream>
#include <map>
#include <set>

using namespace llvm;

// cupbop_debug() defined in tool.h
#define DBG_PRINT(...)                                                         \
  do {                                                                         \
    if (cupbop_debug())                                                        \
      printf(__VA_ARGS__);                                                     \
  } while (0)

#define DBG(BODY)                                                              \
  do {                                                                         \
    if (cupbop_debug()) {                                                      \
      BODY                                                                     \
    }                                                                          \
  } while (0)

bool triton_cupbop_enabled() {
  static bool enabled = [] {
    const char *v = std::getenv("TRITON_CUPBOP");
    return (v != nullptr && std::strcmp(v, "1") == 0);
  }();
  return enabled;
}

llvm::Module *LoadModuleFromFilr(char *file_name) {
  llvm::SMDiagnostic Err;
  llvm::LLVMContext *globalContext = new llvm::LLVMContext;
  auto program = parseIRFile(file_name, Err, *globalContext).release();
  if (!program) {
    printf("error when opening the bitcode\n");
    exit(1);
  }
  return program;
}

void VerifyModule(llvm::Module *program) {
  std::string msg;
  llvm::raw_string_ostream os(msg);
  if (llvm::verifyModule(*program, &(llvm::errs())))
    llvm::report_fatal_error(os.str().c_str());
}

void DumpModule(llvm::Module *M, char *file_name) {
  // modify the program, add a wrapper
  std::string msg;
  llvm::raw_string_ostream os(msg);
  std::error_code EC;
  ToolOutputFile Out(file_name, EC, sys::fs::OF_None);
  if (EC) {
    errs() << "Fails to open output file: " << EC.message();
    return;
  }
  WriteBitcodeToFile(*M, Out.os());
  Out.keep();
}

// LLVM 20 clang marks CUDA kernels with the ptx_kernel calling convention instead of
// the nvvm.annotations {F, "kernel", 1} entry that this translator (and LLVM <= 18
// clang) use. Normalize: record the annotation so isKernelFunction() keeps working,
// and drop the NVPTX-only calling convention, which the RISC-V backend rejects
// ("Unsupported calling convention").
void normalize_ptx_kernel_cc(llvm::Module *M) {
  llvm::LLVMContext &C = M->getContext();
  NamedMDNode *NamedMD = M->getOrInsertNamedMetadata("nvvm.annotations");
  for (Function &F : *M) {
    if (F.getCallingConv() != llvm::CallingConv::PTX_Kernel)
      continue;
    bool annotated = false;
    for (unsigned I = 0, E = NamedMD->getNumOperands(); I != E && !annotated; ++I) {
      MDNode *MD = NamedMD->getOperand(I);
      if (!MD || MD->getNumOperands() != 3) continue;
      auto *VMD = dyn_cast<llvm::ValueAsMetadata>(MD->getOperand(0));
      auto *Str = dyn_cast<MDString>(MD->getOperand(1));
      if (VMD && Str && VMD->getValue() == &F && Str->getString() == "kernel")
        annotated = true;
    }
    if (!annotated) {
      llvm::Metadata *Ops[] = {
          llvm::ValueAsMetadata::get(&F), MDString::get(C, "kernel"),
          llvm::ValueAsMetadata::get(ConstantInt::get(Type::getInt32Ty(C), 1))};
      NamedMD->addOperand(MDNode::get(C, Ops));
    }
    F.setCallingConv(llvm::CallingConv::C);
    for (User *U : F.users())
      if (auto *CB = dyn_cast<CallBase>(U))
        CB->setCallingConv(llvm::CallingConv::C);
  }
}

bool isKernelFunction(llvm::Module *M, llvm::Function *F) {
  NamedMDNode *NamedMD = M->getNamedMetadata("nvvm.annotations");
  if (!NamedMD) {
    printf("there must be nvvm.annotations!\n");
    exit(1);
  }
  for (unsigned I = 0, E = NamedMD->getNumOperands(); I != E; ++I) {
    MDNode *MD = NamedMD->getOperand(I);
    if (!MD || MD->getNumOperands() == 0)
      continue;
    if (MD->getNumOperands() != 3)
      continue;
    Metadata *Op = MD->getOperand(1);
    if (auto Str = llvm::cast<MDString>(Op)) {
      if (Str->getString().str() != "kernel")
        continue;
      auto *VMD = dyn_cast<llvm::ValueAsMetadata>(MD->getOperand(0));
      if (!VMD)
        continue;
      llvm::Value *meta = VMD->getValue();
      auto *FF = llvm::dyn_cast<Function>(meta);
      if (!FF)
        continue;
      if (FF->getName().str() == F->getName().str())
        return true;
    }
  }
  return false;
}

bool isDeviceFunction(Module *M, Function *F) {
  // Must be device-side code
  if (!(M->getTargetTriple().substr(0, 5) == "nvptx"))
    return false;
  // Skip declarations and intrinsics
  if (F->isDeclaration() || F->isIntrinsic())
    return false;
  // Skip kernels
  if (isKernelFunction(M, F))
    return false;
  return true;
}

void replace_block(llvm::Function *F, llvm::BasicBlock *before,
                   llvm::BasicBlock *after) {
  for (Function::iterator i = F->begin(); i != F->end(); ++i) {
    llvm::BasicBlock *bb = &(*i);
    if (bb == after)
      continue;
    bb->getTerminator()->replaceUsesOfWith(before, after);
  }
}

llvm::CallInst *CreateInterWarpBarrier(llvm::Instruction *InsertBefore) {
  llvm::Module *M = InsertBefore->getParent()->getParent()->getParent();

  llvm::FunctionType *LauncherFuncT =
      FunctionType::get(llvm::Type::getVoidTy(M->getContext()), {}, false);

  llvm::FunctionCallee f =
      M->getOrInsertFunction("llvm.nvvm.barrier0", LauncherFuncT);
  llvm::Function *F = llvm::cast<llvm::Function>(f.getCallee());
  return llvm::CallInst::Create(F, "", InsertBefore);
}

VirtGeom getVirtGeom() {
  VirtGeom g; g.schedule = 0; g.nt = 32;
  if (const char *e = std::getenv("VORTEX_SCHEDULE_FLAG")) g.schedule = std::atoi(e);
  if (const char *e = std::getenv("VORTEX_NUM_THREADS")) { int v = std::atoi(e); if (v > 0) g.nt = v; }
  int L = g.nt;
  if (const char *e = std::getenv("CUPBOP_VIRT_LANES")) { int v = std::atoi(e); if (v > 0 && v < L) L = v; }
  if (L > 32) L = 32;              // a wider warp runs one 32-lane logical warp at a time
  while (32 % L) L >>= 1;          // L must divide the CUDA warp
  g.lanes = L; g.subpasses = 32 / L; g.lg_lanes = 0;
  while ((1 << g.lg_lanes) < L) g.lg_lanes++;
  g.trips = 0; g.trips_exact = 0;
  if (const char *e = std::getenv("CUPBOP_VIRT_TRIPS_EXACT")) g.trips_exact = (std::atoi(e) != 0);
  if (const char *e = std::getenv("CUPBOP_VIRT_TRIPS")) { int v = std::atoi(e); if (v > 0 && g.schedule == 1 && g.subpasses == 1) g.trips = v; }
  return g;
}

llvm::CallInst *CreateIntraWarpBarrier(llvm::Instruction *InsertBefore) {
  llvm::Module *M = InsertBefore->getParent()->getParent()->getParent();

  // void @llvm.nvvm.bar.warp.sync(i32 %membermask)
  llvm::FunctionType *LauncherFuncT =
      llvm::FunctionType::get(llvm::Type::getVoidTy(M->getContext()),
                              {llvm::Type::getInt32Ty(M->getContext())}, false);

  llvm::FunctionCallee f =
      M->getOrInsertFunction("llvm.nvvm.bar.warp.sync", LauncherFuncT);

  llvm::Function *F = llvm::cast<llvm::Function>(f.getCallee());

  llvm::Constant *AllActiveMask = llvm::ConstantInt::get(
      llvm::Type::getInt32Ty(M->getContext()), 0xFFFFFFFF);

  return llvm::CallInst::Create(F, {AllActiveMask}, "", InsertBefore);
}

llvm::Instruction *BreakPHIToAllocas(PHINode *phi) {

  std::string allocaName = std::string(phi->getName().str()) + ".ex_phi";

  llvm::Function *function = phi->getParent()->getParent();

  IRBuilder<> builder(&*(function->getEntryBlock().getFirstInsertionPt()));

  llvm::Instruction *alloca =
      builder.CreateAlloca(phi->getType(), 0, allocaName);

  for (unsigned incoming = 0; incoming < phi->getNumIncomingValues();
       ++incoming) {
    Value *val = phi->getIncomingValue(incoming);
    BasicBlock *incomingBB = phi->getIncomingBlock(incoming);
    builder.SetInsertPoint(incomingBB->getTerminator());
    llvm::Instruction *store = builder.CreateStore(val, alloca);
  }
  // Insert the load at the phi's position, but AFTER any barrier calls
  // (cupbop.shfl.barrier, llvm.nvvm.barrier0) that were inserted at the
  // merge block start. This ensures the barrier is BEFORE the load,
  // so the exchange code is inside the intra-warp PR.
  Instruction *insertPt = phi;
  {
    auto *nextInst = phi->getNextNode();
    while (nextInst) {
      if (auto *CI = dyn_cast<CallInst>(nextInst)) {
        if (CI->getCalledFunction()) {
          auto name = CI->getCalledFunction()->getName();
          if (name == "cupbop.shfl.barrier" || name == "llvm.nvvm.barrier0" ||
              name == "llvm.nvvm.barrier.sync") {
            insertPt = nextInst->getNextNode();
            nextInst = insertPt;
            continue;
          }
        }
      }
      break;
    }
  }
  if (insertPt && insertPt != phi)
    builder.SetInsertPoint(insertPt);
  else
    builder.SetInsertPoint(phi);

  llvm::Instruction *loadedValue =
      createLoad(builder, alloca);
  phi->replaceAllUsesWith(loadedValue);
  phi->eraseFromParent();

  return loadedValue;
}

void phi2alloc(llvm::Module *M) {
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();
    if (!isKernelFunction(M, F))
      continue;

    typedef std::vector<llvm::Instruction *> InstructionVec;

    InstructionVec PHIs;

    for (Function::iterator bb = F->begin(); bb != F->end(); ++bb) {
      for (BasicBlock::iterator p = bb->begin(); p != bb->end(); ++p) {
        Instruction *instr = &*p;
        if (isa<PHINode>(instr)) {
          PHIs.push_back(instr);
        }
      }
    }

    bool changed = false;
    for (InstructionVec::iterator i = PHIs.begin(); i != PHIs.end(); ++i) {
      Instruction *instr = *i;
      BreakPHIToAllocas(dyn_cast<PHINode>(instr));
    }
  }
}

void remove_cuda_built_in(llvm::Module *M) {
  // initialize function name
  std::set<std::string> useless_func_name;
  useless_func_name.insert("cudaMalloc");
  useless_func_name.insert("cudaFuncGetAttributes");
  useless_func_name.insert("cudaGetDevice");
  useless_func_name.insert("cudaDeviceGetAttribute");
  useless_func_name.insert("cudaOccupancyMaxActiveBlocksPerMultiprocessor");
  useless_func_name.insert(
      "cudaOccupancyMaxActiveBlocksPerMultiprocessorWithFlags");

  std::set<llvm::Function *> need_remove;
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();
    if (useless_func_name.find(func_name) != useless_func_name.end()) {
      need_remove.insert(F);
    }
  }
  for (auto F : need_remove) {
    F->dropAllReferences();
    F->eraseFromParent();
  }
}

// copied from POCL
static void breakConstantExpressions(llvm::Value *Val, llvm::Function *Func) {
  std::vector<llvm::Value *> Users(Val->user_begin(), Val->user_end());
  for (auto *U : Users) {
    if (auto *CE = llvm::dyn_cast<llvm::ConstantExpr>(U)) {
      // First, make sure no users of this constant expression are themselves
      // constant expressions.
      breakConstantExpressions(U, Func);
      // Convert this constant expression to an instruction.
      llvm::Instruction *I = CE->getAsInstruction();
      I->insertBefore(&*Func->begin()->begin());
      if (cupbop_debug())
        printf("--------------------\n");
      if (cupbop_debug())
        std::cout << I << std::endl;
      CE->replaceAllUsesWith(I);
      CE->destroyConstant();
    }
  }
}

void replace_dynamic_shared_memory(llvm::Module *M) {
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    if (!isKernelFunction(M, F))
      continue;
    for (Module::global_iterator i = M->global_begin(), e = M->global_end();
         i != e; ++i) {
      breakConstantExpressions(&*i, F);
    }
    auto dynamic_shared_memory_addr =
        M->getGlobalVariable("dynamic_shared_memory");
    if (!dynamic_shared_memory_addr) {
      return;
    }
    auto load_shared_memory = new LoadInst(
        // LLVM 18
        // dynamic_shared_memory_addr->getType()->getPointerElementType(),
        dynamic_shared_memory_addr->getValueType(), dynamic_shared_memory_addr,
        "new_load", &*F->begin()->begin());
    auto new_bit_cast =
        new BitCastInst(load_shared_memory,
                        dynamic_shared_memory_addr->getType(), "new_bit_cast");
    // CHECK NEEDED
    new_bit_cast->insertAfter(load_shared_memory);
    //(old)new_bit_cast->insertBefore(&*F->begin()->begin());
    //(old)load_shared_memory->insertBefore(new_bit_cast);
    dynamic_shared_memory_addr->replaceUsesWithIf(new_bit_cast, [&](Use &U) {
      auto *Instr = dyn_cast<Instruction>(U.getUser());
      return Instr != new_bit_cast && Instr != load_shared_memory;
    });
  }
}

void lower_atomicrmw_fadd(llvm::Module *M) {
  // RISC-V "A" extension has no native float atomic add. The natural
  // lowering to a cmpxchg (LR/SC) loop livelocks under SIMT contention
  // because the inner `bnez` retry diverges and Vortex BR uses the
  // last-active-lane to decide branches. Replace with a call to the
  // runtime helper `__cuda_atomic_fadd_f32` (in cudaKernelImpl.cpp),
  // which serializes the RMW lane-by-lane to avoid the divergence.
  //
  // SCHE_0 only: lower_cmpxchg_for_flat (below) already converts cmpxchg to
  // plain load+compare+store (safe because FLAT mode runs threads serially),
  // so the standard cmpxchg expansion works fine without the helper. Skip
  // this lowering in SCHE_0 to avoid the helper's unnecessary lock overhead.
  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG"))
    schedule = std::stoi(std::string(env));
  if (schedule == 0) return;

  SmallVector<AtomicRMWInst *, 16> fadd_ops;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *RMW = dyn_cast<AtomicRMWInst>(&I))
          if (RMW->getOperation() == AtomicRMWInst::FAdd &&
              RMW->getValOperand()->getType()->isFloatTy())
            fadd_ops.push_back(RMW);

  if (fadd_ops.empty())
    return;

  auto &Ctx = M->getContext();
  auto *FloatTy = Type::getFloatTy(Ctx);
  auto *VoidTy = Type::getVoidTy(Ctx);
  auto *PtrTy = PointerType::getUnqual(Ctx);
  auto *FnTy = FunctionType::get(FloatTy, {PtrTy, FloatTy}, false);
  auto *VoidFnTy = FunctionType::get(VoidTy, {PtrTy, FloatTy}, false);
  FunctionCallee Helper = M->getOrInsertFunction(
      "__cuda_atomic_fadd_f32", FnTy);
  FunctionCallee HelperUniformVoid = M->getOrInsertFunction(
      "__cuda_atomic_fadd_f32_uniform_void", VoidFnTy);

  size_t nuniform = 0, ngeneral = 0;
  for (auto *RMW : fadd_ops) {
    IRBuilder<> B(RMW);
    auto *ptr = RMW->getPointerOperand();
    auto *addend = RMW->getValOperand();

    // Fast path: if the atomic result is unused AND the pointer is a
    // kernel argument (uniform across the warp — all 32 lanes add to
    // the same address), call the warp-reduced helper instead of the
    // lane-serialized one. Typical for accumulators like `atomicAdd(&g, v)`
    // where g is a single global scalar passed as a kernel parameter.
    // ~30x faster because it collapses 32 lock acquires into 1 per warp.
    // Check if pointer is uniform (same across all 32 lanes in a warp).
    // Clang's CUDA atomicAdd helper lowers to:
    //   %alloca = alloca ptr; store %arg → %alloca; %p = load %alloca
    //   atomicrmw fadd %p
    // so the RMW pointer is `load from alloca` that was stored from an Argument.
    const Value *underlying = getUnderlyingObject(ptr);
    bool addr_uniform = isa<Argument>(underlying) || isa<GlobalValue>(underlying);

    // getUnderlyingObject stops at load instructions. For the common pattern
    // above (load-from-alloca with store(s) whose values are uniform), walk
    // through. Accept multiple stores as long as ALL stored values are
    // Argument/GlobalValue (all uniform across the warp). Also trace chains
    // like load→alloca → load→alloca (inliner sometimes creates these).
    if (!addr_uniform) {
      const Value *cur = underlying;
      for (int depth = 0; depth < 4 && !addr_uniform; ++depth) {
        auto *L = dyn_cast<LoadInst>(cur);
        if (!L) break;
        auto *AI = dyn_cast<AllocaInst>(
            getUnderlyingObject(L->getPointerOperand()));
        if (!AI) break;
        const Value *storedVal = nullptr;
        bool all_uniform_stores = true;
        int store_count = 0;
        for (auto *U : AI->users()) {
          if (auto *SI = dyn_cast<StoreInst>(U)) {
            store_count++;
            const Value *v = SI->getValueOperand();
            if (!isa<Argument>(v) && !isa<GlobalValue>(v) &&
                !(isa<LoadInst>(v))) {
              all_uniform_stores = false;
              break;
            }
            storedVal = v;
          }
        }
        if (!storedVal || !all_uniform_stores) break;
        if (isa<Argument>(storedVal) || isa<GlobalValue>(storedVal)) {
          addr_uniform = true;
          break;
        }
        // storedVal is another Load — follow it
        cur = storedVal;
      }
    }

    if (RMW->use_empty() && addr_uniform) {
      auto *call = B.CreateCall(HelperUniformVoid, {ptr, addend});
      call->addFnAttr(Attribute::Convergent);
      RMW->eraseFromParent();
      nuniform++;
    } else {
      auto *call = B.CreateCall(Helper, {ptr, addend});
      RMW->replaceAllUsesWith(call);
      RMW->eraseFromParent();
      ngeneral++;
    }
  }
  fprintf(stderr, "[CuPBoP] lowered %zu atomicrmw fadd (%zu uniform-void + %zu general)\n",
          fadd_ops.size(), nuniform, ngeneral);
}

// Same pattern as lower_atomicrmw_fadd but for i64 atomicrmw add.
// RV64 has native amoadd.d so no software lock is needed; the only point
// is to collapse 32 lanes' atomics into 1 per warp via warp-reduce, which
// is a big win for kernels like marchingCubes' generatingTriangles where
// many lanes hammer a single uniform global counter inside a divergent
// for-loop. Safe under divergence because the helper is convergent and
// shfl-xor with inactive lanes returns 0 → those lanes contribute 0,
// matching their "didn't execute the atomic" semantics.
void lower_atomicrmw_add_i64(llvm::Module *M) {
  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG"))
    schedule = std::stoi(std::string(env));
  if (schedule == 0) return; // SCHE_0 doesn't need this (sequential exec)

  SmallVector<AtomicRMWInst *, 16> add_ops;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *RMW = dyn_cast<AtomicRMWInst>(&I))
          if (RMW->getOperation() == AtomicRMWInst::Add &&
              RMW->getValOperand()->getType()->isIntegerTy(64))
            add_ops.push_back(RMW);

  if (add_ops.empty())
    return;

  auto &Ctx = M->getContext();
  auto *I64Ty = Type::getInt64Ty(Ctx);
  auto *VoidTy = Type::getVoidTy(Ctx);
  auto *PtrTy = PointerType::getUnqual(Ctx);
  auto *VoidFnTy = FunctionType::get(VoidTy, {PtrTy, I64Ty}, false);
  FunctionCallee HelperUniformVoid = M->getOrInsertFunction(
      "__cuda_atomic_add_u64_uniform_void", VoidFnTy);
  if (auto *fn = dyn_cast<Function>(HelperUniformVoid.getCallee()))
    fn->addFnAttr(Attribute::Convergent);

  size_t nuniform = 0;
  for (auto *RMW : add_ops) {
    if (!RMW->use_empty()) continue; // only optimize use_empty (return ignored)
    IRBuilder<> B(RMW);
    auto *ptr = RMW->getPointerOperand();
    auto *addend = RMW->getValOperand();

    // Same uniform-pointer detection as lower_atomicrmw_fadd
    const Value *underlying = getUnderlyingObject(ptr);
    bool addr_uniform = isa<Argument>(underlying) || isa<GlobalValue>(underlying);
    if (!addr_uniform) {
      const Value *cur = underlying;
      for (int depth = 0; depth < 4 && !addr_uniform; ++depth) {
        auto *L = dyn_cast<LoadInst>(cur);
        if (!L) break;
        auto *AI = dyn_cast<AllocaInst>(
            getUnderlyingObject(L->getPointerOperand()));
        if (!AI) break;
        const Value *storedVal = nullptr;
        bool all_uniform_stores = true;
        int store_count = 0;
        for (auto *U : AI->users()) {
          if (auto *SI = dyn_cast<StoreInst>(U)) {
            store_count++;
            const Value *v = SI->getValueOperand();
            if (!isa<Argument>(v) && !isa<GlobalValue>(v) &&
                !(isa<LoadInst>(v))) {
              all_uniform_stores = false;
              break;
            }
            storedVal = v;
          }
        }
        if (!storedVal || !all_uniform_stores) break;
        if (isa<Argument>(storedVal) || isa<GlobalValue>(storedVal)) {
          addr_uniform = true;
          break;
        }
        cur = storedVal;
      }
    }

    if (!addr_uniform) continue;

    auto *call = B.CreateCall(HelperUniformVoid, {ptr, addend});
    call->addFnAttr(Attribute::Convergent);
    RMW->eraseFromParent();
    nuniform++;
  }
  fprintf(stderr, "[CuPBoP] lowered %zu atomicrmw add i64 to uniform-void warp-reduce\n",
          nuniform);
}

void lower_cmpxchg_for_flat(llvm::Module *M) {
  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG"))
    schedule = std::stoi(std::string(env));
  if (schedule != 0) return;

  // In SCHE_0 (FLAT mode), all threads run sequentially on one core.
  // LR/SC (load-reserved/store-conditional) may not work correctly
  // because Vortex simx may not track reservations in FLAT mode.
  // Replace cmpxchg with plain load+compare+store (safe: no races).
  SmallVector<AtomicCmpXchgInst *, 16> cas_ops;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *CAS = dyn_cast<AtomicCmpXchgInst>(&I))
          cas_ops.push_back(CAS);

  for (auto *CAS : cas_ops) {
    IRBuilder<> B(CAS);
    auto *ptr = CAS->getPointerOperand();
    auto *cmpVal = CAS->getCompareOperand();
    auto *newVal = CAS->getNewValOperand();
    auto *ty = cmpVal->getType();

    // Load current value
    auto *loaded = B.CreateLoad(ty, ptr);
    // Compare
    auto *eq = B.CreateICmpEQ(loaded, cmpVal);
    // Store new value if equal
    auto *selected = B.CreateSelect(eq, newVal, loaded);
    B.CreateStore(selected, ptr);

    // CAS returns {loaded_val, success_bit}
    Value *result = UndefValue::get(CAS->getType());
    result = B.CreateInsertValue(result, loaded, 0);
    result = B.CreateInsertValue(result, eq, 1);
    CAS->replaceAllUsesWith(result);
    CAS->eraseFromParent();
  }
  if (!cas_ops.empty())
    fprintf(stderr, "[FLAT] lowered %zu cmpxchg to plain load+cmp+store\n",
            cas_ops.size());
}

void replace_warp_shfl_early(llvm::Module *M) {
  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG"))
    schedule = std::stoi(std::string(env));
  if (schedule != 0) return; // Only FLAT mode needs early shfl replacement

  using namespace cupbop;
  ReplaceWarpLevelPrimitive rw(MAPPING_FLAT);
  rw.replaceWarpShfl(*M);
  fprintf(stderr, "[FLAT] early shfl replace done\n");
}

// llvm.nvvm.membar.cta right next to a CTA barrier -- CuLifter emits one after every bar.sync -- is
// dropped: a CTA runs on one core and vx_barrier drains the LSU before it releases (RTL VX_wctl_unit),
// so the barrier already orders the CTA's memory, while vx_fence is a whole-cache flush on the RTL (L1
// and L2 written back and invalidated) that would run at every __syncthreads. Runs before insert_sync /
// insert_warp_loop so the pair is still adjacent. A standalone membar.cta and membar.gl / membar.sys keep
// their vx_fence. CUPBOP_KEEP_CTA_MEMBAR=1 keeps them all.
void drop_cta_membar_at_barriers(llvm::Module *M) {
  if (std::getenv("CUPBOP_KEEP_CTA_MEMBAR")) return;
  auto isBarrier = [](llvm::Instruction *I) {
    auto *C = llvm::dyn_cast_or_null<llvm::CallInst>(I);
    if (!C || !C->getCalledFunction()) return false;
    auto n = C->getCalledFunction()->getName();
    return n.starts_with("llvm.nvvm.barrier") || n.starts_with("__cupbop_bar_"); // named barriers drain the LSU too
  };
  std::vector<llvm::CallInst *> dead;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB) {
        auto *C = llvm::dyn_cast<llvm::CallInst>(&I);
        if (!C || !C->getCalledFunction() || C->getCalledFunction()->getName() != "llvm.nvvm.membar.cta")
          continue;
        if (isBarrier(C->getPrevNonDebugInstruction()) || isBarrier(C->getNextNonDebugInstruction()))
          dead.push_back(C);
      }
  for (auto *C : dead)
    C->eraseFromParent();
  if (cupbop_debug() && !dead.empty())
    std::cout << "[membar] dropped " << dead.size() << " membar.cta next to a CTA barrier\n";
}

// PTX named barriers: `bar.sync a{, b}` / `bar.arrive a, b` (and the barrier.{,cta.}{sync,arrive}[.aligned]
// spellings) as inline asm -- how CUDA sources write them and how CuLifter lifts BAR.SYNC/BAR.ARV <id>,
// <count> -- and llvm.nvvm.barrier.sync{,.cnt}. Runs first, so every later pass sees ordinary calls.
// - Without a count every thread of the CTA takes part: a plain CTA barrier (llvm.nvvm.barrier0) whatever
//   the id, on every schedule.
// - With a count, or for an arrive, only some warps take part (warp specialization). On the 1:1 schedule
//   that is Vortex barrier `id` of this CTA counting b/32 warps (__cupbop_bar_sync / __cupbop_bar_arrive,
//   cudaKernelImpl.cpp). The warp-loop schedules run several CUDA warps on one hardware thread (flat) or
//   warp (core mapping) and cannot express it, so translation stops instead of dropping the barrier.
// Other barrier-family asm (bar.red, mbarrier, barrier.cluster, ...) is refused too: replace_asm_call would
// otherwise drop it with only a warning.
static std::string barrierAsmOpcode(llvm::CallInst *C, std::string *rest = nullptr) {
  if (!C || !C->isInlineAsm()) return "";
  auto *IA = llvm::dyn_cast<llvm::InlineAsm>(C->getCalledOperand());
  if (!IA) return "";
  const std::string &s = IA->getAsmString();
  size_t b = s.find_first_not_of(" \t\n");
  if (b == std::string::npos) return "";
  size_t e = s.find_first_of(" \t\n;", b);
  std::string op = s.substr(b, e == std::string::npos ? std::string::npos : e - b);
  bool family = op.rfind("bar.", 0) == 0 || op.rfind("barrier.", 0) == 0 || op.rfind("mbarrier.", 0) == 0;
  if (!family || op.rfind("bar.warp.", 0) == 0) return ""; // __syncwarp: no-op on Vortex, see replace_asm_call
  if (rest) *rest = e == std::string::npos ? "" : s.substr(e);
  return op;
}

void lower_named_barriers(llvm::Module *M) {
  int schedule = 0;
  if (const char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) schedule = std::atoi(env);
#ifdef VX_CFG_NUM_BARRIERS
  const uint64_t num_barriers = VX_CFG_NUM_BARRIERS;
#else
  const uint64_t num_barriers = 8;
#endif
  LLVMContext &ctx = M->getContext();
  Type *I32 = Type::getInt32Ty(ctx), *Void = Type::getVoidTy(ctx);
  auto fail = [](CallInst *C, const std::string &what) {
    std::string s;
    raw_string_ostream os(s);
    C->print(os);
    fprintf(stderr, "error: %s\n  at:%s (in %s)\n", what.c_str(), os.str().c_str(),
            C->getFunction()->getName().str().c_str());
    exit(1);
  };
  enum Kind { CTA_SYNC, COUNTED_SYNC, ARRIVE };
  struct Site { CallInst *call; Kind kind; std::vector<Value *> args; };
  std::vector<Site> sites;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB) {
        auto *C = dyn_cast<CallInst>(&I);
        if (!C) continue;
        if (!C->isInlineAsm()) {
          Function *Fn = C->getCalledFunction();
          if (!Fn) continue;
          if (Fn->getName() == "llvm.nvvm.barrier.sync")
            sites.push_back({C, CTA_SYNC, {}});
          else if (Fn->getName() == "llvm.nvvm.barrier.sync.cnt")
            sites.push_back({C, COUNTED_SYNC, {C->getArgOperand(0), C->getArgOperand(1)}});
          continue;
        }
        std::string rest, op = barrierAsmOpcode(C, &rest);
        if (op.empty()) continue;
        auto is = [&](const std::string &what) { // bar{.cta}.<what>, barrier{.cta}.<what>{.aligned}
          return op == "bar." + what || op == "bar.cta." + what || op.rfind("barrier." + what, 0) == 0 ||
                 op.rfind("barrier.cta." + what, 0) == 0;
        };
        bool sync = is("sync"), arrive = is("arrive");
        if (!sync && !arrive)
          fail(C, "unsupported PTX barrier asm `" + op + "` (dropping it would break synchronization)");
        // operands up to the first ';': $k (the k-th asm argument) or an integer literal
        size_t semi = rest.find(';');
        if (semi != std::string::npos && rest.find_first_not_of(" \t\n;", semi) != std::string::npos)
          fail(C, "barrier asm with more than one statement");
        std::vector<Value *> args;
        std::string list = rest.substr(0, semi), tok;
        for (size_t p = 0; p <= list.size();) {
          size_t q = list.find(',', p);
          tok = list.substr(p, q == std::string::npos ? std::string::npos : q - p);
          tok.erase(0, tok.find_first_not_of(" \t\n"));
          tok.erase(tok.find_last_not_of(" \t\n") + 1);
          char *end = nullptr;
          if (!tok.empty() && tok[0] == '$') {
            unsigned k = std::strtoul(tok.c_str() + 1, &end, 10);
            if (*end || k >= C->arg_size()) fail(C, "barrier asm operand `" + tok + "` is not an input");
            args.push_back(C->getArgOperand(k));
          } else if (!tok.empty()) {
            long long v = std::strtoll(tok.c_str(), &end, 0);
            if (*end) fail(C, "barrier asm operand `" + tok + "` is neither $k nor an integer");
            args.push_back(ConstantInt::get(I32, (uint64_t)v));
          }
          if (q == std::string::npos) break;
          p = q + 1;
        }
        if (args.empty() || args.size() > 2 || (arrive && args.size() != 2))
          fail(C, "barrier asm `" + op + "` needs an id and, for an arrive, a thread count");
        sites.push_back({C, arrive ? ARRIVE : args.size() == 1 ? CTA_SYNC : COUNTED_SYNC, args});
      }
  if (sites.empty()) return;
  FunctionCallee bar0 = M->getOrInsertFunction("llvm.nvvm.barrier0", FunctionType::get(Void, false));
  FunctionCallee bsync = M->getOrInsertFunction("__cupbop_bar_sync", FunctionType::get(Void, {I32, I32}, false));
  FunctionCallee barrive = M->getOrInsertFunction("__cupbop_bar_arrive", FunctionType::get(Void, {I32, I32}, false));
  // convergent, like the asm it replaces: otherwise LoopUnswitch copies the barrier into lane-dependent
  // branches and a warp arrives once per branch (deadlock); same fix as the shfl/vote helpers (warp_func.cpp)
  for (FunctionCallee f : {bsync, barrive})
    cast<Function>(f.getCallee())->addFnAttr(Attribute::Convergent);
  unsigned n_cta = 0, n_named = 0;
  for (auto &s : sites) {
    IRBuilder<> B(s.call);
    if (s.kind == CTA_SYNC) {
      B.CreateCall(bar0);
      ++n_cta;
    } else {
      if (schedule != 2)
        fail(s.call, "a named barrier with a thread count or an arrive (warp-specialized synchronization) is only "
                     "supported on the 1:1 schedule (SCHEDULE=2); schedule " + std::to_string(schedule) +
                     " runs several CUDA warps on one hardware " + (schedule == 1 ? "warp" : "thread"));
      if (auto *K = dyn_cast<ConstantInt>(s.args[0]))
        if (K->getZExtValue() >= num_barriers)
          fail(s.call, "named barrier id " + std::to_string(K->getZExtValue()) + " >= the " +
                       std::to_string(num_barriers) + " barriers per CTA of this Vortex configuration");
      if (auto *K = dyn_cast<ConstantInt>(s.args[1]))
        if (K->isZero() || K->getZExtValue() % 32)
          fail(s.call, "named barrier thread count must be a non-zero multiple of 32");
      B.CreateCall(s.kind == COUNTED_SYNC ? bsync : barrive,
                   {B.CreateZExtOrTrunc(s.args[0], I32), B.CreateZExtOrTrunc(s.args[1], I32)})
          ->addFnAttr(Attribute::Convergent);
      ++n_named;
    }
    s.call->eraseFromParent();
  }
  if (cupbop_debug())
    std::cout << "[named-barrier] " << n_cta << " CTA syncs, " << n_named << " counted syncs / arrives\n";
}

// block_index_*, block_size*, grid_size_* (and the virt barrier's __local_group_id / __warps_per_group)
// are written by the wrapper / kernel_main before a kernel
// runs and never inside it, but every store through a kernel pointer may alias them, so -O3 reloads
// them after each store -- and block_index_* is __thread, i.e. a different address (and cache line) per
// lane on Vortex. In every function that neither writes them nor calls a function that does, load each
// one once at entry and use that value. (Not !invariant.load: that claims the value for the whole
// program, and once the kernel is inlined into a wrapper that loops over blocks the load would be
// hoisted out of the loop.)
void hoist_block_constant_loads(llvm::Module *M) {
  // Off by default: on the flat schedule (bh-cuda) and the core-mapping sub-pass form (virt_warp_test L16) it
  // breaks the build or the run, and with sreg->CSR its main target (the per-lane TLS block index) is gone.
  // CUPBOP_HOIST_BLOCK_CONST_LOADS=1 turns it on.
  if (!std::getenv("CUPBOP_HOIST_BLOCK_CONST_LOADS")) return;
  std::set<llvm::GlobalVariable *> G;
  for (const char *n : {"block_index_x", "block_index_y", "block_index_z", "block_size_x", "block_size_y",
                        "block_size_z", "block_size", "grid_size_x", "grid_size_y", "grid_size_z",
                        "__local_group_id", "__warps_per_group"})   // the last two: virt CTA barrier args
    if (auto *gv = M->getGlobalVariable(n)) G.insert(gv);
  if (G.empty()) return;
  auto base = [&](llvm::Value *p) {
    auto *gv = llvm::dyn_cast<llvm::GlobalVariable>(p->stripPointerCasts());
    return gv && G.count(gv) ? gv : nullptr;
  };
  std::set<llvm::Function *> writers;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *S = llvm::dyn_cast<llvm::StoreInst>(&I))
          if (base(S->getPointerOperand())) writers.insert(&F);
  unsigned replaced = 0;
  for (auto &F : *M) {
    if (F.isDeclaration() || writers.count(&F)) continue;
    bool calls_writer = false;
    std::map<llvm::GlobalVariable *, std::vector<llvm::LoadInst *>> loads;
    for (auto &BB : F)
      for (auto &I : BB) {
        if (auto *C = llvm::dyn_cast<llvm::CallBase>(&I))
          if (C->getCalledFunction() && writers.count(C->getCalledFunction())) calls_writer = true;
        if (auto *L = llvm::dyn_cast<llvm::LoadInst>(&I))
          if (!L->isVolatile())
            if (auto *gv = base(L->getPointerOperand())) loads[gv].push_back(L);
      }
    if (calls_writer) continue;
    llvm::IRBuilder<> B(&*F.getEntryBlock().getFirstInsertionPt());
    for (auto &[gv, ls] : loads) {
      if (ls.size() < 2) continue;
      llvm::Type *T = ls.front()->getType();
      llvm::LoadInst *V = B.CreateLoad(T, gv, gv->getName() + ".entry");
      for (auto *L : ls)
        if (L->getType() == T) { L->replaceAllUsesWith(V); L->eraseFromParent(); ++replaced; }
    }
  }
  if (cupbop_debug() && replaced)
    std::cout << "[block-const] " << replaced << " loads of block/grid constants folded to one entry load per function\n";
}

// KMU launch (launch2): the CTA dispatcher loads the CUDA block index (and, on the 1:1 schedule, the thread index)
// into CTA CSRs; kernel_main only copies them into the legacy vx_spawn TLS. Reading the CSR is one instruction with
// no memory traffic, while each TLS load touches one 64 B line per lane (32 lines per warp) and is reloaded after
// every store alias analysis cannot separate from it. The asm is pure, so LLVM may CSE and hoist it.
// CUPBOP_SREG_TLS=1 keeps the TLS loads.
bool sreg_from_csr() {
  static const bool off = std::getenv("CUPBOP_SREG_TLS") != nullptr;
  return !off;
}
llvm::CallInst *read_cta_csr(llvm::IRBuilder<> &B, unsigned csr, const char *name) {
  auto *FT = llvm::FunctionType::get(B.getInt32Ty(), false);
  char asm_str[32];
  snprintf(asm_str, sizeof(asm_str), "csrr $0, 0x%x", csr);
  auto *IA = llvm::InlineAsm::get(FT, asm_str, "=r", /*hasSideEffects=*/false);
  llvm::CallInst *C = B.CreateCall(FT, IA, {}, name);
  C->setDoesNotAccessMemory();
  C->setDoesNotThrow();
  return C;
}

void replace_built_in_function(llvm::Module *M) {

  // Remove __vx_* stub function bodies (CUDA device stubs).
  // Real implementations are in cudaKernelImpl.o, linked later.
  {
    std::vector<Function *> vx_stubs;
    for (auto &F : *M) {
      if (F.getName().contains("__vx_") && !F.isDeclaration()) {
        vx_stubs.push_back(&F);
      }
    }
    for (auto *F : vx_stubs) {
      if (cupbop_debug())
        std::cout << "[DXA] Removing stub body: " << F->getName().str() << "\n";
      F->deleteBody();
      F->setLinkage(GlobalValue::ExternalLinkage);
    }
  }

  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
    schedule = std::stoi(std::string(env));
  }

  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);
  std::vector<llvm::Instruction *> need_remove;
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();

    DBG_PRINT("Function name: %s\n", func_name.c_str());
    DBG_PRINT("iskernel=%d\n", isKernelFunction(M, F));
    DBG_PRINT("isdevice=%d\n", isDeviceFunction(M, F));
    if (!(isKernelFunction(M, F) || isDeviceFunction(M, F)))
      continue;

    IRBuilder<> builder(&*(F->getEntryBlock().getFirstInsertionPt()));
    auto global_intra_warp_idx =
        F->getParent()->getGlobalVariable("intra_warp_index");
    auto local_intra_warp_idx =
        // LLVM 18
        // builder.CreateAlloca(global_intra_warp_idx->getType()->getElementType(),
        //                      0, "local_intra_warp_idx");
        builder.CreateAlloca(global_intra_warp_idx->getValueType(), 0,
                             "local_intra_warp_idx");
    global_intra_warp_idx->replaceUsesWithIf(local_intra_warp_idx, [&](Use &U) {
      auto *Instr = dyn_cast<Instruction>(U.getUser());
      return Instr->getParent()->getParent()->getName().str() == func_name;
    });

    // virt: the pass counter is per hardware thread too
    if (auto *global_slot = F->getParent()->getGlobalVariable("intra_warp_slot")) {
      auto local_slot = builder.CreateAlloca(global_slot->getValueType(), 0, "local_intra_warp_slot");
      builder.CreateStore(ConstantInt::get(I32, 0), local_slot);
      global_slot->replaceUsesWithIf(local_slot, [&](Use &U) {
        auto *Instr = dyn_cast<Instruction>(U.getUser());
        return Instr->getParent()->getParent()->getName().str() == func_name;
      });
    }

    auto global_inter_warp_idx =
        F->getParent()->getGlobalVariable("inter_warp_index");

    // LLVM 18
    auto local_inter_warp_idx = builder.CreateAlloca(
        global_inter_warp_idx->getValueType(), 0, "local_inter_warp_idx");
    // builder.CreateAlloca(global_inter_warp_idx->getType()->getElementType(),
    //                      0, "local_inter_warp_idx");

    builder.CreateStore(ConstantInt::get(I32, 0), local_inter_warp_idx);

    global_inter_warp_idx->replaceUsesWithIf(local_inter_warp_idx, [&](Use &U) {
      auto *Instr = dyn_cast<Instruction>(U.getUser());
      return Instr->getParent()->getParent()->getName().str() == func_name;
    });

    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Load = dyn_cast<LoadInst>(BI)) {
          auto load_from = Load->getOperand(0);
        } else if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->getCalledFunction()) {
            auto func_name = Call->getCalledOperand()->getName().str();
            // Mark: Temporarily commented out the _ZN25 function, we don't
            // think it's being used in vortex
            if (func_name == "llvm.nvvm.read.ptx.sreg.ntid.x" ||
                func_name == "llvm.nvvm.read.ptx.sreg.ntid.y" ||
                func_name == "llvm.nvvm.read.ptx.sreg.ntid.z") {
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              Value *val;
              if (schedule == 2) {
                // Load from vx_spawn's blockDim struct field
                int field = (func_name.back() == 'x')   ? 0
                            : (func_name.back() == 'y') ? 1
                                                        : 2;
                auto blockDimGV = M->getGlobalVariable("blockDim");
                auto field_ptr = builder.CreateStructGEP(
                    blockDimGV->getValueType(), blockDimGV, field);
                val = builder.CreateLoad(I32, field_ptr);
              } else {
                const char *name = (func_name.back() == 'x')   ? "block_size_x"
                                   : (func_name.back() == 'y') ? "block_size_y"
                                                               : "block_size_z";
                auto block_size_addr = M->getGlobalVariable(name);
                val = createLoad(builder, block_size_addr);
              }
              Call->replaceAllUsesWith(val);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.tid.x") {
              if (schedule == 2) {
                IRBuilder<> builder(context);
                builder.SetInsertPoint(Call);

                // Load from vx_spawn's threadIdx.x struct field
                auto threadIdxGV = M->getGlobalVariable("threadIdx");
                auto tls_ptr = builder.CreateCall(
                    Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address,
                                              {threadIdxGV->getType()}),
                    {threadIdxGV});
                auto field_ptr = builder.CreateStructGEP(
                    threadIdxGV->getValueType(), tls_ptr, 0);
                Instruction *tidx = sreg_from_csr()
                    ? (Instruction *)read_cta_csr(builder, 0xCD3, "tidx") // VX_CSR_CTA_THREAD_ID_X
                    : (Instruction *)builder.CreateLoad(I32, field_ptr, "tidx");

                MDNode *N =
                    MDNode::get(context, MDString::get(context, "divergence"));
                tidx->setMetadata("divergence", N);

                Call->replaceAllUsesWith(tidx);
                need_remove.push_back(Call);
              } else {
                auto block_size_x_tmp = M->getGlobalVariable("block_size_x");

                Constant *const_intra_warp_idx =
                    global_intra_warp_idx->getInitializer();
                Constant *const_inter_warp_idx =
                    global_inter_warp_idx->getInitializer();
                // Constant* const_block_size_x =
                // block_size_x_tmp->getInitializer();

                auto *con_intra_warp_idx =
                    dyn_cast<ConstantInt>(const_intra_warp_idx);
                auto *con_inter_warp_idx =
                    dyn_cast<ConstantInt>(const_inter_warp_idx);
                if (!con_intra_warp_idx || !con_inter_warp_idx) {
                  if (cupbop_debug())
                    printf("warning: warp idx globals not ConstantInt, "
                           "skipping\n");
                  continue;
                }
                // ConstantInt* con_block_size_x =
                // cast<ConstantInt>(const_block_size_x);

                int32_t int_intra_warp_idx =
                    con_intra_warp_idx->getSExtValue(); // changed to 32
                int32_t int_inter_warp_idx = con_inter_warp_idx->getSExtValue();
                // int64_t int_block_size_x = con_block_size_x->getSExtValue();

                DBG_PRINT("intra warp corresponding value is : %d \n",
                          int_intra_warp_idx);
                DBG_PRINT("inter warp corresponding value is : %d \n",
                          int_inter_warp_idx);
                // printf("block size x corresponding value is : %ld \n",
                // int_block_size_x);

                // Mark Debug: Until here (printing out warp_idx values)

                IRBuilder<> builder(context);
                builder.SetInsertPoint(Call);

                auto thread_idx = builder.CreateBinOp(
                    Instruction::Mul, createLoad(builder, local_inter_warp_idx),
                    ConstantInt::get(I32, 32),
                    ""); // Mark temp  (changed 32 -> 4)
                thread_idx = builder.CreateBinOp(
                    // Instruction::Add,
                    // builder.CreateLoad(local_intra_warp_idx),
                    Instruction::Add, createLoad(builder, local_intra_warp_idx),
                    thread_idx, "thread_idx");

                thread_idx = builder.CreateBinOp(
                    Instruction::SRem, thread_idx,
                    createLoad(builder, M->getGlobalVariable("block_size_x")),
                    "thread_id_x");

                // Add metadata to indicate non-uniformity
                // MDNode* N = MDNode::get(context, MDString::get(context,
                // "non-uniform"));
                // cast<Instruction>(thread_idx)->setMetadata("divergence", N);

                Call->replaceAllUsesWith(thread_idx);
                need_remove.push_back(Call);
              }
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.tid.y") {
              if (schedule == 2) {
                IRBuilder<> builder(context);
                builder.SetInsertPoint(Call);

                // Load from vx_spawn's threadIdx.y struct field
                auto threadIdxGV = M->getGlobalVariable("threadIdx");
                auto tls_ptr = builder.CreateCall(
                    Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address,
                                              {threadIdxGV->getType()}),
                    {threadIdxGV});
                auto field_ptr = builder.CreateStructGEP(
                    threadIdxGV->getValueType(), tls_ptr, 1);
                Instruction *tidy = sreg_from_csr()
                    ? (Instruction *)read_cta_csr(builder, 0xCD4, "tidy") // VX_CSR_CTA_THREAD_ID_Y
                    : (Instruction *)builder.CreateLoad(I32, field_ptr, "tidy");

                MDNode *N =
                    MDNode::get(context, MDString::get(context, "divergence"));
                tidy->setMetadata("divergence", N);

                Call->replaceAllUsesWith(tidy);
                need_remove.push_back(Call);
              } else {
                // replace it by warp_id
                IRBuilder<> builder(context);
                builder.SetInsertPoint(Call);

                auto thread_idx = builder.CreateBinOp(
                    Instruction::Mul, createLoad(builder, local_inter_warp_idx),
                    ConstantInt::get(I32, 32),
                    ""); // SW_WARP_SIZE = 32
                thread_idx = builder.CreateBinOp(
                    Instruction::Add, createLoad(builder, local_intra_warp_idx),
                    thread_idx, "thread_idx");
                // tidy = (flat_tid / block_size_x) % block_size_y
                thread_idx = builder.CreateBinOp(
                    Instruction::SDiv, thread_idx,
                    createLoad(builder, M->getGlobalVariable("block_size_x")),
                    "");
                thread_idx = builder.CreateBinOp(
                    Instruction::SRem, thread_idx,
                    createLoad(builder, M->getGlobalVariable("block_size_y")),
                    "thread_id_y");

                Call->replaceAllUsesWith(thread_idx);
                need_remove.push_back(Call);
              }
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.tid.z") {
              if (schedule == 2) {
                IRBuilder<> builder(context);
                builder.SetInsertPoint(Call);

                // Load from vx_spawn's threadIdx.z struct field
                auto threadIdxGV = M->getGlobalVariable("threadIdx");
                auto tls_ptr = builder.CreateCall(
                    Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address,
                                              {threadIdxGV->getType()}),
                    {threadIdxGV});
                auto field_ptr = builder.CreateStructGEP(
                    threadIdxGV->getValueType(), tls_ptr, 2);
                Instruction *tidz = sreg_from_csr()
                    ? (Instruction *)read_cta_csr(builder, 0xCD5, "tidz") // VX_CSR_CTA_THREAD_ID_Z
                    : (Instruction *)builder.CreateLoad(I32, field_ptr, "tidz");

                MDNode *N =
                    MDNode::get(context, MDString::get(context, "divergence"));
                tidz->setMetadata("divergence", N);
                Call->replaceAllUsesWith(tidz);
                need_remove.push_back(Call);
              } else {
                // tidz = flat_tid / (block_size_x * block_size_y)
                IRBuilder<> builder(context);
                builder.SetInsertPoint(Call);

                auto thread_idx = builder.CreateBinOp(
                    Instruction::Mul, createLoad(builder, local_inter_warp_idx),
                    ConstantInt::get(I32, 32),
                    ""); // SW_WARP_SIZE = 32
                thread_idx = builder.CreateBinOp(
                    Instruction::Add, createLoad(builder, local_intra_warp_idx),
                    thread_idx, "thread_idx");
                auto block_xy = builder.CreateBinOp(
                    Instruction::Mul,
                    createLoad(builder, M->getGlobalVariable("block_size_x")),
                    createLoad(builder, M->getGlobalVariable("block_size_y")),
                    "block_size_xy");
                thread_idx = builder.CreateBinOp(Instruction::SDiv, thread_idx,
                                                 block_xy, "thread_id_z");

                Call->replaceAllUsesWith(thread_idx);
                need_remove.push_back(Call);
              }
            }
            // Mark: Temporarily commented out the _ZN25 function, we don't
            // think it's being used in vortex

            else if (func_name == "llvm.nvvm.read.ptx.sreg.ctaid.x" ||
                     func_name == "llvm.nvvm.read.ptx.sreg.ctaid.y" ||
                     func_name == "llvm.nvvm.read.ptx.sreg.ctaid.z") {
              int field = (func_name.back() == 'x')   ? 0
                          : (func_name.back() == 'y') ? 1
                                                      : 2;
              if (cupbop_debug())
                printf("block_Id-%c is called\n", func_name.back());
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);

              Value *block_idx;
              if ((schedule == 1 || schedule == 2) && sreg_from_csr()) {
                block_idx = read_cta_csr(builder, 0xCD6 + field, "ctaid"); // VX_CSR_CTA_BLOCK_ID_{X,Y,Z}
              } else if (schedule == 2) {
                // Load from vx_spawn's blockIdx struct field
                auto blockIdxGV = M->getGlobalVariable("blockIdx");
                auto tls_ptr = builder.CreateCall(
                    Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address,
                                              {blockIdxGV->getType()}),
                    {blockIdxGV});
                auto field_ptr = builder.CreateStructGEP(
                    blockIdxGV->getValueType(), tls_ptr, field);
                block_idx = builder.CreateLoad(I32, field_ptr);
              } else {
                const char *name = (field == 0)   ? "block_index_x"
                                   : (field == 1) ? "block_index_y"
                                                  : "block_index_z";
                auto block_index_addr = M->getGlobalVariable(name);
                auto tls_ptr = builder.CreateCall(
                    Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address,
                                              {block_index_addr->getType()}),
                    {block_index_addr});
                block_idx = builder.CreateLoad(I32, tls_ptr);
              }

              Call->replaceAllUsesWith(block_idx);
              need_remove.push_back(Call);
            }
            // Mark: Temporarily commented out the _ZN25 function, we don't
            // think it's being used in vortex
            else if (func_name == "llvm.nvvm.read.ptx.sreg.nctaid.x" ||
                     func_name == "llvm.nvvm.read.ptx.sreg.nctaid.y" ||
                     func_name == "llvm.nvvm.read.ptx.sreg.nctaid.z") {
              int field = (func_name.back() == 'x')   ? 0
                          : (func_name.back() == 'y') ? 1
                                                      : 2;
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              Value *grid_size;
              if (schedule == 2) {
                // Load from vx_spawn's gridDim struct field
                auto gridDimGV = M->getGlobalVariable("gridDim");
                auto field_ptr = builder.CreateStructGEP(
                    gridDimGV->getValueType(), gridDimGV, field);
                grid_size = builder.CreateLoad(I32, field_ptr);
              } else {
                const char *name = (field == 0)   ? "grid_size_x"
                                   : (field == 1) ? "grid_size_y"
                                                  : "grid_size_z";
                auto grid_size_addr = M->getGlobalVariable(name);
                grid_size = createLoad(builder, grid_size_addr);
              }
              Call->replaceAllUsesWith(grid_size);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.warp.sz") {
              // warpSize = 32. Also propagate through alloca store→load chains
              // so loop trip count is visible to LoopUnroll.
              auto *C32 = ConstantInt::get(Type::getInt32Ty(context), 32);
              for (auto *U : Call->users()) {
                if (auto *SI = dyn_cast<StoreInst>(U)) {
                  auto *Ptr = SI->getPointerOperand();
                  for (auto *PU : Ptr->users()) {
                    if (auto *LI = dyn_cast<LoadInst>(PU)) {
                      LI->replaceAllUsesWith(C32);
                      need_remove.push_back(LI);
                    }
                  }
                }
              }
              Call->replaceAllUsesWith(C32);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.cluster.ctarank" ||
                       func_name == "llvm.nvvm.read.ptx.sreg.cluster.nctarank") {
              // no thread-block clusters on Vortex: rank 0 of a cluster of 1
              bool isN = func_name.find("nctarank") != std::string::npos;
              Call->replaceAllUsesWith(ConstantInt::get(I32, isN ? 1 : 0));
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.laneid") {
              // CuLifter-lifted kernels read the lane id through this intrinsic
              // (clang CUDA emits the `mov.u32 $0, %laneid;` asm, handled in
              // replace_asm_call). Left alone it reaches the RISC-V backend and
              // crashes ISel. 1:1 schedule: the hardware lane (vx_thread_id via
              // __cupbop_laneid), consistent with the shuffle/vote wrappers and
              // the mma.sync helpers. Flat schedule: the warp-loop index, as for
              // the asm form.
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              Value *lane;
              if (schedule == 2) { // 1:1: lanes are hardware
                FunctionCallee fc = M->getOrInsertFunction(
                    "__cupbop_laneid", FunctionType::get(I32, {}, false));
                CallInst *c = builder.CreateCall(fc, {}, "laneid");
                MDNode *N =
                    MDNode::get(context, MDString::get(context, "divergence"));
                c->setMetadata("divergence", N);
                lane = c;
              } else if (schedule == 1) { // virt: the CUDA lane of the logical thread (NT may differ from 32)
                lane = builder.CreateAnd(createLoad(builder, local_intra_warp_idx), ConstantInt::get(I32, 31), "laneid");
              } else {
                lane = createLoad(builder,
                                  M->getGlobalVariable("intra_warp_index"));
              }
              Call->replaceAllUsesWith(lane);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.barrier0") {
              if (schedule == 2) {
                IRBuilder<> builder(context);
                builder.SetInsertPoint(Call);

                auto localGroupIdGV = (llvm::GlobalVariable *)M->getNamedGlobal(
                    "__local_group_id");
                auto warpsPerGroupGV =
                    (llvm::GlobalVariable *)M->getNamedGlobal(
                        "__warps_per_group");

                FunctionCallee threadIdxFunc = M->getOrInsertFunction(
                    "vx_barrier", FunctionType::get(Type::getVoidTy(context),
                                                    {Type::getInt32Ty(context),
                                                     Type::getInt32Ty(context)},
                                                    false));

                Value *localGroupId, *warpsPerGroup;
                if (sreg_from_csr()) {
                  localGroupId = read_cta_csr(builder, 0xCD0, "cta_id");     // VX_CSR_CTA_ID
                  warpsPerGroup = read_cta_csr(builder, 0xCD2, "cta_warps"); // VX_CSR_CTA_SIZE
                } else {
                  localGroupId = builder.CreateLoad(localGroupIdGV->getValueType(), localGroupIdGV);
                  warpsPerGroup = builder.CreateLoad(warpsPerGroupGV->getValueType(), warpsPerGroupGV);
                }

                CallInst *syncThreads = builder.CreateCall(
                    threadIdxFunc, {localGroupId, warpsPerGroup});
                // convergent like the llvm.nvvm.barrier0 it replaces: without it LLVM may copy the barrier into
                // lane-dependent branches (a warp then arrives once per branch and the CTA deadlocks); the TLS
                // loads that used to feed it happened to keep it in place, the pure CSR reads do not
                syncThreads->addFnAttr(Attribute::Convergent);
                cast<Function>(threadIdxFunc.getCallee())->addFnAttr(Attribute::Convergent);

                MDNode *N =
                    MDNode::get(context, MDString::get(context, "divergence"));
                syncThreads->setMetadata("divergence", N);

                Call->replaceAllUsesWith(syncThreads);
                need_remove.push_back(Call);
              }
            } else if (isWarpSync(func_name)) {
              // Warp barrier is unnecessary in vortex
              // Removing barriers including warp barrier is usually done at
              // insert_warp_loop stage Since schedule 2 skips this stage, we
              // remove warp barriers here
              if (schedule == 2) {
                need_remove.push_back(Call);
              }
            }
          }
          if (Call->isInlineAsm()) {
            auto asm_inst = dyn_cast<InlineAsm>(Call->getCalledOperand());
            if (!asm_inst)
              continue;
            if (asm_inst->getAsmString() != "mov.u32 $0, %laneid;") {
              if (cupbop_debug())
                printf("Warning: unhandled InlineAsm: %s\n",
                       asm_inst->getAsmString().c_str());
              continue;
            }
            // return the rank within the warp
            IRBuilder<> builder(context);
            builder.SetInsertPoint(Call);
            Value *intra_warp_index;
            if (schedule == 2) { // 1:1: hardware lane
              FunctionCallee fc = M->getOrInsertFunction(
                  "__cupbop_laneid", FunctionType::get(I32, {}, false));
              CallInst *c = builder.CreateCall(fc, {}, "laneid");
              c->setMetadata("divergence", MDNode::get(context, MDString::get(context, "divergence")));
              intra_warp_index = c;
            } else if (schedule == 1) { // virt: CUDA lane of the logical thread
              intra_warp_index = builder.CreateAnd(createLoad(builder, local_intra_warp_idx), ConstantInt::get(I32, 31), "laneid");
            } else {
              intra_warp_index = createLoad(builder, local_intra_warp_idx);
            }
            Call->replaceAllUsesWith(intra_warp_index);
            need_remove.push_back(Call);
          }
        }
      }
    }
  }
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->getCalledFunction()) {
            auto func_name = Call->getCalledOperand()->getName().str();
            auto callFn = Call->getCalledFunction();
            if (func_name == "vprintf") {

              llvm::FunctionType *printfType = FunctionType::get(
                  I32, {PointerType::getUnqual(context)}, true);
              llvm::FunctionCallee _f =
                  M->getOrInsertFunction("vx_printf", printfType);
              llvm::Function *func_printf =
                  llvm::cast<llvm::Function>(_f.getCallee());
              std::vector<Value *> printf_args;

              // Skip the first argument (format string)
              bool isFirstArg = true;
              for (auto &Arg : Call->args()) {
                if (isFirstArg) {
                  printf_args.push_back(Arg);
                  isFirstArg = false;
                  continue;
                }

                // If it's not a pointer type, keep it as is
                if (!Arg->getType()->isPointerTy()) {
                  printf_args.push_back(Arg);
                  continue;
                }

                // For pointers, try to determine element type and create a load
                Type *ElemTy = getOpaquePointerElementType(Arg);

                if (ElemTy) {
                  auto new_load = new LoadInst(ElemTy, Arg, "", Call);
                  printf_args.push_back(new_load);
                } else {
                  // Cannot determine element type, keep it as is
                  printf_args.push_back(Arg);
                  dbgs() << "Warning: Couldn't determine element type for "
                            "pointer argument\n";
                }
              }

              auto c_printf_inst =
                  llvm::CallInst::Create(func_printf, printf_args, "", Call);
              // insert
              Call->replaceAllUsesWith(c_printf_inst);
              need_remove.push_back(Call);
            } else if (func_name == "__nv_fast_log2f" ||
                       func_name == "__nv_log2f" ||
                       func_name == "__nv_fast_powf" ||
                       func_name == "__nv_powf" || func_name == "__nv_logf" ||
                       func_name == "__nv_expf" || func_name == "__nv_fabsf" ||
                       func_name == "__nv_log10f" ||
                       func_name == "__nv_fmodf" || func_name == "__nv_sqrt" ||
                       func_name == "__nv_rsqrtf" ||
                       func_name == "__nv_sqrtf" || func_name == "__nv_exp" ||
                       func_name == "__nv_isnanf" ||
                       func_name == "__nv_isinff" || func_name == "__nv_powi" ||
                       func_name == "__nv_powif" || func_name == "__nv_erfcf" ||
                       func_name == "__nv_ffs" || func_name == "__nv_popc") {
              Call->getCalledFunction()->deleteBody();
            } else if (func_name == "llvm.nvvm.fma.rn.d") {
              Call->getCalledFunction()->setName("__nvvm_fma_rn_d");
            } else if (func_name == "llvm.nvvm.d2i.lo") {
              Call->getCalledFunction()->setName("__nvvm_d2i_lo");
            } else if (func_name == "llvm.nvvm.d2i.hi") {
              Call->getCalledFunction()->setName("__nvvm_d2i_hi");
            } else if (func_name == "llvm.nvvm.add.rn.d") {
              Call->getCalledFunction()->setName("__nvvm_add_rn_d");
            } else if (func_name == "llvm.nvvm.lohi.i2d") {
              Call->getCalledFunction()->setName("__nvvm_lohi_i2d");
            } else if (func_name == "llvm.nvvm.fabs.f" ||
                       func_name == "llvm.nvvm.fmin.ftz.f" ||
                       func_name == "llvm.nvvm.fmin.f" ||
                       func_name == "llvm.nvvm.fmax.ftz.f" ||
                       func_name == "llvm.nvvm.fmax.f") {
              // Handled in NVVM intrinsic replacement pass below
            } else if (func_name == "llvm.nvvm.mul24.i") {
              Call->getCalledFunction()->setName("__nvvm_mul24_i");
            } else if (func_name == "llvm.nvvm.membar.gl" ||
                       func_name == "llvm.nvvm.membar.cta" ||
                       func_name == "llvm.nvvm.membar.sys") {
              // Vortex has a single fence scope (a whole-cache flush on the RTL); membar.cta next to a
              // barrier was already dropped by drop_cta_membar_at_barriers.
              Call->getCalledFunction()->setName("__nvvm_membar_gl");
            } else if (func_name.find("llvm.nvvm.atomic.load.inc.32") !=
                       std::string::npos) {
              Call->getCalledFunction()->setName("__nvvm_atomic_load_inc_32");
            } else if (func_name == "llvm.nvvm.div.approx.ftz.f") {
              Call->getCalledFunction()->setName("__nvvm_div_approx_ftz_f");
            } else if (func_name == "llvm.nvvm.div.approx.f") {
              Call->getCalledFunction()->setName("__nvvm_div_approx_f");
            }
          }
        }
      }
    }
  }

  for (auto inst : need_remove) {
    inst->eraseFromParent();
  }

  // Replace NVVM float intrinsics with standard LLVM IR operations.
  // These intrinsics are not supported by the RISC-V backend and would
  // cause "Don't know how to custom type legalize this intrinsic!" errors.
  {
    std::vector<CallInst *> to_replace;
    for (auto &F : *M) {
      for (auto &BB : F) {
        for (auto &Inst : BB) {
          if (auto *Call = dyn_cast<CallInst>(&Inst)) {
            if (!Call->getCalledFunction())
              continue;
            auto name = Call->getCalledFunction()->getName().str();
            if (name.find("llvm.nvvm.fma.") != std::string::npos ||
                name.find("llvm.nvvm.mul.r") != std::string::npos ||
                name.find("llvm.nvvm.add.r") != std::string::npos ||
                name.find("llvm.nvvm.fabs.") != std::string::npos ||
                name.find("llvm.nvvm.f2i.r") != std::string::npos ||
                name.find("llvm.nvvm.f2ui.r") != std::string::npos ||
                name.find("llvm.nvvm.i2f.r") != std::string::npos ||
                name.find("llvm.nvvm.ui2f.r") != std::string::npos ||
                name.find("llvm.nvvm.d2f.r") != std::string::npos ||
                name.find("llvm.nvvm.f2ll.r") != std::string::npos ||
                name.find("llvm.nvvm.f2ull.r") != std::string::npos ||
                name.find("llvm.nvvm.ll2f.r") != std::string::npos ||
                name.find("llvm.nvvm.ull2f.r") != std::string::npos ||
                name.find("llvm.nvvm.d2i.r") != std::string::npos ||
                name.find("llvm.nvvm.d2ui.r") != std::string::npos ||
                name.find("llvm.nvvm.i2d.r") != std::string::npos ||
                name.find("llvm.nvvm.ui2d.r") != std::string::npos ||
                name.find("llvm.nvvm.d2ll.r") != std::string::npos ||
                name.find("llvm.nvvm.d2ull.r") != std::string::npos ||
                name.find("llvm.nvvm.ll2d.r") != std::string::npos ||
                name.find("llvm.nvvm.ull2d.r") != std::string::npos ||
                name.find("llvm.nvvm.sqrt.") != std::string::npos ||
                name.find("llvm.nvvm.rsqrt.") != std::string::npos ||
                name.find("llvm.nvvm.rcp.") != std::string::npos ||
                name.find("llvm.nvvm.sin.") != std::string::npos ||
                name.find("llvm.nvvm.cos.") != std::string::npos ||
                name.find("llvm.nvvm.ex2.approx.f") != std::string::npos ||
                name.find("llvm.nvvm.lg2.approx.f") != std::string::npos ||
                name.find("llvm.nvvm.div.r") != std::string::npos ||
                name.find("llvm.nvvm.fmin.") != std::string::npos ||
                name.find("llvm.nvvm.fmax.") != std::string::npos ||
                name.find("llvm.nvvm.saturate") != std::string::npos) {
              to_replace.push_back(Call);
            }
          }
        }
      }
    }

    auto I32 = llvm::Type::getInt32Ty(M->getContext());
    auto I64 = llvm::Type::getInt64Ty(M->getContext());
    auto F32 = llvm::Type::getFloatTy(M->getContext());
    auto F64 = llvm::Type::getDoubleTy(M->getContext());

    for (auto *Call : to_replace) {
      auto name = Call->getCalledFunction()->getName().str();
      IRBuilder<> Builder(Call);

      Value *replacement = nullptr;

      // FMA: fma(a,b,c) = a*b+c
      if (name.find("llvm.nvvm.fma.") != std::string::npos) {
        Value *a = Call->getArgOperand(0);
        Value *b = Call->getArgOperand(1);
        Value *c = Call->getArgOperand(2);
        auto *fma_func =
            Intrinsic::getDeclaration(M, Intrinsic::fma, {a->getType()});
        replacement = Builder.CreateCall(fma_func, {a, b, c});

        // Multiply: a*b
      } else if (name.find("llvm.nvvm.mul.r") != std::string::npos) {
        replacement =
            Builder.CreateFMul(Call->getArgOperand(0), Call->getArgOperand(1));

        // Add: a+b
      } else if (name.find("llvm.nvvm.add.r") != std::string::npos) {
        replacement =
            Builder.CreateFAdd(Call->getArgOperand(0), Call->getArgOperand(1));

        // Division: a/b
      } else if (name.find("llvm.nvvm.div.r") != std::string::npos) {
        replacement =
            Builder.CreateFDiv(Call->getArgOperand(0), Call->getArgOperand(1));

        // Absolute value
      } else if (name.find("llvm.nvvm.fabs.") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::fabs, {x->getType()}), {x});

        // Min/Max
      } else if (name.find("llvm.nvvm.fmin.") != std::string::npos) {
        Value *a = Call->getArgOperand(0);
        Value *b = Call->getArgOperand(1);
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::minnum, {a->getType()}),
            {a, b});
      } else if (name.find("llvm.nvvm.fmax.") != std::string::npos) {
        Value *a = Call->getArgOperand(0);
        Value *b = Call->getArgOperand(1);
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::maxnum, {a->getType()}),
            {a, b});

        // Square root
      } else if (name.find("llvm.nvvm.sqrt.") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::sqrt, {x->getType()}), {x});

        // Reciprocal square root: 1/sqrt(x)
      } else if (name.find("llvm.nvvm.rsqrt.") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        Value *sq = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::sqrt, {x->getType()}), {x});
        replacement =
            Builder.CreateFDiv(ConstantFP::get(x->getType(), 1.0), sq);

        // Reciprocal: 1/x
      } else if (name.find("llvm.nvvm.rcp.") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateFDiv(ConstantFP::get(x->getType(), 1.0), x);

        // sin/cos
      } else if (name.find("llvm.nvvm.sin.") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::sin, {x->getType()}), {x});
      } else if (name.find("llvm.nvvm.cos.") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::cos, {x->getType()}), {x});

        // exp2 / log2
      } else if (name.find("llvm.nvvm.ex2.approx.f") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::exp2, {x->getType()}), {x});
      } else if (name.find("llvm.nvvm.lg2.approx.f") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::log2, {x->getType()}), {x});

        // Saturate: clamp to [0, 1]
      } else if (name.find("llvm.nvvm.saturate") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        Value *zero = ConstantFP::get(x->getType(), 0.0);
        Value *one = ConstantFP::get(x->getType(), 1.0);
        Value *clamped_lo = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::maxnum, {x->getType()}),
            {x, zero});
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::minnum, {x->getType()}),
            {clamped_lo, one});

        // Float-to-signed-int
      } else if (name.find("llvm.nvvm.f2i.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(
                                     M, Intrinsic::roundeven, {x->getType()}),
                                 {x});
        } else if (name.find(".rm") != std::string::npos) {
          x = Builder.CreateCall(
              Intrinsic::getDeclaration(M, Intrinsic::floor, {x->getType()}),
              {x});
        } else if (name.find(".rp") != std::string::npos) {
          x = Builder.CreateCall(
              Intrinsic::getDeclaration(M, Intrinsic::ceil, {x->getType()}),
              {x});
        }
        replacement = Builder.CreateFPToSI(x, I32);

        // Float-to-unsigned-int
      } else if (name.find("llvm.nvvm.f2ui.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(
                                     M, Intrinsic::roundeven, {x->getType()}),
                                 {x});
        } else if (name.find(".rm") != std::string::npos) {
          x = Builder.CreateCall(
              Intrinsic::getDeclaration(M, Intrinsic::floor, {x->getType()}),
              {x});
        } else if (name.find(".rp") != std::string::npos) {
          x = Builder.CreateCall(
              Intrinsic::getDeclaration(M, Intrinsic::ceil, {x->getType()}),
              {x});
        }
        replacement = Builder.CreateFPToUI(x, I32);

        // Float-to-long-long
      } else if (name.find("llvm.nvvm.f2ll.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(
                                     M, Intrinsic::roundeven, {x->getType()}),
                                 {x});
        }
        replacement = Builder.CreateFPToSI(x, I64);
      } else if (name.find("llvm.nvvm.f2ull.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(
                                     M, Intrinsic::roundeven, {x->getType()}),
                                 {x});
        }
        replacement = Builder.CreateFPToUI(x, I64);

        // Double-to-int conversions
      } else if (name.find("llvm.nvvm.d2i.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(
                                     M, Intrinsic::roundeven, {x->getType()}),
                                 {x});
        } else if (name.find(".rm") != std::string::npos) {
          x = Builder.CreateCall(
              Intrinsic::getDeclaration(M, Intrinsic::floor, {x->getType()}),
              {x});
        } else if (name.find(".rp") != std::string::npos) {
          x = Builder.CreateCall(
              Intrinsic::getDeclaration(M, Intrinsic::ceil, {x->getType()}),
              {x});
        }
        replacement = Builder.CreateFPToSI(x, I32);
      } else if (name.find("llvm.nvvm.d2ui.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateFPToUI(x, I32);
      } else if (name.find("llvm.nvvm.d2ll.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateFPToSI(x, I64);
      } else if (name.find("llvm.nvvm.d2ull.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        replacement = Builder.CreateFPToUI(x, I64);

        // Int-to-float conversions
      } else if (name.find("llvm.nvvm.i2f.r") != std::string::npos) {
        replacement = Builder.CreateSIToFP(Call->getArgOperand(0), F32);
      } else if (name.find("llvm.nvvm.ui2f.r") != std::string::npos) {
        replacement = Builder.CreateUIToFP(Call->getArgOperand(0), F32);
      } else if (name.find("llvm.nvvm.ll2f.r") != std::string::npos) {
        replacement = Builder.CreateSIToFP(Call->getArgOperand(0), F32);
      } else if (name.find("llvm.nvvm.ull2f.r") != std::string::npos) {
        replacement = Builder.CreateUIToFP(Call->getArgOperand(0), F32);
      } else if (name.find("llvm.nvvm.i2d.r") != std::string::npos) {
        replacement = Builder.CreateSIToFP(Call->getArgOperand(0), F64);
      } else if (name.find("llvm.nvvm.ui2d.r") != std::string::npos) {
        replacement = Builder.CreateUIToFP(Call->getArgOperand(0), F64);
      } else if (name.find("llvm.nvvm.ll2d.r") != std::string::npos) {
        replacement = Builder.CreateSIToFP(Call->getArgOperand(0), F64);
      } else if (name.find("llvm.nvvm.ull2d.r") != std::string::npos) {
        replacement = Builder.CreateUIToFP(Call->getArgOperand(0), F64);

        // Double-to-float truncation
      } else if (name.find("llvm.nvvm.d2f.r") != std::string::npos) {
        replacement = Builder.CreateFPTrunc(Call->getArgOperand(0), F32);
      }

      if (replacement) {
        Call->replaceAllUsesWith(replacement);
        Call->eraseFromParent();
      }
    }
  }
}

// =============================================================================
// Tensor-core data types (mma.sync / wmma): shared classification and lowering-mode selection
// =============================================================================
// One mma.sync form m16n8kK.row.col (NVVM intrinsic llvm.nvvm.mma.*, CuLifter output; or the
// cupbop.mma.* pseudo-intrinsic that replace_asm_call makes from inline-asm mma.sync) maps to the
// runtime helper __cupbop_mma_<geom>_<tag>[_sw|_tcu] (cudaKernelImpl.cpp, cudaKernelImpl_dtypes.inc):
//   f16/bf16 -> f32  m16n8k16 (A 4 regs, B 2) / m16n8k8 (A 2, B 1)     tag f16f32 / bf16f32
//   tf32 -> f32      m16n8k8 (4/2) / m16n8k4 (2/1)                     tag tf32f32
//   s8/u8 -> s32     m16n8k32 (4/2) / m16n8k16 (2/1), [.satfinite]      tag s8s32, u8s32, s8u8s32, u8s8s32 [+sat]
//   e4m3/e5m2 -> f32 m16n8k32 (4/2)                                     tag e4m3f32, e5m2f32, e4m3e5m2f32, e5m2e4m3f32
// Everything else (f16 accumulators, m8n8k4, m8n8k16/m16n8k64 int4, b1, f64, sparse) is refused.
namespace {
struct TensorForm {
  std::string geom, ta, tb; // geometry, A/B element types
  bool sat = false, intAcc = false, full = false;
  int nA = 0, nB = 0;
  std::string tag;          // runtime tag
};
} // namespace

static bool tensor_is_f16ish(const std::string &t) { return t == "f16" || t == "bf16"; }
static bool tensor_is_int8(const std::string &t) { return t == "s8" || t == "u8"; }
static bool tensor_is_fp8(const std::string &t) { return t == "e4m3" || t == "e5m2"; }

// acc: "f32" or "s32"
static bool classify_mma_form(const std::string &geom, const std::string &ta, const std::string &tb, bool sat,
                              const std::string &acc, TensorForm &S, std::string &err) {
  S = TensorForm(); S.geom = geom; S.ta = ta; S.tb = tb; S.sat = sat;
  auto shapes = [&](const char *fullG, const char *halfG) {
    if (geom == fullG) { S.full = true; S.nA = 4; S.nB = 2; return true; }
    if (halfG && geom == halfG) { S.full = false; S.nA = 2; S.nB = 1; return true; }
    err = "shape " + geom + " not supported for " + ta + " (supported: " + fullG + (halfG ? std::string(", ") + halfG : std::string("")) + ")";
    return false;
  };
  if (tensor_is_f16ish(ta) || ta == "tf32") {
    if (tb != ta) { err = "mixed A/B types " + ta + "/" + tb; return false; }
    if (acc != "f32") { err = ta + " with " + acc + " accumulator (only f32 accumulators are lowered)"; return false; }
    if (sat) { err = ".satfinite with " + ta; return false; }
    if (!(ta == "tf32" ? shapes("m16n8k8", "m16n8k4") : shapes("m16n8k16", "m16n8k8"))) return false;
    S.tag = ta + "f32";
    return true;
  }
  if (tensor_is_int8(ta)) {
    if (!tensor_is_int8(tb)) { err = "A " + ta + " with B " + tb; return false; }
    if (acc != "s32") { err = "int8 with " + acc + " accumulator"; return false; }
    if (!shapes("m16n8k32", "m16n8k16")) return false;
    S.intAcc = true;
    S.tag = ta + (tb != ta ? tb : std::string("")) + "s32" + (sat ? "sat" : "");
    return true;
  }
  if (tensor_is_fp8(ta)) {
    if (!tensor_is_fp8(tb)) { err = "A " + ta + " with B " + tb; return false; }
    if (acc != "f32") { err = "fp8 with " + acc + " accumulator (only f32 accumulators are lowered)"; return false; }
    if (sat) { err = ".satfinite with fp8"; return false; }
    if (!shapes("m16n8k32", nullptr)) return false;
    S.tag = ta + (tb != ta ? tb : std::string("")) + "f32";
    return true;
  }
  err = "element type " + ta + " not supported (f16, bf16, tf32, s8, u8, e4m3, e5m2)";
  return false;
}

// VORTEX_CONFIGS (exported by examples/common.mk callers: ci/rg-ci-setup-v3.sh, the coadapt harness) holds the
// -DVX_CFG_* flags of the SimX build the kernel is compiled for. Unset: unknown build (the link then decides).
static bool tensor_cfg_known() { return std::getenv("VORTEX_CONFIGS") != nullptr; }
static bool tensor_cfg_has(const char *flag) {
  const char *e = std::getenv("VORTEX_CONFIGS");
  if (!e) return true;
  std::string s(e), f(flag);
  for (size_t p = s.find(f); p != std::string::npos; p = s.find(f, p + 1)) {
    size_t q = p + f.size();
    if (q == s.size() || s[q] == ' ' || s[q] == '=' || s[q] == '\t') return true;
  }
  return false;
}
// Vortex config flag that gates element type t on the TCU (RTL: VX_tcu_pkg / tfr_mul_join; SimX implements
// every dense type once VX_CFG_EXT_TCU_ENABLE is on, but a build for a type the RTL leaves out is not real).
static const char *tensor_type_flag(const std::string &t) {
  if (tensor_is_f16ish(t)) return nullptr;            // VX_CFG_TCU_FP16_ENABLE, on by default (VX_config.toml)
  if (t == "tf32") return "-DVX_CFG_TCU_TF32_ENABLE";
  if (tensor_is_int8(t)) return "-DVX_CFG_TCU_INT8_ENABLE";
  if (tensor_is_fp8(t)) return "-DVX_CFG_TCU_FP8_ENABLE";
  return "?";
}
static bool tensor_build_enables(const std::string &t, std::string &why) {
  if (!tensor_cfg_has("-DVX_CFG_EXT_TCU_ENABLE")) { why = "VORTEX_CONFIGS has no -DVX_CFG_EXT_TCU_ENABLE"; return false; }
  if (tensor_is_f16ish(t)) {
    if (tensor_cfg_known() && tensor_cfg_has("-DVX_CFG_TCU_FP16_DISABLE")) { why = "VORTEX_CONFIGS has -DVX_CFG_TCU_FP16_DISABLE"; return false; }
    return true;
  }
  const char *f = tensor_type_flag(t);
  if (!tensor_cfg_has(f)) { why = std::string("VORTEX_CONFIGS has no ") + f; return false; }
  return true;
}
static std::string tensor_lowering_mode() {
  const char *env = std::getenv("CUPBOP_MMA_LOWERING");
  std::string mode = env ? env : "auto";
  if (mode.empty()) mode = "auto";
  if (mode != "auto" && mode != "sw" && mode != "tcu") {
    fprintf(stderr, "warning: CUPBOP_MMA_LOWERING=%s unknown (auto|sw|tcu); using auto\n", mode.c_str());
    mode = "auto";
  }
  return mode;
}
// CUPBOP_MMA_SATFINITE=wrap: run .satfinite int8 forms on the TCU with a wrapping int32 sum (differs from NVIDIA
// only when the exact sum leaves the int32 range). Default: .satfinite is software only.
static bool tensor_satfinite_wrap() {
  const char *e = std::getenv("CUPBOP_MMA_SATFINITE");
  return e && std::string(e) == "wrap";
}
// Pick the runtime symbol for an operation on element types (ta, tb). base: dispatch symbol of the exact
// operation; base_nosat: the same operation without .satfinite (== base when !sat). Exits on refusal.
static std::string tensor_pick_symbol(const std::string &what, const std::string &base, const std::string &base_nosat,
                                      const std::string &ta, const std::string &tb, bool sat) {
  const std::string mode = tensor_lowering_mode();
  std::string reason; // why the TCU cannot run it exactly
  if (ta != tb) reason = "the Vortex TCU has one input format per op (A " + ta + ", B " + tb + ")";
  else if (sat && !tensor_satfinite_wrap()) reason = ".satfinite clamps the exact sum, the Vortex TCU int32 accumulator wraps (CUPBOP_MMA_SATFINITE=wrap accepts that)";
  const std::string tcu_base = (sat && tensor_satfinite_wrap() && ta == tb) ? base_nosat : base;
  if (mode == "sw") return base + "_sw";
  if (mode == "tcu") {
    if (!reason.empty()) {
      fprintf(stderr, "error: %s: CUPBOP_MMA_LOWERING=tcu cannot lower it: %s; use sw or auto\n", what.c_str(), reason.c_str());
      exit(1);
    }
    std::string why;
    if (!tensor_build_enables(ta, why)) {
      fprintf(stderr, "error: %s: CUPBOP_MMA_LOWERING=tcu needs a TCU build that enables %s (%s); use sw or auto\n",
              what.c_str(), ta.c_str(), why.c_str());
      exit(1);
    }
    return tcu_base + "_tcu";
  }
  if (!reason.empty()) { // auto
    static std::set<std::string> told;
    if (told.insert(what).second)
      fprintf(stderr, "[mma] %s: auto -> software (%s)\n", what.c_str(), reason.c_str());
    return base + "_sw";
  }
  return tcu_base; // dispatch symbol: the runtime picks _tcu only when the kernel's build enables the type
}

// Mark a call (and its callee declaration) convergent: the helpers exchange values across the warp.
static void tensor_set_convergent(CallInst *C) {
  C->addFnAttr(Attribute::Convergent);
  if (Function *F = C->getCalledFunction()) F->addFnAttr(Attribute::Convergent);
}

// ---- inline-asm mma.sync (CUDA source kernels: CUTLASS-style asm, the only way to reach fp8 mma) ---------
// "mma.sync.aligned.<geom>.row.col[.satfinite].<d>.<a>.<b>.<c> {D}, {A}, {B}, {C};" (one or more statements)
// becomes calls to the pseudo-intrinsic cupbop.mma.<geom>.row.col[.satfinite].<sig> (NVVM naming: sig .f32.f32
// for f16, else .<a>[.<b>]), which the NT=16 staging and replace_nvvm_mma_intrinsics treat like llvm.nvvm.mma.*.
// Returns false (asm left to the older handlers) when the string is not made of mma.sync statements or the
// fragments come from ldmatrix asm (Triton path). Recognized but unsupported forms are a hard error.
static std::string tensor_trim(const std::string &s) {
  size_t a = s.find_first_not_of(" \t\n\r"), b = s.find_last_not_of(" \t\n\r");
  return a == std::string::npos ? std::string() : s.substr(a, b - a + 1);
}
static bool lower_inline_mma_sync(CallInst *Call, Module *M) {
  auto *IA = dyn_cast<InlineAsm>(Call->getCalledOperand());
  if (!IA) return false;
  const std::string asmStr = IA->getAsmString();
  if (asmStr.find("mma.sync.aligned") == std::string::npos) return false;
  std::vector<std::string> stmts;
  {
    size_t p = 0;
    while (p < asmStr.size()) {
      size_t q = asmStr.find(';', p);
      std::string st = tensor_trim(asmStr.substr(p, q == std::string::npos ? std::string::npos : q - p));
      if (!st.empty()) stmts.push_back(st);
      if (q == std::string::npos) break;
      p = q + 1;
    }
  }
  if (stmts.empty()) return false;
  for (auto &st : stmts)
    if (st.rfind("mma.sync.aligned.", 0) != 0) return false; // braces, .reg, other instructions: not ours
  // operand numbering: non-clobber constraints in order (outputs first)
  InlineAsm::ConstraintInfoVector CV = IA->ParseConstraints();
  struct Opnd { bool out; int pos; std::string code; };
  std::vector<Opnd> ops;
  int nOut = 0, nIn = 0;
  for (auto &CI : CV) {
    if (CI.Type == InlineAsm::isClobber) continue;
    if (CI.isIndirect) return false;
    Opnd o; o.out = CI.Type == InlineAsm::isOutput; o.pos = o.out ? nOut++ : nIn++; o.code = CI.Codes.empty() ? "" : CI.Codes[0];
    ops.push_back(o);
  }
  if ((int)Call->arg_size() != nIn) return false;
  LLVMContext &Ctx = M->getContext();
  Type *I32 = Type::getInt32Ty(Ctx), *F32 = Type::getFloatTy(Ctx);
  auto outType = [&](int pos) -> Type * {
    Type *RT = Call->getType();
    if (auto *ST = dyn_cast<StructType>(RT)) return ST->getElementType(pos);
    return RT;
  };
  std::vector<Value *> cur(nOut, nullptr);
  IRBuilder<> B(Call);
  auto as32 = [&](Value *V, Type *T) -> Value * {
    if (V->getType() == T) return V;
    if (V->getType()->getPrimitiveSizeInBits() == 32) return B.CreateBitCast(V, T);
    return nullptr;
  };
  auto fromLdmatrix = [](Value *V) {
    if (auto *EV = dyn_cast<ExtractValueInst>(V)) V = EV->getAggregateOperand();
    if (auto *C = dyn_cast<CallInst>(V))
      if (C->isInlineAsm())
        if (auto *X = dyn_cast<InlineAsm>(C->getCalledOperand()))
          return X->getAsmString().find("ldmatrix") != std::string::npos;
    return false;
  };
  // value of template operand n read as an input
  auto readOp = [&](int n) -> Value * {
    if (n < 0 || n >= (int)ops.size()) return nullptr;
    if (!ops[n].out) return Call->getArgOperand(ops[n].pos);
    if (cur[ops[n].pos]) return cur[ops[n].pos];
    for (auto &o : ops) // tied input ("0", "1", ...)
      if (!o.out && o.code == std::to_string(n)) return Call->getArgOperand(o.pos);
    return nullptr;
  };
  struct Plan { TensorForm S; std::string sig; std::vector<int> D, A, Bv, C; };
  std::vector<Plan> plans;
  for (auto &st : stmts) {
    size_t sp = st.find_first_of(" \t\n");
    if (sp == std::string::npos) return false;
    std::string opc = st.substr(0, sp), rest = st.substr(sp);
    std::vector<std::string> tk;
    { size_t p = 0; while (true) { size_t q = opc.find('.', p); tk.push_back(opc.substr(p, q == std::string::npos ? std::string::npos : q - p)); if (q == std::string::npos) break; p = q + 1; } }
    // mma sync aligned <geom> <la> <lb> [satfinite] <d> <a> <b> <c>
    if (tk.size() < 10) {
      fprintf(stderr, "error: inline-asm %s: unsupported mma.sync form (expected mma.sync.aligned.<shape>.row.col[.satfinite].<d>.<a>.<b>.<c>)\n", opc.c_str());
      exit(1);
    }
    bool sat = tk.size() == 11 && tk[6] == "satfinite";
    size_t ti = sat ? 7 : 6;
    if (tk.size() != ti + 4 || tk[4] != "row" || tk[5] != "col") {
      fprintf(stderr, "error: inline-asm %s: only .row.col mma.sync is lowered\n", opc.c_str());
      exit(1);
    }
    const std::string geom = tk[3], td = tk[ti], ta = tk[ti + 1], tb = tk[ti + 2], tc = tk[ti + 3];
    Plan P; std::string err;
    if (td != tc || !classify_mma_form(geom, ta, tb, sat, td, P.S, err)) {
      if (err.empty()) err = "D type " + td + " differs from C type " + tc;
      fprintf(stderr, "error: inline-asm %s: %s\n", opc.c_str(), err.c_str());
      exit(1);
    }
    P.sig = tensor_is_f16ish(ta) && ta == "f16" ? ".f32.f32" : ("." + ta + (tb != ta ? "." + tb : std::string("")));
    // four brace groups of $N operands
    std::vector<std::vector<int>> groups;
    size_t p = 0;
    while ((p = rest.find('{', p)) != std::string::npos) {
      size_t q = rest.find('}', p);
      if (q == std::string::npos) return false;
      std::vector<int> g;
      std::string body = rest.substr(p + 1, q - p - 1);
      for (size_t k = 0; k < body.size(); ++k)
        if (body[k] == '$') {
          size_t e = k + 1;
          if (e < body.size() && body[e] == '{') ++e;
          int v = 0; bool any = false;
          while (e < body.size() && isdigit((unsigned char)body[e])) { v = v * 10 + (body[e] - '0'); ++e; any = true; }
          if (!any) return false;
          g.push_back(v);
        }
      groups.push_back(g);
      p = q + 1;
    }
    if (groups.size() != 4 || groups[0].size() != 4 || (int)groups[1].size() != P.S.nA || (int)groups[2].size() != P.S.nB || groups[3].size() != 4) {
      fprintf(stderr, "error: inline-asm %s: operand groups do not match the %s fragment sizes\n", opc.c_str(), geom.c_str());
      exit(1);
    }
    for (int n : groups[0]) if (n >= (int)ops.size() || !ops[n].out) return false; // D must be outputs
    P.D = groups[0]; P.A = groups[1]; P.Bv = groups[2]; P.C = groups[3];
    plans.push_back(P);
  }
  // fragments loaded by ldmatrix asm: leave the whole asm to the Triton (WGMMA_SS) path
  for (auto &P : plans)
    for (int n : P.A) if (!ops[n].out && fromLdmatrix(Call->getArgOperand(ops[n].pos))) return false;
  { // validate before emitting anything: every operand readable and 32-bit
    std::vector<bool> written(nOut, false);
    auto ok = [&](int n) {
      if (n < 0 || n >= (int)ops.size()) return false;
      if (!ops[n].out) return Call->getArgOperand(ops[n].pos)->getType()->getPrimitiveSizeInBits() == 32;
      if (written[ops[n].pos]) return true;
      for (auto &o : ops)
        if (!o.out && o.code == std::to_string(n)) return Call->getArgOperand(o.pos)->getType()->getPrimitiveSizeInBits() == 32;
      return false;
    };
    for (auto &P : plans) {
      for (int n : P.A) if (!ok(n)) return false;
      for (int n : P.Bv) if (!ok(n)) return false;
      for (int n : P.C) if (!ok(n)) return false;
      for (int n : P.D) written[ops[n].pos] = true;
    }
    for (int i = 0; i < nOut; ++i) {
      if (outType(i)->getPrimitiveSizeInBits() != 32) return false;
      if (!written[i]) { fprintf(stderr, "error: inline-asm mma.sync: output %d is never written\n", i); exit(1); }
    }
  }
  for (auto &P : plans) {
    Type *AccT = P.S.intAcc ? I32 : F32;
    std::string name = "cupbop.mma." + P.S.geom + ".row.col" + (P.S.sat ? ".satfinite" : "") + P.sig;
    SmallVector<Type *, 12> tys;
    SmallVector<Value *, 12> args;
    for (int n : P.A) { Value *v = readOp(n); if (!v || !(v = as32(v, I32))) return false; args.push_back(v); tys.push_back(I32); }
    for (int n : P.Bv) { Value *v = readOp(n); if (!v || !(v = as32(v, I32))) return false; args.push_back(v); tys.push_back(I32); }
    for (int n : P.C) { Value *v = readOp(n); if (!v || !(v = as32(v, AccT))) return false; args.push_back(v); tys.push_back(AccT); }
    StructType *RT = StructType::get(Ctx, {AccT, AccT, AccT, AccT});
    FunctionCallee FC = M->getOrInsertFunction(name, FunctionType::get(RT, tys, false));
    CallInst *R = B.CreateCall(FC, args, "asm.mma");
    tensor_set_convergent(R);
    for (int i = 0; i < 4; ++i) cur[ops[P.D[i]].pos] = B.CreateExtractValue(R, i);
  }
  // results
  if (Call->getType()->isVoidTy()) return true;
  Value *res = UndefValue::get(Call->getType());
  bool isStruct = isa<StructType>(Call->getType());
  for (int i = 0; i < nOut; ++i) {
    Value *v = as32(cur[i], outType(i));
    if (isStruct) res = B.CreateInsertValue(res, v, i); else res = v;
  }
  Call->replaceAllUsesWith(res);
  fprintf(stderr, "[mma] inline-asm mma.sync: %zu statement(s) -> cupbop.mma.%s\n", plans.size(), plans[0].S.geom.c_str());
  return true;
}

// cvt.rna[.satfinite].tf32.f32 (wmma::__float_to_tf32, CUTLASS): round to the top 19 bits, ties away from zero,
// result in fp32 layout (low 13 bits zero); NaN -> 0x7fffffff, infinities kept; overflow -> inf (satfinite: max).
static Value *emit_cvt_rna_tf32(IRBuilder<> &B, Value *x, bool satfinite) {
  Type *I32 = B.getInt32Ty();
  if (!x->getType()->isIntegerTy(32)) x = B.CreateBitCast(x, I32);
  Value *special = B.CreateICmpEQ(B.CreateAnd(x, 0x7f800000u), B.getInt32(0x7f800000u));
  Value *r = B.CreateAnd(B.CreateAdd(x, B.getInt32(0x1000u)), B.getInt32(0xffffe000u));
  if (satfinite) { // finite input rounded to infinity -> largest finite tf32 of that sign
    Value *rinf = B.CreateICmpEQ(B.CreateAnd(r, 0x7fffffffu), B.getInt32(0x7f800000u));
    r = B.CreateSelect(rinf, B.CreateOr(B.CreateAnd(x, 0x80000000u), B.getInt32(0x7f7fe000u)), r);
  }
  Value *nan = B.CreateICmpNE(B.CreateAnd(x, 0x007fffffu), B.getInt32(0));
  Value *s = B.CreateSelect(nan, B.getInt32(0x7fffffffu), x);
  return B.CreateSelect(special, s, r, "cvt.rna.tf32");
}

void replace_asm_call(llvm::Module *M) {
  // clang (CUDA 12, sm_90) emits __activemask() as the llvm.nvvm.activemask intrinsic,
  // not the `activemask.b32` asm the lifter uses; lower it the same way here so the
  // schedule-1 staging sees a __cupbop_activemask call and the backend never sees the
  // NVVM intrinsic ("Do not know how to promote this operator").
  {
    int sched = 0;
    if (const char *e = std::getenv("VORTEX_SCHEDULE_FLAG")) sched = std::atoi(e);
    auto I32 = llvm::Type::getInt32Ty(M->getContext());
    std::vector<llvm::CallInst *> acts;
    for (auto &F : *M)
      for (auto &BB : F)
        for (auto &I : BB)
          if (auto *CI = llvm::dyn_cast<llvm::CallInst>(&I))
            if (CI->getCalledFunction() && CI->getCalledFunction()->getName() == "llvm.nvvm.activemask")
              acts.push_back(CI);
    for (auto *CI : acts) {
      llvm::IRBuilder<> builder(CI);
      llvm::Value *res;
      if (sched != 0) {
        llvm::FunctionCallee FC = M->getOrInsertFunction("__cupbop_activemask", llvm::FunctionType::get(I32, false));
        res = builder.CreateCall(FC, {}, "activemask");
      } else {
        res = llvm::ConstantInt::get(I32, 0xffffffffu);
      }
      if (CI->getType() != I32) res = builder.CreateBitCast(res, CI->getType());
      CI->replaceAllUsesWith(res);
      CI->eraseFromParent();
    }
    if (!acts.empty()) fprintf(stderr, "[CuPBoP] lowered %zu llvm.nvvm.activemask\n", acts.size());
  }
  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);
  auto I64 = llvm::Type::getInt64Ty(context);
  auto F32 = llvm::Type::getFloatTy(context);
  auto HalfTy = llvm::Type::getHalfTy(context);
  auto PtrTy = PointerType::getUnqual(context);
  std::vector<CallInst *> need_remove;

  // TCU: Track ldmatrix results → shared memory pointers
  // Key: the ldmatrix CallInst result (struct {i32,i32,i32,i32})
  // Value: {smem_ptr, is_transposed}
  struct LdMatrixInfo {
    Value *smem_ptr;    // ptr addrspace(3) operand
    bool is_transposed; // .trans variant (B tile)
  };
  std::map<Value *, LdMatrixInfo> ldmatrix_map;

  // Helper: strip thread-dependent GEP indices to get the tile base address.
  // Triton IR pattern:
  //   %ptr = GEP @global_smem, %thread_dep_offset   ← strip variable index
  //   %ptr2 = GEP %ptr, 0                           ← strip constant-zero index
  // Returns: @global_smem (for A) or ConstExpr GEP(@global_smem + offset) (for
  // B)
  auto getSmemTileBase = [](Value *smem_ptr) -> Value * {
    Value *cur = smem_ptr;
    while (auto *GEP = dyn_cast<GetElementPtrInst>(cur)) {
      bool all_const = true;
      for (auto idx = GEP->idx_begin(); idx != GEP->idx_end(); ++idx) {
        if (!isa<ConstantInt>(*idx)) {
          all_const = false;
          break;
        }
      }
      if (all_const) {
        // Check if it's a no-op GEP (constant 0 index) — strip it too
        bool all_zero = true;
        for (auto idx = GEP->idx_begin(); idx != GEP->idx_end(); ++idx) {
          if (!cast<ConstantInt>(*idx)->isZero()) {
            all_zero = false;
            break;
          }
        }
        if (all_zero) {
          cur = GEP->getPointerOperand();
          continue;
        }
        break; // Non-zero constant offset — keep it (e.g., B tile offset)
      }
      // Variable index — strip this GEP (thread-dependent offset)
      cur = GEP->getPointerOperand();
    }
    return cur;
  };

  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);

    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->isInlineAsm()) {
            auto asm_inst = dyn_cast<InlineAsm>(Call->getCalledOperand());
            if (!asm_inst)
              continue;
            auto asm_str = asm_inst->getAsmString();
            // RISC-V asm the translator emitted itself (read_cta_csr), not PTX: keep it
            if (asm_str.rfind("csrr ", 0) == 0)
              continue;

            if (lower_inline_mma_sync(Call, M)) { // mma.sync (all element types) -> cupbop.mma.*
              need_remove.push_back(Call);
              continue;
            }
            if (asm_str.find("cvt.rna.tf32.f32") != std::string::npos ||
                asm_str.find("cvt.rna.satfinite.tf32.f32") != std::string::npos) {
              if (Call->arg_size() != 1 || Call->getType()->isVoidTy() || Call->getType()->getPrimitiveSizeInBits() != 32) {
                fprintf(stderr, "error: unsupported cvt.rna.tf32.f32 asm form: %s\n", asm_str.c_str());
                exit(1);
              }
              IRBuilder<> builder(Call);
              Value *v = emit_cvt_rna_tf32(builder, Call->getArgOperand(0), asm_str.find("satfinite") != std::string::npos);
              if (Call->getType() != v->getType()) v = builder.CreateBitCast(v, Call->getType());
              Call->replaceAllUsesWith(v);
              need_remove.push_back(Call);
              continue;
            }
            if (asm_str == "mov.u32 $0, %laneid;") {
              // return the rank within the warp
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              int lane_sched = 0;
              if (const char *e = std::getenv("VORTEX_SCHEDULE_FLAG")) lane_sched = std::atoi(e);
              Value *intra_warp_index;
              if (lane_sched != 0) { // 1:1 and virt: hardware lane
                FunctionCallee fc = M->getOrInsertFunction(
                    "__cupbop_laneid", FunctionType::get(I32, {}, false));
                CallInst *c = builder.CreateCall(fc, {}, "laneid");
                c->setMetadata("divergence", MDNode::get(context, MDString::get(context, "divergence")));
                intra_warp_index = c;
              } else {
                auto intra_warp_index_addr = M->getGlobalVariable("intra_warp_index");
                intra_warp_index = createLoad(builder, intra_warp_index_addr);
              }
              Call->replaceAllUsesWith(intra_warp_index);
              need_remove.push_back(Call);
            } else if (asm_str.find("mad.lo.cc.u32") != std::string::npos &&
                       asm_str.find("madc.hi.u32") != std::string::npos) {
              // PTX: {lo, hi} = a * b + c (64-bit multiply-add)
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              Value *a = Call->getArgOperand(0);
              Value *b = Call->getArgOperand(1);
              Value *c = Call->getArgOperand(2);
              Value *a64 = builder.CreateZExt(a, I64);
              Value *b64 = builder.CreateZExt(b, I64);
              Value *c64 = builder.CreateZExt(c, I64);
              Value *prod = builder.CreateMul(a64, b64);
              Value *sum = builder.CreateAdd(prod, c64);
              Value *lo = builder.CreateTrunc(sum, I32);
              Value *hi = builder.CreateTrunc(builder.CreateLShr(sum, 32), I32);
              Value *result = UndefValue::get(Call->getType());
              result = builder.CreateInsertValue(result, lo, 0);
              result = builder.CreateInsertValue(result, hi, 1);
              Call->replaceAllUsesWith(result);
              need_remove.push_back(Call);
            } else if (asm_str.find("ldmatrix.sync") != std::string::npos) {
              // ── Triton ldmatrix: loads from shared memory into MMA register
              // fragments ── Pattern:
              // ldmatrix.sync.aligned.m8n8.x4[.trans].shared.b16 {$0,$1,$2,$3},
              // [$4] Operands: 4 output i32 (packed fp16), 1 input ptr
              // addrspace(3)
              //
              // For WGMMA_SS TCU path: ldmatrix is NOT needed — TCU reads
              // directly from shared memory. But we save the shared memory
              // pointer for later use by mma.sync conversion.
              //
              // TODO(TCU): Instead of removing, save the smem pointer and
              // associate
              //            it with the mma.sync that consumes these fragments.
              //            For now, replace with undef (TCU conversion
              //            pending).
              bool is_trans = asm_str.find(".trans.") != std::string::npos;
              Value *smem_ptr = Call->getArgOperand(0); // ptr addrspace(3)
              if (cupbop_debug())
                printf("[TCU] detected ldmatrix%s: smem_ptr operand found\n",
                       is_trans ? " (transposed, B tile)" : " (A tile)");
              // Save ldmatrix result → smem pointer mapping
              // Don't replace with undef yet — mma.sync needs to trace operands
              // back through extractvalue to this ldmatrix call.
              ldmatrix_map[Call] = {smem_ptr, is_trans};

            } else if (asm_str.find("mma.sync.aligned") != std::string::npos) {
              // ── Triton mma.sync → Vortex TCU conversion ──
              //
              // Triton IR pattern (Turing fp16, one asm block = m16n8k16):
              //   %result = call {f32,f32,f32,f32} asm "
              //     mma.sync.aligned.m16n8k8.row.col.f32.f16.f16.f32
              //     {$0,$1,$2,$3},{$8,$9},{$10},{$4,$5,$6,$7};
              //     mma.sync.aligned.m16n8k8.row.col.f32.f16.f16.f32
              //     {$0,$1,$2,$3},{$11,$12},{$13},{$4,$5,$6,$7};"
              //   constraints: "=f,=f,=f,=f, 0,1,2,3, r,r,r,r,r,r"
              //   operands: (C0,C1,C2,C3, A0_k0,A1_k0,B_k0, A0_k1,A1_k1,B_k1)
              //
              // Upstream chain:
              //   A regs ← ldmatrix(@global_smem + offset_A)
              //   B regs ← ldmatrix.trans(@global_smem + 1024 + offset_B)
              //   C regs ← previous accumulator or zero
              //
              // Vortex TCU (NT=32, NR=8): m16n16k16
              //   - Needs 2 mma.sync blocks in N direction (each covers n=8)
              //   - Uses WGMMA_SS (flags=6): TCU reads A,B from shared memory
              //   - Register layout differs: NVIDIA 2x2 block vs Vortex
              //   quadrant
              //   - C/D need layout shuffle between NVIDIA and Vortex
              //
              // NOTE: If Vortex NR changes, tile sizes change:
              //   NR=8 → m16n16k16 (need 2 mma.sync blocks in N)
              //   NR=4 → m16n8k8 (1:1 mapping, but still layout mismatch)
              //
              // Implementation plan:
              //   1. Collect consecutive mma.sync calls covering full N
              //   dimension
              //   2. Find shared memory base for A and B from ldmatrix trace
              //   3. Build WGMMA descriptors (smem addr, stride, layout)
              //   4. Emit Vortex TCU: .insn r 0x0b, 0, 2, x0, x1, x6
              //   5. Shuffle C/D between NVIDIA ↔ Vortex layout via shared
              //   memory
              //
              // TODO(TCU): Replace undef with actual TCU instruction emission.

              // Trace A/B operands back to ldmatrix → shared memory pointers
              // mma.sync operands: (C0-C3, A0_k0, A1_k0, B_k0, A0_k1, A1_k1,
              // B_k1) A operands come from extractvalue of ldmatrix result B
              // operands come from extractvalue of ldmatrix.trans result
              Value *smem_A = nullptr, *smem_B = nullptr;

              // Trace operand 4 (first A reg) back to ldmatrix
              if (Call->arg_size() >= 5) {
                Value *a0 = Call->getArgOperand(4);
                if (auto *EV = dyn_cast<ExtractValueInst>(a0)) {
                  Value *agg = EV->getAggregateOperand();
                  if (ldmatrix_map.count(agg)) {
                    smem_A = ldmatrix_map[agg].smem_ptr;
                    if (cupbop_debug())
                      printf("[TCU] traced A to shared memory\n");
                  }
                }
              }
              // Trace operand 6 (first B reg) back to ldmatrix.trans
              if (Call->arg_size() >= 7) {
                Value *b0 = Call->getArgOperand(6);
                if (auto *EV = dyn_cast<ExtractValueInst>(b0)) {
                  Value *agg = EV->getAggregateOperand();
                  if (ldmatrix_map.count(agg)) {
                    smem_B = ldmatrix_map[agg].smem_ptr;
                    if (cupbop_debug())
                      printf("[TCU] traced B to shared memory (transposed)\n");
                  }
                }
              }

              if (cupbop_debug()) {
                printf("[TCU] mma.sync: smem_A=%s, smem_B=%s\n",
                       smem_A ? "found" : "NOT FOUND",
                       smem_B ? "found" : "NOT FOUND");
              }

              // Parse operand info for logging
              unsigned num_args = Call->arg_size();
              if (cupbop_debug()) {
                printf("[TCU] detected mma.sync (%u operands):\n", num_args);
                // C/D: first 4 operands (tied float)
                // A: operands 4-7 (i32 packed fp16)
                // B: operands 8-9 (i32 packed fp16)
                for (unsigned j = 0; j < num_args; j++) {
                  Value *op = Call->getArgOperand(j);
                  printf("  arg[%u]: ", j);
                  op->getType()->print(errs());
                  errs() << "\n";
                  errs().flush();
                }
              }

              // ── TCU instruction emission via WGMMA_SS ──
              // Declare external functions from cudaKernelImpl.cpp (linked at
              // kernel.elf time)
              auto *VoidTy = Type::getVoidTy(context);
              auto *wgmma_encode_fn =
                  M->getOrInsertFunction(
                       "_Z22__vx_wgmma_encode_descyjjjjjj",
                       FunctionType::get(
                           I32, {I64, I32, I32, I32, I32, I32, I32}, false))
                      .getCallee();
              auto *wgmma_mma_fn =
                  M->getOrInsertFunction(
                       "_Z17__vx_wgmma_mma_ssPfS_S_",
                       FunctionType::get(VoidTy, {PtrTy, PtrTy, PtrTy}, false))
                      .getCallee();

              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);

              if (smem_A && smem_B) {
                // ── Strip per-thread GEP to get tile base address ──
                // ldmatrix operand is per-thread: GEP @global_smem,
                // %thread_offset WGMMA needs tile base: @global_smem (A) or
                // @global_smem+1024 (B)
                Value *tile_base_A = getSmemTileBase(smem_A);
                Value *tile_base_B = getSmemTileBase(smem_B);

                if (cupbop_debug()) {
                  printf("[TCU] A tile base: ");
                  tile_base_A->print(errs());
                  errs() << "\n";
                  errs().flush();
                  printf("[TCU] B tile base: ");
                  tile_base_B->print(errs());
                  errs() << "\n";
                  errs().flush();
                }

                // Allocate stack arrays for TCU fragments (8 floats each for
                // NR=8) NOTE: Vortex TCU is m16n16k16. This mma.sync covers
                // m16n8k16. We compute the full m16n16k16 but only use first 4
                // results.
                // TODO: combine 2 mma.sync calls for full N=16.
                auto *fragC_arr = builder.CreateAlloca(
                    F32, ConstantInt::get(I32, 8), "tcu_fragC");
                auto *fragA_arr = builder.CreateAlloca(
                    F32, ConstantInt::get(I32, 8), "tcu_fragA");
                auto *fragB_arr = builder.CreateAlloca(
                    F32, ConstantInt::get(I32, 8), "tcu_fragB");

                // Initialize C accumulator from mma.sync input (first 4
                // operands) Remaining 4 slots zeroed (for the n=8..15 half that
                // this mma.sync doesn't cover)
                for (int ci = 0; ci < 4; ci++) {
                  auto *gep = builder.CreateGEP(F32, fragC_arr,
                                                ConstantInt::get(I32, ci));
                  builder.CreateStore(Call->getArgOperand(ci), gep);
                }
                for (int ci = 4; ci < 8; ci++) {
                  auto *gep = builder.CreateGEP(F32, fragC_arr,
                                                ConstantInt::get(I32, ci));
                  builder.CreateStore(ConstantFP::get(F32, 0.0), gep);
                }

                // ── Encode A descriptor metadata ──
                // Use TILE BASE (not per-thread) address for WGMMA descriptor.
                // For fp16 A tile [M_tile × K_tile] stored row-major:
                //   ldm = K_tile (leading dimension in elements)
                //   TCU load_smem_word: addr = base + (row * ldm + col) *
                //   sizeof(half)
                // For 16x16 tile: ldm=16, is_col_major=0
                Value *smem_A_base_i64 =
                    builder.CreatePtrToInt(tile_base_A, I64);
                Value *a_word = builder.CreateCall(
                    cast<Function>(wgmma_encode_fn),
                    {
                        smem_A_base_i64,
                        ConstantInt::get(I32,
                                         32), // leading_bytes (unused by bugfix
                                              // TCU, kept for compat)
                        ConstantInt::get(I32,
                                         512), // stride_bytes (unused by bugfix
                                               // TCU, kept for compat)
                        ConstantInt::get(I32, 0), // mn_idx (tile at position 0)
                        ConstantInt::get(I32, 0), // k_idx (tile at position 0)
                        ConstantInt::get(I32, 16), // ldm (K_tile = 16 elements)
                        ConstantInt::get(I32,
                                         0) // is_col_major (A is row-major)
                    },
                    "a_desc_word");

                // Fill all 8 A fragment regs with the same metadata word
                Value *a_meta_f =
                    builder.CreateBitCast(a_word, F32, "a_meta_f");
                for (int ai = 0; ai < 8; ai++) {
                  auto *gep = builder.CreateGEP(F32, fragA_arr,
                                                ConstantInt::get(I32, ai));
                  builder.CreateStore(a_meta_f, gep);
                }

                // ── Encode B descriptor metadata ──
                // B tile stored as [K_tile × N_tile] row-major in shared
                // memory. Triton ldmatrix.trans transposes during load, but
                // physical storage is K-major (rows = K, cols = N). TCU
                // accesses B as: load_smem_word(meta_b, k, n, ...) With
                // is_col_major=0: addr = base + (k * ldm + n) * sizeof(half)
                // ldm = N_tile = 16 for [K=16 × N=16] tile
                Value *smem_B_base_i64 =
                    builder.CreatePtrToInt(tile_base_B, I64);
                Value *b_word = builder.CreateCall(
                    cast<Function>(wgmma_encode_fn),
                    {
                        smem_B_base_i64,
                        ConstantInt::get(
                            I32, 32), // leading_bytes (unused by bugfix TCU)
                        ConstantInt::get(
                            I32, 512), // stride_bytes (unused by bugfix TCU)
                        ConstantInt::get(I32, 0),  // mn_idx
                        ConstantInt::get(I32, 0),  // k_idx
                        ConstantInt::get(I32, 16), // ldm (N_tile = 16 elements)
                        ConstantInt::get(
                            I32, 0) // is_col_major (B stored row-major [K×N])
                    },
                    "b_desc_word");

                Value *b_meta_f =
                    builder.CreateBitCast(b_word, F32, "b_meta_f");
                for (int bi = 0; bi < 8; bi++) {
                  auto *gep = builder.CreateGEP(F32, fragB_arr,
                                                ConstantInt::get(I32, bi));
                  builder.CreateStore(b_meta_f, gep);
                }

                // Call WGMMA_SS: TCU reads A,B from shared memory via
                // descriptors
                builder.CreateCall(cast<Function>(wgmma_mma_fn),
                                   {fragC_arr, fragA_arr, fragB_arr});

                // Extract results: first 4 floats from fragC (Vortex layout)
                // Vortex TCU C/D layout: thread t owns elements:
                //   fragC[i*tcN + j] for i in [0,tcM), j in [0,tcN)
                //   where thread t is at row=(t/tcN), col=(t%tcN) in the output
                //   tile
                // NVIDIA mma.sync m16n8 layout: each thread owns 4 elements
                //   mapped to specific (row,col) positions in the output
                // TODO: C/D layout shuffle NVIDIA ↔ Vortex (for now, take
                // as-is)
                Value *result = UndefValue::get(Call->getType());
                for (int ri = 0; ri < 4; ri++) {
                  auto *gep = builder.CreateGEP(F32, fragC_arr,
                                                ConstantInt::get(I32, ri));
                  Value *val = builder.CreateLoad(F32, gep, "tcu_result");
                  result = builder.CreateInsertValue(result, val, ri);
                }
                Call->replaceAllUsesWith(result);

                if (cupbop_debug())
                  printf("[TCU] Emitted WGMMA_SS TCU instruction for mma.sync "
                         "(tile base fixed)\n");
              } else {
                // Fallback: smem pointers not found, replace with undef
                if (cupbop_debug())
                  printf(
                      "[TCU] WARNING: smem pointers not found, using undef\n");
                if (!Call->getType()->isVoidTy()) {
                  Call->replaceAllUsesWith(UndefValue::get(Call->getType()));
                }
              }
              need_remove.push_back(Call);

              // Now clean up the ldmatrix calls that fed this mma.sync
              for (auto &[ldCall, info] : ldmatrix_map) {
                if (auto *CI = dyn_cast<CallInst>(ldCall)) {
                  if (!CI->getType()->isVoidTy() && CI->getParent()) {
                    CI->replaceAllUsesWith(UndefValue::get(CI->getType()));
                    need_remove.push_back(CI);
                  }
                }
              }
              ldmatrix_map.clear();

            } else if (asm_str.find("cvt.rn.f16.f32") != std::string::npos) {
              // float → half conversion: replace with fptrunc
              IRBuilder<> builder(Call);
              Value *src = Call->getArgOperand(0); // float input
              Value *result = builder.CreateFPTrunc(src, HalfTy, "cvt.f32.f16");
              // The asm returns i16 (bitcast of half)
              Value *i16val = builder.CreateBitCast(result, llvm::Type::getInt16Ty(context));
              Call->replaceAllUsesWith(i16val);
              need_remove.push_back(Call);
            } else if (asm_str.find("cvt.f32.f16") != std::string::npos) {
              // half → float conversion: replace with fpext
              IRBuilder<> builder(Call);
              Value *src = Call->getArgOperand(0); // i16 input (bitcast of half)
              Value *half_val = builder.CreateBitCast(src, HalfTy);
              Value *result = builder.CreateFPExt(half_val, F32, "cvt.f16.f32");
              Call->replaceAllUsesWith(result);
              need_remove.push_back(Call);
            } else if (asm_str.find("cvta.to.shared") != std::string::npos) {
              // shared-window address of a generic pointer (i32 or i64 result) -> offset from
              // the Vortex local memory base (runtime __cupbop_cvta_to_shared)
              IRBuilder<> builder(Call);
              FunctionCallee FC = M->getOrInsertFunction(
                  "__cupbop_cvta_to_shared", FunctionType::get(I32, {PtrTy}, false));
              Value *p = Call->getArgOperand(0);
              if (!p->getType()->isPointerTy())
                p = builder.CreateIntToPtr(p, PtrTy);
              Value *res = builder.CreateCall(FC, {p}, "smem.off");
              if (Call->getType()->isIntegerTy(64))
                res = builder.CreateZExt(res, I64);
              else if (!Call->getType()->isIntegerTy(32))
                res = builder.CreateBitCast(res, Call->getType());
              Call->replaceAllUsesWith(res);
              need_remove.push_back(Call);
            } else if (asm_str.find("activemask.b32") != std::string::npos) {
              // CuLifter's warp-reconvergence idiom: activemask feeds bar.warp.sync. 1:1: the
              // hardware active mask; flat schedule: all lanes.
              IRBuilder<> builder(Call);
              int sched = 0;
              if (const char *e = std::getenv("VORTEX_SCHEDULE_FLAG")) sched = std::atoi(e);
              Value *res;
              if (sched != 0) { // 1:1 and virt: hardware active mask
                FunctionCallee FC = M->getOrInsertFunction("__cupbop_activemask", FunctionType::get(I32, false));
                res = builder.CreateCall(FC, {}, "activemask");
              } else {
                res = ConstantInt::get(I32, 0xffffffffu);
              }
              if (!Call->getType()->isIntegerTy(32)) res = builder.CreateBitCast(res, Call->getType());
              Call->replaceAllUsesWith(res);
              need_remove.push_back(Call);
            } else if (asm_str.find("wgmma.fence") != std::string::npos ||
                       asm_str.find("wgmma.commit_group") != std::string::npos ||
                       asm_str.find("wgmma.wait_group") != std::string::npos ||
                       asm_str.find("fence.proxy.async") != std::string::npos) {
              // the wgmma lowering below is synchronous and reads shared memory through the
              // ordinary load path, so the async-proxy fences and group bookkeeping are no-ops
              need_remove.push_back(Call);
            } else if (asm_str.find("wgmma.mma_async") != std::string::npos) {
              // wgmma.mma_async.sync.aligned.m64n<N>k<K>[.satfinite].<d>.<a>.<b> {d0..d(N/2-1)}, desc-a, desc-b, <tail>
              //   f16/bf16 (k16, f32): tail = scale-d, scale-a, scale-b, trans-a, trans-b
              //   tf32 (k8) / e4m3|e5m2 (k32), f32: tail = scale-d, scale-a, scale-b   (K-major only)
              //   s8|u8 (k32, s32):                tail = scale-d
              // LLVM operands: [0] desc_a (i64), [1] desc_b (i64), [2] scale-d (i32, when it is a register), then the
              // N/2 tied accumulators. -> __cupbop_wgmma_m64nNk<K>_<tag>[_sw|_tcu](N, desc_a, desc_b, scale_d, warp_in_wg, acc[N/2])
              size_t sp = asm_str.find("m64n");
              int N = (sp == std::string::npos) ? 0 : atoi(asm_str.c_str() + sp + 4);
              std::string opc;
              if (sp != std::string::npos) {
                size_t e = asm_str.find_first_of(" \t\n{", sp);
                opc = asm_str.substr(sp, e == std::string::npos ? std::string::npos : e - sp);
              }
              std::vector<std::string> otk; // m64nNkK [satfinite] d a b
              { size_t p = 0; while (!opc.empty()) { size_t q = opc.find('.', p); otk.push_back(opc.substr(p, q == std::string::npos ? std::string::npos : q - p)); if (q == std::string::npos) break; p = q + 1; } }
              bool wsat = false;
              for (size_t i = 1; i < otk.size(); ++i) if (otk[i] == "satfinite") { wsat = true; otk.erase(otk.begin() + i); break; }
              std::string wd = otk.size() == 4 ? otk[1] : "", wa = otk.size() == 4 ? otk[2] : "", wb = otk.size() == 4 ? otk[3] : "";
              int wK = 0;
              if (!otk.empty()) { size_t kp = otk[0].find('k'); if (kp != std::string::npos) wK = atoi(otk[0].c_str() + kp + 1); }
              std::string wtag, werr;
              int ntrail = 0;          // trailing immediates after scale-d
              int want[4] = {1, 1, 0, 0};
              bool wint = tensor_is_int8(wa);
              if (otk.size() != 4) werr = "unrecognized opcode";
              else if (tensor_is_f16ish(wa)) {
                if (wb != wa || wd != "f32" || wK != 16 || wsat) werr = "f16/bf16 wgmma needs m64nNk16 .f32 with equal A/B types";
                wtag = wa + "f32"; ntrail = 4;
              } else if (wa == "tf32") {
                if (wb != wa || wd != "f32" || wK != 8 || wsat) werr = "tf32 wgmma needs m64nNk8 .f32.tf32.tf32";
                wtag = "tf32f32"; ntrail = 2;
              } else if (tensor_is_fp8(wa)) {
                if (!tensor_is_fp8(wb) || wd != "f32" || wK != 32 || wsat) werr = "fp8 wgmma needs m64nNk32 .f32.<e4m3|e5m2>.<e4m3|e5m2>";
                wtag = wa + (wb != wa ? wb : std::string("")) + "f32"; ntrail = 2;
              } else if (wint) {
                if (wb != wa || wd != "s32" || wK != 32) werr = "int8 wgmma needs m64nNk32 .s32 with equal A/B types (PTX has no mixed s8/u8 wgmma)";
                wtag = wa + "s32" + (wsat ? "sat" : ""); ntrail = 0;
              } else werr = "element type " + wa + " not lowered (f16, bf16, tf32, e4m3, e5m2, s8, u8)";
              bool ok = werr.empty() && N >= 16 && N <= 256 && (N % 16) == 0;
              if (werr.empty() && !ok) werr = "N must be a multiple of 16";
              unsigned nacc = ok ? (unsigned)N / 2 : 0;
              unsigned firstAcc = Call->arg_size() >= nacc ? Call->arg_size() - nacc : 0;
              // operands before the accumulators: desc_a, desc_b and, when scale-d is a register ("r" operand,
              // clang/CUTLASS form) rather than a literal in the string (CuLifter form: "..., $32, $33, 1, 1, 1, 0, 0;"),
              // the i32 scale-d
              ok = ok && (firstAcc == 2 || firstAcc == 3) &&
                   Call->getArgOperand(0)->getType()->isIntegerTy(64) &&
                   Call->getArgOperand(1)->getType()->isIntegerTy(64);
              for (unsigned i = firstAcc; ok && i < Call->arg_size(); i++)
                if (Call->getArgOperand(i)->getType()->getPrimitiveSizeInBits() != 32) ok = false;
              Value *scaleD = nullptr; // nullptr -> literal, resolved below
              if (ok) {
                size_t kpos = asm_str.find(opc);
                size_t semi = asm_str.find(';', kpos);
                std::string tail = asm_str.substr(kpos, semi - kpos);
                std::vector<std::string> toks; size_t st = 0;
                for (size_t c = tail.find(','); ; c = tail.find(',', st)) {
                  toks.push_back(tail.substr(st, (c == std::string::npos ? tail.size() : c) - st));
                  if (c == std::string::npos) break; st = c + 1;
                }
                auto resolve = [&](std::string tk, long &v, Value *&reg) {
                  tk.erase(0, tk.find_first_not_of(" \t\n")); tk.erase(tk.find_last_not_of(" \t\n;") + 1);
                  v = -999; reg = nullptr;
                  if (!tk.empty() && tk[0] == '$') { // operand placeholder: outputs come first
                    unsigned ph = (unsigned)atoi(tk.c_str() + 1);
                    if (ph >= nacc && ph - nacc < Call->arg_size()) {
                      Value *op = Call->getArgOperand(ph - nacc);
                      if (auto *CI = dyn_cast<ConstantInt>(op)) v = CI->getSExtValue(); else reg = op;
                    }
                  } else if (tk == "p") {
                    reg = (firstAcc >= 3) ? Call->getArgOperand(2) : nullptr; // predicate set from the "r" operand
                  } else if (!tk.empty() && (isdigit(tk[0]) || tk[0] == '-')) {
                    v = atol(tk.c_str());
                  }
                };
                if ((int)toks.size() >= ntrail + 1 + 2) {
                  long v; Value *reg;
                  for (int i = 0; i < ntrail; i++) {
                    resolve(toks[toks.size() - ntrail + i], v, reg);
                    if (v != want[i]) ok = false;
                  }
                  resolve(toks[toks.size() - ntrail - 1], v, reg); // scale-d
                  if (reg) scaleD = reg;
                  else if (v == 0 || v == 1) scaleD = ConstantInt::get(I32, (uint64_t)v);
                  else ok = false;
                } else {
                  ok = false;
                }
              }
              if (!ok) {
                fprintf(stderr, "error: unsupported wgmma form (%u operands): %s\n"
                        "  %s; lowered: m64nNk16 .f32.f16.f16 / .f32.bf16.bf16 (K-major A and B, trans 0,0, scale 1,1), "
                        "m64nNk8 .f32.tf32.tf32 and m64nNk32 .f32.e4m3|e5m2 (scale 1,1), m64nNk32 [.satfinite].s32.s8.s8 / .u8.u8\n",
                        (unsigned)Call->arg_size(), asm_str.c_str(), werr.empty() ? "operands" : werr.c_str());
                exit(1);
              }
              const std::string wbase = "__cupbop_wgmma_m64nNk" + std::to_string(wK) + "_" + wtag;
              std::string wname;
              if (tensor_is_f16ish(wa) && tensor_lowering_mode() != "sw")
                wname = wbase; // f16/bf16: the TCU wrappers as before (TCU builds)
              else
                wname = tensor_pick_symbol("wgmma " + opc, wbase, "__cupbop_wgmma_m64nNk" + std::to_string(wK) + "_" + wa + "s32", wa, wb, wsat);
              Type *AccT = wint ? I32 : F32;
              IRBuilder<> builder(Call);
              auto sreg = [&](const char *name) -> Value * {
                return builder.CreateCall(
                    M->getOrInsertFunction(name, FunctionType::get(I32, false)), {});
              };
              // warp index inside the warpgroup = (linear thread id / 32) % 4; the sreg calls are
              // lowered later by replace_built_in_function for either schedule
              Value *ntx = sreg("llvm.nvvm.read.ptx.sreg.ntid.x");
              Value *nty = sreg("llvm.nvvm.read.ptx.sreg.ntid.y");
              Value *lin = sreg("llvm.nvvm.read.ptx.sreg.tid.x");
              lin = builder.CreateAdd(lin, builder.CreateMul(sreg("llvm.nvvm.read.ptx.sreg.tid.y"), ntx));
              lin = builder.CreateAdd(lin, builder.CreateMul(sreg("llvm.nvvm.read.ptx.sreg.tid.z"),
                                                             builder.CreateMul(ntx, nty)));
              Value *wig = builder.CreateAnd(builder.CreateLShr(lin, 5), 3, "warp.in.wg");
              Type *AccTy = ArrayType::get(AccT, nacc);
              IRBuilder<> AB(&Call->getFunction()->getEntryBlock().front());
              Value *Acc = AB.CreateAlloca(AccTy, nullptr, "wgmma.acc");
              for (unsigned i = 0; i < nacc; i++) {
                Value *v = Call->getArgOperand(firstAcc + i);
                if (v->getType() != AccT) v = builder.CreateBitCast(v, AccT);
                builder.CreateStore(v, builder.CreateConstInBoundsGEP2_32(AccTy, Acc, 0, i));
              }
              FunctionCallee FC = M->getOrInsertFunction(
                  wname, FunctionType::get(Type::getVoidTy(context), {I32, I64, I64, I32, I32, PtrTy}, false));
              tensor_set_convergent(builder.CreateCall(FC, {ConstantInt::get(I32, N), Call->getArgOperand(0),
                                                            Call->getArgOperand(1), scaleD, wig, Acc}));
              Value *Res = UndefValue::get(Call->getType());
              auto *RST = dyn_cast<StructType>(Call->getType());
              for (unsigned i = 0; i < nacc; i++) {
                Value *v = builder.CreateLoad(AccT, builder.CreateConstInBoundsGEP2_32(AccTy, Acc, 0, i));
                Type *ET = RST ? RST->getElementType(i) : Call->getType();
                if (v->getType() != ET) v = builder.CreateBitCast(v, ET);
                Res = builder.CreateInsertValue(Res, v, i);
              }
              Call->replaceAllUsesWith(Res);
              need_remove.push_back(Call);
            } else if (asm_str.find("movmatrix.sync.aligned.m8n8.trans.b16") !=
                       std::string::npos) {
              // CuLifter form of SASS MOVM (8x8 b16 transpose across the warp):
              //   %d = call i32 asm sideeffect "movmatrix.sync.aligned.m8n8.trans.b16 $0, $1;", "=r,r"(i32 %a)
              // -> runtime helper on hardware shuffles (cudaKernelImpl.cpp). 1:1 schedule only.
              IRBuilder<> builder(Call);
              FunctionType *FT = FunctionType::get(I32, {I32}, false);
              FunctionCallee FC = M->getOrInsertFunction(
                  "__cupbop_movmatrix_m8n8_trans_b16", FT);
              Value *src = Call->getArgOperand(0);
              if (!src->getType()->isIntegerTy(32))
                src = builder.CreateBitCast(src, I32);
              Value *res = builder.CreateCall(FC, {src}, "movmatrix.trans");
              if (!Call->getType()->isIntegerTy(32))
                res = builder.CreateBitCast(res, Call->getType());
              Call->replaceAllUsesWith(res);
              need_remove.push_back(Call);
            } else if (asm_str.find(".f32.u32") != std::string::npos &&
                       (asm_str.find("cvt.rn.") != std::string::npos ||
                        asm_str.find("cvt.rz.") != std::string::npos ||
                        asm_str.find("cvt.rm.") != std::string::npos ||
                        asm_str.find("cvt.rp.") != std::string::npos)) {
              // CuLifter form of SASS I2F.U32 with an explicit rounding mode, e.g. the
              // integer-division emulation (cvt.rp + rcp.approx + correction):
              //   %f = call float asm "cvt.rp.f32.u32 $0, $1;", "=f,r"(i32 %x)
              // uitofp rounds to nearest; for rz/rm/rp step one ulp toward the requested
              // direction when the rounded value landed on the wrong side of x (exact: the
              // check goes through i64, and for unsigned x rz == rm).
              IRBuilder<> builder(Call);
              Value *x = Call->getArgOperand(0);
              if (!x->getType()->isIntegerTy(32))
                x = builder.CreateBitCast(x, I32);
              Value *f = builder.CreateUIToFP(x, F32, "cvt.u32.f32");
              bool up = asm_str.find("cvt.rp.") != std::string::npos;
              if (asm_str.find("cvt.rn.") == std::string::npos) {
                Value *back = builder.CreateFPToUI(f, I64);
                Value *x64 = builder.CreateZExt(x, I64);
                Value *wrong = up ? builder.CreateICmpULT(back, x64)
                                  : builder.CreateICmpUGT(back, x64);
                Value *bits = builder.CreateBitCast(f, I32);
                Value *step = builder.CreateBitCast(
                    up ? builder.CreateAdd(bits, ConstantInt::get(I32, 1))
                       : builder.CreateSub(bits, ConstantInt::get(I32, 1)),
                    F32);
                f = builder.CreateSelect(wrong, step, f, "cvt.u32.f32.dir");
              }
              if (Call->getType() != F32)
                f = builder.CreateBitCast(f, Call->getType());
              Call->replaceAllUsesWith(f);
              need_remove.push_back(Call);
            } else if (asm_str.find("cp.async") != std::string::npos ||
                       asm_str.find("mbarrier") != std::string::npos) {
              // lower_cp_async handles (or refuses) these before init_block; never drop one here
              fprintf(stderr, "error: async-copy / mbarrier PTX InlineAsm reached replace_asm_call: %s\n",
                      asm_str.c_str());
              exit(1);
            } else {
              // Anything left is dropped. A dropped asm that produces a value leaves undef
              // behind, which silently changes the program, so say so on every run.
              fprintf(stderr, "warning: unknown PTX InlineAsm: %s (removing%s)\n",
                      asm_str.c_str(),
                      Call->getType()->isVoidTy() ? "" : "; its result becomes undef");
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              if (!Call->getType()->isVoidTy()) {
                Call->replaceAllUsesWith(UndefValue::get(Call->getType()));
              }
              need_remove.push_back(Call);
            }
          }
        }
      }
    }
  }
  for (auto inst : need_remove) {
    inst->eraseFromParent();
  }
}

bool has_warp_barrier(llvm::BasicBlock *B) {
  for (BasicBlock::iterator i = B->begin(); i != B->end(); ++i) {
    Instruction *inst = &(*i);
    llvm::CallInst *Call = llvm::dyn_cast<llvm::CallInst>(inst);
    if (Call) {
      if (Call->isInlineAsm() || !Call->getCalledFunction())
        continue;
      auto func_name = Call->getCalledFunction()->getName().str();
      if (isWarpSync(func_name)) {
        return true;
      }
    }
  }
  return false;
}

bool has_barrier(llvm::BasicBlock *B) {
  for (BasicBlock::iterator i = B->begin(); i != B->end(); ++i) {
    Instruction *inst = &(*i);
    llvm::CallInst *Call = llvm::dyn_cast<llvm::CallInst>(inst);
    if (Call) {
      if (Call->isInlineAsm() || !Call->getCalledFunction())
        continue;
      auto func_name = Call->getCalledFunction()->getName().str();
      if (func_name == "llvm.nvvm.barrier0" || isWarpSync(func_name) ||
          func_name == "llvm.nvvm.barrier.sync" ||
          func_name == "cupbop.shfl.barrier") {
        return true;
      }
    }
  }
  return false;
}

bool has_block_barrier(llvm::BasicBlock *B) {
  for (BasicBlock::iterator i = B->begin(); i != B->end(); ++i) {
    Instruction *inst = &(*i);
    llvm::CallInst *Call = llvm::dyn_cast<llvm::CallInst>(inst);
    if (Call) {
      if (Call->isInlineAsm() || !Call->getCalledFunction())
        continue;
      auto func_name = Call->getCalledFunction()->getName().str();
      if (func_name == "llvm.nvvm.barrier0" ||
          func_name == "llvm.nvvm.barrier.sync") {
        return true;
      }
    }
  }
  return false;
}

bool has_barrier(llvm::Function *F) {
  for (auto B = F->begin(); B != F->end(); B++) {
    if (has_barrier(&(*B)))
      return true;
  }
  return false;
}

bool find_block_barrier_in_region(llvm::BasicBlock *start,
                                  llvm::BasicBlock *end) {
  std::set<llvm::BasicBlock *> visit;
  std::vector<llvm::BasicBlock *> pending_blocks;
  for (int i = 0; i < start->getTerminator()->getNumSuccessors(); i++) {
    pending_blocks.push_back(start->getTerminator()->getSuccessor(i));
  }
  while (!pending_blocks.empty()) {
    BasicBlock *current = pending_blocks.back();
    pending_blocks.pop_back();
    if (visit.find(current) != visit.end())
      continue;
    visit.insert(current);
    if (current == end)
      continue;
    if (has_block_barrier(current)) {
      return 1;
    }
    for (int i = 0; i < current->getTerminator()->getNumSuccessors(); i++) {
      pending_blocks.push_back(current->getTerminator()->getSuccessor(i));
    }
  }
  return 0;
}

bool find_barrier_in_region(llvm::BasicBlock *start, llvm::BasicBlock *end) {
  std::set<llvm::BasicBlock *> visit;
  std::vector<llvm::BasicBlock *> pending_blocks;
  for (int i = 0; i < start->getTerminator()->getNumSuccessors(); i++) {
    pending_blocks.push_back(start->getTerminator()->getSuccessor(i));
  }
  while (!pending_blocks.empty()) {
    BasicBlock *current = pending_blocks.back();
    pending_blocks.pop_back();
    if (visit.find(current) != visit.end())
      continue;
    visit.insert(current);
    if (current == end)
      continue;
    if (has_barrier(current)) {
      return 1;
    }
    for (int i = 0; i < current->getTerminator()->getNumSuccessors(); i++) {
      pending_blocks.push_back(current->getTerminator()->getSuccessor(i));
    }
  }
  return 0;
}

// /*
//   Print IR Module for Debugging Purposes
// */
// static void printIR(llvm::Module *module_) {
//   std::string module_str;
//   llvm::raw_string_ostream ostream{module_str};
//   module_->print(ostream, nullptr, false);
//   std::cout << module_str << std::endl;
// }

/*
  Print IR to String Output for Debugging Purposes
*/
// void printModule(llvm::Module *M) {
//   std::string str;
//   llvm::raw_string_ostream ss(str);
//   std::cout << "### Printing Module ###" << std::endl;
//   for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
//     Function *F = &(*i);
//     auto func_name = F->getName().str();
//     std::cout << func_name << std::endl;
//     for (Function::iterator b = F->begin(); b != F->end(); ++b) {
//       BasicBlock *B = &(*b);
//       errs() << *B;
//     }
//   }
// }

LoadInst *createLoad(IRBuilder<> &B, Value *addr, bool isVolatile) {
  // Before LLVM 18
  // return B.CreateLoad(addr->getType()->getPointerElementType(), addr,
  //                    isVolatile);
  llvm::Type *elementType = nullptr;
  if (auto *allocaInst = dyn_cast<AllocaInst>(addr)) {
    elementType = allocaInst->getAllocatedType();
  } else if (auto *globalVar = dyn_cast<GlobalVariable>(addr)) {
    elementType = globalVar->getValueType();
  } else if (auto *gepInst = dyn_cast<GetElementPtrInst>(addr)) {
    elementType = gepInst->getResultElementType();
  } else {
    errs() << "Unable to determine element type for addr in createLoad\n";
    return nullptr; // Handle the error as appropriate
  }
  if (!elementType) {
    errs() << "Element type is null for addr in createLoad\n";
    return nullptr; // Handle the error as appropriate
  }
  LoadInst *loadInst = B.CreateLoad(elementType, addr);
  loadInst->setVolatile(isVolatile);
  return loadInst;
}

Value *createInBoundsGEP(IRBuilder<> &B, Value *ptr,
                         ArrayRef<Value *> idxlist) {
  // Before LLVM 18
  // return B.CreateInBoundsGEP(
  //  ptr->getType()->getScalarType()->getPointerElementType(), ptr, idxlist);

  llvm::Type *elementType = nullptr;
  if (auto *allocaInst = dyn_cast<AllocaInst>(ptr)) {
    elementType = allocaInst->getAllocatedType();
  } else if (auto *globalVar = dyn_cast<GlobalVariable>(ptr)) {
    elementType = globalVar->getValueType();
  } else if (auto *gepInst = dyn_cast<GetElementPtrInst>(ptr)) {
    elementType = gepInst->getResultElementType();
  } else {
    errs() << "Unable to determine element type for ptr in createInBoundsGEP\n";
    return nullptr;
  }

  if (!elementType) {
    errs() << "Element type is null for ptr in createInBoundsGEP\n";
    return nullptr;
  }
  return B.CreateInBoundsGEP(elementType, ptr, idxlist);
}

Value *createGEP(IRBuilder<> &B, Value *ptr, ArrayRef<Value *> idxlist) {
  // Before LLVM 18
  // return
  // B.CreateGEP(ptr->getType()->getScalarType()->getPointerElementType(),
  //                   ptr, idxlist);
  llvm::Type *elementType = nullptr;
  if (auto *allocaInst = dyn_cast<AllocaInst>(ptr)) {
    elementType = allocaInst->getAllocatedType();
  } else if (auto *globalVar = dyn_cast<GlobalVariable>(ptr)) {
    elementType = globalVar->getValueType();
  } else if (auto *gepInst = dyn_cast<GetElementPtrInst>(ptr)) {
    elementType = gepInst->getResultElementType();
  } else if (auto *bitCastInst = dyn_cast<BitCastInst>(ptr)) {
    elementType = bitCastInst->getDestTy();
  } else {
    // LLVM 18, temporarily disabled (Link issue to be fixed)
    // ptr->dump();
    errs() << "Unable to determine element type for ptr in createGEP\n";
    return nullptr;
  }
  if (!elementType) {
    errs() << "Element type is null for ptr in createGEP\n";
    return nullptr;
  }
  return B.CreateGEP(elementType, ptr, idxlist);
}

// =============================================================================
// WMMA intrinsic translation for Vortex TCU
// =============================================================================
//
// Replaces @llvm.nvvm.wmma.* intrinsics with Vortex TCU equivalent code.
// Handles: load_matrix_sync, mma_sync, store_matrix_sync
//
// Vortex TCU custom instruction (from vx_tensor.h):
//   .insn r 0x0B, 0, 2, x{Ot_id}, x{It_id}, x{flags}
//   Inputs:  f0-f7 (C/D accum), f10-f17 (A), f24-f31 (B)
//   Outputs: f0-f7 (D result)
//
// For CUDA wmma m16n16k16 fp16->fp32:
//   Ot_id = 0 (fp32), It_id = 1 (fp16), flags = 0 (dense)
// =============================================================================

// =============================================================================
// cp.async → DXA transformation
//
// Replaces CUDA cp.async intrinsics with Vortex DXA tile-copy calls.
//
// Pattern:
//   call @llvm.nvvm.cp.async.ca.shared.global.{4,8,16}(ptr addrspace(3), ptr
//   addrspace(1))
//   ...
//   call @llvm.nvvm.cp.async.commit.group()
//   call @llvm.nvvm.cp.async.wait.group(i32 N)
//
// Becomes:
//   if (__vx_is_dxa_warp()) {
//     __vx_dxa_issue_2d(desc_slot, bar_id, smem_base, coord0, coord1);
//   }
//   __vx_barrier_arrive_and_wait(bar_id, num_warps);
// =============================================================================

void replace_cp_async_with_dxa(llvm::Module *M) {
  using namespace llvm;
  LLVMContext &ctx = M->getContext();
  auto *I32 = Type::getInt32Ty(ctx);
  auto *VoidTy = Type::getVoidTy(ctx);
  auto *PtrTy = PointerType::getUnqual(ctx);

  // Declare __vx_* functions (C++ mangled names matching cudaKernelImpl.cpp)
  auto *dxa_issue_fn =
      M->getOrInsertFunction(
           "_Z17__vx_dxa_issue_2djjPvjj",
           FunctionType::get(VoidTy, {I32, I32, PtrTy, I32, I32}, false))
          .getCallee();
  auto *barrier_fn =
      M->getOrInsertFunction("_Z28__vx_barrier_arrive_and_waitjj",
                             FunctionType::get(VoidTy, {I32, I32}, false))
          .getCallee();
  auto *barrier_id_fn =
      M->getOrInsertFunction("_Z19__vx_dxa_barrier_idj",
                             FunctionType::get(I32, {I32}, false))
          .getCallee();
  auto *is_dxa_fn = M->getOrInsertFunction("_Z16__vx_is_dxa_warpv",
                                           FunctionType::get(I32, {}, false))
                        .getCallee();
  auto *warps_fn = M->getOrInsertFunction("_Z20__vx_warps_per_groupv",
                                          FunctionType::get(I32, {}, false))
                       .getCallee();
  auto *local_mem_fn =
      M->getOrInsertFunction("_Z21__vx_local_mem_offsetj",
                             FunctionType::get(PtrTy, {I32}, false))
          .getCallee();

  // Collect all cp.async-related calls
  struct CpAsyncCopyInfo {
    CallInst *call;
    Value *smem_dst; // ptr addrspace(3)
    Value *gmem_src; // ptr addrspace(1)
    unsigned bytes;  // 4, 8, or 16
  };

  std::vector<CpAsyncCopyInfo> copy_calls;
  std::vector<CallInst *> commit_calls;
  std::vector<CallInst *> wait_calls;
  std::vector<CallInst *> wait_all_calls;

  if (cupbop_debug())
    std::cout << "[cp.async→DXA] Scanning module for cp.async patterns...\n"
              << std::flush;

  for (auto &F : *M) {
    if (cupbop_debug())
      std::cout << "[cp.async→DXA] Scanning function: " << F.getName().str()
                << "\n"
                << std::flush;
    for (auto &BB : F) {
      for (auto &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;

        if (!CI->getCalledFunction()) {
          // Could be inline asm or indirect call — skip for approach A
          continue;
        }
        auto name = CI->getCalledFunction()->getName();

        // Debug: print any call containing "async" or "pipeline"
        if (name.contains("async") || name.contains("pipeline") ||
            name.contains("cp_async")) {
          if (cupbop_debug())
            std::cout << "[cp.async→DXA] Candidate call: " << name.str()
                      << " in " << F.getName().str() << "\n"
                      << std::flush;
        }

        // Approach A: Function-level detection (wrapper functions like
        // cp_async_4) Demangled patterns: cp_async_4(void*, void const*),
        // cp_async_commit(), cp_async_wait() Also matches
        // __pipeline_memcpy_async variants Skip kernel functions — filter by
        // checking the callee is a small helper, not a kernel. Kernel functions
        // have many args; cp_async helpers have 0-2.
        if ((name.contains("cp_async") ||
             name.contains("pipeline_memcpy_async") ||
             name.contains("CpAsyncChooser")) &&
            CI->getCalledFunction()->arg_size() <= 2) {
          if (name.contains("commit") || name.contains("pipeline_commit")) {
            commit_calls.push_back(CI);
          } else if (name.contains("wait")) {
            wait_calls.push_back(CI);
          } else if (CI->arg_size() >= 2) {
            // Copy function: first arg = smem dst, second arg = gmem src
            unsigned bytes = 4; // default; could parse from name
            if (name.contains("16"))
              bytes = 16;
            else if (name.contains("8"))
              bytes = 8;
            copy_calls.push_back(
                {CI, CI->getArgOperand(0), CI->getArgOperand(1), bytes});
          }
        }

        // LLVM intrinsics (from __builtin_nvvm_cp_async_*)
        else if (name.starts_with("llvm.nvvm.cp.async.ca.shared.global") ||
                 name.starts_with("llvm.nvvm.cp.async.cg.shared.global")) {
          unsigned bytes = 0;
          if (name.contains(".16"))
            bytes = 16;
          else if (name.contains(".8"))
            bytes = 8;
          else if (name.contains(".4"))
            bytes = 4;
          copy_calls.push_back(
              {CI, CI->getArgOperand(0), CI->getArgOperand(1), bytes});
        } else if (name == "llvm.nvvm.cp.async.commit.group") {
          commit_calls.push_back(CI);
        } else if (name == "llvm.nvvm.cp.async.wait.group") {
          wait_calls.push_back(CI);
        } else if (name == "llvm.nvvm.cp.async.wait.all") {
          wait_all_calls.push_back(CI);
        }
      }
    }
  }

  if (cupbop_debug())
    std::cout << "[cp.async→DXA] Scan done. copy=" << copy_calls.size()
              << " commit=" << commit_calls.size()
              << " wait=" << wait_calls.size() << "\n"
              << std::flush;

  if (copy_calls.empty() && commit_calls.empty() && wait_calls.empty() &&
      wait_all_calls.empty()) {
    if (cupbop_debug())
      std::cout << "[cp.async→DXA] No cp.async found, returning\n"
                << std::flush;
    return;
  }

  // Debug: print collected info
  for (size_t i = 0; i < copy_calls.size(); i++) {
    if (cupbop_debug())
      std::cout << "[cp.async→DXA] copy[" << i
                << "]: smem=" << (void *)copy_calls[i].smem_dst
                << " gmem=" << (void *)copy_calls[i].gmem_src
                << " bytes=" << copy_calls[i].bytes << "\n"
                << std::flush;
  }

  if (cupbop_debug())
    std::cout << "[cp.async→DXA] Found " << copy_calls.size() << " copy, "
              << commit_calls.size() << " commit, " << wait_calls.size()
              << " wait.group, " << wait_all_calls.size()
              << " wait.all calls\n";

  // Track descriptor slots by tracing global pointer back to kernel arg
  // For each distinct global base pointer, assign a descriptor slot
  uint32_t next_desc_slot = 0;
  std::map<Value *, uint32_t> ptr_to_slot;

  auto getBasePtr = [](Value *V) -> Value * {
    // Walk through GEPs, bitcasts, addrspacecasts to find the base pointer
    while (true) {
      if (auto *GEP = dyn_cast<GetElementPtrInst>(V)) {
        V = GEP->getPointerOperand();
      } else if (auto *BC = dyn_cast<BitCastInst>(V)) {
        V = BC->getOperand(0);
      } else if (auto *ASC = dyn_cast<AddrSpaceCastInst>(V)) {
        V = ASC->getPointerOperand();
      } else if (auto *PHI = dyn_cast<PHINode>(V)) {
        V = PHI->getIncomingValue(0); // take first incoming
      } else {
        break;
      }
    }
    return V;
  };

  // Assign descriptor slots — one per copy for now (simplified)
  for (size_t i = 0; i < copy_calls.size(); i++) {
    ptr_to_slot[copy_calls[i].gmem_src] = i;
    if (cupbop_debug())
      std::cout << "[cp.async→DXA] Assigned desc slot " << i << "\n"
                << std::flush;
  }

  // Collect wrapper functions before erasing calls (use-after-free prevention)
  // Save original copy info before eraseFromParent invalidates pointers
  struct CpAsyncOrigInfo {
    Value *gmem_src;
    unsigned bytes;
  };
  std::vector<CpAsyncOrigInfo> copy_calls_orig;
  for (auto &info : copy_calls)
    copy_calls_orig.push_back({info.gmem_src, info.bytes});

  std::set<Function *> wrapper_fns;
  for (auto &info : copy_calls) {
    if (info.call->getCalledFunction())
      wrapper_fns.insert(info.call->getCalledFunction());
  }
  for (auto *CI : commit_calls) {
    if (CI->getCalledFunction())
      wrapper_fns.insert(CI->getCalledFunction());
  }
  for (auto *CI : wait_calls) {
    if (CI->getCalledFunction())
      wrapper_fns.insert(CI->getCalledFunction());
  }

  // --- Extract tile coordinates from kernel structure ---
  // Phase 1: pattern-match blockIdx*TILE and k_base in the kernel function.
  // Phase 2 (TODO): generalized GEP chain analysis for arbitrary patterns.
  Function *kernelFn = copy_calls[0].call->getFunction();

  auto getBlockIdxDim = [](Value *V) -> int {
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI || !CI->getCalledFunction())
      return -1;
    auto name = CI->getCalledFunction()->getName();
    if (name.contains("blockIdx") && name.contains("fetch_builtin")) {
      if (name.contains("_x"))
        return 0;
      if (name.contains("_y"))
        return 1;
      if (name.contains("_z"))
        return 2;
    }
    if (name == "llvm.nvvm.read.ptx.sreg.ctaid.x")
      return 0;
    if (name == "llvm.nvvm.read.ptx.sreg.ctaid.y")
      return 1;
    if (name == "llvm.nvvm.read.ptx.sreg.ctaid.z")
      return 2;
    return -1;
  };

  // Helper: check if Value is a loop induction variable
  auto isLoopVar = [](Value *V) -> bool {
    if (auto *LI = dyn_cast<LoadInst>(V)) {
      if (auto *AI = dyn_cast<AllocaInst>(LI->getPointerOperand())) {
        auto n = AI->getName();
        if (n.contains("k_base") || n.contains("k_tile") || n == "k" ||
            n == "kk")
          return true;
      }
      auto bb = LI->getParent()->getName();
      if (bb.starts_with("for.cond") || bb.starts_with("for.body")) {
        if (isa<AllocaInst>(LI->getPointerOperand()))
          return true;
      }
    }
    if (auto *PHI = dyn_cast<PHINode>(V)) {
      auto bb = PHI->getParent()->getName();
      if (bb.starts_with("for.cond") || bb.contains("loop"))
        return true;
    }
    return false;
  };

  // Recursive classifier: given a Value in an offset expression, determine what
  // it depends on
  enum class TK { BlockX, BlockY, LoopVar, ThreadIdx, Const, Unknown };
  std::function<TK(Value *, int)> classify = [&](Value *V, int depth) -> TK {
    if (depth > 20)
      return TK::Unknown;
    if (isa<ConstantInt>(V))
      return TK::Const;
    int dim = getBlockIdxDim(V);
    if (dim == 0)
      return TK::BlockX;
    if (dim == 1)
      return TK::BlockY;
    {
      auto *CI = dyn_cast<CallInst>(V);
      if (CI && CI->getCalledFunction()) {
        auto n = CI->getCalledFunction()->getName();
        if (n.contains("threadIdx") ||
            n.starts_with("llvm.nvvm.read.ptx.sreg.tid."))
          return TK::ThreadIdx;
      }
    }
    if (isLoopVar(V))
      return TK::LoopVar;
    if (auto *BinOp = dyn_cast<BinaryOperator>(V)) {
      auto k0 = classify(BinOp->getOperand(0), depth + 1);
      auto k1 = classify(BinOp->getOperand(1), depth + 1);
      if (BinOp->getOpcode() == Instruction::Add ||
          BinOp->getOpcode() == Instruction::Or) {
        if (k0 != TK::Const && k0 != TK::Unknown)
          return k0;
        if (k1 != TK::Const && k1 != TK::Unknown)
          return k1;
        return (k0 == TK::Const && k1 == TK::Const) ? TK::Const : TK::Unknown;
      }
      if (BinOp->getOpcode() == Instruction::Mul ||
          BinOp->getOpcode() == Instruction::Shl) {
        if (k0 == TK::Const || k0 == TK::Unknown)
          return k1;
        if (k1 == TK::Const || k1 == TK::Unknown)
          return k0;
        return k0; // both non-trivial: prefer first operand
      }
    }
    if (auto *CE = dyn_cast<CastInst>(V))
      return classify(CE->getOperand(0), depth + 1);
    if (auto *PHI = dyn_cast<PHINode>(V))
      return classify(PHI->getIncomingValue(0), depth + 1);
    if (auto *LI = dyn_cast<LoadInst>(V)) {
      if (auto *AI = dyn_cast<AllocaInst>(LI->getPointerOperand())) {
        auto n = AI->getName();
        if (n.contains("k_base") || n == "k")
          return TK::LoopVar;
        for (auto *U : AI->users()) {
          if (auto *SI = dyn_cast<StoreInst>(U)) {
            if (SI->getPointerOperand() == AI) {
              auto k = classify(SI->getValueOperand(), depth + 1);
              if (k != TK::Unknown)
                return k;
            }
          }
        }
      }
    }
    return TK::Unknown;
  };

  // Collect all blockIdx*TILE and loop induction variable values in the kernel
  std::map<int, Value *> blockIdxTile; // dim -> mul instruction
  Value *loopVar = nullptr;
  for (auto &BB : *kernelFn) {
    for (auto &I : BB) {
      if (auto *Mul = dyn_cast<BinaryOperator>(&I)) {
        if (Mul->getOpcode() == Instruction::Mul) {
          for (int op = 0; op < 2; op++) {
            int dim = getBlockIdxDim(Mul->getOperand(op));
            if (dim >= 0 && isa<ConstantInt>(Mul->getOperand(1 - op))) {
              if (blockIdxTile.find(dim) == blockIdxTile.end()) {
                blockIdxTile[dim] = Mul;
                auto tile =
                    cast<ConstantInt>(Mul->getOperand(1 - op))->getZExtValue();
                if (cupbop_debug())
                  std::cout << "[cp.async→DXA] Found blockIdx." << "xyz"[dim]
                            << " * " << tile << "\n"
                            << std::flush;
              }
            }
          }
        }
      }
      if (!loopVar && isLoopVar(&I)) {
        loopVar = &I;
        if (cupbop_debug())
          std::cout << "[cp.async→DXA] Found loop var in " << BB.getName().str()
                    << "\n"
                    << std::flush;
      }
    }
  }

  // --- Replace copy calls with DXA issue using GEP-based coordinate extraction
  // ---
  for (size_t i = 0; i < copy_calls.size(); i++) {
    auto *CI = copy_calls[i].call;
    IRBuilder<> builder(CI);

    Value *bar_id =
        builder.CreateCall(cast<Function>(barrier_id_fn),
                           {ConstantInt::get(I32, 0)}, "dxa_bar_id");
    Value *smem = copy_calls[i].smem_dst;

    Value *coord0 = ConstantInt::get(I32, 0);
    Value *coord1 = ConstantInt::get(I32, 0);

#if 1 // Phase 2: GEP chain analysis (re-enabled for debugging)
    // Walk GEP chain on gmem_src to find the offset expression

    Value *gmem = copy_calls[i].gmem_src;
    // Find the GEP that computes the element address
    if (auto *GEP = dyn_cast<GetElementPtrInst>(gmem)) {
      // Get the linearized offset (last index in GEP)
      Value *offset = GEP->getOperand(GEP->getNumOperands() - 1);

      // Decompose: walk add chain and classify each term
      bool hasBlockX = false, hasBlockY = false, hasLoop = false;
      Value *blockXVal = nullptr, *blockYVal = nullptr, *loopVal = nullptr;

      std::vector<Value *> worklist = {offset};
      std::set<Value *> visited;
      while (!worklist.empty()) {
        Value *V = worklist.back();
        worklist.pop_back();
        if (visited.count(V))
          continue;
        visited.insert(V);
        // Follow casts (sext, zext, trunc)
        if (auto *CE = dyn_cast<CastInst>(V)) {
          worklist.push_back(CE->getOperand(0));
          continue;
        }
        // Split additions
        if (auto *BinOp = dyn_cast<BinaryOperator>(V)) {
          if (BinOp->getOpcode() == Instruction::Add ||
              BinOp->getOpcode() == Instruction::Or) {
            worklist.push_back(BinOp->getOperand(0));
            worklist.push_back(BinOp->getOperand(1));
            continue;
          }
        }
        TK kind = classify(V, 0);
        if (kind == TK::BlockX && !hasBlockX) {
          hasBlockX = true;
          blockXVal = V;
        }
        if (kind == TK::BlockY && !hasBlockY) {
          hasBlockY = true;
          blockYVal = V;
        }
        if (kind == TK::LoopVar && !hasLoop) {
          hasLoop = true;
          loopVal = V;
        }
      }

      // Map classified terms to DXA coordinates
      // For A[row*K+col]: blockIdx.x (row) + loopVar (col) -> coord0=loopVar,
      // coord1=blockIdx.x For B[row*N+col]: loopVar (row) + blockIdx.y (col) ->
      // coord0=blockIdx.y, coord1=loopVar
      if (hasBlockX && hasLoop && !hasBlockY) {
        coord0 =
            loopVal ? loopVal : (loopVar ? loopVar : ConstantInt::get(I32, 0));
        coord1 = blockXVal ? blockXVal
                           : (blockIdxTile.count(0) ? blockIdxTile[0]
                                                    : ConstantInt::get(I32, 0));
      } else if (hasBlockY && hasLoop && !hasBlockX) {
        coord0 = blockYVal ? blockYVal
                           : (blockIdxTile.count(1) ? blockIdxTile[1]
                                                    : ConstantInt::get(I32, 0));
        coord1 =
            loopVal ? loopVal : (loopVar ? loopVar : ConstantInt::get(I32, 0));
      } else if (hasBlockX && hasBlockY) {
        coord0 = blockYVal ? blockYVal : ConstantInt::get(I32, 0);
        coord1 = blockXVal ? blockXVal : ConstantInt::get(I32, 0);
      } else if (hasLoop) {
        coord0 = loopVal ? loopVal : ConstantInt::get(I32, 0);
      }

      if (cupbop_debug())
        std::cout << "[cp.async→DXA] copy[" << i << "]: blockX=" << hasBlockX
                  << " blockY=" << hasBlockY << " loop=" << hasLoop << "\n"
                  << std::flush;
    }

#endif // Phase 2

    // Phase 1: hardcoded coord pattern for SGEMM
    {
      Value *rb = nullptr, *cb = nullptr, *kb = nullptr;
      for (auto &BB2 : *kernelFn) {
        for (auto &I2 : BB2) {
          if (auto *Mul = dyn_cast<BinaryOperator>(&I2)) {
            if (Mul->getOpcode() != Instruction::Mul)
              continue;
            for (int op = 0; op < 2; op++) {
              int dim = getBlockIdxDim(Mul->getOperand(op));
              if (dim == 0 && !rb && isa<ConstantInt>(Mul->getOperand(1 - op)))
                rb = Mul;
              if (dim == 1 && !cb && isa<ConstantInt>(Mul->getOperand(1 - op)))
                cb = Mul;
            }
          }
          if (auto *LI = dyn_cast<LoadInst>(&I2)) {
            if (auto *AI = dyn_cast<AllocaInst>(LI->getPointerOperand())) {
              if (AI->getName() == "k_base" && !kb &&
                  (BB2.getName().starts_with("for.cond") ||
                   BB2.getName().starts_with("for.body")))
                kb = LI;
            }
          }
        }
      }
      if (!rb)
        rb = ConstantInt::get(I32, 0);
      if (!cb)
        cb = ConstantInt::get(I32, 0);
      if (!kb)
        kb = ConstantInt::get(I32, 0);
      if (i == 0) {
        coord0 = kb;
        coord1 = rb;
      } else {
        coord0 = cb;
        coord1 = kb;
      }
    }

    // Ensure i32 type
    auto ensureI32 = [&](Value *V) -> Value * {
      if (V->getType() == I32)
        return V;
      if (V->getType()->isIntegerTy()) {
        return V->getType()->getIntegerBitWidth() > 32
                   ? builder.CreateTrunc(V, I32, "i32")
                   : builder.CreateZExt(V, I32, "i32");
      }
      return ConstantInt::get(I32, 0);
    };
    coord0 = ensureI32(coord0);
    coord1 = ensureI32(coord1);

    builder.CreateCall(
        cast<Function>(dxa_issue_fn),
        {ConstantInt::get(I32, (uint32_t)i), bar_id, smem, coord0, coord1});
    if (cupbop_debug())
      std::cout << "[cp.async→DXA] Replaced copy " << i << " with DXA issue\n"
                << std::flush;
    CI->eraseFromParent();
  }

  // --- Remove commit.group calls (no-op for DXA) ---
  for (auto *CI : commit_calls) {
    if (cupbop_debug())
      std::cout << "[cp.async→DXA] Removing commit.group\n";
    CI->eraseFromParent();
  }

  // --- Replace wait.group / wait.all with barrier ---
  for (auto *CI : wait_calls) {
    IRBuilder<> builder(CI);
    Value *bar_id =
        builder.CreateCall(cast<Function>(barrier_id_fn),
                           {ConstantInt::get(I32, 0)}, "dxa_bar_id");
    Value *num_warps =
        builder.CreateCall(cast<Function>(warps_fn), {}, "num_warps");
    builder.CreateCall(cast<Function>(barrier_fn), {bar_id, num_warps});
    if (cupbop_debug())
      std::cout << "[cp.async→DXA] Replaced wait.group with barrier\n";
    CI->eraseFromParent();
  }

  for (auto *CI : wait_all_calls) {
    IRBuilder<> builder(CI);
    Value *bar_id =
        builder.CreateCall(cast<Function>(barrier_id_fn),
                           {ConstantInt::get(I32, 0)}, "dxa_bar_id");
    Value *num_warps =
        builder.CreateCall(cast<Function>(warps_fn), {}, "num_warps");
    builder.CreateCall(cast<Function>(barrier_fn), {bar_id, num_warps});
    if (cupbop_debug())
      std::cout << "[cp.async→DXA] Replaced wait.all with barrier\n";
    CI->eraseFromParent();
  }

  // --- Remove cp.async wrapper function bodies ---
  // These contain PTX inline asm that won't compile for RISC-V
  // NOTE: wrapper_fns was collected before eraseFromParent calls above
  {
    for (auto *F : wrapper_fns) {
      if (!F->isDeclaration()) {
        if (cupbop_debug())
          std::cout << "[cp.async→DXA] Removing wrapper body: "
                    << F->getName().str() << "\n";
        F->deleteBody();
      }
    }
  }

  // Emit descriptor metadata as sidecar file for runtime auto-programming.
  // Traces gmem pointers to kernel args, writes dxa_descriptors.txt.
  // TESTED+PASSED.
  if (!copy_calls_orig.empty()) {
    // Trace global memory pointers back to kernel function arguments
    auto traceToArgIdx = [](Value *V) -> int {
      std::set<Value *> visited;
      while (V && visited.insert(V).second) {
        if (auto *Arg = dyn_cast<Argument>(V))
          return Arg->getArgNo();
        if (auto *GEP = dyn_cast<GetElementPtrInst>(V))
          V = GEP->getPointerOperand();
        else if (auto *BC = dyn_cast<BitCastInst>(V))
          V = BC->getOperand(0);
        else if (auto *ASC = dyn_cast<AddrSpaceCastInst>(V))
          V = ASC->getPointerOperand();
        else if (auto *LI = dyn_cast<LoadInst>(V)) {
          auto *ptr = LI->getPointerOperand();
          if (auto *AI = dyn_cast<AllocaInst>(ptr)) {
            for (auto *U : AI->users()) {
              if (auto *SI = dyn_cast<StoreInst>(U)) {
                V = SI->getValueOperand();
                break;
              }
            }
          } else
            break;
        } else if (auto *PHI = dyn_cast<PHINode>(V))
          V = PHI->getIncomingValue(0);
        else
          break;
      }
      return -1;
    };

    // Find integer arguments (likely dimensions: M, N, K)
    std::vector<int> dim_args;
    for (auto &Arg : kernelFn->args()) {
      if (Arg.getType()->isIntegerTy())
        dim_args.push_back(Arg.getArgNo());
    }

    // Extract tile size from blockIdxTile map
    uint32_t tile_size = 16;
    for (auto &[dim, val] : blockIdxTile) {
      if (auto *Mul = dyn_cast<BinaryOperator>(val)) {
        for (int op = 0; op < 2; op++) {
          if (auto *CInt = dyn_cast<ConstantInt>(Mul->getOperand(op))) {
            tile_size = CInt->getZExtValue();
            break;
          }
        }
        break;
      }
    }

    // Infer element bytes from kernel name
    uint32_t elem_bytes = 4;
    if (kernelFn->getName().contains("half") ||
        kernelFn->getName().contains("6__half"))
      elem_bytes = 2;

    // Write sidecar file
    std::ofstream dxa_ofs("dxa_descriptors.txt");
    if (dxa_ofs.is_open()) {
      dxa_ofs << "# kernel_name slot ptr_arg dim0_arg dim1_arg tile0 tile1 "
                 "elem_bytes\n";
      for (size_t i = 0; i < copy_calls_orig.size(); i++) {
        int ptr_arg = traceToArgIdx(copy_calls_orig[i].gmem_src);
        int dim0_arg = -1, dim1_arg = -1;
        if (dim_args.size() >= 3) {
          if (i == 0) {
            dim0_arg = dim_args[2];
            dim1_arg = dim_args[0];
          } // A: K, M
          else {
            dim0_arg = dim_args[1];
            dim1_arg = dim_args[2];
          } // B: N, K
        } else if (!dim_args.empty()) {
          dim0_arg = dim1_arg = dim_args[0]; // square
        }
        dxa_ofs << kernelFn->getName().str() << " " << i << " " << ptr_arg
                << " " << dim0_arg << " " << dim1_arg << " " << tile_size << " "
                << tile_size << " " << elem_bytes << "\n";
        if (cupbop_debug())
          std::cout << "[cp.async→DXA] Desc meta: slot=" << i
                    << " ptr_arg=" << ptr_arg << " dim0=" << dim0_arg
                    << " dim1=" << dim1_arg << " tile=" << tile_size
                    << " elem=" << elem_bytes << "\n"
                    << std::flush;
      }
      dxa_ofs.close();
      extern bool cupbop_dxa_sidecar_written; // async_copy.cpp: !vx.dxa.desc entries append to this file
      cupbop_dxa_sidecar_written = true;
    }
  }
}

// WMMA Section

enum class WmmaOpKind { Unknown, Load, Store, Mma };
enum class WmmaFragKind { Unknown, MatrixA, MatrixB, Accumulator };
enum class WmmaElemKind { Unknown, F16, F32, U8, S8, S32 };
enum class WmmaLayout { None, RowMajor, ColMajor, Dynamic };

struct FragmentSig {
  WmmaFragKind Kind = WmmaFragKind::Unknown;
  WmmaElemKind Elem = WmmaElemKind::Unknown;
  WmmaLayout Layout = WmmaLayout::None;
  int M = 0;
  int N = 0;
  int K = 0;

  bool isValid() const {
    return Kind != WmmaFragKind::Unknown && M > 0 && N > 0 && K > 0;
  }
};

struct WmmaCallDesc {
  WmmaOpKind Op = WmmaOpKind::Unknown;
  SmallVector<FragmentSig, 4> OrderedFrags;

  FragmentSig D;
  FragmentSig A;
  FragmentSig B;
  FragmentSig C;

  WmmaLayout StoreMemLayout = WmmaLayout::None;
  std::string ReplacementName;
};

std::string maybeDemangle(StringRef Name) {
  if (Name.starts_with("_Z") || Name.starts_with("?")) {
    return demangle(Name.str());
  }
  return Name.str();
}

DenseMap<CallInst *, WmmaCallDesc> collectWMMADesc(llvm::Module *M) {
  DenseMap<CallInst *, WmmaCallDesc> CallToDesc;

  auto toFragSuffix = [](WmmaFragKind K) -> const char * {
    switch (K) {
    case WmmaFragKind::MatrixA:
      return "a";
    case WmmaFragKind::MatrixB:
      return "b";
    case WmmaFragKind::Accumulator:
      return "acc";
    default:
      return "unknown";
    }
  };

  auto toElemSuffix = [](WmmaElemKind K) -> const char * {
    switch (K) {
    case WmmaElemKind::F16:
      return "f16";
    case WmmaElemKind::F32:
      return "f32";
    case WmmaElemKind::U8:
      return "u8";
    case WmmaElemKind::S8:
      return "s8";
    case WmmaElemKind::S32:
      return "s32";
    default:
      return "unknown";
    }
  };

  auto toLayoutSuffix = [](WmmaLayout L) -> const char * {
    switch (L) {
    case WmmaLayout::RowMajor:
      return "row";
    case WmmaLayout::ColMajor:
      return "col";
    case WmmaLayout::Dynamic:
      return "dyn";
    case WmmaLayout::None:
      return "none";
    default:
      return "unknown";
    }
  };

  for (Function &F : *M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;

        Function *Callee = CI->getCalledFunction();
        if (!Callee)
          continue;

        std::string Name = maybeDemangle(Callee->getName());
        StringRef Demangled(Name);

        if (!Demangled.contains("nvcuda::wmma::"))
          continue;

        WmmaCallDesc Desc;

        if (Demangled.contains("load_matrix_sync("))
          Desc.Op = WmmaOpKind::Load;
        else if (Demangled.contains("store_matrix_sync("))
          Desc.Op = WmmaOpKind::Store;
        else if (Demangled.contains("mma_sync("))
          Desc.Op = WmmaOpKind::Mma;
        else
          continue;

        size_t SearchFrom = 0;
        while (true) {
          size_t Pos = Demangled.find("fragment<", SearchFrom);
          if (Pos == StringRef::npos)
            break;

          size_t Start = Pos + strlen("fragment<");
          int Depth = 1;
          size_t End = Start;
          for (; End < Demangled.size(); ++End) {
            if (Demangled[End] == '<')
              ++Depth;
            else if (Demangled[End] == '>') {
              --Depth;
              if (Depth == 0)
                break;
            }
          }
          if (End >= Demangled.size())
            break;

          StringRef Body = Demangled.slice(Start, End);

          SmallVector<StringRef, 8> Parts;
          size_t PartStart = 0;
          int AngleDepth = 0;
          for (size_t J = 0; J < Body.size(); ++J) {
            if (Body[J] == '<')
              ++AngleDepth;
            else if (Body[J] == '>')
              --AngleDepth;
            else if (Body[J] == ',' && AngleDepth == 0) {
              Parts.push_back(Body.slice(PartStart, J).trim());
              PartStart = J + 1;
            }
          }
          Parts.push_back(Body.drop_front(PartStart).trim());

          if (Parts.size() == 6) {
            FragmentSig Sig;

            if (Parts[0].contains("matrix_a"))
              Sig.Kind = WmmaFragKind::MatrixA;
            else if (Parts[0].contains("matrix_b"))
              Sig.Kind = WmmaFragKind::MatrixB;
            else if (Parts[0].contains("accumulator"))
              Sig.Kind = WmmaFragKind::Accumulator;

            if (Parts[1].getAsInteger(10, Sig.M) ||
                Parts[2].getAsInteger(10, Sig.N) ||
                Parts[3].getAsInteger(10, Sig.K)) {
              SearchFrom = End + 1;
              continue;
            }

            if (Parts[4] == "__half" || Parts[4].ends_with("__half"))
              Sig.Elem = WmmaElemKind::F16;
            else if (Parts[4] == "float")
              Sig.Elem = WmmaElemKind::F32;
            else if (Parts[4] == "unsigned char")
              Sig.Elem = WmmaElemKind::U8;
            else if (Parts[4] == "signed char")
              Sig.Elem = WmmaElemKind::S8;
            else if (Parts[4] == "int")
              Sig.Elem = WmmaElemKind::S32;

            if (Parts[5] == "void")
              Sig.Layout = WmmaLayout::None;
            else if (Parts[5].contains("row_major"))
              Sig.Layout = WmmaLayout::RowMajor;
            else if (Parts[5].contains("col_major"))
              Sig.Layout = WmmaLayout::ColMajor;

            if (Sig.isValid())
              Desc.OrderedFrags.push_back(Sig);
          }

          SearchFrom = End + 1;
        }

        if (Desc.Op == WmmaOpKind::Load && Desc.OrderedFrags.size() == 1) {
          if (Desc.OrderedFrags[0].Kind == WmmaFragKind::MatrixA)
            Desc.A = Desc.OrderedFrags[0];
          else if (Desc.OrderedFrags[0].Kind == WmmaFragKind::MatrixB)
            Desc.B = Desc.OrderedFrags[0];
        } else if (Desc.Op == WmmaOpKind::Store &&
                   Desc.OrderedFrags.size() == 1) {
          Desc.D = Desc.OrderedFrags[0];
          if (CI->arg_size() >= 4) {
            if (auto *C = dyn_cast<ConstantInt>(CI->getArgOperand(3)))
              Desc.StoreMemLayout =
                  C->isZero() ? WmmaLayout::RowMajor : WmmaLayout::ColMajor;
            else
              Desc.StoreMemLayout = WmmaLayout::Dynamic;
          }
        } else if (Desc.Op == WmmaOpKind::Mma &&
                   Desc.OrderedFrags.size() == 4) {
          Desc.D = Desc.OrderedFrags[0];
          Desc.A = Desc.OrderedFrags[1];
          Desc.B = Desc.OrderedFrags[2];
          Desc.C = Desc.OrderedFrags[3];
        }

        raw_string_ostream OS(Desc.ReplacementName);
        if (Desc.Op == WmmaOpKind::Load) {
          const FragmentSig &Frag = Desc.A.isValid() ? Desc.A : Desc.B;
          OS << "__vx_wmma_load_" << toFragSuffix(Frag.Kind) << "_m" << Frag.M
             << "n" << Frag.N << "k" << Frag.K << "_"
             << toLayoutSuffix(Frag.Layout) << "_" << toElemSuffix(Frag.Elem);
        } else if (Desc.Op == WmmaOpKind::Store) {
          OS << "__vx_wmma_store_d"
             << "_m" << Desc.D.M << "n" << Desc.D.N << "k" << Desc.D.K << "_"
             << toElemSuffix(Desc.D.Elem);
        } else if (Desc.Op == WmmaOpKind::Mma) {
          OS << "__vx_wmma_mma"
             << "_m" << Desc.D.M << "n" << Desc.D.N << "k" << Desc.D.K << "_"
             << toLayoutSuffix(Desc.A.Layout) << "_"
             << toLayoutSuffix(Desc.B.Layout) << "_"
             << toElemSuffix(Desc.A.Elem) << "_" << toElemSuffix(Desc.B.Elem)
             << "_" << toElemSuffix(Desc.D.Elem);
        }
        OS.flush();

        CallToDesc[CI] = std::move(Desc);
      }
    }
  }

  return CallToDesc;
}

void replace_wmma_intrinsics(llvm::Module *M) {
  DenseMap<CallInst *, WmmaCallDesc> CallToDesc = collectWMMADesc(M);
  SmallPtrSet<Function *, 8> ToErase;

  DBG(for (auto &It : CallToDesc) {
    CallInst *CI = It.first;
    WmmaCallDesc &Desc = It.second;
    errs() << "[wmma] " << maybeDemangle(CI->getCalledFunction()->getName())
           << " -> " << Desc.ReplacementName << "\n";
  });

  for (auto &It : CallToDesc) {
    CallInst *CI = It.first;
    WmmaCallDesc &Desc = It.second;

    Function *OldHelper = CI->getCalledFunction();

    FunctionType *FTy = OldHelper->getFunctionType();
    FunctionCallee NewHelperCallee =
        M->getOrInsertFunction(Desc.ReplacementName, FTy);
    Function *NewHelper = dyn_cast<Function>(NewHelperCallee.getCallee());
    if (!NewHelper)
      continue;
    NewHelper->setCallingConv(CallingConv::C);
    CI->setCalledFunction(NewHelperCallee);
    if (OldHelper->use_empty()) {
      ToErase.insert(OldHelper);
    }
  }

  for (Function *F : ToErase) {
    F->dropAllReferences();
    F->removeFromParent();
  }
}

// =============================================================================
// llvm.nvvm.mma.* (mma.sync) and cupbop.mma.* (inline-asm mma.sync) → runtime helpers
//
// CuLifter lifts SASS HMMA/IMMA to the NVPTX mma.sync intrinsics (never to wmma), e.g.
//   {f32 x4} @llvm.nvvm.mma.m16n8k16.row.col.f32.f32(<2 x half> a0..a3, <2 x half> b0,b1, f32 c0..c3)  (HMMA.16816.F32)
//   {f32 x4} @llvm.nvvm.mma.m16n8k16.row.col.bf16   (i32 a0..a3, i32 b0,b1, f32 c0..c3)                (HMMA.16816.F32.BF16)
//   {f32 x4} @llvm.nvvm.mma.m16n8k8.row.col.tf32    (i32 a0..a3, i32 b0,b1, f32 c0..c3)                (HMMA.1688.F32.TF32)
//   {i32 x4} @llvm.nvvm.mma.m16n8k32.row.col[.satfinite].s8 (i32 a0..a3, i32 b0,b1, i32 c0..c3)       (IMMA.16832.S8.S8[.SAT])
// Left alone they reach the Vortex RISC-V backend, which crashes in ISel. Each form (classify_mma_form) is
// lowered to
//   void __cupbop_mma_<geom>_<tag>[_sw|_tcu](i32 a.., i32 b.., ACC c0..c3, ptr d4)    ACC = f32 | i32
// (cudaKernelImpl.cpp / cudaKernelImpl_dtypes.inc: PTX fragment layouts; _sw = arithmetic over hardware
// shuffles, _tcu = Vortex TCU, no suffix = dispatch). CUPBOP_MMA_LOWERING=auto|sw|tcu picks the suffix
// (tensor_pick_symbol). Anything else is reported and aborts the translation.
// =============================================================================
void replace_nvvm_mma_intrinsics(llvm::Module *M) {
  LLVMContext &Ctx = M->getContext();
  Type *F32 = Type::getFloatTy(Ctx);
  Type *I32 = Type::getInt32Ty(Ctx);
  Type *PtrTy = PointerType::getUnqual(Ctx);
  Type *VoidTy = Type::getVoidTy(Ctx);

  SmallVector<CallInst *, 16> ToReplace;
  for (Function &F : *M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *Callee = CI->getCalledFunction())
            if (Callee->getName().starts_with("llvm.nvvm.mma.") || Callee->getName().starts_with("cupbop.mma."))
              ToReplace.push_back(CI);
  if (ToReplace.empty())
    return;

  DBG_PRINT("[nvvm-mma] found %zu NVVM mma.sync intrinsics to replace\n",
            ToReplace.size());

  for (CallInst *CI : ToReplace) {
    const std::string Name = CI->getCalledFunction()->getName().str();
    // <prefix><geom>.<la>.<lb>[.satfinite].<sig...>
    std::string rest = Name.substr(Name.rfind("llvm.nvvm.mma.", 0) == 0 ? strlen("llvm.nvvm.mma.") : strlen("cupbop.mma."));
    std::vector<std::string> tk;
    { size_t p = 0; while (true) { size_t q = rest.find('.', p); tk.push_back(rest.substr(p, q == std::string::npos ? std::string::npos : q - p)); if (q == std::string::npos) break; p = q + 1; } }
    std::string err;
    TensorForm S;
    bool ok = tk.size() >= 4 && tk[1] == "row" && tk[2] == "col";
    if (!ok) err = "only .row.col mma.sync is lowered";
    if (ok) {
      bool sat = tk[3] == "satfinite";
      std::vector<std::string> sig(tk.begin() + (sat ? 4 : 3), tk.end());
      std::string ta, tb, acc;
      if (sig.size() == 2 && sig[0] == "f32" && sig[1] == "f32") { ta = tb = "f16"; acc = "f32"; }    // f16 in, D/C f32
      else if (sig.size() == 2 && (sig[0] == "f16" || sig[1] == "f16")) { err = "f16 accumulators are not lowered"; ok = false; }
      else if (sig.size() == 1 || sig.size() == 2) {
        ta = sig[0]; tb = sig.size() == 2 ? sig[1] : sig[0];
        acc = (tensor_is_int8(ta) || ta == "s4" || ta == "u4" || ta == "b1") ? "s32" : "f32";
      } else { err = "unrecognized signature"; ok = false; }
      if (ok) ok = classify_mma_form(tk[0], ta, tb, sat, acc, S, err);
    }
    if (!ok || CI->arg_size() != (unsigned)(S.nA + S.nB + 4)) {
      fprintf(stderr,
              "error: unsupported mma.sync intrinsic %s (%u operands): %s. Lowered: m16n8k16/m16n8k8 .row.col "
              "f16|bf16 -> f32, m16n8k8/m16n8k4 tf32 -> f32, m16n8k32/m16n8k16 s8|u8 -> s32 [.satfinite], "
              "m16n8k32 e4m3|e5m2 -> f32\n",
              Name.c_str(), (unsigned)CI->arg_size(), err.empty() ? "operand count" : err.c_str());
      exit(1);
    }
    const std::string base = "__cupbop_mma_" + S.geom + "_" + S.tag;
    std::string nosat = S.tag;
    if (S.sat) nosat = nosat.substr(0, nosat.size() - 3);
    const std::string rtName = tensor_pick_symbol(Name, base, "__cupbop_mma_" + S.geom + "_" + nosat, S.ta, S.tb, S.sat);
    DBG_PRINT("[nvvm-mma] %s -> %s\n", Name.c_str(), rtName.c_str());

    Type *AccT = S.intAcc ? I32 : F32;
    IRBuilder<> B(CI);
    SmallVector<Value *, 12> Args;
    SmallVector<Type *, 12> ArgTys;
    for (int i = 0; i < S.nA + S.nB; i++) { // packed A/B fragments as i32
      Value *V = CI->getArgOperand(i);
      if (!V->getType()->isIntegerTy(32))
        V = B.CreateBitCast(V, I32);
      Args.push_back(V);
      ArgTys.push_back(I32);
    }
    for (int i = 0; i < 4; i++) { // accumulators
      Value *V = CI->getArgOperand(S.nA + S.nB + i);
      if (V->getType() != AccT)
        V = B.CreateBitCast(V, AccT);
      Args.push_back(V);
      ArgTys.push_back(AccT);
    }
    Type *DTy = ArrayType::get(AccT, 4);
    IRBuilder<> AB(&CI->getFunction()->getEntryBlock().front());
    Value *D = AB.CreateAlloca(DTy, nullptr, "mma.d");
    Args.push_back(D);
    ArgTys.push_back(PtrTy);

    FunctionCallee FC =
        M->getOrInsertFunction(rtName.c_str(), FunctionType::get(VoidTy, ArgTys, false));
    tensor_set_convergent(B.CreateCall(FC, Args));

    auto *RT = cast<StructType>(CI->getType());
    Value *Result = UndefValue::get(RT);
    for (unsigned i = 0; i < 4; i++) {
      Value *GEP = B.CreateConstInBoundsGEP2_32(DTy, D, 0, i);
      Value *V = B.CreateLoad(AccT, GEP);
      if (RT->getElementType(i) != AccT) V = B.CreateBitCast(V, RT->getElementType(i));
      Result = B.CreateInsertValue(Result, V, i);
    }
    CI->replaceAllUsesWith(Result);
    CI->eraseFromParent();
  }
}

// =============================================================================
// llvm.nvvm.wmma.* (CUDA wmma after init_block inlined the mma.hpp helpers) → runtime helpers
//
// Supported (NT=32): m16n16k16 f16 (f32 accumulators), m16n16k16 bf16, m16n16k8 tf32, m16n16k16 s8/u8 (s32,
// [.satfinite]); loads of A/B (row|col), C (row|col, f32|s32), stores of D (row|col). The fragment storage is
// the NVVM return type (bf16/tf32 A,B: 4 x i32; s8/u8 A,B: 2 x i32; f16 A,B: 8 x <2 x half>; C/D: 8 x 32-bit)
// and holds the Vortex TCU layout (cudaKernelImpl_dtypes.inc), so software and TCU mma read the same fragments.
//   f16  : loads __vx_wmma_load_{a,b}_m16n16k16_{row,col}_f16 (sw: __cupbop_wmma_load_{a,b}_f16_*), mma
//          __vx_wmma_mma_m16n16k16_row_row_f16_f16_f32 (auto) / __cupbop_wmma_mma_f16_{sw,tcu}
//   other: __cupbop_wmma_load_{a,b}_<t>_{row,col}, __cupbop_wmma_mma_<t>[sat][_sw|_tcu]
//   C/D  : __cupbop_wmma_load_c_{f32,s32}_{row,col}; stores __vx_wmma_store_d_m16n16k16_f32 (f32, not sw) /
//          __cupbop_wmma_store_d_{f32,s32}_{row,col}
// Other shapes (m32n8k16, m8n32k16, m8n8k32 int4, m8n8k128 b1, m8n8k4 f64) and f16 accumulators are refused.
// =============================================================================
void replace_nvvm_wmma_intrinsics(llvm::Module *M) {
  LLVMContext &Ctx = M->getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  Type *PtrTy = PointerType::getUnqual(Ctx);
  Type *VoidTy = Type::getVoidTy(Ctx);

  SmallVector<CallInst *, 16> ToReplace;
  SmallVector<CallInst *, 8> Tf32Cvt;
  for (Function &F : *M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *Callee = CI->getCalledFunction()) {
            if (Callee->getName().starts_with("llvm.nvvm.wmma."))
              ToReplace.push_back(CI);
            else if (Callee->getName().starts_with("llvm.nvvm.f2tf32.rna"))
              Tf32Cvt.push_back(CI);
          }
  for (CallInst *CI : Tf32Cvt) { // __nvvm_f2tf32_rna[_satfinite]
    IRBuilder<> B(CI);
    Value *v = emit_cvt_rna_tf32(B, CI->getArgOperand(0), CI->getCalledFunction()->getName().contains("satfinite"));
    if (v->getType() != CI->getType()) v = B.CreateBitCast(v, CI->getType());
    CI->replaceAllUsesWith(v);
    CI->eraseFromParent();
  }

  if (ToReplace.empty())
    return;

  DBG_PRINT("[nvvm-wmma] found %zu NVVM WMMA intrinsics to replace\n",
            ToReplace.size());
  const std::string mode = tensor_lowering_mode();

  auto refuse = [](const std::string &name, const std::string &why) {
    fprintf(stderr, "error: CUDA wmma intrinsic %s: %s. Lowered: m16n16k16 f16 (f32 accumulators), bf16, s8, u8 "
                    "(s32, [.satfinite]) and m16n16k8 tf32; .stride loads/stores, row|col\n", name.c_str(), why.c_str());
    exit(1);
  };
  auto geomOf = [](const std::string &t) -> std::string {
    if (t == "f16" || t == "bf16" || tensor_is_int8(t)) return "m16n16k16";
    if (t == "tf32") return "m16n16k8";
    return "";
  };

  for (CallInst *CI : ToReplace) {
    const std::string Name = CI->getCalledFunction()->getName().str();
    std::vector<std::string> tk;
    { const std::string rest = Name.substr(strlen("llvm.nvvm.wmma.")); size_t p = 0; while (true) { size_t q = rest.find('.', p); tk.push_back(rest.substr(p, q == std::string::npos ? std::string::npos : q - p)); if (q == std::string::npos) break; p = q + 1; } }
    if (!tk.empty() && tk.back().size() >= 2 && tk.back()[0] == 'p' && isdigit((unsigned char)tk.back()[1])) tk.pop_back(); // .p0 / .p1 / .p3
    if (tk.size() < 3) refuse(Name, "unrecognized name");
    const std::string geom = tk[0], op = tk[1];
    IRBuilder<> B(CI);
    IRBuilder<> AB(&CI->getFunction()->getEntryBlock().front());
    auto genericPtr = [&](Value *P) -> Value * {
      if (P->getType() != PtrTy) P = B.CreateAddrSpaceCast(P, PtrTy);
      return P;
    };

    if (op == "load" || op == "store") {
      // load.<a|b|c>.<row|col>.stride.<t> / store.d.<row|col>.stride.<t>
      if (tk.size() != 6 || tk[4] != "stride") refuse(Name, "only the .stride forms are lowered");
      const std::string frag = tk[2], lay = tk[3], t = tk[5];
      if (lay != "row" && lay != "col") refuse(Name, "layout " + lay);
      const bool row = lay == "row";
      std::string rt;
      if (op == "load" && (frag == "a" || frag == "b")) {
        if (geomOf(t).empty() || geomOf(t) != geom) refuse(Name, "type " + t + " with shape " + geom);
        if (t == "f16" && mode != "sw")
          rt = std::string("__vx_wmma_load_") + frag + "_m16n16k16_" + lay + "_f16";
        else
          rt = "__cupbop_wmma_load_" + frag + "_" + t + "_" + lay;
      } else if (op == "load" && frag == "c") {
        if (t != "f32" && t != "s32") refuse(Name, t + " accumulators are not lowered");
        if (geom != "m16n16k16" && geom != "m16n16k8") refuse(Name, "shape " + geom);
        rt = "__cupbop_wmma_load_c_" + t + "_" + lay;
      } else if (op == "store" && frag == "d") {
        if (t != "f32" && t != "s32") refuse(Name, t + " accumulators are not lowered");
        if (geom != "m16n16k16" && geom != "m16n16k8") refuse(Name, "shape " + geom);
        rt = (t == "f32" && mode != "sw") ? std::string("__vx_wmma_store_d_m16n16k16_f32") : "__cupbop_wmma_store_d_" + t + "_" + lay;
      } else {
        refuse(Name, "fragment " + frag);
      }
      DBG_PRINT("[nvvm-wmma] %s -> %s\n", Name.c_str(), rt.c_str());
      if (op == "load") {
        auto *RT = dyn_cast<StructType>(CI->getType());
        if (!RT || CI->arg_size() != 2) refuse(Name, "unexpected signature");
        const unsigned NR = RT->getNumElements();
        Type *FragTy = ArrayType::get(I32, NR);
        Value *Frag = AB.CreateAlloca(FragTy, nullptr, "wmma.frag");
        FunctionCallee FC = M->getOrInsertFunction(rt, FunctionType::get(VoidTy, {PtrTy, PtrTy, I32}, false));
        B.CreateCall(FC, {Frag, genericPtr(CI->getArgOperand(0)), CI->getArgOperand(1)});
        Value *Result = UndefValue::get(RT);
        for (unsigned i = 0; i < NR; i++) {
          Value *GEP = B.CreateConstInBoundsGEP2_32(FragTy, Frag, 0, i);
          Result = B.CreateInsertValue(Result, B.CreateLoad(RT->getElementType(i), GEP), i);
        }
        CI->replaceAllUsesWith(Result);
      } else {
        // (ptr dst, v0..v7, i32 stride)
        if (CI->arg_size() != 10) refuse(Name, "unexpected signature");
        Type *FragTy = ArrayType::get(I32, 8);
        Value *Frag = AB.CreateAlloca(FragTy, nullptr, "wmma.store");
        for (unsigned i = 0; i < 8; i++)
          B.CreateStore(CI->getArgOperand(1 + i), B.CreateConstInBoundsGEP2_32(FragTy, Frag, 0, i));
        Value *Dst = genericPtr(CI->getArgOperand(0)), *Stride = CI->getArgOperand(9);
        if (rt.rfind("__vx_", 0) == 0) { // void (ptr p, ptr frag, i32 ldm, i32 layout)
          FunctionCallee FC = M->getOrInsertFunction(rt, FunctionType::get(VoidTy, {PtrTy, PtrTy, I32, I32}, false));
          B.CreateCall(FC, {Dst, Frag, Stride, ConstantInt::get(I32, row ? 0 : 1)});
        } else {
          FunctionCallee FC = M->getOrInsertFunction(rt, FunctionType::get(VoidTy, {PtrTy, PtrTy, I32}, false));
          B.CreateCall(FC, {Dst, Frag, Stride});
        }
      }
      CI->eraseFromParent();
      continue;
    }

    if (op != "mma") refuse(Name, "operation " + op);
    // mma.<la>.<lb>[.<rnd>].<sig>[.satfinite]; the layouts only matter to the loads (the fragments are layout-free here)
    std::vector<std::string> sig(tk.begin() + 4, tk.end());
    bool sat = !sig.empty() && sig.back() == "satfinite";
    if (sat) sig.pop_back();
    std::string t;
    if (sig.size() == 2 && sig[0] == "f32" && sig[1] == "f32") t = "f16";
    else if (sig.size() == 2 && (sig[0] == "f16" || sig[1] == "f16")) refuse(Name, "f16 accumulators are not lowered");
    else if (sig.size() == 1) t = sig[0];
    else refuse(Name, "unrecognized signature");
    if (geomOf(t).empty() || geomOf(t) != geom) refuse(Name, "type " + t + " with shape " + geom);
    if (sat && !tensor_is_int8(t)) refuse(Name, ".satfinite with " + t);
    const int nAB = t == "f16" ? 8 : (tensor_is_int8(t) ? 2 : 4);
    auto *RT = dyn_cast<StructType>(CI->getType());
    if (!RT || RT->getNumElements() != 8 || CI->arg_size() != (unsigned)(2 * nAB + 8)) refuse(Name, "unexpected signature");
    std::string rt;
    if (t == "f16") {
      if (mode == "sw") rt = "__cupbop_wmma_mma_f16_sw";
      else if (mode == "tcu") rt = tensor_pick_symbol(Name, "__cupbop_wmma_mma_f16", "__cupbop_wmma_mma_f16", "f16", "f16", false);
      else rt = "__vx_wmma_mma_m16n16k16_row_row_f16_f16_f32"; // auto: TCU on TCU builds, software otherwise (runtime)
    } else {
      const std::string base = "__cupbop_wmma_mma_" + t + (sat ? "sat" : "");
      rt = tensor_pick_symbol(Name, base, "__cupbop_wmma_mma_" + t, t, t, sat);
    }
    DBG_PRINT("[nvvm-wmma] %s -> %s\n", Name.c_str(), rt.c_str());
    Type *ABTy = ArrayType::get(I32, nAB), *CTy = ArrayType::get(I32, 8);
    Value *AA = AB.CreateAlloca(ABTy, nullptr, "wmma.a");
    Value *BA = AB.CreateAlloca(ABTy, nullptr, "wmma.b");
    Value *CA = AB.CreateAlloca(CTy, nullptr, "wmma.c");
    Value *DA = AB.CreateAlloca(CTy, nullptr, "wmma.d");
    for (int i = 0; i < nAB; i++) B.CreateStore(CI->getArgOperand(i), B.CreateConstInBoundsGEP2_32(ABTy, AA, 0, i));
    for (int i = 0; i < nAB; i++) B.CreateStore(CI->getArgOperand(nAB + i), B.CreateConstInBoundsGEP2_32(ABTy, BA, 0, i));
    for (int i = 0; i < 8; i++) B.CreateStore(CI->getArgOperand(2 * nAB + i), B.CreateConstInBoundsGEP2_32(CTy, CA, 0, i));
    // void (ptr d, ptr a, ptr b, ptr c)
    FunctionCallee FC = M->getOrInsertFunction(rt, FunctionType::get(VoidTy, {PtrTy, PtrTy, PtrTy, PtrTy}, false));
    tensor_set_convergent(B.CreateCall(FC, {DA, AA, BA, CA}));
    Value *Result = UndefValue::get(RT);
    for (unsigned i = 0; i < 8; i++)
      Result = B.CreateInsertValue(Result, B.CreateLoad(RT->getElementType(i), B.CreateConstInBoundsGEP2_32(CTy, DA, 0, i)), i);
    CI->replaceAllUsesWith(Result);
    CI->eraseFromParent();
  }

  // Remove unused NVVM intrinsic declarations
  SmallVector<Function *, 8> DeadDecls;
  for (Function &F : *M) {
    if ((F.getName().starts_with("llvm.nvvm.wmma.") || F.getName().starts_with("llvm.nvvm.f2tf32.")) && F.use_empty())
      DeadDecls.push_back(&F);
  }
  for (Function *F : DeadDecls)
    F->removeFromParent();
}


// Core mapping (virt, schedule 1): lanes are hardware, so every value derived from
// the intra-warp index is lane-divergent. Mark the loads of the lane index (global
// intra_warp_index / per-function local_intra_warp_idx alloca) with the "divergence"
// metadata the 1:1 schedule puts on threadIdx loads; the root call (vx_thread_id) is
// marked in insert_warp_loop.cpp.
void mark_virt_lane_divergence(llvm::Module *M) {
  auto *gv = M->getGlobalVariable("intra_warp_index");
  for (auto &F : *M) {
    if (F.isDeclaration()) continue;
    for (auto &BB : F) {
      for (auto &I : BB) {
        auto *LI = dyn_cast<LoadInst>(&I);
        if (!LI) continue;
        auto *ptr = LI->getPointerOperand();
        bool lane = (gv && ptr == gv);
        if (auto *AI = dyn_cast<AllocaInst>(ptr))
          lane = lane || AI->getName() == "local_intra_warp_idx";
        if (!lane) continue;
        LI->setMetadata("divergence", MDNode::get(M->getContext(), MDString::get(M->getContext(), "divergence")));
      }
    }
  }
}
