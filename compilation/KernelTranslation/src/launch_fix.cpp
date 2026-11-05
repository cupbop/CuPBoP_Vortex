// Launch rewrites left by the translator for the host runtime (launch_fix.h). 2026-11-04.
#include "launch_fix.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Metadata.h"
#include <cstdio>
#include <fstream>
#include <map>
#include <string>

using namespace llvm;

static const char *const MD_NAME = "cupbop.launch_fix";
static std::map<std::string, std::map<std::string, uint64_t>> table;   // ordered: the file does not depend on pass order

void launch_fix_note(Module *M, StringRef kernel, StringRef key, uint64_t value) {
  LLVMContext &C = M->getContext();
  M->getOrInsertNamedMetadata(MD_NAME)->addOperand(MDNode::get(
      C, {MDString::get(C, kernel), MDString::get(C, key), ConstantAsMetadata::get(ConstantInt::get(Type::getInt64Ty(C), value))}));
}

void launch_fix_collect(Module *M) {
  NamedMDNode *N = M->getNamedMetadata(MD_NAME);
  if (!N) return;
  for (MDNode *E : N->operands()) {
    auto *K = E->getNumOperands() == 3 ? dyn_cast<MDString>(E->getOperand(0)) : nullptr;
    auto *Y = E->getNumOperands() == 3 ? dyn_cast<MDString>(E->getOperand(1)) : nullptr;
    auto *V = E->getNumOperands() == 3 ? mdconst::dyn_extract<ConstantInt>(E->getOperand(2)) : nullptr;
    if (!K || !Y || !V) report_fatal_error("!cupbop.launch_fix: an entry is not {kernel, key, i64 value}");
    table[K->getString().str()][Y->getString().str()] = V->getZExtValue();
  }
  M->eraseNamedMetadata(N);
}

void launch_fix_write() {
  std::remove("cupbop_launch_fix.txt");   // a stale file of an earlier translation in this directory must not rewrite this kernel's launch
  if (table.empty()) return;
  std::ofstream f("cupbop_launch_fix.txt");
  f << "# launch rewrites of the translator (launch_fix.h): <kernel> <key>=<value> ...\n";
  for (auto &[k, kv] : table) {
    f << k;
    for (auto &[key, v] : kv) f << ' ' << key << '=' << v;
    f << '\n';
  }
}
