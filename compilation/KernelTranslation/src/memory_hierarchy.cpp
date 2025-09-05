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

// 상수식(ConstantExpr)으로 남아있는 GEP/bitcast 등을 Instruction으로 바꿔서
// 실제 IR 안에서 replaceAllUsesWith가 정상적으로 먹히도록 해줌.
// static void breakConstantExprUses(Value *V, Function *F) {
//   std::vector<User*> users(V->user_begin(), V->user_end());
//   for (User *U : users) {
//     if (auto *CE = dyn_cast<ConstantExpr>(U)) {
//       // 재귀적으로 내부 operand의 const expr도 먼저 깨줌
//       breakConstantExprUses(CE, F);

//       Instruction *I = CE->getAsInstruction();
//       // 함수의 entry에 삽입 (혹은 F 내부 첫 basic block의 첫 부분)
//       I->insertBefore(&*F->getEntryBlock().getFirstInsertionPt());
//       CE->replaceAllUsesWith(I);
//       CE->destroyConstant();
//     }
//   }
// }

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

// ---- helper: ConstantExpr uses -> Instruction로 깨기 ----
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
    if (GV->hasInitializer()) return false;   // extern만 dynamic marker로 취급
    if (auto *AT = dyn_cast<ArrayType>(GV->getValueType()))
      return AT->getNumElements() == 0;       // [0 x T]
    return false;
  };

  // 모듈 내 AS3 전역 수집
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

    // 이 함수에서 실제 쓰는 AS3 전역만 선별 (CE uses 정리 포함)
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

    // --- 0) 엔트리에서 "첫 vx_barrier 호출"을 찾는다
    BasicBlock *EntryBB = &F.getEntryBlock();
    CallInst *FirstBarrier = nullptr;
    for (Instruction &I : *EntryBB) {
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (Function *Callee = CI->getCalledFunction()) {
          if (Callee->getName() == "vx_barrier") { FirstBarrier = CI; break; }
        }
      }
    }
 
    // 첫 배리어가 없으면: 엔트리에서 바로 처리 (group_off 추가 금지!)
    if (!FirstBarrier) {
      IRBuilder<> B(&*EntryBB->getFirstInsertionPt());

      // 정적 레이아웃
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

      // 동적 정렬 요구치
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

      // base_group = vx_local_alloc(stride)  // ★ 내부가 이미 gid*stride 적용
      Value *bgrp = B.CreateCall(vxAlloc, {stride}, "__local_group_i8");

      // 정적 치환
      DenseMap<GlobalVariable*, Value*> repl;
      for (auto &it : layout) {
        auto *GV = it.GV;
        Value *p = B.CreateGEP(I8, bgrp, ConstantInt::get(I32, it.off), GV->getName()+".i8");
        Value *t = B.CreatePointerCast(p, PointerType::get(GV->getValueType(), GV->getType()->getAddressSpace()),
                                       GV->getName()+".ptr");
        repl[GV] = t;
      }
      // 동적 치환
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

    // --- 1) 첫 배리어 위치에서 블록 split: [Pre] -> [WithBarrier(=배리어가 첫 inst)]
    BasicBlock *WithBarrierBB = EntryBB->splitBasicBlock(FirstBarrier, "with.barrier");
    // EntryBB 말미의 unconditional br 제거 후, 리더 분기 삽입
    EntryBB->getTerminator()->eraseFromParent();

    // 리더만 1회 할당할 블록 + 바로 통과 블록
    BasicBlock *AllocBB = BasicBlock::Create(C, "share.alloc.once", &F);
    IRBuilder<> IB_Alloc(AllocBB);
    BasicBlock *ContToBarrierBB = WithBarrierBB;

    // Entry에서 리더 판정 후 분기
    IRBuilder<> IB_Entry(EntryBB);
    auto mkIsZero = [&](GlobalVariable *GV, const char *nm) -> Value* {
      if (!GV) return ConstantInt::get(I1, 1); // 해당 축이 없으면 '0으로 가정'
      Value *p = IB_Entry.CreateCall(tlsAddr(GV), {GV});
      Value *v = IB_Entry.CreateLoad(I32, p, nm);
      return IB_Entry.CreateICmpEQ(v, ConstantInt::get(I32, 0));
    };
    Value *is_x0 = mkIsZero(TidXGV, "tid.x");
    Value *is_y0 = mkIsZero(TidYGV, "tid.y");
    Value *is_leader = IB_Entry.CreateAnd(is_x0, is_y0);
    IB_Entry.CreateCondBr(is_leader, AllocBB, ContToBarrierBB);

    // 함수별 공유 베이스 저장 전역(AS3 전역, 내용 타입은 i8* AS0)
    std::string baseName = "__vx_shared_base_" + F.getName().str();
    GlobalVariable *SharedBaseGV = M->getGlobalVariable(baseName);
    if (!SharedBaseGV) {
      SharedBaseGV = new GlobalVariable(
          *M, I8Ptr, /*isConst*/false, GlobalValue::ExternalLinkage,
          ConstantPointerNull::get(I8Ptr), baseName, nullptr,
          GlobalValue::NotThreadLocal, /*AddressSpace=*/3);
    }

    // --- 2) AllocBB: 정적/동적 사이즈 계산 → 1회 할당 → 전역 저장
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

    // base_group = vx_local_alloc(stride)  // ★ 내부가 이미 gid*stride 적용
    Value *bgrp = IB_Alloc.CreateCall(vxAlloc, {stride}, "__local_group_i8");
    IB_Alloc.CreateStore(bgrp, SharedBaseGV);
    IB_Alloc.CreateBr(ContToBarrierBB);

    // --- 3) 배리어 직후 포인터 로드/캐스트 삽입
    Instruction *AfterBarrierInst = WithBarrierBB->getFirstNonPHI()->getNextNode();
    BasicBlock *AfterBarrierBB =
        WithBarrierBB->splitBasicBlock(AfterBarrierInst, "after.barrier");

    IRBuilder<> IB_After(&*AfterBarrierBB->getFirstInsertionPt());

    // 베이스 로드
    Value *bgrp_all = IB_After.CreateLoad(SharedBaseGV->getValueType(), SharedBaseGV, "base_group");

    DenseMap<GlobalVariable*, Value*> repl;

    // 정적 치환 포인터들 생성
    for (auto &it : layout) {
      auto *GV = it.GV;
      Value *pi8 = IB_After.CreateGEP(I8, bgrp_all, ConstantInt::get(I32, it.off), GV->getName()+".i8");
      Value *tp  = IB_After.CreatePointerCast(
                      pi8,
                      PointerType::get(GV->getValueType(), GV->getType()->getAddressSpace()),
                      GV->getName()+".ptr");
      repl[GV] = tp;
    }
    // 동적 치환 포인터 생성 (base + staticAligned → [0 x T]*)
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

  // 더 이상 쓰지 않는 AS3 전역 제거
  SmallVector<GlobalVariable*, 16> toErase;
  for (auto &GV : M->globals()) {
    if (GV.getType()->getAddressSpace() != 3) continue;
    if (GV.use_empty()) toErase.push_back(&GV);
  }
  for (auto *GV : toErase) GV->eraseFromParent();
}

// // ---- helper: ConstantExpr uses -> Instruction로 깨기 ----
// static void breakConstantExprUses(llvm::Value *V, llvm::Function *F) {
//   using namespace llvm;
//   SmallVector<User*, 8> Users(V->users().begin(), V->users().end());
//   for (User *U : Users) {
//     if (auto *CE = dyn_cast<ConstantExpr>(U)) {
//       breakConstantExprUses(CE, F);
//       Instruction *I = CE->getAsInstruction();
//       I->insertBefore(&*F->begin()->begin());
//       CE->replaceAllUsesWith(I);
//       CE->destroyConstant();
//     }
//   }
// }

// void mem_share2local(llvm::Module *M) {
//   using namespace llvm;

//   LLVMContext &C = M->getContext();
//   const DataLayout &DL = M->getDataLayout();

//   auto *I32   = Type::getInt32Ty(C);
//   auto *I8    = Type::getInt8Ty(C);
//   auto *I1    = Type::getInt1Ty(C);
//   auto *I8Ptr = PointerType::get(I8, 0);

//   // runtime hooks
//   FunctionCallee vxAlloc = M->getOrInsertFunction(
//       "vx_local_alloc", FunctionType::get(I8Ptr, {I32}, false));
//   FunctionCallee vxBarrier = M->getOrInsertFunction(
//       "vx_barrier", FunctionType::get(Type::getVoidTy(C), {I32, I32}, false));

//   // TLS
//   GlobalVariable *LocalGroupIdGV = M->getGlobalVariable("__local_group_id");
//   assert(LocalGroupIdGV && "missing __local_group_id");
//   GlobalVariable *TidXGV = M->getGlobalVariable("thread_id_x");
//   GlobalVariable *TidYGV = M->getGlobalVariable("thread_id_y");

//   // non-TLS
//   GlobalVariable *WarpsPerGroupGV = M->getGlobalVariable("__warps_per_group");

//   // dynamic shared total bytes (optional)
//   GlobalVariable *DynSizeGV = M->getGlobalVariable("dyn_shared_mem_size");

//   auto isSharedAS = [](const GlobalVariable* GV) {
//     return GV->getType()->getAddressSpace() == 3;
//   };
//   auto isDynamicMarker = [&](const GlobalVariable* GV) {
//     if (!isSharedAS(GV)) return false;
//     if (GV->hasInitializer()) return false;   // extern만 dynamic marker로 취급
//     if (auto *AT = dyn_cast<ArrayType>(GV->getValueType()))
//       return AT->getNumElements() == 0;       // [0 x T]
//     return false;
//   };

//   // 모듈 내 AS3 전역 수집
//   SmallVector<GlobalVariable*, 16> allShared;
//   for (auto &GV : M->globals())
//     if (isSharedAS(&GV)) allShared.push_back(&GV);
//   if (allShared.empty()) return;

//   // TLS intrinsic decl
//   auto tlsAddr = [&](GlobalVariable *GV) -> FunctionCallee {
//     return Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address, {GV->getType()});
//   };

//   for (Function &F : *M) {
//     if (F.isDeclaration()) continue;

//     // 이 함수에서 실제 쓰는 AS3 전역만 선별 (CE uses 정리 포함)
//     SmallVector<GlobalVariable*, 8> usedStatic, usedDynamic;
//     for (auto *GV : allShared) {
//       breakConstantExprUses(GV, &F);
//       bool used = false;
//       for (User *U : GV->users()) {
//         if (auto *I = dyn_cast<Instruction>(U))
//           if (I->getFunction() == &F) { used = true; break; }
//       }
//       if (!used) continue;
//       if (isDynamicMarker(GV)) usedDynamic.push_back(GV);
//       else                     usedStatic .push_back(GV);
//     }
//     if (usedStatic.empty() && usedDynamic.empty()) continue;

//     // --- 0) 엔트리에서 "첫 vx_barrier 호출"을 찾는다
//     BasicBlock *EntryBB = &F.getEntryBlock();
//     CallInst *FirstBarrier = nullptr;
//     for (Instruction &I : *EntryBB) {
//       if (auto *CI = dyn_cast<CallInst>(&I)) {
//         if (Function *Callee = CI->getCalledFunction()) {
//           if (Callee->getName() == "vx_barrier") { FirstBarrier = CI; break; }
//         }
//       }
//     }

//     // 첫 배리어가 없으면, 기존 방식(엔트리 첫 삽입점)으로 하되 배리어 추가는 하지 않음.
//     // 대부분 커널(네가 올린 IR들)은 엔트리 직후 배리어가 있으니, 우선 그 경로를 사용.
//     if (!FirstBarrier) {
//       // 안전하게: 기존 간단 버전으로만 처리 (warps_per_group==1인 커널에서 동작했던 패턴)
//       IRBuilder<> B(&*EntryBB->getFirstInsertionPt());

//       // 정적 레이아웃
//       struct Item { GlobalVariable* GV; uint32_t off; };
//       SmallVector<Item, 8> layout;
//       uint32_t staticBytes = 0;
//       for (auto *GV : usedStatic) {
//         Type *Ty = GV->getValueType();
//         uint64_t a = DL.getABITypeAlign(Ty).value();
//         staticBytes = alignTo(staticBytes, a);
//         layout.push_back({GV, staticBytes});
//         staticBytes += DL.getTypeAllocSize(Ty);
//       }

//       // 동적 정렬 요구치
//       uint64_t dynAlign = 1;
//       for (auto *GV : usedDynamic) {
//         auto *AT = cast<ArrayType>(GV->getValueType());
//         dynAlign = std::max<uint64_t>(dynAlign, DL.getABITypeAlign(AT->getElementType()).value());
//       }
//       uint32_t staticAligned = alignTo(staticBytes, dynAlign);

//       Value *dynBytes = ConstantInt::get(I32, 0);
//       if (!usedDynamic.empty() && DynSizeGV)
//         dynBytes = B.CreateLoad(I32, DynSizeGV, "dyn_bytes");

//       Value *stride = B.CreateAdd(ConstantInt::get(I32, staticAligned), dynBytes, "total_stride");

//       // base = vx_local_alloc(stride)
//       Value *base = B.CreateCall(vxAlloc, {stride}, "__local_base_i8");

//       // group offset
//       Value *lgp  = B.CreateCall(tlsAddr(LocalGroupIdGV), {LocalGroupIdGV});
//       Value *lgid = B.CreateLoad(I32, lgp, "__local_group_id");
//       Value *goff = B.CreateMul(lgid, stride, "group_off");
//       Value *bgrp = B.CreateGEP(I8, base, goff, "base_group");

//       // 정적 치환
//       DenseMap<GlobalVariable*, Value*> repl;
//       for (auto &it : layout) {
//         auto *GV = it.GV;
//         Value *p = B.CreateGEP(I8, bgrp, ConstantInt::get(I32, it.off), GV->getName()+".i8");
//         Value *t = B.CreatePointerCast(p, PointerType::get(GV->getValueType(), GV->getType()->getAddressSpace()),
//                                        GV->getName()+".ptr");
//         repl[GV] = t;
//       }
//       // 동적 치환
//       if (!usedDynamic.empty()) {
//         Value *dynBase = B.CreateGEP(I8, bgrp, ConstantInt::get(I32, staticAligned), "dyn_base_i8");
//         for (auto *GV : usedDynamic) {
//           Value *t = B.CreatePointerCast(dynBase, GV->getType(), GV->getName()+".dynptr");
//           repl[GV] = t;
//         }
//       }

//       auto replaceUsesInFunc = [&](GlobalVariable *GV, Value *NewV) {
//         SmallVector<Use*, 16> toFix;
//         for (Use &U : GV->uses())
//           if (auto *I = dyn_cast<Instruction>(U.getUser()))
//             if (I->getFunction() == &F) toFix.push_back(&U);
//         for (auto *U : toFix) U->set(NewV);
//       };
//       for (auto *GV : usedStatic)  replaceUsesInFunc(GV, repl[GV]);
//       for (auto *GV : usedDynamic) replaceUsesInFunc(GV, repl[GV]);
//       continue;
//     }

//     // --- 1) 첫 배리어 위치에서 블록 split: [Pre] -> [WithBarrier(=배리어가 첫 inst)]
//     BasicBlock *WithBarrierBB = EntryBB->splitBasicBlock(FirstBarrier, "with.barrier");
//     // EntryBB 말미의 unconditional br를 지우고, 여기에 리더 분기 삽입
//     EntryBB->getTerminator()->eraseFromParent();

//     // 리더만 1회 할당할 블록 + 바로 통과 블록
//     BasicBlock *AllocBB = BasicBlock::Create(C, "share.alloc.once", &F);
//     IRBuilder<> IB_Alloc(AllocBB);
//     BasicBlock *ContToBarrierBB = WithBarrierBB; // 리더든 아니든 결국 여기로

//     // Entry에서 리더 판정 후 분기
//     IRBuilder<> IB_Entry(EntryBB);
//     auto mkIsZero = [&](GlobalVariable *GV, const char *nm) -> Value* {
//       if (!GV) return ConstantInt::get(I1, 1); // 해당 축이 없으면 '0으로 가정'
//       Value *p = IB_Entry.CreateCall(tlsAddr(GV), {GV});
//       Value *v = IB_Entry.CreateLoad(I32, p, nm);
//       return IB_Entry.CreateICmpEQ(v, ConstantInt::get(I32, 0));
//     };
//     Value *is_x0 = mkIsZero(TidXGV, "tid.x");
//     Value *is_y0 = mkIsZero(TidYGV, "tid.y");
//     Value *is_leader = IB_Entry.CreateAnd(is_x0, is_y0);
//     IB_Entry.CreateCondBr(is_leader, AllocBB, ContToBarrierBB);

//     // 함수별 공유 베이스 저장 전역(AS3 전역, 내용 타입은 i8* AS0)
//     std::string baseName = "__vx_shared_base_" + F.getName().str();
//     GlobalVariable *SharedBaseGV = M->getGlobalVariable(baseName);
//     if (!SharedBaseGV) {
//       SharedBaseGV = new GlobalVariable(
//           *M, I8Ptr, /*isConst*/false, GlobalValue::ExternalLinkage,
//           ConstantPointerNull::get(I8Ptr), baseName, nullptr,
//           GlobalValue::NotThreadLocal, /*AddressSpace=*/3);
//     }

//     // --- 2) AllocBB: 정적/동적 사이즈 계산 → 1회 할당 → group offset → 전역 저장
//     struct Item { GlobalVariable* GV; uint32_t off; };
//     SmallVector<Item, 8> layout;
//     uint32_t staticBytes = 0;
//     for (auto *GV : usedStatic) {
//       Type *Ty = GV->getValueType();
//       uint64_t a = DL.getABITypeAlign(Ty).value();
//       staticBytes = alignTo(staticBytes, a);
//       layout.push_back({GV, staticBytes});
//       staticBytes += DL.getTypeAllocSize(Ty);
//     }

//     uint64_t dynAlign = 1;
//     for (auto *GV : usedDynamic) {
//       auto *AT = cast<ArrayType>(GV->getValueType());
//       dynAlign = std::max<uint64_t>(dynAlign, DL.getABITypeAlign(AT->getElementType()).value());
//     }
//     uint32_t staticAligned = alignTo(staticBytes, dynAlign);

//     Value *dynBytes = ConstantInt::get(I32, 0);
//     if (!usedDynamic.empty() && DynSizeGV)
//       dynBytes = IB_Alloc.CreateLoad(I32, DynSizeGV, "dyn_bytes");

//     Value *stride = IB_Alloc.CreateAdd(ConstantInt::get(I32, staticAligned), dynBytes, "total_stride");

//     Value *lgp  = IB_Alloc.CreateCall(tlsAddr(LocalGroupIdGV), {LocalGroupIdGV});
//     Value *lgid = IB_Alloc.CreateLoad(I32, lgp, "__local_group_id");

//     Value *base  = IB_Alloc.CreateCall(vxAlloc, {stride}, "__local_base_i8");
//     Value *goff  = IB_Alloc.CreateMul(lgid, stride, "group_off");
//     Value *bgrp  = IB_Alloc.CreateGEP(I8, base, goff, "base_group");
//     IB_Alloc.CreateStore(bgrp, SharedBaseGV);
//     IB_Alloc.CreateBr(ContToBarrierBB); // 배리어 있는 블록으로

//     // --- 3) 배리어 "직후"에 베이스 로드/캐스트 삽입 위해 또 split
//     // WithBarrierBB의 첫 inst가 barrier니까, 그 다음 inst에서 split
//     Instruction *AfterBarrierInst = WithBarrierBB->getFirstNonPHI()->getNextNode();
//     BasicBlock *AfterBarrierBB =
//         WithBarrierBB->splitBasicBlock(AfterBarrierInst, "after.barrier");

//     // AfterBarrierBB의 시작에 새 IR을 넣고, 거기서 만든 값으로 전체 치환
//     IRBuilder<> IB_After(&*AfterBarrierBB->getFirstInsertionPt());

//     // 배리어 호출 인자 그대로 유지 (추가 배리어 없음)
//     // 베이스 로드
//     Value *bgrp_all = IB_After.CreateLoad(SharedBaseGV->getValueType(), SharedBaseGV, "base_group");

//     DenseMap<GlobalVariable*, Value*> repl;

//     // 정적 치환 포인터들 생성
//     for (auto &it : layout) {
//       auto *GV = it.GV;
//       Value *pi8 = IB_After.CreateGEP(I8, bgrp_all, ConstantInt::get(I32, it.off), GV->getName()+".i8");
//       Value *tp  = IB_After.CreatePointerCast(
//                       pi8,
//                       PointerType::get(GV->getValueType(), GV->getType()->getAddressSpace()),
//                       GV->getName()+".ptr");
//       repl[GV] = tp;
//     }
//     // 동적 치환 포인터 생성 (base + staticAligned → [0 x T]*)
//     if (!usedDynamic.empty()) {
//       Value *dynBase = IB_After.CreateGEP(I8, bgrp_all, ConstantInt::get(I32, staticAligned), "dyn_base_i8");
//       for (auto *GV : usedDynamic) {
//         Value *tp = IB_After.CreatePointerCast(dynBase, GV->getType(), GV->getName()+".dynptr");
//         repl[GV] = tp;
//       }
//     }

//     auto replaceUsesInFunc = [&](GlobalVariable *GV, Value *NewV) {
//       SmallVector<Use*, 16> toFix;
//       for (Use &U : GV->uses())
//         if (auto *I = dyn_cast<Instruction>(U.getUser()))
//           if (I->getFunction() == &F) toFix.push_back(&U);
//       for (auto *U : toFix) U->set(NewV);
//     };
//     for (auto *GV : usedStatic)  replaceUsesInFunc(GV, repl[GV]);
//     for (auto *GV : usedDynamic) replaceUsesInFunc(GV, repl[GV]);
//   }

//   // 더 이상 쓰지 않는 AS3 전역 제거
//   SmallVector<GlobalVariable*, 16> toErase;
//   for (auto &GV : M->globals()) {
//     if (GV.getType()->getAddressSpace() != 3) continue;
//     if (GV.use_empty()) toErase.push_back(&GV);
//   }
//   for (auto *GV : toErase) GV->eraseFromParent();
// }

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
