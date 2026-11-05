// lodq.h (2026-11-04, experiments/p4): IDEAS 54. The steady state of the p2c-fold queue at S' = 1 without the queue. See lodq.cpp.
#pragma once
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include <map>
#include <memory>
#include <vector>
struct LoDqSite {
  int k = -1, d = 0, Tn = 0;                    // site, queue depth, first tile the site runs in the loop
  llvm::CallInst *C = nullptr;                  // the loop site's cp.async
  std::map<int, llvm::CallInst *> ev;           // straight-line prologue: queue entry t -> the event's cp.async
  llvm::CallInst *pl = nullptr;                 // prologue loop: the round's cp.async (entry = round - Tn)
};
class LoDq {
public:
  // nullptr: no site qualifies. Lp: the prologue loop or nullptr. Pre: preheader of Lm. needG: entries carry a guard (0 = no copy, 1 = zero fill).
  static std::unique_ptr<LoDq> build(llvm::Function &F, llvm::DominatorTree &DT, llvm::Loop *Lm, llvm::Loop *Lp, llvm::BasicBlock *Pre, const std::vector<LoDqSite> &S, bool needG);
  bool affine(int k);                                  // the site's steady state runs without the queue
  bool noq();                                          // no queue at all (every site, with its prologue). Otherwise the queue serves trips t < d of the affine sites
  void pushEvent(llvm::IRBuilder<> &B, int k, int t, llvm::Value *src, llvm::Value *sz);   // noq: entry t of site k, straight-line prologue
  void pushLoop(llvm::IRBuilder<> &B, int k, llvm::Value *sz);                             // noq: prologue loop, every round: the site's bits
  void loopEnd(llvm::IRBuilder<> &B, llvm::Value *c);                                      // noq: end of prologue round c
  void preheader(llvm::Instruction *PT);                                                   // noq: after the prologue is rewritten
  void header(llvm::IRBuilder<> &B);                   // top of the main loop
  llvm::Value *trip();                                 // this trip's number, i32
  void pushMain(llvm::IRBuilder<> &B, int k, llvm::Value *sz, llvm::Value *g);   // the site: this trip's guard and size
  llvm::Value *addr(llvm::IRBuilder<> &B, int k);      // trip >= d: the source of d trips ago
  llvm::Value *go(llvm::IRBuilder<> &B, int k);        // trip >= d: copy at all (needG)
  llvm::Value *nz(llvm::IRBuilder<> &B, int k);        // trip >= d: copy, not zero fill
  void step(llvm::IRBuilder<> &B, int k);              // behind the copy
  void fixup(llvm::Instruction *At);                   // noq, prologue loop: behind every step
  void finish(llvm::Function &F);                      // scalars to registers
  struct Impl; std::unique_ptr<Impl> I;
  LoDq(); ~LoDq();
};
