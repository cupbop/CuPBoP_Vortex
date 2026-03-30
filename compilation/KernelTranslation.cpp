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
#include "llvm/Passes/PassBuilder.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/PassManager.h"
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
  MPM.addPass(ReplaceWarpLevelPrimitive(MAPPING_1TO1));
  MPM.run(*program, MAM);

  VerifyModule(program);
  insert_sync(program);
  dumpFile(program, "1_after_insert_sync.ll");

  VerifyModule(program);
  DBG_LOG("split_block_by_sync\n");
  split_block_by_sync(program);
  dumpFile(program, "2_after_split_sync.ll");

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
  DBG_LOG("generate_wrapper\n");
  generate_wrapper(program);
  dumpFile(program, "6_after_generate_wrapper.ll");

  DBG_LOG("performance_optimization\n");
  performance_optimization(program);
  dumpFile(program, "7_after_perf_opt.ll");

  VerifyModule(program);

  DumpModule(program, argv[2]);

  fout.close();

  return 0;
}
