// p3plugin.cpp (2026-11-04): one plugin for the whole lift optimisation. Each source keeps its own registration, renamed by the build (-DllvmGetPassPluginInfo=...).
// liftopt.cpp (lo-mma, experiments/p2a), p2cfold.cpp (p2c-fold, p2c-alias, experiments/p2c), pairjoin.cpp (lo-pair, lo-brmark, lo-brfix, experiments/p2f), losink.cpp (lo-sink).
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
using namespace llvm;
extern "C" PassPluginLibraryInfo p3_liftopt_info();
extern "C" PassPluginLibraryInfo p3_fold_info();
extern "C" PassPluginLibraryInfo p3_pair_info();
void p3RegisterSink(PassBuilder &PB);
void p3RegisterNext(PassBuilder &PB);
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "p3", "0.1", [](PassBuilder &PB) {
    p3_liftopt_info().RegisterPassBuilderCallbacks(PB);
    p3_fold_info().RegisterPassBuilderCallbacks(PB);
    p3_pair_info().RegisterPassBuilderCallbacks(PB);
    p3RegisterSink(PB);
    p3RegisterNext(PB);
  }};
}
