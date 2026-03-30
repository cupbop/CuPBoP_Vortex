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
#include <fstream>
#include <set>

using namespace llvm;

static bool cupbop_debug() {
  static bool enabled = (std::getenv("CUPBOP_DEBUG") != nullptr);
  return enabled;
}
#define DBG_PRINT(...) do { if (cupbop_debug()) printf(__VA_ARGS__); } while(0)

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
      llvm::Value *meta =
          dyn_cast<llvm::ValueAsMetadata>(MD->getOperand(0))->getValue();
      Function *FF = llvm::cast<Function>(meta);
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

  // Remove __vx_* stub function bodies (CUDA device stubs).
  // Real implementations are in cudaKernelImpl.o, linked later.
  {
    std::vector<Function*> vx_stubs;
    for (auto &F : *M) {
      if (F.getName().contains("__vx_") && !F.isDeclaration()) {
        vx_stubs.push_back(&F);
      }
    }
    for (auto *F : vx_stubs) {
      if (cupbop_debug()) std::cout << "[DXA] Removing stub body: " << F->getName().str() << "\n";
      F->deleteBody();
      F->setLinkage(GlobalValue::ExternalLinkage);
    }
  }

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

    DBG_PRINT("Function name: %s\n", func_name.c_str());
    DBG_PRINT("iskernel=%d\n", isKernelFunction(M, F));
    DBG_PRINT("isdevice=%d\n", isDeviceFunction(M, F));
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

                ConstantInt *con_intra_warp_idx =
                    cast<ConstantInt>(const_intra_warp_idx);
                ConstantInt *con_inter_warp_idx =
                    cast<ConstantInt>(const_inter_warp_idx);
                // ConstantInt* con_block_size_x =
                // cast<ConstantInt>(const_block_size_x);

                int32_t int_intra_warp_idx =
                    con_intra_warp_idx->getSExtValue(); // changed to 32
                int32_t int_inter_warp_idx = con_inter_warp_idx->getSExtValue();
                // int64_t int_block_size_x = con_block_size_x->getSExtValue();

                DBG_PRINT("intra warp corresponding value is : %d \n",
                       int_intra_warp_idx);
                DBG_PRINT("inter warp corresponding value is : %d \n",
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
  auto F32 = llvm::Type::getFloatTy(context);
  auto HalfTy = llvm::Type::getHalfTy(context);
  auto PtrTy = PointerType::getUnqual(context);
  std::vector<CallInst *> need_remove;

  // TCU: Track ldmatrix results → shared memory pointers
  // Key: the ldmatrix CallInst result (struct {i32,i32,i32,i32})
  // Value: {smem_ptr, is_transposed}
  struct LdMatrixInfo {
    Value *smem_ptr;    // ptr addrspace(3) operand
    bool is_transposed; // .trans variant (B tile)
  };
  std::map<Value*, LdMatrixInfo> ldmatrix_map;

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
            } else if (asm_str.find("ldmatrix.sync") != std::string::npos) {
              // ── Triton ldmatrix: loads from shared memory into MMA register fragments ──
              // Pattern: ldmatrix.sync.aligned.m8n8.x4[.trans].shared.b16 {$0,$1,$2,$3}, [$4]
              // Operands: 4 output i32 (packed fp16), 1 input ptr addrspace(3)
              //
              // For WGMMA_SS TCU path: ldmatrix is NOT needed — TCU reads directly
              // from shared memory. But we save the shared memory pointer for later
              // use by mma.sync conversion.
              //
              // TODO(TCU): Instead of removing, save the smem pointer and associate
              //            it with the mma.sync that consumes these fragments.
              //            For now, replace with undef (TCU conversion pending).
              bool is_trans = asm_str.find(".trans.") != std::string::npos;
              Value *smem_ptr = Call->getArgOperand(0); // ptr addrspace(3)
              if (cupbop_debug()) printf("[TCU] detected ldmatrix%s: smem_ptr operand found\n",
                                         is_trans ? " (transposed, B tile)" : " (A tile)");
              // Save ldmatrix result → smem pointer mapping
              // Don't replace with undef yet — mma.sync needs to trace operands
              // back through extractvalue to this ldmatrix call.
              ldmatrix_map[Call] = {smem_ptr, is_trans};

            } else if (asm_str.find("mma.sync.aligned") != std::string::npos) {
              // ── Triton mma.sync → Vortex TCU conversion ──
              //
              // Triton IR pattern (Turing fp16, one asm block = m16n8k16):
              //   %result = call {f32,f32,f32,f32} asm "
              //     mma.sync.aligned.m16n8k8.row.col.f32.f16.f16.f32 {$0,$1,$2,$3},{$8,$9},{$10},{$4,$5,$6,$7};
              //     mma.sync.aligned.m16n8k8.row.col.f32.f16.f16.f32 {$0,$1,$2,$3},{$11,$12},{$13},{$4,$5,$6,$7};"
              //   constraints: "=f,=f,=f,=f, 0,1,2,3, r,r,r,r,r,r"
              //   operands: (C0,C1,C2,C3, A0_k0,A1_k0,B_k0, A0_k1,A1_k1,B_k1)
              //
              // Upstream chain:
              //   A regs ← ldmatrix(@global_smem + offset_A)
              //   B regs ← ldmatrix.trans(@global_smem + 1024 + offset_B)
              //   C regs ← previous accumulator or zero
              //
              // Vortex TCU (NT=32, NR=8): m16n16k16
              //   - Needs 2 mma.sync blocks in N direction (each covers n=8)
              //   - Uses WGMMA_SS (flags=6): TCU reads A,B from shared memory
              //   - Register layout differs: NVIDIA 2x2 block vs Vortex quadrant
              //   - C/D need layout shuffle between NVIDIA and Vortex
              //
              // NOTE: If Vortex NR changes, tile sizes change:
              //   NR=8 → m16n16k16 (need 2 mma.sync blocks in N)
              //   NR=4 → m16n8k8 (1:1 mapping, but still layout mismatch)
              //
              // Implementation plan:
              //   1. Collect consecutive mma.sync calls covering full N dimension
              //   2. Find shared memory base for A and B from ldmatrix trace
              //   3. Build WGMMA descriptors (smem addr, stride, layout)
              //   4. Emit Vortex TCU: .insn r 0x0b, 0, 2, x0, x1, x6
              //   5. Shuffle C/D between NVIDIA ↔ Vortex layout via shared memory
              //
              // TODO(TCU): Replace undef with actual TCU instruction emission.

              // Trace A/B operands back to ldmatrix → shared memory pointers
              // mma.sync operands: (C0-C3, A0_k0, A1_k0, B_k0, A0_k1, A1_k1, B_k1)
              // A operands come from extractvalue of ldmatrix result
              // B operands come from extractvalue of ldmatrix.trans result
              Value *smem_A = nullptr, *smem_B = nullptr;

              // Trace operand 4 (first A reg) back to ldmatrix
              if (Call->arg_size() >= 5) {
                Value *a0 = Call->getArgOperand(4);
                if (auto *EV = dyn_cast<ExtractValueInst>(a0)) {
                  Value *agg = EV->getAggregateOperand();
                  if (ldmatrix_map.count(agg)) {
                    smem_A = ldmatrix_map[agg].smem_ptr;
                    if (cupbop_debug()) printf("[TCU] traced A to shared memory\n");
                  }
                }
              }
              // Trace operand 6 (first B reg) back to ldmatrix.trans
              if (Call->arg_size() >= 7) {
                Value *b0 = Call->getArgOperand(6);
                if (auto *EV = dyn_cast<ExtractValueInst>(b0)) {
                  Value *agg = EV->getAggregateOperand();
                  if (ldmatrix_map.count(agg)) {
                    smem_B = ldmatrix_map[agg].smem_ptr;
                    if (cupbop_debug()) printf("[TCU] traced B to shared memory (transposed)\n");
                  }
                }
              }

              if (cupbop_debug()) {
                printf("[TCU] mma.sync: smem_A=%s, smem_B=%s\n",
                       smem_A ? "found" : "NOT FOUND",
                       smem_B ? "found" : "NOT FOUND");
              }

              // Parse operand info for logging
              unsigned num_args = Call->arg_size();
              if (cupbop_debug()) {
                printf("[TCU] detected mma.sync (%u operands):\n", num_args);
                // C/D: first 4 operands (tied float)
                // A: operands 4-7 (i32 packed fp16)
                // B: operands 8-9 (i32 packed fp16)
                for (unsigned j = 0; j < num_args; j++) {
                  Value *op = Call->getArgOperand(j);
                  printf("  arg[%u]: ", j);
                  op->getType()->print(errs()); errs() << "\n"; errs().flush();
                }
              }

              // ── TCU instruction emission via WGMMA_SS ──
              // Declare external functions from cudaKernelImpl.cpp (linked at kernel.elf time)
              auto *VoidTy = Type::getVoidTy(context);
              auto *wgmma_encode_fn = M->getOrInsertFunction(
                  "_Z22__vx_wgmma_encode_descyjjjjjj",
                  FunctionType::get(I32, {I64, I32, I32, I32, I32, I32, I32}, false)).getCallee();
              auto *wgmma_mma_fn = M->getOrInsertFunction(
                  "_Z17__vx_wgmma_mma_ssPfS_S_",
                  FunctionType::get(VoidTy, {PtrTy, PtrTy, PtrTy}, false)).getCallee();

              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);

              if (smem_A && smem_B) {
                // Allocate stack arrays for TCU fragments (8 floats each for NR=8)
                // NOTE: Vortex TCU is m16n16k16. This mma.sync covers m16n8k16.
                // We compute the full m16n16k16 but only use first 4 results.
                // TODO: combine 2 mma.sync calls for full N=16.
                auto *fragC_arr = builder.CreateAlloca(F32, ConstantInt::get(I32, 8), "tcu_fragC");
                auto *fragA_arr = builder.CreateAlloca(F32, ConstantInt::get(I32, 8), "tcu_fragA");
                auto *fragB_arr = builder.CreateAlloca(F32, ConstantInt::get(I32, 8), "tcu_fragB");

                // Initialize C accumulator from mma.sync input (first 4 operands)
                // Remaining 4 slots zeroed (for the n=8..15 half that this mma.sync doesn't cover)
                for (int ci = 0; ci < 4; ci++) {
                  auto *gep = builder.CreateGEP(F32, fragC_arr, ConstantInt::get(I32, ci));
                  builder.CreateStore(Call->getArgOperand(ci), gep);
                }
                for (int ci = 4; ci < 8; ci++) {
                  auto *gep = builder.CreateGEP(F32, fragC_arr, ConstantInt::get(I32, ci));
                  builder.CreateStore(ConstantFP::get(F32, 0.0), gep);
                }

                // Encode A descriptor metadata
                // smem_A is ptr addrspace(3). Cast to i64 for base_addr.
                // For fp16 A tile [16 x K]: leading = K * sizeof(half), stride = M_tile * K * sizeof(half)
                // For 16x16 matmul: leading = 16*2 = 32, stride = 16*16*2 = 512
                // TODO: extract these from the IR instead of hardcoding
                Value *smem_A_i64 = builder.CreatePtrToInt(smem_A, I64);
                Value *a_word = builder.CreateCall(cast<Function>(wgmma_encode_fn), {
                    smem_A_i64,
                    ConstantInt::get(I32, 32),   // leading_bytes: K_tile * sizeof(half) = 16*2
                    ConstantInt::get(I32, 512),  // stride_bytes: M_tile * K * sizeof(half) = 16*16*2
                    ConstantInt::get(I32, 0),    // mn_idx
                    ConstantInt::get(I32, 0),    // k_idx
                    ConstantInt::get(I32, 16),   // ldm
                    ConstantInt::get(I32, 0)     // is_col_major
                }, "a_desc_word");

                // Fill all 8 A fragment regs with the same metadata word
                Value *a_meta_f = builder.CreateBitCast(a_word, F32, "a_meta_f");
                for (int ai = 0; ai < 8; ai++) {
                  auto *gep = builder.CreateGEP(F32, fragA_arr, ConstantInt::get(I32, ai));
                  builder.CreateStore(a_meta_f, gep);
                }

                // Encode B descriptor metadata (transposed)
                Value *smem_B_i64 = builder.CreatePtrToInt(smem_B, I64);
                Value *b_word = builder.CreateCall(cast<Function>(wgmma_encode_fn), {
                    smem_B_i64,
                    ConstantInt::get(I32, 32),   // leading_bytes
                    ConstantInt::get(I32, 512),  // stride_bytes
                    ConstantInt::get(I32, 0),    // mn_idx
                    ConstantInt::get(I32, 0),    // k_idx
                    ConstantInt::get(I32, 16),   // ldm
                    ConstantInt::get(I32, 0)     // is_col_major (B was transposed by ldmatrix.trans)
                }, "b_desc_word");

                Value *b_meta_f = builder.CreateBitCast(b_word, F32, "b_meta_f");
                for (int bi = 0; bi < 8; bi++) {
                  auto *gep = builder.CreateGEP(F32, fragB_arr, ConstantInt::get(I32, bi));
                  builder.CreateStore(b_meta_f, gep);
                }

                // Call WGMMA_SS: TCU reads A,B from shared memory via descriptors
                builder.CreateCall(cast<Function>(wgmma_mma_fn), {fragC_arr, fragA_arr, fragB_arr});

                // Extract results: first 4 floats from fragC (Vortex layout)
                // TODO: C/D layout shuffle NVIDIA ↔ Vortex (for now, take as-is)
                Value *result = UndefValue::get(Call->getType());
                for (int ri = 0; ri < 4; ri++) {
                  auto *gep = builder.CreateGEP(F32, fragC_arr, ConstantInt::get(I32, ri));
                  Value *val = builder.CreateLoad(F32, gep, "tcu_result");
                  result = builder.CreateInsertValue(result, val, ri);
                }
                Call->replaceAllUsesWith(result);

                if (cupbop_debug()) printf("[TCU] Emitted WGMMA_SS TCU instruction for mma.sync\n");
              } else {
                // Fallback: smem pointers not found, replace with undef
                if (cupbop_debug()) printf("[TCU] WARNING: smem pointers not found, using undef\n");
                if (!Call->getType()->isVoidTy()) {
                  Call->replaceAllUsesWith(UndefValue::get(Call->getType()));
                }
              }
              need_remove.push_back(Call);

              // Now clean up the ldmatrix calls that fed this mma.sync
              for (auto &[ldCall, info] : ldmatrix_map) {
                if (auto *CI = dyn_cast<CallInst>(ldCall)) {
                  if (!CI->getType()->isVoidTy() && CI->getParent()) {
                    CI->replaceAllUsesWith(UndefValue::get(CI->getType()));
                    need_remove.push_back(CI);
                  }
                }
              }
              ldmatrix_map.clear();

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

// =============================================================================
// WMMA intrinsic translation for Vortex TCU
// =============================================================================
//
// Replaces @llvm.nvvm.wmma.* intrinsics with Vortex TCU equivalent code.
// Handles: load_matrix_sync, mma_sync, store_matrix_sync
//
// Vortex TCU custom instruction (from vx_tensor.h):
//   .insn r 0x0B, 0, 2, x{Ot_id}, x{It_id}, x{flags}
//   Inputs:  f0-f7 (C/D accum), f10-f17 (A), f24-f31 (B)
//   Outputs: f0-f7 (D result)
//
// For CUDA wmma m16n16k16 fp16->fp32:
//   Ot_id = 0 (fp32), It_id = 1 (fp16), flags = 0 (dense)
// =============================================================================

// =============================================================================
// cp.async → DXA transformation
//
// Replaces CUDA cp.async intrinsics with Vortex DXA tile-copy calls.
//
// Pattern:
//   call @llvm.nvvm.cp.async.ca.shared.global.{4,8,16}(ptr addrspace(3), ptr addrspace(1))
//   ...
//   call @llvm.nvvm.cp.async.commit.group()
//   call @llvm.nvvm.cp.async.wait.group(i32 N)
//
// Becomes:
//   if (__vx_is_dxa_warp()) {
//     __vx_dxa_issue_2d(desc_slot, bar_id, smem_base, coord0, coord1);
//   }
//   __vx_barrier_arrive_and_wait(bar_id, num_warps);
// =============================================================================

void replace_cp_async_with_dxa(llvm::Module *M) {
  using namespace llvm;
  LLVMContext &ctx = M->getContext();
  auto *I32 = Type::getInt32Ty(ctx);
  auto *VoidTy = Type::getVoidTy(ctx);
  auto *PtrTy = PointerType::getUnqual(ctx);

  // Declare __vx_* functions (C++ mangled names matching cudaKernelImpl.cpp)
  auto *dxa_issue_fn = M->getOrInsertFunction(
      "_Z17__vx_dxa_issue_2djjPvjj",
      FunctionType::get(VoidTy, {I32, I32, PtrTy, I32, I32}, false)).getCallee();
  auto *barrier_fn = M->getOrInsertFunction(
      "_Z28__vx_barrier_arrive_and_waitjj",
      FunctionType::get(VoidTy, {I32, I32}, false)).getCallee();
  auto *barrier_id_fn = M->getOrInsertFunction(
      "_Z19__vx_dxa_barrier_idj",
      FunctionType::get(I32, {I32}, false)).getCallee();
  auto *is_dxa_fn = M->getOrInsertFunction(
      "_Z16__vx_is_dxa_warpv",
      FunctionType::get(I32, {}, false)).getCallee();
  auto *warps_fn = M->getOrInsertFunction(
      "_Z20__vx_warps_per_groupv",
      FunctionType::get(I32, {}, false)).getCallee();
  auto *local_mem_fn = M->getOrInsertFunction(
      "_Z21__vx_local_mem_offsetj",
      FunctionType::get(PtrTy, {I32}, false)).getCallee();

  // Collect all cp.async-related calls
  struct CpAsyncCopyInfo {
    CallInst *call;
    Value *smem_dst;   // ptr addrspace(3)
    Value *gmem_src;   // ptr addrspace(1)
    unsigned bytes;    // 4, 8, or 16
  };

  std::vector<CpAsyncCopyInfo> copy_calls;
  std::vector<CallInst*> commit_calls;
  std::vector<CallInst*> wait_calls;
  std::vector<CallInst*> wait_all_calls;

  if (cupbop_debug()) std::cout << "[cp.async→DXA] Scanning module for cp.async patterns...\n" << std::flush;

  for (auto &F : *M) {
    if (cupbop_debug()) std::cout << "[cp.async→DXA] Scanning function: " << F.getName().str() << "\n" << std::flush;
    for (auto &BB : F) {
      for (auto &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI) continue;

        if (!CI->getCalledFunction()) {
          // Could be inline asm or indirect call — skip for approach A
          continue;
        }
        auto name = CI->getCalledFunction()->getName();

        // Debug: print any call containing "async" or "pipeline"
        if (name.contains("async") || name.contains("pipeline") || name.contains("cp_async")) {
          if (cupbop_debug()) std::cout << "[cp.async→DXA] Candidate call: " << name.str() << " in " << F.getName().str() << "\n" << std::flush;
        }

        // Approach A: Function-level detection (wrapper functions like cp_async_4)
        // Demangled patterns: cp_async_4(void*, void const*), cp_async_commit(), cp_async_wait()
        // Also matches __pipeline_memcpy_async variants
        // Skip kernel functions — filter by checking the callee is a small helper,
        // not a kernel. Kernel functions have many args; cp_async helpers have 0-2.
        if ((name.contains("cp_async") || name.contains("pipeline_memcpy_async") ||
            name.contains("CpAsyncChooser")) &&
            CI->getCalledFunction()->arg_size() <= 2) {
          if (name.contains("commit") || name.contains("pipeline_commit")) {
            commit_calls.push_back(CI);
          }
          else if (name.contains("wait")) {
            wait_calls.push_back(CI);
          }
          else if (CI->arg_size() >= 2) {
            // Copy function: first arg = smem dst, second arg = gmem src
            unsigned bytes = 4; // default; could parse from name
            if (name.contains("16")) bytes = 16;
            else if (name.contains("8")) bytes = 8;
            copy_calls.push_back({CI, CI->getArgOperand(0), CI->getArgOperand(1), bytes});
          }
        }

        // LLVM intrinsics (from __builtin_nvvm_cp_async_*)
        else if (name.starts_with("llvm.nvvm.cp.async.ca.shared.global") ||
                 name.starts_with("llvm.nvvm.cp.async.cg.shared.global")) {
          unsigned bytes = 0;
          if (name.contains(".16")) bytes = 16;
          else if (name.contains(".8")) bytes = 8;
          else if (name.contains(".4")) bytes = 4;
          copy_calls.push_back({CI, CI->getArgOperand(0), CI->getArgOperand(1), bytes});
        }
        else if (name == "llvm.nvvm.cp.async.commit.group") {
          commit_calls.push_back(CI);
        }
        else if (name == "llvm.nvvm.cp.async.wait.group") {
          wait_calls.push_back(CI);
        }
        else if (name == "llvm.nvvm.cp.async.wait.all") {
          wait_all_calls.push_back(CI);
        }
      }
    }
  }

  if (cupbop_debug()) std::cout << "[cp.async→DXA] Scan done. copy=" << copy_calls.size()
            << " commit=" << commit_calls.size()
            << " wait=" << wait_calls.size() << "\n" << std::flush;

  if (copy_calls.empty() && commit_calls.empty() && wait_calls.empty() && wait_all_calls.empty()) {
    if (cupbop_debug()) std::cout << "[cp.async→DXA] No cp.async found, returning\n" << std::flush;
    return;
  }

  // Debug: print collected info
  for (size_t i = 0; i < copy_calls.size(); i++) {
    if (cupbop_debug()) std::cout << "[cp.async→DXA] copy[" << i << "]: smem=" << (void*)copy_calls[i].smem_dst
              << " gmem=" << (void*)copy_calls[i].gmem_src
              << " bytes=" << copy_calls[i].bytes << "\n" << std::flush;
  }

  if (cupbop_debug()) std::cout << "[cp.async→DXA] Found " << copy_calls.size() << " copy, "
            << commit_calls.size() << " commit, "
            << wait_calls.size() << " wait.group, "
            << wait_all_calls.size() << " wait.all calls\n";

  // Track descriptor slots by tracing global pointer back to kernel arg
  // For each distinct global base pointer, assign a descriptor slot
  uint32_t next_desc_slot = 0;
  std::map<Value*, uint32_t> ptr_to_slot;

  auto getBasePtr = [](Value *V) -> Value* {
    // Walk through GEPs, bitcasts, addrspacecasts to find the base pointer
    while (true) {
      if (auto *GEP = dyn_cast<GetElementPtrInst>(V)) {
        V = GEP->getPointerOperand();
      } else if (auto *BC = dyn_cast<BitCastInst>(V)) {
        V = BC->getOperand(0);
      } else if (auto *ASC = dyn_cast<AddrSpaceCastInst>(V)) {
        V = ASC->getPointerOperand();
      } else if (auto *PHI = dyn_cast<PHINode>(V)) {
        V = PHI->getIncomingValue(0); // take first incoming
      } else {
        break;
      }
    }
    return V;
  };

  // Assign descriptor slots — one per copy for now (simplified)
  for (size_t i = 0; i < copy_calls.size(); i++) {
    ptr_to_slot[copy_calls[i].gmem_src] = i;
    if (cupbop_debug()) std::cout << "[cp.async→DXA] Assigned desc slot " << i << "\n" << std::flush;
  }

  // Collect wrapper functions before erasing calls (use-after-free prevention)
  // Save original copy info before eraseFromParent invalidates pointers
  struct CpAsyncOrigInfo { Value *gmem_src; unsigned bytes; };
  std::vector<CpAsyncOrigInfo> copy_calls_orig;
  for (auto &info : copy_calls)
    copy_calls_orig.push_back({info.gmem_src, info.bytes});

  std::set<Function*> wrapper_fns;
  for (auto &info : copy_calls) {
    if (info.call->getCalledFunction())
      wrapper_fns.insert(info.call->getCalledFunction());
  }
  for (auto *CI : commit_calls) {
    if (CI->getCalledFunction())
      wrapper_fns.insert(CI->getCalledFunction());
  }
  for (auto *CI : wait_calls) {
    if (CI->getCalledFunction())
      wrapper_fns.insert(CI->getCalledFunction());
  }

  // --- Extract tile coordinates from kernel structure ---
  // Phase 1: pattern-match blockIdx*TILE and k_base in the kernel function.
  // Phase 2 (TODO): generalized GEP chain analysis for arbitrary patterns.
  Function *kernelFn = copy_calls[0].call->getFunction();

  auto getBlockIdxDim = [](Value *V) -> int {
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI || !CI->getCalledFunction()) return -1;
    auto name = CI->getCalledFunction()->getName();
    if (name.contains("blockIdx") && name.contains("fetch_builtin")) {
      if (name.contains("_x")) return 0;
      if (name.contains("_y")) return 1;
      if (name.contains("_z")) return 2;
    }
    if (name == "llvm.nvvm.read.ptx.sreg.ctaid.x") return 0;
    if (name == "llvm.nvvm.read.ptx.sreg.ctaid.y") return 1;
    if (name == "llvm.nvvm.read.ptx.sreg.ctaid.z") return 2;
    return -1;
  };

  // Helper: check if Value is a loop induction variable
  auto isLoopVar = [](Value *V) -> bool {
    if (auto *LI = dyn_cast<LoadInst>(V)) {
      if (auto *AI = dyn_cast<AllocaInst>(LI->getPointerOperand())) {
        auto n = AI->getName();
        if (n.contains("k_base") || n.contains("k_tile") || n == "k" || n == "kk") return true;
      }
      auto bb = LI->getParent()->getName();
      if (bb.starts_with("for.cond") || bb.starts_with("for.body")) {
        if (isa<AllocaInst>(LI->getPointerOperand())) return true;
      }
    }
    if (auto *PHI = dyn_cast<PHINode>(V)) {
      auto bb = PHI->getParent()->getName();
      if (bb.starts_with("for.cond") || bb.contains("loop")) return true;
    }
    return false;
  };

  // Recursive classifier: given a Value in an offset expression, determine what it depends on
  enum class TK { BlockX, BlockY, LoopVar, ThreadIdx, Const, Unknown };
  std::function<TK(Value*, int)> classify = [&](Value *V, int depth) -> TK {
    if (depth > 20) return TK::Unknown;
    if (isa<ConstantInt>(V)) return TK::Const;
    int dim = getBlockIdxDim(V);
    if (dim == 0) return TK::BlockX;
    if (dim == 1) return TK::BlockY;
    { auto *CI = dyn_cast<CallInst>(V);
      if (CI && CI->getCalledFunction()) {
        auto n = CI->getCalledFunction()->getName();
        if (n.contains("threadIdx") || n.starts_with("llvm.nvvm.read.ptx.sreg.tid.")) return TK::ThreadIdx;
      }
    }
    if (isLoopVar(V)) return TK::LoopVar;
    if (auto *BinOp = dyn_cast<BinaryOperator>(V)) {
      auto k0 = classify(BinOp->getOperand(0), depth+1);
      auto k1 = classify(BinOp->getOperand(1), depth+1);
      if (BinOp->getOpcode() == Instruction::Add || BinOp->getOpcode() == Instruction::Or) {
        if (k0 != TK::Const && k0 != TK::Unknown) return k0;
        if (k1 != TK::Const && k1 != TK::Unknown) return k1;
        return (k0 == TK::Const && k1 == TK::Const) ? TK::Const : TK::Unknown;
      }
      if (BinOp->getOpcode() == Instruction::Mul || BinOp->getOpcode() == Instruction::Shl) {
        if (k0 == TK::Const || k0 == TK::Unknown) return k1;
        if (k1 == TK::Const || k1 == TK::Unknown) return k0;
        return k0; // both non-trivial: prefer first operand
      }
    }
    if (auto *CE = dyn_cast<CastInst>(V)) return classify(CE->getOperand(0), depth+1);
    if (auto *PHI = dyn_cast<PHINode>(V)) return classify(PHI->getIncomingValue(0), depth+1);
    if (auto *LI = dyn_cast<LoadInst>(V)) {
      if (auto *AI = dyn_cast<AllocaInst>(LI->getPointerOperand())) {
        auto n = AI->getName();
        if (n.contains("k_base") || n == "k") return TK::LoopVar;
        for (auto *U : AI->users()) {
          if (auto *SI = dyn_cast<StoreInst>(U)) {
            if (SI->getPointerOperand() == AI) {
              auto k = classify(SI->getValueOperand(), depth+1);
              if (k != TK::Unknown) return k;
            }
          }
        }
      }
    }
    return TK::Unknown;
  };

  // Collect all blockIdx*TILE and loop induction variable values in the kernel
  std::map<int, Value*> blockIdxTile; // dim -> mul instruction
  Value *loopVar = nullptr;
  for (auto &BB : *kernelFn) {
    for (auto &I : BB) {
      if (auto *Mul = dyn_cast<BinaryOperator>(&I)) {
        if (Mul->getOpcode() == Instruction::Mul) {
          for (int op = 0; op < 2; op++) {
            int dim = getBlockIdxDim(Mul->getOperand(op));
            if (dim >= 0 && isa<ConstantInt>(Mul->getOperand(1-op))) {
              if (blockIdxTile.find(dim) == blockIdxTile.end()) {
                blockIdxTile[dim] = Mul;
                auto tile = cast<ConstantInt>(Mul->getOperand(1-op))->getZExtValue();
                if (cupbop_debug()) std::cout << "[cp.async→DXA] Found blockIdx." << "xyz"[dim] << " * " << tile << "\n" << std::flush;
              }
            }
          }
        }
      }
      if (!loopVar && isLoopVar(&I)) {
        loopVar = &I;
        if (cupbop_debug()) std::cout << "[cp.async→DXA] Found loop var in " << BB.getName().str() << "\n" << std::flush;
      }
    }
  }

  // --- Replace copy calls with DXA issue using GEP-based coordinate extraction ---
  for (size_t i = 0; i < copy_calls.size(); i++) {
    auto *CI = copy_calls[i].call;
    IRBuilder<> builder(CI);

    Value *bar_id = builder.CreateCall(
        cast<Function>(barrier_id_fn), {ConstantInt::get(I32, 0)}, "dxa_bar_id");
    Value *smem = copy_calls[i].smem_dst;

    Value *coord0 = ConstantInt::get(I32, 0);
    Value *coord1 = ConstantInt::get(I32, 0);

#if 1 // Phase 2: GEP chain analysis (re-enabled for debugging)
    // Walk GEP chain on gmem_src to find the offset expression

    Value *gmem = copy_calls[i].gmem_src;
    // Find the GEP that computes the element address
    if (auto *GEP = dyn_cast<GetElementPtrInst>(gmem)) {
      // Get the linearized offset (last index in GEP)
      Value *offset = GEP->getOperand(GEP->getNumOperands() - 1);

      // Decompose: walk add chain and classify each term
      bool hasBlockX = false, hasBlockY = false, hasLoop = false;
      Value *blockXVal = nullptr, *blockYVal = nullptr, *loopVal = nullptr;

      std::vector<Value*> worklist = {offset};
      std::set<Value*> visited;
      while (!worklist.empty()) {
        Value *V = worklist.back(); worklist.pop_back();
        if (visited.count(V)) continue;
        visited.insert(V);
        // Follow casts (sext, zext, trunc)
        if (auto *CE = dyn_cast<CastInst>(V)) {
          worklist.push_back(CE->getOperand(0));
          continue;
        }
        // Split additions
        if (auto *BinOp = dyn_cast<BinaryOperator>(V)) {
          if (BinOp->getOpcode() == Instruction::Add || BinOp->getOpcode() == Instruction::Or) {
            worklist.push_back(BinOp->getOperand(0));
            worklist.push_back(BinOp->getOperand(1));
            continue;
          }
        }
        TK kind = classify(V, 0);
        if (kind == TK::BlockX && !hasBlockX) { hasBlockX = true; blockXVal = V; }
        if (kind == TK::BlockY && !hasBlockY) { hasBlockY = true; blockYVal = V; }
        if (kind == TK::LoopVar && !hasLoop) { hasLoop = true; loopVal = V; }
      }

      // Map classified terms to DXA coordinates
      // For A[row*K+col]: blockIdx.x (row) + loopVar (col) -> coord0=loopVar, coord1=blockIdx.x
      // For B[row*N+col]: loopVar (row) + blockIdx.y (col) -> coord0=blockIdx.y, coord1=loopVar
      if (hasBlockX && hasLoop && !hasBlockY) {
        coord0 = loopVal ? loopVal : (loopVar ? loopVar : ConstantInt::get(I32, 0));
        coord1 = blockXVal ? blockXVal : (blockIdxTile.count(0) ? blockIdxTile[0] : ConstantInt::get(I32, 0));
      } else if (hasBlockY && hasLoop && !hasBlockX) {
        coord0 = blockYVal ? blockYVal : (blockIdxTile.count(1) ? blockIdxTile[1] : ConstantInt::get(I32, 0));
        coord1 = loopVal ? loopVal : (loopVar ? loopVar : ConstantInt::get(I32, 0));
      } else if (hasBlockX && hasBlockY) {
        coord0 = blockYVal ? blockYVal : ConstantInt::get(I32, 0);
        coord1 = blockXVal ? blockXVal : ConstantInt::get(I32, 0);
      } else if (hasLoop) {
        coord0 = loopVal ? loopVal : ConstantInt::get(I32, 0);
      }

      if (cupbop_debug()) std::cout << "[cp.async→DXA] copy[" << i << "]: blockX=" << hasBlockX
                << " blockY=" << hasBlockY << " loop=" << hasLoop << "\n" << std::flush;
    }

#endif // Phase 2

    // Phase 1: hardcoded coord pattern for SGEMM
    {
      Value *rb = nullptr, *cb = nullptr, *kb = nullptr;
      for (auto &BB2 : *kernelFn) {
        for (auto &I2 : BB2) {
          if (auto *Mul = dyn_cast<BinaryOperator>(&I2)) {
            if (Mul->getOpcode() != Instruction::Mul) continue;
            for (int op = 0; op < 2; op++) {
              int dim = getBlockIdxDim(Mul->getOperand(op));
              if (dim == 0 && !rb && isa<ConstantInt>(Mul->getOperand(1-op))) rb = Mul;
              if (dim == 1 && !cb && isa<ConstantInt>(Mul->getOperand(1-op))) cb = Mul;
            }
          }
          if (auto *LI = dyn_cast<LoadInst>(&I2)) {
            if (auto *AI = dyn_cast<AllocaInst>(LI->getPointerOperand())) {
              if (AI->getName() == "k_base" && !kb &&
                  (BB2.getName().starts_with("for.cond") || BB2.getName().starts_with("for.body")))
                kb = LI;
            }
          }
        }
      }
      if (!rb) rb = ConstantInt::get(I32, 0);
      if (!cb) cb = ConstantInt::get(I32, 0);
      if (!kb) kb = ConstantInt::get(I32, 0);
      if (i == 0) { coord0 = kb; coord1 = rb; }
      else { coord0 = cb; coord1 = kb; }
    }

    // Ensure i32 type
    auto ensureI32 = [&](Value *V) -> Value* {
      if (V->getType() == I32) return V;
      if (V->getType()->isIntegerTy()) {
        return V->getType()->getIntegerBitWidth() > 32
          ? builder.CreateTrunc(V, I32, "i32") : builder.CreateZExt(V, I32, "i32");
      }
      return ConstantInt::get(I32, 0);
    };
    coord0 = ensureI32(coord0);
    coord1 = ensureI32(coord1);

    builder.CreateCall(cast<Function>(dxa_issue_fn),
        {ConstantInt::get(I32, (uint32_t)i), bar_id, smem, coord0, coord1});
    if (cupbop_debug()) std::cout << "[cp.async→DXA] Replaced copy " << i << " with DXA issue\n" << std::flush;
    CI->eraseFromParent();
  }

  // --- Remove commit.group calls (no-op for DXA) ---
  for (auto *CI : commit_calls) {
    if (cupbop_debug()) std::cout << "[cp.async→DXA] Removing commit.group\n";
    CI->eraseFromParent();
  }

  // --- Replace wait.group / wait.all with barrier ---
  for (auto *CI : wait_calls) {
    IRBuilder<> builder(CI);
    Value *bar_id = builder.CreateCall(
        cast<Function>(barrier_id_fn), {ConstantInt::get(I32, 0)}, "dxa_bar_id");
    Value *num_warps = builder.CreateCall(cast<Function>(warps_fn), {}, "num_warps");
    builder.CreateCall(cast<Function>(barrier_fn), {bar_id, num_warps});
    if (cupbop_debug()) std::cout << "[cp.async→DXA] Replaced wait.group with barrier\n";
    CI->eraseFromParent();
  }

  for (auto *CI : wait_all_calls) {
    IRBuilder<> builder(CI);
    Value *bar_id = builder.CreateCall(
        cast<Function>(barrier_id_fn), {ConstantInt::get(I32, 0)}, "dxa_bar_id");
    Value *num_warps = builder.CreateCall(cast<Function>(warps_fn), {}, "num_warps");
    builder.CreateCall(cast<Function>(barrier_fn), {bar_id, num_warps});
    if (cupbop_debug()) std::cout << "[cp.async→DXA] Replaced wait.all with barrier\n";
    CI->eraseFromParent();
  }

  // --- Remove cp.async wrapper function bodies ---
  // These contain PTX inline asm that won't compile for RISC-V
  // NOTE: wrapper_fns was collected before eraseFromParent calls above
  {
    for (auto *F : wrapper_fns) {
      if (!F->isDeclaration()) {
        if (cupbop_debug()) std::cout << "[cp.async→DXA] Removing wrapper body: " << F->getName().str() << "\n";
        F->deleteBody();
      }
    }
  }

  // Emit descriptor metadata as sidecar file for runtime auto-programming.
  // Traces gmem pointers to kernel args, writes dxa_descriptors.txt. TESTED+PASSED.
  if (!copy_calls_orig.empty()) {
    // Trace global memory pointers back to kernel function arguments
    auto traceToArgIdx = [](Value *V) -> int {
      std::set<Value*> visited;
      while (V && visited.insert(V).second) {
        if (auto *Arg = dyn_cast<Argument>(V)) return Arg->getArgNo();
        if (auto *GEP = dyn_cast<GetElementPtrInst>(V)) V = GEP->getPointerOperand();
        else if (auto *BC = dyn_cast<BitCastInst>(V)) V = BC->getOperand(0);
        else if (auto *ASC = dyn_cast<AddrSpaceCastInst>(V)) V = ASC->getPointerOperand();
        else if (auto *LI = dyn_cast<LoadInst>(V)) {
          auto *ptr = LI->getPointerOperand();
          if (auto *AI = dyn_cast<AllocaInst>(ptr)) {
            for (auto *U : AI->users()) {
              if (auto *SI = dyn_cast<StoreInst>(U)) { V = SI->getValueOperand(); break; }
            }
          } else break;
        }
        else if (auto *PHI = dyn_cast<PHINode>(V)) V = PHI->getIncomingValue(0);
        else break;
      }
      return -1;
    };

    // Find integer arguments (likely dimensions: M, N, K)
    std::vector<int> dim_args;
    for (auto &Arg : kernelFn->args()) {
      if (Arg.getType()->isIntegerTy()) dim_args.push_back(Arg.getArgNo());
    }

    // Extract tile size from blockIdxTile map
    uint32_t tile_size = 16;
    for (auto &[dim, val] : blockIdxTile) {
      if (auto *Mul = dyn_cast<BinaryOperator>(val)) {
        for (int op = 0; op < 2; op++) {
          if (auto *CInt = dyn_cast<ConstantInt>(Mul->getOperand(op))) {
            tile_size = CInt->getZExtValue();
            break;
          }
        }
        break;
      }
    }

    // Infer element bytes from kernel name
    uint32_t elem_bytes = 4;
    if (kernelFn->getName().contains("half") || kernelFn->getName().contains("6__half"))
      elem_bytes = 2;

    // Write sidecar file
    std::ofstream dxa_ofs("dxa_descriptors.txt");
    if (dxa_ofs.is_open()) {
      dxa_ofs << "# kernel_name slot ptr_arg dim0_arg dim1_arg tile0 tile1 elem_bytes\n";
      for (size_t i = 0; i < copy_calls_orig.size(); i++) {
        int ptr_arg = traceToArgIdx(copy_calls_orig[i].gmem_src);
        int dim0_arg = -1, dim1_arg = -1;
        if (dim_args.size() >= 3) {
          if (i == 0) { dim0_arg = dim_args[2]; dim1_arg = dim_args[0]; } // A: K, M
          else { dim0_arg = dim_args[1]; dim1_arg = dim_args[2]; }        // B: N, K
        } else if (!dim_args.empty()) {
          dim0_arg = dim1_arg = dim_args[0]; // square
        }
        dxa_ofs << kernelFn->getName().str() << " " << i << " " << ptr_arg << " "
                << dim0_arg << " " << dim1_arg << " "
                << tile_size << " " << tile_size << " " << elem_bytes << "\n";
        if (cupbop_debug()) std::cout << "[cp.async→DXA] Desc meta: slot=" << i << " ptr_arg=" << ptr_arg
                  << " dim0=" << dim0_arg << " dim1=" << dim1_arg
                  << " tile=" << tile_size << " elem=" << elem_bytes << "\n" << std::flush;
      }
      dxa_ofs.close();
    }
  }
}

void replace_wmma_intrinsics(llvm::Module *M) {
  using namespace llvm;

  LLVMContext &Ctx = M->getContext();
  auto *F32Ty = Type::getFloatTy(Ctx);

  // Collect all wmma intrinsic calls
  std::vector<CallInst *> wmma_calls;
  for (auto &F : *M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          if (!CI->getCalledFunction()) continue;
          auto name = CI->getCalledFunction()->getName().str();
          if (name.find("llvm.nvvm.wmma") != std::string::npos) {
            wmma_calls.push_back(CI);
          }
        }
      }
    }
  }

  if (wmma_calls.empty()) return;

  if (cupbop_debug()) printf("[wmma] Found %zu wmma intrinsic calls to translate\n", wmma_calls.size());

  // Helper: get thread lane ID for wmma cooperative load/store
  // SCHE_2: threadIdx struct field 0, SCHE_0: thread_id_x TLS
  auto getThreadLaneID = [&](IRBuilder<> &B) -> Value* {
    auto *I32Ty = Type::getInt32Ty(Ctx);
    // Try threadIdx struct (SCHE_2)
    auto *threadIdxGV = M->getGlobalVariable("threadIdx");
    if (threadIdxGV) {
      auto tls = B.CreateCall(
          Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address, {threadIdxGV->getType()}),
          {threadIdxGV});
      auto field_ptr = B.CreateStructGEP(threadIdxGV->getValueType(), tls, 0);
      return B.CreateLoad(I32Ty, field_ptr, "lane");
    }
    // Fallback: thread_id_x TLS
    auto *tidGV = M->getGlobalVariable("thread_id_x");
    if (tidGV) {
      if (tidGV->isThreadLocal()) {
        auto tls = B.CreateCall(
            Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address, {tidGV->getType()}),
            {tidGV});
        return B.CreateLoad(I32Ty, tls, "lane");
      }
      return B.CreateLoad(I32Ty, tidGV, "lane");
    }
    return ConstantInt::get(I32Ty, 0);
  };

  for (auto *CI : wmma_calls) {
    auto name = CI->getCalledFunction()->getName().str();
    IRBuilder<> Builder(CI);

    if (cupbop_debug()) printf("[wmma] Translating: %s\n", name.c_str());

    if (name.find(".mma.") != std::string::npos) {
      // mma_sync: the core TCU operation
      // Intrinsic for m16n16k16.mma.row.row.f32.f32:
      //   ({float x8}) @llvm.nvvm.wmma.m16n16k16.mma.row.row.f32.f32(
      //     <2 x half> %a0..%a7, <2 x half> %b0..%b7, float %c0..%c7)
      // Total: 8(A) + 8(B) + 8(C) = 24 args, returns {float x8}
      //
      // Translation to Vortex TCU:
      // 1. Bitcast A values (<2 x half> -> float)
      // 2. Bitcast B values (<2 x half> -> float)
      // 3. Place in f0-f7(C), f10-f17(A), f24-f31(B)
      // 4. Execute: .insn r 0x0B, 0, 2, x0, x1, x0
      // 5. Read results from f0-f7

      unsigned numArgs = CI->arg_size();
      if (numArgs != 24) {
        if (cupbop_debug()) printf("[wmma] WARNING: mma_sync has %u args (expected 24), skipping\n", numArgs);
        continue;
      }

      // Extract A operands (args 0-7): <2 x half> -> bitcast to float
      std::vector<Value *> a_regs(8);
      for (int i = 0; i < 8; i++) {
        Value *arg = CI->getArgOperand(i);
        a_regs[i] = Builder.CreateBitCast(arg, F32Ty, "wmma.a." + std::to_string(i));
      }

      // Extract B operands (args 8-15): <2 x half> -> bitcast to float
      std::vector<Value *> b_regs(8);
      for (int i = 0; i < 8; i++) {
        Value *arg = CI->getArgOperand(8 + i);
        b_regs[i] = Builder.CreateBitCast(arg, F32Ty, "wmma.b." + std::to_string(i));
      }

      // Extract C operands (args 16-23): float
      std::vector<Value *> c_regs(8);
      for (int i = 0; i < 8; i++) {
        c_regs[i] = CI->getArgOperand(16 + i);
      }

      // Build inline assembly for Vortex TCU custom instruction
      // Register allocation: f0-f7(C/D), f10-f17(A), f24-f31(B)
      std::string asmStr = ".insn r 0x0b, 0, 2, x0, x1, x0";

      std::string constraints =
        "=&{f0},=&{f1},=&{f2},=&{f3},=&{f4},=&{f5},=&{f6},=&{f7},"
        "{f10},{f11},{f12},{f13},{f14},{f15},{f16},{f17},"
        "{f24},{f25},{f26},{f27},{f28},{f29},{f30},{f31},"
        "0,1,2,3,4,5,6,7";

      std::vector<Type *> resultTypes(8, F32Ty);
      auto *resultTy = StructType::get(Ctx, resultTypes);

      std::vector<Value *> asmArgs;
      for (int i = 0; i < 8; i++) asmArgs.push_back(a_regs[i]);
      for (int i = 0; i < 8; i++) asmArgs.push_back(b_regs[i]);
      for (int i = 0; i < 8; i++) asmArgs.push_back(c_regs[i]);

      std::vector<Type *> inputTypes;
      for (auto *v : asmArgs) inputTypes.push_back(v->getType());

      auto *asmFTy = FunctionType::get(resultTy, inputTypes, false);
      auto *inlineAsm = InlineAsm::get(asmFTy, asmStr, constraints, true);
      auto *asmCall = Builder.CreateCall(inlineAsm, asmArgs, "wmma.mma.result");

      CI->replaceAllUsesWith(asmCall);
      CI->eraseFromParent();

    } else if (name.find(".load.a.") != std::string::npos) {
      // load_matrix_sync for A fragment (row-major, fp16)
      // Intrinsic: (ptr, i32 stride) -> {<2 x half> x 8}
      // Vortex layout (NT=32): block_row = lane/4, block_col = (lane%4)*2
      // Per register r: row = block_row + (r/4)*8, col = block_col + (r%4)*2
      // Load 2 contiguous fp16 as <2 x half>
      if (cupbop_debug()) printf("[wmma] Translating load A\n");

      Value *ptr = CI->getArgOperand(0);
      Value *stride = CI->getArgOperand(1);
      auto *I32Ty = Type::getInt32Ty(Ctx);
      auto *I64Ty = Type::getInt64Ty(Ctx);
      auto *HalfTy = Type::getHalfTy(Ctx);
      auto *V2HalfTy = FixedVectorType::get(HalfTy, 2);

      Value *lane = getThreadLaneID(Builder);

      Value *block_row = Builder.CreateUDiv(lane, ConstantInt::get(I32Ty, 4), "block_row");
      Value *block_col = Builder.CreateMul(
          Builder.CreateURem(lane, ConstantInt::get(I32Ty, 4)), ConstantInt::get(I32Ty, 2), "block_col");

      // Build result struct
      Value *result = UndefValue::get(CI->getType());
      for (int r = 0; r < 8; r++) {
        Value *elem_row = Builder.CreateAdd(block_row,
            ConstantInt::get(I32Ty, (r / 4) * 8), "erow");
        Value *elem_col = Builder.CreateAdd(block_col,
            ConstantInt::get(I32Ty, (r % 4) * 8), "ecol");
        // offset = elem_row * stride + elem_col
        Value *offset = Builder.CreateAdd(
            Builder.CreateMul(elem_row, stride), elem_col, "off");
        Value *offset64 = Builder.CreateSExt(offset, I64Ty);
        Value *gep = Builder.CreateGEP(HalfTy, ptr, offset64, "gep");
        // Load 2 contiguous fp16
        Value *h0 = Builder.CreateLoad(HalfTy, gep, "h0");
        Value *gep1 = Builder.CreateGEP(HalfTy, gep, ConstantInt::get(I64Ty, 1), "gep1");
        Value *h1 = Builder.CreateLoad(HalfTy, gep1, "h1");
        Value *vec = Builder.CreateInsertElement(UndefValue::get(V2HalfTy), h0, (uint64_t)0);
        vec = Builder.CreateInsertElement(vec, h1, (uint64_t)1, "v2h");
        result = Builder.CreateInsertValue(result, vec, r, "frag.a");
      }
      CI->replaceAllUsesWith(result);
      CI->eraseFromParent();

    } else if (name.find(".load.b.") != std::string::npos) {
      // load_matrix_sync for B fragment (row-major, fp16)
      // Vortex layout (NT=32): block_idx = lane/16, lane_in_blk = lane%16
      // block_col = lane_in_blk/4 + block_idx*4, block_row = (lane_in_blk%4)*2
      // Per register r: k_off = (r/2)*8, n_off = (r%2)*8
      // Load 2 fp16 from consecutive rows
      if (cupbop_debug()) printf("[wmma] Translating load B\n");

      Value *ptr = CI->getArgOperand(0);
      Value *stride = CI->getArgOperand(1);
      auto *I32Ty = Type::getInt32Ty(Ctx);
      auto *I64Ty = Type::getInt64Ty(Ctx);
      auto *HalfTy = Type::getHalfTy(Ctx);
      auto *V2HalfTy = FixedVectorType::get(HalfTy, 2);

      Value *lane = getThreadLaneID(Builder);

      Value *block_idx = Builder.CreateUDiv(lane, ConstantInt::get(I32Ty, 16), "bidx");
      Value *lane_in_blk = Builder.CreateURem(lane, ConstantInt::get(I32Ty, 16), "linb");
      Value *block_col = Builder.CreateAdd(
          Builder.CreateUDiv(lane_in_blk, ConstantInt::get(I32Ty, 4)),
          Builder.CreateMul(block_idx, ConstantInt::get(I32Ty, 4)), "bcol");
      Value *block_row = Builder.CreateMul(
          Builder.CreateURem(lane_in_blk, ConstantInt::get(I32Ty, 4)),
          ConstantInt::get(I32Ty, 2), "brow");

      Value *result = UndefValue::get(CI->getType());
      for (int r = 0; r < 8; r++) {
        Value *row = Builder.CreateAdd(block_row,
            ConstantInt::get(I32Ty, (r / 2) * 8), "row");
        Value *col = Builder.CreateAdd(block_col,
            ConstantInt::get(I32Ty, (r % 2) * 8), "col");
        // Load h0 at (row, col), h1 at (row+1, col)
        Value *off0 = Builder.CreateAdd(Builder.CreateMul(row, stride), col);
        Value *off0_64 = Builder.CreateSExt(off0, I64Ty);
        Value *gep0 = Builder.CreateGEP(HalfTy, ptr, off0_64, "gep0");
        Value *h0 = Builder.CreateLoad(HalfTy, gep0, "h0");
        Value *off1 = Builder.CreateAdd(off0, stride); // next row
        Value *off1_64 = Builder.CreateSExt(off1, I64Ty);
        Value *gep1 = Builder.CreateGEP(HalfTy, ptr, off1_64, "gep1");
        Value *h1 = Builder.CreateLoad(HalfTy, gep1, "h1");
        Value *vec = Builder.CreateInsertElement(UndefValue::get(V2HalfTy), h0, (uint64_t)0);
        vec = Builder.CreateInsertElement(vec, h1, (uint64_t)1, "v2h");
        result = Builder.CreateInsertValue(result, vec, r, "frag.b");
      }
      CI->replaceAllUsesWith(result);
      CI->eraseFromParent();

    } else if (name.find(".load.c.") != std::string::npos) {
      // load accumulator C (fp32)
      // Layout: block_row = lane/4, block_col = lane%4
      // Per register r: row = block_row + (r/4)*8, col = block_col + (r%4)*4
      if (cupbop_debug()) printf("[wmma] Translating load C\n");

      Value *ptr = CI->getArgOperand(0);
      Value *stride = CI->getArgOperand(1);
      auto *I32Ty = Type::getInt32Ty(Ctx);
      auto *I64Ty = Type::getInt64Ty(Ctx);

      Value *lane = getThreadLaneID(Builder);

      Value *block_row = Builder.CreateUDiv(lane, ConstantInt::get(I32Ty, 4), "block_row");
      Value *block_col = Builder.CreateURem(lane, ConstantInt::get(I32Ty, 4), "block_col");

      Value *result = UndefValue::get(CI->getType());
      for (int r = 0; r < 8; r++) {
        Value *row = Builder.CreateAdd(block_row, ConstantInt::get(I32Ty, (r / 4) * 8), "row");
        Value *col = Builder.CreateAdd(block_col, ConstantInt::get(I32Ty, (r % 4) * 4), "col");
        Value *offset = Builder.CreateAdd(Builder.CreateMul(row, stride), col);
        Value *offset64 = Builder.CreateSExt(offset, I64Ty);
        Value *gep = Builder.CreateGEP(F32Ty, ptr, offset64, "gep");
        Value *val = Builder.CreateLoad(F32Ty, gep, "c_val");
        result = Builder.CreateInsertValue(result, val, r, "frag.c");
      }
      CI->replaceAllUsesWith(result);
      CI->eraseFromParent();

    } else if (name.find(".store.d.") != std::string::npos) {
      // store_matrix_sync for D (fp32, row-major)
      // Intrinsic: (ptr, float x8, i32 stride) -> void
      // Same layout as load C
      if (cupbop_debug()) printf("[wmma] Translating store D\n");

      Value *ptr = CI->getArgOperand(0);
      // Args 1-8 are the 8 float values, arg 9 is stride
      unsigned numArgs = CI->arg_size();
      Value *stride = CI->getArgOperand(numArgs - 1);
      auto *I32Ty = Type::getInt32Ty(Ctx);
      auto *I64Ty = Type::getInt64Ty(Ctx);

      Value *lane = getThreadLaneID(Builder);

      Value *block_row = Builder.CreateUDiv(lane, ConstantInt::get(I32Ty, 4), "block_row");
      Value *block_col = Builder.CreateURem(lane, ConstantInt::get(I32Ty, 4), "block_col");

      for (int r = 0; r < 8; r++) {
        Value *val = CI->getArgOperand(1 + r); // float values start at arg 1
        Value *row = Builder.CreateAdd(block_row, ConstantInt::get(I32Ty, (r / 4) * 8), "row");
        Value *col = Builder.CreateAdd(block_col, ConstantInt::get(I32Ty, (r % 4) * 4), "col");
        Value *offset = Builder.CreateAdd(Builder.CreateMul(row, stride), col);
        Value *offset64 = Builder.CreateSExt(offset, I64Ty);
        Value *gep = Builder.CreateGEP(F32Ty, ptr, offset64, "gep");
        Builder.CreateStore(val, gep);
      }
      CI->eraseFromParent();

    } else {
      if (cupbop_debug()) printf("[wmma] WARNING: unhandled wmma intrinsic: %s\n", name.c_str());
    }
  }
}