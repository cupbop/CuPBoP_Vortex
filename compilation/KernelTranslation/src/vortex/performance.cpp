#include "performance.h"
#include "tool.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/StringRef.h"

//LLVM 18
//#include "llvm/TargetParser/Triple.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/LoopPass.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/InitializePasses.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/PassInfo.h"
#include "llvm/PassRegistry.h"
#include "llvm/Support/CommandLine.h"
//LLVM 18
//#include "llvm/Support/Host.h"
#include "llvm/TargetParser/Host.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/IR/PassManager.h"

#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"

//LLVM 18
#include "llvm/Passes/PassBuilder.h"
//#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <map>
#include <set>
#include <sstream>
#include <tuple>
#include <vector>


using namespace llvm;

void eliminate_redudant_threadIdx_computation(llvm::Module *M) {
  for (Module::iterator f = M->begin(); f != M->end(); ++f) {
    Function *F = &(*f);
    if (!isKernelFunction(M, F))
      continue;
    // check whether we have inter_warp
    bool has_inter_warp = false;
    for (Function::iterator b = F->begin(); b != F->end(); ++b) {
      BasicBlock *B = &(*b);
      if (B->getName().starts_with("inter_warp_cond")) {
        has_inter_warp = true;
        break;
      }
    }
    if (!has_inter_warp) {
      // since there is not inter_warp, the inter_warp_index is always 0,
      // threadIdx = 32*inter_warp_index+intra_warp_index --> threadIdx =
      // intra_warp_index
      for (Function::iterator b = F->begin(); b != F->end(); ++b) {
        BasicBlock *B = &(*b);
        LoadInst *load_intra_warp_index = NULL;
        // if there is store to local_intra_warp_idx, it is not safe to replace
        bool safe_to_replace = true;
        std::set<Instruction *> need_to_replace;
        for (BasicBlock::iterator i = B->begin(); i != B->end(); ++i) {
          Instruction *inst = &(*i);
          if (auto loadInst = dyn_cast<LoadInst>(inst)) {
            if (loadInst->getOperand(0)->getName().equals(
                    "local_intra_warp_idx") &&
                !load_intra_warp_index)
              load_intra_warp_index = loadInst;
          } else if (auto storeInst = dyn_cast<StoreInst>(inst)) {
            if (storeInst->getOperand(1)->getName().equals(
                    "local_intra_warp_idx")) {
              safe_to_replace = false;
              break;
            }
          } else if (auto binaryInst = dyn_cast<BinaryOperator>(inst)) {
            if (binaryInst->getName().starts_with("thread_idx") &&
                binaryInst->getOpcode() == Instruction::Add) {
              need_to_replace.insert(binaryInst);
            }
          }
        }
        if (safe_to_replace) {
          for (auto inst : need_to_replace) {
            inst->replaceAllUsesWith(load_intra_warp_index);
            inst->eraseFromParent();
          }
        }
      }
    }
  }
}

void performance_optimization(llvm::Module *M) {
  printf("performance optimization\n");
  for (auto F = M->begin(); F != M->end(); F++) {
    for (auto I = F->arg_begin(); I != F->arg_end(); ++I) {
      if (I->getType()->isPointerTy()) {
        I->addAttr(llvm::Attribute::NoAlias);
      }
    }
  }

  llvm::PassBuilder PassBuilder;
  llvm::LoopAnalysisManager LAM;
  llvm::FunctionAnalysisManager FAM;
  llvm::CGSCCAnalysisManager CGAM;
  llvm::ModuleAnalysisManager MAM;

  PassBuilder.registerModuleAnalyses(MAM);
  PassBuilder.registerCGSCCAnalyses(CGAM);
  PassBuilder.registerFunctionAnalyses(FAM);
  PassBuilder.registerLoopAnalyses(LAM);
  PassBuilder.crossRegisterProxies(LAM, FAM, CGAM, MAM);

  llvm::ModulePassManager MPM;
  llvm::OptimizationLevel OptLevel = llvm::OptimizationLevel::O3;
  MPM = PassBuilder.buildPerModuleDefaultPipeline(OptLevel);
  MPM.run(*M, MAM);
}


// Legacy Optimization before LLVM 18
/*
void performance_optimization(llvm::Module *M) {
    //DEBUG_INFO("performance optimization\n");
  // remove useless load
  eliminate_redudant_threadIdx_computation(M);
  // we assume no alias in arguments
  for (auto F = M->begin(); F != M->end(); F++) {
    for (auto I = F->arg_begin(); I != F->arg_end(); ++I) {
      if (I->getType()->isPointerTy()) {
        I->addAttr(llvm::Attribute::NoAlias);
      }
    }
  }

  llvm::legacy::PassManager Passes;

  // add target machine info
  llvm::Triple triple("x86_64-unknown-linux-gnu");

  std::string Error;
  const Target *TheTarget = TargetRegistry::lookupTarget("", triple, Error);
  if (!TheTarget) {
    printf("Error: %s\n", Error.c_str());
    assert(0);
  }
  llvm::TargetOptions Options;
  Options.FloatABIType = FloatABI::Hard;

  TargetMachine *TM = TheTarget->createTargetMachine(
      triple.getTriple(), llvm::sys::getHostCPUName().str(), StringRef("+m,+f"),
      Options, Reloc::PIC_, CodeModel::Small, CodeGenOpt::Aggressive);
  assert(TM && "No Machine Information\n");

  Passes.add(createTargetTransformInfoWrapperPass(TM->getTargetIRAnalysis()));

  TargetLibraryInfoImpl TLII(triple);
  TLII.disableAllFunctions();
  Passes.add(new TargetLibraryInfoWrapperPass(TLII));

  // Add O3 optimization
  llvm::PassManagerBuilder Builder;
  Builder.OptLevel = 3;
  Builder.SizeLevel = 0;

  Builder.LoopVectorize = true;
  Builder.SLPVectorize = true;

  // Commented out from newest CupBop
  //Builder.VerifyInput = true;
  //Builder.VerifyOutput = true;

  Builder.populateModulePassManager(Passes);
  Passes.run(*M);
}
*/