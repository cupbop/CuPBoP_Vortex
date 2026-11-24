// The direct DXA form of an elected TMA pipeline (CUPBOP_TMA_DIRECT=1, default 0; schedule 2). async_direct.h has the
// shape, experiments/cpasync README 7-8 the measurements behind it.
//
// Why a pass of its own, before lower_async_ptx. lower_async_ptx lowers one PTX statement at a time, which is right for
// any program: an mbarrier becomes a record in its shared-memory word that every arrive and wait reads back, a predicated
// statement a region under the elected thread's mask, a TMA load an entry of a queue that the warp issues once it is
// converged again. For the pipeline Triton writes for a TensorDescriptor load, all of that is bookkeeping about facts
// the translator can prove: which Vortex barrier, which thread, how many arrivals. A native Vortex kernel has none of
// it: the CTA's first warp issues the DXA transfer on a barrier whose number is a constant, and every warp waits on that
// barrier. On the G2 main build the Triton matmul loses 16-25% to the difference.
//
// What is checked, per kernel, before anything changes (all or nothing):
//  - every asm of the kernel that mentions mbarrier or cp.async is one of the five statements of async_direct.h, and the
//    kernel has no mbarrier / cp.async intrinsic, named barrier or DXA call of its own;
//  - the block is 1-D with a known size (nvvm.reqntid);
//  - each mbarrier is an 8-byte word of one shared variable: the inits at constant offsets with count 1 (a word may be
//    initialized more than once); the other statements at one of those words, or at word [an index that is the same in
//    every thread] counted from one of them;
//  - the predicate of an arrive and of a load is (one thread of the block) and (a condition that is the same in every
//    thread of the CTA);
//  - a load's tensor map is a kernel parameter, and its destination and coordinates are the same in every thread;
//  - every load and wait is in a block that every thread of the CTA executes the same number of times.
// "The same in every thread" comes from a divergence analysis that starts at the thread id (Divergence below).
//
// Why the rewrite keeps the meaning. With count 1, a phase of the mbarrier completes when the one arrive.expect_tx has
// run and its transfers have landed. The Vortex barrier completes when every warp of the CTA has arrived at the wait and
// the transfers registered on it have landed; the first warp registers a transfer when it issues it, which is before it
// arrives. So a wait returns no earlier than the PTX one, and every warp passes the same waits in the same order,
// because the control flow around them is uniform. The parity operand is not needed: a warp waits for the phase it
// arrived in. For the same reason a second mbarrier.init of a word needs nothing: it restarts the PTX phase count, which
// the barrier does not keep.
#include "async_direct.h"
#include "launch_fix.h"
#include "tool.h"

#include "llvm/ADT/MapVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/Regex.h"
#include "llvm/Transforms/Utils/Local.h"

#include <cstdio>
#include <cstdlib>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <vector>

using namespace llvm;

namespace {

bool enabled() {
  const char *e = std::getenv("CUPBOP_TMA_DIRECT");
  return e && std::atoi(e) != 0;
}

// runs of white space -> one space, none at the ends: Triton's asm templates differ in line breaks and tabs only
std::string squeeze(StringRef s) {
  std::string o;
  bool gap = false;
  for (char c : s) {
    if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
      gap = !o.empty();
      continue;
    }
    if (gap) o.push_back(' ');
    gap = false;
    o.push_back(c);
  }
  return o;
}

enum Kind { Init, Arrive, Load, Wait, Inval };

struct Site {
  CallInst *C = nullptr;
  Kind kind = Init;
  Value *pred = nullptr; // the @$k predicate; null: none
  Value *mbar = nullptr;
  uint64_t count = 0;    // Init
  unsigned rank = 0;     // Load
  Value *smem = nullptr, *desc = nullptr;
  std::vector<Value *> coords;
  // from the checks
  unsigned word = 0;         // the mbarrier word, counted from the kernel's first one
  Value *index = nullptr;    // plus this many words
  std::vector<Value *> when; // Arrive, Load: the part of the predicate every thread agrees on
};

// 1: one of the five statements (S filled); 0: an asm without mbarrier / cp.async; -1: one of another form
int match(CallInst *C, Site &S) {
  const std::string a = squeeze(cast<InlineAsm>(C->getCalledOperand())->getAsmString());
  if (a.find("mbarrier") == std::string::npos && a.find("cp.async") == std::string::npos) return 0;
  static const std::string P = "^(@\\$([0-9]+) )?", MB = "\\.shared(::cta)?\\.b64 ", ID = "([A-Za-z_][A-Za-z_0-9]*)";
  static const Regex init(P + "mbarrier\\.init" + MB + "\\[\\$([0-9]+)\\], ([0-9]+);?$");
  static const Regex arrive(P + "mbarrier\\.arrive\\.expect_tx" + MB + "_, \\[\\$([0-9]+)\\], (\\$[0-9]+|[0-9]+);?$");
  static const Regex inval(P + "mbarrier\\.inval" + MB + "\\[\\$([0-9]+)\\];?$");
  static const Regex load(P + "cp\\.async\\.bulk\\.tensor\\.([1-5])d\\.shared::cta\\.global\\.mbarrier::complete_tx::bytes "
                              "\\[\\$([0-9]+)\\], \\[\\$([0-9]+), \\{([$0-9, ]+)\\}\\], \\[\\$([0-9]+)\\];?$");
  static const Regex wait("^\\{ \\.reg \\.pred " + ID + "; " + ID + ": mbarrier\\.try_wait\\.parity" + MB + ID +
                          ", \\[\\$([0-9]+)\\], (\\$[0-9]+|[0-9]+); @!" + ID + " bra\\.uni " + ID + "; \\}$");
  auto arg = [&](StringRef digits) -> Value * {
    unsigned k;
    if (digits.getAsInteger(10, k) || k >= C->arg_size()) return nullptr;
    return C->getArgOperand(k);
  };
  SmallVector<StringRef, 10> m;
  auto pred = [&]() {
    S.pred = m[1].empty() ? nullptr : arg(m[2]);
    return m[1].empty() || (S.pred && S.pred->getType()->isIntegerTy(1));
  };
  auto pointer = [](Value *V) { return V && V->getType()->isPointerTy(); };
  S.C = C;
  if (init.match(a, &m)) {
    S.kind = Init;
    S.mbar = arg(m[4]);
    return pred() && pointer(S.mbar) && !m[5].getAsInteger(10, S.count) ? 1 : -1;
  }
  if (arrive.match(a, &m)) {
    S.kind = Arrive;
    S.mbar = arg(m[4]);
    return pred() && pointer(S.mbar) ? 1 : -1;
  }
  if (inval.match(a, &m)) {
    S.kind = Inval;
    S.mbar = arg(m[4]);
    return pred() && pointer(S.mbar) ? 1 : -1;
  }
  if (load.match(a, &m)) {
    S.kind = Load;
    S.rank = m[3][0] - '0';
    S.smem = arg(m[4]);
    S.desc = arg(m[5]);
    S.mbar = arg(m[7]);
    SmallVector<StringRef, 5> cs;
    m[6].split(cs, ',');
    for (StringRef c : cs) {
      c = c.trim();
      Value *v = c.consume_front("$") ? arg(c) : nullptr;
      if (!v || !v->getType()->isIntegerTy(32)) return -1;
      S.coords.push_back(v);
    }
    return pred() && pointer(S.smem) && pointer(S.desc) && pointer(S.mbar) && S.coords.size() == S.rank ? 1 : -1;
  }
  if (wait.match(a, &m)) {
    if (m[1] != m[4] || m[1] != m[7] || m[2] != m[8]) return -1; // one predicate register, one label
    S.kind = Wait;
    S.mbar = arg(m[5]);
    return pointer(S.mbar) ? 1 : -1;
  }
  return -1;
}

// ---- which values, and which blocks, are the same for every thread of a CTA
//
// D: the values that can differ between two threads of one CTA at the same point of the program. The least set that
// holds the sources (what is read from memory, the result of a call other than a block-level register or a pure
// intrinsic, a phi that merges branches, everything in a loop the threads can leave at different iterations) and what is
// computed from them. Kernel arguments, constants and the block's own coordinates are outside it, and so is a loop
// counter of a loop every thread leaves together.
// DB: the blocks some threads can execute more often than others: those control dependent, directly or through other
// branches, on a branch whose condition is in D.
struct Divergence {
  Function &F;
  DominatorTree DT;
  LoopInfo LI;
  PostDominatorTree PDT;
  std::set<const Value *> D;
  std::set<const BasicBlock *> DB;

  explicit Divergence(Function &f) : F(f), DT(f), LI(DT), PDT(f) {
    values();
    blocks();
  }
  bool uniform(const Value *V) const {
    return (isa<Constant>(V) || isa<Argument>(V) || isa<Instruction>(V)) && !D.count(V);
  }
  bool source(const Instruction &I) const {
    if (isa<PHINode>(I)) {
      const Loop *L = LI.getLoopFor(I.getParent());
      return !L || L->getHeader() != I.getParent();
    }
    if (auto *C = dyn_cast<CallBase>(&I)) {
      const Function *G = C->getCalledFunction();
      if (!G) return true; // inline asm, indirect calls
      StringRef n = G->getName();
      if (n.starts_with("llvm.nvvm.read.ptx.sreg.ctaid.") || n.starts_with("llvm.nvvm.read.ptx.sreg.nctaid.") ||
          n.starts_with("llvm.nvvm.read.ptx.sreg.ntid."))
        return false;
      return !(G->isIntrinsic() && !n.starts_with("llvm.nvvm.") && G->doesNotAccessMemory());
    }
    return isa<AllocaInst>(I) || I.mayReadOrWriteMemory();
  }
  bool divergentTerminator(const BasicBlock &B) const {
    const Instruction *T = B.getTerminator();
    if (auto *Br = dyn_cast<BranchInst>(T)) return Br->isConditional() && !uniform(Br->getCondition());
    if (auto *Sw = dyn_cast<SwitchInst>(T)) return !uniform(Sw->getCondition());
    return T->getNumSuccessors() > 1;
  }
  bool divergentLoop(const Loop *L) const {
    SmallVector<BasicBlock *, 4> exiting;
    L->getExitingBlocks(exiting);
    for (BasicBlock *B : exiting)
      if (divergentTerminator(*B)) return true;
    return false;
  }
  void values() {
    for (bool changed = true; changed;) {
      changed = false;
      for (BasicBlock &B : F)
        for (Instruction &I : B) {
          if (D.count(&I)) continue;
          bool d = source(I);
          for (const Use &U : I.operands()) d = d || D.count(U.get());
          for (const Loop *L = LI.getLoopFor(&B); L && !d; L = L->getParentLoop()) d = divergentLoop(L);
          if (d) {
            D.insert(&I);
            changed = true;
          }
        }
    }
  }
  void blocks() {
    std::vector<const BasicBlock *> work;
    // the blocks control dependent on X's terminator: from each successor up the post-dominator tree, as far as X's
    // own post-dominator
    auto controlled = [&](const BasicBlock *X) {
      const DomTreeNode *XN = PDT.getNode(X);
      const BasicBlock *stop = XN && XN->getIDom() ? XN->getIDom()->getBlock() : nullptr;
      for (const BasicBlock *S : successors(X))
        for (const BasicBlock *R = S; R && R != stop;) {
          if (DB.insert(R).second) work.push_back(R);
          const DomTreeNode *N = PDT.getNode(R);
          R = N && N->getIDom() ? N->getIDom()->getBlock() : nullptr;
        }
    };
    for (const BasicBlock &B : F)
      if (divergentTerminator(B)) controlled(&B);
    while (!work.empty()) {
      const BasicBlock *X = work.back();
      work.pop_back();
      if (X->getTerminator()->getNumSuccessors() > 1) controlled(X);
    }
  }

  // V in thread t of a 1-D block, when it follows from the thread id alone. The lane is t % 32, and elect.sync of a whole
  // warp, executed by the whole warp, elects its lowest lane (PTX: the lowest numbered active thread of membermask).
  std::optional<APInt> at(const Value *V, unsigned t, unsigned depth = 0) const {
    if (depth > 32 || !V->getType()->isIntegerTy()) return std::nullopt;
    const unsigned bits = V->getType()->getIntegerBitWidth();
    if (auto *K = dyn_cast<ConstantInt>(V)) return K->getValue();
    auto *I = dyn_cast<Instruction>(V);
    if (!I) return std::nullopt;
    auto of = [&](unsigned i) { return at(I->getOperand(i), t, depth + 1); };
    if (auto *C = dyn_cast<CallInst>(I)) {
      const Function *G = C->getCalledFunction();
      StringRef n = G ? G->getName() : "";
      if (n == "llvm.nvvm.read.ptx.sreg.tid.x") return APInt(bits, t);
      if (n == "llvm.nvvm.read.ptx.sreg.tid.y" || n == "llvm.nvvm.read.ptx.sreg.tid.z") return APInt(bits, 0);
      if (n == "llvm.nvvm.read.ptx.sreg.laneid") return APInt(bits, t % 32);
      return std::nullopt;
    }
    if (auto *E = dyn_cast<ExtractValueInst>(I)) {
      auto *C = dyn_cast<CallInst>(E->getAggregateOperand());
      const Function *G = C ? C->getCalledFunction() : nullptr;
      if (!G || G->getName() != "llvm.nvvm.elect.sync" || E->getNumIndices() != 1 || E->getIndices()[0] != 1 ||
          DB.count(C->getParent()))
        return std::nullopt;
      auto *M = dyn_cast<ConstantInt>(C->getArgOperand(0));
      if (!M || (M->getZExtValue() & 0xFFFFFFFFull) != 0xFFFFFFFFull) return std::nullopt;
      return APInt(1, t % 32 == 0 ? 1 : 0);
    }
    if (auto *Cst = dyn_cast<CastInst>(I)) {
      auto a = of(0);
      if (!a) return std::nullopt;
      switch (Cst->getOpcode()) {
      case Instruction::ZExt: return a->zext(bits);
      case Instruction::SExt: return a->sext(bits);
      case Instruction::Trunc: return a->trunc(bits);
      default: return std::nullopt;
      }
    }
    if (isa<SelectInst>(I)) {
      auto c = of(0);
      if (!c) return std::nullopt;
      return c->isZero() ? of(2) : of(1);
    }
    if (auto *Cmp = dyn_cast<ICmpInst>(I)) {
      auto a = of(0), b = of(1);
      if (!a || !b) return std::nullopt;
      return APInt(1, ICmpInst::compare(*a, *b, Cmp->getPredicate()) ? 1 : 0);
    }
    if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      auto a = of(0), b = of(1);
      if (!a || !b) return std::nullopt;
      const APInt &x = *a, &y = *b;
      switch (BO->getOpcode()) {
      case Instruction::And: return x & y;
      case Instruction::Or: return x | y;
      case Instruction::Xor: return x ^ y;
      case Instruction::Add: return x + y;
      case Instruction::Sub: return x - y;
      case Instruction::Mul: return x * y;
      case Instruction::Shl: return y.uge(bits) ? std::nullopt : std::optional<APInt>(x.shl(y));
      case Instruction::LShr: return y.uge(bits) ? std::nullopt : std::optional<APInt>(x.lshr(y));
      case Instruction::AShr: return y.uge(bits) ? std::nullopt : std::optional<APInt>(x.ashr(y));
      case Instruction::UDiv: return y.isZero() ? std::nullopt : std::optional<APInt>(x.udiv(y));
      case Instruction::URem: return y.isZero() ? std::nullopt : std::optional<APInt>(x.urem(y));
      default: return std::nullopt;
      }
    }
    return std::nullopt;
  }

  // pred = (exactly one thread of the block) and (the conjunction of `when`); why, when it is not of that form
  bool oneThread(Value *pred, unsigned threads, std::vector<Value *> &when, std::string &why) const {
    std::vector<Value *> terms, mine;
    std::vector<Value *> stack{pred};
    while (!stack.empty()) {
      Value *V = stack.back();
      stack.pop_back();
      auto *BO = dyn_cast<BinaryOperator>(V);
      auto *Sel = dyn_cast<SelectInst>(V);
      auto *No = Sel ? dyn_cast<ConstantInt>(Sel->getFalseValue()) : nullptr;
      if (BO && BO->getOpcode() == Instruction::And) {
        stack.push_back(BO->getOperand(1));
        stack.push_back(BO->getOperand(0));
      } else if (No && No->isZero()) { // select c, x, false: the and that does not evaluate x's poison
        stack.push_back(Sel->getTrueValue());
        stack.push_back(Sel->getCondition());
      } else {
        terms.push_back(V);
      }
    }
    for (Value *T : terms) (uniform(T) ? when : mine).push_back(T);
    if (mine.empty()) {
      why = "a predicate that names no thread";
      return false;
    }
    unsigned holds = 0;
    for (unsigned t = 0; t < threads; ++t) {
      bool all = true;
      for (Value *T : mine) {
        auto v = at(T, t);
        if (!v) {
          why = "a predicate term that is neither the same in every thread nor a function of the thread id";
          return false;
        }
        all = all && !v->isZero();
      }
      holds += all;
    }
    if (holds != 1) {
      why = "a predicate that holds in " + std::to_string(holds) + " threads of the block";
      return false;
    }
    return true;
  }
};

// an mbarrier address: variable + constant offset [+ 8 * index]
struct Ref {
  GlobalVariable *G = nullptr;
  int64_t off = 0;
  Value *index = nullptr;
};
std::optional<Ref> refOf(Value *P, const DataLayout &DL) {
  const unsigned bits = DL.getIndexTypeSizeInBits(P->getType());
  APInt off(bits, 0);
  SmallMapVector<Value *, APInt, 4> var;
  Ref r;
  for (int guard = 0; guard < 16 && !r.G; ++guard) {
    P = P->stripPointerCasts();
    if ((r.G = dyn_cast<GlobalVariable>(P))) break;
    auto *GEP = dyn_cast<GEPOperator>(P);
    if (!GEP || DL.getIndexTypeSizeInBits(GEP->getType()) != bits || !GEP->collectOffset(DL, bits, var, off))
      return std::nullopt;
    P = GEP->getPointerOperand();
  }
  if (!r.G || r.G->getAddressSpace() != 3 || var.size() > 1) return std::nullopt;
  if (var.size() == 1) {
    if (var.begin()->second != 8) return std::nullopt;
    r.index = var.begin()->first;
  }
  r.off = off.getSExtValue();
  return r;
}

unsigned blockThreads(const Function &F) { // a 1-D block's size, 0 when unknown
  Attribute R = F.getFnAttribute("nvvm.reqntid");
  if (!R.isStringAttribute()) return 0;
  SmallVector<StringRef, 3> dims;
  R.getValueAsString().split(dims, ',');
  unsigned n = 0;
  if (dims.empty() || dims[0].trim().getAsInteger(10, n)) return 0;
  for (size_t i = 1; i < dims.size(); ++i) {
    unsigned d = 0;
    if (dims[i].trim().getAsInteger(10, d) || d != 1) return 0;
  }
  return n <= 1024 ? n : 0;
}

// true: F rewritten (done says what); false with why: F has the statements but not the shape; false without: nothing to do
bool rewrite(Module *M, Function &F, std::string &why, std::string &done) {
#ifdef VX_CFG_NUM_BARRIERS
  const unsigned numBarriers = VX_CFG_NUM_BARRIERS;
#else
  const unsigned numBarriers = 8;
#endif
  const DataLayout &DL = M->getDataLayout();
  std::vector<Site> sites;
  std::string other;
  bool tmaElsewhere = false; // a TMA load in a form the pass does not take: worth a line in the log
  for (BasicBlock &BB : F)
    for (Instruction &I : BB) {
      auto *C = dyn_cast<CallInst>(&I);
      if (!C) continue;
      if (C->isInlineAsm()) {
        Site S;
        const int r = match(C, S);
        const std::string a = squeeze(cast<InlineAsm>(C->getCalledOperand())->getAsmString());
        if (r > 0) {
          sites.push_back(S);
        } else if (r < 0) {
          if (other.empty()) other = "an async statement of another form: " + a.substr(0, 96);
          if (a.find("cp.async.bulk.tensor") != std::string::npos) tmaElsewhere = true;
        } else if (other.empty() && (a.find("bar.") != std::string::npos || a.find("barrier.") != std::string::npos)) {
          other = "a named barrier";
        }
        continue;
      }
      const Function *G = C->getCalledFunction();
      if (!G) continue;
      StringRef n = G->getName();
      if (n.starts_with("llvm.nvvm.cp.async.bulk.tensor")) tmaElsewhere = true;
      if (!other.empty()) continue;
      if (n.starts_with("llvm.nvvm.mbarrier") || n.starts_with("llvm.nvvm.cp.async")) other = "an mbarrier / cp.async intrinsic";
      if (n.starts_with("llvm.nvvm.barrier") && C->arg_size() >= 1) {
        auto *K = dyn_cast<ConstantInt>(C->getArgOperand(0));
        if (!K || !K->isZero()) other = "a named barrier";
      }
      if (n == "_Z19__vx_dxa_barrier_idj" || n.starts_with("_Z17__vx_dxa_issue_") || n.starts_with("__vx_dxa_issue_") ||
          n == "__cupbop_bar_sync" || n == "__cupbop_bar_arrive")
        other = "DXA or named-barrier calls of its own";
    }
  unsigned count[5] = {0, 0, 0, 0, 0};
  for (const Site &S : sites) count[S.kind]++;
  if (!count[Load] && !tmaElsewhere) return false; // no TMA load: not this pass's business
  auto no = [&](const std::string &w) {
    why = w;
    return false;
  };
  if (!other.empty()) return no(other);
  if (!isKernelFunction(M, &F)) return no("the statements are in a function that is not a kernel");
  const unsigned threads = blockThreads(F);
  if (!threads) return no("no 1-D block size (nvvm.reqntid)");

  // the mbarrier words
  std::vector<Ref> refs;
  for (Site &S : sites) {
    auto r = refOf(S.mbar, DL);
    if (!r) return no("an mbarrier address that is not variable + offset [+ 8 * index]");
    if (!refs.empty() && refs[0].G != r->G) return no("mbarriers in more than one shared variable");
    refs.push_back(*r);
  }
  std::set<int64_t> inits;
  for (size_t i = 0; i < sites.size(); ++i)
    if (sites[i].kind == Init) {
      if (refs[i].index) return no("an mbarrier.init at a computed address");
      if (sites[i].count != 1) return no("an mbarrier.init with count " + std::to_string(sites[i].count));
      inits.insert(refs[i].off); // a word can be initialized again (Triton without a pipeline: init, arrive, load, wait, inval per load)
    }
  if (inits.empty()) return no("no mbarrier.init");
  const unsigned words = inits.size();
  if (words > numBarriers - 1)
    return no(std::to_string(words) + " mbarriers, the CTA has " + std::to_string(numBarriers - 1) + " Vortex barriers for them");
  // Vortex barrier 1 + k for the k-th word in address order: the words need not follow each other (an attention kernel has
  // one mbarrier behind its Q tile and two behind its K / V stages). A statement at word [index] counts from its base
  // word, which is right for words that do follow each other, as the elements of an mbarrier array do.
  std::map<int64_t, unsigned> number;
  for (int64_t o : inits) number.emplace(o, (unsigned)number.size());
  for (size_t i = 0; i < sites.size(); ++i) {
    auto it = number.find(refs[i].off);
    if (it == number.end()) return no("an mbarrier statement on a word without mbarrier.init");
    sites[i].word = it->second;
    sites[i].index = refs[i].index;
  }
  // the last words that follow each other: the tail of the shared memory when the kernel's buffers end before them
  int64_t tail = *inits.rbegin();
  while (inits.count(tail - 8)) tail -= 8;
  const uint64_t tailBytes = (uint64_t)(*inits.rbegin() + 8 - tail);

  // who executes what
  Divergence A(F);
  for (Site &S : sites) {
    if (S.index && !A.uniform(S.index)) return no("an mbarrier index that differs between threads");
    if (S.kind == Arrive || S.kind == Load) {
      if (!S.pred) return no("an arrive or a load without a predicate (every thread would execute it)");
      std::string w;
      if (!A.oneThread(S.pred, threads, S.when, w)) return no((S.kind == Load ? "a load with " : "an arrive with ") + w);
    }
    if (S.kind == Load) {
      auto *Arg = dyn_cast<Argument>(S.desc);
      if (!Arg || !Arg->hasByValAttr()) return no("a tensor map that is not a by-value kernel parameter");
      if (!A.uniform(S.smem)) return no("a load destination that differs between threads");
      for (Value *c : S.coords)
        if (!A.uniform(c)) return no("a load coordinate that differs between threads");
    }
    if ((S.kind == Load || S.kind == Wait) && A.DB.count(S.C->getParent()))
      return no(std::string(S.kind == Load ? "a load" : "a wait") + " under a branch that differs between threads");
  }

  // ---- the rewrite
  LLVMContext &ctx = M->getContext();
  Type *I32 = Type::getInt32Ty(ctx), *Void = Type::getVoidTy(ctx);
  PointerType *Ptr = PointerType::get(ctx, 0);
  FunctionCallee BarId = M->getOrInsertFunction("_Z19__vx_dxa_barrier_idj", FunctionType::get(I32, {I32}, false));
  FunctionCallee WaitFn = M->getOrInsertFunction("_Z13__vx_dxa_waitj", FunctionType::get(Void, {I32}, false));
  FunctionCallee SlotFn = M->getOrInsertFunction("__cupbop_tma_slot", FunctionType::get(I32, {Ptr, I32}, false));
  FunctionCallee Direct = M->getOrInsertFunction(
      "__cupbop_tma_direct", FunctionType::get(Void, {I32, I32, I32, Ptr, Ptr, I32, I32, I32, I32, I32, I32}, false));
  for (FunctionCallee f : {WaitFn, Direct})
    if (auto *Fn = dyn_cast<Function>(f.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  // at the kernel's entry: the packed number of each barrier (it holds the CTA's id) and the DXA slot of each tensor map,
  // so that neither is read again per transfer
  Instruction *IP = &*F.getEntryBlock().getFirstInsertionPt();
  while (isa<AllocaInst>(IP)) IP = IP->getNextNode();
  IRBuilder<> EB(IP);
  std::vector<Value *> bar;
  for (unsigned k = 0; k < words; ++k) bar.push_back(EB.CreateCall(BarId, {EB.getInt32(1 + k)}, "tma.bar"));
  std::map<std::pair<Value *, unsigned>, Value *> slots;
  for (const Site &S : sites)
    if (S.kind == Load) {
      Value *&V = slots[{S.desc, S.rank}];
      if (!V) V = EB.CreateCall(SlotFn, {S.desc, EB.getInt32(S.rank)}, "tma.slot");
    }
  auto barOf = [&](IRBuilder<> &B, const Site &S) -> Value * {
    if (!S.index) return bar[S.word];
    return B.CreateAdd(bar[S.word], B.CreateShl(B.CreateZExtOrTrunc(S.index, I32), 8), "tma.bar.i");
  };
  SmallVector<WeakTrackingVH, 32> operands;
  for (Site &S : sites) {
    IRBuilder<> B(S.C);
    if (S.kind == Load) {
      Value *when = nullptr;
      for (Value *T : S.when) when = when ? B.CreateAnd(when, T, "tma.when") : T;
      Value *smem = S.smem;
      if (smem->getType()->getPointerAddressSpace() != 0) smem = B.CreateAddrSpaceCast(smem, Ptr, "tma.dst");
      std::vector<Value *> args{when ? B.CreateZExt(when, I32) : B.getInt32(1), slots[{S.desc, S.rank}], barOf(B, S), smem,
                                S.desc, B.getInt32(S.rank)};
      for (unsigned i = 0; i < 5; ++i) args.push_back(i < S.coords.size() ? S.coords[i] : B.getInt32(0));
      B.CreateCall(Direct, args)->addFnAttr(Attribute::Convergent);
    } else if (S.kind == Wait) {
      B.CreateCall(WaitFn, {barOf(B, S)})->addFnAttr(Attribute::Convergent);
    }
    for (Value *O : S.C->args())
      if (isa<Instruction>(O)) operands.emplace_back(O);
    S.C->eraseFromParent();
  }
  // what only the statements used: predicates, mbarrier addresses, parities, and the elect.sync behind a predicate
  RecursivelyDeleteTriviallyDeadInstructionsPermissive(operands);
  std::vector<CallInst *> elects;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *C = dyn_cast<CallInst>(&I))
        if (const Function *G = C->getCalledFunction(); G && G->getName() == "llvm.nvvm.elect.sync" && C->use_empty())
          elects.push_back(C);
  for (CallInst *C : elects) C->eraseFromParent();

  const std::string var = refs[0].G->getName().str();
  // The mbarrier words have no access left. When they are the end of the kernel's dynamic shared memory (Triton puts
  // them after its buffers), the launch can leave them out of the CTA's local memory: mbar_off / mbar_bytes
  // (launch_fix.h), which the runtime applies only to a launch whose dynamic size is exactly off + bytes. A CTA area
  // 16 bytes over a power of two costs a whole CTA per core (4 x 4096-byte tiles + 2 mbarriers: 3 CTAs in 64 KB, not 4).
  // The program itself guarantees that nothing else is in those bytes: an mbarrier word is not ordinary memory in PTX.
  // CUPBOP_TMA_DIRECT_SHRINK=0 leaves the launch as it is (measurement).
  bool shrink = false;
  if (auto *AT = dyn_cast<ArrayType>(refs[0].G->getValueType()); AT && AT->getNumElements() == 0 && !refs[0].G->hasInitializer()) {
    const char *e = std::getenv("CUPBOP_TMA_DIRECT_SHRINK");
    if (!e || std::atoi(e) != 0) {
      launch_fix_note(M, F.getName(), "mbar_off", (uint64_t)tail);
      launch_fix_note(M, F.getName(), "mbar_bytes", tailBytes);
      shrink = true;
    }
  }
  done = std::to_string(count[Load]) + " TMA load(s) issue their DXA transfer directly, " + std::to_string(count[Wait]) +
         " wait(s) on Vortex barrier(s) 1.." + std::to_string(words) + "; dropped " + std::to_string(count[Init]) + " init, " +
         std::to_string(count[Arrive]) + " arrive.expect_tx, " + std::to_string(count[Inval]) + " inval, " +
         std::to_string(elects.size()) + " elect.sync; the " + std::to_string(words) + " mbarrier word(s) of " + var +
         " have no access left" +
         (shrink ? ", and a launch that ends its shared memory behind " + var + "+" + std::to_string(tail) + ".." +
                       std::to_string(tail + (int64_t)tailBytes - 1) + " leaves those out"
                 : "");
  return true;
}

} // namespace

void lower_tma_direct(Module *M) {
  if (!enabled()) return;
  const char *sc = std::getenv("VORTEX_SCHEDULE_FLAG");
  if (!sc || std::atoi(sc) != 2) {
    fprintf(stderr, "[CuPBoP] tma direct: schedule %s: only the 1:1 schedule (2), nothing changed\n", sc ? sc : "0");
    return;
  }
  std::vector<Function *> functions;
  for (Function &F : *M)
    if (!F.isDeclaration()) functions.push_back(&F);
  for (Function *F : functions) {
    std::string why, done;
    if (rewrite(M, *F, why, done))
      fprintf(stderr, "[CuPBoP] tma direct: %s: %s\n", F->getName().str().c_str(), done.c_str());
    else if (!why.empty())
      fprintf(stderr, "[CuPBoP] tma direct: %s: left to lower_async_ptx: %s\n", F->getName().str().c_str(), why.c_str());
  }
}
