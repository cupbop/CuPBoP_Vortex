#pragma once

#include "flag.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Support/Casting.h"
#include <set>

namespace cupbop {

using namespace llvm;
using namespace std;

class ReplaceWarpLevelPrimitive : public PassInfoMixin<ReplaceWarpLevelPrimitive> {

private:
  /// the mapping options
  MapOpt mapping_;

public:
  /// @brief construct warp level primitives & mapping
  ReplaceWarpLevelPrimitive(MapOpt mapping);
  /// @brief replace warp level primitives
  PreservedAnalyses run(Module &M, ModuleAnalysisManager&);

private:
  /// @brief replace warp vote
  /// @param m the module where the instructions will be replaced
  bool replaceWarpVote(Module &m);
  /// @brief replace warp vote for flat mapping
  /// @param m the module where the instructions will be replaced
  /// @param replace the call instructions to be replaced
  void replaceWarpVoteFlat(Module &m, const set<CallInst *> &replace);
  /// @brief replace warp vote for 1-to-1 mapping
  /// @param m the module where the instructions will be replaced
  /// @param replace the call instructions to be replaced
  void replaceWarpVote1to1(Module &m, const set<CallInst *> &replace);
  /// @brief replace warp shuffle for flat mappping (x86)
  /// @param m the module where the instructions will be replaced
  /// @param replace the call instructions to be replaced
  void replaceWarpVoteX86(Module &m, const set<CallInst *> &replace);
  /// @brief replace warp shuffle
  /// @param m the module where the instructions will be replaced
  bool replaceWarpShfl(Module &m);
  /// @brief replace warp shuffle for flat mappping
  /// @param m the module where the instructions will be replaced
  /// @param replace the call instructions to be replaced
  void replaceWarpShflFlat(Module &m, const set<CallInst *> &replace);
  /// @brief replace warp shuffle for 1-to-1 mapping
  /// @param m the module where the instructions will be replaced
  /// @param replace the call instructions to be replaced
  void replaceWarpShfl1to1(Module &m, const set<CallInst *> &replace);
  /// @brief replace warp shuffle for flat mappping (x86)
  /// @param m the module where the instructions will be replaced
  /// @param replace the call instructions to be replaced
  void replaceWarpShflX86(Module &m, const set<CallInst *> &replace);
};

}