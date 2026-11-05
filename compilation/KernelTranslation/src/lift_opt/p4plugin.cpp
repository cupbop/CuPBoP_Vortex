// p4plugin.cpp (2026-11-04): the passes of experiments/p4 in one plugin; each source keeps its registration, renamed by the build.
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
using namespace llvm;
extern "C" PassPluginLibraryInfo p4_stale_info();
extern "C" PassPluginLibraryInfo p4_pred_info();
extern "C" PassPluginLibraryInfo p4_tree_info();
extern "C" PassPluginLibraryInfo p4_mm_info();
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "p4", "0.1", [](PassBuilder &PB) {
    p4_stale_info().RegisterPassBuilderCallbacks(PB);
    p4_pred_info().RegisterPassBuilderCallbacks(PB);
    p4_tree_info().RegisterPassBuilderCallbacks(PB);
    p4_mm_info().RegisterPassBuilderCallbacks(PB);
  }};
}
