// cp.async family and DXA (Vortex tile-copy engine) support in the kernel translator. See async_copy.h.
#include "async_copy.h"
#include "tool.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <map>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <vector>

using namespace llvm;

extern int need_nested_loop; // insert_warp_loop.cpp: schedule 1 sub-pass form (lanes < 32)
bool cupbop_dxa_sidecar_written = false; // set by the (opt-in) cp.async -> DXA conversion in tool.cpp

namespace {

[[noreturn]] void fail_at(Instruction *I, const std::string &what) {
  std::string s;
  raw_string_ostream os(s);
  I->print(os);
  fprintf(stderr, "error: %s\n  at:%s (in %s)\n", what.c_str(), os.str().c_str(),
          I->getFunction()->getName().str().c_str());
  exit(1);
}

std::string trim(const std::string &s) {
  size_t b = s.find_first_not_of(" \t\n\r");
  if (b == std::string::npos) return "";
  size_t e = s.find_last_not_of(" \t\n\r");
  return s.substr(b, e - b + 1);
}

std::string asmString(CallInst *C) {
  if (!C->isInlineAsm()) return "";
  return cast<InlineAsm>(C->getCalledOperand())->getAsmString();
}

std::string calleeName(CallInst *C) {
  if (Function *F = C->getCalledFunction()) return F->getName().str();
  return "";
}

// The value a load from a -O0 local returns: the one store to an alloca that never escapes, when that
// store dominates the load. nullptr otherwise.
Value *singleStoreValue(LoadInst *LI, std::map<Function *, std::unique_ptr<DominatorTree>> &DTs) {
  auto *AI = dyn_cast<AllocaInst>(LI->getPointerOperand()->stripPointerCasts());
  if (!AI) return nullptr;
  StoreInst *only = nullptr;
  for (User *U : AI->users()) {
    if (auto *SI = dyn_cast<StoreInst>(U)) {
      if (SI->getPointerOperand()->stripPointerCasts() != AI || only) return nullptr;
      only = SI;
      continue;
    }
    if (isa<LoadInst>(U)) continue;
    if (auto *II = dyn_cast<IntrinsicInst>(U))
      if (II->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(II)) continue;
    if (auto *BC = dyn_cast<BitCastInst>(U)) { // typed-pointer leftovers: only loads through it
      bool loads_only = true;
      for (User *UU : BC->users()) loads_only &= isa<LoadInst>(UU);
      if (loads_only) continue;
    }
    return nullptr;
  }
  if (!only || only->getFunction() != LI->getFunction()) return nullptr;
  auto &DT = DTs[LI->getFunction()];
  if (!DT) DT = std::make_unique<DominatorTree>(*LI->getFunction());
  if (!DT->dominates(only, LI)) return nullptr;
  return only->getValueOperand();
}

Value *callAddrArg(CallInst *CI, std::map<Function *, std::unique_ptr<DominatorTree>> &DTs, int depth);

bool isAddrCast(Value *V) {
  return isa<TruncInst>(V) || isa<ZExtInst>(V) || isa<SExtInst>(V) || isa<PtrToIntInst>(V) || isa<IntToPtrInst>(V) ||
         isa<AddrSpaceCastInst>(V) || isa<BitCastInst>(V);
}

// The argument number of F whose value V (in F) is an address chain of, or -1.
int argOfChain(Value *V, std::map<Function *, std::unique_ptr<DominatorTree>> &DTs, int depth) {
  std::set<Value *> seen;
  while (V && seen.insert(V).second) {
    if (auto *A = dyn_cast<Argument>(V)) return A->getArgNo();
    if (isAddrCast(V)) { V = cast<Instruction>(V)->getOperand(0); continue; }
    if (auto *L = dyn_cast<LoadInst>(V)) { V = singleStoreValue(L, DTs); continue; }
    if (auto *C = dyn_cast<CallInst>(V)) { V = callAddrArg(C, DTs, depth + 1); continue; }
    return -1;
  }
  return -1;
}

// A call whose result is an address chain of one of its arguments (NVVM gen->shared conversion, or a small
// helper such as clang's -O0 __cvta_generic_to_shared -> __nv_cvta_generic_to_shared_impl): that argument.
Value *callAddrArg(CallInst *CI, std::map<Function *, std::unique_ptr<DominatorTree>> &DTs, int depth) {
  Function *Fn = CI->getCalledFunction();
  if (!Fn || CI->isInlineAsm() || depth > 4) return nullptr;
  if (Fn->getName().starts_with("llvm.nvvm.ptr.gen.to.") && CI->arg_size() == 1) return CI->getArgOperand(0);
  if (Fn->isDeclaration()) return nullptr;
  ReturnInst *ret = nullptr;
  for (auto &BB : *Fn)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator())) {
      if (ret) return nullptr;
      ret = R;
    }
  if (!ret || !ret->getReturnValue()) return nullptr;
  int k = argOfChain(ret->getReturnValue(), DTs, depth);
  return k < 0 ? nullptr : CI->getArgOperand(k);
}

// Follow a value that holds an address back to the pointer it was computed from: integer casts, ptrtoint,
// generic<->specific address-space casts, NVVM gen->shared conversions, single-store -O0 locals, and small
// helper calls whose result is such a chain of an argument. Returns the pointer (any address space; the
// generic original of an address-space cast), or nullptr when the chain ends in something else (arithmetic).
Value *tracePointer(Value *V, std::map<Function *, std::unique_ptr<DominatorTree>> &DTs) {
  std::set<Value *> seen;
  while (V && seen.insert(V).second) {
    if (auto *CI = dyn_cast<CallInst>(V)) {
      if (Value *a = callAddrArg(CI, DTs, 0)) { V = a; continue; }
      return V->getType()->isPointerTy() ? V : nullptr;
    }
    if (V->getType()->isPointerTy()) {
      if (auto *ASC = dyn_cast<AddrSpaceCastInst>(V)) { V = ASC->getPointerOperand(); continue; }
      if (auto *CE = dyn_cast<ConstantExpr>(V))
        if (CE->getOpcode() == Instruction::AddrSpaceCast) { V = CE->getOperand(0); continue; }
      if (auto *L = dyn_cast<LoadInst>(V)) // a pointer reloaded from a -O0 local: its stored value, if any
        if (Value *sv = singleStoreValue(L, DTs)) { V = sv; continue; }
      return V;
    }
    if (isAddrCast(V)) { V = cast<Instruction>(V)->getOperand(0); continue; }
    if (auto *LI = dyn_cast<LoadInst>(V)) { V = singleStoreValue(LI, DTs); continue; }
    if (auto *CE = dyn_cast<ConstantExpr>(V)) {
      if (CE->isCast()) { V = CE->getOperand(0); continue; }
      return nullptr;
    }
    return nullptr;
  }
  return nullptr;
}

Value *toGeneric(IRBuilder<> &B, Value *P) {
  auto *PT = cast<PointerType>(P->getType());
  if (PT->getAddressSpace() == 0) return P;
  if (auto *ASC = dyn_cast<AddrSpaceCastInst>(P))
    if (ASC->getPointerOperand()->getType()->getPointerAddressSpace() == 0) return ASC->getPointerOperand();
  return B.CreateAddrSpaceCast(P, PointerType::get(P->getContext(), 0), "cpa_gen");
}

struct CopySite {
  CallInst *call;
  unsigned cp;        // 4, 8 or 16 bytes
  Value *dst;         // address operand (pointer or integer)
  int64_t dst_off;    // [$k+off]
  Value *src;
  int64_t src_off;
  Value *src_size;    // nullptr = cp; an i1 = ignore-src predicate (true: nothing is read)
  bool ignore_src;
};

// Emit the synchronous copy of one cp.async in front of S.call.
void emitCopy(CopySite &S, std::map<Function *, std::unique_ptr<DominatorTree>> &DTs, unsigned &n_traced,
              unsigned &n_inttoptr) {
  LLVMContext &ctx = S.call->getContext();
  IRBuilder<> B(S.call);
  Type *I8 = Type::getInt8Ty(ctx), *I32 = Type::getInt32Ty(ctx), *I64 = Type::getInt64Ty(ctx);
  Type *T = IntegerType::get(ctx, S.cp * 8);
  auto addr = [&](Value *V, int64_t off, bool shared) -> Value * {
    Value *P = tracePointer(V, DTs);
    if (!P && V->getType()->isPointerTy()) P = V;
    if (P && P->getType()->isPointerTy()) {
      ++n_traced;
    } else if (V->getType()->isIntegerTy(64)) {
      // a full-width address we cannot see the origin of (lifted global addresses are i64 register
      // values): Vortex memory is flat, so the integer is the generic address
      P = B.CreateIntToPtr(V, PointerType::get(ctx, 0), shared ? "cpa_dst_i2p" : "cpa_src_i2p");
      ++n_inttoptr;
      if (shared)
        fprintf(stderr, "warning: cp.async shared destination is a computed 64-bit integer; using it as the "
                        "generic address (in %s)\n", S.call->getFunction()->getName().str().c_str());
    } else {
      fail_at(S.call, std::string("cannot recover the ") + (shared ? "shared destination" : "global source") +
                          " pointer of a cp.async from its 32-bit operand (expected a cvta/ptrtoint of a pointer)");
    }
    if (off) P = B.CreateGEP(I8, P, ConstantInt::get(I64, off), "cpa_off");
    return P;
  };
  Value *dst = addr(S.dst, S.dst_off, true);
  Value *src = toGeneric(B, addr(S.src, S.src_off, false)); // global memory is the flat address space
  Align al(S.cp);
  Value *zero = ConstantInt::get(T, 0);

  // src-size: constant, select(c, cp, 0) (the lifter's predicate form), an ignore-src predicate, or runtime
  Value *full = nullptr; // i1: all cp bytes come from src
  Value *nz = nullptr;   // i1: some bytes come from src
  bool partial_possible = false;
  uint64_t const_size = S.cp;
  bool is_const = true;
  if (S.ignore_src) {
    full = B.CreateNot(S.src_size, "cpa_read");
    nz = full;
    is_const = false;
  } else if (S.src_size) {
    if (auto *K = dyn_cast<ConstantInt>(S.src_size)) {
      const_size = std::min<uint64_t>(K->getZExtValue(), S.cp);
    } else if (auto *Sel = dyn_cast<SelectInst>(S.src_size)) {
      auto *A = dyn_cast<ConstantInt>(Sel->getTrueValue()), *Bv = dyn_cast<ConstantInt>(Sel->getFalseValue());
      is_const = false;
      if (A && Bv && A->getZExtValue() >= S.cp && Bv->isZero()) {
        full = Sel->getCondition();
      } else if (A && Bv && A->isZero() && Bv->getZExtValue() >= S.cp) {
        full = B.CreateNot(Sel->getCondition(), "cpa_read");
      }
      nz = full;
    } else {
      is_const = false;
    }
    if (!is_const && !full) { // general runtime src-size
      Value *ss = B.CreateZExtOrTrunc(S.src_size, I32, "cpa_srcsz");
      full = B.CreateICmpUGE(ss, ConstantInt::get(I32, S.cp), "cpa_full");
      nz = B.CreateICmpNE(ss, ConstantInt::get(I32, 0), "cpa_nz");
      partial_possible = true;
    }
  }

  if (is_const) {
    if (const_size == 0) {
      B.CreateAlignedStore(zero, dst, al);
    } else {
      Value *v = B.CreateAlignedLoad(T, src, al, "cpa_val");
      if (const_size < S.cp) // the remainder is zero-filled (the read stays inside the aligned cp-byte block)
        v = B.CreateAnd(v, ConstantInt::get(T, APInt::getLowBitsSet(S.cp * 8, const_size * 8)), "cpa_zfill");
      B.CreateAlignedStore(v, dst, al);
    }
    return;
  }
  // runtime: never read src when nothing is to be read (its address may be out of bounds) -- read the
  // destination instead and discard the value
  Value *rd = B.CreateSelect(nz, toGeneric(B, src), toGeneric(B, dst), "cpa_rdaddr");
  Value *v = B.CreateAlignedLoad(T, rd, al, "cpa_val");
  Value *outv;
  if (partial_possible) {
    Value *ss = B.CreateZExtOrTrunc(S.src_size, T);
    Value *sh = B.CreateMul(B.CreateSub(ConstantInt::get(T, S.cp), ss), ConstantInt::get(T, 8), "cpa_sh");
    Value *mask = B.CreateLShr(ConstantInt::getAllOnesValue(T), sh, "cpa_mask"); // poison when nz is false: unselected
    Value *part = B.CreateAnd(v, mask);
    outv = B.CreateSelect(full, v, B.CreateSelect(nz, part, zero), "cpa_zfill");
  } else {
    outv = B.CreateSelect(full, v, zero, "cpa_zfill");
  }
  B.CreateAlignedStore(outv, dst, al);
}

// `[$k]`, `[$k+imm]`, `[$k-imm]` -> operand k and the byte offset
bool parseMemOperand(const std::string &tok, CallInst *C, Value *&v, int64_t &off) {
  std::string t = trim(tok);
  if (t.size() < 4 || t.front() != '[' || t.back() != ']') return false;
  t = trim(t.substr(1, t.size() - 2));
  if (t.empty() || t[0] != '$') return false;
  char *end = nullptr;
  unsigned k = std::strtoul(t.c_str() + 1, &end, 10);
  if (end == t.c_str() + 1 || k >= C->arg_size()) return false;
  std::string rest = trim(std::string(end));
  off = 0;
  if (!rest.empty()) {
    if (rest[0] != '+' && rest[0] != '-') return false;
    char *e2 = nullptr;
    long long o = std::strtoll(trim(rest.substr(1)).c_str(), &e2, 0);
    if (*e2) return false;
    off = rest[0] == '+' ? o : -o;
  }
  v = C->getArgOperand(k);
  return true;
}

// `$k` or an integer literal -> Value (constant for literals)
Value *parseScalarOperand(const std::string &tok, CallInst *C) {
  std::string t = trim(tok);
  if (t.empty()) return nullptr;
  char *end = nullptr;
  if (t[0] == '$') {
    unsigned k = std::strtoul(t.c_str() + 1, &end, 10);
    if (*end || k >= C->arg_size()) return nullptr;
    return C->getArgOperand(k);
  }
  long long v = std::strtoll(t.c_str(), &end, 0);
  if (*end) return nullptr;
  return ConstantInt::get(Type::getInt32Ty(C->getContext()), (uint64_t)v);
}

bool mentionsAsync(const std::string &s) {
  return s.find("cp.async") != std::string::npos || s.find("mbarrier") != std::string::npos ||
         s.find("cp.reduce.async") != std::string::npos;
}

} // namespace

void lower_cp_async(Module *M) {
  std::map<Function *, std::unique_ptr<DominatorTree>> DTs;
  std::vector<CopySite> copies;
  std::vector<CallInst *> commits, waits;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB) {
        auto *C = dyn_cast<CallInst>(&I);
        if (!C) continue;
        if (!C->isInlineAsm()) {
          std::string n = calleeName(C);
          if (n.rfind("llvm.nvvm.", 0) != 0) continue;
          if (n.find("cp.async.mbarrier.arrive") != std::string::npos)
            fail_at(C, "cp.async.mbarrier.arrive (mbarrier-tracked cp.async completion) is not supported yet: "
                       "mbarrier lowering is being designed separately; use cp.async.commit_group/wait_group");
          if (n.find("cp.async.bulk") != std::string::npos || n.find("cp.reduce.async.bulk") != std::string::npos)
            fail_at(C, "bulk / tensor async copies (" + n + ", TMA) are not supported; refusing instead of dropping");
          if (n.rfind("llvm.nvvm.mbarrier", 0) == 0)
            fail_at(C, "mbarrier intrinsics (" + n + ") are not supported yet (mbarrier lowering is being designed)");
          if (n == "llvm.nvvm.cp.async.commit.group") { commits.push_back(C); continue; }
          if (n == "llvm.nvvm.cp.async.wait.group" || n == "llvm.nvvm.cp.async.wait.all") { waits.push_back(C); continue; }
          if (n.rfind("llvm.nvvm.cp.async.ca.shared.global.", 0) == 0 ||
              n.rfind("llvm.nvvm.cp.async.cg.shared.global.", 0) == 0) {
            // llvm.nvvm.cp.async.{ca,cg}.shared.global.{4,8,16}[.s](ptr addrspace(3) dst, ptr addrspace(1) src[, i32 src_size])
            std::string tail = n.substr(std::string("llvm.nvvm.cp.async.ca.shared.global.").size());
            unsigned cp = std::strtoul(tail.c_str(), nullptr, 10);
            if (cp != 4 && cp != 8 && cp != 16) fail_at(C, "unsupported cp.async size in " + n);
            CopySite S{C, cp, C->getArgOperand(0), 0, C->getArgOperand(1), 0,
                       C->arg_size() >= 3 ? C->getArgOperand(2) : nullptr, false};
            copies.push_back(S);
            continue;
          }
          if (n.rfind("llvm.nvvm.cp.async", 0) == 0)
            fail_at(C, "unsupported cp.async intrinsic " + n + " (refusing instead of dropping it)");
          continue;
        }
        std::string s = asmString(C);
        if (!mentionsAsync(s)) continue;
        std::string body = trim(s);
        while (!body.empty() && (body.back() == ';' || isspace((unsigned char)body.back()))) body.pop_back();
        // the families that are refused outright, wherever they appear in the asm
        if (body.find("cp.async.mbarrier.arrive") != std::string::npos)
          fail_at(C, "cp.async.mbarrier.arrive (mbarrier-tracked cp.async completion, CuLifter's ARRIVES.LDGSTSBAR) is "
                     "not supported yet: mbarrier lowering is being designed separately");
        if (body.find("cp.async.bulk") != std::string::npos || body.find("cp.reduce.async.bulk") != std::string::npos)
          fail_at(C, "bulk / tensor async copy asm (cp.async.bulk*, TMA) is not supported; refusing instead of dropping it");
        if (body.find("mbarrier") != std::string::npos)
          fail_at(C, "mbarrier asm is not supported yet (mbarrier lowering is being designed separately); refusing "
                     "instead of dropping it");
        if (body.find(';') != std::string::npos || body.find('{') != std::string::npos || body.find('@') != std::string::npos)
          fail_at(C, "unsupported async-copy / mbarrier inline asm (several statements or a predicate): `" + trim(s) +
                         "`; only a single cp.async.{ca,cg}.shared.global, cp.async.commit_group, cp.async.wait_group "
                         "or cp.async.wait_all is lowered (refusing instead of dropping it)");
        size_t sp = body.find_first_of(" \t\n");
        std::string op = body.substr(0, sp), rest = sp == std::string::npos ? "" : trim(body.substr(sp));
        if (op.rfind("cp.async.mbarrier.arrive", 0) == 0)
          fail_at(C, "`" + op + "` (mbarrier-tracked cp.async completion, CuLifter's ARRIVES.LDGSTSBAR) is not "
                     "supported yet: mbarrier lowering is being designed separately");
        if (op.rfind("cp.async.bulk", 0) == 0 || op.rfind("cp.reduce.async.bulk", 0) == 0)
          fail_at(C, "`" + op + "` (bulk / tensor async copy, TMA) is not supported; refusing instead of dropping it");
        if (op.find("mbarrier") != std::string::npos)
          fail_at(C, "`" + op + "`: mbarrier operations are not supported yet (mbarrier lowering is being designed)");
        if (op == "cp.async.commit_group") {
          if (!rest.empty()) fail_at(C, "unexpected operands on cp.async.commit_group");
          commits.push_back(C);
          continue;
        }
        if (op == "cp.async.wait_all" || op == "cp.async.wait_group") {
          waits.push_back(C); // any N: with synchronous copies every group is already complete
          continue;
        }
        bool ca = op.rfind("cp.async.ca.shared", 0) == 0, cg = op.rfind("cp.async.cg.shared", 0) == 0;
        if (!(ca || cg) || op.find(".global") == std::string::npos)
          fail_at(C, "unsupported async-copy inline asm `" + op + "` (refusing instead of dropping it)");
        if (!C->getType()->isVoidTy()) fail_at(C, "cp.async asm with an output operand");
        std::vector<std::string> ops;
        for (size_t p = 0; p <= rest.size();) {
          size_t q = rest.find(',', p);
          ops.push_back(trim(rest.substr(p, q == std::string::npos ? std::string::npos : q - p)));
          if (q == std::string::npos) break;
          p = q + 1;
        }
        if (op.find("L2::cache_hint") != std::string::npos && !ops.empty()) ops.pop_back(); // cache-policy operand
        if (ops.size() < 3 || ops.size() > 4)
          fail_at(C, "cp.async asm `" + trim(s) + "`: expected [dst], [src], cp-size[, src-size | ignore-src]");
        CopySite S{C, 0, nullptr, 0, nullptr, 0, nullptr, false};
        if (!parseMemOperand(ops[0], C, S.dst, S.dst_off) || !parseMemOperand(ops[1], C, S.src, S.src_off))
          fail_at(C, "cp.async asm `" + trim(s) + "`: address operands must be [$k] or [$k+imm]");
        auto *K = dyn_cast_or_null<ConstantInt>(parseScalarOperand(ops[2], C));
        if (!K || (K->getZExtValue() != 4 && K->getZExtValue() != 8 && K->getZExtValue() != 16))
          fail_at(C, "cp.async asm `" + trim(s) + "`: cp-size must be a constant 4, 8 or 16");
        S.cp = K->getZExtValue();
        if (cg && S.cp != 16) fail_at(C, "cp.async.cg requires cp-size 16");
        if (ops.size() == 4) {
          S.src_size = parseScalarOperand(ops[3], C);
          if (!S.src_size) fail_at(C, "cp.async asm `" + trim(s) + "`: bad src-size operand");
          S.ignore_src = S.src_size->getType()->isIntegerTy(1);
        }
        copies.push_back(S);
      }

  if (copies.empty() && commits.empty() && waits.empty()) return;
  unsigned n_traced = 0, n_i2p = 0;
  for (auto &S : copies) {
    emitCopy(S, DTs, n_traced, n_i2p);
    S.call->eraseFromParent();
  }
  for (auto *C : commits) C->eraseFromParent();
  for (auto *C : waits) {
    // keep the compiler ordering the "memory" clobber gave (no instruction: a single-thread fence)
    IRBuilder<> B(C);
    B.CreateFence(AtomicOrdering::SequentiallyConsistent, SyncScope::SingleThread);
    C->eraseFromParent();
  }
  fprintf(stderr, "[CuPBoP] cp.async lowered to synchronous copies: %zu copies (%u pointer operands traced, %u "
                  "integer addresses), %zu commit_group, %zu wait_group/wait_all\n",
          copies.size(), n_traced, n_i2p, commits.size(), waits.size());
}

// ---------------------------------------------------------------------------------------------------------
// DXA waits

namespace {
const char *kDxaBarrierId = "_Z19__vx_dxa_barrier_idj";
const char *kArriveAndWait = "_Z28__vx_barrier_arrive_and_waitjj";
const char *kDxaWaitRt = "__cupbop_dxa_wait";  // device runtime, extern "C" (id, warps)
const char *kDxaWaitUser = "_Z13__vx_dxa_waitj"; // __vx_dxa_wait(unsigned bar_id): user-facing

bool comesFromDxaBarrierId(Value *V, std::map<Function *, std::unique_ptr<DominatorTree>> &DTs) {
  std::set<Value *> seen;
  while (V && seen.insert(V).second) {
    if (auto *C = dyn_cast<CallInst>(V)) return calleeName(C) == kDxaBarrierId;
    if (auto *Cst = dyn_cast<CastInst>(V)) { V = Cst->getOperand(0); continue; }
    if (auto *L = dyn_cast<LoadInst>(V)) { V = singleStoreValue(L, DTs); continue; }
    return false;
  }
  return false;
}

bool isDxaIssueName(const std::string &n) {
  return n.rfind("_Z17__vx_dxa_issue_", 0) == 0 || n.rfind("__vx_dxa_issue_", 0) == 0;
}
bool isDxaWaitName(const std::string &n) { return n == kDxaWaitRt || n == kDxaWaitUser; }
} // namespace

void mark_dxa_waits(Module *M) {
  std::map<Function *, std::unique_ptr<DominatorTree>> DTs;
  std::vector<CallInst *> sites;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *C = dyn_cast<CallInst>(&I))
          if (calleeName(C) == kArriveAndWait && C->arg_size() == 2 && comesFromDxaBarrierId(C->getArgOperand(0), DTs))
            sites.push_back(C);
  if (sites.empty()) return;
  LLVMContext &ctx = M->getContext();
  Type *I32 = Type::getInt32Ty(ctx);
  FunctionCallee W = M->getOrInsertFunction(kDxaWaitRt, FunctionType::get(Type::getVoidTy(ctx), {I32, I32}, false));
  cast<Function>(W.getCallee())->addFnAttr(Attribute::Convergent);
  for (auto *C : sites) {
    IRBuilder<> B(C);
    B.CreateCall(W, {C->getArgOperand(0), C->getArgOperand(1)})->addFnAttr(Attribute::Convergent);
    C->eraseFromParent();
  }
  if (cupbop_debug()) fprintf(stderr, "[dxa] %zu DXA waits marked\n", sites.size());
}

void virt_dxa_cta_once(Module *M) {
  int sched = 0;
  if (const char *e = std::getenv("VORTEX_SCHEDULE_FLAG")) sched = std::atoi(e);
  if (sched != 1) return;
  if (std::getenv("CUPBOP_DXA_PER_PASS")) { // the pre-2026-10-28 behavior (A/B, fallback): no guard
    fprintf(stderr, "[CuPBoP] CUPBOP_DXA_PER_PASS: DXA issue/wait run on every warp-loop pass\n");
    return;
  }
  GlobalVariable *slotGV = M->getGlobalVariable("intra_warp_slot");
  GlobalVariable *intraGV = M->getGlobalVariable("intra_warp_index");
  if (!slotGV || !intraGV) return;
  LLVMContext &ctx = M->getContext();
  Type *I32 = Type::getInt32Ty(ctx);
  const unsigned lanes = getVirtGeom().lanes;
  unsigned n_guarded = 0, n_kept = 0;
  for (auto &F : *M) {
    if (F.isDeclaration()) continue;
    std::vector<CallInst *> ops;
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *C = dyn_cast<CallInst>(&I)) {
          std::string n = calleeName(C);
          if (isDxaIssueName(n) || isDxaWaitName(n)) ops.push_back(C);
        }
    if (ops.empty()) continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    auto isTripHeader = [](BasicBlock *H) {
      return H->getName().starts_with("intra_warp_cond") || H->getName().starts_with("inter_warp_cond");
    };
    auto outermostTrip = [&](BasicBlock *BB) -> Loop * {
      Loop *T = nullptr;
      for (Loop *L = LI.getLoopFor(BB); L; L = L->getParentLoop())
        if (isTripHeader(L->getHeader())) T = L;
      return T;
    };
    std::map<Loop *, std::vector<CallInst *>> groups;
    for (auto *C : ops)
      if (Loop *T = outermostTrip(C->getParent())) groups[T].push_back(C);
    // uniform code (not in a warp loop) runs once per hardware warp already
    std::vector<CallInst *> to_guard;
    for (auto &g : groups) {
      Loop *T = g.first;
      std::vector<CallInst *> barriers;
      for (BasicBlock *BB : T->blocks())
        for (auto &I : *BB)
          if (auto *C = dyn_cast<CallInst>(&I)) {
            std::string n = calleeName(C);
            if ((n.find("barrier") != std::string::npos && n.find("barrier_id") == std::string::npos) || isDxaWaitName(n))
              barriers.push_back(C); // a wait / barrier (not the __vx_dxa_barrier_id getter)
          }
      // can a DXA issue run after a barrier/wait within the same pass of the warp loop (without going
      // through a warp-loop header)? Then the pass after the first would need its own transfer.
      auto reachable = [&](CallInst *from, CallInst *to) {
        if (from->getParent() == to->getParent() && from->comesBefore(to)) return true;
        std::vector<BasicBlock *> work(succ_begin(from->getParent()), succ_end(from->getParent()));
        std::set<BasicBlock *> seen;
        while (!work.empty()) {
          BasicBlock *BB = work.back();
          work.pop_back();
          if (!T->contains(BB) || !seen.insert(BB).second) continue;
          if (isTripHeader(BB)) continue;
          if (BB == to->getParent()) return true;
          for (BasicBlock *S : successors(BB)) work.push_back(S);
        }
        return false;
      };
      bool unsafe = false;
      for (auto *I : g.second) {
        if (!isDxaIssueName(calleeName(I))) continue;
        for (auto *W : barriers)
          if (W != I && reachable(W, I)) { unsafe = true; break; }
        if (unsafe) break;
      }
      if (unsafe) {
        n_kept += g.second.size();
        fprintf(stderr, "warning: [dxa] %s: a DXA issue can run again after a wait within one warp-loop pass "
                        "(a pipeline loop without __syncthreads); keeping %zu DXA call(s) per pass: each logical "
                        "warp re-issues its transfers (correct, but P=1 repeats them once per trip). Put a "
                        "__syncthreads() around the pipeline loop body for one transfer per CTA.\n",
                F.getName().str().c_str(), g.second.size());
        continue;
      }
      to_guard.insert(to_guard.end(), g.second.begin(), g.second.end());
    }
    for (auto *C : to_guard) {
      IRBuilder<> B(C);
      Value *first = B.CreateICmpEQ(B.CreateLoad(I32, slotGV, "dxa_pass"), ConstantInt::get(I32, 0), "dxa_first_pass");
      if (need_nested_loop) // sub-pass form: and the first sub-pass (logical lanes 0..L-1)
        first = B.CreateAnd(first, B.CreateICmpULT(B.CreateLoad(I32, intraGV, "dxa_lane"), ConstantInt::get(I32, lanes)),
                            "dxa_first_subpass");
      Instruction *term = SplitBlockAndInsertIfThen(first, C->getIterator(), false);
      term->getParent()->setName(isDxaIssueName(calleeName(C)) ? "dxa_issue_once" : "dxa_wait_once");
      C->moveBefore(term);
      C->addFnAttr(Attribute::Convergent);
      ++n_guarded;
    }
  }
  if (n_guarded || n_kept)
    fprintf(stderr, "[CuPBoP] DXA core mapping: %u issue/wait call(s) once per CTA / hardware warp, %u kept per pass\n",
            n_guarded, n_kept);
}

// ---------------------------------------------------------------------------------------------------------
// !vx.dxa.desc -> dxa_descriptors.txt
//
//   !vx.dxa.desc = !{!0, ...}
//   !0 = !{ptr @kernel, !"slot=0 base=arg1 size=arg2,arg3 stride=arg2*4 box=16,16 elem=4 [rank=2] [layout=row|kmajor]
//                         [smem_stride=0] [fill=0 | fillf=1.5]"}
// (the kernel may also be named by a string). Each value is an integer literal, argK (kernel argument K) or
// a product of those with '*'; base is argK[+bytes]. stride lists the byte strides of dims 1..rank-1 (default:
// dense), box the tile (elements per dim), fill the 32-bit out-of-bounds pattern (lane-replicated).

namespace {
bool validValueExpr(const std::string &v, unsigned nargs, std::string &why) {
  if (v.empty()) { why = "empty value"; return false; }
  std::stringstream ss(v);
  std::string term;
  while (std::getline(ss, term, '*')) {
    term = trim(term);
    if (term.rfind("arg", 0) == 0) {
      char *end = nullptr;
      unsigned k = std::strtoul(term.c_str() + 3, &end, 10);
      if (end == term.c_str() + 3 || *end) { why = "bad argument reference `" + term + "`"; return false; }
      if (k >= nargs) { why = "argument " + std::to_string(k) + " out of range (kernel has " + std::to_string(nargs) + ")"; return false; }
    } else {
      char *end = nullptr;
      std::strtoll(term.c_str(), &end, 0);
      if (term.empty() || *end) { why = "bad integer `" + term + "`"; return false; }
    }
  }
  return true;
}
std::vector<std::string> splitList(const std::string &v) {
  std::vector<std::string> out;
  std::stringstream ss(v);
  std::string t;
  while (std::getline(ss, t, ',')) out.push_back(trim(t));
  return out;
}
} // namespace

void emit_dxa_desc_sidecar(Module *M) {
  NamedMDNode *N = M->getNamedMetadata("vx.dxa.desc");
  if (!N || N->getNumOperands() == 0) return;
  auto bad = [](unsigned i, const std::string &why) {
    fprintf(stderr, "error: !vx.dxa.desc entry %u: %s\n", i, why.c_str());
    exit(1);
  };
  std::vector<std::string> lines;
  std::set<std::pair<std::string, long>> slots;
  for (unsigned i = 0; i < N->getNumOperands(); ++i) {
    MDNode *E = N->getOperand(i);
    if (E->getNumOperands() != 2) bad(i, "expected !{ptr @kernel | !\"kernel\", !\"spec\"}");
    Function *K = nullptr;
    std::string kname;
    if (auto *VM = dyn_cast_or_null<ValueAsMetadata>(E->getOperand(0).get())) {
      K = dyn_cast<Function>(VM->getValue()->stripPointerCasts());
      if (K) kname = K->getName().str();
    } else if (auto *S = dyn_cast_or_null<MDString>(E->getOperand(0).get())) {
      kname = S->getString().str();
      K = M->getFunction(kname);
    }
    if (!K) bad(i, "first operand must name a kernel defined in this module (got `" + kname + "`)");
    auto *Spec = dyn_cast_or_null<MDString>(E->getOperand(1).get());
    if (!Spec) bad(i, "second operand must be a spec string");
    unsigned nargs = K->arg_size();
    std::map<std::string, std::string> kv;
    std::stringstream ss(Spec->getString().str());
    std::string tok;
    while (ss >> tok) {
      size_t eq = tok.find('=');
      if (eq == std::string::npos) bad(i, "token `" + tok + "` is not key=value");
      kv[tok.substr(0, eq)] = tok.substr(eq + 1);
    }
    static const std::set<std::string> keys = {"slot", "base", "rank", "size", "stride", "box", "elem",
                                               "layout", "smem_stride", "fill", "fillf"};
    for (auto &p : kv)
      if (!keys.count(p.first)) bad(i, "unknown key `" + p.first + "`");
    for (const char *req : {"slot", "base", "size", "box", "elem"})
      if (!kv.count(req)) bad(i, std::string("missing ") + req + "=");
    long slot = std::strtol(kv["slot"].c_str(), nullptr, 0);
    if (slot < 0 || slot > 15) bad(i, "slot must be 0..15");
    if (!slots.insert({kname, slot}).second) bad(i, "slot " + std::to_string(slot) + " used twice for " + kname);
    {
      std::string b = kv["base"], why;
      size_t plus = b.find('+');
      std::string a = trim(b.substr(0, plus));
      if (a.rfind("arg", 0) != 0) bad(i, "base must be argK[+bytes]");
      if (!validValueExpr(a, nargs, why)) bad(i, "base: " + why);
      unsigned k = std::strtoul(a.c_str() + 3, nullptr, 10);
      if (!K->getArg(k)->getType()->isPointerTy() && !K->getArg(k)->getType()->isIntegerTy(64))
        bad(i, "base argument " + std::to_string(k) + " is neither a pointer nor an i64 address");
      if (plus != std::string::npos && !validValueExpr(trim(b.substr(plus + 1)), nargs, why)) bad(i, "base offset: " + why);
    }
    auto sizes = splitList(kv["size"]), box = splitList(kv["box"]);
    unsigned rank = kv.count("rank") ? std::strtoul(kv["rank"].c_str(), nullptr, 0) : sizes.size();
    if (rank < 1 || rank > 5) bad(i, "rank must be 1..5");
    if (sizes.size() != rank || box.size() != rank) bad(i, "size= and box= need rank entries each");
    std::string why;
    for (auto &v : sizes) if (!validValueExpr(v, nargs, why)) bad(i, "size: " + why);
    for (auto &v : box) {
      long t = std::strtol(v.c_str(), nullptr, 0);
      if (t < 1 || t > 65535) bad(i, "box entries must be integer literals 1..65535");
    }
    if (kv.count("stride")) {
      auto st = splitList(kv["stride"]);
      if (st.size() != rank - 1) bad(i, "stride= needs rank-1 entries (byte strides of dims 1..rank-1)");
      for (auto &v : st) if (!validValueExpr(v, nargs, why)) bad(i, "stride: " + why);
    }
    long elem = std::strtol(kv["elem"].c_str(), nullptr, 0);
    if (elem != 1 && elem != 2 && elem != 4 && elem != 8) bad(i, "elem must be 1, 2, 4 or 8");
    if (kv.count("layout") && kv["layout"] != "row" && kv["layout"] != "kmajor") bad(i, "layout must be row or kmajor");
    if (kv["layout"] == "kmajor" && rank > 2) bad(i, "layout=kmajor needs rank <= 2");
    if (kv.count("fill") && kv.count("fillf")) bad(i, "give fill= or fillf=, not both");
    lines.push_back("desc " + kname + " " + trim(Spec->getString().str()));
  }
  std::ofstream out("dxa_descriptors.txt", cupbop_dxa_sidecar_written ? std::ios::app : std::ios::trunc);
  if (!out) {
    fprintf(stderr, "error: cannot write dxa_descriptors.txt\n");
    exit(1);
  }
  if (!cupbop_dxa_sidecar_written)
    out << "# DXA descriptors for the CuPBoP host runtime (written by kernelTranslator from !vx.dxa.desc)\n"
           "# desc <kernel> slot=S base=argK[+B] size=v,.. [stride=v,..] box=t,.. elem=E [rank=R] [layout=row|kmajor]"
           " [smem_stride=B] [fill=P|fillf=F]\n";
  for (auto &l : lines) out << l << "\n";
  cupbop_dxa_sidecar_written = true;
  N->eraseFromParent(); // the descriptors live in the sidecar now
  fprintf(stderr, "[CuPBoP] wrote %zu DXA descriptor(s) from !vx.dxa.desc to dxa_descriptors.txt\n", lines.size());
}

// For lower_async_ptx (async_ptx.cpp): the pointer an address operand was computed from (see tracePointer),
// with fresh dominator trees (the caller changes the CFG between calls). nullptr when it cannot be traced.
Value *cupbop_trace_pointer(Value *V) {
  std::map<Function *, std::unique_ptr<DominatorTree>> DTs;
  return tracePointer(V, DTs);
}
