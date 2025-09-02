
#include "warp_func.h"
#include "flag.h"
#include "tool.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include <set>

#include "insert_warp_loop.h"

namespace cupbop {

using namespace llvm;
using namespace std;

ReplaceWarpLevelPrimitive::ReplaceWarpLevelPrimitive(MapOpt mapping)
    : mapping_(mapping) {}

PreservedAnalyses ReplaceWarpLevelPrimitive::run(Module &m, ModuleAnalysisManager&) {
  replaceWarpShfl(m);
  replaceWarpVote(m);
  return PreservedAnalyses::all();
}

bool ReplaceWarpLevelPrimitive::replaceWarpVote(Module &m) {

  DenseSet<StringRef> voteFuncs;
  if (mapping_ == MAPPING_1TO1) {
    voteFuncs = {
    "_Z10__any_syncji",
    "_Z10__all_syncji",     
    "_Z14__uniform_syncji", 
    "_Z13__ballot_syncji"   
    };

  } else {
    voteFuncs = {"llvm.nvvm.vote.any.sync",
                 "llvm.nvvm.vote.all.sync",
                 "llvm.nvvm.vote.uni.sync",
                 "llvm.nvvm.vote.ballot.sync"};
  }

  // get the callee functions to be replaced
  set<CallInst *> replace;
  for (auto &f : m.functions()) {
    // if (isKernelFunction(&m, &f))
    //   continue;
    auto name_caller = f.getName().str();
    for (auto &bb : f) {
      for (auto &i : bb) {
        auto ci = dyn_cast<CallInst>(&i);
        if (!ci || ci->isInlineAsm())
          continue;
        auto name_callee = ci->getCalledOperand()->getName();
        if (voteFuncs.count(name_callee.str())) {
          dbgs() << "\nvote detected: ";
          ci->print(dbgs(), true);
          dbgs() << "\n";
          replace.insert(ci);
        }
      }
    }
  }
  // handle different mappings
  switch (mapping_) {
  case MAPPING_CORE:
    break;
  case MAPPING_FLAT:
    replaceWarpVoteFlat(m, replace);
    break;
  case MAPPING_1TO1:
    replaceWarpVote1to1(m, replace);
    break;
  case MAPPING_X86:
    replaceWarpVoteX86(m, replace);
    break;
  }
  return !replace.empty();
}

void ReplaceWarpLevelPrimitive::replaceWarpVoteFlat(
    Module &m, const set<CallInst *> &replace) {
  // type
  Type *Int1T = Type::getInt1Ty(m.getContext());
  Type *I32 = Type::getInt32Ty(m.getContext());
  Type *I8 = Type::getInt8Ty(m.getContext());
  // constant
  auto C0 = ConstantInt::get(I32, 0, true);
  auto C1 = ConstantInt::get(I32, 1, true);
  // warp vote pointer
  GlobalVariable *warp_vote_ptr = m.getNamedGlobal("warp_vote");
  assert(warp_vote_ptr != NULL);
  auto vote_count_ptr = m.getNamedGlobal("vote_count");
  assert(vote_count_ptr != NULL);
  for (auto sync_inst : replace) {
    Function *F = sync_inst->getParent()->getParent();
    IRBuilder<> builder(sync_inst);
    CreateIntraWarpBarrier(sync_inst);
    // Store vote in warp_vote array
    auto intra_warp_index_addr = m.getGlobalVariable("intra_warp_index");
    auto intra_warp_index =
        new LoadInst(intra_warp_index_addr->getValueType(),
                     intra_warp_index_addr, "intra_warp_index", sync_inst);
    // Get array index for this thread
    auto GEP =
        GetElementPtrInst::Create(warp_vote_ptr->getValueType(), warp_vote_ptr,
                                  {C0, intra_warp_index}, "", sync_inst);
    // Handle mask
    auto mask = CastInst::CreateIntegerCast(sync_inst->getArgOperand(0), I32,
                                            false, "", sync_inst);
    auto bit_flag = builder.CreateLShr(mask, intra_warp_index);
    auto valid = builder.CreateAnd(C1, bit_flag);
    auto valid_8bit =
        CastInst::CreateIntegerCast(valid, I8, false, "", sync_inst);
    // Get predicate and convert to i8
    auto predict_8bit = CastInst::CreateIntegerCast(sync_inst->getArgOperand(1),
                                                    I8, false, "", sync_inst);
    // Combine mask and predicate
    auto vote_value_8bit = builder.CreateMul(valid_8bit, predict_8bit);
    auto vote_value =
        CastInst::CreateIntegerCast(vote_value_8bit, I32, false, "", sync_inst);
    // Add this thread's vote to count
    auto old_count = builder.CreateLoad(I32, vote_count_ptr, "vote_count");
    auto new_count = builder.CreateAdd(old_count, vote_value);
    builder.CreateStore(new_count, vote_count_ptr);
    CreateIntraWarpBarrier(sync_inst);
    Value *result;
    bool is_any_sync =
        sync_inst->getCalledOperand()->getName() == "llvm.nvvm.vote.any.sync";
    if (is_any_sync) {
      auto count = new LoadInst(I32, vote_count_ptr, "", sync_inst);
      result = builder.CreateICmpNE(count, C0);
    } else {
      auto count = new LoadInst(I32, vote_count_ptr, "", sync_inst);
      // auto block_size = GetCachedBlockSize(F);
      auto block_size_addr = m.getGlobalVariable("block_size");
      auto block_size = createLoad(builder, block_size_addr);
      result = builder.CreateICmpEQ(count, block_size);
    }
    // Reset count
    builder.CreateStore(C0, vote_count_ptr);
    // Replace original instruction
    sync_inst->replaceAllUsesWith(result);
    sync_inst->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpVote1to1(
    Module &m, const set<CallInst *> &replace) {
  for (auto &callInst : replace) {
    dbgs() << "vote replaced to 1to1 mapping: ";
    callInst->print(dbgs());
    callInst->getCalledFunction()->setComdat(nullptr);
    callInst->getCalledFunction()->deleteBody();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpVoteX86(
    Module &m, const set<CallInst *> &replace) {}

bool ReplaceWarpLevelPrimitive::replaceWarpShfl(Module &m) {

  DenseSet<StringRef> shflFuncs;

  if (mapping_ == MAPPING_1TO1) {
    shflFuncs = {
      "_Z11__shfl_syncjiii",
      "_Z11__shfl_syncjfii",
      "_Z14__shfl_up_syncjiji",
      "_Z16__shfl_down_syncjiji",
      "_Z15__shfl_xor_syncjiii"
    };

  } else {
    shflFuncs = {"llvm.nvvm.shfl.sync.down.i32",
                 "llvm.nvvm.shfl.sync.up.i32",
                 "llvm.nvvm.shfl.sync.bfly.i32",
                 "llvm.nvvm.shfl.sync.idx.i32"};
  }

  // get the callee functions to be replaced
  set<CallInst *> replace;
  for (auto &f : m.functions()) {
    // if (isKernelFunction(&m, &f))
    //   continue;
    auto name_caller = f.getName().str();
    dbgs() << "Processing function: " << name_caller << "\n";
    for (auto &bb : f) {
      for (auto &i : bb) {
        auto ci = dyn_cast<CallInst>(&i);
        if (!ci || ci->isInlineAsm())
          continue;
        auto name_callee = ci->getCalledOperand()->getName();
        if (shflFuncs.count(name_callee.str())) {
          dbgs() << "\nshfl detected: ";
          ci->print(dbgs(), true);
          dbgs() << "\n";
          replace.insert(ci);
        }
      }
    }
  }
  // handle different mappings
  switch (mapping_) {
  case MAPPING_CORE:
    break;
  case MAPPING_FLAT:
    replaceWarpShflFlat(m, replace);
    break;
  case MAPPING_1TO1:
    replaceWarpShfl1to1(m, replace);
    break;
  case MAPPING_X86:
    replaceWarpShflX86(m, replace);
    break;
  }
  return !replace.empty();
}

void ReplaceWarpLevelPrimitive::replaceWarpShflFlat(
    Module &m, const set<CallInst *> &replace) {
  // type
  Type *Int1T = Type::getInt1Ty(m.getContext());
  Type *I32 = Type::getInt32Ty(m.getContext());
  Type *I8 = Type::getInt8Ty(m.getContext());
  // constant
  auto C0 = ConstantInt::get(I32, 0, true);
  auto C1 = ConstantInt::get(I32, 1, true);
  GlobalVariable *warp_shfl_ptr = m.getNamedGlobal("warp_shfl");
  for (auto shfl_inst : replace) {
    /*
     * %10 = tail call i32 @llvm.nvvm.shfl.sync.down.i32(i32 -1, i32 %add32,
     * i32 16, i32 31)
     * ->
     * warp_shfl[warp_id] = add32
     * warp.barrier()
     * %10 = warp_shfl[warp_id + offset]
     */
    IRBuilder<> builder(shfl_inst);

    auto shfl_variable = shfl_inst->getArgOperand(1);
    auto shfl_offset = shfl_inst->getArgOperand(2);

    auto intra_warp_index =
        createLoad(builder, m.getGlobalVariable("intra_warp_index"));
    builder.CreateStore(shfl_variable, createGEP(builder, warp_shfl_ptr,
                                                 {C0, intra_warp_index}));
    // we should create barrier before store
    CreateIntraWarpBarrier(intra_warp_index);
    // load shuffled data
    auto new_intra_warp_index =
        createLoad(builder, m.getGlobalVariable("intra_warp_index"));
    auto shfl_name = shfl_inst->getCalledOperand()->getName().str();
    if (shfl_name.find("down") != shfl_name.npos) {
      auto calculate_offset = builder.CreateBinOp(
          Instruction::Add, new_intra_warp_index, shfl_offset);
      auto new_index = builder.CreateBinOp(Instruction::SRem, calculate_offset,
                                           ConstantInt::get(I32, 32));
      auto gep = createGEP(builder, warp_shfl_ptr, {C0, new_index});
      auto load_inst = createLoad(builder, gep);

      // create barrier
      CreateIntraWarpBarrier(new_intra_warp_index);
      shfl_inst->replaceAllUsesWith(load_inst);
      shfl_inst->eraseFromParent();
    } else if (shfl_name.find("up") != shfl_name.npos) {
      auto calculate_offset = builder.CreateBinOp(
          Instruction::Sub, new_intra_warp_index, shfl_offset);
      auto new_index = builder.CreateBinOp(Instruction::SRem, calculate_offset,
                                           ConstantInt::get(I32, 32));
      auto gep = createGEP(builder, warp_shfl_ptr, {C0, new_index});
      auto load_inst = createLoad(builder, gep);

      // create barrier
      CreateIntraWarpBarrier(new_intra_warp_index);
      shfl_inst->replaceAllUsesWith(load_inst);
      shfl_inst->eraseFromParent();
    } else if (shfl_name.find("bfly") != shfl_name.npos) {
      auto calculate_offset = builder.CreateBinOp(
          Instruction::Xor, new_intra_warp_index, shfl_offset);
      auto new_index = builder.CreateBinOp(Instruction::SRem, calculate_offset,
                                           ConstantInt::get(I32, 32));
      auto gep = createGEP(builder, warp_shfl_ptr, {C0, new_index});
      auto load_inst = createLoad(builder, gep);

      // create barrier
      CreateIntraWarpBarrier(new_intra_warp_index);
      shfl_inst->replaceAllUsesWith(load_inst);
      shfl_inst->eraseFromParent();
    }
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpShfl1to1(
    Module &m, const set<CallInst *> &replace) {
  for (auto callInst : replace) {
    dbgs() << "shfl replaced to 1to1 mapping: ";
    callInst->print(dbgs());
    callInst->getCalledFunction()->setComdat(nullptr);
    callInst->getCalledFunction()->deleteBody();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpShflX86(
    Module &m, const set<CallInst *> &replace) {}

} // namespace cupbop