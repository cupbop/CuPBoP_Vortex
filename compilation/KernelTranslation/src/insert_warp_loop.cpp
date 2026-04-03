
#include "insert_warp_loop.h"
#include "handle_sync.h"
#include "tool.h"
#include <assert.h>
#include <iostream>
#include <set>

#include "llvm/ADT/Statistic.h"
// LLVM 18
#include "llvm/TargetParser/Triple.h"
// #include "llvm/ADT/Triple.h"
// #include "llvm/Analysis/DivergenceAnalysis.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/LoopPass.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
// LLVM 18
// #include "llvm/IR/Instructions.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/InitializePasses.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/PassInfo.h"
#include "llvm/PassRegistry.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
// LLVM18
// #include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <map>
#include <queue>
#include <set>
#include <sstream>
#include <tuple>
#include <unordered_set>
#include <vector>

#include "cg_sync.h"

using namespace llvm;

#define SW_WARP_SIZE (32)

// Forward declaration — set in insert_warp_loop() before pass runs
extern int need_nested_loop;

// LLVM-19 does not provide divergence analysis for NVPTX backend.
// Thus, we need to implement our own divergence analysis.
class CustomDivergenceAnalysis {
    DominatorTree *DT;
    PostDominatorTree *PDT;
    LoopInfo *LI;

public:
  std::unordered_set<const Value *> DivergentValues;
  std::queue<const Instruction *> Worklist;

  void setAnalyzers(DominatorTree &DomTree, PostDominatorTree &PostDomTree,
                    LoopInfo &LoopInf) {
        DT = &DomTree;
        PDT = &PostDomTree;
        LI = &LoopInf;
    }

  void analyze(Function &F) {

    //printf("analyze divergence\n");
    // Identify divergence sources
    for (Instruction &I : instructions(F)) {
      // print instruction
      // I.print(llvm::errs());
      // llvm::errs() << "\n";

      if (isDivergenceSource(&I)) {
        DivergentValues.insert(&I);
        Worklist.push(&I);
        fprintf(stderr, "[div] source: ");
        I.print(llvm::errs());
        fprintf(stderr, "\n");
      }
    }

    // Propagate divergence
    while (!Worklist.empty()) {
      const Instruction *Inst = Worklist.front();
      Worklist.pop();
      // print current working instruction
      // llvm::errs() << "current working instruction\n";
      // Inst->print(llvm::errs());
      // llvm::errs() << "this \n";
      if (auto storeInst = dyn_cast<StoreInst>(Inst)) {
        const Instruction *storeLocation =
            dyn_cast<Instruction>(storeInst->getOperand(1));
        if (storeLocation && DivergentValues.insert(storeLocation).second) {
          
          // llvm::errs() << "new divergence source 1\n";
          // print storeLocation
          // storeLocation->print(llvm::errs());
          // llvm::errs() << "this \n";

          Worklist.push(storeLocation);
        }
      }
      // if it's a conditional branch
      
      else if (auto cond_branch = dyn_cast<BranchInst>(Inst)) {
        if (cond_branch->isConditional()) {
          // get context and put metadata for inserting vx_split
          // Mark's working on this
          
          /*

          */
          // llvm::errs() << "Processing conditional branch\n";
          assert(DT && "DominatorTree is not initialized!");
          assert(cond_branch && "cond_branch is null!");
          
          Value *Cond = cond_branch->getCondition();
          // tid 와 관련된 variable 로 branch 가 진행
          if (DivergentValues.count(Cond) > 0) {
            // llvm::errs() << "new divergence check 1\n";
            for (auto *SuccBB : successors(cond_branch->getParent())) {
            assert(SuccBB && "Successor basic block is null!");
              // llvm::errs() << "new divergence check 2\n";
              // print successor block
              // SuccBB->print(llvm::errs());
              // cond_branch->getParent()->print(llvm::errs());
              // llvm::errs() << "this \n";
              // llvm::errs() << DT->dominates(cond_branch->getParent(), SuccBB);
              if (DT->dominates(cond_branch->getParent(), SuccBB)) {
                // llvm::errs() << "new divergence check 3\n";
                for (const Instruction &I : *SuccBB) {
                  // llvm::errs() << "new divergence check 4\n";
                  // if (DivergentValues.insert(&I).second) {
                    Worklist.push(&I);
                  //}
                }
              }
            }
          }
        }
          /*
          // Iterate through the successors of the branch instruction
          for (unsigned i = 0; i < cond_branch->getNumSuccessors(); ++i) {
            const BasicBlock *successor = cond_branch->getSuccessor(i);

            llvm::errs() << "Processing successor block:\n";
            successor->print(llvm::errs());

            // Add all instructions in the successor block to the worklist
            for (const Instruction &succInst : *successor) {
              if (dyn_cast<Instruction>(&succInst)) {
              llvm::errs() << "Adding new instruction to worklist from
        successor\n"; succInst.print(llvm::errs()); Worklist.push(&succInst);
              }
            }
          }
          */

        else {
          goto not_st_not_br;
        }
      }
      
       else {
        not_st_not_br:
        for (const Use &U : Inst->uses()) {
          const Instruction *UserInst = dyn_cast<Instruction>(U.getUser());
          if (UserInst && DivergentValues.insert(UserInst).second) {
            // llvm::errs() << "new divergence source 2\n";
          // print storeLocation
          // UserInst->print(llvm::errs());
            Worklist.push(UserInst);
            // llvm::errs() << "this \n";
          }
        }
      }
    }
    fprintf(stderr, "[div] total divergent values: %zu\n", DivergentValues.size());
  }

  bool isDivergent(const Value *V) const {
    return DivergentValues.count(V) > 0;
  }

private:
  bool isDivergenceSource(const Instruction *I) const {
    if (const CallInst *CI = dyn_cast<CallInst>(I)) {
      if (const Function *F = CI->getCalledFunction()) {
        if (F->getName() == "llvm.nvvm.read.ptx.sreg.tid.x" ||
            F->getName() == "llvm.nvvm.read.ptx.sreg.tid.y" ||
            F->getName() == "llvm.nvvm.read.ptx.sreg.tid.z" //||
            // LLVM 18 added for thread mapping (flat collapsing)
            // F->getName() == "llvm.nvvm.read.ptx.sreg.ctaid.x" ||
            // F->getName() == "llvm.nvvm.read.ptx.sreg.ctaid.y" ||
            // F->getName() == "llvm.nvvm.read.ptx.sreg.ctaid.z"
            ) {
          return true;
        }
      }
    }
    // For SCHE_0 nested loop: tool.cpp replaces threadIdx intrinsics with
    // calculations based on local_intra_warp_idx / local_inter_warp_idx.
    // Only needed for nested-loop kernels (warp_shfl); in single-loop mode,
    // the original tid.x intrinsic is sufficient for divergence detection.
    if (need_nested_loop) {
      if (const LoadInst *LI = dyn_cast<LoadInst>(I)) {
        auto *ptr = LI->getPointerOperand();
        if (auto *GV = dyn_cast<GlobalVariable>(ptr)) {
          if (GV->getName() == "intra_warp_index" ||
              GV->getName() == "sche_0_thread_idx_TLS")
            return true;
        }
        if (auto *AI = dyn_cast<AllocaInst>(ptr)) {
          if (AI->getName() == "local_intra_warp_idx")
            return true;
        }
      }
    }
    return false;
  }
};

struct ParallelRegion {
  std::set<llvm::BasicBlock *> wrapped_block;
  llvm::BasicBlock *successor_block;
  llvm::BasicBlock *start_block;
  llvm::BasicBlock *end_block;
  bool inst_in_region(llvm::Instruction *inst) {
    for (auto bb : wrapped_block) {
      if (inst->getParent()->getName().str() == bb->getName().str())
        return true;
    }
    return false;
  }
};

std::map<llvm::Instruction *, unsigned> tempInstructionIds;
std::map<std::string, llvm::Instruction *> contextArrays;
int tempInstructionIndex = 0;
int need_nested_loop;

// adding multiple kenerl in file support

bool ShouldNotBeContextSaved(llvm::Instruction *instr,
                             CustomDivergenceAnalysis &DI) {
  if (isa<BranchInst>(instr))
    return true;
  // if (isa<AddrSpaceCastInst>(instr))
  //   return true;
  // if (isa<CastInst>(instr))
  //   return true;

  llvm::Module *M = instr->getParent()->getParent()->getParent();
  llvm::LoadInst *load = dyn_cast<llvm::LoadInst>(instr);
  if (load != NULL) {
    auto load_addr = load->getPointerOperand();
    if (load_addr == M->getGlobalVariable("intra_warp_index"))
      return true;
    if (load_addr == M->getGlobalVariable("inter_warp_index"))
      return true;
    if (load_addr == M->getGlobalVariable("warp_vote"))
      return true;
  }

  // TODO: we should further analyze whether the local variable
  // is same among all threads within a wrap
  // LLVM 18
  return !DI.isDivergent(instr);
  //return false;
}

// generate countpart alloc in the beginning of the Function
llvm::Instruction *GetContextArray(llvm::Instruction *instruction,
                                   bool intra_warp_loop) {
  std::ostringstream var;

  if (std::string(instruction->getName().str()) != "") {
    var << instruction->getName().str();
  } else if (tempInstructionIds.find(instruction) != tempInstructionIds.end()) {
    var << tempInstructionIds[instruction];
  } else {
    tempInstructionIds[instruction] = tempInstructionIndex++;
    var << tempInstructionIds[instruction];
  }
  if (intra_warp_loop)
    var << "_intra_warp_";
  else
    var << "_inter_warp_";
  std::string varName = var.str();

  if (contextArrays.find(varName) != contextArrays.end())
    return contextArrays[varName];

  BasicBlock &bb = instruction->getParent()->getParent()->getEntryBlock();

  IRBuilder<> builder(&*(bb.getFirstInsertionPt()));
  Function *FF = instruction->getParent()->getParent();
  Module *M = instruction->getParent()->getParent()->getParent();
  LLVMContext &C = M->getContext();
  const llvm::DataLayout &Layout = M->getDataLayout();

  llvm::Type *elementType;
  if (isa<AllocaInst>(instruction)) {
    // LLVM 18
    // elementType =
    // dyn_cast<AllocaInst>(instruction)->getType()->getElementType();
    elementType = dyn_cast<AllocaInst>(instruction)->getAllocatedType();
  } else {
    elementType = instruction->getType();
  }

  Type *AllocType = elementType;
  AllocaInst *InstCast = dyn_cast<AllocaInst>(instruction);
  /*
  if (InstCast) {
    unsigned Alignment = InstCast->getAlignment();

    uint64_t StoreSize = Layout.getTypeStoreSize(InstCast->getAllocatedType());

    if ((Alignment > 1) && (StoreSize & (Alignment - 1))) {
      uint64_t AlignedSize = (StoreSize & (~(Alignment - 1))) + Alignment;
      assert(AlignedSize > StoreSize);
      uint64_t RequiredExtraBytes = AlignedSize - StoreSize;

      if (isa<ArrayType>(elementType)) {

        ArrayType *StructPadding = ArrayType::get(
            Type::getInt8Ty(M->getContext()), RequiredExtraBytes);

        std::vector<Type *> PaddedStructElements;
        PaddedStructElements.push_back(elementType);
        PaddedStructElements.push_back(StructPadding);
        const ArrayRef<Type *> NewStructElements(PaddedStructElements);
        AllocType = StructType::get(M->getContext(), NewStructElements, true);
        uint64_t NewStoreSize = Layout.getTypeStoreSize(AllocType);
        assert(NewStoreSize == AlignedSize);
      } else if (isa<StructType>(elementType)) {
        StructType *OldStruct = dyn_cast<StructType>(elementType);

        ArrayType *StructPadding = ArrayType::get(
            Type::getInt8Ty(M->getContext()), RequiredExtraBytes);
        std::vector<Type *> PaddedStructElements;
        for (unsigned j = 0; j < OldStruct->getNumElements(); j++)
          PaddedStructElements.push_back(OldStruct->getElementType(j));
        PaddedStructElements.push_back(StructPadding);
        const ArrayRef<Type *> NewStructElements(PaddedStructElements);
        AllocType = StructType::get(OldStruct->getContext(), NewStructElements,
                                    OldStruct->isPacked());
        uint64_t NewStoreSize = Layout.getTypeStoreSize(AllocType);
        assert(NewStoreSize == AlignedSize);
      }
    }
  }
  */
  llvm::Value *ItemSize = nullptr;
  llvm::AllocaInst *Alloca = nullptr;

  auto block_size_addr = M->getGlobalVariable("block_size");
  auto block_size = createLoad(builder, block_size_addr);
  Alloca = builder.CreateAlloca(AllocType, block_size, varName);

  contextArrays[varName] = Alloca;
  return Alloca;
}

// save the local variable into replicated array
llvm::Instruction *AddContextSave(llvm::Instruction *instruction,
                                  llvm::Instruction *alloca,
                                  bool intra_warp_loop) {

  if (isa<AllocaInst>(instruction)) {
    return NULL;
  }

  llvm::Module *M = instruction->getParent()->getParent()->getParent();
  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);

  /* Save the produced variable to the array. */
  BasicBlock::iterator definition =
      (dyn_cast<Instruction>(instruction))->getIterator();
  ++definition;

  IRBuilder<> builder(&*definition);
  std::vector<llvm::Value *> gepArgs;

  auto inter_warp_index =
      createLoad(builder, M->getGlobalVariable("inter_warp_index"));
  auto intra_warp_index =
      createLoad(builder, M->getGlobalVariable("intra_warp_index"));
  auto thread_idx = builder.CreateBinOp(
      Instruction::Add, intra_warp_index,
      builder.CreateBinOp(Instruction::Mul, inter_warp_index,
                          ConstantInt::get(I32, SW_WARP_SIZE)), 
      "thread_idx");
  gepArgs.push_back(thread_idx);

  return builder.CreateStore(instruction, createGEP(builder, alloca, gepArgs));
}

llvm::Instruction *AddContextRestore(llvm::Value *val,
                                     llvm::Instruction *alloca,
                                     llvm::Instruction *before, bool isAlloca,
                                     bool intra_warp_loop) {
  assert(val != NULL);
  assert(alloca != NULL);
  IRBuilder<> builder(alloca);
  if (before != NULL) {
    builder.SetInsertPoint(before);
  } else if (isa<Instruction>(val)) {
    builder.SetInsertPoint(dyn_cast<Instruction>(val));
    before = dyn_cast<Instruction>(val);
  } else {
    assert(false && "Unknown context restore location!");
  }

  std::vector<llvm::Value *> gepArgs;

  auto M = before->getParent()->getParent()->getParent();
  auto I32 = llvm::Type::getInt32Ty(M->getContext());
  auto inter_warp_index =
        createLoad(builder, M->getGlobalVariable("inter_warp_index"));
  auto intra_warp_index =
        createLoad(builder, M->getGlobalVariable("intra_warp_index"));
  auto thread_idx = builder.CreateBinOp(
      Instruction::Add, intra_warp_index,
      builder.CreateBinOp(Instruction::Mul, inter_warp_index,
                          ConstantInt::get(I32, SW_WARP_SIZE)),
      "thread_idx");
  gepArgs.push_back(thread_idx);

  // print val
  // llvm::errs() << "AddContextRestore: val\n";
  // val->print(llvm::errs());
  // llvm::errs() << "\n";
  // llvm::errs() << "AddcontextRestore: before\n";
  // before->print(llvm::errs());
  // llvm::errs() << "\n";
  llvm::Instruction *gep =
      dyn_cast<Instruction>(createGEP(builder, alloca, gepArgs));
  if (isAlloca) {
    return gep;
  }

// Mark's fix (Dec 24, 2024)
// Check if `before` is a LoadInst
// print before
// llvm::errs() << "AddcontextRestore: before\n";
// before->print(llvm::errs());
// llvm::errs() << "\n";
if (auto *loadInst = dyn_cast<LoadInst>(before)) {
    // print loadInst
    // llvm::errs() << "AddcontextRestore: loadInst\n";
    // loadInst->print(llvm::errs());
    // llvm::errs() << "\n";
    // Check if the LoadInst has "divergence" metadata
    if (auto *MD = loadInst->getMetadata("divergence")) {
        // Create the new load with the metadata
        llvm::Instruction *newLoad = createLoad(builder, gep);
        newLoad->setMetadata("divergence", MD); // Attach the metadata
        return newLoad;
    }
}

// If `before` is not a LoadInst or has no "divergence" metadata
  return createLoad(builder, gep);
}

void AddContextSaveRestore(llvm::Instruction *instruction,
                           bool intra_warp_loop) {
  
                            // print instruction
  // llvm::errs() << "addcontextsaverestore\n";
  // instruction->print(llvm::errs());

  /* Allocate the context data array for the variable. */
  llvm::Instruction *alloca = GetContextArray(instruction, intra_warp_loop);

  llvm::Instruction *theStore =
      AddContextSave(instruction, alloca, intra_warp_loop);

  std::vector<Instruction *> uses;

  for (Instruction::use_iterator ui = instruction->use_begin(),
                                 ue = instruction->use_end();
       ui != ue; ++ui) {
    llvm::Instruction *user = dyn_cast<Instruction>(ui->getUser());
    if (!user)
      continue;
    if (user == theStore)
      continue;
    uses.push_back(user);
  }

  for (auto user : uses) {
    Instruction *contextRestoreLocation = user;
    llvm::Value *loadedValue =
        AddContextRestore(user, alloca, contextRestoreLocation,
                          isa<AllocaInst>(instruction), intra_warp_loop);
    user->replaceUsesOfWith(instruction, loadedValue);
  }
}

void handle_alloc(llvm::Function *F) {
  auto M = F->getParent();
  LLVMContext &C = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(C);

  std::vector<llvm::Instruction *> instruction_to_fix;
  for (auto bb = F->begin(); bb != F->end(); bb++) {
    for (auto ii = bb->begin(); ii != bb->end(); ii++) {
      if (llvm::AllocaInst *i = dyn_cast<AllocaInst>(ii)) {
        instruction_to_fix.push_back(i);
      }
    }
  }

  std::vector<llvm::Instruction *> need_remove;

  for (auto inst : instruction_to_fix) {
    // generate a new alloc
    auto block_size_addr = M->getGlobalVariable("block_size");
    IRBuilder<> builder(inst);
    auto block_size = createLoad(builder, block_size_addr);

    llvm::Type *elementType = NULL;
    // LLVM 18
    // if (dyn_cast<AllocaInst>(inst)->getType()->getElementType()) {
    //   elementType = dyn_cast<AllocaInst>(inst)->getType()->getElementType();
    // }
        if (dyn_cast<AllocaInst>(inst)) {
      elementType = dyn_cast<AllocaInst>(inst)->getAllocatedType();
    }

    assert(elementType != NULL);

    auto Alloca = builder.CreateAlloca(elementType, block_size,
                                       inst->getName().str() + "inter_warp");

    // replace all usage
    std::set<Instruction *> replace_user;
    for (Instruction::use_iterator ui = inst->use_begin(), ue = inst->use_end();
         ui != ue; ++ui) {
      auto *cast_user = dyn_cast<Instruction>(ui->getUser());
      if (cast_user)  // skip ConstantExpr and other non-Instruction users
        replace_user.insert(cast_user);
    }
    for (auto user : replace_user) {

      IRBuilder<> builder(user);
      // std::vector<llvm::Value *> gepArgs;
      auto inter_warp_index =
          createLoad(builder, M->getGlobalVariable("inter_warp_index"));
      auto intra_warp_index =
          createLoad(builder, M->getGlobalVariable("intra_warp_index"));
      auto thread_idx = builder.CreateBinOp(
          Instruction::Add, intra_warp_index,
          builder.CreateBinOp(Instruction::Mul, inter_warp_index,
                              ConstantInt::get(I32, SW_WARP_SIZE)),
          "thread_idx");

      auto gep = createGEP(builder, Alloca, thread_idx);

      user->replaceUsesOfWith(inst, gep);
    }
    need_remove.push_back(inst);
  }
  for (auto inst : need_remove) {
    inst->dropAllReferences();
    inst->eraseFromParent();
  }
}

void handle_local_variable_intra_warp(std::vector<ParallelRegion> &PRs,
                                      CustomDivergenceAnalysis &DI,
                                      bool skip_lifetime) {
  bool intra_warp_loop = 1;
  // we should handle allocation generated by PHI
  auto F = PRs[0].start_block->getParent();
  // Track which instructions have already been context-saved to avoid
  // double processing (entry block allocas may appear in multiple passes).
  std::set<llvm::Instruction *> already_context_saved;
  {
    std::vector<llvm::Instruction *> instruction_to_fix;
    // std::vector<llvm::AllocaInst *> instruction_to_move;-> vx_printf doesn't
    // work with this
    
    // llvm::LLVMContext &context = F->getParent()->getContext();
    for (auto bb = F->begin(); bb != F->end(); bb++) {
      for (auto ii = bb->begin(); ii != bb->end(); ii++) {
        if (isa<AllocaInst>(&(*ii))) {
          auto alloc = dyn_cast<AllocaInst>(&(*ii));
          // Skip context arrays and shfl emulation temporaries
          if (alloc->getName().contains("_intra_warp_") ||
              alloc->getName().contains("_inter_warp_") ||
              alloc->getName().starts_with("shfl_"))
            continue;
          // if this alloc's write are all non-divergence, then no need to
          // replicate
          // added: Nov 20 2023
          bool allStoreNonDivergence = true;
          for (Instruction::use_iterator ui = alloc->use_begin(),
                                         ue = alloc->use_end();
               ui != ue; ++ui) {
            // print ui
            // llvm::errs() << "ui->getUser() : ";
            // ui->getUser()->print(llvm::errs());
            // llvm::errs() << "\n";
            // before fix 
            llvm::Instruction *user = dyn_cast<Instruction>(ui->getUser());
            if (!user) {
              // skip ConstantExpr and other non-Instruction users
              allStoreNonDivergence = false;
              break;
            }
            // Skip lifetime intrinsics — they don't access data.
            // Only skip when nested loop is active (warp_shfl kernels);
            // for single-loop kernels, the old behavior is correct.
            if (skip_lifetime) {
              if (auto *CI = dyn_cast<CallInst>(user)) {
                if (auto *callee = CI->getCalledFunction()) {
                  if (callee->getName().starts_with("llvm.lifetime."))
                    continue;
                }
              }
            }
            if (isa<StoreInst>(user)) {
              auto storeVar = user->getOperand(0);
              if (DI.isDivergent(storeVar) ||
                  DI.isDivergent(dyn_cast<Value>(user))) {
                allStoreNonDivergence = false;
                break;
              }
            } else if (!isa<LoadInst>(user)) {
              allStoreNonDivergence = false;
              break;
            }
          }
          if (allStoreNonDivergence) {
            fprintf(stderr, "[alloca] SKIP (non-divergent stores): %s\n",
                    alloc->getName().str().c_str());
            // print all users
            for (Instruction::use_iterator ui = alloc->use_begin(),
                                             ue = alloc->use_end();
                                              ui != ue; ++ui) {
                llvm::User *user = ui->getUser(); // Use의 사용자 객체
                if (auto *inst = dyn_cast<Instruction>(user)) {
                    // inst->print(llvm::errs()); // 모든 Instruction 출력
                } else {
                    // llvm::errs() << "Non-instruction use found!\n";
                }
            }
            // instruction_to_move.push_back(alloc);-> vx_printf doesn't work
            // with this
            continue;
          }
          // Do not duplicate var used outside PRs
          bool used_in_non_PR = false;
          for (Instruction::use_iterator ui = alloc->use_begin(),
                                         ue = alloc->use_end();
               ui != ue; ++ui) {
            llvm::Instruction *user = dyn_cast<Instruction>(ui->getUser());
            if (!user) continue;  // skip ConstantExpr and other non-Instruction users
            // Skip lifetime intrinsics — they mark alloca scope but don't
            // access data, so they shouldn't prevent context save.
            // Only skip for nested-loop kernels to avoid regression.
            if (skip_lifetime) {
              if (auto *CI = dyn_cast<CallInst>(user)) {
                if (auto *callee = CI->getCalledFunction()) {
                  if (callee->getName().starts_with("llvm.lifetime."))
                    continue;
                }
              }
            }
            auto user_block = user->getParent();
            bool find_in_PR = false;
            for (auto PR : PRs) {
              if (PR.wrapped_block.find(user_block) != PR.wrapped_block.end()) {
                find_in_PR = true;
                break;
              }
            }
            if (find_in_PR == false) {
              used_in_non_PR = true;
              fprintf(stderr, "[alloca]   non-PR user in BB=%s: ",
                      user_block->getName().str().c_str());
              user->print(llvm::errs()); fprintf(stderr, "\n");
              break;
            }
          }
          if (used_in_non_PR) {
            fprintf(stderr, "[alloca] SKIP (used outside PR): %s\n",
                    alloc->getName().str().c_str());
          }
          if (!used_in_non_PR) {
            fprintf(stderr, "[alloca] FIX (divergent, all users in PR): %s\n",
                    alloc->getName().str().c_str());
            instruction_to_fix.push_back(alloc);

            // Additional recursive check: Does this instruction eventually lead
            // to a conditional branch?
            std::queue<const Instruction *> Worklist_prev;
            std::queue<const Instruction *> Worklist_curr;
            std::unordered_set<const Instruction *> Visited_prev;
            std::unordered_set<const Instruction *> Visited_curr;
            std::vector<const Instruction *> Visited_prev_vec;
            std::vector<const Instruction *> Visited_curr_vec;

            for (const Use &U : alloc->uses()) {
                const Instruction *User = dyn_cast<Instruction>(U.getUser());
                if (User) {
                    Worklist_prev.push(alloc);
                    Worklist_curr.push(User);
                }
            }

            // Worklist.push(alloc); // Start with the user of the instruction
           
            while (!Worklist_prev.empty()) {
                
                const Instruction *Prev = Worklist_prev.front();
                const Instruction *Current = Worklist_curr.front();

              // const Instruction *Current = Worklist.front();
                
                Worklist_prev.pop();
                Worklist_curr.pop();

                // llvm::errs() << "\nworklist working: Current instruction:\n";
                // Current->print(llvm::errs());

                // Skip already visited instructions
                if (Visited_curr.count(Current) && Visited_prev.count(Prev)) {
                continue;
              }
                Visited_prev.insert(Prev);
                Visited_curr.insert(Current);
                Visited_prev_vec.push_back(Prev);
                Visited_curr_vec.push_back(Current);

                // If the current instruction is a conditional branch, log it
                if (const BranchInst *branch = dyn_cast<BranchInst>(Current)) {
                if (branch->isConditional() &&
                    Prev->getParent() == Current->getParent()) {
                  // llvm::errs() << "\nInstruction eventually leads to a "
                  //                 "conditional branch:\n";
                        // branch->print(llvm::errs());
                        // llvm::errs() << "\n";
                                  
                        LLVMContext &context = F->getContext();
                  MDNode *N = MDNode::get(
                      context, MDString::get(context, "non-uniform"));
                        // Remove const qualifier
                        
                        // Set metadata

                        // Backtrack to find the LoadInst
                        // llvm::errs() << "\nBacktracking to find LoadInst:\n";
                        const Instruction *BacktrackInst = Prev;
                        while (BacktrackInst) {
                            // llvm::errs() << "Checking instruction:\n";
                            // BacktrackInst->print(llvm::errs());
                            // llvm::errs() << "\n";

                    if (const LoadInst *loadInst =
                            dyn_cast<LoadInst>(BacktrackInst)) {
                              // check branch and loadInst are in the same block
                              if (loadInst->getParent() == branch->getParent()) {
                                // llvm::errs() << "Found LoadInst:\n";
                                // loadInst->print(llvm::errs());
                                // llvm::errs() << "\n";
                        auto non_const_inst =
                            const_cast<Instruction *>(BacktrackInst);
                                non_const_inst->setMetadata("divergence", N);
                              }
                                break; // Stop backtracking once the LoadInst is found
                            }

                          // Find the index of BacktrackInst in Visited_curr
                    auto it = std::find(Visited_curr_vec.begin(),
                                        Visited_curr_vec.end(), BacktrackInst);
                          if (it == Visited_curr_vec.end()) {
                      // llvm::errs() << "Instruction not found in visited list. "
                      //                 "Backtracking ends.\n";
                              break;
                          }

                    // Get the corresponding index and update BacktrackInst
                    // using Visited_prev
                          size_t index = std::distance(Visited_curr_vec.begin(), it);
                          BacktrackInst = Visited_prev_vec[index];
                        }
                    }
                }
                /*
              // also covers the case where there's a switch instruction
            else if (const SwitchInst *switchInst =
            dyn_cast<SwitchInst>(Current)) { printf("SwitchInst\n"); if
            (Prev->getParent() == Current->getParent()) { llvm::errs() <<
            "\nInstruction eventually leads to a switch statement:\n";
                      switchInst->print(llvm::errs());
                      llvm::errs() << "\n";
                      
                      LLVMContext &context = F->getContext();
                    MDNode* N = MDNode::get(context, MDString::get(context,
            "non-uniform"));
                      
                    // Backtracking to find LoadInst (similar logic for
            SwitchInst) llvm::errs() << "\nBacktracking to find LoadInst:\n";
                      const Instruction *BacktrackInst = Prev;
                      while (BacktrackInst) {
                          llvm::errs() << "Checking instruction:\n";
                          BacktrackInst->print(llvm::errs());
                          llvm::errs() << "\n";

                        if (const LoadInst *loadInst =
            dyn_cast<LoadInst>(BacktrackInst)) { if (loadInst->getParent() ==
            switchInst->getParent()) { llvm::errs() << "Found LoadInst:\n";
                                  loadInst->print(llvm::errs());
                                  llvm::errs() << "\n";
                                auto non_const_inst = const_cast<Instruction
            *>(BacktrackInst); non_const_inst->setMetadata("divergence", N);
                              }
                            break; // Stop backtracking once the LoadInst is
            found
                          }

                          // Backtracking logic
                        auto it = std::find(Visited_curr_vec.begin(),
            Visited_curr_vec.end(), BacktrackInst); if (it ==
            Visited_curr_vec.end()) { llvm::errs() << "Instruction not found in
            visited list. Backtracking ends.\n"; break;
                          }

                        size_t index = std::distance(Visited_curr_vec.begin(),
            it); BacktrackInst = Visited_prev_vec[index];
                      }
                  }
              }
                */
                // Add al l users of the current instruction to the worklist
                for (const Use &U : Current->uses()) {
                const Instruction *NextUser =
                    dyn_cast<Instruction>(U.getUser());
                if (NextUser && !Visited_prev.count(Current) &&
                    !Visited_curr.count(NextUser)) {
                        Worklist_prev.push(Current);
                        Worklist_curr.push(NextUser);
                        // llvm::errs() << "\nNext user of the instruction:\n";
                        // NextUser->print(llvm::errs());
                    }
                }
            }
          }
    
          // LLVM 18 (temporaily disabled)-> vx_printf doesn't work with this
          /*
          // Do not duplicate var used only by a single PR
          int used_PR = 0;
          for (auto PR : PRs) {
            used_PR += PR.inst_used_in_region(alloc);
          }
          if (!used_in_non_PR && used_PR > 1) {
            instruction_to_fix.push_back(alloc);
          } else {
            instruction_to_move.push_back(alloc);
          }
          */
        }
      }
    }
    for (auto inst : instruction_to_fix) {
      if (already_context_saved.count(inst)) {
        fprintf(stderr, "[alloca] SKIP (already context-saved): %s\n",
                inst->getName().str().c_str());
        continue;
      }
      already_context_saved.insert(inst);
      AddContextSaveRestore(inst, intra_warp_loop);
    }
    /*
        for (auto alloc : instruction_to_move) {
      // need to move all allocInst to the entry basic block
      IRBuilder<> builder(&*(alloc->getParent()
                                 ->getParent()
                                 ->getEntryBlock()
                                 .getFirstInsertionPt()));
      auto newAllocInst = builder.CreateAlloca(
          alloc->getAllocatedType(), alloc->getArraySize(), alloc->getName());
      alloc->replaceAllUsesWith(newAllocInst);
      alloc->removeFromParent();
    }
    */
  }

  // First pass: detect allocas with cross-region store→load dependencies.
  // In SCHE_0, alloca variables are shared across all warp loop iterations.
  // If a divergent value is stored to an alloca in one region and loaded
  // in another, the alloca only holds the last thread's value → wrong.
  // Convert such allocas to per-thread _intra_warp_ arrays.
  {
    // Build per-region instruction sets
    std::vector<std::set<llvm::BasicBlock *>> regionBBs;
    for (auto &pr : PRs)
      regionBBs.push_back(pr.wrapped_block);

    // Find allocas with cross-region store→load
    std::set<AllocaInst *> cross_region_allocas;
    for (auto &F_inst : F->getEntryBlock()) {
      auto *AI = dyn_cast<AllocaInst>(&F_inst);
      if (!AI) continue;
      // Skip context arrays and shfl emulation temporaries
      if (AI->getName().contains("_intra_warp_") ||
          AI->getName().contains("_inter_warp_") ||
          AI->getName().starts_with("shfl_"))
        continue;
      // Find which regions contain stores and loads to this alloca
      int store_region = -1, load_region = -1;
      for (auto *U : AI->users()) {
        auto *SI = dyn_cast<StoreInst>(U);
        auto *LI = dyn_cast<LoadInst>(U);
        if (!SI && !LI) continue;
        auto *BB = cast<Instruction>(U)->getParent();
        for (int r = 0; r < (int)regionBBs.size(); r++) {
          if (regionBBs[r].count(BB)) {
            if (SI) store_region = r;
            if (LI) load_region = r;
          }
        }
      }
      if (AI->getName().find("thread_id") != std::string::npos ||
          AI->getName().find("lane") != std::string::npos ||
          AI->getName().find("wid") != std::string::npos) {
        fprintf(stderr, "[alloca] %s: store_region=%d, load_region=%d\n",
                AI->getName().str().c_str(), store_region, load_region);
      }
      // Context save if: cross-region (different regions) OR if store/load
      // are outside any region (region=-1) but the alloca has divergent stores.
      // The latter handles cases where getParallelRegionBefore doesn't include
      // the BB containing the thread_id store/load.
      bool needs_check = (store_region >= 0 && load_region >= 0 && store_region != load_region) ||
                          (store_region == -1 || load_region == -1);
      if (needs_check) {
        fprintf(stderr, "[alloca] %s: IS cross-region (%d→%d), checking divergence\n",
                AI->getName().str().c_str(), store_region, load_region);
        // Check if the stored value is divergent
        bool found_store = false;
        for (auto *U : AI->users()) {
          if (auto *SI = dyn_cast<StoreInst>(U)) {
            found_store = true;
            bool div = DI.isDivergent(SI->getValueOperand());
            fprintf(stderr, "[alloca]   store user divergent=%d\n", div);
            if (div) {
              cross_region_allocas.insert(AI);
              break;
            }
          }
        }
        if (!found_store) {
          fprintf(stderr, "[alloca]   no store users found! adding anyway\n");
          cross_region_allocas.insert(AI);
        }
      }
    }
    // Context-save divergent allocas in the entry block.
    // These allocas are outside all parallel regions, so the normal
    // context save loop doesn't see them. But if a divergent value
    // is stored to an alloca, each thread needs its own slot.
    for (auto *AI : cross_region_allocas) {
      if (already_context_saved.count(AI)) {
        fprintf(stderr, "[alloca] SKIP cross-region (already context-saved): %s\n",
                AI->getName().str().c_str());
        continue;
      }
      already_context_saved.insert(AI);
      AddContextSaveRestore(AI, intra_warp_loop);
    }
  }

  for (auto parallel_regions : PRs) {
    std::set<llvm::Instruction *> instruction_in_region;
    std::vector<llvm::Instruction *> instruction_to_fix;

    for (auto bb : parallel_regions.wrapped_block) {
      for (llvm::BasicBlock::iterator instr = bb->begin(); instr != bb->end();
           ++instr) {
        llvm::Instruction *instruction = &*instr;
        instruction_in_region.insert(instruction);
      }
    }
    /* Find all the instructions that define new values and
       check if they need to be context saved. */
    SmallVector<BasicBlock *, 16> blocks_to_check;
    blocks_to_check.push_back(&F->getEntryBlock());
    for (auto bb : parallel_regions.wrapped_block) {
      blocks_to_check.push_back(bb);
    }
    for (auto *bb : blocks_to_check) {
      for (llvm::BasicBlock::iterator instr = bb->begin(); instr != bb->end();
           ++instr) {
        llvm::Instruction *instruction = &*instr;
        // Skip context arrays from prior passes
        if (isa<AllocaInst>(instruction) &&
            (instruction->getName().contains("_intra_warp_") ||
             instruction->getName().contains("_inter_warp_")))
          continue;
        if (ShouldNotBeContextSaved(instruction, DI))
          continue;
        for (Instruction::use_iterator ui = instruction->use_begin(),
                                       ue = instruction->use_end();
             ui != ue; ++ui) {
          llvm::Instruction *user = dyn_cast<Instruction>(ui->getUser());

          if (user == NULL)
            continue;
          if (isa<AllocaInst>(instruction) ||
              (instruction_in_region.find(user) ==
               instruction_in_region.end())) {
            instruction_to_fix.push_back(instruction);
            break;
          }
        }
      }
    }
    for (auto inst : instruction_to_fix) {
      if (already_context_saved.count(inst)) {
        fprintf(stderr, "[alloca] SKIP PR-loop (already context-saved): %s\n",
                inst->getName().str().c_str());
        continue;
      }
      already_context_saved.insert(inst);
      AddContextSaveRestore(inst, intra_warp_loop);
    }
  }
}

// Schedule 1, 
// 1. !nested loop
//    for (int i = hw_tid + hw_wid * hw_nt; i < sw_block_size; i += hw_nt *
//    hw_nw)
//      id = i;
//      doWork()
// 2. nested loop
//    sw_warp_size = 32 // TODO : change to the CUDA function 
//    for (int i = hw_wid; i < (sw_block_size + sw_warp_size -1) / sw_warp_size;
//    i += hw_nw)
//        for(int j = tid; j < sw_warp_size; j += hw_nt)
//          id = i * sw_warp_size + j
//          if(id < block_size)
//            doWork()
//        barrier()

struct ScheduleInfo {
  llvm::Value *inner_loop_init;
  llvm::Value *inner_loop_inc;
  llvm::Value *inner_loop_cond;

  llvm::Value *outer_loop_init;
  llvm::Value *outer_loop_inc;
  llvm::Value *outer_loop_cond;
};
ScheduleInfo sche_data;


void add_mapping_variable(llvm::Function* F, bool intra_warp_loop, 
      bool need_nested_loop, int schedule_flag)
{
  IRBuilder<> builder(&*(F->getEntryBlock().getFirstInsertionPt()));
  auto M = F->getParent();

  // Generate function definition for getting VX functions
  LLVMContext &context = M->getContext();
  FunctionType *nTTy =
      FunctionType::get(IntegerType::getInt32Ty(context), true);

  // Load basic software info
  auto sw_block_size = createLoad(builder, M->getGlobalVariable("block_size"));
  auto sw_warp_size = builder.getInt32(SW_WARP_SIZE);

  // For nested loops: intra_warp pass handles inner loop (warp-level),
  // inter_warp pass handles outer loop (block-level).
  // Skip full setup for intra_warp pass when nested — the inter_warp pass
  // will set up outer loop variables. But still set inner loop variables.
  if (need_nested_loop && intra_warp_loop) {
    // Only set inner loop variables for intra_warp pass
    if (schedule_flag == 1) {
      FunctionCallee nHTC = M->getOrInsertFunction("vx_num_threads", nTTy);
      FunctionCallee tidC = M->getOrInsertFunction("vx_thread_id", nTTy);
      auto tid = builder.CreateCall(tidC, {}, "hw_tid");
      auto nHT = builder.CreateCall(nHTC, {}, "nHT");
      sche_data.inner_loop_init = tid;
      sche_data.inner_loop_inc = nHT;
      sche_data.inner_loop_cond = sw_warp_size;
    } else { // Schedule 0
      sche_data.inner_loop_init = builder.getInt32(0);
      sche_data.inner_loop_inc = builder.getInt32(1);
      sche_data.inner_loop_cond = sw_warp_size;
    }
    return;
  }

  if (schedule_flag == 1) {
      // Get hardware information
      FunctionCallee nHTC = M->getOrInsertFunction("vx_num_threads", nTTy);
      FunctionCallee nHWC = M->getOrInsertFunction("vx_num_warps", nTTy);
      FunctionCallee tidC = M->getOrInsertFunction("vx_thread_id", nTTy);
      FunctionCallee widC = M->getOrInsertFunction("vx_warp_id", nTTy);

      auto tid = builder.CreateCall(tidC, {}, "hw_tid");
      auto wid = builder.CreateCall(widC, {}, "hw_wid");
      auto nHT = builder.CreateCall(nHTC, {}, "nHT");
      auto nHW = builder.CreateCall(nHWC, {}, "nHW"); 

    if (!need_nested_loop) {
      sche_data.inner_loop_init =
          builder.CreateAdd(tid, builder.CreateMul(wid, nHT, "hw_"), "hw_tlid");
      sche_data.inner_loop_inc = builder.CreateMul(nHT, nHW, "hw_tpc");
      sche_data.inner_loop_cond = sw_block_size;
      //printf("SCHEDULE DEBUG: no nested loop!\n");
    } else {
      // sche_data.inner_loop_init = M->getGlobalVariable("intra_warp_index");
      sche_data.inner_loop_init = tid;
      sche_data.inner_loop_inc = nHT;
      sche_data.inner_loop_cond = sw_warp_size;

      sche_data.outer_loop_init = wid;
      sche_data.outer_loop_inc = nHW;
      sche_data.outer_loop_cond = builder.CreateSDiv(
          builder.CreateSub(builder.CreateAdd(sw_block_size, sw_warp_size),
                            builder.getInt32(1)),
          sw_warp_size, "warp_number");
              //printf("SCHEDULE DEBUG: nested loop!\n");
    }
  } else { // Schedule 0 
    if (!need_nested_loop) {
      sche_data.inner_loop_init = builder.getInt32(0);
      sche_data.inner_loop_inc = builder.getInt32(1);
      sche_data.inner_loop_cond = sw_block_size;
    } else {
      sche_data.inner_loop_init = builder.getInt32(0);
      sche_data.inner_loop_inc = builder.getInt32(1);
      sche_data.inner_loop_cond = sw_warp_size;

      sche_data.outer_loop_init = builder.getInt32(0);
      sche_data.outer_loop_inc = builder.getInt32(1);
      sche_data.outer_loop_cond =
          builder.CreateSDiv(sw_block_size, sw_warp_size, "warp_number");
    } 
  }

  return;
}

BasicBlock *insert_loop_init(llvm::BasicBlock *InsertInitBefore,
                             bool intra_warp_loop) {
  llvm::Module *M = InsertInitBefore->getParent()->getParent();
  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);
  std::string block_name =
      (intra_warp_loop) ? "intra_warp_init" : "inter_warp_init";

  BasicBlock *loop_init = BasicBlock::Create(
      context, block_name, InsertInitBefore->getParent(), InsertInitBefore);

  IRBuilder<> builder(context);
  builder.SetInsertPoint(loop_init);

  if (!intra_warp_loop) { // inter warp
    auto inter_warp_index = M->getGlobalVariable("inter_warp_index");
    builder.CreateStore(sche_data.outer_loop_init, inter_warp_index);
  } else { // intra warp
    auto intra_warp_index = M->getGlobalVariable("intra_warp_index");
    // Add TLS divergent seed to loop init value so LLVM recognizes
    // the warp loop counter as divergent (SCHE_0 only)
    auto tls_seed = M->getGlobalVariable("sche_0_thread_idx_TLS");
    if (tls_seed) {
      auto tls_ptr = builder.CreateCall(
          Intrinsic::getDeclaration(M, Intrinsic::threadlocal_address,
                                    {tls_seed->getType()}),
          {tls_seed});
      auto seed_val = builder.CreateLoad(I32, tls_ptr, "div_seed");
      auto init_with_seed = builder.CreateAdd(sche_data.inner_loop_init, seed_val, "init_divergent");
      builder.CreateStore(init_with_seed, intra_warp_index);
    } else {
      builder.CreateStore(sche_data.inner_loop_init, intra_warp_index);
    }
  }

  builder.CreateBr(InsertInitBefore);
  return loop_init;
}

BasicBlock *insert_loop_cond(llvm::BasicBlock *InsertCondBefore,
                             llvm::BasicBlock *LoopEnd, bool intra_warp_loop) {
  llvm::Module *M = InsertCondBefore->getParent()->getParent();
  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);
  std::string block_name =
      (intra_warp_loop) ? "intra_warp_cond" : "inter_warp_cond";
  BasicBlock *loop_cond = BasicBlock::Create(
      context, block_name, InsertCondBefore->getParent(), InsertCondBefore);
  IRBuilder<> builder(context);
  builder.SetInsertPoint(loop_cond);

  llvm::Value *cmpResult = NULL;
  if (!intra_warp_loop) {
    auto inter_warp_index = M->getGlobalVariable("inter_warp_index");
    cmpResult = builder.CreateICmpULT(createLoad(builder, inter_warp_index),
                                      sche_data.outer_loop_cond);
  } else {
    auto intra_warp_index = M->getGlobalVariable("intra_warp_index");
    cmpResult = builder.CreateICmpULT(createLoad(builder, intra_warp_index),
                                      sche_data.inner_loop_cond);
  }

  builder.CreateCondBr(cmpResult, InsertCondBefore, LoopEnd);
  return loop_cond;
}

BasicBlock *insert_loop_inc(llvm::BasicBlock *InsertIncBefore,
                            bool intra_warp_loop) {
  llvm::Module *M = InsertIncBefore->getParent()->getParent();
  LLVMContext &context = M->getContext();
  auto I32 = llvm::Type::getInt32Ty(context);
  std::string block_name =
      (intra_warp_loop) ? "intra_warp_inc" : "inter_warp_inc";
  BasicBlock *loop_inc = BasicBlock::Create(
      context, block_name, InsertIncBefore->getParent(), InsertIncBefore);

  IRBuilder<> builder(context);
  builder.SetInsertPoint(loop_inc);

  if (!intra_warp_loop) { // inter warp
    auto inter_warp_index = M->getGlobalVariable("inter_warp_index");
    auto new_index = builder.CreateBinOp(
        Instruction::Add, createLoad(builder, inter_warp_index),
        sche_data.outer_loop_inc, "inter_warp_index_increment");
    builder.CreateStore(new_index, inter_warp_index);
  } else { // intra warp
    auto intra_warp_index = M->getGlobalVariable("intra_warp_index");
      auto new_index = builder.CreateBinOp(
          Instruction::Add, createLoad(builder, intra_warp_index),
          sche_data.inner_loop_inc, "intra_warp_index_increment");
      builder.CreateStore(new_index, intra_warp_index);
  } 

  builder.CreateBr(InsertIncBefore);
  return loop_inc;
}

void add_warp_loop(std::vector<ParallelRegion> parallel_regions,
                   bool intra_warp_loop) {
  for (auto region : parallel_regions) {
    auto start_block = region.start_block;
    auto tail_block = region.end_block;
    auto next_block = region.successor_block;

    // if the start block's name is "cond_after_block_sync_5", continue
    // if(start_block->getName().str().find("cond_after_block_sync_5") !=
    // std::string::npos)
    //  continue;

    auto loop_cond = insert_loop_cond(start_block, next_block, intra_warp_loop);
    auto loop_init = insert_loop_init(loop_cond, intra_warp_loop);

    auto F = start_block->getParent();
    for (Function::iterator i = F->begin(); i != F->end(); ++i) {
      llvm::BasicBlock *bb = &(*i);
      if (bb == loop_cond)
        continue;
      bb->getTerminator()->replaceUsesOfWith(start_block, loop_init);
    }
    auto loop_inc = insert_loop_inc(loop_cond, intra_warp_loop);
    tail_block->getTerminator()->replaceUsesOfWith(next_block, loop_inc);
    // we have to reset inter/intra warp index to 0, as these maybe used
    // outside PR when there are conditional loop/branch
    llvm::Module *M = start_block->getParent()->getParent();
    LLVMContext &context = M->getContext();
    auto I32 = llvm::Type::getInt32Ty(context);
    auto reset_block_name =
        intra_warp_loop ? "intra_reset_block" : "inter_reset_block";
    BasicBlock *reset_index = BasicBlock::Create(
        start_block->getContext(), reset_block_name, F, next_block);
    IRBuilder<> builder(start_block->getContext());
    builder.SetInsertPoint(reset_index);
    if (intra_warp_loop) { // intra warp
      auto intra_warp_index = M->getGlobalVariable("intra_warp_index");
      builder.CreateStore(ConstantInt::get(I32, 0), intra_warp_index);
    } else { // inter warp
      auto inter_warp_index = M->getGlobalVariable("inter_warp_index");
      builder.CreateStore(ConstantInt::get(I32, 0), inter_warp_index);
    }
    builder.CreateBr(next_block);
    loop_cond->getTerminator()->replaceUsesOfWith(next_block, reset_index);

    // add metadata
    MDNode *Dummy =
        MDNode::getTemporary(context, ArrayRef<Metadata *>()).release();
    MDNode *AccessGroupMD = MDNode::getDistinct(context, {});
    MDNode *ParallelAccessMD = MDNode::get(
        context,
        {MDString::get(context, "llvm.loop.parallel_accesses"), AccessGroupMD});
    MDNode *Root = MDNode::get(context, {Dummy, ParallelAccessMD});

    Root->replaceOperandWith(0, Root);
    MDNode::deleteTemporary(Dummy);
    // We now have
    //   !1 = metadata !{metadata !1} <- self-referential root
    loop_cond->getTerminator()->setMetadata("llvm.loop", Root);

    for (auto bb : region.wrapped_block) {
      for (BasicBlock::iterator ii = bb->begin(), ee = bb->end(); ii != ee;
           ii++) {
        if (!ii->mayReadOrWriteMemory()) {
          continue;
        }
        MDNode *NewMD = MDNode::get(bb->getContext(), AccessGroupMD);
        MDNode *OldMD = ii->getMetadata("llvm.mem.parallel_loop_access");
        if (OldMD != nullptr) {
          NewMD = llvm::MDNode::concatenate(OldMD, NewMD);
        }
        ii->setMetadata("llvm.mem.parallel_loop_access", NewMD);
      }
    }
  }
}

void print_parallel_region(std::vector<ParallelRegion> parallel_regions) {
  //printf("get PR:\n");
  for (auto region : parallel_regions) {
    auto start = region.start_block;
    auto end = region.end_block;
    auto next = region.successor_block;
    //printf("parallel region: %s->%s next: %s\n", start->getName().str().c_str(),
//           end->getName().str().c_str(), next->getName().str().c_str());
    //printf("have: \n");
    for (auto b : region.wrapped_block) {
      //printf("%s\n", b->getName().str().c_str());
    }
  }
}

void remove_barrier(llvm::Function *F, bool intra_warp_loop,
                    int schedule_flag) {
  
  std::vector<Instruction *> barriers;

  for (auto BB = F->begin(); BB != F->end(); ++BB) {
    for (auto BI = BB->begin(); BI != BB->end(); BI++) {
      if (auto Call = dyn_cast<CallInst>(BI)) {
        if (Call->isInlineAsm() || !Call->getCalledFunction())
          continue;
        auto func_name = Call->getCalledFunction()->getName().str();
        if (isWarpSync(func_name)) {
          barriers.push_back(Call);
        }
        if (!intra_warp_loop && (func_name == "llvm.nvvm.barrier0" ||
                                 func_name == "llvm.nvvm.barrier.sync")) {
          barriers.push_back(Call);
        }
      }
    }
  }

  if (schedule_flag == 1 && barriers.size() > 1) {
    auto M = F->getParent();
    LLVMContext &context = M->getContext();

    // Generate function def for getting VX Warp Size
    FunctionType *nTTy =
        FunctionType::get(IntegerType::getInt32Ty(context), true);
    FunctionCallee nWC = M->getOrInsertFunction("vx_num_warps", nTTy);

    // Generate function def for VX Barrier
    ArrayRef<Type *> VXBParams = {IntegerType::getInt32Ty(context),
                                  IntegerType::getInt32Ty(context)};
    FunctionType *VXBarTy =
        FunctionType::get(Type::getVoidTy(context), VXBParams, false);
    FunctionCallee VXBarC = M->getOrInsertFunction("vx_barrier", VXBarTy);
    
    int curBNum_ = 1;
    for (auto B = barriers.begin() + 1; B != barriers.end(); ++B) {
      IRBuilder<> builder(*B);
      CallInst *nW = builder.CreateCall(nWC);
      auto cnt = builder.getInt32(curBNum_++);
      // builder.CreateCall(VXBarC, {cnt, nW});
    } 
  }

  for (auto inst : barriers) {
    inst->eraseFromParent();
  }  
}

class InsertWarpLoopPass : public llvm::FunctionPass {

public:
  static char ID;
  bool intra_warp_loop;
  int schedule_flag; 

  InsertWarpLoopPass(bool intra_warp = 0, int schedule = 0)
      : FunctionPass(ID), intra_warp_loop(intra_warp), schedule_flag(schedule) {}

  virtual void getAnalysisUsage(llvm::AnalysisUsage &AU) const {
    AU.addRequired<DominatorTreeWrapperPass>();
    AU.addRequired<PostDominatorTreeWrapperPass>();
    AU.addRequired<LoopInfoWrapperPass>();
    AU.addRequired<TargetTransformInfoWrapperPass>();
  }

  void getParallelRegionBefore(llvm::BasicBlock *B, bool intra_warp_loop,
                               std::vector<ParallelRegion> &parallel_regions,
                               CustomDivergenceAnalysis &DI) {
    ParallelRegion current_region;

    SmallVector<BasicBlock *, 4> pending_blocks;
    BasicBlock *region_entry_barrier = NULL;
    BasicBlock *entry = NULL;
    BasicBlock *exit = B->getSinglePredecessor();
    fprintf(stderr, "[PR] === getParallelRegionBefore: B=%s, preds=%d ===\n",
            B->getName().str().c_str(), (int)std::distance(pred_begin(B), pred_end(B)));
    for (BasicBlock *Pred : predecessors(B)) {
      pending_blocks.push_back(Pred);
    }
    // Note: multiple predecessors can occur at merge points (if-else) or
    // loop headers (back edge). Previously this returned early, which caused
    // regions before loops to be missed (e.g., thread_id store before a for
    // loop). The while-loop below handles duplicates via wrapped_block check,
    // so it's safe to continue with all predecessors.

    while (!pending_blocks.empty()) {
      BasicBlock *current = pending_blocks.back();
      pending_blocks.pop_back();

      // avoid infinite recursion of loops
      if (current_region.wrapped_block.count(current) != 0) {
        fprintf(stderr, "[PR]   skip (already in region): %s\n", current->getName().str().c_str());
        continue;
      }

      fprintf(stderr, "[PR]   visiting: %s\n", current->getName().str().c_str());

      // If we reach another barrier this must be the
      // parallel region entry.
      bool has_barrier = 0;
      for (auto i = current->begin(), e = current->end(); i != e; ++i) {
        if (llvm::CallInst *call_inst = llvm::dyn_cast<llvm::CallInst>(&(*i))) {
          if (call_inst->isInlineAsm() || !call_inst->getCalledFunction())
            continue;
          auto func_name = call_inst->getCalledFunction()->getName().str();
          if (func_name == "llvm.nvvm.barrier0" ||
              func_name == "llvm.nvvm.barrier.sync")
            has_barrier = 1;
          if (isWarpSync(func_name) && intra_warp_loop)
            has_barrier = 1;
        }
      }
      // print current block
      //printf("getParallelRegionbefore: current block: ");
      // current->print(llvm::errs());
      // print has barrier value
      //printf("has_barrier: %d\n", has_barrier);

      // if we reach a block which only has a single condtional branch,
      // it is the start point of a B-condition, we have to stop here
      bool is_single_conditional_branch_block = 0;
      if (auto br = dyn_cast<llvm::BranchInst>(current->getTerminator())) {
        if (br->isConditional()) {
          if (current->size() == 1) {
            is_single_conditional_branch_block = 1;
          } else {
            // generate by replicate local variable
            //printf(
//                "[WARNING] match single conditional branch with HARD CODE\n");
            bool branch_to_intra_init = false;
            for (unsigned suc = 0; suc < br->getNumSuccessors(); ++suc) {
              llvm::BasicBlock *entryCandidate = br->getSuccessor(suc);
              auto block_name = entryCandidate->getName().str();
              if (find_block_barrier_in_region(current, B)) {
                if (block_name.find("warp_init") != block_name.npos) {
                  is_single_conditional_branch_block = 1;
                  break;
                }
              }
            }
          }
        }
      }

      if (has_barrier || is_single_conditional_branch_block) {
        fprintf(stderr, "[PR]   → barrier/branch stop: %s (has_barrier=%d, single_cond=%d)\n",
                current->getName().str().c_str(), has_barrier, is_single_conditional_branch_block);
        if (region_entry_barrier == NULL)
          region_entry_barrier = current;
        else if (region_entry_barrier != current) {
          // this means there is not PR before B, just return
          return;
        }
        continue;
      }

      // Non-barrier block, this must be on the region.
      current_region.wrapped_block.insert(current);

      // Add predecessors to pending queue.
      for (BasicBlock *Pred : predecessors(current)) {
        pending_blocks.push_back(Pred);
      }
    }

    if (current_region.wrapped_block.empty()) {
      return;
    }

    // if do not find entry node, this means all predecessor
    // blocks do not need to execute multiply times
    if (region_entry_barrier == NULL) {
      return;
    }
    // Find the entry node.
    assert(region_entry_barrier != NULL);
    for (unsigned
             suc = 0,
             num = region_entry_barrier->getTerminator()->getNumSuccessors();
         suc < num; ++suc) {
      llvm::BasicBlock *entryCandidate =
          region_entry_barrier->getTerminator()->getSuccessor(suc);
      if (current_region.wrapped_block.count(entryCandidate) == 0)
        continue;
      entry = entryCandidate;
      break;
    }
    // delete useless PR, those PRs only have branch
    if (entry == exit) {
      if (entry->size() == 1 && isa<llvm::BranchInst>(entry->begin())) {
        return;
      }
    }
    bool is_useless = true;
    auto iter = entry;
    // llvm::errs() << "CHECK HERE: entry block: \n";
    // entry->print(llvm::errs());
    // llvm::errs() << "iter_size: "<<iter->size();
    // llvm::errs() << "print done\n";

    do {
      // llvm::errs() << "\niter block: \n";
      //  iter->print(llvm::errs());
      // llvm::errs() << "iter_size: " << iter->size();
      if (iter->size() != 1 || !isa<llvm::BranchInst>(entry->begin())) {
        // llvm::errs() << "became useful CASE 1\n";
        // llvm::errs() << "--------------\n";
        is_useless = false;
        
        break;
      }
      if (iter->getTerminator()->getNumSuccessors() > 1) {
        is_useless = false;
        // llvm::errs() << "became useful CASE 2\n";
        // llvm::errs() << "--------------\n";
        break;
      }
      iter = iter->getTerminator()->getSuccessor(0);
      // llvm::errs() << "--------------\n";
    } while (iter != exit);
    
    iter = entry;
    bool any_divergent_var = false;
    // create a vector of BasicBlock*
    std::vector<BasicBlock *> checked_blocks;
    checked_blocks.push_back(entry);
    do {
      // llvm::errs() << "divergent iteration check: \n";
      //  go through every variable in the block and check whether they have any
      //  divergent variable
      for (auto &I : *iter) {
        // get all the operands of the instruction
        if (llvm::dyn_cast<llvm::BranchInst>(&I) != nullptr ||
            llvm::dyn_cast<llvm::ReturnInst>(&I) != nullptr ||
            llvm::dyn_cast<llvm::CallInst>(&I) != nullptr ||
            I.getNumOperands() == 0) {
          continue;
        }
        // llvm::errs() << "Instruction check: ";
        // I.print(llvm::errs());
        // llvm::errs() << "number of operands: " << I.getNumOperands();
        for (unsigned i = 0, e = I.getNumOperands(); i != e; ++i) {

          llvm::Value *v = I.getOperand(i);
          if (!v || llvm::dyn_cast<llvm::Constant>(v) != nullptr) {
            continue;
          }
          // v->print(llvm::errs());
          // llvm::errs() << "checking operand: \n";
          if (DI.isDivergent(v)) {
            any_divergent_var = true;
            goto divergent_found;
          }
        }
      }
      if (iter == exit) {
        break;
      }

      if (auto *BI = dyn_cast<BranchInst>(iter->getTerminator())) {
        if (BI->isConditional()) {
          // pick the “other” successor that isn’t the back‐edge
          BasicBlock *succ0 = BI->getSuccessor(0);
          BasicBlock *succ1 = BI->getSuccessor(1);
          
          // check if the successor is in the checked_blocks
          if (std::find(checked_blocks.begin(), checked_blocks.end(), succ0) ==
              checked_blocks.end()) {
            checked_blocks.push_back(succ0);
            iter = succ0;
          } else {
            checked_blocks.push_back(succ1);
            iter = succ1;
          }
        } else {
          iter = iter->getTerminator()->getSuccessor(0);
        }
      }
        
      // llvm::errs() << iter->getName().str() << "\n";
      // llvm::errs() << exit->getName().str() << "\n";
      // llvm::errs() << "iter, exit check--------------\n";

    } while (iter != exit);

    divergent_found:
    if (is_useless || !any_divergent_var) {
      return;
    }
    
    assert(current_region.wrapped_block.count(entry) != 0);
    current_region.start_block = entry;
    current_region.end_block = exit;
    current_region.successor_block = B;
    parallel_regions.push_back(current_region);
  }

  std::vector<ParallelRegion> getParallelRegions(llvm::Function *F,
                                                 bool intra_warp_loop,
                                                 CustomDivergenceAnalysis &DI) {
    std::vector<ParallelRegion> parallel_regions;

    SmallVector<BasicBlock *, 4> exit_blocks;
    for (Function::iterator s = F->begin(); s != F->end(); s++) {
      auto *firstInst = &*s->begin();
      if (s->getName().find("if.end_after_block_sync") != std::string::npos) {
        fprintf(stderr, "[exit] checking BB: %s, first_inst: ", s->getName().str().c_str());
        firstInst->print(llvm::errs());
        fprintf(stderr, "\n");
      }
      if (llvm::CallInst *call_inst =
              llvm::dyn_cast<llvm::CallInst>(firstInst)) {
        if (call_inst->isInlineAsm() || !call_inst->getCalledFunction())
          continue;
        auto func_name = call_inst->getCalledFunction()->getName().str();
        if (func_name == "llvm.nvvm.barrier0" ||
            func_name == "llvm.nvvm.barrier.sync") {
          fprintf(stderr, "[exit] found barrier at BB: %s\n", s->getName().str().c_str());
              // print the whole function(s)
              //printf("found the barrier in function (initial)");
              // call_inst->getParent()->getParent()->print(llvm::errs());
              
          exit_blocks.push_back(&(*s));
        }
        // when handling intra warp loop, we need also split the blocks
        // between warp barrier
        if (intra_warp_loop && isWarpSync(func_name)) {
          exit_blocks.push_back(&(*s));
        }

        // split the blocks between thread group barrier
        if (intra_warp_loop && isCGThreadGroupSync(func_name)) {
          exit_blocks.push_back(&(*s));
        }
      }
    }

    // First find all the ParallelRegions in the Function.
    while (!exit_blocks.empty()) {
      BasicBlock *exit = exit_blocks.back();
      exit_blocks.pop_back();
      getParallelRegionBefore(exit, intra_warp_loop, parallel_regions, DI); // exit=bb that has barrier at the beginning
    }
    return parallel_regions;
  }

  virtual bool runOnFunction(Function &F) {
    fprintf(stderr, "[ROF] runOnFunction: %s (isKernel=%d, intra_warp=%d)\n",
            F.getName().str().c_str(),
            isKernelFunction(F.getParent(), &F) ? 1 : 0,
            intra_warp_loop);
    if (!isKernelFunction(F.getParent(), &F))
      return 0;

    add_mapping_variable(&F, intra_warp_loop, need_nested_loop, schedule_flag);

    auto func_name = (&F)->getName().str();
    // clear context array, temp variables for new kernel function
    contextArrays.clear();
    tempInstructionIds.clear();
    tempInstructionIndex = 0;


    // get DivergenceInfo
    // Removed for LLVM 18 (No Divergence Analysis)
    /*
    auto DT = &getAnalysis<DominatorTreeWrapperPass>().getDomTree();
    auto PDT = &getAnalysis<PostDominatorTreeWrapperPass>().getPostDomTree();
    auto &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
    llvm::Triple triple("nvptx64-nvidia-cuda");
    std::string Error;
    const Target *TheTarget = TargetRegistry::lookupTarget("", triple, Error);
    llvm::TargetOptions Options;
    llvm::TargetMachine *target_machine = TheTarget->createTargetMachine(
        triple.getTriple(), "sm_35", "+ptx50", Options, llvm::Reloc::Static,
        llvm::CodeModel::Small, llvm::CodeGenOpt::Aggressive);

    llvm::FunctionAnalysisManager DummyFAM;
    llvm::TargetTransformInfo TTI =
        target_machine->getTargetIRAnalysis().run(F, DummyFAM); 
        */
    // DivergenceInfo DI(F, *DT, *PDT, LI, TTI, /*KnownReducible*/ true);

    CustomDivergenceAnalysis DI;
    auto DT = &getAnalysis<DominatorTreeWrapperPass>().getDomTree();
    auto PDT = &getAnalysis<PostDominatorTreeWrapperPass>().getPostDomTree();
    auto &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();

    DI.setAnalyzers(*DT, *PDT, LI);

    DI.analyze(F);

    // llvm::errs() << "FInal Divergent values are : \n";
    // for (auto value : DI.DivergentValues) {
    //   value->print(llvm::errs() << "\n");
    // }
    // llvm::errs() << "Done \n";

    // print all the DivergentValues

    // find parallel region we need to wrap
    // print Function name
    //printf("Function name: %s\n", func_name.c_str());
    // print function
    // F.print(llvm::errs());
    auto parallel_regions = getParallelRegions(&F, intra_warp_loop, DI);
    fprintf(stderr, "[warp_loop] %s: %zu parallel regions, intra_warp=%d\n",
            func_name.c_str(), parallel_regions.size(), intra_warp_loop);
    for (size_t r = 0; r < parallel_regions.size(); r++) {
      fprintf(stderr, "[warp_loop]   region %zu: %zu BBs [",
              r, parallel_regions[r].wrapped_block.size());
      for (auto *bb : parallel_regions[r].wrapped_block)
        fprintf(stderr, " %s", bb->getName().str().c_str());
      fprintf(stderr, " ]\n");
    }
    print_parallel_region(parallel_regions);
    // assert(!parallel_regions.empty() && "can not find any parallel regions\n");
    //printf("print parallel region done!\n");
    if (parallel_regions.empty()) {
      remove_barrier(&F, intra_warp_loop, schedule_flag);
      return 1;      
    }

    if (intra_warp_loop) {
      handle_local_variable_intra_warp(parallel_regions, DI, need_nested_loop);
    }
    // print function
    // llvm::errs() << "handle_local_variable_intra_warp: \n";
    // F.print(llvm::errs());

    add_warp_loop(parallel_regions, intra_warp_loop);
    remove_barrier(&F, intra_warp_loop, schedule_flag);

    return 1;
  }
};

char InsertWarpLoopPass::ID = 0;

namespace {
static RegisterPass<InsertWarpLoopPass> X("insert-warp-loop",
                                          "Insert inter/intra warp loop");
} // namespace

bool has_warp_barrier(llvm::Module *M) {
  for (auto F = M->begin(); F != M->end(); ++F)
    for (auto BB = F->begin(); BB != F->end(); ++BB) {
      for (auto BI = BB->begin(); BI != BB->end(); BI++) {
        if (auto Call = dyn_cast<CallInst>(BI)) {
          if (Call->isInlineAsm() || !Call->getCalledFunction())
            continue;
          auto func_name = Call->getCalledFunction()->getName().str();
          if (isWarpSync(func_name)) {
            return true;
          }
        }
      }
    }
  return false;
}


static bool has_warp_shfl_usage(llvm::Module *M) {
  for (const char *name : {"warp_shfl", "warp_shfl_i64"}) {
    if (auto *GV = M->getGlobalVariable(name)) {
      if (!GV->use_empty())
        return true;
    }
  }
  return false;
}

void insert_warp_loop(llvm::Module *M) {
  fprintf(stderr, "[IWL] insert_warp_loop called\n");
  llvm::legacy::PassManager Passes;
  need_nested_loop = has_warp_barrier(M) || has_cg_group_sync(M) || has_warp_shfl_usage(M);

  int schedule = 0;
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
    schedule = std::stoi(std::string(env));
  }

  int need_loop_serialize = (schedule != 2);

  fprintf(stderr, "[IWL] schedule=%d, need_loop_serialize=%d, need_nested_loop=%d\n",
          schedule, need_loop_serialize, need_nested_loop);
  //printf("SCHEDULE FLAG: %d\n", schedule);
  // no loop serialization performed for one on one mapping
  //printf("NEED LOOP SERIALIZE: %d\n", need_loop_serialize);
  // use nested loop only when there are warp-level barrier
  //printf("NEED NESTED LOOP: %d\n", need_nested_loop);

  if (need_loop_serialize) {
    if (need_nested_loop) {
      bool intra_warp = true;
      Passes.add(new InsertWarpLoopPass(intra_warp, schedule));
      // insert inter warp loop
      Passes.add(new InsertWarpLoopPass(!intra_warp, schedule));
      //printf("insert both intra and inter warp loop\n");
      Passes.run(*M);
    } else {
      bool intra_warp = true;
      // only need a single loop, with size=block_size
      Passes.add(new InsertWarpLoopPass(intra_warp, schedule));
      //printf("insert intra warp loop\n");
      Passes.run(*M);
    }
    // remove all barriers
    //printf("remove all barriers\n");
    for (auto F = M->begin(); F != M->end(); ++F)
      remove_barrier(dyn_cast<llvm::Function>(F), false, schedule);
  }
}
