// triton_ir.cpp: the input side of the Triton path (TRITON_CUPBOP=1).
//
// The LLVM IR of a stock Triton (no fork, make_llir of its NVIDIA backend) reaches memory through PTX inline asm and
// uses NVVM intrinsics newer than this translator's LLVM. Both are lowered here, first thing, so that every later pass
// sees plain loads, stores and the intrinsics it already handles:
//   PTX asm     [@p] ld.{global,shared}[.vN].bK, [@p] st.{global,shared}[.vN].bK, mov (the "other" value of a masked
//               load): the small statement language Triton's LoadStoreOpToLLVM and TargetInfo print
//               mma.sync m16n8k16 f16 -> llvm.nvvm.mma.m16n8k16.row.col.f32.f32, the form of a lifted module
//   intrinsics  llvm.nvvm.barrier.cta.sync.aligned.all -> llvm.nvvm.barrier0, llvm.nvvm.div.full -> fdiv,
//               llvm.nvvm.{ex2,lg2,rcp,rsqrt,sqrt,sin,cos}.*.f32 -> *.f, llvm.nvvm.ldmatrix.*.p3 -> the ldmatrix asm of a lifted module
// An asm this file does not know and no later pass handles stops the translation. replace_asm_call would drop it with
// a warning and leave undef, which is how a stock Triton vecadd became an empty kernel.
#include "triton_ir.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include <cstdio>
#include <cstdlib>
#include <map>
#include <regex>
#include <string>
#include <vector>

using namespace llvm;

namespace {

[[noreturn]] void die(const std::string &what, const std::string &a) {
  fprintf(stderr, "kernelTranslator: error: Triton input: %s: %s\n", what.c_str(), a.c_str());
  exit(1);
}

std::vector<std::string> split_statements(const std::string &a) {
  std::vector<std::string> out;
  size_t p = 0;
  while (p < a.size()) {
    size_t q = a.find(';', p);
    std::string s = a.substr(p, q == std::string::npos ? std::string::npos : q - p);
    size_t b = s.find_first_not_of(" \t\r\n"), e = s.find_last_not_of(" \t\r\n");
    if (b != std::string::npos) out.push_back(s.substr(b, e - b + 1));
    if (q == std::string::npos) break;
    p = q + 1;
  }
  return out;
}

// "{ $0, $1 }" or "$0" -> operand numbers; -1 when something else is listed
std::vector<int> operand_list(const std::string &s) {
  std::vector<int> out;
  static const std::regex tok(R"(\$(\d+))");
  for (auto it = std::sregex_iterator(s.begin(), s.end(), tok); it != std::sregex_iterator(); ++it)
    out.push_back(std::stoi((*it)[1].str()));
  return out;
}

struct MemOp {
  unsigned addrspace = 0, bits = 0, vec = 1;
  bool isVolatile = false, ok = false;
};

// ".global.L1::evict_first.v4.b32" -> space, vector width, element bits. An ordering or scope (.acquire, .relaxed,
// .gpu ...) is not a plain load or store: such a form stays unknown.
MemOp parse_modifiers(const std::string &m) {
  MemOp r;
  size_t p = 0;
  while (p < m.size()) {
    size_t q = m.find('.', p + 1);
    std::string t = m.substr(p + 1, q == std::string::npos ? std::string::npos : q - p - 1);
    p = q == std::string::npos ? m.size() : q;
    if (t == "global") r.addrspace = 1;
    else if (t == "shared" || t == "shared::cta") r.addrspace = 3;
    else if (t == "volatile") r.isVolatile = true;
    else if (t == "v2") r.vec = 2;
    else if (t == "v4") r.vec = 4;
    else if (t.size() >= 2 && (t[0] == 'b' || t[0] == 'u' || t[0] == 's' || t[0] == 'f') && isdigit((unsigned char)t[1]))
      r.bits = std::stoi(t.substr(1));
    else if (t == "ca" || t == "cg" || t == "cs" || t == "lu" || t == "cv" || t == "wb" || t == "wt" || t == "nc" ||
             t.rfind("L1::", 0) == 0 || t.rfind("L2::", 0) == 0)
      continue; // cache hints
    else
      return r;
  }
  r.ok = r.addrspace && r.bits;
  return r;
}

// the asm of one call, statement by statement, on values: operand $i of the asm text is regs[i]
class AsmLowering {
  CallInst *CI;
  std::string text;
  unsigned nOut = 0;
  std::vector<Value *> regs;
  std::vector<Type *> outTy;

public:
  explicit AsmLowering(CallInst *C) : CI(C), text(cast<InlineAsm>(C->getCalledOperand())->getAsmString()) {
    Type *RT = CI->getType();
    if (auto *ST = dyn_cast<StructType>(RT)) for (Type *T : ST->elements()) outTy.push_back(T);
    else if (!RT->isVoidTy()) outTy.push_back(RT);
    nOut = outTy.size();
    regs.assign(nOut + CI->arg_size(), nullptr);
    for (unsigned i = 0; i < CI->arg_size(); ++i) regs[nOut + i] = CI->getArgOperand(i);
  }

  Value *reg(unsigned i) {
    if (i >= regs.size()) die("operand out of range", text);
    return regs[i];
  }
  Value *pred(const std::string &neg, const std::string &num, IRBuilder<> &B) {
    if (num.empty()) return nullptr;
    Value *P = reg(std::stoi(num));
    if (!P->getType()->isIntegerTy(1)) die("predicate is not i1", text);
    return neg.empty() ? P : B.CreateNot(P);
  }
  Value *address(const std::string &num, const std::string &off, unsigned as, IRBuilder<> &B) {
    Value *A = reg(std::stoi(num));
    Type *PT = PointerType::get(CI->getContext(), as);
    if (A->getType()->isIntegerTy()) A = B.CreateIntToPtr(A, PT);
    else if (A->getType() != PT) A = B.CreateAddrSpaceCast(A, PT);
    if (!off.empty() && std::stoi(off) != 0) A = B.CreateConstGEP1_32(B.getInt8Ty(), A, std::stoi(off));
    return A;
  }
  Value *as_bits(Value *V, unsigned bits, IRBuilder<> &B) {
    Type *IT = B.getIntNTy(bits);
    if (V->getType() == IT) return V;
    if (V->getType()->getPrimitiveSizeInBits() == bits) return B.CreateBitCast(V, IT);
    if (V->getType()->isIntegerTy()) return B.CreateZExtOrTrunc(V, IT);
    die("store operand of another width", text);
  }

  // Masked access: the access runs in its own block under the predicate, as PTX does (a masked-off lane must not touch
  // its address). A constant predicate needs no block.
  template <class Body> void guarded(Value *P, IRBuilder<> &B, Body body) {
    if (auto *K = dyn_cast_or_null<ConstantInt>(P)) {
      if (K->isZero()) return;
      P = nullptr;
    }
    if (!P) { body(B, nullptr); return; }
    Instruction *T = SplitBlockAndInsertIfThen(P, CI->getIterator(), false);
    IRBuilder<> TB(T);
    body(TB, T);
    B.SetInsertPoint(CI);
  }

  bool lower() {
    static const std::regex mov(R"(^(?:@(!?)\$(\d+)\s+)?mov\.[bus]\d+\s+\$(\d+)\s*,\s*(\$\d+|0x[0-9a-fA-F]+|-?\d+)$)");
    // a trailing $n is the cache policy of .L2::cache_hint; createpolicy makes that policy, which means nothing here
    static const std::regex ld(R"(^(?:@(!?)\$(\d+)\s+)?ld((?:\.[A-Za-z0-9_:]+)+)\s+(\{[^}]*\}|\$\d+)\s*,\s*\[\s*\$(\d+)(?:\s*\+\s*(-?\d+))?\s*\](?:\s*,\s*\$\d+)?$)");
    static const std::regex st(R"(^(?:@(!?)\$(\d+)\s+)?st((?:\.[A-Za-z0-9_:]+)+)\s+\[\s*\$(\d+)(?:\s*\+\s*(-?\d+))?\s*\]\s*,\s*(\{[^}]*\}|\$\d+)(?:\s*,\s*\$\d+)?$)");
    static const std::regex policy(R"(^createpolicy\.[A-Za-z0-9_:.]+\s+\$\d+\s*,.*$)");
    const auto stmts = split_statements(text);
    // parse everything first: a form with one unknown statement stays untouched
    for (const auto &s : stmts) {
      std::smatch m;
      if (std::regex_match(s, m, mov)) { if (m[2].matched) return false; continue; }
      if (std::regex_match(s, policy)) continue;
      if (std::regex_match(s, m, ld) || std::regex_match(s, m, st)) { if (!parse_modifiers(m[3].str()).ok) return false; continue; }
      return false;
    }
    IRBuilder<> B(CI);
    for (const auto &s : stmts) {
      std::smatch m;
      if (std::regex_match(s, policy)) continue;
      if (std::regex_match(s, m, mov)) {
        const unsigned d = std::stoi(m[3].str());
        if (d >= nOut) die("mov to an input", text);
        const std::string v = m[4].str();
        if (v[0] == '$') regs[d] = reg(std::stoi(v.substr(1)));
        else regs[d] = outTy[d]->isIntegerTy() ? (Value *)ConstantInt::get(outTy[d], std::stoull(v, nullptr, 0))
                                               : B.CreateBitCast(B.getIntN(outTy[d]->getPrimitiveSizeInBits(), std::stoull(v, nullptr, 0)), outTy[d]);
      } else if (std::regex_match(s, m, ld)) {
        const MemOp op = parse_modifiers(m[3].str());
        const std::vector<int> dst = operand_list(m[4].str());
        if (dst.size() != op.vec) die("ld operand count", text);
        Value *P = pred(m[1].str(), m[2].str(), B);
        const unsigned bytes = op.bits / 8;
        Value *A = address(m[5].str(), m[6].str(), op.addrspace, B);
        // A masked-off lane keeps a defined register in PTX. It must not become undef here: Triton feeds such values to
        // shuffles, the helper's parameter is noundef, and LLVM then drops the predicate as an unreachable path (the
        // softmax store ran on every 4th thread and overwrote the next CTAs' shared memory).
        std::vector<Value *> old;
        for (int d : dst) old.push_back(regs[d] ? regs[d] : Constant::getNullValue(outTy[d]));
        guarded(P, B, [&](IRBuilder<> &G, Instruction *T) {
          for (unsigned i = 0; i < op.vec; ++i) {
            Type *Ty = outTy[dst[i]];
            Value *EA = i ? G.CreateConstGEP1_32(G.getInt8Ty(), A, i * bytes) : A;
            Value *V;
            if (Ty->getPrimitiveSizeInBits() == op.bits) V = G.CreateAlignedLoad(Ty, EA, Align(bytes), op.isVolatile);
            else die("ld result of another width", text);
            if (!T) { regs[dst[i]] = V; continue; }
            BasicBlock *Then = T->getParent(), *Cont = CI->getParent();
            PHINode *Phi = PHINode::Create(Ty, 2, "", Cont->begin());
            Phi->addIncoming(V, Then);
            Phi->addIncoming(old[i], Then->getSinglePredecessor());
            regs[dst[i]] = Phi;
          }
        });
      } else if (std::regex_match(s, m, st)) {
        const MemOp op = parse_modifiers(m[3].str());
        const std::vector<int> src = operand_list(m[6].str());
        if (src.size() != op.vec) die("st operand count", text);
        Value *P = pred(m[1].str(), m[2].str(), B);
        const unsigned bytes = op.bits / 8;
        Value *A = address(m[4].str(), m[5].str(), op.addrspace, B);
        guarded(P, B, [&](IRBuilder<> &G, Instruction *) {
          for (unsigned i = 0; i < op.vec; ++i) {
            Value *EA = i ? G.CreateConstGEP1_32(G.getInt8Ty(), A, i * bytes) : A;
            G.CreateAlignedStore(as_bits(reg(src[i]), op.bits, G), EA, Align(bytes), op.isVolatile);
          }
        });
      }
    }
    B.SetInsertPoint(CI);
    if (nOut == 1) {
      if (!regs[0]) die("output never written", text);
      CI->replaceAllUsesWith(regs[0]);
    } else if (nOut > 1) {
      Value *R = PoisonValue::get(CI->getType());
      for (unsigned i = 0; i < nOut; ++i) {
        if (!regs[i]) die("output never written", text);
        R = B.CreateInsertValue(R, regs[i], i);
      }
      CI->replaceAllUsesWith(R);
    }
    CI->eraseFromParent();
    return true;
  }
};

// Triton's mma.sync (i32 registers, the accumulator tied to the result) -> the intrinsic a lifted module has, with its operand
// order: a, b, c. Other shapes stay asm for lower_inline_mma_sync.
bool mma_to_intrinsic(CallInst *CI, const std::string &a) {
  static const std::regex form(R"(^\s*mma\.sync\.aligned\.m16n8k16\.row\.col\.f32\.f16\.f16\.f32\s*\{\s*\$0,\s*\$1,\s*\$2,\s*\$3\s*\},\s*\{\s*\$8,\s*\$9,\s*\$10,\s*\$11\s*\},\s*\{\s*\$12,\s*\$13\s*\},\s*\{\s*\$4,\s*\$5,\s*\$6,\s*\$7\s*\};?\s*$)");
  if (!std::regex_match(a, form) || CI->arg_size() != 10) return false;
  LLVMContext &C = CI->getContext();
  Type *F32 = Type::getFloatTy(C), *V2H = FixedVectorType::get(Type::getHalfTy(C), 2);
  IRBuilder<> B(CI);
  std::vector<Value *> args;
  for (unsigned i = 4; i < 10; ++i) args.push_back(B.CreateBitCast(CI->getArgOperand(i), V2H));
  for (unsigned i = 0; i < 4; ++i) args.push_back(CI->getArgOperand(i));
  std::vector<Type *> tys;
  for (Value *V : args) tys.push_back(V->getType());
  Type *RT = StructType::get(C, {F32, F32, F32, F32});
  if (CI->getType() != RT) return false;
  CI->replaceAllUsesWith(B.CreateCall(CI->getModule()->getOrInsertFunction("llvm.nvvm.mma.m16n8k16.row.col.f32.f32", FunctionType::get(RT, tys, false)), args));
  CI->eraseFromParent();
  return true;
}

// what later passes lower themselves (replace_asm_call, lower_async_ptx, lower_ldmatrix_asm)
bool handled_later(const std::string &a) {
  for (const char *k : {"mma.sync", "ldmatrix", "stmatrix", "cvt.rna", "%laneid", "mad.lo.cc", "mbarrier", "cp.async", "wgmma", "fence."})
    if (a.find(k) != std::string::npos) return true;
  return false;
}

// fptrunc / fpext between float and a vector of half: element by element. Next to a store the back end folds the vector form
// into a truncating vector store, which a target without half registers cannot select ("Cannot select: store ... trunc to
// v2f16", the p.to(tl.float16) of FlashAttention).
void scalarize_half_casts(Module *M) {
  std::vector<CastInst *> casts;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *C = dyn_cast<CastInst>(&I))
          if ((isa<FPTruncInst>(C) || isa<FPExtInst>(C)) && C->getType()->isVectorTy()) casts.push_back(C);
  for (CastInst *C : casts) {
    IRBuilder<> B(C);
    auto *VT = cast<FixedVectorType>(C->getType());
    Value *R = PoisonValue::get(VT);
    for (unsigned i = 0; i < VT->getNumElements(); ++i) {
      Value *E = B.CreateExtractElement(C->getOperand(0), i);
      R = B.CreateInsertElement(R, B.CreateCast(C->getOpcode(), E, VT->getElementType()), i);
    }
    C->replaceAllUsesWith(R);
    C->eraseFromParent();
  }
}

// The ldmatrix intrinsic -> the asm CuLifter writes for LDSM, with an integer shared address: from here on a Triton ldmatrix is the
// same thing as a lifted one (lower_ldmatrix_asm, and the lift passes that read it). Each lane passes the address of its own
// row, so the layout, swizzled or not, stays Triton's business.
void lower_ldmatrix(CallInst *CI, StringRef name) {
  LLVMContext &C = CI->getContext();
  Type *I32 = Type::getInt32Ty(C);
  const int num = name.contains(".x4") ? 4 : name.contains(".x2") ? 2 : 1;
  std::string regs, cons;
  for (int i = 0; i < num; ++i) { regs += (i ? ",$" : "$") + std::to_string(i); cons += "=r,"; }
  const std::string text = "ldmatrix.sync.aligned.m8n8.x" + std::to_string(num) + (name.contains(".trans") ? ".trans" : "") +
                           ".shared.b16 {" + regs + "}, [$" + std::to_string(num) + "];";
  IRBuilder<> B(CI);
  Value *A32 = B.CreatePtrToInt(CI->getArgOperand(0), I32, "smem.win");
  auto *FT = FunctionType::get(CI->getType(), {I32}, false);
  CI->replaceAllUsesWith(B.CreateCall(InlineAsm::get(FT, text, cons + "r", /*hasSideEffects=*/true), {A32}));
  CI->eraseFromParent();
}

} // namespace

void lower_triton_input(Module *M) {
  LLVMContext &C = M->getContext();
  std::vector<CallInst *> calls;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I)) calls.push_back(CI);
  static const std::regex nvvm_f32(R"(^llvm\.nvvm\.(ex2|lg2|rcp|rsqrt|sqrt|sin|cos)\.[a-z]+(\.ftz)?\.f32$)");
  unsigned nAsm = 0, nIntr = 0;
  for (CallInst *CI : calls) {
    if (CI->isInlineAsm()) {
      const std::string a = cast<InlineAsm>(CI->getCalledOperand())->getAsmString();
      if (mma_to_intrinsic(CI, a)) { nAsm++; continue; }
      if (handled_later(a)) continue;
      if (!AsmLowering(CI).lower()) die("unknown PTX asm", a);
      nAsm++;
      continue;
    }
    Function *Fn = CI->getCalledFunction();
    if (!Fn) continue;
    const StringRef n = Fn->getName();
    IRBuilder<> B(CI);
    if (n == "llvm.nvvm.barrier.cta.sync.aligned.all") {
      auto *K = dyn_cast<ConstantInt>(CI->getArgOperand(0));
      if (!K || !K->isZero()) die("named barrier", n.str());
      B.CreateCall(M->getOrInsertFunction("llvm.nvvm.barrier0", FunctionType::get(Type::getVoidTy(C), false)));
      CI->eraseFromParent();
    } else if (n == "llvm.nvvm.div.full") {
      CI->replaceAllUsesWith(B.CreateFDiv(CI->getArgOperand(0), CI->getArgOperand(1)));
      CI->eraseFromParent();
    } else if (std::regex_match(n.str(), nvvm_f32)) {
      // LLVM 21 renamed these .f -> .f32. Under the new name the .ftz forms missed the MUFU and became libm calls.
      std::vector<Type *> tys;
      std::vector<Value *> args;
      for (Value *A : CI->args()) { tys.push_back(A->getType()); args.push_back(A); }
      FunctionType *FT = FunctionType::get(CI->getType(), tys, false);
      const std::string old = n.drop_back(2).str(); // ...f32 -> ...f
      CI->replaceAllUsesWith(B.CreateCall(M->getOrInsertFunction(old, FT), args));
      CI->eraseFromParent();
    } else if (n.starts_with("llvm.nvvm.ldmatrix.sync.aligned.m8n8.")) {
      lower_ldmatrix(CI, n);
    } else {
      continue;
    }
    nIntr++;
  }
  scalarize_half_casts(M);
  if (const char *f = std::getenv("CUPBOP_TRITON_DUMP")) { // the module as the rest of the translator sees it
    std::error_code EC;
    raw_fd_ostream os(f, EC);
    if (!EC) M->print(os, nullptr);
  }
  fprintf(stderr, "[CuPBoP] Triton input: %u PTX asm, %u intrinsics lowered\n", nAsm, nIntr);
}
