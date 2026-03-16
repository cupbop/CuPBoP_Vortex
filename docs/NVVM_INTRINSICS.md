# CuPBoP NVVM Intrinsics Replacement Reference

This document lists all NVVM (NVIDIA Virtual Machine) intrinsics encountered in CUDA code
and how CuPBoP's kernel translator (`tool.cpp`) handles them for RISC-V/Vortex targets.

## Status Legend

- **EXISTING** — handled before this work (original CuPBoP)
- **NEW** — added in this work (March 2026)
- **NOT HANDLED** — not yet implemented, will cause backend crash or link error

---

## 1. Float Arithmetic Intrinsics

### Fused Multiply-Add (FMA)

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.fma.rn.f` | `@llvm.fma.f32(a,b,c)` | **NEW** | Round-to-nearest float FMA |
| `llvm.nvvm.fma.rz.f` | `@llvm.fma.f32(a,b,c)` | **NEW** | Round-to-zero (mapped to rn) |
| `llvm.nvvm.fma.rm.f` | `@llvm.fma.f32(a,b,c)` | **NEW** | Round-to-minus-inf (mapped to rn) |
| `llvm.nvvm.fma.rp.f` | `@llvm.fma.f32(a,b,c)` | **NEW** | Round-to-plus-inf (mapped to rn) |
| `llvm.nvvm.fma.rn.ftz.f` | `@llvm.fma.f32(a,b,c)` | **NEW** | FTZ variant |
| `llvm.nvvm.fma.rz.ftz.f` | `@llvm.fma.f32(a,b,c)` | **NEW** | FTZ variant |
| `llvm.nvvm.fma.rm.ftz.f` | `@llvm.fma.f32(a,b,c)` | **NEW** | FTZ variant |
| `llvm.nvvm.fma.rp.ftz.f` | `@llvm.fma.f32(a,b,c)` | **NEW** | FTZ variant |
| `llvm.nvvm.fma.rn.d` | renamed to `__nvvm_fma_rn_d` | EXISTING | Double FMA, linked from cudaKernelImpl |
| `llvm.nvvm.fma.rz.d` | NOT HANDLED | | |
| `llvm.nvvm.fma.rm.d` | NOT HANDLED | | |
| `llvm.nvvm.fma.rp.d` | NOT HANDLED | | |

### Multiply

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.mul.rn.f` | `fmul float a, b` | **NEW** | Standard float multiply |
| `llvm.nvvm.mul.rz.f` | `fmul float a, b` | **NEW** | Mapped to standard fmul |
| `llvm.nvvm.mul.rm.f` | `fmul float a, b` | **NEW** | Mapped to standard fmul |
| `llvm.nvvm.mul.rp.f` | `fmul float a, b` | **NEW** | Mapped to standard fmul |
| `llvm.nvvm.mul.rn.ftz.f` | `fmul float a, b` | **NEW** | FTZ variant |
| `llvm.nvvm.mul.rz.ftz.f` | `fmul float a, b` | **NEW** | FTZ variant |
| `llvm.nvvm.mul.rm.ftz.f` | `fmul float a, b` | **NEW** | FTZ variant |
| `llvm.nvvm.mul.rp.ftz.f` | `fmul float a, b` | **NEW** | FTZ variant |
| `llvm.nvvm.mul.rn.d` | NOT HANDLED | | Double multiply |
| `llvm.nvvm.mul24.i` | renamed to `__nvvm_mul24_i` | EXISTING | 24-bit integer multiply |

### Add

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.add.rn.f` | `fadd float a, b` | **NEW** | Standard float add |
| `llvm.nvvm.add.rn.ftz.f` | `fadd float a, b` | **NEW** | FTZ variant |
| `llvm.nvvm.add.rn.d` | renamed to `__nvvm_add_rn_d` | EXISTING | Double add |
| Other rounding modes (rz/rm/rp) | NOT HANDLED | | |

### Division

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.div.approx.f` | renamed to `__nvvm_div_approx_f` | EXISTING | Approximate float divide |
| `llvm.nvvm.div.approx.ftz.f` | renamed to `__nvvm_div_approx_ftz_f` | EXISTING | FTZ variant |
| `llvm.nvvm.div.rn.f` | NOT HANDLED | | Exact rounded divide |
| `llvm.nvvm.div.rn.d` | NOT HANDLED | | Double divide |

### Absolute Value

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.fabs.f` | `@llvm.fabs.f32(x)` | **NEW** | Was renamed to `__nvvm_fabs_f` (link error), now replaced inline |
| `llvm.nvvm.fabs.ftz.f` | `@llvm.fabs.f32(x)` | **NEW** | FTZ variant |
| `llvm.nvvm.fabs.d` | NOT HANDLED | | Double fabs |

### Min/Max

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.fmin.f` | renamed to `__nvvm_fmin_f` | EXISTING | Float min |
| `llvm.nvvm.fmin.ftz.f` | renamed to `__nvvm_fmin_ftz_f` | EXISTING | FTZ variant |
| `llvm.nvvm.fmax.f` | renamed to `__nvvm_fmax_f` | EXISTING | Float max |
| `llvm.nvvm.fmax.ftz.f` | renamed to `__nvvm_fmax_ftz_f` | EXISTING | FTZ variant |

---

## 2. Type Conversion Intrinsics

### Float to Integer

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.f2i.rn` | `roundeven(x)` then `fptosi` | **NEW** | Round-to-nearest |
| `llvm.nvvm.f2i.rn.ftz` | `roundeven(x)` then `fptosi` | **NEW** | FTZ variant |
| `llvm.nvvm.f2i.rz` | NOT HANDLED | | Round-to-zero (same as default fptosi) |
| `llvm.nvvm.f2ui.rn` | NOT HANDLED | | Unsigned variant |

### Double to Integer

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.d2i.lo` | renamed to `__nvvm_d2i_lo` | EXISTING | Low 32 bits of double-to-int |
| `llvm.nvvm.d2i.hi` | renamed to `__nvvm_d2i_hi` | EXISTING | High 32 bits |

### Special Conversions

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.lohi.i2d` | renamed to `__nvvm_lohi_i2d` | EXISTING | Two ints to double |

---

## 3. Special Math Intrinsics

These are NOT `llvm.nvvm.*` intrinsics but CUDA device math functions that appear in kernel IR:

| Function | Handling | Status | Notes |
|---|---|---|---|
| `__nv_sinf` | body removed (uses inlined libdevice code) | EXISTING | |
| `__nv_cosf` | body removed | EXISTING | |
| `__nv_expf` | body removed | EXISTING | |
| `__nv_logf` | body removed | EXISTING | |
| `__nv_sqrtf` | body removed | EXISTING | |
| `__nv_fabsf` | body removed | EXISTING | Provided by cudaKernelImpl_64 |
| `__nv_fast_log2f` | trampolines to `log2f` | EXISTING | Via cudaKernelImpl_64 |
| `__nv_fast_powf` | trampolines to `powf` | EXISTING | Via cudaKernelImpl_64 |
| `__nv_powif` | body removed | EXISTING | |
| `__nv_ffs` | body removed | EXISTING | Find first set bit |
| `__nv_popc` | body removed | EXISTING | Population count |
| `__nvvm_reflect` | provided by cudaKernelImpl_64 | EXISTING | Compile-time reflection |

---

## 4. PTX Inline Assembly Replacement

CUDA math libraries (libdevice) may contain PTX inline assembly that can't run on RISC-V.

| PTX Pattern | Replacement | Status | Notes |
|---|---|---|---|
| `mov.u32 $0, %laneid` | Load from `intra_warp_index` TLS | EXISTING | Lane ID |
| `mad.lo.cc.u32` + `madc.hi.u32` | 64-bit multiply-add via `zext`+`mul`+`add`+`trunc` | **NEW** | Used in trig reduction |
| Other PTX asm | Replaced with `undef` (warning printed) | **NEW** | Graceful fallback |

---

## 5. Synchronization Intrinsics

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.barrier0` | `vx_barrier(__local_group_id, __warps_per_group)` | EXISTING | `__syncthreads()` |
| `llvm.nvvm.barrier.sync` | `vx_barrier(...)` | EXISTING | Named barrier |
| `llvm.nvvm.bar.warp.sync` | Handled | EXISTING | Warp sync |
| `llvm.nvvm.membar.gl` | renamed to `__nvvm_membar_gl` | EXISTING | Global memory fence |

---

## 6. Thread/Block Index Intrinsics

| NVVM Intrinsic | Replacement | Status |
|---|---|---|
| `llvm.nvvm.read.ptx.sreg.tid.x/y/z` | Load from `thread_id_x/y/z` TLS | EXISTING |
| `llvm.nvvm.read.ptx.sreg.ctaid.x/y/z` | Load from `block_index_x/y/z` TLS | EXISTING |
| `llvm.nvvm.read.ptx.sreg.ntid.x/y/z` | Load from `block_size_x/y/z` global | EXISTING |
| `llvm.nvvm.read.ptx.sreg.nctaid.x/y/z` | Load from `grid_size_x/y/z` global | EXISTING |

---

## 7. Warp-Level Intrinsics

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.shfl.sync.down.i32/f32` | Runtime function | EXISTING | Shuffle down |
| `llvm.nvvm.shfl.sync.up.i32/f32` | Runtime function | EXISTING | Shuffle up |
| `llvm.nvvm.shfl.sync.bfly.i32/f32` | Runtime function | EXISTING | XOR shuffle |
| `llvm.nvvm.shfl.sync.idx.i32/f32` | Runtime function | EXISTING | Indexed shuffle |
| `llvm.nvvm.vote.all.sync` | Runtime function | EXISTING | All-vote |
| `llvm.nvvm.vote.any.sync` | Runtime function | EXISTING | Any-vote |
| `llvm.nvvm.vote.uni.sync` | Runtime function | EXISTING | Uniform-vote |
| `llvm.nvvm.vote.ballot.sync` | Runtime function | EXISTING | Ballot |

---

## 8. Atomic Operations

| NVVM Intrinsic | Replacement | Status | Notes |
|---|---|---|---|
| `llvm.nvvm.atomic.load.inc.32` | renamed to `__nvvm_atomic_load_inc_32` | EXISTING | Atomic increment |

---

## 9. CUTLASS-Critical Intrinsics NOT YET Handled

Based on analysis of CUTLASS source code, these are used by CUTLASS but not yet in CuPBoP:

| CUDA Intrinsic | NVVM Form | Priority | CUTLASS Usage |
|---|---|---|---|
| `__hfma2(a,b,c)` | half2 FMA | HIGH | 23 uses — tensor core emulation |
| `__hmul2(a,b)` | half2 multiply | HIGH | 8+ uses |
| `__hmul(a,b)` | half multiply | HIGH | 12+ uses |
| `__hfma(a,b,c)` | half FMA | HIGH | 2+ uses |
| `atomicAdd` | LLVM atomicrmw | HIGH | 20 uses — reduction |
| `atomicCAS` | LLVM cmpxchg | MEDIUM | 12 uses — lock-free |
| `atomicMax` | LLVM atomicrmw | MEDIUM | 11 uses |
| `__frcp_rn(x)` | `llvm.nvvm.rcp.rn.f` | LOW | 2 uses |
| `__float2int_rn(x)` | `llvm.nvvm.f2i.rn` | LOW | 2 uses — now **NEW** handled |
| `__fmaf_rn(a,b,c)` | `llvm.nvvm.fma.rn.f` | LOW | 1 use — now **NEW** handled |
| `__logf(x)` | `llvm.nvvm.lg2.approx.f` | LOW | 1 use |
| `__ffs(x)` | `llvm.cttz` | LOW | 2 uses |
| `__popc(x)` | `llvm.ctpop` | LOW | 5 uses |

---

## 10. Design Notes

### Rounding Mode Handling
RISC-V does not support per-instruction rounding mode selection like PTX.
All rounding mode variants (rn, rz, rm, rp) are mapped to the same standard
operation, which uses the hardware default rounding mode (round-to-nearest-even).
This is acceptable for most applications but may cause minor numerical differences.

### Flush-to-Zero (FTZ) Handling
RISC-V does not have a per-instruction FTZ mode. FTZ variants are mapped to the
same operations as non-FTZ variants. Subnormal float handling may differ from NVIDIA GPUs.

### Implementation Location
All replacements are in `compilation/KernelTranslation/src/tool.cpp`:
- `replace_built_in_function()` — NVVM intrinsic renaming and inline replacement
- `replace_asm_call()` — PTX inline assembly replacement
