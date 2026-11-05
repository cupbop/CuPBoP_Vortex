#ifndef __STABLE_ORDER__
#define __STABLE_ORDER__

// Translation must not depend on where the allocator put the IR. Iterating a container keyed by pointers visits the
// entries in heap-address order (std::set, std::map) or pointer-hash order (DenseMap, SmallPtrSet, unordered_*), and
// both move between runs of the same binary on the same input. ASLR changes the pointer hashes, so a DenseMap frees its
// entries in another order (first seen: ~AnalysisManager, keyed by the addresses of static AnalysisKeys), later
// allocations reuse other chunks, and even std::set<T *> order moves. Without ASLR, an input path of another length
// shifts the heap the same way. Such a loop that creates, names or places IR gives a different kernel from run to run
// (experiments/determ).
// Rule of this translator: a pointer-keyed container may answer membership questions; a loop over one whose result
// depends on the visiting order goes through llvm::SetVector / llvm::MapVector (insertion order) or the helper below.

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"

#include <algorithm>
#include <vector>

namespace cupbop {

// the blocks of S: those the kernel came with, then those split off at barriers (split_block_by_sync names them), each
// group in the function's block order. A std::set<BasicBlock *> mostly gave this order, because the split blocks are
// allocated after the rest; the context arrays are numbered in it, so it keeps the array layout of the older builds.
template <class Set> std::vector<llvm::BasicBlock *> blocks_in_order(llvm::Function &F, const Set &S) {
  std::vector<llvm::BasicBlock *> v;
  v.reserve(S.size());
  for (llvm::BasicBlock &B : F)
    if (S.count(&B)) v.push_back(&B);
  std::stable_partition(v.begin(), v.end(), [](llvm::BasicBlock *B) { return !B->getName().contains("_after_block_sync_"); });
  return v;
}

} // namespace cupbop

#endif
