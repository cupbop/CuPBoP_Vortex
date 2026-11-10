// Shared-memory reserve drop (CUPBOP_SMEM_RESERVE_DROP, default 0). 2026-11-03.
//
// Why: nvcc for sm_90 / sm_100 places the driver-reserved shared memory (cudaDevAttrReservedSharedMemoryPerBlock,
// 1 KB) at shared-window offsets 0..0x3ff and the kernel's own shared memory above it: the SASS forms every shared
// address from ((%cluster_ctarank << 24) + 0x400) + offset. CuLifter keeps the window offsets and declares
// @shared_mem with the ELF's reserved + static size (1024 bytes for a kernel with only dynamic shared memory), and the
// host side (experiments/mllib/hostlib/vx_wrapper.h) sizes the launch so that the CTA area reaches 1 KB + the
// kernel's "Shared:" bytes. An sm_75..86 lift addresses its data from window offset 0, so the same CUTLASS GEMM needs
// 32,768 bytes per CTA there and 33,792 bytes as an sm_90 / sm_100 lift: one CTA per core in 64 KB of local memory
// instead of two.
//
// What is proven: for every kernel F and every addrspace(3) global G that F uses, the lowest byte of G that F can
// touch -- loads, stores, atomics, and runtime helpers that read or write at or above a pointer argument (mbarrier
// words, TMA / bulk copies, ldmatrix / stmatrix rows). mem_share2local then places the CTA's shared area L bytes
// lower, L = the lowest touched byte of the whole area (statics in their layout, the dynamic part after them),
// rounded down to 64 and at most the static part, and logs L fewer static bytes (kernel_lmem.log, which the host
// adds to the dynamic size). Every pointer into the area moves by -L, nothing below L is ever touched, so the
// accessed bytes keep their relative layout and the program computes the same values. Nothing overlaps: the bytes
// that move out of the CTA's area are bytes no instruction reads or writes.
//
// Soundness rules (any violation leaves G "not proven" for that function, and mem_share2local keeps the layout):
//  - the uses of a pointer into G (and of integers made from one with ptrtoint) must not observe the shift: GEP,
//    bitcast / addrspacecast, phi / select, load / store / atomic address, icmp of two such pointers; an integer
//    address only through trunc / zext / sext, add / sub of a plain integer, inttoptr, and the allowlisted helpers
//    below. A pointer or address stored to memory, passed to any other call or asm, returned, or used in other
//    arithmetic (e.g. wgmma descriptors: shifts and masks of the address) is a failure;
//  - G must be used by kernel functions only (no device function that init_block would inline later);
//  - offsets: interval analysis (llvm::ConstantRange, wrapped intervals) of the SSA integer computations; threadIdx
//    in [0, 1024), blockDim in [1, 1024], %laneid in [0, 32), shuffles keep their operand's range, loads and
//    arguments are unknown. Loop-header phis: the tuples of header-phi ranges reachable from the loop entry are
//    enumerated (trace partitioning), so a double-buffer offset that toggles with a stage parity keeps its two
//    values; a phi with too many distinct values becomes "any value" (a loop counter). Where an interval is
//    imprecise because its operands are correlated ((a | b) - b, x - ((x + y) & ~3): the lifted SASS idioms), the
//    slice is evaluated exactly for every combination of its leaf values (each leaf over its range, at most 2^17
//    combinations), which over-approximates the real combinations;
//  - the analysis reads a canonicalized copy of the module (canonical_clone): poison flags and metadata dropped
//    first, undef / poison operands replaced by opaque calls, loads / stores made volatile (none deleted), the
//    shared globals turned into 1 GB external arrays (no object-size reasoning); then sroa / early-cse / simplifycfg
//    / instcombine / sccp / correlated-propagation. Results are keyed by function and global name; the copy is
//    discarded and the module being translated is not touched.
//
// The switch only adds this analysis and the drop: with CUPBOP_SMEM_RESERVE_DROP unset or 0 nothing here runs and the
// translation is unchanged.
//
// CUPBOP_SMEM_SHRINK=1 (default 0, needs CUPBOP_SMEM_RESERVE_DROP=1; 2026-11-04, experiments/p2b): the other end. CuLifter
// declares @shared_mem with its default window (32 KB) whatever the kernel uses, so a kernel touching 4 KB reserves
// 32 KB per CTA and fewer CTAs fit a core. The same walk records the end of every access (offset + access size), and
// the host gives the CTA only the bytes below the highest proven end. Addresses are not moved: the kernel's code is
// the same with the switch on, only the CTA's local-memory size differs. Most offsets depend on threadIdx, so the
// bound is taken per block shape: the analysis runs again with threadIdx / blockDim limited to each shape of a small
// list (kShapes; the limits reach the canonicalization as !range too), and kernel_lmem_hi.log gets
// "<kernel> <X> <Y> <Z> <bytes>": sound for every launch with blockDim.x <= X, .y <= Y, .z <= Z. The host takes the
// smallest entry covering the launch, at most the usual static + dynamic size; no covering entry = the usual size.
// An access whose extent is not known (TMA / bulk copy helpers) or any failure of the proof leaves no entry.
#include "smem_reserve.h"
#include "tool.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/IR/Operator.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <map>
#include <memory>
#include <optional>
#include <pthread.h>
#include <set>
#include <string>
#include <vector>

using namespace llvm;

bool smem_shrink_enabled() {
  static const bool on = [] {
    const char *e = std::getenv("CUPBOP_SMEM_SHRINK");
    return smem_reserve_drop_enabled() && e && std::atoi(e) != 0;
  }();
  return on;
}

bool smem_reserve_drop_enabled() {
  static const bool on = [] {
    const char *e = std::getenv("CUPBOP_SMEM_RESERVE_DROP");
    return e && std::atoi(e) != 0;
  }();
  return on;
}

namespace {

bool debug() {
  static const bool on = [] {
    const char *e = std::getenv("CUPBOP_SMEM_RESERVE_DEBUG");
    return e && std::atoi(e) != 0;
  }();
  return on;
}
std::string shortName(const std::string &n) { return n.size() > 48 ? n.substr(0, 40) + "..." + n.substr(n.size() - 8) : n; }

struct Shape {
  uint32_t x, y, z;
};
// the limits of threadIdx / blockDim during an analysis run: CUDA's (the drop) or one block shape (CUPBOP_SMEM_SHRINK)
Shape g_shape = {1024, 1024, 64};
bool g_hull = false;   // CUPBOP_SMEM_SHRINK runs: see RangeEval::fix
const Shape kShapes[] = {{32, 1, 1},  {64, 1, 1},  {128, 1, 1}, {256, 1, 1},  {512, 1, 1}, {1024, 1, 1},
                         {32, 2, 1},  {32, 4, 1},  {32, 8, 1},  {32, 16, 1},  {32, 32, 1}, {16, 16, 1},
                         {64, 2, 1},  {64, 4, 1},  {128, 2, 1}, {8, 8, 1}};
struct ShapeEnd {
  Shape s;
  uint64_t end;  // highest touched byte of the global + 1 (0: nothing touched)
};
// (function name, global name) -> the proven ends, one per shape that could be proven
std::map<std::pair<std::string, std::string>, std::vector<ShapeEnd>> g_ends;

const uint64_t kNone = UINT64_MAX;  // proven, but F never touches G
// (function name, global name) -> lowest touched byte of the global; absent = not proven
std::map<std::pair<std::string, std::string>, uint64_t> g_lowest;
std::map<std::pair<std::string, std::string>, std::string> g_why;

const size_t kMaxTuples = 32;      // header-phi tuples per loop and outer binding
const size_t kMaxDistinct = 4;     // a phi with more distinct ranges among the tuples is widened to "any value"
const uint64_t kMaxSteps = 4000000; // transfer-function evaluations per function

struct Tuple {
  int id;
  std::vector<ConstantRange> v;
};
struct Fix {
  bool failed = false;
  std::vector<std::unique_ptr<Tuple>> tuples;
};
using Bind = std::pair<const Loop *, const Tuple *>;
using Ctx = std::vector<Bind>;

ConstantRange full(unsigned W) { return ConstantRange::getFull(W); }
ConstantRange range(unsigned W, uint64_t lo, uint64_t hiExcl) {
  return ConstantRange(APInt(W, lo), APInt(W, hiExcl));
}

// x & m, m a run of ones [j, k): (x mod 2^k) rounded down to 2^j, monotone inside one 2^k block
std::optional<ConstantRange> andMask(const ConstantRange &X, const ConstantRange &M) {
  const APInt *m = M.getSingleElement();
  if (!m || m->isZero() || X.isFullSet() || X.isEmptySet() || X.isWrappedSet()) return std::nullopt;
  const unsigned W = m->getBitWidth(), j = m->countr_zero(), k = W - m->countl_zero();
  if (m->lshr(j).countr_one() != k - j) return std::nullopt;
  APInt lo = X.getUnsignedMin(), hi = X.getUnsignedMax();
  if (k < W && lo.lshr(k) != hi.lshr(k)) return std::nullopt;
  return ConstantRange::getNonEmpty(lo & *m, (hi & *m) + 1);
}
// x ^ y with y < 2^t: only the low t bits of x change, so x stays in its aligned 2^t block
std::optional<ConstantRange> xorBlock(const ConstantRange &X, const ConstantRange &Y) {
  if (X.isFullSet() || X.isEmptySet() || X.isWrappedSet() || Y.isFullSet() || Y.isEmptySet() || Y.isWrappedSet())
    return std::nullopt;
  APInt ymax = Y.getUnsignedMax();
  const unsigned W = ymax.getBitWidth(), t = W - ymax.countl_zero();
  if (t == 0 || t >= W) return std::nullopt;
  APInt lo = X.getUnsignedMin(), hi = X.getUnsignedMax();
  if (lo.lshr(t) != hi.lshr(t)) return std::nullopt;
  APInt base = lo.lshr(t).shl(t);
  return ConstantRange::getNonEmpty(base, base + APInt::getLowBitsSet(W, t) + 1);
}
bool shiftOk(const ConstantRange &S, unsigned W) { return !S.isEmptySet() && S.getUnsignedMax().ult(W); }
bool noZero(const ConstantRange &S) { return !S.isEmptySet() && !S.contains(APInt::getZero(S.getBitWidth())); }

class RangeEval {
public:
  explicit RangeEval(Function &F) : DT(F), LI(DT) {}
  ConstantRange eval(Value *V, const Ctx &ctx);
  bool aborted = false;
  std::string why;
  uint64_t steps = 0, loops = 0, widened = 0;
  // debug (CUPBOP_SMEM_RESERVE_TRACE=<value name>): the ranges of the value's operand tree, all iterations
  void trace(Value *V, int depth, std::set<Value *> &seen) {
    std::string t;
    raw_string_ostream os(t);
    if (auto *I = dyn_cast<Instruction>(V)) I->print(os);
    else V->printAsOperand(os, true);
    std::string line = os.str();
    if (line.size() > 160) line = line.substr(0, 160) + "...";
    std::string rs;
    raw_string_ostream ro(rs);
    if (V->getType()->isIntegerTy()) ro << eval(V, {});
    fprintf(stderr, "[trace] %*s%s   => %s\n", 2 * (12 - depth), "", line.c_str(), ro.str().c_str());
    auto *I = dyn_cast<Instruction>(V);
    if (!I || depth == 0 || !seen.insert(V).second || isa<PHINode>(I)) return;
    for (Value *O : I->operands())
      if (isa<Instruction>(O)) trace(O, depth - 1, seen);
  }

private:
  DominatorTree DT;
  LoopInfo LI;
  int nextId = 1;
  std::map<std::pair<const Value *, std::vector<int>>, ConstantRange> memo;
  std::set<std::pair<const Value *, std::vector<int>>> busy;
  std::map<std::pair<const Loop *, std::vector<int>>, std::unique_ptr<Fix>> fixes;
  std::map<const Loop *, std::vector<PHINode *>> hphis;

  const std::vector<PHINode *> &headerPhis(const Loop *L) {
    auto it = hphis.find(L);
    if (it != hphis.end()) return it->second;
    std::vector<PHINode *> v;
    for (PHINode &P : L->getHeader()->phis()) v.push_back(&P);
    return hphis.emplace(L, std::move(v)).first->second;
  }
  static std::vector<int> ids(const Ctx &c) {
    std::vector<int> k;
    for (auto &b : c) k.push_back(b.second->id);
    return k;
  }
  Fix *fix(const Loop *L, const Ctx &r);
  // exact range of I by evaluating its slice for every combination of the slice's leaf values (atoms), each atom
  // ranging over its interval; nullopt when the atoms are too many / too wide or an operation is not modelled
  std::optional<ConstantRange> enumerate(Instruction *I, const Ctx &r);
  bool interior(Value *V, const Ctx &r);

public:
  uint64_t enums = 0, enumOk = 0;
  ConstantRange transfer(Instruction *I, const Ctx &r, unsigned W);
};

ConstantRange RangeEval::eval(Value *V, const Ctx &ctx) {
  Type *T = V->getType();
  if (!T->isIntegerTy()) return full(1);  // callers only ask for integers
  const unsigned W = T->getIntegerBitWidth();
  if (auto *CI = dyn_cast<ConstantInt>(V)) return ConstantRange(CI->getValue());
  auto *I = dyn_cast<Instruction>(V);
  if (!I || aborted) return full(W);  // arguments, undef / poison, constant expressions
  // the loops around I (outermost first) and the bindings of ctx that apply to I
  SmallVector<const Loop *, 4> chain;
  for (const Loop *L = LI.getLoopFor(I->getParent()); L; L = L->getParentLoop()) chain.push_back(L);
  std::reverse(chain.begin(), chain.end());
  Ctx r;
  for (auto &b : ctx)
    if (r.size() < chain.size() && b.first == chain[r.size()]) r.push_back(b);
  auto key = std::make_pair((const Value *)I, ids(r));
  auto it = memo.find(key);
  if (it != memo.end()) return it->second;
  if (++steps > kMaxSteps) {
    aborted = true;
    why = "evaluation budget";
    return full(W);
  }
  ConstantRange R = full(W);
  if (r.size() < chain.size()) {
    // an unbound loop around I: the union over its reachable header tuples
    const Loop *L = chain[r.size()];
    Fix *fx = fix(L, r);
    if (fx && !fx->failed) {
      R = ConstantRange::getEmpty(W);
      for (auto &t : fx->tuples) {
        Ctx c2 = r;
        c2.push_back({L, t.get()});
        R = R.unionWith(eval(I, c2));
        if (R.isFullSet()) break;
      }
      if (R.isEmptySet()) R = full(W);
    }
  } else {
    if (!busy.insert(key).second) return full(W);  // a cycle that is not a natural loop: any value
    R = transfer(I, r, W);
    if (R.isEmptySet()) R = full(W);  // (only an operation on poison is empty; the machine computes something)
    // an imprecise interval (correlated operands: (a | b) - b, x - ((x + y) & ~3), ...): evaluate the slice exactly
    if ((R.isFullSet() || R.isSignWrappedSet() || R.isWrappedSet() ||
         (R.getUnsignedMax() - R.getUnsignedMin()).ugt(1 << 20)) && interior(I, r))
      if (auto X = enumerate(I, r)) R = R.intersectWith(*X);
    busy.erase(key);
  }
  memo.emplace(key, R);
  return R;
}

Fix *RangeEval::fix(const Loop *L, const Ctx &r) {
  auto fk = std::make_pair(L, ids(r));
  auto it = fixes.find(fk);
  if (it != fixes.end()) return it->second.get();  // nullptr while being computed: re-entry fails
  fixes[fk] = nullptr;
  loops++;
  auto fx = std::make_unique<Fix>();
  const auto &ph = headerPhis(L);
  BasicBlock *H = L->getHeader();
  std::vector<ConstantRange> init;
  for (PHINode *P : ph) {
    if (!P->getType()->isIntegerTy()) { init.push_back(full(1)); continue; }
    const unsigned W = P->getType()->getIntegerBitWidth();
    ConstantRange R = ConstantRange::getEmpty(W);
    for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
      if (!L->contains(P->getIncomingBlock(i))) R = R.unionWith(eval(P->getIncomingValue(i), r));
    if (R.isEmptySet()) R = full(W);
    init.push_back(R);
  }
  SmallVector<BasicBlock *, 4> latches;
  for (BasicBlock *B : predecessors(H))
    if (L->contains(B) && std::find(latches.begin(), latches.end(), B) == latches.end()) latches.push_back(B);
  std::vector<bool> topped(ph.size(), false);
  // CUPBOP_SMEM_SHRINK runs: a widened phi keeps the union of its values instead of "any value", so a reduction loop's
  // stride (s >>= 1) or a stale register carried around the loop stays bounded; 8 growths, then any value.
  std::vector<ConstantRange> hull;
  for (auto &x : init) hull.push_back(ConstantRange::getEmpty(x.getBitWidth()));
  std::vector<int> grown(ph.size(), 0);
  bool ok = false;
  for (int round = 0; round < (g_hull ? 32 : 12) && !ok && !aborted; ++round) {
    fx->tuples.clear();
    auto add = [&](std::vector<ConstantRange> v) -> bool {  // false: too many tuples
      for (size_t k = 0; k < v.size(); ++k)
        if (topped[k]) {
          if (!g_hull) { v[k] = full(v[k].getBitWidth()); continue; }
          ConstantRange U = hull[k].unionWith(v[k]);
          if (U != hull[k] && ++grown[k] > 8) U = full(v[k].getBitWidth());
          hull[k] = U;
          v[k] = U;
        }
      for (auto &t : fx->tuples)
        if (t->v == v) return true;
      if (fx->tuples.size() >= kMaxTuples) return false;
      auto t = std::make_unique<Tuple>();
      t->id = nextId++;
      t->v = std::move(v);
      fx->tuples.push_back(std::move(t));
      return true;
    };
    add(init);
    bool overflow = false;
    for (size_t i = 0; i < fx->tuples.size() && !overflow && !aborted; ++i) {
      const Tuple *t = fx->tuples[i].get();
      Ctx c2 = r;
      c2.push_back({L, t});
      for (BasicBlock *B : latches) {
        std::vector<ConstantRange> nv;
        for (size_t k = 0; k < ph.size(); ++k) {
          PHINode *P = ph[k];
          if (!P->getType()->isIntegerTy() || topped[k]) { nv.push_back(t->v[k]); continue; }
          nv.push_back(eval(P->getIncomingValueForBlock(B), c2));
        }
        if (!add(std::move(nv))) { overflow = true; break; }
      }
    }
    if (!overflow) { ok = true; break; }
    // widen: every phi with more than kMaxDistinct ranges among the tuples, else the one with the most
    size_t best = ph.size(), bestN = 1;
    bool any = false;
    for (size_t k = 0; k < ph.size(); ++k) {
      if (topped[k]) continue;
      std::vector<const ConstantRange *> d;
      for (auto &t : fx->tuples) {
        bool seen = false;
        for (auto *x : d) seen |= (*x == t->v[k]);
        if (!seen) d.push_back(&t->v[k]);
      }
      if (d.size() > kMaxDistinct) { topped[k] = true; any = true; widened++; }
      if (d.size() > bestN) { bestN = d.size(); best = k; }
    }
    if (!any) {
      if (best == ph.size()) break;
      topped[best] = true;
      widened++;
    }
  }
  if (!ok) fx->failed = true;
  Fix *res = fx.get();
  fixes[fk] = std::move(fx);
  return res;
}

bool RangeEval::interior(Value *V, const Ctx &r) {
  auto *I = dyn_cast<Instruction>(V);
  if (!I || !I->getType()->isIntegerTy() || I->getType()->getIntegerBitWidth() > 64) return false;
  if (!(isa<BinaryOperator>(I) || isa<ZExtInst>(I) || isa<SExtInst>(I) || isa<TruncInst>(I) || isa<ICmpInst>(I) ||
        isa<SelectInst>(I) || isa<FreezeInst>(I)))
    return false;
  for (Value *O : I->operands())
    if (!O->getType()->isIntegerTy() || O->getType()->getIntegerBitWidth() > 64) return false;
  // every loop around I must be bound (its header phis are then atoms of this context)
  size_t depth = 0;
  for (const Loop *L = LI.getLoopFor(I->getParent()); L; L = L->getParentLoop()) depth++;
  if (depth > r.size()) return false;
  const Loop *L = LI.getLoopFor(I->getParent());
  for (size_t k = depth; k-- > 0; L = L->getParentLoop())
    if (r[k].first != L) return false;
  return true;
}

std::optional<ConstantRange> RangeEval::enumerate(Instruction *Root, const Ctx &r) {
  const size_t kMaxSlice = 3000;
  const uint64_t kMaxAtom = 4096, kMaxCombos = uint64_t(1) << 17;
  enums++;
  // 1. the slice (interior instructions, operands first) and its atoms
  std::vector<Instruction *> order;
  std::vector<Value *> atoms;
  std::map<Value *, int> slot;  // value -> index in vals
  std::vector<std::pair<Value *, bool>> st{{Root, false}};
  std::set<Value *> onStack;
  while (!st.empty()) {
    auto [V, done] = st.back();
    st.pop_back();
    if (slot.count(V)) continue;
    if (isa<ConstantInt>(V)) continue;
    if (done) {
      slot[V] = (int)slot.size();
      order.push_back(cast<Instruction>(V));
      continue;
    }
    if (V != Root && !interior(V, r)) {
      slot[V] = (int)slot.size();
      atoms.push_back(V);
      continue;
    }
    if (!onStack.insert(V).second) return std::nullopt;  // (no cycles among interior instructions)
    if (order.size() + atoms.size() > kMaxSlice) return std::nullopt;
    st.push_back({V, true});
    for (Value *O : cast<Instruction>(V)->operands())
      if (!slot.count(O) && !isa<ConstantInt>(O)) st.push_back({O, false});
  }
  // 2. the atoms' ranges
  std::vector<uint64_t> base(atoms.size()), size(atoms.size());
  uint64_t combos = 1;
  for (size_t a = 0; a < atoms.size(); ++a) {
    ConstantRange R = eval(atoms[a], r);
    const unsigned AW = atoms[a]->getType()->getIntegerBitWidth();
    if (R.isEmptySet() || (R.isFullSet() && AW > 12)) return std::nullopt;
    if (R.isFullSet()) {  // a narrow atom (e.g. an i1 condition) with any value
      base[a] = 0;
      size[a] = uint64_t(1) << AW;
    } else {
      APInt n = R.getUpper() - R.getLower();  // modulo 2^W: the set size of a non-full range
      if (n.getActiveBits() > 13 || n.getZExtValue() > kMaxAtom) return std::nullopt;
      base[a] = R.getLower().getZExtValue();
      size[a] = n.getZExtValue();
    }
    combos *= size[a];
    if (combos > kMaxCombos) return std::nullopt;
  }
  // 3. every combination
  auto mask = [](unsigned w) { return w >= 64 ? ~uint64_t(0) : (uint64_t(1) << w) - 1; };
  auto sx = [](uint64_t v, unsigned w) -> int64_t { return w >= 64 ? (int64_t)v : (int64_t)(v << (64 - w)) >> (64 - w); };
  std::vector<uint64_t> vals(slot.size());
  std::vector<uint64_t> digit(atoms.size(), 0);
  const unsigned RW = Root->getType()->getIntegerBitWidth();
  uint64_t umin = ~uint64_t(0), umax = 0;
  int64_t smin = INT64_MAX, smax = INT64_MIN;
  auto get = [&](Value *O) -> uint64_t {
    if (auto *CI = dyn_cast<ConstantInt>(O)) return CI->getValue().getZExtValue();
    return vals[slot[O]];
  };
  for (uint64_t c = 0; c < combos; ++c) {
    for (size_t a = 0; a < atoms.size(); ++a)
      vals[slot[atoms[a]]] = (base[a] + digit[a]) & mask(atoms[a]->getType()->getIntegerBitWidth());
    for (Instruction *I : order) {
      const unsigned W = I->getType()->getIntegerBitWidth();
      uint64_t v = 0;
      if (auto *B = dyn_cast<BinaryOperator>(I)) {
        const uint64_t x = get(B->getOperand(0)), y = get(B->getOperand(1));
        switch (B->getOpcode()) {
        case Instruction::Add: v = x + y; break;
        case Instruction::Sub: v = x - y; break;
        case Instruction::Mul: v = x * y; break;
        case Instruction::Shl: if (y >= W) return std::nullopt; v = x << y; break;
        case Instruction::LShr: if (y >= W) return std::nullopt; v = x >> y; break;
        case Instruction::AShr: if (y >= W) return std::nullopt; v = (uint64_t)(sx(x, W) >> y); break;
        case Instruction::And: v = x & y; break;
        case Instruction::Or: v = x | y; break;
        case Instruction::Xor: v = x ^ y; break;
        case Instruction::UDiv: if (!y) return std::nullopt; v = x / y; break;
        case Instruction::URem: if (!y) return std::nullopt; v = x % y; break;
        case Instruction::SDiv: if (!y || (sx(y, W) == -1 && sx(x, W) == sx(uint64_t(1) << (W - 1), W))) return std::nullopt;
          v = (uint64_t)(sx(x, W) / sx(y, W)); break;
        case Instruction::SRem: if (!y || sx(y, W) == -1) return std::nullopt; v = (uint64_t)(sx(x, W) % sx(y, W)); break;
        default: return std::nullopt;
        }
      } else if (auto *C = dyn_cast<CastInst>(I)) {
        const uint64_t x = get(C->getOperand(0));
        const unsigned SW = C->getOperand(0)->getType()->getIntegerBitWidth();
        if (isa<SExtInst>(C)) v = (uint64_t)sx(x, SW);
        else v = x;  // zext, trunc (masked below)
      } else if (auto *Cm = dyn_cast<ICmpInst>(I)) {
        const unsigned OW = Cm->getOperand(0)->getType()->getIntegerBitWidth();
        const uint64_t x = get(Cm->getOperand(0)), y = get(Cm->getOperand(1));
        const int64_t a = sx(x, OW), b = sx(y, OW);
        switch (Cm->getPredicate()) {
        case CmpInst::ICMP_EQ: v = x == y; break;
        case CmpInst::ICMP_NE: v = x != y; break;
        case CmpInst::ICMP_UGT: v = x > y; break;
        case CmpInst::ICMP_UGE: v = x >= y; break;
        case CmpInst::ICMP_ULT: v = x < y; break;
        case CmpInst::ICMP_ULE: v = x <= y; break;
        case CmpInst::ICMP_SGT: v = a > b; break;
        case CmpInst::ICMP_SGE: v = a >= b; break;
        case CmpInst::ICMP_SLT: v = a < b; break;
        case CmpInst::ICMP_SLE: v = a <= b; break;
        default: return std::nullopt;
        }
      } else if (auto *S = dyn_cast<SelectInst>(I)) {
        v = (get(S->getCondition()) & 1) ? get(S->getTrueValue()) : get(S->getFalseValue());
      } else if (isa<FreezeInst>(I)) {
        v = get(I->getOperand(0));
      } else {
        return std::nullopt;
      }
      vals[slot[I]] = v & mask(W);
    }
    const uint64_t rv = vals[slot[Root]];
    umin = std::min(umin, rv);
    umax = std::max(umax, rv);
    smin = std::min(smin, sx(rv, RW));
    smax = std::max(smax, sx(rv, RW));
    for (size_t a = 0; a < atoms.size(); ++a) {  // next combination
      if (++digit[a] < size[a]) break;
      digit[a] = 0;
    }
    if ((steps += order.size() / 64 + 1) > kMaxSteps * 4) {
      aborted = true;
      why = "enumeration budget";
      return std::nullopt;
    }
  }
  enumOk++;
  ConstantRange U = ConstantRange::getNonEmpty(APInt(RW, umin), APInt(RW, umax) + 1);
  ConstantRange S = ConstantRange::getNonEmpty(APInt(RW, (uint64_t)smin, true), APInt(RW, (uint64_t)smax, true) + 1);
  return U.intersectWith(S);
}

ConstantRange RangeEval::transfer(Instruction *I, const Ctx &r, unsigned W) {
  auto op = [&](unsigned i) { return eval(I->getOperand(i), r); };
  if (auto *P = dyn_cast<PHINode>(I)) {
    if (!r.empty() && r.back().first->getHeader() == P->getParent()) {
      const auto &ph = headerPhis(r.back().first);
      for (size_t k = 0; k < ph.size(); ++k)
        if (ph[k] == P) return r.back().second->v[k];
      return full(W);
    }
    ConstantRange R = ConstantRange::getEmpty(W);
    for (Value *In : P->incoming_values()) {
      R = R.unionWith(eval(In, r));
      if (R.isFullSet()) break;
    }
    return R;
  }
  if (auto *B = dyn_cast<BinaryOperator>(I)) {
    ConstantRange A = op(0), C = op(1);
    switch (B->getOpcode()) {
    case Instruction::Add: return A.add(C);
    case Instruction::Sub: return A.sub(C);
    case Instruction::Mul: return A.multiply(C);
    case Instruction::Shl: return shiftOk(C, W) ? A.shl(C) : full(W);
    case Instruction::LShr: return shiftOk(C, W) ? A.lshr(C) : full(W);
    case Instruction::AShr: return shiftOk(C, W) ? A.ashr(C) : full(W);
    case Instruction::UDiv: return noZero(C) ? A.udiv(C) : full(W);
    case Instruction::URem: return noZero(C) ? A.urem(C) : full(W);
    case Instruction::SDiv: return noZero(C) ? A.sdiv(C) : full(W);
    case Instruction::SRem: return noZero(C) ? A.srem(C) : full(W);
    case Instruction::And: {
      ConstantRange R = A.binaryAnd(C);
      if (auto Q = andMask(A, C)) R = R.intersectWith(*Q);
      else if (auto Q2 = andMask(C, A)) R = R.intersectWith(*Q2);
      return R;
    }
    case Instruction::Or: return A.binaryOr(C);
    case Instruction::Xor: {
      ConstantRange R = A.binaryXor(C);
      if (auto Q = xorBlock(A, C)) R = R.intersectWith(*Q);
      if (auto Q = xorBlock(C, A)) R = R.intersectWith(*Q);
      return R;
    }
    default: return full(W);
    }
  }
  if (auto *C = dyn_cast<CastInst>(I)) {
    Value *O = C->getOperand(0);
    if (!O->getType()->isIntegerTy()) return full(W);
    switch (C->getOpcode()) {
    case Instruction::ZExt: return eval(O, r).zeroExtend(W);
    case Instruction::SExt: return eval(O, r).signExtend(W);
    case Instruction::Trunc: return eval(O, r).truncate(W);
    case Instruction::BitCast: return eval(O, r);
    default: return full(W);
    }
  }
  if (auto *S = dyn_cast<SelectInst>(I)) {
    if (!S->getCondition()->getType()->isIntegerTy(1)) return full(W);
    ConstantRange c = eval(S->getCondition(), r);
    if (const APInt *k = c.getSingleElement()) return k->isOne() ? eval(S->getTrueValue(), r) : eval(S->getFalseValue(), r);
    return eval(S->getTrueValue(), r).unionWith(eval(S->getFalseValue(), r));
  }
  if (auto *Cm = dyn_cast<ICmpInst>(I)) {
    if (!Cm->getOperand(0)->getType()->isIntegerTy()) return full(W);
    ConstantRange A = op(0), B = op(1);
    if (A.isEmptySet() || B.isEmptySet()) return full(W);
    if (A.icmp(Cm->getPredicate(), B)) return ConstantRange(APInt(1, 1));
    if (A.icmp(Cm->getInversePredicate(), B)) return ConstantRange(APInt(1, 0));
    return full(W);
  }
  if (auto *CB = dyn_cast<CallInst>(I)) {
    Function *Fn = CB->getCalledFunction();
    if (!Fn) return full(W);
    StringRef n = Fn->getName();
    if (n.consume_front("llvm.nvvm.read.ptx.sreg.")) {
      if (n == "tid.x") return range(W, 0, g_shape.x);
      if (n == "tid.y") return range(W, 0, g_shape.y);
      if (n == "tid.z") return range(W, 0, g_shape.z);
      if (n == "ntid.x") return range(W, 1, g_shape.x + 1);
      if (n == "ntid.y") return range(W, 1, g_shape.y + 1);
      if (n == "ntid.z") return range(W, 1, g_shape.z + 1);
      if (n == "laneid") return range(W, 0, 32);
      if (n == "warpsize") return range(W, 32, 33);
      return full(W);
    }
    // a shuffle returns its operand's value in some lane (or its own): the operand's range over all threads
    if (n.starts_with("llvm.nvvm.shfl.sync.") && CB->arg_size() >= 2 && CB->getArgOperand(1)->getType() == CB->getType())
      return eval(CB->getArgOperand(1), r);
    if (n.starts_with("llvm.nvvm.shfl.") && !n.starts_with("llvm.nvvm.shfl.sync.") && CB->arg_size() >= 1 &&
        CB->getArgOperand(0)->getType() == CB->getType())
      return eval(CB->getArgOperand(0), r);
    if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
      switch (II->getIntrinsicID()) {
      case Intrinsic::umin: return op(0).umin(op(1));
      case Intrinsic::umax: return op(0).umax(op(1));
      case Intrinsic::smin: return op(0).smin(op(1));
      case Intrinsic::smax: return op(0).smax(op(1));
      case Intrinsic::ctpop:
      case Intrinsic::ctlz:
      case Intrinsic::cttz: return range(W, 0, W + 1);
      default: break;
      }
    }
    return full(W);
  }
  if (auto *EV = dyn_cast<ExtractValueInst>(I)) {
    if (auto *CB = dyn_cast<CallInst>(EV->getAggregateOperand()))
      if (Function *Fn = CB->getCalledFunction())
        if (Fn->getName().starts_with("llvm.nvvm.shfl.sync.") && EV->getNumIndices() == 1 && EV->getIndices()[0] == 0 &&
            CB->arg_size() >= 2 && CB->getArgOperand(1)->getType() == EV->getType())
          return eval(CB->getArgOperand(1), r);
    return full(W);
  }
  if (isa<FreezeInst>(I)) return op(0);
  return full(W);
}

// ---- pointers into one global: the derived values, their offsets, the use checks ----------------------------------

struct Off {
  ConstantRange r;  // byte offset from the global's start (64 bits)
  bool mixed;       // some incoming of a phi / select is not a pointer into the global
};

class GlobalUses {
public:
  GlobalUses(GlobalVariable *G, Function &F, RangeEval &E) : G(G), F(F), E(E), DL(F.getParent()->getDataLayout()) {}
  // true: proven, *lowest = the lowest touched byte (kNone: nothing touched)
  bool run(uint64_t *lowest, std::string &why);
  uint64_t end() const { return high; }      // highest touched byte + 1, valid when endKnown()
  bool endKnown() const { return highOk; }

private:
  GlobalVariable *G;
  Function &F;
  RangeEval &E;
  const DataLayout &DL;
  llvm::SetVector<const Value *> D;  // values derived from G (pointers, and integers made from them), in discovery order
  std::map<const Value *, std::optional<Off>> offs;
  std::set<const Value *> busy;
  uint64_t low = kNone;
  uint64_t high = 0;
  bool highOk = true;  // every access had a known extent
  std::string err;

  bool inF(const User *U) const {
    if (auto *I = dyn_cast<Instruction>(U)) return I->getFunction() == &F;
    return true;  // constant expressions: their instruction users are filtered
  }
  std::optional<Off> off(Value *V);
  // size: the bytes touched at or above P; 0 = not known (no end for this global)
  bool access(Value *P, const char *what, uint64_t size);
  bool fail(const std::string &w) {
    if (err.empty()) err = w;
    return false;
  }
  bool checkUse(Value *V, User *U);
};

std::optional<Off> GlobalUses::off(Value *V) {
  if (V == G) return Off{ConstantRange(APInt(64, 0)), false};
  auto it = offs.find(V);
  if (it != offs.end()) return it->second;
  if (!busy.insert(V).second) return std::nullopt;  // a cycle through pointer phis: not handled
  std::optional<Off> R;
  auto *Op = dyn_cast<Operator>(V);
  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    if (auto B = off(GEP->getPointerOperand())) {
      const unsigned IW = DL.getIndexTypeSizeInBits(GEP->getPointerOperand()->getType());
      ConstantRange acc = B->r.sextOrTrunc(IW);
      bool ok = true;
      for (auto GTI = gep_type_begin(GEP), GE = gep_type_end(GEP); GTI != GE && ok; ++GTI) {
        Value *Idx = GTI.getOperand();
        if (StructType *ST = GTI.getStructTypeOrNull()) {
          auto *CI = dyn_cast<ConstantInt>(Idx);
          if (!CI) { ok = false; break; }
          acc = acc.add(ConstantRange(APInt(IW, DL.getStructLayout(ST)->getElementOffset(CI->getZExtValue()).getFixedValue())));
        } else {
          if (!Idx->getType()->isIntegerTy()) { ok = false; break; }
          const uint64_t sz = GTI.getSequentialElementStride(DL).getFixedValue();
          ConstantRange ix = E.eval(Idx, {}).sextOrTrunc(IW);
          acc = acc.add(ix.multiply(ConstantRange(APInt(IW, sz))));
        }
      }
      if (ok) R = Off{acc.sextOrTrunc(64), B->mixed};
    }
  } else if (Op && (Op->getOpcode() == Instruction::BitCast || Op->getOpcode() == Instruction::AddrSpaceCast ||
                    Op->getOpcode() == Instruction::PtrToInt || Op->getOpcode() == Instruction::IntToPtr ||
                    Op->getOpcode() == Instruction::Trunc || Op->getOpcode() == Instruction::ZExt ||
                    Op->getOpcode() == Instruction::SExt)) {
    R = off(Op->getOperand(0));
  } else if (Op && (Op->getOpcode() == Instruction::Add || Op->getOpcode() == Instruction::Sub)) {
    Value *A = Op->getOperand(0), *B = Op->getOperand(1);
    const bool dA = D.count(A), dB = D.count(B);
    if (Op->getOpcode() == Instruction::Add && dA != dB) {
      Value *Ad = dA ? A : B, *Pl = dA ? B : A;
      if (auto O = off(Ad)) R = Off{O->r.add(E.eval(Pl, {}).sextOrTrunc(64)), O->mixed};
    } else if (Op->getOpcode() == Instruction::Sub && dA && !dB) {
      if (auto O = off(A)) R = Off{O->r.sub(E.eval(B, {}).sextOrTrunc(64)), O->mixed};
    }
  } else if (isa<PHINode>(V) || isa<SelectInst>(V)) {
    auto *I = cast<Instruction>(V);
    std::vector<Value *> in;
    if (auto *P = dyn_cast<PHINode>(I)) in.assign(P->incoming_values().begin(), P->incoming_values().end());
    else in = {cast<SelectInst>(I)->getTrueValue(), cast<SelectInst>(I)->getFalseValue()};
    ConstantRange acc = ConstantRange::getEmpty(64);
    bool mixed = false, ok = true;
    for (Value *X : in) {
      if (!D.count(X) && X != G) { mixed = true; continue; }  // not a pointer into G (not derived from it)
      auto O = off(X);
      if (!O) { ok = false; break; }
      acc = acc.unionWith(O->r);
      mixed |= O->mixed;
    }
    if (ok && !acc.isEmptySet()) R = Off{acc, mixed};
  } else if (auto *CB = dyn_cast<CallInst>(V)) {
    if (Function *Fn = CB->getCalledFunction())
      if (Fn->getName() == "__cupbop_cvta_to_shared" && CB->arg_size() == 1) R = off(CB->getArgOperand(0));
  }
  busy.erase(V);
  offs[V] = R;
  return R;
}

bool GlobalUses::access(Value *P, const char *what, uint64_t size) {
  auto O = off(P);
  if (debug()) {
    std::string t;
    raw_string_ostream os(t);
    P->printAsOperand(os, false);
    if (O) os << " offset " << O->r << (O->mixed ? " (mixed)" : "");
    else os << " offset ?";
    fprintf(stderr, "[CuPBoP] smem reserve access: %s %s\n", what, os.str().c_str());
  }
  if (!O) return fail(std::string(what) + ": offset not analyzable");
  const ConstantRange &R = O->r;
  if (R.isFullSet() || R.isEmptySet() || R.isSignWrappedSet())
    return fail(std::string(what) + ": offset not bounded");
  const int64_t lo = R.getSignedMin().getSExtValue();
  if (R.getSignedMax().sgt(APInt(64, 1ull << 40))) return fail(std::string(what) + ": offset not bounded");
  low = std::min<uint64_t>(low, lo < 0 ? 0 : (uint64_t)lo);
  if (size) high = std::max<uint64_t>(high, (uint64_t)R.getSignedMax().getSExtValue() + size);
  else highOk = false;
  return true;
}

// the shared-pointer arguments of the runtime helpers that touch memory at or above them
const std::map<std::string, std::vector<unsigned>> &helperArgs() {
  static const std::map<std::string, std::vector<unsigned>> m = {
      {"__cupbop_ldmatrix_m8n8_b16", {0}},  {"__cupbop_stmatrix_m8n8_b16", {0}}, // window address; rows of all lanes
      {"__cupbop_mbar_init", {0}},          {"__cupbop_mbar_arrive", {0}},       {"__cupbop_mbar_arrive_tx", {0}},
      {"__cupbop_mbar_wait_parity", {0}},   {"__cupbop_mbar_test_parity", {0}},  {"__cupbop_mbar_wait_state", {0}},
      {"__cupbop_mbar_test_state", {0}},    {"__cupbop_mbar_arrive_qi", {3}},    {"__cupbop_mbar_arrive_tx_qi", {3}},
      {"__cupbop_tma_load", {0, 2}},        {"__cupbop_tma_load_qi", {4, 6}},    {"__cupbop_tma_store", {1}},
      {"__cupbop_bulk_copy", {0, 1}},
  };
  return m;
}

bool GlobalUses::checkUse(Value *V, User *U) {
  if (auto *CE = dyn_cast<ConstantExpr>(U)) {
    switch (CE->getOpcode()) {
    case Instruction::GetElementPtr:
      if (CE->getOperand(0) != V) return fail("constant GEP index");
      for (unsigned i = 1; i < CE->getNumOperands(); ++i)
        if (CE->getOperand(i) == V) return fail("constant GEP index");
      return true;
    case Instruction::BitCast: case Instruction::AddrSpaceCast: case Instruction::PtrToInt:
    case Instruction::IntToPtr: case Instruction::Trunc: case Instruction::ZExt: case Instruction::SExt:
      return true;
    default: return fail(std::string("constant expression ") + CE->getOpcodeName());
    }
  }
  auto *I = dyn_cast<Instruction>(U);
  if (!I) return fail("non-instruction user");
  if (I->getFunction() != &F) return true;
  if (auto *GEP = dyn_cast<GetElementPtrInst>(I)) {
    for (unsigned i = 1; i < GEP->getNumOperands(); ++i)
      if (GEP->getOperand(i) == V) return fail("address used as a GEP index");
    return true;
  }
  if (isa<TruncInst>(I) && I->getType()->getIntegerBitWidth() < 32) return fail("shared address truncated below 32 bits");
  if (isa<PtrToIntInst>(I) && I->getType()->getIntegerBitWidth() < 32) return fail("shared address truncated below 32 bits");
  if (isa<BitCastInst>(I) || isa<AddrSpaceCastInst>(I) || isa<PtrToIntInst>(I) || isa<IntToPtrInst>(I) ||
      isa<TruncInst>(I) || isa<ZExtInst>(I) || isa<SExtInst>(I))
    return true;
  if (auto *B = dyn_cast<BinaryOperator>(I)) {
    const bool d0 = D.count(B->getOperand(0)), d1 = D.count(B->getOperand(1));
    if (B->getOpcode() == Instruction::Add && d0 != d1) return true;
    if (B->getOpcode() == Instruction::Sub && d0 && !d1) return true;
    return fail(std::string("shared address in `") + B->getOpcodeName() + "`");
  }
  if (isa<PHINode>(I)) return true;
  if (auto *S = dyn_cast<SelectInst>(I)) {
    if (S->getCondition() == V) return fail("address as a select condition");
    return true;
  }
  if (auto *L = dyn_cast<LoadInst>(I)) return access(L->getPointerOperand(), "load", DL.getTypeStoreSize(L->getType()));
  if (auto *S = dyn_cast<StoreInst>(I)) {
    if (S->getValueOperand() == V) return fail("shared address stored to memory");
    return access(S->getPointerOperand(), "store", DL.getTypeStoreSize(S->getValueOperand()->getType()));
  }
  if (auto *A = dyn_cast<AtomicRMWInst>(I)) {
    if (A->getValOperand() == V) return fail("shared address in an atomic value");
    return access(A->getPointerOperand(), "atomicrmw", DL.getTypeStoreSize(A->getValOperand()->getType()));
  }
  if (auto *A = dyn_cast<AtomicCmpXchgInst>(I)) {
    if (A->getCompareOperand() == V || A->getNewValOperand() == V) return fail("shared address in a cmpxchg value");
    return access(A->getPointerOperand(), "cmpxchg", DL.getTypeStoreSize(A->getCompareOperand()->getType()));
  }
  if (auto *Cm = dyn_cast<ICmpInst>(I)) {
    Value *A = Cm->getOperand(0), *B = Cm->getOperand(1);
    if (!(D.count(A) || A == G) || !(D.count(B) || B == G)) return fail("shared address compared with another value");
    auto OA = off(A), OB = off(B);
    if (!OA || !OB || OA->mixed || OB->mixed) return fail("compare of a mixed pointer");
    return true;
  }
  if (auto *CB = dyn_cast<CallInst>(I)) {
    if (CB->getCalledOperand() == V) return fail("called");
    if (CB->isInlineAsm()) return fail("shared address in inline asm");
    Function *Fn = CB->getCalledFunction();
    if (!Fn) return fail("indirect call");
    const std::string n = Fn->getName().str();
    if (n == "__cupbop_cvta_to_shared") return true;  // derived integer, checked through its own uses
    if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
      const Intrinsic::ID id = II->getIntrinsicID();
      if (id == Intrinsic::lifetime_start || id == Intrinsic::lifetime_end) return true;
      if (id == Intrinsic::memcpy || id == Intrinsic::memmove || id == Intrinsic::memset) {
        for (unsigned a = 0; a < 2 && a < CB->arg_size(); ++a)
          if (CB->getArgOperand(a) == V) {
            if (id == Intrinsic::memset && a == 1) return fail("shared address as a memset value");
            uint64_t len = 0;   // constant length, or the largest value of a bounded one
            ConstantRange LR = E.eval(CB->getArgOperand(2), {});
            if (!LR.isFullSet() && !LR.isEmptySet() && !LR.isWrappedSet() && LR.getUnsignedMax().getActiveBits() <= 32)
              len = LR.getUnsignedMax().getZExtValue();
            if (!access(V, "memory intrinsic", len)) return false;
          }
        for (unsigned a = 2; a < CB->arg_size(); ++a)
          if (CB->getArgOperand(a) == V) return fail("shared address as a memory intrinsic length");
        return true;
      }
    }
    auto h = helperArgs().find(n);
    if (h == helperArgs().end()) return fail("shared address passed to `" + n + "`");
    for (unsigned a = 0; a < CB->arg_size(); ++a) {
      if (CB->getArgOperand(a) != V) continue;
      if (std::find(h->second.begin(), h->second.end(), a) == h->second.end())
        return fail("shared address as argument " + std::to_string(a) + " of `" + n + "`");
      if (auto O = off(V); O && O->mixed) return fail("mixed pointer passed to `" + n + "`");
      // the row of ldmatrix / stmatrix, the 64-bit word of an mbarrier; TMA and bulk copies: extent not known here
      const uint64_t ext = n.find("matrix") != std::string::npos ? 16 : n.find("__cupbop_mbar") == 0 ? 8 : 0;
      if (!access(V, n.c_str(), ext)) return false;
    }
    return true;
  }
  return fail(std::string("shared address used by `") + I->getOpcodeName() + "`");
}

bool GlobalUses::run(uint64_t *lowest, std::string &why) {
  // 1. the values derived from G in F (closure over the value-producing users)
  std::vector<Value *> work{G};
  std::set<const Value *> seen{G};
  while (!work.empty()) {
    Value *V = work.back();
    work.pop_back();
    for (User *U : V->users()) {
      if (!inF(U)) continue;
      bool derives = false;
      if (auto *CE = dyn_cast<ConstantExpr>(U)) derives = true;
      else if (auto *I = dyn_cast<Instruction>(U)) {
        if (isa<GetElementPtrInst>(I)) derives = cast<GetElementPtrInst>(I)->getPointerOperand() == V;
        else if (isa<CastInst>(I) || isa<PHINode>(I) || isa<BinaryOperator>(I)) derives = true;
        else if (auto *S = dyn_cast<SelectInst>(I)) derives = S->getCondition() != V;
        else if (auto *CB = dyn_cast<CallInst>(I))
          derives = CB->getCalledFunction() && CB->getCalledFunction()->getName() == "__cupbop_cvta_to_shared";
      }
      if (!derives) continue;
      Value *UV = cast<Value>(U);
      if (UV->getType()->isVoidTy() || !seen.insert(UV).second) continue;
      if (!UV->getType()->isPointerTy() && !UV->getType()->isIntegerTy()) { why = "shared address becomes a non-scalar"; return false; }
      D.insert(UV);
      work.push_back(UV);
    }
  }
  // 2. every use of G and of the derived values
  std::vector<Value *> all{G};
  for (const Value *V : D) all.push_back(const_cast<Value *>(V));
  for (Value *V : all) {
    for (User *U : V->users())
      if (!checkUse(V, U)) { why = err; return false; }
    if (E.aborted) { why = E.why; return false; }
  }
  *lowest = low;
  return true;
}

// The module the analysis reads: a copy of M, canonicalized so that the interval analysis sees through the lifted
// SASS idioms (x - (x & ~31) for x & 31, 64-bit IADD3 carries, LOP3 trees, signed-division-by-2^k rounding). Before
// optimizing: every poison flag and poison metadata is dropped (the optimizer may not use the lifter's or clang's
// claims), the addrspace(3) globals become external 1 GB arrays of the same name (no object-size reasoning), and
// the special registers get their CUDA ranges as !range (threadIdx < 1024, blockDim <= 1024, ...). The copy is
// discarded after the analysis; M is not changed.
std::unique_ptr<Module> canonical_clone(Module *M) {
  std::unique_ptr<Module> C = CloneModule(*M);
  LLVMContext &Cx = C->getContext();
  std::vector<GlobalVariable *> sh;
  for (GlobalVariable &G : C->globals())
    if (G.getType()->getAddressSpace() == 3) sh.push_back(&G);
  for (GlobalVariable *G : sh) {
    auto *N = new GlobalVariable(*C, ArrayType::get(Type::getInt8Ty(Cx), uint64_t(1) << 30), false,
                                 GlobalValue::ExternalLinkage, nullptr, "", nullptr, GlobalValue::NotThreadLocal, 3);
    N->setAlignment(G->getAlign());
    G->replaceAllUsesWith(N);
    N->takeName(G);
    G->eraseFromParent();
  }
  // undef / poison integer and pointer operands -> an opaque call each (the optimizer may not pick a convenient value
  // for them), every load and store volatile (none is deleted: an unused load still touches its address)
  std::map<Type *, FunctionCallee> any;
  auto anyOf = [&](Type *T) {
    auto it = any.find(T);
    if (it != any.end()) return it->second;
    FunctionCallee FC = C->getOrInsertFunction("__cupbop_smemrsv_any." + std::to_string(any.size()), FunctionType::get(T, false));
    return any.emplace(T, FC).first->second;
  };
  for (Function &F : *C)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        if (auto *L = dyn_cast<LoadInst>(&I)) L->setVolatile(true);
        if (auto *S = dyn_cast<StoreInst>(&I)) S->setVolatile(true);
        for (unsigned i = 0; i < I.getNumOperands(); ++i) {
          Value *O = I.getOperand(i);
          if (!isa<UndefValue>(O) || !(O->getType()->isIntegerTy() || O->getType()->isPointerTy())) continue;
          Instruction *At = &I;
          if (auto *P = dyn_cast<PHINode>(&I)) At = P->getIncomingBlock(i)->getTerminator();
          I.setOperand(i, CallInst::Create(anyOf(O->getType()), "", At->getIterator()));
        }
      }
  MDBuilder MDB(Cx);
  for (Function &F : *C)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        I.dropPoisonGeneratingAnnotations();
        auto *CB = dyn_cast<CallInst>(&I);
        if (!CB || !CB->getCalledFunction() || !CB->getType()->isIntegerTy()) continue;
        StringRef n = CB->getCalledFunction()->getName();
        if (!n.consume_front("llvm.nvvm.read.ptx.sreg.")) continue;
        const unsigned W = CB->getType()->getIntegerBitWidth();
        uint64_t lo = 0, hi = 0;
        if (n == "tid.x") hi = g_shape.x;
        else if (n == "tid.y") hi = g_shape.y;
        else if (n == "tid.z") hi = g_shape.z;
        else if (n == "ntid.x") lo = 1, hi = g_shape.x + 1;
        else if (n == "ntid.y") lo = 1, hi = g_shape.y + 1;
        else if (n == "ntid.z") lo = 1, hi = g_shape.z + 1;
        else if (n == "laneid") hi = 32;
        if (hi) CB->setMetadata(LLVMContext::MD_range, MDB.createRange(APInt(W, lo), APInt(W, hi)));
      }
  PassBuilder PB;
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
  if (auto Err = PB.parsePassPipeline(
          MPM, "function(sroa,early-cse,simplifycfg,instcombine<no-verify-fixpoint>,sccp,correlated-propagation,"
              "simplifycfg,instcombine<no-verify-fixpoint>,early-cse,instcombine<no-verify-fixpoint>)")) {
    consumeError(std::move(Err));
    return nullptr;
  }
  MPM.run(*C, MAM);
  return C;
}

// CUPBOP_SMEM_SHRINK: one run per block shape; g_ends gets the ends of the globals proven for that shape
void analyze_shape(Module *Orig, const Shape &sh) {
  g_shape = sh;
  g_hull = true;
  std::unique_ptr<Module> Clone = canonical_clone(Orig);
  if (!Clone) { g_shape = Shape{1024, 1024, 64}; g_hull = false; return; }
  Module *M = Clone.get();
  std::vector<GlobalVariable *> shared;
  for (GlobalVariable &G : M->globals())
    if (G.getType()->getAddressSpace() == 3) shared.push_back(&G);
  std::map<Function *, std::unique_ptr<RangeEval>> evals;
  for (GlobalVariable *G : shared) {
    std::set<Function *> fs;
    std::vector<const User *> w(G->user_begin(), G->user_end());
    std::set<const User *> vis;
    while (!w.empty()) {
      const User *U = w.back();
      w.pop_back();
      if (!vis.insert(U).second) continue;
      if (auto *I = dyn_cast<Instruction>(U)) fs.insert(const_cast<Function *>(I->getFunction()));
      else for (const User *UU : U->users()) w.push_back(UU);
    }
    bool kernels_only = true;
    for (Function *F : fs) kernels_only &= isKernelFunction(M, F);
    if (!kernels_only) continue;
    for (Function *F : fs) {
      auto &E = evals[F];
      if (!E) E = std::make_unique<RangeEval>(*F);
      if (E->aborted) continue;
      GlobalUses GU(G, *F, *E);
      uint64_t low = kNone;
      std::string why;
      if (GU.run(&low, why) && GU.endKnown())
        g_ends[{F->getName().str(), G->getName().str()}].push_back({sh, GU.end()});
    }
  }
  g_shape = Shape{1024, 1024, 64};
  g_hull = false;
}

void analyze_impl(Module *Orig) {
  std::unique_ptr<Module> Clone = canonical_clone(Orig);
  if (!Clone) {
    fprintf(stderr, "[CuPBoP] smem reserve analysis: canonicalization pipeline unavailable; nothing proven\n");
    return;
  }
  Module *M = Clone.get();
  if (const char *dumpf = std::getenv("CUPBOP_SMEM_RESERVE_DUMP")) {
    std::error_code ec;
    raw_fd_ostream os(dumpf, ec);
    if (!ec) M->print(os, nullptr);
  }
  std::vector<GlobalVariable *> shared;
  for (GlobalVariable &G : M->globals())
    if (G.getType()->getAddressSpace() == 3) shared.push_back(&G);
  if (shared.empty()) return;
  std::map<Function *, std::unique_ptr<RangeEval>> evals;
  for (GlobalVariable *G : shared) {
    // the functions using G (through constant expressions too)
    std::set<Function *> fs;
    std::vector<const User *> w(G->user_begin(), G->user_end());
    std::set<const User *> vis;
    while (!w.empty()) {
      const User *U = w.back();
      w.pop_back();
      if (!vis.insert(U).second) continue;
      if (auto *I = dyn_cast<Instruction>(U)) fs.insert(const_cast<Function *>(I->getFunction()));
      else for (const User *UU : U->users()) w.push_back(UU);
    }
    bool kernels_only = true;
    for (Function *F : fs) kernels_only &= isKernelFunction(M, F);
    for (Function *F : fs) {
      const auto key = std::make_pair(F->getName().str(), G->getName().str());
      if (!kernels_only) { g_why[key] = "also used outside kernel functions"; continue; }
      auto &E = evals[F];
      if (!E) E = std::make_unique<RangeEval>(*F);
      if (E->aborted) { g_why[key] = E->why; continue; }
      if (const char *tn = std::getenv("CUPBOP_SMEM_RESERVE_TRACE"))
        for (BasicBlock &BB : *F)
          for (Instruction &I : BB)
            if (I.getName() == tn) {
              std::set<Value *> seen;
              E->trace(&I, 12, seen);
            }
      GlobalUses GU(G, *F, *E);
      uint64_t low = kNone;
      std::string why;
      if (GU.run(&low, why)) g_lowest[key] = low;
      else g_why[key] = why;
    }
  }
  for (auto &[F, E] : evals)
    fprintf(stderr, "[CuPBoP] smem reserve analysis: %s: %llu evaluations, %llu loop fixpoints, %llu widened phis, "
                    "%llu/%llu slices enumerated%s\n",
            shortName(F->getName().str()).c_str(), (unsigned long long)E->steps, (unsigned long long)E->loops,
            (unsigned long long)E->widened, (unsigned long long)E->enumOk, (unsigned long long)E->enums,
            E->aborted ? " (aborted)" : "");
  for (auto &[k, v] : g_lowest)
    fprintf(stderr, "[CuPBoP] smem reserve analysis: %s: @%s lowest touched byte %s\n", shortName(k.first).c_str(),
            k.second.c_str(), v == kNone ? "none" : std::to_string(v).c_str());
  for (auto &[k, v] : g_why)
    fprintf(stderr, "[CuPBoP] smem reserve analysis: %s: @%s not proven (%s)\n", shortName(k.first).c_str(), k.second.c_str(),
            v.c_str());
}

void *analyze_thread(void *p) {
  analyze_impl(static_cast<Module *>(p));
  if (smem_shrink_enabled())
    for (const Shape &sh : kShapes) analyze_shape(static_cast<Module *>(p), sh);
  return nullptr;
}

} // namespace

void analyze_smem_reserve(Module *M) {
  std::remove("kernel_lmem_hi.log");   // a stale table from an earlier translation in this directory
  if (!smem_reserve_drop_enabled()) return;
  // deep def-use chains of lifted kernels: the recursive evaluation runs on a thread with a 1 GB stack
  pthread_attr_t a;
  pthread_attr_init(&a);
  pthread_attr_setstacksize(&a, size_t(1) << 30);
  pthread_t t;
  if (pthread_create(&t, &a, analyze_thread, M) == 0) pthread_join(t, nullptr);
  else analyze_thread(M);
  pthread_attr_destroy(&a);
}

uint32_t smem_reserve_drop_for(Function &F, const std::vector<std::pair<GlobalVariable *, uint32_t>> &statics,
                               const std::vector<GlobalVariable *> &dynamics, uint32_t staticAligned) {
  if (!smem_reserve_drop_enabled()) return 0;
  uint64_t lowest = staticAligned;
  auto look = [&](GlobalVariable *G, uint64_t at) -> bool {
    auto it = g_lowest.find({F.getName().str(), G->getName().str()});
    if (it == g_lowest.end()) {
      auto w = g_why.find({F.getName().str(), G->getName().str()});
      fprintf(stderr, "[CuPBoP] smem reserve: %s: layout kept (@%s: %s)\n", shortName(F.getName().str()).c_str(),
              G->getName().str().c_str(), w == g_why.end() ? "not analyzed" : w->second.c_str());
      return false;
    }
    if (it->second != kNone) lowest = std::min<uint64_t>(lowest, at + it->second);
    return true;
  };
  for (auto &[G, o] : statics)
    if (!look(G, o)) return 0;
  for (GlobalVariable *G : dynamics)
    if (!look(G, staticAligned)) return 0;
  const uint32_t drop = (uint32_t)(lowest & ~uint64_t(63));
  fprintf(stderr, "[CuPBoP] smem reserve: %s: %u of %u static shared bytes dropped (lowest touched byte %llu)\n",
          shortName(F.getName().str()).c_str(), drop, staticAligned, (unsigned long long)lowest);
  return drop;
}

// CUPBOP_SMEM_SHRINK: F's lines of kernel_lmem_hi.log: for each block shape where every global of the CTA area has a
// proven end, the CTA bytes the kernel can touch (above the dropped prefix), rounded up to 64. A kernel with a used
// dynamic marker gets none (its size is the launch's). Nothing when the switch is off.
void smem_shrink_log(Function &F, const std::vector<std::pair<GlobalVariable *, uint32_t>> &statics,
                     const std::vector<GlobalVariable *> &dynamics, uint32_t drop) {
  if (!smem_shrink_enabled() || !dynamics.empty() || statics.empty()) return;
  static std::ofstream log("kernel_lmem_hi.log");
  for (const Shape &sh : kShapes) {
    uint64_t need = 0;
    bool ok = true;
    for (auto &[G, o] : statics) {
      auto it = g_ends.find({F.getName().str(), G->getName().str()});
      const ShapeEnd *e = nullptr;
      if (it != g_ends.end())
        for (auto &x : it->second)
          if (x.s.x == sh.x && x.s.y == sh.y && x.s.z == sh.z) e = &x;
      if (!e) { ok = false; break; }
      if (e->end) need = std::max<uint64_t>(need, o + e->end);
    }
    if (!ok) continue;
    need = need > drop ? need - drop : 0;
    need = (need + 63) & ~uint64_t(63);
    log << F.getName().str() << " " << sh.x << " " << sh.y << " " << sh.z << " " << need << "\n";
    log.flush();
    fprintf(stderr, "[CuPBoP] smem shrink: %s: block <= %ux%ux%u touches %llu CTA bytes\n", shortName(F.getName().str()).c_str(),
            sh.x, sh.y, sh.z, (unsigned long long)need);
  }
}
