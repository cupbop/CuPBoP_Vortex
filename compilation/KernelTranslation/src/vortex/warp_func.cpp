
#include "warp_func.h"
#include "tool.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <iostream>
#include <set>

#include "insert_warp_loop.h"

using namespace llvm;

/*
 * Insert sync before each vote, and replace the
 * original vote function to warp vote version
 */
void handle_warp_vote(llvm::Module *M) {
  std::set<llvm::CallInst *> need_replace;
  llvm::Type *Int1T = Type::getInt1Ty(M->getContext());
  llvm::Type *I32 = llvm::Type::getInt32Ty(M->getContext());
  llvm::Type *I8 = llvm::Type::getInt8Ty(M->getContext());
  auto zero = llvm::ConstantInt::get(I32, 0, true);
  auto one = llvm::ConstantInt::get(I32, 1, true);


  // replace llvm.nvvm.vote.any.sync to warp vote function
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();
    if (!isKernelFunction(M, F))
      continue;
    Function::iterator I = F->begin();
    for (Function::iterator E = F->end(); I != E; ++I) {
      for (BasicBlock::iterator BI = I->begin(); BI != I->end(); BI++) {
        if (CallInst *vote_any_sync = dyn_cast<CallInst>(BI)) {
          if (vote_any_sync->isInlineAsm())
            continue;
          auto func_name = vote_any_sync->getCalledOperand()->getName();
          if (func_name == "llvm.nvvm.vote.any.sync" ||
              func_name == "llvm.nvvm.vote.all.sync" ||
              func_name == "llvm.nvvm.vote.uni.sync" ||
              func_name == "llvm.nvvm.vote.ballot.sync") {
            // insert sync before call
            need_replace.insert(vote_any_sync);
          }
        }
      }
    }
  }

  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
    schedule = std::stoi(std::string(env));
  }

  // thread mapping: replace vote with serialized code
  if (schedule == 0)
  {
    GlobalVariable *warp_vote_ptr = M->getNamedGlobal("warp_vote");
    assert(warp_vote_ptr != NULL);

    auto vote_count_ptr = M->getNamedGlobal("vote_count");
    assert(vote_count_ptr != NULL);

    for (auto sync_inst : need_replace) {
      Function *F = sync_inst->getParent()->getParent();
      IRBuilder<> builder(sync_inst);
      
      CreateIntraWarpBarrier(sync_inst);

      // Store vote in warp_vote array
      auto intra_warp_index_addr = M->getGlobalVariable("intra_warp_index");
      auto intra_warp_index = new LoadInst(intra_warp_index_addr->getValueType(),
                                          intra_warp_index_addr, "intra_warp_index", 
                                          sync_inst);

      // Get array index for this thread
      auto GEP = GetElementPtrInst::Create(
          warp_vote_ptr->getValueType(),
          warp_vote_ptr,
          {zero, intra_warp_index},
          "",
          sync_inst);

      // Handle mask
      auto mask = llvm::CastInst::CreateIntegerCast(
          sync_inst->getArgOperand(0), I32, false, "", sync_inst);
      auto bit_flag = builder.CreateLShr(mask, intra_warp_index);
      auto valid = builder.CreateAnd(one, bit_flag);
      auto valid_8bit = llvm::CastInst::CreateIntegerCast(valid, I8, false, "", sync_inst);

      // Get predicate and convert to i8
      auto predict_8bit = llvm::CastInst::CreateIntegerCast(
          sync_inst->getArgOperand(1), I8, false, "", sync_inst);
      // Combine mask and predicate    
      auto vote_value_8bit = builder.CreateMul(valid_8bit, predict_8bit);
      auto vote_value = llvm::CastInst::CreateIntegerCast(vote_value_8bit, I32, false, "", sync_inst);

      // Add this thread's vote to count
      auto old_count = builder.CreateLoad(I32, vote_count_ptr, "vote_count");
      auto new_count = builder.CreateAdd(old_count, vote_value);
      builder.CreateStore(new_count, vote_count_ptr);

      CreateIntraWarpBarrier(sync_inst);
      

      Value *result;
      bool is_any_sync = sync_inst->getCalledOperand()->getName() == "llvm.nvvm.vote.any.sync";
      if (is_any_sync) {
          auto count = new LoadInst(I32, vote_count_ptr, "", sync_inst);
          result = builder.CreateICmpNE(count, zero);
      } else {
          auto count = new LoadInst(I32, vote_count_ptr, "", sync_inst);
          auto block_size = GetCachedBlockSize(F);
          result = builder.CreateICmpEQ(count, block_size);
      }

      // Reset count
      builder.CreateStore(zero, vote_count_ptr);

      // Replace original instruction
      sync_inst->replaceAllUsesWith(result);
      sync_inst->eraseFromParent();
    }
  }
  else if (schedule == 1) { // core mapping: replacement strategy not yet decided
    // NOT IMPLEMENTED
  }
  else // one-on-one mapping: replace with vortex intrinsics
  {
    llvm::LLVMContext &Context = M->getContext();
    std::vector<llvm::Type *> ParamTypes(4, llvm::Type::getInt32Ty(Context));
    llvm::Type *ReturnType = llvm::Type::getInt32Ty(Context);
    llvm::FunctionType *nTTy = llvm::FunctionType::get(ReturnType, ParamTypes, false);
    FunctionCallee vote_func = M->getOrInsertFunction("vx_vote_sync", nTTy);
    for (auto sync_inst : need_replace) {
        IRBuilder<> builder(sync_inst);

        auto func_name = sync_inst->getCalledOperand()->getName();
        Value *mode, *neg, *mask, *pred;
        if (func_name == "llvm.nvvm.vote.all.sync") {
          mode = builder.getInt32(0);
          neg = builder.getInt32(0); 
        } else if (func_name == "llvm.nvvm.vote.any.sync") {
            mode = builder.getInt32(1);
            neg = builder.getInt32(0);
        } else if (func_name == "llvm.nvvm.vote.uni.sync") {
            mode = builder.getInt32(2); 
            neg = builder.getInt32(0);
        } else if (func_name == "llvm.nvvm.vote.ballot.sync") {
            mode = builder.getInt32(3);
            neg = builder.getInt32(0);
        } else {
            llvm::errs() << "Unknown vote function: " << func_name << "\n";
            continue;
        }

        mask = sync_inst->getArgOperand(0);

        auto pred_i1 = sync_inst->getArgOperand(1);
        pred = builder.CreateZExt(pred_i1, builder.getInt32Ty());
        
        Value *result = builder.CreateCall(vote_func, {pred, neg, mode, mask});

        // all, any, uni returns i1 base on nvvm specification
        if (func_name != "llvm.nvvm.vote.ballot.sync") {
            result = builder.CreateICmpNE(result, builder.getInt32(0));
        }
        
        sync_inst->replaceAllUsesWith(result);
        sync_inst->eraseFromParent();
    }
  }
}

void handle_warp_shfl(llvm::Module *M) {
  std::set<llvm::CallInst *> need_replace;

  llvm::Type *I32 = llvm::Type::getInt32Ty(M->getContext());
  auto ZERO = llvm::ConstantInt::get(I32, 0, true);
  // replace llvm.nvvm.vote.any.sync to warp vote function
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    if (!isKernelFunction(M, F))
      continue;
    Function::iterator I = F->begin();
    for (Function::iterator E = F->end(); I != E; ++I) {
      for (BasicBlock::iterator BI = I->begin(); BI != I->end(); BI++) {
        if (CallInst *warp_shfl = dyn_cast<CallInst>(BI)) {
          auto func_name = warp_shfl->getCalledOperand()->getName().str();
          if (func_name == "llvm.nvvm.shfl.sync.down.i32" ||
              func_name == "llvm.nvvm.shfl.sync.up.i32" ||
              func_name == "llvm.nvvm.shfl.sync.bfly.i32" ||
              func_name == "llvm.nvvm.shfl.sync.idx.i32" ) {
            // insert sync before call
            need_replace.insert(warp_shfl);
          }
        }
      }
    }
  }

  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
    schedule = std::stoi(std::string(env));
  }

  // thread mapping: replace vote with serialized code, may not work for now
  if (schedule == 0) {
    GlobalVariable *warp_shfl_ptr = M->getNamedGlobal("warp_shfl");
    for (auto shfl_inst : need_replace) {
      /*
      * %10 = tail call i32 @llvm.nvvm.shfl.sync.down.i32(i32 -1, i32 %add32, i32
      * 16, i32 31)
      * ->
      * warp_shfl[warp_id] = add32
      * warp.barrier()
      * %10 = warp_shfl[warp_id + offset]
      */
      IRBuilder<> builder(shfl_inst);

      auto shfl_variable = shfl_inst->getArgOperand(1);
      auto shfl_offset = shfl_inst->getArgOperand(2);

      auto intra_warp_index =
          createLoad(builder, M->getGlobalVariable("intra_warp_index"));
          builder.CreateStore(shfl_variable, createGEP(builder, warp_shfl_ptr,
                                                  {ZERO, intra_warp_index}));
      // we should create barrier before store
      CreateIntraWarpBarrier(intra_warp_index);
      // load shuffled data
      auto new_intra_warp_index =
          createLoad(builder, M->getGlobalVariable("intra_warp_index"));
      auto shfl_name = shfl_inst->getCalledOperand()->getName().str();
      if (shfl_name.find("down") != shfl_name.npos) {
        auto calculate_offset = builder.CreateBinOp(
            Instruction::Add, new_intra_warp_index, shfl_offset);
        auto new_index = builder.CreateBinOp(Instruction::SRem, calculate_offset,
                                            ConstantInt::get(I32, 32));
        auto gep = createGEP(builder, warp_shfl_ptr, {ZERO, new_index});
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
        auto gep = createGEP(builder, warp_shfl_ptr, {ZERO, new_index});
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
        auto gep = createGEP(builder, warp_shfl_ptr, {ZERO, new_index});
        auto load_inst = createLoad(builder, gep);

        // create barrier
        CreateIntraWarpBarrier(new_intra_warp_index);
        shfl_inst->replaceAllUsesWith(load_inst);
        shfl_inst->eraseFromParent();
      }
    }
  } else if (schedule == 1) { // core mapping: replacement strategy not yet decided
    // NOT IMPLEMENTED
  } else { // one-on-one mapping: replace with vortex intrinsics
    llvm::LLVMContext &Context = M->getContext();
    std::vector<llvm::Type *> ParamTypes(4, llvm::Type::getInt32Ty(Context));
    llvm::Type *ReturnType = llvm::Type::getInt32Ty(Context);
    llvm::FunctionType *nTTy = llvm::FunctionType::get(ReturnType, ParamTypes, false);
    FunctionCallee shfl_func = M->getOrInsertFunction("vx_shfl_sync", nTTy);
    for (auto shfl_inst : need_replace) {
        IRBuilder<> builder(shfl_inst);

        Value *offset, *mode, *val, *mask;
        auto func_name = shfl_inst->getCalledOperand()->getName().str();

        if (func_name == "llvm.nvvm.shfl.sync.down.i32") {
            mode = builder.getInt32(0);
        } else if (func_name == "llvm.nvvm.shfl.sync.up.i32") {
            mode = builder.getInt32(1);
        } else if (func_name == "llvm.nvvm.shfl.sync.bfly.i32") {
            mode = builder.getInt32(2);
        } else if (func_name == "llvm.nvvm.shfl.sync.idx.i32") {
            mode = builder.getInt32(3);
        } else {
            llvm::errs() << "Unknown shuffle function: " << func_name << "\n";
            continue;
        }
        offset = shfl_inst->getArgOperand(2);
        val = shfl_inst->getArgOperand(1);
        mask = shfl_inst->getArgOperand(3);
        
        Value *result = builder.CreateCall(shfl_func, {offset, mode, val, mask});
        shfl_inst->replaceAllUsesWith(result);
        shfl_inst->eraseFromParent();
    }
  }
}
