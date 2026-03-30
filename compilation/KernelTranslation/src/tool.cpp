#include "tool.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
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

#include "cg_sync.h"
#include "llvm_type_utils.h"

#include <iostream>
#include <set>

using namespace llvm;

static bool cupbop_debug() {
  static bool enabled = (std::getenv("CUPBOP_DEBUG") != nullptr);
  return enabled;
}

bool triton_cupbop_enabled() {
  static bool enabled = []{
    const char* v = std::getenv("TRITON_CUPBOP");
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
      if (!VMD) continue;
      llvm::Value *meta = VMD->getValue();
      auto *FF = llvm::dyn_cast<Function>(meta);
      if (!FF) continue;
      if (FF->getName().str() == F->getName().str())
        return true;
    }
  }
  return false;
}

bool isDeviceFunction(Module *M, Function *F) {
  // Must be device-side code
  if (!(M->getTargetTriple().substr(0,5) == "nvptx")) return false;
  // Skip declarations and intrinsics
  if (F->isDeclaration() || F->isIntrinsic()) return false;
  // Skip kernels
  if (isKernelFunction(M, F)) return false;
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
  builder.SetInsertPoint(phi);

  llvm::Instruction *loadedValue =
      createLoad(builder, alloca); // builder.CreateLoad(alloca);
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
      if (cupbop_debug()) printf("--------------------\n");
      if (cupbop_debug()) std::cout << I << std::endl;
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

void replace_built_in_function(llvm::Module *M) {

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

    if (cupbop_debug()) printf("Function name: %s\n", func_name.c_str());
    if (cupbop_debug()) printf("iskernel=%d\n", isKernelFunction(M, F));
    if (cupbop_debug()) printf("isdevice=%d\n", isDeviceFunction(M, F));
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
                int field = (func_name.back() == 'x') ? 0 : (func_name.back() == 'y') ? 1 : 2;
                auto blockDimGV = M->getGlobalVariable("blockDim");
                auto field_ptr = builder.CreateStructGEP(blockDimGV->getValueType(), blockDimGV, field);
                val = builder.CreateLoad(I32, field_ptr);
              } else {
                const char *name = (func_name.back() == 'x') ? "block_size_x" :
                                   (func_name.back() == 'y') ? "block_size_y" : "block_size_z";
                auto block_size_addr = M->getGlobalVariable(name);
                val = createLoad(builder, block_size_addr);
              }
              Call->replaceAllUsesWith(val);
              need_remove.push_back(Call);
            }
            else if (func_name == "llvm.nvvm.read.ptx.sreg.tid.x") {
              if (schedule == 2) {
                IRBuilder<> builder(context);
                builder.SetInsertPoint(Call);

                // Load from vx_spawn's threadIdx.x struct field
                auto threadIdxGV = M->getGlobalVariable("threadIdx");
                auto tls_ptr = builder.CreateCall(
                    Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address,
                                              {threadIdxGV->getType()}),
                    {threadIdxGV});
                auto field_ptr = builder.CreateStructGEP(threadIdxGV->getValueType(), tls_ptr, 0);
                auto tidx = builder.CreateLoad(I32, field_ptr, "tidx");

                MDNode *N =
                    MDNode::get(context, MDString::get(context, "divergence"));
                tidx->setMetadata("divergence", N);

                Call->replaceAllUsesWith(tidx);
                need_remove.push_back(Call);
              } else {
                auto block_size_x_tmp = M->getGlobalVariable("block_size_x");
                errs() << block_size_x_tmp;

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
                  if (cupbop_debug()) printf("warning: warp idx globals not ConstantInt, skipping\n");
                  continue;
                }
                // ConstantInt* con_block_size_x =
                // cast<ConstantInt>(const_block_size_x);

                int32_t int_intra_warp_idx =
                    con_intra_warp_idx->getSExtValue(); // changed to 32
                int32_t int_inter_warp_idx = con_inter_warp_idx->getSExtValue();
                // int64_t int_block_size_x = con_block_size_x->getSExtValue();

                if (cupbop_debug()) printf("intra warp corresponding value is : %d \n",
                       int_intra_warp_idx);
                if (cupbop_debug()) printf("inter warp corresponding value is : %d \n",
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
                auto field_ptr = builder.CreateStructGEP(threadIdxGV->getValueType(), tls_ptr, 1);
                auto tidy = builder.CreateLoad(I32, field_ptr, "tidy");

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
                    ConstantInt::get(I32, 4),
                    ""); // Mark temp  (changed 32 -> 4)
                thread_idx = builder.CreateBinOp(
                    Instruction::Add, createLoad(builder, local_intra_warp_idx),
                    thread_idx, "thread_idx");
                // tidy = tid / block_dim.x
                thread_idx = builder.CreateBinOp(
                    Instruction::SDiv, thread_idx,
                    createLoad(builder, M->getGlobalVariable("block_size_x")),
                    "thread_id_y");

                // Add metadata to indicate non-uniformity
                // MDNode* N = MDNode::get(context, MDString::get(context,
                // "non-uniform"));
                // cast<Instruction>(thread_idx)->setMetadata("divergence", N);

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
                auto field_ptr = builder.CreateStructGEP(threadIdxGV->getValueType(), tls_ptr, 2);
                auto tidz = builder.CreateLoad(I32, field_ptr, "tidz");

                MDNode *N =
                    MDNode::get(context, MDString::get(context, "divergence"));
                tidz->setMetadata("divergence", N);
                Call->replaceAllUsesWith(tidz);
                need_remove.push_back(Call);
              } else {
                if (cupbop_debug()) printf("[WARNING] We DO NOT support triple-dim block\n");
                exit(1);
                auto zero = ConstantInt::get(I32, 0);
                Call->replaceAllUsesWith(zero);
                need_remove.push_back(Call);
              }
            }
            // Mark: Temporarily commented out the _ZN25 function, we don't
            // think it's being used in vortex

            else if (func_name == "llvm.nvvm.read.ptx.sreg.ctaid.x" ||
                     func_name == "llvm.nvvm.read.ptx.sreg.ctaid.y" ||
                     func_name == "llvm.nvvm.read.ptx.sreg.ctaid.z") {
              int field = (func_name.back() == 'x') ? 0 : (func_name.back() == 'y') ? 1 : 2;
              if (cupbop_debug()) printf("block_Id-%c is called\n", func_name.back());
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);

              Value *block_idx;
              if (schedule == 2) {
                // Load from vx_spawn's blockIdx struct field
                auto blockIdxGV = M->getGlobalVariable("blockIdx");
                auto tls_ptr = builder.CreateCall(
                    Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address,
                                              {blockIdxGV->getType()}),
                    {blockIdxGV});
                auto field_ptr = builder.CreateStructGEP(blockIdxGV->getValueType(), tls_ptr, field);
                block_idx = builder.CreateLoad(I32, field_ptr);
              } else {
                const char *name = (field == 0) ? "block_index_x" :
                                   (field == 1) ? "block_index_y" : "block_index_z";
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
              int field = (func_name.back() == 'x') ? 0 : (func_name.back() == 'y') ? 1 : 2;
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              Value *grid_size;
              if (schedule == 2) {
                // Load from vx_spawn's gridDim struct field
                auto gridDimGV = M->getGlobalVariable("gridDim");
                auto field_ptr = builder.CreateStructGEP(gridDimGV->getValueType(), gridDimGV, field);
                grid_size = builder.CreateLoad(I32, field_ptr);
              } else {
                const char *name = (field == 0) ? "grid_size_x" :
                                   (field == 1) ? "grid_size_y" : "grid_size_z";
                auto grid_size_addr = M->getGlobalVariable(name);
                grid_size = createLoad(builder, grid_size_addr);
              }
              Call->replaceAllUsesWith(grid_size);
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

                auto localGroupId = builder.CreateLoad(
                    localGroupIdGV->getValueType(), localGroupIdGV);
                auto warpsPerGroup = builder.CreateLoad(
                    warpsPerGroupGV->getValueType(), warpsPerGroupGV);

                CallInst *syncThreads = builder.CreateCall(
                    threadIdxFunc, {localGroupId, warpsPerGroup});

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
            if (!asm_inst) continue;
            if (asm_inst->getAsmString() != "mov.u32 $0, %laneid;") {
              if (cupbop_debug()) printf("Warning: unhandled InlineAsm: %s\n",
                     asm_inst->getAsmString().c_str());
              continue;
            }
            // return the rank within the warp
            IRBuilder<> builder(context);
            builder.SetInsertPoint(Call);
            auto intra_warp_index = createLoad(builder, local_intra_warp_idx);
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
              Call->print(errs());
              // print Call->getArgOperand(1)
              Call->getArgOperand(1)->print(errs());
              // print the entire module
              M->print(errs(), nullptr);
              need_remove.push_back(Call);
            } else if (func_name == "__nv_fast_log2f" ||
                       func_name == "__nv_log2f" ||
                       func_name == "__nv_fast_powf" ||
                       func_name == "__nv_powf" || func_name == "__nv_logf" ||
                       func_name == "__nv_expf" || func_name == "__nv_fabsf" ||
                       func_name == "__nv_log10f" ||
                       func_name == "__nv_fmodf" || func_name == "__nv_sqrt" || func_name == "__nv_rsqrtf" ||
                       func_name == "__nv_sqrtf" || func_name == "__nv_exp" ||
                       func_name == "__nv_isnanf" ||
                       func_name == "__nv_isinff" || func_name == "__nv_powi" ||
                       func_name == "__nv_powif" ||
                       func_name == "__nv_erfcf" ||
                       func_name == "__nv_ffs" || func_name == "__nv_popc") {
              dbgs() << "Removing call to " << func_name << "\n";
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
            } else if (func_name == "llvm.nvvm.membar.gl") {
              Call->getCalledFunction()->setName("__nvvm_membar_gl");
            } else if (func_name.find("llvm.nvvm.atomic.load.inc.32") != std::string::npos) {
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
        auto *fma_func = Intrinsic::getDeclaration(M, Intrinsic::fma, {a->getType()});
        replacement = Builder.CreateCall(fma_func, {a, b, c});

      // Multiply: a*b
      } else if (name.find("llvm.nvvm.mul.r") != std::string::npos) {
        replacement = Builder.CreateFMul(Call->getArgOperand(0), Call->getArgOperand(1));

      // Add: a+b
      } else if (name.find("llvm.nvvm.add.r") != std::string::npos) {
        replacement = Builder.CreateFAdd(Call->getArgOperand(0), Call->getArgOperand(1));

      // Division: a/b
      } else if (name.find("llvm.nvvm.div.r") != std::string::npos) {
        replacement = Builder.CreateFDiv(Call->getArgOperand(0), Call->getArgOperand(1));

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
            Intrinsic::getDeclaration(M, Intrinsic::minnum, {a->getType()}), {a, b});
      } else if (name.find("llvm.nvvm.fmax.") != std::string::npos) {
        Value *a = Call->getArgOperand(0);
        Value *b = Call->getArgOperand(1);
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::maxnum, {a->getType()}), {a, b});

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
        replacement = Builder.CreateFDiv(ConstantFP::get(x->getType(), 1.0), sq);

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
            Intrinsic::getDeclaration(M, Intrinsic::maxnum, {x->getType()}), {x, zero});
        replacement = Builder.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::minnum, {x->getType()}), {clamped_lo, one});

      // Float-to-signed-int
      } else if (name.find("llvm.nvvm.f2i.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::roundeven, {x->getType()}), {x});
        } else if (name.find(".rm") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::floor, {x->getType()}), {x});
        } else if (name.find(".rp") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::ceil, {x->getType()}), {x});
        }
        replacement = Builder.CreateFPToSI(x, I32);

      // Float-to-unsigned-int
      } else if (name.find("llvm.nvvm.f2ui.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::roundeven, {x->getType()}), {x});
        } else if (name.find(".rm") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::floor, {x->getType()}), {x});
        } else if (name.find(".rp") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::ceil, {x->getType()}), {x});
        }
        replacement = Builder.CreateFPToUI(x, I32);

      // Float-to-long-long
      } else if (name.find("llvm.nvvm.f2ll.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::roundeven, {x->getType()}), {x});
        }
        replacement = Builder.CreateFPToSI(x, I64);
      } else if (name.find("llvm.nvvm.f2ull.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::roundeven, {x->getType()}), {x});
        }
        replacement = Builder.CreateFPToUI(x, I64);

      // Double-to-int conversions
      } else if (name.find("llvm.nvvm.d2i.r") != std::string::npos) {
        Value *x = Call->getArgOperand(0);
        if (name.find(".rn") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::roundeven, {x->getType()}), {x});
        } else if (name.find(".rm") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::floor, {x->getType()}), {x});
        } else if (name.find(".rp") != std::string::npos) {
          x = Builder.CreateCall(Intrinsic::getDeclaration(M, Intrinsic::ceil, {x->getType()}), {x});
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

void replace_asm_call(llvm::Module *M) {
  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);
  auto I64 = llvm::Type::getInt64Ty(context);
  std::vector<CallInst *> need_remove;
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);

    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->isInlineAsm()) {
            auto asm_inst = dyn_cast<InlineAsm>(Call->getCalledOperand());
            auto asm_str = asm_inst->getAsmString();

            if (asm_str == "mov.u32 $0, %laneid;") {
              // return the rank within the warp
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              auto intra_warp_index_addr =
                  M->getGlobalVariable("intra_warp_index");
              auto intra_warp_index = createLoad(builder, intra_warp_index_addr);
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
            } else {
              if (cupbop_debug()) printf("warning: unknown PTX InlineAsm: %s (removing)\n", asm_str.c_str());
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
      if (Call->isInlineAsm())
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
      if (Call->isInlineAsm())
        continue;
      auto func_name = Call->getCalledFunction()->getName().str();
      if (func_name == "llvm.nvvm.barrier0" || isWarpSync(func_name) ||
          func_name == "llvm.nvvm.barrier.sync") {
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
      if (Call->isInlineAsm())
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