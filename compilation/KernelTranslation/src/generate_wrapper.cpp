#include "generate_wrapper.h"
#include "base_address.h"
#include "tool.h"
#include "cg_sync.h"
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
#include "llvm/Target/TargetMachine.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <iostream>
#include <sstream>
#include <fstream>
#include <cstdlib>
#include <map>
#include <set>

using namespace llvm;


void set_meta_data(llvm::Module *M) {
  const char *arch_env = std::getenv("VORTEX_ARCHITECTURE");
  std::string arch = arch_env ? arch_env : "";

  if (arch == "64") {
    M->setTargetTriple("riscv64-unknown-unknown-elf");
    M->setDataLayout("e-m:e-p:64:64-i64:64-i128:128-n32:64-S128");
  } else {
    // this is an unverified guess for 32-bit RISC-V
    M->setTargetTriple("riscv32-unknown-unknown-elf");
    M->setDataLayout("e-m:e-p:32:32-i64:64-n32-S128"); 
  }
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
    if (cupbop_debug()) printf("function name: %s\n", func_name.c_str());
    
    // remove mangle prefix
    // remove _Z24
    // this only applies for nvcc compiled kernel (pass for triton)
    bool triton_enabled = triton_cupbop_enabled();
    if ((triton_enabled && func_name[0] == '_') || (!triton_enabled)) {
      for (int pos = 2; pos < func_name.length(); pos++) {
      if (func_name[pos] >= '0' && func_name[pos] <= '9')
        continue;
      func_name = func_name.substr(pos);
      break;
    } 
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

      llvm::FunctionType *LaunchFun2 = FunctionType::get(PointerType::get(PointerType::get(Int32T, 0), 0), false);
      // Triton version
      // llvm::FunctionType *LaunchFun2 = FunctionType::get(
          // PointerType::get(PointerType::get(Int32T, 0), 0), NULL);

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

      //LLVM 18 changes
      //auto element_type = PT->getElementType();
      // LLVM 17+: pointers are opaque; the pointee is the global's value type.
      [[maybe_unused]] auto element_type = share_memory->getValueType();
      (void)PT;

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
      // LLVM 18 changes
      //Value *GEP = createGEP(Builder, input_arg, ConstantInt::get(Int32T, idx));
      Value *GEP = Builder.CreateGEP(PointerType::get(Int32T, 0), input_arg,
                                     ConstantInt::get(Int32T, idx));
      // load corresponding int*
      //GEP = Builder.CreateLoad(GEP);
      // bitcast
      GEP = Builder.CreateBitOrPointerCast(GEP, PointerType::get(ArgType, 0));
      Value *Arg = Builder.CreateLoad(ArgType, GEP);
      Arguments.push_back(Arg);
      ++idx;
    }

    Builder.CreateCall(F, ArrayRef<llvm::Value *>(Arguments));
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
          auto func_name = Call->getCalledOperand()->getName().str();
          if (isWarpSync(func_name) ||
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

    int schedule = 0;
    if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
      schedule = std::stoi(std::string(env));
    }

    
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
    bool triton_enabled = triton_cupbop_enabled();

    for (auto F = M->begin(); F != M->end(); ++F) {
      for (auto BB = F->begin(); BB != F->end(); ++BB) {
        for (auto BI = BB->begin(); BI != BB->end(); BI++) {
          if (auto Call = dyn_cast<CallInst>(BI)) {
            if (!Call->getCalledFunction())
              continue;

            auto func_name = Call->getCalledOperand()->getName().str();
            auto func_arg_size = Call->getCalledFunction()->arg_size();
            if (cupbop_debug()) std::cout << "currently looking function is " << func_name << std::endl;

            // Find the kernel function name
            if(isKernelFunction(M, Call->getCalledFunction()) && std::find(wrapper_name.begin(), wrapper_name.end(), func_name+"_wrapper") == wrapper_name.end())
            {
              if (cupbop_debug()) std::cout << "Found the kernel name for the kernel_wrapper.cpp, it is " << func_name << "with number of arg "<< func_arg_size << " kernel_idx: " << std::to_string(kernel_idx) << std::endl;
              
              // remove _Z24, covers triton as well
              if ((triton_enabled && func_name[0] == '_') || (!triton_enabled)) {
                for (int i = 2; i < func_name.length(); i++) {
                  if (func_name[i] >= '0' && func_name[i] <= '9')
                    continue;
                  func_name = func_name.substr(i);
                  break;
                }
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

    // Read __device__ variable info from kernel_meta.log
    struct DeviceVarInfo { std::string name; uint64_t size; };
    std::vector<DeviceVarInfo> device_vars;
    {
      std::ifstream meta("kernel_meta.log");
      std::string line;
      bool in_device_section = false;
      while (std::getline(meta, line)) {
        if (line == "DeviceVariables") { in_device_section = true; continue; }
        if (line == "END_DeviceVariables") { in_device_section = false; continue; }
        if (in_device_section) {
          std::istringstream iss(line);
          DeviceVarInfo info;
          iss >> info.name >> info.size;
          device_vars.push_back(info);
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
          //memcpytosymbol: Implementation updated, we will not use the additional info base addr for now, but we can keep this macro for future use if needed
          //"#define KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR "
          //<< KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR <<
          "\n"
          "\n"

          "void (* volatile vx_barrier_dummy)(int, int) = vx_barrier;\n"
          // "int (* volatile vx_vote_all_dummy)(int) = vx_vote_all;\n"
          // "int (* volatile vx_vote_any_dummy)(int) = vx_vote_any;\n"
          // "int (* volatile vx_vote_uni_dummy)(int) = vx_vote_uni;\n"
          // "int (* volatile vx_vote_ballot_dummy)(int) = vx_vote_ballot;\n"
          // "int (* volatile vx_shfl_up_dummy)(size_t, int, int, int) = vx_shfl_up;\n"
          // "int (* volatile vx_shfl_down_dummy)(size_t, int, int, int) = vx_shfl_down;\n"
          // "int (* volatile vx_shfl_bfly_dummy)(size_t, int, int, int) = vx_shfl_bfly;\n"
          // "int (* volatile vx_shfl_idx_dummy)(size_t, int, int, int) = vx_shfl_idx;\n"
          "\n"
          "\n"

      "struct alignas(8) context_t { \n"
      "uint32_t num_groups[3]; \n"
      "uint32_t global_offset[3]; \n"
      "uint32_t local_size[3]; \n"
      "char * printf_buffer; \n"
      "uint32_t printf_buffer_position; \n"
      "uint32_t printf_buffer_capacity; \n"
      "uint32_t work_dim; \n"
      "uint32_t dyn_shared_mem_size; \n"
      "}; \n"
      "\n"

          "typedef struct {\n"
          "    context_t ctx;\n"
          "    int kernel_idx;\n"
          "    int num_args;\n"
          "    uint64_t args[0];\n"
          "} kernel_arg_t;\n"
          "\n";

    if (schedule != 2) {
      // Schedule 0/1: CuPBoP's own globals (populated by cuda_*_wrapper)
      ss << "int grid_size_x;\n"
            "int grid_size_y;\n"
            "int grid_size_z;\n"
            "\n"

            "int block_size_x;\n"
            "int block_size_y;\n"
            "int block_size_z;\n"
            "\n"

            "int block_size;\n"
            "\n"

            "__attribute__((used)) int __thread block_index_x;\n"
            "__attribute__((used)) int __thread block_index_y;\n"
            "__attribute__((used)) int __thread block_index_z;\n"

            "__attribute__((used)) int __thread *dynamic_shared_memory = NULL;\n"


            "__attribute__((used)) int __thread thread_id_x;\n"
            "__attribute__((used)) int __thread thread_id_y;\n"
            "__attribute__((used)) int __thread thread_id_z;\n"
            "\n"
            "#include <VX_config.h>\n"
            "__attribute__((used)) int __thread warp_shfl[NUM_WARPS * NUM_THREADS] = {0};\n"
            "__attribute__((used)) char __thread warp_vote[32] = {0};\n"
            "__attribute__((used)) int __thread vote_count = 0;\n"
            "\n";
    }

    ss << "char *__ctx_pool = 0;\n"
          "int dyn_shared_mem_size;\n\n";

    // __device__ variables are preserved across kernel launches by the host
    // runtime (cudaRuntimeImpl.cpp) using the cudaMemcpyToSymbol mechanism.
    // No device-side scratch needed.

    ss << "// Vortex 3.0 KMU launch (CUPBOP_LAUNCH2): the CTA dispatcher hands each CTA its own\n"
          "// local-memory window (VX_CSR_CTA_LMEM_ADDR, stride = lmem_size of the launch), so the\n"
          "// legacy __local_mem(size) = base + group_id*size carve is no longer needed.\n"
          "extern \"C\" void* vx_local_alloc(uint32_t size) {\n"
            "(void)size;\n"
            "void* p = (void*)csr_read_nv(VX_CSR_CTA_LMEM_ADDR);\n"
            //"vx_printf(\"local memory allocation with %d bytes, add 0x%p\\n\", size, p);\n"
            // "void* csr_read = (void*)csr_read(VX_CSR_LOCAL_MEM_BASE);\n"
            // "vx_printf(\"csr_parameter: %d\\n\", VX_CSR_LOCAL_MEM_BASE);\n"
            // "vx_printf(\"csr_read_value: %p\\n\", csr_read);\n"
            // "vx_printf(\"local_group_id: %d\\n\", __local_group_id);\n"
            "return p;\n"
          "}\n"


          "\n";


    ss <<  "\n extern \"C\" {\n";

    for (auto f : wrapper_name) {
        ss << "    extern void " + f + "(void *args);\n";
    }

    ss << "}\n"
          "\n";

    if (schedule != 2) {
      // Schedule 0/1: generate cuda_*_wrapper that copies vx_spawn TLS → CuPBoP TLS
      for (auto f : wrapper_name) {
        ss << "void cuda_" << f << "(void* args) {\n"
                  "    // block_index_{x,y,z} were set by the KMU entry (one CUDA block per hardware thread)\n"
                  "    thread_id_x = 0;\n"
                  "    thread_id_y = 0;\n"
                  "    thread_id_z = 0;\n"
                  "\n"
                  "//    vx_printf(\"kernel_warpper: group=(%d, %d) thread=(%d, %d)\\n\", blockIdx.x, blockIdx.y, thread_id_x, thread_id_y);\n"
                  "\n"
              "    " << f << "((void **)args);\n"
                "}\n"
                "\n";
      }
    }

    ss << "vx_kernel_func_cb callbacks[] = {\n";

    for (auto f : wrapper_name) {
      if (schedule == 2) {
        // Schedule 2: call kernel wrapper directly — no TLS copy layer
        ss << "    (vx_kernel_func_cb)" << f << ", \n";
      } else {
        ss << "    cuda_" << f << ", \n";
      }
    }

    ss << "};\n"
          "\n";

    // FIX (huffman SCHE_2 LMEM=1 wrap bug, May 13 2026): emit per-kernel static
    // lmem size table. Built from kernel_lmem.log written by mem_share2local.
    // main() reads this to set __vx_lmem_per_cta_bytes before vx_spawn_threads
    // so groups_per_core can be clamped to avoid lmem wraparound.
    {
      // Apply the same Itanium-ABI demangling-prefix strip that CuPBoP uses for
      // wrapper_name: strip "_Z" and any subsequent length digits. See
      // lines 262-266 above for the original logic.
      auto strip_mangling_prefix = [](std::string s) -> std::string {
        if (s.size() < 2 || s[0] != '_' || s[1] != 'Z') return s;
        size_t i = 2;
        while (i < s.size() && s[i] >= '0' && s[i] <= '9') ++i;
        return s.substr(i);
      };
      std::map<std::string, uint32_t> kernel_to_lmem;
      std::ifstream lmem_log("kernel_lmem.log");
      if (lmem_log.is_open()) {
        std::string raw_kname;
        uint32_t bytes;
        while (lmem_log >> raw_kname >> bytes) {
          std::string kname = strip_mangling_prefix(raw_kname);
          // Keep the maximum across multiple entries (passes may log the same
          // kernel more than once; we want the final layout size).
          auto it = kernel_to_lmem.find(kname);
          if (it == kernel_to_lmem.end() || it->second < bytes) {
            kernel_to_lmem[kname] = bytes;
          }
        }
      }
      ss << "// Per-kernel __shared__ static byte count (index = kernel_idx).\n";
      ss << "// Set to 0 if unknown; vx_spawn_threads then skips its lmem clamp.\n";
      // Provide a WEAK fallback definition so that linking succeeds against
      // older libvortex.a builds that don't yet define this global (no
      // vx_spawn lmem-clamp fix). In that case main() still writes to this
      // variable but no one reads it — harmless. When linking against a new
      // libvortex.a, both weak symbols merge and vx_spawn_threads reads the
      // value main() stores.
      ss << "extern \"C\" __attribute__((weak)) uint32_t __vx_lmem_per_cta_bytes = 0;\n";
      ss << "static const uint32_t kernel_static_lmem_bytes[] = {\n";
      for (auto f : wrapper_name) {
        // Strip the "_wrapper" suffix to get the kernel symbol name used by
        // mem_share2local for its log entries.
        std::string kname = f;
        const std::string suffix = "_wrapper";
        if (kname.size() >= suffix.size() &&
            kname.compare(kname.size() - suffix.size(), suffix.size(), suffix) == 0) {
          kname.resize(kname.size() - suffix.size());
        }
        uint32_t bytes = 0;
        // Map keys are pre-normalized to the same demangled form as kname
        // (see strip_mangling_prefix above).
        auto it = kernel_to_lmem.find(kname);
        if (it != kernel_to_lmem.end()) {
          bytes = it->second;
        }
        ss << "    " << bytes << "u, // " << kname << "\n";
      }
      ss << "};\n\n";
    }

    ss <<
          "// ─── Vortex 3.0 KMU entry (CUPBOP_LAUNCH2) ─────────────────────────────────\n"
          "// The host launches this entry with the real CUDA grid/block geometry\n"
          "// (vx_enqueue_launch); the hardware CTA dispatcher places one CTA per core slot and\n"
          "// every thread of every CTA starts here with the kernel-arg pointer in MSCRATCH.\n"
          "// We fill the legacy vx_spawn globals (threadIdx/blockIdx TLS, blockDim/gridDim,\n"
          "// __local_group_id, __warps_per_group) from the CTA CSRs so the translated kernel IR\n"
          "// and the device runtime keep working unchanged.\n"
          "static inline __attribute__((always_inline)) void __cupbop_fill_spawn_globals() {\n"
          "    threadIdx.x = (uint32_t)csr_read_nv(VX_CSR_CTA_THREAD_ID_X);\n"
          "    threadIdx.y = (uint32_t)csr_read_nv(VX_CSR_CTA_THREAD_ID_Y);\n"
          "    threadIdx.z = (uint32_t)csr_read_nv(VX_CSR_CTA_THREAD_ID_Z);\n"
          "    blockIdx.x  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_ID_X);\n"
          "    blockIdx.y  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_ID_Y);\n"
          "    blockIdx.z  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_ID_Z);\n"
          "    blockDim.x  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_DIM_X);\n"
          "    blockDim.y  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_DIM_Y);\n"
          "    blockDim.z  = (uint32_t)csr_read_nv(VX_CSR_CTA_BLOCK_DIM_Z);\n"
          "    gridDim.x   = (uint32_t)csr_read_nv(VX_CSR_CTA_GRID_DIM_X);\n"
          "    gridDim.y   = (uint32_t)csr_read_nv(VX_CSR_CTA_GRID_DIM_Y);\n"
          "    gridDim.z   = (uint32_t)csr_read_nv(VX_CSR_CTA_GRID_DIM_Z);\n"
          "    __local_group_id = (uint32_t)csr_read_nv(VX_CSR_CTA_ID);\n"
          "    __warps_per_group = (uint32_t)csr_read_nv(VX_CSR_CTA_SIZE);\n"
          "}\n"
          "\n"
          "// Service launches (grid 1, block 1): kernel_idx == -1 applies the cudaMemcpyToSymbol\n"
          "// list [count | dst, size, inline data...]*; kernel_idx == -2 performs device->device\n"
          "// copies [count | dst, src, size]* (device-variable read-back into a staging buffer).\n"
          "static void __cupbop_service(int kernel_idx, uint64_t* list) {\n"
          "    if (kernel_idx == -1) {\n"
          "        uint64_t* slot = &list[1];\n"
          "        for (int i = 0; i < (int)list[0]; i++) {\n"
          "            auto dst_addr = (void*)slot[0];\n"
          "            auto size = (size_t)slot[1];\n"
          "            auto src_data = (void*)&slot[2];\n"
          "            memcpy(dst_addr, src_data, size);\n"
          "            size_t data_slots = (size + sizeof(uint64_t) - 1) / sizeof(uint64_t);\n"
          "            slot += 2 + data_slots;\n"
          "        }\n"
          "    } else if (kernel_idx == -2) {\n"
          "        uint64_t* slot = &list[1];\n"
          "        for (int i = 0; i < (int)list[0]; i++) {\n"
          "            memcpy((void*)slot[0], (const void*)slot[1], (size_t)slot[2]);\n"
          "            slot += 3;\n"
          "        }\n"
          "    }\n"
          "}\n"
          "\n"
          "extern \"C\" __attribute__((annotate(\"vortex.kernel\"), used, retain, noinline))\n"
          "void kernel_main(kernel_arg_t* kernel_arg) {\n"
          "    auto ctx = &kernel_arg->ctx; \n"
          "    auto num_args = kernel_arg->num_args;\n"
          "    auto args = (uint64_t*)kernel_arg->args;\n"
          "    if (kernel_arg->kernel_idx < 0) { __cupbop_service(kernel_arg->kernel_idx, args + num_args); return; }\n"
          "    __cupbop_fill_spawn_globals();\n"
          "    dyn_shared_mem_size = ctx->dyn_shared_mem_size;\n"
;
    if (schedule == 0) {
      ss <<           "    // Flat schedule: one CUDA block per hardware thread. The host launched\n"
          "    // ceil(num_blocks / NT) CTAs of NT threads; recover the CUDA block index.\n"
          "    grid_size_x = ctx->num_groups[0];\n"
          "    grid_size_y = ctx->num_groups[1];\n"
          "    grid_size_z = ctx->num_groups[2];\n"
          "    block_size_x = ctx->local_size[0];\n"
          "    block_size_y = ctx->local_size[1];\n"
          "    block_size_z = ctx->local_size[2];\n"
          "    block_size = ctx->local_size[0] * ctx->local_size[1] * ctx->local_size[2];\n"
          "    uint32_t linear = blockIdx.x * blockDim.x + threadIdx.x;\n"
          "    uint32_t total = ctx->num_groups[0] * ctx->num_groups[1] * ctx->num_groups[2];\n"
          "    if (linear >= total) return;\n"
          "    block_index_x = linear % ctx->num_groups[0];\n"
          "    block_index_y = (linear / ctx->num_groups[0]) % ctx->num_groups[1];\n"
          "    block_index_z = linear / (ctx->num_groups[0] * ctx->num_groups[1]);\n"
          "    callbacks[kernel_arg->kernel_idx](args);\n"
          "}\n"
;
    } else if (schedule == 1) {
      // Core mapping (virt): CTA == CUDA block but only P physical warps; the
      // translated kernel loops over logical warps rank, rank+P, ... (insert_warp_loop)
      // and __syncthreads is a real CTA barrier. Logical geometry comes from ctx.
      {
      int vl = getVirtGeom().lanes;
      extern int need_nested_loop; // set by insert_warp_loop (sub-pass form)
      const int own_stride = need_nested_loop ? 32 : vl; // logical threads a physical warp owns per pass
      ss << "    const bool getenv_dbg_virt = " << (std::getenv("CUPBOP_VIRT_DEBUG_PRINT") ? "true" : "false") << ";\n";
      ss << "    const uint32_t __bs = ctx->local_size[0] * ctx->local_size[1] * ctx->local_size[2];\n"
            "    const uint32_t __L = " << (std::to_string(vl) + "u") << "; // lanes per warp: CUPBOP_VIRT_LANES at translation, else NT\n"
            "    const uint32_t __lane = (uint32_t)vx_thread_id();\n"
            "    const uint32_t __rank = (uint32_t)csr_read_nv(VX_CSR_CTA_RANK);\n"
            "    // Grid constants are plain globals the translated kernel reads. No fence here: on the\n"
            "    // Vortex RTL a fence is a whole-cache flush (L1 and L2 written back and invalidated),\n"
            "    // per CTA. Each hardware thread stores them only when what it reads differs (in practice\n"
            "    // the first CTAs of a launch) and afterwards reads its own store or a value it has just\n"
            "    // checked; every writer stores the same values, so program order on one thread suffices.\n"
            "    // (Storing from every thread unconditionally cost small kernels more than their body:\n"
            "    // nn stores 2.4x of 1:1.)\n"
            "    if (__lane == 0 && blockIdx.x == 0 && blockIdx.y == 0 && __rank == 0 && getenv_dbg_virt) vx_printf(\"[virt] L=%d bs=%d nt=%d\\n\", (int)__L, (int)__bs, (int)vx_num_threads());\n"
            "    {\n"
            "        const int __gx = (int)ctx->num_groups[0], __gy = (int)ctx->num_groups[1], __gz = (int)ctx->num_groups[2];\n"
            "        const int __lx = (int)ctx->local_size[0], __ly = (int)ctx->local_size[1], __lz = (int)ctx->local_size[2];\n"
            "        if (grid_size_x != __gx || grid_size_y != __gy || grid_size_z != __gz ||\n"
            "            block_size_x != __lx || block_size_y != __ly || block_size_z != __lz || block_size != (int)__bs) {\n"
            "            grid_size_x = __gx; grid_size_y = __gy; grid_size_z = __gz;\n"
            "            block_size_x = __lx; block_size_y = __ly; block_size_z = __lz;\n"
            "            block_size = (int)__bs;\n"
            "        }\n"
            "    }\n"
            "    block_index_x = blockIdx.x;\n"
            "    block_index_y = blockIdx.y;\n"
            "    block_index_z = blockIdx.z;\n"
            "    // Lane gating and partial blocks: hardware thread (rank, lane) owns logical\n"
            "    // threads rank*L + lane + k*(P*L); one without any (lane >= L, or beyond the\n"
            "    // block) leaves now, before the kernel's uniform control flow reads its\n"
            "    // per-thread scalars. The warp keeps its other lanes, so CTA barriers\n"
            "    // (counted per warp) are unaffected; the host guarantees every warp owns\n"
            "    // at least one logical thread (P <= ceil(block/L)).\n"
            "    if (__lane >= __L || __rank * " << own_stride << "u + __lane >= __bs) return;\n"
            "    callbacks[kernel_arg->kernel_idx](args);\n"
            "}\n";
      }
    } else {
      ss <<           "    callbacks[kernel_arg->kernel_idx](args);\n"
          "}\n"
;
    }
    ss << "\n";

    auto content = ss.str();

    std::ofstream ofs;

    //NOTE: was ../vortex_debug/kernel_wrapper.cpp — changed to cwd for per-example build
    ofs.open("kernel_wrapper.cpp");
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
