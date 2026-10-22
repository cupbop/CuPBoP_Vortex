#include "cudaKernelImpl.h"
#include <atomic>
#include <cstdint>
#include <cstdlib>
#include <math.h>
#include <vx_intrinsics.h>
#include <vx_print.h>

__attribute__((always_inline)) double __nv_exp(double base) {
  return exp(base);
}
__attribute__((always_inline)) double __nv_sqrt(double v) { return sqrt(v); }
__attribute__((always_inline)) float __nv_sqrtf(float v) { return sqrt(v); }
__attribute__((always_inline)) float __nv_powif(float base, int exp) {
  return pow(base, exp);
}
__attribute__((always_inline)) float __nv_logf(float v) { return logf(v); }
__attribute__((always_inline)) float __nv_expf(float v) { return expf(v); }
__attribute__((always_inline)) float __nv_log10f(float v) { return log10f(v); }
__attribute__((always_inline)) float __nv_fast_log2f(float v) {
  return log2f(v);
}
__attribute__((always_inline)) double __nv_powi(double base, int exp) {
  return pow(base, exp);
}
__attribute__((always_inline)) float __nv_powf(float base, float exp) {
  return pow(base, exp);
}
extern "C" __attribute__((always_inline)) float __nv_erfcf(float v) {
  return erfcf(v);
}
__attribute__((always_inline)) float __nv_fast_powf(float base, float exp) {
  return pow(base, exp);
}
__attribute__((always_inline)) float __nv_fmodf(float x, float y) {
  return fmod(x, y);
}
__attribute__((always_inline)) int __nv_isnanf(float v) { return isnan(v); }
__attribute__((always_inline)) int __nv_isinff(float v) { return isinf(v); }
__attribute__((always_inline)) float __nv_fabsf(float v) { return fabs(v); }
__attribute__((always_inline)) int __nvvm_mul24_i(int a, int b) {
  return a * b;
}
__attribute__((always_inline)) double _ZL3expd(double base) {
  return exp(base);
}
__attribute__((always_inline)) int __nv_ffs(int x) { return __builtin_ffs(x); }
__attribute__((always_inline)) int __nv_popc(int x) {
  return __builtin_popcount(x);
}
__attribute__((always_inline)) float __nvvm_fmin_ftz_f(int a, int b) {
  return __builtin_fmin(a, b);
}
__attribute__((always_inline)) float __nvvm_fmin_f(float a, float b) {
  return __builtin_fmin(a, b);
}
__attribute__((always_inline)) float __nvvm_fmax_ftz_f(float a, float b) {
  return __builtin_fmax(a, b);
}
__attribute__((always_inline)) float __nvvm_fmax_f(float a, float b) {
  return __builtin_fmax(a, b);
}
__attribute__((always_inline)) void __nvvm_membar_gl() { vx_fence(); }
__attribute__((always_inline)) int __nvvm_atomic_load_inc_32(int *addr,
                                                             int val) {
  return __atomic_fetch_add(addr, val, __ATOMIC_SEQ_CST);
}
__attribute__((always_inline)) float __nv_rsqrtf(float f) {
  return 1.0f / sqrtf(f);
}
__attribute__((always_inline)) int __nvvm_reflect(int *) { return 0; }
__attribute__((always_inline)) float __nvvm_div_approx_ftz_f(float a, float b) {
  return a / b;
}
__attribute__((always_inline)) float __nvvm_div_approx_f(float a, float b) {
  return a / b;
}

__attribute__((always_inline)) bool __all_sync(int mask, bool predicate) {
  int in_mask = ((vx_active_threads() & mask) != 0);
  int effective = in_mask ? predicate : 1;
  return vx_vote_all(effective);
}

__attribute__((always_inline)) bool __any_sync(int mask, bool predicate) {
  int in_mask = ((vx_active_threads() & mask) != 0);
  int effective = in_mask ? predicate : 0;
  return vx_vote_any(effective);
}

__attribute__((always_inline)) int __ballot_sync(int mask, bool predicate) {
  int in_mask = ((vx_active_threads() & mask) != 0);
  int bits = (int)vx_vote_ballot(in_mask ? predicate : 0);
  return bits & mask;
}

__attribute__((always_inline)) bool __uniform_sync(int mask, bool predicate) {
  auto b = __ballot_sync(mask, predicate);
  return (b == 0u) || (b == mask);
}

__attribute__((always_inline)) int __activemask(void) {
  return (int)vx_active_threads();
}

// The `c` parameter received here is NVPTX's encoded shfl operand (per the
// SHFL.SYNC instruction): bits [4:0] hold the per-direction clamp and bits
// [12:8] hold the segment-id mask. Clang lowers CUDA's
// `__shfl_*_sync(mask, val, idx_or_delta_or_laneMask, width=warpSize)` to
// these encodings, so for the default warp-wide call we observe:
//   __shfl_up_sync(..., width=32)   → c = 0  (UP clamp = 0,  mask = 0)
//   __shfl_down_sync(..., width=32) → c = 31 (DOWN clamp=31, mask = 0)
//   __shfl_xor_sync(..., width=32)  → c = 31 (clamp = 31,    mask = 0)
//   __shfl_sync(..., width=32)      → c = 31 (clamp = 31,    mask = 0)
// Vortex's vx_shfl_* expects (clamp, segment_mask) separately. Previously the
// wrapper passed `cval = c` and `mask = ~c`, which for shfl_up's `c = 0`
// produced `mask = ~0 = 0x3F`. simx then computed `minLane = t & 0x3F = t`,
// so the `lane >= minLane` check always failed → every Hillis-Steele prefix
// scan was silently broken.

__attribute__((always_inline, convergent)) int __shfl_sync(int mem_mask, int var,
                                               int srcLane, int c) {
  int clamp = c & 0x1F;
  int mask = (c >> 8) & 0x1F;
  return vx_shfl_idx((size_t)var, srcLane, clamp, mask);
}

__attribute__((always_inline, convergent)) float __shfl_sync(int mem_mask, float var,
                                                 int srcLane, int c) {
  int clamp = c & 0x1F;
  int mask = (c >> 8) & 0x1F;
  int vali = *reinterpret_cast<int *>(&var);
  int ri = vx_shfl_idx(vali, srcLane, clamp, mask);
  return *reinterpret_cast<float *>(&ri);
}

__attribute__((always_inline, convergent)) int __shfl_up_sync(int mem_mask, int var,
                                                  int delta, int c) {
  int clamp = c & 0x1F;
  int mask = (c >> 8) & 0x1F;
  return vx_shfl_up((size_t)var, delta, clamp, mask);
}

__attribute__((always_inline, convergent)) float __shfl_up_sync(int mem_mask, float var,
                                                    int delta, int c) {
  int clamp = c & 0x1F;
  int mask = (c >> 8) & 0x1F;
  int vali = *reinterpret_cast<int *>(&var);
  int ri = vx_shfl_up(vali, delta, clamp, mask);
  return *reinterpret_cast<float *>(&ri);
}

__attribute__((always_inline, convergent)) int __shfl_down_sync(int mem_mask, int var,
                                                    int delta, int c) {
  int clamp = c & 0x1F;
  int mask = (c >> 8) & 0x1F;
  return vx_shfl_down((size_t)var, delta, clamp, mask);
}

__attribute__((always_inline, convergent)) float __shfl_down_sync(int mem_mask, float var,
                                                      int delta, int c) {
  int clamp = c & 0x1F;
  int mask = (c >> 8) & 0x1F;
  int vali = *reinterpret_cast<int *>(&var);
  int ri = vx_shfl_down(vali, delta, clamp, mask);
  return *reinterpret_cast<float *>(&ri);
}

__attribute__((always_inline, convergent)) int __shfl_xor_sync(int mem_mask, int var,
                                                   int laneMask, int c) {
  int clamp = c & 0x1F;
  int mask = (c >> 8) & 0x1F;
  return vx_shfl_bfly((size_t)var, laneMask, clamp, mask);
}

__attribute__((always_inline, convergent)) float __shfl_xor_sync(int mem_mask, float var,
                                                     int laneMask, int c) {
  int clamp = c & 0x1F;
  int mask = (c >> 8) & 0x1F;
  int vali = *reinterpret_cast<int *>(&var);
  int ri = vx_shfl_bfly(vali, laneMask, clamp, mask);
  return *reinterpret_cast<float *>(&ri);
}

// ── DXA (Direct Cross-bar Access) support ──────────────────────────────────

#define VX_DXA_EXT_OPCODE 0x0B // RISCV_CUSTOM0
#define VX_DXA_FUNCT7 0x3

// These are defined in kernel_wrapper.cpp (generated by CuPBoP)
extern __thread uint32_t __local_group_id __attribute__((weak));
extern uint32_t __warps_per_group __attribute__((weak));

// Issue a 2D DXA tile copy: global memory → shared memory
// Only the first warp in the CTA actually issues the DXA command.
// Safe to call from all threads — non-DXA warps are no-ops.
__attribute__((always_inline)) void
__vx_dxa_issue_2d(unsigned int desc_slot, unsigned int barrier_id,
                  void *smem_addr, unsigned int coord0, unsigned int coord1) {
  // Only first warp in CTA issues DXA
  if (__warps_per_group != 0 && (vx_warp_id() & (__warps_per_group - 1)) != 0)
    return;
#if defined(VX_CFG_NUM_THREADS)
  // Vortex 3.0: a barrier with pending transactions releases only after the DXA engine
  // retires them (BarrierUnit events). Register this transfer before issuing it, like
  // vortex::barrier::expect_tx() in tests/regression/sgemm2_dxa. 2.0 counted it implicitly.
  vx_barrier_expect_tx((int)barrier_id, 1);
#endif
  unsigned int meta = (barrier_id << 4) | desc_slot;
  unsigned int a0 =
      (unsigned int)vx_wgather((size_t)(uintptr_t)smem_addr, (size_t)meta,
                               (size_t)coord0, (size_t)coord1);
  __asm__ volatile(".insn r %0, 0, %1, x0, %2, x0\n\t"
                   :
                   : "i"(VX_DXA_EXT_OPCODE), "i"(VX_DXA_FUNCT7), "r"(a0)
                   : "memory");
}

// Async barrier: arrive and wait (blocking)
__attribute__((always_inline)) void
__vx_barrier_arrive_and_wait(unsigned int bar_id, unsigned int num_warps) {
  vx_barrier(bar_id, num_warps);
}

// Async barrier arrive (non-blocking), returns phase
__attribute__((always_inline)) int __vx_barrier_arrive(unsigned int bar_id,
                                                       unsigned int num_warps) {
  return vx_barrier_arrive(bar_id, num_warps);
}

// Async barrier wait (blocking until phase completes)
__attribute__((always_inline)) void __vx_barrier_wait(unsigned int bar_id,
                                                      unsigned int phase) {
  vx_barrier_wait(bar_id, phase);
}

// Get packed barrier id for DXA
__attribute__((always_inline)) unsigned int
__vx_dxa_barrier_id(unsigned int id) {
  return __local_group_id + (id << 8);
}

// Check if current warp is the DXA warp (first warp in CTA)
__attribute__((always_inline)) int __vx_is_dxa_warp(void) {
  if (__warps_per_group == 0)
    return 0;
  return (vx_warp_id() & (__warps_per_group - 1)) == 0 ? 1 : 0;
}

// Get shared memory base pointer (local memory)
#ifndef VX_CSR_LOCAL_MEM_BASE
#define VX_CSR_LOCAL_MEM_BASE 0xFC3
#endif
// Get number of warps per CTA (runtime value from vx_spawn_threads)
__attribute__((always_inline)) unsigned int __vx_warps_per_group(void) {
  return __warps_per_group;
}

// ── WGMMA (TCU with shared memory descriptors) ────────────────────────────

// Encode descriptor metadata into fragment registers for WGMMA
// lane 0: lower 32 bits of tile_addr
// lane 1: upper 32 bits of tile_addr
// lane 2: leading dimension (stride per K step)
// lane 3: layout (0=row_major, 1=col_major)
// Returns: the metadata word for this lane (written to all fragment regs)
__attribute__((always_inline)) unsigned int
__vx_wgmma_encode_desc(unsigned long long base_addr, unsigned int leading_bytes,
                       unsigned int stride_bytes, unsigned int mn_idx,
                       unsigned int k_idx, unsigned int ldm,
                       unsigned int is_col_major) {
  unsigned long long tile_addr = base_addr +
                                 (unsigned long long)mn_idx * stride_bytes +
                                 (unsigned long long)k_idx * leading_bytes;
  unsigned int lane = vx_thread_id();
  unsigned int m0 = (lane == 0) ? 0xffffffffu : 0u;
  unsigned int m1 = (lane == 1) ? 0xffffffffu : 0u;
  unsigned int m2 = (lane == 2) ? 0xffffffffu : 0u;
  unsigned int m3 = (lane == 3) ? 0xffffffffu : 0u;
  unsigned int word = 0;
  word |= (unsigned int)(tile_addr & 0xffffffffull) & m0;
  word |= (unsigned int)(tile_addr >> 32) & m1;
  word |= ldm & m2;
  word |= is_col_major & m3;
  return word;
}

// WGMMA MMA with smem descriptors for both A and B (flags=6)
// fragC: 8 floats (accumulator), fragA_meta/fragB_meta: 8 floats (descriptor
// metadata)
__attribute__((always_inline)) void
__vx_wgmma_mma_ss(float *fragC, float *fragA_meta, float *fragB_meta) {
  register float fd0 __asm__("f0") = fragC[0];
  register float fd1 __asm__("f1") = fragC[1];
  register float fd2 __asm__("f2") = fragC[2];
  register float fd3 __asm__("f3") = fragC[3];
  register float fd4 __asm__("f4") = fragC[4];
  register float fd5 __asm__("f5") = fragC[5];
  register float fd6 __asm__("f6") = fragC[6];
  register float fd7 __asm__("f7") = fragC[7];

  register float fa0 __asm__("f10") = fragA_meta[0];
  register float fa1 __asm__("f11") = fragA_meta[1];
  register float fa2 __asm__("f12") = fragA_meta[2];
  register float fa3 __asm__("f13") = fragA_meta[3];
  register float fa4 __asm__("f14") = fragA_meta[4];
  register float fa5 __asm__("f15") = fragA_meta[5];
  register float fa6 __asm__("f16") = fragA_meta[6];
  register float fa7 __asm__("f17") = fragA_meta[7];

  register float fb0 __asm__("f24") = fragB_meta[0];
  register float fb1 __asm__("f25") = fragB_meta[1];
  register float fb2 __asm__("f26") = fragB_meta[2];
  register float fb3 __asm__("f27") = fragB_meta[3];
  register float fb4 __asm__("f28") = fragB_meta[4];
  register float fb5 __asm__("f29") = fragB_meta[5];
  register float fb6 __asm__("f30") = fragB_meta[6];
  register float fb7 __asm__("f31") = fragB_meta[7];

  // flags=6: Ot=0(fp32), It=1(fp16), src_a_smem=1, src_b_smem=1
  __asm__ volatile(".insn r 0x0b, 0, 2, x0, x1, x6"
                   : "+f"(fd0), "+f"(fd1), "+f"(fd2), "+f"(fd3), "+f"(fd4),
                     "+f"(fd5), "+f"(fd6), "+f"(fd7)
                   : "f"(fa0), "f"(fa1), "f"(fa2), "f"(fa3), "f"(fa4), "f"(fa5),
                     "f"(fa6), "f"(fa7), "f"(fb0), "f"(fb1), "f"(fb2), "f"(fb3),
                     "f"(fb4), "f"(fb5), "f"(fb6), "f"(fb7)
                   : "memory");

  fragC[0] = fd0;
  fragC[1] = fd1;
  fragC[2] = fd2;
  fragC[3] = fd3;
  fragC[4] = fd4;
  fragC[5] = fd5;
  fragC[6] = fd6;
  fragC[7] = fd7;
}

__attribute__((always_inline)) void *__vx_local_mem(void) {
  // Must offset by __local_group_id so each CTA gets its own shared memory
  // region Same as vx_spawn.h's __local_mem(size) but without size param
  // (caller manages layout)
  return (void *)csr_read(VX_CSR_LOCAL_MEM_BASE);
}

// Local mem with per-CTA offset (matches vx_spawn.h __local_mem(size))
__attribute__((always_inline)) void *__vx_local_mem_offset(unsigned int size) {
  return (void *)((char *)csr_read(VX_CSR_LOCAL_MEM_BASE) +
                  __local_group_id * size);
}

struct __vx_dim3 {
  uint32_t x;
  uint32_t y;
  uint32_t z;
};

extern "C" __thread __vx_dim3 threadIdx __attribute__((weak));
extern "C" __thread uint32_t thread_id_x __attribute__((weak));

__attribute__((always_inline)) uint32_t __vx_get_lane_id() {
  if (&threadIdx != nullptr)
    return threadIdx.x;

  if (&thread_id_x != nullptr)
    return thread_id_x;

  return 0;
}

__attribute__((always_inline)) float __vx_bitcast_u32_to_f32(uint32_t x) {
  float f;
  __builtin_memcpy(&f, &x, sizeof(f));
  return f;
}

// ── TCU wrappers ───────────────────────────────────────────────────────────
// Vortex 3.0 (tools-v3.0.1 trees define VX_CFG_* macros): the TCU is driven through
// <vx_tensor.h>'s wmma_context, which owns the per-lane fragment layout and the
// bank-conflict-free register permutation that the 3.0 WMMA macro-op expects. The
// hand-written 2.0 register protocol below (f0-7 / f10-17 / f24-31 in logical order,
// `.insn r 0x0b, 0, 2`) is kept for 2.0 trees only. The translator allocates 8 x 32-bit
// per lane for every fragment; the 3.0 fragments for NT=32 / fp16->fp32 fit in that.
// NOTE: for NT=32 the hardware tile is m16n16k32 (two fp16 per 32-bit lane register),
// exactly as the 2.0 wrappers loaded it; CUDA's m16n16k16 fragments are mapped the same way.
#if defined(VX_CFG_NUM_THREADS)
#if defined(VX_CFG_EXT_TCU_ENABLE)
#include <vx_tensor.h>
namespace {
namespace vt = vortex::tensor;
using tcu_ctx = vt::wmma_context<VX_CFG_NUM_THREADS, vt::fp16, vt::fp32>;
static_assert(tcu_ctx::tileM == 16 && tcu_ctx::tileN == 16, "CuPBoP TCU wrappers assume a 16x16 (M,N) tile: use NUM_THREADS=32");
static_assert(sizeof(tcu_ctx::fragment_a) <= 32 && sizeof(tcu_ctx::fragment_b) <= 32 && sizeof(tcu_ctx::fragment_acc) == 32,
              "translator fragment storage is 8 x 32-bit per lane");
} // namespace

// CUDA m16n16k16 fragments on the NT=32 m16n16k32 tile: load_matrix_sync reads 32 k-columns
// (A regs r with (r&3) >= 2, B regs r with (r>>1) >= 2 hold k = 16..31). A CUDA k16 step must
// not see them (they are the next step's data, or memory past the matrix), so zero them: each
// wmma call is then an exact k16 product and K loops of any length are correct. Found with
// sgemm_tcu -n 64 (n=32 in CI happened to pass; sgemm_tcu_dxa zero-pads its smem tiles to 32).
// Fusing two k16 steps into one k32 op is a translator-side optimization (mma_fuse).
static inline void __vx_wmma_zero_upper_k_a(tcu_ctx::fragment_a &f) { f.data[2] = f.data[3] = f.data[6] = f.data[7] = 0.f; }
static inline void __vx_wmma_zero_upper_k_b(tcu_ctx::fragment_b &f) { f.data[4] = f.data[5] = f.data[6] = f.data[7] = 0.f; }
extern "C" void __vx_wmma_load_a_m16n16k16_row_f16(void *frag, const void *p, int32_t ldm) {
  auto &f = *reinterpret_cast<tcu_ctx::fragment_a *>(frag);
  tcu_ctx::load_matrix_sync(f, p, (size_t)ldm);
  __vx_wmma_zero_upper_k_a(f);
}
extern "C" void __vx_wmma_load_a_m16n16k16_col_f16(void *frag, const void *p, int32_t ldm) {
  auto &f = *reinterpret_cast<tcu_ctx::fragment_a *>(frag);
  tcu_ctx::load_matrix_sync<vt::col_major>(f, p, (size_t)ldm);
  __vx_wmma_zero_upper_k_a(f);
}
extern "C" void __vx_wmma_load_b_m16n16k16_row_f16(void *frag, const void *p, int32_t ldm) {
  auto &f = *reinterpret_cast<tcu_ctx::fragment_b *>(frag);
  tcu_ctx::load_matrix_sync(f, p, (size_t)ldm);
  __vx_wmma_zero_upper_k_b(f);
}
extern "C" void __vx_wmma_load_b_m16n16k16_col_f16(void *frag, const void *p, int32_t ldm) {
  auto &f = *reinterpret_cast<tcu_ctx::fragment_b *>(frag);
  tcu_ctx::load_matrix_sync<vt::col_major>(f, p, (size_t)ldm);
  __vx_wmma_zero_upper_k_b(f);
}
extern "C" void __vx_wmma_load_c_m16n16k16_row_f32(void *frag, const void *p, int32_t ldm) {
  tcu_ctx::load_matrix_sync(*reinterpret_cast<tcu_ctx::fragment_acc *>(frag), p, (size_t)ldm);
}
extern "C" void __vx_wmma_store_d_m16n16k16_f32(float *p, const float *frag, int32_t ldm, WmmaLayout layout) {
  const auto &acc = *reinterpret_cast<const tcu_ctx::fragment_acc *>(frag);
  if (layout == WMMA_LAYOUT_ROW)
    tcu_ctx::store_matrix_sync(p, acc, (size_t)ldm);
  else
    tcu_ctx::store_matrix_sync<vt::col_major>(p, acc, (size_t)ldm);
}
extern "C" void __vx_wmma_mma_m16n16k16_row_row_f16_f16_f32(float *d, const uint32_t *a, const uint32_t *b, const float *c) {
  tcu_ctx::fragment_acc fd;
  tcu_ctx::mma_sync(fd, *reinterpret_cast<const tcu_ctx::fragment_a *>(a), *reinterpret_cast<const tcu_ctx::fragment_b *>(b),
                    *reinterpret_cast<const tcu_ctx::fragment_acc *>(c));
  __builtin_memcpy(d, fd.data.data(), sizeof(fd.data));
}
#endif // VX_CFG_EXT_TCU_ENABLE (3.0: TCU disabled -> no wrappers, TCU kernels fail to link with a clear symbol name)
#else  // Vortex 2.0 register-protocol wrappers
extern "C" void __vx_wmma_m16n16k16_load_a_row_f16(uint32_t *out_regs,
                                                   const uint16_t *ptr,
                                                   int stride) {
  uint32_t lane = __vx_get_lane_id();

  uint32_t block_row = lane / 4;
  uint32_t block_col = (lane % 4) * 2;

  for (int r = 0; r < 8; ++r) {
    uint32_t elem_row = block_row + (r / 4) * 8;
    uint32_t elem_col = block_col + (r % 4) * 8;

    uint16_t h0 = ptr[elem_row * stride + elem_col];
    uint16_t h1 = ptr[elem_row * stride + elem_col + 1];

    out_regs[r] = uint32_t(h0) | (uint32_t(h1) << 16);
  }
}

extern "C" void __vx_wmma_load_a_m16n16k16_row_f16(
    void *frag,    // fragment storage, 8 x i32
    const void *p, // base pointer to matrix A (fp16 elements)
    int32_t ldm) { // stride in fp16 elements

  auto *dst = reinterpret_cast<uint32_t *>(frag);
  auto *src = reinterpret_cast<const uint16_t *>(p);

  uint32_t lane = __vx_get_lane_id();

  uint32_t block_row = lane / 4u;
  uint32_t block_col = (lane % 4u) * 2u;

  for (uint32_t r = 0; r < 8; ++r) {
    uint32_t elem_row = block_row + ((r / 4u) * 8u);
    uint32_t elem_col = block_col + ((r % 4u) * 8u);

    uint32_t off = elem_row * static_cast<uint32_t>(ldm) + elem_col;

    // Two contiguous fp16 values packed into one i32 register.
    uint16_t h0 = src[off];
    uint16_t h1 = src[off + 1u];
    dst[r] = static_cast<uint32_t>(h0) | (static_cast<uint32_t>(h1) << 16);
  }
}

// TODO: Fix BUG. Compute is not resulting in correct result
extern "C" void __vx_wmma_load_a_m32n8k16_row_f16(
    void *frag,    // fragment storage, 8 x i32
    const void *p, // base pointer to matrix A (fp16 elements)
    int32_t ldm) { // stride in fp16 elements

  auto *dst = reinterpret_cast<uint32_t *>(frag);
  auto *src = reinterpret_cast<const uint8_t *>(p);

  uint32_t lane = __vx_get_lane_id();
  uint32_t lane16 = lane & 0xFu; // 16-lane native subgroup
  uint32_t row_base =
      (lane >> 4u) * 16u; // lanes 0..15 => rows 0..15, 16..31 => rows 16..31

  // Native 16x8x16 A mapping:
  // block_row = lane16 / 4, block_col = (lane16 % 4) * 2
  // row stride across regs = 4, col stride across regs = 8
  uint32_t block_row = row_base + (lane16 / 4u);
  uint32_t block_col = (lane16 % 4u) * 2u;

  for (uint32_t r = 0; r < 8u; ++r) {
    uint32_t elem_row = block_row + ((r / 2u) * 4u);
    uint32_t elem_col = block_col + ((r % 2u) * 8u);

    uint32_t off = elem_row * static_cast<uint32_t>(ldm) + elem_col;

    uint32_t packed;
    __builtin_memcpy(&packed, src + static_cast<uintptr_t>(off) * 2u, 4);
    dst[r] = packed;
  }
}

extern "C" void
__vx_wmma_load_b_m16n16k16_row_f16(void *frag,    // 8 x i32 fragment storage
                                   const void *p, // base ptr to matrix B
                                   int32_t ldm) { // stride in half elements

  auto *dst = reinterpret_cast<uint32_t *>(frag);
  auto *src = reinterpret_cast<const uint16_t *>(p);

  uint32_t lane = __vx_get_lane_id();

  uint32_t block_idx = lane / 16u;
  uint32_t lane_in_blk = lane % 16u;
  uint32_t block_col = (lane_in_blk / 4u) + (block_idx * 4u);
  uint32_t block_row = (lane_in_blk % 4u) * 2u;

  for (uint32_t r = 0; r < 8u; ++r) {
    uint32_t row = block_row + ((r / 2u) * 8u);
    uint32_t col = block_col + ((r % 2u) * 8u);

    uint32_t off0 = row * static_cast<uint32_t>(ldm) + col;
    uint32_t off1 = off0 + static_cast<uint32_t>(ldm); // next row

    uint16_t h0 = src[off0];
    uint16_t h1 = src[off1];

    // Matches <2 x half> {h0, h1} packed into one i32 on little-endian targets.
    dst[r] = static_cast<uint32_t>(h0) | (static_cast<uint32_t>(h1) << 16);
  }
}

// TODO: Fix BUG. Compute is not resulting in correct result
extern "C" void __vx_wmma_load_b_m32n8k16_row_f16(
    void *frag,    // fragment storage, keep 8 x i32 to match wrapper
    const void *p, // base ptr to matrix B
    int32_t ldm) { // stride in half elements

  auto *dst = reinterpret_cast<uint32_t *>(frag);
  auto *src = reinterpret_cast<const uint8_t *>(p);

  uint32_t lane = __vx_get_lane_id();
  uint32_t lane16 = lane & 0xFu; // both 16-lane subgroups use the same B tile

  // Native 16x8x16 B mapping:
  // block_col = lane16 / 4, block_row = (lane16 % 4) * 2
  // NRB = 4 for this native shape, so only dst[0..3] are meaningful.
  uint32_t block_col = lane16 / 4u;
  uint32_t block_row = (lane16 % 4u) * 2u;

  for (uint32_t r = 0; r < 4u; ++r) {
    uint32_t row = block_row + ((r / 2u) * 8u);
    uint32_t col = block_col + ((r % 2u) * 4u);

    uint32_t off0 = row * static_cast<uint32_t>(ldm) + col;
    uint32_t off1 = off0 + static_cast<uint32_t>(ldm); // next row

    uint16_t h0;
    uint16_t h1;
    __builtin_memcpy(&h0, src + static_cast<uintptr_t>(off0) * 2u, 2);
    __builtin_memcpy(&h1, src + static_cast<uintptr_t>(off1) * 2u, 2);

    dst[r] = static_cast<uint32_t>(h0) | (static_cast<uint32_t>(h1) << 16);
  }

  // Unused by the 4-reg B mma path, but keep fragment storage deterministic.
  dst[4] = 0;
  dst[5] = 0;
  dst[6] = 0;
  dst[7] = 0;
}

extern "C" void
__vx_wmma_load_c_m16n16k16_row_f32(void *frag,    // fragment storage: 8 x float
                                   const void *p, // base pointer to matrix C
                                   int32_t ldm) { // stride in float elements

  auto *dst = reinterpret_cast<float *>(frag);
  auto *src = reinterpret_cast<const float *>(p);

  uint32_t lane = __vx_get_lane_id();

  uint32_t block_row = lane / 4u;
  uint32_t block_col = lane % 4u;

  for (uint32_t r = 0; r < 8u; ++r) {
    uint32_t row = block_row + ((r / 4u) * 8u);
    uint32_t col = block_col + ((r % 4u) * 4u);
    uint32_t off = row * static_cast<uint32_t>(ldm) + col;
    dst[r] = src[off];
  }
}

extern "C" void __vx_wmma_store_d_m16n16k16_f32(float *p, const float *frag,
                                                int32_t ldm,
                                                WmmaLayout layout) {
  if (layout == WMMA_LAYOUT_ROW) {
    uint32_t lane = __vx_get_lane_id();

    uint32_t block_row = lane / 4u;
    uint32_t block_col = lane % 4u;

    for (uint32_t r = 0; r < 8u; ++r) {
      uint32_t row = block_row + ((r / 4u) * 8u);
      uint32_t col = block_col + ((r % 4u) * 4u);
      uint32_t off = row * static_cast<uint32_t>(ldm) + col;
      p[off] = frag[r];
    }
  } else if (layout == WMMA_LAYOUT_COL) {
    // TODO: Implement this later
  }
}

// TODO: Fix BUG. Compute is not resulting in correct result
extern "C" void __vx_wmma_store_d_m32n8k16_f32(float *p, const float *frag,
                                               int32_t ldm, WmmaLayout layout) {
  uint32_t lane = __vx_get_lane_id();

  uint32_t block_row = lane / 4u;
  uint32_t block_col = lane % 4u;

  if (layout == WMMA_LAYOUT_ROW) {
    for (uint32_t r = 0; r < 8u; ++r) {
      uint32_t row = block_row + ((r / 2u) * 8u);
      uint32_t col = block_col + ((r % 2u) * 4u);
      uint32_t off = row * static_cast<uint32_t>(ldm) + col;
      p[off] = frag[r];
    }
  } else if (layout == WMMA_LAYOUT_COL) {
    for (uint32_t r = 0; r < 8u; ++r) {
      uint32_t row = block_row + ((r / 2u) * 8u);
      uint32_t col = block_col + ((r % 2u) * 4u);
      uint32_t off = col * static_cast<uint32_t>(ldm) + row;
      p[off] = frag[r];
    }
  }
}

extern "C" void __vx_wmma_mma_m16n16k16_row_row_f16_f16_f32(float *d,
                                                            const uint32_t *a,
                                                            const uint32_t *b,
                                                            const float *c) {

  // D/C live in f0-f7
  register float d0 asm("f0") = c[0];
  register float d1 asm("f1") = c[1];
  register float d2 asm("f2") = c[2];
  register float d3 asm("f3") = c[3];
  register float d4 asm("f4") = c[4];
  register float d5 asm("f5") = c[5];
  register float d6 asm("f6") = c[6];
  register float d7 asm("f7") = c[7];

  // A lives in f10-f17, bitcast packed i32 -> float
  register float a0 asm("f10") = __vx_bitcast_u32_to_f32(a[0]);
  register float a1 asm("f11") = __vx_bitcast_u32_to_f32(a[1]);
  register float a2 asm("f12") = __vx_bitcast_u32_to_f32(a[2]);
  register float a3 asm("f13") = __vx_bitcast_u32_to_f32(a[3]);
  register float a4 asm("f14") = __vx_bitcast_u32_to_f32(a[4]);
  register float a5 asm("f15") = __vx_bitcast_u32_to_f32(a[5]);
  register float a6 asm("f16") = __vx_bitcast_u32_to_f32(a[6]);
  register float a7 asm("f17") = __vx_bitcast_u32_to_f32(a[7]);

  // B lives in f24-f31, bitcast packed i32 -> float
  register float b0 asm("f24") = __vx_bitcast_u32_to_f32(b[0]);
  register float b1 asm("f25") = __vx_bitcast_u32_to_f32(b[1]);
  register float b2 asm("f26") = __vx_bitcast_u32_to_f32(b[2]);
  register float b3 asm("f27") = __vx_bitcast_u32_to_f32(b[3]);
  register float b4 asm("f28") = __vx_bitcast_u32_to_f32(b[4]);
  register float b5 asm("f29") = __vx_bitcast_u32_to_f32(b[5]);
  register float b6 asm("f30") = __vx_bitcast_u32_to_f32(b[6]);
  register float b7 asm("f31") = __vx_bitcast_u32_to_f32(b[7]);

  asm volatile(".insn r 0x0b, 0, 2, x0, x1, x0"
               : "+f"(d0), "+f"(d1), "+f"(d2), "+f"(d3), "+f"(d4), "+f"(d5),
                 "+f"(d6), "+f"(d7)
               : "f"(a0), "f"(a1), "f"(a2), "f"(a3), "f"(a4), "f"(a5), "f"(a6),
                 "f"(a7), "f"(b0), "f"(b1), "f"(b2), "f"(b3), "f"(b4), "f"(b5),
                 "f"(b6), "f"(b7)
               : "memory");

  d[0] = d0;
  d[1] = d1;
  d[2] = d2;
  d[3] = d3;
  d[4] = d4;
  d[5] = d5;
  d[6] = d6;
  d[7] = d7;
}

// TODO: Fix BUG. Compute is not resulting in correct result
extern "C" void __vx_wmma_mma_m32n8k16_row_row_f16_f16_f32(float *d,
                                                           const uint32_t *a,
                                                           const uint32_t *b,
                                                           const float *c) {
  register float d0 asm("f0") = c[0];
  register float d1 asm("f1") = c[1];
  register float d2 asm("f2") = c[2];
  register float d3 asm("f3") = c[3];
  register float d4 asm("f4") = c[4];
  register float d5 asm("f5") = c[5];
  register float d6 asm("f6") = c[6];
  register float d7 asm("f7") = c[7];

  register float a0 asm("f10") = __vx_bitcast_u32_to_f32(a[0]);
  register float a1 asm("f11") = __vx_bitcast_u32_to_f32(a[1]);
  register float a2 asm("f12") = __vx_bitcast_u32_to_f32(a[2]);
  register float a3 asm("f13") = __vx_bitcast_u32_to_f32(a[3]);
  register float a4 asm("f14") = __vx_bitcast_u32_to_f32(a[4]);
  register float a5 asm("f15") = __vx_bitcast_u32_to_f32(a[5]);
  register float a6 asm("f16") = __vx_bitcast_u32_to_f32(a[6]);
  register float a7 asm("f17") = __vx_bitcast_u32_to_f32(a[7]);

  // Native 16x8x16 B fragment uses 4 regs, matching the supported Vortex path.
  register float b0 asm("f28") = __vx_bitcast_u32_to_f32(b[0]);
  register float b1 asm("f29") = __vx_bitcast_u32_to_f32(b[1]);
  register float b2 asm("f30") = __vx_bitcast_u32_to_f32(b[2]);
  register float b3 asm("f31") = __vx_bitcast_u32_to_f32(b[3]);

  // x0 = fp32::id, x1 = fp16::id, x0 flags = dense
  asm volatile(".insn r 0x0b, 0, 2, x0, x1, x0"
               : "+f"(d0), "+f"(d1), "+f"(d2), "+f"(d3), "+f"(d4), "+f"(d5),
                 "+f"(d6), "+f"(d7)
               : "f"(a0), "f"(a1), "f"(a2), "f"(a3), "f"(a4), "f"(a5), "f"(a6),
                 "f"(a7), "f"(b0), "f"(b1), "f"(b2), "f"(b3)
               : "memory");

  d[0] = d0;
  d[1] = d1;
  d[2] = d2;
  d[3] = d3;
  d[4] = d4;
  d[5] = d5;
  d[6] = d6;
  d[7] = d7;
}
#endif // Vortex 2.0 TCU wrappers

// Float atomic add helper.
// RISC-V "A" extension has no native float atomic add. The default LLVM
// lowering of `atomicrmw fadd` produces a cmpxchg (LR/SC) loop whose
// inner `bnez` retry diverges within a warp; Vortex BR uses the
// last-active-lane to decide branches → livelock when multiple lanes
// contend on the same float address.
//
// This helper serializes the RMW two ways:
//   1. Within a warp: lane-by-lane (only lane==k executes per iteration)
//   2. Across warps/cores: spinlock acquired inside the per-lane region,
//      so the spin's branch is single-threaded and uniform (no divergence).
static volatile int __cuda_atomic_fadd_lock __attribute__((aligned(4))) = 0;

extern "C" __attribute__((noinline))
float __cuda_atomic_fadd_f32(float *addr, float val) {
  int lane = vx_thread_id();
  float old = 0.0f;
  for (int k = 0; k < 32; k++) {
    if (lane == k) {
      // Single active thread here; spin to acquire global lock.
      while (__atomic_exchange_n((int *)&__cuda_atomic_fadd_lock, 1,
                                 __ATOMIC_ACQUIRE) != 0) { }
      old = *addr;
      *addr = old + val;
      __atomic_store_n((int *)&__cuda_atomic_fadd_lock, 0, __ATOMIC_RELEASE);
    }
  }
  return old;
}

// ── Warp-sum over the ACTIVE lanes only ─────────────────────────────────────
// Vortex 3.0's SHFL yields the reader's OWN value when the source lane is
// inactive (simx alu_unit.cpp: "a masked source lane yields the reader's own
// value"); 2.0 returned the inactive lane's stale register, which the two
// warp-reduced atomic fast paths below relied on being 0. A butterfly over a
// partially active warp therefore double-counts on 3.0: a single active lane
// ends up with 32x its value (jacobi SCHE_2 reported error x sqrt(32)).
// Full warps keep the log2(NT)-step butterfly; partial warps gather the
// active lanes' values with idx shuffles. `active` is uniform across the
// warp, so the gather loop does not diverge.
static inline __attribute__((always_inline))
unsigned __vx_full_warp_mask(void) {
  unsigned nt = (unsigned)vx_num_threads();
  return (nt >= 32u) ? 0xFFFFFFFFu : ((1u << nt) - 1u);
}

static inline __attribute__((always_inline))
float __vx_warp_sum_active_f32(float val, unsigned active) {
  if (active == __vx_full_warp_mask()) {
    for (int i = (int)vx_num_threads() >> 1; i > 0; i >>= 1)
      val += __shfl_xor_sync(0xFFFFFFFF, val, i, 31);
    return val;
  }
  float sum = 0.0f;
  for (unsigned m = active; m != 0u; m &= m - 1u)
    sum += __shfl_sync(0xFFFFFFFF, val, (int)__builtin_ctz(m), 31);
  return sum;
}

static inline __attribute__((always_inline))
unsigned long long __vx_warp_sum_active_u64(unsigned long long val, unsigned active) {
  if (active == __vx_full_warp_mask()) {
    for (int i = (int)vx_num_threads() >> 1; i > 0; i >>= 1) {
      int lo = (int)(unsigned int)val;
      int hi = (int)(unsigned int)(val >> 32);
      unsigned int rlo = (unsigned int)__shfl_xor_sync(0xFFFFFFFF, lo, i, 31);
      unsigned int rhi = (unsigned int)__shfl_xor_sync(0xFFFFFFFF, hi, i, 31);
      val += ((unsigned long long)rhi << 32) | rlo;
    }
    return val;
  }
  unsigned long long sum = 0ull;
  for (unsigned m = active; m != 0u; m &= m - 1u) {
    int l = (int)__builtin_ctz(m);
    int lo = (int)(unsigned int)val;
    int hi = (int)(unsigned int)(val >> 32);
    unsigned int rlo = (unsigned int)__shfl_sync(0xFFFFFFFF, lo, l, 31);
    unsigned int rhi = (unsigned int)__shfl_sync(0xFFFFFFFF, hi, l, 31);
    sum += ((unsigned long long)rhi << 32) | rlo;
  }
  return sum;
}

// Warp-reduced fast path for the common case: uniform address + unused return.
// All 32 lanes add to the SAME `addr`, reduce within the warp first via
// shfl_xor butterfly, then only lane 0 takes the global lock and does the
// single add. ~30x faster than the lane-serialized path because it collapses
// 32 lock acquires into 1 (per warp) and avoids inter-lane contention.
//
// Called by lower_atomicrmw_fadd when RMW->use_empty() AND pointer is
// a function argument (uniform across warp). Unsafe to use when the
// pointer varies per lane.
extern "C" __attribute__((noinline, convergent))
void __cuda_atomic_fadd_f32_uniform_void(float *addr, float val) {
  // Warp reduction over the active lanes (see __vx_warp_sum_active_f32).
  unsigned active = (unsigned)vx_active_threads();
  val = __vx_warp_sum_active_f32(val, active);
  // Lowest active lane issues lock-free CAS-based atomic add.
  // Spinlock approach (originally here) deadlocks under multi-warp
  // contention in simx — Vortex's vx_split_n + global spinlock interaction
  // never releases the lock if the holder's vx_join is gated on lanes that
  // are themselves spinning. CAS has no shared lock state so cannot deadlock.
  // The cmpxchg-bnez divergence issue (per atomic_float_cas_hang.md) only
  // applies when MANY lanes do cmpxchg concurrently; here only ONE lane
  // executes the CAS, so no divergence.
  unsigned issuer = (unsigned)__builtin_ctz(active);
  if ((unsigned)vx_thread_id() == issuer) {
    int *iaddr = (int *)addr;
    int expected = __atomic_load_n(iaddr, __ATOMIC_RELAXED);
    int desired;
    do {
      float curr = *reinterpret_cast<float *>(&expected);
      float next = curr + val;
      desired = *reinterpret_cast<int *>(&next);
    } while (!__atomic_compare_exchange_n(iaddr, &expected, desired, false,
                                          __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE));
  }
}

// i64 atomic add fastpath: same pattern as the float version above.
// RV64 has native amoadd.d so no software lock is needed — lane 0 just
// issues a single hardware atomic with the warp-reduced sum.
//
// Called by lower_atomicrmw_add_i64 when RMW->use_empty() AND pointer is
// uniform across the warp. Targets marchingCubes generatingTriangles'
// `atomicAdd(triangles, ...)` (uniform addr, per-lane value, divergent
// loop) — collapses up to 32 atomic ops into 1 per warp.
//
// Warp reduction operates on i64 by splitting into two i32 halves,
// shfl-xoring each half independently, and recombining; the existing
// __shfl_xor_sync wrapper only takes int.
extern "C" __attribute__((noinline, convergent))
void __cuda_atomic_add_u64_uniform_void(unsigned long long *addr,
                                        unsigned long long val) {
  // marchingCubes generatingTriangles calls this from inside a divergent
  // `for c0 < numTriangles` loop. Lane 0 may be inactive (numTriangles=0)
  // while lanes 1-31 are still iterating, so reduce over the ACTIVE lanes
  // (see __vx_warp_sum_active_u64) and key the atomic off the lowest one.
  unsigned active = (unsigned)vx_active_threads();
  val = __vx_warp_sum_active_u64(val, active);
  unsigned issuer = (unsigned)__builtin_ctz(active);
  if ((unsigned)vx_thread_id() == issuer) {
    __atomic_fetch_add(addr, val, __ATOMIC_RELAXED);
  }
}

// =============================================================================
// mma.sync lowering for lifted (CuLifter) kernels
// =============================================================================
// CuLifter emits SASS HMMA as the NVPTX intrinsics
//   llvm.nvvm.mma.m16n8k16.row.col.f32.f32  (sm_80: A 4x<2 x half>, B 2x<2 x half>, C/D 4xf32)
//   llvm.nvvm.mma.m16n8k8.row.col.f32.f32   (sm_75: A 2x<2 x half>, B 1x<2 x half>, C/D 4xf32)
// and SASS MOVM as the inline asm `movmatrix.sync.aligned.m8n8.trans.b16`.
// kernelTranslator (replace_nvvm_mma_intrinsics / replace_asm_call) lowers them to the helpers
// below. Fragment layouts are the PTX ISA ones: groupID = lane >> 2, tig = lane & 3,
//   A(16xK,row): a0 = A[g][2t..2t+1], a1 = A[g+8][2t..], a2 = A[g][2t+8..], a3 = A[g+8][2t+8..]
//   B(Kx8,col):  b0 = B[2t..2t+1][g], b1 = B[2t+8..][g]
//   C/D(16x8):   c0 = C[g][2t], c1 = C[g][2t+1], c2 = C[g+8][2t], c3 = C[g+8][2t+1]
// (low 16 bits of a register = the lower column/row index). This is the software reference:
// fp32 FMAs over hardware index shuffles, SCHE_2 / 1:1 only (lane = hardware thread, all 32
// lanes active, as mma.sync requires). A TCU-backed variant can replace it behind the same
// symbols; keep the two numerically comparable (products exact in fp32, k-ordered sums).
// Three symbols per shape: <name>_sw (this reference), <name>_tcu (TCU-backed, TCU builds only) and
// <name> (dispatch: _tcu when available unless CUPBOP_MMA_SW is defined). kernelTranslator picks the
// suffix from CUPBOP_MMA_LOWERING=auto|sw|tcu.
// %laneid for the 1:1 schedule: the hardware lane, like the shuffle/vote wrappers above.
extern "C" __attribute__((always_inline)) int __cupbop_laneid() { return vx_thread_id(); }

static inline float __cupbop_f16_to_f32(uint32_t h) {
  h &= 0xffffu;
  uint32_t sign = (h & 0x8000u) << 16, e = (h >> 10) & 0x1fu, m = h & 0x3ffu, bits;
  if (e == 0) {
    if (m == 0) {
      bits = sign;
    } else { // subnormal: value = m * 2^-24
      int sh = 0;
      while (!(m & 0x400u)) { m <<= 1; ++sh; }
      bits = sign | ((uint32_t)(113 - sh) << 23) | ((m & 0x3ffu) << 13);
    }
  } else if (e == 31) {
    bits = sign | 0x7f800000u | (m << 13);
  } else {
    bits = sign | ((e + 112u) << 23) | (m << 13);
  }
  float f;
  __builtin_memcpy(&f, &bits, 4);
  return f;
}
static inline uint32_t __cupbop_shfl32(uint32_t v, int src_lane) {
  return (uint32_t)vx_shfl_idx((size_t)v, src_lane, 31, 0); // full-warp index gather
}

// movmatrix.sync.aligned.m8n8.trans.b16: 8x8 b16 matrix, lane holds M[g][2t..2t+1]; result is the
// transpose in the same layout, i.e. {M[2t][g], M[2t+1][g]}.
extern "C" __attribute__((always_inline)) uint32_t __cupbop_movmatrix_m8n8_trans_b16(uint32_t a) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const uint32_t x = __cupbop_shfl32(a, ((2 * t) << 2) | (g >> 1));     // owner of M[2t][g]
  const uint32_t y = __cupbop_shfl32(a, ((2 * t + 1) << 2) | (g >> 1)); // owner of M[2t+1][g]
  const int sh = 16 * (g & 1);
  return ((x >> sh) & 0xffffu) | (((y >> sh) & 0xffffu) << 16);
}

// D = A(16x16,f16,row) * B(16x8,f16,col) + C(16x8,f32)
extern "C" __attribute__((always_inline)) void __cupbop_mma_m16n8k16_f16f32_sw(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3,
                                             uint32_t b0, uint32_t b1,
                                             float c0, float c1, float c2, float c3, float *d) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const int la = g << 2, lb0 = (2 * t) << 2, lb1 = (2 * t + 1) << 2;
  float d0 = c0, d1 = c1, d2 = c2, d3 = c3;
  for (int kk = 0; kk < 8; ++kk) { // k = 2kk, 2kk+1 ; owner tig = kk & 3 ; k >= 8 -> a2/a3, b1
    const int q = kk & 3;
    const uint32_t xa = __cupbop_shfl32(kk < 4 ? a0 : a2, la | q);  // A[g][k..k+1]
    const uint32_t ya = __cupbop_shfl32(kk < 4 ? a1 : a3, la | q);  // A[g+8][k..k+1]
    const uint32_t ub = __cupbop_shfl32(kk < 4 ? b0 : b1, lb0 | q); // B[k..k+1][2t]
    const uint32_t vb = __cupbop_shfl32(kk < 4 ? b0 : b1, lb1 | q); // B[k..k+1][2t+1]
    for (int h = 0; h < 32; h += 16) {
      const float ag = __cupbop_f16_to_f32(xa >> h), ag8 = __cupbop_f16_to_f32(ya >> h);
      const float bn0 = __cupbop_f16_to_f32(ub >> h), bn1 = __cupbop_f16_to_f32(vb >> h);
      d0 += ag * bn0; d1 += ag * bn1; d2 += ag8 * bn0; d3 += ag8 * bn1;
    }
  }
  d[0] = d0; d[1] = d1; d[2] = d2; d[3] = d3;
}

// D = A(16x8,f16,row) * B(8x8,f16,col) + C(16x8,f32)
extern "C" __attribute__((always_inline)) void __cupbop_mma_m16n8k8_f16f32_sw(uint32_t a0, uint32_t a1, uint32_t b0,
                                            float c0, float c1, float c2, float c3, float *d) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const int la = g << 2, lb0 = (2 * t) << 2, lb1 = (2 * t + 1) << 2;
  float d0 = c0, d1 = c1, d2 = c2, d3 = c3;
  for (int kk = 0; kk < 4; ++kk) { // k = 2kk, 2kk+1 ; owner tig = kk
    const uint32_t xa = __cupbop_shfl32(a0, la | kk);
    const uint32_t ya = __cupbop_shfl32(a1, la | kk);
    const uint32_t ub = __cupbop_shfl32(b0, lb0 | kk);
    const uint32_t vb = __cupbop_shfl32(b0, lb1 | kk);
    for (int h = 0; h < 32; h += 16) {
      const float ag = __cupbop_f16_to_f32(xa >> h), ag8 = __cupbop_f16_to_f32(ya >> h);
      const float bn0 = __cupbop_f16_to_f32(ub >> h), bn1 = __cupbop_f16_to_f32(vb >> h);
      d0 += ag * bn0; d1 += ag * bn1; d2 += ag8 * bn0; d3 += ag8 * bn1;
    }
  }
  d[0] = d0; d[1] = d1; d[2] = d2; d[3] = d3;
}

// ---- TCU-backed variant ----------------------------------------------------------------------
#if defined(VX_CFG_NUM_THREADS) && defined(VX_CFG_EXT_TCU_ENABLE)
// vx_tensor.h layouts for NT=32, NR=8, fp16->fp32 (tcM=8, tcN=4, tcK=4, tile m16n16k32), lane l,
// g = l>>2, t = l&3:
//   A  reg r : row g + 8*(r>>2),  k = 8*(r&3) + 2t + {0,1}   (low half = lower k)
//   B  reg r : k = 8*(r>>1) + 2t + {0,1},  n = g + 8*(r&1)    (pack_row: low half = lower k)
//   C/D reg r: row g + 8*(r>>2),  col t + 4*(r&3)
// The PTX m16n8k16 fragments of the *same lane* are A: a0=(g,2t..) a1=(g+8,2t..) a2=(g,2t+8..)
// a3=(g+8,2t+8..) and B: b0=(2t..,g) b1=(2t+8..,g), so A and B map register-for-register:
//   fa = {a0, a2, 0, 0, a1, a3, 0, 0}   (k >= 16 zero)      fb = {b0, 0, b1, 0, 0, 0, 0, 0}   (n >= 8, k >= 16 zero)
// Only the accumulator columns differ (PTX: 2t, 2t+1 ; Vortex: t, t+4), hence 8 shuffles in and 8 out.
// The padded three quarters of the tile cost nothing extra: one macro-op either way. Fusing the two
// N-halves (and two K-steps) that CuLifter emits as separate mma calls would fill the tile; that
// needs the translator to pair calls and is a later recipe option.
static_assert(tcu_ctx::tileM == 16 && tcu_ctx::tileN == 16 && tcu_ctx::tileK == 32, "TCU-backed mma.sync helpers assume the NT=32 m16n16k32 tile");
static_assert(tcu_ctx::fragment_a::NR == 8 && tcu_ctx::fragment_b::NR == 8 && tcu_ctx::fragment_acc::NR == 8, "8 registers per fragment");
static inline float __cupbop_u32_as_f32(uint32_t u) { float f; __builtin_memcpy(&f, &u, 4); return f; }
static inline float __cupbop_shflf(float v, int src_lane) {
  uint32_t u; __builtin_memcpy(&u, &v, 4);
  u = __cupbop_shfl32(u, src_lane);
  float f; __builtin_memcpy(&f, &u, 4); return f;
}
// PTX accumulator (c0=(g,2t) c1=(g,2t+1) c2=(g+8,2t) c3=(g+8,2t+1)) -> Vortex acc regs 0,1,4,5 (cols t, t+4)
static inline void __cupbop_acc_nv_to_vx(float c0, float c1, float c2, float c3, tcu_ctx::fragment_acc &fc) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const int s0 = (g << 2) | (t >> 1), s1 = (g << 2) | ((t >> 1) + 2); // owners of col t and col t+4
  const bool odd = t & 1;                                              // their slot
  const float x0 = __cupbop_shflf(c0, s0), x1 = __cupbop_shflf(c1, s0);
  const float y0 = __cupbop_shflf(c0, s1), y1 = __cupbop_shflf(c1, s1);
  const float z0 = __cupbop_shflf(c2, s0), z1 = __cupbop_shflf(c3, s0);
  const float w0 = __cupbop_shflf(c2, s1), w1 = __cupbop_shflf(c3, s1);
  fc.data[0] = odd ? x1 : x0; fc.data[1] = odd ? y1 : y0; fc.data[2] = 0.f; fc.data[3] = 0.f;
  fc.data[4] = odd ? z1 : z0; fc.data[5] = odd ? w1 : w0; fc.data[6] = 0.f; fc.data[7] = 0.f;
}
// Vortex acc regs -> PTX d0..d3
static inline void __cupbop_acc_vx_to_nv(const tcu_ctx::fragment_acc &fd, float *d) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const int u0 = (g << 2) | ((2 * t) & 3), u1 = u0 + 1; // holders of col 2t and 2t+1
  const bool hi = t >> 1;                               // in reg 1/5 (col >= 4) or reg 0/4
  const float p0 = __cupbop_shflf(fd.data[0], u0), p1 = __cupbop_shflf(fd.data[1], u0);
  const float q0 = __cupbop_shflf(fd.data[0], u1), q1 = __cupbop_shflf(fd.data[1], u1);
  const float r0 = __cupbop_shflf(fd.data[4], u0), r1 = __cupbop_shflf(fd.data[5], u0);
  const float v0 = __cupbop_shflf(fd.data[4], u1), v1 = __cupbop_shflf(fd.data[5], u1);
  d[0] = hi ? p1 : p0; d[1] = hi ? q1 : q0; d[2] = hi ? r1 : r0; d[3] = hi ? v1 : v0;
}
extern "C" __attribute__((always_inline)) void __cupbop_mma_m16n8k16_f16f32_tcu(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3,
                                                 uint32_t b0, uint32_t b1,
                                                 float c0, float c1, float c2, float c3, float *d) {
  tcu_ctx::fragment_a fa; tcu_ctx::fragment_b fb; tcu_ctx::fragment_acc fc, fd;
  fa.data = {{__cupbop_u32_as_f32(a0), __cupbop_u32_as_f32(a2), 0.f, 0.f, __cupbop_u32_as_f32(a1), __cupbop_u32_as_f32(a3), 0.f, 0.f}};
  fb.data = {{__cupbop_u32_as_f32(b0), 0.f, __cupbop_u32_as_f32(b1), 0.f, 0.f, 0.f, 0.f, 0.f}};
  __cupbop_acc_nv_to_vx(c0, c1, c2, c3, fc);
  tcu_ctx::mma_sync(fd, fa, fb, fc);
  __cupbop_acc_vx_to_nv(fd, d);
}
extern "C" __attribute__((always_inline)) void __cupbop_mma_m16n8k8_f16f32_tcu(uint32_t a0, uint32_t a1, uint32_t b0,
                                                float c0, float c1, float c2, float c3, float *d) {
  tcu_ctx::fragment_a fa; tcu_ctx::fragment_b fb; tcu_ctx::fragment_acc fc, fd;
  fa.data = {{__cupbop_u32_as_f32(a0), 0.f, 0.f, 0.f, __cupbop_u32_as_f32(a1), 0.f, 0.f, 0.f}};
  fb.data = {{__cupbop_u32_as_f32(b0), 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f}};
  __cupbop_acc_nv_to_vx(c0, c1, c2, c3, fc);
  tcu_ctx::mma_sync(fd, fa, fb, fc);
  __cupbop_acc_vx_to_nv(fd, d);
}
#define CUPBOP_MMA_TCU_AVAILABLE 1
#endif // TCU-backed variant

// ---- dispatch symbols (what kernelTranslator emits for CUPBOP_MMA_LOWERING=auto) ----------------
extern "C" __attribute__((always_inline)) void __cupbop_mma_m16n8k16_f16f32(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3,
                                             uint32_t b0, uint32_t b1,
                                             float c0, float c1, float c2, float c3, float *d) {
#if defined(CUPBOP_MMA_TCU_AVAILABLE) && !defined(CUPBOP_MMA_SW)
  __cupbop_mma_m16n8k16_f16f32_tcu(a0, a1, a2, a3, b0, b1, c0, c1, c2, c3, d);
#else
  __cupbop_mma_m16n8k16_f16f32_sw(a0, a1, a2, a3, b0, b1, c0, c1, c2, c3, d);
#endif
}
extern "C" __attribute__((always_inline)) void __cupbop_mma_m16n8k8_f16f32(uint32_t a0, uint32_t a1, uint32_t b0,
                                            float c0, float c1, float c2, float c3, float *d) {
#if defined(CUPBOP_MMA_TCU_AVAILABLE) && !defined(CUPBOP_MMA_SW)
  __cupbop_mma_m16n8k8_f16f32_tcu(a0, a1, b0, c0, c1, c2, c3, d);
#else
  __cupbop_mma_m16n8k8_f16f32_sw(a0, a1, b0, c0, c1, c2, c3, d);
#endif
}

// =============================================================================
// Hopper warpgroup forms: cvta.to.shared, wgmma.mma_async (sgemm_wgmma and lifted sm_90a kernels)
// =============================================================================
// Shared-memory window address: Vortex local memory is the shared window, so the 32-bit
// "shared" address of a pointer is its byte offset from the local memory base (<= 256 KB fits
// the 18-bit descriptor address field). kernelTranslator lowers the cvta.to.shared asm to this.
extern "C" __attribute__((always_inline)) uint32_t __cupbop_cvta_to_shared(const void *p) {
  return (uint32_t)((uintptr_t)p - (uintptr_t)csr_read(VX_CSR_LOCAL_MEM_BASE));
}

#if defined(VX_CFG_NUM_THREADS) && defined(VX_CFG_EXT_TCU_ENABLE)
// PTX matrix descriptor (wgmma smem operand): [13:0] addr>>4, [29:16] LBO>>4, [45:32] SBO>>4,
// [63:62] swizzle. Canonical no-swizzle K-major layout: 8-row x 16-byte core matrices, LBO = next
// core matrix along K, SBO = next 8-row group; element (r,k) at (r>>3)*SBO + (k>>3)*LBO + (r&7)*16 + (k&7)*2.
struct __cupbop_smem_desc { const char *base; uint32_t lbo, sbo, swz; };
static inline __cupbop_smem_desc __cupbop_decode_desc(uint64_t d) {
  __cupbop_smem_desc m;
  m.base = (const char *)csr_read(VX_CSR_LOCAL_MEM_BASE) + ((d & 0x3FFFu) << 4);
  m.lbo = (uint32_t)((d >> 16) & 0x3FFFu) << 4;
  m.sbo = (uint32_t)((d >> 32) & 0x3FFFu) << 4;
  m.swz = (uint32_t)(d >> 62);
  return m;
}
static inline float __cupbop_core_ld(const __cupbop_smem_desc &m, int r, int k) { // fp16 pair (k, k+1), k even
  uint32_t v = *(const uint32_t *)(m.base + (r >> 3) * m.sbo + (k >> 3) * m.lbo + (r & 7) * 16 + (k & 7) * 2);
  float f; __builtin_memcpy(&f, &v, 4); return f;
}
// wgmma.mma_async.sync.aligned.m64nNk16.f32.f16.f16 with K-major A (64x16) and B (Nx16, i.e. KxN
// column-major) in shared memory, no swizzle. Warp `warp_in_wg` of the warpgroup owns rows
// 16w..16w+15 and computes them as N/16 TCU m16n16k16 ops (the k32 tile's upper half zero).
// acc: N/2 fp32 per thread, in/out, PTX accumulator layout
//   acc[4j+0] = (g, 8j+2t)  acc[4j+1] = (g, 8j+2t+1)  acc[4j+2] = (g+8, 8j+2t)  acc[4j+3] = (g+8, 8j+2t+1)
// Vortex acc reg r = (g + 8*(r>>2), t + 4*(r&3)) within a 16-column block, hence the shuffles.
// scale_d = 0 ignores the incoming accumulator (D = A*B). Synchronous: the translator drops
// wgmma.fence / commit_group / wait_group and fence.proxy.async.
extern "C" __attribute__((always_inline)) void __cupbop_wgmma_m64nNk16_f16f32(int n_cols, uint64_t desc_a, uint64_t desc_b, int scale_d,
                                               int warp_in_wg, float *acc) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const __cupbop_smem_desc A = __cupbop_decode_desc(desc_a), B = __cupbop_decode_desc(desc_b);
  const int row0 = 16 * warp_in_wg;
  tcu_ctx::fragment_a fa; // reg r: row g + 8*(r>>2), k = 8*(r&3) + 2t ; k >= 16 zero
  fa.data = {{__cupbop_core_ld(A, row0 + g, 2 * t), __cupbop_core_ld(A, row0 + g, 8 + 2 * t), 0.f, 0.f,
              __cupbop_core_ld(A, row0 + g + 8, 2 * t), __cupbop_core_ld(A, row0 + g + 8, 8 + 2 * t), 0.f, 0.f}};
  const bool odd = t & 1, hi = t >> 1;
  for (int nb = 0; nb < n_cols / 16; ++nb) {
    const int n0 = 16 * nb;
    tcu_ctx::fragment_b fb; // reg r: k = 8*(r>>1) + 2t, n = g + 8*(r&1) ; k >= 16 zero
    fb.data = {{__cupbop_core_ld(B, n0 + g, 2 * t), __cupbop_core_ld(B, n0 + g + 8, 2 * t),
                __cupbop_core_ld(B, n0 + g, 8 + 2 * t), __cupbop_core_ld(B, n0 + g + 8, 8 + 2 * t), 0.f, 0.f, 0.f, 0.f}};
    tcu_ctx::fragment_acc fc, fd;
    if (scale_d) {
      for (int r = 0; r < 8; ++r) { // Vortex reg r <- PTX owner lane (g, cc>>1), slot cc&1, cc = t + 4*((r&3)&1), j = 2nb + ((r&3)>>1)
        const int jl = (r & 3) >> 1, q = (r & 3) & 1;
        const int src = (g << 2) | ((t >> 1) + 2 * q);
        const int base = 4 * (2 * nb + jl) + 2 * (r >> 2);
        const float v0 = __cupbop_shflf(acc[base], src), v1 = __cupbop_shflf(acc[base + 1], src);
        fc.data[r] = odd ? v1 : v0;
      }
    } else {
      for (int r = 0; r < 8; ++r) fc.data[r] = 0.f;
    }
    tcu_ctx::mma_sync(fd, fa, fb, fc);
    for (int jl = 0; jl < 2; ++jl) { // PTX acc[4j+s] <- Vortex holder lane (g, c&3), reg 4*(s>>1) + (c>>2), c = 8jl + 2t + (s&1)
      const int j = 2 * nb + jl;
      for (int s = 0; s < 4; ++s) {
        const int c = 8 * jl + 2 * t + (s & 1);
        const int src = (g << 2) | (c & 3), rb = 4 * (s >> 1) + 2 * jl;
        const float p0 = __cupbop_shflf(fd.data[rb], src), p1 = __cupbop_shflf(fd.data[rb + 1], src);
        acc[4 * j + s] = hi ? p1 : p0;
      }
    }
  }
}
#endif // wgmma (TCU builds)
