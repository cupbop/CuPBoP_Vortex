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

__attribute__((always_inline)) int __shfl_sync(int mem_mask, int var,
                                               int srcLane, int c) {
  int mask = ~c;
  return vx_shfl_idx((size_t)var, srcLane, c, mask);
}

__attribute__((always_inline)) float __shfl_sync(int mem_mask, float var,
                                                 int srcLane, int c) {
  int mask = ~c;
  int vali = *reinterpret_cast<int *>(&var);
  int ri = vx_shfl_idx(vali, srcLane, c, mask);
  return *reinterpret_cast<float *>(&ri);
}

__attribute__((always_inline)) int __shfl_up_sync(int mem_mask, int var,
                                                  int delta, int c) {
  int mask = ~c;
  return vx_shfl_up((size_t)var, delta, c, mask);
}

__attribute__((always_inline)) float __shfl_up_sync(int mem_mask, float var,
                                                    int delta, int c) {
  int mask = ~c;
  int vali = *reinterpret_cast<int *>(&var);
  int ri = vx_shfl_up(vali, delta, c, mask);
  return *reinterpret_cast<float *>(&ri);
}

__attribute__((always_inline)) int __shfl_down_sync(int mem_mask, int var,
                                                    int delta, int c) {
  int mask = ~c;
  return vx_shfl_down((size_t)var, delta, c, mask);
}

__attribute__((always_inline)) float __shfl_down_sync(int mem_mask, float var,
                                                      int delta, int c) {
  int mask = ~c;
  int vali = *reinterpret_cast<int *>(&var);
  int ri = vx_shfl_down(vali, delta, c, mask);
  return *reinterpret_cast<float *>(&ri);
}

__attribute__((always_inline)) int __shfl_xor_sync(int mem_mask, int var,
                                                   int laneMask, int c) {
  int mask = ~c;
  return vx_shfl_bfly((size_t)var, laneMask, c, mask);
}

__attribute__((always_inline)) float __shfl_xor_sync(int mem_mask, float var,
                                                     int laneMask, int c) {
  int mask = ~c;
  int vali = *reinterpret_cast<int *>(&var);
  int ri = vx_shfl_bfly(vali, laneMask, c, mask);
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
  auto *src = reinterpret_cast<const uint8_t *>(p);

  uint32_t lane = __vx_get_lane_id();

  uint32_t block_row = lane / 4u;
  uint32_t block_col = (lane % 4u) * 2u;

  for (uint32_t r = 0; r < 8; ++r) {
    uint32_t elem_row = block_row + ((r / 4u) * 8u);
    uint32_t elem_col = block_col + ((r % 4u) * 8u);

    uint32_t off = elem_row * static_cast<uint32_t>(ldm) + elem_col;

    // Two contiguous fp16 values = 4 bytes = one packed i32 register.
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
  auto *src = reinterpret_cast<const uint8_t *>(p);

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

    uint16_t h0;
    uint16_t h1;
    __builtin_memcpy(&h0, src + static_cast<uintptr_t>(off0) * 2u, 2);
    __builtin_memcpy(&h1, src + static_cast<uintptr_t>(off1) * 2u, 2);

    // Matches <2 x half> {h0, h1} packed into one i32 on little-endian targets.
    dst[r] = static_cast<uint32_t>(h0) | (static_cast<uint32_t>(h1) << 16);
  }
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

__attribute__((always_inline)) float __vx_bitcast_u32_to_f32(uint32_t x) {
  float f;
  __builtin_memcpy(&f, &x, sizeof(f));
  return f;
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
