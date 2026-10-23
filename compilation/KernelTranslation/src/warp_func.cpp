
#include "warp_func.h"
#include "flag.h"
#include "tool.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
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
  // In FLAT mode, skip shfl replacement here — it's handled by
  // replace_warp_shfl_early() after init_block (barrier insertion order matters).
  if (mapping_ != MAPPING_FLAT)
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
  case MAPPING_CORE: // virt: hardware lanes; with sub-passes (L < 32) staged + glue
    if (getVirtGeom().subpasses > 1) replaceWarpVoteStaged(m, replace);
    else replaceWarpVote1to1(m, replace);
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

    // Vote intrinsics (any/all/uni/ballot) are warp-synchronizing — need
    // convergent so LoopUnswitch/LICM don't hoist code containing them
    // across non-uniform branches. (Same root cause as the shfl convergent
    // fix in replaceWarpShfl1to1.)
    call->addFnAttr(Attribute::Convergent);
    if (auto *fn = dyn_cast<Function>(call->getCalledFunction()))
      fn->addFnAttr(Attribute::Convergent);
    ci->replaceAllUsesWith(call);
    ci->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpVoteX86(
    Module &m, const set<CallInst *> &replace) {}

bool ReplaceWarpLevelPrimitive::replaceWarpShfl(Module &m, bool excludeIdx) {

  DenseSet<StringRef> shflFuncs;

  shflFuncs = {"llvm.nvvm.shfl.sync.down.i32",
                "llvm.nvvm.shfl.sync.up.i32",
                "llvm.nvvm.shfl.sync.bfly.i32",
                "llvm.nvvm.shfl.sync.down.f32",
                "llvm.nvvm.shfl.sync.up.f32",
                "llvm.nvvm.shfl.sync.bfly.f32"};
  if (!excludeIdx) {
    shflFuncs.insert("llvm.nvvm.shfl.sync.idx.i32");
    shflFuncs.insert("llvm.nvvm.shfl.sync.idx.f32");
  }

  // Also match C++ mangled __shfl*_sync functions for FLAT mode.
  // These appear when CUDA code uses __shfl_sync() directly.
  // The C++ wrappers have same arg layout as NVVM: (mask, val, offset, width).
  auto isShflCall = [&](const string &name) -> bool {
    if (shflFuncs.count(name))
      return true;
    if (name.find("__shfl_down_sync") != string::npos ||
        name.find("__shfl_up_sync") != string::npos ||
        name.find("__shfl_xor_sync") != string::npos)
      return true;
    // Plain __shfl_sync (idx mode) — only match if not excluding idx
    if (!excludeIdx && name.find("__shfl_sync") != string::npos)
      return true;
    return false;
  };

  // get the callee functions to be replaced
  set<CallInst *> replace;
  const bool coreStaged = (mapping_ == MAPPING_CORE && getVirtGeom().subpasses > 1);
  if (mapping_ == MAPPING_FLAT || coreStaged) {
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
          // Match both C++ wrapper calls and NVVM intrinsics.
          // On sm_90, clang inlines C++ wrappers leaving only NVVM intrinsics.
          if (isShflCall(name)) {
            fprintf(stderr, "[FLAT] matched shfl: %s (excludeIdx=%d)\n",
                    name.c_str(), excludeIdx);
            replace.insert(ci);
          }
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
  case MAPPING_CORE: // virt: hardware lanes; with sub-passes (L < 32) staged + glue
    if (coreStaged) {
      replaceWarpShflStaged(m, replace);
      bool changed = true;
      while (changed) { // drop the now-unused C++ wrappers (their NVVM bodies would reach the backend)
        changed = false;
        SmallVector<Function *, 8> toRemove;
        for (auto &f : m.functions())
          if (f.use_empty() && !isKernelFunction(&m, &f) && isShflCall(f.getName().str())) toRemove.push_back(&f);
        for (auto *f : toRemove) { f->eraseFromParent(); changed = true; }
      }
    } else
      replaceWarpShfl1to1(m, replace);
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

    // idx mode: __shfl_sync(mask,val,lane) — simple broadcast/read.
    // Don't add barrier splits (too many warp loops for cc-cuda).
    bool isIdxMode = (shfl_name.find("idx") != shfl_name.npos ||
                      (shfl_name.find("__shfl_sync") != shfl_name.npos &&
                       shfl_name.find("down") == shfl_name.npos &&
                       shfl_name.find("up") == shfl_name.npos &&
                       shfl_name.find("xor") == shfl_name.npos));

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

    // Split BEFORE the store: separates this shfl's store from the
    // PREVIOUS shfl's read+combine. Skip for idx mode (no combine).
    if (!isIdxMode) {
      auto *insertBB = builder.GetInsertBlock();
      auto *insertPt = &*builder.GetInsertPoint();
      if (insertPt != &*insertBB->begin()) {
        auto *newBB = insertBB->splitBasicBlock(
            insertPt, insertBB->getName().str() + "_shfl_store");
        builder.SetInsertPoint(&*newBB->begin());
      }
    }

    auto intra_warp_index =
        createLoad(builder, m.getGlobalVariable("intra_warp_index"));
    auto inter_warp_index =
        createLoad(builder, m.getGlobalVariable("inter_warp_index"));
    // Index by inter*32 + intra to isolate warps in warp_shfl[1024]
    auto store_idx = builder.CreateAdd(intra_warp_index,
        builder.CreateMul(inter_warp_index, ConstantInt::get(I32, 32)),
        "shfl_store_idx");
    Value *val_to_store = shfl_variable;
    if (isFloat)
        val_to_store = builder.CreateBitCast(val_to_store, I32);
    auto store_gep = builder.CreateGEP(warp_shfl_ptr->getValueType(),
                                        warp_shfl_ptr, {C0, store_idx});
    auto *store_inst = builder.CreateStore(val_to_store, store_gep);
    cast<StoreInst>(store_inst)->setVolatile(true);

    // shfl_barrier separates the store from the read.
    // For idx mode, skip barrier/split — idx is a simple read from
    // a fixed lane, no synchronization needed between store and read.
    if (!isIdxMode) {
      CallInst *shfl_call;
      {
        auto FT = FunctionType::get(Type::getVoidTy(m.getContext()), {}, false);
        auto callee = m.getOrInsertFunction("cupbop.shfl.barrier", FT);
        shfl_call = builder.CreateCall(callee);
      }
      // Split block: store → | shfl_barrier → read
      auto *storeBlock = shfl_call->getParent();
      auto *barrierBlock = storeBlock->splitBasicBlock(
          shfl_call, storeBlock->getName().str() + "_shfl_barrier");
      // Split again: shfl_barrier → | read
      auto *nextAfterBarrier = shfl_call->getNextNode();
      if (nextAfterBarrier && !nextAfterBarrier->isTerminator()) {
        barrierBlock->splitBasicBlock(
            nextAfterBarrier, storeBlock->getName().str() + "_shfl_read");
      }
      // Reset builder to the read block
      builder.SetInsertPoint(nextAfterBarrier);
    }

    // After barrier: load offset from alloca (survives BB split)
    auto safe_offset = builder.CreateLoad(I32, offset_alloca, "shfl_off_ld");
    auto new_intra_warp_index =
        createLoad(builder, m.getGlobalVariable("intra_warp_index"));
    auto new_inter_warp_index =
        createLoad(builder, m.getGlobalVariable("inter_warp_index"));

    // Compute lane-level index within warp (0..31)
    Value *lane_index;
    if (shfl_name.find("down") != shfl_name.npos) {
      auto calc = builder.CreateAdd(new_intra_warp_index, safe_offset);
      lane_index = builder.CreateSRem(calc, ConstantInt::get(I32, 32));
    } else if (shfl_name.find("up") != shfl_name.npos) {
      auto calc = builder.CreateSub(new_intra_warp_index, safe_offset);
      lane_index = builder.CreateSRem(calc, ConstantInt::get(I32, 32));
    } else if (shfl_name.find("bfly") != shfl_name.npos ||
               shfl_name.find("xor") != shfl_name.npos) {
      auto calc = builder.CreateXor(new_intra_warp_index, safe_offset);
      lane_index = builder.CreateSRem(calc, ConstantInt::get(I32, 32));
    } else {
      lane_index = builder.CreateSRem(safe_offset, ConstantInt::get(I32, 32));
    }
    // Add inter_warp offset: warp_shfl[inter*32 + lane]
    auto load_index = builder.CreateAdd(lane_index,
        builder.CreateMul(new_inter_warp_index, ConstantInt::get(I32, 32)),
        "shfl_load_idx");

    auto gep = builder.CreateGEP(warp_shfl_ptr->getValueType(), warp_shfl_ptr,
                                  {C0, load_index});
    auto *load_raw = builder.CreateLoad(I32, gep);
    cast<LoadInst>(load_raw)->setVolatile(true);
    Value *load_inst = load_raw;
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
    // The original NVPTX shfl intrinsic call carries `convergent`; without
    // re-applying it on the replacement, clang's LoopUnswitch hoists any
    // surrounding `if (tid==0)` predicate to the top of the enclosing loop,
    // and VortexBranchDivergence then wraps that predicate in vx_split_n.
    // The result is that only one of {tid==0, tid!=0} is active when shfl
    // runs, so it reads from inactive lanes (returning 0). Symptom in
    // marchingCubes computeMinMaxLv2: per-voxel min reduces to 0, inflating
    // Block Lv2 from ~3520 to ~15280.
    newCall->addFnAttr(Attribute::Convergent);
    if (auto *fn = dyn_cast<Function>(callee.getCallee()))
      fn->addFnAttr(Attribute::Convergent);
    ci->replaceAllUsesWith(newCall);
    ci->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpShflX86(
    Module &m, const set<CallInst *> &replace) {}

} // namespace cupbop


// ---------------------------------------------------------------------------
// Core mapping with sub-passes (schedule 1, L < 32 lanes per physical warp).
// A CUDA warp is S = 32/L sub-passes of the intra loop; a warp-level op needs
// all 32 logical lanes. Each sub-pass stores its operands in per-thread stage
// slots, a warp-sync marker ends the region, and uniform glue (all lanes, once
// per logical warp, between the two intra loops) combines the S slots with
// hardware ballots/shuffles into per-sub-pass results read after a second
// marker (…glue_end, a warp sync by name so every pass treats it as one).
// ---------------------------------------------------------------------------
static Value *virtLogicalLane(IRBuilder<> &b, Module &m) {
  return createLoad(b, m.getGlobalVariable("intra_warp_index"));
}

void ReplaceWarpLevelPrimitive::replaceWarpVoteStaged(Module &m, const set<CallInst *> &replace_in) {
  const VirtGeom vg = getVirtGeom();
  const int S = vg.subpasses, L = vg.lanes, LG = vg.lg_lanes;
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx), *I1 = Type::getInt1Ty(ctx), *VoidT = Type::getVoidTy(ctx);
  set<CallInst *> replace = replace_in;
  for (auto &f : m.functions())
    for (auto &bb : f)
      for (auto &i : bb)
        if (auto *ci = dyn_cast<CallInst>(&i))
          if (!ci->isInlineAsm() && ci->getCalledFunction() &&
              ci->getCalledFunction()->getName() == "__cupbop_activemask")
            replace.insert(ci);
  if (replace.empty()) return;
  FunctionCallee hwBallot = m.getOrInsertFunction("__cupbop_hw_ballot", FunctionType::get(I32, {I32}, false));
  if (auto *Fn = dyn_cast<Function>(hwBallot.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  FunctionCallee glueEnd = m.getOrInsertFunction("cupbop.virt.syncwarp.glue_end", FunctionType::get(VoidT, {}, false));
  if (auto *Fn = dyn_cast<Function>(glueEnd.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  auto *ArrTy = ArrayType::get(I32, S);
  int n = 0;
  for (auto *ci : replace) {
    Function *F = ci->getFunction();
    std::string name = ci->getCalledOperand()->getName().str();
    if (!isKernelFunction(&m, F)) {
      fprintf(stderr, "[virt-stage] WARNING: %s in non-kernel %s left to the hardware lowering\n", name.c_str(), F->getName().str().c_str());
      set<CallInst *> one; one.insert(ci);
      if (name != "__cupbop_activemask") replaceWarpVote1to1(m, one);
      continue;
    }
    const bool isActive = (name == "__cupbop_activemask");
    Value *mask = isActive ? ConstantInt::get(I32, -1) : ci->getArgOperand(0);
    Value *pred = isActive ? ConstantInt::getTrue(ctx) : ci->getArgOperand(1);
    if (mask->getType() != I32) { IRBuilder<> tb(ci); mask = tb.CreateIntCast(mask, I32, false); }
    IRBuilder<> eb(&F->getEntryBlock(), F->getEntryBlock().getFirstInsertionPt());
    auto *stage = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_vote_stage");
    auto *res = eb.CreateAlloca(I32, nullptr, "shfl_virt_vote_res");
    for (int j = 0; j < S; j++) eb.CreateStore(ConstantInt::get(I32, 0), eb.CreateConstInBoundsGEP2_32(ArrTy, stage, 0, j));
    IRBuilder<> b(ci);
    // store phase (this sub-pass): in-mask predicate of the logical lane
    Value *l = virtLogicalLane(b, m);
    Value *j = b.CreateLShr(l, ConstantInt::get(I32, LG), "vsub");
    Value *inm = b.CreateAnd(b.CreateLShr(mask, l), ConstantInt::get(I32, 1));
    Value *v = b.CreateAnd(inm, b.CreateZExt(pred, I32), "vote_v");
    b.CreateStore(v, b.CreateInBoundsGEP(ArrTy, stage, {ConstantInt::get(I32, 0), j}));
    CreateIntraWarpBarrier(ci); // marker: all sub-passes of this logical warp are done
    // glue (uniform, all lanes): OR of the hardware ballots of the S slots, then clean
    Value *bits = ConstantInt::get(I32, 0);
    for (int jj = 0; jj < S; jj++) {
      auto *gep = b.CreateConstInBoundsGEP2_32(ArrTy, stage, 0, jj);
      auto *hb = b.CreateCall(hwBallot, {b.CreateLoad(I32, gep)});
      hb->addFnAttr(Attribute::Convergent);
      bits = b.CreateOr(bits, b.CreateShl(hb, ConstantInt::get(I32, L * jj)));
      b.CreateStore(ConstantInt::get(I32, 0), gep);
    }
    b.CreateStore(bits, res);
    b.CreateCall(glueEnd)->addFnAttr(Attribute::Convergent);
    // load phase (next region, per sub-pass)
    Value *bm = b.CreateAnd(b.CreateLoad(I32, res, "vote_bits"), mask);
    Value *result;
    if (isActive || name.find(".ballot.") != string::npos) result = bm;
    else if (name.find(".any.") != string::npos) result = b.CreateICmpNE(bm, ConstantInt::get(I32, 0));
    else if (name.find(".all.") != string::npos) result = b.CreateICmpEQ(bm, mask);
    else result = b.CreateOr(b.CreateICmpEQ(bm, ConstantInt::get(I32, 0)), b.CreateICmpEQ(bm, mask)); // uni
    if (result->getType() != ci->getType()) {
      if (ci->getType() == I1) result = b.CreateICmpNE(result, Constant::getNullValue(result->getType()));
      else result = b.CreateZExtOrTrunc(result, ci->getType());
    }
    ci->replaceAllUsesWith(result);
    ci->eraseFromParent();
    n++;
  }
  fprintf(stderr, "[virt-stage] %d vote/activemask sites staged over %d sub-passes of %d lanes\n", n, S, L);
}

void ReplaceWarpLevelPrimitive::replaceWarpShflStaged(Module &m, const set<CallInst *> &replace) {
  const VirtGeom vg = getVirtGeom();
  const int S = vg.subpasses, L = vg.lanes, LG = vg.lg_lanes;
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx), *VoidT = Type::getVoidTy(ctx), *F32 = Type::getFloatTy(ctx);
  if (replace.empty()) return;
  FunctionCallee hwShfl = m.getOrInsertFunction("__cupbop_hw_shfl_idx", FunctionType::get(I32, {I32, I32, I32}, false));
  if (auto *Fn = dyn_cast<Function>(hwShfl.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  FunctionCallee srcLane = m.getOrInsertFunction("__cupbop_shfl_srclane", FunctionType::get(I32, {I32, I32, I32, I32}, false));
  FunctionCallee laneId = m.getOrInsertFunction("__cupbop_laneid", FunctionType::get(I32, false));
  FunctionCallee glueEnd = m.getOrInsertFunction("cupbop.virt.syncwarp.glue_end", FunctionType::get(VoidT, {}, false));
  if (auto *Fn = dyn_cast<Function>(glueEnd.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  auto *ArrTy = ArrayType::get(I32, S);
  int n = 0;
  for (auto *ci : replace) {
    Function *F = ci->getFunction();
    std::string name = ci->getCalledOperand()->getName().str();
    if (!isKernelFunction(&m, F)) {
      fprintf(stderr, "[virt-stage] WARNING: %s in non-kernel %s left to the hardware lowering\n", name.c_str(), F->getName().str().c_str());
      set<CallInst *> one; one.insert(ci); replaceWarpShfl1to1(m, one);
      continue;
    }
    const bool isIntrinsic = name.rfind("llvm.nvvm.shfl.sync.", 0) == 0;
    int mode = 0;
    if (name.find("up") != string::npos) mode = 1;
    else if (name.find("down") != string::npos) mode = 2;
    else if (name.find("bfly") != string::npos || name.find("xor") != string::npos) mode = 3;
    Value *var = ci->getArgOperand(1);
    Value *bArg = ci->getArgOperand(2);
    Value *cArg = ci->getArgOperand(3);
    Type *VT = var->getType();
    const bool isFloat = VT->isFloatTy();
    IRBuilder<> b(ci);
    if (!isIntrinsic) { // C++ wrapper: 4th arg is width -> PTX c = (32-width)<<8 | (up ? 0 : 31)
      Value *w = b.CreateIntCast(cArg, I32, false);
      Value *seg = b.CreateShl(b.CreateSub(ConstantInt::get(I32, 32), w), ConstantInt::get(I32, 8));
      cArg = b.CreateOr(seg, ConstantInt::get(I32, mode == 1 ? 0 : 31));
    }
    bArg = b.CreateIntCast(bArg, I32, true);
    Value *varBits = isFloat ? b.CreateBitCast(var, I32) : b.CreateIntCast(var, I32, true);
    IRBuilder<> eb(&F->getEntryBlock(), F->getEntryBlock().getFirstInsertionPt());
    auto *stV = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_val");
    auto *stB = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_b");
    auto *stC = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_c");
    auto *stR = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_res");
    // store phase (this sub-pass)
    Value *l = virtLogicalLane(b, m);
    Value *j = b.CreateLShr(l, ConstantInt::get(I32, LG), "ssub");
    Value *zero = ConstantInt::get(I32, 0);
    b.CreateStore(varBits, b.CreateInBoundsGEP(ArrTy, stV, {zero, j}));
    b.CreateStore(bArg, b.CreateInBoundsGEP(ArrTy, stB, {zero, j}));
    b.CreateStore(cArg, b.CreateInBoundsGEP(ArrTy, stC, {zero, j}));
    CreateIntraWarpBarrier(ci);
    // glue: for every reader sub-pass jr, source logical lane s -> hardware shuffle of slot s>>LG from lane s&(L-1)
    Value *hl = b.CreateAnd(b.CreateCall(laneId, {}, "hwlane"), ConstantInt::get(I32, L - 1));
    for (int jr = 0; jr < S; jr++) {
      Value *lr = b.CreateAdd(hl, ConstantInt::get(I32, L * jr));
      Value *bj = b.CreateLoad(I32, b.CreateConstInBoundsGEP2_32(ArrTy, stB, 0, jr));
      Value *cj = b.CreateLoad(I32, b.CreateConstInBoundsGEP2_32(ArrTy, stC, 0, jr));
      Value *s = b.CreateCall(srcLane, {ConstantInt::get(I32, mode), lr, bj, cj}, "srclane");
      Value *js = b.CreateLShr(s, ConstantInt::get(I32, LG));
      Value *hs = b.CreateAnd(s, ConstantInt::get(I32, L - 1));
      Value *val = zero;
      for (int jj = 0; jj < S; jj++) {
        auto *x = b.CreateCall(hwShfl, {b.CreateLoad(I32, b.CreateConstInBoundsGEP2_32(ArrTy, stV, 0, jj)), hs, ConstantInt::get(I32, L - 1)});
        x->addFnAttr(Attribute::Convergent);
        val = b.CreateSelect(b.CreateICmpEQ(js, ConstantInt::get(I32, jj)), x, val);
      }
      b.CreateStore(val, b.CreateConstInBoundsGEP2_32(ArrTy, stR, 0, jr));
    }
    b.CreateCall(glueEnd)->addFnAttr(Attribute::Convergent);
    // load phase (next region): this sub-pass's result
    Value *l2 = virtLogicalLane(b, m);
    Value *j2 = b.CreateLShr(l2, ConstantInt::get(I32, LG));
    Value *r = b.CreateLoad(I32, b.CreateInBoundsGEP(ArrTy, stR, {zero, j2}), "shfl_r");
    Value *result = isFloat ? b.CreateBitCast(r, F32) : b.CreateIntCast(r, VT, true);
    ci->replaceAllUsesWith(result);
    ci->eraseFromParent();
    n++;
  }
  fprintf(stderr, "[virt-stage] %d shfl sites staged over %d sub-passes of %d lanes\n", n, S, L);
}
