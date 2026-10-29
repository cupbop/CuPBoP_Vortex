// Hopper / Ampere asynchronous PTX (mbarrier, TMA, bulk copy, elect, cluster registers, proxy fences) lowered
// to CuPBoP internal calls in software mode. See async_ptx.h and 2026-10-28_ASYNC_DESIGN_KO.md (§4-§6).
#include "async_ptx.h"
#include "async_copy.h"
#include "tool.h"

#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Local.h"

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <map>
#include <set>
#include <string>
#include <vector>

using namespace llvm;

namespace {

const char *kInit = "__cupbop_mbar_init", *kArrive = "__cupbop_mbar_arrive", *kArriveTx = "__cupbop_mbar_arrive_tx",
           *kWaitPar = "__cupbop_mbar_wait_parity", *kTestPar = "__cupbop_mbar_test_parity",
           *kWaitSt = "__cupbop_mbar_wait_state", *kTestSt = "__cupbop_mbar_test_state",
           *kElect = "__cupbop_elect_sync", *kElectLane = "__cupbop_elect_lane", *kTmaLoad = "__cupbop_tma_load",
           *kTmaStore = "__cupbop_tma_store", *kBulk = "__cupbop_bulk_copy", *kRankFail = "__cupbop_cluster_rank_fail",
           *kActive = "__cupbop_activemask";
const uint32_t kIdPlaceholder = 0xFFFFFFFFu;

int schedule() {
  const char *e = std::getenv("VORTEX_SCHEDULE_FLAG");
  return e ? std::atoi(e) : 0;
}

std::string str(const Value *V) {
  std::string s;
  raw_string_ostream os(s);
  V->print(os);
  return os.str();
}

[[noreturn]] void fail_at(Instruction *I, const std::string &what) {
  fprintf(stderr, "error: %s\n  at:%s (in %s)\n", what.c_str(), str(I).c_str(),
          I->getFunction()->getName().str().c_str());
  exit(1);
}

std::string trim(const std::string &s) {
  size_t b = s.find_first_not_of(" \t\n\r");
  if (b == std::string::npos) return "";
  size_t e = s.find_last_not_of(" \t\n\r");
  return s.substr(b, e - b + 1);
}

void replaceAll(std::string &s, const std::string &a, const std::string &b) {
  for (size_t p = s.find(a); p != std::string::npos; p = s.find(a, p + b.size())) s.replace(p, a.size(), b);
}

// split at top-level separators (not inside [] {} ())
std::vector<std::string> splitTop(const std::string &s, char sep) {
  std::vector<std::string> out;
  int depth = 0;
  std::string cur;
  for (char c : s) {
    if (c == '[' || c == '{' || c == '(') depth++;
    if (c == ']' || c == '}' || c == ')') depth--;
    if (c == sep && depth == 0) {
      out.push_back(trim(cur));
      cur.clear();
    } else {
      cur += c;
    }
  }
  if (!trim(cur).empty() || !out.empty()) out.push_back(trim(cur));
  return out;
}

std::vector<std::string> splitDots(const std::string &op) {
  std::vector<std::string> t;
  size_t p = 0;
  while (p <= op.size()) {
    size_t q = op.find('.', p);
    t.push_back(op.substr(p, q == std::string::npos ? std::string::npos : q - p));
    if (q == std::string::npos) break;
    p = q + 1;
  }
  return t;
}

struct Stmt {
  std::string label, pred, op, text;
  bool neg = false;
  std::vector<std::string> ops;
  std::vector<std::string> tok; // op split at '.'
  bool has(const std::string &t) const {
    for (auto &x : tok)
      if (x == t) return true;
    return false;
  }
  bool hasPrefix(const std::string &t) const {
    for (auto &x : tok)
      if (x.rfind(t, 0) == 0) return true;
    return false;
  }
};

bool isIdentChar(char c) { return isalnum((unsigned char)c) || c == '_' || c == '$' || c == '%'; }

// PTX inline asm -> statements. { } scopes are dropped (register names are only looked up by name), .reg
// declarations are skipped, `L:` labels and `@p` / `@!p` predicates are kept.
bool parsePtx(const std::string &in, std::vector<Stmt> &out, std::string &err) {
  std::string s = in;
  replaceAll(s, "${:uid}", "UID");
  replaceAll(s, "%=", "UID");
  for (size_t p = s.find("//"); p != std::string::npos; p = s.find("//", p)) {
    size_t e = s.find('\n', p);
    s.erase(p, e == std::string::npos ? std::string::npos : e - p);
  }
  std::vector<std::string> raw;
  std::string cur;
  int depth = 0;
  for (char c : s) {
    if ((c == '{' || c == '}') && depth == 0 && trim(cur).empty()) continue; // a scope brace
    if (c == '{' || c == '[') depth++;
    if (c == '}' || c == ']') depth--;
    if (depth < 0) { err = "unbalanced braces"; return false; }
    if (c == ';' && depth == 0) {
      raw.push_back(trim(cur));
      cur.clear();
      continue;
    }
    cur += c;
  }
  if (!trim(cur).empty()) raw.push_back(trim(cur));
  for (auto &r0 : raw) {
    std::string r = trim(r0);
    if (r.empty()) continue;
    Stmt st;
    st.text = r;
    // label
    size_t i = 0;
    while (i < r.size() && isIdentChar(r[i])) ++i;
    size_t j = i;
    while (j < r.size() && isspace((unsigned char)r[j])) ++j;
    if (i > 0 && j < r.size() && r[j] == ':' && (j + 1 >= r.size() || r[j + 1] != ':')) {
      st.label = r.substr(0, i);
      r = trim(r.substr(j + 1));
      if (r.empty()) { out.push_back(st); continue; }
    }
    if (r[0] == '.') continue; // .reg / .pred declarations
    if (r[0] == '@') {
      size_t k = 1;
      if (k < r.size() && r[k] == '!') { st.neg = true; ++k; }
      size_t b = k;
      while (k < r.size() && isIdentChar(r[k])) ++k;
      st.pred = r.substr(b, k - b);
      r = trim(r.substr(k));
    }
    size_t sp = r.find_first_of(" \t\n");
    st.op = r.substr(0, sp);
    std::string rest = sp == std::string::npos ? "" : trim(r.substr(sp));
    if (!rest.empty()) st.ops = splitTop(rest, ',');
    st.tok = splitDots(st.op);
    out.push_back(st);
  }
  return true;
}

// Is this statement one lower_async_ptx owns?
bool ownedOp(const Stmt &s) {
  const std::string &o = s.op;
  auto sw = [&](const char *p) { return o.rfind(p, 0) == 0; };
  if (sw("mbarrier.") || sw("cp.async.bulk") || sw("cp.reduce.async.bulk") || sw("cp.async.mbarrier.arrive") ||
      sw("elect.sync") || sw("fence.mbarrier_init") || sw("mapa") || sw("barrier.cluster.") ||
      sw("setmaxnreg.") || sw("griddepcontrol.") || sw("prefetch.tensormap") || sw("cvta.param") ||
      sw("multimem.") || sw("tensormap."))
    return true;
  if ((sw("fence.") && o.find(".cluster") != std::string::npos)) return true;
  for (auto &x : s.ops)
    if (x.find("%cluster_") != std::string::npos || x.find("%clusterid") != std::string::npos ||
        x.find("%nclusterid") != std::string::npos || x.find("%is_explicit_cluster") != std::string::npos)
      return true;
  return false;
}

bool mentionsAsyncText(const std::string &s) {
  for (const char *k : {"mbarrier", "cp.async.bulk", "cp.reduce.async.bulk", "elect.sync", "mapa",
                        "barrier.cluster", "%cluster_", "setmaxnreg", "griddepcontrol", "tensormap", "cvta.param"})
    if (s.find(k) != std::string::npos) return true;
  return false;
}

bool isCuLifterFunction(Function *F) {
  for (auto &A : F->args())
    if (A.getName().starts_with("arg_")) return true;
  for (auto &I : F->getEntryBlock())
    if (auto *AI = dyn_cast<AllocaInst>(&I))
      if (AI->getName() == "param_local") return true;
  return false;
}

// ---------------------------------------------------------------------------------------------------------
// pass state

struct PassState {
  Module *M;
  LLVMContext &ctx;
  Type *I1, *I32, *I64, *Void;
  PointerType *Ptr;
  std::map<Function *, std::vector<CallInst *>> arrives; // candidates for the §5.3 move
  std::set<CallInst *> txCopies;                          // copies that complete on an mbarrier
  std::set<Function *> needWarps;                         // functions with ops that need real warps
  std::map<Function *, Value *> txq;                      // per-function DXA issue queue (§5.3 moved arrives)
  std::set<CallInst *> orderedCopies;                     // copies some arrive of the same thread was moved after
  std::set<std::pair<Function *, unsigned>> paramAddrArgs; // kernel parameters whose address cvta.param takes
  unsigned n_asm = 0, n_intr = 0, n_moved = 0;
  explicit PassState(Module *m)
      : M(m), ctx(m->getContext()), I1(Type::getInt1Ty(ctx)), I32(Type::getInt32Ty(ctx)), I64(Type::getInt64Ty(ctx)),
        Void(Type::getVoidTy(ctx)), Ptr(PointerType::get(ctx, 0)) {}
  FunctionCallee fn(const char *name, Type *ret, ArrayRef<Type *> args, bool convergent = true, bool noreturn = false) {
    FunctionCallee f = M->getOrInsertFunction(name, FunctionType::get(ret, args, false));
    if (auto *Fn = dyn_cast<Function>(f.getCallee())) {
      if (convergent) Fn->addFnAttr(Attribute::Convergent);
      if (noreturn) Fn->addFnAttr(Attribute::NoReturn);
    }
    return f;
  }
  CallInst *call(IRBuilder<> &B, const char *name, Type *ret, ArrayRef<Value *> args, bool convergent = true) {
    std::vector<Type *> tys;
    for (auto *a : args) tys.push_back(a->getType());
    CallInst *c = B.CreateCall(fn(name, ret, tys, convergent), args);
    if (convergent) c->addFnAttr(Attribute::Convergent);
    return c;
  }
};

// A pointer (generic address space) for an address operand value.
Value *toPointer(IRBuilder<> &B, PassState &S, Value *V, Instruction *at, const char *what) {
  Value *P = nullptr;
  if (V->getType()->isPointerTy()) P = V;
  else P = cupbop_trace_pointer(V);
  if (P && P->getType()->isPointerTy()) {
    if (P->getType()->getPointerAddressSpace() != 0) P = B.CreateAddrSpaceCast(P, S.Ptr, "async_gen");
    return P;
  }
  if (V->getType()->isIntegerTy(64)) return B.CreateIntToPtr(V, S.Ptr, "async_i2p"); // flat memory
  fail_at(at, std::string("cannot recover the ") + what +
                  " pointer from its 32-bit operand (expected a cvta / ptrtoint of a pointer)");
}

// ---------------------------------------------------------------------------------------------------------
// one inline asm call

struct AsmLowering {
  PassState &S;
  CallInst *C;
  Function *F;
  IRBuilder<> B;
  std::vector<Stmt> st;
  unsigned nout = 0;
  std::vector<Type *> outTy;
  std::vector<Value *> outVal;
  std::map<std::string, Value *> regs;
  std::map<std::string, std::string> paramSym; // register -> <fn>_param_N symbol
  std::set<size_t> blocking;                    // try/test_wait statements spun on by a following @!p bra
  std::set<size_t> consumedBra;

  AsmLowering(PassState &s, CallInst *c) : S(s), C(c), F(c->getFunction()), B(c) {}

  [[noreturn]] void fail(const std::string &what) { fail_at(C, what); }

  bool isOutputRef(const std::string &t, unsigned &k) {
    if (t.size() < 2 || t[0] != '$') return false;
    char *e = nullptr;
    k = std::strtoul(t.c_str() + 1, &e, 10);
    return *e == 0 && k < nout;
  }
  // a value operand
  Value *val(const std::string &t0, Type *want) {
    std::string t = trim(t0);
    Value *v = nullptr;
    if (t.empty()) fail("empty operand");
    if (t[0] == '$') {
      char *e = nullptr;
      unsigned k = std::strtoul(t.c_str() + 1, &e, 10);
      if (*e) fail("bad operand `" + t + "`");
      if (k < nout) {
        if (!outVal[k]) fail("output operand `" + t + "` read before it is written");
        v = outVal[k];
      } else {
        if (k - nout >= C->arg_size()) fail("operand `" + t + "` out of range");
        v = C->getArgOperand(k - nout);
      }
    } else if (t == "%cluster_ctarank" || t.rfind("%cluster_ctaid", 0) == 0 || t == "%is_explicit_cluster") {
      v = ConstantInt::get(S.I32, 0);
    } else if (t == "%cluster_nctarank" || t.rfind("%cluster_nctaid", 0) == 0) {
      v = ConstantInt::get(S.I32, 1);
    } else if (t[0] == '%') {
      fail("special register `" + t + "` in async asm is not supported");
    } else if (isdigit((unsigned char)t[0]) || t[0] == '-') {
      char *e = nullptr;
      long long x = std::strtoll(t.c_str(), &e, 0);
      if (*e && !(e[0] == 'U' && e[1] == 0)) fail("bad integer `" + t + "`");
      v = ConstantInt::get(want && want->isIntegerTy() ? want : S.I64, (uint64_t)x);
    } else {
      auto it = regs.find(t);
      if (it == regs.end()) fail("register `" + t + "` read before it is written");
      v = it->second;
    }
    if (want && v->getType() != want) {
      if (v->getType()->isPointerTy() && want->isIntegerTy()) v = B.CreatePtrToInt(v, want);
      else if (v->getType()->isIntegerTy() && want->isIntegerTy()) v = B.CreateZExtOrTrunc(v, want);
      else fail("operand `" + t + "` has an unexpected type");
    }
    return v;
  }
  // `[x]`, `[x+imm]`, `[x-imm]` -> a generic pointer
  Value *addr(const std::string &t0, const char *what) {
    std::string t = trim(t0);
    if (t.size() < 3 || t.front() != '[' || t.back() != ']') fail(std::string("expected a [address] operand for the ") + what);
    t = trim(t.substr(1, t.size() - 2));
    int64_t off = 0;
    size_t pm = t.find_first_of("+-", 1);
    if (pm != std::string::npos) {
      char *e = nullptr;
      long long o = std::strtoll(trim(t.substr(pm + 1)).c_str(), &e, 0);
      if (*e) fail("bad address offset in `" + t0 + "`");
      off = t[pm] == '+' ? o : -o;
      t = trim(t.substr(0, pm));
    }
    Value *v = val(t, nullptr);
    Value *P = toPointer(B, S, v, C, what);
    if (off) P = B.CreateGEP(Type::getInt8Ty(S.ctx), P, ConstantInt::get(S.I64, off), "async_off");
    return P;
  }
  void setReg(const std::string &d, Value *v, Value *pred) {
    if (d == "_") return;
    unsigned k;
    Value *old = nullptr;
    bool out = isOutputRef(d, k);
    if (out) old = outVal[k];
    else if (regs.count(d)) old = regs[d];
    if (pred) {
      if (auto *K = dyn_cast<ConstantInt>(pred)) {
        if (K->isZero()) return;
      } else if (old && old->getType() == v->getType()) {
        v = B.CreateSelect(pred, v, old);
      }
    }
    if (out) {
      Type *T = outTy[k];
      if (v->getType() != T) {
        if (v->getType()->isIntegerTy() && T->isIntegerTy()) v = B.CreateZExtOrTrunc(v, T);
        else if (v->getType()->isPointerTy() && T->isIntegerTy()) v = B.CreatePtrToInt(v, T);
        else fail("cannot assign to output `" + d + "`");
      }
      outVal[k] = v;
    } else {
      regs[d] = v;
    }
  }
  Value *predOf(const Stmt &s) {
    if (s.pred.empty()) return nullptr;
    auto it = regs.find(s.pred);
    if (it == regs.end()) fail("predicate `" + s.pred + "` used before it is set");
    Value *p = it->second;
    if (!p->getType()->isIntegerTy(1)) p = B.CreateICmpNE(p, ConstantInt::get(p->getType(), 0));
    if (s.neg) {
      if (auto *K = dyn_cast<ConstantInt>(p)) return ConstantInt::get(S.I1, K->isZero() ? 1 : 0);
      p = B.CreateNot(p);
    }
    return p;
  }
  // run body under pred (nullptr / constant: no branch); returns body's value merged with `dflt` by a phi
  Value *underPred(Value *pred, const std::function<Value *()> &body, Value *dflt = nullptr) {
    if (!pred) return body();
    if (auto *K = dyn_cast<ConstantInt>(pred)) return K->isZero() ? dflt : body();
    // everything is emitted in front of the asm call C, which stays at the head of the tail block
    Instruction *thenT = SplitBlockAndInsertIfThen(pred, C->getIterator(), false);
    BasicBlock *head = thenT->getParent()->getSinglePredecessor();
    BasicBlock *tail = C->getParent();
    B.SetInsertPoint(thenT);
    Value *r = body();
    BasicBlock *thenEnd = B.GetInsertBlock();
    B.SetInsertPoint(C);
    if (r && !r->getType()->isVoidTy()) {
      PHINode *phi = PHINode::Create(r->getType(), 2, "async_pred");
      phi->insertBefore(&*tail->begin());
      phi->addIncoming(r, thenEnd);
      phi->addIncoming(dflt && dflt->getType() == r->getType() ? dflt : UndefValue::get(r->getType()), head);
      r = phi;
    }
    return r;
  }
  void needWarps() { S.needWarps.insert(F); }

  void run() {
    auto *IA = cast<InlineAsm>(C->getCalledOperand());
    // outputs
    std::vector<std::string> cons = splitTop(IA->getConstraintString(), ',');
    for (auto &c : cons) {
      if (c.empty()) continue;
      if (c[0] == '=') { if (c.find('&') != std::string::npos || c.find('*') != std::string::npos) fail("unsupported output constraint " + c); ++nout; }
      else if (isdigit((unsigned char)c[0]) || c[0] == '*') fail("tied or indirect asm operand (" + c + ") in async asm");
    }
    if (nout == 1) outTy.push_back(C->getType());
    else if (nout > 1) {
      auto *STy = dyn_cast<StructType>(C->getType());
      if (!STy || STy->getNumElements() != nout) fail("unexpected asm result type");
      for (unsigned i = 0; i < nout; ++i) outTy.push_back(STy->getElementType(i));
    }
    for (Type *T : outTy)
      if (!T->isIntegerTy()) fail("async asm outputs must be integers");
    outVal.assign(nout, nullptr);
    // spin loops: `L: (try|test)_wait p, ...; @!p bra L` is a blocking wait
    for (size_t j = 0; j < st.size(); ++j) {
      if (st[j].op.rfind("bra", 0) != 0) continue;
      if (st[j].ops.size() != 1 || st[j].pred.empty() || !st[j].neg)
        fail("branch in async asm other than a wait loop (`L: mbarrier.try_wait/test_wait p, ...; @!p bra L;`)");
      size_t i = 0;
      for (; i < j; ++i)
        if (st[i].label == st[j].ops[0]) break;
      if (i == j || st[i].op.rfind("mbarrier.", 0) != 0 ||
          (st[i].op.find(".try_wait") == std::string::npos && st[i].op.find(".test_wait") == std::string::npos) ||
          st[i].ops.empty() || st[i].ops[0] != st[j].pred)
        fail("branch in async asm other than a wait loop (`L: mbarrier.try_wait/test_wait p, ...; @!p bra L;`)");
      for (size_t k = i + 1; k < j; ++k)
        if (st[k].op.rfind("mbarrier.", 0) != 0 || st[k].op.find("_wait") == std::string::npos)
          if (!st[k].op.empty()) fail("statements between a wait and its loop branch in async asm");
      blocking.insert(i);
      consumedBra.insert(j);
    }
    for (size_t i = 0; i < st.size(); ++i) {
      if (st[i].op.empty() || consumedBra.count(i)) continue;
      lowerStmt(i);
    }
    // results
    if (nout) {
      for (unsigned k = 0; k < nout; ++k)
        if (!outVal[k]) fail("async asm output $" + std::to_string(k) + " is never written");
      Value *res = outVal[0];
      if (nout > 1) {
        res = UndefValue::get(C->getType());
        for (unsigned k = 0; k < nout; ++k) res = B.CreateInsertValue(res, outVal[k], k);
      }
      C->replaceAllUsesWith(res);
    }
    // keep the compiler ordering the asm's "memory" clobber gave
    B.CreateFence(AtomicOrdering::SequentiallyConsistent, SyncScope::SingleThread);
    C->eraseFromParent();
  }

  void lowerStmt(size_t idx) {
    const Stmt &s = st[idx];
    const std::string &o = s.op;
    Value *pred = predOf(s);
    auto sw = [&](const char *p) { return o.rfind(p, 0) == 0; };
    auto nops = [&](size_t lo, size_t hi) {
      if (s.ops.size() < lo || s.ops.size() > hi) fail("`" + s.text + "`: unexpected operand count");
    };
    auto width = [&]() -> Type * {
      for (auto &t : s.tok)
        if (t.size() >= 2 && (t[0] == 'u' || t[0] == 's' || t[0] == 'b') && isdigit((unsigned char)t[1]))
          return IntegerType::get(S.ctx, std::atoi(t.c_str() + 1));
      return S.I32;
    };
    // --- plain data movement and predicates
    if (o == "mov" || sw("mov.")) {
      nops(2, 2);
      std::string src = trim(s.ops[1]);
      if (src.find("_param_") != std::string::npos && src[0] != '$' && src[0] != '%') {
        paramSym[trim(s.ops[0])] = src;
        return;
      }
      setReg(trim(s.ops[0]), val(src, width()), pred);
      return;
    }
    if (sw("cvta.param")) {
      nops(2, 2);
      auto it = paramSym.find(trim(s.ops[1]));
      if (it == paramSym.end()) fail("cvta.param of something other than a kernel parameter symbol");
      setReg(trim(s.ops[0]), B.CreatePtrToInt(paramAddress(it->second), S.I64), pred);
      return;
    }
    if (sw("setp.")) {
      nops(3, 3);
      if (s.tok.size() < 3) fail("`" + s.text + "`");
      if (s.ops[0].find('|') != std::string::npos) fail("setp with two destinations in async asm");
      const std::string &cmp = s.tok[1];
      Type *T = width();
      bool sgn = s.tok[2][0] == 's';
      Value *a = val(s.ops[1], T), *b = val(s.ops[2], T);
      CmpInst::Predicate P;
      if (cmp == "eq") P = CmpInst::ICMP_EQ;
      else if (cmp == "ne") P = CmpInst::ICMP_NE;
      else if (cmp == "lt") P = sgn ? CmpInst::ICMP_SLT : CmpInst::ICMP_ULT;
      else if (cmp == "le") P = sgn ? CmpInst::ICMP_SLE : CmpInst::ICMP_ULE;
      else if (cmp == "gt") P = sgn ? CmpInst::ICMP_SGT : CmpInst::ICMP_UGT;
      else if (cmp == "ge") P = sgn ? CmpInst::ICMP_SGE : CmpInst::ICMP_UGE;
      else fail("setp comparison `" + cmp + "` in async asm");
      Value *r = B.CreateICmp(P, a, b); // folds when both are constants
      setReg(trim(s.ops[0]), r, pred);
      return;
    }
    if (sw("selp.")) {
      nops(4, 4);
      Type *T = width();
      Value *p = val(s.ops[3], nullptr);
      if (!p->getType()->isIntegerTy(1)) p = B.CreateICmpNE(p, ConstantInt::get(p->getType(), 0));
      Value *a = val(s.ops[1], T), *b = val(s.ops[2], T);
      Value *r;
      if (auto *K = dyn_cast<ConstantInt>(p)) r = K->isZero() ? b : a;
      else r = B.CreateSelect(p, a, b);
      setReg(trim(s.ops[0]), r, pred);
      return;
    }
    if (sw("activemask")) {
      nops(1, 1);
      Value *m = underPred(pred, [&]() -> Value * { return S.call(B, kActive, S.I32, {}); });
      setReg(trim(s.ops[0]), m, nullptr);
      return;
    }
    if (sw("elect.sync")) {
      nops(2, 2);
      needWarps();
      if (pred && !isa<ConstantInt>(pred)) fail("predicated elect.sync in async asm");
      std::vector<std::string> d = splitTop(s.ops[0], '|');
      if (d.size() != 2) fail("elect.sync needs `d|p`");
      Value *mask = val(s.ops[1], S.I32);
      Value *lane = nullptr, *p = nullptr;
      underPred(pred, [&]() -> Value * {
        if (trim(d[0]) != "_") lane = S.call(B, kElectLane, S.I32, {mask});
        p = B.CreateICmpNE(S.call(B, kElect, S.I32, {mask}), ConstantInt::get(S.I32, 0), "elected");
        return nullptr;
      });
      if (lane) setReg(trim(d[0]), lane, nullptr);
      setReg(trim(d[1]), p, nullptr);
      return;
    }
    if (sw("mapa")) {
      nops(3, 3);
      // clusters of one CTA: mapa(a, 0) = a; any other rank traps (and the predicate is false afterwards)
      Value *a = val(s.ops[1], nullptr);
      Value *rank = val(s.ops[2], S.I32);
      bool known0 = isa<ConstantInt>(rank) && cast<ConstantInt>(rank)->isZero();
      if (!known0) {
        Value *bad = B.CreateICmpNE(rank, ConstantInt::get(S.I32, 0));
        if (pred && !isa<ConstantInt>(pred)) bad = B.CreateAnd(bad, pred);
        if (!(pred && isa<ConstantInt>(pred) && cast<ConstantInt>(pred)->isZero())) {
          // a normal join, not `unreachable`: the Vortex back end inserts no split/join for a divergent branch
          // whose immediate post-dominator is unreachable, and the warp then never reconverges (lifted tma2d hung)
          Instruction *T = SplitBlockAndInsertIfThen(bad, C->getIterator(), /*Unreachable=*/false);
          IRBuilder<> TB(T);
          TB.CreateCall(S.fn(kRankFail, S.Void, {S.I32}, false, false), {rank});
          B.SetInsertPoint(C);
        }
        // past the check the predicate cannot hold (a rank != 0 trapped)
        if (!s.pred.empty() && !s.neg && pred && !isa<ConstantInt>(pred)) regs[s.pred] = ConstantInt::getFalse(S.ctx);
      }
      setReg(trim(s.ops[0]), a, nullptr);
      return;
    }
    // --- fences and hints
    if (sw("fence.proxy.") || sw("fence.mbarrier_init") || sw("setmaxnreg.") || sw("griddepcontrol.") ||
        sw("prefetch.tensormap") || sw("cp.async.bulk.prefetch") || sw("cp.async.bulk.commit_group") ||
        sw("cp.async.bulk.wait_group") || sw("barrier.cluster.arrive") || sw("tensormap.cp_fenceproxy") ||
        sw("wgmma.fence") || sw("wgmma.commit_group") || sw("wgmma.wait_group")) {
      return; // synchronous software copies: nothing to order beyond the compiler fence
    }
    if (sw("fence.") && o.find(".cluster") != std::string::npos) {
      underPred(pred, [&]() -> Value * {
        B.CreateCall(S.M->getOrInsertFunction("llvm.nvvm.membar.cta", FunctionType::get(S.Void, false)), {});
        return nullptr;
      });
      return;
    }
    if (sw("barrier.cluster.wait")) {
      if (pred) fail("predicated barrier.cluster.wait");
      B.CreateCall(S.M->getOrInsertFunction("llvm.nvvm.barrier0", FunctionType::get(S.Void, false)), {});
      return;
    }
    // --- mbarrier
    if (sw("mbarrier.")) {
      lowerMbarrier(idx, pred);
      return;
    }
    if (sw("cp.async.mbarrier.arrive")) {
      nops(1, 1);
      if (isCuLifterFunction(F))
        fail("sm_80 mbarrier lifted by CuLifter (ARRIVES.LDGSTSBAR without its .noinc suffix; the matching wait is an "
             "LDS polling loop on the hardware-encoded barrier word) is not supported: translate the CUDA source, or "
             "lift an sm_90 build");
      if (s.has("noinc")) {
        needWarps();
        underPred(pred, [&]() -> Value * {
          Value *P = addr(s.ops[0], "mbarrier");
          CallInst *a = S.call(B, kArrive, S.I32, {P, ConstantInt::get(S.I32, 1)});
          S.arrives[F].push_back(a);
          return nullptr;
        });
      }
      // without .noinc: pending count +1 now, -1 when this thread's cp.async complete -- net zero, and
      // lower_cp_async makes the copies synchronous
      return;
    }
    if (sw("cp.reduce.async.bulk")) fail("cp.reduce.async.bulk (bulk reductions) is not supported");
    if (sw("cp.async.bulk")) {
      lowerBulk(idx, pred);
      return;
    }
    fail("unsupported statement in async asm: `" + s.text + "`");
  }

  void lowerMbarrier(size_t idx, Value *pred) {
    const Stmt &s = st[idx];
    const std::string what = s.tok.size() > 1 ? s.tok[1] : "";
    if (s.has("shared::cluster") && what != "arrive")
      fail("`" + s.op + "` on a shared::cluster address (clusters are not supported)");
    if (what == "init") {
      if (s.ops.size() != 2) fail("mbarrier.init needs [addr], count");
      underPred(pred, [&]() -> Value * {
        Value *P = addr(s.ops[0], "mbarrier");
        Value *n = val(s.ops[1], S.I32);
        S.call(B, kInit, S.Void, {P, n, ConstantInt::get(S.I32, kIdPlaceholder)});
        return nullptr;
      });
      return;
    }
    if (what == "inval" || what == "complete_tx") return; // software mode: no transaction count
    if (what == "expect_tx") return;                       // see the §5.3 move of the arrives
    if (what == "arrive_drop" || s.has("noComplete"))
      fail("`" + s.op + "` (drop / noComplete arrivals) is not supported");
    if (what == "pending_count") fail("mbarrier.pending_count is not supported");
    if (what == "arrive") {
      needWarps();
      if (s.ops.size() < 2 || s.ops.size() > 3) fail("mbarrier.arrive needs state, [addr][, count]");
      const bool tx = s.has("expect_tx");
      Value *r = underPred(pred, [&]() -> Value * {
        Value *P = addr(s.ops[1], "mbarrier");
        Value *cnt = s.ops.size() == 3 ? val(s.ops[2], S.I32) : nullptr;
        CallInst *a = tx ? S.call(B, kArriveTx, S.I32, {P, cnt ? cnt : ConstantInt::get(S.I32, 0)})
                         : S.call(B, kArrive, S.I32, {P, cnt ? cnt : ConstantInt::get(S.I32, 1)});
        S.arrives[F].push_back(a);
        return a;
      });
      if (trim(s.ops[0]) != "_" && r) setReg(trim(s.ops[0]), B.CreateZExt(r, S.I64), nullptr);
      return;
    }
    if (what == "try_wait" || what == "test_wait") {
      needWarps();
      if (s.ops.size() < 3 || s.ops.size() > 4) fail("`" + s.op + "` needs p, [addr], state|parity[, hint]");
      const bool parity = s.has("parity");
      const bool block = what == "try_wait" || blocking.count(idx);
      Value *r = underPred(pred, [&]() -> Value * {
        Value *P = addr(s.ops[1], "mbarrier");
        Value *arg = val(s.ops[2], parity ? S.I32 : S.I64);
        const char *name = parity ? (block ? kWaitPar : kTestPar) : (block ? kWaitSt : kTestSt);
        return S.call(B, name, S.I32, {P, arg});
      });
      // a blocking wait returns only once the phase completed: the predicate is known to be true
      Value *p = (block && !pred) || !r ? (Value *)ConstantInt::getTrue(S.ctx)
                                       : B.CreateICmpNE(r, ConstantInt::get(S.I32, 0), "mbar_done");
      setReg(trim(s.ops[0]), p, nullptr);
      return;
    }
    fail("unsupported mbarrier operation `" + s.op + "`");
  }

  void lowerBulk(size_t idx, Value *pred) {
    const Stmt &s = st[idx];
    needWarps();
    for (const char *bad : {"multicast::cluster", "cta_group::1", "cta_group::2", "cp_mask", "im2col", "im2col::w",
                            "im2col::w::128", "tile::gather4", "tile::scatter4", "im2col_no_offs"})
      if (s.has(bad)) fail("`" + s.op + "`: ." + bad + " is not supported");
    std::vector<std::string> ops = s.ops;
    if (s.has("L2::cache_hint")) {
      if (ops.empty()) fail("missing cache-policy operand");
      ops.pop_back(); // the cache policy
    }
    const bool tensor = s.tok.size() > 3 && s.tok[3] == "tensor";
    if (tensor) {
      if (s.tok.size() < 7) fail("`" + s.op + "`");
      const std::string &r = s.tok[4];
      if (r.size() != 2 || r[1] != 'd' || r[0] < '1' || r[0] > '5') fail("`" + s.op + "`: bad rank");
      unsigned rank = r[0] - '0';
      const bool load = s.tok[5].rfind("shared::", 0) == 0 && s.tok[6] == "global";
      const bool store = s.tok[5] == "global" && s.tok[6] == "shared::cta";
      auto coords = [&](const std::string &t, Value *&desc) -> std::vector<Value *> {
        std::string in = trim(t);
        if (in.size() < 2 || in.front() != '[' || in.back() != ']') fail("tensor operand must be [tmap, {coords}]");
        std::vector<std::string> parts = splitTop(in.substr(1, in.size() - 2), ',');
        if (parts.size() != 2) fail("tensor operand must be [tmap, {coords}]");
        Value *dv = val(parts[0], nullptr);
        desc = toPointer(B, S, dv, C, "tensor map");
        std::string cl = trim(parts[1]);
        if (cl.size() < 2 || cl.front() != '{' || cl.back() != '}') fail("tensor coordinates must be {c0, ...}");
        std::vector<std::string> cs = splitTop(cl.substr(1, cl.size() - 2), ',');
        if (cs.size() != rank) fail("tensor coordinate count differs from the rank");
        std::vector<Value *> v;
        for (auto &c : cs) v.push_back(val(c, S.I32));
        while (v.size() < 5) v.push_back(ConstantInt::get(S.I32, 0));
        return v;
      };
      if (load) {
        if (!s.has("mbarrier::complete_tx::bytes")) fail("`" + s.op + "`: a tensor load must complete on an mbarrier");
        if (ops.size() != 3) fail("`" + s.op + "`: expected [dst], [tmap, {coords}], [mbar]");
        underPred(pred, [&]() -> Value * {
          Value *dst = addr(ops[0], "shared destination");
          Value *desc = nullptr;
          std::vector<Value *> c = coords(ops[1], desc);
          Value *mb = addr(ops[2], "mbarrier"); // DXA mode completes the transfer there; software mode ignores it
          CallInst *k = S.call(B, kTmaLoad, S.Void,
                               {dst, desc, mb, ConstantInt::get(S.I32, rank), c[0], c[1], c[2], c[3], c[4]}, false);
          S.txCopies.insert(k);
          return nullptr;
        });
        return;
      }
      if (store) {
        if (!s.has("bulk_group")) fail("`" + s.op + "`: expected .bulk_group completion");
        if (ops.size() != 2) fail("`" + s.op + "`: expected [tmap, {coords}], [src]");
        underPred(pred, [&]() -> Value * {
          Value *desc = nullptr;
          std::vector<Value *> c = coords(ops[0], desc);
          Value *src = addr(ops[1], "shared source");
          S.call(B, kTmaStore, S.Void, {desc, src, ConstantInt::get(S.I32, rank), c[0], c[1], c[2], c[3], c[4]}, false);
          return nullptr;
        });
        return;
      }
      fail("`" + s.op + "`: unsupported tensor copy direction");
    }
    // non-tensor bulk copies
    if (s.tok.size() < 5) fail("`" + s.op + "`");
    const std::string &dsp = s.tok[3], &ssp = s.tok[4];
    const bool g2s = dsp.rfind("shared::", 0) == 0 && ssp == "global";
    const bool s2s = dsp == "shared::cluster" && ssp == "shared::cta";
    const bool s2g = dsp == "global" && ssp == "shared::cta";
    if (g2s || s2s) {
      if (!s.has("mbarrier::complete_tx::bytes")) fail("`" + s.op + "`: expected mbarrier::complete_tx::bytes");
      if (ops.size() != 4) fail("`" + s.op + "`: expected [dst], [src], size, [mbar]");
      underPred(pred, [&]() -> Value * {
        Value *dst = addr(ops[0], "shared destination");
        Value *src = addr(ops[1], "source");
        Value *n = val(ops[2], S.I32);
        CallInst *k = S.call(B, kBulk, S.Void, {dst, src, n}, false);
        S.txCopies.insert(k);
        return nullptr;
      });
      return;
    }
    if (s2g) {
      if (!s.has("bulk_group")) fail("`" + s.op + "`: expected .bulk_group completion");
      if (ops.size() != 3) fail("`" + s.op + "`: expected [dst], [src], size");
      underPred(pred, [&]() -> Value * {
        Value *dst = addr(ops[0], "global destination");
        Value *src = addr(ops[1], "shared source");
        Value *n = val(ops[2], S.I32);
        S.call(B, kBulk, S.Void, {dst, src, n}, false);
        return nullptr;
      });
      return;
    }
    fail("unsupported bulk copy `" + s.op + "`");
  }

  // `<fn>_param_N`: the address of kernel parameter N in the CUDA parameter image. CuLifter keeps that image
  // in the `param_local` alloca, indexed by constant-bank offset (argument `arg_<offset>`).
  Value *paramAddress(const std::string &sym) {
    size_t p = sym.rfind("_param_");
    std::string fname = sym.substr(0, p);
    unsigned n = std::atoi(sym.c_str() + p + 7);
    if (fname != F->getName() && fname != F->getName().str().substr(F->getName().starts_with("__src_") ? 6 : 0))
      fail("cvta.param of another function's parameter (" + sym + ")");
    if (n >= F->arg_size()) fail("cvta.param of a parameter the function does not have (" + sym + ")");
    S.paramAddrArgs.insert({F, n});
    Argument *A = F->getArg(n);
    AllocaInst *img = nullptr;
    for (auto &I : F->getEntryBlock())
      if (auto *AI = dyn_cast<AllocaInst>(&I))
        if (AI->getName() == "param_local") img = AI;
    unsigned off = 0;
    if (img && A->getName().starts_with("arg_")) {
      off = std::atoi(A->getName().str().c_str() + 4);
      // the image must hold this argument at that offset
      bool stored = false;
      for (User *U : A->users())
        if (auto *SI = dyn_cast<StoreInst>(U)) {
          APInt o(64, 0);
          Value *base = SI->getPointerOperand()->stripAndAccumulateConstantOffsets(S.M->getDataLayout(), o, true);
          if (base == img && o.getZExtValue() == off) stored = true;
        }
      if (!stored) img = nullptr;
    } else {
      img = nullptr;
    }
    IRBuilder<> EB(&*F->getEntryBlock().getFirstInsertionPt());
    if (!img) { // a private image of this one argument
      AllocaInst *one = EB.CreateAlloca(A->getType(), nullptr, "param_img");
      one->setAlignment(Align(64));
      EB.CreateStore(A, one);
      return one;
    }
    return B.CreateGEP(Type::getInt8Ty(S.ctx), img, ConstantInt::get(S.I64, off), "param_addr");
  }
};

// ---------------------------------------------------------------------------------------------------------
// NVVM intrinsics

bool lowerIntrinsic(PassState &S, CallInst *C) {
  Function *Fn = C->getCalledFunction();
  if (!Fn) return false;
  StringRef n = Fn->getName();
  if (!n.starts_with("llvm.nvvm.")) return false;
  Function *F = C->getFunction();
  IRBuilder<> B(C);
  auto P = [&](unsigned i) { return toPointer(B, S, C->getArgOperand(i), C, "mbarrier"); };
  auto done = [&](Value *r) {
    if (r && !C->getType()->isVoidTy()) {
      if (r->getType() != C->getType()) r = B.CreateZExtOrTrunc(r, C->getType());
      C->replaceAllUsesWith(r);
    }
    C->eraseFromParent();
    S.n_intr++;
    return true;
  };
  if (n.starts_with("llvm.nvvm.read.ptx.sreg.cluster.ctarank") || n.starts_with("llvm.nvvm.read.ptx.sreg.cluster.ctaid") ||
      n.starts_with("llvm.nvvm.read.ptx.sreg.is.explicit.cluster"))
    return done(ConstantInt::get(C->getType(), 0));
  if (n.starts_with("llvm.nvvm.read.ptx.sreg.cluster.nctarank") || n.starts_with("llvm.nvvm.read.ptx.sreg.cluster.nctaid"))
    return done(ConstantInt::get(C->getType(), 1));
  if (n.starts_with("llvm.nvvm.read.ptx.sreg.clusterid.") || n.starts_with("llvm.nvvm.read.ptx.sreg.nclusterid.")) {
    std::string d = n.str().substr(n.rfind('.') + 1);
    bool nc = n.contains("nclusterid");
    Function *G = S.M->getFunction(std::string("llvm.nvvm.read.ptx.sreg.") + (nc ? "nctaid." : "ctaid.") + d);
    FunctionCallee GC = G ? FunctionCallee(G) : S.M->getOrInsertFunction(std::string("llvm.nvvm.read.ptx.sreg.") + (nc ? "nctaid." : "ctaid.") + d, FunctionType::get(S.I32, false));
    return done(B.CreateCall(GC, {}));
  }
  if (n.starts_with("llvm.nvvm.mbarrier.")) {
    if (n.starts_with("llvm.nvvm.mbarrier.init")) {
      S.call(B, kInit, S.Void, {P(0), B.CreateZExtOrTrunc(C->getArgOperand(1), S.I32), ConstantInt::get(S.I32, kIdPlaceholder)});
      return done(nullptr);
    }
    if (n.starts_with("llvm.nvvm.mbarrier.inval")) return done(nullptr);
    if (n == "llvm.nvvm.mbarrier.arrive" || n == "llvm.nvvm.mbarrier.arrive.shared") {
      S.needWarps.insert(F);
      CallInst *a = S.call(B, kArrive, S.I32, {P(0), ConstantInt::get(S.I32, 1)});
      S.arrives[F].push_back(a);
      return done(B.CreateZExt(a, S.I64));
    }
    if (n.starts_with("llvm.nvvm.mbarrier.test.wait")) {
      S.needWarps.insert(F);
      return done(B.CreateICmpNE(S.call(B, kTestSt, S.I32, {P(0), B.CreateZExtOrTrunc(C->getArgOperand(1), S.I64)}),
                                 ConstantInt::get(S.I32, 0)));
    }
    fail_at(C, "mbarrier intrinsic " + n.str() + " is not supported (noComplete / drop / pending_count)");
  }
  if (n.starts_with("llvm.nvvm.cp.async.mbarrier.arrive")) {
    if (n.contains("noinc")) {
      S.needWarps.insert(F);
      CallInst *a = S.call(B, kArrive, S.I32, {P(0), ConstantInt::get(S.I32, 1)});
      S.arrives[F].push_back(a);
    }
    return done(nullptr);
  }
  if (n == "llvm.nvvm.cp.async.bulk.commit.group" || n.starts_with("llvm.nvvm.cp.async.bulk.wait.group") ||
      n.starts_with("llvm.nvvm.cp.async.bulk.prefetch") || n.starts_with("llvm.nvvm.cp.async.bulk.tensor.prefetch") ||
      n.starts_with("llvm.nvvm.fence.proxy") || n.starts_with("llvm.nvvm.setmaxnreg") ||
      n.starts_with("llvm.nvvm.griddepcontrol") || n.starts_with("llvm.nvvm.prefetch.tensormap") ||
      n.starts_with("llvm.nvvm.barrier.cluster.arrive")) {
    B.CreateFence(AtomicOrdering::SequentiallyConsistent, SyncScope::SingleThread);
    return done(nullptr);
  }
  if (n.starts_with("llvm.nvvm.barrier.cluster.wait")) {
    B.CreateCall(S.M->getOrInsertFunction("llvm.nvvm.barrier0", FunctionType::get(S.Void, false)), {});
    return done(nullptr);
  }
  if (n.starts_with("llvm.nvvm.cp.async.bulk") || n.starts_with("llvm.nvvm.cp.reduce.async.bulk") ||
      n.starts_with("llvm.nvvm.mapa") || n.starts_with("llvm.nvvm.elect") || n.starts_with("llvm.nvvm.tensormap"))
    fail_at(C, "the NVVM intrinsic form " + n.str() +
                   " is not supported yet (the inline asm form is); refusing instead of dropping it");
  return false;
}

// ---------------------------------------------------------------------------------------------------------
// §5.3: move an arrive after the bulk / TMA copies that follow it in the same thread

bool isWaitLike(Instruction *I, std::set<Function *> &visiting);

bool functionWaits(Function *F, std::set<Function *> &visiting) {
  if (!F || F->isDeclaration() || !visiting.insert(F).second) return false;
  for (auto &BB : *F)
    for (auto &I : BB)
      if (isWaitLike(&I, visiting)) return true;
  return false;
}

bool isWaitLike(Instruction *I, std::set<Function *> &visiting) {
  auto *C = dyn_cast<CallInst>(I);
  if (!C) return false;
  if (C->isInlineAsm()) {
    std::string a = trim(cast<InlineAsm>(C->getCalledOperand())->getAsmString());
    if ((a.rfind("bar.", 0) == 0 || a.rfind("barrier.", 0) == 0) && a.rfind("bar.warp.", 0) != 0) return true;
    return a.find("mbarrier") != std::string::npos && a.find("wait") != std::string::npos;
  }
  Function *F = C->getCalledFunction();
  if (!F) return true; // unknown callee: be conservative
  StringRef n = F->getName();
  if (n == kWaitPar || n == kTestPar || n == kWaitSt || n == kTestSt) return true;
  if (n.starts_with("llvm.nvvm.barrier") || n.starts_with("__cupbop_bar_") || n.contains("syncthreads")) return true;
  if (n.starts_with("llvm.")) return false;
  return functionWaits(F, visiting);
}

void moveArrives(PassState &S, Function *F) {
  auto it = S.arrives.find(F);
  if (it == S.arrives.end()) return;
  if (std::getenv("CUPBOP_ASYNC_NO_MOVE")) { // negative control for the tests only: produces wrong code
    fprintf(stderr, "*** WARNING: CUPBOP_ASYNC_NO_MOVE=1: arrives are NOT moved after their copies (wrong code; tests "
                    "only)\n");
    return;
  }
  for (CallInst *A : it->second) {
    DominatorTree DT(*F);
    PostDominatorTree PDT(*F);
    LoopInfo LI(DT);
    BasicBlock *BA = A->getParent();
    std::set<Function *> visiting;
    auto waits = [&](Instruction *I) {
      visiting.clear();
      return isWaitLike(I, visiting);
    };
    // copies reachable from A before a wait or a back edge
    std::vector<CallInst *> copies;
    std::set<BasicBlock *> seen;
    std::vector<std::pair<BasicBlock *, Instruction *>> work{{BA, A->getNextNode()}};
    while (!work.empty()) {
      auto [BB, from] = work.back();
      work.pop_back();
      bool stop = false;
      for (Instruction *I = from; I; I = I->getNextNode()) {
        if (auto *CI = dyn_cast<CallInst>(I))
          if (S.txCopies.count(CI)) copies.push_back(CI);
        if (waits(I)) { stop = true; break; }
      }
      if (stop) continue;
      for (BasicBlock *Sc : successors(BB)) {
        if (DT.dominates(Sc, BB)) continue; // back edge
        if (Sc == BA) continue;
        if (seen.insert(Sc).second) work.push_back({Sc, &Sc->front()});
      }
    }
    const bool tx = A->getCalledFunction()->getName() == kArriveTx;
    for (CallInst *Cp : copies) S.orderedCopies.insert(Cp);
    if (copies.empty()) {
      if (tx) {
        auto *K = dyn_cast<ConstantInt>(A->getArgOperand(1));
        if (!K || !K->isZero())
          fail_at(A, "mbarrier.arrive.expect_tx is not followed, in the same thread and before any wait, by the bulk / "
                     "TMA copies that complete its transaction: the synchronous copies cannot be ordered before the "
                     "arrival (async design §5.3); refusing");
      }
      continue;
    }
    // a state written to a register nobody reads (CuLifter: `@!p mbarrier.arrive... s, [a]`) leaves dead casts
    for (bool again = true; again;) {
      again = false;
      for (User *U : A->users())
        if (auto *I = dyn_cast<Instruction>(U))
          if (isInstructionTriviallyDead(I)) { I->eraseFromParent(); again = true; break; }
    }
    if (!A->use_empty())
      fail_at(A, "an mbarrier arrive whose state is used cannot be moved after the bulk / TMA copies that follow it");
    // nearest common post-dominator of the arrive and the copies, outside any loop the arrive is not in
    BasicBlock *PD = BA;
    for (CallInst *Cp : copies) PD = PDT.findNearestCommonDominator(PD, Cp->getParent());
    if (!PD) fail_at(A, "no common point after the arrive and its copies (§5.3); refusing");
    Loop *LA = LI.getLoopFor(BA);
    for (int guard = 0; guard < 64; ++guard) {
      Loop *LP = LI.getLoopFor(PD);
      if (LP == LA) break;
      if (LA && !LA->contains(PD))
        fail_at(A, "moving the arrive after its copies would leave the arrive's loop (§5.3); refusing");
      if (!LP) break;
      SmallVector<BasicBlock *, 4> exits;
      LP->getExitBlocks(exits);
      for (BasicBlock *E : exits) PD = PDT.findNearestCommonDominator(PD, E);
      if (!PD) fail_at(A, "no common point after the copies' loop (§5.3); refusing");
    }
    // insertion points
    std::vector<Instruction *> IPs;
    Instruction *lastInPD = nullptr;
    for (CallInst *Cp : copies)
      if (Cp->getParent() == PD && (!lastInPD || lastInPD->comesBefore(Cp))) lastInPD = Cp;
    if (PD == BA) {
      if (!lastInPD) fail_at(A, "internal: copies after the arrive but none in its block (§5.3)");
      IPs.push_back(lastInPD->getNextNode());
    } else if (DT.dominates(BA, PD)) {
      IPs.push_back(lastInPD ? lastInPD->getNextNode() : &*PD->getFirstInsertionPt());
    } else {
      if (lastInPD) fail_at(A, "the arrive's copies are also reached on paths without the arrive (§5.3); refusing");
      std::vector<BasicBlock *> preds;
      for (BasicBlock *X : predecessors(PD)) {
        if (X != BA && !seen.count(X)) continue; // not reached from the arrive
        if (!DT.dominates(BA, X))
          fail_at(A, "the point after the arrive's copies is shared with paths without the arrive (§5.3); refusing");
        preds.push_back(X);
      }
      if (preds.empty()) fail_at(A, "internal: no edge from the arrive's region to its post-dominator (§5.3)");
      for (BasicBlock *X : preds) {
        BasicBlock *NB = SplitEdge(X, PD, &DT, &LI);
        NB->setName("mbar_arrive_after_copies");
        IPs.push_back(NB->getTerminator());
      }
    }
    // no wait between the arrive and the new position(s)
    {
      std::set<BasicBlock *> rs;
      std::vector<std::pair<BasicBlock *, Instruction *>> w{{BA, A->getNextNode()}};
      std::set<Instruction *> ipset(IPs.begin(), IPs.end());
      DominatorTree DT2(*F);
      while (!w.empty()) {
        auto [BB, from] = w.back();
        w.pop_back();
        bool stop = false;
        for (Instruction *I = from; I; I = I->getNextNode()) {
          if (ipset.count(I)) { stop = true; break; }
          if (waits(I))
            fail_at(A, "a wait lies between the arrive and the end of its copies; moving the arrive could deadlock "
                       "(§5.3); refusing");
        }
        if (stop) continue;
        for (BasicBlock *Sc : successors(BB)) {
          if (DT2.dominates(Sc, BB) || Sc == BA) continue;
          if (rs.insert(Sc).second) w.push_back({Sc, &Sc->front()});
        }
      }
    }
    // TMA loads among the copies queue their DXA issue (DXA mode) until the moved arrive has arrived: see
    // __cupbop_tma_load_q in cudaKernelImpl_async.inc (a DXA completion must not overtake the arrival)
    bool anyTma = false;
    for (CallInst *Cp : copies) anyTma |= Cp->getCalledFunction() && Cp->getCalledFunction()->getName() == kTmaLoad;
    Value *Q = nullptr;
    if (anyTma) {
      Q = S.txq[F];
      if (!Q) {
        IRBuilder<> EB(&*F->getEntryBlock().getFirstInsertionPt());
        AllocaInst *AI = EB.CreateAlloca(ArrayType::get(Type::getInt8Ty(S.ctx), 192), nullptr, "cupbop_txq");
        AI->setAlignment(Align(8));
        // n = 0 after the entry block's allocas (the core-mapping passes expect them contiguous at the top)
        Instruction *firstNonAlloca = &*F->getEntryBlock().getFirstInsertionPt();
        while (isa<AllocaInst>(firstNonAlloca)) firstNonAlloca = firstNonAlloca->getNextNode();
        IRBuilder<>(firstNonAlloca).CreateStore(ConstantInt::get(S.I32, 0), AI);
        S.txq[F] = Q = AI;
      }
      for (CallInst *Cp : copies) {
        if (!Cp->getCalledFunction() || Cp->getCalledFunction()->getName() != kTmaLoad) continue;
        IRBuilder<> CB(Cp);
        std::vector<Value *> args{Q};
        for (auto &U : Cp->args()) args.push_back(U.get());
        CallInst *N = S.call(CB, "__cupbop_tma_load_q", S.Void, args, true);
        S.txCopies.erase(Cp);
        S.txCopies.insert(N);
        S.orderedCopies.erase(Cp);
        S.orderedCopies.insert(N);
        Cp->eraseFromParent();
      }
    }
    for (Instruction *IP : IPs) {
      if (Q) {
        IRBuilder<> IB(IP);
        const bool isTx = A->getCalledFunction()->getName() == kArriveTx;
        S.call(IB, isTx ? "__cupbop_mbar_arrive_tx_q" : "__cupbop_mbar_arrive_q", S.I32,
               {Q, A->getArgOperand(0), A->getArgOperand(1)});
      } else {
        Instruction *Cl = A->clone();
        Cl->insertBefore(IP);
      }
    }
    A->eraseFromParent();
    S.n_moved++;
  }
}

// Fold the integer arithmetic of a function to constants where possible (CuLifter computes shared-memory
// offsets of mbarriers through PRMT / LOP3 chains of constants and %cluster_ctarank). Pointer-typed
// instructions are left alone (their indices become constants).
void foldIntegers(Function &F) {
  const DataLayout &DL = F.getParent()->getDataLayout();
  for (bool changed = true; changed;) {
    changed = false;
    for (auto &BB : F)
      for (auto It = BB.begin(); It != BB.end();) {
        Instruction *I = &*It++;
        if (!I->getType()->isIntegerTy() || isa<CallBase>(I) || isa<LoadInst>(I)) continue;
        if (Constant *K = ConstantFoldInstruction(I, DL)) {
          if (!isa<ConstantInt>(K)) continue;
          I->replaceAllUsesWith(K);
          I->eraseFromParent();
          changed = true;
        }
      }
  }
}

// A CUtensorMap kernel parameter (CuLifter: [2 x <8 x i64>], whose address the lifted code takes with
// cvta.param) becomes an i64: the CUDA host passes it in one 8-byte launch slot (cudaLaunchKernel_vortex), which
// holds the device address of its record (cuTensorMapEncodeTiled shim). The body sees the old value rebuilt from
// those 8 bytes, the rest zero.
// Only vector-typed parameters reached through cvta.param: CuLifter types EVERY 64-byte-multiple parameter as
// [N/64 x <8 x i64>] (for the .align 64 of the PTX parameter), e.g. a 448-byte CUTLASS Kernel::Params, and those
// keep all their bytes through pass_wide_kernel_args_by_slot (generate_wrapper.cpp) like the [N x i8] ones.
// CUPBOP_NARROW_VECTOR_ARGS=1: the earlier rule (every vector-typed parameter wider than 8 bytes).
static bool hasVectorType(Type *T) {
  if (T->isVectorTy()) return true;
  if (auto *AT = dyn_cast<ArrayType>(T)) return hasVectorType(AT->getElementType());
  if (auto *ST = dyn_cast<StructType>(T))
    for (Type *E : ST->elements()) if (hasVectorType(E)) return true;
  return false;
}
static void narrowWideKernelArgs(Module *M, const std::set<std::pair<Function *, unsigned>> &paramAddrArgs) {
  const DataLayout &DL = M->getDataLayout();
  const bool all = std::getenv("CUPBOP_NARROW_VECTOR_ARGS") != nullptr;
  auto isWide = [&](Argument &A) {
    return !A.getType()->isPointerTy() && hasVectorType(A.getType()) && DL.getTypeStoreSize(A.getType()) > 8 &&
           (all || paramAddrArgs.count({A.getParent(), A.getArgNo()}));
  };
  std::vector<Function *> todo;
  for (auto &F : *M)
    if (!F.isDeclaration() && isKernelFunction(M, &F))
      for (auto &A : F.args())
        if (isWide(A)) { todo.push_back(&F); break; }
  LLVMContext &ctx = M->getContext();
  Type *I64 = Type::getInt64Ty(ctx);
  for (Function *F : todo) {
    std::vector<Type *> params;
    std::vector<bool> wide;
    for (auto &A : F->args()) {
      bool w = isWide(A);
      wide.push_back(w);
      params.push_back(w ? I64 : A.getType());
    }
    FunctionType *FT = FunctionType::get(F->getReturnType(), params, F->isVarArg());
    Function *NF = Function::Create(FT, F->getLinkage(), F->getAddressSpace(), "", M);
    NF->copyAttributesFrom(F);
    AttributeList AL = F->getAttributes();
    for (unsigned i = 0; i < wide.size(); ++i)
      if (wide[i]) AL = AL.removeParamAttributes(ctx, i);
    NF->setAttributes(AL);
    NF->setCallingConv(F->getCallingConv());
    NF->takeName(F);
    NF->splice(NF->begin(), F);
    IRBuilder<> B(&*NF->getEntryBlock().getFirstInsertionPt());
    for (unsigned i = 0; i < wide.size(); ++i) {
      Argument *OA = F->getArg(i), *NA = NF->getArg(i);
      if (!wide[i]) {
        NA->takeName(OA);
        OA->replaceAllUsesWith(NA);
        continue;
      }
      NA->setName(OA->getName() + ".lo8");
      AllocaInst *tmp = B.CreateAlloca(OA->getType(), nullptr, OA->getName() + ".wide");
      tmp->setAlignment(Align(64));
      B.CreateStore(Constant::getNullValue(OA->getType()), tmp);
      B.CreateStore(NA, tmp);
      Value *v = B.CreateLoad(OA->getType(), tmp, OA->getName());
      OA->replaceAllUsesWith(v);
      fprintf(stderr, "[CuPBoP] %s: parameter %u (%u bytes) narrowed to its first 8 bytes (one launch slot)\n",
              NF->getName().str().c_str(), i, (unsigned)DL.getTypeStoreSize(OA->getType()));
    }
    F->replaceAllUsesWith(NF);
    F->eraseFromParent();
  }
}

} // namespace

void lower_async_ptx(Module *M) {
  PassState S(M);
  const int sched = schedule();
  // 1. NVVM intrinsics (cluster registers first: CuLifter mbarrier addresses fold to constants after that)
  std::vector<CallInst *> calls;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *C = dyn_cast<CallInst>(&I))
          if (!C->isInlineAsm() && C->getCalledFunction() && C->getCalledFunction()->getName().starts_with("llvm.nvvm."))
            calls.push_back(C);
  for (auto *C : calls) lowerIntrinsic(S, C);
  // 2. inline asm
  std::vector<CallInst *> asms;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *C = dyn_cast<CallInst>(&I))
          if (C->isInlineAsm()) asms.push_back(C);
  std::set<Function *> touched;
  for (auto *C : asms) {
    const std::string a = cast<InlineAsm>(C->getCalledOperand())->getAsmString();
    std::vector<Stmt> st;
    std::string err;
    if (!parsePtx(a, st, err)) {
      if (mentionsAsyncText(a)) fail_at(C, "cannot parse async asm (" + err + ")");
      continue;
    }
    bool owned = false;
    for (auto &s : st) owned |= ownedOp(s);
    if (!owned) {
      if (mentionsAsyncText(a) && a.find("cp.async") == std::string::npos)
        fail_at(C, "async asm that the statement parser does not recognize: `" + a + "`");
      continue;
    }
    touched.insert(C->getFunction());
    AsmLowering L(S, C);
    L.st = st;
    L.run();
    S.n_asm++;
  }
  if (!S.n_asm && !S.n_intr) {
    std::remove("cupbop_async_kernels.txt");
    return;
  }

  // 3. constant mbarrier addresses (CuLifter), then the §5.3 move
  for (auto *F : touched) foldIntegers(*F);
  for (auto &F : *M)
    if (!F.isDeclaration()) moveArrives(S, &F);
  // A copy completing on an mbarrier that no arrive of its own thread follows (before a wait) relies on the
  // transaction count to hold the phase open -- e.g. a standalone mbarrier.expect_tx and the copy here, the
  // arrival in another thread -- which the synchronous copies do not model: refuse instead of racing.
  if (!std::getenv("CUPBOP_ASYNC_NO_MOVE"))
    for (CallInst *Cp : S.txCopies)
      if (!S.orderedCopies.count(Cp))
        fail_at(Cp, "a bulk / TMA copy completing on an mbarrier is not followed, in the same thread and before any "
                    "wait, by an arrive on it: without a transaction count the synchronous copy cannot hold the "
                    "phase open (async design §5.3); refusing");

  // 4. schedules
  if (!S.needWarps.empty()) {
    std::string fns;
    for (auto *F : S.needWarps) fns += (fns.empty() ? "" : ", ") + F->getName().str();
    if (sched == 0) {
      fprintf(stderr, "error: mbarrier / TMA / bulk copy / elect (warp-specialized synchronization) is only supported "
                      "on the 1:1 schedule (SCHEDULE=2); the flat schedule runs a whole CUDA block on one hardware "
                      "thread (in %s)\n", fns.c_str());
      exit(1);
    }
    if (const char *e = std::getenv("VORTEX_NUM_THREADS"))
      if (std::atoi(e) != 32) {
        fprintf(stderr, "error: mbarrier / TMA / bulk copy / elect need 32-lane hardware warps (VORTEX_NUM_THREADS=%s) "
                        "(in %s)\n", e, fns.c_str());
        exit(1);
      }
    if (sched == 1) {
      const char *trips = std::getenv("CUPBOP_VIRT_TRIPS"), *lanes = std::getenv("CUPBOP_VIRT_LANES");
      if ((trips && std::atoi(trips) > 1) || (lanes && std::atoi(lanes) > 0 && std::atoi(lanes) < 32)) {
        fprintf(stderr, "error: mbarrier / TMA / bulk copy / elect (warp-specialized synchronization) is only supported "
                        "on the 1:1 schedule (SCHEDULE=2) or a de facto 1:1 core mapping (one logical warp per "
                        "physical warp: no CUPBOP_VIRT_TRIPS > 1, no CUPBOP_VIRT_LANES < 32); the core mapping "
                        "serializes CUDA warps that wait on each other (in %s)\n", fns.c_str());
        exit(1);
      }
      // the host refuses the launch unless CUPBOP_VIRT_WARPS gives every CUDA warp its own physical warp
      std::ofstream out("cupbop_async_kernels.txt");
      for (auto &F : *M)
        if (isKernelFunction(M, &F)) out << F.getName().str() << "\n";
      fprintf(stderr, "[CuPBoP] async: core mapping accepted as de facto 1:1 only (checked at launch: physical warps "
                      "= CTA warps)\n");
    } else {
      std::remove("cupbop_async_kernels.txt");
    }
  } else {
    std::remove("cupbop_async_kernels.txt");
  }
  // last: the steps above are keyed by Function, and cvta.param needed the original CuLifter parameter image
  narrowWideKernelArgs(M, S.paramAddrArgs);
  fprintf(stderr, "[CuPBoP] async PTX lowered (software mode): %u asm, %u intrinsics, %u arrive(s) moved after their "
                  "copies\n", S.n_asm, S.n_intr, S.n_moved);
}

// ---------------------------------------------------------------------------------------------------------

void finalize_mbarrier_ids(Module *M) {
#ifdef VX_CFG_NUM_BARRIERS
  const unsigned num_barriers = VX_CFG_NUM_BARRIERS;
#else
  const unsigned num_barriers = 8;
#endif
  std::vector<CallInst *> inits;
  std::set<unsigned> used = {0}; // 0: __syncthreads
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *C = dyn_cast<CallInst>(&I))
          if (Function *Fn = C->getCalledFunction()) {
            StringRef n = Fn->getName();
            if (n == kInit) inits.push_back(C);
            else if (n == "__cupbop_bar_sync" || n == "__cupbop_bar_arrive" || n == "_Z19__vx_dxa_barrier_idj") {
              if (auto *K = dyn_cast<ConstantInt>(C->getArgOperand(0))) used.insert((unsigned)K->getZExtValue());
              else used.insert(~0u); // marker: unknown
            }
          }
  if (inits.empty()) return;
  if (used.count(~0u))
    fail_at(inits[0], "mbarriers together with a named barrier / DXA barrier whose id is not a constant: cannot "
                      "allocate distinct Vortex barrier numbers");
  const DataLayout &DL = M->getDataLayout();
  struct Obj { GlobalVariable *G; int64_t off; bool dyn; };
  std::vector<Obj> objs;
  for (auto *C : inits) {
    Value *P = C->getArgOperand(0);
    int64_t off = 0;
    bool dyn = false;
    GlobalVariable *G = nullptr;
    for (int guard = 0; guard < 64 && P; ++guard) {
      P = P->stripPointerCasts();
      if ((G = dyn_cast<GlobalVariable>(P))) break;
      if (auto *GEP = dyn_cast<GEPOperator>(P)) {
        APInt o(64, 0);
        if (GEP->accumulateConstantOffset(DL, o)) off += o.getSExtValue();
        else dyn = true;
        P = GEP->getPointerOperand();
        continue;
      }
      if (auto *ASC = dyn_cast<AddrSpaceCastOperator>(P)) { P = ASC->getPointerOperand(); continue; }
      if (auto *ITP = dyn_cast<IntToPtrInst>(P)) { P = cupbop_trace_pointer(ITP->getOperand(0)); continue; }
      break;
    }
    if (!G || G->getAddressSpace() != 3)
      fail_at(C, "mbarrier.init on an address that is not a constant or computed offset into a __shared__ variable: "
                 "cannot assign it a Vortex barrier number");
    objs.push_back({G, off, dyn});
  }
  // allocation: a variable with a computed-offset init gets one number per 8-byte word; otherwise one per offset
  std::map<GlobalVariable *, bool> anyDyn;
  for (auto &o : objs) anyDyn[o.G] = anyDyn[o.G] || o.dyn;
  // Numbers must differ between the mbarriers of one CTA, i.e. of one kernel. An init in a kernel's own body
  // draws from that kernel's numbers; an init in another (device) function from numbers no kernel uses.
  std::vector<unsigned> freeIds;
  for (unsigned i = 1; i < num_barriers; ++i)
    if (!used.count(i)) freeIds.push_back(i);
  size_t next = 0, shared_next = 0;
  std::map<GlobalVariable *, unsigned> rangeBase;
  std::map<std::pair<GlobalVariable *, int64_t>, unsigned> constId;
  auto take = [&](CallInst *C, unsigned n) -> unsigned {
    if (next + n > freeIds.size())
      fail_at(C, "too many mbarriers: the CTA has " + std::to_string(num_barriers) + " Vortex barriers (" +
                     std::to_string(freeIds.size()) + " free after __syncthreads and named barriers); design §8-1(b)");
    for (size_t k = 1; k < n; ++k)
      if (freeIds[next + k] != freeIds[next] + k)
        fail_at(C, "no contiguous range of Vortex barrier numbers for an mbarrier array (named barriers in between)");
    unsigned b = freeIds[next];
    next += n;
    return b;
  };
  LLVMContext &ctx = M->getContext();
  Type *I32 = Type::getInt32Ty(ctx), *I64 = Type::getInt64Ty(ctx);
  std::string summary;
  // order: inits in non-kernel functions first (their numbers are reserved for every kernel), then per kernel
  std::vector<size_t> order;
  for (size_t i = 0; i < inits.size(); ++i)
    if (!isKernelFunction(M, inits[i]->getFunction())) order.push_back(i);
  const size_t n_shared = order.size();
  for (size_t i = 0; i < inits.size(); ++i)
    if (isKernelFunction(M, inits[i]->getFunction())) order.push_back(i);
  std::stable_sort(order.begin() + n_shared, order.end(), [&](size_t a, size_t b) {
    return inits[a]->getFunction()->getName() < inits[b]->getFunction()->getName();
  });
  Function *curK = nullptr;
  for (size_t oi = 0; oi < order.size(); ++oi) {
    const size_t i = order[oi];
    CallInst *C = inits[i];
    Obj &o = objs[i];
    if (oi == n_shared) shared_next = next;
    if (oi >= n_shared && C->getFunction() != curK) { // a new kernel: its own numbers after the shared ones
      curK = C->getFunction();
      next = shared_next;
      rangeBase.clear();
      constId.clear();
      summary += std::string(" |") + curK->getName().str() + ":";
    }
    Value *id;
    if (anyDyn[o.G]) {
      const uint64_t words = (DL.getTypeAllocSize(o.G->getValueType()) + 7) / 8;
      if (!rangeBase.count(o.G)) {
        rangeBase[o.G] = take(C, (unsigned)words);
        summary += " " + o.G->getName().str() + "[" + std::to_string(words) + "]->" + std::to_string(rangeBase[o.G]);
      }
      IRBuilder<> B(C);
      Value *P = C->getArgOperand(0);
      Value *base = B.CreateAddrSpaceCast(o.G, PointerType::get(ctx, 0));
      Value *d = B.CreateSub(B.CreatePtrToInt(P, I64), B.CreatePtrToInt(base, I64));
      id = B.CreateAdd(B.CreateTrunc(B.CreateLShr(d, 3), I32), ConstantInt::get(I32, rangeBase[o.G]), "mbar_id");
    } else {
      auto key = std::make_pair(o.G, o.off);
      if (!constId.count(key)) {
        constId[key] = take(C, 1);
        summary += " " + o.G->getName().str() + "+" + std::to_string(o.off) + "->" + std::to_string(constId[key]);
      }
      id = ConstantInt::get(I32, constId[key]);
    }
    C->setArgOperand(2, id);
  }
  fprintf(stderr, "[CuPBoP] mbarrier Vortex barrier numbers:%s\n", summary.c_str());
}
