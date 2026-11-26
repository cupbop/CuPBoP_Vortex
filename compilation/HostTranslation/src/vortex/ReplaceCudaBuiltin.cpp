#include "ReplaceCudaBuiltin.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Demangle/Demangle.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <map>
#include <set>

using namespace llvm;

static bool cupbop_debug() {
  static bool enabled = (std::getenv("CUPBOP_DEBUG") != nullptr);
  return enabled;
}

static std::string functionBaseName(const std::string &name) {
  ItaniumPartialDemangler demangler;
  if (demangler.partialDemangle(name.c_str()) || !demangler.isFunction()) return {};
  size_t size = 0;
  char *base = demangler.getFunctionBaseName(nullptr, &size);
  if (!base) return {};
  std::string result(base);
  std::free(base);
  return result;
}

// Host-only CUDA modules have no registration table. Clang inserts the stub
// prefix inside the Itanium source name, so removing it must also change that
// source name's byte count, including inside namespaces and templates.
static std::string deviceNameFromStub(StringRef symbol) {
  const StringRef prefix = "__device_stub__";
  if (symbol.consume_front(prefix)) return symbol.str(); // extern "C"
  if (!symbol.starts_with("_Z") || !symbol.contains(prefix)) return symbol.str();
  const std::string oldBase = functionBaseName(symbol.str());
  StringRef base(oldBase);
  if (!base.consume_front(prefix)) return symbol.str();
  const std::string stubComponent = std::to_string(oldBase.size()) + oldBase;
  const std::string deviceComponent = std::to_string(base.size()) + base.str();
  for (size_t pos = symbol.find(stubComponent); pos != StringRef::npos;
       pos = symbol.find(stubComponent, pos + 1)) {
    std::string candidate = symbol.str();
    candidate.replace(pos, stubComponent.size(), deviceComponent);
    if (functionBaseName(candidate) == base) return candidate;
  }
  return symbol.str();
}

// Keep the kernel translator's lookup.txt convention for named launches.
static std::string deviceLookupName(StringRef name) {
  const char *triton = std::getenv("TRITON_CUPBOP");
  if (name.starts_with("_Z") || (triton && StringRef(triton) == "1" && name.starts_with("_")))
    return name.drop_front(std::min<size_t>(2, name.size())).ltrim("0123456789").str();
  return name.str();
}

// Kernel-pointer launch APIs can call through a template or a function parameter.
// Resolve the registered host stub at run time when it is not constant in the IR.
static void replacePointerLaunch(Module &M, CallBase &launch,
                                 const std::map<Function *, std::string> &registered, bool cooperative) {
  IRBuilder<> b(&launch);
  unsigned kernelArg = cooperative ? 0 : 1;
  StringRef name = cooperative ? "cupbopLaunchCooperativeKernel" : "cupbopLaunchKernelEx";
  SmallVector<Type *> types(launch.getFunctionType()->params());
  types.push_back(b.getInt32Ty());
  auto target = M.getOrInsertFunction(name, FunctionType::get(b.getInt32Ty(), types, false));
  auto arguments = [&](IRBuilder<> &ir, ArrayRef<Value *> args, Function *stub, StringRef device) {
    SmallVector<Value *> values(args);
    values[kernelArg] = ir.CreateGlobalStringPtr(device);
    values.push_back(ir.getInt32(stub->arg_size()));
    return values;
  };
  auto replace = [&](FunctionCallee callee, ArrayRef<Value *> args) {
    if (auto *invoke = dyn_cast<InvokeInst>(&launch))
      launch.replaceAllUsesWith(b.CreateInvoke(callee,invoke->getNormalDest(),invoke->getUnwindDest(),args));
    else
      launch.replaceAllUsesWith(b.CreateCall(callee,args));
  };
  SmallVector<Value *> args(launch.args());
  auto *stub = dyn_cast<Function>(args[kernelArg]->stripPointerCasts());
  auto it = registered.find(stub);
  if (it != registered.end()) {
    replace(target, arguments(b,args,stub,it->second));
    return;
  }
  StringRef dispatchName = cooperative ? "__cupbop_dispatch_cooperative_launch" : "__cupbop_dispatch_extended_launch";
  auto *dispatch = M.getFunction(dispatchName);
  if (!dispatch) {
    dispatch = Function::Create(launch.getFunctionType(),Function::InternalLinkage,dispatchName,M);
    IRBuilder<> ir(BasicBlock::Create(M.getContext(),"entry",dispatch));
    SmallVector<Value *> params;
    for (auto &arg : dispatch->args()) params.push_back(&arg);
    for (auto &entry : registered) {
      auto *matched = BasicBlock::Create(M.getContext(),"matched",dispatch);
      auto *next = BasicBlock::Create(M.getContext(),"next",dispatch);
      ir.CreateCondBr(ir.CreateICmpEQ(params[kernelArg],entry.first),matched,next);
      ir.SetInsertPoint(matched);
      ir.CreateRet(ir.CreateCall(target, arguments(ir,params,entry.first,entry.second)));
      ir.SetInsertPoint(next);
    }
    ir.CreateRet(ir.getInt32(98)); // cudaErrorInvalidDeviceFunction
  }
  replace(dispatch,args);
}

/*
insert sync after cudaKernel launch
  call void @_Z13staticReversePii(i32* %55, i32 64)
  %57 = call i32 @cudaDeviceSynchronize()
*/
void InsertSyncAfterKernelLaunch(llvm::Module *M) {
  LLVMContext *C = &M->getContext();

  llvm::Type *Int32T = Type::getInt32Ty(*C);
  llvm::FunctionType *LauncherFuncT = FunctionType::get(Int32T, NULL);
  llvm::FunctionCallee _f =
      M->getOrInsertFunction("cudaDeviceSynchronize", LauncherFuncT);
  llvm::Function *func_launch = llvm::cast<llvm::Function>(_f.getCallee());
  //std::set<llvm::Instruction *> kernel_launch_instruction;
  std::set<std::string> launch_function_name;


  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();

    for (Function::iterator b = F->begin(); b != F->end(); ++b) {
      BasicBlock *B = &(*b);

      for (BasicBlock::iterator i = B->begin(); i != B->end(); ++i) {
        Instruction *inst = &(*i);
        if (llvm::CallBase *callInst = llvm::dyn_cast<llvm::CallBase>(inst)) {
          if (Function *calledFunction = callInst->getCalledFunction()) {
            if (calledFunction->getName().starts_with("cudaLaunchKernel")) {
              // F is a kernel launch function
              launch_function_name.insert(func_name);
              //kernel_launch_instruction.insert(callInst);
            }
          }
        }
      }
    }
  }
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    for (Function::iterator b = F->begin(); b != F->end(); ++b) {
      BasicBlock *B = &(*b);

      for (BasicBlock::iterator i = B->begin(); i != B->end(); ++i) {
        Instruction *inst = &(*i);
        if (llvm::CallBase *callInst = llvm::dyn_cast<llvm::CallBase>(inst)) {
          if (Function *calledFunction = callInst->getCalledFunction()) {
            if (launch_function_name.find(calledFunction->getName().str()) !=
                launch_function_name.end()) {
              // insert a sync after launch

              //if (callInst->getNextNonDebugInstruction()) {
              //  llvm::CallInst::Create(func_launch, "",
              //                         callInst->getNextNonDebugInstruction());
              //}
              // Vortex specific code
              if (callInst->getNextNonDebugInstruction()) {
                  llvm::CallInst *newCall = llvm::CallInst::Create(func_launch, "");
                  newCall->insertBefore(callInst->getNextNonDebugInstruction());
                  // Copy debug info from the current instruction to the new one
                  newCall->setDebugLoc(callInst->getDebugLoc());
              }
            }
          }
        }
      }
    }
  }
  
}



// Change to i8* bitcast (i8* (i8*)* @_Z9vecPKiS0_Pii_wrapper to i8*)
// Original: i8* bitcast (void (i32*, i32*, i32*, i32)* @_Z9vecPKiS0_Pii to i8*)
void ReplaceKernelLaunch(llvm::Module *M) {
  LLVMContext &context = M->getContext();
  auto VoidTy = llvm::Type::getVoidTy(context);
  //LLVM 18 
  auto I8 = PointerType::getUnqual(context);
  //auto I8 = llvm::Type::getInt8PtrTy(context);

  std::set<llvm::Function *> need_remove;
  LLVMContext *C = &M->getContext();

  llvm::Type *Int32T = Type::getInt32Ty(*C);
  llvm::Type *Int8T = Type::getInt8Ty(*C);

  llvm::FunctionType *LauncherFuncT =
      FunctionType::get(Type::getVoidTy(*C), NULL);

  llvm::FunctionType *LaunchFun2 =
      FunctionType::get(PointerType::get(PointerType::get(Int32T, 0), 0), NULL);

  bool done = false;

  std::set<std::string> cuda_register_kernel_names;

  std::string str;
  llvm::raw_string_ostream ss(str);

  /*

  When using << >>, clang generates cudaPushCallConfiguration with the same
  function definition as the kernel definition in the kernel bitcode

    define internal void @__cuda_register_globals(i8** %0) {
    entry:
      %1 = call i32 @__cudaRegisterFunction(i8** %0, i8* bitcast (void (float*,
  float*, i32, i32)* @_Z4Fan1PfS_ii to i8*), i8* getelementptr inbounds ([14 x
  i8], [14 x i8]* @0, i64 0, i64 0), i8* getelementptr inbounds ([14 x i8], [14
  x i8]* @0, i64 0, i64 0), i32 -1, i8* null, i8* null, i8* null, i8* null, i32*
  null) %2 = call i32 @__cudaRegisterFunction(i8** %0, i8* bitcast (void
  (float*, float*, float*, i32, i32, i32)* @_Z4Fan2PfS_S_iii to i8*), i8*
  getelementptr inbounds ([17 x i8], [17 x i8]* @1, i64 0, i64 0), i8*
  getelementptr inbounds ([17 x i8], [17 x i8]* @1, i64 0, i64 0), i32 -1, i8*
  null, i8* null, i8* null, i8* null, i32* null) ret void 
    }

  */

  if (cupbop_debug()) std::cout << "Does it come here?" << std::endl;
  std::map<Function *, std::string> deviceKernels;
  if (auto *registration = M->getFunction("__cudaRegisterFunction")) {
    for (auto *user : registration->users()) {
      auto *call = dyn_cast<CallBase>(user);
      if (!call || call->arg_size() < 4) continue;
      auto *stub = dyn_cast<Function>(call->getArgOperand(1)->stripPointerCasts());
      if (!stub) continue;
      StringRef deviceName;
      if ((getConstantStringInfo(call->getArgOperand(3), deviceName) && !deviceName.empty()) ||
          (getConstantStringInfo(call->getArgOperand(2), deviceName) && !deviceName.empty()))
        deviceKernels.emplace(stub, deviceLookupName(deviceName));
      if (!isa<Function>(call->getArgOperand(1)))
        cuda_register_kernel_names.insert(stub->getName().str());
    }
  }
  // Registration takes precedence over the fallback used in host-only modules.
  if (auto *ordinary = M->getFunction("cudaLaunchKernel")) {
    for (auto *user : ordinary->users()) {
      auto *call = dyn_cast<CallBase>(user);
      if (!call || call->arg_empty()) continue;
      if (auto *stub = dyn_cast<Function>(call->getArgOperand(0)->stripPointerCasts()))
        deviceKernels.emplace(stub, deviceLookupName(deviceNameFromStub(stub->getName())));
    }
  }

std::vector<llvm::Instruction *> need_remove_inst;
int kernel_idx = 0;



  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();

    for (Function::iterator b = F->begin(); b != F->end(); ++b) {
      BasicBlock *B = &(*b);

      for (BasicBlock::iterator i = B->begin(); i != B->end(); ++i) {
        Instruction *inst = &(*i);

        if (llvm::CallBase *callInst = llvm::dyn_cast<llvm::CallBase>(inst)) {
          llvm::CallInst *callInst_inst = llvm::dyn_cast<llvm::CallInst>(inst);
          if (Function *calledFunction = callInst->getCalledFunction()) {
            //print function name
            if (cupbop_debug()) std::cout << "function_name: " << calledFunction->getName().str() << std::endl;
            if (calledFunction->getName() == "cudaLaunchCooperativeKernel" && callInst->arg_size() == 8) {
              replacePointerLaunch(*M,*callInst,deviceKernels,true);
              need_remove_inst.push_back(callInst);
              continue;
            }
            if (calledFunction->getName().starts_with("cudaLaunchKernel")) {
              //print function name
              if (cupbop_debug()) std::cout << "function_name2: " << calledFunction->getName().str() << std::endl;

              if (calledFunction->getName() == "cudaLaunchKernelExC" && callInst->arg_size() == 3) {
                replacePointerLaunch(*M,*callInst,deviceKernels,false);
                need_remove_inst.push_back(callInst);
                continue;
              }
              Value *callOperand = callInst->getArgOperand(0);

              Function *functionOperand =
                  dyn_cast<Function>(callInst->getArgOperand(0));

              // call function is wrapped in a bitcast
              if (functionOperand == NULL) {

                std::vector<size_t> arg_sizes;
                functionOperand =
                    dyn_cast<Function>(callOperand->stripPointerCasts());
              }
              // Only a CUDA launch of a kernel stub (cudaLaunchKernel(stub, grid, block, args, shmem, stream): a
              // function as operand 0 and the 8 operands of the split dim3s). A direct call of cudaLaunchKernel_vortex
              // (kernel name string, e.g. a lifted kernel's host) or of any other function whose name starts with
              // "cudaLaunchKernel" is left alone; it used to be taken for a stub launch and segfault here.
              if (functionOperand == NULL || callInst_inst == NULL || callInst_inst->arg_size() < 8 ||
                  calledFunction->getName() == "cudaLaunchKernel_vortex")
                continue;

                FunctionType *ft = calledFunction->getFunctionType();
                if (cupbop_debug()) std::cout << " Parent (Caller) Function Name: " << func_name
                          << ", cudaLaunchKernel Function: "
                          << functionOperand->getName().str() << ", args "
                          << functionOperand->arg_size() << std::endl;
                
                auto kernel = deviceKernels.find(functionOperand);
                const std::string name = kernel == deviceKernels.end()
                    ? deviceLookupName(deviceNameFromStub(functionOperand->getName())) : kernel->second;
                if (cupbop_debug()) std::cout << "Change Kernel Name to: " << name << std::endl;

                IRBuilder<> builder(callInst_inst);
                callInst_inst->setArgOperand(0, builder.CreateGlobalStringPtr(name));
                Value *arg_count = builder.getInt32(functionOperand->arg_size());

                std::vector<Value*> ArgsT;
                for (int oper_idx = 0; oper_idx <= 7; ++oper_idx) {
                  ArgsT.push_back(callInst_inst->getArgOperand(oper_idx));}
                ArgsT.push_back(arg_count);

                std::vector<llvm::Type *> ArgTys;
                for (Value *V : ArgsT)
                  ArgTys.push_back(V->getType());

                llvm::FunctionType *func_Type = FunctionType::get(llvm::Type::getInt32Ty(context), ArgTys, false);
                
                llvm::FunctionCallee _f = M->getOrInsertFunction("cudaLaunchKernel_vortex", func_Type);
                llvm::Function *calledFunction_argnum = llvm::cast<llvm::Function>(_f.getCallee());
                  //calledFunction_argnum->setDSOLocal(true);
                  //calledFunction_argnum->setUnnamedAddr(llvm::GlobalValue::UnnamedAddr::Global);

                CallInst *CI_argnum = CallInst::Create(calledFunction_argnum, ArgsT, "", callInst_inst);
                callInst_inst->replaceAllUsesWith(CI_argnum);
                      //ReplaceInstWithInst(callInst_inst, NewCI);
                CI_argnum->setCallingConv(callInst_inst->getCallingConv());
                CI_argnum->setDebugLoc(callInst_inst->getDebugLoc());
                need_remove_inst.push_back(callInst_inst);
              
            

            } else if (cuda_register_kernel_names.find(
                           calledFunction->getName().str()) !=
                       cuda_register_kernel_names.end()) {
              // if the called function collides with kernel definiton
              // TODO: some reason changes all occurences of the function name
              // for both cudaKernelLaunch calls and regular function call
              
              calledFunction->setName(calledFunction->getName() + "_host");
              if (cupbop_debug()) std::cout << std::endl;
              if (cupbop_debug()) std::cout << "Change Host Function Name To: "
                        << calledFunction->getName().str() << std::endl;
            }
          }
        }
      }
    }
  }
  for (auto inst : need_remove_inst) 
    inst->eraseFromParent();
  

}




void ReplaceMemcpyToSymbol(llvm::Module *M) {
  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);
  std::vector<llvm::Instruction *> need_remove;
  std::string arg0_name;  

  for (Module::iterator F = M->begin(); F != M->end(); ++F) {
    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->getCalledFunction()) {
              auto func_name = Call->getCalledFunction()->getName().str();

            if (func_name == "cudaMemcpyToSymbol") {
              
              llvm::Function *parentFunction = (Call->getParent()->getParent());

              //get the name of the function
              auto parentFunction_name = parentFunction->getName().str();
              if (cupbop_debug()) printf("parentFunction_name: %s\n", parentFunction_name.c_str());

              //Go through every instruction in every module to find function call with the name of parentFunction_name
              for (Module::iterator PF = M->begin(); PF != M->end(); ++PF) {
                for (auto PBB = PF->begin(); PBB != PF->end(); ++PBB) {
                  for (auto PBI = PBB->begin(); PBI != PBB->end(); PBI++) {
                    if (auto Call_parent = dyn_cast<CallInst>(PBI)) {
                      if (Call_parent->getCalledFunction()) {
                        if (auto *F = Call_parent->getCalledFunction()) {
                          auto func_name = F->getName().str();
                          if (func_name == parentFunction_name) {
                            //get first argument of the called function of call_parent
                            auto arg0 = Call_parent->getArgOperand(0);
                            //print the name of the value that arg0 is pointing to
                          arg0_name += arg0->stripPointerCasts()->getName().str();
                          arg0_name += " ";
                          if (cupbop_debug()) printf("arg0_name: %s\n", arg0_name.c_str());
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    }
  }

  if (cupbop_debug()) printf("final arg0_name: %s\n", arg0_name.c_str());

  for (Module::iterator F = M->begin(); F != M->end(); ++F) {
    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->getCalledFunction()) {
            if (auto *F = Call->getCalledFunction()) {
              auto func_name = F->getName().str();
              if (func_name == "cudaMemcpyToSymbol") {

              // Create a constant for arg0_name
              auto arg0_name_constant = llvm::ConstantDataArray::getString(context, arg0_name, /*AddNull=*/true);
              auto arg0_name_ptr = new llvm::GlobalVariable(*M, arg0_name_constant->getType(), true, llvm::GlobalValue::ExternalLinkage, arg0_name_constant);

              std::vector<llvm::Type *> args;
              // i32 @cudaMemcpyToSymbol(i8* %1, i8* %2, i64 %3, i64 %4, i32 %5)
              //LLVM 18
              //args.push_back(llvm::Type::getInt8PtrTy(context));
              //args.push_back(llvm::Type::getInt8PtrTy(context));
              args.push_back(PointerType::getUnqual(context));
              args.push_back(PointerType::getUnqual(context));

              args.push_back(llvm::Type::getInt64Ty(context));
              args.push_back(llvm::Type::getInt64Ty(context));
              args.push_back(llvm::Type::getInt32Ty(context));
              args.push_back(arg0_name_ptr->getType()); 
              //fix below based on arg0_ptr type
  
              llvm::FunctionType *func_Type =
                  FunctionType::get(I32, args, false);

              if (cupbop_debug()) printf("inserting cudamemcpytosymbol function\n");

              llvm::FunctionCallee _f =
                  M->getOrInsertFunction("cudaMemcpyToSymbol_host", func_Type);
                  
              llvm::Function *func = llvm::cast<llvm::Function>(_f.getCallee());
              // construct argument(s)
              std::vector<Value *> func_args;
              
              func_args.push_back(Call->getArgOperand(0));
              func_args.push_back(Call->getArgOperand(1));
              func_args.push_back(Call->getArgOperand(2));
              func_args.push_back(Call->getArgOperand(3));
              func_args.push_back(Call->getArgOperand(4));
              func_args.push_back(arg0_name_ptr);
              
              auto c_inst = llvm::CallInst::Create(func, func_args, "", Call);

              // insert
              Call->replaceAllUsesWith(c_inst);
              need_remove.push_back(Call);
              
            }
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
void ReplaceCudaBuiltin(llvm::Module *M) {
  InsertSyncAfterKernelLaunch(M);
  ReplaceKernelLaunch(M);
  ReplaceMemcpyToSymbol(M);
}
