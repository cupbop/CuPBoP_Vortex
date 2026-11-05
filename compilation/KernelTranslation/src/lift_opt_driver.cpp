// The lift optimisation inside the translator (2026-11-04). Until now separate `opt` steps in front of CuPBoP (experiments/p4/scripts/mkp4.sh on
// experiments/p3). The passes in src/lift_opt come from those trees and pipeline.inc is generated from their scripts (sync_from_p3.py), so that this file
// holds no pipeline of its own: what mkp4.sh writes to its output file is what the translator goes on with, byte for byte (CUPBOP_LIFT_OPT_DUMP).
// VORTEX_SCHEDULE_FLAG picks the row of schedule.inc, as the options of mkp4.sh would.
//
// CUPBOP_LIFT_OPT (default 1)    the pipeline and the defaults of schedule.inc on a module that is_lifted_module accepts; never on anything else.
//                                =0: the translation of before, also for input that went through mkp4.sh already (a second run changes it)
// CUPBOP_LIFT_OPT_WHY=1          prints the decision and the pipeline
// CUPBOP_LIFT_OPT_DUMP=<file>    the module after the pipeline, as `opt -S` prints it
// CUPBOP_LIFT_OPT_DUMP_ONLY=1    with _DUMP: stop there
// CUPBOP_LIFT_OPT_BC=<file>      the bitcode the rest of the translation reads: the bytes of the harness's device bitcode
// CUPBOP_LIFT_OPT_DETECT_ONLY=1  print lifted=0|1 and the reason, stop (corpus audits)
// CUPBOP_LIFT_OPT_NOPAIR=1       without lo-pair (mkp3.sh P3_NOPAIR=1; comparison with CUPBOP_ADDR_CARRY)
// CUPBOP_LIFT_OPT_PIPE=<p>       replaces the first stage (mkp3.sh P3_PIPE; measurements)
// CUPBOP_LIFT_OPT_P4=0           the pipeline of experiments/p3 alone: no row of schedule.inc, the queue of p2c-fold instead of lo-dq
// CUPBOP_LIFT_OPT_STALE=0        without lo-stale (its default waits for a decision: tg sm75 -19.5%, dotproduct s2 +12.2%)
// The passes' own switches (P2C_*, LO_*, LP_*) are read as in the opt step; LIFT_OPT_ENV gives mkp3.sh's defaults.
//
// Every translation reads the original input and runs the pipeline once, so the translations of examples/stack_fallback.sh
// (with the same environment) get the same module: nothing is applied twice and nothing is lost, unlike PRE_BACKEND_OPT.
#include "lift_opt.h"
#include "launch_fix.h"
#include "tool.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/Analysis/CGSCCPassManager.h"
#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Analysis/LoopAnalysisManager.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassInstrumentation.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/raw_ostream.h"
#include <cstdio>
#include <cstdlib>
#include <string>

using namespace llvm;

#include "lift_opt/pipeline.inc"
#include "lift_opt/schedule.inc"

extern "C" PassPluginLibraryInfo p3_all_info();   // src/lift_opt/p3plugin.cpp
extern "C" PassPluginLibraryInfo p4_all_info();   // src/lift_opt/p4plugin.cpp

static bool env_on(const char *n) {
  const char *e = std::getenv(n);
  return e && std::atoi(e) != 0;
}

// CuLifter's output has no marker of its own, and !llvm.ident, the entry block's name and the parameter buffer are all kept by
// llvm-as, llvm-link, internalize and always-inline. Each test alone is enough to reject: a CUDA source module has !llvm.ident (clang
// always writes it) and neither the name of the lifter's entry block nor its parameter copy. A lifted module that fails a test
// only loses the optimisation.
bool is_lifted_module(Module *M, std::string *why) {
  auto no = [&](std::string w) { if (why) *why = std::move(w); return false; };
  if (M->getNamedMetadata("llvm.ident")) return no("has !llvm.ident (a compiler's module)");
  if (!M->getNamedMetadata("nvvmir.version")) return no("no !nvvmir.version");
  // isKernelFunction exits on such a module; the translator's own "no kernel entry" error comes later (cuDNN modules without an entry)
  if (!M->getNamedMetadata("nvvm.annotations")) return no("no !nvvm.annotations");
  unsigned kernels = 0;
  for (Function &F : *M) {
    if (F.isDeclaration() || !isKernelFunction(M, &F)) continue;
    ++kernels;
    BasicBlock &E = F.getEntryBlock();
    if (!E.getName().starts_with("EntryBB_")) return no("kernel " + F.getName().str() + ": entry block is not the lifter's");
    bool param_local = false;
    for (Instruction &I : E) param_local |= isa<AllocaInst>(I) && I.getName() == "param_local";
    if (!param_local) return no("kernel " + F.getName().str() + ": no param_local buffer");
  }
  if (!kernels) return no("no kernel");
  if (why) *why = std::to_string(kernels) + " lifted kernel(s)";
  return true;
}

// mkp3.sh's gate: `grep -qE` on the module's text. Globals and functions only: the module's name is a path, not a property of the code.
static bool gate_full(Module *M) {
  auto hit = [](const std::string &s) {
    for (const char *w : LIFT_OPT_GATE) if (s.find(w) != std::string::npos) return true;
    return false;
  };
  std::string s;
  raw_string_ostream os(s);
  for (GlobalVariable &G : M->globals()) { s.clear(); G.print(os); if (hit(s)) return true; }
  for (Function &F : *M) { s.clear(); F.print(os); if (hit(s)) return true; }
  return false;
}

static void replace_all(std::string &s, const std::string &a, const std::string &b) {
  for (size_t i = 0; (i = s.find(a, i)) != std::string::npos; i += b.size()) s.replace(i, a.size(), b);
}

// the row of schedule.inc for this translation, nullptr: none
static const LiftOptRow *schedule_row() {
  if (const char *e = std::getenv("CUPBOP_LIFT_OPT_P4"); e && std::atoi(e) == 0) return nullptr;
  int s = 2;
  if (const char *e = std::getenv("VORTEX_SCHEDULE_FLAG")) s = std::atoi(e);
  for (const LiftOptRow &r : LIFT_OPT_SCHEDULES) if (r.schedule == s) return &r;
  return nullptr;
}

static std::string pipeline_for(Module *M, const LiftOptRow *row, const char *&kind) {
  kind = "CUPBOP_LIFT_OPT_PIPE";
  if (const char *p = std::getenv("CUPBOP_LIFT_OPT_PIPE")) return p;
  const bool full = gate_full(M);
  kind = full ? "full" : "light";
  std::string s = full ? LIFT_OPT_FULL : LIFT_OPT_LIGHT;
  replace_all(s, "${LP}", env_on("CUPBOP_LIFT_OPT_NOPAIR") ? "" : LIFT_OPT_LP);
  replace_all(s, "${P4_PREHEXT:-}", row ? row->prehext : "");
  replace_all(s, "$IC", LIFT_OPT_IC);
  return s;
}

// mkp4.sh's second opt; empty: no such step
static std::string stage2_for(const LiftOptRow *row) {
  if (!row) return "";
  std::string list = row->stage2;
  if (const char *e = std::getenv("CUPBOP_LIFT_OPT_STALE"); e && std::atoi(e) == 0) {
    replace_all(list, "lo-stale,", "");
    replace_all(list, ",lo-stale", "");
  }
  std::string s = LIFT_OPT_STAGE2;
  replace_all(s, "${P4_POST:-}", "");
  replace_all(s, "$P4", list);
  return s;
}

// After p2c-fold or p2c-alias @shared_mem holds the whole CTA area, so the dynamic size of the launch would only add a second one.
// Both passes work on a @shared_mem with one user function and tell by their result whether they rewrote it.
static void note_shared_fold(Module *M) {
  GlobalVariable *G = M->getGlobalVariable("shared_mem", true);
  if (!G) report_fatal_error("lift optimisation: @shared_mem gone after a fold");
  SetVector<Function *> users;
  SmallVector<User *, 64> w(G->users().begin(), G->users().end());
  while (!w.empty()) {
    User *U = w.pop_back_val();
    if (auto *I = dyn_cast<Instruction>(U)) users.insert(I->getFunction());
    else for (User *V : U->users()) w.push_back(V);
  }
  for (Function *F : users) {
    if (isKernelFunction(M, F)) launch_fix_note(M, F->getName(), "dyn_smem", 0);
    else fprintf(stderr, "[lift-opt] @shared_mem folded in %s, not a kernel: the launch keeps its dynamic size\n", F->getName().str().c_str());
  }
}

static void run_pipeline(Module *M, const std::string &pipe, PassInstrumentationCallbacks *PIC) {
  PassBuilder PB(nullptr, PipelineTuningOptions(), std::nullopt, PIC);
  p3_all_info().RegisterPassBuilderCallbacks(PB);
  p4_all_info().RegisterPassBuilderCallbacks(PB);
  LoopAnalysisManager LAM;
  FunctionAnalysisManager FAM;
  CGSCCAnalysisManager CGAM;
  ModuleAnalysisManager MAM;
  PB.registerModuleAnalyses(MAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.registerFunctionAnalyses(FAM);
  PB.registerLoopAnalyses(LAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);
  ModulePassManager MPM;
  if (Error E = PB.parsePassPipeline(MPM, pipe)) report_fatal_error(Twine("lift optimisation: ") + toString(std::move(E)));
  MPM.run(*M, MAM);
}

// The rest of the translation depends on more than the text of the module: on use lists, which differ between a module held in memory
// after the passes, one parsed from text and one read from bitcode. The steps behind mkp3.sh are therefore followed one by one, so that
// a translation with the pipeline inside IS the translation of the pipeline's output:
//   opt -S writes text and llvm-as keeps the text parser's use lists in its bitcode, so `opt -passes=always-inline,globaldce` works on those:
//   reload_text + reload_bitcode. Without them the inliner takes the helpers' call sites in another order.
//   That opt keeps its use lists in the bitcode too, and the translator reads them: reload_bitcode, the same bytes (CUPBOP_LIFT_OPT_BC).
// New contexts: identified struct types of the old module would rename the new ones.
static Module *reload_text(Module *M, const std::string &text) {
  auto *C = new LLVMContext;
  SMDiagnostic Err;
  std::unique_ptr<Module> N = parseAssemblyString(text, Err, *C);
  if (!N) report_fatal_error(Twine("lift optimisation: reading the module back: ") + Err.getMessage());
  N->setModuleIdentifier(M->getModuleIdentifier());
  delete M;
  return N.release();
}

static Module *reload_bitcode(Module *M, const char *save) {
  SmallVector<char, 0> buf;
  raw_svector_ostream os(buf);
  WriteBitcodeToFile(*M, os, /*ShouldPreserveUseListOrder=*/true);
  if (save) {
    std::error_code EC;
    raw_fd_ostream f(save, EC, sys::fs::OF_None);
    if (EC) report_fatal_error(Twine("lift optimisation: ") + save + ": " + EC.message());
    f.write(buf.data(), buf.size());
  }
  auto *C = new LLVMContext;
  Expected<std::unique_ptr<Module>> N = parseBitcodeFile(MemoryBufferRef(StringRef(buf.data(), buf.size()), M->getModuleIdentifier()), *C);
  if (!N) report_fatal_error(Twine("lift optimisation: reading the module back: ") + toString(N.takeError()));
  delete M;
  return N->release();
}

Module *run_lift_opt(Module *M) {
  std::string why;
  if (env_on("CUPBOP_LIFT_OPT_DETECT_ONLY")) {
    const bool l = is_lifted_module(M, &why);
    printf("lifted=%d %s\n", (int)l, why.c_str());
    std::exit(0);
  }
  if (const char *e = std::getenv("CUPBOP_LIFT_OPT"); e && std::atoi(e) == 0) return M;
  const bool verbose = env_on("CUPBOP_LIFT_OPT_WHY");
  if (!is_lifted_module(M, &why)) {
    if (verbose) fprintf(stderr, "[lift-opt] off: %s\n", why.c_str());
    return M;
  }
  const char *kind;
  const LiftOptRow *row = schedule_row();
  const std::string pipe = pipeline_for(M, row, kind), stage2 = stage2_for(row);
  fprintf(stderr, "[lift-opt] %s: %s pipeline%s%s\n", why.c_str(), kind, stage2.empty() ? "" : ", then ", stage2.c_str());
  if (verbose) fprintf(stderr, "[lift-opt] %s\n", pipe.c_str());
  for (auto &e : LIFT_OPT_ENV) setenv(e.name, e.value, 0);
  for (auto &e : LIFT_OPT_DEFAULTS) setenv(e.name, e.value, 0);
  if (row) { for (auto &e : row->env) if (e.name) setenv(e.name, e.value, 0); }
  else for (auto &e : LIFT_OPT_NO_P4_ENV) setenv(e.name, e.value, 0);

  // mkp3.sh reads text, the harnesses hand over bitcode through llvm-as and opt: the same IR with other use lists, and lo-dq walks them (g32: two words swapped). Start from
  // what the script starts from, whatever the input file was.
  {
    std::string in;
    raw_string_ostream(in) << *M;
    M = reload_text(M, in);
  }

  bool folded = false, fold_seen = false;
  PassInstrumentationCallbacks PIC;
  PIC.registerAfterPassCallback([&](StringRef P, Any, const PreservedAnalyses &PA) {
    if (!P.ends_with("::FoldPass") && !P.ends_with("::AliasPass")) return;
    fold_seen = true;
    folded |= !PA.areAllPreserved();
  });
  // opt's command-line options, for the pipeline only: performance_optimization's instcombine keeps its defaults
  auto &opts = cl::getRegisteredOptions();
  for (auto &c : LIFT_OPT_CL) {
    auto it = opts.find(c.name);
    if (it == opts.end() || it->second->addOccurrence(0, c.name, c.value)) report_fatal_error(Twine("lift optimisation: option ") + c.name);
  }
  run_pipeline(M, pipe, &PIC);
  for (auto &c : LIFT_OPT_CL) opts[c.name]->setDefault();
  if (pipe.find("p2c-") != std::string::npos && !fold_seen)
    report_fatal_error("lift optimisation: the fold passes did not report (renamed? see run_lift_opt)");

  VerifyModule(M);
  std::string text;
  raw_string_ostream(text) << *M;
  if (!stage2.empty()) {   // mkp4.sh: a second opt on the printed module, with none of the first one's options
    M = reload_text(M, text);
    run_pipeline(M, stage2, nullptr);
    VerifyModule(M);
    text.clear();
    raw_string_ostream(text) << *M;
  }
  if (const char *d = std::getenv("CUPBOP_LIFT_OPT_DUMP")) {
    std::error_code EC;
    raw_fd_ostream os(d, EC, sys::fs::OF_TextWithCRLF);
    if (EC) report_fatal_error(Twine("lift optimisation: ") + d + ": " + EC.message());
    os << text;
    os.close();
    if (env_on("CUPBOP_LIFT_OPT_DUMP_ONLY")) std::exit(0);
  }
  // What stands behind mkp3.sh in every harness (compile_one.sh, run_trial.sh mode alone). The pipeline's own helpers (lo.cvt.*, lo.wmma) are
  // alwaysinline; left to the translation they are placed differently (hgemm, g32, fa2, fprop, cuBLAS hgemm).
  M = reload_bitcode(reload_text(M, text), nullptr);
  run_pipeline(M, "always-inline,globaldce", nullptr);
  M = reload_bitcode(M, std::getenv("CUPBOP_LIFT_OPT_BC"));
  if (folded) note_shared_fold(M);   // after the bytes above: launch_fix_collect takes the mark out again
  return M;
}
