// Hopper / Ampere asynchronous PTX (mbarrier, TMA, bulk copy, elect, cluster registers, proxy fences) lowered
// to CuPBoP internal calls in software mode. See async_ptx.h and 2026-10-28_ASYNC_DESIGN_KO.md (§4-§6).
#include "async_ptx.h"
#include "../../../runtime/include/cupbop_reduce.h"
#include "async_copy.h"
#include "tool.h"

#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/IntrinsicsNVPTX.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Local.h"

#include <algorithm>
#include <array>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <vector>

using namespace llvm;

namespace {

const char *kInit = "__cupbop_mbar_init", *kArrive = "__cupbop_mbar_arrive", *kArriveTx = "__cupbop_mbar_arrive_tx",
           *kWaitPar = "__cupbop_mbar_wait_parity", *kTestPar = "__cupbop_mbar_test_parity",
           *kWaitSt = "__cupbop_mbar_wait_state", *kTestSt = "__cupbop_mbar_test_state",
           *kElect = "__cupbop_elect_sync", *kElectLane = "__cupbop_elect_lane", *kTmaLoad = "__cupbop_tma_load",
           *kTmaStore = "__cupbop_tma_store", *kBulk = "__cupbop_bulk_copy",
           *kActive = "__cupbop_activemask", *kTmaLoadQi = "__cupbop_tma_load_qi",
           *kArriveM = "__cupbop_mbar_arrive_m", *kArriveTxM = "__cupbop_mbar_arrive_tx_m", *kTmaSlot = "__cupbop_tma_slot",
           *kTxqIssue = "__cupbop_txq_issue", *kTxqCheck = "__cupbop_txq_check";
const uint32_t kIdPlaceholder = 0xFFFFFFFFu;
const uint32_t kTxqN = 4, kTxqEntrySize = 48;

int schedule() {
  const char *e = std::getenv("VORTEX_SCHEDULE_FLAG");
  return e ? std::atoi(e) : 0;
}

bool tensorMapScope(StringRef scope) {
  return scope == "cta" || scope == "cluster" || scope == "gpu" || scope == "sys";
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

static bool isWgmmaMma(const Stmt &s) {
  return StringRef(s.op).starts_with("wgmma.mma_async");
}

static void validateWgmmaMma(CallInst *C, ArrayRef<Stmt> statements) {
  const Stmt &mma = statements.back();
  for (const Stmt &s : statements)
    if (isWgmmaMma(s) && (s.has("sp") || s.hasPrefix("sp::")))
      fail_at(C, "sparse WGMMA MMA is unsupported");
  const auto *result = dyn_cast<StructType>(C->getType());
  if (!StringRef(mma.op).starts_with("wgmma.mma_async.sync.aligned.m64n") || !mma.pred.empty() ||
      !mma.label.empty() || !result || mma.ops.size() < 4)
    fail_at(C, "WGMMA MMA requires a single unpredicated instruction and a register tuple result");

  StringRef outputs(mma.ops[0]);
  if (!outputs.consume_front("{") || !outputs.consume_back("}"))
    fail_at(C, "WGMMA MMA is missing its accumulator register tuple");
  auto registers = splitTop(outputs.str(), ',');
  if (registers.size() != result->getNumElements())
    fail_at(C, "WGMMA MMA accumulator count differs from its LLVM result");
  for (unsigned i = 0; i < registers.size(); ++i) {
    StringRef reg(registers[i]);
    if (reg.consume_front("$")) {
      if (reg.consume_front("{") && reg.consume_back("}")) reg = reg.split(':').first;
      unsigned index = 0;
      if (!reg.getAsInteger(10, index) && index == i) continue;
    }
    fail_at(C, "WGMMA MMA accumulator output operands must be in LLVM result order");
  }

  // CUTLASS defines its scale-D predicate with `setp.ne.b32 p, $input, 0` immediately before MMA.
  if (statements.size() == 1 && mma.ops[3] != "p") return;
  if (statements.size() == 2 && mma.ops[3] == "p") {
    const Stmt &set = statements.front();
    if (set.op == "setp.ne.b32" && set.pred.empty() && set.label.empty() && set.ops.size() == 3 &&
        set.ops[0] == "p" && set.ops[1] == "$" + std::to_string(registers.size() + 2) && set.ops[2] == "0")
      return;
  }
  fail_at(C, "WGMMA MMA inline asm must contain just the MMA and its optional scale-D setp.ne.b32");
}

// Scoped scalar atomics emitted by libcudacxx's barrier and pipeline state.
static bool isCtaAtomic(const Stmt &s) {
  return s.op == "ld.acquire.cta.b64" || s.op == "ld.relaxed.cta.b32" ||
         s.op == "st.relaxed.cta.b32" || s.op == "atom.add.acquire.cta.u32" ||
         s.op == "atom.add.relaxed.cta.u32" || s.op == "atom.add.acq_rel.cta.u64" ||
         s.op == "atom.add.relaxed.cta.u64";
}

// Is this statement one lower_async_ptx owns?
bool ownedOp(const Stmt &s) {
  const std::string &o = s.op;
  auto sw = [&](const char *p) { return o.rfind(p, 0) == 0; };
  if (sw("clusterlaunchcontrol.") || sw("tcgen05.") || sw("mbarrier.") || sw("cp.async.bulk") ||
      sw("cp.reduce.async.bulk") || sw("cp.async.mbarrier.arrive") || sw("elect.sync") || sw("fence.mbarrier_init") ||
      sw("ld.shared::cluster.") || sw("st.shared::cluster.") || sw("st.async.") || sw("getctarank") || sw("isspacep.shared::cluster") || sw("mapa") || sw("barrier.cluster.") || sw("setmaxnreg.") || sw("griddepcontrol.") || sw("prefetch.tensormap") ||
      sw("cvta.param") || sw("multimem.") || sw("tensormap.") || sw("fence.proxy."))
    return true;
  if (isCtaAtomic(s) || o == "fence.sc.cta")
    return true;
  if ((sw("fence.") && o.find(".cluster") != std::string::npos)) return true;
  for (auto &x : s.ops)
    if (x.find("%cluster_") != std::string::npos || x.find("%clusterid") != std::string::npos ||
        x.find("%nclusterid") != std::string::npos || x.find("%is_explicit_cluster") != std::string::npos)
      return true;
  return false;
}

bool mentionsAsyncText(const std::string &s) {
  for (const char *k :
       {"clusterlaunchcontrol.", "tcgen05.", "mbarrier", "cp.async.bulk", "cp.reduce.async.bulk", "elect.sync", "mapa",
        "barrier.cluster", "%cluster_", "setmaxnreg", "griddepcontrol", "tensormap", "cvta.param", "fence.proxy.", "fence.mbarrier_init"})
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
  std::set<Function *> tcgenFunctions;                    // use a byte-counted software barrier for TCGEN/TMA kernels
  std::set<Function *> needWarps;                         // functions with ops that need real warps
  std::map<BasicBlock *, WeakTrackingVH> txqIssueAnchors;
  std::map<std::pair<Function *, Value *>, Value *> slots; // DXA slot of a tensor-map parameter, read at the entry
  std::set<CallInst *> orderedCopies;                     // copies some arrive of the same thread was moved after
  std::set<std::pair<Function *, unsigned>> tensorMapArgs;
  std::map<Function *, std::pair<AllocaInst *, unsigned>> paramImages;
  unsigned n_asm = 0, n_intr = 0, n_moved = 0, n_issue = 0;
  explicit PassState(Module *m)
      : M(m), ctx(m->getContext()), I1(Type::getInt1Ty(ctx)), I32(Type::getInt32Ty(ctx)), I64(Type::getInt64Ty(ctx)),
        Void(Type::getVoidTy(ctx)), Ptr(PointerType::get(ctx, 0)) {}
  FunctionCallee fn(const char *name, Type *ret, ArrayRef<Type *> args, bool convergent = true, bool noreturn = false) {
    FunctionCallee f = M->getOrInsertFunction(name, FunctionType::get(ret, args, false));
    if (auto *Fn = dyn_cast<Function>(f.getCallee())) {
      if (convergent) Fn->addFnAttr(Attribute::Convergent);
      if (StringRef(name) == "__cupbop_cluster_sync") Fn->addFnAttr(Attribute::NoDuplicate);
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

// CUDA CTA coordinates are relative to the recorded launch geometry.
static Value *clusterRegister(PassState &S, IRBuilder<> &B, StringRef reg) {
  unsigned axis = reg.ends_with(".z") ? 2 : reg.ends_with(".y") ? 1 : 0;
  unsigned which = reg.contains("is_explicit_cluster") || reg.contains("is.explicit.cluster") ? 6 :
                   reg.contains("nclusterid") ? 5 : reg.contains("clusterid") ? 4 :
                   reg.contains("nctaid") ? 3 : reg.contains("ctaid") ? 2 : reg.contains("nctarank") ? 1 : 0;
  return S.call(B, "__cupbop_cluster_register", S.I32, {B.getInt32(which), B.getInt32(axis)});
}

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
  if (V->getType()->isIntegerTy(32) && (StringRef(what).contains("shared") || StringRef(what).contains("barrier")))
    return S.call(B,"__cupbop_cluster_shared_ptr",S.Ptr,{V});
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
    } else if (t.rfind("%cluster", 0) == 0 || t.rfind("%nclusterid", 0) == 0 || t == "%is_explicit_cluster") {
      v = clusterRegister(S,B,t);
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
      else if (v->getType()->isFloatingPointTy() && want->isIntegerTy() && v->getType()->getPrimitiveSizeInBits() == want->getPrimitiveSizeInBits()) v = B.CreateBitCast(v,want);
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
        else if (T->isFloatingPointTy() && v->getType()->getPrimitiveSizeInBits() == T->getPrimitiveSizeInBits()) v = B.CreateBitCast(v,T);
        else fail("cannot assign to output `" + d + "`");
      }
      outVal[k] = v;
    } else {
      regs[d] = v;
    }
  }
  Value *predOf(const Stmt &s) {
    if (s.pred.empty()) return nullptr;
    Value *p = nullptr;
    if (s.pred[0] == '$') { // an operand (Triton: `@$0 cp.async.bulk.tensor ...` with an i1 "b" operand)
      p = val(s.pred, nullptr);
    } else {
      auto it = regs.find(s.pred);
      if (it == regs.end()) fail("predicate `" + s.pred + "` used before it is set");
      p = it->second;
    }
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
        if (t.size() >= 2 && (t[0] == 'u' || t[0] == 's' || t[0] == 'b' || t[0] == 'f') && isdigit((unsigned char)t[1]))
          return IntegerType::get(S.ctx, std::atoi(t.c_str() + 1));
      return S.I32;
    };
    if (isCtaAtomic(s)) {
      bool add = sw("atom."), store = sw("st.");
      nops(add ? 3 : 2, add ? 3 : 2);
      Type *ty = width();
      auto align = Align(ty->getIntegerBitWidth() / 8);
      Value *result = underPred(pred, [&]() -> Value * {
        Value *ptr = addr(s.ops[store ? 0 : 1], "CTA atomic address");
        if (add) {
          auto order = s.has("acq_rel") ? AtomicOrdering::AcquireRelease :
                       s.has("acquire") ? AtomicOrdering::Acquire : AtomicOrdering::Monotonic;
          return B.CreateAtomicRMW(AtomicRMWInst::Add, ptr, val(s.ops[2], ty), align, order);
        }
        if (store) {
          B.CreateAlignedStore(val(s.ops[1], ty), ptr, align)->setAtomic(AtomicOrdering::Monotonic);
          return nullptr;
        }
        auto *load = B.CreateAlignedLoad(ty, ptr, align);
        load->setAtomic(s.has("acquire") ? AtomicOrdering::Acquire : AtomicOrdering::Monotonic);
        return load;
      });
      if (!store && result) setReg(s.ops[0], result, pred);
      return;
    }
    if (o == "fence.sc.cta") {
      underPred(pred, [&]() -> Value * { return B.CreateFence(AtomicOrdering::SequentiallyConsistent); });
      return;
    }
    if (sw("clusterlaunchcontrol.")) {
      if (o != "clusterlaunchcontrol.try_cancel.async.mbarrier::complete_tx::bytes.multicast::cluster::all.b128")
        fail("unsupported cluster launch control operation: " + s.text);
      nops(2, 2);
      needWarps();
      underPred(pred, [&]() -> Value * {
        return S.call(B, "__cupbop_tcgen_decline_cancel", S.Void,
                      {addr(s.ops[0], "cancellation response"), addr(s.ops[1], "completion barrier")});
      });
      return;
    }
    if (sw("tcgen05.")) {
      lowerTcgen(s, pred);
      return;
    }
    // CuLifter emits these address calculations inside its tcgen05 allocation bundles.
    if (o == "not.b32" || o == "brev.b32" || o == "clz.b32") {
      nops(2, 2);
      Value *src = val(s.ops[1], S.I32);
      Value *v = o == "not.b32"    ? B.CreateNot(src)
                 : o == "brev.b32" ? B.CreateUnaryIntrinsic(Intrinsic::bitreverse, src)
                                   : B.CreateBinaryIntrinsic(Intrinsic::ctlz, src, B.getFalse());
      setReg(s.ops[0], v, pred);
      return;
    }
    if (o == "shr.u32" || o == "shl.b32") {
      nops(3, 3);
      Value *v = val(s.ops[1], S.I32), *shift = val(s.ops[2], S.I32);
      Value *inRange = B.CreateICmpULT(shift, B.getInt32(32));
      Value *bits = o == "shr.u32" ? B.CreateLShr(v, shift) : B.CreateShl(v, shift);
      setReg(s.ops[0], B.CreateSelect(inRange, bits, B.getInt32(0)), pred);
      return;
    }
    if (o == "bar.warp.sync") {
      nops(1, 1);
      needWarps();
      if (pred || !isa<ConstantInt>(val(s.ops[0], S.I32)) || !cast<ConstantInt>(val(s.ops[0], S.I32))->isMinusOne())
        fail("only unpredicated full-warp sync is supported in an async bundle");
      B.CreateFence(AtomicOrdering::SequentiallyConsistent);
      return;
    }
    if (o == "ld.shared.b32") {
      nops(2, 2);
      Value *v = underPred(pred, [&]() -> Value * { return B.CreateLoad(S.I32, addr(s.ops[1], "shared")); });
      if (v) setReg(s.ops[0], v, pred);
      return;
    }
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
      nops(3,3);
      Value *mapped = underPred(pred, [&]() -> Value * {
        auto *a = toPointer(B,S,val(s.ops[1],nullptr),C,"shared");
        return S.call(B,"__cupbop_cluster_map",S.Ptr,{a,val(s.ops[2],S.I32)});
      });
      if (mapped) setReg(trim(s.ops[0]),mapped,pred);
      return;
    }
    if (sw("st.async.")) {
      if (!s.has("shared::cluster") || !s.has("mbarrier::complete_tx::bytes") ||
          s.has("v2") || s.has("v4")) fail("unsupported async store form");
      nops(3,3);
      Type *ty = width();
      underPred(pred,[&]() -> Value * {
        B.CreateStore(val(s.ops[1],ty),addr(s.ops[0],"shared destination"));
        return S.call(B,"__cupbop_tcgen_arrive",S.I64,{addr(s.ops[2],"completion barrier"),
                        B.getInt32(0),B.getInt32(-int(ty->getIntegerBitWidth()/8))});
      });
      return;
    }
    if (sw("getctarank") || sw("isspacep.shared::cluster")) {
      nops(2,2);
      Value *value = underPred(pred,[&]() -> Value * {
        auto *ptr = toPointer(B,S,val(s.ops[1],nullptr),C,"shared");
        return S.call(B,sw("getctarank") ? "__cupbop_cluster_query_rank" : "__cupbop_cluster_contains",
                      S.I32,{ptr});
      });
      if (value) setReg(s.ops[0],value,pred);
      return;
    }
    if (sw("ld.shared::cluster.") || sw("st.shared::cluster.")) {
      bool load = sw("ld.");
      nops(2,2);
      const unsigned count = s.has("v4") ? 4 : s.has("v2") ? 2 : 1;
      Type *ty = width();
      std::string reg = trim(s.ops[load ? 0 : 1]);
      std::vector<std::string> regs = {reg};
      if (count > 1) {
        if (reg.size() < 2 || reg.front() != '{' || reg.back() != '}') fail("expected a shared vector operand");
        regs = splitTop(reg.substr(1,reg.size()-2), ',');
        if (regs.size() != count) fail("wrong number of shared vector elements");
      }
      for (unsigned i=0; i<count; ++i) {
        Value *value = underPred(pred,[&]() -> Value * {
          auto *ptr = addr(s.ops[load ? 1 : 0],"shared::cluster");
          if (i) ptr = B.CreateGEP(ty,ptr,B.getInt32(i));
          if (load) {
            Value *v = B.CreateLoad(ty,ptr);
            if (ty->getIntegerBitWidth()<32 && (s.has("s8") || s.has("s16")))
              v = B.CreateSExt(v,S.I32);
            return v;
          }
          B.CreateStore(val(regs[i],ty),ptr);
          return nullptr;
        });
        if (load && value) setReg(trim(regs[i]),value,pred);
      }
      return;
    }
    // Both proxies use the same record and memory on Vortex. Publication copies
    // the record before the releasing warp resumes, and consumers use a memory fence.
    if (sw("tensormap.cp_fenceproxy.")) {
      nops(3, 3);
      if (!sw("tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.") ||
          s.tok.size() != 9 || s.tok[7] != "sync" || s.tok[8] != "aligned")
        fail("unsupported tensor-map proxy operation");
      if (!tensorMapScope(s.tok[6])) fail("unsupported tensor-map proxy scope");
      auto *size = dyn_cast<ConstantInt>(val(s.ops.back(), S.I64));
      if (!size || !size->equalsInt(128)) fail("tensor-map proxy operation requires immediate size 128");
      needWarps();
      underPred(pred, [&]() -> Value * {
        return S.call(B, "__cupbop_tensormap_publish", S.Void,
                      {addr(s.ops[0], "tensor-map address"), addr(s.ops[1], "shared")});
      });
      return;
    }
    if (sw("fence.proxy.tensormap::generic.")) {
      const bool acquire = sw("fence.proxy.tensormap::generic.acquire.");
      if ((!acquire && !sw("fence.proxy.tensormap::generic.release.")) || s.tok.size() != 5)
        fail("unsupported tensor-map proxy operation");
      if (!tensorMapScope(s.tok[4])) fail("unsupported tensor-map proxy scope");
      nops(acquire ? 2 : 0, acquire ? 2 : 0);
      underPred(pred, [&]() -> Value * {
        if (acquire) {
          addr(s.ops[0], "tensor-map address");
          auto *size = dyn_cast<ConstantInt>(val(s.ops[1], S.I64));
          if (!size || !size->equalsInt(128)) fail("tensor-map proxy operation requires immediate size 128");
        }
        return B.CreateFence(acquire ? AtomicOrdering::Acquire : AtomicOrdering::Release);
      });
      return;
    }
    // --- fences and hints
    if (sw("fence.proxy.") || sw("fence.mbarrier_init")) {
      const bool init = o == "fence.mbarrier_init.release.cluster";
      if (!s.ops.empty() || !(init || o == "fence.proxy.async" || o == "fence.proxy.async.global" ||
                             o == "fence.proxy.async.shared::cta" || o == "fence.proxy.async.shared::cluster"))
        fail("unsupported proxy or mbarrier initialization fence: " + s.text);
      underPred(pred, [&]() -> Value * {
        // Order the issuing thread's accesses before DXA/TCU can consume the data.
        return B.CreateFence(init ? AtomicOrdering::Release : AtomicOrdering::SequentiallyConsistent);
      });
      return;
    }
    if (sw("setmaxnreg.") || sw("griddepcontrol.") ||
        sw("prefetch.tensormap") || sw("cp.async.bulk.prefetch") || sw("cp.async.bulk.commit_group") ||
        sw("cp.async.bulk.wait_group")) {
      return; // synchronous software copies: nothing to order beyond the compiler fence
    }
    if (sw("fence.") && o.find(".cluster") != std::string::npos) {
      underPred(pred, [&]() -> Value * {
        B.CreateCall(S.M->getOrInsertFunction("llvm.nvvm.membar.cta", FunctionType::get(S.Void, false)), {});
        return nullptr;
      });
      return;
    }
    if (sw("barrier.cluster.")) {
      underPred(pred,[&]() -> Value * {
        return S.call(B,"__cupbop_cluster_sync",S.Void,{B.getInt32(sw("barrier.cluster.wait") ? 1 : 0)});
      });
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
          if (S.tcgenFunctions.count(F))
            return S.call(B, "__cupbop_tcgen_arrive", S.I64, {P, B.getInt32(1), B.getInt32(0)});
          CallInst *a = S.call(B, kArrive, S.I32, {P, ConstantInt::get(S.I32, 1)});
          S.arrives[F].push_back(a);
          return nullptr;
        });
      }
      // without .noinc: pending count +1 now, -1 when this thread's cp.async complete -- net zero, and
      // lower_cp_async makes the copies synchronous
      return;
    }
    if (sw("cp.reduce.async.bulk")) {
      lowerBulk(idx,pred,true);
      return;
    }
    if (sw("cp.async.bulk")) {
      lowerBulk(idx, pred);
      return;
    }
    fail("unsupported statement in async asm: `" + s.text + "`");
  }

  void lowerTcgen(const Stmt &s, Value *pred) {
    needWarps();
    const bool pair = s.has("cta_group::2");
    if (pair && (!vortexConfigHasFlag("-DVX_CFG_EXT_TCU_ENABLE") ||
                 !vortexConfigHasFlag("-DVX_CFG_TCU_TMEM_ENABLE")))
      fail("TCGEN CTA pairs require -DVX_CFG_EXT_TCU_ENABLE and -DVX_CFG_TCU_TMEM_ENABLE");
    auto taddr = [&](const std::string &op) -> Value * {
      if (op.size() < 3 || op.front() != '[' || op.back() != ']') fail("expected [tmem address]");
      return val(op.substr(1, op.size() - 2), S.I32);
    };
    if (s.op == "tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32" ||
        s.op == "tcgen05.alloc.cta_group::2.sync.aligned.shared::cta.b32" ||
        s.op == "tcgen05.dealloc.cta_group::1.sync.aligned.b32" ||
        s.op == "tcgen05.dealloc.cta_group::2.sync.aligned.b32") {
      if (pred || s.ops.size() != 2) fail("unsupported predicated or malformed TCGEN allocation");
      auto *cols = dyn_cast<ConstantInt>(val(s.ops[1], S.I32));
      if (!cols || cols->getZExtValue() != 512) fail("only full 512-column TMEM allocations are supported");
      if (s.tok[1] == "alloc")
        S.call(B, pair ? "__cupbop_tmem_alloc512_pair" : "__cupbop_tmem_alloc512", S.Void,
               {addr(s.ops[0], "TMEM allocation result")});
      else
        S.call(B, pair ? "__cupbop_tmem_free512_pair" : "__cupbop_tmem_free512", S.Void, {val(s.ops[0], S.I32)});
      return;
    }
    if (s.op == "tcgen05.relinquish_alloc_permit.cta_group::1.sync.aligned" ||
        s.op == "tcgen05.relinquish_alloc_permit.cta_group::2.sync.aligned" ||
        s.op == "tcgen05.wait::ld.sync.aligned" || s.op == "tcgen05.fence::before_thread_sync" ||
        s.op == "tcgen05.fence::after_thread_sync") {
      if (pred || !s.ops.empty()) fail("malformed TCGEN synchronization");
      // Each CTA occupies a full slot; loads retire synchronously.
      B.CreateFence(AtomicOrdering::SequentiallyConsistent);
      return;
    }
    if (s.op == "tcgen05.mma.cta_group::1.kind::i8" || s.op == "tcgen05.mma.cta_group::2.kind::i8") {
      if (s.ops.size() != 5) fail("expected dense SMEM/SMEM i8 MMA");
      auto *desc = dyn_cast<ConstantInt>(val(s.ops[3], S.I32));
      if (!desc || desc->getZExtValue() != (pair ? 0x104004a0u : 0x084004a0u))
        fail("unsupported i8 MMA instruction descriptor");
      underPred(pred, [&]() -> Value * {
        return S.call(B, pair ? "__cupbop_tmem_mma_s8_256x256x32" : "__cupbop_tmem_mma_s8_128x256x32", S.Void,
                      {taddr(s.ops[0]), val(s.ops[1], S.I64), val(s.ops[2], S.I64), val(s.ops[4], S.I32)});
      });
      return;
    }
    if (s.op == "tcgen05.ld.sync.aligned.32x32b.x2.b32" || s.op == "tcgen05.ld.sync.aligned.32x32b.x4.b32") {
      if (pred || s.ops.size() != 2 || s.ops[0].front() != '{' || s.ops[0].back() != '}')
        fail("expected unpredicated TCGEN register tuple load");
      auto dst = splitTop(s.ops[0].substr(1, s.ops[0].size() - 2), ',');
      if (dst.size() != (s.has("x2") ? 2u : 4u)) fail("TCGEN load tuple width mismatch");
      Value *base = taddr(s.ops[1]);
      for (size_t i = 0; i < dst.size(); ++i)
        setReg(dst[i], S.call(B, "__cupbop_tmem_ld32", S.I32, {base, B.getInt32(i)}), nullptr);
      return;
    }
    if (s.op == "tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.multicast::cluster.b64" ||
        s.op == "tcgen05.commit.cta_group::2.mbarrier::arrive::one.shared::cluster.multicast::cluster.b64") {
      if (s.ops.size() != 2) fail("expected TCGEN completion barrier and CTA mask");
      underPred(pred,[&]() -> Value * {
        return S.call(B,"__cupbop_cluster_commit",S.Void,{addr(s.ops[0],"barrier"),val(s.ops[1],S.I32)});
      });
      return;
    }
    if ((s.op == "tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64" ||
         s.op == "tcgen05.commit.cta_group::2.mbarrier::arrive::one.shared::cluster.b64") && s.ops.size() == 1) {
      underPred(pred, [&]() -> Value * {
        B.CreateFence(AtomicOrdering::Release);
        return S.call(B, "__cupbop_tcgen_arrive", S.I64,
                      {addr(s.ops[0], "TCGEN completion barrier"), B.getInt32(1), B.getInt32(0)});
      });
      return;
    }
    fail("unsupported TCGEN form: " + s.text);
  }

  void lowerMbarrier(size_t idx, Value *pred) {
    const Stmt &s = st[idx];
    const std::string what = s.tok.size() > 1 ? s.tok[1] : "";
    if (s.has("shared::cluster") && !S.tcgenFunctions.count(F) && what != "arrive")
      fail("`" + s.op + "` on a shared::cluster address (clusters are not supported)");
    if (S.tcgenFunctions.count(F)) {
      if (what == "init" && s.ops.size() == 2) {
        underPred(pred, [&]() -> Value * {
          return S.call(B, "__cupbop_tcgen_mbar_init", S.Void, {addr(s.ops[0], "barrier"), val(s.ops[1], S.I32)});
        });
        return;
      }
      if ((what == "expect_tx" || what == "complete_tx") && s.ops.size() == 2) {
        underPred(pred, [&]() -> Value * {
          Value *bytes = val(s.ops[1], S.I32);
          if (what == "complete_tx") bytes = B.CreateNeg(bytes);
          return S.call(B, "__cupbop_tcgen_arrive", S.I64, {addr(s.ops[0], "barrier"), B.getInt32(0), bytes});
        });
        return;
      }
      if (what == "arrive" && !s.has("noComplete") &&
          (s.ops.size() == 3 || (s.ops.size() == 2 && !s.has("expect_tx")))) {
        Value *token = underPred(pred, [&]() -> Value * {
          Value *arg = s.ops.size() == 3 ? val(s.ops[2], S.I32) : B.getInt32(1);
          return S.call(B, "__cupbop_tcgen_arrive", S.I64,
                        {addr(s.ops[1], "barrier"), s.has("expect_tx") ? B.getInt32(1) : arg,
                         s.has("expect_tx") ? arg : B.getInt32(0)});
        });
        if (token) setReg(s.ops[0], token, pred);
        return;
      }
      if ((what == "try_wait" || what == "test_wait") && (s.ops.size() == 3 || s.ops.size() == 4)) {
        Value *ok = underPred(pred, [&]() -> Value * {
          Value *phase =
              s.has("parity") ? val(s.ops[2], S.I32) : B.CreateTrunc(B.CreateLShr(val(s.ops[2], S.I64), 63), S.I32);
          return S.call(B, "__cupbop_tcgen_wait", S.I32,
                        {addr(s.ops[1], "barrier"), phase, B.getInt32(blocking.count(idx))});
        });
        if (ok) setReg(s.ops[0], B.CreateICmpNE(ok, B.getInt32(0)), pred);
        return;
      }
      if (what == "inval") return;
      fail("unsupported mbarrier form in TCGEN kernel: " + s.text);
    }
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

  void lowerBulk(size_t idx, Value *pred, bool reduction = false) {
    Stmt s = st[idx];
    unsigned op = ReduceAdd;
    if (reduction) {
      s.tok.erase(s.tok.begin()+1);
      const std::vector<std::string> names = {"add","min","max","inc","dec","and","or","xor"};
      auto it = std::find_if(names.begin(),names.end(),[&](const auto &name){return s.has(name);});
      if (it == names.end()) fail("unknown bulk reduction operation");
      op = it - names.begin();
    }
    needWarps();
    for (const char *bad : {"cta_group::1", "cta_group::2", "cp_mask", "im2col", "im2col::w",
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
        if (ops.size() != (s.has("multicast::cluster") ? 4 : 3)) fail("invalid tensor-load operand count");
        underPred(pred, [&]() -> Value * {
          Value *dst = addr(ops[0], "shared destination");
          Value *desc = nullptr;
          std::vector<Value *> c = coords(ops[1], desc);
          Value *mb = addr(ops[2], "mbarrier"); // DXA mode completes the transfer there; software mode ignores it
          if (s.has("multicast::cluster"))
            return S.call(B,"__cupbop_tma_multicast",S.Void,{dst,desc,mb,B.getInt32(rank),c[0],c[1],c[2],c[3],c[4],val(ops[3],S.I32)});
          bool tcgen = S.tcgenFunctions.count(F);
          CallInst *k = S.call(B, tcgen ? "__cupbop_tcgen_tma_load" : kTmaLoad, S.Void,
                               {dst, desc, mb, ConstantInt::get(S.I32, rank), c[0], c[1], c[2], c[3], c[4]}, false);
          if (!tcgen) S.txCopies.insert(k);
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
          if (reduction)
            return S.call(B,"__cupbop_tensor_reduce",S.Void,{desc,src,B.getInt32(rank),c[0],c[1],c[2],c[3],c[4],B.getInt32(op)});
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
    if (reduction) {
      const bool remote = s.has("shared::cluster") && s.has("mbarrier::complete_tx::bytes");
      if (!(remote || (s.has("global") && s.has("bulk_group"))) || !s.has("shared::cta") ||
          ops.size() != (remote ? 4 : 3)) fail("invalid bulk reduction direction or operands");
      const std::map<std::string,unsigned> types = {{"b32",2},{"u32",2},{"s32",3},{"b64",4},{"u64",4},
          {"s64",5},{"f16",6},{"f32",7},{"f64",8},{"bf16",9}};
      auto ty = types.find(s.tok.back());
      if (ty == types.end()) fail("unsupported bulk reduction type");
      underPred(pred,[&]() -> Value * {
        auto *size = val(ops[2],S.I32);
        S.call(B,"__cupbop_bulk_reduce",S.Void,{addr(ops[0],remote?"shared destination":"global destination"),
               addr(ops[1],"shared source"),size,B.getInt32(ty->second),B.getInt32(op)});
        if (remote) S.call(B,"__cupbop_tcgen_arrive",S.I64,{addr(ops[3],"barrier"),B.getInt32(0),B.CreateNeg(size)});
        return nullptr;
      });
      return;
    }
    if (g2s || s2s) {
      if (!s.has("mbarrier::complete_tx::bytes")) fail("`" + s.op + "`: expected mbarrier::complete_tx::bytes");
      const bool multicast = s.has("multicast::cluster");
      if (ops.size() != (multicast ? 5 : 4)) fail("invalid bulk copy operand count");
      underPred(pred, [&]() -> Value * {
        Value *dst = addr(ops[0], "shared destination");
        Value *src = addr(ops[1], "source");
        Value *n = val(ops[2], S.I32);
        if (multicast)
          return S.call(B,"__cupbop_bulk_multicast",S.Void,{dst,src,n,addr(ops[3],"completion barrier"),val(ops[4],S.I32)});
        CallInst *k = S.call(B, kBulk, S.Void, {dst, src, n}, false);
        if (S.tcgenFunctions.count(F))
          S.call(B, "__cupbop_tcgen_arrive", S.I64,
                 {addr(ops[3], "completion barrier"), B.getInt32(0), B.CreateNeg(n)});
        else
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

  // `cvta.param` exposes a position in the CUDA parameter bank. NVCC can reach other arguments by
  // adding an offset to that position, even if the lifted program has no explicit loads from param_local.
  Value *paramAddress(const std::string &sym) {
    size_t p = sym.rfind("_param_");
    std::string fname = sym.substr(0, p);
    unsigned n = std::atoi(sym.c_str() + p + 7);
    if (fname != F->getName() && fname != F->getName().str().substr(F->getName().starts_with("__src_") ? 6 : 0))
      fail("cvta.param of another function's parameter (" + sym + ")");
    if (n >= F->arg_size()) fail("cvta.param of a parameter the function does not have (" + sym + ")");
    Argument *A = F->getArg(n);
    IRBuilder<> EB(&*F->getEntryBlock().getFirstInsertionPt());
    StringRef name = A->getName();
    unsigned off;
    if (!name.consume_front("arg_") || name.getAsInteger(10, off)) {
      AllocaInst *one = EB.CreateAlloca(A->getType(), nullptr, "param_img");
      one->setAlignment(Align(64));
      EB.CreateStore(A, one);
      return one;
    }
    auto &[img, base] = S.paramImages[F];
    if (!img) {
      const DataLayout &DL = S.M->getDataLayout();
      std::vector<unsigned> offsets;
      unsigned first = UINT32_MAX;
      uint64_t end = 0;
      for (Argument &arg : F->args()) {
        StringRef word = arg.getName();
        unsigned offset;
        if (!word.consume_front("arg_") || word.getAsInteger(10, offset))
          fail("cvta.param requires an offset for every lifted kernel parameter");
        first = std::min(first, offset);
        end = std::max(end, offset + DL.getTypeStoreSize(arg.getType()).getFixedValue());
        offsets.push_back(offset);
      }
      base = first & ~63u;
      img = EB.CreateAlloca(ArrayType::get(EB.getInt8Ty(), end - base), nullptr, "param_bank");
      img->setAlignment(Align(64));
      for (Argument &arg : F->args()) {
        Value *dst = EB.CreateConstGEP1_64(EB.getInt8Ty(), img, offsets[arg.getArgNo()] - base);
        EB.CreateAlignedStore(&arg, dst, Align(1));
      }
    }
    return B.CreateConstGEP1_64(B.getInt8Ty(), img, off - base, "param_addr");
  }
};

// ---------------------------------------------------------------------------------------------------------
// NVVM intrinsics

static bool isOrdinaryTmaLoad(const CallInst &C) {
  const Function *F = C.getCalledFunction();
  if (!F || C.arg_size() < 2 || !F->getName().starts_with("llvm.nvvm.cp.async.bulk.tensor.g2s.tile.")) return false;
  // The tile intrinsics end with the constant `has multicast` and `has cache hint` flags.
  const auto *multicast = dyn_cast<ConstantInt>(C.getArgOperand(C.arg_size() - 2));
  return multicast && multicast->isZero();
}

// Use the hardware-mbarrier ABI only for a structured load paired with an earlier local arrive in
// the same producer block. Split byte accounting and other patterns keep the existing software ABI.
static bool hasLocalTmaArrive(const CallInst &C, const DataLayout &DL) {
  int64_t loadOffset = 0;
  const Value *loadBar = GetPointerBaseWithConstantOffset(C.getArgOperand(1), loadOffset, DL);
  for (const Instruction *I = C.getPrevNonDebugInstruction(); I; I = I->getPrevNonDebugInstruction()) {
    const auto *A = dyn_cast<CallInst>(I);
    if (!A) {
      if (I->mayHaveSideEffects()) return false;
      continue;
    }
    if (isOrdinaryTmaLoad(*A)) continue;
    const auto *assembly = dyn_cast<InlineAsm>(A->getCalledOperand());
    if (!assembly || !A->getType()->isVoidTy()) return false;
    std::vector<Stmt> statements;
    std::string error;
    if (!parsePtx(assembly->getAsmString(), statements, error) || statements.size() != 1) return false;
    const Stmt &s = statements.front();
    if (!s.label.empty() || !s.pred.empty() || s.op.rfind("mbarrier.arrive.", 0) != 0 ||
        !s.has("expect_tx") || !s.has("shared::cta") || s.ops.size() != 3 || s.ops[0] != "_")
      return false;
    StringRef operand(s.ops[1]);
    if (!operand.consume_front("[$") || !operand.consume_back("]")) return false;
    unsigned index;
    if (operand.getAsInteger(10, index) || index >= A->arg_size()) return false;
    Value *bar = A->getArgOperand(index);
    if (!bar->getType()->isPointerTy()) bar = cupbop_trace_pointer(bar);
    if (!bar || !bar->getType()->isPointerTy()) return false;
    int64_t arriveOffset = 0;
    return GetPointerBaseWithConstantOffset(bar, arriveOffset, DL) == loadBar && arriveOffset == loadOffset;
  }
  return false;
}

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
  if (n.starts_with("llvm.nvvm.mapa")) {
    Value *mapped = S.call(B,"__cupbop_cluster_map",S.Ptr,{P(0),C->getArgOperand(1)});
    return done(B.CreatePointerCast(mapped,C->getType()));
  }
  if (n == "llvm.nvvm.isspacep.shared" || n == "llvm.nvvm.isspacep.global") {
    auto *object = getUnderlyingObject(C->getArgOperand(0));
    if (isa<AllocaInst>(object)) return done(B.getFalse());
    if (auto *global = dyn_cast<GlobalVariable>(object)) {
      unsigned space = global->getAddressSpace();
      if (space == 1 || space == 3 || space == 4)
        return done(B.getInt1(n.ends_with(".shared") ? space == 3 : space == 1));
    }
    return done(S.call(B, n.ends_with(".shared") ? "__cupbop_is_cta_shared" : "__cupbop_is_global",
                       S.I32, {P(0)}));
  }
  if (n == "llvm.nvvm.match.any.sync.i32" || n == "llvm.nvvm.match.any.sync.i64") {
    S.needWarps.insert(F);
    return done(S.call(B, "__cupbop_match_any", S.I32,
                       {C->getArgOperand(0), B.CreateZExtOrTrunc(C->getArgOperand(1), S.I64)}));
  }
  if (n == "llvm.nvvm.isspacep.shared.cluster")
    return done(S.call(B,"__cupbop_cluster_contains",S.I32,{P(0)}));
  if (n.starts_with("llvm.nvvm.getctarank"))
    return done(S.call(B,"__cupbop_cluster_query_rank",S.I32,{P(0)}));
  if (n == "llvm.nvvm.is_explicit_cluster")
    return done(clusterRegister(S,B,"is_explicit_cluster"));
  if (n == "llvm.nvvm.read.ptx.sreg.smid") return done(S.call(B, "__cupbop_smid", S.I32, {}));
  if (n.starts_with("llvm.nvvm.read.ptx.sreg.cluster") || n.starts_with("llvm.nvvm.read.ptx.sreg.nclusterid") ||
      n.starts_with("llvm.nvvm.read.ptx.sreg.is.explicit.cluster"))
    return done(clusterRegister(S,B,n));
  if (S.tcgenFunctions.count(F) && n.starts_with("llvm.nvvm.mbarrier.")) {
    auto *zero = B.getInt32(0);
    if (n.starts_with("llvm.nvvm.mbarrier.init")) {
      S.call(B, "__cupbop_tcgen_mbar_init", S.Void, {P(0), C->getArgOperand(1)});
      return done(nullptr);
    }
    if (n.starts_with("llvm.nvvm.mbarrier.inval")) return done(nullptr);
    if (n == "llvm.nvvm.mbarrier.arrive" || n == "llvm.nvvm.mbarrier.arrive.shared")
      return done(S.call(B, "__cupbop_tcgen_arrive", S.I64, {P(0), B.getInt32(1), zero}));
    if (n == "llvm.nvvm.mbarrier.test.wait" || n == "llvm.nvvm.mbarrier.test.wait.shared") {
      Value *phase = B.CreateTrunc(B.CreateLShr(C->getArgOperand(1), 63), S.I32);
      return done(B.CreateICmpNE(S.call(B, "__cupbop_tcgen_wait", S.I32, {P(0), phase, zero}), zero));
    }
    fail_at(C, "unsupported mbarrier intrinsic in a TCGEN kernel: " + n.str());
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
    if (n.contains("noinc") && S.tcgenFunctions.count(F)) {
      S.call(B, "__cupbop_tcgen_arrive", S.I64, {P(0), B.getInt32(1), B.getInt32(0)});
      return done(nullptr);
    }
    if (n.contains("noinc")) {
      S.needWarps.insert(F);
      CallInst *a = S.call(B, kArrive, S.I32, {P(0), ConstantInt::get(S.I32, 1)});
      S.arrives[F].push_back(a);
    }
    return done(nullptr);
  }
  StringRef fence = n;
  if (fence.consume_front("llvm.nvvm.fence.proxy.tensormap_generic.")) {
    const bool acquire = fence.consume_front("acquire.");
    if ((!acquire && !fence.consume_front("release.")) || !tensorMapScope(fence) ||
        C->arg_size() != (acquire ? 2u : 0u))
      fail_at(C, "unsupported tensor-map proxy intrinsic");
    if (acquire) {
      auto *size = dyn_cast<ConstantInt>(C->getArgOperand(1));
      if (!size || !size->equalsInt(128)) fail_at(C, "tensor-map proxy operation requires immediate size 128");
    }
    return done(B.CreateFence(acquire ? AtomicOrdering::Acquire : AtomicOrdering::Release));
  }
  if (n == "llvm.nvvm.cp.async.bulk.commit.group" || n.starts_with("llvm.nvvm.cp.async.bulk.wait.group") ||
      n.starts_with("llvm.nvvm.cp.async.bulk.prefetch") || n.starts_with("llvm.nvvm.cp.async.bulk.tensor.prefetch") ||
      n.starts_with("llvm.nvvm.fence.proxy") || n.starts_with("llvm.nvvm.setmaxnreg") ||
      n.starts_with("llvm.nvvm.griddepcontrol") || n.starts_with("llvm.nvvm.prefetch.tensormap")) {
    B.CreateFence(AtomicOrdering::SequentiallyConsistent, SyncScope::SingleThread);
    return done(nullptr);
  }
  if (n.starts_with("llvm.nvvm.fence.") && n.ends_with(".cluster")) {
    B.CreateFence(AtomicOrdering::SequentiallyConsistent);
    return done(nullptr);
  }
  if (n == "llvm.nvvm.cp.async.bulk.global.to.shared.cluster" ||
      n == "llvm.nvvm.cp.async.bulk.shared.cta.to.cluster") {
    S.needWarps.insert(F);
    Value *bytes = C->getArgOperand(3);
    const bool multicast = C->arg_size() == 8 && !cast<ConstantInt>(C->getArgOperand(6))->isZero();
    if (multicast)
      S.call(B,"__cupbop_bulk_multicast",S.Void,{P(0),P(2),bytes,P(1),B.CreateZExt(C->getArgOperand(4),S.I32)});
    else {
      S.call(B,kBulk,S.Void,{P(0),P(2),bytes});
      S.call(B,"__cupbop_tcgen_arrive",S.I64,{P(1),B.getInt32(0),B.CreateNeg(bytes)});
    }
    return done(nullptr);
  }
  if (n == "llvm.nvvm.cp.async.bulk.shared.cta.to.global") {
    S.call(B,kBulk,S.Void,{P(0),P(1),C->getArgOperand(2)});
    return done(nullptr);
  }
  if (n.starts_with("llvm.nvvm.cp.async.bulk.tensor.") && n.contains(".tile.")) {
    S.needWarps.insert(F);
    bool load = n.contains(".g2s.");
    unsigned rank = n.rsplit('.').second.front() - '0';
    SmallVector<Value *,10> args;
    if (load) args = {P(0),P(2),P(1)};
    else args = {P(1),P(0)};
    args.push_back(B.getInt32(rank));
    for (unsigned d=0; d<5; ++d)
      args.push_back(d < rank ? C->getArgOperand((load ? 3 : 2) + d) : B.getInt32(0));
    if (load) {
      bool multicast = !cast<ConstantInt>(C->getArgOperand(rank+5))->isZero();
      if (multicast) args.push_back(B.CreateZExt(C->getArgOperand(rank+3),S.I32));
      if (multicast)
        S.call(B, "__cupbop_tma_multicast", S.Void, args);
      else if (S.tcgenFunctions.count(F))
        S.call(B, "__cupbop_tcgen_tma_load", S.Void, args);
      else
        S.txCopies.insert(S.call(B, kTmaLoad, S.Void, args, false));
    } else if (n.contains(".reduce.")) {
      StringRef op = n.split(".reduce.").second.split('.').first;
      static const StringRef names[] = {"add","min","max","inc","dec","and","or","xor"};
      auto id = llvm::find(names,op) - std::begin(names);
      if (id == std::size(names)) fail_at(C,"unknown tensor reduction operation");
      args.push_back(B.getInt32(id));
      S.call(B,"__cupbop_tensor_reduce",S.Void,args);
    } else S.call(B,kTmaStore,S.Void,args);
    return done(nullptr);
  }
  if (n.starts_with("llvm.nvvm.barrier.cluster.")) {
    S.call(B,"__cupbop_cluster_sync",S.Void,{B.getInt32(n.contains("wait") ? 1 : 0)});
    return done(nullptr);
  }
  if (n == "llvm.nvvm.elect.sync") {
    // { i32 leader lane, i1 is this lane the leader } (Triton's TMA issue from capability 90): the helpers of the asm form,
    // the lane only where a user reads it
    S.needWarps.insert(F);
    auto *ST = dyn_cast<StructType>(C->getType());
    if (!ST || ST->getNumElements() != 2) fail_at(C, "llvm.nvvm.elect.sync of an unexpected type");
    Value *mask = B.CreateZExtOrTrunc(C->getArgOperand(0), S.I32);
    Value *p = B.CreateICmpNE(S.call(B, kElect, S.I32, {mask}), ConstantInt::get(S.I32, 0), "elected");
    Value *lane = nullptr;
    auto laneOf = [&]() { return lane ? lane : (lane = S.call(B, kElectLane, S.I32, {mask})); };
    for (User *U : make_early_inc_range(C->users())) {
      auto *E = dyn_cast<ExtractValueInst>(U);
      if (!E || E->getNumIndices() != 1) continue;
      E->replaceAllUsesWith(E->getIndices()[0] == 0 ? laneOf() : p);
      E->eraseFromParent();
    }
    Value *r = nullptr;
    if (!C->use_empty())
      r = B.CreateInsertValue(B.CreateInsertValue(UndefValue::get(ST), laneOf(), {0}), p, {1});
    return done(r);
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

// Separate transaction queues let multiple stages register copies in the
// same elected-lane region before the warp reconverges and submits them.
Value *txQueue(PassState &S, Function *F) {
  IRBuilder<> EB(&*F->getEntryBlock().getFirstInsertionPt());
  AllocaInst *AI = EB.CreateAlloca(ArrayType::get(EB.getInt8Ty(), kTxqN * kTxqEntrySize), nullptr, "cupbop_txq");
  AI->setAlignment(Align(8));
  // The core-mapping passes expect the entry block's allocas contiguous. Initialize
  // each entry's byte count and valid flag after them; the copy writes the rest.
  Instruction *firstNonAlloca = &*F->getEntryBlock().getFirstInsertionPt();
  while (isa<AllocaInst>(firstNonAlloca)) firstNonAlloca = firstNonAlloca->getNextNode();
  IRBuilder<> IB(firstNonAlloca);
  for (unsigned j = 0; j < kTxqN; ++j)
    for (unsigned off : {12u, 16u})
      IB.CreateAlignedStore(IB.getInt32(0), IB.CreateConstGEP1_32(IB.getInt8Ty(), AI, kTxqEntrySize * j + off), Align(4));
  return AI;
}

// CUPBOP_TMA_STATIC=0: no slot read at the entry and no barrier number from the translator (the queued loads read both
// from their records at the copy, as the first indexed-queue form did)
bool tmaStatic() {
  const char *e = std::getenv("CUPBOP_TMA_STATIC");
  return !e || std::atoi(e) != 0;
}

// A by-value tensor map keeps its launch-time slot. A descriptor reached
// through a pointer may be published during the kernel, so read it at the copy.
// The core mapping would carry an entry value through every thread's context.
Value *tmaSlot(PassState &S, CallInst *Cp) {
  Function *F = Cp->getFunction();
  Value *desc = Cp->getArgOperand(1), *rank = Cp->getArgOperand(3);
  auto *arg = dyn_cast<Argument>(desc);
  if (tmaStatic() && schedule() == 2 && arg && arg->hasByValAttr() && isa<ConstantInt>(rank)) {
    Value *&V = S.slots[{F, desc}];
    if (!V) {
      Instruction *IP = &*F->getEntryBlock().getFirstInsertionPt();
      while (isa<AllocaInst>(IP)) IP = IP->getNextNode();
      IRBuilder<> EB(IP);
      V = S.call(EB, kTmaSlot, S.I32, {desc, rank}, false);
    }
    return V;
  }
  IRBuilder<> CB(Cp);
  return S.call(CB, kTmaSlot, S.I32, {desc, rank}, false);
}

// The TMA loads among the copies of one moved arrive queue their DXA issue: the j-th becomes __cupbop_tma_load_qi(Q, j, ...).
// Returns K, one past the highest entry these copies use, which the arrive issues. A copy already queued for another arrive (whose
// copies these are too) keeps its entry. Constant entries: after inlining, SROA keeps the queue in registers.
unsigned queueCopies(PassState &S, Function *F, std::vector<CallInst *> &copies, Value *&Q) {
  unsigned K = 0;
  for (CallInst *Cp : copies)
    if (Cp->getCalledFunction() && Cp->getCalledFunction()->getName() == kTmaLoadQi) {
      Value *oldQueue = Cp->getArgOperand(0);
      if (Q && Q != oldQueue) fail_at(Cp, "TMA copies shared by disjoint mbarrier transactions");
      Q = oldQueue;
      const uint64_t j = cast<ConstantInt>(Cp->getArgOperand(1))->getZExtValue();
      K = std::max<unsigned>(K, j + 1);
    }
  for (CallInst *&Cp : copies) {
    if (!Cp->getCalledFunction() || Cp->getCalledFunction()->getName() != kTmaLoad) continue;
    if (!Q) Q = txQueue(S, F);
    Value *slot = tmaSlot(S, Cp);
    IRBuilder<> CB(Cp);
    // the barrier number: kIdPlaceholder until finalize_mbarrier_ids knows it
    std::vector<Value *> args{Q, ConstantInt::get(S.I32, K++), ConstantInt::get(S.I32, kIdPlaceholder), slot};
    for (auto &U : Cp->args()) args.push_back(U.get());
    CallInst *N = S.call(CB, kTmaLoadQi, S.Void, args, true);
    S.txCopies.erase(Cp);
    S.txCopies.insert(N);
    S.orderedCopies.erase(Cp);
    S.orderedCopies.insert(N);
    Cp->eraseFromParent();
    Cp = N;
  }
  return K;
}

void checkTmaBytes(PassState &S, IRBuilder<> &B, Value *Q, unsigned K, Value *bar, Value *bytes,
                   const std::vector<CallInst *> &copies) {
  const bool counted = bytes && K <= kTxqN &&
      std::all_of(copies.begin(), copies.end(), [](CallInst *C) {
        return C->getCalledFunction() && C->getCalledFunction()->getName() == kTmaLoadQi;
      });
  S.call(B, kTxqCheck, S.Void,
         {Q, B.getInt32(std::min<unsigned>(K, kTxqN)), bar, counted ? bytes : B.getInt32(0), B.getInt32(counted)});
}

// ---- which threads of the block can satisfy a predicate (the arrive of Triton's TMA issue and its copies)
//
// A value for one thread t of a 1-D block: a known integer, or `uniform` (the same, unknown, value for every thread of the block:
// arguments, block ids, and what is computed from them). The thread id is t, the lane t % 32, and elect.sync of the whole warp lane 0:
// PTX requires every lane of membermask to execute it together, and of a full warp the helper elects the lowest lane.
struct ThreadValue {
  bool known = false;
  APInt v;
};

// UA: allocas known to hold the same value in every thread (uniformAllocas); a load from one is uniform.
bool isUniformValue(Value *V, std::set<Value *> &visiting, LoopInfo &LI, const std::set<AllocaInst *> *UA = nullptr) {
  if (isa<Constant>(V) || isa<Argument>(V)) return true;
  auto *I = dyn_cast<Instruction>(V);
  if (!I || !visiting.insert(V).second) return I != nullptr; // a cycle through loop-header phis: optimistic
  if (auto *C = dyn_cast<CallInst>(I)) {
    Function *Fn = C->getCalledFunction();
    if (!Fn) return false;
    StringRef n = Fn->getName();
    return n.starts_with("llvm.nvvm.read.ptx.sreg.ctaid.") || n.starts_with("llvm.nvvm.read.ptx.sreg.nctaid.") ||
           n.starts_with("llvm.nvvm.read.ptx.sreg.ntid.");
  }
  if (auto *L = dyn_cast<LoadInst>(I))
    if (UA && L->isSimple())
      if (auto *A = dyn_cast<AllocaInst>(getUnderlyingObject(L->getPointerOperand())))
        if (UA->count(A)) return true;
  if (isa<LoadInst>(I) || isa<AllocaInst>(I) || I->mayHaveSideEffects()) return false;
  if (auto *P = dyn_cast<PHINode>(I)) { // a loop header's: the iteration all threads of the block are in
    Loop *L = LI.getLoopFor(P->getParent());
    if (!L || L->getHeader() != P->getParent()) return false;
  }
  for (Value *O : I->operands())
    if (!isa<BasicBlock>(O) && !isUniformValue(O, visiting, LI, UA)) return false;
  return true;
}

std::optional<ThreadValue> valueForThread(Value *V, unsigned t, LoopInfo &LI, int depth = 0) {
  auto known = [](const APInt &x) { ThreadValue r; r.known = true; r.v = x; return std::optional<ThreadValue>(r); };
  auto uniform = []() { ThreadValue r; return std::optional<ThreadValue>(r); };
  if (depth > 48) return std::nullopt;
  if (auto *K = dyn_cast<ConstantInt>(V)) return known(K->getValue());
  if (isa<Argument>(V)) return uniform();
  auto *I = dyn_cast<Instruction>(V);
  if (!I || !V->getType()->isIntegerTy()) return std::nullopt;
  const unsigned bits = V->getType()->getIntegerBitWidth();
  if (auto *C = dyn_cast<CallInst>(I)) {
    Function *Fn = C->getCalledFunction();
    StringRef n = Fn ? Fn->getName() : "";
    if (n == "llvm.nvvm.read.ptx.sreg.tid.x") return known(APInt(bits, t));
    if (n == "llvm.nvvm.read.ptx.sreg.laneid") return known(APInt(bits, t % 32));
    if (n == kElect && C->arg_size() == 1)
      if (auto *M = dyn_cast<ConstantInt>(C->getArgOperand(0)))
        if ((M->getZExtValue() & 0xFFFFFFFFull) == 0xFFFFFFFFull) return known(APInt(bits, t % 32 == 0 ? 1 : 0));
  }
  std::set<Value *> visiting;
  if (!isa<PHINode>(I) && !isa<SelectInst>(I) && isUniformValue(V, visiting, LI)) return uniform();
  if (auto *P = dyn_cast<PHINode>(I)) {
    visiting.clear();
    if (isUniformValue(P, visiting, LI)) return uniform();
    return std::nullopt;
  }
  if (auto *Cst = dyn_cast<CastInst>(I)) {
    auto a = valueForThread(Cst->getOperand(0), t, LI, depth + 1);
    if (!a || !a->known) return a;
    switch (Cst->getOpcode()) {
    case Instruction::ZExt: return known(a->v.zext(bits));
    case Instruction::SExt: return known(a->v.sext(bits));
    case Instruction::Trunc: return known(a->v.trunc(bits));
    default: return std::nullopt;
    }
  }
  if (auto *Sel = dyn_cast<SelectInst>(I)) {
    auto c = valueForThread(Sel->getCondition(), t, LI, depth + 1);
    auto a = valueForThread(Sel->getTrueValue(), t, LI, depth + 1), b = valueForThread(Sel->getFalseValue(), t, LI, depth + 1);
    if (!c || !a || !b) return std::nullopt;
    if (c->known) return c->v.isZero() ? b : a;
    if (a->known && b->known && a->v == b->v) return a;
    return uniform();
  }
  if (auto *Cmp = dyn_cast<ICmpInst>(I)) {
    auto a = valueForThread(Cmp->getOperand(0), t, LI, depth + 1), b = valueForThread(Cmp->getOperand(1), t, LI, depth + 1);
    if (!a || !b) return std::nullopt;
    if (!a->known || !b->known) return uniform();
    return known(APInt(1, ICmpInst::compare(a->v, b->v, Cmp->getPredicate()) ? 1 : 0));
  }
  if (auto *BO = dyn_cast<BinaryOperator>(I)) {
    auto a = valueForThread(BO->getOperand(0), t, LI, depth + 1), b = valueForThread(BO->getOperand(1), t, LI, depth + 1);
    if (!a || !b) return std::nullopt;
    const auto op = BO->getOpcode();
    if (op == Instruction::And && ((a->known && a->v.isZero()) || (b->known && b->v.isZero()))) return known(APInt(bits, 0));
    if (op == Instruction::Or && bits == 1 && ((a->known && a->v.isOne()) || (b->known && b->v.isOne()))) return known(APInt(1, 1));
    if (!a->known || !b->known) return uniform();
    const APInt &x = a->v, &y = b->v;
    switch (op) {
    case Instruction::And: return known(x & y);
    case Instruction::Or: return known(x | y);
    case Instruction::Xor: return known(x ^ y);
    case Instruction::Add: return known(x + y);
    case Instruction::Sub: return known(x - y);
    case Instruction::Mul: return known(x * y);
    case Instruction::Shl: return y.uge(bits) ? std::nullopt : known(x.shl(y));
    case Instruction::LShr: return y.uge(bits) ? std::nullopt : known(x.lshr(y));
    case Instruction::AShr: return y.uge(bits) ? std::nullopt : known(x.ashr(y));
    case Instruction::UDiv: return y.isZero() ? std::nullopt : known(x.udiv(y));
    case Instruction::URem: return y.isZero() ? std::nullopt : known(x.urem(y));
    default: return std::nullopt;
    }
  }
  return std::nullopt;
}

// Threads of the block (1-D, `nvvm.reqntid`) for which `pred` can hold; nullopt when the predicate or the block is not understood.
std::optional<std::vector<unsigned>> threadsOf(Value *pred, Function *F, LoopInfo &LI) {
  Attribute R = F->getFnAttribute("nvvm.reqntid");
  if (!R.isStringAttribute()) return std::nullopt;
  std::vector<std::string> dims = splitTop(R.getValueAsString().str(), ',');
  unsigned n = dims.empty() ? 0 : (unsigned)std::atoi(dims[0].c_str());
  for (size_t i = 1; i < dims.size(); ++i)
    if (std::atoi(dims[i].c_str()) != 1) return std::nullopt;
  if (n == 0 || n > 1024) return std::nullopt;
  std::vector<unsigned> out;
  for (unsigned t = 0; t < n; ++t) {
    auto v = valueForThread(pred, t, LI);
    if (!v) return std::nullopt;
    if (!v->known || !v->v.isZero()) out.push_back(t);
  }
  return out;
}

// The condition under which the then-block of a lowered predicated asm (underPred) runs: its single predecessor's branch.
Value *guardOf(BasicBlock *BB) {
  BasicBlock *H = BB->getSinglePredecessor();
  auto *Br = H ? dyn_cast<BranchInst>(H->getTerminator()) : nullptr;
  if (!Br || !Br->isConditional() || Br->getSuccessor(0) != BB || Br->getSuccessor(1) == BB) return nullptr;
  return Br->getCondition();
}

// ---- where the DXA issue of a moved arrive's queued copies runs
//
// The DXA takes its operands packed in lanes 0-3 of x31 (x30), which WGATHER writes in every non-source lane whether the
// lane is active or not (vortex vx_intrinsics.h, SimX alu_unit). The compiler reserves neither register once the runtime
// helpers are inlined into a kernel, and keeps other values there; under the partial thread mask of the elected thread's
// region, a WGATHER would clobber the inactive lanes' copies (schedule 1 + DXA + num_stages >= 2: a misaligned store,
// experiments/s1dxa). So the issue (__cupbop_txq_issue) runs after the region, where the warp is converged and every lane
// executes it, as the compiler's per-lane model assumes. The point: out of every region whose branch is not uniform
// (isUniformValue), in the arrive's loop, with no wait and no other queue access (a TMA load, an arrive, an issue) on the
// way from the arrive. nullptr (why) when there is none.
Instruction *convergedIssuePoint(PassState &S, Function *F, CallInst *Ar, std::string &why) {
  // a device function may be called under a partial mask: only a kernel's entry has the whole warp
  if (!isKernelFunction(F->getParent(), F)) { why = "the arrive is in a device function, not a kernel"; return nullptr; }
  DominatorTree DT(*F);
  PostDominatorTree PDT(*F);
  LoopInfo LI(DT);
  // the branches a block is control dependent on: the block post-dominates one of the branch's successors, not the branch
  std::map<BasicBlock *, std::vector<BasicBlock *>> cdMemo;
  auto cd = [&](BasicBlock *B) -> const std::vector<BasicBlock *> & {
    auto it = cdMemo.find(B);
    if (it != cdMemo.end()) return it->second;
    std::vector<BasicBlock *> &v = cdMemo[B];
    for (BasicBlock &X : *F) {
      Instruction *T = X.getTerminator();
      if (!T || T->getNumSuccessors() < 2 || PDT.dominates(B, &X)) continue;
      for (BasicBlock *Sc : successors(&X))
        if (PDT.dominates(B, Sc)) { v.push_back(&X); break; }
    }
    return v;
  };
  // Loop counters and parameters live in allocas. CuLifter copies parameters
  // into a byte array and accesses them through fixed offsets. Track those
  // addresses as well as scalar slots, and require uniform values and control
  // for every store to an alloca before treating its loads as uniform.
  std::set<AllocaInst *> UA;
  std::map<AllocaInst *, SmallVector<StoreInst *, 4>> stores;
  for (Instruction &I : F->getEntryBlock()) {
    auto *A = dyn_cast<AllocaInst>(&I);
    if (!A) continue;
    bool ok = true;
    SmallVector<Value *, 4> pointers{A};
    while (ok && !pointers.empty()) {
      Value *pointer = pointers.pop_back_val();
      for (User *U : pointer->users()) {
        if (auto *L = dyn_cast<LoadInst>(U)) {
          ok &= L->getPointerOperand() == pointer && L->isSimple();
        } else if (auto *St = dyn_cast<StoreInst>(U)) {
          ok &= St->getPointerOperand() == pointer && St->getValueOperand() != pointer && St->isSimple();
          stores[A].push_back(St);
        } else if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
          ok &= GEP->getPointerOperand() == pointer && GEP->hasAllConstantIndices();
          pointers.push_back(GEP);
        } else if (auto *II = dyn_cast<IntrinsicInst>(U)) {
          ok &= II->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(II);
        } else {
          ok = false;
        }
      }
    }
    if (ok) UA.insert(A);
  }
  auto branchUniform = [&](BasicBlock *X) {
    Instruction *T = X->getTerminator();
    Value *c = nullptr;
    if (auto *Br = dyn_cast<BranchInst>(T)) c = Br->getCondition();
    else if (auto *Sw = dyn_cast<SwitchInst>(T)) c = Sw->getCondition();
    std::set<Value *> visiting;
    return c && isUniformValue(c, visiting, LI, &UA);
  };
  // a non-uniform branch B is control dependent on, directly or through uniform branches (whose blocks may themselves lie
  // in a non-uniform region: `if (tid == 0 && c)` is a uniform `c` under `tid == 0`)
  auto divergentBranch = [&](BasicBlock *B) -> BasicBlock * {
    std::set<BasicBlock *> seenX;
    std::vector<BasicBlock *> st{B};
    while (!st.empty()) {
      BasicBlock *Y = st.back();
      st.pop_back();
      for (BasicBlock *X : cd(Y)) {
        if (!seenX.insert(X).second) continue;
        if (!branchUniform(X)) return X;
        st.push_back(X);
      }
    }
    return nullptr;
  };
  for (bool changed = true; changed;) {
    changed = false;
    for (auto it = UA.begin(); it != UA.end();) {
      bool ok = true;
      for (StoreInst *St : stores[*it]) {
        std::set<Value *> visiting;
        if (!isUniformValue(St->getValueOperand(), visiting, LI, &UA) || divergentBranch(St->getParent())) {
          ok = false;
          break;
        }
      }
      if (ok) { ++it; continue; }
      it = UA.erase(it);
      changed = true;
    }
  }
  Loop *L0 = LI.getLoopFor(Ar->getParent());
  BasicBlock *P = Ar->getParent();
  bool moved = false;
  for (int guard = 0;; ++guard) {
    if (guard > 1024) { why = "internal: no fixpoint"; return nullptr; }
    // a branch whose condition may differ between the lanes decides whether P runs: some lanes may be off at P
    BasicBlock *D = divergentBranch(P);
    if (!D) break;
    if (std::getenv("CUPBOP_TMA_ISSUE_DEBUG")) {
      std::string t;
      raw_string_ostream os(t);
      os << "[CuPBoP] issue point: " << P->getName() << " depends on " << D->getName() << ": " << *D->getTerminator();
      fprintf(stderr, "%s\n", os.str().c_str());
    }
    DomTreeNode *N = PDT.getNode(D);
    BasicBlock *J = N && N->getIDom() ? N->getIDom()->getBlock() : nullptr;
    if (!J) { why = "a non-uniform region around the arrive does not join before the function's end"; return nullptr; }
    if (LI.getLoopFor(J) != L0) { why = "a non-uniform region around the arrive ends outside the arrive's loop"; return nullptr; }
    P = J;
    moved = true;
  }
  Instruction *IP = moved ? &*P->getFirstInsertionPt() : Ar->getNextNode();
  if (moved) {
    auto &anchor = S.txqIssueAnchors[P];
    if (Value *original = anchor) IP = cast<Instruction>(original);
    else anchor = IP;
  }
  std::set<Function *> visiting;
  std::set<BasicBlock *> seen;
  std::vector<std::pair<BasicBlock *, Instruction *>> w{{Ar->getParent(), Ar->getNextNode()}};
  while (!w.empty()) {
    auto [BB, from] = w.back();
    w.pop_back();
    bool stop = false;
    for (Instruction *I = from; I; I = I->getNextNode()) {
      if (I == IP) { stop = true; break; }
      auto *C = dyn_cast<CallInst>(I);
      if (!C) continue;
      visiting.clear();
      if (isWaitLike(C, visiting)) { why = "a wait lies between the arrive and the end of its region"; return nullptr; }
    }
    if (stop) continue;
    for (BasicBlock *Sc : successors(BB))
      if (seen.insert(Sc).second) w.push_back({Sc, &Sc->front()});
  }
  return IP;
}

bool tmaIssueForcedSync() {
  const char *e = std::getenv("CUPBOP_TMA_ISSUE");
  return e && std::string(e) == "sync";
}

// The issue of the K queued copies of a moved arrive Ars (one call, or one per insertion point): one
// __cupbop_txq_issue(Q, K, wide) at each call's converged point (deduplicated). Without such a point for every call, the
// copies of these entries copy synchronously and count their bytes, but do not issue DXA.
// CUPBOP_TMA_ISSUE=sync forces that (tests).
void placeIssue(PassState &S, Function *F, const std::vector<CallInst *> &Ars, Value *Q, unsigned K,
                const std::vector<CallInst *> &copies) {
  if (!K) return;
  uint32_t wide = 0;
  std::vector<CallInst *> mine;
  std::string why;
  for (CallInst *Cp : copies) {
    if (!Cp->getCalledFunction() || Cp->getCalledFunction()->getName() != kTmaLoadQi) continue;
    const uint64_t j = cast<ConstantInt>(Cp->getArgOperand(1))->getZExtValue();
    if (j >= K || j >= kTxqN) continue; // past the queue: synchronous anyway
    mine.push_back(Cp);
    auto *R = dyn_cast<ConstantInt>(Cp->getArgOperand(7));
    if (!R) why = "a TMA load's rank is not a constant";
    else if (R->getZExtValue() > 2) wide |= 1u << j;
  }
  std::vector<Instruction *> IPs;
  if (why.empty() && tmaIssueForcedSync()) why = "CUPBOP_TMA_ISSUE=sync";
  for (CallInst *Ar : Ars) {
    if (!why.empty()) break;
    Instruction *IP = convergedIssuePoint(S, F, Ar, why);
    if (IP && std::find(IPs.begin(), IPs.end(), IP) == IPs.end()) IPs.push_back(IP);
  }
  if (!why.empty()) {
    for (CallInst *Cp : mine) Cp->setArgOperand(3, ConstantInt::get(S.I32, UINT32_MAX));
    fprintf(stderr, "[CuPBoP] warning: %s: no point where the warp is converged after an mbarrier arrive for the DXA issue "
                    "of its %zu TMA copies (%s): they copy synchronously\n", F->getName().str().c_str(), mine.size(),
            why.c_str());
    return;
  }
  // The entries' data die at the issue. The queue is memory: without these stores, on a path without a fill SROA (schedule 2)
  // carries the last fill's values around the loop to the next issue, and a GEMM loop holds them in registers (async_tg3
  // +8.9% cycles). Poison stores are free: SROA drops them, and InstCombine the context-memory stores of the core mapping.
  // valid stays meaningful (the issue clears it).
  Type *I8 = Type::getInt8Ty(S.ctx);
  for (Instruction *IP : IPs) {
    IRBuilder<> IB(IP);
    S.call(IB, kTxqIssue, S.Void, {Q, ConstantInt::get(S.I32, K), ConstantInt::get(S.I32, wide)});
    for (unsigned j = 0; j < K && j < kTxqN; ++j) {
      IB.CreateAlignedStore(PoisonValue::get(S.Ptr), IB.CreateConstGEP1_32(I8, Q, kTxqEntrySize * j), Align(8));
      for (unsigned off : {8u, 20u, 24u, 28u, 32u, 36u})
        IB.CreateAlignedStore(PoisonValue::get(S.I32), IB.CreateConstGEP1_32(I8, Q, kTxqEntrySize * j + off), Align(4));
    }
  }
  S.n_issue += IPs.size();
}

// Triton's TMA issue (capability 90): one thread arrives with expect_tx, then CTA barriers, then the same thread, elected by another
// predicate, issues the copies:
//   @(tid % 128 == 0 && c) mbarrier.arrive.expect_tx _, [bar], 8192;  bar.sync 0;
//   @(tid < 32 && elect.sync(-1) && c) cp.async.bulk.tensor [a], [tmapA, ...], [bar];  bar.sync 0;  @(...) cp.async.bulk.tensor [b], ...
// The arrive moves after the last copy on its mbarrier, under its own predicate. It may pass CTA barriers there: an arrive that comes
// later can only make a waiter wait longer, and no mbarrier wait lies in between (checked), so no thread waits on it while its own
// thread waits at a CTA barrier. That the arriving and the copying thread are one and the same is proved from the predicates
// (threadsOf): the copies run synchronously, or their DXA issue is queued in that thread until the arrive.
bool moveArriveOverCtaBarriers(PassState &S, Function *F, CallInst *A, std::string &why) {
  DominatorTree DT(*F);
  PostDominatorTree PDT(*F);
  LoopInfo LI(DT);
  BasicBlock *BA = A->getParent();
  Value *bar = A->getArgOperand(0)->stripPointerCasts();
  auto isMbarWait = [](CallInst *C) {
    Function *Fn = C->getCalledFunction();
    StringRef n = Fn ? Fn->getName() : "";
    return n == kWaitPar || n == kTestPar || n == kWaitSt || n == kTestSt;
  };
  auto isArriveOn = [&](CallInst *C) {
    Function *Fn = C->getCalledFunction();
    StringRef n = Fn ? Fn->getName() : "";
    return C != A && (n == kArrive || n == kArriveTx) && C->getArgOperand(0)->stripPointerCasts() == bar;
  };
  Value *pA = guardOf(BA);
  if (!pA || BA->getTerminator()->getNumSuccessors() != 1) { why = "the arrive is not under a predicate of its own"; return false; }
  // the TMA loads on this mbarrier from the arrive on, through CTA barriers, up to an mbarrier wait or another arrive on it
  std::vector<CallInst *> copies;
  std::set<BasicBlock *> seen{BA};
  std::vector<std::pair<BasicBlock *, Instruction *>> work{{BA, A->getNextNode()}};
  while (!work.empty()) {
    auto [BB, from] = work.back();
    work.pop_back();
    bool stop = false;
    for (Instruction *I = from; I && !stop; I = I->getNextNode()) {
      auto *C = dyn_cast<CallInst>(I);
      if (!C) continue;
      Function *Fn = C->getCalledFunction();
      if (Fn && Fn->getName() == kTmaLoad && C->getArgOperand(2)->stripPointerCasts() == bar && S.txCopies.count(C))
        copies.push_back(C);
      else if (isMbarWait(C) || isArriveOn(C)) stop = true;
      else if (!C->isInlineAsm() && Fn && Fn->getName() == kBulk) stop = true; // a bulk copy names no mbarrier here
    }
    if (stop) continue;
    for (BasicBlock *Sc : successors(BB)) {
      if (DT.dominates(Sc, BB)) continue; // back edge
      if (seen.insert(Sc).second) work.push_back({Sc, &Sc->front()});
    }
  }
  if (copies.empty()) { why = "no TMA copy on its mbarrier follows before a wait on it"; return false; }
  // the end of the copies: the join after the last one, which every other copy's join dominates
  BasicBlock *end = nullptr;
  for (CallInst *Cp : copies) {
    BasicBlock *T = Cp->getParent()->getSingleSuccessor();
    if (!guardOf(Cp->getParent()) || !T) { why = "a copy is not under a predicate of its own"; return false; }
    if (!end || DT.dominates(end, T)) end = T;
  }
  for (CallInst *Cp : copies)
    if (!DT.dominates(Cp->getParent()->getSingleSuccessor(), end) && Cp->getParent()->getSingleSuccessor() != end) {
      why = "the copies are not in one sequence";
      return false;
    }
  BasicBlock *head = BA->getSinglePredecessor();
  if (!DT.dominates(head, end) || !PDT.dominates(end, BA) || LI.getLoopFor(end) != LI.getLoopFor(BA)) {
    why = "the copies do not follow the arrive on every path, in its loop";
    return false;
  }
  // no mbarrier wait from the arrive to the end of its copies
  {
    std::set<BasicBlock *> rs{BA};
    std::vector<std::pair<BasicBlock *, Instruction *>> w{{BA, A->getNextNode()}};
    while (!w.empty()) {
      auto [BB, from] = w.back();
      w.pop_back();
      if (BB == end) continue;
      for (Instruction *I = from; I; I = I->getNextNode())
        if (auto *C = dyn_cast<CallInst>(I)) {
          Function *Fn = C->getCalledFunction();
          if (isMbarWait(C) || isArriveOn(C) || (!Fn && !C->isInlineAsm())) { why = "a wait lies between the arrive and its copies"; return false; }
          if (Fn && !Fn->isDeclaration()) {
            std::set<Function *> visiting;
            if (functionWaits(Fn, visiting)) { why = "a call that may wait lies between the arrive and its copies"; return false; }
          }
        }
      for (BasicBlock *Sc : successors(BB))
        if (!DT.dominates(Sc, BB) && rs.insert(Sc).second) w.push_back({Sc, &Sc->front()});
    }
  }
  // one thread: the arrive's, and every copy's
  auto tA = threadsOf(pA, F, LI);
  if (!tA || tA->size() != 1) { why = "the arrive's predicate does not select one thread of the block"; return false; }
  for (CallInst *Cp : copies) {
    auto tC = threadsOf(guardOf(Cp->getParent()), F, LI);
    if (!tC || tC->size() > 1 || (tC->size() == 1 && (*tC)[0] != (*tA)[0])) {
      why = "a copy's predicate does not select the arriving thread alone";
      return false;
    }
  }
  // the arrive's operands at its new place: the mbarrier from before the predicate (its generic cast was made in the arrive's block)
  auto *barI = dyn_cast<Instruction>(bar), *bytesI = dyn_cast<Instruction>(A->getArgOperand(1));
  if ((barI && barI->getParent() == BA) || (bytesI && bytesI->getParent() == BA) || !bar->getType()->isPointerTy()) {
    why = "the arrive's operands are computed under its predicate";
    return false;
  }
  // `_` as the state: the phi of the predicated arrive's result has no users
  for (bool again = true; again;) {
    again = false;
    for (User *U : A->users())
      if (auto *I = dyn_cast<Instruction>(U))
        if (isInstructionTriviallyDead(I)) { I->eraseFromParent(); again = true; break; }
  }
  if (!A->use_empty()) { why = "the arrive's state is used"; return false; }
  // the move: the copies queue their DXA issue, the arrive goes to the end of the copies under its own predicate; one thread
  // (proved above) arrives, which the arrive's helper takes without counting the warp's active threads
  Value *Q = nullptr;
  for (CallInst *Cp : copies) S.orderedCopies.insert(Cp);
  const unsigned K = queueCopies(S, F, copies, Q);
  if (!Q) Q = txQueue(S, F);
  Instruction *thenT = SplitBlockAndInsertIfThen(pA, end->getFirstInsertionPt(), false);
  thenT->getParent()->setName("mbar_arrive_after_copies");
  IRBuilder<> IB(thenT);
  Value *P = bar->getType()->getPointerAddressSpace() ? IB.CreateAddrSpaceCast(bar, S.Ptr, "async_gen") : bar;
  const bool isTx = A->getCalledFunction()->getName() == kArriveTx;
  checkTmaBytes(S, IB, Q, K, P, isTx ? A->getArgOperand(1) : nullptr, copies);
  CallInst *Ar = S.call(IB, isTx ? kArriveTxM : kArriveM, S.I32, {ConstantInt::get(S.I32, 1), P, A->getArgOperand(1)});
  fprintf(stderr, "[CuPBoP] %s: an mbarrier arrive of thread %u moved after its %zu TMA copies, over CTA barriers (§5.3)\n",
          F->getName().str().c_str(), (*tA)[0], copies.size());
  // the DXA takes its operands from lane 0 (cupbop_tma_dxa_ok): another thread's copies are synchronous
  if ((*tA)[0] % 32 != 0)
    fprintf(stderr, "[CuPBoP] warning: %s: the TMA copies of thread %u (not lane 0 of its warp) copy synchronously\n",
            F->getName().str().c_str(), (*tA)[0]);
  A->eraseFromParent();
  S.n_moved++;
  placeIssue(S, F, {Ar}, Q, K, copies);
  return true;
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
        if (auto *CI = dyn_cast<CallInst>(I)) {
          Function *callee = CI->getCalledFunction();
          // Another producer phase owns its own TMA sites. A pipeline's
          // prologue can reach the next tile's issue before the first wait.
          if (callee && callee->getName() == kArriveTx) { stop = true; break; }
          if (S.txCopies.count(CI)) copies.push_back(CI);
        }
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
        std::string why;
        if ((!K || !K->isZero()) && !moveArriveOverCtaBarriers(S, F, A, why))
          fail_at(A, "mbarrier.arrive.expect_tx is not followed, in the same thread and before any wait, by the bulk / "
                     "TMA copies that complete its transaction: the synchronous copies cannot be ordered before the "
                     "arrival (async design §5.3); refusing (over CTA barriers: " + why + ")");
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
    // __cupbop_tma_load_qi in cudaKernelImpl_async.inc (a DXA completion must not overtake the arrival). The arriving
    // threads are not proved here: the helper looks at the warp's active threads.
    bool anyTma = false;
    for (CallInst *Cp : copies) {
      StringRef n = Cp->getCalledFunction() ? Cp->getCalledFunction()->getName() : "";
      anyTma |= n == kTmaLoad || n == kTmaLoadQi;
    }
    Value *Q = nullptr;
    unsigned K = 0;
    if (anyTma) {
      K = queueCopies(S, F, copies, Q);
      if (!Q) Q = txQueue(S, F);
    }
    std::vector<CallInst *> moved;
    for (Instruction *IP : IPs) {
      if (Q) {
        IRBuilder<> IB(IP);
        const bool isTx = A->getCalledFunction()->getName() == kArriveTx;
        checkTmaBytes(S, IB, Q, K, A->getArgOperand(0), isTx ? A->getArgOperand(1) : nullptr, copies);
        moved.push_back(S.call(IB, isTx ? kArriveTxM : kArriveM, S.I32,
                               {ConstantInt::get(S.I32, 0), A->getArgOperand(0), A->getArgOperand(1)}));
      } else {
        Instruction *Cl = A->clone();
        Cl->insertBefore(IP);
      }
    }
    A->eraseFromParent();
    S.n_moved++;
    if (Q) placeIssue(S, F, moved, Q, K, copies);
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
// CuLifter also uses vectors to represent aligned by-value structs. Taking the address of one does
// not make it a standalone tensor map: a CUTLASS Kernel::Params may contain several embedded maps.
// CUPBOP_NARROW_VECTOR_ARGS=1: the earlier rule (every vector-typed parameter wider than 8 bytes).
static bool hasVectorType(Type *T) {
  if (T->isVectorTy()) return true;
  if (auto *AT = dyn_cast<ArrayType>(T)) return hasVectorType(AT->getElementType());
  if (auto *ST = dyn_cast<StructType>(T))
    for (Type *E : ST->elements()) if (hasVectorType(E)) return true;
  return false;
}

static std::optional<uint64_t> paramBankOffset(Value *V, AllocaInst *bank, const DataLayout &DL) {
  if (V == bank) return 0;
  if (isa<PtrToIntInst, IntToPtrInst>(V))
    return paramBankOffset(cast<Instruction>(V)->getOperand(0), bank, DL);
  if (auto *op = dyn_cast<BinaryOperator>(V)) {
    if (op->getOpcode() != Instruction::Add && op->getOpcode() != Instruction::Sub) return {};
    if (auto *amount = dyn_cast<ConstantInt>(op->getOperand(1)))
      if (auto base = paramBankOffset(op->getOperand(0), bank, DL))
        return op->getOpcode() == Instruction::Add ? *base + amount->getZExtValue() : *base - amount->getZExtValue();
  }
  if (V->getType()->isPointerTy()) {
    APInt offset(64, 0);
    Value *base = V->stripAndAccumulateConstantOffsets(DL, offset, true);
    if (base != V)
      if (auto start = paramBankOffset(base, bank, DL)) return *start + offset.getZExtValue();
  }
  return {};
}

// The host passes a CUDA tensor map as one device-address slot, even when NVCC derived
// its parameter address by adding an offset to another tensor map's cvta.param.
static void markTensorMapParameters(PassState &S) {
  const DataLayout &DL = S.M->getDataLayout();
  for (const auto &[F, image] : S.paramImages) {
    auto [bank, bankBase] = image;
    std::map<uint64_t, unsigned> tensorMaps;
    for (Argument &arg : F->args()) {
      unsigned off;
      StringRef name = arg.getName();
      if (hasVectorType(arg.getType()) && DL.getTypeStoreSize(arg.getType()) == 128 &&
          name.consume_front("arg_") && !name.getAsInteger(10, off))
        tensorMaps.emplace(off - bankBase, arg.getArgNo());
    }
    if (tensorMaps.empty()) continue;
    for (BasicBlock &bb : *F)
      for (Instruction &I : bb) {
        auto *call = dyn_cast<CallInst>(&I);
        Value *descriptor = call ? async_tensor_map_operand(*call) : nullptr;
        if (!descriptor) continue;
        if (auto off = paramBankOffset(descriptor, bank, DL)) {
          auto map = tensorMaps.find(*off);
          if (map != tensorMaps.end()) S.tensorMapArgs.insert({F, map->second});
        }
      }
  }
}

static void narrowWideKernelArgs(Module *M, const std::set<std::pair<Function *, unsigned>> &tensorMapArgs) {
  const DataLayout &DL = M->getDataLayout();
  const bool all = std::getenv("CUPBOP_NARROW_VECTOR_ARGS") != nullptr;
  auto isWide = [&](Argument &A) {
    return !A.getType()->isPointerTy() && hasVectorType(A.getType()) && DL.getTypeStoreSize(A.getType()) > 8 &&
           (all || tensorMapArgs.count({A.getParent(), A.getArgNo()}));
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

Value *async_tensor_map_operand(CallBase &call) {
  const Function *callee = call.getCalledFunction();
  if (!callee) return nullptr;
  StringRef name = callee->getName();
  if (name == kTmaLoad || name == "__cupbop_tcgen_tma_load" || name == "__cupbop_tma_multicast")
    return call.getArgOperand(1);
  if (name == kTmaLoadQi) return call.getArgOperand(5);
  if (name == kTmaStore || name == "__cupbop_tensor_reduce") return call.getArgOperand(0);
  return nullptr;
}

// CuLifter emits both CTA-local and peer paths for SASS ARRIVES. A direct read
// of the current CTA rank, including its low byte from the SASS address, proves
// that the peer path cannot execute for any supported CUDA cluster size.
static void simplifySelfClusterArrive(CallInst &call) {
  auto *assembly = cast<InlineAsm>(call.getCalledOperand());
  StringRef body(assembly->getAsmString());
  if (!body.consume_front("{.reg .pred p; .reg .u32 r; .reg .u32 m; .reg .b64 s; "
                           "mov.u32 r, %cluster_ctarank; setp.ne.u32 p, r, $2; "
                           "@p mapa.shared::cluster.u32 m, $0, $2; "))
    return;

  StringRef local;
  if (call.arg_size() == 4 &&
      body == "@p mbarrier.arrive.expect_tx.release.cluster.shared::cluster.b64 _, [m], $3; "
              "@!p mbarrier.arrive.expect_tx.shared::cta.b64 s, [$1], $3;}") {
    local = "mbarrier.arrive.expect_tx.shared::cta.b64 _, [$1], $3;";
  } else if (call.arg_size() == 3 &&
             body == "@p mbarrier.arrive.release.cluster.shared::cluster.b64 _, [m]; "
                     "@!p mbarrier.arrive.shared::cta.b64 s, [$1];}") {
    local = "mbarrier.arrive.shared::cta.b64 _, [$1];";
  } else {
    return;
  }

  using namespace llvm::PatternMatch;
  Value *rank = call.getArgOperand(2);
  Value *unmasked;
  if (match(rank, m_c_And(m_Value(unmasked), m_SpecificInt(255))))
    rank = unmasked;
  const auto *read = dyn_cast<CallInst>(rank);
  const Function *reg = read ? read->getCalledFunction() : nullptr;
  if (!reg || reg->getIntrinsicID() != Intrinsic::nvvm_read_ptx_sreg_cluster_ctarank)
    return;
  call.setCalledOperand(InlineAsm::get(assembly->getFunctionType(), local,
                                       assembly->getConstraintString(), assembly->hasSideEffects()));
}

// Fixed SDK sequences that return a pointer, read a timer, or suspend/trap.
// Leave mixed or otherwise different PTX bundles to the statement parser.
static bool lowerSdkBuiltin(PassState &s, CallInst *call, ArrayRef<Stmt> statements) {
  IRBuilder<> b(call);
  Value *value = nullptr;
  if (statements.size() == 3 && statements[0].op == "mov.u32" &&
      statements[0].ops.size() == 2 && statements[0].ops[1] == "%reserved_smem_offset_1" &&
      statements[1].op == "cvt.u64.u32" && statements[2].op == "cvta.shared.u64" &&
      statements[1].ops.size() == 2 && statements[2].ops.size() == 2 &&
      statements[1].ops[1] == statements[0].ops[0] && statements[2].ops[1] == statements[1].ops[0] &&
      statements[2].ops[0] == "$0" && call->getType()->isPointerTy()) {
    // cooperative_groups/details/memory.h specifies 288 bytes per CTA.
    auto *scratch = s.M->getNamedGlobal("__cupbop_cg_reserved_shared");
    if (!scratch) {
      auto *type = ArrayType::get(b.getInt8Ty(), 288);
      scratch = new GlobalVariable(*s.M, type, false, GlobalValue::InternalLinkage, UndefValue::get(type),
                                   "__cupbop_cg_reserved_shared", nullptr, GlobalValue::NotThreadLocal, 3);
      scratch->setAlignment(Align(16));
    }
    value = b.CreatePointerCast(scratch, call->getType());
  } else if (statements.size() == 1 && statements[0].pred.empty()) {
    const auto &st = statements[0];
    if (st.op == "mov.u64" && st.ops == std::vector<std::string>{"$0", "%globaltimer"})
      value = s.call(b, "__cupbop_time_ns", s.I64, {});
    else if (st.op == "nanosleep.u32" && st.ops == std::vector<std::string>{"$0"} && call->arg_size() == 1)
      s.call(b, "__cupbop_sleep_ns", s.Void, {call->getArgOperand(0)});
    else if (st.op == "trap" && st.ops.empty())
      s.call(b, "__cupbop_device_trap", s.Void, {});
    else return false;
  } else return false;
  if (value) call->replaceAllUsesWith(value);
  call->eraseFromParent();
  return true;
}

void lower_async_ptx(Module *M) {
  PassState S(M);
  const int sched = schedule();
  // 1. NVVM intrinsics (cluster registers first: CuLifter mbarrier addresses fold to constants after that)
  std::vector<CallInst *> calls;
  std::map<Function *, std::vector<Function *>> callers, callees;
  std::set<Function *> barrierFunctions;
  std::set<Function *> structuredTma, splitByteTransactions;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB) {
        auto *C = dyn_cast<CallInst>(&I);
        if (!C) continue;
        if (C->isInlineAsm()) {
          simplifySelfClusterArrive(*C);
          const auto &body = cast<InlineAsm>(C->getCalledOperand())->getAsmString();
          if (body.find("mbarrier") != std::string::npos) barrierFunctions.insert(&F);
          if (body.find("mbarrier.expect_tx.") != std::string::npos || body.find("mbarrier.complete_tx.") != std::string::npos)
            splitByteTransactions.insert(&F);
          if (body.find("tcgen05.") != std::string::npos ||
              body.find("clusterlaunchcontrol.try_cancel") != std::string::npos ||
              body.find("multicast::cluster") != std::string::npos || body.find("cp.reduce.async.bulk") != std::string::npos ||
              body.find("st.async.") != std::string::npos ||
              (body.find("mbarrier.") != std::string::npos && body.find("shared::cluster") != std::string::npos) ||
              body.find("shared::cluster.shared::cta") != std::string::npos || body.find("mapa.") != std::string::npos)
            S.tcgenFunctions.insert(&F);
        } else if (auto *callee = C->getCalledFunction()) {
          if (callee->getName().starts_with("llvm.nvvm.")) {
            calls.push_back(C);
            if (callee->getName().contains("mbarrier")) barrierFunctions.insert(&F);
            StringRef name = callee->getName();
            if (name.starts_with("llvm.nvvm.cp.async.bulk.tensor.g2s.")) {
              barrierFunctions.insert(&F);
              structuredTma.insert(&F);
              if (!isOrdinaryTmaLoad(*C) || !hasLocalTmaArrive(*C, M->getDataLayout())) S.tcgenFunctions.insert(&F);
            }
            if (name.starts_with("llvm.nvvm.mapa") ||
                name == "llvm.nvvm.cp.async.bulk.global.to.shared.cluster" ||
                name == "llvm.nvvm.cp.async.bulk.shared.cta.to.cluster") S.tcgenFunctions.insert(&F);
          } else if (!callee->isDeclaration()) {
            callers[callee].push_back(&F);
            callees[&F].push_back(callee);
          }
        }
      }
  for (auto *F : structuredTma)
    if (splitByteTransactions.count(F)) S.tcgenFunctions.insert(F);
  if (!S.tcgenFunctions.empty()) {
    // A noinline helper must agree with all callers on the 8-byte barrier ABI.
    // Only follow edges into helpers that actually use a barrier (transitively).
    barrierFunctions.insert(S.tcgenFunctions.begin(), S.tcgenFunctions.end());
    std::vector<Function *> pending(barrierFunctions.begin(), barrierFunctions.end());
    while (!pending.empty()) {
      auto *f = pending.back();
      pending.pop_back();
      for (auto *caller : callers[f])
        if (barrierFunctions.insert(caller).second) pending.push_back(caller);
    }
    pending.assign(S.tcgenFunctions.begin(), S.tcgenFunctions.end());
    while (!pending.empty()) {
      auto *f = pending.back();
      pending.pop_back();
      for (auto *caller : callers[f])
        if (S.tcgenFunctions.insert(caller).second) pending.push_back(caller);
      for (auto *callee : callees[f])
        if (barrierFunctions.count(callee) && S.tcgenFunctions.insert(callee).second) pending.push_back(callee);
    }
  }
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
      if (mentionsAsyncText(a) || StringRef(a).contains("wgmma."))
        fail_at(C, "cannot parse async asm (" + err + ")");
      continue;
    }
    auto isWgmmaControl = [](const Stmt &s) {
      StringRef op(s.op);
      return op.starts_with("wgmma.fence") || op.starts_with("wgmma.commit_group") || op.starts_with("wgmma.wait_group");
    };
    if (llvm::any_of(st, isWgmmaControl)) {
      if (!llvm::all_of(st, [&](const Stmt &s) { return isWgmmaControl(s) && s.pred.empty() && s.label.empty(); }))
        fail_at(C, "WGMMA control must use unpredicated inline asm containing only fence/commit_group/wait_group");
      continue; // Retain the call for the WGMMA lowering, including all of its group controls.
    }
    if (llvm::any_of(st, isWgmmaMma)) {
      validateWgmmaMma(C, st);
      continue;
    }
    if (lowerSdkBuiltin(S, C, st)) continue;
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
  // Record fixed geometry and the kernels whose threads participate in a split
  // barrier (including through a callee). Retired threads no longer owe an arrival.
  std::set<Function *> syncKernels;
  if (auto *sync = M->getFunction("__cupbop_cluster_sync")) {
    std::vector<Function *> pending;
    for (auto *u : sync->users())
      if (auto *call = dyn_cast<CallInst>(u)) pending.push_back(call->getFunction());
    while (!pending.empty()) {
      auto *f = pending.back(); pending.pop_back();
      if (!syncKernels.insert(f).second) continue;
      pending.insert(pending.end(),callers[f].begin(),callers[f].end());
    }
  }
  std::map<Function *, std::array<unsigned,3>> sourceShapes;
  if (auto *annotations = M->getGlobalVariable("llvm.global.annotations")) {
    for (auto &operand : annotations->getInitializer()->operands()) {
      auto *record = dyn_cast<ConstantStruct>(operand.get());
      StringRef tag;
      if (!record || record->getNumOperands() < 5 || !getConstantStringInfo(record->getOperand(1), tag) ||
          tag != "cupbop.cluster_dims") continue;
      auto *kernel = cast<Function>(record->getOperand(0)->stripPointerCasts());
      auto *args = cast<GlobalVariable>(record->getOperand(4)->stripPointerCasts())->getInitializer();
      if (args->getNumOperands() == 0 || args->getNumOperands() > 3)
        report_fatal_error("invalid __cluster_dims__ argument count");
      auto &dims = sourceShapes[kernel];
      dims = {1,1,1};
      for (unsigned d=0; d<args->getNumOperands(); ++d) {
        auto *value = dyn_cast<ConstantInt>(args->getOperand(d));
        if (!value || value->isZero() || value->getLimitedValue() > 16)
          report_fatal_error("invalid __cluster_dims__ dimension");
        dims[d] = value->getZExtValue();
      }
    }
  }
  std::ofstream shapes("cupbop_cluster_dims.txt");
  for (auto &F : *M) {
    if (!isKernelFunction(M,&F)) continue;
    auto dims = sourceShapes[&F];
    if (auto *metadata = M->getNamedMetadata("nvvm.annotations"))
      for (auto *node : metadata->operands()) {
        auto *v = dyn_cast<ValueAsMetadata>(node->getOperand(0));
        if (!v || v->getValue() != &F) continue;
        for (unsigned i=1; i+1<node->getNumOperands(); i+=2) {
          auto *key = dyn_cast<MDString>(node->getOperand(i));
          auto *number = mdconst::dyn_extract<ConstantInt>(node->getOperand(i+1));
          if (!key || !number) continue;
          StringRef k = key->getString();
          if (k == "cluster_dim_x" || k == "cluster_dim_y" || k == "cluster_dim_z")
            dims[k.back()-'x'] = number->getZExtValue();
        }
      }
    if (dims[0]) {
      if (!dims[1]) dims[1] = 1;
      if (!dims[2]) dims[2] = 1;
    }
    const bool sync = syncKernels.count(&F);
    if (sync || dims[0]) shapes << cupbop_kernel_lookup_name(F.getName().str()) << ' ' << dims[0] << ' ' << dims[1]
                                << ' ' << dims[2] << ' ' << sync << '\n';
    if (sync) for (auto &BB : F)
      if (auto *ret = dyn_cast<ReturnInst>(BB.getTerminator())) {
        IRBuilder<> rb(ret);
        S.call(rb,"__cupbop_cluster_sync",S.Void,{rb.getInt32(2)});
      }
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
  markTensorMapParameters(S);
  narrowWideKernelArgs(M, S.tensorMapArgs);
  fprintf(stderr, "[CuPBoP] async PTX lowered (software mode): %u asm, %u intrinsics, %u arrive(s) moved after their "
                  "copies, %u converged DXA issue point(s)\n", S.n_asm, S.n_intr, S.n_moved, S.n_issue);
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
  // the __shared__ variable an mbarrier address points into, and the offset (dyn: a computed one); G null when not found
  auto objOf = [&](Value *P) -> Obj {
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
    if (G && G->getAddressSpace() != 3) G = nullptr;
    return {G, off, dyn};
  };
  std::vector<Obj> objs;
  for (auto *C : inits) {
    Obj o = objOf(C->getArgOperand(0));
    if (!o.G)
      fail_at(C, "mbarrier.init on an address that is not a constant or computed offset into a __shared__ variable: "
                 "cannot assign it a Vortex barrier number");
    objs.push_back(o);
  }
  std::map<std::tuple<Function *, GlobalVariable *, int64_t>, uint64_t> idOf; // constant mbarriers of each kernel
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
    if (!anyDyn[o.G]) idOf[{C->getFunction(), o.G, o.off}] = cast<ConstantInt>(id)->getZExtValue();
  }
  // a queued TMA load on a constant mbarrier of its own kernel learns the number, so that it does not read the record for it
  unsigned nKnown = 0;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *C = dyn_cast<CallInst>(&I))
          if (tmaStatic() && C->getCalledFunction() && C->getCalledFunction()->getName() == kTmaLoadQi) {
            Obj o = objOf(C->getArgOperand(6));
            auto it = o.G && !o.dyn ? idOf.find({&F, o.G, o.off}) : idOf.end();
            if (it != idOf.end()) { C->setArgOperand(2, ConstantInt::get(I32, it->second)); nKnown++; }
          }
  if (nKnown) summary += " (" + std::to_string(nKnown) + " queued TMA loads with a known number)";
  fprintf(stderr, "[CuPBoP] mbarrier Vortex barrier numbers:%s\n", summary.c_str());
}
