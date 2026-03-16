# CuPBoP-Vortex: Remaining Issues and Implementation Plan

## Overview

After the March 2026 debugging session, CuPBoP-Vortex passes 41/41 benchmarks
(11 CI + 30 stress tests) with workarounds. Three Vortex-side bugs need proper
fixes, and several CUDA features needed by CUTLASS are unimplemented.

---

## Part A: Vortex-Side Bugs (need Vortex source changes)

### A1. LMEM Addressing Wrap Bug

**File:** `sim/simx/local_mem.cpp:32`

**Bug:** `to_local_addr()` extracts `log2(capacity / line_size)` address bits instead
of `log2(capacity)` bits. With LMEM_LOG_SIZE=14 (16KB) and LSU_WORD_SIZE=8,
only 2048 bytes are addressable. Addresses >= 2048 alias back to 0.

**Impact:** Any shared memory allocation > 2KB produces wrong results. The 3rd
shared array overwrites the 1st.

**Current workaround:** Build simx with `-DLMEM_LOG_SIZE=17`.

**Fix:**
```cpp
// local_mem.cpp line 31-33, change:
uint64_t to_local_addr(uint64_t addr) {
    return bit_getw(addr, 0, line_bits_-1);
}
// to:
uint64_t to_local_addr(uint64_t addr) {
    uint32_t addr_bits = log2ceil(config_.capacity);
    return bit_getw(addr, 0, addr_bits - 1);
}
```

**Risk:** Low. Only changes the address masking width. Should not affect any
other simx behavior since the RAM already has `capacity` bytes allocated.

**Testing:** Run shared_multiarray (3 arrays, 3072 bytes) without the
LMEM_LOG_SIZE=17 workaround.

---

### A2. vx_spawn_threads Block Size Check

**File:** `kernel/src/vx_spawn.c:198`

**Bug:** `vx_spawn_threads` rejects `group_size > threads_per_core` with
`return -1`, even though Vortex hardware can schedule oversized blocks by
batching warps across multiple iterations.

**Impact:** vecadd, saxpy, conv3, bfs (all use 512 threads/block) fail on
simx with NUM_WARPS=64 (256 threads/core).

**Current workaround:** CuPBoP runtime warns instead of aborting. But the
kernel-side check still kills execution.

**Fix:** In `vx_spawn.c`, replace the hard error with batched scheduling:
```c
// Line 198, change:
if (threads_per_core < group_size) {
    vx_printf("error: group_size > threads_per_core (%d,%d)\n", ...);
    return -1;
}
// to: allow batching — schedule warps_per_group warps at a time
// When group_size > threads_per_core, process the block in multiple
// warp batches, using barriers to synchronize between batches.
```

**Challenges:**
- The current grouped execution path assumes all warps in a group can run
  simultaneously. With batching, barrier semantics change — a barrier must
  wait for all batches, not just currently-running warps.
- `__syncthreads()` maps to `vx_barrier(group_id, warps_per_group)`. If
  warps_per_group exceeds hardware warps, the barrier count parameter is
  wrong. Need to handle this in the barrier hardware or software.
- Thread-local storage (TLS) setup for batched warps must correctly assign
  `threadIdx` values beyond the first batch.

**Risk:** Medium-high. Barrier semantics are the hardest part. May require
changes to both `vx_spawn.c` and the barrier hardware model in simx.

**Alternative:** Just increase NUM_WARPS. But NUM_WARPS=128 currently produces
wrong results in simx (a separate issue to investigate).

---

### A3. LLVM Vortex CSR Name Collision

**File:** LLVM Vortex backend CSR register definitions (likely in
`lib/Target/RISCV/RISCVSystemOperands.td` or similar)

**Bug:** CSR 0xFC3 (`VX_CSR_LOCAL_MEM_BASE`) and CSR 0xFC1 (`VX_CSR_NUM_WARPS`)
both map to assembly name `nw`. When the compiler emits text assembly
(via `-save-temps`), the assembler encodes `nw` as 0xFC1.

**Impact:** `vx_local_alloc()` reads NUM_WARPS (64) instead of the LMEM base
address (0x1FFFF0000). Shared memory writes hit IO_COUT range (0x40-0x7F),
crashing simx.

**Current workaround:** Don't use `-save-temps` for kernel_wrapper compilation.

**Fix:** In the Vortex LLVM backend's CSR definition table, give 0xFC3 a
unique name (e.g., `lmem_base` instead of `nw`). Check all custom Vortex CSRs
(0xFC0-0xFFF range) for duplicate name mappings.

**Risk:** Low. Just a name table fix. No behavioral change.

---

## Part B: CuPBoP Feature Gaps for CUTLASS

### B1. Half-Precision (FP16) Operations — HIGH PRIORITY

**CUTLASS usage:** 47 intrinsic calls across core tensor operation files.

**Intrinsics needed:**
- `__hfma2(a, b, c)` — half2 fused multiply-add (23 uses)
- `__hmul2(a, b)` — half2 multiply (8 uses)
- `__hmul(a, b)` — half multiply (12 uses)
- `__hfma(a, b, c)` — half fused multiply-add (2 uses)
- `__hfma2_relu(a, b, c)` — half2 FMA with ReLU (4 uses)
- `__hfma_relu(a, b, c)` — half FMA with ReLU (4 uses)

**NVVM IR form:** These appear as calls to `__nv_*` functions or as
`llvm.nvvm.*` intrinsics for half/half2 types.

**Implementation approach:**
1. In `tool.cpp`, detect half-precision NVVM intrinsics
2. Replace with standard LLVM FP16 operations:
   - `__hfma(a,b,c)` → `@llvm.fma.f16(a, b, c)`
   - `__hmul(a,b)` → `fmul half a, b`
   - `__hfma2` → operate on `<2 x half>` vector type
   - `_relu` variants → `fma` followed by `maxnum(result, 0.0)`

**Challenges:**
- RISC-V `rv64imafd` does NOT include the `Zfh` (half-precision float)
  extension. The Vortex LLVM backend may not support `half` type natively.
- Without hardware FP16, the compiler must either:
  (a) Promote to float32, compute, demote back — loses performance but works
  (b) Use soft-float FP16 emulation — very slow on simx
- The `half2` type (`<2 x half>`) is a packed vector. RISC-V has no native
  packed-half SIMD. Must unpack, compute as float, repack.
- CUTLASS uses FP16 extensively in GEMM inner loops. Promoting to FP32
  changes numerical behavior and may break CUTLASS's expected precision.

**Estimated effort:** Medium-high. The promotion approach is straightforward
in LLVM IR but may cause subtle precision issues.

---

### B2. Atomic Operations — HIGH PRIORITY

**CUTLASS usage:** 43 total (20 atomicAdd, 12 atomicCAS, 11 atomicMax).

**NVVM IR form:**
- `atomicAdd` → `atomicrmw add ptr %p, float %val seq_cst`
- `atomicCAS` → `cmpxchg ptr %p, i32 %expected, i32 %desired seq_cst`
- `atomicMax` → `atomicrmw max ptr %p, i32 %val seq_cst`

**Implementation approach:**
Vortex supports RISC-V atomic instructions (A extension: `amoadd.w`,
`amomax.w`, `lr/sc`). The LLVM backend should lower these automatically.

The issue is that CuPBoP's `replace_built_in_function` might strip or
rename atomic operations. Need to verify that atomicrmw and cmpxchg
instructions pass through the translation unchanged.

For `atomicAdd` on **float**: RISC-V A extension only supports integer
atomics. Float atomicAdd requires a compare-and-swap loop:
```c
float atomicAdd_float(float *addr, float val) {
    uint32_t *iaddr = (uint32_t *)addr;
    uint32_t old, assumed;
    old = *iaddr;
    do {
        assumed = old;
        float new_val = __int_as_float(assumed) + val;
        old = atomicCAS(iaddr, assumed, __float_as_int(new_val));
    } while (assumed != old);
    return __int_as_float(old);
}
```

**Challenges:**
- Float atomicAdd needs CAS loop emulation (no hardware support)
- Memory ordering: CUDA uses relaxed atomics by default, but RISC-V
  `amo` instructions have acquire/release semantics. May need `fence`
  instructions for correct ordering.
- In the Vortex simx, atomic operations go through the memory hierarchy.
  Need to verify simx correctly handles `amoadd.w` on shared (LMEM)
  and global memory.
- CuPBoP currently doesn't have atomic operation tests.

**Estimated effort:** Medium. Integer atomics should "just work" if LLVM
lowers them correctly. Float atomicAdd needs the CAS loop wrapper.

---

### B3. Warp Shuffle (i64/f64 variants) — MEDIUM PRIORITY

**Current state:** i32 and f32 shuffle variants are already handled by
`warp_func.cpp`. The i64 and f64 variants are not.

**Implementation:** Extend the existing shuffle replacement to handle
64-bit types by doing two 32-bit shuffles (low and high halves).

**Estimated effort:** Low.

---

### B4. Bit Operations — LOW PRIORITY

**CUTLASS usage:** 7 total (__ffs: 2, __popc: 5).

**Intrinsics needed:**
- `__ffs(x)` — find first set bit → `llvm.cttz` + 1
- `__popc(x)` — population count → `llvm.ctpop`
- `__clz(x)` — count leading zeros → `llvm.ctlz`
- `__brev(x)` — bit reverse → `llvm.bitreverse`

**Implementation:** In `tool.cpp`, replace `__nv_ffs`, `__nv_popc` calls
(currently removed via `deleteBody()`) with proper LLVM intrinsic calls.

**Current bug:** `tool.cpp` line 736 calls `deleteBody()` on these functions,
which removes the implementation but leaves the declaration. If the kernel
actually calls them, it gets a link error or undefined behavior.

**Fix:**
```cpp
// Instead of deleteBody(), replace with LLVM intrinsics:
// __nv_ffs(x) → cttz(x) + 1  (cttz returns 0-based, ffs returns 1-based)
// __nv_popc(x) → ctpop(x)
```

**Estimated effort:** Low. Straightforward intrinsic replacement.

---

### B5. Reciprocal with Rounding — LOW PRIORITY

**CUTLASS usage:** 2 uses of `__frcp_rn(x)`.

**NVVM form:** `llvm.nvvm.rcp.rn.f`

**Status:** Already handled by the latest commit (mapped to `1.0 / x`).

---

## Part C: Implementation Order

Recommended order based on impact and difficulty:

| Priority | Task | Effort | Blocking |
|----------|------|--------|----------|
| 1 | A1: Fix LMEM addressing (Vortex) | Low | Removes workaround |
| 2 | A3: Fix CSR name collision (Vortex LLVM) | Low | Removes workaround |
| 3 | B4: Bit operations (__ffs, __popc) | Low | CUTLASS |
| 4 | B2: Integer atomics (atomicAdd i32, atomicCAS, atomicMax) | Medium | CUTLASS |
| 5 | A2: Block size > threads_per_core (Vortex) | Medium-high | vecadd/saxpy/conv3/bfs |
| 6 | B2: Float atomicAdd (CAS loop) | Medium | CUTLASS reductions |
| 7 | B1: Half-precision FP16 | Medium-high | CUTLASS tensor ops |
| 8 | B3: 64-bit shuffle | Low | CUTLASS edge cases |

Items 1-3 can be done in a day. Items 4-6 in a week. Items 7-8 require
more architectural decisions about FP16 support on RISC-V.

---

## Part D: Testing Strategy

Each fix should be verified by:

1. **Targeted stress test** — new benchmark exercising the specific feature
2. **Regression test** — re-run all 41 existing benchmarks
3. **CUTLASS unit test** — try compiling a minimal CUTLASS GEMM kernel

Suggested new stress tests for each feature:
- Atomics: `atomic_sum` (parallel reduction via atomicAdd)
- FP16: `half_gemm` (simple 16x16 GEMM with __half)
- Bit ops: `popcount_test` (population count + find-first-set)
- Large blocks: `block512` (512-thread kernel, needs A2 fix)
