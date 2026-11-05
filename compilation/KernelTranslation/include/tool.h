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
// trips: CUPBOP_VIRT_TRIPS=k (translation time, single-loop form with 32 lanes only): every warp loop runs
// exactly k passes (P*32*k >= block_size, checked by the host) so loops unroll and context arrays become
// registers. 0 = runtime trip count.
// trips_exact: CUPBOP_VIRT_TRIPS_EXACT=1 promises P*32*k == block_size (host aborts otherwise), so the per-pass
// index < block_size guard (a divergent split/join per region) is dropped.
struct VirtGeom { int schedule; int nt; int lanes; int subpasses; int lg_lanes; int trips; int trips_exact; };
VirtGeom getVirtGeom();
void VerifyModule(llvm::Module *);
void phi2alloc(llvm::Module *M);
void remove_cuda_built_in(llvm::Module *M);
void replace_built_in_function(llvm::Module *M);
void drop_cta_membar_at_barriers(llvm::Module *M);
void lower_named_barriers(llvm::Module *M);
// KMU CTA CSR reads instead of the legacy vx_spawn TLS copies (tool.cpp; CUPBOP_SREG_TLS=1 turns them off)
bool sreg_from_csr();
llvm::CallInst *read_cta_csr(llvm::IRBuilder<> &B, unsigned csr, const char *name);
// CUPBOP_FAST_ENTRY (tool.cpp, default 1; 0 = the previous entry path, same machine code): native-style kernel entry
// on the 1:1 schedule and the core mapping. fast_entry_on() is false on the flat schedule (0) whatever the variable says.
bool fast_entry_on();
// A CTA CSR read the Vortex backend takes as uniform (llvm.riscv.vx.uniform, what __UNIFORM__ in vx_spawn2.h becomes)
llvm::Value *read_cta_csr_uniform(llvm::IRBuilder<> &B, unsigned csr, const char *name);
// fast entry, core mapping: the kernel may read gridDim from the CTA CSRs (single-loop form, run-time trip count)
bool fast_entry_s1_grid_csr();
// fast entry, end of the translation: replace __vx_warps_per_group() calls by the CTA-size CSR, then find which
// launch constants the final module still reads and write that into kernel_wrapper.cpp (generate_wrapper.cpp)
void fast_entry_csr_runtime_calls(llvm::Module *M);
void inline_vx_barrier_calls(llvm::Module *M);
void merge_adjacent_barriers(llvm::Module *M);
void protect_dxa_operand_registers(llvm::Module *M); // CUPBOP_BAR_INLINE / CUPBOP_DXA_CLOBBER (uniform_branch.cpp)
void sign_extend_kernel_args(llvm::Module *M); // CUPBOP_ARG_SIGNEXT (uniform_branch.cpp)
void mark_uniform_branches(llvm::Module *M); // CUPBOP_UNIFORM_BR (uniform_branch.cpp)
void fast_entry_finalize_wrapper(llvm::Module *M);

void hoist_block_constant_loads(llvm::Module *M);
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
// kernel name as lookup.txt / the wrapper symbol carry it ("_Z<len>" of a mangled name dropped; extern "C" kept)
std::string cupbop_kernel_lookup_name(const std::string &name);
void replace_wmma_intrinsics(llvm::Module *M);
void replace_nvvm_wmma_intrinsics(llvm::Module *M);
void replace_nvvm_mma_intrinsics(llvm::Module *M);
// virt sub-pass form (S = 2, 16 lanes): one mma.sync call as replaceMmaStaged stages it. The glue symbols take the
// slots (a, b, c, d): <sw>_sw_glue16 is the software glue (every form), <tcu>_glue16 the NT=16 TCU glue (f16/bf16 only,
// empty otherwise). Half shapes run on the m16n8k16 TCU tile with the missing registers zero (pad).
struct MmaSubpassForm {
  std::string sw, tcu;
  int nA = 0, nB = 0, nC = 0; // operand registers of the call
  bool f64 = false;           // operands and accumulators are doubles: two 32-bit words per register
  bool pad = false;
};
bool mma_subpass_form(const std::string &name, unsigned nargs, MmaSubpassForm &f, std::string &err);
void replace_cp_async_with_dxa(llvm::Module *M);
void mark_virt_lane_divergence(llvm::Module *M); // schedule 1 (virt): lane-index loads are divergent
#endif
