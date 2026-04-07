
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
#include <vector>

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
  voteFuncs = {"llvm.nvvm.vote.any.sync",
              "llvm.nvvm.vote.all.sync",
              "llvm.nvvm.vote.uni.sync",
              "llvm.nvvm.vote.ballot.sync"};

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
          //dbgs() << "\nvote detected: ";
          ci->print(dbgs(), true);
          //dbgs() << "\n";
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
  auto &ctx = m.getContext();
  Type *I1 = Type::getInt1Ty(ctx);
  Type *I32 = Type::getInt32Ty(ctx);

  // Use mangled C++ names to match runtime symbols
  FunctionCallee fn_all = m.getOrInsertFunction(
      "_Z10__all_syncib", FunctionType::get(I1, {I32, I1}, false));
  FunctionCallee fn_any = m.getOrInsertFunction(
      "_Z10__any_syncib", FunctionType::get(I1, {I32, I1}, false));
  FunctionCallee fn_uni = m.getOrInsertFunction(
      "_Z14__uniform_syncib", FunctionType::get(I1, {I32, I1}, false));
  FunctionCallee fn_ballot = m.getOrInsertFunction(
      "_Z13__ballot_syncib", FunctionType::get(I32, {I32, I1}, false));

  for (auto *ci : replace) {
    IRBuilder<> builder(ci);
    auto callee_name = ci->getCalledOperand()->getName().str();

    Value *mask = ci->getArgOperand(0); // i32
    Value *pred = ci->getArgOperand(1); // i1

    CallInst *call = nullptr;
    if (callee_name.find(".all.") != string::npos) {
      call = builder.CreateCall(fn_all, {mask, pred});
    } else if (callee_name.find(".any.") != string::npos) {
      call = builder.CreateCall(fn_any, {mask, pred});
    } else if (callee_name.find(".uni.") != string::npos) {
      call = builder.CreateCall(fn_uni, {mask, pred});
    } else if (callee_name.find(".ballot.") != string::npos) {
      call = builder.CreateCall(fn_ballot, {mask, pred});
    } else {
      //dbgs() << "Unknown vote variant: " << callee_name << "\n";
      continue;
    }

    ci->replaceAllUsesWith(call);
    ci->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpVoteX86(
    Module &m, const set<CallInst *> &replace) {}

bool ReplaceWarpLevelPrimitive::replaceWarpShfl(Module &m) {

  DenseSet<StringRef> shflFuncs;

  shflFuncs = {"llvm.nvvm.shfl.sync.down.i32",
                "llvm.nvvm.shfl.sync.up.i32",
                "llvm.nvvm.shfl.sync.bfly.i32",
                "llvm.nvvm.shfl.sync.idx.i32",
                "llvm.nvvm.shfl.sync.down.f32",
                "llvm.nvvm.shfl.sync.up.f32",
                "llvm.nvvm.shfl.sync.bfly.f32",
                "llvm.nvvm.shfl.sync.idx.f32"};

  // Also match C++ mangled __shfl*_sync functions for FLAT mode.
  // These appear when CUDA code uses __shfl_sync() directly.
  // The C++ wrappers have same arg layout as NVVM: (mask, val, offset, width).
  auto isShflCall = [&](const string &name) -> bool {
    if (shflFuncs.count(name))
      return true;
    if (name.find("__shfl_down_sync") != string::npos ||
        name.find("__shfl_up_sync") != string::npos ||
        name.find("__shfl_xor_sync") != string::npos ||
        name.find("__shfl_sync") != string::npos)
      return true;
    return false;
  };

  // get the callee functions to be replaced
  set<CallInst *> replace;
  if (mapping_ == MAPPING_FLAT) {
    // FLAT mode: replace C++ wrapper CALLS in the kernel body directly.
    // Replacing NVVM intrinsics inside wrapper bodies doesn't work because
    // the wrapper function is not wrapped by the warp loop — only kernel
    // functions are. So warp_shfl store→load would execute in the same
    // thread iteration without synchronization.
    // By replacing the wrapper call in the kernel, the warp_shfl code
    // ends up inside the kernel body → properly wrapped by warp loop.
    for (auto &f : m.functions()) {
      if (f.isDeclaration())
        continue;
      // Only replace in kernel functions — helper functions like
      // parallel_prefix_sum have their shfl calls inlined into kernels
      // by inline_shfl_helpers. Replacing in non-kernel functions causes
      // domination errors because they aren't wrapped by warp loops.
      if (!isKernelFunction(&m, const_cast<Function*>(&f)))
        continue;
      for (auto &bb : f) {
        for (auto &i : bb) {
          auto ci = dyn_cast<CallInst>(&i);
          if (!ci || ci->isInlineAsm())
            continue;
          auto *calledFunc = ci->getCalledFunction();
          if (!calledFunc)
            continue;
          auto name = calledFunc->getName().str();
          // Match C++ wrapper calls (not NVVM intrinsics).
          // For SCHE_0, inline_warp_level_func skips shfl inline, so
          // C++ wrapper calls remain in the kernel body for us to replace.
          if (!shflFuncs.count(name) && isShflCall(name))
            replace.insert(ci);
        }
      }
    }
  } else {
    // 1TO1/other modes: replace NVVM intrinsics inside wrapper bodies.
    // The wrapper itself is called from kernel, and the hardware shfl
    // call inside the wrapper executes correctly with real hardware warps.
    for (auto &f : m.functions()) {
      for (auto &bb : f) {
        for (auto &i : bb) {
          auto ci = dyn_cast<CallInst>(&i);
          if (!ci || ci->isInlineAsm())
            continue;
          auto calledOp = ci->getCalledOperand();
          if (!calledOp || !calledOp->hasName())
            continue;
          if (shflFuncs.count(calledOp->getName().str()))
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
    // Remove now-unused wrapper functions and NVVM intrinsic declarations
    // to prevent RISC-V backend crashes on unknown NVVM ops.
    {
      bool changed = true;
      while (changed) {
        changed = false;
        SmallVector<Function *, 8> toRemove;
        for (auto &f : m.functions()) {
          if (f.use_empty() && isShflCall(f.getName().str()))
            toRemove.push_back(&f);
        }
        for (auto *f : toRemove) {
          f->eraseFromParent();
          changed = true;
        }
      }
    }
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
  fprintf(stderr, "[FLAT] replaceWarpShflFlat called, %zu to replace, warp_shfl_ptr=%p\n",
          replace.size(), (void*)warp_shfl_ptr);
  for (auto shfl_inst : replace) {
    fprintf(stderr, "[FLAT] processing shfl in %s\n",
            shfl_inst->getParent()->getParent()->getName().str().c_str());
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
    bool isFloat = shfl_variable->getType()->isFloatTy();
    auto shfl_name = shfl_inst->getCalledOperand()->getName().str();

    // Always use allocas for shfl_offset — split_block_by_sync splits at
    // barrier0 later, which can separate operand definition from use.
    // The allocas are named "shfl_*" so insert_warp_loop skips them
    // during context save (they're shfl emulation temporaries, not user data).
    Function *F = shfl_inst->getParent()->getParent();
    IRBuilder<> entryBuilder(&F->getEntryBlock(), F->getEntryBlock().getFirstInsertionPt());
    auto *offset_alloca = entryBuilder.CreateAlloca(I32, nullptr, "shfl_off");
    auto *result_alloca = entryBuilder.CreateAlloca(
        isFloat ? builder.getFloatTy() : I32, nullptr, "shfl_res");

    // Store offset before barrier
    builder.CreateStore(shfl_offset, offset_alloca);

    auto intra_warp_index =
        createLoad(builder, m.getGlobalVariable("intra_warp_index"));
    Value *val_to_store = shfl_variable;
    if (isFloat)
        val_to_store = builder.CreateBitCast(val_to_store, I32);
    auto store_gep = builder.CreateGEP(warp_shfl_ptr->getValueType(),
                                        warp_shfl_ptr, {C0, intra_warp_index});
    builder.CreateStore(val_to_store, store_gep);

    // Use a custom "shfl_barrier" marker instead of barrier0.
    // barrier0 triggers split_block_by_sync which breaks if-guard structure.
    // shfl_barrier is handled by insert_warp_loop as a parallel region
    // boundary but NOT by split_block_by_sync.
    {
      auto FT = FunctionType::get(Type::getVoidTy(m.getContext()), {}, false);
      auto callee = m.getOrInsertFunction("cupbop.shfl.barrier", FT);
      builder.CreateCall(callee);
    }

    // After barrier: load offset from alloca (survives BB split)
    auto safe_offset = builder.CreateLoad(I32, offset_alloca, "shfl_off_ld");
    auto new_intra_warp_index =
        createLoad(builder, m.getGlobalVariable("intra_warp_index"));

    Value *load_index;
    if (shfl_name.find("down") != shfl_name.npos) {
      auto calc = builder.CreateAdd(new_intra_warp_index, safe_offset);
      load_index = builder.CreateSRem(calc, ConstantInt::get(I32, 32));
    } else if (shfl_name.find("up") != shfl_name.npos) {
      auto calc = builder.CreateSub(new_intra_warp_index, safe_offset);
      load_index = builder.CreateSRem(calc, ConstantInt::get(I32, 32));
    } else if (shfl_name.find("bfly") != shfl_name.npos ||
               shfl_name.find("xor") != shfl_name.npos) {
      auto calc = builder.CreateXor(new_intra_warp_index, safe_offset);
      load_index = builder.CreateSRem(calc, ConstantInt::get(I32, 32));
    } else {
      load_index = builder.CreateSRem(safe_offset, ConstantInt::get(I32, 32));
    }

    auto gep = builder.CreateGEP(warp_shfl_ptr->getValueType(), warp_shfl_ptr,
                                  {C0, load_index});
    Value *load_inst = builder.CreateLoad(I32, gep);
    if (isFloat)
      load_inst = builder.CreateBitCast(load_inst, builder.getFloatTy());

    // Store result to alloca, replace uses with per-user loads
    builder.CreateStore(load_inst, result_alloca);
    // Second shfl_barrier
    {
      auto FT = FunctionType::get(Type::getVoidTy(m.getContext()), {}, false);
      auto callee = m.getOrInsertFunction("cupbop.shfl.barrier", FT);
      builder.CreateCall(callee);
    }
    std::vector<Instruction *> users;
    for (auto &U : shfl_inst->uses())
      if (auto *I = dyn_cast<Instruction>(U.getUser()))
        users.push_back(I);
    for (auto *user : users) {
      IRBuilder<> userBuilder(user);
      auto *res_load = userBuilder.CreateLoad(
          isFloat ? builder.getFloatTy() : I32, result_alloca, "shfl_res_ld");
      user->replaceUsesOfWith(shfl_inst, res_load);
    }
    shfl_inst->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpShfl1to1(
    Module &m, const set<CallInst *> &replace) {
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx);
  Type *F32 = Type::getFloatTy(ctx);

  for (auto *ci : replace) {
    IRBuilder<> builder(ci);
    auto name = ci->getCalledOperand()->getName().str();

    // NVVM shfl signature: (mask, val, delta/srcLane, clamp)
    Value *mask = ci->getArgOperand(0);
    Value *val = ci->getArgOperand(1);
    Value *arg2 = ci->getArgOperand(2);
    Value *cparam = ci->getArgOperand(3);

    if (mask->getType() != I32) mask = builder.CreateIntCast(mask, I32, false);
    if (arg2->getType() != I32) arg2 = builder.CreateIntCast(arg2, I32, false);
    if (cparam->getType() != I32) cparam = builder.CreateIntCast(cparam, I32, false);

    bool isFloat = (ci->getType() == F32);

    FunctionCallee callee;
    std::vector<Value*> args;

    if (name.find(".down.") != string::npos) {
      if (isFloat) {
        FunctionType *FT = FunctionType::get(F32, {I32, F32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z16__shfl_down_syncifii", FT);
      } else {
        FunctionType *FT = FunctionType::get(I32, {I32, I32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z16__shfl_down_synciiii", FT);
        if (val->getType() != I32) val = builder.CreateIntCast(val, I32, false);
      }
      args = {mask, val, arg2, cparam};
    } else if (name.find(".up.") != string::npos) {
      if (isFloat) {
        FunctionType *FT = FunctionType::get(F32, {I32, F32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z14__shfl_up_syncifii", FT);
      } else {
        FunctionType *FT = FunctionType::get(I32, {I32, I32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z14__shfl_up_synciiii", FT);
        if (val->getType() != I32) val = builder.CreateIntCast(val, I32, false);
      }
      args = {mask, val, arg2, cparam};
    } else if (name.find(".bfly.") != string::npos) {
      if (isFloat) {
        FunctionType *FT = FunctionType::get(F32, {I32, F32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z15__shfl_xor_syncifii", FT);
      } else {
        FunctionType *FT = FunctionType::get(I32, {I32, I32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z15__shfl_xor_synciiii", FT);
        if (val->getType() != I32) val = builder.CreateIntCast(val, I32, false);
      }
      args = {mask, val, arg2, cparam};
    } else if (name.find(".idx.") != string::npos) {
      if (isFloat) {
        FunctionType *FT = FunctionType::get(F32, {I32, F32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z11__shfl_syncifii", FT);
      } else {
        FunctionType *FT = FunctionType::get(I32, {I32, I32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z11__shfl_synciiii", FT);
        if (val->getType() != I32) val = builder.CreateIntCast(val, I32, false);
      }
      args = {mask, val, arg2, cparam};
    } else {
      // Unknown variant, skip
      continue;
    }

    CallInst *newCall = builder.CreateCall(callee, args);
    ci->replaceAllUsesWith(newCall);
    ci->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpShflX86(
    Module &m, const set<CallInst *> &replace) {}

} // namespace cupbop
