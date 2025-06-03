#pragma once

#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

llvm::Type *getOpaquePointerElementType(llvm::Value *Ptr);