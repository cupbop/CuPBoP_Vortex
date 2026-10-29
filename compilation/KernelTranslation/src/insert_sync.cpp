#include "insert_sync.h"
#include "assert.h"
#include "handle_sync.h"
#include "tool.h"
#include "cg_sync.h"
#include <cstdlib>
#include <map>
#include <set>
#include <vector>
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/LoopPass.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/InitializePasses.h"
#include "llvm/PassInfo.h"
#include "llvm/PassRegistry.h"
#include "llvm/Support/CommandLine.h"
//LLVM 18
//#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <iostream>
#include <queue>

using namespace llvm;


class InsertBuiltInBarrier : public llvm::FunctionPass {

public:
  static char ID;

  InsertBuiltInBarrier() : FunctionPass(ID) {}

  virtual bool runOnFunction(Function &F) {
    if (!isKernelFunction(F.getParent(), &F))
      return 0;
    std::vector<llvm::Instruction *> insert_intra_warp_sync_before;
    std::vector<llvm::Instruction *> insert_inter_warp_sync_before;

    // insert sync after the entry and before the first non-AllocaInst/load/cast
    // instruction The idea is the make as many as possible instructions in the
    // first block, so that we do not need to execute these instructions
    // multiple times (in intra-warp loops).
    BasicBlock *entry = &(*F.begin());
    // for (auto i = entry->begin(); i != entry->end(); i++) {
    //   // LLVM 18 changes

    //   //if (!isa<AllocaInst>(i)) {
    //   if (!isa<AllocaInst>(i) && !isa<LoadInst>(i) && !isa<CastInst>(i)) {
    //     //print the instruction before inserting the barrier
    //     printf("inserting intra warp barrier before instruction: AllocInst\n");
    //     i->print(llvm::errs());
    //     insert_inter_warp_sync_before.push_back(&(*(i)));
    //     break;
    //   }
    // }
    
    // The local-memory prologue memory_hierarchy puts after the allocas -- [dyn_bytes load,
    // total_stride add,] vx_local_alloc(stride), then a GEP + cast per shared array -- is uniform
    // across the CTA (vx_local_alloc only reads VX_CSR_CTA_LMEM_ADDR), so it belongs before the
    // entry barrier. Collect all of it (the call, the side-effect-free instructions computing its
    // argument, and the GEP/cast chains derived from its result) instead of matching one exact
    // call/gep/addrspacecast/store sequence: any other shape (two shared arrays, dynamic shared
    // memory, a kernel whose first instruction is not a store) put the call inside the first
    // warp-loop region, i.e. one real call -- with register save/restore -- per trip.
    std::set<Instruction *> lmem_prologue;
    if (!std::getenv("CUPBOP_OLD_LMEM_PROLOGUE")) {   // =1: the old exact call/gep/addrspacecast/store rule only
        std::vector<Instruction *> work;
        for (Instruction &J : *entry)
            if (auto *C = dyn_cast<CallInst>(&J))
                if (C->getCalledFunction() &&
                    C->getCalledFunction()->getName().contains("vx_local_alloc"))
                    work.push_back(C);
        std::vector<Instruction *> users(work.begin(), work.end());
        while (!work.empty()) {          // argument computation: pure, in the entry block
            Instruction *J = work.back(); work.pop_back();
            if (!lmem_prologue.insert(J).second) continue;
            for (Value *Op : J->operands())
                if (auto *OI = dyn_cast<Instruction>(Op))
                    if (OI->getParent() == entry &&
                        (isa<BinaryOperator>(OI) || isa<CastInst>(OI) ||
                         (isa<LoadInst>(OI) && !cast<LoadInst>(OI)->isVolatile())))
                        work.push_back(OI);
        }
        while (!users.empty()) {         // GEP / cast chains on the allocated pointer
            Instruction *J = users.back(); users.pop_back();
            for (User *U : J->users())
                if (auto *UI = dyn_cast<Instruction>(U))
                    if (UI->getParent() == entry &&
                        (isa<GetElementPtrInst>(UI) || isa<CastInst>(UI)) &&
                        lmem_prologue.insert(UI).second)
                        users.push_back(UI);
        }
    }

    auto iter = entry->begin();
    while (iter != entry->end()) {
        Instruction* I = &*iter;

        if (lmem_prologue.count(I)) {
            ++iter;
            continue;
        }
        // ...and, as the old exact-sequence rule did, a store of a prologue pointer into an alloca
        if (auto *ST = dyn_cast<StoreInst>(I))
            if (auto *VI = dyn_cast<Instruction>(ST->getValueOperand()))
                if (lmem_prologue.count(VI) && isa<AllocaInst>(ST->getPointerOperand()->stripPointerCasts())) {
                    ++iter;
                    continue;
                }

        // 기존 예외: AllocaInst, LoadInst, CastInst
        if (isa<AllocaInst>(I) || isa<LoadInst>(I) || isa<CastInst>(I)) {
            ++iter;
            continue;
        }
        // virt sub-pass staging: the zero-init stores of the per-thread stage slots
        // (shfl_virt_* allocas, and the GEPs into them) belong before the entry
        // barrier; inside the first region loop every sub-pass would re-zero them.
        // getUnderlyingObject (not stripPointerCasts): the slot-j store goes through a
        // [0, j] GEP, which stripPointerCasts only sees through for j == 0 -- with
        // stripPointerCasts the barrier landed before the very first slot-1 store.
        {
            Value *P = nullptr;
            if (auto *GEP = dyn_cast<GetElementPtrInst>(I)) P = GEP->getPointerOperand();
            else if (auto *ST = dyn_cast<StoreInst>(I)) P = ST->getPointerOperand();
            if (P)
                if (auto *A = dyn_cast<AllocaInst>(getUnderlyingObject(P)))
                    if (A->getName().starts_with("shfl_virt_")) { ++iter; continue; }
        }

        // vx_local_alloc + gep + addrspacecast + store 시퀀스 예외
        if (auto call = dyn_cast<CallInst>(I)) {
            Function *callee = call->getCalledFunction();
            if (callee && callee->getName().contains("vx_local_alloc")) {
                // 뒤에 gep, addrspacecast, store 있는지 체크
                auto next1 = std::next(iter);
                auto next2 = std::next(next1);
                auto next3 = std::next(next2);
                if (next1 != entry->end() && next2 != entry->end() && next3 != entry->end() &&
                    isa<GetElementPtrInst>(&*next1) &&
                    isa<AddrSpaceCastInst>(&*next2) &&
                    isa<StoreInst>(&*next3)) {
                    // 네 개 다 barrier 앞 예외로 인정 (store까지 스킵)
                    iter = ++next3; // store까지 skip
                    continue;
                }
            }
        }

        // 위 예외에 걸리지 않으면, 여기에 barrier 삽입
        if (cupbop_debug()) printf("inserting intra warp barrier before instruction:\n");
        I->print(llvm::errs());
        insert_inter_warp_sync_before.push_back(I);
        break;
    }

    for (Function::iterator I = F.begin(); I != F.end(); ++I) {
      BasicBlock::iterator BI = I->begin();

      // insert barrier before return
      for (; BI != I->end(); BI++) {
        llvm::ReturnInst *Ret = llvm::dyn_cast<llvm::ReturnInst>(&(*BI));
        if (Ret) {
          if (cupbop_debug()) printf("inserting intra warp barrier before instruction: ReturnInst\n");
          Ret->print(llvm::errs());
          insert_inter_warp_sync_before.push_back(&(*BI));
        }
      }
    }
    if (insert_intra_warp_sync_before.empty() &&
        insert_inter_warp_sync_before.empty())
      return 0;
    for (auto inst : insert_intra_warp_sync_before) {
      CreateIntraWarpBarrier(inst);
    }
    for (auto inst : insert_inter_warp_sync_before) {
      // Entry/exit markers: warp-loop region boundaries for schedule 0/1 only.
      // Tagged so the virt schedule (1) does not turn them into hardware CTA
      // barriers (a CTA needs no barrier at kernel entry or before return).
      auto *c = CreateInterWarpBarrier(inst);
      auto &mctx = c->getContext();
      c->setMetadata("cupbop.builtin_barrier", llvm::MDNode::get(mctx, llvm::MDString::get(mctx, "entry_exit")));
    }
    return 1;
  }
};

// Core mapping (schedule 1) changed three schedule-independent rules below while the
// sub-pass form was being made to work; they are gated here so FLAT (schedule 0)
// keeps its pre-virt behaviour (jacobi-cuda SCHE_0 regressed otherwise).
static bool virtSchedule() { return getVirtGeom().schedule == 1; }
// A sync call (block barrier, FLAT shfl barrier, warp sync / staged marker)?
static bool isSyncCallInst(llvm::Instruction *I) {
  auto *CI = llvm::dyn_cast_or_null<llvm::CallInst>(I);
  if (!CI || CI->isInlineAsm() || !CI->getCalledFunction()) return false;
  auto n = CI->getCalledFunction()->getName().str();
  return n == "llvm.nvvm.barrier0" || n == "llvm.nvvm.barrier.sync" || n == "cupbop.shfl.barrier" || isWarpSync(n);
}
// Does a sync call immediately precede I (debug intrinsics skipped)?
static bool syncRightBefore(llvm::Instruction *I) {
  for (auto *P = I->getPrevNode(); P; P = P->getPrevNode()) {
    if (llvm::isa<llvm::DbgInfoIntrinsic>(P)) continue;
    return isSyncCallInst(P);
  }
  return false;
}

// Schedule 2 and a CuLifter-lifted kernel (parameters named arg_<cbank offset>, SASS-derived CFG): the
// conditional-if / for / special-case CTA barriers are not inserted. They shape single-entry regions for the warp
// loops of schedules 0/1; schedule 2 has none, and in a lifted kernel every barrier counts as conditional (an early
// `exit` and predicated BARs: nothing post-dominates the entry), so the walk put CTA barriers on paths only some warps
// take -- cuBLAS sdot/ddot reduce_1Block_kernel went from 6 to 332 CTA barriers and deadlocked (2026-10-29).
// CUDA-source kernels keep them: btree's s2 result depends on them (all zeros without, CI 2026-10-29), so this is
// not a general schedule-2 rule. CUPBOP_S2_COND_BARRIERS=1 keeps them for lifted kernels too.
static bool s2_skip_cond_barriers(Function &F) {
  static const int sched = [] { const char *e = std::getenv("VORTEX_SCHEDULE_FLAG"); return e ? std::atoi(e) : 0; }();
  if (sched != 2 || std::getenv("CUPBOP_S2_COND_BARRIERS") || F.arg_empty()) return false;
  for (Argument &A : F.args()) {
    StringRef n = A.getName();
    if (!n.consume_front("arg_") || n.empty() || !isdigit((unsigned char)n[0])) return false;
  }
  return true;
}

class InsertConditionalBarrier : public llvm::FunctionPass {

public:
  static char ID;

  InsertConditionalBarrier() : FunctionPass(ID) {}

  virtual void getAnalysisUsage(llvm::AnalysisUsage &AU) const {
    AU.addRequired<PostDominatorTreeWrapperPass>();
    AU.addPreserved<PostDominatorTreeWrapperPass>();
    AU.addRequired<DominatorTreeWrapperPass>();
    AU.addPreserved<DominatorTreeWrapperPass>();
  }

  BasicBlock *firstNonBackedgePredecessor(llvm::BasicBlock *bb) {

    DominatorTree *DT = &getAnalysis<DominatorTreeWrapperPass>().getDomTree();

    pred_iterator I = pred_begin(bb), E = pred_end(bb);
    if (I == E)
      return NULL;
    while (DT->dominates(bb, *I) && I != E)
      ++I;
    if (I == E)
      return NULL;
    else
      return *I;
  }

  BasicBlock *firstNonBackedgeSuccessor(llvm::BasicBlock *bb) {
    DominatorTree *DT = &getAnalysis<DominatorTreeWrapperPass>().getDomTree();
    auto t = bb->getTerminator();
    assert(t->getNumSuccessors() <= 2);
    for (unsigned i = 0, e = t->getNumSuccessors(); i != e; ++i) {
      BasicBlock *successor = t->getSuccessor(i);
      bool isBackedge = DT->dominates(successor, bb);
      if (isBackedge)
        continue;
      return successor;
    }
  };

  virtual bool runOnFunction(Function &F) {
    if (!isKernelFunction(F.getParent(), &F))
      return 0;
    if (s2_skip_cond_barriers(F))
      return 0;

    auto PDT = &getAnalysis<PostDominatorTreeWrapperPass>();

    const bool virt_subpass = (getVirtGeom().schedule == 1 && getVirtGeom().subpasses > 1);
    // virt sub-pass form: run to a fixpoint (a merge that received a barrier is a
    // conditional barrier of the enclosing if), with idempotent insertion so that
    // the fixpoint terminates. Other schedules: one round, as before.
    int inserted = 0;
    auto alreadySynced = [&](llvm::Instruction *at) {
      if (!virt_subpass) return false;
      if (at == &*at->getParent()->begin()) return isSyncCallInst(at);
      return syncRightBefore(at);
    };
    auto insIntra = [&](llvm::Instruction *at) { if (alreadySynced(at)) return; CreateIntraWarpBarrier(at); inserted++; };
    auto insInter = [&](llvm::Instruction *at) { if (alreadySynced(at)) return; CreateInterWarpBarrier(at); inserted++; };
    bool changed = false;
    for (int round = 0; round < (virt_subpass ? 8 : 1); round++) {
    inserted = 0;
    // first find all conditional barriers
    std::vector<BasicBlock *> conditionalBarriers;
    for (Function::iterator i = F.begin(), e = F.end(); i != e; ++i) {
      BasicBlock *b = &*i;
      // virt sub-pass form: a warp sync (staged warp-op marker, glue_end, native
      // __syncwarp) is a region boundary too, so an `if` that contains only warp
      // syncs needs the same treatment (barrier before the branch, at the merge and
      // at the merge's predecessors). has_barrier() lists block barriers and the
      // FLAT shfl barrier only; without this the merge had two entry barriers, no
      // region was formed there, and the code after the `if` ran once per hardware
      // thread (if-body results visible to all lanes, post-loop stores to sub-pass 0).
      if (!has_barrier(b) && !(virt_subpass && has_warp_barrier(b)))
        continue;

      // Unconditional barrier postdominates the entry node.
      if (PDT->getPostDomTree().dominates(b, &F.getEntryBlock()))
        continue;
      if (cupbop_debug()) printf("insert barrier at the beginning of block(conditional barrier): %s\n", b->getName().str().c_str());
      // print block
      b->print(llvm::errs());
      conditionalBarriers.push_back(b);
    }

    if (conditionalBarriers.size() == 0)
      break;

    while (!conditionalBarriers.empty()) {
      BasicBlock *b = conditionalBarriers.back();
      conditionalBarriers.pop_back();

      // insert barrier in the start of if-condition

      BasicBlock *pos = b;
      BasicBlock *pred = firstNonBackedgePredecessor(b);

      while (PDT->getPostDomTree().dominates(b, pred)) {
        pos = pred;
        // If our BB post dominates the given block, we know it is not the
        // branching block that makes the barrier conditional.
        pred = firstNonBackedgePredecessor(pred);

        if (pred == b)
          break; // Traced across a loop edge, skip this case.
      }

      // print pred and b
      if (cupbop_debug()) printf("pred and b check\n");
      // print block
      if (cupbop_debug()) printf("pred: %s\n", pred->getName().str().c_str());
      pred->print(llvm::errs());
      //printf("b: %s\n", b->getName().str().c_str());
      b->print(llvm::errs());


      // we should create warp/block barrier based on the conditional barrier
      if ((has_warp_barrier(b) && !(virtSchedule() && has_block_barrier(b)))) {
        insIntra(pred->getTerminator());
      } else {
        insInter(pred->getTerminator());
      }
      changed = true;

      // insert barrier in the merge point for then-else branches
      // also insert barrier at the end of conditional branch
      DominatorTree *DT = &getAnalysis<DominatorTreeWrapperPass>().getDomTree();
      std::queue<llvm::BasicBlock *> successor_queue;

      for (int i = 0; i < pred->getTerminator()->getNumSuccessors(); i++) {
        auto ss = pred->getTerminator()->getSuccessor(i);
        if (!DT->dominates(ss, pred))
          successor_queue.push(ss);
      }
      std::set<llvm::BasicBlock *> visited;
      llvm::BasicBlock *merge_point = NULL;
      while (!successor_queue.empty()) {
        auto curr = successor_queue.front();
        successor_queue.pop();
        if (visited.find(curr) != visited.end())
          continue;

        visited.insert(curr);
        if (PDT->getPostDomTree().dominates(curr, pred)) {
          // find the truly merge point
          merge_point = curr;
          if ((has_warp_barrier(b) && !(virtSchedule() && has_block_barrier(b)))) {
            insIntra(&(*curr->begin()));
            for (BasicBlock *Pred : predecessors(curr)) {
              insIntra(&(*Pred->getTerminator()));
            }
          } else {
            insInter(&(*curr->begin()));
            for (BasicBlock *Pred : predecessors(curr)) {
              insInter(&(*Pred->getTerminator()));
            }
          }
          break;
        }
        for (int i = 0; i < curr->getTerminator()->getNumSuccessors(); i++) {
          auto ss = curr->getTerminator()->getSuccessor(i);
          if (!DT->dominates(ss, curr))
            successor_queue.push(ss);
        }
      }
      if (!merge_point) {
        // Loop unroll may create unreachable blocks with no merge point
        continue;
      }
      changed = true;

      // we may create a new conditional barrier after insert
      if (!PDT->getPostDomTree().dominates(pred, &F.getEntryBlock())) {
        // if the block postdominates all its predecessor
        // then it is not a conditional barriers
        bool post_dominate_all = true;
        for (auto I = pred_begin(pred); I != pred_end(pred); I++) {
          if (!PDT->getPostDomTree().dominates(pred, *I)) {
            post_dominate_all = false;
            break;
          }
        }
        if (!post_dominate_all)
        {
          conditionalBarriers.push_back(pred);
          if (cupbop_debug()) printf("insert barrier at the beginning of block(conditional barrier pred): %s\n", pred->getName().str().c_str());
          // print block
          pred->print(llvm::errs());

        }
      }

      // find any block which are not dominated by header
      // but be postdominated by merge point
      std::queue<llvm::BasicBlock *> if_body;
      std::set<llvm::BasicBlock *> visited_block;
      for (int i = 0; i < pred->getTerminator()->getNumSuccessors(); i++) {
        if_body.push(pred->getTerminator()->getSuccessor(i));
      }
      while (!if_body.empty()) {
        auto curr = if_body.front();
        if_body.pop();
        if (visited_block.find(curr) != visited_block.end())
          continue;
        visited_block.insert(curr);
        if (!PDT->getPostDomTree().dominates(merge_point, curr))
          continue;
        if (!DT->dominates(pred, curr) &&
            PDT->getPostDomTree().dominates(merge_point, curr)) {
          // we should insert barrier at the beginning and
          // end of its predecessor
          //printf("insert [255]: %s\n", curr->getName().str().c_str());
          if ((has_warp_barrier(b) && !(virtSchedule() && has_block_barrier(b)))) {
            insIntra(&(*curr->begin()));
            for (BasicBlock *Pred : predecessors(curr)) {
              //printf("insert [262]: %s\n", Pred->getName().str().c_str());
              insIntra(&(*Pred->getTerminator()));
            }
          } else {
            insInter(&(*curr->begin()));
            for (BasicBlock *Pred : predecessors(curr)) {
              //printf("insert [268]: %s\n", Pred->getName().str().c_str());
              insInter(&(*Pred->getTerminator()));
            }
          }
        }
        for (int i = 0; i < curr->getTerminator()->getNumSuccessors(); i++) {
          // avoid backedge
          if (DT->dominates(curr->getTerminator()->getSuccessor(i), pred)) {
            continue;
          }
          if_body.push(curr->getTerminator()->getSuccessor(i));
        }
      }
    }
    if (inserted == 0) break;
    changed = true;
    } // rounds
    return changed;
  }
};

class InsertBarrierForSpecialCase : public llvm::FunctionPass {
public:
  static char ID;

  InsertBarrierForSpecialCase() : FunctionPass(ID) {}

  virtual void getAnalysisUsage(llvm::AnalysisUsage &AU) const {
    AU.addRequired<PostDominatorTreeWrapperPass>();
    AU.addRequired<DominatorTreeWrapperPass>();
  }

  BasicBlock *find_merge_point(BasicBlock *start, PostDominatorTree &PDT) {
    assert(start->getTerminator()->getNumSuccessors() == 2);
    std::set<llvm::BasicBlock *> visit;
    std::queue<llvm::BasicBlock *> pending_blocks;
    for (int i = 0; i < start->getTerminator()->getNumSuccessors(); i++) {
      pending_blocks.push(start->getTerminator()->getSuccessor(i));
    }
    while (!pending_blocks.empty()) {
      BasicBlock *current = pending_blocks.front();
      pending_blocks.pop();

      if (visit.find(current) != visit.end())
        continue;

      visit.insert(current);
      if (PDT.dominates(current, start))
        return current;
      for (int i = 0; i < current->getTerminator()->getNumSuccessors(); i++) {
        auto succ = current->getTerminator()->getSuccessor(i);
        if (visit.find(succ) == visit.end())
          pending_blocks.push(succ);
      }
    }
    // Loop unroll may create unreachable paths with no merge point
    return NULL;
  }
  virtual bool runOnFunction(Function &F) {
    if (!isKernelFunction(F.getParent(), &F))
      return 0;
    if (s2_skip_cond_barriers(F))
      return 0;
    bool changed = false;
    std::set<BasicBlock *> if_head;
    // insert an extra block for the following case
    // 1) there is a merge point for an if-else branch,
    // but this merge point has other income edge

    auto PDT = &getAnalysis<PostDominatorTreeWrapperPass>();
    auto DT = &getAnalysis<DominatorTreeWrapperPass>().getDomTree();

    for (Function::iterator i = F.begin(), e = F.end(); i != e; ++i) {
      BasicBlock *b = &*i;
      if (b->getTerminator()->getNumSuccessors() == 2) {
        auto merge_point = find_merge_point(b, PDT->getPostDomTree());
        if (!merge_point) continue;
        for (BasicBlock *Pred : predecessors(merge_point)) {
          if (!DT->dominates(b, Pred)) {
            // we need to insert an extra block to be the merge point
            // for the if-branch
            if_head.insert(b);
          }
        }
      }
    }

    auto M = F.getParent();
    for (auto head : if_head) {
      assert(head->getTerminator()->getNumSuccessors() == 2);
      BasicBlock *merge_point = find_merge_point(head, PDT->getPostDomTree());
      assert(PDT->getPostDomTree().dominates(merge_point, head));
      if (!find_barrier_in_region(head, merge_point)) {
        //printf("do not need to handle tri-income if: %s\n",
               //merge_point->getName().str().c_str());
        continue;
      }

      BasicBlock *Block = BasicBlock::Create(M->getContext(), "if_end", &F);
      llvm::IRBuilder<> Builder(M->getContext());
      Builder.SetInsertPoint(Block);
      auto br_inst = Builder.CreateBr(merge_point);
      if (!has_barrier(head)) continue;  // skip if O1 removed barrier
      if ((has_warp_barrier(head) && !(virtSchedule() && has_block_barrier(head)))) {
        CreateIntraWarpBarrier(br_inst);
      } else {
        CreateInterWarpBarrier(br_inst);
      }
      // replace usage in if-branch
      std::set<Instruction *> need_replace;
      for (BasicBlock *Pred : predecessors(merge_point)) {
        if (DT->dominates(head, Pred) && Pred != Block) {
          need_replace.insert(Pred->getTerminator());
        }
      }
      for (auto inst : need_replace) {
        inst->replaceUsesOfWith(merge_point, Block);
      }
      changed = 1;
    }
    return changed;
  }
};

class InsertConditionalForBarrier : public llvm::LoopPass {

public:
  static char ID;

  InsertConditionalForBarrier() : LoopPass(ID) {}

  void getAnalysisUsage(AnalysisUsage &AU) const {
    AU.addRequired<DominatorTreeWrapperPass>();
  }

  bool runOnLoop(Loop *L, LPPassManager &LPM) {
    if (s2_skip_cond_barriers(*L->getHeader()->getParent()))
      return 0;
    if (!isKernelFunction(L->getHeader()->getParent()->getParent(),
                          L->getHeader()->getParent()))
      return 0;
    // check whether this loop has barrier
    bool is_conditional_loop = 0;
    bool is_warp = 0;
    // A loop with any CTA barrier (barrier0) needs CTA barriers at its edges; warp
    // syncs alone make it a warp-level loop. The old scan stopped at the first sync
    // it met, so a staged warp op (virt sub-passes) ahead of a __syncthreads turned a
    // CTA-barrier loop into a warp-level one and the inter-warp regions vanished.
    bool has_block_sync = false, has_warp_sync = false;
    int first_sync = -1; // legacy rule (schedule 0): the first sync met decides; 1 = warp-level
    for (Loop::block_iterator i = L->block_begin(), e = L->block_end(); i != e;
         ++i) {
      for (BasicBlock::iterator j = (*i)->begin(), e = (*i)->end(); j != e;
           ++j) {
        if (auto Call = dyn_cast<CallInst>(j)) {
          if (Call->isInlineAsm() || !Call->getCalledFunction())
            continue;
          auto func_name = Call->getCalledFunction()->getName().str();
          if (func_name == "llvm.nvvm.barrier0" || func_name == "llvm.nvvm.barrier.sync") {
            has_block_sync = true;
            if (first_sync < 0) first_sync = 0;
          } else if (isWarpSync(func_name) || func_name == "cupbop.shfl.barrier") {
            has_warp_sync = true;
            if (first_sync < 0) first_sync = 1;
          }
        }
      }
    }
    is_conditional_loop = has_block_sync || has_warp_sync;
    is_warp = virtSchedule() ? (has_warp_sync && !has_block_sync) : (first_sync == 1);
    if (!is_conditional_loop)
      return 0;
    // insert barrier at the beginning of header (for_cond)
    // and the end of pre header, so that we can get a
    // single block connected with latch
    if (!is_warp) {
      auto prehead_block = L->getLoopPreheader();
      CreateInterWarpBarrier(prehead_block->getTerminator());
      auto header_block = L->getHeader();
      CreateInterWarpBarrier(&(*header_block->begin()));
    } else {
      auto prehead_block = L->getLoopPreheader();
      CreateIntraWarpBarrier(prehead_block->getTerminator());
      auto header_block = L->getHeader();
      CreateIntraWarpBarrier(&(*header_block->begin()));
    }

    // as we assume all loops are rotated, we have to insert
    // barrier before the condition jump of the for_cond
    if (auto for_cond = L->getExitingBlock()) {
      assert(for_cond->getTerminator()->getNumSuccessors() == 2 &&
             "has more than 2 successors of the for-cond\n");
      auto conditional_br =
          dyn_cast<llvm::BranchInst>(for_cond->getTerminator());
      assert(conditional_br && conditional_br->isConditional());
      // insert barrier before the condition jump of the loop cond
      if (!is_warp)
        CreateInterWarpBarrier(conditional_br);
      else
        CreateIntraWarpBarrier(conditional_br);
      // insert barrier before the for_body
      auto for_body = for_cond->getTerminator()->getSuccessor(0);
      if (for_body == L->getExitBlock()) {
        for_body = for_cond->getTerminator()->getSuccessor(1);
      }
      // insert at the beginning of for_body
      if (!is_warp)
        CreateInterWarpBarrier(&(*for_body->begin()));
      else
        CreateIntraWarpBarrier(&(*for_body->begin()));
      // insert at the beginning and end in for_inc block
      if (auto for_inc = L->getLoopLatch()) {
        if (!is_warp) {
          CreateInterWarpBarrier(&(*for_inc->begin()));
          CreateInterWarpBarrier(for_inc->getTerminator());
        } else {
          CreateIntraWarpBarrier(&(*for_inc->begin()));
          CreateIntraWarpBarrier(for_inc->getTerminator());
        }
      } else {
        assert(0 && "has continue in a barrier loop\n");
      }
    } else {
      // handle break in for-loop
      //printf("loop has multiply exists\n");
      // this time, we have also insert sync before the for-body
      auto header_block = L->getHeader();
      assert(header_block->getTerminator()->getNumSuccessors() == 2 &&
             "has more than 2 successors of the for-head\n");
      // The header's branch is the loop test (clang's for.cond) only when one
      // successor leaves the loop; then the in-loop successor is the body entry
      // that every continuing thread passes. Lifted (SASS-derived) loops are
      // rotated: the header may end in an ordinary, possibly divergent, if whose
      // both targets stay in the loop (hotspot: `if (computed) ...` right after
      // the header). A barrier at one of those targets would be executed by a
      // subset of the threads only (path-dependent barrier count: hang or
      // desync); the barrier at the header start already synchronizes every
      // iteration.
      BasicBlock *for_body = NULL;
      bool header_exits = !virtSchedule(); // legacy (schedule 0): always place the body barrier
      for (int i = 0; i < header_block->getTerminator()->getNumSuccessors(); i++)
        if (!L->contains(header_block->getTerminator()->getSuccessor(i)))
          header_exits = true;
      for (int i = 0; header_exits &&
                      i < header_block->getTerminator()->getNumSuccessors();
           i++) {
        auto bb = header_block->getTerminator()->getSuccessor(i);
        if (L->contains(bb)) {
          if (is_warp) {
            CreateIntraWarpBarrier(&(*bb->begin()));
          } else {
            CreateInterWarpBarrier(&(*bb->begin()));
          }
        }
      }

      SmallVector<llvm::BasicBlock *, 8> ExitingBlocks;

      L->getExitingBlocks(ExitingBlocks);
      while (!ExitingBlocks.empty()) {
        auto exit_block = ExitingBlocks.back();
        ExitingBlocks.pop_back();
        auto conditional_br =
            dyn_cast<llvm::BranchInst>(exit_block->getTerminator());
        assert(conditional_br && conditional_br->isConditional());
        // insert barrier at the beginning of successor of exit
        if (!is_warp)
          CreateInterWarpBarrier(conditional_br);
        else
          CreateIntraWarpBarrier(conditional_br);
      }
    }

    return 1;
  }
};

char InsertBuiltInBarrier::ID = 0;
char InsertConditionalBarrier::ID = 0;
char InsertConditionalForBarrier::ID = 0;
char InsertBarrierForSpecialCase::ID = 0;

namespace {
static RegisterPass<InsertConditionalBarrier>
    insert_conditional_barrier("insert-conditional-if-barriers",
                               "Insert conditional barriers for if body");
static RegisterPass<InsertConditionalForBarrier>
    insert_conditional_for_barrier("insert-conditional-for-barriers",
                                   "Insert conditional barriers for for loop");
static RegisterPass<InsertBarrierForSpecialCase>
    insert_special_case("insert-special-case-barriers",
                        "Insert barriers for special cases");
static RegisterPass<InsertBuiltInBarrier>
    insert_built_in_barrier("insert-built-in-barriers",
                            "Insert built in barriers");
} // namespace

// Core mapping (virt, schedule 1): a physical warp runs one logical warp at a time
// with all NT lanes in lockstep, so __syncwarp / llvm.nvvm.bar.warp.sync are no-ops.
// They are erased here, before any sync pass, because the lifted (SASS-derived)
// kernels carry one before almost every __syncthreads and branch
// (CuLifter's reconvergence idiom): left in place they (a) make insert_sync treat
// conditional barriers as intra-warp ones, (b) get their own blocks from
// split_block_by_sync, and (c) stop the parallel-region walk in insert_warp_loop
// right in front of every CTA barrier, so lifted hotspot/pathfinder/backprop
// ended up with 0 regions and wrote nothing.
static void erase_warp_syncs_for_virt(llvm::Module *M, bool keep_markers = false) {
  std::vector<llvm::CallInst *> dead;
  for (auto &F : *M)
    for (auto &BB : F)
      for (auto &I : BB)
        if (auto *CI = llvm::dyn_cast<llvm::CallInst>(&I)) {
          if (CI->isInlineAsm() || !CI->getCalledFunction())
            continue;
          if (keep_markers && (CI->getMetadata("cupbop.virt_marker") ||
                               CI->getCalledFunction()->getName().contains("glue_end")))
            continue; // staged warp-op markers stay
          if (isWarpSync(CI->getCalledFunction()->getName().str()))
            dead.push_back(CI);
        }
  for (auto *CI : dead)
    CI->eraseFromParent();
  if (!dead.empty())
    fprintf(stderr, "[insert_sync] schedule 1 (virt): erased %zu warp-level syncs (lanes run in lockstep)\n", dead.size());
}

// Warp loops need every parallel region (the code between two barriers) to have ONE entry barrier.
// insert_warp_loop cannot wrap a region that two different barriers lead into: it used to drop such a
// region silently, so its code ran once per hardware thread instead of once per logical thread.
// The conditional-if/for passes above produce single-entry regions for structured source code; lifted
// (SASS-derived) control flow leaves merge points whose predecessors come from different barriers (the
// cuBLAS ampere_sgemm main loop after FixIrreducible: the loop header and the bottom test both branch
// into the same block; an early `return` path and the code after the last barrier both reaching the shared return
// block). At such a merge M whose predecessors are all reached by every thread (each contains a barrier or
// post-dominates the barriers it is entered from), put a region boundary at the end of every predecessor and
// at the start of M: each incoming path then ends its own region, and the code from M on starts a
// single-entry one; the region left between them holds only branches. The boundaries are entry/exit
// markers (no hardware barrier under the core mapping): they only order logical warps inside a
// physical warp, and the paths that reach them are CTA-uniform, as the barriers on them require.
static bool isCtaBarrierCall(const llvm::Instruction &I) {
  auto *CI = llvm::dyn_cast<llvm::CallInst>(&I);
  if (!CI || CI->isInlineAsm() || !CI->getCalledFunction()) return false;
  auto n = CI->getCalledFunction()->getName();
  return n == "llvm.nvvm.barrier0" || n == "llvm.nvvm.barrier.sync";
}
static bool isTrivialInst(const llvm::Instruction &I) {
  return llvm::isa<llvm::BranchInst>(I) || llvm::isa<llvm::PHINode>(I) || llvm::isa<llvm::DbgInfoIntrinsic>(I) ||
         I.isLifetimeStartOrEnd() || isCtaBarrierCall(I);
}
static void separate_multi_entry_regions(llvm::Module *M) {
  for (llvm::Function &F : *M) {
    if (F.isDeclaration() || !isKernelFunction(M, &F)) continue;
    int added = 0;
    // A predecessor is safe for a boundary when every thread that passes the barriers leading to it also passes
    // it: it contains a barrier itself, or it post-dominates every barrier block (or the entry) it is entered from.
    // (The boundaries below do not change the CFG, so one post-dominator tree serves all iterations.)
    llvm::PostDominatorTree PDT(F);
    std::map<llvm::BasicBlock *, std::set<llvm::BasicBlock *>> in, out;
    std::set<llvm::BasicBlock *> done;
    auto hasBarB = [](llvm::BasicBlock &B) { for (auto &I : B) if (isCtaBarrierCall(I)) return true; return false; };
    // A block entered only from barrier blocks also qualifies: at a merge of differently-entered regions the
    // branch that split the paths chose between different barrier sequences, which CUDA requires to be uniform
    // (the loop exit after a barrier-carrying loop body, e.g. `common.ret.loopexit` in lifted Warp cholesky).
    auto uniformlyReached = [&](llvm::BasicBlock *P) {
      if (hasBarB(*P)) return true;
      bool all_bar_preds = P->hasNPredecessorsOrMore(1);
      for (auto *Q : llvm::predecessors(P)) all_bar_preds &= hasBarB(*Q);
      if (all_bar_preds) return true;
      if (in[P].empty()) return false;
      for (auto *E : in[P]) if (!PDT.dominates(P, E)) return false;
      return true;
    };
    for (int iter = 0; iter < 4096; ++iter) {
      // out[b]: the barriers a path leaving b last crossed (b itself if it has a barrier); in[b]: union over preds
      in.clear(); out.clear();
      auto hasBar = [](llvm::BasicBlock &B) { for (auto &I : B) if (isCtaBarrierCall(I)) return true; return false; };
      bool ch = true;
      while (ch) {
        ch = false;
        for (llvm::BasicBlock &B : F) {
          std::set<llvm::BasicBlock *> i;
          if (&B == &F.getEntryBlock()) i.insert(&B);
          for (auto *P : llvm::predecessors(&B)) i.insert(out[P].begin(), out[P].end());
          std::set<llvm::BasicBlock *> o = hasBar(B) ? std::set<llvm::BasicBlock *>{&B} : i;
          if (i != in[&B] || o != out[&B]) { in[&B] = i; out[&B] = o; ch = true; }
        }
      }
      llvm::BasicBlock *merge = nullptr;
      for (llvm::BasicBlock &B : F) {
        if (in[&B].size() < 2) continue;
        // Only where every predecessor is reached by every thread (see uniformlyReached), so a boundary at
        // its end cannot land in thread-divergent code.
        bool all_pred_bar = true;
        for (auto *P : llvm::predecessors(&B)) all_pred_bar &= uniformlyReached(P);
        if (!all_pred_bar) continue;
        // only where the multi-entry region has real work: B up to its next barrier, or the region code
        // reaching B (preds back to their barriers)
        bool work = false;
        for (auto &I : B) { if (isCtaBarrierCall(I)) break; if (!isTrivialInst(I)) { work = true; break; } }
        std::vector<llvm::BasicBlock *> st(llvm::pred_begin(&B), llvm::pred_end(&B));
        std::set<llvm::BasicBlock *> seen;
        while (!work && !st.empty()) {
          auto *P = st.back(); st.pop_back();
          if (!seen.insert(P).second) continue;
          // only the part of P after its last barrier belongs to this region
          for (auto it = P->rbegin(); it != P->rend(); ++it) {
            if (isCtaBarrierCall(*it)) break;
            if (!isTrivialInst(*it)) { work = true; break; }
          }
          if (!hasBar(*P)) st.insert(st.end(), llvm::pred_begin(P), llvm::pred_end(P));
        }
        if (!work || done.count(&B)) continue;
        // the forward part may itself be a trivial branch block (e.g. `br`) but the paths into it are not
        merge = &B;
        break;
      }
      if (!merge) break;
      done.insert(merge);   // boundaries are placed once per merge; a merge that needs none is not retried
      auto marker = [&](llvm::Instruction *before) {
        auto *c = CreateInterWarpBarrier(before);
        auto &mctx = c->getContext();
        c->setMetadata("cupbop.builtin_barrier", llvm::MDNode::get(mctx, llvm::MDString::get(mctx, "region_split")));
        ++added;
      };
      for (auto *P : llvm::predecessors(merge)) {
        auto *T = P->getTerminator();
        auto *prev = T->getPrevNode();
        while (prev && llvm::isa<llvm::DbgInfoIntrinsic>(prev)) prev = prev->getPrevNode();
        if (!(prev && isCtaBarrierCall(*prev))) marker(T);
      }
      auto *first = &*merge->getFirstNonPHIIt();
      if (!isCtaBarrierCall(*first)) marker(first);
    }
    if (added)
      fprintf(stderr, "[insert_sync] %s: %d region boundaries at merges of differently-entered regions\n",
              F.getName().str().c_str(), added);
  }
}

void insert_sync(llvm::Module *M) {
  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
    schedule = std::stoi(std::string(env));
  }
  if (schedule == 1 && getVirtGeom().subpasses == 1) // sub-pass form keeps them as boundaries
    erase_warp_syncs_for_virt(M);
  else if (schedule == 1 && std::getenv("CUPBOP_VIRT_ERASE_NATIVE_WS")) // experiment: keep only the staged markers
    erase_warp_syncs_for_virt(M, /*keep_markers=*/true);

  auto Registry = PassRegistry::getPassRegistry();

  llvm::legacy::PassManager Passes;

  std::vector<std::string> passes;
  // Entry/exit barriers are warp-loop boundary markers for schedule 0/1.
  // In schedule 2 (1:1 mapping), no warp loops exist, so these become
  // pure overhead — forcing all warps to synchronize on every kernel call.
  if (schedule == 0 || schedule == 1) {
    passes.push_back("insert-built-in-barriers");
  }
  // (lifted kernels at schedule 2 skip these three: s2_skip_cond_barriers)
  passes.push_back("insert-conditional-if-barriers");
  passes.push_back("insert-conditional-for-barriers");
  passes.push_back("insert-special-case-barriers");
  for (auto pass : passes) {
    const PassInfo *PIs = Registry->getPassInfo(StringRef(pass));
    if (PIs) {
      Pass *thispass = PIs->createPass();
      Passes.add(thispass);
    } else {
      assert(0 && "Pass not found\n");
    }
  }
  Passes.run(*M);
  if (schedule == 1)   // core mapping only: with it, score-cuda s0 (warp_shfl, nested loops) left its CI baseline
    if (!std::getenv("CUPBOP_S1_NO_MULTI_ENTRY")) separate_multi_entry_regions(M);
}
