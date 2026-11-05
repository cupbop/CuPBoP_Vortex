// pairjoin.cpp (2026-11-04): LLVM 20 pass plugin for lifted NVVM IR, run BEFORE CuPBoP on the raw lift output
// (opt -load-pass-plugin=libpairjoin.so -passes='function(instsimplify,early-cse),lo-pair').
//
// SASS computes 64-bit values as two 32-bit registers. The lift keeps that: IADD3 + carry predicate + IADD3.X, IMAD.WIDE + two
// IMAD for the cross products, LEA + LEA.HI.X, SHF.L.U64.HI, ISETP + ISETP.EX. Vortex is RV64, where each of those is one i64
// instruction, and SCEV cannot see an induction variable that lives in two i32 phis. This pass rebuilds the i64 value.
//
// Only bit identities, no assumption about the inputs. For a pair (lo, hi) the pass looks for an i64 V with
// lo == trunc(V) and hi == trunc(V >> 32) on every execution. What it may do:
//   sum     lo = trunc(T), hi = H1 + .. + Hn + carry(T)           ->  V = T + ((H1 + .. + Hn) << 32)      mod 2^64
//           carry(T) is `trunc(T >> 32)` (any T), or a bool `(T >> 32) >= 1`, `trunc (T >> 32) to i1` only if T < 2^33 is proved from
//           the terms of T (each zext i32 < 2^32, each zext i1 <= 1, each and-mask, constants), or the two IADD3 carry outs
//           `(T >> 32) >= 1` and `(T >> 32) >= 2` together, only if T < 3 * 2^32. Otherwise no rewrite.
//   high    lo == low(S), hi = H1 + .. + Hn + (S >> 32)            ->  V = S + ((H1 + .. + Hn) << 32)
//           low(S) is proved structurally: S = shl(F, k), lo = shl(low(F), k) or mul(low(F), 2^k), ...
//   terms   T + (H << 32) is a sum mod 2^64, so terms may be regrouped: and(S, M32) + high(S) -> S,
//           zext(a) * zext(b) + (a * bh + ah * b) << 32 -> Pair(a, ah) * Pair(b, bh), zext(x) + (y << 32) -> Pair(x, y)
//   bitwise lo = op(a, b), hi = op(c, d) for op in and, or, xor    ->  V = op(Pair(a, c), Pair(b, d))
//   select  lo = c ? a : b, hi = c ? d : e                         ->  V = c ? Pair(a, d) : Pair(b, e)
//   phi     lo, hi phis of one block                               ->  V = phi of Pair(lo_in, hi_in), per predecessor
//   ext     hi == 0 -> zext(lo); hi == sign(lo) -> sext(lo); both constants -> constant
//   lanes   lanes 2j, 2j + 1 of one <N x i32> -> the same bits as i64 (little endian datalayout)
// Nothing else. A pair that matches none of these stays as it is (the `pack` or the compare is left in place).
// What gets replaced: every `or(zext lo, shl(zext hi, 32))` and every ISETP.EX select `hi1 == hi2 ? lo1 P' lo2 : hi1 P hi2`
// (-> icmp on the two i64 values). The remaining uses of a joined phi pair read trunc(V) and trunc(V >> 32).
//
// Env: LP_DEBUG=1 prints what stayed; LP_OFF_PHI=1, LP_OFF_CMP=1 turn off parts (diagnosis only).
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"
#include <cstdlib>
#include <map>
#include <string>
#include <vector>
using namespace llvm;
using namespace llvm::PatternMatch;

namespace {
const uint64_t M32 = 0xFFFFFFFFull;
bool envOn(const char *n) { const char *e = getenv(n); return e && atoi(e) != 0; }

struct Term0 {                    // term of the i64 sum at weight 2^0
  enum K { Z, L, MUL, C, B, O } k; // zext(v) | and(v, M32) | zext(a) * zext(b) | constant c | zext(i1 v) | other i64 v
  Value *v = nullptr, *a = nullptr, *b = nullptr; uint64_t c = 0; bool used = false;
};
struct TermH {                    // term of the high word (weight 2^32, mod 2^32)
  enum K { V32, BOOL, HIGH, MUL32, V64, C } k; // i32 v | zext(i1 v) | v >> 32 | a * b (i32) | i64 v, low word | constant c
  Value *v = nullptr, *a = nullptr, *b = nullptr, *n = nullptr; uint64_t c = 0; bool used = false; // n: the node in the tree
};

// ---- structure queries (no IR changes) --------------------------------------------------------------------------------
bool matchPack(Value *V, Value *&lo, Value *&hi) {
  Value *a, *b;
  if (!V->getType()->isIntegerTy(64) || !match(V, m_c_Or(m_ZExt(m_Value(a)), m_Shl(m_ZExt(m_Value(b)), m_SpecificInt(32))))) return false;
  if (!a->getType()->isIntegerTy(32) || !b->getType()->isIntegerTy(32)) return false;
  lo = a; hi = b; return true;
}
// the i32 x with low(v) == x, when the shape shows it
Value *lowOf(Value *v) {
  Value *a, *h;
  if (match(v, m_ZExt(m_Value(a))) && a->getType()->isIntegerTy(32)) return a;
  if (match(v, m_SExt(m_Value(a))) && a->getType()->isIntegerTy(32)) return a;
  if (matchPack(v, a, h)) return a;
  return nullptr;
}
bool lowEq64(Value *x, Value *s, int d = 0) {          // low 32 bits of two i64 values are the same
  if (x == s) return true;
  if (d > 6) return false;
  Value *p, *q; const APInt *k1, *k2;
  if (match(x, m_Shl(m_Value(p), m_APInt(k1))) && match(s, m_Shl(m_Value(q), m_APInt(k2))) && *k1 == *k2 && k1->ult(64)) return lowEq64(p, q, d + 1);
  Value *a = lowOf(x), *b = lowOf(s);
  return a && a == b;
}
bool lowEq(Value *x, Value *s, int d = 0) {            // i32 x == low(i64 s)
  if (d > 6) return false;
  Value *y, *f; const APInt *k, *kk;
  if (Value *l = lowOf(s)) if (l == x) return true;
  if (match(x, m_Trunc(m_Value(y))) && y->getType()->isIntegerTy(64) && lowEq64(y, s)) return true;
  if (match(s, m_Shl(m_Value(f), m_APInt(k))) && k->ult(32)) {
    if (match(x, m_Shl(m_Value(y), m_APInt(kk))) && kk->ult(32) && kk->getZExtValue() == k->getZExtValue()) return lowEq(y, f, d + 1);
    if (match(x, m_Mul(m_Value(y), m_APInt(kk))) && kk->isPowerOf2() && kk->logBase2() == k->getZExtValue()) return lowEq(y, f, d + 1);
  }
  return false;
}
// y == (x >> 31) arithmetic: returns x. Shapes: ashr i32, or SHF.R.S32.HI = trunc(lshr(ashr(shl(zext x, 32), 31), 32))
Value *signSrc(Value *y) {
  Value *x;
  if (match(y, m_AShr(m_Value(x), m_SpecificInt(31))) && x->getType()->isIntegerTy(32)) return x;
  if (match(y, m_Trunc(m_LShr(m_AShr(m_Shl(m_ZExt(m_Value(x)), m_SpecificInt(32)), m_SpecificInt(31)), m_SpecificInt(32)))) && x->getType()->isIntegerTy(32)) return x;
  if (match(y, m_Trunc(m_LShr(m_SExt(m_Value(x)), m_SpecificInt(32)))) && x->getType()->isIntegerTy(32)) return x;
  return nullptr;
}
// sees through the lift's i1 <-> i32 carriers
Value *stripBool(Value *v) {
  for (int i = 0; i < 8; i++) {
    Value *x;
    if (match(v, m_Trunc(m_ZExt(m_Value(x)))) && x->getType()->isIntegerTy(1) && v->getType()->isIntegerTy(1)) { v = x; continue; }
    if (match(v, m_SpecificICmp(ICmpInst::ICMP_NE, m_ZExt(m_Value(x)), m_Zero())) && x->getType()->isIntegerTy(1)) { v = x; continue; }
    if (match(v, m_SpecificICmp(ICmpInst::ICMP_NE, m_Zero(), m_ZExt(m_Value(x)))) && x->getType()->isIntegerTy(1)) { v = x; continue; }
    if (auto *Z = dyn_cast<ZExtInst>(v)) if (Z->getSrcTy()->isIntegerTy(1)) { v = Z->getOperand(0); continue; }
    break;
  }
  return v;
}
// b == ((T >> 32) >= 2): IADD3 second carry out. Returns T or null.
Value *carry2Src(Value *b) {
  b = stripBool(b);
  Value *t;
  if (match(b, m_SpecificICmp(ICmpInst::ICMP_UGE, m_LShr(m_Value(t), m_SpecificInt(32)), m_SpecificInt(2)))) return t;
  return nullptr;
}
// b == ((T >> 32) >= 1) if T < 2^33. Returns T or null.
Value *carrySrc(Value *b) {
  b = stripBool(b);
  Value *t;
  if (match(b, m_Trunc(m_LShr(m_Value(t), m_SpecificInt(32))))) return t;                                     // LEA cout
  if (match(b, m_SpecificICmp(ICmpInst::ICMP_UGE, m_LShr(m_Value(t), m_SpecificInt(32)), m_One()))) return t;  // IADD3 cout
  if (match(b, m_SpecificICmp(ICmpInst::ICMP_NE, m_LShr(m_Value(t), m_SpecificInt(32)), m_Zero()))) return t;
  if (match(b, m_SpecificICmp(ICmpInst::ICMP_UGT, m_LShr(m_Value(t), m_SpecificInt(32)), m_Zero()))) return t;
  if (match(b, m_SpecificICmp(ICmpInst::ICMP_UGT, m_Value(t), m_SpecificInt(M32)))) return t;
  return nullptr;
}
// sum of i64 terms, weight 2^0
void flatten0(Value *v, std::vector<Term0> &o, int d = 0) {
  Value *a, *b; const APInt *c;
  if (d < 12 && match(v, m_Add(m_Value(a), m_Value(b)))) { flatten0(a, o, d + 1); flatten0(b, o, d + 1); return; }
  Term0 t{};
  if (auto *C = dyn_cast<ConstantInt>(v)) { t.k = Term0::C; t.c = C->getZExtValue(); o.push_back(t); return; }
  if (match(v, m_ZExt(m_Value(a)))) {
    if (a->getType()->isIntegerTy(32)) { t.k = Term0::Z; t.v = a; o.push_back(t); return; }
    if (a->getType()->isIntegerTy(1)) { t.k = Term0::B; t.v = a; o.push_back(t); return; }
  }
  if (match(v, m_And(m_Value(a), m_SpecificInt(M32)))) { t.k = Term0::L; t.v = a; o.push_back(t); return; }
  if (match(v, m_Mul(m_ZExt(m_Value(a)), m_ZExt(m_Value(b)))) && a->getType()->isIntegerTy(32) && b->getType()->isIntegerTy(32)) {
    t.k = Term0::MUL; t.a = a; t.b = b; t.v = v; o.push_back(t); return;
  }
  if (match(v, m_Mul(m_ZExt(m_Value(a)), m_APInt(c))) && a->getType()->isIntegerTy(32) && c->getActiveBits() <= 32) {
    t.k = Term0::MUL; t.a = a; t.b = ConstantInt::get(a->getType(), c->getZExtValue()); t.v = v; o.push_back(t); return;
  }
  t.k = Term0::O; t.v = v; o.push_back(t);
}
void flattenH(Value *v, std::vector<TermH> &o, int d = 0) {
  Value *a, *b;
  TermH t{};
  if (d < 12 && match(v, m_Add(m_Value(a), m_Value(b)))) { flattenH(a, o, d + 1); flattenH(b, o, d + 1); return; }
  if (auto *C = dyn_cast<ConstantInt>(v)) { t.k = TermH::C; t.c = C->getZExtValue(); o.push_back(t); return; }
  if (match(v, m_Trunc(m_Value(a))) && a->getType()->isIntegerTy(64) && v->getType()->isIntegerTy(32)) { flattenH(a, o, d + 1); return; }
  if (match(v, m_ZExt(m_Value(a)))) {
    if (a->getType()->isIntegerTy(1)) { t.k = TermH::BOOL; t.v = a; t.n = v; o.push_back(t); return; }
    if (a->getType()->isIntegerTy(32)) { flattenH(a, o, d + 1); return; }
  }
  if (v->getType()->isIntegerTy(64) && match(v, m_LShr(m_Value(a), m_SpecificInt(32)))) { t.k = TermH::HIGH; t.v = a; t.n = v; o.push_back(t); return; }
  if (v->getType()->isIntegerTy(32) && match(v, m_Mul(m_Value(a), m_Value(b)))) { t.k = TermH::MUL32; t.a = a; t.b = b; t.v = v; o.push_back(t); return; }
  if (v->getType()->isIntegerTy(32)) { t.k = TermH::V32; t.v = v; o.push_back(t); return; }
  t.k = TermH::V64; t.v = v; o.push_back(t);
}
// exact upper bound of the sum: true when sum < limit; false when a term has no bound
bool sumBelow(const std::vector<Term0> &w, unsigned __int128 limit) {
  unsigned __int128 ub = 0;
  for (auto &t : w) switch (t.k) {
    case Term0::Z: case Term0::L: ub += M32; break;
    case Term0::B: ub += 1; break;
    case Term0::C: ub += t.c; break;
    default: return false;
  }
  return ub < limit;
}

// ---- the join -----------------------------------------------------------------------------------------------------------
struct Join {
  Function &F; DominatorTree &DT; Type *I32, *I64;
  struct E { Value *v; bool leaf, loose; };   // leaf: only a pack; loose: built, but some high-word terms found no low partner
  std::map<std::pair<Value *, Value *>, E> memo;
  std::vector<std::tuple<PHINode *, PHINode *, PHINode *>> phis; // lo, hi, V
  DenseSet<Value *> fresh;                                        // instructions this pass made
  bool noPhi = envOn("LP_OFF_PHI"), debug = envOn("LP_DEBUG");
  std::map<std::string, int> stat;

  Join(Function &f, DominatorTree &dt) : F(f), DT(dt) { I32 = Type::getInt32Ty(F.getContext()); I64 = Type::getInt64Ty(F.getContext()); }

  Value *mk(Value *v) { if (isa<Instruction>(v)) fresh.insert(v); return v; }
  Value *z(IRBuilder<> &B, Value *x) { return mk(B.CreateZExt(x, I64)); }
  Value *hiShift(IRBuilder<> &B, Value *y) { return mk(B.CreateShl(y->getType()->isIntegerTy(64) ? y : z(B, y), 32)); }

  // where a value of (lo, hi) can live: after the later of the two, when one dominates the other; otherwise at IP
  Instruction *natural(Value *lo, Value *hi, Instruction *IP) {
    auto *a = dyn_cast<Instruction>(lo), *b = dyn_cast<Instruction>(hi);
    Instruction *L = nullptr;
    if (a && b) { if (a == b || DT.dominates(a, b)) L = b; else if (DT.dominates(b, a)) L = a; else return IP; }
    else L = a ? a : b;
    if (!L) return &*F.getEntryBlock().getFirstInsertionPt();
    if (isa<PHINode>(L)) return &*L->getParent()->getFirstInsertionPt();
    return L->getNextNode();
  }
  bool usableAt(Value *v, Instruction *IP) { auto *I = dyn_cast<Instruction>(v); return !I || DT.dominates(I, IP); }

  Value *get(Value *lo, Value *hi, Instruction *IP, bool *leaf = nullptr, bool *loose = nullptr) {
    auto key = std::make_pair(lo, hi);
    auto it = memo.find(key);
    if (it != memo.end() && usableAt(it->second.v, IP)) { if (leaf) *leaf = it->second.leaf; if (loose) *loose = it->second.loose; return it->second.v; }
    Instruction *N = natural(lo, hi, IP);
    bool lf = false, ls = false;
    Value *v = build(lo, hi, N, lf, ls);
    memo[key] = {v, lf, ls};
    if (leaf) *leaf = lf;
    if (loose) *loose = ls;
    return v;
  }

  Value *pack(IRBuilder<> &B, Value *lo, Value *hi) { return mk(B.CreateOr(z(B, lo), hiShift(B, hi))); }

  Value *build(Value *lo, Value *hi, Instruction *IP, bool &leaf, bool &loose) {
    IRBuilder<> B(IP);
    auto *cl = dyn_cast<ConstantInt>(lo), *ch = dyn_cast<ConstantInt>(hi);
    if (cl && ch) return ConstantInt::get(I64, (ch->getZExtValue() << 32) | (cl->getZExtValue() & M32));
    if (ch && ch->isZero()) return z(B, lo);
    if (signSrc(hi) == lo) return mk(B.CreateSExt(lo, I64));
    if (lo == hi && signSrc(lo)) return mk(B.CreateSExt(lo, I64));   // s = 0 or -1: (s, s) = sext(s)
    if (signSrc(lo) && signSrc(lo) == signSrc(hi)) return mk(B.CreateSExt(lo, I64));
    if (auto *pl = dyn_cast<PHINode>(lo)) if (auto *ph = dyn_cast<PHINode>(hi))
      if (!noPhi && pl->getParent() == ph->getParent() && pl != ph) return joinPhi(pl, ph);
    if (auto *sl = dyn_cast<SelectInst>(lo)) if (auto *sh = dyn_cast<SelectInst>(hi)) if (sl->getCondition() == sh->getCondition() && !isa<Constant>(sl->getCondition())) {
      Value *t = get(sl->getTrueValue(), sh->getTrueValue(), IP), *f = get(sl->getFalseValue(), sh->getFalseValue(), IP);
      return mk(B.CreateSelect(sl->getCondition(), t, f));
    }
    if (auto *bl = dyn_cast<BinaryOperator>(lo)) if (auto *bh = dyn_cast<BinaryOperator>(hi))
      if (bl->getOpcode() == bh->getOpcode() && bl->isBitwiseLogicOp()) {
        // operands may be listed either way: take the order with fewer leaves
        bool l1 = false, l2 = false, l3 = false, l4 = false;
        Value *a = get(bl->getOperand(0), bh->getOperand(0), IP, &l1), *b = get(bl->getOperand(1), bh->getOperand(1), IP, &l2);
        if (l1 || l2) {
          Value *c = get(bl->getOperand(0), bh->getOperand(1), IP, &l3), *d = get(bl->getOperand(1), bh->getOperand(0), IP, &l4);
          if (!l3 && !l4) { a = c; b = d; }
        }
        return mk(B.CreateBinOp(bl->getOpcode(), a, b));
      }
    if (auto *el = dyn_cast<ExtractElementInst>(lo)) if (auto *eh = dyn_cast<ExtractElementInst>(hi))
      if (Value *v = lanes(el, eh, B)) return v;
    if (Value *v = sum(lo, hi, IP, loose)) return v;
    if (envOn("LP_WIDE")) if (Value *v = wideLoad(lo, hi, B, IP)) return v;   // off: FA2 +56% (main loop 2x), not needed once SIMT modules skip the clean-up
    leaf = true;
    stat["leaf"]++;
    return pack(B, lo, hi);
  }

  // p3: the two words of a 64-bit parameter, read as two i32 from the lifter's byte buffer (sm_5x has no 64-bit LDC): one i64 load. Only an alloca written in the entry block alone, with
  // 8 byte alignment proved: nothing can change between the two reads, and the translator's parameter forwarding then sees the whole value. Without this, instcombine dissolves the pack
  // before forwarding and (a & m) + (a & ~m) stays in the code.
  Value *wideLoad(Value *lo, Value *hi, IRBuilder<> &B, Instruction *IP) {
    auto *a = dyn_cast<LoadInst>(lo), *b = dyn_cast<LoadInst>(hi);
    if (!a || !b || !a->isSimple() || !b->isSimple()) return nullptr;
    const DataLayout &DL = F.getDataLayout(); int64_t oa = 0, ob = 0;
    Value *pa = GetPointerBaseWithConstantOffset(a->getPointerOperand(), oa, DL), *pb = GetPointerBaseWithConstantOffset(b->getPointerOperand(), ob, DL);
    auto *AI = dyn_cast<AllocaInst>(pa);
    if (!AI || pa != pb || ob != oa + 4 || commonAlignment(AI->getAlign(), oa) < Align(8)) return nullptr;
    SmallVector<Value *, 16> w{AI}; SmallPtrSet<Value *, 32> seen;
    while (!w.empty()) { Value *V = w.pop_back_val(); if (!seen.insert(V).second) continue;
      for (User *U : V->users()) { auto *I = dyn_cast<Instruction>(U); if (!I) return nullptr;
        if (isa<GetElementPtrInst>(I) || isa<BitCastInst>(I)) { w.push_back(I); continue; }
        if (isa<LoadInst>(I)) continue;
        if (auto *S = dyn_cast<StoreInst>(I)) { if (S->getValueOperand() == V || S->getParent() != &F.getEntryBlock() || !DT.dominates(S, IP)) return nullptr; continue; }
        if (auto *II = dyn_cast<IntrinsicInst>(I)) if (II->isLifetimeStartOrEnd()) continue;
        return nullptr; } }
    stat["wide_load"]++;
    return mk(B.CreateAlignedLoad(I64, a->getPointerOperand(), Align(8)));
  }

  // lanes 2j, 2j + 1 of one <N x i32> vector: little endian, so they are element j of the same bits as <N/2 x i64>
  Value *lanes(ExtractElementInst *el, ExtractElementInst *eh, IRBuilder<> &B) {
    auto *vt = dyn_cast<FixedVectorType>(el->getVectorOperandType());
    auto *il = dyn_cast<ConstantInt>(el->getIndexOperand()), *ih = dyn_cast<ConstantInt>(eh->getIndexOperand());
    if (!F.getDataLayout().isLittleEndian() || !vt || !il || !ih || el->getVectorOperand() != eh->getVectorOperand() || !vt->getElementType()->isIntegerTy(32)) return nullptr;
    unsigned n = vt->getNumElements(), l = il->getZExtValue();
    if (n % 2 || l % 2 || ih->getZExtValue() != l + 1) return nullptr;
    stat["lanes"]++;
    if (n == 2) return mk(B.CreateBitCast(el->getVectorOperand(), I64));
    return mk(B.CreateExtractElement(mk(B.CreateBitCast(el->getVectorOperand(), FixedVectorType::get(I64, n / 2))), l / 2));
  }

  Value *joinPhi(PHINode *pl, PHINode *ph) {
    IRBuilder<> B(pl->getParent(), pl->getParent()->begin());
    PHINode *V = B.CreatePHI(I64, pl->getNumIncomingValues());
    fresh.insert(V);
    memo[{pl, ph}] = {V, false, false};
    phis.emplace_back(pl, ph, V);
    stat["phi"]++;
    for (unsigned i = 0; i < pl->getNumIncomingValues(); i++) {
      BasicBlock *P = pl->getIncomingBlock(i);
      Value *l = pl->getIncomingValue(i), *h = ph->getIncomingValueForBlock(P);
      V->addIncoming(get(l, h, P->getTerminator()), P);
    }
    return V;
  }

  // does v, read as a high word, contain one of the terms the sum consumes (carry bool or high(S))?
  bool holds(Value *v, const SmallVectorImpl<Value *> &tgt, int d = 0) {   // tgt: nodes of the tree, each consumed once
    for (Value *t : tgt) if (t == v) return true;
    Value *a, *b;
    if (d > 16) return true;           // unknown: never pair this node
    if (match(v, m_Add(m_Value(a), m_Value(b)))) return holds(a, tgt, d + 1) || holds(b, tgt, d + 1);
    if (match(v, m_Trunc(m_Value(a))) && v->getType()->isIntegerTy(32)) return holds(a, tgt, d + 1);
    if (match(v, m_ZExt(m_Value(a)))) return holds(a, tgt, d + 1);
    return false;
  }
  // top-down over the add tree of the high word: a node that is the high half of a zext(x) term of W is joined whole.
  // This keeps nested pairs nested: hi2 = (hi1 + y) + carry2 with lo2 = trunc(zext(lo1) + zext(z)) takes Pair(lo1, hi1), not the terms of hi1.
  void walk(Value *v, std::vector<Term0> &W, SmallVectorImpl<Value *> &tgt, std::vector<TermH> &H, SmallVectorImpl<Value *> &acc, Instruction *IP, bool root, int d = 0) {
    for (unsigned i = 0; i < tgt.size(); i++) if (tgt[i] == v) { tgt.erase(tgt.begin() + i); return; }
    Value *a, *b;
    bool isAdd = match(v, m_Add(m_Value(a), m_Value(b)));
    bool isTr = match(v, m_Trunc(m_Value(a))) && v->getType()->isIntegerTy(32) && a->getType()->isIntegerTy(64);
    bool isZx = match(v, m_ZExt(m_Value(a))) && a->getType()->isIntegerTy(32);
    if (!root && v->getType()->isIntegerTy(32) && !holds(v, tgt)) {
      for (auto &t : W) if (t.k == Term0::Z && !t.used) {
        bool lf = false, ls = false;
        Value *r = get(t.v, v, IP, &lf, &ls);
        if (!lf && !ls) { acc.push_back(r); t.used = true; return; }
      }
    }
    if (d < 16 && isAdd) { Value *x = cast<BinaryOperator>(v)->getOperand(0), *y = cast<BinaryOperator>(v)->getOperand(1); walk(x, W, tgt, H, acc, IP, false, d + 1); walk(y, W, tgt, H, acc, IP, false, d + 1); return; }
    if (d < 16 && (isTr || isZx)) { walk(a, W, tgt, H, acc, IP, false, d + 1); return; }
    flattenH(v, H, 100);
  }

  // lo = trunc(T) or low(S); hi = terms + carry
  Value *sum(Value *lo, Value *hi, Instruction *IP, bool &loose) {
    std::vector<TermH> F; flattenH(hi, F);
    Value *base = nullptr; SmallVector<Value *, 4> tgt;
    // (a) S with lo == low(S) and high(S) a term of hi
    for (auto &h : F) if (h.k == TermH::HIGH && lowEq(lo, h.v)) { base = h.v; tgt.push_back(h.n); stat["high"]++; break; }
    // (a') lo = trunc(Y), Y = shift right of a pair, hi = high word of the same shift
    if (!base) { Value *y; if (match(lo, m_Trunc(m_Value(y))) && y->getType()->isIntegerTy(64)) for (auto &h : F) if (h.k == TermH::HIGH && highEq(y, h.v)) { base = y; tgt.push_back(h.n); stat["shr"]++; break; } }
    std::vector<Term0> W;
    if (base) flatten0(base, W);
    else {
      // (b) lo = trunc(T), carry(T) in hi: one bool with T < 2^33, or both IADD3 carry outs with T < 3 * 2^32
      Value *T;
      if (!match(lo, m_Trunc(m_Value(T))) || !T->getType()->isIntegerTy(64)) return nullptr;
      flatten0(T, W);
      Value *c1 = nullptr, *c2 = nullptr;
      for (auto &h : F) if (h.k == TermH::BOOL) {
        if (!c1 && carrySrc(h.v) == T) c1 = h.n;
        else if (!c2 && carry2Src(h.v) == T) c2 = h.n;
      }
      if (c1 && c2 && sumBelow(W, (unsigned __int128)3 << 32)) { tgt.push_back(c1); tgt.push_back(c2); base = T; stat["carry2"]++; }
      else if (c1 && !c2 && sumBelow(W, (unsigned __int128)1 << 33)) { tgt.push_back(c1); base = T; stat["carry"]++; }
      if (!base) return nullptr;
    }
    IRBuilder<> B(IP);
    SmallVector<Value *, 8> acc;
    std::vector<TermH> H;
    walk(hi, W, tgt, H, acc, IP, true);
    if (!tgt.empty()) { stat["sum_abort"]++; return nullptr; }   // the consumed term was not reached: no rewrite
    // and(X, M32) + high(S) with low(X) == low(S): S
    for (auto &t : W) if (t.k == Term0::L) for (auto &h : H) if (!h.used && h.k == TermH::HIGH && lowEq64(t.v, h.v)) {
      acc.push_back(h.v); t.used = h.used = true; break;
    }
    // a * b + (a * bh + ah * b) << 32: Pair(a, ah) * Pair(b, bh)
    for (auto &t : W) if (t.k == Term0::MUL && !t.used) {
      Value *ah = nullptr, *bh = nullptr;
      for (auto &h : H) if (!h.used && h.k == TermH::MUL32) {
        if (!bh && h.a == t.a) { bh = h.b; h.used = true; }
        else if (!bh && h.b == t.a) { bh = h.a; h.used = true; }
        else if (!ah && h.a == t.b) { ah = h.b; h.used = true; }
        else if (!ah && h.b == t.b) { ah = h.a; h.used = true; }
      }
      if (ah || bh) {
        Value *zero = ConstantInt::get(I32, 0);
        Value *A = get(t.a, ah ? ah : zero, IP), *Bv = get(t.b, bh ? bh : zero, IP);
        acc.push_back(mk(B.CreateMul(A, Bv))); t.used = true; stat["mul"]++;
      }
    }
    // zext(x) + high(S) with x == low(S): S
    for (auto &t : W) if (t.k == Term0::Z && !t.used) for (auto &h : H) if (!h.used && h.k == TermH::HIGH && lowEq(t.v, h.v)) {
      acc.push_back(h.v); t.used = h.used = true; break;
    }
    for (auto &t : W) if (!t.used) switch (t.k) {
      case Term0::Z: acc.push_back(z(B, t.v)); break;
      case Term0::L: acc.push_back(mk(B.CreateAnd(t.v, ConstantInt::get(I64, M32)))); break;
      case Term0::C: acc.push_back(ConstantInt::get(I64, t.c)); break;
      case Term0::B: acc.push_back(mk(B.CreateZExt(t.v, I64))); break;
      case Term0::MUL: case Term0::O: acc.push_back(t.v); break;
    }
    for (auto &h : H) if (!h.used) loose = true;
    for (auto &h : H) if (!h.used) switch (h.k) {
      case TermH::V32: case TermH::MUL32: acc.push_back(hiShift(B, h.v)); break;
      case TermH::V64: acc.push_back(hiShift(B, h.v)); break;
      case TermH::BOOL: acc.push_back(hiShift(B, mk(B.CreateZExt(h.v, I64)))); break;
      case TermH::HIGH: acc.push_back(mk(B.CreateAnd(h.v, ConstantInt::get(I64, ~M32)))); break;
      case TermH::C: acc.push_back(ConstantInt::get(I64, h.c << 32)); break;
    }
    if (acc.empty()) return ConstantInt::get(I64, 0);
    Value *r = acc[0];
    for (unsigned i = 1; i < acc.size(); i++) r = mk(B.CreateAdd(r, acc[i]));
    stat["sum"]++;
    return r;
  }

  // high word of y equals high word of s: same right shift of values with the same high word
  bool highEq(Value *y, Value *s) {
    Value *c, *c2, *l, *h, *h2; const APInt *k, *k2;
    bool yL = match(y, m_LShr(m_Value(c), m_APInt(k))), yA = !yL && match(y, m_AShr(m_Value(c), m_APInt(k)));
    bool sL = match(s, m_LShr(m_Value(c2), m_APInt(k2))), sA = !sL && match(s, m_AShr(m_Value(c2), m_APInt(k2)));
    if (!(yL || yA) || !(sL || sA) || *k != *k2) return false;
    if (!matchPack(c, l, h) || !match(c2, m_Shl(m_ZExt(m_Value(h2)), m_SpecificInt(32))) || h != h2) return false;
    if (yL == sL) return true;     // same kind of shift
    return false;
  }

  bool cmpFlip(ICmpInst::Predicate lo, ICmpInst::Predicate hi, ICmpInst::Predicate &q) {
    using P = ICmpInst::Predicate;
    auto dir = [](P p) { return ICmpInst::isLT(p) ? 1 : ICmpInst::isLE(p) ? 2 : ICmpInst::isGT(p) ? 3 : ICmpInst::isGE(p) ? 4 : 0; };
    if (lo == ICmpInst::ICMP_EQ || lo == ICmpInst::ICMP_NE) { if (hi != lo) return false; q = lo; return true; }
    if (!ICmpInst::isUnsigned(lo) || hi == ICmpInst::ICMP_EQ || hi == ICmpInst::ICMP_NE) return false;
    int a = dir(lo), b = dir(hi);
    bool less = a <= 2, strict = a == 1 || a == 3;
    if (less != (b <= 2)) return false;
    bool sgn = ICmpInst::isSigned(hi);
    q = less ? (strict ? (sgn ? ICmpInst::ICMP_SLT : ICmpInst::ICMP_ULT) : (sgn ? ICmpInst::ICMP_SLE : ICmpInst::ICMP_ULE))
             : (strict ? (sgn ? ICmpInst::ICMP_SGT : ICmpInst::ICMP_UGT) : (sgn ? ICmpInst::ICMP_SGE : ICmpInst::ICMP_UGE));
    return true;
  }
  // hi1 == hi2 ? (lo1 P' lo2) : (hi1 P hi2)  ->  icmp Q Pair(lo1, hi1), Pair(lo2, hi2)
  Value *cmp(SelectInst *S) {
    Value *h1, *h2;
    if (!match(S->getCondition(), m_SpecificICmp(ICmpInst::ICMP_EQ, m_Value(h1), m_Value(h2)))) return nullptr;
    if (!h1->getType()->isIntegerTy(32)) return nullptr;
    auto *tl = dyn_cast<ICmpInst>(stripBool(S->getTrueValue())); auto *th = dyn_cast<ICmpInst>(stripBool(S->getFalseValue()));
    if (!tl || !th || th->getOperand(0) != h1 || th->getOperand(1) != h2) return nullptr;
    ICmpInst::Predicate q;
    if (!cmpFlip(tl->getPredicate(), th->getPredicate(), q)) return nullptr;
    bool f1 = false, f2 = false;
    Value *a = get(tl->getOperand(0), h1, S, &f1), *b = get(tl->getOperand(1), h2, S, &f2);
    if (f1 && f2) return nullptr;    // two plain packs: the compare stays on the words
    IRBuilder<> B(S);
    return mk(B.CreateICmp(q, a, b));
  }

  bool run() {
    std::vector<std::tuple<Instruction *, Value *, Value *>> packs; std::vector<SelectInst *> sels;
    for (BasicBlock &BB : F) for (Instruction &I : BB) {
      Value *lo, *hi;
      if (matchPack(&I, lo, hi)) packs.emplace_back(&I, lo, hi);
      else if (auto *S = dyn_cast<SelectInst>(&I)) sels.push_back(S);
    }
    if (packs.empty() && sels.empty()) return false;
    MapVector<Value *, Value *> repl;   // insertion order: the RAUW order sets the use lists later passes walk
    for (auto &[I, lo, hi] : packs) {
      bool lf = false;
      Value *v = get(lo, hi, I, &lf);
      if (!lf && v != I) { repl[I] = v; stat["pack_joined"]++; }
      else { stat["pack_kept"]++; if (debug) errs() << "lo-pair: KEPT  lo=" << *lo << "\n         hi=" << *hi << "\n"; }
    }
    if (!envOn("LP_OFF_CMP")) for (auto *S : sels) if (Value *v = cmp(S)) { repl[S] = v; stat["cmp_joined"]++; }
    if (repl.empty() && phis.empty()) { cleanup(); return !fresh.empty(); }
    for (auto &[I, v] : repl) {
      Value *r = v;
      for (auto f = repl.find(r); f != repl.end() && f->second != r; f = repl.find(r)) r = f->second;
      if (r != I) I->replaceAllUsesWith(r);
    }
    cleanup();
    // remaining uses of a live joined phi pair read V
    for (auto &[pl, ph, V] : phis) {
      if (!fresh.count(V)) continue;   // removed as dead
      IRBuilder<> B(V->getParent(), V->getParent()->getFirstInsertionPt());
      if (!pl->use_empty()) { pl->replaceAllUsesWith(B.CreateTrunc(V, I32)); stat["phi_lo_kept_use"]++; }
      if (!ph->use_empty()) { ph->replaceAllUsesWith(B.CreateTrunc(B.CreateLShr(V, 32), I32)); stat["phi_hi_kept_use"]++; }
    }
    SmallVector<WeakTrackingVH, 64> dead;
    for (auto &[pl, ph, V] : phis) if (fresh.count(V)) { dead.push_back(pl); dead.push_back(ph); }
    for (auto &[I, v] : repl) dead.push_back(I);
    RecursivelyDeleteTriviallyDeadInstructionsPermissive(dead);
    // whole-function sweep: dead i32 chains that the lift left
    std::vector<Instruction *> all;
    for (BasicBlock &BB : F) for (Instruction &I : BB) all.push_back(&I);
    SmallVector<WeakTrackingVH, 64> d2;
    for (auto *I : all) if (isInstructionTriviallyDead(I)) d2.push_back(I);
    RecursivelyDeleteTriviallyDeadInstructionsPermissive(d2);
    return true;
  }

  // drop what this pass made and nothing uses (incl. phi cycles among themselves)
  void cleanup() {
    DenseSet<Value *> live; SmallVector<Value *, 64> wl;
    for (Value *v : fresh) for (User *u : v->users()) if (!fresh.count(u)) { if (live.insert(v).second) wl.push_back(v); break; }
    while (!wl.empty()) {
      auto *I = cast<Instruction>(wl.pop_back_val());
      for (Value *o : I->operands()) if (fresh.count(o) && live.insert(o).second) wl.push_back(o);
    }
    std::vector<Instruction *> gone;
    for (Value *v : fresh) if (!live.count(v)) gone.push_back(cast<Instruction>(v));
    for (auto *I : gone) I->dropAllReferences();
    for (auto *I : gone) { fresh.erase(I); I->eraseFromParent(); }
  }
};

struct LoPair : PassInfoMixin<LoPair> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM) {
    if (F.isDeclaration()) return PreservedAnalyses::all();
    Join J(F, AM.getResult<DominatorTreeAnalysis>(F));
    bool ch = J.run();
    if (!J.stat.empty()) {
      errs() << "lo-pair: " << F.getName().substr(0, 40) << ":";
      for (auto &[k, v] : J.stat) errs() << " " << k << "=" << v;
      errs() << "\n";
    }
    return ch ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
} // namespace

// CuPBoP's region walk (insert_warp_loop.cpp, schedule 1) treats a block that holds only a conditional branch as a B-condition stop,
// by block size. The raw lift never has that shape where it matters: the i1 carriers (`cond_trunc`, `pbra_cond_to_i32`, ...) sit in
// front of the branch. instsimplify and early-cse remove them, and the translator then refuses the kernel. lo-brmark remembers the
// blocks with more than the branch; lo-brfix gives such a block two identity instructions back (zext + icmp ne; O3 removes them).
struct LoBrMark : PassInfoMixin<LoBrMark> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) if (auto *Br = dyn_cast<BranchInst>(BB.getTerminator())) if (Br->isConditional() && BB.size() > 1)
      Br->setMetadata("lo.nb", MDNode::get(F.getContext(), {}));
    return PreservedAnalyses::all();
  }
};
struct LoBrFix : PassInfoMixin<LoBrFix> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    int n = 0;
    for (BasicBlock &BB : F) if (auto *Br = dyn_cast<BranchInst>(BB.getTerminator())) {
      // p3: the same trap one step later. A conditional branch right behind a barrier (only calls between: membar, vote, which the translator takes out) ends up in the barrier's block when the translator splits at the
      // barrier: the region after it then has two entries, gets no warp loop and runs for logical warp 0 only, silently (backprop s1p1: simplifycfg's common.ret + a branch-only rest).
      bool behind = false;
      if (Br->isConditional()) for (auto it = std::next(BB.rbegin()); it != BB.rend(); ++it) { auto *C = dyn_cast<CallInst>(&*it); if (!C) break; Function *G = C->getCalledFunction();
        if (G && G->getName().starts_with("llvm.nvvm.barrier")) { behind = !envOn("LO_BRFIX_NOBAR"); break; } }
      if (behind || ((Br->getMetadata("lo.nb") || (Br->isConditional() && envOn("LO_BRFIX_ALL"))) && BB.size() == 1)) {
        IRBuilder<> B(Br);
        Value *z = B.CreateZExt(Br->getCondition(), Type::getInt32Ty(F.getContext()));
        Br->setCondition(B.CreateICmpNE(z, ConstantInt::get(z->getType(), 0)));
        n++;
      }
      Br->setMetadata("lo.nb", nullptr);
    }
    if (n) errs() << "lo-brfix: " << F.getName().substr(0, 40) << ": " << n << " branch blocks kept\n";
    return PreservedAnalyses::none();
  }
};

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pairjoin", "1", [](PassBuilder &PB) {
    PB.registerPipelineParsingCallback([](StringRef N, FunctionPassManager &FPM, ArrayRef<PassBuilder::PipelineElement>) {
      if (N == "lo-pair") { FPM.addPass(LoPair()); return true; }
      if (N == "lo-brmark") { FPM.addPass(LoBrMark()); return true; }
      if (N == "lo-brfix") { FPM.addPass(LoBrFix()); return true; }
      return false;
    });
  }};
}
