#include "flag.h"
#include "generate_wrapper.h"
#include "handle_sync.h"
#include "init.h"
#include "insert_sync.h"
#include "insert_warp_loop.h"
#include "performance.h"
#include "tool.h"
#include "warp_func.h"
#include "llvm/IR/Module.h"
#include <assert.h>
#include <fstream>
#include <iostream>
#include "llvm/Analysis/CGSCCPassManager.h"
#include "llvm/Analysis/LoopAnalysisManager.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/InitializePasses.h"
#include "llvm/PassInfo.h"
#include "llvm/PassRegistry.h"
#include "llvm/Support/raw_ostream.h"
#include <stdlib.h>

using namespace llvm;
using namespace cupbop;

std::string PATH = "kernel_meta.log";

static bool debug_mode() {
  static bool enabled = (std::getenv("CUPBOP_DEBUG") != nullptr);
  return enabled;
}

static void dumpFile(llvm::Module *program, std::string name) {
  if (!debug_mode()) return;
  std::error_code EC;
  raw_fd_ostream OutFile(name, EC);
  program->print(OutFile, nullptr);
}

#define DBG_LOG(msg) do { if (debug_mode()) std::cout << msg << std::flush; } while(0)

int main(int argc, char **argv) {
  assert(argc == 3 && "incorrect number of arguments\n");
  llvm::Module *program = LoadModuleFromFilr(argv[1]);

  std::ofstream fout;
  fout.open(PATH);

  // Replace cp.async before init_block (PTX inline asm must be alive)
  DBG_LOG("replace_cp_async_dxa\n");
  replace_cp_async_with_dxa(program);


  DBG_LOG("init_block\n");
  init_block(program, fout);
  dumpFile(program, "0_after_init_block.ll");

  // Create pass infrastructure
  PassBuilder PB;
  ModuleAnalysisManager MAM;
  FunctionAnalysisManager FAM;
  LoopAnalysisManager LAM;
  CGSCCAnalysisManager CGAM;

  PB.registerModuleAnalyses(MAM);
  PB.registerFunctionAnalyses(FAM);
  PB.registerLoopAnalyses(LAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);

  ModulePassManager MPM;
  MapOpt warp_mapping = MAPPING_1TO1;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
    int schedule = std::stoi(std::string(env));
    if (schedule == 0) warp_mapping = MAPPING_FLAT;
  }
  MPM.addPass(ReplaceWarpLevelPrimitive(warp_mapping));
  MPM.run(*program, MAM);

  VerifyModule(program);
  insert_sync(program);
  dumpFile(program, "1_after_insert_sync.ll");

  VerifyModule(program);

  // Lower atomicrmw fadd (float atomic add) to CAS loop.
  // RISC-V has no float atomic add instruction.
  DBG_LOG("lower_atomicrmw_fadd\n");
  lower_atomicrmw_fadd(program);

  // Same uniform-void warp-reduce fastpath for i64 atomicrmw add — RV64
  // has native amoadd.d but cross-warp/cross-core contention on a single
  // global counter still serializes; collapsing 32 atomics to 1 per warp
  // is a big win for kernels like marchingCubes generatingTriangles.
  DBG_LOG("lower_atomicrmw_add_i64\n");
  lower_atomicrmw_add_i64(program);

  DBG_LOG("lower_cmpxchg_for_flat\n");
  lower_cmpxchg_for_flat(program);

  DBG_LOG("split_block_by_sync\n");
  split_block_by_sync(program);
  dumpFile(program, "2_after_split_sync.ll");

  // For SCHE_0: replace shfl intrinsics with warp_shfl store/barrier/read
  // BEFORE warp loop creation. This ensures the initial store to warp_shfl
  // is inside a PR and gets wrapped in a warp loop for per-thread access.
  // If done after insert_warp_loop, O3 hoists the store out of the loop
  // and constant-folds the thread index to 0.
  DBG_LOG("replace_warp_shfl_early\n");
  replace_warp_shfl_early(program);
  // Re-run split_block_by_sync for barriers added by shfl replacement
  split_block_by_sync(program);
  dumpFile(program, "2b_after_shfl_replace.ll");

  DBG_LOG("insert_warp_loop\n");
  insert_warp_loop(program);
  dumpFile(program, "3_after_warp_loop.ll");

  VerifyModule(program);

  DBG_LOG("replace_built_in_function\n");
  replace_built_in_function(program);
  dumpFile(program, "4_after_replace_builtin.ll");

  DBG_LOG("replace_wmma_intrinsics\n");
  replace_wmma_intrinsics(program);
  dumpFile(program, "5_after_wmma.ll");

  VerifyModule(program);
  fout.flush(); // ensure kernel_meta.log is written before generate_wrapper reads it
  DBG_LOG("generate_wrapper\n");
  generate_wrapper(program);
  dumpFile(program, "6_after_generate_wrapper.ll");

  DBG_LOG("performance_optimization\n");
  performance_optimization(program);
  dumpFile(program, "7_after_perf_opt.ll");

  VerifyModule(program);

  // Run LoopSimplify to ensure all loops have preheaders.
  // Multi-entry PRs can create warp loops with side entries that
  // bypass the preheader, causing VortexBranchDivergence to crash.
  {
    llvm::legacy::PassManager Passes;
    const PassInfo *PI = PassRegistry::getPassRegistry()->getPassInfo(StringRef("loop-simplify"));
    if (PI) Passes.add(PI->createPass());
    Passes.run(*program);
  }

  DumpModule(program, argv[2]);

  fout.close();

  return 0;
}
