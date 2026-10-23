#ifndef __NVVM2x86_TOOL__
#define __NVVM2x86_TOOL__

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include <cstdlib>

inline bool cupbop_debug() {
  static bool enabled = (std::getenv("CUPBOP_DEBUG") != nullptr);
  return enabled;
}
llvm::Module *LoadModuleFromFilr(char *file_name);
void DumpModule(llvm::Module *M, char *file_name);
bool isKernelFunction(llvm::Module *M, llvm::Function *F);
void normalize_ptx_kernel_cc(llvm::Module *M);
void replace_block(llvm::Function *F, llvm::BasicBlock *before,
                   llvm::BasicBlock *after);
llvm::CallInst *CreateInterWarpBarrier(llvm::Instruction *InsertBefore);
llvm::CallInst *CreateIntraWarpBarrier(llvm::Instruction *InsertBefore);
// Core mapping (virt) geometry known at translation time: hardware NT
// (VORTEX_NUM_THREADS, exported by the example makefile), lanes per warp used
// (CUPBOP_VIRT_LANES, lane gating; at most 32) and the number of sub-passes a
// 32-lane CUDA warp needs on them (32/L). The kernel IR is therefore per NT.
struct VirtGeom { int schedule; int nt; int lanes; int subpasses; int lg_lanes; };
VirtGeom getVirtGeom();
void VerifyModule(llvm::Module *);
void phi2alloc(llvm::Module *M);
void remove_cuda_built_in(llvm::Module *M);
void replace_built_in_function(llvm::Module *M);
void replace_warp_shfl_early(llvm::Module *M);
void lower_cmpxchg_for_flat(llvm::Module *M);
void lower_atomicrmw_fadd(llvm::Module *M);
void lower_atomicrmw_add_i64(llvm::Module *M);
void replace_asm_call(llvm::Module *M);
bool find_block_barrier_in_region(llvm::BasicBlock *start,
                                  llvm::BasicBlock *end);
bool find_barrier_in_region(llvm::BasicBlock *start, llvm::BasicBlock *end);
bool has_warp_barrier(llvm::BasicBlock *B);
bool has_barrier(llvm::BasicBlock *B);
bool has_block_barrier(llvm::BasicBlock *B);
bool has_barrier(llvm::Function *F);
void replace_dynamic_shared_memory(llvm::Module *M);
llvm::LoadInst *createLoad(llvm::IRBuilder<> &B, llvm::Value *addr,
                           bool isVolatile = false);
llvm::Value *createInBoundsGEP(llvm::IRBuilder<> &B, llvm::Value *ptr,
                               llvm::ArrayRef<llvm::Value *> idxlist);
llvm::Value *createGEP(llvm::IRBuilder<> &B, llvm::Value *ptr,
                       llvm::ArrayRef<llvm::Value *> idxlist);
void printIR(llvm::Module *module_);
bool triton_cupbop_enabled();
void replace_wmma_intrinsics(llvm::Module *M);
void replace_nvvm_wmma_intrinsics(llvm::Module *M);
void replace_nvvm_mma_intrinsics(llvm::Module *M);
void replace_cp_async_with_dxa(llvm::Module *M);
void mark_virt_lane_divergence(llvm::Module *M); // schedule 1 (virt): lane-index loads are divergent
#endif
