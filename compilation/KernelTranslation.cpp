#include "flag.h"
#include "generate_wrapper.h"
#include "handle_sync.h"
#include "init.h"
#include "async_copy.h"
#include "async_ptx.h"
#include "insert_sync.h"
#include "insert_warp_loop.h"
#include "performance.h"
#include "tool.h"
#include "warp_func.h"
#include "lifted_ir.h"
#include "llvm/IR/Module.h"
#include <assert.h>
#include <fstream>
#include <iostream>
#include "llvm/Analysis/CGSCCPassManager.h"
#include "llvm/Analysis/LoopAnalysisManager.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/Analysis/CycleAnalysis.h"
#include "llvm/Transforms/Utils/FixIrreducible.h"
#include "llvm/Transforms/Utils/LoopSimplify.h"
#include "llvm/Transforms/Utils/LowerSwitch.h"
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
  {
    // A module without any kernel entry (no nvvm.annotations "kernel" / ptx_kernel function) used to translate
    // into an ELF with an empty kernel table that only fails at launch. CuLifter's CPU-lifter output (kernel
    // `void K()` reading a thread_local const_mem image, ir/platform_porting/raw) is such a module.
    int nkern = 0;
    for (auto &F : *program)
      if (!F.isDeclaration() && isKernelFunction(program, &F)) ++nkern;
    if (nkern == 0) {
      fprintf(stderr, "kernelTranslator: error: %s has no kernel entry (no nvvm.annotations \"kernel\" or ptx_kernel "
                      "function); CuLifter CPU-lifter IR must be converted to NVVM form first\n", argv[1]);
      return 1;
    }
  }

  // Hopper/Ampere async PTX (mbarrier, TMA, bulk copy, elect, cluster registers; async_ptx.h): first, so that
  // lower_named_barriers and lower_cp_async only see what is left, and every later pass sees plain calls
  DBG_LOG("lower_async_ptx\n");
  lower_async_ptx(program);
  // wide by-value parameters (CuLifter parameter structs) -> pointer to their consecutive launch slots
  pass_wide_kernel_args_by_slot(program);
  // __syncthreads_and / _or / _count (CuLifter: BAR.RED) -> barrier + shared-memory reduction
  lower_barrier_reductions(program);
  // ldmatrix / stmatrix inline asm (CuLifter LDSM / STSM) -> shuffle-based runtime helpers
  lower_ldmatrix_asm(program);
  lower_nvvm_rounding(program);
  shrink_lifter_local_mem(program);
  lower_redux_sync(program);
  lower_lanemask(program);
  dumpFile(program, "00_after_async_ptx.ll");

  DBG_LOG("lower_named_barriers\n");
  lower_named_barriers(program);
  // Vortex barrier numbers for the mbarriers, after the named barriers took theirs
  finalize_mbarrier_ids(program);
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


  // Warp loops (core mapping, schedule 1) need reducible control flow. insert_sync places the
  // loop-boundary barriers with LoopInfo, which does not see an irreducible cycle, and the parallel
  // region before a barrier that such a cycle enters twice gets two entries and is left without a warp
  // loop: its code then runs once per hardware thread instead of once per logical thread. Lifted
  // software-pipelined SASS has these (cuBLAS ampere_sgemm_*: the main loop is entered both at its
  // head and in the middle), and under the core mapping with more than one logical warp per physical
  // warp every logical warp read warp 0's shared-memory addresses (batched_gemm s1, P < warps/CTA).
  // Make such functions reducible (node splitting through a guard block) and give the new loops
  // preheaders; reducible functions are left untouched.
  int irr_schedule = 2;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) irr_schedule = std::stoi(std::string(env));
  if (irr_schedule == 1 && !std::getenv("CUPBOP_S1_NO_FIXIRR")) {   // core mapping only; schedule 0 keeps its CI baseline
    // before init_block, so that the guard PHIs FixIrreducible creates are demoted with all the others
    PassBuilder IPB;
    LoopAnalysisManager ILAM; FunctionAnalysisManager FAM; CGSCCAnalysisManager ICGAM; ModuleAnalysisManager IMAM;
    IPB.registerModuleAnalyses(IMAM); IPB.registerFunctionAnalyses(FAM); IPB.registerLoopAnalyses(ILAM);
    IPB.registerCGSCCAnalyses(ICGAM); IPB.crossRegisterProxies(ILAM, FAM, ICGAM, IMAM);
    for (Function &F : *program) {
      if (F.isDeclaration()) continue;
      bool irreducible = false;
      std::vector<const CycleInfo::CycleT *> work;
      for (const auto *C : FAM.getResult<CycleAnalysis>(F).toplevel_cycles()) work.push_back(C);
      while (!work.empty() && !irreducible) {
        const auto *C = work.back(); work.pop_back();
        if (!C->isReducible()) irreducible = true;
        for (const auto *Child : C->children()) work.push_back(Child);
      }
      if (!irreducible) continue;
      bool has_switch = false;
      for (BasicBlock &BB : F) has_switch |= isa<SwitchInst>(BB.getTerminator());
      if (has_switch) FAM.invalidate(F, LowerSwitchPass().run(F, FAM));
      FAM.invalidate(F, FixIrreduciblePass().run(F, FAM));
      FAM.invalidate(F, LoopSimplifyPass().run(F, FAM));
      fprintf(stderr, "[fixirr] %s: irreducible control flow made reducible (FixIrreducible%s + LoopSimplify)\n",
              F.getName().str().c_str(), has_switch ? " after LowerSwitch" : "");
    }
    VerifyModule(program);
  }

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

  fold_bitreverse_i1(program); // after the -O3 of performance_optimization, which creates them
  DumpModule(program, argv[2]);

  fout.close();

  return 0;
}
