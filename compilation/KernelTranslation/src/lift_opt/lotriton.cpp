// lotriton.cpp (2026-11-05): passes for stock Triton input without tl.dot: the SIMT path. They run in run_triton_lo_mma in front of lo-mma, and nothing else runs them, so a lifted or CUDA module never
// meets them. Why each one exists, and the measurements: experiments/tropt_simt. Costs below are cycles per warp instruction on one core with 16 warps (native/micro.cpp of that root):
// integer op 1.3, float compare or move 1.9, float add or multiply 6.5 (the FPU holds two operations in flight), fdiv 15.7, MUFU 32.
//   lo-tmask : a run of masked accesses, each a block of its own under its predicate (triton_ir.cpp: guarded), gets a copy for lanes where every predicate of the run holds, with the predicates folded.
//              Such a run costs one branch instead of one per access, and in the copy `other` values, the moves into their phis and tl.where on the same mask are gone. A lane where one predicate
//              fails takes the original blocks. Nothing convergent is inside a run, so lanes taking different sides stay correct. LO_TMASK=0 turns it off.
//   lo-ex2   : ex2.approx.f keeps subnormal results: the translator scales around the MUFU, two float operations and a float select per value, and the select is a branch for the Vortex backend.
//              Only arguments in (-151, -126) need that. A group of N values is tested once, in integers, and takes the .ftz form when no lane has such a value. The results are those of the .f form:
//              above the band the scale is 1, below it both give 0. lg2.approx.f and rsqrt.approx.f the same way, for zero and subnormal arguments. LO_EX2=0 turns it off, LO_EX2_N the group size.
//   lo-fdiv  : divisions with the arcp flag (div.full.f32, which allows 2 ulp) by one divisor in one block: one reciprocal and multiplications, when the divisor is in the range where 1/s is a
//              normal number; otherwise the divisions. LO_FDIV=0 turns it off, LO_FDIV_N the group size.
//   lo-fpext : fpext half -> float is a call, tens of instructions and branches per value. A group of N takes a few integer operations when its values are zeros or normal numbers. LO_FPEXT=0 turns it off.
//   lo-gep   : constant parts of an element offset into the address's immediate.  LO_GEP=0 turns it off.
//   lo-fma   : the contract flag on float multiplications, additions and subtractions, which is what Triton's enable_fp_fusion (default on) asks ptxas for. CUPBOP_TRITON_FMA=0 in the environment turns it off.
// LO_DEBUG=1 prints what each pass did.
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <algorithm>
#include <cstdlib>
#include <map>
#include <vector>
using namespace llvm;

unsigned triton_warp_mask();   // triton_ir.cpp
bool triton_dot_helper_in_lift();   // triton_ir.cpp: CUPBOP_TRITON_DOT_HELPER other than 2

namespace {
int envI(const char *n, int d) { const char *e = getenv(n); return e && *e ? atoi(e) : d; }

// tl.dot kernels stay as they are: lo-mma reads their shape. With CUPBOP_TRITON_DOT_HELPER (not =2) the vxdot route's TCU call counts too
bool hasDot(Module &M) {
  for (Function &F : M) {
    if (F.isDeclaration()) { if (F.getName().starts_with("llvm.nvvm.mma.") || F.getName().starts_with("llvm.nvvm.ldmatrix") || (triton_dot_helper_in_lift() && F.getName() == "__vx_tcu_mma_f16_f32")) if (!F.use_empty()) return true; continue; }
    for (BasicBlock &B : F) for (Instruction &I : B) if (auto *C = dyn_cast<CallInst>(&I)) if (C->isInlineAsm()) { const std::string &a = cast<InlineAsm>(C->getCalledOperand())->getAsmString(); if (a.find("ldmatrix") != std::string::npos || a.find("mma.") != std::string::npos) return true; }
  }
  return false;
}

// an instruction that may sit inside a masked run
bool plain(Instruction &I) {
  if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I)) return false;
  if (auto *L = dyn_cast<LoadInst>(&I)) return L->isSimple();
  if (auto *S = dyn_cast<StoreInst>(&I)) return S->isSimple();
  if (auto *C = dyn_cast<CallBase>(&I)) {
    if (C->isConvergent() || C->isInlineAsm()) return false;
    if (C->doesNotAccessMemory()) return true;
    Function *F = C->getCalledFunction(); if (!F) return false;
    StringRef n = F->getName();
    return n.starts_with("llvm.nvvm.ex2.") || n.starts_with("llvm.nvvm.lg2.") || n.starts_with("llvm.nvvm.rcp.") || n.starts_with("llvm.nvvm.rsqrt.") || n.starts_with("llvm.nvvm.sqrt.") || n.starts_with("llvm.nvvm.sin.") || n.starts_with("llvm.nvvm.cos.") || n.starts_with("llvm.nvvm.read.ptx.sreg.") || n.starts_with("llvm.nvvm.fabs");
  }
  return true;
}

struct Guard { BasicBlock *P, *T, *C; Value *M; };

bool guardAt(BasicBlock *P, Guard &G) {
  auto *B = dyn_cast<BranchInst>(P->getTerminator());
  if (!B || !B->isConditional()) return false;
  BasicBlock *T = B->getSuccessor(0), *C = B->getSuccessor(1);
  if (T == P || C == P || T == C || T->getSinglePredecessor() != P || T->getSingleSuccessor() != C) return false;
  unsigned n = 0; for (BasicBlock *X : predecessors(C)) { if (X != P && X != T) return false; ++n; }
  if (n != 2) return false;
  for (Instruction &I : *T) if (isa<PHINode>(I) || (!I.isTerminator() && !plain(I))) return false;
  G = {P, T, C, B->getCondition()};
  return true;
}

// the run starting at the guard of P: guards whose predicates are known at the end of P
void runFrom(BasicBlock *P, const DominatorTree &DT, const DenseSet<BasicBlock *> &skip, std::vector<Guard> &run) {
  Guard G;
  if (!guardAt(P, G) || skip.count(P)) return;
  auto known = [&](Value *M) { auto *I = dyn_cast<Instruction>(M); return isa<Argument>(M) || (I && DT.dominates(I, P->getTerminator())); };
  while (known(G.M)) {
    run.push_back(G);
    BasicBlock *C = G.C;
    bool ok = true;
    for (Instruction &I : *C) if (!I.isTerminator() && !isa<PHINode>(I) && !plain(I)) { ok = false; break; }
    if (!ok || skip.count(C)) break;
    Guard N;
    if (!guardAt(C, N)) break;
    G = N;
  }
}

// An integer as a sum: disjoint ors and no-wrap adds, as Triton writes a tensor's offsets, flattened into leaves and a constant
void flatten(Value *V, SmallVectorImpl<Value *> &L, int64_t &C, int depth = 0) {
  if (auto *K = dyn_cast<ConstantInt>(V)) { C += K->getSExtValue(); return; }
  if (auto *O = dyn_cast<BinaryOperator>(V)) if (depth < 5 && ((O->getOpcode() == Instruction::Or && cast<PossiblyDisjointInst>(O)->isDisjoint()) || (O->getOpcode() == Instruction::Add && O->hasNoSignedWrap()))) {
    flatten(O->getOperand(0), L, C, depth + 1); flatten(O->getOperand(1), L, C, depth + 1); return;
  }
  L.push_back(V);
}
Value *leafSum(IRBuilder<> &Q, ArrayRef<Value *> L, int64_t C, Type *T) {
  Value *S = nullptr;
  for (Value *V : L) S = S ? Q.CreateNSWAdd(S, V) : V;
  if (!S) return ConstantInt::get(T, C);
  return C ? Q.CreateNSWAdd(S, ConstantInt::get(T, C)) : S;
}

// x < n with x = y + c, c >= 0: per (y, n) only the largest c needs testing
struct Bound { ICmpInst *I = nullptr; SmallVector<Value *, 4> L; Value *N = nullptr; int64_t C = 0; };
bool asBound(Value *M, Bound &B) {
  auto *I = dyn_cast<ICmpInst>(M);
  if (!I || I->getPredicate() != ICmpInst::ICMP_SLT) return false;
  B.I = I; B.N = I->getOperand(1); flatten(I->getOperand(0), B.L, B.C);
  if (B.C < 0) return false;
  std::sort(B.L.begin(), B.L.end(), [](Value *a, Value *b) { return a->getName() < b->getName() || (a->getName() == b->getName() && a->getValueID() < b->getValueID()); });
  return true;
}

// the test of `m` again at the insertion point of Q: an i1 held across a reduction costs a register, x and n are live anyway
Value *again(IRBuilder<> &Q, Value *M) {
  auto *I = dyn_cast<ICmpInst>(M);
  if (!I) return M;
  Value *A = I->getOperand(0);
  if (auto *O = dyn_cast<BinaryOperator>(A)) if (isa<ConstantInt>(O->getOperand(1)) && (O->getOpcode() == Instruction::Or || O->getOpcode() == Instruction::Add)) {
    Instruction *C = O->clone(); Q.Insert(C); A = C;
  }
  Instruction *C = I->clone(); Q.Insert(C); C->setOperand(0, A);
  return C;
}

unsigned foldRun(Function &F, std::vector<Guard> &run, DenseSet<BasicBlock *> &skip) {
  LLVMContext &Ctx = F.getContext();
  BasicBlock *P1 = run[0].P;
  SmallVector<BasicBlock *, 32> region;
  for (size_t i = 0; i < run.size(); ++i) { region.push_back(run[i].T); if (i + 1 < run.size()) region.push_back(run[i].C); }
  SetVector<Value *> masks; for (Guard &G : run) masks.insert(G.M);

  ValueToValueMapTy VM;
  for (Value *M : masks) VM[M] = ConstantInt::getTrue(Ctx);
  SmallVector<BasicBlock *, 32> clones;
  for (BasicBlock *B : region) { BasicBlock *N = CloneBasicBlock(B, VM, ".allmask", &F); VM[B] = N; clones.push_back(N); }
  remapInstructionsInBlocks(clones, VM);

  // the copy is straight-line: each guard falls through its then-block, and a phi behind it takes the value of that side
  std::map<Instruction *, Value *> copyOf;
  for (BasicBlock *B : region) for (Instruction &I : *B) if (!isa<PHINode>(I) && !I.isTerminator()) copyOf[&I] = VM[&I];
  for (size_t i = 0; i + 1 < run.size(); ++i) {
    BasicBlock *C = run[i].C, *NC = cast<BasicBlock>(VM[C]), *NT = cast<BasicBlock>(VM[run[i].T]);
    for (PHINode &Ph : make_early_inc_range(C->phis())) {
      auto *NP = cast<PHINode>(VM[&Ph]);
      Value *V = NP->getIncomingValueForBlock(NT);
      NP->replaceAllUsesWith(V); NP->eraseFromParent();
      copyOf[&Ph] = V;
    }
    (void)NC;
  }
  for (size_t i = 1; i < run.size(); ++i) {   // P_i of the copy: straight on into its then-block
    auto *NP = cast<BasicBlock>(VM[run[i].P]), *NT = cast<BasicBlock>(VM[run[i].T]);
    NP->getTerminator()->eraseFromParent();
    BranchInst::Create(NT, NP);
  }
  // copied phi users: a phi of the copy replaced above may have fed a later instruction of the copy through copyOf only; the RAUW covered those
  BasicBlock *End = cast<BasicBlock>(VM[run.back().T]), *Cn = run.back().C;
  for (PHINode &Ph : Cn->phis()) {
    Value *V = Ph.getIncomingValueForBlock(run.back().T);
    if (auto It = copyOf.find(dyn_cast_or_null<Instruction>(V)); It != copyOf.end()) V = It->second;
    else if (Value *W = VM.lookup(V)) V = W;
    Ph.addIncoming(V, End);
  }

  // the entry: lanes where every predicate holds go to the copy
  auto *Term = cast<BranchInst>(P1->getTerminator());
  BasicBlock *Slow = BasicBlock::Create(Ctx, "mask.some", &F, run[0].T);
  IRBuilder<> Q(Term);
  Value *All = nullptr;
  { // the masks to test: of those with one (y, n), the one with the largest offset. Kept in the order of the masks, so that the output does not depend on addresses
    std::vector<Bound> top; SmallVector<Value *, 16> rest;
    for (Value *M : masks) {
      Bound B; if (!asBound(M, B)) { rest.push_back(M); continue; }
      bool merged = false;
      for (Bound &T : top) if (T.N == B.N && T.L == B.L) { if (B.C > T.C) { T.C = B.C; T.I = B.I; } merged = true; break; }
      if (!merged) top.push_back(B);
    }
    for (Bound &B : top) { Value *T = Q.CreateICmpSLT(leafSum(Q, B.L, B.C, B.N->getType()), B.N); All = All ? Q.CreateAnd(All, T) : T; }
    for (Value *M : rest) All = All ? Q.CreateAnd(All, M) : M;
  }
  run[0].C->replacePhiUsesWith(P1, Slow);
  Term->removeFromParent(); Term->insertInto(Slow, Slow->end());
  BranchInst::Create(cast<BasicBlock>(VM[run[0].T]), Slow, All, P1);
  if (envI("LO_TMASK_REMAT", 1)) { // the slow side tests each mask where it needs it
    DenseSet<BasicBlock *> slow(region.begin(), region.end()); slow.insert(Slow);
    IRBuilder<> S(Slow->getTerminator());
    for (Value *M : masks) {
      if (!isa<ICmpInst>(M)) continue;
      Value *T = again(S, M);
      M->replaceUsesWithIf(T, [&](Use &U) { auto *J = cast<Instruction>(U.getUser()); return slow.count(J->getParent()); });
    }
  }

  // values of the run used behind it
  DenseSet<BasicBlock *> inside(region.begin(), region.end());
  for (BasicBlock *B : clones) inside.insert(B);
  for (BasicBlock *B : region) for (Instruction &I : *B) {
    if (I.isTerminator()) continue;
    SmallVector<Use *, 8> out;
    for (Use &U : I.uses()) {
      auto *J = cast<Instruction>(U.getUser());
      if (inside.count(J->getParent())) continue;
      if (J->getParent() == Slow) continue;
      if (auto *Ph = dyn_cast<PHINode>(J)) if (J->getParent() == Cn) { BasicBlock *In = Ph->getIncomingBlock(U); if (In == run.back().T || In == run.back().P || In == End) continue; }
      out.push_back(&U);
    }
    if (out.empty()) continue;
    SSAUpdater S; S.Initialize(I.getType(), I.getName());
    S.AddAvailableValue(B, &I);
    S.AddAvailableValue(End, copyOf[&I]);
    for (Use *U : out) S.RewriteUseAfterInsertions(*U);
  }
  for (BasicBlock *B : region) skip.insert(B);
  skip.insert(Slow);
  // the copy as one block
  for (auto It = clones.rbegin(); It != clones.rend(); ++It) { BasicBlock *B = *It; if (B == cast<BasicBlock>(VM[run[0].T])) continue; if (B->getSinglePredecessor() && B->getSinglePredecessor()->getSingleSuccessor() == B) MergeBlockIntoPredecessor(B); }
  skip.insert(cast<BasicBlock>(VM[run[0].T]));
  return run.size();
}

struct LoTmask : PassInfoMixin<LoTmask> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    if (!envI("LO_TMASK", 1) || hasDot(M)) return PreservedAnalyses::all();
    const int maxI = envI("LO_TMASK_MAX", 4000); const bool dbg = envI("LO_DEBUG", 0); unsigned runs = 0, guards = 0;
    for (Function &F : M) {
      if (F.isDeclaration() || F.getName().starts_with("lo.")) continue;
      DenseSet<BasicBlock *> skip;
      for (bool again = true; again;) {
        again = false;
        DominatorTree DT(F);
        for (BasicBlock &B : F) {
          std::vector<Guard> run; runFrom(&B, DT, skip, run);
          if (run.empty()) continue;
          // one guard pays only if something else reads its mask in the block behind it
          unsigned n = 0; for (Guard &G : run) { n += G.T->size(); n += G.C->size(); }
          if (run.size() < 2 || (int)n > maxI) { skip.insert(&B); continue; }
          guards += foldRun(F, run, skip); ++runs; again = true; break;
        }
      }
    }
    if (dbg && runs) errs() << "lo-tmask: " << guards << " guards in " << runs << " runs\n";
    return runs ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

// a group helper: float xN -> { float xN }
Function *groupFn(Module &M, const std::string &name, unsigned nargs, unsigned nres) {
  LLVMContext &C = M.getContext(); Type *F32 = Type::getFloatTy(C);
  SmallVector<Type *, 16> rt(nres, F32), at(nargs, F32);
  auto *FT = FunctionType::get(StructType::get(C, rt), at, false);
  Function *F = Function::Create(FT, GlobalValue::InternalLinkage, name, &M);
  F->addFnAttr(Attribute::AlwaysInline); F->addFnAttr(Attribute::NoUnwind);
  return F;
}

void joinResults(Function *F, BasicBlock *Fast, BasicBlock *Slow, BasicBlock *J, ArrayRef<Value *> f, ArrayRef<Value *> s) {
  IRBuilder<> Q(J);
  SmallVector<PHINode *, 16> ph;
  for (size_t i = 0; i < f.size(); ++i) { PHINode *P = Q.CreatePHI(f[i]->getType(), 2); P->addIncoming(f[i], Fast); P->addIncoming(s[i], Slow); ph.push_back(P); }
  Value *R = PoisonValue::get(F->getReturnType());
  for (size_t i = 0; i < f.size(); ++i) R = Q.CreateInsertValue(R, ph[i], i);
  Q.CreateRet(R);
}

Value *anyLane(Module &M, IRBuilder<> &Q, Value *lane);

// The forms the translator scales around the MUFU (tool.cpp mufu_lower) and the arguments that need the scaling: ex2 the band of subnormal results; lg2 and rsqrt zero and subnormal arguments.
struct Scaled { const char *full, *ftz; bool band; };
const Scaled SCALED[] = {{"llvm.nvvm.ex2.approx.f", "llvm.nvvm.ex2.approx.ftz.f", true}, {"llvm.nvvm.lg2.approx.f", "llvm.nvvm.lg2.approx.ftz.f", false}, {"llvm.nvvm.rsqrt.approx.f", "llvm.nvvm.rsqrt.approx.ftz.f", false}};

Function *mufuGroup(Module &M, const Scaled &K, unsigned N) {
  std::string name = std::string("lo.") + (K.full + 10) + "." + std::to_string(N);
  if (Function *F = M.getFunction(name)) return F;
  Function *F = groupFn(M, name, N, N);
  LLVMContext &C = M.getContext(); Type *F32 = Type::getFloatTy(C), *I32 = Type::getInt32Ty(C);
  BasicBlock *E = BasicBlock::Create(C, "e", F), *Fa = BasicBlock::Create(C, "f", F), *Sl = BasicBlock::Create(C, "s", F), *J = BasicBlock::Create(C, "j", F);
  IRBuilder<> Q(E);
  Value *any = nullptr;
  for (Argument &A : F->args()) {
    Value *b = Q.CreateBitCast(&A, I32), *c;
    // bits of -126.0 and -151.0: negative floats order as unsigned integers, so one subtraction and one compare test the open interval
    if (K.band) c = Q.CreateICmpULT(Q.CreateSub(b, Q.getInt32(0xC2FC0001u)), Q.getInt32(0xC3170000u - 0xC2FC0001u));
    else c = Q.CreateICmpEQ(Q.CreateAnd(b, Q.getInt32(0x7f800000u)), Q.getInt32(0));
    any = any ? Q.CreateOr(any, c) : c;
  }
  Q.CreateCondBr(anyLane(M, Q, any), Sl, Fa);
  auto *FT = FunctionType::get(F32, {F32}, false);
  FunctionCallee ftz = M.getOrInsertFunction(K.ftz, FT), full = M.getOrInsertFunction(K.full, FT);
  SmallVector<Value *, 16> f, s;
  IRBuilder<> QF(Fa), QS(Sl);
  for (Argument &A : F->args()) { f.push_back(QF.CreateCall(ftz, {&A})); s.push_back(QS.CreateCall(full, {&A})); }
  QF.CreateBr(J); QS.CreateBr(J);
  joinResults(F, Fa, Sl, J, f, s);
  return F;
}

// From the first member I: the group as it can grow, up to N. mv: what reads a member and has to move behind the group
template <class Is> Instruction *formGroup(Instruction *I, Is is, unsigned N, std::vector<Instruction *> &g, std::vector<Instruction *> &mv) {
  g.assign(1, I); DenseSet<Value *> dep{I}; std::vector<Instruction *> mvNow; Instruction *last = I;
  for (Instruction *J = I->getNextNode(); J && !J->isTerminator() && g.size() < N; J = J->getNextNode()) {
    bool reads = false; for (Value *V : J->operands()) if (dep.count(V)) reads = true;
    if (is(J)) { if (reads) break; g.push_back(J); dep.insert(J); last = J; mv.insert(mv.end(), mvNow.begin(), mvNow.end()); mvNow.clear(); continue; }
    if (reads) { if (isa<PHINode>(J) || J->mayHaveSideEffects() || J->mayReadOrWriteMemory()) break; dep.insert(J); mvNow.push_back(J); }
  }
  return last;
}

// the group's helper call behind `last`, members replaced, readers moved behind it; returns the instruction after the group
Instruction *callGroup(Function *H, std::vector<Instruction *> &g, std::vector<Instruction *> &mv, Instruction *last) {
  Instruction *next = last->getNextNode();
  SmallVector<Value *, 16> args; for (Instruction *C : g) args.push_back(C->getOperand(0));
  IRBuilder<> Q(next);
  CallInst *R = Q.CreateCall(H, args);
  for (size_t i = 0; i < g.size(); ++i) g[i]->replaceAllUsesWith(Q.CreateExtractValue(R, i));
  for (Instruction *X : mv) X->moveBefore(next);
  for (Instruction *C : g) C->eraseFromParent();
  return next;
}

} // namespace
namespace {
// One lane with an exception sends the whole warp the old way: the MUFU is 32 cycles per warp with one lane active too, so taking both sides would double the expensive part
Value *anyLane(Module &M, IRBuilder<> &Q, Value *lane) {
  Type *I1 = Q.getInt1Ty();
  FunctionCallee Vote = M.getOrInsertFunction("llvm.nvvm.vote.any.sync", FunctionType::get(I1, {Q.getInt32Ty(), I1}, false));
  if (auto *VF = dyn_cast<Function>(Vote.getCallee())) VF->addFnAttr(Attribute::Convergent);
  CallInst *W = Q.CreateCall(Vote, {Q.getInt32(triton_warp_mask()), lane}); W->addFnAttr(Attribute::Convergent);
  return W;
}

struct LoEx2 : PassInfoMixin<LoEx2> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    // without CUPBOP_MUFU both forms are the same libm call: there is no scaling to save
    if (!envI("LO_EX2", 1) || !envI("CUPBOP_MUFU", 0) || hasDot(M)) return PreservedAnalyses::all();
    const unsigned N = envI("LO_EX2_N", 8); const bool dbg = envI("LO_DEBUG", 0); unsigned total = 0, groups = 0;
    std::vector<Function *> fs; for (Function &F : M) if (!F.isDeclaration() && !F.getName().starts_with("lo.")) fs.push_back(&F);
    for (const Scaled &K : SCALED) {
      auto is = [&](Instruction *I) { auto *C = dyn_cast<CallInst>(I); return C && C->getCalledFunction() && C->getCalledFunction()->getName() == K.full; };
      for (Function *F : fs) for (BasicBlock &B : *F) {
        for (Instruction *I = &B.front(); I;) {
          if (!is(I)) { I = I->getNextNode(); continue; }
          std::vector<Instruction *> g, mv;
          Instruction *last = formGroup(I, is, N, g, mv);
          Instruction *next = callGroup(mufuGroup(M, K, g.size()), g, mv, last);
          total += g.size(); ++groups; I = next;
        }
      }
    }
    if (dbg && groups) errs() << "lo-ex2: " << total << " calls in " << groups << " groups\n";
    return groups ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

// half -> float, N at a time: normal numbers and zeros in integers, any other value in a warp sends it to fpext (a call: the target has no half)
Function *hextGroup(Module &M, unsigned N) {
  std::string name = "lo.hext." + std::to_string(N);
  if (Function *F = M.getFunction(name)) return F;
  LLVMContext &C = M.getContext(); Type *F32 = Type::getFloatTy(C), *H = Type::getHalfTy(C), *I32 = Type::getInt32Ty(C), *I16 = Type::getInt16Ty(C);
  SmallVector<Type *, 16> rt(N, F32), at(N, H);
  Function *F = Function::Create(FunctionType::get(StructType::get(C, rt), at, false), GlobalValue::InternalLinkage, name, &M);
  F->addFnAttr(Attribute::AlwaysInline); F->addFnAttr(Attribute::NoUnwind);
  BasicBlock *E = BasicBlock::Create(C, "e", F), *Fa = BasicBlock::Create(C, "f", F), *Sl = BasicBlock::Create(C, "s", F), *J = BasicBlock::Create(C, "j", F);
  IRBuilder<> Q(E), QF(Fa), QS(Sl);
  Value *any = nullptr; SmallVector<Value *, 16> f, s;
  for (Argument &A : F->args()) {
    Value *z = Q.CreateZExt(Q.CreateBitCast(&A, I16), I32), *x = Q.CreateAnd(z, Q.getInt32(0x7fff));
    Value *normal = Q.CreateICmpULT(Q.CreateSub(x, Q.getInt32(0x400)), Q.getInt32(0x7800)), *zero = Q.CreateICmpEQ(x, Q.getInt32(0));
    Value *c = Q.CreateNot(Q.CreateOr(normal, zero));
    any = any ? Q.CreateOr(any, c) : c;
    Value *b = QF.CreateAdd(QF.CreateShl(x, 13), QF.getInt32(0x38000000));
    b = QF.CreateSelect(QF.CreateICmpEQ(x, QF.getInt32(0)), QF.getInt32(0), b);
    b = QF.CreateOr(b, QF.CreateShl(QF.CreateAnd(z, QF.getInt32(0x8000)), 16));
    f.push_back(QF.CreateBitCast(b, F32)); s.push_back(QS.CreateFPExt(&A, F32));
  }
  Q.CreateCondBr(anyLane(M, Q, any), Sl, Fa);
  QF.CreateBr(J); QS.CreateBr(J);
  joinResults(F, Fa, Sl, J, f, s);
  return F;
}

struct LoFpext : PassInfoMixin<LoFpext> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    if (!envI("LO_FPEXT", 1) || hasDot(M)) return PreservedAnalyses::all();
    const unsigned N = envI("LO_FPEXT_N", 8); unsigned total = 0;
    std::vector<Function *> fs; for (Function &F : M) if (!F.isDeclaration() && !F.getName().starts_with("lo.")) fs.push_back(&F);
    auto is = [](Instruction *I) { auto *X = dyn_cast<FPExtInst>(I); return X && X->getSrcTy()->isHalfTy() && X->getType()->isFloatTy(); };
    for (Function *F : fs) for (BasicBlock &B : *F) for (Instruction *I = &B.front(); I;) {
      if (!is(I)) { I = I->getNextNode(); continue; }
      std::vector<Instruction *> g, mv;
      Instruction *last = formGroup(I, is, N, g, mv);
      total += g.size();
      I = callGroup(hextGroup(M, g.size()), g, mv, last);
    }
    if (envI("LO_DEBUG", 0) && total) errs() << "lo-fpext: " << total << " fpext\n";
    return total ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

Function *fdivGroup(Module &M, unsigned N) {
  std::string name = "lo.fdiv." + std::to_string(N);
  if (Function *F = M.getFunction(name)) return F;
  Function *F = groupFn(M, name, N + 1, N);
  LLVMContext &C = M.getContext(); Type *F32 = Type::getFloatTy(C), *I32 = Type::getInt32Ty(C);
  BasicBlock *E = BasicBlock::Create(C, "e", F), *Fa = BasicBlock::Create(C, "f", F), *Sl = BasicBlock::Create(C, "s", F), *J = BasicBlock::Create(C, "j", F);
  IRBuilder<> Q(E);
  Value *s = F->getArg(0);
  // the exponent field in 2..252: 1/s and s are normal numbers
  Value *ex = Q.CreateAnd(Q.CreateLShr(Q.CreateBitCast(s, I32), 23), Q.getInt32(255));
  Q.CreateCondBr(Q.CreateICmpULT(Q.CreateSub(ex, Q.getInt32(2)), Q.getInt32(251)), Fa, Sl);
  IRBuilder<> QF(Fa), QS(Sl);
  Value *r = QF.CreateFDiv(ConstantFP::get(F32, 1.0), s);
  SmallVector<Value *, 16> f, sl;
  for (unsigned i = 1; i <= N; ++i) { f.push_back(QF.CreateFMul(F->getArg(i), r)); sl.push_back(QS.CreateFDiv(F->getArg(i), s)); }
  QF.CreateBr(J); QS.CreateBr(J);
  joinResults(F, Fa, Sl, J, f, sl);
  return F;
}

// A divisor that stays arcp reaches the backend, whose combineRepeatedFPDivisors would take the reciprocal with no look at the range
void clearArcp(Module &M) { for (Function &F : M) for (BasicBlock &B : F) for (Instruction &I : B) if (I.getOpcode() == Instruction::FDiv) I.setHasAllowReciprocal(false); }

struct LoFdiv : PassInfoMixin<LoFdiv> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    if (!envI("LO_FDIV", 1) || hasDot(M)) { clearArcp(M); return PreservedAnalyses::none(); }
    const unsigned N = envI("LO_FDIV_N", 16); const bool dbg = envI("LO_DEBUG", 0); unsigned total = 0, groups = 0;
    std::vector<Function *> fs; for (Function &F : M) if (!F.isDeclaration() && !F.getName().starts_with("lo.")) fs.push_back(&F);
    for (Function *F : fs) {
      DominatorTree DT(*F);
      for (BasicBlock &B : *F) {
        for (bool again = true; again;) {
          again = false;
          std::map<Value *, std::vector<BinaryOperator *>> by; std::vector<Value *> order;
          for (Instruction &I : B) if (auto *D = dyn_cast<BinaryOperator>(&I)) if (D->getOpcode() == Instruction::FDiv && D->hasAllowReciprocal() && D->getType()->isFloatTy() && !isa<Constant>(D->getOperand(1))) { if (!by.count(D->getOperand(1))) order.push_back(D->getOperand(1)); by[D->getOperand(1)].push_back(D); }
          for (Value *S : order) {
            auto &v = by[S]; if (v.size() < 2) continue;
            BinaryOperator *A = v[0]; std::vector<BinaryOperator *> g{A};
            for (size_t i = 1; i < v.size() && g.size() < N; ++i) { auto *X = dyn_cast<Instruction>(v[i]->getOperand(0)); if (!X || DT.dominates(X, A)) g.push_back(v[i]); }
            if (g.size() < 2) continue;
            Function *H = fdivGroup(M, g.size());
            IRBuilder<> Q(A);
            SmallVector<Value *, 17> args{S}; for (auto *D : g) args.push_back(D->getOperand(0));
            CallInst *R = Q.CreateCall(H, args);
            for (size_t i = 0; i < g.size(); ++i) { g[i]->replaceAllUsesWith(Q.CreateExtractValue(R, i)); }
            for (auto *D : g) D->eraseFromParent();
            total += g.size(); ++groups; again = true; break;
          }
        }
      }
    }
    clearArcp(M);
    if (dbg && groups) errs() << "lo-fdiv: " << total << " divisions in " << groups << " groups\n";
    return PreservedAnalyses::none();
  }
};

// gep p, sext(x + c) -> gep (gep p, sext x), 4c: a tensor's elements then share one base register and differ in the load's immediate. Otherwise each element holds its own address across the reductions.
struct LoGep : PassInfoMixin<LoGep> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    if (!envI("LO_GEP", 1) || hasDot(M)) return PreservedAnalyses::all();
    unsigned n = 0; const DataLayout &DL = M.getDataLayout();
    for (Function &F : M) for (BasicBlock &B : F) for (Instruction &I : make_early_inc_range(B)) if (auto *G = dyn_cast<GetElementPtrInst>(&I)) {
      if (G->getNumIndices() != 1) continue;
      Value *Ix = G->getOperand(1); Value *Narrow = nullptr;
      if (auto *S = dyn_cast<SExtInst>(Ix)) Narrow = S->getOperand(0);
      else if (auto *Z = dyn_cast<ZExtInst>(Ix)) { if (Z->hasNonNeg()) Narrow = Z->getOperand(0); }
      if (!Narrow) continue;
      SmallVector<Value *, 4> L; int64_t C = 0; flatten(Narrow, L, C);
      if (C <= 0 || L.empty()) continue;
      const uint64_t sz = DL.getTypeAllocSize(G->getSourceElementType()).getFixedValue();
      IRBuilder<> Q(G);
      Value *X = Q.CreateSExt(leafSum(Q, L, 0, Narrow->getType()), Ix->getType());
      Value *P = Q.CreateGEP(G->getSourceElementType(), G->getPointerOperand(), {X});
      Value *R = Q.CreateConstGEP1_64(Q.getInt8Ty(), P, C * sz);
      G->replaceAllUsesWith(R); G->eraseFromParent(); ++n;
    }
    return n ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

struct LoFma : PassInfoMixin<LoFma> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    if (!envI("CUPBOP_TRITON_FMA", 1) || hasDot(M)) return PreservedAnalyses::all();
    unsigned n = 0;
    for (Function &F : M) for (BasicBlock &B : F) for (Instruction &I : B) if (I.getOpcode() == Instruction::FMul || I.getOpcode() == Instruction::FAdd || I.getOpcode() == Instruction::FSub) if (I.getType()->isFloatTy()) { I.setHasAllowContract(true); ++n; }
    return n ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
} // namespace

void loTritonClearArcp(Module &M) { clearArcp(M); }
bool loTritonHasDot(Module &M) { return hasDot(M); }

void loTritonRegister(PassBuilder &PB) {
  PB.registerPipelineParsingCallback([](StringRef N, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
    if (N == "lo-tmask") { MPM.addPass(LoTmask()); return true; }
    if (N == "lo-ex2") { MPM.addPass(LoEx2()); return true; }
    if (N == "lo-fdiv") { MPM.addPass(LoFdiv()); return true; }
    if (N == "lo-fma") { MPM.addPass(LoFma()); return true; }
    if (N == "lo-gep") { MPM.addPass(LoGep()); return true; }
    if (N == "lo-fpext") { MPM.addPass(LoFpext()); return true; }
    return false; });
}
