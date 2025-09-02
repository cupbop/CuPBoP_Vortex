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

static void dumpFile(llvm::Module * program, std::string name) {
  std::error_code EC;
  raw_fd_ostream OutFile(name, EC);
  program->print(OutFile, nullptr);
}

int main(int argc, char **argv) {
  assert(argc == 3 && "incorrect number of arguments\n");
  llvm::Module *program = LoadModuleFromFilr(argv[1]);

  std::ofstream fout;
  fout.open(PATH);

  // inline, and create auxiliary global variables
  std::cout << "init_block\n" << std::flush;
  printIR(program);
  init_block(program, fout);

  dumpFile(program, "0.ll");
  // Create pass infrastructure
  PassBuilder PB;
  ModuleAnalysisManager MAM;
  FunctionAnalysisManager FAM;
  LoopAnalysisManager LAM;
  CGSCCAnalysisManager CGAM;

  // Register analyses
  PB.registerModuleAnalyses(MAM);
  PB.registerFunctionAnalyses(FAM);
  PB.registerLoopAnalyses(LAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);

  // Create pass manager and add your pass
  ModulePassManager MPM;
  MPM.addPass(ReplaceWarpLevelPrimitive(MAPPING_1TO1));
  MPM.run(*program, MAM);

  // insert sync
  VerifyModule(program);
  insert_sync(program);

  dumpFile(program, "3.ll");

  // split block by sync
  VerifyModule(program);


  std::cout << "split\n" << std::flush;
  //print the proogram
  printIR(program);
  split_block_by_sync(program);
  // add loop for intra&intera thread


  dumpFile(program, "4.ll");
  
  // VerifyModule(program);
  std::cout << "insert_warp_loop\n" << std::flush;
  printIR(program);
  insert_warp_loop(program);

  dumpFile(program, "5.ll");

  VerifyModule(program);

  // (TODO): replace this patch
  std::cout << "replace\n" << std::flush;
  printIR(program);
  replace_built_in_function(program);

  dumpFile(program, "6.ll");
  
  VerifyModule(program);
  std::cout << "generate\n" << std::flush;
  printIR(program);
  generate_wrapper(program);

  // VerifyModule(program);
  std::cout << "performance opt\n" << std::flush;
  printIR(program);
  // performance optimization
  performance_optimization(program);

  std::cout << "verify\n" << std::flush;
  printIR(program);
  VerifyModule(program);

  std::cout << "dump\n" << std::flush;
  DumpModule(program, argv[2]);

  fout.close();

  return 0;
}
