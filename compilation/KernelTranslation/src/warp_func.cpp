
#include "warp_func.h"
#include "flag.h"
#include "tool.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <cstring>
#include <set>
#include <vector>

#include "insert_warp_loop.h"
#include <map>

namespace cupbop {

using namespace llvm;
using namespace std;

ReplaceWarpLevelPrimitive::ReplaceWarpLevelPrimitive(MapOpt mapping)
    : mapping_(mapping) {}


// virt: the lifter emits a ballot at every SASS branch (legacy_entry/taken/path
// masks) whose only consumers are bar.warp.sync masks and the mask operand of
// further warp ops -- reconvergence bookkeeping. In the warp loop a sync's mask
// is irrelevant (passes run in sequence) and such a mask equals the active set,
// so ballot(mask, p) == ballot(-1, p): fold these ballots to the full mask and
// drop the syncs they fed. Anything with a data use is left alone.
static void foldReconvergenceMasks(Module &m) {
  auto isVote = [](CallInst *ci) {
    Function *f = ci->getCalledFunction();
    if (!f) return false;
    auto n = f->getName();
    return n.starts_with("llvm.nvvm.vote.") || n == "__cupbop_activemask" || n == "llvm.nvvm.activemask";
  };
  auto isWarpOp = [](Function *f) {
    auto n = f->getName();
    return n.starts_with("llvm.nvvm.vote.") || n.starts_with("llvm.nvvm.shfl.") || n.starts_with("llvm.nvvm.match.");
  };
  std::vector<CallInst *> cands;
  for (auto &f : m)
    for (auto &bb : f)
      for (auto &i : bb)
        if (auto *ci = dyn_cast<CallInst>(&i))
          if (!ci->isInlineAsm() && isVote(ci)) cands.push_back(ci);
  if (cands.empty()) return;
  std::set<CallInst *> syncs_fed;
  int folded = 0;
  for (auto *ci : cands) {
    std::set<CallInst *> local_syncs;
    std::set<Value *> seen;
    std::vector<Value *> work{ci};
    bool ok = true;
    while (ok && !work.empty()) {
      Value *v = work.back(); work.pop_back();
      if (!seen.insert(v).second) continue;
      for (Use &u : v->uses()) {
        auto *I = dyn_cast<Instruction>(u.getUser());
        if (!I) { ok = false; break; }
        if (auto *call = dyn_cast<CallInst>(I)) {
          Function *cf = call->getCalledFunction();
          if (!cf || call->isInlineAsm()) { ok = false; break; }
          if (cf->getName() == "llvm.nvvm.bar.warp.sync") { local_syncs.insert(call); continue; }
          if (isWarpOp(cf) && u.getOperandNo() == 0) continue; // mask operand of another warp op
          if (cf->getName().starts_with("llvm.dbg")) continue;
          ok = false; break;
        }
        if (auto *bo = dyn_cast<BinaryOperator>(I)) {
          auto op = bo->getOpcode();
          if (op == Instruction::And || op == Instruction::Or || op == Instruction::Xor) { work.push_back(I); continue; }
          ok = false; break;
        }
        if (isa<SelectInst>(I)) { if (u.getOperandNo() == 0) { ok = false; break; } work.push_back(I); continue; }
        if (isa<PHINode>(I) || isa<ZExtInst>(I) || isa<SExtInst>(I) || isa<TruncInst>(I) || isa<BitCastInst>(I) || isa<FreezeInst>(I)) { work.push_back(I); continue; }
        if (auto *st = dyn_cast<StoreInst>(I)) { // PHI-demoted lifter temporaries: follow the alloca's loads
          if (u.getOperandNo() != 0) { ok = false; break; }
          auto *ai = dyn_cast<AllocaInst>(st->getPointerOperand()->stripPointerCasts());
          if (!ai) { ok = false; break; }
          bool simple = true;
          for (User *au : ai->users()) {
            if (isa<LoadInst>(au) || isa<StoreInst>(au)) continue;
            if (auto *ii = dyn_cast<IntrinsicInst>(au)) if (ii->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(ii)) continue;
            if (auto *cc = dyn_cast<CallInst>(au)) if (cc->getCalledFunction() && cc->getCalledFunction()->getName().starts_with("llvm.dbg")) continue;
            simple = false; break;
          }
          if (!simple) { ok = false; break; }
          for (User *au : ai->users()) if (auto *ld = dyn_cast<LoadInst>(au)) work.push_back(ld);
          continue;
        }
        ok = false; break;
      }
    }
    if (!ok) continue;
    ci->replaceAllUsesWith(Constant::getAllOnesValue(ci->getType()));
    ci->eraseFromParent();
    folded++;
    syncs_fed.insert(local_syncs.begin(), local_syncs.end());
  }
  for (auto *s : syncs_fed) s->eraseFromParent();
  if (folded)
    fprintf(stderr, "[virt] folded %d reconvergence ballot/activemask sites (mask-only results); erased %zu bar.warp.sync fed by them\n", folded, syncs_fed.size());
}

// The vote/activemask result ci only reaches bar.warp.sync masks and the mask operand of other warp ops (through
// bit ops, casts, phis, selects and PHI-demoted lifter temporaries): reconvergence bookkeeping, no data use.
// local_syncs collects the bar.warp.sync calls it feeds. Same test as foldReconvergenceMasks above (kept as its own
// copy so that the NT32 translation path runs exactly the code it ran before).
static bool voteFeedsOnlyMasks(CallInst *ci, std::set<CallInst *> &local_syncs) {
  auto isWarpOp = [](Function *f) {
    auto n = f->getName();
    return n.starts_with("llvm.nvvm.vote.") || n.starts_with("llvm.nvvm.shfl.") || n.starts_with("llvm.nvvm.match.");
  };
  {
    std::set<Value *> seen;
    std::vector<Value *> work{ci};
    bool ok = true;
    while (ok && !work.empty()) {
      Value *v = work.back(); work.pop_back();
      if (!seen.insert(v).second) continue;
      for (Use &u : v->uses()) {
        auto *I = dyn_cast<Instruction>(u.getUser());
        if (!I) { ok = false; break; }
        if (auto *call = dyn_cast<CallInst>(I)) {
          Function *cf = call->getCalledFunction();
          if (!cf || call->isInlineAsm()) { ok = false; break; }
          if (cf->getName() == "llvm.nvvm.bar.warp.sync") { local_syncs.insert(call); continue; }
          if (isWarpOp(cf) && u.getOperandNo() == 0) continue; // mask operand of another warp op
          if (cf->getName().starts_with("llvm.dbg")) continue;
          ok = false; break;
        }
        if (auto *bo = dyn_cast<BinaryOperator>(I)) {
          auto op = bo->getOpcode();
          if (op == Instruction::And || op == Instruction::Or || op == Instruction::Xor) { work.push_back(I); continue; }
          ok = false; break;
        }
        if (isa<SelectInst>(I)) { if (u.getOperandNo() == 0) { ok = false; break; } work.push_back(I); continue; }
        if (isa<PHINode>(I) || isa<ZExtInst>(I) || isa<SExtInst>(I) || isa<TruncInst>(I) || isa<BitCastInst>(I) || isa<FreezeInst>(I)) { work.push_back(I); continue; }
        if (auto *st = dyn_cast<StoreInst>(I)) { // PHI-demoted lifter temporaries: follow the alloca's loads
          if (u.getOperandNo() != 0) { ok = false; break; }
          auto *ai = dyn_cast<AllocaInst>(st->getPointerOperand()->stripPointerCasts());
          if (!ai) { ok = false; break; }
          bool simple = true;
          for (User *au : ai->users()) {
            if (isa<LoadInst>(au) || isa<StoreInst>(au)) continue;
            if (auto *ii = dyn_cast<IntrinsicInst>(au)) if (ii->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(ii)) continue;
            if (auto *cc = dyn_cast<CallInst>(au)) if (cc->getCalledFunction() && cc->getCalledFunction()->getName().starts_with("llvm.dbg")) continue;
            simple = false; break;
          }
          if (!simple) { ok = false; break; }
          for (User *au : ai->users()) if (auto *ld = dyn_cast<LoadInst>(au)) work.push_back(ld);
          continue;
        }
        ok = false; break;
      }
    }
    return ok;
  }
}
// ---------------------------------------------------------------------------
// Warp-collective operations when a hardware warp is not one CUDA warp (2026-11-02). Build-time refusals that
// replace silent wrong results; nothing here runs with 32-lane hardware warps on the 1:1 schedule or with the
// S = 1 core mapping (NT32), so those translations are unchanged.
//  - 1:1 schedule (SCHEDULE=2) with VORTEX_NUM_THREADS != 32 (a real NT16 bitstream, or rt_simd_width "as-if
//    NT=16" on NT32): a CUDA warp spans two hardware warps (NT=16) or shares one with another CUDA warp (NT=64),
//    and every warp-level lowering of this schedule works on the hardware warp: mma/ldmatrix/movmatrix (32-lane
//    fragments; under as-if NT16 also the NT32 TCU tile with half the lanes masked), wmma/wgmma, redux, match,
//    %laneid, and shuffles/votes whose lanes cross the 16-lane boundary (E12 stage 1: lifted CUTLASS GEMM NT16 s2
//    FAIL with no error). Kept: votes/activemask that only feed masks (lifted reconvergence bookkeeping), and at
//    NT < 32 shuffles that provably stay in one hardware warp (constant segment width <= NT, butterfly lane mask
//    < NT, constant member mask within lanes [0, NT), or a constant / kernel-argument value).
//  - core mapping sub-pass form (S > 1): staged are shfl, vote/activemask, every mma.sync form replace_nvvm_mma_intrinsics
//    lowers, movmatrix and (16 lanes) ldmatrix/stmatrix and redux.sync; the %laneid asm reads the logical lane. wmma, wgmma,
//    match and anything else would run once per sub-pass with 32-lane semantics -> refused. The staged mma/movmatrix glue
//    exists only on a real NT=16 build (TCU glue for f16/bf16: NT=16 TCU build); with a wider bitstream (as-if NT16,
//    CUPBOP_VIRT_LANES=16) the link used to fail on an undefined __cupbop_*_glue16 symbol -> refused with a reason (the
//    TCU tile is fixed by the synthesized NT, 2026-10-26_TCU_DATAPATH_KO.md 6.1).
// CUPBOP_ALLOW_NARROW_WARP_OPS=1 translates anyway (warnings only).
// ---------------------------------------------------------------------------
static bool narrowWarpOpsAllowed() {
  const char *e = std::getenv("CUPBOP_ALLOW_NARROW_WARP_OPS");
  return e && std::atoi(e) != 0;
}
// VX_CFG_NUM_THREADS of the bitstream from VORTEX_CONFIGS (the SimX build flags the examples pass), 0 if unknown
static int bitstreamThreads() {
  const char *e = std::getenv("VORTEX_CONFIGS");
  if (!e) return 0;
  const std::string s(e), k("-DVX_CFG_NUM_THREADS=");
  size_t p = s.find(k);
  return p == std::string::npos ? 0 : std::atoi(s.c_str() + p + k.size());
}
static bool bitstreamHasTcu() {
  const char *e = std::getenv("VORTEX_CONFIGS");
  return e && std::string(e).find("-DVX_CFG_EXT_TCU_ENABLE") != std::string::npos;
}
// The sub-pass glue (__cupbop_*_glue16, cudaKernelImpl.cpp, cudaKernelImpl_dtypes.inc) is only built for an NT=16
// bitstream; the TCU glue runs on the NT=16 TCU tile (needTcu), the software glue needs no TCU. Unknown configuration
// (no VORTEX_CONFIGS): left to the link, as before.
static void requireGlue16Bitstream(const char *what, int n, bool needTcu = true) {
  const int hw = bitstreamThreads();
  if (hw == 0 || (hw == 16 && (!needTcu || bitstreamHasTcu()))) return;
  fprintf(stderr, "error: virt sub-pass form (16 lanes): %d %s site(s) need the NT=16 glue, but the bitstream is "
                  "VX_CFG_NUM_THREADS=%d%s (as-if NT=16 / CUPBOP_VIRT_LANES on a wider warp): its TCU tile is fixed by the "
                  "synthesized NT and cannot serve a 16-lane warp; refusing (no __cupbop_*_glue16 for this build)\n",
          n, what, hw, bitstreamHasTcu() ? "" : " without the TCU");
  if (!narrowWarpOpsAllowed()) exit(1);
}
// What a call does across the CUDA warp, by callee name as the module has it when ReplaceWarpLevelPrimitive runs
// (after init_block, lower_ldmatrix_asm, lower_redux_sync); nullptr: not a warp-level operation.
static const char *warpCollectiveKind(const CallInst *CI) {
  if (CI->isInlineAsm()) {
    auto *IA = dyn_cast<InlineAsm>(CI->getCalledOperand());
    if (!IA) return nullptr;
    const std::string &a = IA->getAsmString();
    for (const char *k : {"mma.", "ldmatrix", "stmatrix", "movmatrix", "redux.sync", "match.", "shfl.sync", "vote.",
                          "activemask", "%laneid", "%lanemask"})
      if (a.find(k) != std::string::npos) return "asm";
    return nullptr;
  }
  const Function *F = CI->getCalledFunction();
  if (!F) return nullptr;
  StringRef n = F->getName();
  for (const char *p : {"llvm.nvvm.mma.", "cupbop.mma.", "llvm.nvvm.wmma.", "llvm.nvvm.ldmatrix", "llvm.nvvm.stmatrix",
                        "__cupbop_mma_", "__cupbop_wmma", "__vx_wmma", "__cupbop_wgmma", "__cupbop_ldmatrix",
                        "__cupbop_stmatrix", "__cupbop_movmatrix"})
    if (n.starts_with(p)) return "tensor";
  if (n.contains("nvcuda4wmma")) return "tensor";
  if (n == "__cupbop_redux_sync" || n.starts_with("llvm.nvvm.redux.sync.") || n.starts_with("llvm.nvvm.match.")) return "collective";
  if (n == "llvm.nvvm.read.ptx.sreg.laneid" || n.starts_with("llvm.nvvm.read.ptx.sreg.lanemask.") || n == "__cupbop_laneid") return "laneid";
  if (n.starts_with("llvm.nvvm.shfl.")) return "shfl";
  if (n.starts_with("llvm.nvvm.vote.") || n == "__cupbop_activemask" || n == "llvm.nvvm.activemask") return "vote";
  return nullptr;
}
// Functions a launched kernel can reach by direct calls (merged-module source twins __src_* are never launched).
static std::vector<Function *> launchedClosure(Module &m) {
  std::vector<Function *> work, out;
  std::set<Function *> seen;
  for (auto &F : m)
    if (!F.isDeclaration() && isKernelFunction(&m, &F) && !F.getName().starts_with("__src_")) work.push_back(&F);
  while (!work.empty()) {
    Function *F = work.back(); work.pop_back();
    if (!seen.insert(F).second) continue;
    out.push_back(F);
    for (auto &I : instructions(*F))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (Function *G = CB->getCalledFunction())
          if (!G->isDeclaration()) work.push_back(G);
  }
  return out;
}
static bool constU64(const Value *V, uint64_t &out) {
  if (auto *C = dyn_cast<ConstantInt>(V)) { out = C->getZExtValue(); return true; }
  return false;
}
// 1:1 schedule, NT < 32: does this llvm.nvvm.shfl.sync.* give the CUDA result on 16-lane hardware warps?
static bool shflStaysInHardwareWarp(Module &m, CallInst *CI, int nt) {
  if (nt >= 32 || CI->arg_size() != 4) return false;
  const StringRef n = CI->getCalledFunction()->getName();
  const Value *val = CI->getArgOperand(1);
  if (isa<Constant>(val)) return true; // every lane gets the same value whatever the source lane
  if (auto *A = dyn_cast<Argument>(val)) if (isKernelFunction(&m, const_cast<Function *>(A->getParent()))) return true;
  uint64_t M, b, c;
  if (constU64(CI->getArgOperand(3), c)) { // PTX c = segmask << 8 | clamp: segments of 32 - segmask lanes
    const uint64_t seg = (c >> 8) & 31, width = 32 - seg;
    if (seg && width <= (uint64_t)nt && !(width & (width - 1))) return true;
  }
  if (n.contains(".bfly.") && constU64(CI->getArgOperand(2), b) && b < (uint64_t)nt) return true;
  if (constU64(CI->getArgOperand(0), M) && !((M & 0xffffffffull) >> nt)) return true; // members in lanes [0, nt)
  return false;
}
static void rejectNarrowWarpOps1to1(Module &m, int nt) {
  if (nt == 32) return;
  int bad = 0;
  for (Function *F : launchedClosure(m))
    for (auto &I : instructions(*F)) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI) continue;
      const char *kind = warpCollectiveKind(CI);
      if (!kind) continue;
      if (!strcmp(kind, "shfl") && shflStaysInHardwareWarp(m, CI, nt)) continue;
      if (!strcmp(kind, "vote")) {
        std::set<CallInst *> syncs;
        if (voteFeedsOnlyMasks(CI, syncs)) continue;
        uint64_t M;
        if (nt < 32 && CI->arg_size() >= 1 && CI->getCalledFunction()->getName().starts_with("llvm.nvvm.vote.") &&
            constU64(CI->getArgOperand(0), M) && !((M & 0xffffffffull) >> nt)) continue;
      }
      if (bad++ < 12) {
        std::string what = CI->isInlineAsm() ? cast<InlineAsm>(CI->getCalledOperand())->getAsmString().substr(0, 60)
                                             : CI->getCalledFunction()->getName().str();
        fprintf(stderr, "[narrow-warp] %s: %s %s in %s\n", narrowWarpOpsAllowed() ? "WARNING" : "error", kind,
                what.c_str(), F->getName().str().substr(0, 80).c_str());
      }
    }
  if (!bad) return;
  fprintf(stderr, "error: 1:1 schedule (SCHEDULE=2) with %d-lane hardware warps (VORTEX_NUM_THREADS=%d): %d warp-collective "
                  "operation(s) need a CUDA warp's 32 lanes in one hardware warp and would give wrong results; refusing. "
                  "Use VORTEX_NUM_THREADS=32 (or the core mapping, SCHEDULE=1, which stages shfl/vote for NT=16); "
                  "CUPBOP_ALLOW_NARROW_WARP_OPS=1 translates anyway\n", nt, nt, bad);
  if (!narrowWarpOpsAllowed()) exit(1);
}
// Core mapping, S > 1: before staging. Kernel-body mma.sync / movmatrix are staged later; everything else of the
// tensor / collective / asm kinds, a staged kind outside a kernel body, and the %laneid asm (lowered to the hardware
// lane, __cupbop_laneid, before the warp loop exists) would run per sub-pass with 32-lane semantics.
static void rejectUnstagedWarpOpsSubpass(Module &m) {
  int bad = 0;
  for (Function *F : launchedClosure(m)) {
    const bool kernel = isKernelFunction(&m, F);
    for (auto &I : instructions(*F)) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI) continue;
      const char *kind = warpCollectiveKind(CI);
      if (!kind || !strcmp(kind, "shfl") || !strcmp(kind, "vote")) continue; // staged (or left with the old warning)
      if (!strcmp(kind, "laneid") && !CI->isInlineAsm() && CI->getCalledFunction()->getName() != "__cupbop_laneid") continue;
      if (kernel && !CI->isInlineAsm()) {
        StringRef n = CI->getCalledFunction()->getName();
        if (n.starts_with("llvm.nvvm.mma.") || n.starts_with("cupbop.mma.") || n == "__cupbop_movmatrix_m8n8_trans_b16") continue;
        if ((n == "__cupbop_ldmatrix_m8n8_b16" || n == "__cupbop_stmatrix_m8n8_b16" || n == "__cupbop_redux_sync") && getVirtGeom().lanes == 16) continue;
      }
      if (kernel && CI->isInlineAsm() &&
          cast<InlineAsm>(CI->getCalledOperand())->getAsmString().find("movmatrix.sync.aligned.m8n8.trans.b16") != std::string::npos)
        continue;
      if (bad++ < 12) {
        std::string what = CI->isInlineAsm() ? cast<InlineAsm>(CI->getCalledOperand())->getAsmString().substr(0, 60)
                                             : CI->getCalledFunction()->getName().str();
        fprintf(stderr, "[narrow-warp] %s: %s %s in %s\n", narrowWarpOpsAllowed() ? "WARNING" : "error", kind,
                what.c_str(), F->getName().str().substr(0, 80).c_str());
      }
    }
  }
  if (!bad) return;
  const VirtGeom vg = getVirtGeom();
  fprintf(stderr, "error: virt sub-pass form (S=%d, %d lanes): %d warp-collective operation(s) have no sub-pass form "
                  "(only shfl, vote/activemask, mma.sync, movmatrix, ldmatrix/stmatrix and redux.sync are staged) and would run per sub-pass "
                  "with 32-lane semantics; refusing. Use 32-lane warps (NT32, no CUPBOP_VIRT_LANES); "
                  "CUPBOP_ALLOW_NARROW_WARP_OPS=1 translates anyway\n", vg.subpasses, vg.lanes, bad);
  if (!narrowWarpOpsAllowed()) exit(1);
}

// virt sub-pass form (S > 1): a hardware thread runs the logical lanes l, l+L, ... through ONE copy of the
// control flow, so a loop whose trip count differs between those lanes runs on sub-pass 0's count and the
// warp ops staged inside it see the other sub-passes on the wrong iteration (conformance div_loop_ballot:
// lane t+16 copied lane t's ballot pattern). Until a per-sub-pass gate exists (decision 2A, 2026-10-24) the
// translator refuses such kernels instead of producing wrong results: a warp op that may legally run with
// part of the warp (activemask, or a vote/shfl/match whose mask is not the constant 0xffffffff) inside a loop
// with an exit condition that depends on the thread or lane id. A full-mask op is exempt: CUDA requires all
// 32 lanes to reach it together, so in a valid program the enclosing loops run the same trips on every lane
// (jaccard's rounded bound, cc-cuda's warp-uniform worklist loop). mma/movmatrix are warp-wide by definition.
// CUPBOP_VIRT_ALLOW_LANE_LOOPS=1 translates anyway (warning only; the conformance test uses it).
static bool isLaneSource(const Instruction *I) {
  auto *CI = dyn_cast<CallInst>(I);
  if (!CI) return false;
  if (CI->isInlineAsm()) {
    auto *IA = dyn_cast<InlineAsm>(CI->getCalledOperand());
    return IA && IA->getAsmString().find("%laneid") != std::string::npos;
  }
  const Function *F = CI->getCalledFunction();
  if (!F) return false;
  StringRef n = F->getName();
  return n.starts_with("llvm.nvvm.read.ptx.sreg.tid.") || n == "llvm.nvvm.read.ptx.sreg.laneid" ||
         n.starts_with("llvm.nvvm.shfl.") || n == "__cupbop_laneid"; // a shuffle result is per lane too
}
static bool isStagedWarpOp(const CallInst *CI) {
  if (CI->isInlineAsm() || !CI->getCalledFunction()) return false;
  StringRef n = CI->getCalledFunction()->getName();
  return n.starts_with("llvm.nvvm.vote.") || n.starts_with("llvm.nvvm.shfl.") || n.starts_with("llvm.nvvm.match.") ||
         n.starts_with("llvm.nvvm.mma.") || n.starts_with("llvm.nvvm.movmatrix") || n == "__cupbop_activemask" ||
         n == "__cupbop_redux_sync";
}
// The mask of an inlined CUDA wrapper (__shfl_sync, __ballot_sync, ...) reaches the intrinsic through the
// wrapper's parameter slot (an alloca the earlier mem2reg never saw): follow stores into that slot.
static bool isFullMask(const Value *V) {
  V = V->stripPointerCasts();
  if (auto *C = dyn_cast<ConstantInt>(V)) return C->getBitWidth() >= 32 && C->getValue().trunc(32).isAllOnes();
  auto *Ld = dyn_cast<LoadInst>(V);
  auto *AI = Ld ? dyn_cast<AllocaInst>(getUnderlyingObject(Ld->getPointerOperand())) : nullptr;
  if (!AI) return false;
  bool stored = false;
  for (const User *U : AI->users()) {
    if (auto *St = dyn_cast<StoreInst>(U)) {
      if (St->getPointerOperand() != AI || !isFullMask(St->getValueOperand())) return false;
      stored = true;
    } else if (!isa<LoadInst>(U) && !(isa<IntrinsicInst>(U) && cast<IntrinsicInst>(U)->isLifetimeStartOrEnd())) return false;
  }
  return stored;
}
static bool mayRunPartialWarp(const CallInst *CI) {
  StringRef n = CI->getCalledFunction()->getName();
  if (n == "__cupbop_activemask") return true;
  if (n.starts_with("llvm.nvvm.mma.") || n.starts_with("llvm.nvvm.movmatrix")) return false;
  if (n == "__cupbop_redux_sync") return !isFullMask(CI->getArgOperand(1));
  return !isFullMask(CI->getArgOperand(0));
}
// Runs before foldReconvergenceMasks, which turns a mask-only __activemask() into -1: the masks are judged
// as the program wrote them (div_loop_ballot's __ballot_sync(__activemask(), ...) stays partial).
static void markPartialMaskWarpOps(Module &m) {
  for (auto &F : m.functions())
    for (auto &I : instructions(F))
      if (auto *CI = dyn_cast<CallInst>(&I))
        if (isStagedWarpOp(CI) && mayRunPartialWarp(CI))
          CI->setMetadata("cupbop.virt_partial_mask", MDNode::get(m.getContext(), {}));
}
static void rejectLaneVariantLoopsAroundWarpOps(Module &m) {
  const bool allow = std::getenv("CUPBOP_VIRT_ALLOW_LANE_LOOPS") && std::atoi(std::getenv("CUPBOP_VIRT_ALLOW_LANE_LOOPS"));
  int found = 0;
  for (auto &F : m.functions()) {
    if (F.isDeclaration()) continue;
    std::vector<CallInst *> ops;
    for (auto &I : instructions(F))
      if (auto *CI = dyn_cast<CallInst>(&I))
        if (isStagedWarpOp(CI)) ops.push_back(CI);
    if (ops.empty()) continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    // lane-dependent values: SSA uses, memory written with one (by underlying object), loads at a
    // lane-dependent address, and phis joining a lane-dependent branch (fixpoint)
    std::set<const Value *> T, Tobj;
    auto divBranch = [&](const BasicBlock *B) {
      auto *Br = dyn_cast<BranchInst>(B->getTerminator());
      return Br && Br->isConditional() && T.count(Br->getCondition());
    };
    for (bool changed = true; changed;) {
      changed = false;
      for (auto &I : instructions(F)) {
        if (auto *St = dyn_cast<StoreInst>(&I)) {
          if (T.count(St->getValueOperand()) && Tobj.insert(getUnderlyingObject(St->getPointerOperand())).second) changed = true;
          continue;
        }
        if (T.count(&I)) continue;
        bool t = isLaneSource(&I);
        if (!t) {
          if (auto *Ld = dyn_cast<LoadInst>(&I)) t = T.count(Ld->getPointerOperand()) || Tobj.count(getUnderlyingObject(Ld->getPointerOperand()));
          else if (auto *CI = dyn_cast<CallInst>(&I); CI && isStagedWarpOp(CI)) t = false; // vote/ballot results are warp-uniform
          else for (auto &U : I.operands()) if (T.count(U.get())) { t = true; break; }
          if (!t)
            if (auto *Phi = dyn_cast<PHINode>(&I)) {
              BasicBlock *D = nullptr;
              for (auto *P : Phi->blocks()) { if (divBranch(P)) t = true; D = D ? DT.findNearestCommonDominator(D, P) : P; }
              if (D && divBranch(D)) t = true;
            }
        }
        if (t) { T.insert(&I); changed = true; }
      }
    }
    for (auto *CI : ops)
      for (Loop *L = CI->getMetadata("cupbop.virt_partial_mask") ? LI.getLoopFor(CI->getParent()) : nullptr; L; L = L->getParentLoop()) {
        SmallVector<BasicBlock *, 4> exiting;
        L->getExitingBlocks(exiting);
        bool lane = false;
        for (auto *E : exiting) lane |= divBranch(E);
        if (!lane) continue;
        found++;
        std::string ms;
        if (CI->arg_size()) { raw_string_ostream os(ms); CI->getArgOperand(0)->print(os); }
        fprintf(stderr, "[virt-stage] %s: %s in %s inside loop %s whose trip count depends on the lane (mask:%s)\n",
                allow ? "WARNING" : "error", CI->getCalledFunction()->getName().str().c_str(), F.getName().str().c_str(),
                L->getHeader()->getName().str().c_str(), ms.c_str());
        break;
      }
  }
  if (found && !allow) {
    fprintf(stderr, "error: virt sub-pass form (S=%d, %d lanes): %d warp op(s) in lane-dependent loops are unsupported at S>1 "
                    "(per-sub-pass loop gate not implemented); use 32 lanes (NT32, no CUPBOP_VIRT_LANES) or set "
                    "CUPBOP_VIRT_ALLOW_LANE_LOOPS=1 to translate anyway\n",
            getVirtGeom().subpasses, getVirtGeom().lanes, found);
    exit(1);
  }
}

static void replaceMmaStaged(Module &m);
static void replaceMovmatrixStaged(Module &m);
static void replaceLdStMatrixStaged(Module &m);
static void replaceReduxStaged(Module &m);
PreservedAnalyses ReplaceWarpLevelPrimitive::run(Module &m, ModuleAnalysisManager&) {
  if (mapping_ == MAPPING_1TO1) rejectNarrowWarpOps1to1(m, getVirtGeom().nt);
  if (mapping_ == MAPPING_CORE && getVirtGeom().subpasses > 1) rejectUnstagedWarpOpsSubpass(m);
  if (mapping_ == MAPPING_CORE && getVirtGeom().subpasses > 1) markPartialMaskWarpOps(m);
  if (mapping_ == MAPPING_CORE) foldReconvergenceMasks(m); // virt: before staging
  if (mapping_ == MAPPING_CORE && getVirtGeom().subpasses > 1) rejectLaneVariantLoopsAroundWarpOps(m);
  if (mapping_ == MAPPING_CORE && getVirtGeom().subpasses > 1) replaceMmaStaged(m); // virt sub-pass form: mma.sync -> NT=16 TCU glue
  if (mapping_ == MAPPING_CORE && getVirtGeom().subpasses > 1) replaceMovmatrixStaged(m);
  if (mapping_ == MAPPING_CORE && getVirtGeom().subpasses > 1) replaceLdStMatrixStaged(m);
  if (mapping_ == MAPPING_CORE && getVirtGeom().subpasses > 1) replaceReduxStaged(m);
  // In FLAT mode, skip shfl replacement here — it's handled by
  // replace_warp_shfl_early() after init_block (barrier insertion order matters).
  if (mapping_ != MAPPING_FLAT)
    replaceWarpShfl(m);
  replaceWarpVote(m);
  return PreservedAnalyses::all();
}

bool ReplaceWarpLevelPrimitive::replaceWarpVote(Module &m) {

  DenseSet<StringRef> voteFuncs;
  voteFuncs = {"llvm.nvvm.vote.any.sync",
              "llvm.nvvm.vote.all.sync",
              "llvm.nvvm.vote.uni.sync",
              "llvm.nvvm.vote.ballot.sync"};

  // get the callee functions to be replaced
  set<CallInst *> replace;
  for (auto &f : m.functions()) {
    // if (isKernelFunction(&m, &f))
    //   continue;
    auto name_caller = f.getName().str();
    for (auto &bb : f) {
      for (auto &i : bb) {
        auto ci = dyn_cast<CallInst>(&i);
        if (!ci || ci->isInlineAsm())
          continue;
        auto name_callee = ci->getCalledOperand()->getName();
        if (voteFuncs.count(name_callee.str())) {
          //dbgs() << "\nvote detected: ";
          ci->print(dbgs(), true);
          //dbgs() << "\n";
          replace.insert(ci);
        }
      }
    }
  }
  // handle different mappings
  switch (mapping_) {
  case MAPPING_CORE: // virt: hardware lanes; with sub-passes (L < 32) staged + glue
    if (getVirtGeom().subpasses > 1) replaceWarpVoteStaged(m, replace);
    else replaceWarpVote1to1(m, replace);
    break;
  case MAPPING_FLAT:
    replaceWarpVoteFlat(m, replace);
    break;
  case MAPPING_1TO1:
    replaceWarpVote1to1(m, replace);
    break;
  case MAPPING_X86:
    replaceWarpVoteX86(m, replace);
    break;
  }
  return !replace.empty();
}

void ReplaceWarpLevelPrimitive::replaceWarpVoteFlat(
    Module &m, const set<CallInst *> &replace) {
  // type
  Type *Int1T = Type::getInt1Ty(m.getContext());
  Type *I32 = Type::getInt32Ty(m.getContext());
  Type *I8 = Type::getInt8Ty(m.getContext());
  // constant
  auto C0 = ConstantInt::get(I32, 0, true);
  auto C1 = ConstantInt::get(I32, 1, true);
  // warp vote pointer
  GlobalVariable *warp_vote_ptr = m.getNamedGlobal("warp_vote");
  assert(warp_vote_ptr != NULL);
  auto vote_count_ptr = m.getNamedGlobal("vote_count");
  assert(vote_count_ptr != NULL);
  for (auto sync_inst : replace) {
    Function *F = sync_inst->getParent()->getParent();
    IRBuilder<> builder(sync_inst);
    CreateIntraWarpBarrier(sync_inst);
    // Store vote in warp_vote array
    auto intra_warp_index_addr = m.getGlobalVariable("intra_warp_index");
    auto intra_warp_index =
        new LoadInst(intra_warp_index_addr->getValueType(),
                     intra_warp_index_addr, "intra_warp_index", sync_inst);
    // Get array index for this thread
    auto GEP =
        GetElementPtrInst::Create(warp_vote_ptr->getValueType(), warp_vote_ptr,
                                  {C0, intra_warp_index}, "", sync_inst);
    // Handle mask
    auto mask = CastInst::CreateIntegerCast(sync_inst->getArgOperand(0), I32,
                                            false, "", sync_inst);
    auto bit_flag = builder.CreateLShr(mask, intra_warp_index);
    auto valid = builder.CreateAnd(C1, bit_flag);
    auto valid_8bit =
        CastInst::CreateIntegerCast(valid, I8, false, "", sync_inst);
    // Get predicate and convert to i8
    auto predict_8bit = CastInst::CreateIntegerCast(sync_inst->getArgOperand(1),
                                                    I8, false, "", sync_inst);
    // Combine mask and predicate
    auto vote_value_8bit = builder.CreateMul(valid_8bit, predict_8bit);
    auto vote_value =
        CastInst::CreateIntegerCast(vote_value_8bit, I32, false, "", sync_inst);
    // Add this thread's vote to count
    auto old_count = builder.CreateLoad(I32, vote_count_ptr, "vote_count");
    auto new_count = builder.CreateAdd(old_count, vote_value);
    builder.CreateStore(new_count, vote_count_ptr);
    CreateIntraWarpBarrier(sync_inst);
    Value *result;
    bool is_any_sync =
        sync_inst->getCalledOperand()->getName() == "llvm.nvvm.vote.any.sync";
    if (is_any_sync) {
      auto count = new LoadInst(I32, vote_count_ptr, "", sync_inst);
      result = builder.CreateICmpNE(count, C0);
    } else {
      auto count = new LoadInst(I32, vote_count_ptr, "", sync_inst);
      // auto block_size = GetCachedBlockSize(F);
      auto block_size_addr = m.getGlobalVariable("block_size");
      auto block_size = createLoad(builder, block_size_addr);
      result = builder.CreateICmpEQ(count, block_size);
    }
    // Reset count
    builder.CreateStore(C0, vote_count_ptr);
    // Replace original instruction
    sync_inst->replaceAllUsesWith(result);
    sync_inst->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpVote1to1(
    Module &m, const set<CallInst *> &replace) {
  auto &ctx = m.getContext();
  Type *I1 = Type::getInt1Ty(ctx);
  Type *I32 = Type::getInt32Ty(ctx);

  // Use mangled C++ names to match runtime symbols
  FunctionCallee fn_all = m.getOrInsertFunction(
      "_Z10__all_syncib", FunctionType::get(I1, {I32, I1}, false));
  FunctionCallee fn_any = m.getOrInsertFunction(
      "_Z10__any_syncib", FunctionType::get(I1, {I32, I1}, false));
  FunctionCallee fn_uni = m.getOrInsertFunction(
      "_Z14__uniform_syncib", FunctionType::get(I1, {I32, I1}, false));
  FunctionCallee fn_ballot = m.getOrInsertFunction(
      "_Z13__ballot_syncib", FunctionType::get(I32, {I32, I1}, false));

  for (auto *ci : replace) {
    IRBuilder<> builder(ci);
    auto callee_name = ci->getCalledOperand()->getName().str();

    Value *mask = ci->getArgOperand(0); // i32
    Value *pred = ci->getArgOperand(1); // i1

    CallInst *call = nullptr;
    if (callee_name.find(".all.") != string::npos) {
      call = builder.CreateCall(fn_all, {mask, pred});
    } else if (callee_name.find(".any.") != string::npos) {
      call = builder.CreateCall(fn_any, {mask, pred});
    } else if (callee_name.find(".uni.") != string::npos) {
      call = builder.CreateCall(fn_uni, {mask, pred});
    } else if (callee_name.find(".ballot.") != string::npos) {
      call = builder.CreateCall(fn_ballot, {mask, pred});
    } else {
      //dbgs() << "Unknown vote variant: " << callee_name << "\n";
      continue;
    }

    // Vote intrinsics (any/all/uni/ballot) are warp-synchronizing — need
    // convergent so LoopUnswitch/LICM don't hoist code containing them
    // across non-uniform branches. (Same root cause as the shfl convergent
    // fix in replaceWarpShfl1to1.)
    call->addFnAttr(Attribute::Convergent);
    if (auto *fn = dyn_cast<Function>(call->getCalledFunction()))
      fn->addFnAttr(Attribute::Convergent);
    ci->replaceAllUsesWith(call);
    ci->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpVoteX86(
    Module &m, const set<CallInst *> &replace) {}

bool ReplaceWarpLevelPrimitive::replaceWarpShfl(Module &m, bool excludeIdx) {

  DenseSet<StringRef> shflFuncs;

  shflFuncs = {"llvm.nvvm.shfl.sync.down.i32",
                "llvm.nvvm.shfl.sync.up.i32",
                "llvm.nvvm.shfl.sync.bfly.i32",
                "llvm.nvvm.shfl.sync.down.f32",
                "llvm.nvvm.shfl.sync.up.f32",
                "llvm.nvvm.shfl.sync.bfly.f32"};
  if (!excludeIdx) {
    shflFuncs.insert("llvm.nvvm.shfl.sync.idx.i32");
    shflFuncs.insert("llvm.nvvm.shfl.sync.idx.f32");
  }

  // Also match C++ mangled __shfl*_sync functions for FLAT mode.
  // These appear when CUDA code uses __shfl_sync() directly.
  // The C++ wrappers have same arg layout as NVVM: (mask, val, offset, width).
  auto isShflCall = [&](const string &name) -> bool {
    if (shflFuncs.count(name))
      return true;
    if (name.find("__shfl_down_sync") != string::npos ||
        name.find("__shfl_up_sync") != string::npos ||
        name.find("__shfl_xor_sync") != string::npos)
      return true;
    // Plain __shfl_sync (idx mode) — only match if not excluding idx
    if (!excludeIdx && name.find("__shfl_sync") != string::npos)
      return true;
    return false;
  };

  // get the callee functions to be replaced
  set<CallInst *> replace;
  const bool coreStaged = (mapping_ == MAPPING_CORE && getVirtGeom().subpasses > 1);
  if (mapping_ == MAPPING_FLAT || coreStaged) {
    // FLAT mode: replace C++ wrapper CALLS in the kernel body directly.
    // Replacing NVVM intrinsics inside wrapper bodies doesn't work because
    // the wrapper function is not wrapped by the warp loop — only kernel
    // functions are. So warp_shfl store→load would execute in the same
    // thread iteration without synchronization.
    // By replacing the wrapper call in the kernel, the warp_shfl code
    // ends up inside the kernel body → properly wrapped by warp loop.
    for (auto &f : m.functions()) {
      if (f.isDeclaration())
        continue;
      // Only replace in kernel functions — helper functions like
      // parallel_prefix_sum have their shfl calls inlined into kernels
      // by inline_shfl_helpers. Replacing in non-kernel functions causes
      // domination errors because they aren't wrapped by warp loops.
      if (!isKernelFunction(&m, const_cast<Function*>(&f)))
        continue;
      for (auto &bb : f) {
        for (auto &i : bb) {
          auto ci = dyn_cast<CallInst>(&i);
          if (!ci || ci->isInlineAsm())
            continue;
          auto *calledFunc = ci->getCalledFunction();
          if (!calledFunc)
            continue;
          auto name = calledFunc->getName().str();
          // Match both C++ wrapper calls and NVVM intrinsics.
          // On sm_90, clang inlines C++ wrappers leaving only NVVM intrinsics.
          if (isShflCall(name)) {
            fprintf(stderr, "[FLAT] matched shfl: %s (excludeIdx=%d)\n",
                    name.c_str(), excludeIdx);
            replace.insert(ci);
          }
        }
      }
    }
  } else {
    // 1TO1/other modes: replace NVVM intrinsics inside wrapper bodies.
    // The wrapper itself is called from kernel, and the hardware shfl
    // call inside the wrapper executes correctly with real hardware warps.
    for (auto &f : m.functions()) {
      for (auto &bb : f) {
        for (auto &i : bb) {
          auto ci = dyn_cast<CallInst>(&i);
          if (!ci || ci->isInlineAsm())
            continue;
          auto calledOp = ci->getCalledOperand();
          if (!calledOp || !calledOp->hasName())
            continue;
          if (shflFuncs.count(calledOp->getName().str()))
            replace.insert(ci);
        }
      }
    }
  }
  // handle different mappings
  switch (mapping_) {
  case MAPPING_CORE: // virt: hardware lanes; with sub-passes (L < 32) staged + glue
    if (coreStaged) {
      replaceWarpShflStaged(m, replace);
      bool changed = true;
      while (changed) { // drop the now-unused C++ wrappers (their NVVM bodies would reach the backend)
        changed = false;
        SmallVector<Function *, 8> toRemove;
        for (auto &f : m.functions())
          if (f.use_empty() && !isKernelFunction(&m, &f) && isShflCall(f.getName().str())) toRemove.push_back(&f);
        for (auto *f : toRemove) { f->eraseFromParent(); changed = true; }
      }
    } else
      replaceWarpShfl1to1(m, replace);
    break;
  case MAPPING_FLAT:
    replaceWarpShflFlat(m, replace);
    // Remove now-unused wrapper functions and NVVM intrinsic declarations
    // to prevent RISC-V backend crashes on unknown NVVM ops.
    {
      bool changed = true;
      while (changed) {
        changed = false;
        SmallVector<Function *, 8> toRemove;
        for (auto &f : m.functions()) {
          if (f.use_empty() && isShflCall(f.getName().str()))
            toRemove.push_back(&f);
        }
        for (auto *f : toRemove) {
          f->eraseFromParent();
          changed = true;
        }
      }
    }
    break;
  case MAPPING_1TO1:
    replaceWarpShfl1to1(m, replace);
    break;
  case MAPPING_X86:
    replaceWarpShflX86(m, replace);
    break;
  }

  return !replace.empty();
}

void ReplaceWarpLevelPrimitive::replaceWarpShflFlat(
    Module &m, const set<CallInst *> &replace) {
  // type
  Type *Int1T = Type::getInt1Ty(m.getContext());
  Type *I32 = Type::getInt32Ty(m.getContext());
  Type *I8 = Type::getInt8Ty(m.getContext());
  // constant
  auto C0 = ConstantInt::get(I32, 0, true);
  auto C1 = ConstantInt::get(I32, 1, true);
  GlobalVariable *warp_shfl_ptr = m.getNamedGlobal("warp_shfl");
  fprintf(stderr, "[FLAT] replaceWarpShflFlat called, %zu to replace, warp_shfl_ptr=%p\n",
          replace.size(), (void*)warp_shfl_ptr);
  for (auto shfl_inst : replace) {
    fprintf(stderr, "[FLAT] processing shfl in %s\n",
            shfl_inst->getParent()->getParent()->getName().str().c_str());
    /*
     * %10 = tail call i32 @llvm.nvvm.shfl.sync.down.i32(i32 -1, i32 %add32,
     * i32 16, i32 31)
     * ->
     * warp_shfl[warp_id] = add32
     * warp.barrier()
     * %10 = warp_shfl[warp_id + offset]
     */
    IRBuilder<> builder(shfl_inst);

    auto shfl_variable = shfl_inst->getArgOperand(1);
    auto shfl_offset = shfl_inst->getArgOperand(2);
    bool isFloat = shfl_variable->getType()->isFloatTy();
    auto shfl_name = shfl_inst->getCalledOperand()->getName().str();

    // idx mode: __shfl_sync(mask,val,lane) — simple broadcast/read.
    // Don't add barrier splits (too many warp loops for cc-cuda).
    bool isIdxMode = (shfl_name.find("idx") != shfl_name.npos ||
                      (shfl_name.find("__shfl_sync") != shfl_name.npos &&
                       shfl_name.find("down") == shfl_name.npos &&
                       shfl_name.find("up") == shfl_name.npos &&
                       shfl_name.find("xor") == shfl_name.npos));

    // Always use allocas for shfl_offset — split_block_by_sync splits at
    // barrier0 later, which can separate operand definition from use.
    // The allocas are named "shfl_*" so insert_warp_loop skips them
    // during context save (they're shfl emulation temporaries, not user data).
    Function *F = shfl_inst->getParent()->getParent();
    IRBuilder<> entryBuilder(&F->getEntryBlock(), F->getEntryBlock().getFirstInsertionPt());
    auto *offset_alloca = entryBuilder.CreateAlloca(I32, nullptr, "shfl_off");
    auto *result_alloca = entryBuilder.CreateAlloca(
        isFloat ? builder.getFloatTy() : I32, nullptr, "shfl_res");

    // Store offset before barrier
    builder.CreateStore(shfl_offset, offset_alloca);

    // Split BEFORE the store: separates this shfl's store from the
    // PREVIOUS shfl's read+combine. Skip for idx mode (no combine).
    if (!isIdxMode) {
      auto *insertBB = builder.GetInsertBlock();
      auto *insertPt = &*builder.GetInsertPoint();
      if (insertPt != &*insertBB->begin()) {
        auto *newBB = insertBB->splitBasicBlock(
            insertPt, insertBB->getName().str() + "_shfl_store");
        builder.SetInsertPoint(&*newBB->begin());
      }
    }

    auto intra_warp_index =
        createLoad(builder, m.getGlobalVariable("intra_warp_index"));
    auto inter_warp_index =
        createLoad(builder, m.getGlobalVariable("inter_warp_index"));
    // Index by inter*32 + intra to isolate warps in warp_shfl[1024]
    auto store_idx = builder.CreateAdd(intra_warp_index,
        builder.CreateMul(inter_warp_index, ConstantInt::get(I32, 32)),
        "shfl_store_idx");
    Value *val_to_store = shfl_variable;
    if (isFloat)
        val_to_store = builder.CreateBitCast(val_to_store, I32);
    auto store_gep = builder.CreateGEP(warp_shfl_ptr->getValueType(),
                                        warp_shfl_ptr, {C0, store_idx});
    auto *store_inst = builder.CreateStore(val_to_store, store_gep);
    cast<StoreInst>(store_inst)->setVolatile(true);

    // shfl_barrier separates the store from the read.
    // For idx mode, skip barrier/split — idx is a simple read from
    // a fixed lane, no synchronization needed between store and read.
    if (!isIdxMode) {
      CallInst *shfl_call;
      {
        auto FT = FunctionType::get(Type::getVoidTy(m.getContext()), {}, false);
        auto callee = m.getOrInsertFunction("cupbop.shfl.barrier", FT);
        shfl_call = builder.CreateCall(callee);
      }
      // Split block: store → | shfl_barrier → read
      auto *storeBlock = shfl_call->getParent();
      auto *barrierBlock = storeBlock->splitBasicBlock(
          shfl_call, storeBlock->getName().str() + "_shfl_barrier");
      // Split again: shfl_barrier → | read
      auto *nextAfterBarrier = shfl_call->getNextNode();
      if (nextAfterBarrier && !nextAfterBarrier->isTerminator()) {
        barrierBlock->splitBasicBlock(
            nextAfterBarrier, storeBlock->getName().str() + "_shfl_read");
      }
      // Reset builder to the read block
      builder.SetInsertPoint(nextAfterBarrier);
    }

    // After barrier: load offset from alloca (survives BB split)
    auto safe_offset = builder.CreateLoad(I32, offset_alloca, "shfl_off_ld");
    auto new_intra_warp_index =
        createLoad(builder, m.getGlobalVariable("intra_warp_index"));
    auto new_inter_warp_index =
        createLoad(builder, m.getGlobalVariable("inter_warp_index"));

    // Compute lane-level index within warp (0..31)
    Value *lane_index;
    if (shfl_name.find("down") != shfl_name.npos) {
      auto calc = builder.CreateAdd(new_intra_warp_index, safe_offset);
      lane_index = builder.CreateSRem(calc, ConstantInt::get(I32, 32));
    } else if (shfl_name.find("up") != shfl_name.npos) {
      auto calc = builder.CreateSub(new_intra_warp_index, safe_offset);
      lane_index = builder.CreateSRem(calc, ConstantInt::get(I32, 32));
    } else if (shfl_name.find("bfly") != shfl_name.npos ||
               shfl_name.find("xor") != shfl_name.npos) {
      auto calc = builder.CreateXor(new_intra_warp_index, safe_offset);
      lane_index = builder.CreateSRem(calc, ConstantInt::get(I32, 32));
    } else {
      lane_index = builder.CreateSRem(safe_offset, ConstantInt::get(I32, 32));
    }
    // Add inter_warp offset: warp_shfl[inter*32 + lane]
    auto load_index = builder.CreateAdd(lane_index,
        builder.CreateMul(new_inter_warp_index, ConstantInt::get(I32, 32)),
        "shfl_load_idx");

    auto gep = builder.CreateGEP(warp_shfl_ptr->getValueType(), warp_shfl_ptr,
                                  {C0, load_index});
    auto *load_raw = builder.CreateLoad(I32, gep);
    cast<LoadInst>(load_raw)->setVolatile(true);
    Value *load_inst = load_raw;
    if (isFloat)
      load_inst = builder.CreateBitCast(load_inst, builder.getFloatTy());

    // Store result to alloca, replace uses with per-user loads
    builder.CreateStore(load_inst, result_alloca);
    // Second shfl_barrier
    {
      auto FT = FunctionType::get(Type::getVoidTy(m.getContext()), {}, false);
      auto callee = m.getOrInsertFunction("cupbop.shfl.barrier", FT);
      builder.CreateCall(callee);
    }
    std::vector<Instruction *> users;
    for (auto &U : shfl_inst->uses())
      if (auto *I = dyn_cast<Instruction>(U.getUser()))
        users.push_back(I);
    for (auto *user : users) {
      IRBuilder<> userBuilder(user);
      auto *res_load = userBuilder.CreateLoad(
          isFloat ? builder.getFloatTy() : I32, result_alloca, "shfl_res_ld");
      user->replaceUsesOfWith(shfl_inst, res_load);
    }
    shfl_inst->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpShfl1to1(
    Module &m, const set<CallInst *> &replace) {
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx);
  Type *F32 = Type::getFloatTy(ctx);

  for (auto *ci : replace) {
    IRBuilder<> builder(ci);
    auto name = ci->getCalledOperand()->getName().str();

    // NVVM shfl signature: (mask, val, delta/srcLane, clamp)
    Value *mask = ci->getArgOperand(0);
    Value *val = ci->getArgOperand(1);
    Value *arg2 = ci->getArgOperand(2);
    Value *cparam = ci->getArgOperand(3);

    if (mask->getType() != I32) mask = builder.CreateIntCast(mask, I32, false);
    if (arg2->getType() != I32) arg2 = builder.CreateIntCast(arg2, I32, false);
    if (cparam->getType() != I32) cparam = builder.CreateIntCast(cparam, I32, false);

    bool isFloat = (ci->getType() == F32);

    FunctionCallee callee;
    std::vector<Value*> args;

    if (name.find(".down.") != string::npos) {
      if (isFloat) {
        FunctionType *FT = FunctionType::get(F32, {I32, F32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z16__shfl_down_syncifii", FT);
      } else {
        FunctionType *FT = FunctionType::get(I32, {I32, I32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z16__shfl_down_synciiii", FT);
        if (val->getType() != I32) val = builder.CreateIntCast(val, I32, false);
      }
      args = {mask, val, arg2, cparam};
    } else if (name.find(".up.") != string::npos) {
      if (isFloat) {
        FunctionType *FT = FunctionType::get(F32, {I32, F32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z14__shfl_up_syncifii", FT);
      } else {
        FunctionType *FT = FunctionType::get(I32, {I32, I32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z14__shfl_up_synciiii", FT);
        if (val->getType() != I32) val = builder.CreateIntCast(val, I32, false);
      }
      args = {mask, val, arg2, cparam};
    } else if (name.find(".bfly.") != string::npos) {
      if (isFloat) {
        FunctionType *FT = FunctionType::get(F32, {I32, F32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z15__shfl_xor_syncifii", FT);
      } else {
        FunctionType *FT = FunctionType::get(I32, {I32, I32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z15__shfl_xor_synciiii", FT);
        if (val->getType() != I32) val = builder.CreateIntCast(val, I32, false);
      }
      args = {mask, val, arg2, cparam};
    } else if (name.find(".idx.") != string::npos) {
      if (isFloat) {
        FunctionType *FT = FunctionType::get(F32, {I32, F32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z11__shfl_syncifii", FT);
      } else {
        FunctionType *FT = FunctionType::get(I32, {I32, I32, I32, I32}, false);
        callee = m.getOrInsertFunction("_Z11__shfl_synciiii", FT);
        if (val->getType() != I32) val = builder.CreateIntCast(val, I32, false);
      }
      args = {mask, val, arg2, cparam};
    } else {
      // Unknown variant, skip
      continue;
    }

    CallInst *newCall = builder.CreateCall(callee, args);
    // The original NVPTX shfl intrinsic call carries `convergent`; without
    // re-applying it on the replacement, clang's LoopUnswitch hoists any
    // surrounding `if (tid==0)` predicate to the top of the enclosing loop,
    // and VortexBranchDivergence then wraps that predicate in vx_split_n.
    // The result is that only one of {tid==0, tid!=0} is active when shfl
    // runs, so it reads from inactive lanes (returning 0). Symptom in
    // marchingCubes computeMinMaxLv2: per-voxel min reduces to 0, inflating
    // Block Lv2 from ~3520 to ~15280.
    newCall->addFnAttr(Attribute::Convergent);
    if (auto *fn = dyn_cast<Function>(callee.getCallee()))
      fn->addFnAttr(Attribute::Convergent);
    ci->replaceAllUsesWith(newCall);
    ci->eraseFromParent();
  }
}

void ReplaceWarpLevelPrimitive::replaceWarpShflX86(
    Module &m, const set<CallInst *> &replace) {}



// ---------------------------------------------------------------------------
// Core mapping with sub-passes (schedule 1, L < 32 lanes per physical warp).
// A CUDA warp is S = 32/L sub-passes of the intra loop; a warp-level op needs
// all 32 logical lanes. Each sub-pass stores its operands in per-thread stage
// slots, a warp-sync marker ends the region, and uniform glue (all lanes, once
// per logical warp, between the two intra loops) combines the S slots with
// hardware ballots/shuffles into per-sub-pass results read after a second
// marker (…glue_end, a warp sync by name so every pass treats it as one).
// ---------------------------------------------------------------------------

// The sub-pass stores and the glue loads sit in different loops that the warp-loop
// pass tags with llvm.mem.parallel_loop_access; without volatile LLVM may reorder
// them (the flat warp_shfl emulation is volatile for the same reason).
static StoreInst *vstore(IRBuilder<> &b, Value *v, Value *p) { auto *st = b.CreateStore(v, p); st->setVolatile(true); return st; }
static LoadInst *vload(IRBuilder<> &b, Type *t, Value *p, const Twine &n = "") { auto *ld = b.CreateLoad(t, p, n); ld->setVolatile(true); return ld; }

static Value *virtLogicalLane(IRBuilder<> &b, Module &m) {
  return createLoad(b, m.getGlobalVariable("intra_warp_index"));
}
// Stage slots live in the entry block after every existing alloca: insert_sync puts
// the kernel-entry barrier before the first non-alloca instruction, so anything
// placed in front of the original allocas would push them behind that barrier
// (verifier: "Instruction does not dominate all uses").
static Instruction *virtEntryInsertPt(Function *F) {
  for (auto &I : F->getEntryBlock())
    if (!isa<AllocaInst>(&I)) return &I;
  return F->getEntryBlock().getTerminator();
}

void ReplaceWarpLevelPrimitive::replaceWarpVoteStaged(Module &m, const set<CallInst *> &replace_in) {
  const VirtGeom vg = getVirtGeom();
  const int S = vg.subpasses, L = vg.lanes, LG = vg.lg_lanes;
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx), *I1 = Type::getInt1Ty(ctx), *VoidT = Type::getVoidTy(ctx);
  set<CallInst *> replace = replace_in;
  for (auto &f : m.functions())
    for (auto &bb : f)
      for (auto &i : bb)
        if (auto *ci = dyn_cast<CallInst>(&i))
          if (!ci->isInlineAsm() && ci->getCalledFunction() &&
              ci->getCalledFunction()->getName() == "__cupbop_activemask")
            replace.insert(ci);
  if (replace.empty()) return;
  FunctionCallee hwBallot = m.getOrInsertFunction("__cupbop_hw_ballot", FunctionType::get(I32, {I32}, false));
  if (auto *Fn = dyn_cast<Function>(hwBallot.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  FunctionCallee glueEnd = m.getOrInsertFunction("cupbop.virt.syncwarp.glue_end", FunctionType::get(VoidT, {}, false));
  if (auto *Fn = dyn_cast<Function>(glueEnd.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  auto *ArrTy = ArrayType::get(I32, S);
  int n = 0;
  for (auto *ci : replace) {
    Function *F = ci->getFunction();
    std::string name = ci->getCalledOperand()->getName().str();
    if (!isKernelFunction(&m, F)) {
      fprintf(stderr, "[virt-stage] WARNING: %s in non-kernel %s left to the hardware lowering\n", name.c_str(), F->getName().str().c_str());
      set<CallInst *> one; one.insert(ci);
      if (name != "__cupbop_activemask") replaceWarpVote1to1(m, one);
      continue;
    }
    const bool isActive = (name == "__cupbop_activemask");
    Value *mask = isActive ? ConstantInt::get(I32, -1) : ci->getArgOperand(0);
    Value *pred = isActive ? ConstantInt::getTrue(ctx) : ci->getArgOperand(1);
    if (mask->getType() != I32) { IRBuilder<> tb(ci); mask = tb.CreateIntCast(mask, I32, false); }
    IRBuilder<> eb(virtEntryInsertPt(F));
    auto *stage = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_vote_stage");
    auto *res = eb.CreateAlloca(I32, nullptr, "shfl_virt_vote_res");
    for (int j = 0; j < S; j++) vstore(eb, ConstantInt::get(I32, 0), eb.CreateConstInBoundsGEP2_32(ArrTy, stage, 0, j));
    IRBuilder<> b(ci);
    // store phase (this sub-pass): in-mask predicate of the logical lane
    Value *l = virtLogicalLane(b, m);
    Value *j = b.CreateLShr(l, ConstantInt::get(I32, LG), "vsub");
    Value *inm = b.CreateAnd(b.CreateLShr(mask, l), ConstantInt::get(I32, 1));
    Value *v = b.CreateAnd(inm, b.CreateZExt(pred, I32), "vote_v");
    vstore(b, v, b.CreateInBoundsGEP(ArrTy, stage, {ConstantInt::get(I32, 0), j}));
    CreateIntraWarpBarrier(ci)->setMetadata("cupbop.virt_marker", MDNode::get(ctx, {})); // marker: all sub-passes of this logical warp are done
    // glue (uniform, all lanes): OR of the hardware ballots of the S slots, then clean
    Value *bits = ConstantInt::get(I32, 0);
    for (int jj = 0; jj < S; jj++) {
      auto *gep = b.CreateConstInBoundsGEP2_32(ArrTy, stage, 0, jj);
      auto *hb = b.CreateCall(hwBallot, {vload(b, I32, gep)});
      hb->addFnAttr(Attribute::Convergent);
      bits = b.CreateOr(bits, b.CreateShl(hb, ConstantInt::get(I32, L * jj)));
      vstore(b, ConstantInt::get(I32, 0), gep);
    }
    vstore(b, bits, res);
    b.CreateCall(glueEnd)->addFnAttr(Attribute::Convergent);
    // load phase (next region, per sub-pass)
    Value *bm = b.CreateAnd(vload(b, I32, res, "vote_bits"), mask);
    Value *result;
    if (isActive || name.find(".ballot.") != string::npos) result = bm;
    else if (name.find(".any.") != string::npos) result = b.CreateICmpNE(bm, ConstantInt::get(I32, 0));
    else if (name.find(".all.") != string::npos) result = b.CreateICmpEQ(bm, mask);
    else result = b.CreateOr(b.CreateICmpEQ(bm, ConstantInt::get(I32, 0)), b.CreateICmpEQ(bm, mask)); // uni
    if (result->getType() != ci->getType()) {
      if (ci->getType() == I1) result = b.CreateICmpNE(result, Constant::getNullValue(result->getType()));
      else result = b.CreateZExtOrTrunc(result, ci->getType());
    }
    ci->replaceAllUsesWith(result);
    ci->eraseFromParent();
    n++;
  }
  fprintf(stderr, "[virt-stage] %d vote/activemask sites staged over %d sub-passes of %d lanes\n", n, S, L);
}

void ReplaceWarpLevelPrimitive::replaceWarpShflStaged(Module &m, const set<CallInst *> &replace) {
  const VirtGeom vg = getVirtGeom();
  const int S = vg.subpasses, L = vg.lanes, LG = vg.lg_lanes;
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx), *VoidT = Type::getVoidTy(ctx), *F32 = Type::getFloatTy(ctx);
  if (replace.empty()) return;
  FunctionCallee hwShfl = m.getOrInsertFunction("__cupbop_hw_shfl_idx", FunctionType::get(I32, {I32, I32, I32}, false));
  if (auto *Fn = dyn_cast<Function>(hwShfl.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  FunctionCallee srcLane = m.getOrInsertFunction("__cupbop_shfl_srclane", FunctionType::get(I32, {I32, I32, I32, I32}, false));
  FunctionCallee laneId = m.getOrInsertFunction("__cupbop_laneid", FunctionType::get(I32, false));
  FunctionCallee glueEnd = m.getOrInsertFunction("cupbop.virt.syncwarp.glue_end", FunctionType::get(VoidT, {}, false));
  if (auto *Fn = dyn_cast<Function>(glueEnd.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  auto *ArrTy = ArrayType::get(I32, S);
  int n = 0;
  for (auto *ci : replace) {
    Function *F = ci->getFunction();
    std::string name = ci->getCalledOperand()->getName().str();
    if (!isKernelFunction(&m, F)) {
      fprintf(stderr, "[virt-stage] WARNING: %s in non-kernel %s left to the hardware lowering\n", name.c_str(), F->getName().str().c_str());
      set<CallInst *> one; one.insert(ci); replaceWarpShfl1to1(m, one);
      continue;
    }
    const bool isIntrinsic = name.rfind("llvm.nvvm.shfl.sync.", 0) == 0;
    int mode = 0;
    if (name.find("up") != string::npos) mode = 1;
    else if (name.find("down") != string::npos) mode = 2;
    else if (name.find("bfly") != string::npos || name.find("xor") != string::npos) mode = 3;
    Value *var = ci->getArgOperand(1);
    Value *bArg = ci->getArgOperand(2);
    Value *cArg = ci->getArgOperand(3);
    Type *VT = var->getType();
    const bool isFloat = VT->isFloatTy();
    IRBuilder<> b(ci);
    if (!isIntrinsic) { // C++ wrapper: 4th arg is width -> PTX c = (32-width)<<8 | (up ? 0 : 31)
      Value *w = b.CreateIntCast(cArg, I32, false);
      Value *seg = b.CreateShl(b.CreateSub(ConstantInt::get(I32, 32), w), ConstantInt::get(I32, 8));
      cArg = b.CreateOr(seg, ConstantInt::get(I32, mode == 1 ? 0 : 31));
    }
    bArg = b.CreateIntCast(bArg, I32, true);
    Value *varBits = isFloat ? b.CreateBitCast(var, I32) : b.CreateIntCast(var, I32, true);
    IRBuilder<> eb(virtEntryInsertPt(F));
    auto *stV = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_val");
    auto *stB = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_b");
    auto *stC = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_c");
    auto *stR = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_res");
    // store phase (this sub-pass)
    Value *l = virtLogicalLane(b, m);
    Value *j = b.CreateLShr(l, ConstantInt::get(I32, LG), "ssub");
    Value *zero = ConstantInt::get(I32, 0);
    vstore(b, varBits, b.CreateInBoundsGEP(ArrTy, stV, {zero, j}));
    vstore(b, bArg, b.CreateInBoundsGEP(ArrTy, stB, {zero, j}));
    vstore(b, cArg, b.CreateInBoundsGEP(ArrTy, stC, {zero, j}));
    CreateIntraWarpBarrier(ci)->setMetadata("cupbop.virt_marker", MDNode::get(ctx, {}));
    // glue: for every reader sub-pass jr, source logical lane s -> hardware shuffle of slot s>>LG from lane s&(L-1)
    Value *hl = b.CreateAnd(b.CreateCall(laneId, {}, "hwlane"), ConstantInt::get(I32, L - 1));
    for (int jr = 0; jr < S; jr++) {
      Value *lr = b.CreateAdd(hl, ConstantInt::get(I32, L * jr));
      Value *bj = vload(b, I32, b.CreateConstInBoundsGEP2_32(ArrTy, stB, 0, jr));
      Value *cj = vload(b, I32, b.CreateConstInBoundsGEP2_32(ArrTy, stC, 0, jr));
      Value *s = b.CreateCall(srcLane, {ConstantInt::get(I32, mode), lr, bj, cj}, "srclane");
      Value *js = b.CreateLShr(s, ConstantInt::get(I32, LG));
      Value *hs = b.CreateAnd(s, ConstantInt::get(I32, L - 1));
      Value *val = zero;
      for (int jj = 0; jj < S; jj++) {
        auto *x = b.CreateCall(hwShfl, {vload(b, I32, b.CreateConstInBoundsGEP2_32(ArrTy, stV, 0, jj)), hs, ConstantInt::get(I32, L - 1)});
        x->addFnAttr(Attribute::Convergent);
        val = b.CreateSelect(b.CreateICmpEQ(js, ConstantInt::get(I32, jj)), x, val);
      }
      vstore(b, val, b.CreateConstInBoundsGEP2_32(ArrTy, stR, 0, jr));
    }
    b.CreateCall(glueEnd)->addFnAttr(Attribute::Convergent);
    // load phase (next region): this sub-pass's result
    Value *l2 = virtLogicalLane(b, m);
    Value *j2 = b.CreateLShr(l2, ConstantInt::get(I32, LG));
    Value *r = vload(b, I32, b.CreateInBoundsGEP(ArrTy, stR, {zero, j2}), "shfl_r");
    Value *result = isFloat ? b.CreateBitCast(r, F32) : b.CreateIntCast(r, VT, true);
    ci->replaceAllUsesWith(result);
    ci->eraseFromParent();
    n++;
  }
  fprintf(stderr, "[virt-stage] %d shfl sites staged over %d sub-passes of %d lanes\n", n, S, L);
}

// virt sub-pass form: mma.sync (llvm.nvvm.mma.*, cupbop.mma.*) staged over the S=2 passes and executed once per CUDA warp
// by the glue in the device runtime, which owns the PTX fragment layouts: __cupbop_mma_m16n8k16_{f16f32,bf16f32,f16f16}_glue16
// on the NT=16 TCU tile (half shapes with the missing registers zero), <helper>_sw_glue16 in software for every form
// (cudaKernelImpl_dtypes.inc). Store phase: this pass's A, B, C registers into the thread's slots [pass][word]; marker; glue
// (uniform); glue_end; load phase: D. A stride 4 words, B 2, C/D nC registers (a double is two words).
static void replaceMmaStaged(Module &m) {
  const VirtGeom vg = getVirtGeom();
  if (std::getenv("CUPBOP_VIRT_NO_MMA_STAGE")) { fprintf(stderr, "[virt-stage] mma/movmatrix staging disabled (bisection)\n"); return; }
  std::vector<CallInst *> sites;
  for (auto &f : m) {
    if (!isKernelFunction(&m, &f)) continue;
    for (auto &bb : f)
      for (auto &i : bb)
        if (auto *ci = dyn_cast<CallInst>(&i))
          if (Function *cf = ci->getCalledFunction())
            if (cf->getName().starts_with("llvm.nvvm.mma.") || cf->getName().starts_with("cupbop.mma.")) sites.push_back(ci);
  }
  if (sites.empty()) return;
  if (vg.lanes != 16) {
    fprintf(stderr, "error: virt sub-pass form stages mma.sync for 16 lanes only (lanes=%d)\n", vg.lanes);
    exit(1);
  }
  const char *lowEnv = std::getenv("CUPBOP_MMA_LOWERING");
  const std::string lowering = lowEnv && *lowEnv ? lowEnv : "auto";
  // auto: the TCU glue where one exists and the bitstream has the TCU (unknown configuration: as before, TCU)
  const bool mayTcu = lowering == "tcu" || (lowering != "sw" && (bitstreamThreads() == 0 || bitstreamHasTcu()));
  std::vector<MmaSubpassForm> forms(sites.size());
  int nTcu = 0, nSw = 0, maxC = 0;
  for (size_t k = 0; k < sites.size(); k++) {
    const std::string Name = sites[k]->getCalledFunction()->getName().str();
    std::string err;
    if (!mma_subpass_form(Name, sites[k]->arg_size(), forms[k], err)) {
      fprintf(stderr, "error: virt sub-pass form: unsupported mma.sync %s: %s\n", Name.c_str(), err.c_str());
      exit(1);
    }
    if (forms[k].tcu.empty() && lowering == "tcu") {
      fprintf(stderr, "error: virt sub-pass form: %s has no NT=16 TCU glue (CUPBOP_MMA_LOWERING=tcu); use auto or sw\n", Name.c_str());
      exit(1);
    }
    if (mayTcu && !forms[k].tcu.empty()) nTcu++; else nSw++;
    maxC = std::max(maxC, forms[k].f64 ? 2 * forms[k].nC : forms[k].nC);
  }
  if (nTcu) requireGlue16Bitstream("mma.sync", nTcu);
  if (nSw) requireGlue16Bitstream("mma.sync (software glue)", nSw, false);
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx), *I64 = Type::getInt64Ty(ctx), *F32 = Type::getFloatTy(ctx), *F64 = Type::getDoubleTy(ctx), *VoidT = Type::getVoidTy(ctx);
  Type *PtrTy = PointerType::getUnqual(ctx);
  FunctionCallee glueEnd = m.getOrInsertFunction("cupbop.virt.syncwarp.glue_end", FunctionType::get(VoidT, {}, false));
  if (auto *Fn = dyn_cast<Function>(glueEnd.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  auto *ATy = ArrayType::get(I32, 8); auto *BTy = ArrayType::get(I32, 4); auto *CTy = ArrayType::get(F32, maxC > 4 ? 16 : 8);
  // one set of slots per function: a slot is written and read back within one staged op, and 112 bytes per site filled the
  // frame of the lifted GEMMs (tg2: 33 sites)
  struct Slots { AllocaInst *a = nullptr, *b = nullptr, *c = nullptr, *d = nullptr; };
  std::map<Function *, Slots> slots;
  int n = 0;
  for (size_t k = 0; k < sites.size(); k++) {
    CallInst *ci = sites[k];
    const MmaSubpassForm &fm = forms[k];
    const bool useTcu = mayTcu && !fm.tcu.empty();
    Function *F = ci->getFunction();
    Slots &sl = slots[F];
    if (!sl.a) {
      IRBuilder<> eb(virtEntryInsertPt(F));
      sl.a = eb.CreateAlloca(ATy, nullptr, "shfl_virt_mma_a");
      sl.b = eb.CreateAlloca(BTy, nullptr, "shfl_virt_mma_b");
      sl.c = eb.CreateAlloca(CTy, nullptr, "shfl_virt_mma_c");
      sl.d = eb.CreateAlloca(CTy, nullptr, "shfl_virt_mma_d");
    }
    auto *stA = sl.a, *stB = sl.b, *stC = sl.c, *stD = sl.d;
    IRBuilder<> b(ci);
    Value *l = virtLogicalLane(b, m);
    Value *j = b.CreateLShr(l, ConstantInt::get(I32, 4), "msub");
    auto slot = [&](Value *base, Type *ArrT, int stride, int i) {
      Value *idx = b.CreateAdd(b.CreateMul(j, ConstantInt::get(I32, stride)), ConstantInt::get(I32, i));
      return b.CreateInBoundsGEP(ArrT, base, {ConstantInt::get(I32, 0), idx});
    };
    auto put = [&](Value *v, Value *base, Type *ArrT, int stride, int w) { // one register at word w: 1 word, a double 2
      if (v->getType()->isDoubleTy()) {
        Value *u = b.CreateBitCast(v, I64);
        vstore(b, b.CreateTrunc(u, I32), slot(base, ArrT, stride, w));
        vstore(b, b.CreateTrunc(b.CreateLShr(u, ConstantInt::get(I64, 32)), I32), slot(base, ArrT, stride, w + 1));
        return;
      }
      if (!v->getType()->isIntegerTy(32) && !v->getType()->isFloatTy()) v = b.CreateBitCast(v, I32);
      vstore(b, v, slot(base, ArrT, stride, w));
    };
    const int rw = fm.f64 ? 2 : 1, cs = fm.nC * rw; // words per register, words of C/D per pass
    for (int i = 0; i < fm.nA; i++) put(ci->getArgOperand(i), stA, ATy, 4, i * rw);
    for (int i = 0; i < fm.nB; i++) put(ci->getArgOperand(fm.nA + i), stB, BTy, 2, i * rw);
    for (int i = 0; i < fm.nC; i++) put(ci->getArgOperand(fm.nA + fm.nB + i), stC, CTy, cs, i * rw);
    if (useTcu && fm.pad && !std::getenv("CUPBOP_VIRT_MMA_NO_PAD")) { // half shape on the full tile (the switch: negative control of the tests)
      for (int i = fm.nA; i < 4; i++) vstore(b, ConstantInt::get(I32, 0), slot(stA, ATy, 4, i));
      for (int i = fm.nB; i < 2; i++) vstore(b, ConstantInt::get(I32, 0), slot(stB, BTy, 2, i));
    }
    CreateIntraWarpBarrier(ci)->setMetadata("cupbop.virt_marker", MDNode::get(ctx, {}));
    std::string gname = useTcu ? fm.tcu + "_glue16" : fm.sw + "_sw_glue16";
    FunctionCallee glue = m.getOrInsertFunction(gname, FunctionType::get(VoidT, {PtrTy, PtrTy, PtrTy, PtrTy}, false));
    if (auto *Fn = dyn_cast<Function>(glue.getCallee())) Fn->addFnAttr(Attribute::Convergent);
    b.CreateCall(glue, {stA, stB, stC, stD})->addFnAttr(Attribute::Convergent);
    b.CreateCall(glueEnd)->addFnAttr(Attribute::Convergent);
    auto *ST = cast<StructType>(ci->getType());
    Value *res = UndefValue::get(ST);
    for (int i = 0; i < fm.nC; i++) {
      Type *ET = ST->getElementType(i);
      Value *v;
      if (fm.f64) {
        Value *lo = b.CreateZExt(vload(b, I32, slot(stD, CTy, cs, 2 * i)), I64), *hi = b.CreateZExt(vload(b, I32, slot(stD, CTy, cs, 2 * i + 1)), I64);
        v = b.CreateBitCast(b.CreateOr(lo, b.CreateShl(hi, ConstantInt::get(I64, 32))), F64);
      } else
        v = vload(b, ET->isFloatTy() ? F32 : I32, slot(stD, CTy, cs, i));
      if (v->getType() != ET) v = b.CreateBitCast(v, ET);
      res = b.CreateInsertValue(res, v, i);
    }
    ci->replaceAllUsesWith(res);
    ci->eraseFromParent();
    n++;
  }
  fprintf(stderr, "[virt-stage] %d mma.sync sites staged over 2 sub-passes of 16 lanes (%d TCU glue, %d software glue)\n", n, nTcu, nSw);
}

// virt sub-pass form: CuLifter's `movmatrix.sync.aligned.m8n8.trans.b16` (inline asm, i32 -> i32)
// staged the same way; the transpose itself is done once per CUDA warp by the NT=16 glue.
static void replaceMovmatrixStaged(Module &m) {
  if (std::getenv("CUPBOP_VIRT_NO_MMA_STAGE")) return;
  std::vector<CallInst *> sites;
  for (auto &f : m) {
    if (!isKernelFunction(&m, &f)) continue;
    for (auto &bb : f)
      for (auto &i : bb)
        if (auto *ci = dyn_cast<CallInst>(&i)) {
          if (ci->isInlineAsm()) {
            if (auto *IA = dyn_cast<InlineAsm>(ci->getCalledOperand()))
              if (IA->getAsmString().find("movmatrix.sync.aligned.m8n8.trans.b16") != std::string::npos) sites.push_back(ci);
          } else if (Function *cf = ci->getCalledFunction()) {
            if (cf->getName() == "__cupbop_movmatrix_m8n8_trans_b16") sites.push_back(ci); // already converted by init_block
          }
        }
  }
  if (sites.empty()) return;
  if (getVirtGeom().lanes != 16) { fprintf(stderr, "error: virt sub-pass form stages movmatrix for 16 lanes only\n"); exit(1); }
  requireGlue16Bitstream("movmatrix", (int)sites.size());
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx), *VoidT = Type::getVoidTy(ctx), *PtrTy = PointerType::getUnqual(ctx);
  FunctionCallee glueEnd = m.getOrInsertFunction("cupbop.virt.syncwarp.glue_end", FunctionType::get(VoidT, {}, false));
  if (auto *Fn = dyn_cast<Function>(glueEnd.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  FunctionCallee glue = m.getOrInsertFunction("__cupbop_movmatrix_m8n8_trans_b16_glue16", FunctionType::get(VoidT, {PtrTy, PtrTy}, false));
  if (auto *Fn = dyn_cast<Function>(glue.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  auto *ArrTy = ArrayType::get(I32, 2);
  int n = 0;
  for (auto *ci : sites) {
    Function *F = ci->getFunction();
    IRBuilder<> eb(virtEntryInsertPt(F));
    auto *stIn = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_mm_in");
    auto *stOut = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_mm_out");
    IRBuilder<> b(ci);
    Value *j = b.CreateLShr(virtLogicalLane(b, m), ConstantInt::get(I32, 4), "mmsub");
    Value *v = ci->getArgOperand(0);
    if (!v->getType()->isIntegerTy(32)) v = b.CreateBitCast(v, I32);
    vstore(b, v, b.CreateInBoundsGEP(ArrTy, stIn, {ConstantInt::get(I32, 0), j}));
    CreateIntraWarpBarrier(ci)->setMetadata("cupbop.virt_marker", MDNode::get(ctx, {}));
    b.CreateCall(glue, {stIn, stOut})->addFnAttr(Attribute::Convergent);
    b.CreateCall(glueEnd)->addFnAttr(Attribute::Convergent);
    Value *res = vload(b, I32, b.CreateInBoundsGEP(ArrTy, stOut, {ConstantInt::get(I32, 0), j}), "movmatrix.trans");
    if (res->getType() != ci->getType()) res = b.CreateBitCast(res, ci->getType());
    ci->replaceAllUsesWith(res);
    ci->eraseFromParent();
    n++;
  }
  fprintf(stderr, "[virt-stage] %d movmatrix sites staged over 2 sub-passes of 16 lanes\n", n);
}

// virt sub-pass form: __cupbop_ldmatrix_m8n8_b16 / __cupbop_stmatrix_m8n8_b16 (lower_ldmatrix_asm) staged at 16 lanes. The
// rows' addresses come from logical lanes of both passes, so the shuffles of the 32-lane helper cannot run per pass. Store
// phase: this pass's address (stmatrix: its registers); marker; glue (uniform, __cupbop_*matrix_m8n8_b16_glue16 in
// cudaKernelImpl_dtypes.inc: index shuffles per reader pass, the shared-memory accesses of both passes); glue_end; load
// phase (ldmatrix): this pass's registers, in place of the loads of the helper's buffer. One set of slots per function:
// a slot is written and read back within one staged op.
static void replaceLdStMatrixStaged(Module &m) {
  if (std::getenv("CUPBOP_VIRT_NO_MMA_STAGE")) return;
  std::vector<CallInst *> sites;
  for (auto &f : m) {
    if (!isKernelFunction(&m, &f)) continue;
    for (auto &bb : f)
      for (auto &i : bb)
        if (auto *ci = dyn_cast<CallInst>(&i))
          if (Function *cf = ci->getCalledFunction())
            if (cf->getName() == "__cupbop_ldmatrix_m8n8_b16" || cf->getName() == "__cupbop_stmatrix_m8n8_b16") sites.push_back(ci);
  }
  if (sites.empty()) return;
  const VirtGeom vg = getVirtGeom();
  if (vg.lanes != 16) { fprintf(stderr, "error: virt sub-pass form stages ldmatrix/stmatrix for 16 lanes only (lanes=%d)\n", vg.lanes); exit(1); }
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx), *VoidT = Type::getVoidTy(ctx), *PtrTy = PointerType::getUnqual(ctx);
  FunctionCallee glueEnd = m.getOrInsertFunction("cupbop.virt.syncwarp.glue_end", FunctionType::get(VoidT, {}, false));
  if (auto *Fn = dyn_cast<Function>(glueEnd.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  auto glueOf = [&](const char *name) {
    FunctionCallee g = m.getOrInsertFunction(name, FunctionType::get(VoidT, {PtrTy, I32, I32, PtrTy}, false));
    if (auto *Fn = dyn_cast<Function>(g.getCallee())) Fn->addFnAttr(Attribute::Convergent);
    return g;
  };
  FunctionCallee ldGlue = glueOf("__cupbop_ldmatrix_m8n8_b16_glue16"), stGlue = glueOf("__cupbop_stmatrix_m8n8_b16_glue16");
  auto *ATy = ArrayType::get(I32, 2), *DTy = ArrayType::get(I32, 8);
  std::map<Function *, std::pair<AllocaInst *, AllocaInst *>> slots;
  int nld = 0, nst = 0;
  Value *zero = ConstantInt::get(I32, 0);
  for (auto *ci : sites) {
    Function *F = ci->getFunction();
    const bool isLd = ci->getCalledFunction()->getName() == "__cupbop_ldmatrix_m8n8_b16";
    auto &sl = slots[F];
    if (!sl.first) {
      IRBuilder<> eb(virtEntryInsertPt(F));
      sl.first = eb.CreateAlloca(ATy, nullptr, "shfl_virt_ldsm_a");
      sl.second = eb.CreateAlloca(DTy, nullptr, "shfl_virt_ldsm_d");
    }
    auto *stA = sl.first, *stD = sl.second;
    Value *num = ci->getArgOperand(1), *trans = ci->getArgOperand(2), *buf = ci->getArgOperand(3);
    const int nreg = (int)cast<ConstantInt>(num)->getZExtValue();
    auto *BufA = dyn_cast<AllocaInst>(buf);
    if (!BufA) { fprintf(stderr, "error: virt sub-pass form: ldmatrix/stmatrix buffer is not a local array\n"); exit(1); }
    Type *BufT = BufA->getAllocatedType();
    IRBuilder<> b(ci);
    Value *j = b.CreateLShr(virtLogicalLane(b, m), ConstantInt::get(I32, 4), "lmsub");
    auto dslot = [&](IRBuilder<> &bb, Value *jj, int r) {
      return bb.CreateInBoundsGEP(DTy, stD, {zero, bb.CreateAdd(bb.CreateMul(jj, ConstantInt::get(I32, 4)), ConstantInt::get(I32, r))});
    };
    vstore(b, ci->getArgOperand(0), b.CreateInBoundsGEP(ATy, stA, {zero, j}));
    if (!isLd)
      for (int r = 0; r < nreg; r++)
        vstore(b, b.CreateLoad(I32, b.CreateConstInBoundsGEP2_32(BufT, BufA, 0, r)), dslot(b, j, r));
    CreateIntraWarpBarrier(ci)->setMetadata("cupbop.virt_marker", MDNode::get(ctx, {}));
    Value *gargs[] = {stA, num, trans, stD};
    b.CreateCall(isLd ? ldGlue : stGlue, gargs)->addFnAttr(Attribute::Convergent);
    b.CreateCall(glueEnd)->addFnAttr(Attribute::Convergent);
    if (isLd) {
      // the lowering loads the registers from the buffer right after the call: they become loads of this pass's slots
      Instruction *after = ci->getNextNode();
      IRBuilder<> lb(after);
      Value *j2 = lb.CreateLShr(virtLogicalLane(lb, m), ConstantInt::get(I32, 4), "lmsub2");
      for (int r = 0; r < nreg; r++)
        vstore(lb, vload(lb, I32, dslot(lb, j2, r), "ldsm_r"), lb.CreateConstInBoundsGEP2_32(BufT, BufA, 0, r));
      nld++;
    } else nst++;
    ci->eraseFromParent();
  }
  fprintf(stderr, "[virt-stage] %d ldmatrix / %d stmatrix sites staged over 2 sub-passes of 16 lanes\n", nld, nst);
}

// virt sub-pass form: __cupbop_redux_sync (lower_redux_sync) staged at 16 lanes. Store phase: this pass's value and member
// mask; marker; glue (uniform, __cupbop_redux_sync_glue16: index shuffles of both slots, one result per pass); glue_end; load
// phase. A lane outside the mask has not stored its slots: no mask contains it, and its own result is not used.
static void replaceReduxStaged(Module &m) {
  std::vector<CallInst *> sites;
  for (auto &f : m) {
    if (!isKernelFunction(&m, &f)) continue;
    for (auto &bb : f)
      for (auto &i : bb)
        if (auto *ci = dyn_cast<CallInst>(&i))
          if (Function *cf = ci->getCalledFunction())
            if (cf->getName() == "__cupbop_redux_sync") sites.push_back(ci);
  }
  if (sites.empty()) return;
  requireGlue16Bitstream("redux.sync", (int)sites.size(), false);
  auto &ctx = m.getContext();
  Type *I32 = Type::getInt32Ty(ctx), *VoidT = Type::getVoidTy(ctx), *PtrTy = PointerType::getUnqual(ctx);
  FunctionCallee glueEnd = m.getOrInsertFunction("cupbop.virt.syncwarp.glue_end", FunctionType::get(VoidT, {}, false));
  if (auto *Fn = dyn_cast<Function>(glueEnd.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  FunctionCallee glue = m.getOrInsertFunction("__cupbop_redux_sync_glue16", FunctionType::get(VoidT, {PtrTy, PtrTy, I32, PtrTy}, false));
  if (auto *Fn = dyn_cast<Function>(glue.getCallee())) Fn->addFnAttr(Attribute::Convergent);
  auto *ArrTy = ArrayType::get(I32, 2);
  struct Slots { AllocaInst *v = nullptr, *m = nullptr, *r = nullptr; };
  std::map<Function *, Slots> slots;
  Value *zero = ConstantInt::get(I32, 0);
  for (auto *ci : sites) {
    Function *F = ci->getFunction();
    Slots &sl = slots[F];
    if (!sl.v) {
      IRBuilder<> eb(virtEntryInsertPt(F));
      sl.v = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_redux_v");
      sl.m = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_redux_m");
      sl.r = eb.CreateAlloca(ArrTy, nullptr, "shfl_virt_redux_r");
    }
    IRBuilder<> b(ci);
    Value *j = b.CreateLShr(virtLogicalLane(b, m), ConstantInt::get(I32, 4), "rsub");
    vstore(b, ci->getArgOperand(0), b.CreateInBoundsGEP(ArrTy, sl.v, {zero, j}));
    vstore(b, ci->getArgOperand(1), b.CreateInBoundsGEP(ArrTy, sl.m, {zero, j}));
    CreateIntraWarpBarrier(ci)->setMetadata("cupbop.virt_marker", MDNode::get(ctx, {}));
    b.CreateCall(glue, {sl.v, sl.m, ci->getArgOperand(2), sl.r})->addFnAttr(Attribute::Convergent);
    b.CreateCall(glueEnd)->addFnAttr(Attribute::Convergent);
    Value *j2 = b.CreateLShr(virtLogicalLane(b, m), ConstantInt::get(I32, 4), "rsub2");
    ci->replaceAllUsesWith(vload(b, I32, b.CreateInBoundsGEP(ArrTy, sl.r, {zero, j2}), "redux_r"));
    ci->eraseFromParent();
  }
  fprintf(stderr, "[virt-stage] %zu redux.sync sites staged over 2 sub-passes of 16 lanes\n", sites.size());
}

} // namespace cupbop
