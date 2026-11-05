// SIMT start-point passes (experiments/p2d, 2026-11-04). Every pass is off unless its switch is set.
#include "simt_opt.h"
#include "tool.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/CaptureTracking.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/IntrinsicsRISCV.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Operator.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/Support/raw_ostream.h"
#include <cstdlib>
#include <cstring>
#include <map>
#include <set>
#include <string>
#include <vector>
using namespace llvm;

// Measurement only (upper bound of what launch-shape knowledge can buy): the block dimensions as constants.
void simt_measure_blockdim(Module *M) {
  if (std::getenv("CUPBOP_MEASURE_SHARED_NONVOL"))   // measurement only: the lifter's volatile on shared memory off (not proved legal)
    for (Function &F : *M)
      for (BasicBlock &BB : F)
        for (Instruction &I : BB) {
          if (auto *L = dyn_cast<LoadInst>(&I); L && L->isVolatile()) L->setVolatile(false);
          if (auto *S = dyn_cast<StoreInst>(&I); S && S->isVolatile()) S->setVolatile(false);
        }
  const char *e = std::getenv("CUPBOP_MEASURE_BLOCKDIM");
  if (!e) return;
  int d[3] = {1, 1, 1};
  std::sscanf(e, "%d,%d,%d", &d[0], &d[1], &d[2]);
  const std::pair<const char *, int> g[] = {{"block_size_x", d[0]}, {"block_size_y", d[1]}, {"block_size_z", d[2]}, {"block_size", d[0] * d[1] * d[2]}};
  for (auto &[name, v] : g) {
    GlobalVariable *G = M->getGlobalVariable(name);
    if (!G) continue;
    std::vector<LoadInst *> ls;
    for (User *U : G->users())
      if (auto *L = dyn_cast<LoadInst>(U)) ls.push_back(L);
    for (LoadInst *L : ls) { L->replaceAllUsesWith(ConstantInt::get(L->getType(), v)); L->eraseFromParent(); }
  }
  if (const char *p = std::getenv("CUPBOP_VIRT_WARPS"))
    if (Function *F = M->getFunction("__cupbop_cta_size")) {
      std::vector<CallInst *> cs;
      for (User *U : F->users())
        if (auto *C = dyn_cast<CallInst>(U)) cs.push_back(C);
      for (CallInst *C : cs) { C->replaceAllUsesWith(ConstantInt::get(C->getType(), std::atoi(p))); C->eraseFromParent(); }
    }
  fprintf(stderr, "[simt] measurement: block dims %d,%d,%d are constants\n", d[0], d[1], d[2]);
}

// a warp loop: LoopSimplify'd loop with llvm.loop.parallel_accesses on its latch
static bool is_warp_loop(Loop *L) {
  MDNode *ID = L->getLoopID();
  if (!ID) return false;
  for (unsigned i = 1; i < ID->getNumOperands(); ++i)
    if (auto *N = dyn_cast<MDNode>(ID->getOperand(i)))
      if (N->getNumOperands() && isa<MDString>(N->getOperand(0)) && cast<MDString>(N->getOperand(0))->getString() == "llvm.loop.parallel_accesses") return true;
  return false;
}

// Nothing in the loop orders memory between logical warps. A load may then move over the other trips' accesses: there is no
// synchronisation between the logical warps of one region, so "every logical warp reads first" is a legal schedule of the program.
static const char *region_has_sync(Loop *L) {
  for (BasicBlock *BB : L->blocks())
    for (Instruction &I : *BB) {
      if (isa<FenceInst>(I) || isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I)) return "atomic or fence";
      // the lifter's shared-memory accesses are volatile; a volatile global access can be a spin on a flag
      if (auto *X = dyn_cast<LoadInst>(&I); X && !X->isSimple() && (X->isAtomic() || X->getPointerAddressSpace() != 3)) return "volatile or atomic load";
      if (auto *X = dyn_cast<StoreInst>(&I); X && !X->isSimple() && (X->isAtomic() || X->getPointerAddressSpace() != 3)) return "volatile or atomic store";
      if (auto *C = dyn_cast<CallBase>(&I)) {
        if (isa<DbgInfoIntrinsic>(C)) continue;
        if (C->isConvergent()) return "convergent call";
        if (C->isInlineAsm()) {
          auto *A = cast<InlineAsm>(C->getCalledOperand());
          const std::string &t = A->getAsmString();
          if (t.rfind("csrr", 0) == 0) continue;              // launch registers
          if (!A->hasSideEffects() && C->doesNotAccessMemory()) continue;   // MUFU and the like
          return "inline asm";
        }
        if (auto *II = dyn_cast<IntrinsicInst>(C)) {
          if (II->isAssumeLikeIntrinsic() || II->isLifetimeStartOrEnd() || II->doesNotAccessMemory()) continue;
          return "memory intrinsic";
        }
        if (C->doesNotAccessMemory()) continue;
        return "call";
      }
    }
  return nullptr;
}

// the store cannot touch what the load reads: a context array (alloca whose address stays in the function) or another address space
static bool store_disjoint(StoreInst *S, LoadInst *X) {
  const unsigned sa = S->getPointerAddressSpace(), xa = X->getPointerAddressSpace();
  if (sa != xa && (sa == 3 || xa == 3) && sa != 0 && xa != 0) return true;     // shared vs global, both named
  const Value *O = getUnderlyingObject(S->getPointerOperand());
  if (auto *A = dyn_cast<AllocaInst>(O))
    if (getUnderlyingObject(X->getPointerOperand()) != O && !PointerMayBeCaptured(A, true, true)) return true;
  return false;
}

// a store in the loop runs before the load inside one trip (no back edge)
static bool store_before_in_trip(Loop *L, LoadInst *X, const std::vector<StoreInst *> &stores) {
  BasicBlock *H = L->getHeader();
  std::set<BasicBlock *> seen{X->getParent()};
  std::vector<BasicBlock *> work{X->getParent()};
  while (!work.empty()) {
    BasicBlock *B = work.back(); work.pop_back();
    if (B == H) continue;
    for (BasicBlock *P : predecessors(B))
      if (L->contains(P) && seen.insert(P).second) work.push_back(P);
  }
  for (StoreInst *S : stores) {
    if (!seen.count(S->getParent())) continue;
    if (S->getParent() == X->getParent() && !S->comesBefore(X)) continue;   // X's block is in no inner loop: this store runs after X
    if (store_disjoint(S, X)) continue;
    return true;
  }
  return false;
}

// pointer = base + constant offset, base an integer (or pointer) value that does not change in the loop
static bool split_pointer(Value *P, Loop *L, Value *&base, int64_t &off, const DataLayout &DL) {
  off = 0;
  for (int i = 0; i < 8; ++i) {
    if (auto *G = dyn_cast<GEPOperator>(P)) {
      APInt o(DL.getIndexTypeSizeInBits(G->getType()), 0);
      if (!G->accumulateConstantOffset(DL, o)) break;
      off += o.getSExtValue(); P = G->getPointerOperand();
    } else if (auto *C = dyn_cast<AddrSpaceCastOperator>(P)) P = C->getPointerOperand();
    else if (auto *T = dyn_cast<IntToPtrInst>(P)) P = T->getOperand(0);
    else if (auto *A = dyn_cast<BinaryOperator>(P); A && A->getOpcode() == Instruction::Add && isa<ConstantInt>(A->getOperand(1))) {
      off += cast<ConstantInt>(A->getOperand(1))->getSExtValue(); P = A->getOperand(0);
    } else break;
  }
  base = P;
  return L->isLoopInvariant(P);
}

// CUPBOP_TRIP_HOIST=1 (default 0, core mapping): a load in a warp loop whose address does not change between trips is read once, in
// front of the loop (the trips are logical warps; every one read the same word). What makes the move legal:
//  - region_has_sync: no atomic, fence, convergent or unknown call, no volatile global access in the region;
//  - a store of the same trip does not run before the load (store_before_in_trip); stores of other trips are the other logical warps, see
//    region_has_sync; the region's loop runs after the barrier that starts the region;
//  - the read itself cannot fault: a load that runs in every trip is moved as it is. A load under a condition may run in no trip at all
//    (a null optional pointer): it reads the same address only when the base is in the memory range [USER_BASE, 2^48), otherwise the pad
//    @__cupbop_spec_pad. The value is used only where the load stood, so a pad value is never used by a correct program. The select is on
//    integers: LLVM learns nothing about the base pointer from it.
// CUPBOP_TRIP_HOIST_MAX: most loads per warp loop (default 16; each stays live in a register over the loop). CUPBOP_TRIP_HOIST_WHY=1: decisions.
void simt_trip_hoist(Module *M) {
  const char *e = std::getenv("CUPBOP_TRIP_HOIST");
  if (!e || !std::atoi(e)) return;
  const char *sf = std::getenv("VORTEX_SCHEDULE_FLAG");
  if (!sf || std::atoi(sf) != 1) return;
  const bool why = std::getenv("CUPBOP_TRIP_HOIST_WHY") != nullptr;
  long maxn = 16;
  if (const char *m = std::getenv("CUPBOP_TRIP_HOIST_MAX")) maxn = std::atol(m);
  long minn = 4;   // CUPBOP_TRIP_HOIST_MIN: fewest loads under a condition worth a range check
  if (const char *m = std::getenv("CUPBOP_TRIP_HOIST_MIN")) minn = std::atol(m);
  long share = 50;
  if (const char *m = std::getenv("CUPBOP_TRIP_HOIST_SHARE")) share = std::atol(m);
  const DataLayout &DL = M->getDataLayout();
  LLVMContext &C = M->getContext();
  Type *I64 = Type::getInt64Ty(C);
  const int64_t PAD = 4096;
  const uint64_t LO = 65536, HI = 1ull << 48;   // VX_MEM_USER_BASE_ADDR, VX_CFG_MEM_ADDR_WIDTH
  GlobalVariable *pad = nullptr;
  for (Function &F : *M) {
    if (F.isDeclaration()) continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    for (Loop *L : LI.getLoopsInPreorder()) {
      if (!is_warp_loop(L)) continue;
      BasicBlock *PH = L->getLoopPreheader();
      if (!PH) continue;
      if (const char *r = region_has_sync(L)) {
        if (why) fprintf(stderr, "[trip-hoist] %s: loop %s refused: %s\n", F.getName().str().c_str(), L->getHeader()->getName().str().c_str(), r);
        continue;
      }
      std::vector<StoreInst *> stores;
      std::vector<LoadInst *> cand;
      for (BasicBlock *BB : L->blocks())
        for (Instruction &I : *BB) {
          if (auto *S = dyn_cast<StoreInst>(&I)) stores.push_back(S);
          if (auto *X = dyn_cast<LoadInst>(&I))
            if (X->isSimple() && L->isLoopInvariant(X->getPointerOperand()) && LI.getLoopFor(BB) == L) cand.push_back(X);
        }
      long n = 0, nguard = 0;
      std::map<Value *, Value *> safe_base;   // base -> checked integer base
      BasicBlock *Latch = L->getLoopLatch();
      auto runs_every_trip = [&](LoadInst *X) { return Latch && L->getExitingBlock() == Latch && DT.dominates(X->getParent(), Latch); };
      // under a condition: worth it when the condition is the bounds check around the kernel's body, not a rare path. The blocks the load's block dominates must hold
      // most of the trip (CUPBOP_TRIP_HOIST_SHARE percent, default 50), otherwise the load would run per region where it ran in few trips
      auto main_path = [&](LoadInst *X) {
        long in_loop = 0, under = 0;
        for (BasicBlock *BB : L->blocks()) {
          in_loop += BB->size();
          if (DT.dominates(X->getParent(), BB)) under += BB->size();
        }
        return under * 100 >= in_loop * share;
      };
      {
        std::vector<LoadInst *> go;
        long guarded = 0;
        for (LoadInst *X : cand) {
          if (store_before_in_trip(L, X, stores)) {
            if (why) fprintf(stderr, "[trip-hoist] %s: %s kept: a store runs before it in the trip\n", F.getName().str().c_str(), X->getName().str().c_str());
            continue;
          }
          const bool every = runs_every_trip(X);
          if (!every && !main_path(X)) {
            if (why) fprintf(stderr, "[trip-hoist] %s: %s kept: its condition covers little of the trip\n", F.getName().str().c_str(), X->getName().str().c_str());
            continue;
          }
          go.push_back(X);
          guarded += !every;
        }
        if (guarded < minn) {   // the range check pays for itself over several loads only (cudnn_add: 2 loads, +3%)
          std::vector<LoadInst *> kept;
          for (LoadInst *X : go)
            if (runs_every_trip(X)) kept.push_back(X);
          go.swap(kept);
        }
        cand.swap(go);
      }
      for (LoadInst *X : cand) {
        if (n >= maxn) break;
        const bool every_trip = runs_every_trip(X);
        Instruction *T = PH->getTerminator();
        if (!every_trip) {
          Value *base; int64_t off;
          const bool ok = split_pointer(X->getPointerOperand(), L, base, off, DL) && off >= 0 && off + 16 < PAD &&
                          (base->getType()->isIntegerTy(64) || base->getType()->isPointerTy()) &&
                          (!isa<Instruction>(base) || DT.dominates(cast<Instruction>(base), T));
          if (!ok) {
            if (why) fprintf(stderr, "[trip-hoist] %s: %s kept: under a condition, address not base + small constant\n", F.getName().str().c_str(), X->getName().str().c_str());
            continue;
          }
          if (!pad) {
            pad = M->getGlobalVariable("__cupbop_spec_pad");
            if (!pad) pad = new GlobalVariable(*M, ArrayType::get(Type::getInt8Ty(C), PAD), false, GlobalValue::InternalLinkage,
                                               ConstantAggregateZero::get(ArrayType::get(Type::getInt8Ty(C), PAD)), "__cupbop_spec_pad");
            pad->setAlignment(Align(64));
          }
          IRBuilder<> B(T);
          Value *&SB = safe_base[base];
          if (!SB) {
            Value *I = base->getType()->isPointerTy() ? B.CreatePtrToInt(base, I64) : base;
            Value *in = B.CreateICmpULT(B.CreateSub(I, ConstantInt::get(I64, LO)), ConstantInt::get(I64, HI - LO), "spec_in_range");
            SB = B.CreateSelect(in, I, B.CreatePtrToInt(pad, I64), "spec_base");
          }
          Value *A = off ? B.CreateAdd(SB, ConstantInt::get(I64, off)) : SB;
          X->setOperand(0, B.CreateIntToPtr(A, X->getPointerOperandType()));
          nguard++;
        } else if (auto *PI = dyn_cast<Instruction>(X->getPointerOperand()); PI && L->contains(PI)) {
          continue;   // invariant by operands only; LICM would have moved it
        }
        X->moveBefore(T);
        X->setMetadata(LLVMContext::MD_mem_parallel_loop_access, nullptr);
        X->setMetadata(LLVMContext::MD_access_group, nullptr);
        n++;
      }
      if (n) fprintf(stderr, "[trip-hoist] %s: %ld loads out of warp loop %s (%ld under a condition)\n", F.getName().str().c_str(), n, L->getHeader()->getName().str().c_str(), nguard);
    }
  }
}

// CUPBOP_TRIP_VERSION=1 (default 0, core mapping, single warp loop): a second copy of the kernel body for the common launch shape. The entry block
// tests launch constants (uniform, same result in every warp of the CTA), so all warps of a CTA take the same copy and meet at the same barriers:
//   exact = block_size is a multiple of 32 P, P = CUPBOP_VIRT_WARPS (a power of two) = the CTA's physical warps: every lane runs every trip, so the warp loop can count
//           trips (slot < block_size / (32 P)): a uniform branch instead of the per-lane index test and its loop predication (vx_pred); at least 4 trips;
//   a kernel that reads no threadIdx.y/z also requires blockDim.y == blockDim.z == 1: there block_size == blockDim.x and index < block_size, so threadIdx.x = the index
//           (no remainder), blockDim.x = block_size.
// Only kernels without a loop inside the trip. The entry block keeps the allocas (one frame for both copies). CUPBOP_TRIP_VERSION_MAX: largest kernel in instructions (default 8000).
void simt_trip_version(Module *M) {
  const char *e = std::getenv("CUPBOP_TRIP_VERSION");
  if (!e || !std::atoi(e)) return;
  VirtGeom vg = getVirtGeom();
  if (vg.schedule != 1 || vg.subpasses != 1 || vg.trips) return;
  long maxi = 8000;
  if (const char *m = std::getenv("CUPBOP_TRIP_VERSION_MAX")) maxi = std::atol(m);
  const char *pe = std::getenv("CUPBOP_VIRT_WARPS");   // the physical warps of a CTA the host asks for; the copy tests the real number
  const unsigned P = pe ? std::atoi(pe) : 0;
  if (!P || (P & (P - 1))) return;
  unsigned lg = 5;
  while ((1u << lg) < 32 * P) lg++;
  LLVMContext &C = M->getContext();
  Type *I32 = Type::getInt32Ty(C);
  GlobalVariable *gx = M->getGlobalVariable("block_size_x"), *gy = M->getGlobalVariable("block_size_y"), *gz = M->getGlobalVariable("block_size_z"), *gb = M->getGlobalVariable("block_size");
  if (!gx || !gy || !gz || !gb) return;
  auto named = [](Instruction &I, const char *n) { return I.getName().starts_with(n); };
  for (Function &F : *M) {
    if (F.isDeclaration() || !isKernelFunction(M, &F)) continue;
    bool uses_x = false, uses_yz = false, has_cond = false;
    long n = 0;
    AllocaInst *slot = nullptr;
    for (BasicBlock &BB : F) {
      if (BB.getName().starts_with("intra_warp_cond")) has_cond = true;
      for (Instruction &I : BB) {
        n++;
        if (named(I, "thread_id_x")) uses_x = true;
        if (named(I, "thread_id_y") || named(I, "thread_id_z")) uses_yz = true;
        if (auto *L = dyn_cast<LoadInst>(&I); L && (L->getPointerOperand() == gy || L->getPointerOperand() == gz)) uses_yz = true;
        if (auto *A = dyn_cast<AllocaInst>(&I); A && A->getName().starts_with("local_intra_warp_slot")) slot = A;
      }
    }
    if (!has_cond || !slot || n > maxi) continue;
    {   // a loop inside the trip: the trip head is not what the kernel spends its time on, the copy only adds registers
      DominatorTree DT(F);
      LoopInfo LI(DT);
      bool inner = false;
      for (Loop *L : LI.getLoopsInPreorder())
        if (!L->getHeader()->getName().starts_with("intra_warp_cond")) inner = true;
      if (inner) continue;
    }
    BasicBlock &E = F.getEntryBlock();
    Instruction *last = nullptr;
    for (Instruction &I : E)
      if (isa<AllocaInst>(I)) last = &I;
    BasicBlock::iterator at = last ? std::next(last->getIterator()) : E.getFirstInsertionPt();
    BasicBlock *Body = E.splitBasicBlock(at, "simt.body");
    std::vector<BasicBlock *> orig;
    for (BasicBlock &BB : F)
      if (&BB != &E) orig.push_back(&BB);
    ValueToValueMapTy VM;
    SmallVector<BasicBlock *, 64> cl;
    for (BasicBlock *BB : orig) {
      BasicBlock *K = CloneBasicBlock(BB, VM, ".lv", &F);
      VM[BB] = K;
      cl.push_back(K);
    }
    remapInstructionsInBlocks(cl, VM);
    E.getTerminator()->eraseFromParent();
    IRBuilder<> B(&E);
    Value *bs = B.CreateLoad(I32, gb, "lv_block_size");
    Function *U = Intrinsic::getDeclaration(M, Intrinsic::riscv_vx_uniform, {I32, I32});   // launch constants: the same in every lane; a bare load or CSR read is divergent to the backend
    auto uni = [&](IRBuilder<> &X, Value *V) { return X.CreateICmpNE(X.CreateCall(U, {X.CreateZExt(V, I32)}), ConstantInt::get(I32, 0)); };
    // two tests: a small block leaves after the first, at two instructions (nn: 64 threads, 2 trips, +5% with one test of 11 instructions)
    BasicBlock *Test = BasicBlock::Create(C, "lv_test", &F, Body);
    // the weights keep SimplifyCFG from folding the two tests into one
    B.CreateCondBr(uni(B, B.CreateICmpUGE(bs, ConstantInt::get(I32, 128 * P), "lv_trips4")), Test, Body, MDBuilder(C).createBranchWeights(1, 1000));
    IRBuilder<> TB(Test);
    FunctionCallee ctaF = M->getOrInsertFunction("__cupbop_cta_size", FunctionType::get(I32, true));
    Value *c = TB.CreateICmpEQ(TB.CreateCall(ctaF, {}, "lv_cta_warps"), ConstantInt::get(I32, P), "lv_p");
    c = TB.CreateAnd(c, TB.CreateICmpEQ(TB.CreateAnd(bs, ConstantInt::get(I32, 32 * P - 1)), ConstantInt::get(I32, 0)), "lv_exact");
    const bool fold1d = uses_x && !uses_yz;
    if (fold1d) c = TB.CreateAnd(c, TB.CreateICmpEQ(TB.CreateLoad(I32, gx), bs), "lv_1d");   // blockDim.x == x * y * z: y == z == 1
    Value *trips = TB.CreateCall(U, {TB.CreateLShr(bs, lg, "lv_trips")}, "lv_trips_u");
    TB.CreateCondBr(uni(TB, c), cast<BasicBlock>(VM[Body]), Body);
    unsigned nt = 0, nc = 0;
    std::vector<Instruction *> dead;
    for (BasicBlock *K : cl) {
      if (K->getName().starts_with("intra_warp_cond"))
        if (auto *T = dyn_cast<BranchInst>(K->getTerminator()); T && T->isConditional()) {
          IRBuilder<> KB(T);
          T->setCondition(KB.CreateICmpULT(KB.CreateLoad(I32, slot), trips, "lv_trip_cond"));
          nc++;
        }
      if (!fold1d) continue;
      for (Instruction &I : *K) {
        if (named(I, "thread_id_x") && isa<BinaryOperator>(I)) { I.replaceAllUsesWith(I.getOperand(0)); dead.push_back(&I); nt++; }
        else if (auto *L = dyn_cast<LoadInst>(&I); L && L->getPointerOperand() == gx) L->setOperand(0, gb);
      }
    }
    for (Instruction *I : dead) I->eraseFromParent();
    fprintf(stderr, "[trip-version] %s: copy for %s blocks, %u warp loops count trips, %u threadIdx.x folded\n", F.getName().str().c_str(), fold1d ? "1D exact" : "exact", nc, nt);
  }
}

// --- CUPBOP_DIV_RESTORE=1 (default 0): nvcc's IEEE single division back to one fdiv. The lifted form of a / b is
//   r = MUFU.RCP(b); e = fma(r, -b, 1); r1 = fma(r, e, r); q0 = fma(a, r1, 0); e2 = fma(q0, -b, a); q = fma(r1, e2, q0)
//   FCHK(a, b) selects a slow path for extreme operands, whose result joins q at a PHI.
// Only the whole shape is rewritten: the rcp, the fma chain over the same a and b, the FCHK test of the same a and b on the branch to the slow path, the join. nvcc emits this
// shape only for the IEEE division (-prec-div=true, CUDA C Programming Guide: correctly rounded), and fdiv.s rounds correctly too, so the result is the same number in every case
// but the payload of a NaN. On Vortex it is even closer than the lifted code, whose rcp is not NVIDIA's. The join gets the fdiv; the FCHK test becomes true, so the slow path is dead.
// Not covered: code built with -ftz=true (its denormals flush; the lifted IR does not show the flag). experiments/p2d/divcheck: A100 / L40S check of the claim for nvcc's a / b and 1 / x.
namespace {
struct Fma { Value *a, *b, *c; };
}
static bool as_fma(Value *V, Fma &f) {
  auto *I = dyn_cast<IntrinsicInst>(V);
  if (!I || I->getIntrinsicID() != Intrinsic::fma) return false;
  f = {I->getArgOperand(0), I->getArgOperand(1), I->getArgOperand(2)};
  return true;
}
static bool match_zero(Value *V) { auto *C = dyn_cast<ConstantInt>(V); return C && C->isZero(); }
static bool is_float_const(Value *V, double d) { auto *C = dyn_cast<ConstantFP>(V); return C && C->getValueAPF().convertToFloat() == (float)d; }
static Value *neg_of(Value *V) { if (auto *U = dyn_cast<UnaryOperator>(V); U && U->getOpcode() == Instruction::FNeg) return U->getOperand(0); return nullptr; }
static Value *rcp_arg(Value *V) {
  auto *C = dyn_cast<CallBase>(V);
  if (!C) { if (auto *D = dyn_cast<BinaryOperator>(V); D && D->getOpcode() == Instruction::FDiv && is_float_const(D->getOperand(0), 1.0)) return D->getOperand(1); return nullptr; }
  if (C->isInlineAsm()) {   // MUFU_RCP (tool.cpp mufu_op): .insn r 0x5b, 0, 0, rd, rs1, x0
    const std::string &t = cast<InlineAsm>(C->getCalledOperand())->getAsmString();
    if (t.rfind(".insn r 0x5b, 0, 0,", 0) == 0 && t.size() >= 2 && t.compare(t.size() - 2, 2, "x0") == 0) return C->getArgOperand(0);
    return nullptr;
  }
  if (Function *F = C->getCalledFunction(); F && F->getName().starts_with("llvm.nvvm.rcp.approx")) return C->getArgOperand(0);
  return nullptr;
}
// V, or its integer source through a bitcast
static Value *bits_of(Value *V) { if (auto *B = dyn_cast<BitCastInst>(V)) return B->getOperand(0); return V; }
// the FCHK test: only the operands' absolute bits matter; the lifter's form after -O3 reads (bits & 0x7fffffff)
static bool reads_abs_bits(Value *Cnd, Value *x) {
  Value *xb = bits_of(x);
  std::set<Value *> seen;
  std::vector<Value *> w{Cnd};
  while (!w.empty()) {
    Value *V = w.back(); w.pop_back();
    if (!seen.insert(V).second || seen.size() > 32) continue;
    auto *I = dyn_cast<Instruction>(V);
    if (!I) continue;
    if (auto *II = dyn_cast<IntrinsicInst>(I); II && II->getIntrinsicID() == Intrinsic::fabs && II->getArgOperand(0) == x) return true;
    if (I->getOpcode() == Instruction::And && (I->getOperand(0) == xb || bits_of(I->getOperand(0)) == xb) && isa<ConstantInt>(I->getOperand(1)) &&
        cast<ConstantInt>(I->getOperand(1))->getZExtValue() == 0x7fffffffu) return true;
    for (Value *O : I->operands()) w.push_back(O);
  }
  return false;
}
// the range test of the reciprocal: ((bits(x) + 0x1800000) & 0x7e000000) != 0
static bool reads_rcp_range(Value *Cnd, Value *x) {
  auto *C = dyn_cast<ICmpInst>(Cnd);
  if (!C || !C->isEquality() || !match_zero(C->getOperand(1))) return false;
  auto *A = dyn_cast<BinaryOperator>(C->getOperand(0));
  if (!A || A->getOpcode() != Instruction::And) return false;
  auto *M = dyn_cast<ConstantInt>(A->getOperand(1));
  auto *S = dyn_cast<BinaryOperator>(A->getOperand(0));
  if (!M || M->getZExtValue() != 0x7e000000u || !S || S->getOpcode() != Instruction::Add) return false;
  auto *K = dyn_cast<ConstantInt>(S->getOperand(1));
  return K && K->getZExtValue() == 0x1800000u && S->getOperand(0) == bits_of(x);
}
// 1 / x (nvcc's rcp.rn): r = rcp(x); t = fma(r, x, -1); q = fma(r, -t, r), reached when reads_rcp_range holds, the slow path otherwise; the two join at a PHI
static bool restore_rcp(PHINode *P, unsigned i, bool why) {
  Value *Q = P->getIncomingValue(i);
  BasicBlock *B0 = P->getIncomingBlock(i);
  Fma q, t;
  if (!as_fma(Q, q) || B0->getTerminator()->getNumSuccessors() != 1) return false;
  Value *R = q.c, *U = q.a == R ? q.b : q.b == R ? q.a : nullptr;
  if (!U) return false;
  Value *x = rcp_arg(R);
  if (!x) return false;
  Value *T = neg_of(U);
  if (!T) if (auto *S = dyn_cast<BinaryOperator>(U); S && S->getOpcode() == Instruction::FSub && is_float_const(S->getOperand(0), 0.0)) T = S->getOperand(1);
  if (!T || !as_fma(T, t) || !is_float_const(t.c, -1.0) || !((t.a == R && t.b == x) || (t.a == x && t.b == R))) return false;
  BasicBlock *PB = B0->getSinglePredecessor();
  auto *Br = PB ? dyn_cast<BranchInst>(PB->getTerminator()) : nullptr;
  if (!Br || !Br->isConditional() || !reads_rcp_range(Br->getCondition(), x)) { if (why) fprintf(stderr, "[div] %s: no range test of 1/x\n", P->getName().str().c_str()); return false; }
  Value *cond = Br->getCondition();
  for (User *U2 : cond->users()) {
    if (U2 == Br) continue;
    auto *C = dyn_cast<CallBase>(U2);
    if (!C || !C->getCalledFunction() || !C->getCalledFunction()->getName().contains("ballot")) return false;
  }
  const bool fast_true = Br->getSuccessor(0) == B0;
  IRBuilder<> B(B0->getTerminator());
  P->setIncomingValue(i, B.CreateFDiv(ConstantFP::get(x->getType(), 1.0), x, "rcp_restored"));
  cond->replaceAllUsesWith(ConstantInt::get(cond->getType(), fast_true ? 1 : 0));
  return true;
}
void simt_div_restore(Module *M) {
  const char *e = std::getenv("CUPBOP_DIV_RESTORE");
  if (!e || !std::atoi(e)) return;
  const bool why = std::getenv("CUPBOP_DIV_RESTORE_WHY") != nullptr;
  unsigned total = 0;
  for (Function &F : *M) {
    if (F.isDeclaration()) continue;
    unsigned n = 0, seen = 0;
    std::vector<PHINode *> phis;
    for (BasicBlock &BB : F)
      for (PHINode &P : BB.phis())
        if (P.getType()->isFloatTy()) phis.push_back(&P);
    for (PHINode *P : phis)
      for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) {
        Value *Q = P->getIncomingValue(i);
        BasicBlock *B0 = P->getIncomingBlock(i);
        auto *T = dyn_cast<BranchInst>(B0->getTerminator());
        Fma q, e2, q0, r1, e1;
        if (T && T->isUnconditional() && restore_rcp(P, i, why)) { n++; seen++; break; }
        if (!T || !T->isConditional() || !as_fma(Q, q)) continue;
        // q = fma(r1, e2, q0)
        Value *R1 = q.a, *E2 = q.b, *Q0 = q.c;
        if (!as_fma(E2, e2)) { std::swap(R1, E2); if (!as_fma(E2, e2)) continue; }
        if (!as_fma(R1, r1) || !as_fma(Q0, q0)) continue;
        // r1 = fma(r, e, r)
        Value *R = r1.c, *E1 = (r1.a == R) ? r1.b : r1.a;
        if ((r1.a != R && r1.b != R) || !as_fma(E1, e1)) continue;
        Value *b = rcp_arg(R);
        if (!b) continue;
        seen++;
        // e = fma(r, -b, 1)
        Value *n1 = e1.a == R ? e1.b : e1.b == R ? e1.a : nullptr;
        if (!n1 || neg_of(n1) != b || !is_float_const(e1.c, 1.0)) { if (why) { std::string str; raw_string_ostream os(str); os << *cast<Instruction>(E1) << " | " << *cast<Instruction>(R); fprintf(stderr, "[div] %s: e %s\n", P->getName().str().c_str(), os.str().c_str()); } continue; }
        // q0 = fma(a, r1, 0)
        Value *a = q0.a == R1 ? q0.b : q0.b == R1 ? q0.a : nullptr;
        if (!a || !is_float_const(q0.c, 0.0)) { if (why) fprintf(stderr, "[div] %s: q0\n", P->getName().str().c_str()); continue; }
        // e2 = fma(q0, -b, a)
        Value *n2 = e2.a == Q0 ? e2.b : e2.b == Q0 ? e2.a : nullptr;
        if (!n2 || neg_of(n2) != b || e2.c != a) { if (why) fprintf(stderr, "[div] %s: e2\n", P->getName().str().c_str()); continue; }
        // FCHK(a, b) on the branch; the other side is the slow path
        Value *cond = T->getCondition();
        const bool fast_true = T->getSuccessor(0) == P->getParent();
        if (!fast_true && T->getSuccessor(1) != P->getParent()) continue;
        if (!reads_abs_bits(cond, a) || !reads_abs_bits(cond, b)) { if (why) fprintf(stderr, "[div] %s: no FCHK of a and b on the branch\n", P->getName().str().c_str()); continue; }
        bool only = true;   // the test feeds the branch and the lifter's ballot only
        for (User *U : cond->users()) {
          if (U == T) continue;
          auto *C = dyn_cast<CallBase>(U);
          if (!C || !C->getCalledFunction() || !C->getCalledFunction()->getName().contains("ballot")) only = false;
        }
        if (!only) { if (why) fprintf(stderr, "[div] %s: FCHK test has other users\n", P->getName().str().c_str()); continue; }
        IRBuilder<> B(T);
        Value *D = B.CreateFDiv(a, b, "div_restored");
        P->setIncomingValue(i, D);
        cond->replaceAllUsesWith(ConstantInt::get(cond->getType(), fast_true ? 1 : 0));
        n++;
        break;
      }
    if (n || seen) fprintf(stderr, "[div] %s: %u of %u divisions restored\n", F.getName().str().c_str(), n, seen);
    total += n;
  }
}

// --- CUPBOP_SQRT_RESTORE=1 (default 0): nvcc's IEEE single sqrt back to llvm.sqrt.f32 (fsqrt.s, correctly rounded like sqrt.rn, -prec-sqrt=true). Lifted form:
//   r = MUFU.RSQ(x); y = x * r; h = 0.5 * r; e = fma(y, -y, x); s = fma(e, h, y), reached when (bits(x) + 0xf3000000) u< 0x72800000, the slow path otherwise; they join at a PHI.
static Value *rsq_arg(Value *V) {
  auto *C = dyn_cast<CallBase>(V);
  if (!C) return nullptr;
  if (C->isInlineAsm()) {   // MUFU_RSQ (tool.cpp mufu_op): .insn r 0x5b, 0, 0, rd, rs1, x1
    const std::string &t = cast<InlineAsm>(C->getCalledOperand())->getAsmString();
    if (t.rfind(".insn r 0x5b, 0, 0,", 0) == 0 && t.size() >= 2 && t.compare(t.size() - 2, 2, "x1") == 0) return C->getArgOperand(0);
    return nullptr;
  }
  if (Function *F = C->getCalledFunction(); F && F->getName().starts_with("llvm.nvvm.rsqrt.approx")) return C->getArgOperand(0);
  return nullptr;
}
static bool fmul_of(Value *V, Value *&a, Value *&b) {
  auto *I = dyn_cast<BinaryOperator>(V);
  if (!I || I->getOpcode() != Instruction::FMul) return false;
  a = I->getOperand(0); b = I->getOperand(1);
  return true;
}
static bool restore_sqrt(PHINode *P, unsigned i) {
  Value *Q = P->getIncomingValue(i);
  BasicBlock *B0 = P->getIncomingBlock(i);
  Fma s, e;
  if (!as_fma(Q, s) || B0->getTerminator()->getNumSuccessors() != 1) return false;
  Value *Y = s.c, *E = s.a, *H = s.b, *r1, *r2, *h1, *h2;
  if (!as_fma(E, e)) { std::swap(E, H); if (!as_fma(E, e)) return false; }
  if (!fmul_of(Y, r1, r2) || !fmul_of(H, h1, h2)) return false;
  Value *R = rsq_arg(r1) ? r1 : r2;
  Value *x = rsq_arg(R);
  if (!x || (r1 != x && r2 != x) || !((h1 == R && is_float_const(h2, 0.5)) || (h2 == R && is_float_const(h1, 0.5)))) return false;
  Value *ny = e.a == Y ? e.b : e.b == Y ? e.a : nullptr;
  if (!ny || e.c != x) return false;
  if (neg_of(ny) != Y) { auto *S = dyn_cast<BinaryOperator>(ny); if (!S || S->getOpcode() != Instruction::FSub || !is_float_const(S->getOperand(0), 0.0) || S->getOperand(1) != Y) return false; }
  BasicBlock *PB = B0->getSinglePredecessor();
  auto *Br = PB ? dyn_cast<BranchInst>(PB->getTerminator()) : nullptr;
  if (!Br || !Br->isConditional()) return false;
  Value *cond = Br->getCondition();
  auto *C = dyn_cast<ICmpInst>(cond);
  auto *A = C ? dyn_cast<BinaryOperator>(C->getOperand(0)) : nullptr;
  auto *K = C ? dyn_cast<ConstantInt>(C->getOperand(1)) : nullptr;
  if (!A || !K || C->getPredicate() != ICmpInst::ICMP_ULT || K->getZExtValue() != 0x72800000u || A->getOpcode() != Instruction::Add || A->getOperand(0) != bits_of(x) && bits_of(A->getOperand(0)) != bits_of(x)) return false;
  auto *K2 = dyn_cast<ConstantInt>(A->getOperand(1));
  if (!K2 || (uint32_t)K2->getZExtValue() != 0xf3000000u) return false;
  for (User *U : cond->users()) {
    if (U == Br) continue;
    auto *CB = dyn_cast<CallBase>(U);
    if (!CB || !CB->getCalledFunction() || !CB->getCalledFunction()->getName().contains("ballot")) return false;
  }
  const bool fast_true = Br->getSuccessor(0) == B0;
  IRBuilder<> B(B0->getTerminator());
  P->setIncomingValue(i, B.CreateUnaryIntrinsic(Intrinsic::sqrt, x, nullptr, "sqrt_restored"));
  cond->replaceAllUsesWith(ConstantInt::get(cond->getType(), fast_true ? 1 : 0));
  return true;
}
void simt_sqrt_restore(Module *M) {
  const char *e = std::getenv("CUPBOP_SQRT_RESTORE");
  if (!e || !std::atoi(e)) return;
  for (Function &F : *M) {
    if (F.isDeclaration()) continue;
    unsigned n = 0;
    std::vector<PHINode *> phis;
    for (BasicBlock &BB : F)
      for (PHINode &P : BB.phis())
        if (P.getType()->isFloatTy()) phis.push_back(&P);
    for (PHINode *P : phis)
      for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
        if (restore_sqrt(P, i)) { n++; break; }
    if (n) fprintf(stderr, "[sqrt] %s: %u square roots restored\n", F.getName().str().c_str(), n);
  }
}

// --- CUPBOP_ADDR_CARRY=1 (default 0): the 64-bit add the lifter spells in 32-bit halves (sm_5x IADD / IADD.X): lo = (B & m) + a, carry = lo > m, hi = (B >> 32) + ah + carry,
// (hi << 32) | (lo & m), m = 0xffffffff, is B + ((ah << 32) | a) modulo 2^64: exact, no assumption. a = x << k with ah = x >>s (32 - k) is sext(x) << k.
static bool and_mask(Value *V, Value *&x) {
  auto *I = dyn_cast<BinaryOperator>(V);
  if (!I || I->getOpcode() != Instruction::And) return false;
  auto *C = dyn_cast<ConstantInt>(I->getOperand(1));
  if (!C || C->getZExtValue() != 0xffffffffu) return false;
  x = I->getOperand(0);
  return true;
}
void simt_addr_carry(Module *M) {
  const char *e = std::getenv("CUPBOP_ADDR_CARRY");
  if (!e || !std::atoi(e)) return;
  LLVMContext &C = M->getContext();
  Type *I64 = Type::getInt64Ty(C);
  auto add_ops = [](Value *V, Value *&a, Value *&b) { auto *I = dyn_cast<BinaryOperator>(V); if (!I || I->getOpcode() != Instruction::Add) return false; a = I->getOperand(0); b = I->getOperand(1); return true; };
  for (Function &F : *M) {
    if (F.isDeclaration()) continue;
    unsigned n = 0;
    std::vector<BinaryOperator *> shls;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *S = dyn_cast<BinaryOperator>(&I); S && S->getOpcode() == Instruction::Shl && S->getType()->isIntegerTy(64))
          if (auto *K = dyn_cast<ConstantInt>(S->getOperand(1)); K && K->getZExtValue() == 32) shls.push_back(S);
    for (BinaryOperator *S : shls) {
      // hi = (B >> 32) + ah + zext(lo > m)
      Value *h0, *h1, *cz = nullptr, *rest = nullptr;
      if (!add_ops(S->getOperand(0), h0, h1)) continue;
      if (isa<ZExtInst>(h1) && cast<ZExtInst>(h1)->getSrcTy()->isIntegerTy(1)) { cz = h1; rest = h0; }
      else if (isa<ZExtInst>(h0) && cast<ZExtInst>(h0)->getSrcTy()->isIntegerTy(1)) { cz = h0; rest = h1; }
      if (!cz) continue;
      auto *cmp = dyn_cast<ICmpInst>(cast<ZExtInst>(cz)->getOperand(0));
      if (!cmp || cmp->getPredicate() != ICmpInst::ICMP_UGT) continue;
      auto *cm = dyn_cast<ConstantInt>(cmp->getOperand(1));
      if (!cm || cm->getZExtValue() != 0xffffffffu) continue;
      Value *lo = cmp->getOperand(0), *l0, *l1, *r0, *r1;
      if (!add_ops(lo, l0, l1) || !add_ops(rest, r0, r1)) continue;
      // lo = (B & m) + zext(a), rest = (B >> 32) + zext(ah), either order
      Value *Bv = nullptr, *az = nullptr;
      if (and_mask(l0, Bv)) az = l1; else if (and_mask(l1, Bv)) az = l0; else continue;
      auto hi_of = [&](Value *V) { auto *I = dyn_cast<BinaryOperator>(V); auto *K = I ? dyn_cast<ConstantInt>(I->getOperand(1)) : nullptr; return I && I->getOpcode() == Instruction::LShr && I->getOperand(0) == Bv && K && K->getZExtValue() == 32; };
      Value *ahz = hi_of(r0) ? r1 : hi_of(r1) ? r0 : nullptr;
      if (!ahz) continue;
      auto *za = dyn_cast<ZExtInst>(az), *zh = dyn_cast<ZExtInst>(ahz);
      if (!za || !zh || !za->getSrcTy()->isIntegerTy(32) || !zh->getSrcTy()->isIntegerTy(32)) continue;
      // uses of the shl: packed = shl | (lo & m), or shl + ((lo & m) + c)
      for (User *U : std::vector<User *>(S->user_begin(), S->user_end())) {
        auto *P = dyn_cast<BinaryOperator>(U);
        if (!P || (P->getOpcode() != Instruction::Or && P->getOpcode() != Instruction::Add)) continue;
        Value *O = P->getOperand(0) == S ? P->getOperand(1) : P->getOperand(0), *inner = nullptr, *c = nullptr;
        if (!and_mask(O, inner)) {
          Value *o0, *o1;
          if (P->getOpcode() != Instruction::Add || !add_ops(O, o0, o1) || !isa<ConstantInt>(o1) || !and_mask(o0, inner)) continue;
          c = o1;
        }
        if (inner != lo) continue;
        IRBuilder<> B(P);
        Value *a = za->getOperand(0), *ah = zh->getOperand(0), *A = nullptr;
        auto *sa = dyn_cast<BinaryOperator>(a), *sh = dyn_cast<BinaryOperator>(ah);
        if (sa && sh && sa->getOpcode() == Instruction::Shl && sh->getOpcode() == Instruction::AShr && sa->getOperand(0) == sh->getOperand(0))
          if (auto *k = dyn_cast<ConstantInt>(sa->getOperand(1)), *k2 = dyn_cast<ConstantInt>(sh->getOperand(1)); k && k2 && k->getZExtValue() + k2->getZExtValue() == 32)
            A = B.CreateShl(B.CreateSExt(sa->getOperand(0), I64), k->getZExtValue());
        if (!A) A = B.CreateOr(B.CreateShl(B.CreateZExt(ah, I64), 32), B.CreateZExt(a, I64));
        Value *R = B.CreateAdd(Bv, A, "addr_carry");
        if (c) R = B.CreateAdd(R, c);
        P->replaceAllUsesWith(R);
        n++;
      }
    }
    if (n) fprintf(stderr, "[addr-carry] %s: %u 64-bit adds in halves folded\n", F.getName().str().c_str(), n);
  }
}
