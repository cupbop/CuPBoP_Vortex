#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

using namespace llvm;

Type *getOpaquePointerElementType(Value *Ptr) {
  if (!Ptr->getType()->isPointerTy()) {
    return nullptr;
  }

  Type *ElemTy = nullptr;

  if (auto GEP = dyn_cast<GetElementPtrInst>(Ptr)) {
    ElemTy = GEP->getSourceElementType();
  } else if (auto AI = dyn_cast<AllocaInst>(Ptr)) {
    ElemTy = AI->getAllocatedType();
  } else if (auto SI = dyn_cast<StoreInst>(Ptr)) {
    ElemTy = SI->getValueOperand()->getType();
  } else if (auto GV = dyn_cast<GlobalVariable>(Ptr)) {
    ElemTy = GV->getValueType();
  }

  return ElemTy;
}