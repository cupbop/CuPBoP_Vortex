#include "flag.h"
#include "generate_wrapper.h"
#include "handle_sync.h"
#include "init.h"
#include "async_copy.h"
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

  // LLVM 20 clang: kernels carry the ptx_kernel calling convention (no "kernel" annotation)
  DBG_LOG("normalize_ptx_kernel_cc\n");
  normalize_ptx_kernel_cc(program);

  DBG_LOG("lower_named_barriers\n");
  lower_named_barriers(program);
  DBG_LOG("drop_cta_membar_at_barriers\n");
  drop_cta_membar_at_barriers(program);

  // cp.async family (before init_block: replace_asm_call would drop the PTX asm).
  // Default: synchronous copies (lower_cp_async), correct whatever the commit/wait groups say.
  // CUPBOP_CP_ASYNC_DXA=1: the old automatic cp.async -> DXA conversion first (an SGEMM-only prototype that
  // produces wrong code for other kernels: fixed coordinates, square tensors, per-thread smem destinations).
  if (const char *e = std::getenv("CUPBOP_CP_ASYNC_DXA"); e && std::atoi(e) != 0) {
    fprintf(stderr, "\n*** WARNING: CUPBOP_CP_ASYNC_DXA=1: automatic cp.async -> DXA conversion is an SGEMM-only "
                    "prototype.\n*** It assumes fixed tile coordinates (0 / blockIdx*TILE), square tensors and the "
                    "SGEMM argument order,\n*** and silently produces WRONG results for other kernels (e.g. "
                    "transpose). Use __vx_dxa_issue_* + descriptors instead.\n\n");
    DBG_LOG("replace_cp_async_dxa\n");
    replace_cp_async_with_dxa(program);
  }
  DBG_LOG("lower_cp_async\n");
  lower_cp_async(program);
  // DXA: !vx.dxa.desc metadata -> dxa_descriptors.txt; tag the DXA waits for the core-mapping pass
  emit_dxa_desc_sidecar(program);
  mark_dxa_waits(program);


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
    if (schedule == 1) warp_mapping = MAPPING_CORE;   // virt: lanes are hardware, warp ops stay native
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

  // core mapping: a DXA issue once per CTA, a DXA wait once per hardware warp (before the warp-loop
  // pass counter is localized by replace_built_in_function)
  DBG_LOG("virt_dxa_cta_once\n");
  virt_dxa_cta_once(program);

  DBG_LOG("replace_built_in_function\n");
  replace_built_in_function(program);
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
    if (std::stoi(std::string(env)) == 1) mark_virt_lane_divergence(program); // virt: hardware lanes
  }
  dumpFile(program, "4_after_replace_builtin.ll");

  DBG_LOG("replace_wmma_intrinsics\n");
  replace_wmma_intrinsics(program);
  replace_nvvm_wmma_intrinsics(program);
  replace_nvvm_mma_intrinsics(program); // CuLifter-lifted HMMA (mma.sync intrinsics)
  dumpFile(program, "5_after_wmma.ll");

  VerifyModule(program);
  fout.flush(); // ensure kernel_meta.log is written before generate_wrapper reads it
  DBG_LOG("generate_wrapper\n");
  generate_wrapper(program);
  dumpFile(program, "6_after_generate_wrapper.ll");

  DBG_LOG("performance_optimization\n");
  performance_optimization(program);
  dumpFile(program, "7_after_perf_opt.ll");

  DBG_LOG("hoist_block_constant_loads\n");
  hoist_block_constant_loads(program);

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
