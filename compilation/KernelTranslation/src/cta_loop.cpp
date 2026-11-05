// CUPBOP_CTA_LOOP (default off; 2026-11-04, experiments/ctaloop). One hardware CTA runs several CUDA blocks, so that the
// per-warp cost of a CTA (the KMU's dispatch, the entry window, kernel_main, the arguments, every value that only depends
// on the launch) is paid once per hardware CTA instead of once per CUDA block.
//
//   off / 0   the previous translation, byte for byte
//   x, y, z   the wrapper walks the grid in a nest of cyclic loops, one per grid dimension the kernel reads, the given one
//             innermost: hardware CTA (hx, hy, hz) of a launched grid (nx, ny, nz) runs the blocks hx + i nx, hy + j ny,
//             hz + k nz. The host chooses the launched grid at each launch (cudaRuntimeImpl.cpp cupbop_cta_loop_launch)
//   auto      the innermost dimension from cta_loop_pick_dim
// CUPBOP_CTA_LOOP_CALL=1 keeps the kernel a separate function: what the loop alone is worth, without the optimizer seeing
// the kernel inside the loop. Otherwise the kernel is inlined into the wrapper's loop: everything that does not depend on
// the block index leaves the loop.
//
// What changes in the kernel: blockIdx and gridDim stop being the CTA CSRs (they now describe the hardware grid) and become
// arguments of a copy of the kernel. The wrapper reads the CUDA grid from ctx.num_groups, which the host fills as before, and
// whether this launch loops from a context word the device never used otherwise (cudaRuntimeImpl.cpp cupbop_cta_loop_launch).
//
// A launch that does not pay (few blocks) takes the old code. A kernel that cannot be looped keeps its translation and gets
// no mark; cupbop_launch_fix.txt is what tells the host that this kernel has the loop.
//
// When it is legal (cta_loop_refusal): CUDA gives no order and no co-residency between the blocks of a grid, except what
// programs assume anyway:
//  * grid-wide sync, clusters: refused;
//  * a block waiting for another block: a loop that keeps reading one address until it changes. With the original launch
//    the block it waits for may be running; here it may be queued behind the waiter on the same hardware CTA. Refused
//    (the rule is syntactic: an exit condition that hangs on a load or atomic at a loop-invariant address, with no induction
//    variable in it: `while (flag == 0)`, not `for (i = 0; i < *n; ++i)`);
//  * mbarrier / TMA / bulk copies: refused for now, their state lives across a block's end in the DXA unit;
//  * shared memory: blocks that share a slot in time must not overlap, so the loop gets a CTA barrier between two blocks
//    when the kernel touches local memory. A kernel without it has none: its warps run ahead independently. Every warp of
//    a CTA makes the same trips (the bound depends on the CTA only), so the number of barriers per warp stays equal among
//    the warps, which is what a hardware barrier counts; CUDA leaves shared memory undefined at a block's start, so nothing
//    legal reads the previous block's values.
#include "cta_loop.h"
#include "generate_wrapper.h"
#include "stable_order.h"
#include "launch_fix.h"
#include "tool.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/IntrinsicsRISCV.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include <memory>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <map>
#include <set>
#include <string>

using namespace llvm;

const std::vector<std::pair<std::string, std::string>> &kabi_kernel_list();   // generate_wrapper.cpp: (kernel, wrapper)
void kabi_add_wrapper(const std::string &wrapper);                            // generate_wrapper.cpp

namespace {
enum Mode { M_OFF = 0, M_X = 1, M_Y = 2, M_Z = 3, M_AUTO = 4 };
const unsigned CSR_CTA_ID = 0xCD0, CSR_CTA_SIZE = 0xCD2, CSR_BLOCK_ID = 0xCD6, CSR_GRID_DIM = 0xCDC;
// offsets from the wrapper's argument (kernel_arg_t.args) back into kernel_arg_t.ctx, generate_wrapper.cpp context_t
const int ARGS_FROM_CTX = 72, CTX_NUM_GROUPS = 0, CTX_LOOP_PARAMS = 48;

std::vector<std::pair<std::string, std::string>> loop_wrappers;   // (wrapper, its copy with the loop)

Mode cta_loop_mode() {
  const char *e = std::getenv("CUPBOP_CTA_LOOP");
  if (!e || !*e || !std::strcmp(e, "0") || !std::strcmp(e, "off")) return M_OFF;
  if (!std::strcmp(e, "x")) return M_X;
  if (!std::strcmp(e, "y")) return M_Y;
  if (!std::strcmp(e, "z")) return M_Z;
  if (!std::strcmp(e, "auto")) return M_AUTO;
  std::fprintf(stderr, "kernelTranslator: CUPBOP_CTA_LOOP=%s: expected x, y, z, auto or off\n", e);
  std::exit(1);
}
bool report() { return cupbop_debug() || std::getenv("CUPBOP_CTA_LOOP_REPORT"); }
// CUPBOP_CTA_LOOP_NEG=skip|nobar: negative controls, the conformance tests must fail with these (experiments/ctaloop)
bool neg_control(const char *what) { const char *e = std::getenv("CUPBOP_CTA_LOOP_NEG"); return e && !std::strcmp(e, what); }

// the CSR an asm "csrr $0, 0x..." reads, else -1
int csr_of(const CallBase *C) {
  auto *IA = dyn_cast<InlineAsm>(C->getCalledOperand());
  if (!IA) return -1;
  unsigned csr = 0;
  if (std::sscanf(IA->getAsmString().c_str(), "csrr $0, 0x%x", &csr) != 1) return -1;
  return (int)csr;
}
bool is_block_or_grid_csr(int c) {
  return (c >= (int)CSR_BLOCK_ID && c < (int)CSR_BLOCK_ID + 3) || (c >= (int)CSR_GRID_DIM && c < (int)CSR_GRID_DIM + 3);
}

using FunctionList = SetVector<Function *>;   // insertion order: the walk below must not depend on heap addresses (stable_order.h)
void reachable(Function *F, FunctionList &out) {
  if (!F || F->isDeclaration() || !out.insert(F)) return;
  for (auto &BB : *F)
    for (auto &I : BB)
      if (auto *C = dyn_cast<CallBase>(&I)) reachable(C->getCalledFunction(), out);
}

bool uses_local_memory(const FunctionList &fs) {
  for (Function *F : fs)
    for (auto &BB : *F)
      for (auto &I : BB) {
        if (auto *C = dyn_cast<CallBase>(&I))
          if (Function *G = C->getCalledFunction())
            if (G->getName().contains("vx_local_alloc")) return true;
        for (Value *Op : I.operands())
          if (auto *P = dyn_cast<PointerType>(Op->getType()))
            if (P->getAddressSpace() == 3) return true;
      }
  return false;
}

// V has the same value in every iteration of L: outside it, or pure arithmetic on such values, or a read of a CSR
bool invariant_expr(const Value *V, const Loop *L, unsigned depth = 0) {
  auto *I = dyn_cast<Instruction>(V);
  if (!I || !L->contains(I)) return true;
  if (depth > 32 || isa<PHINode>(I) || I->mayReadOrWriteMemory() || I->mayHaveSideEffects()) {
    if (auto *C = dyn_cast<CallBase>(I))
      if (csr_of(C) >= 0) return true;
    return false;
  }
  for (const Value *Op : I->operands())
    if (!invariant_expr(Op, L, depth + 1)) return false;
  return true;
}

// an exit of a loop that depends on a load or atomic at a loop-invariant, non-private address
bool spin_loop(Function *F, std::string &where) {
  DominatorTree DT(*F);
  LoopInfo LI(DT);
  for (Loop *Top : LI)
    for (Loop *L : depth_first(Top)) {
      SmallVector<BasicBlock *, 8> exits;
      L->getExitingBlocks(exits);
      for (BasicBlock *B : exits) {
        auto *Br = dyn_cast<BranchInst>(B->getTerminator());
        if (!Br || !Br->isConditional()) continue;
        std::set<Value *> seen;   // membership only
        SmallVector<Value *, 16> work{Br->getCondition()};
        bool counted = false, waits = false;
        std::string what;
        while (!work.empty()) {
          Value *V = work.pop_back_val();
          auto *I = dyn_cast<Instruction>(V);
          if (!I || !L->contains(I) || !seen.insert(V).second) continue;
          if (isa<PHINode>(I)) { counted = true; continue; }   // an induction variable: this exit counts, it does not wait (bfs reloads its bound)
          Value *Ptr = nullptr;
          if (auto *Ld = dyn_cast<LoadInst>(I)) Ptr = Ld->getPointerOperand();
          else if (auto *A = dyn_cast<AtomicRMWInst>(I)) Ptr = A->getPointerOperand();
          else if (auto *A = dyn_cast<AtomicCmpXchgInst>(I)) Ptr = A->getPointerOperand();
          if (Ptr) {
            const Value *O = getUnderlyingObject(Ptr);
            // private memory, and the CTA's own local memory: a wait on it is a wait inside the block
            const bool priv = isa<AllocaInst>(O) || Ptr->getType()->getPointerAddressSpace() == 3;
            auto *G = dyn_cast<GlobalVariable>(O);
            if (!priv && !(G && G->isConstant()) && invariant_expr(Ptr, L)) {
              raw_string_ostream os(what); I->print(os);
              waits = true;
            }
            continue;
          }
          for (Value *Op : I->operands()) work.push_back(Op);
        }
        if (waits && !counted) { where = "loop at " + B->getName().str() + " waits on" + what; return true; }
      }
    }
  return false;
}

std::string cta_loop_refusal(const FunctionList &fs, Function *K) {
  {   // async_ptx: kernels with mbarrier waits, TMA or bulk copies
    std::ifstream af("cupbop_async_kernels.txt");
    std::string n;
    while (af >> n)
      if (n == K->getName() || n == cupbop_kernel_lookup_name(K->getName().str())) return "mbarrier, TMA or bulk copies";
  }
  for (Function *F : fs) {
    for (auto &BB : *F)
      for (auto &I : BB) {
        auto *C = dyn_cast<CallBase>(&I);
        if (!C) continue;
        Function *G = C->getCalledFunction();
        const std::string n = G ? G->getName().str() : "";
        // cooperative groups at grid level (block-level ones became barriers)
        if ((n.find("grid") != std::string::npos && n.find("sync") != std::string::npos) || n.find("grid_group") != std::string::npos || n.find("this_grid") != std::string::npos ||
            n.find("cudaCG") != std::string::npos)
          return "grid sync (" + n + ")";
        if (n.find("cluster") != std::string::npos) return "cluster (" + n + ")";
        if (n.find("mbarrier") != std::string::npos || n.find("__cupbop_tma") != std::string::npos || n.find("cp_async_bulk") != std::string::npos ||
            n.find("vx_dxa") != std::string::npos || n.find("cupbop_dxa") != std::string::npos)
          return "mbarrier, TMA or DXA (" + n + ")";
      }
    std::string w;
    if (spin_loop(F, w)) return w + " in " + F->getName().str();
  }
  return "";
}

// inline the functions (other than the kernel) that read the CTA's block or grid CSRs: only the kernel gets the arguments
bool inline_block_readers(Function *K) {
  for (int round = 0; round < 16; ++round) {
    FunctionList fs;
    reachable(K, fs);
    std::set<Function *> readers;   // membership only
    for (Function *F : fs) {
      if (F == K) continue;
      for (auto &BB : *F)
        for (auto &I : BB)
          if (auto *C = dyn_cast<CallBase>(&I))
            if (is_block_or_grid_csr(csr_of(C))) readers.insert(F);
    }
    if (readers.empty()) return true;
    bool any = false;
    for (Function *F : fs) {
      std::vector<CallBase *> calls;
      for (auto &BB : *F)
        for (auto &I : BB)
          if (auto *C = dyn_cast<CallBase>(&I))
            if (readers.count(C->getCalledFunction()) && C->getCalledFunction() != F) calls.push_back(C);
      for (CallBase *C : calls) {
        InlineFunctionInfo IFI;
        if (InlineFunction(*C, IFI).isSuccess()) any = true;
      }
    }
    if (!any) return false;
  }
  return false;
}

Value *uniform_i32(IRBuilder<> &B, Value *V, const char *name) {
  Function *U = Intrinsic::getDeclaration(B.GetInsertBlock()->getModule(), Intrinsic::riscv_vx_uniform, {B.getInt32Ty(), B.getInt32Ty()});
  return B.CreateCall(U, {V}, name);
}
Value *uniform_i1(IRBuilder<> &B, Value *V, const char *name) {
  Function *U = Intrinsic::getDeclaration(B.GetInsertBlock()->getModule(), Intrinsic::riscv_vx_uniform, {B.getInt1Ty(), B.getInt1Ty()});
  return B.CreateCall(U, {V}, name);
}
Value *ctx_word(IRBuilder<> &B, Value *Args, int off, const char *name) {
  Value *P = B.CreateConstGEP1_64(B.getInt8Ty(), Args, off - ARGS_FROM_CTX);
  return uniform_i32(B, B.CreateAlignedLoad(B.getInt32Ty(), P, Align(4), std::string(name) + ".ld"), name);
}
// CTA barrier as the 1:1 and core-mapping translations emit it (tool.cpp, insert_warp_loop.cpp)
void cta_barrier(IRBuilder<> &B, Module *M) {
  LLVMContext &C = M->getContext();
  FunctionCallee Bar = M->getOrInsertFunction("vx_barrier", FunctionType::get(Type::getVoidTy(C), {B.getInt32Ty(), B.getInt32Ty()}, false));
  Value *id = read_cta_csr(B, CSR_CTA_ID, "cta_id"), *n = read_cta_csr(B, CSR_CTA_SIZE, "cta_warps");
  CallInst *S = B.CreateCall(Bar, {id, n});
  S->addFnAttr(Attribute::Convergent);
  cast<Function>(Bar.getCallee())->addFnAttr(Attribute::Convergent);
  S->setMetadata("divergence", MDNode::get(C, MDString::get(C, "divergence")));
}

// K(args...) -> K(args..., bx, by, bz, gx, gy, gz): the reads of the CTA's block and grid CSRs become the new arguments
Function *with_block_args(Function *K) {
  Module *M = K->getParent();
  LLVMContext &C = M->getContext();
  std::vector<Type *> params(K->getFunctionType()->param_begin(), K->getFunctionType()->param_end());
  const unsigned n0 = params.size();
  for (int i = 0; i < 6; ++i) params.push_back(Type::getInt32Ty(C));
  auto *NF = Function::Create(FunctionType::get(K->getReturnType(), params, false), K->getLinkage(), "", M);
  NF->copyAttributesFrom(K);
  ValueToValueMapTy VM;
  auto NA = NF->arg_begin();
  for (auto &A : K->args()) { NA->setName(A.getName()); VM[&A] = &*NA; ++NA; }
  SmallVector<ReturnInst *, 4> rets;
  CloneFunctionInto(NF, K, VM, CloneFunctionChangeType::LocalChangesOnly, rets);
  std::vector<CallBase *> reads;
  for (auto &BB : *NF)
    for (auto &I : BB)
      if (auto *Ci = dyn_cast<CallBase>(&I))
        if (is_block_or_grid_csr(csr_of(Ci))) reads.push_back(Ci);
  for (CallBase *R : reads) {
    const int c = csr_of(R);
    const unsigned idx = c >= (int)CSR_GRID_DIM ? 3 + (c - CSR_GRID_DIM) : (c - CSR_BLOCK_ID);
    R->replaceAllUsesWith(NF->getArg(n0 + idx));
    R->eraseFromParent();
  }
  static const char *const names[6] = {"cta.bx", "cta.by", "cta.bz", "cta.gx", "cta.gy", "cta.gz"};
  for (int i = 0; i < 6; ++i) NF->getArg(n0 + i)->setName(names[i]);
  return NF;
}

// CUPBOP_CTA_LOOP=auto: the innermost dimension is the highest one the kernel reads. A rule of thumb: the rule of the store's smallest
// stride, proposed by seed/transpose, is not implemented. Both directions measured on 2D grids (experiments/ctaloop m10): transpose y
// -48.6%, x +2.2%; sgeam y -16.5%, x -18.9%; sger y -10.0%, x -6.6%; conv3, hotspot, g32, hgemm within 0.5 points of each other.
int cta_loop_pick_dim(unsigned dims) { return dims & 4 ? 2 : dims & 2 ? 1 : 0; }

unsigned block_dims_read(Function *K) {
  unsigned dims = 0;
  for (auto &BB : *K)
    for (auto &I : BB)
      if (auto *C = dyn_cast<CallBase>(&I)) {
        const int c = csr_of(C);
        if (c >= (int)CSR_BLOCK_ID && c < (int)CSR_BLOCK_ID + 3) dims |= 1u << (c - CSR_BLOCK_ID);
      }
  return dims;
}

void build_loop(Module *M, Function *K, Function *W0, int inner, unsigned dims, bool barrier, bool call_mode) {
  LLVMContext &C = M->getContext();
  // The wrapper stays as it was, so a launch without a loop runs the old code; kernel_main takes the copy of the wrapper when the
  // host's word in the context says so (cta_loop_finalize_wrapper). A branch inside the wrapper would not do: the wrapper then
  // needs a frame, which moves the kernel's frame (conv +16% on a launch that never loops: the stack's L2 sets), and the backend
  // does not tail-call here. The copy calls a copy of the kernel that takes the block index as arguments.
  ValueToValueMapTy VM0;
  Function *W = CloneFunction(W0, VM0);
  W->setName(W0->getName() + "_cta_loop");
  W->setLinkage(GlobalValue::ExternalLinkage);
  loop_wrappers.push_back({W0->getName().str(), W->getName().str()});
  kabi_add_wrapper(W->getName().str());
  CallInst *Call = nullptr;
  for (auto &BB : *W)
    for (auto &I : BB)
      if (auto *CI = dyn_cast<CallInst>(&I))
        if (CI->getCalledFunction() == K) Call = CI;
  if (!Call || !isa<ReturnInst>(Call->getNextNode())) { std::fprintf(stderr, "kernelTranslator: CUPBOP_CTA_LOOP: unexpected wrapper %s\n", W0->getName().str().c_str()); std::exit(1); }

  Function *NK = with_block_args(K);
  NK->setName(K->getName() + ".cta");
  BasicBlock *Entry = Call->getParent();
  Value *Args = W->getArg(0);
  std::vector<Value *> callargs(Call->arg_begin(), Call->arg_end());
  Instruction *Ret = Call->getNextNode();
  IRBuilder<> B(Call);
  // per dimension: blocks start, start + step, ... below end. Cyclic: start = hw, step = launched extent, end = grid; a launch of
  // the whole grid makes one trip. CUPBOP_CTA_LOOP_CHUNK=1 (measurement): context word k != 0 runs k neighbours instead.
  const bool chunk_mode = std::getenv("CUPBOP_CTA_LOOP_CHUNK") && std::atoi(std::getenv("CUPBOP_CTA_LOOP_CHUNK"));
  Value *g[3], *hw[3], *st[3] = {}, *step[3] = {}, *end[3] = {};
  for (int i = 0; i < 3; ++i) g[i] = ctx_word(B, Args, CTX_NUM_GROUPS + 4 * i, "cta.g");
  for (int i = 0; i < 3; ++i) hw[i] = uniform_i32(B, read_cta_csr(B, CSR_BLOCK_ID + i, "cta.hw.ld"), "cta.hw");
  for (int i = 0; i < 3; ++i) {
    if (!(dims >> i & 1)) continue;
    Value *nd = uniform_i32(B, read_cta_csr(B, CSR_GRID_DIM + i, "cta.n.ld"), "cta.n");
    st[i] = hw[i]; step[i] = nd; end[i] = g[i];
    if (i == inner && neg_control("skip")) step[i] = B.CreateAdd(nd, B.getInt32(1));   // skips blocks: the checks must see it
    if (chunk_mode) {
      Value *k = ctx_word(B, Args, CTX_LOOP_PARAMS + 4 * i, "cta.k");
      Value *chunk = B.CreateICmpNE(k, B.getInt32(0));
      Value *s0 = B.CreateSelect(chunk, B.CreateMul(hw[i], k), hw[i]);
      Value *e0 = B.CreateAdd(s0, k);
      Value *e1 = B.CreateSelect(B.CreateICmpULT(e0, g[i]), e0, g[i]);
      st[i] = uniform_i32(B, s0, "cta.s");
      step[i] = uniform_i32(B, B.CreateSelect(chunk, B.getInt32(1), nd), "cta.step");
      end[i] = uniform_i32(B, B.CreateSelect(chunk, e1, g[i]), "cta.e");
    }
  }

  // nest: the other dimensions outside (higher first), `inner` innermost
  Call->eraseFromParent();
  Ret->eraseFromParent();
  B.SetInsertPoint(Entry);
  std::vector<int> order;
  for (int i = 2; i >= 0; --i)
    if ((dims >> i & 1) && i != inner) order.push_back(i);
  order.push_back(inner);
  Value *v[3] = {hw[0], hw[1], hw[2]};
  std::map<int, PHINode *> phi;
  std::map<int, BasicBlock *> head;
  BasicBlock *prev = Entry;
  for (int d : order) {
    BasicBlock *H = BasicBlock::Create(C, "cta.head", W);
    B.CreateBr(H);
    B.SetInsertPoint(H);
    PHINode *P = B.CreatePHI(B.getInt32Ty(), 2, "cta.b");
    P->addIncoming(st[d], prev);
    phi[d] = P; head[d] = H; v[d] = P; prev = H;
  }
  std::vector<Value *> a = callargs;
  a.insert(a.end(), {v[0], v[1], v[2], g[0], g[1], g[2]});
  B.CreateCall(NK, a);
  if (barrier) cta_barrier(B, M);
  for (auto it = order.rbegin(); it != order.rend(); ++it) {
    const int d = *it;
    Value *c1 = B.CreateAdd(phi[d], step[d]);
    Value *more = uniform_i1(B, B.CreateICmpULT(c1, end[d]), "cta.more");
    Value *nc = uniform_i32(B, c1, "cta.nc");
    BasicBlock *Latch = B.GetInsertBlock(), *Next = BasicBlock::Create(C, "cta.next", W);
    B.CreateCondBr(more, head[d], Next);
    phi[d]->addIncoming(nc, Latch);
    B.SetInsertPoint(Next);
  }
  B.CreateRetVoid();

  if (call_mode) {
    NK->removeFnAttr(Attribute::AlwaysInline);
    NK->addFnAttr(Attribute::NoInline);
  } else {
    NK->removeFnAttr(Attribute::NoInline);
    NK->addFnAttr(Attribute::AlwaysInline);
  }
  NK->setLinkage(GlobalValue::InternalLinkage);
}
} // namespace

void cta_loop_transform(Module *M) {
  const Mode mode = cta_loop_mode();
  if (mode == M_OFF) return;
  const char *s = std::getenv("VORTEX_SCHEDULE_FLAG");
  const int sched = s ? std::atoi(s) : 0;
  if (sched != 1 && sched != 2) return;
  if (!sreg_from_csr() || !fast_entry_on()) { std::fprintf(stderr, "[CuPBoP] CUPBOP_CTA_LOOP needs the CTA CSR reads (CUPBOP_SREG_TLS or CUPBOP_FAST_ENTRY=0 is set): off\n"); return; }
  const bool call_mode = std::getenv("CUPBOP_CTA_LOOP_CALL") && std::atoi(std::getenv("CUPBOP_CTA_LOOP_CALL"));
  // Legality is read from an optimized copy of the module: a CUDA source kernel has its values in allocas and its atomics
  // behind calls here, and a wait would hide behind them.
  std::unique_ptr<Module> Copy = CloneModule(*M);
  {
    PassBuilder PB;
    LoopAnalysisManager LAM; FunctionAnalysisManager FAM; CGSCCAnalysisManager CGAM; ModuleAnalysisManager MAM;
    PB.registerModuleAnalyses(MAM); PB.registerCGSCCAnalyses(CGAM); PB.registerFunctionAnalyses(FAM); PB.registerLoopAnalyses(LAM);
    PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);
    ModulePassManager MPM = PB.buildPerModuleDefaultPipeline(OptimizationLevel::O1);
    MPM.run(*Copy, MAM);
  }
  const auto kernels = kabi_kernel_list();   // a copy: build_loop adds to the list
  for (auto &kw : kernels) {
    Function *K = M->getFunction(kw.first), *W = M->getFunction(kw.second);
    if (!K || !W || W->isDeclaration()) continue;
    const std::string lookup = cupbop_kernel_lookup_name(kw.first);
    if (!inline_block_readers(K)) { std::fprintf(stderr, "[CuPBoP] cta_loop: %s: refused: a function reads blockIdx and cannot be inlined\n", lookup.c_str()); continue; }
    FunctionList fs, cfs;
    reachable(K, fs);
    Function *CK = Copy->getFunction(kw.first);
    reachable(CK, cfs);
    const std::string why = CK ? cta_loop_refusal(cfs, CK) : std::string();
    if (!why.empty()) { std::fprintf(stderr, "[CuPBoP] cta_loop: %s: refused: %s\n", lookup.c_str(), why.c_str()); continue; }
    const bool lmem = !neg_control("nobar") && (uses_local_memory(fs) || (std::getenv("CUPBOP_CTA_LOOP_SYNC") && std::atoi(std::getenv("CUPBOP_CTA_LOOP_SYNC"))));
    const unsigned dims = block_dims_read(K);
    if (!dims) { std::fprintf(stderr, "[CuPBoP] cta_loop: %s: refused: reads no block index\n", lookup.c_str()); continue; }
    int inner = mode == M_AUTO ? cta_loop_pick_dim(dims) : mode - M_X;
    if (!(dims >> inner & 1)) inner = cta_loop_pick_dim(dims);
    build_loop(M, K, W, inner, dims, lmem, call_mode);
    launch_fix_note(M, lookup, "cta_inner", (uint64_t)inner);
    launch_fix_note(M, lookup, "cta_dims", (uint64_t)dims);
    if (std::getenv("CUPBOP_CTA_LOOP_CHUNK") && std::atoi(std::getenv("CUPBOP_CTA_LOOP_CHUNK"))) launch_fix_note(M, lookup, "cta_chunk", 1);
    if (report()) std::fprintf(stderr, "[CuPBoP] cta_loop: %s: dims %u, inner %d, %s, %s\n", lookup.c_str(), dims, inner, lmem ? "barrier between blocks" : "no barrier", call_mode ? "call" : "inline");
  }
}

// kernel_wrapper.cpp was written before the loops existed: kernel_main calls the copy of the wrapper when the context word is set.
void cta_loop_finalize_wrapper() {
  if (loop_wrappers.empty()) return;
  std::ifstream in("kernel_wrapper.cpp");
  if (!in) { std::fprintf(stderr, "kernelTranslator: CUPBOP_CTA_LOOP: no kernel_wrapper.cpp\n"); std::exit(1); }
  std::string s((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
  in.close();
  const size_t t0 = s.find("vx_kernel_func_cb callbacks[] = {"), t1 = t0 == std::string::npos ? t0 : s.find("};", t0);
  if (t1 == std::string::npos) { std::fprintf(stderr, "kernelTranslator: CUPBOP_CTA_LOOP: no callbacks table\n"); std::exit(1); }
  std::string decl, table = s.substr(t0, t1 + 2 - t0);
  table.replace(0, std::strlen("vx_kernel_func_cb callbacks"), "static vx_kernel_func_cb __cupbop_loop_callbacks");
  auto swap_all = [](std::string &t, const std::string &a, const std::string &b) {
    for (size_t p = t.find(a); p != std::string::npos; p = t.find(a, p + b.size())) t.replace(p, a.size(), b);
  };
  for (auto &w : loop_wrappers) {
    decl += "extern \"C\" void " + w.second + "(void *);\n";
    swap_all(table, "(vx_kernel_func_cb)" + w.first + ",", "(vx_kernel_func_cb)" + w.second + ",");
    swap_all(table, "cuda_" + w.first + ",", "(vx_kernel_func_cb)" + w.second + ",");
  }
  const size_t m = s.find("void kernel_main(kernel_arg_t");
  if (m == std::string::npos) { std::fprintf(stderr, "kernelTranslator: CUPBOP_CTA_LOOP: no kernel_main\n"); std::exit(1); }
  size_t a = std::string::npos, e = std::string::npos;
  for (const char *pre : {"__cupbop_kcall(", "__cupbop_kcall_lmem(ctx, ", "__cupbop_call_kernel("}) {
    const size_t p = s.find(pre, m);
    if (p != std::string::npos) { a = p + std::strlen(pre); e = s.find(", (void *)args", a); break; }
  }
  if (e == std::string::npos) { std::fprintf(stderr, "kernelTranslator: CUPBOP_CTA_LOOP: no kernel call in kernel_main\n"); std::exit(1); }
  const std::string fn = s.substr(a, e - a);
  const std::string loop = fn.find("kernel_idx") != std::string::npos ? "__cupbop_loop_callbacks[kernel_arg->kernel_idx]" : "(vx_kernel_func_cb)" + loop_wrappers[0].second;
  // two calls rather than a selected pointer: the launches that do not loop pay a load and a branch
  const size_t l0 = s.rfind('\n', a) + 1, l1 = s.find('\n', e);
  std::string call = s.substr(l0, l1 - l0), lcall = call;
  lcall.replace(a - l0, e - a, loop);
  s.replace(l0, l1 - l0, "    if (ctx->printf_buffer) {\n    " + lcall + "\n    } else {\n    " + call + "\n    }");
  s.insert(t1 + 2, "\n// CUPBOP_CTA_LOOP: the wrappers with the block loop (cta_loop.cpp)\n" + decl + table + "\n");
  std::ofstream("kernel_wrapper.cpp", std::ios::trunc) << s;
}

// CUPBOP_CTA_EMPTY=1 (default off; 2026-11-04, experiments/ctaloop): a block whose every thread fails the kernel's range guard
// skips the kernel. cuBLAS asum and nrm2 launch 1024 blocks for n = 1024: 1020 blocks have no element, and each still runs the
// tree reduction of zeros and stores the zero.
//
// Find guards `blockIdx * blockDim + threadIdx >= v` (v the same value in the whole CTA). With t = blockIdx * blockDim, the CTA
// condition U: t >= v, t + blockDim does not wrap, makes every such guard true for all threads. A copy of the kernel with the
// guards folded is what the block does under U. What remains has to be proved to be nothing but constants:
//  * all stores to local memory write the same constant e; assume that loads from local memory give e, fold, and check the
//    stores again (this is the identity: f(e, e) = e for the block's reduction, found by constant folding, whichever f is);
//  * a load of a local-memory word that no thread of the block wrote would have read garbage in the original: not legal code;
//  * nothing else reads memory: no global load and no atomic remains. The local-memory traffic and the barriers then go.
// Only for kernels that read gridDim on that dimension (grid-stride): others size the grid to the data and have no empty block.
// If any of this fails the kernel stays as it was. The kernel gets `if (U) { copy; return; }` at its entry. U is CTA-uniform, so
// barriers stay uniform.
namespace {
using namespace llvm::PatternMatch;
bool is_sreg(Value *V, const char *reg, int &dim) {
  auto *C = dyn_cast<CallInst>(V);
  Function *F = C ? C->getCalledFunction() : nullptr;
  if (!F) return false;
  std::string n = F->getName().str(), pre = std::string("llvm.nvvm.read.ptx.sreg.") + reg + ".";
  if (n.rfind(pre, 0) != 0 || n.size() != pre.size() + 1) return false;
  const int d = n.back() - 'x';
  if (d < 0 || d > 2 || (dim >= 0 && dim != d)) return false;
  dim = d;
  return true;
}
Value *strip_ext(Value *V) {
  while (isa<ZExtInst>(V) || isa<TruncInst>(V)) V = cast<Instruction>(V)->getOperand(0);
  return V;
}
// V depends only on blockIdx.d, blockDim.d and constants
bool block_base(Value *V, int &d) {
  if (isa<ConstantInt>(V)) return true;
  int dd = d;
  if (is_sreg(V, "ctaid", dd) || is_sreg(V, "ntid", dd)) { d = dd; return true; }
  auto *I = dyn_cast<Instruction>(V);
  if (!I) return false;
  if (isa<ZExtInst>(I) || isa<TruncInst>(I)) return block_base(I->getOperand(0), d);
  switch (I->getOpcode()) {
    case Instruction::Add: case Instruction::Mul: case Instruction::Shl: case Instruction::And:
      return block_base(I->getOperand(0), d) && block_base(I->getOperand(1), d);
    default: return false;
  }
}
bool reads_ctaid(Value *V) {
  int d = -1;
  if (is_sreg(V, "ctaid", d)) return true;
  auto *I = dyn_cast<Instruction>(V);
  if (!I || isa<LoadInst>(I)) return false;
  for (Value *Op : I->operands()) if (reads_ctaid(Op)) return true;
  return false;
}
// X = base + threadIdx.d with base a function of the block: returns d and base, or -1
int match_global_index(Value *X, Value *&Base) {
  Value *V = X;
  if (auto *T = dyn_cast<TruncInst>(V)) V = T->getOperand(0);
  Value *A, *B;
  if (!match(V, m_Add(m_Value(A), m_Value(B)))) return -1;
  for (int k = 0; k < 2; ++k, std::swap(A, B)) {
    int d = -1;
    if (!is_sreg(strip_ext(B), "tid", d)) continue;
    if (block_base(A, d) && reads_ctaid(A)) { Base = A; return d; }
  }
  return -1;
}
// a key for values that are the same in the whole launch: an argument, a constant, a load from an argument or a parameter copy,
// casts and shifts of those
std::string launch_value_key(Value *V, const DataLayout &DL) {
  std::string k;
  raw_string_ostream os(k);
  if (auto *A = dyn_cast<Argument>(V)) { os << "A" << A->getArgNo(); return os.str(); }
  if (auto *C = dyn_cast<ConstantInt>(V)) { os << "C" << C->getValue(); return os.str(); }
  if (auto *T = dyn_cast<CastInst>(V)) {
    if (!isa<TruncInst>(T) && !isa<ZExtInst>(T) && !isa<SExtInst>(T)) return "";
    std::string i = launch_value_key(T->getOperand(0), DL);
    if (i.empty()) return "";
    os << T->getOpcodeName() << DL.getTypeSizeInBits(T->getType()) << "(" << i << ")";
    return os.str();
  }
  if (auto *B = dyn_cast<BinaryOperator>(V)) {
    if (B->getOpcode() != Instruction::LShr && B->getOpcode() != Instruction::And && B->getOpcode() != Instruction::Shl) return "";
    auto *C = dyn_cast<ConstantInt>(B->getOperand(1));
    std::string i = launch_value_key(B->getOperand(0), DL);
    if (!C || i.empty()) return "";
    os << B->getOpcodeName() << C->getValue() << "(" << i << ")";
    return os.str();
  }
  if (auto *L = dyn_cast<LoadInst>(V)) {
    int64_t off = 0;
    Value *Base = GetPointerBaseWithConstantOffset(L->getPointerOperand(), off, DL);
    if (auto *Al = dyn_cast<AllocaInst>(Base)) {
      for (User *U : Al->users()) {   // written only in the entry block: the parameter copy
        auto *I = dyn_cast<Instruction>(U);
        if (!I) return "";
        if (auto *G = dyn_cast<GetElementPtrInst>(I)) { for (User *U2 : G->users()) if (auto *S = dyn_cast<StoreInst>(U2)) if (S->getParent() != &S->getFunction()->getEntryBlock()) return ""; }
        else if (auto *S = dyn_cast<StoreInst>(I)) { if (S->getParent() != &S->getFunction()->getEntryBlock()) return ""; }
      }
      os << "L" << Al->getName() << ":" << off << ":" << DL.getTypeStoreSize(L->getType()).getFixedValue();
      return os.str();
    }
    if (auto *A = dyn_cast<Argument>(Base)) { os << "P" << A->getArgNo() << ":" << off << ":" << DL.getTypeStoreSize(L->getType()).getFixedValue(); return os.str(); }
  }
  return "";
}
// a copy of the pure expression V at the builder's place
Value *clone_expr(IRBuilder<> &B, Value *V, const DataLayout &DL, std::map<Value *, Value *> &m) {
  if (!isa<Instruction>(V)) return V;
  if (m.count(V)) return m[V];
  auto *I = cast<Instruction>(V);
  Instruction *N;
  if (auto *L = dyn_cast<LoadInst>(I)) {
    int64_t off = 0;
    Value *Base = GetPointerBaseWithConstantOffset(L->getPointerOperand(), off, DL);
    return m[V] = B.CreateLoad(L->getType(), B.CreateConstGEP1_64(B.getInt8Ty(), Base, off), "cta.v");
  }
  N = I->clone();
  for (unsigned i = 0; i < N->getNumOperands(); ++i)
    if (!isa<Function>(N->getOperand(i))) N->setOperand(i, clone_expr(B, N->getOperand(i), DL, m));
  B.Insert(N);
  return m[V] = N;
}
void cleanup(Function *F, bool loops) {
  {  // what LLVM's constant folder does not know: fabs of a constant, and the one exact value of the approximate rsqrt
    std::vector<CallInst *> calls;
    for (auto &BB : *F)
      for (auto &I : BB)
        if (auto *C = dyn_cast<CallInst>(&I))
          if (Function *G = C->getCalledFunction())
            if ((G->getName().starts_with("llvm.nvvm.fabs") || G->getName().starts_with("llvm.nvvm.rsqrt.approx")) && isa<ConstantFP>(C->getArgOperand(0))) calls.push_back(C);
    for (CallInst *C : calls) {
      APFloat v = cast<ConstantFP>(C->getArgOperand(0))->getValueAPF();
      if (C->getCalledFunction()->getName().starts_with("llvm.nvvm.fabs")) { v.clearSign(); C->replaceAllUsesWith(ConstantFP::get(C->getType(), v)); C->eraseFromParent(); }
      else if (v.isPosZero()) { C->replaceAllUsesWith(ConstantFP::getInfinity(C->getType())); C->eraseFromParent(); }
    }
  }
  PassBuilder PB;
  LoopAnalysisManager LAM; FunctionAnalysisManager FAM; CGSCCAnalysisManager CGAM; ModuleAnalysisManager MAM;
  PB.registerModuleAnalyses(MAM); PB.registerCGSCCAnalyses(CGAM); PB.registerFunctionAnalyses(FAM); PB.registerLoopAnalyses(LAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);
  FunctionPassManager FPM;
  if (auto E = PB.parsePassPipeline(FPM, loops ? "sccp,instsimplify,simplifycfg,dce,loop-simplify,lcssa,loop(loop-deletion),simplifycfg,dce" : "sccp,instsimplify,simplifycfg,dce")) {
    std::fprintf(stderr, "kernelTranslator: CUPBOP_CTA_EMPTY: %s\n", toString(std::move(E)).c_str());
    std::exit(1);
  }
  FPM.run(*F, FAM);
}
bool is_local(Value *P) { return P->getType()->getPointerAddressSpace() == 3; }
Constant *bits_as(Type *T, uint64_t bits) {
  if (T->isIntegerTy()) return ConstantInt::get(T, bits);
  if (T->isFloatTy()) return ConstantFP::get(T, APFloat(APFloat::IEEEsingle(), APInt(32, bits)));
  if (T->isDoubleTy()) return ConstantFP::get(T, APFloat(APFloat::IEEEdouble(), APInt(64, bits)));
  return nullptr;
}
bool const_bits(Value *V, uint64_t &bits, unsigned &size) {
  if (auto *C = dyn_cast<ConstantInt>(V)) { bits = C->getZExtValue(); size = C->getBitWidth() / 8; return C->getBitWidth() <= 64; }
  if (auto *C = dyn_cast<ConstantFP>(V)) { APInt b = C->getValueAPF().bitcastToAPInt(); if (b.getBitWidth() > 64) return false; bits = b.getZExtValue(); size = b.getBitWidth() / 8; return true; }
  return false;
}
// the copy under U: true when it was reduced to constant stores outside local memory
bool reduce_empty_copy(Function *E, std::string &why) {
  const DataLayout &DL = E->getParent()->getDataLayout();
  cleanup(E, false);
  // worth it only when the block does something the guard does not already skip
  bool work = false;
  for (auto &BB : *E)
    for (auto &I : BB) {
      if (auto *S = dyn_cast<StoreInst>(&I)) work |= is_local(S->getPointerOperand());
      if (auto *C = dyn_cast<CallBase>(&I))
        if (Function *G = C->getCalledFunction()) work |= G->getName().starts_with("llvm.nvvm.barrier");
    }
  if (!work) { why = "the guard already skips everything"; return false; }
  bool have = false; uint64_t e = 0;
  for (int round = 0; round < 12; ++round) {
    std::vector<LoadInst *> loads;
    for (auto &BB : *E)
      for (auto &I : BB) {
        if (auto *S = dyn_cast<StoreInst>(&I)) {
          if (!is_local(S->getPointerOperand())) continue;
          uint64_t b; unsigned sz;
          if (!const_bits(S->getValueOperand(), b, sz)) continue;   // decided after the loads are folded
          if (sz != 4 && sz != 8) { why = "store size"; return false; }
          if (sz == 8 && (b >> 32) != (b & 0xffffffffu)) { why = "wide store"; return false; }
          b &= 0xffffffffu;
          if (have && b != e) { why = "two different constants in local memory"; return false; }
          e = b; have = true;
        } else if (auto *L = dyn_cast<LoadInst>(&I)) {
          if (is_local(L->getPointerOperand())) loads.push_back(L);
        } else if (isa<AtomicRMWInst>(&I) || isa<AtomicCmpXchgInst>(&I)) { why = "an atomic"; return false; }
      }
    if (loads.empty()) break;
    if (!have) { why = "loads from local memory with no store seen"; return false; }
    for (LoadInst *L : loads) {
      const uint64_t sz = DL.getTypeStoreSize(L->getType()).getFixedValue();
      Constant *C = bits_as(L->getType(), sz == 8 ? (e << 32 | e) : e);
      if (!C || (sz != 4 && sz != 8)) { why = "load type"; return false; }
      L->replaceAllUsesWith(C);
      L->eraseFromParent();
    }
    cleanup(E, false);
  }
  std::vector<Instruction *> dead;
  for (auto &BB : *E)
    for (auto &I : BB) {
      if (auto *L = dyn_cast<LoadInst>(&I)) {
        if (is_local(L->getPointerOperand())) { why = "a local load survived"; return false; }
        const Value *O = getUnderlyingObject(L->getPointerOperand());
        if (!isa<AllocaInst>(O) && !isa<Argument>(O)) { why = "a load from global memory remains"; return false; }
      }
      if (auto *S = dyn_cast<StoreInst>(&I))
        if (is_local(S->getPointerOperand())) {
          uint64_t b; unsigned sz;
          if (!const_bits(S->getValueOperand(), b, sz) || (b & 0xffffffffu) != e) {
            std::string d; raw_string_ostream os(d); S->print(os);
            why = "a store to local memory stays different:" + os.str();
            if (std::getenv("CUPBOP_CTA_EMPTY_DUMP")) { std::error_code ec; raw_fd_ostream f("cta_empty_dump.ll", ec); E->print(f); }
            return false;
          }
          dead.push_back(S);
        }
      if (auto *C = dyn_cast<CallBase>(&I))
        if (Function *G = C->getCalledFunction()) {
          StringRef n = G->getName();
          if (n == "llvm.nvvm.barrier0" || n.starts_with("llvm.nvvm.barrier.sync")) dead.push_back(C);
          else if (n.starts_with("llvm.nvvm.bar.warp.sync")) dead.push_back(C);
          else if (n.contains("shfl") || n.contains("vote") || n.contains("match")) { why = "a warp operation remains"; return false; }
        }
    }
  for (Instruction *I : dead) I->eraseFromParent();
  dead.clear();
  for (auto &BB : *E)
    for (auto &I : BB)
      if (auto *C = dyn_cast<CallBase>(&I))
        if (Function *G = C->getCalledFunction())
          if (G->getName() == "llvm.nvvm.activemask" && C->use_empty()) dead.push_back(C);
  for (Instruction *I : dead) I->eraseFromParent();
  E->addFnAttr(Attribute::MustProgress);
  cleanup(E, true);
  unsigned n = 0;
  for (auto &BB : *E) n += BB.size();
  DominatorTree DT(*E);
  LoopInfo LI(DT);
  if (!LI.empty()) { why = "a loop remains"; return false; }
  if (n > 64) { why = "the copy stays large"; return false; }
  return true;
}
} // namespace

void cta_empty_exit(Module *M) {
  const char *en = std::getenv("CUPBOP_CTA_EMPTY");
  if (!en || !std::atoi(en)) return;
  const DataLayout &DL = M->getDataLayout();
  std::vector<Function *> ks;
  for (auto &F : *M)
    if (!F.isDeclaration() && isKernelFunction(M, &F)) ks.push_back(&F);
  for (Function *K : ks) {
    const std::string name = cupbop_kernel_lookup_name(K->getName().str());
    struct G { Value *v, *base; int dim; bool sgn; std::vector<std::pair<ICmpInst *, bool>> uses; };
    std::map<std::string, G> groups;
    for (auto &BB : *K)
      for (auto &I : BB) {
        auto *C = dyn_cast<ICmpInst>(&I);
        if (!C) continue;
        for (int side = 0; side < 2; ++side) {
          Value *X = C->getOperand(side), *V = C->getOperand(1 - side), *Base = nullptr;
          const int d = match_global_index(X, Base);
          if (d < 0) continue;
          ICmpInst::Predicate P = side == 0 ? C->getPredicate() : C->getSwappedPredicate();   // P(X, V)
          bool sgn, val;
          if (P == ICmpInst::ICMP_UGE) { sgn = false; val = true; } else if (P == ICmpInst::ICMP_ULT) { sgn = false; val = false; }
          else if (P == ICmpInst::ICMP_SGE) { sgn = true; val = true; } else if (P == ICmpInst::ICMP_SLT) { sgn = true; val = false; }
          else continue;
          const std::string key = launch_value_key(V, DL);
          if (key.empty()) continue;
          auto &g = groups[key + (sgn ? "s" : "u") + std::to_string(d)];
          g.v = V; g.base = Base; g.dim = d; g.sgn = sgn; g.uses.push_back({C, val});
        }
      }
    if (groups.empty()) continue;
    G *best = nullptr;
    for (auto &kv : groups) if (!best || kv.second.uses.size() > best->uses.size()) best = &kv.second;
    // a kernel that reads gridDim on this dimension walks the grid (grid-stride): its grid need not be sized to the data, which
    // is when whole blocks can be empty. Otherwise the test at the entry is only a cost (pool_avg +1.5%).
    bool strided = false;
    for (auto &BB : *K)
      for (auto &I : BB) {
        int d = -1;
        if (is_sreg(&I, "nctaid", d) && d == best->dim) strided = true;
      }
    if (!strided) { if (report()) std::fprintf(stderr, "[CuPBoP] cta_empty: %s: not used: the kernel does not read gridDim\n", name.c_str()); continue; }
    ValueToValueMapTy VM;
    Function *E = CloneFunction(K, VM);
    E->setName(K->getName() + ".empty");
    E->setLinkage(GlobalValue::InternalLinkage);
    for (auto &u : best->uses) {
      auto *C = cast<Instruction>(VM[u.first]);
      C->replaceAllUsesWith(ConstantInt::getBool(M->getContext(), u.second));
      C->eraseFromParent();
    }
    std::string why;
    if (!reduce_empty_copy(E, why)) {
      if (report()) std::fprintf(stderr, "[CuPBoP] cta_empty: %s: %zu guards, not used: %s\n", name.c_str(), best->uses.size(), why.c_str());
      E->eraseFromParent();
      continue;
    }
    // at the end of the entry block: the parameter copy is written there
    BasicBlock *Entry = &K->getEntryBlock();
    Instruction *T = Entry->getTerminator();
    IRBuilder<> B(T);
    std::map<Value *, Value *> copies;
    Value *V = clone_expr(B, best->v, DL, copies);
    Value *t = clone_expr(B, best->base, DL, copies);
    t = B.CreateZExtOrTrunc(t, V->getType());
    const char xyz[] = "xyz";
    Value *nt = B.CreateCall(M->getOrInsertFunction(std::string("llvm.nvvm.read.ptx.sreg.ntid.") + xyz[best->dim], FunctionType::get(B.getInt32Ty(), false)));
    Value *e = B.CreateAdd(t, B.CreateZExtOrTrunc(nt, V->getType()));
    Value *U = best->sgn ? B.CreateAnd(B.CreateICmpSGE(t, V), B.CreateICmpSGE(e, t)) : B.CreateAnd(B.CreateICmpUGE(t, V), B.CreateICmpUGE(e, t));
    BasicBlock *Rest = Entry->splitBasicBlock(T, "cta.rest");
    Entry->getTerminator()->eraseFromParent();
    BasicBlock *Go = BasicBlock::Create(M->getContext(), "cta.empty", K, Rest);
    B.SetInsertPoint(Entry);
    B.CreateCondBr(U, Go, Rest);
    B.SetInsertPoint(Go);
    std::vector<Value *> args;
    for (auto &A : K->args()) args.push_back(&A);
    CallInst *CI = B.CreateCall(E, args);
    B.CreateRetVoid();
    InlineFunctionInfo IFI;
    if (!InlineFunction(*CI, IFI).isSuccess()) { std::fprintf(stderr, "kernelTranslator: CUPBOP_CTA_EMPTY: inlining failed in %s\n", name.c_str()); std::exit(1); }
    E->eraseFromParent();
    std::fprintf(stderr, "[CuPBoP] cta_empty: %s: %zu guards on dimension %d: a block past the range skips the kernel\n", name.c_str(), best->uses.size(), best->dim);
  }
}
