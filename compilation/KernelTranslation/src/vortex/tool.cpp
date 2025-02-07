#include "tool.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Config/llvm-config.h"
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
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorOr.h"
#include "llvm/Support/FileSystem.h"

// LLVM 18
//#include "llvm/Support/ManagedStatic.h"
//#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Pass.h"
#include "llvm/IR/Type.h"

#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"


#include <iostream>
#include <set>

using namespace llvm;

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
  llvm::FunctionType *LauncherFuncT = llvm::FunctionType::get(
      llvm::Type::getVoidTy(M->getContext()),
      { llvm::Type::getInt32Ty(M->getContext()) },
      false
  );
  
  llvm::FunctionCallee f =
      M->getOrInsertFunction("llvm.nvvm.bar.warp.sync", LauncherFuncT);
  
  llvm::Function *F = llvm::cast<llvm::Function>(f.getCallee());

  llvm::Constant *AllActiveMask = llvm::ConstantInt::get(
      llvm::Type::getInt32Ty(M->getContext()),
      0xFFFFFFFF
  );

  return llvm::CallInst::Create(F, { AllActiveMask }, "", InsertBefore);
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

  llvm::Instruction *loadedValue = createLoad(builder, alloca);//builder.CreateLoad(alloca);
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
      printf("--------------------\n");
      std::cout<<I<<std::endl;
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
      //dynamic_shared_memory_addr->getType()->getPointerElementType(),
      dynamic_shared_memory_addr->getValueType(),
        dynamic_shared_memory_addr, "new_load", &*F->begin()->begin());
    auto new_bit_cast =
        new BitCastInst(load_shared_memory,
                        dynamic_shared_memory_addr->getType(), "new_bit_cast");
    //CHECK NEEDED
    //(new)new_bit_cast->insertAfter(load_shared_memory);                        
    //(old)new_bit_cast->insertBefore(&*F->begin()->begin());
    //(old)load_shared_memory->insertBefore(new_bit_cast);
    dynamic_shared_memory_addr->replaceUsesWithIf(new_bit_cast, [&](Use &U) {
      auto *Instr = dyn_cast<Instruction>(U.getUser());
      return Instr != new_bit_cast && Instr != load_shared_memory;
    });
  }
}

void replace_built_in_function(llvm::Module *M) {
  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);
  std::vector<llvm::Instruction *> need_remove;
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();
    if (!isKernelFunction(M, F))
      continue;

    IRBuilder<> builder(&*(F->getEntryBlock().getFirstInsertionPt()));
    auto global_intra_warp_idx =
        F->getParent()->getGlobalVariable("intra_warp_index");
    auto local_intra_warp_idx =
        //LLVM 18 
        //builder.CreateAlloca(global_intra_warp_idx->getType()->getElementType(),
        //                     0, "local_intra_warp_idx");
         builder.CreateAlloca(global_intra_warp_idx->getValueType(), 0, "local_intra_warp_idx");
    global_intra_warp_idx->replaceUsesWithIf(local_intra_warp_idx, [&](Use &U) {
      auto *Instr = dyn_cast<Instruction>(U.getUser());
      return Instr->getParent()->getParent()->getName().str() == func_name;
    });

    auto global_inter_warp_idx =
        F->getParent()->getGlobalVariable("inter_warp_index");

    //LLVM 18
    auto local_inter_warp_idx =
    builder.CreateAlloca(
        global_inter_warp_idx->getValueType(), 0, "local_inter_warp_idx");
        //builder.CreateAlloca(global_inter_warp_idx->getType()->getElementType(),
        //                     0, "local_inter_warp_idx");

    builder.CreateStore(ConstantInt::get(I32, 0), local_inter_warp_idx);

    global_inter_warp_idx->replaceUsesWithIf(local_inter_warp_idx, [&](Use &U) {
      auto *Instr = dyn_cast<Instruction>(U.getUser());
      return Instr->getParent()->getParent()->getName().str() == func_name;
    });
  
    printf(" replacing built-in functions\n");

    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Load = dyn_cast<LoadInst>(BI)) {
          auto load_from = Load->getOperand(0);
        } else if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->getCalledFunction()) {
            auto func_name = Call->getCalledOperand()->getName().str();
            // Mark: Temporarily commented out the _ZN25 function, we don't think it's being used in vortex
            if (func_name == "llvm.nvvm.read.ptx.sreg.ntid.x" ){//||
                //func_name ==
                //    "_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv") {
              auto block_size_addr = M->getGlobalVariable("block_size_x");
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              auto val = createLoad(builder, block_size_addr);
              Call->replaceAllUsesWith(val);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.ntid.y") {
              auto block_size_addr = M->getGlobalVariable("block_size_y");
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              auto val = createLoad(builder, block_size_addr);
              Call->replaceAllUsesWith(val);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.ntid.z") {
              auto block_size_addr = M->getGlobalVariable("block_size_z");
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              auto val = createLoad(builder, block_size_addr);
              Call->replaceAllUsesWith(val);
              need_remove.push_back(Call);
            }
            // Mark: Temporarily commented out the _ZN25 function, we don't think it's being used in vortex
             else if (func_name == "llvm.nvvm.read.ptx.sreg.tid.x" ){//||
              //         func_name == "_ZN26__cuda_builtin_threadIdx_t17__fetch_"
              //                      "builtin_xEv") {
              // replace it by warp_id

              // Mark: printing out the warp_idx values
              // printf("global_intra_warp_idx is : %d \n", global_intra_warp_idx);
              // printf("global_inter_warp_idx is : %d \n", global_inter_warp_idx);

                  auto block_size_x_tmp = M->getGlobalVariable("block_size_x");
                  errs() << block_size_x_tmp;
                  
                  Constant* const_intra_warp_idx = global_intra_warp_idx->getInitializer();
                  Constant* const_inter_warp_idx = global_inter_warp_idx->getInitializer();
                  //Constant* const_block_size_x = block_size_x_tmp->getInitializer();

                  ConstantInt* con_intra_warp_idx = cast<ConstantInt>(const_intra_warp_idx);
                  ConstantInt* con_inter_warp_idx = cast<ConstantInt>(const_inter_warp_idx);
                  //ConstantInt* con_block_size_x = cast<ConstantInt>(const_block_size_x);

                  int32_t int_intra_warp_idx = con_intra_warp_idx->getSExtValue(); //changed to 32
                  int32_t int_inter_warp_idx = con_inter_warp_idx->getSExtValue();
                  //int64_t int_block_size_x = con_block_size_x->getSExtValue();

                  printf("intra warp corresponding value is : %d \n", int_intra_warp_idx);
                  printf("inter warp corresponding value is : %d \n", int_inter_warp_idx);
                  //printf("block size x corresponding value is : %ld \n", int_block_size_x);

              // Mark Debug: Until here (printing out warp_idx values)

              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);

              auto thread_idx = builder.CreateBinOp(
                  Instruction::Mul, createLoad(builder, local_inter_warp_idx),
                  ConstantInt::get(I32, 32), ""); // Mark temp  (changed 32 -> 4)
              thread_idx = builder.CreateBinOp(
                  //Instruction::Add, builder.CreateLoad(local_intra_warp_idx),
                  Instruction::Add, createLoad(builder, local_intra_warp_idx),
                  thread_idx, "thread_idx");

              thread_idx = builder.CreateBinOp(
                  Instruction::SRem, thread_idx,
                  createLoad(builder, M->getGlobalVariable("block_size_x")),
                  "thread_id_x");

                  // Add metadata to indicate non-uniformity
              MDNode* N = MDNode::get(context, MDString::get(context, "non-uniform"));
              cast<Instruction>(thread_idx)->setMetadata("divergence", N);


              Call->replaceAllUsesWith(thread_idx);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.tid.y") {
              // replace it by warp_id
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);

              auto thread_idx = builder.CreateBinOp(
                  Instruction::Mul, createLoad(builder, local_inter_warp_idx),
                  ConstantInt::get(I32, 4), ""); // Mark temp  (changed 32 -> 4)
              thread_idx = builder.CreateBinOp(
                  Instruction::Add, createLoad(builder, local_intra_warp_idx),
                  thread_idx, "thread_idx");
              // tidy = tid / block_dim.x
              thread_idx = builder.CreateBinOp(
                  Instruction::SDiv, thread_idx,
                  createLoad(builder, M->getGlobalVariable("block_size_x")),
                  "thread_id_y");
              
                  // Add metadata to indicate non-uniformity
              MDNode* N = MDNode::get(context, MDString::get(context, "non-uniform"));
              cast<Instruction>(thread_idx)->setMetadata("divergence", N);

              
              Call->replaceAllUsesWith(thread_idx);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.tid.z") {
              printf("[WARNING] We DO NOT support triple-dim block\n");
              exit(1);
              auto zero = ConstantInt::get(I32, 0);
              Call->replaceAllUsesWith(zero);
              need_remove.push_back(Call);
            }
            // Mark: Temporarily commented out the _ZN25 function, we don't think it's being used in vortex 
            

            else if (func_name == "llvm.nvvm.read.ptx.sreg.ctaid.x" ){//||
                       //func_name == "_ZN25__cuda_builtin_blockIdx_t17__fetch_"
                       //             "builtin_xEv") {
              /* replace this with what??? */  // hyesoon 
              printf("block_Id-X is called\n");
              auto block_index_addr = M->getGlobalVariable("block_index_x");
              IRBuilder<> builder(context);
              MDNode* N = MDNode::get(context, MDString::get(context, "non-uniform"));
              builder.SetInsertPoint(Call);
              auto block_idx = createLoad(builder, block_index_addr);
              // print block_idx instruction
              

              block_idx->setMetadata("divergence", N);

              llvm::errs() << "block_idx instruction\n";
              block_idx->print(llvm::errs());
              
              Call->replaceAllUsesWith(block_idx);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.ctaid.y") {
              printf("block_Id-Y is called\n");
              auto block_index_addr = M->getGlobalVariable("block_index_y");
              IRBuilder<> builder(context);
              MDNode* N = MDNode::get(context, MDString::get(context, "non-uniform"));
              builder.SetInsertPoint(Call);
              auto block_idx = createLoad(builder, block_index_addr);
              block_idx->setMetadata("divergence", N);
              Call->replaceAllUsesWith(block_idx);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.ctaid.z") {
              printf("block_Id-Z is called\n");
              auto block_index_addr = M->getGlobalVariable("block_index_z");
              IRBuilder<> builder(context);
              MDNode* N = MDNode::get(context, MDString::get(context, "non-uniform"));
              builder.SetInsertPoint(Call);
              auto block_idx = createLoad(builder, block_index_addr);
              block_idx->setMetadata("divergence", N);
              Call->replaceAllUsesWith(block_idx);
              need_remove.push_back(Call);
            }
            // Mark: Temporarily commented out the _ZN25 function, we don't think it's being used in vortex
             else if (func_name == "llvm.nvvm.read.ptx.sreg.nctaid.x" ){// ||
                       //func_name == "_ZN24__cuda_builtin_gridDim_t17__fetch_"
                       //             "builtin_xEv") {
              auto grid_size_addr = M->getGlobalVariable("grid_size_x");
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              auto grid_size = createLoad(builder, grid_size_addr);
              Call->replaceAllUsesWith(grid_size);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.nctaid.y") {
              auto grid_size_addr = M->getGlobalVariable("grid_size_y");
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              auto grid_size = createLoad(builder, grid_size_addr);
              Call->replaceAllUsesWith(grid_size);
              need_remove.push_back(Call);
            } else if (func_name == "llvm.nvvm.read.ptx.sreg.nctaid.z") {
              auto grid_size_addr = M->getGlobalVariable("grid_size_z");
              IRBuilder<> builder(context);
              builder.SetInsertPoint(Call);
              auto grid_size = createLoad(builder, grid_size_addr);
              Call->replaceAllUsesWith(grid_size);
              need_remove.push_back(Call);
            }
          }
          if (Call->isInlineAsm()) {
            auto asm_inst = dyn_cast<InlineAsm>(Call->getCalledOperand());
            if (asm_inst->getAsmString() != "mov.u32 $0, %laneid;") {
              printf("unknown InlineAsm\n");
              exit(1);
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
              /*
               * replace CUDA's printf to Vortex's vx_printf (same as c's printf)
               * CUDA:
               * %0 = tail call i32 @vprintf(i8* getelementptr inbounds ([19 x
               * i8], [19 x i8]* @.str, i64 0, i64 0), i8* null)
               * C: %call1 = call i32 (i8*, ...) @printf(i8* getelementptr
               * inbounds ([45 x i8], [45 x i8]* @.str.1, i64 0, i64 0))
               * Vortex: %84 = call i32 (i8*, ...) @vx_printf(i8* getelementptr inbounds ([20 x i8], [20 x i8]* @.str.1, i64 0, i64 0), i32 %83), !dbg !159
                       * %67 = call i32 (i8*, ...) @vx_printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @.str, i64 0, i64 0), i32 %66)
               */
              // find/create C's printf function
              std::vector<llvm::Type *> args;
              //LLVM 18
              args.push_back(PointerType::getUnqual(context));
              //args.push_back(llvm::Type::getInt8PtrTy(context));
              llvm::FunctionType *printfType =
                  FunctionType::get(I32, args, true);

              llvm::FunctionCallee _f =
                  M->getOrInsertFunction("vx_printf", printfType);
              llvm::Function *func_printf =
                  llvm::cast<llvm::Function>(_f.getCallee());
              // construct argument(s)
              std::vector<Value *> printf_args;
              // first argument is same between CUDA and C

              //auto placeholder = Call->getArgOperand(0);
              //printf_args.push_back(placeholder);
              for (auto &Arg : Call->args()) {
                //check Arg is a GEP
                if (auto GEP = dyn_cast<GetElementPtrInst>(Arg)) {
                  Type *ElemTy;
                  if (GEP->getType()->isOpaquePointerTy()) {
                  // For opaque pointers, we need to get the element type from the GEP instruction
                  ElemTy = GEP->getSourceElementType();
                  }
                  else{
                    printf("Error: printf GEP operands is not opaque pointer\n");
                exit(1);
                  }
                  //load 를 만들고 그걸로 print 넣기
                  auto new_load =
                      new LoadInst(ElemTy,
                                   GEP, "", Call);
                  printf_args.push_back(new_load);
                  } else {
                      printf_args.push_back(Arg);
                      //LLVM_DEBUG(dbgs() << "Added original argument of type: " << *Arg->getType() << "\n");
                  }
              }



              // insert arguments

              // New try with legacy prior LLVM18 code
              /*
              auto compressed_args = Call->getArgOperand(1);
              if (auto BC = dyn_cast<BitCastInst>(compressed_args)) {
                auto src_alloc = BC->getOperand(0);
                auto SrcPointTy = dyn_cast<PointerType>(BC->getOperand(0)->getType());
                auto SrcTy = SrcPointTy->getPointerElementType();
                // reverse the bitcast
                auto reverse_BC = new BitCastInst(BC, SrcPointTy, "", Call);
                assert(SrcTy->isStructTy() == 1);
                auto StructTy = dyn_cast<StructType>(SrcTy);
                for (int i = 0; i < StructTy->getNumElements(); i++) {
                  std::vector<Value *> Indices;
                  Indices.push_back(ConstantInt::get(I32, 0));
                  Indices.push_back(ConstantInt::get(I32, i));
                  auto new_GEP = GetElementPtrInst::Create(
                    cast<PointerType>(src_alloc->getType()->getScalarType())
                          ->getPointerElementType(), // Pointee type
                                                           src_alloc, // Alloca
                                                           Indices,   // Indices
                                                           "", Call);
                  auto new_load =
                      new LoadInst(new_GEP->getType()->getPointerElementType(),
                                   new_GEP, "", Call);
                  printf_args.push_back(new_load);
                  
              */
              // legacy code before LLVM 18 
              /*
              auto compressed_args = Call->getArgOperand(1);
              if (auto BC = dyn_cast<BitCastInst>(compressed_args)) {
                auto src_alloc = BC->getOperand(0);
                auto SrcPointTy = dyn_cast<PointerType>(BC->getOperand(0)->getType());
                auto SrcTy = SrcPointTy->getPointerElementType();
                // reverse the bitcast
                auto reverse_BC = new BitCastInst(BC, SrcPointTy, "", Call);
                assert(SrcTy->isStructTy() == 1);
                auto StructTy = dyn_cast<StructType>(SrcTy);
                for (int i = 0; i < StructTy->getNumElements(); i++) {
                  std::vector<Value *> Indices;
                  Indices.push_back(ConstantInt::get(I32, 0));
                  Indices.push_back(ConstantInt::get(I32, i));
                  auto new_GEP = GetElementPtrInst::Create(
                    cast<PointerType>(src_alloc->getType()->getScalarType())
                          ->getPointerElementType(), // Pointee type
                                                           src_alloc, // Alloca
                                                           Indices,   // Indices
                                                           "", Call);
                  auto new_load =
                      new LoadInst(new_GEP->getType()->getPointerElementType(),
                                   new_GEP, "", Call);
                  printf_args.push_back(new_load);
              */
                  

              //print the whole call instruction (Call)



              /*
              auto allocaInst = dyn_cast<AllocaInst>(Call->getArgOperand(1));
              if (!allocaInst) {
                // check if allocaInst is nullptr
                if(isa<ConstantPointerNull>(Call->getArgOperand(1)))
                printf("warning: the second argument for CUDA print is a null pointer");
                //create ptr noundef

                //else{
                //printf("Error: the second arguments for CUDA printf is not an "
                //       "allocaInst\n");
                //exit(1);}
              }
              */


              /*
              if(!isa<ConstantPointerNull>(Call->getArgOperand(1)))
              {
                for (User *U : allocaInst->users()) {
                  if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(U)) {
                    if (ConstantInt *Index =
                            dyn_cast<ConstantInt>(GEP->getOperand(2))) {
                      unsigned ArgIndex = Index->getZExtValue();
                      // Find the store instruction that uses this GEP
                      for (User *GU : GEP->users()) {
                        if (StoreInst *Store = dyn_cast<StoreInst>(GU)) {
                          Value *Arg = Store->getValueOperand();
                          if (printf_args.size() < ArgIndex + 2)
                            printf_args.resize(ArgIndex + 2);
                          // The first argument is the format string,
                          // so we need to skip it
                          printf_args[ArgIndex + 1] = Arg;
                        }
                      }
                    }
                  }
                }
              }
              */
              auto c_printf_inst =
                  llvm::CallInst::Create(func_printf, printf_args, "", Call);
              // insert
              Call->replaceAllUsesWith(c_printf_inst);
              Call->print(errs());
              //print Call->getArgOperand(1)
              Call->getArgOperand(1)->print(errs());
              //print the entire module
              M->print(errs(), nullptr);
              need_remove.push_back(Call);
            } else if (func_name == "__nv_fast_log2f" ||
                       func_name == "__nv_log2f" ||
                       func_name == "__nv_fast_powf" ||
                       func_name == "__nv_powf" || func_name == "__nv_logf" ||
                       func_name == "__nv_expf" || func_name == "__nv_fabsf" ||
                       func_name == "__nv_log10f" ||
                       func_name == "__nv_fmodf" || func_name == "__nv_sqrt" ||
                       func_name == "__nv_sqrtf" || func_name == "__nv_exp" ||
                       func_name == "__nv_isnanf" ||
                       func_name == "__nv_isinff" || func_name == "__nv_powi" ||
                       func_name == "__nv_powif") {
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
            } else if (func_name == "llvm.nvvm.fabs.f") {
              Call->getCalledFunction()->setName("__nvvm_fabs_f");
            } else if (func_name == "llvm.nvvm.mul24.i") {
              Call->getCalledFunction()->setName("__nvvm_mul24_i");
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

void replace_asm_call(llvm::Module *M) {
  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);
  std::vector<CallInst *> need_remove;
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();
    if (!isKernelFunction(M, F))
      continue;

    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->isInlineAsm()) {
            auto asm_inst = dyn_cast<InlineAsm>(Call->getCalledOperand());
            if (asm_inst->getAsmString() != "mov.u32 $0, %laneid;") {
              printf("unknown InlineAsm\n");
              exit(1);
            }
            // return the rank within the warp
            IRBuilder<> builder(context);
            builder.SetInsertPoint(Call);
            auto intra_warp_index_addr =
                M->getGlobalVariable("intra_warp_index");
            auto intra_warp_index = createLoad(builder, intra_warp_index_addr);
            Call->replaceAllUsesWith(intra_warp_index);
            need_remove.push_back(Call);
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
      if (func_name == "llvm.nvvm.bar.warp.sync") {
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
      if (func_name == "llvm.nvvm.barrier0" ||
          func_name == "llvm.nvvm.bar.warp.sync" ||
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

/*
  Print IR Module for Debugging Purposes
*/
void printIR(llvm::Module *module_) {
 std::string module_str;
 llvm::raw_string_ostream ostream{module_str};
 module_->print(ostream, nullptr, false);
 std::cout << module_str << std::endl;
}

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
  //return B.CreateLoad(addr->getType()->getPointerElementType(), addr,
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
  //return B.CreateInBoundsGEP(
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
  //return B.CreateGEP(ptr->getType()->getScalarType()->getPointerElementType(),
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
    //LLVM 18, temporarily disabled (Link issue to be fixed)
    //ptr->dump();
    errs() << "Unable to determine element type for ptr in createGEP\n";
    return nullptr;
  }
  if (!elementType) {
    errs() << "Element type is null for ptr in createGEP\n";
    return nullptr;
  }
  return B.CreateGEP(elementType, ptr, idxlist);
}