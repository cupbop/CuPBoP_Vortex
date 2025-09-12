#include "memory_hierarchy.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <assert.h>
#include "tool.h"
#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <sstream>
#include <tuple>
#include <vector>


//Previous approach (Shared mem -> Global mem)
void mem_share2global(llvm::Module *M) {
  LLVMContext *C = &M->getContext();
  llvm::Type *Int32T = Type::getInt32Ty(*C);
  llvm::Type *Int64T = Type::getInt64Ty(*C);
  llvm::Type *Int8T = Type::getInt8Ty(*C);

  std::map<GlobalVariable *, GlobalVariable *> corresponding_global_memory;
  std::set<llvm::Instruction *> need_remove;
  std::set<GlobalVariable *> need_remove_share_memory;

  // find all share memory and generate corresponding global memory
  
  for (auto I = M->global_begin(), E = M->global_end(); I != E; ++I) {
    if (GlobalVariable *share_memory = dyn_cast<GlobalVariable>(I)) {
      if (auto PT = dyn_cast<PointerType>(I->getType())) {
        unsigned AS = PT->getAddressSpace();
        if (AS == 3) {
        // find a share memory
        //printIR(M);
          need_remove_share_memory.insert(share_memory);
          // generate the corresponding global memory variable
          auto new_name = "wrapper_global_" + share_memory->getName().str();
          // LLVM 18
          auto element_type = share_memory->getValueType();
          //auto element_type = PT->getElementType();
          //shared memory 가 array type 일때
          if (auto array_type = dyn_cast<ArrayType>(element_type)) {
            if (share_memory->hasExternalLinkage() &&
                array_type->getArrayNumElements() == 0) {
              // external shared memory of [] (dynamic shared memory)
              // generate global type pointer
              PointerType *PointerTy =
                  PointerType::get(array_type->getElementType(), 0);
              llvm::Constant *x1 = ConstantPointerNull::get(PointerTy);
              llvm::GlobalVariable *global_ptr = new llvm::GlobalVariable(
                  *M, PointerTy, false, llvm::GlobalValue::CommonLinkage, x1,
                  "wrapper_global_data", NULL,
                  llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);

              global_ptr->setDSOLocal(true);

              corresponding_global_memory.insert(
                  std::pair<GlobalVariable *, GlobalVariable *>(share_memory,
                                                                global_ptr));
            } else {
              //llvm::GlobalVariable *global_memory = new llvm::GlobalVariable(
              //    *M, array_type, false, llvm::GlobalValue::ExternalLinkage,
              //    NULL, new_name, NULL,
              //    llvm::GlobalValue::GeneralDynamicTLSModel, 1);
              llvm::GlobalVariable *global_memory = new llvm::GlobalVariable(
                  *M, array_type, false, llvm::GlobalValue::ExternalLinkage,
                  NULL, new_name, NULL,
                  llvm::GlobalValue::LocalExecTLSModel, 1);
              ConstantAggregateZero *const_array =
                  ConstantAggregateZero::get(array_type);
              global_memory->setInitializer(const_array);
              corresponding_global_memory.insert(
                  std::pair<GlobalVariable *, GlobalVariable *>(share_memory,
                                                                global_memory));
            }
          } else if (auto int_type = dyn_cast<IntegerType>(element_type)) {
            auto zero = llvm::ConstantInt::get(int_type, 0, true);
            llvm::GlobalVariable *global_memory = new llvm::GlobalVariable(
                *M, int_type, false, llvm::GlobalValue::ExternalLinkage, zero,
                new_name, NULL, llvm::GlobalValue::GeneralDynamicTLSModel, 0,
                false);
            corresponding_global_memory.insert(
                std::pair<GlobalVariable *, GlobalVariable *>(share_memory,
                                                              global_memory));
          } else if (element_type->isFloatTy()) {
            auto FP_type = llvm::Type::getFloatTy(*C);
            auto zero = llvm::ConstantFP::get(FP_type, 0);
            llvm::GlobalVariable *global_memory = new llvm::GlobalVariable(
                *M, FP_type, false, llvm::GlobalValue::ExternalLinkage, zero,
                new_name, NULL, llvm::GlobalValue::GeneralDynamicTLSModel, 0,
                false);
            corresponding_global_memory.insert(
                std::pair<GlobalVariable *, GlobalVariable *>(share_memory,
                                                              global_memory));
          } else {
            assert(0 && "The required Share Memory Type is not supported\n");
          }
          //printIR(M);
        }
      }
    }
  }

  for (auto k : corresponding_global_memory) {
    auto share_addr = k.first;
    auto global_addr = k.second;
    share_addr->replaceAllUsesWith(ConstantExpr::getPointerCast(
        global_addr, cast<PointerType>(share_addr->getType())));
  }

  for (auto i : need_remove) {
    i->dropAllReferences();
    i->eraseFromParent();
  }
  for (auto i : need_remove_share_memory) {
    i->dropAllReferences();
    i->eraseFromParent();
  }
}

// === Hardcoded selection for gridDim.x * gridDim.y per benchmark ===
//  - Priority order:
//    (1) Compile-time constant initializer for grid_size_{x,y} (if available, use it)
//    (2) Hardcoded value matched by benchmark name (current path/moduleID/source file)
//    (3) Environment variable VORTEX_NUM_CTA (if set, overrides everything)
//    (4) Final fallback: 256
static uint64_t decideNumCTAsByBench(const llvm::Module &M) {
  using namespace llvm;
  auto hay = M.getSourceFileName() + " " + M.getModuleIdentifier();
  // Convert to lowercase for case-insensitive matching
  std::string s = hay;
  std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c){ return std::tolower(c); });

  // Force override via environment variable if available
  if (const char* env = std::getenv("VORTEX_NUM_CTA")) {
    char* endp = nullptr;
    unsigned long long v = std::strtoull(env, &endp, 10);
    if (endp && *endp == '\0' && v > 0) return v;
  }

  auto contains = [&](const char* key)->bool {
    return s.find(key) != std::string::npos;
  };

  // --- Add/modify cases here ---
  // backprop [grid=(1,4,1)]
  if (contains("backprop"))     return 1ull * 4ull;

  // bfs [grid=(8,1,1)]
  if (contains("bfs"))          return 8ull;

  // b+tree / btree  [grid=(6000,1,1)] or [grid=(10000,1,1)]
  // Default is 6000; can be overridden with env VORTEX_BPTREE_CTA=10000 etc.
  if (contains("b+tree") || contains("bptree") || contains("btree")) {
    if (const char* bp = std::getenv("VORTEX_BPTREE_CTA")) {
      char* endp = nullptr;
      unsigned long long v = std::strtoull(bp, &endp, 10);
      if (endp && *endp == '\0' && v > 0) return v;
    }
    return 6000ull; // adjust to 10000 if needed
  }

  // conv3 [grid=(8,16,1)]
  if (contains("conv3"))        return 8ull * 16ull;

  // dotproduct [grid=(256,1,1)]
  if (contains("dotproduct"))   return 256ull;

  // gauss [grid=(13,13,1)]
  if (contains("gauss"))        return 13ull * 13ull;

  // nearn [grid=(1,669,1)] → 669
  if (contains("nearn"))        return 669ull;

  // pathfinder [grid=(3,1,1)]
  if (contains("pathfinder"))   return 3ull;

  // psum [grid=(256,1,1)]
  if (contains("psum"))         return 256ull;

  // saxpy [grid=(128,1,1)]
  if (contains("saxpy"))        return 128ull;

  // sgemm [grid=(16,16,1)]
  if (contains("sgemm"))        return 16ull * 16ull;

  // stencil [grid=(1,30,6)] → y=30 * x=1 = 30
  // (If z dimension is included in total CTA count, use 30*1*6 = 180 instead)
  if (contains("stencil"))      return 30ull; // change to 180 if needed

  // transpose [grid=(64,64,1)]
  if (contains("transpose"))    return 64ull * 64ull;

  // vecadd [grid=(8,1,1)]
  if (contains("vecadd"))       return 8ull;

  // psort [grid=(64,1,1)]
  if (contains("psort"))        return 64ull;

  // Default fallback
  return 256ull;
}

// Function to replace shared memory with global memory
// (Originally assumed thread collapsing, but extended to work under HW thread mapping)
// Replace shared memory (AS=3) with global (AS=1).
// Create CTA slices of size grid_size_x * grid_size_y,
// and rewrite all IR uses so that block_index_x, block_index_y point to different slices per block.
//
// - static shared (arrays/scalars): [NumCTA x Elem] or [NumCTA x N x T]
// - dynamic shared (extern __shared__ []): [NumCTA x MAX_DYN_BYTES] i8 buffer
//
// Note: If grid_size_* are not compile-time constants, the global array size cannot be determined → fallback value is used
//       (runtime indexing still works fine)
void mem_share2global_sche_2(llvm::Module *M) {
  using namespace llvm;
  LLVMContext &C = M->getContext();

  auto *I32 = Type::getInt32Ty(C);
  auto *I64 = Type::getInt64Ty(C);
  auto *I8  = Type::getInt8Ty(C);

  // 0) grid_size_x * grid_size_y → compute as compile-time constants if possible
  auto *GV_grid_x = M->getGlobalVariable("grid_size_x", /*AllowInternal*/true);
  auto *GV_grid_y = M->getGlobalVariable("grid_size_y", /*AllowInternal*/true);

  auto getConstInitI32 = [&](GlobalVariable *GV) -> std::optional<uint32_t> {
    if (!GV) return std::nullopt;
    if (GV->hasInitializer()) {
      if (auto *CI = dyn_cast<ConstantInt>(GV->getInitializer())) {
        return static_cast<uint32_t>(CI->getZExtValue());
      }
    }
    return std::nullopt;
  };

  std::optional<uint32_t> gxC = getConstInitI32(GV_grid_x);
  std::optional<uint32_t> gyC = getConstInitI32(GV_grid_y);

  uint64_t NumCTAConst = 0;
  if (gxC && gyC) {
    NumCTAConst = static_cast<uint64_t>(*gxC) * static_cast<uint64_t>(*gyC);
  }

  // (fallback)
  uint64_t Fallback = decideNumCTAsByBench(*M);
  uint64_t NumCTAForType = NumCTAConst ? NumCTAConst : Fallback;
  printf("mem_share2global_sche_2");
  std::cout << "[mem_share2global_sche_2] NumCTA = "
             << (NumCTAConst ? "from const grid_size" : "from bench switch")
             << " : " << NumCTAForType << "\n";

  if (!NumCTAConst) {
    std::cout << "[mem_share2global_sche_2] grid_size_{x,y} are not compile-time constants. "
              "Declaring global type size as " << NumCTAForType
           << " and computing indexing at runtime.\n";
  } else {
    std::cout << "[mem_share2global_sche_2] NumCTA = grid_size_x * grid_size_y = "
           << NumCTAForType << "\n";
  }

  // 1) Find globals in addrspace(3) (shared)
  SmallVector<GlobalVariable*, 8> SharedGVs;
  for (auto &G : M->globals()) {
    // Judge by GV’s address space (not type’s AS)
    if (G.getAddressSpace() == 3) {
      SharedGVs.push_back(&G);
    }
  }

  DenseMap<GlobalVariable*, GlobalVariable*> MapToSlicedGlobal;

  // 2) Create per-CTA slice globals in AS=1
  auto createNoTLSGlobal = [&](Type *Ty, StringRef Name) -> GlobalVariable* {
    // Cleanly recreate if a global with the same name exists
    if (auto *Old = M->getGlobalVariable(Name, /*AllowInternal*/true)) {
      Old->dropAllReferences();
      Old->eraseFromParent();
    }
    auto *Init = isa<ArrayType>(Ty) ? (Constant*)ConstantAggregateZero::get(Ty)
                                    : (Constant*)Constant::getNullValue(Ty);
    auto *GV = new GlobalVariable(
        *M, Ty, /*isConst=*/false,
        GlobalValue::ExternalLinkage, Init, Name,
        /*InsertBefore=*/nullptr,
        GlobalValue::NotThreadLocal, /*AddressSpace=*/1);
    GV->setThreadLocal(false);
    GV->setThreadLocalMode(GlobalVariable::NotThreadLocal);
    return GV;
  };

  // Maximum bytes allocated for dynamic shared (adjust if needed)
  const uint64_t MaxDynBytes = 64 * 1024;

  for (auto *SM : SharedGVs) {
    Type *ElemTy = SM->getValueType(); // LLVM18+: type of the GV’s "value" (what the pointer points to)
    GlobalVariable *NewGV = nullptr;

    if (auto *ArrTy = dyn_cast<ArrayType>(ElemTy)) {
      // [N x T] → [NumCTAForType x N x T]
      if (SM->hasExternalLinkage() && ArrTy->getNumElements() == 0) {
        // extern __shared__ [] : [NumCTA x MaxDynBytes] i8
        auto *DynTy = ArrayType::get(ArrayType::get(I8, MaxDynBytes), NumCTAForType);
        NewGV = createNoTLSGlobal(DynTy, "wrapper_global_dynbuf");
      } else {
        auto *SlicedTy = ArrayType::get(ArrTy, NumCTAForType);
        NewGV = createNoTLSGlobal(SlicedTy, "wrapper_global_" + SM->getName().str());
      }
    } else if (ElemTy->isIntegerTy() || ElemTy->isFloatTy() || isa<PointerType>(ElemTy)) {
      // Scalar shared → [NumCTA x Elem]
      auto *SlicedTy = ArrayType::get(ElemTy, NumCTAForType);
      NewGV = createNoTLSGlobal(SlicedTy, "wrapper_global_" + SM->getName().str());
    } else {
      errs() << "[mem_share2global_sche_2] Unsupported shared type: " << *ElemTy << "\n";
      report_fatal_error("Unsupported shared memory element type");
    }

    MapToSlicedGlobal[SM] = NewGV;
  }

  // 3) Utilities for rewriting uses

  // (a) To load TLS globals (block_index_x/y), call llvm.threadlocal.address.p0
  auto getTLSLoadI32 = [&](IRBuilder<> &B, const char *Name) -> Value* {
    auto *GV = M->getGlobalVariable(Name, /*AllowInternal*/true);
    if (!GV) {
      errs() << "[mem_share2global_sche_2] missing TLS global: " << Name << "\n";
      report_fatal_error("missing TLS global");
    }
    // declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull)
    FunctionCallee tla = M->getOrInsertFunction(
        "llvm.threadlocal.address.p0",
        FunctionType::get(PointerType::get(C, /*AS=*/0),
                          { PointerType::get(C, /*AS=*/0) }, false));
    Value *tls_ptr = B.CreateCall(tla, {GV}, Twine(Name) + Twine("_tlsaddr"));
    return B.CreateLoad(I32, tls_ptr, Name);
  };

  // (b) grid_size_x is a non-TLS global, so just load directly
  auto getGridLoadI32 = [&](IRBuilder<> &B, const char *Name) -> Value* {
    auto *GV = M->getGlobalVariable(Name, /*AllowInternal*/true);
    if (!GV) {
      errs() << "[mem_share2global_sche_2] missing global: " << Name << "\n";
      report_fatal_error("missing global");
    }
    return B.CreateLoad(I32, GV, Name);
  };

  // (c) Expand ConstantExpr users safely into instructions
  auto expandIfConstExpr = [&](User *U, Instruction *InsertBefore) -> Instruction* {
    if (auto *CE = dyn_cast<ConstantExpr>(U)) {
      Instruction *I = CE->getAsInstruction();
      I->insertBefore(InsertBefore);
      U->replaceAllUsesWith(I);
      return I;
    }
    return dyn_cast<Instruction>(U);
  };

  // 4) Rewrite all uses of each shared global to per-CTA bases
  SmallVector<GlobalVariable*, 8> ToErase;
  for (auto &kv : MapToSlicedGlobal) {
    GlobalVariable *SM  = kv.first;   // original shared
    GlobalVariable *New = kv.second;  // [NumCTA x ...] global

    SmallVector<User*, 32> Users(SM->user_begin(), SM->user_end());

    for (User *U : Users) {
      Instruction *SiteI = nullptr;
      if (auto *I = dyn_cast<Instruction>(U)) {
        SiteI = I;
      } else if (auto *CE = dyn_cast<ConstantExpr>(U)) {
        // Expand CE → Instruction
        Instruction *FirstUserI = nullptr;
        for (User *UU : CE->users()) if (auto *II = dyn_cast<Instruction>(UU)) { FirstUserI = II; break; }
        if (!FirstUserI) continue;
        SiteI = expandIfConstExpr(U, FirstUserI);
        if (!SiteI) continue;
      } else {
        // Skip constant initializers, etc.
        continue;
      }

      IRBuilder<> B(SiteI);

      // (1) cta_linear = block_index_x + block_index_y * grid_size_x
      //     - block_index_{x,y} are TLS
      //     - grid_size_x is global
      Value *bx = getTLSLoadI32(B, "block_index_x");
      Value *by = getTLSLoadI32(B, "block_index_y");
      Value *gx = getGridLoadI32(B, "grid_size_x");
      Value *t0 = B.CreateMul(by, gx);
      Value *cta32 = B.CreateAdd(t0, bx);
      Value *cta64 = B.CreateZExt(cta32, I64);

      // (2) New : [NumCTA x X], so get GEP to per-CTA base
      //     %cta_base = getelementptr New, {0, cta}
      Value *ctaBase = B.CreateInBoundsGEP(
          New->getValueType(), New, { ConstantInt::get(I64, 0), cta64 });

      // (3) If original use was a GEP, append its indices; else use pointer cast
      if (auto *GEP = dyn_cast<GetElementPtrInst>(SiteI)) {
        SmallVector<Value*, 8> NewIdx;
        // New is [NumCTA x X], so start with {0, cta, ...}
        NewIdx.push_back(ConstantInt::get(I64, 0));
        NewIdx.push_back(cta64);
        for (Value *Idx : GEP->indices()) NewIdx.push_back(Idx);

        Value *NewPtr = B.CreateInBoundsGEP(New->getValueType(), New, NewIdx);
        GEP->replaceAllUsesWith(NewPtr);
        GEP->eraseFromParent();
        continue;
      }

      // (4) For other uses (load/store/bitcast/phi, etc.): replace SM with per-CTA base
      //     Cast pointer if type/address space differ
      Value *TypedBase = ctaBase;
      Type  *WantPtrTy = SM->getType(); // original shared pointer type (including AS)
      if (TypedBase->getType() != WantPtrTy) {
        TypedBase = B.CreatePointerCast(TypedBase, WantPtrTy);
      }
      SiteI->replaceUsesOfWith(SM, TypedBase);
    }

    ToErase.push_back(SM);
  }

  // 5) Delete original shared globals
  for (auto *G : ToErase) {
    if (!G->use_empty()) {
      errs() << "[mem_share2global_sche_2] still used (BUG): " << G->getName() << "\n";
    }
    G->dropAllReferences();
    G->eraseFromParent();
  }

  // 6) Debugging output
  errs() << "[mem_share2global_sche_2] converted " << MapToSlicedGlobal.size()
         << " shared globals; Declared per-CTA slices = " << NumCTAForType << "\n";
}


// ---- helper: break ConstantExpr uses into Instructions ----
static void breakConstantExprUses(llvm::Value *V, llvm::Function *F) {
  using namespace llvm;
  SmallVector<User*, 8> Users(V->users().begin(), V->users().end());
  for (User *U : Users) {
    if (auto *CE = dyn_cast<ConstantExpr>(U)) {
      breakConstantExprUses(CE, F);
      Instruction *I = CE->getAsInstruction();
      I->insertBefore(&*F->begin()->begin());
      CE->replaceAllUsesWith(I);
      CE->destroyConstant();
    }
  }
}

void mem_share2local(llvm::Module *M) {
  using namespace llvm;

  LLVMContext &C = M->getContext();
  const DataLayout &DL = M->getDataLayout();

  auto *I32   = Type::getInt32Ty(C);
  auto *I8    = Type::getInt8Ty(C);
  auto *I1    = Type::getInt1Ty(C);
  auto *I8Ptr = PointerType::get(I8, 0);

  // runtime hooks
  FunctionCallee vxAlloc = M->getOrInsertFunction(
      "vx_local_alloc", FunctionType::get(I8Ptr, {I32}, false));
  FunctionCallee vxBarrier = M->getOrInsertFunction(
      "vx_barrier", FunctionType::get(Type::getVoidTy(C), {I32, I32}, false));

  // TLS
  GlobalVariable *LocalGroupIdGV = M->getGlobalVariable("__local_group_id");
  assert(LocalGroupIdGV && "missing __local_group_id");
  GlobalVariable *TidXGV = M->getGlobalVariable("thread_id_x");
  GlobalVariable *TidYGV = M->getGlobalVariable("thread_id_y");

  // non-TLS
  GlobalVariable *WarpsPerGroupGV = M->getGlobalVariable("__warps_per_group");

  // dynamic shared total bytes (optional)
  GlobalVariable *DynSizeGV = M->getGlobalVariable("dyn_shared_mem_size");

  auto isSharedAS = [](const GlobalVariable* GV) {
    return GV->getType()->getAddressSpace() == 3;
  };
  auto isDynamicMarker = [&](const GlobalVariable* GV) {
    if (!isSharedAS(GV)) return false;
    if (GV->hasInitializer()) return false;   // treat extern only as dynamic marker
    if (auto *AT = dyn_cast<ArrayType>(GV->getValueType()))
      return AT->getNumElements() == 0;       // [0 x T]
    return false;
  };

  // collect AS3 globals in the module
  SmallVector<GlobalVariable*, 16> allShared;
  for (auto &GV : M->globals())
    if (isSharedAS(&GV)) allShared.push_back(&GV);
  if (allShared.empty()) return;

  // TLS intrinsic decl
  auto tlsAddr = [&](GlobalVariable *GV) -> FunctionCallee {
    return Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address, {GV->getType()});
  };

  for (Function &F : *M) {
    if (F.isDeclaration()) continue;

    // For this function, pick only AS3 globals actually used (also break CE uses)
    SmallVector<GlobalVariable*, 8> usedStatic, usedDynamic;
    for (auto *GV : allShared) {
      breakConstantExprUses(GV, &F);
      bool used = false;
      for (User *U : GV->users()) {
        if (auto *I = dyn_cast<Instruction>(U))
          if (I->getFunction() == &F) { used = true; break; }
      }
      if (!used) continue;
      if (isDynamicMarker(GV)) usedDynamic.push_back(GV);
      else                     usedStatic .push_back(GV);
    }
    if (usedStatic.empty() && usedDynamic.empty()) continue;

    // --- 0) In the entry block, find the "first vx_barrier" call
    BasicBlock *EntryBB = &F.getEntryBlock();
    CallInst *FirstBarrier = nullptr;
    for (Instruction &I : *EntryBB) {
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (Function *Callee = CI->getCalledFunction()) {
          if (Callee->getName() == "vx_barrier") { FirstBarrier = CI; break; }
        }
      }
    }

    // If there is no first barrier: handle immediately in entry (do NOT add group_off)
    if (!FirstBarrier) {
      IRBuilder<> B(&*EntryBB->getFirstInsertionPt());

      // static layout
      struct Item { GlobalVariable* GV; uint32_t off; };
      SmallVector<Item, 8> layout;
      uint32_t staticBytes = 0;
      for (auto *GV : usedStatic) {
        Type *Ty = GV->getValueType();
        uint64_t a = DL.getABITypeAlign(Ty).value();
        staticBytes = alignTo(staticBytes, a);
        layout.push_back({GV, staticBytes});
        staticBytes += DL.getTypeAllocSize(Ty);
      }

      // required alignment for dynamic region
      uint64_t dynAlign = 1;
      for (auto *GV : usedDynamic) {
        auto *AT = cast<ArrayType>(GV->getValueType());
        dynAlign = std::max<uint64_t>(dynAlign, DL.getABITypeAlign(AT->getElementType()).value());
      }
      uint32_t staticAligned = alignTo(staticBytes, dynAlign);

      Value *dynBytes = ConstantInt::get(I32, 0);
      if (!usedDynamic.empty() && DynSizeGV)
        dynBytes = B.CreateLoad(I32, DynSizeGV, "dyn_bytes");

      Value *stride = B.CreateAdd(ConstantInt::get(I32, staticAligned), dynBytes, "total_stride");

      // base_group = vx_local_alloc(stride)  // ★ internally already applies gid*stride
      Value *bgrp = B.CreateCall(vxAlloc, {stride}, "__local_group_i8");

      // replace statics
      DenseMap<GlobalVariable*, Value*> repl;
      for (auto &it : layout) {
        auto *GV = it.GV;
        Value *p = B.CreateGEP(I8, bgrp, ConstantInt::get(I32, it.off), GV->getName()+".i8");
        Value *t = B.CreatePointerCast(p, PointerType::get(GV->getValueType(), GV->getType()->getAddressSpace()),
                                       GV->getName()+".ptr");
        repl[GV] = t;
      }
      // replace dynamics
      if (!usedDynamic.empty()) {
        Value *dynBase = B.CreateGEP(I8, bgrp, ConstantInt::get(I32, staticAligned), "dyn_base_i8");
        for (auto *GV : usedDynamic) {
          Value *t = B.CreatePointerCast(dynBase, GV->getType(), GV->getName()+".dynptr");
          repl[GV] = t;
        }
      }

      auto replaceUsesInFunc = [&](GlobalVariable *GV, Value *NewV) {
        SmallVector<Use*, 16> toFix;
        for (Use &U : GV->uses())
          if (auto *I = dyn_cast<Instruction>(U.getUser()))
            if (I->getFunction() == &F) toFix.push_back(&U);
        for (auto *U : toFix) U->set(NewV);
      };
      for (auto *GV : usedStatic)  replaceUsesInFunc(GV, repl[GV]);
      for (auto *GV : usedDynamic) replaceUsesInFunc(GV, repl[GV]);
      continue;
    }

    // --- 1) Split at the first barrier: [Pre] -> [WithBarrier (barrier is first inst)]
    BasicBlock *WithBarrierBB = EntryBB->splitBasicBlock(FirstBarrier, "with.barrier");
    // Remove EntryBB's unconditional br terminator and insert leader branch
    EntryBB->getTerminator()->eraseFromParent();

    // Block for leader-only allocation + fall-through block
    BasicBlock *AllocBB = BasicBlock::Create(C, "share.alloc.once", &F);
    IRBuilder<> IB_Alloc(AllocBB);
    BasicBlock *ContToBarrierBB = WithBarrierBB;

    // In Entry, determine leader and branch
    IRBuilder<> IB_Entry(EntryBB);
    auto mkIsZero = [&](GlobalVariable *GV, const char *nm) -> Value* {
      if (!GV) return ConstantInt::get(I1, 1); // if that axis does not exist, assume zero
      Value *p = IB_Entry.CreateCall(tlsAddr(GV), {GV});
      Value *v = IB_Entry.CreateLoad(I32, p, nm);
      return IB_Entry.CreateICmpEQ(v, ConstantInt::get(I32, 0));
    };
    Value *is_x0 = mkIsZero(TidXGV, "tid.x");
    Value *is_y0 = mkIsZero(TidYGV, "tid.y");
    Value *is_leader = IB_Entry.CreateAnd(is_x0, is_y0);
    IB_Entry.CreateCondBr(is_leader, AllocBB, ContToBarrierBB);

    // Per-function shared base global (AS3 global; payload type is i8* in AS0)
    std::string baseName = "__vx_shared_base_" + F.getName().str();
    GlobalVariable *SharedBaseGV = M->getGlobalVariable(baseName);
    if (!SharedBaseGV) {
      SharedBaseGV = new GlobalVariable(
          *M, I8Ptr, /*isConst*/false, GlobalValue::ExternalLinkage,
          ConstantPointerNull::get(I8Ptr), baseName, nullptr,
          GlobalValue::NotThreadLocal, /*AddressSpace=*/3);
    }

    // --- 2) AllocBB: compute static/dynamic sizes → single allocation → store to global
    struct Item { GlobalVariable* GV; uint32_t off; };
    SmallVector<Item, 8> layout;
    uint32_t staticBytes = 0;
    for (auto *GV : usedStatic) {
      Type *Ty = GV->getValueType();
      uint64_t a = DL.getABITypeAlign(Ty).value();
      staticBytes = alignTo(staticBytes, a);
      layout.push_back({GV, staticBytes});
      staticBytes += DL.getTypeAllocSize(Ty);
    }

    uint64_t dynAlign = 1;
    for (auto *GV : usedDynamic) {
      auto *AT = cast<ArrayType>(GV->getValueType());
      dynAlign = std::max<uint64_t>(dynAlign, DL.getABITypeAlign(AT->getElementType()).value());
    }
    uint32_t staticAligned = alignTo(staticBytes, dynAlign);

    Value *dynBytes = ConstantInt::get(I32, 0);
    if (!usedDynamic.empty() && DynSizeGV)
      dynBytes = IB_Alloc.CreateLoad(I32, DynSizeGV, "dyn_bytes");

    Value *stride = IB_Alloc.CreateAdd(ConstantInt::get(I32, staticAligned), dynBytes, "total_stride");

    // base_group = vx_local_alloc(stride)  // ★ internally already applies gid*stride
    Value *bgrp = IB_Alloc.CreateCall(vxAlloc, {stride}, "__local_group_i8");
    IB_Alloc.CreateStore(bgrp, SharedBaseGV);
    IB_Alloc.CreateBr(ContToBarrierBB);

    // --- 3) Right after the barrier, insert pointer loads/casts
    Instruction *AfterBarrierInst = WithBarrierBB->getFirstNonPHI()->getNextNode();
    BasicBlock *AfterBarrierBB =
        WithBarrierBB->splitBasicBlock(AfterBarrierInst, "after.barrier");

    IRBuilder<> IB_After(&*AfterBarrierBB->getFirstInsertionPt());

    // load base
    Value *bgrp_all = IB_After.CreateLoad(SharedBaseGV->getValueType(), SharedBaseGV, "base_group");

    DenseMap<GlobalVariable*, Value*> repl;

    // create replacement pointers for statics
    for (auto &it : layout) {
      auto *GV = it.GV;
      Value *pi8 = IB_After.CreateGEP(I8, bgrp_all, ConstantInt::get(I32, it.off), GV->getName()+".i8");
      Value *tp  = IB_After.CreatePointerCast(
                      pi8,
                      PointerType::get(GV->getValueType(), GV->getType()->getAddressSpace()),
                      GV->getName()+".ptr");
      repl[GV] = tp;
    }
    // create replacement pointer(s) for dynamic region (base + staticAligned → [0 x T]*)
    if (!usedDynamic.empty()) {
      Value *dynBase = IB_After.CreateGEP(I8, bgrp_all, ConstantInt::get(I32, staticAligned), "dyn_base_i8");
      for (auto *GV : usedDynamic) {
        Value *tp = IB_After.CreatePointerCast(dynBase, GV->getType(), GV->getName()+".dynptr");
        repl[GV] = tp;
      }
    }

    auto replaceUsesInFunc = [&](GlobalVariable *GV, Value *NewV) {
      SmallVector<Use*, 16> toFix;
      for (Use &U : GV->uses())
        if (auto *I = dyn_cast<Instruction>(U.getUser()))
          if (I->getFunction() == &F) toFix.push_back(&U);
      for (auto *U : toFix) U->set(NewV);
    };
    for (auto *GV : usedStatic)  replaceUsesInFunc(GV, repl[GV]);
    for (auto *GV : usedDynamic) replaceUsesInFunc(GV, repl[GV]);
  }

  // remove now-unused AS3 globals
  SmallVector<GlobalVariable*, 16> toErase;
  for (auto &GV : M->globals()) {
    if (GV.getType()->getAddressSpace() != 3) continue;
    if (GV.use_empty()) toErase.push_back(&GV);
  }
  for (auto *GV : toErase) GV->eraseFromParent();
}

void mem_constant2global(llvm::Module *M, std::ofstream &fout) {
  LLVMContext *C = &M->getContext();
  llvm::Type *Int32T = Type::getInt32Ty(*C);
  llvm::Type *Int64T = Type::getInt64Ty(*C);
  llvm::Type *Int8T = Type::getInt8Ty(*C);

  std::map<GlobalVariable *, GlobalVariable *> corresponding_global_memory;
  std::set<llvm::Instruction *> need_remove;
  std::set<GlobalVariable *> need_remove_constant_memory;


  // find all constant memory and generate corresponding global memory
  for (auto I = M->global_begin(), E = M->global_end(); I != E; ++I) {
    if (GlobalVariable *constant_memory = dyn_cast<GlobalVariable>(I)) {
      if (auto PT = dyn_cast<PointerType>(I->getType())) {
        unsigned AS = PT->getAddressSpace();
        if (AS == 4) { // find a constant memory
          need_remove_constant_memory.insert(constant_memory);
          // generate the corresponding global memory variable
          auto new_name = "wrapper_global_" + constant_memory->getName().str();
          // printf new_name
          std::cout <<"(debug) const mem, "<< new_name<< std::endl;

          //LLVM 18
          //auto element_type = PT->getElementType();
          auto element_type = constant_memory->getValueType();
          
          if (auto array_type = dyn_cast<ArrayType>(element_type)) {
            if (constant_memory->hasExternalLinkage() &&
                array_type->getArrayNumElements() == 0) {
                  std::cout << "(debug) const mem case 1"<< std::endl;
     
              // external shared memory of []
              // generate global type pointer
              PointerType *PointerTy =
                  PointerType::get(array_type->getElementType(), 0);
              llvm::Constant *x1 = ConstantPointerNull::get(PointerTy);
              llvm::GlobalVariable *global_ptr = new llvm::GlobalVariable(
                  *M, PointerTy, false, llvm::GlobalValue::ExternalLinkage, x1,
                  "wrapper_global_data", NULL,
                  llvm::GlobalValue::NotThreadLocal, 0, true);

              corresponding_global_memory.insert(
                  std::pair<GlobalVariable *, GlobalVariable *>(constant_memory,
                                                                global_ptr));
            } else {
              std::cout << "(debug) const mem case 2"<< constant_memory->hasExternalLinkage() << " " << array_type->getArrayNumElements() <<std::endl;

              Type *elementType = array_type->getElementType();
              uint64_t numElements = array_type->getArrayNumElements();
              elementType->print(llvm::outs(), true);
              //print the type of the elementType

              llvm::GlobalVariable *global_memory = new llvm::GlobalVariable(
                  *M, array_type, false, llvm::GlobalValue::ExternalLinkage,
                  constant_memory->getInitializer(), new_name, NULL, llvm::GlobalValue::NotThreadLocal, 0);
              corresponding_global_memory.insert(
                  std::pair<GlobalVariable *, GlobalVariable *>(constant_memory,
                                                                global_memory));                                            
            }
          }
          else if (element_type->isStructTy() || element_type->isIntegerTy() || element_type->isFloatTy() || element_type->isDoubleTy() || element_type->isPointerTy()) {
            // TODO:  need to implement structure type definition for kernel wrapper
            std::cout << "(debug) const mem case 3"<< std::endl;

            llvm::GlobalVariable *global_memory = new llvm::GlobalVariable(
                *M, element_type, false, llvm::GlobalValue::ExternalLinkage,
                constant_memory->getInitializer(), new_name, NULL, llvm::GlobalValue::NotThreadLocal, 0);
            corresponding_global_memory.insert(
                std::pair<GlobalVariable *, GlobalVariable *>(constant_memory,
                                                              global_memory));
          }
          else {
            assert(0 && "The required Constant Memory Type is not supported\n");
          }
        }
      }
    }
  }
  fout << "ConstMemory2GlobalMemory\n";
  for (auto k : corresponding_global_memory) {
    auto const_addr = k.first;
    auto global_addr = k.second;
    const_addr->replaceAllUsesWith(ConstantExpr::getPointerCast(
        global_addr, cast<PointerType>(const_addr->getType())));
    // this file will be used by host translator
    fout << const_addr->getName().str().c_str() << " to "
         << global_addr->getName().str().c_str() << std::endl;
  }
  fout << "END\n";

  for (auto i : need_remove) {
    i->dropAllReferences();
    i->eraseFromParent();
  }
  for (auto i : need_remove_constant_memory) {
    i->dropAllReferences();
    i->eraseFromParent();
  }
}
