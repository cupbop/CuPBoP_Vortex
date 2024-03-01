#include "generate_wrapper.h"
#include "base_address.h"
#include "tool.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <iostream>
#include <sstream>
#include <fstream>
#include <limits>
#include <cstdlib>
#include <map>

using namespace llvm;

void set_meta_data(llvm::Module *M) {
  M->setTargetTriple("riscv32-unknown-linux-gnu");
  M->setDataLayout(
      "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128");
}

// as pthread only accept a single void* for input
// we have to decode this input inside the kernel
void decode_input(llvm::Module *M) {

  std::set<llvm::Function *> need_remove;

  LLVMContext *C = &M->getContext();
  llvm::Type *Int32T = Type::getInt32Ty(*C);
  llvm::Type *Int8T = Type::getInt8Ty(*C);

  llvm::FunctionType *LauncherFuncT = FunctionType::get(
    Type::getVoidTy(*C), {PointerType::get(Int8T, 0)}, false);

  std::set<GlobalVariable *> dynmaic_memory;

  std::map<GlobalVariable *, Value *> corres_dynamic_memory_load_address;

  // generate Wrapper Function type
  // now we only support a single int32*
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    if (!isKernelFunction(M, F))
      continue;

    auto func_name = F->getName().str();
    
    // remove mangle prefix
    // remove _Z24
    for (int pos = 2; pos < func_name.length(); pos++) {
      if (func_name[pos] >= '0' && func_name[pos] <= '9')
        continue;
      func_name = func_name.substr(pos);
      break;
    }

    llvm::IRBuilder<> Builder(M->getContext());

    FunctionCallee fc =
        M->getOrInsertFunction(func_name + "_wrapper", LauncherFuncT);
    Function *WorkGroup = dyn_cast<Function>(fc.getCallee());

    BasicBlock *Block = BasicBlock::Create(M->getContext(), "", WorkGroup);
    Builder.SetInsertPoint(Block);

    // get the wrapper kernel arguments
    Function::arg_iterator ai = WorkGroup->arg_begin();

    SmallVector<Value *, 8> Arguments;
    Value *input_arg = &*ai;
    // convert to int**
    input_arg = Builder.CreateBitOrPointerCast(
        input_arg, PointerType::get(PointerType::get(Int32T, 0), 0));

    // dynamic memory load in the wrapper function
    GlobalVariable *share_memory = M->getGlobalVariable("wrapper_global_data");
    if (share_memory != NULL) {
      dynmaic_memory.insert(share_memory);
      llvm::GlobalVariable *global_mem = new llvm::GlobalVariable(
          *M, Int32T, false, llvm::GlobalValue::ExternalLinkage, NULL,
          "thread_memory_size", NULL, llvm::GlobalValue::GeneralDynamicTLSModel,
          0, false);
      Value *loadedValue = createLoad(Builder, global_mem);

      llvm::FunctionType *LaunchFun2 = FunctionType::get(
          PointerType::get(PointerType::get(Int32T, 0), 0), NULL);

      FunctionCallee fc2 =
          M->getOrInsertFunction("_wrapper_global_data", LaunchFun2);

      Function *WorkGroup2 = dyn_cast<Function>(fc2.getCallee());

      WorkGroup2->setLinkage(GlobalValue::WeakODRLinkage);
      WorkGroup2->setVisibility(GlobalValue::HiddenVisibility);
      Comdat *co = M->getOrInsertComdat("_wrapper_global_data");
      co->setSelectionKind(Comdat::SelectionKind::Any);
      WorkGroup2->setComdat(co);

      BasicBlock *Block2 = BasicBlock::Create(M->getContext(), "", WorkGroup2);

      llvm::IRBuilder<> Builder2(M->getContext());
      Builder2.SetInsertPoint(Block2);
      Builder2.CreateRet(share_memory);

      auto PT = dyn_cast<PointerType>(share_memory->getType());
      auto element_type = PT->getElementType();
      // std::cout << element_type->getTypeID()  << " Got global memor $$$$$$"
      // << share_memory->getName().str() << std::endl;

      AllocaInst *new_arr = Builder.CreateAlloca(Int8T, loadedValue, "new_arr");
      // new_arr->setAlignment(llvm::MaybeAlign(16));
      Value *new_ar = new_arr;
      Value *gptr = Builder.CreateBitOrPointerCast(
          share_memory, PointerType::get(PointerType::get(Int8T, 0), 0));

      Builder.CreateStore(new_ar, gptr);
    }

    size_t idx = 0;
    for (Function::const_arg_iterator ii = F->arg_begin(), ee = F->arg_end();
         ii != ee; ++ii) {
      Type *ArgType = ii->getType();

      // calculate addr
      Value *GEP = createGEP(Builder, input_arg, ConstantInt::get(Int32T, idx));
      // load corresponding int*
      //GEP = Builder.CreateLoad(GEP);
      // bitcast
      GEP = Builder.CreateBitOrPointerCast(GEP, PointerType::get(ArgType, 0));
      Value *Arg = createLoad(Builder, GEP);
      Arguments.push_back(Arg);
      ++idx;
    }

    CallInst *c = Builder.CreateCall(F, ArrayRef<llvm::Value *>(Arguments));
    Builder.CreateRetVoid();
  }

  for (auto f : need_remove) {
    f->dropAllReferences();
    f->eraseFromParent();
  }
}

void remove_barrier(llvm::Module *M) {
  std::vector<Instruction *> need_remove;
  for (auto F = M->begin(); F != M->end(); ++F)
    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->isInlineAsm())
            continue;
          auto func_name = Call->getCalledFunction()->getName().str();
          if (func_name == "llvm.nvvm.bar.warp.sync" ||
              func_name == "llvm.nvvm.barrier0" ||
              func_name == "llvm.nvvm.barrier.sync") {
            need_remove.push_back(Call);
          }
        }
      }
    }
  for (auto inst : need_remove) {
    inst->eraseFromParent();
  }
}

void remove_useless_var(llvm::Module *M) {
    M->getGlobalVariable("intra_warp_index")->eraseFromParent();
    M->getGlobalVariable("inter_warp_index")->eraseFromParent();
}

std::string converttostring(const char* a) {
    std::string s = a;
    return s;
}

void create_kernel_wrapper_function(llvm::Module *M){

    auto ALIGNED_CTX_SIZE = 100;

    std::string kernel_name_tmp;
    std::vector<std::string> wrapper_name;
    //std::vector<int> kernel_idx;

    
    std::fstream outfile;
    outfile.open("lookup.txt", std::ios::out);
    outfile.close();
    
    ///////////////// Temporarily not using (.txt) //////////////////
    /*
    while(readfile >> kernel_idx_tmp)
    {
      readfile >> kernel_name_tmp;
      kernel_idx.push_back(kernel_idx_tmp);
      std::cout << "looking for kernel name " << kernel_name_tmp << " with " << kernel_idx_tmp << std::endl;
      readfile.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
      wrapper_name.push_back(kernel_name_tmp + "_wrapper");
    }
    readfile.close();
    */

    int kernel_idx = 0;

    for (auto F = M->begin(); F != M->end(); ++F) {
      for (auto BB = F->begin(); BB != F->end(); ++BB) {
        for (auto BI = BB->begin(); BI != BB->end(); BI++) {
          if (auto Call = dyn_cast<CallInst>(BI)) {
            auto func_name = Call->getCalledFunction()->getName().str();
            auto func_arg_size = Call->getCalledFunction()->arg_size();
            std::cout << "currently looking function is " << func_name << std::endl;

            // Find the kernel function name
            if(isKernelFunction(M, Call->getCalledFunction()) && std::find(wrapper_name.begin(), wrapper_name.end(), func_name+"_wrapper") == wrapper_name.end())
            {
              std::cout << "Found the kernel name for the kernel_wrapper.cpp, it is " << func_name << "with number of arg "<< func_arg_size << " kernel_idx: " << std::to_string(kernel_idx) << std::endl;
              // remove _Z24
              for (int i = 2; i < func_name.length(); i++) {
                if (func_name[i] >= '0' && func_name[i] <= '9')
                  continue;
                func_name = func_name.substr(i);
                break;
              }
              wrapper_name.push_back(func_name + "_wrapper");
              outfile.open("lookup.txt", std::ios::app);
              outfile << kernel_idx << " " << func_name << " " << func_arg_size << "\n";
              outfile.close();
              kernel_idx++;
            }
          }
        }
      }
    }

    std::stringstream ss;

    ss << "#include <stdint.h>\n"
          "#include <vx_print.h>\n"
          "#include <vx_intrinsics.h>\n"
          "#include <vx_spawn.h>\n"
          "#include <stdint.h>\n" 
          "#include <string.h>\n"         
          "\n"

          "#define KERNEL_ARG_BASE_ADDR "
          << KERNEL_ARG_BASE_ADDR <<
          "\n"
          "#define KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR "
          << KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR <<
          "\n"
          "\n"

          "typedef struct {\n"
          "    context_t ctx;\n"
          "    int kernel_idx;\n"
          "    uint64_t args[0];\n"
          "} kernel_arg_t;\n"          
          "\n"

          "int grid_size_x;\n"
          "int grid_size_y;\n"
          "int grid_size_z;\n"
          "\n"

          "int block_size_x;\n"
          "int block_size_y;\n"
          "int block_size_z;\n"
          "\n"

          "int block_size;\n"
          "\n"

          "int __thread block_index_x;\n"
          "int __thread block_index_y;\n"
          "int __thread block_index_z;\n"
          "\n";

    ss <<  "\n extern \"C\" {\n";

    for (auto f : wrapper_name) {
        ss << "    extern void " + f + "(void *args);\n";
    }

    ss << "}\n"
          "\n";

    for (auto f : wrapper_name) {
        ss << "void cuda_" << f << "(\n"
              "    const void * args, \n"
              "    const context_t* /*context*/, \n"
              "    uint32_t group_x, \n"
              "    uint32_t group_y, \n"
              "    uint32_t /*group_z*/)\n"
              "{\n"
              "    block_index_x = group_x;\n"
              "    block_index_y = group_y;\n"
              "    block_index_z = 0;\n"
              "\n"
              "    vx_printf(\"kernel_warpper: group=(%d, %d)\\n\", group_x, group_y);\n"
              "\n"
              "    " << f << "((void **)args);\n"
            "}\n"
            "\n";
    }
      
    ss << "vx_spawn_kernel_cb callbacks[] = {\n";

    for (auto f : wrapper_name) {
        ss << "    cuda_" << f << ", \n";
    }

    ss << "};\n"
          "\n" 

          "int main() {\n"
          "    auto kernel_arg = (kernel_arg_t*)KERNEL_ARG_BASE_ADDR; \n"
          "    auto ctx = &kernel_arg->ctx; \n"
          "    auto args = (uint64_t*)kernel_arg->args;\n"
          "\n"

          "    grid_size_x = ctx->num_groups[0];\n"
          "    grid_size_y = ctx->num_groups[1];\n"
          "    grid_size_z = ctx->num_groups[2];\n"
          "\n"

          "    block_size_x = ctx->local_size[0];\n"
          "    block_size_y = ctx->local_size[1];\n"
          "    block_size_z = ctx->local_size[2];\n"
          "\n"

          "    block_size = ctx->local_size[0] * ctx->local_size[1];\n"
          "\n"
          "    auto additional_info = (uint64_t*)KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR; \n"
          //"    vx_printf(\"additional_info[0]: %lu\\n\", additional_info[0]);\n"
          "    if (additional_info[0] != 0) {\n"
          "       vx_printf(\"CHECK: cudamemcpytosymbol\");\n"
          "       int additional_info_idx = 0;\n"
          "       while (additional_info_idx < additional_info[0]) {\n"
          "           auto dst_addr = (uint64_t*)additional_info[additional_info_idx * 3 + 1];\n"
          "           auto src_addr = (uint64_t*)additional_info[additional_info_idx * 3 + 2];\n"
          "           auto size = (size_t)additional_info[additional_info_idx * 3 + 3];\n"
          "           memcpy(dst_addr, src_addr, size);\n"
          "           additional_info_idx++;}}\n"
          "\n"
          "    vx_printf(\"sizeof everything %d %d %d\\n\", sizeof(*kernel_arg), sizeof(*ctx), sizeof(ctx->printf_buffer)); \n"
          "    vx_printf(\"base: 0x%lx\\n\", KERNEL_ARG_BASE_ADDR); \n"
          "    vx_printf(\"kernel#%d (callback:0x%lx): gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), args=(0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx)\\n\", \n"
          "        kernel_arg->kernel_idx, callbacks[kernel_arg->kernel_idx], ctx->num_groups[0], ctx->num_groups[1], ctx->num_groups[2], \n"
          "        ctx->local_size[0], ctx->local_size[1], ctx->local_size[2],\n"
          "        args[0], args[1], args[2], args[3], args[4], args[5]);\n"
          "    vx_printf(\"workdim=%d\\n\", ctx->work_dim);\n"
          "\n";

         
    bool mapping_type = std::stoi(std::string(std::getenv("VORTEX_SCHEDULE_FLAG")));
    if(mapping_type == 1)
      ss << "    vx_spawn_kernel_cm(ctx, callbacks[kernel_arg->kernel_idx], args);\n";
    else
      ss << "    vx_spawn_kernel(ctx, callbacks[kernel_arg->kernel_idx], args);\n";

    ss << "\n" 
          "    // Copy back the additional info (changed by the kernel, Cudamemcpytosymbol)\n"
          "    if (additional_info[0] != 0) {\n"
          "       int additional_info_idx = 0;\n"
          "       while (additional_info_idx < additional_info[0]) {\n"
          "           auto src_addr = (uint64_t*)additional_info[additional_info_idx * 3 + 1];\n"
          "           auto dst_addr = (uint64_t*)additional_info[additional_info_idx * 3 + 2];\n"
          "           auto size = (size_t)additional_info[additional_info_idx * 3 + 3];\n"
          "           memcpy(dst_addr, src_addr, size);\n"
          "           additional_info_idx++;}}\n"
          "    return 0;\n"
          "}\n"
          "\n";

    auto content = ss.str();

    std::ofstream ofs;

    ofs.open("../vortex_debug/kernel_wrapper.cpp");
    ofs << ss.rdbuf();
    ofs.close();    

    return;
}

void generate_wrapper(llvm::Module *M) {
  // change metadata
  set_meta_data(M);
  // decode argument
  decode_input(M);
  // remove barrier
  remove_barrier(M);
  // remove useless func/variable
  remove_useless_var(M);
  // create kernel wraper function  // Hyesoon 6-7-202 
  create_kernel_wrapper_function(M);
}
