#include "init.h"
#include "memory_hierarchy.h"
#include "tool.h"
#include <fstream>
#include <functional>
#include <set>
#include <cstdlib>
#include <iostream>

#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/InitializePasses.h"
#include "llvm/PassInfo.h"
#include "llvm/PassRegistry.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/TargetSelect.h"
//LLVM18
//#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Transforms/Scalar/LoopUnrollPass.h"
#include "llvm/Transforms/Scalar/SCCP.h"
#include "llvm/Transforms/InstCombine/InstCombine.h"
#include "llvm/Transforms/Scalar/SimplifyCFG.h"
#include "llvm/Transforms/Utils/LoopSimplify.h"
#include "llvm/Transforms/Utils/LCSSA.h"
#include "llvm/Transforms/Utils/Mem2Reg.h"
#include "llvm/Passes/PassBuilder.h"

//extern void initializeInstrumentation(PassRegistry&);

using namespace llvm;


bool inline_warp_level_func(llvm::Module *M) {
  bool changed = false;
  std::set<llvm::Function *> need_remove;

  // For SCHE_0 (FLAT), skip inlining shfl wrappers — they will be
  // replaced by ReplaceWarpLevelPrimitive with warp_shfl emulation.
  // Inlining them would expose NVVM intrinsics in the kernel body
  // which causes domination errors when replaceWarpShflFlat tries
  // to insert store→barrier→load around them in complex control flow.
  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG"))
    schedule = std::stoi(std::string(env));
  bool skip_shfl_inline = (schedule == 0);

  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();
    if (!isKernelFunction(M, F))
      continue;
    Function::iterator I = F->begin();
    for (Function::iterator E = F->end(); I != E; ++I) {
      for (BasicBlock::iterator BI = I->begin(), BE = I->end(); BI != BE;) {
        if (CallInst *c = dyn_cast<CallInst>(BI++)) {
          if (c->getCalledFunction()) {
            auto callee_name = c->getCalledOperand()->getName().str();
            bool is_any_sync = (callee_name == "_Z10__any_syncji");
            bool is_shfl = (callee_name.find("shfl_down_sync") != std::string::npos);
            if (is_any_sync || (is_shfl && !skip_shfl_inline)) {
              InlineFunctionInfo IFI;
              InlineFunction(*c, IFI);
              need_remove.insert(c->getCalledFunction());
              changed = true;
            }
          }
        }
      }
    }
  }
  for (auto f : need_remove) {
    if (f->use_empty()) {
      f->dropAllReferences();
      f->eraseFromParent();
    }
  }
  return changed;
}

// Check if a function transitively calls any shfl function
static bool calls_shfl_transitively(llvm::Function *F,
                                     std::set<llvm::Function *> &visited) {
  if (!F || F->isDeclaration())
    return false;
  if (visited.count(F))
    return false;
  visited.insert(F);
  for (auto &BB : *F) {
    for (auto &I : BB) {
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (CI->isInlineAsm() || !CI->getCalledFunction())
          continue;
        auto name = CI->getCalledFunction()->getName().str();
        if (name.find("shfl_down_sync") != std::string::npos ||
            name.find("shfl_up_sync") != std::string::npos ||
            name.find("shfl_xor_sync") != std::string::npos ||
            name.find("__shfl_sync") != std::string::npos ||
            name.find("llvm.nvvm.shfl.sync") != std::string::npos)
          return true;
        if (calls_shfl_transitively(CI->getCalledFunction(), visited))
          return true;
      }
    }
  }
  return false;
}

// Inline functions that transitively contain shfl calls into kernel functions.
// This ensures warp_shfl store→barrier→load ends up inside the kernel body,
// where split_block_by_sync and insert_warp_loop can properly process it.
bool inline_shfl_helpers(llvm::Module *M) {
  bool changed = false;
  // Collect inline targets first (avoid iterator invalidation)
  SmallVector<CallInst *, 16> to_inline;
  std::set<llvm::Function *> need_remove;
  for (auto &F : *M) {
    if (!isKernelFunction(M, &F))
      continue;
    for (auto &BB : F) {
      for (auto &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm() || !CI->getCalledFunction())
          continue;
        auto *callee = CI->getCalledFunction();
        auto name = callee->getName().str();
        // Skip NVVM intrinsics and shfl wrappers (handled by replaceWarpShflFlat)
        if (name.find("llvm.nvvm.") != std::string::npos)
          continue;
        if (name.find("shfl_down_sync") != std::string::npos ||
            name.find("shfl_up_sync") != std::string::npos ||
            name.find("shfl_xor_sync") != std::string::npos ||
            name.find("__shfl_sync") != std::string::npos)
          continue;
        // Check if callee transitively calls shfl
        std::set<llvm::Function *> visited;
        if (calls_shfl_transitively(callee, visited)) {
          to_inline.push_back(CI);
          need_remove.insert(callee);
        }
      }
    }
  }
  for (auto *CI : to_inline) {
    // Save the next instruction after the call — this is where the
    // inlined code ends and the original code resumes.
    auto *nextInst = CI->getNextNode();
    InlineFunctionInfo IFI;
    InlineFunction(*CI, IFI);
    // Insert barrier0 after the inlined helper code so that
    // post-reduction code (e.g., `if (thread_id == 0)`) is in a
    // separate parallel region for proper context save/restore.
    if (nextInst)
      CreateInterWarpBarrier(nextInst);
    changed = true;
  }
  for (auto *F : need_remove) {
    if (F->use_empty()) {
      F->dropAllReferences();
      F->eraseFromParent();
    }
  }
  return changed;
}

bool find_sreg_inst(llvm::Function *F) {
  Function::iterator I = F->begin();
  for (Function::iterator E = F->end(); I != E; ++I) {
    for (BasicBlock::iterator BI = I->begin(), BE = I->end(); BI != BE;) {
      if (CallInst *c = dyn_cast<CallInst>(BI++)) {
        if (c->getCalledFunction()) {
          auto func_name = c->getCalledOperand()->getName().str();
          if (func_name.find("llvm.nvvm.read.ptx.sreg.") != std::string::npos) {
            return true;
          }
        }
      }
    }
  }
  return false;
}
bool inline_func_with_tid(llvm::Module *M) {
  bool changed = false;
  std::set<llvm::Function *> need_remove;
  std::set<CallInst *> need_inline;
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();
    Function::iterator I = F->begin();
    for (Function::iterator E = F->end(); I != E; ++I) {
      for (BasicBlock::iterator BI = I->begin(), BE = I->end(); BI != BE;) {
        if (CallInst *c = dyn_cast<CallInst>(BI++)) {
          if (c->getCalledFunction()) {
            if (find_sreg_inst(c->getCalledFunction())) {
              if (cupbop_debug()) printf("inline: %s\n",
                     c->getCalledOperand()->getName().str().c_str());
              need_inline.insert(c);
              need_remove.insert(c->getCalledFunction());
            }
          }
        }
      }
    }
  }
  if (!need_inline.empty()) {
    changed = true;
  }
  for (auto c : need_inline) {
    InlineFunctionInfo IFI;
    InlineFunction(*c, IFI);
  }
  return changed;
}

void remove_non_return_property(llvm::Module *M) {
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i){
    Function *F = &(*i);
    if (F->hasFnAttribute(Attribute::NoReturn)){
      F->removeFnAttr(Attribute::NoReturn);
    }
  }
}

void create_global_variable(llvm::Module *M) {
  llvm::Type *I32 = llvm::Type::getInt32Ty(M->getContext());
  llvm::Type *I8 = llvm::Type::getInt8Ty(M->getContext());

  auto zero = llvm::ConstantInt::get(I32, 0, true);

  // we need global variable used for warp shuffle
  // 1024 entries: indexed by inter_warp_idx*32 + intra_warp_idx
  // to isolate warp shuffle data across inter_warp loop iterations.
  llvm::Type *WarpArrayType = llvm::ArrayType::get(I32, 1024);
  llvm::Type *VoteArrayType = llvm::ArrayType::get(I8, 32);

  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
    schedule = std::stoi(std::string(env));
  }

  new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                           zero, "intra_warp_index", NULL,
                           llvm::GlobalValue::NotThreadLocal, 0, false);
  new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                           zero, "inter_warp_index", NULL,
                           llvm::GlobalValue::NotThreadLocal, 0, false);

  new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                           NULL, "__warps_per_group", NULL,
                           llvm::GlobalValue::NotThreadLocal, 0, false);

  auto local_group_id = new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                           NULL, "__local_group_id", NULL,
                           llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
  local_group_id->setDSOLocal(true);

  new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                           NULL, "dyn_shared_mem_size", NULL,
                           llvm::GlobalValue::NotThreadLocal, 0, false);

  if (schedule == 2) {
    // Schedule 2 (1:1 mapping): use vx_spawn's dim3_t globals directly,
    // eliminating the cuda_*_wrapper TLS copy layer.
    // dim3_t = union { struct {uint32_t x,y,z}; uint32_t m[3]; }
    auto Dim3Type = llvm::StructType::create(M->getContext(), {I32, I32, I32}, "dim3_t");

    // Remove CUDA's dummy declarations (non-TLS, addrspace(1), { i8 } types)
    // so we can create proper globals matching vx_spawn's definitions.
    if (auto *existing = M->getGlobalVariable("blockIdx")) {
      existing->eraseFromParent();
    }
    if (auto *existing = M->getGlobalVariable("threadIdx")) {
      existing->eraseFromParent();
    }
    if (auto *existing = M->getGlobalVariable("blockDim")) {
      existing->eraseFromParent();
    }
    if (auto *existing = M->getGlobalVariable("gridDim")) {
      existing->eraseFromParent();
    }

    // TLS: blockIdx, threadIdx (set by vx_spawn's process_threads)
    auto blockIdxGV = new llvm::GlobalVariable(*M, Dim3Type, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "blockIdx", NULL,
                             llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
    blockIdxGV->setDSOLocal(true);

    auto threadIdxGV = new llvm::GlobalVariable(*M, Dim3Type, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "threadIdx", NULL,
                             llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
    threadIdxGV->setDSOLocal(true);

    // Global structs: blockDim, gridDim (set by vx_spawn_threads before callback)
    new llvm::GlobalVariable(*M, Dim3Type, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "blockDim", NULL,
                             llvm::GlobalValue::NotThreadLocal, 0, false);
    new llvm::GlobalVariable(*M, Dim3Type, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "gridDim", NULL,
                             llvm::GlobalValue::NotThreadLocal, 0, false);

  } else {
    // Schedule 0/1: use CuPBoP's individual i32 globals (populated by cuda_*_wrapper)
    // TLS seed for divergence tracking — value is always 0 but LLVM treats
    // TLS loads as divergent sources, propagating to warp loop counters
    auto sche0_tid_tls = new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             zero, "sche_0_thread_idx_TLS", NULL,
                             llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
    sche0_tid_tls->setDSOLocal(true);

    new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "block_size", NULL,
                             llvm::GlobalValue::NotThreadLocal, 0, false);
    new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "block_size_x", NULL,
                             llvm::GlobalValue::NotThreadLocal, 0, false);
    new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "block_size_y", NULL,
                             llvm::GlobalValue::NotThreadLocal, 0, false);
    new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "block_size_z", NULL,
                             llvm::GlobalValue::NotThreadLocal, 0, false);
    new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "grid_size_x", NULL,
                             llvm::GlobalValue::NotThreadLocal, 0, false);
    new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "grid_size_y", NULL,
                             llvm::GlobalValue::NotThreadLocal, 0, false);
    new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "grid_size_z", NULL,
                             llvm::GlobalValue::NotThreadLocal, 0, false);
    auto block_index_x = new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "block_index_x", NULL,
                             llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
    auto block_index_y = new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "block_index_y", NULL,
                             llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
    auto block_index_z = new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "block_index_z", NULL,
                             llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
    auto thread_index_x = new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "thread_id_x", NULL,
                             llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
    auto thread_index_y = new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "thread_id_y", NULL,
                             llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
    auto thread_index_z = new llvm::GlobalVariable(*M, I32, false, llvm::GlobalValue::ExternalLinkage,
                             NULL, "thread_id_z", NULL,
                             llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);

    // LLVM is broken when using TLS with dynamic linkage on RISCV
    // and the generated binary contains invalid instructions.
    // Disable dynamic linkage since we don't create a shared library.
    block_index_x->setDSOLocal(true);
    block_index_y->setDSOLocal(true);
    block_index_z->setDSOLocal(true);
    thread_index_x->setDSOLocal(true);
    thread_index_y->setDSOLocal(true);
    thread_index_z->setDSOLocal(true);
  }

  // TLS variable used for warp-level collective operators
  auto warp_shfl = new llvm::GlobalVariable(
      *M, WarpArrayType, false, llvm::GlobalValue::ExternalLinkage, NULL,
      "warp_shfl", NULL, llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
  warp_shfl->setDSOLocal(true);
  auto warp_vote = new llvm::GlobalVariable(
      *M, VoteArrayType, false, llvm::GlobalValue::ExternalLinkage, NULL,
      "warp_vote", NULL, llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
  warp_vote->setAlignment(llvm::MaybeAlign(32));
  warp_vote->setDSOLocal(true);
  auto vote_count = new llvm::GlobalVariable(
      *M, I32, false, llvm::GlobalValue::ExternalLinkage, NULL,
      "vote_count", NULL, llvm::GlobalValue::GeneralDynamicTLSModel, 0, false);
  vote_count->setDSOLocal(true);

  // Context pool pointer — set by host via cudaMalloc + cudaMemcpyToSymbol
  auto PtrTy = PointerType::getUnqual(M->getContext());
  auto ctx_pool = new llvm::GlobalVariable(
      *M, PtrTy, false, llvm::GlobalValue::ExternalLinkage, NULL,
      "__ctx_pool", NULL, llvm::GlobalValue::NotThreadLocal, 0, false);
  ctx_pool->setDSOLocal(true);
}

void remove_metadata(llvm::Module *M) {
  SmallVector<std::pair<unsigned, MDNode *>, 4> MDs;
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    F->getAllMetadata(MDs);
    for (auto &MD : MDs) {
      F->setMetadata(MD.first, NULL);
    }
    F->removeFnAttr("target-features");
    F->removeFnAttr("target-cpu");
    // Strip optnone so that backend -O3 can actually optimize kernel functions.
    // optnone is inherited from the frontend -O0 compilation and blocks all
    // LLVM optimization passes even when -O3 is specified at the backend.
    if (F->hasFnAttribute(Attribute::OptimizeNone)) {
      F->removeFnAttr(Attribute::OptimizeNone);
      // optnone forces noinline; remove it to allow inlining decisions at -O3
      F->removeFnAttr(Attribute::NoInline);
    }
  }
}

void init_llvm_pass() {

  InitializeAllTargets();
  InitializeAllTargetMCs();
  InitializeAllAsmPrinters();
  InitializeAllAsmParsers();

  PassRegistry &Registry = *PassRegistry::getPassRegistry();

  initializeCore(Registry);
  initializeScalarOpts(Registry);
  initializeVectorization(Registry);
  initializeIPO(Registry);
  initializeAnalysis(Registry);
  initializeTransformUtils(Registry);
  initializeInstCombine(Registry);
  //initializeInstrumentation(Registry);
  initializeTarget(Registry);

  llvm::StringMap<llvm::cl::Option *> &opts = llvm::cl::getRegisteredOptions();
  // Set an LLVM cl::opt if this LLVM still registers it. Options come and go
  // between releases (e.g. 'scalarize-load-store' exists in LLVM 18 but is a
  // ScalarizerPass parameter in LLVM 20), so a missing one is reported, not fatal.
  auto set_opt = [&](const char *name, const char *value) {
    auto it = opts.find(name);
    if (it == opts.end() || !it->second) {
      if (cupbop_debug()) fprintf(stderr, "[init] LLVM option '%s' not registered in this LLVM; skipped\n", name);
      return;
    }
    it->second->addOccurrence(1, StringRef(name), StringRef(value), false);
  };
  set_opt("scalarize-load-store", "1");
  set_opt("vectorizer-min-trip-count", "2");
  set_opt("jump-threading-threshold", "0");
  set_opt("jump-threading-implication-search-threshold", "0");
  // Enable diagnostics from the loop vectorizer.
  set_opt("pass-remarks-missed", "loop-vectorize");
  set_opt("pass-remarks-missed", "slp-vectorize");
  set_opt("pass-remarks-analysis", "loop-vectorize");
  set_opt("pass-remarks-analysis", "slp-vectorize");
  set_opt("pass-remarks", "loop-vectorize");
  set_opt("pass-remarks", "slp-vectorize");
}

void llvm_preprocess(llvm::Module *M) {
  init_llvm_pass();

  auto Registry = PassRegistry::getPassRegistry();

  llvm::legacy::PassManager Passes;

  std::vector<std::string> passes;
  passes.push_back("lowerswitch");
  passes.push_back("mem2reg");
  passes.push_back("simplifycfg");
  passes.push_back("loop-simplify");
  for (auto pass : passes) {
    const PassInfo *PIs = Registry->getPassInfo(StringRef(pass));
    if (PIs) {
      Pass *thispass = PIs->createPass();
      Passes.add(thispass);
    } else {
      if (cupbop_debug()) printf("Pass: %s not found\n", pass.c_str());
    }
  }
  Passes.run(*M);
}

bool lower_constant_expr(llvm::Module *M) {
  bool modified = false;
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
        if (auto load_inst = dyn_cast<llvm::LoadInst>(BI)) {
          if (auto ce = dyn_cast<llvm::ConstantExpr>(load_inst->getOperand(0))) {
            modified = true;
            auto ReplInst = ce->getAsInstruction();
            ReplInst->insertBefore(load_inst);
            load_inst->setOperand(0, ReplInst);
          }
        } else if (auto store_inst = dyn_cast<llvm::StoreInst>(BI)) {
          for (unsigned op = 0; op < 2; op++) {
            if (auto ce = dyn_cast<llvm::ConstantExpr>(store_inst->getOperand(op))) {
              modified = true;
              auto ReplInst = ce->getAsInstruction();
              ReplInst->insertBefore(store_inst);
              store_inst->setOperand(op, ReplInst);
            }
          }
        } else if (auto gep = dyn_cast<llvm::GetElementPtrInst>(BI)) {
          if (auto ce = dyn_cast<llvm::ConstantExpr>(gep->getOperand(0))) {
            modified = true;
            auto ReplInst = ce->getAsInstruction();
            ReplInst->insertBefore(gep);
            gep->setOperand(0, ReplInst);
          }
        } else if (auto rmw = dyn_cast<llvm::AtomicRMWInst>(BI)) {
          if (auto ce = dyn_cast<llvm::ConstantExpr>(rmw->getPointerOperand())) {
            modified = true;
            auto ReplInst = ce->getAsInstruction();
            ReplInst->insertBefore(rmw);
            rmw->setOperand(0, ReplInst);
          }
        }
      }
    }
  }
  return modified;
}

void replace_cuda_math_built_in(llvm::Module *M) {
  // replace _ZL3expd, just delete its body
  for (Module::iterator i = M->begin(), e = M->end(); i != e; ++i) {
    Function *F = &(*i);
    auto func_name = F->getName().str();
    if (func_name.find("_ZL3expd") != std::string::npos) {
      F->deleteBody();
    }
  }
}


void init_block(llvm::Module *M, std::ofstream &fout) {
  // triton update
  bool triton_enabled = triton_cupbop_enabled();
  if (triton_enabled) {
    remove_non_return_property(M);
  }

  // using official llvm preprocess
  llvm_preprocess(M);
  // remove useles Cuda function
  remove_cuda_built_in(M);
  // replace CUDA math function, like expf
  replace_cuda_math_built_in(M);

  // lower ConstantExpression
  bool modified;
  do {
    modified = lower_constant_expr(M);
  } while (modified);
  // remove useless metadata
  remove_metadata(M);
  // inline warp-level function
  while (1) {
    if (!inline_warp_level_func(M))
      break;
  }
  // TODO: remove the hardcode
  while (1) {
    if (!inline_func_with_tid(M))
      break;
  }

  // Inline helper functions that transitively call shfl into kernel functions.
  // Must run BEFORE the general inline loop so that inline_shfl_helpers can
  // insert barrier0 after the inlined code. If the general inline loop runs
  // first, it inlines shfl-containing functions without adding barriers,
  // and the inter-warp exchange code won't get its own parallel region.
  int sched = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG"))
    sched = std::stoi(std::string(env));
  if (sched == 0) {
    while (1) {
      if (!inline_shfl_helpers(M))
        break;
    }
    // Re-run inline_func_with_tid after inline_shfl_helpers, because the
    // inlined helper code may contain threadIdx wrapper calls (__fetch_builtin_xEv)
    // that need to be inlined so tool.cpp can replace them with intra_warp_index.
    while (1) {
      if (!inline_func_with_tid(M))
        break;
    }
  }

  // Inline ALL remaining device functions (e.g. __float2half, __half2float)
  // that aren't covered by inline_func_with_tid. Without inlining, these
  // functions remain as external calls that have no implementation on Vortex.
  {
    bool changed = true;
    while (changed) {
      changed = false;
      for (auto &F : *M) {
        if (F.isDeclaration() || F.isIntrinsic()) continue;
        if (isKernelFunction(M, &F)) continue;
        if (F.getName().starts_with("__nv_")) continue;
        if (F.getName().contains("__vx_")) continue;
        // Skip functions that cause code explosion when inlined HERE
        // (general inline loop). However, do NOT mark them noinline —
        // the later O3 inliner needs to inline them, otherwise Vortex
        // backend's VortexDivergenceArguments pass enters an infinite
        // ping-pong loop when multiple kernels call the same callee
        // with different argument divergence (cc-cuda: compute1+compute2
        // both call representative, pass loops 20,325× per function).
        if (F.getName().contains("AtomicCAS") ||
            F.getName().contains("atomicCAS") ||
            F.getName().contains("representative")) continue;
        SmallVector<CallInst*, 8> calls;
        for (auto *U : F.users())
          if (auto *CI = dyn_cast<CallInst>(U))
            calls.push_back(CI);
        for (auto *CI : calls) {
          InlineFunctionInfo IFI;
          if (InlineFunction(*CI, IFI).isSuccess()) {
            if (cupbop_debug()) printf("inline-dev: %s\n", F.getName().str().c_str());
            changed = true;
          }
        }
      }
    }
  }

  // Force-unroll loops containing shfl calls (SCHE_0 only).
  // Replace warpSize with 32 so loop trip count is known for unroll.
  remove_cuda_built_in(M);

  // Must happen BEFORE replaceWarpShflFlat inserts barriers.
  // At this point shfl calls are still CUDA intrinsics (no barrier0 yet).
  // shfl barrier splits break for-loop control flow in warp loop.
  // Use LLVM pass pipeline instead of direct UnrollLoop API.
  if (sched == 0) {
    // First, add llvm.loop.unroll.full metadata to shfl-containing loops
    bool added_unroll_md = false;
    for (auto &F : *M) {
      if (F.isDeclaration()) continue;
      if (!isKernelFunction(M, &F)) continue;

      llvm::DominatorTree DT(F);
      llvm::LoopInfo LI(DT);

      if (cupbop_debug())
        fprintf(stderr, "[init] kernel %s: %u top-level loops\n",
                F.getName().str().c_str(),
                (unsigned)std::distance(LI.begin(), LI.end()));

      // Collect all loops including subloops
      SmallVector<Loop *, 8> AllLoops;
      for (auto *L : LI) {
        SmallVector<Loop *, 4> worklist;
        worklist.push_back(L);
        while (!worklist.empty()) {
          auto *CL = worklist.pop_back_val();
          AllLoops.push_back(CL);
          for (auto *SL : CL->getSubLoops())
            worklist.push_back(SL);
        }
      }
      if (cupbop_debug())
        fprintf(stderr, "[init]   total loops (including sub): %u\n",
                (unsigned)AllLoops.size());

      for (auto *L : AllLoops) {
        bool has_shfl = false;
        // Only unroll INNERMOST loops containing shfl. If a loop has
        // subloops (e.g. parallel_prefix_sum's outer per-thread loop with
        // an inner shfl reduction), unrolling the outer one is pointless
        // (its trip count is runtime-dependent) and makes the inner shfl
        // copies multiply, blowing up IR (jaccard SCHE_0: 32x outer × inner
        // unroll → 4.9 M IR lines, kernelTranslator hang).
        bool has_subloops_with_shfl = false;
        std::function<bool(Loop *)> hasShflInLoop = [&](Loop *LL) {
          for (auto *BB : LL->getBlocks()) {
            for (auto &I : *BB) {
              if (auto *CI = dyn_cast<CallInst>(&I)) {
                if (CI->getCalledFunction()) {
                  auto name = CI->getCalledFunction()->getName();
                  if (name.contains("shfl_down") || name.contains("shfl_up") ||
                      name.contains("shfl_xor") || name.contains("shfl_bfly") ||
                      name.contains("nvvm.shfl.sync.down") ||
                      name.contains("nvvm.shfl.sync.up") ||
                      name.contains("nvvm.shfl.sync.bfly"))
                    return true;
                }
              }
            }
          }
          return false;
        };
        for (auto *SL : L->getSubLoops())
          if (hasShflInLoop(SL)) { has_subloops_with_shfl = true; break; }
        if (has_subloops_with_shfl) continue;
        for (auto *BB : L->getBlocks()) {
          for (auto &I : *BB) {
            if (auto *CI = dyn_cast<CallInst>(&I)) {
              if (CI->getCalledFunction()) {
                auto name = CI->getCalledFunction()->getName();
                // Only unroll for shfl variants that need per-lane state:
                // down/up/xor/bfly. idx-mode (__shfl_sync) is a broadcast
                // that doesn't need warp-loop unrolling — and forcing 32x
                // unroll on a loop containing CAS/atomic causes O3 to hang
                // (cc-cuda compute2: 5306 lines, clang stuck at 99% CPU).
                if (name.contains("shfl_down") || name.contains("shfl_up") ||
                    name.contains("shfl_xor") || name.contains("shfl_bfly") ||
                    name.contains("nvvm.shfl.sync.down") ||
                    name.contains("nvvm.shfl.sync.up") ||
                    name.contains("nvvm.shfl.sync.bfly"))
                  has_shfl = true;
              }
            }
          }
        }
        if (!has_shfl) continue;

        // Add llvm.loop.unroll.count=32 to force unroll with explicit count.
        // "full" requires SE to compute trip count; explicit count does not.
        auto &Ctx = M->getContext();
        MDNode *Dummy = MDNode::getTemporary(Ctx, {}).release();
        auto *I32Ty = Type::getInt32Ty(Ctx);
        MDNode *UnrollMD = MDNode::get(Ctx,
            {MDString::get(Ctx, "llvm.loop.unroll.count"),
             ConstantAsMetadata::get(ConstantInt::get(I32Ty, 32))});
        MDNode *Root = MDNode::get(Ctx, {Dummy, UnrollMD});
        Root->replaceOperandWith(0, Root);
        MDNode::deleteTemporary(Dummy);

        // Set on loop latch terminator
        if (auto *Latch = L->getLoopLatch()) {
          Latch->getTerminator()->setMetadata("llvm.loop", Root);
          added_unroll_md = true;
          if (cupbop_debug())
            fprintf(stderr, "[init] added unroll.full to shfl loop in %s\n",
                    F.getName().str().c_str());
        }
      }
    }

    // Run O1 pipeline to unroll loops with #pragma unroll metadata.
    // -O0 BC ignores pragma; O1 processes llvm.loop.unroll.* hints.
    if (added_unroll_md) {
      llvm::PassBuilder PB;
      llvm::LoopAnalysisManager LAM;
      llvm::FunctionAnalysisManager FAM;
      llvm::CGSCCAnalysisManager CGAM;
      llvm::ModuleAnalysisManager MAM;
      PB.registerModuleAnalyses(MAM);
      PB.registerCGSCCAnalyses(CGAM);
      PB.registerFunctionAnalyses(FAM);
      PB.registerLoopAnalyses(LAM);
      PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);

      // Minimal passes to unroll shfl loops:
      // mem2reg promotes alloca→SSA so LoopUnroll can compute trip count
      // and loop rotation works correctly (while→do-while for exact 5 copies).
      llvm::FunctionPassManager FPM;
      FPM.addPass(llvm::PromotePass());
      FPM.addPass(llvm::InstCombinePass());
      FPM.addPass(llvm::SimplifyCFGPass());
      FPM.addPass(llvm::LoopSimplifyPass());
      FPM.addPass(llvm::LCSSAPass());
      FPM.addPass(llvm::LoopUnrollPass());

      for (auto &F : *M) {
        if (F.isDeclaration()) continue;
        if (!isKernelFunction(M, &F)) continue;
        bool func_has_shfl = false;
        for (auto &BB : F) {
          for (auto &I : BB) {
            if (auto *CI = dyn_cast<CallInst>(&I)) {
              if (CI->getCalledFunction()) {
                auto name = CI->getCalledFunction()->getName();
                if (name.contains("shfl") || name.contains("nvvm.shfl"))
                  func_has_shfl = true;
              }
            }
          }
        }
        if (func_has_shfl) {
          FPM.run(F, FAM);
          if (cupbop_debug())
            fprintf(stderr, "[init] O1 unroll on %s\n",
                    F.getName().str().c_str());
        }
      }
      if (cupbop_debug())
        fprintf(stderr, "[init] ran selective unroll passes for shfl loops\n");
    }
  }

  // Re-run remove_cuda_built_in to replace any new threadIdx/blockDim
  // NVVM intrinsics exposed by the helper inlining above.
  remove_cuda_built_in(M);

  // create global variable for warp and vote
  create_global_variable(M);

  // replace phi with data load
  phi2alloc(M);

  // For SCHE_0: insert cupbop.shfl.barrier after each barrier0 and at
  // conditional merge points. Must run AFTER phi2alloc so we can insert
  // barrier BEFORE phi2alloc's loads (phi nodes are already converted).
  if (sched == 0) {
    for (auto &F : *M) {
      if (!isKernelFunction(M, &F)) continue;
      SmallVector<CallInst *, 8> sync_calls;
      for (auto &BB : F) {
        for (auto &I : BB) {
          if (auto *CI = dyn_cast<CallInst>(&I)) {
            if (CI->isInlineAsm() || !CI->getCalledFunction()) continue;
            auto name = CI->getCalledFunction()->getName().str();
            if (name == "llvm.nvvm.barrier0" || name == "llvm.nvvm.barrier.sync")
              sync_calls.push_back(CI);
          }
        }
      }
      // Only insert shfl_barriers in kernels that actually use shfl.
      // Kernels without shfl don't need the extra barriers, and adding
      // them causes barrier/warp-loop explosion (cc-cuda: 1201 barriers).
      // Only insert shfl_barriers if kernel uses shfl_down/up/xor/bfly.
      // shfl idx (broadcast) doesn't need barrier synchronization, and
      // adding barriers causes code explosion (cc-cuda: 569→9032 lines).
      // Note: at this point, early shfl replacement has already converted
      // shfl calls to warp_shfl store+cupbop.shfl.barrier+read.
      // Check for warp_shfl GEPs as evidence of down/up/xor replacement.
      // idx mode replacement doesn't create barriers (isIdxMode skip).
      bool kernel_has_shfl = false;
      for (auto &BB : F) {
        for (auto &I : BB) {
          if (auto *CI2 = dyn_cast<CallInst>(&I)) {
            if (CI2->isInlineAsm() || !CI2->getCalledFunction()) continue;
            auto n = CI2->getCalledFunction()->getName().str();
            // Only count down/up/xor/bfly shfl (not idx, not cupbop.shfl.barrier)
            if (n.find("shfl") != std::string::npos &&
                (n.find("down") != std::string::npos ||
                 n.find("up") != std::string::npos ||
                 n.find("xor") != std::string::npos ||
                 n.find("bfly") != std::string::npos))
              kernel_has_shfl = true;
          }
        }
        if (kernel_has_shfl) break;
      }
      if (!sync_calls.empty() && kernel_has_shfl) {
        auto &Ctx = M->getContext();
        auto FT = FunctionType::get(Type::getVoidTy(Ctx), {}, false);
        auto callee = M->getOrInsertFunction("cupbop.shfl.barrier", FT);
        for (auto *CI : sync_calls) {
          // shfl_barrier after each barrier0
          auto *next = CI->getNextNode();
          if (next) {
            IRBuilder<> builder(next);
            builder.CreateCall(callee);
          }
          // Create a separate barrier block BEFORE the exchange merge.
          // Exchange-path predecessors go through the barrier block,
          // skip-path predecessors go directly to the merge.
          // This eliminates multi-entry PR issues.
          BasicBlock *syncBB = CI->getParent();
          auto *term = syncBB->getTerminator();
          if (auto *br = dyn_cast<BranchInst>(term)) {
            if (br->isConditional()) {
              BasicBlock *mergeBB = br->getSuccessor(1);
              // Only split exchange merge blocks. Identify by having a
              // predecessor named "cond.*" (from cond.true.i in exchange).
              bool has_exchange_pred = false;
              for (auto *pred : predecessors(mergeBB)) {
                if (pred->getName().starts_with("cond."))
                  has_exchange_pred = true;
              }
              if (mergeBB && mergeBB != syncBB && has_exchange_pred) {
                BasicBlock *barrierBB = BasicBlock::Create(
                    Ctx, mergeBB->getName().str() + "_xchg_barrier",
                    CI->getFunction(), mergeBB);
                IRBuilder<> bbBuilder(barrierBB);
                bbBuilder.CreateCall(callee);
                bbBuilder.CreateBr(mergeBB);
                // Three-barrier structure:
                // exchange preds → xchg_barrier → common_barrier → mergeBB
                // skip preds → skip_barrier → common_barrier → mergeBB
                //
                // xchg_barrier: clean single-path entry for exchange PR
                // skip_barrier: clean single-path entry for skip path
                // common_barrier: single entry for mergeBB's PR (warp loop)

                // Create common barrier (between xchg/skip and mergeBB)
                BasicBlock *commonBB = BasicBlock::Create(
                    Ctx, mergeBB->getName().str() + "_common_barrier",
                    CI->getFunction(), mergeBB);
                {
                  IRBuilder<> cb(commonBB);
                  cb.CreateCall(callee);
                  cb.CreateBr(mergeBB);
                }

                // xchg_barrier → common_barrier (not directly to mergeBB)
                barrierBB->getTerminator()->replaceUsesOfWith(mergeBB, commonBB);

                // Collect and redirect preds
                SmallVector<BasicBlock *, 4> exchange_preds;
                SmallVector<BasicBlock *, 4> skip_preds;
                for (auto *pred : predecessors(mergeBB)) {
                  if (pred == commonBB) continue;
                  if (pred->getName().starts_with("if.then") ||
                      pred->getName().starts_with("cond.") ||
                      pred == syncBB)
                    exchange_preds.push_back(pred);
                  else
                    skip_preds.push_back(pred);
                }
                for (auto *pred : exchange_preds)
                  pred->getTerminator()->replaceUsesOfWith(mergeBB, barrierBB);
                // Skip preds → skip_barrier → common_barrier
                if (!skip_preds.empty()) {
                  BasicBlock *skipBB = BasicBlock::Create(
                      Ctx, mergeBB->getName().str() + "_skip_barrier",
                      CI->getFunction(), commonBB);
                  IRBuilder<> sb(skipBB);
                  sb.CreateCall(callee);
                  sb.CreateBr(commonBB);
                  for (auto *pred : skip_preds)
                    pred->getTerminator()->replaceUsesOfWith(mergeBB, skipBB);
                }
              }
            }
          }
        }
      }
    }
  }

  // Split blocks after shfl_barrier calls to separate the barrier
  // from following code (e.g. exchange conditional). This ensures
  // the following code gets its own PR and warp loop.
  // Must run AFTER xchg_barrier creation (which checks for
  // conditional terminators in barrier blocks).
  if (sched == 0) {
    for (auto &F : *M) {
      if (!isKernelFunction(M, &F)) continue;
      SmallVector<CallInst *, 8> shfl_barriers;
      for (auto &BB : F) {
        for (auto &I : BB) {
          if (auto *CI = dyn_cast<CallInst>(&I)) {
            if (!CI->getCalledFunction()) continue;
            if (CI->getCalledFunction()->getName() == "cupbop.shfl.barrier")
              shfl_barriers.push_back(CI);
          }
        }
      }
      for (auto *CI : shfl_barriers) {
        auto *following = CI->getNextNode();
        if (following && !following->isTerminator()) {
          CI->getParent()->splitBasicBlock(
              following,
              CI->getParent()->getName().str() + "_after_shfl");
        }
      }
    }
  }

  // DEBUG: dump IR before phi2alloc
  // phi2alloc already called above (before barrier insertion)

  // replace share memory
  int schedule = 0;
  int local_mem_use = 1;

  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
    schedule = std::stoi(std::string(env));
  }
  if (char *env = std::getenv("VORTEX_LOCALMEM_FLAG"))
  {
    local_mem_use = std::stoi(std::string(env));
  }

  if (schedule == 0)
  {
    mem_share2global(M);
  }

  else if (schedule == 2)
  {
    if (local_mem_use == 1)
    {
      mem_share2local(M);
    }
    else
    {
      mem_share2global_sche_2(M);
    }
  }
    else 
    {
    std::cerr << "Error: invalid VORTEX_SCHEDULE_FLAG (use 0 or 2)\n";
    std::exit(1);
    }
  // replace constant memory (addrspace 4 → 0)
  mem_constant2global(M, fout);
  // replace __device__ variables (addrspace 1 → 0)
  mem_device2global(M, fout);
  // Replace __nvvm_reflect() with constant 1 (FTZ enabled, CUDA default).
  // On sm_90, clang inlines CUDA math helpers exposing __nvvm_reflect calls
  // that query device properties at compile time. These must be resolved
  // before the RISC-V backend sees them. FTZ=0 path contains NaN sentinels.
  {
    if (Function *RF = M->getFunction("__nvvm_reflect")) {
      SmallVector<CallInst *, 8> calls;
      for (auto *U : RF->users())
        if (auto *CI = dyn_cast<CallInst>(U))
          calls.push_back(CI);
      for (auto *CI : calls) {
        CI->replaceAllUsesWith(ConstantInt::get(Type::getInt32Ty(M->getContext()), 1));
        CI->eraseFromParent();
      }
      if (RF->use_empty())
        RF->eraseFromParent();
      if (cupbop_debug())
        printf("[init] replaced %zu __nvvm_reflect calls with 1\n", calls.size());
    }
  }

  // Mark __vx_* Vortex runtime functions as having side effects so LLVM's
  // O3 optimizer doesn't eliminate them. These are DXA/barrier/local-mem
  // functions with hardware side effects invisible to LLVM.
  // They may be definitions (inline in CUDA) or declarations (external).
  for (auto &F : *M) {
    // Match both unmangled (__vx_*) and C++ mangled (_Z*__vx_*) names
    if (F.getName().contains("__vx_")) {
      F.addFnAttr(Attribute::NoInline);
      F.setMemoryEffects(MemoryEffects::unknown());
      F.removeFnAttr(Attribute::ReadNone);
      F.removeFnAttr(Attribute::ReadOnly);
      if (cupbop_debug())
        printf("[init] marked __vx_ function: %s\n", F.getName().str().c_str());
    }
  }

  // replace asm Inline
  replace_asm_call(M);

  // replace dynamic shared memory
  auto dynamic_shared_memory_addr =
      M->getGlobalVariable("dynamic_shared_memory");

  if (dynamic_shared_memory_addr) {
    if (cupbop_debug()) std::cout << "[DEBUG] replace dynamic shared memory found!" << std::endl;
    replace_dynamic_shared_memory(M);
  }
}
