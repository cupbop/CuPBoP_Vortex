# CuPBoP-Vortex Debugging Session Summary — March 15-16, 2026

## What Was Done

### 1. OpenCL vs CuPBoP Comparison
Ran 9 matching benchmarks on both clean Vortex (OpenCL) and CuPBoP-Vortex (CUDA).
**All 9 match — both paths produce correct results.**

### 2. Bugs Found and Fixed

#### Bug 1: `-save-temps` CSR Encoding (commit `cb212b0`)
- **Symptom:** backprop and pathfinder crash with SIGABRT during kernel execution
- **Root cause:** LLVM Vortex backend maps CSR 0xFC3 (`LOCAL_MEM_BASE`) to assembly name `nw`, which the assembler encodes as CSR 0xFC1 (`NUM_WARPS`). Only triggers when `-save-temps` forces compilation through text assembly.
- **Effect:** `vx_local_alloc()` returns 64 (NUM_WARPS) instead of LMEM base address. Shared memory writes hit IO_COUT range (0x40-0x7F).
- **Fix:** Removed `-save-temps -v` from kernel_wrapper compilation in all `kjrun_llvm18.sh` scripts.
- **Underlying Vortex LLVM bug:** CSR name table has duplicate `nw` mapping. Needs fix in Vortex LLVM backend.

#### Bug 2: NVVM Intrinsics Not Replaced (commits `3836dda`, `049a37e`)
- **Symptom:** math_stress kernel compilation crashes with "Don't know how to custom type legalize this intrinsic!"
- **Root cause:** CuPBoP's kernel translator didn't replace many NVVM float intrinsics (`llvm.nvvm.fma.rn.ftz.f`, `llvm.nvvm.mul.rn.f`, etc.) or PTX inline assembly (`mad.lo.cc.u32`).
- **Fix:** Added 40+ NVVM intrinsic replacements in `tool.cpp`:
  - FMA, mul, add, div → standard LLVM fma/fmul/fadd/fdiv
  - fabs, fmin, fmax → @llvm.fabs, @llvm.minnum, @llvm.maxnum
  - sqrt, rsqrt, rcp → @llvm.sqrt, 1/sqrt, 1/x
  - sin, cos, exp2, log2 → @llvm.sin, @llvm.cos, @llvm.exp2, @llvm.log2
  - f2i, f2ui, i2f, d2f (all rounding modes) → fptosi/fptoui/sitofp/fptrunc
  - PTX `mad.lo.cc.u32 + madc.hi.u32` → 64-bit zext/mul/add/trunc
  - Unknown PTX asm → graceful warning instead of exit(1)
- Also fixed: `llvm.nvvm.fabs.f` rename collision, fmin/fmax now replaced inline instead of renamed, `replace_asm_call` extended to all functions (not just kernels).

#### Bug 3: LMEM Addressing Wraps at 2KB (commit `5dec921`)
- **Symptom:** 3+ shared memory arrays produce wrong results (3rd array aliases 1st)
- **Root cause:** Vortex simx `local_mem.cpp:to_local_addr()` uses `log2(capacity/line_size)` address bits instead of `log2(capacity)`. With LMEM_LOG_SIZE=14 and LSU_WORD_SIZE=8, only 2048 bytes addressable.
- **Fix (workaround):** Rebuild simx with `-DLMEM_LOG_SIZE=17`.
- **Proper Vortex fix:** Change `bit_getw(addr, 0, line_bits_-1)` to use `log2ceil(config_.capacity)` bits.

#### Bug 4: blockDim Resource Check Too Strict (commit `f0ba38c`)
- **Symptom:** vecadd/saxpy/conv3/bfs abort when blockDim > threads_per_core
- **Fix:** Changed CuPBoP runtime check from `std::abort()` to warning.
- **Remaining:** Vortex `vx_spawn.c:198` still rejects oversized blocks with `return -1`.

### 3. Stress Tests Created
**30 stress test benchmarks**, all passing:

**Original 20:** reduce_sum, reduce_max, scan_prefix, matmul_tiled, transpose_smem, stencil1d, stencil2d, histogram_reduce, divergent_branch, multi_kernel, dynamic_shared, math_stress, large_args, block2d_reduce, kernel_chain, shared_multiarray, nested_loop, stride_access, bitonic_sort, gather_scatter

**Additional 10:** shared_boundary, shared_4arrays, shared_int_float, shared_2d_block, multi_launch_shared, double_precision, mixed_global_shared, barrier_loop, large_shared, shared_write_read_pattern

**Plus:** atomic_test (integer atomicAdd passes, float atomicAdd crashes)

### 4. Documentation Created
- `docs/NVVM_INTRINSICS.md` — complete intrinsic replacement reference table
- `docs/REMAINING_ISSUES_PLAN.md` — remaining issues with implementation plan
- `examples/BENCHMARK_CONFIGS.md` — per-benchmark simx requirements

---

## Current simx Configuration

```bash
make -C /projects/ci-runners/CuPBoP-Vortex/tools/vortex/build/runtime/simx \
  CONFIGS='-DNUM_WARPS=64 -DLMEM_ENABLE -DLMEM_LOG_SIZE=17'
```

---

## All Commits (on branch `resource-checks-and-race-fix`)

```
bbbdfc7 Update plan with atomic test results: int atomics PASS, float CRASH
f76340c Add remaining issues plan with challenges and implementation order
5dec921 Fix shared_multiarray: document Vortex LMEM addressing bug and workaround
049a37e Expand NVVM intrinsic support: add math, conversion, and trig ops
3836dda Add NVVM float intrinsic replacements and PTX asm handling
f0ba38c Relax blockDim resource check to warning instead of abort
cb212b0 Remove -save-temps from kernel_wrapper compilation to fix CSR encoding bug
6a89e94 Add resource checks, debug output, and race condition fix (prior)
```

---

## Action Items for Next Sessions

### Priority 1 — Vortex-Side Fixes (give to Vortex maintainers)

**A1. LMEM addressing bug** (`local_mem.cpp:32`)
- 2-line fix: use `log2ceil(capacity)` instead of `log2ceil(capacity/line_size)`
- Currently worked around with LMEM_LOG_SIZE=17

**A2. CSR name collision** (LLVM Vortex backend)
- CSR 0xFC3 (`LOCAL_MEM_BASE`) incorrectly named `nw` (same as 0xFC1 `NUM_WARPS`)
- Fix: give 0xFC3 a unique name in the CSR .td definition
- Currently worked around by not using `-save-temps`

**A3. vx_spawn_threads block size limit** (`vx_spawn.c:198`)
- Rejects blockDim > threads_per_core even though Vortex can batch warps
- Blocks vecadd/saxpy/conv3/bfs (512 threads)
- Needs batched scheduling support or just remove the check if Vortex handles it

**A4. Divergent branch in CAS loops** (simx split/join)
- Float atomicAdd uses LR/SC CAS loop → backward branch divergence
- Vortex SIMT split/join stack can't handle threads looping back while others exit
- Blocks all float atomic operations and potentially other CAS patterns

### Priority 2 — CuPBoP Feature Additions

**B1. Bit operations** (`tool.cpp`)
- `__nv_ffs(x)` → `@llvm.cttz + 1`, `__nv_popc(x)` → `@llvm.ctpop`
- Currently `deleteBody()` removes implementations — need proper intrinsic replacement
- Low effort, 7 CUTLASS uses

**B2. Half-precision FP16** (`tool.cpp` + architecture decision)
- `__hfma`, `__hmul`, `__hfma2`, `__hmul2` → need FP16 support
- RISC-V rv64imafd has no `Zfh` extension — must promote to FP32
- 47 CUTLASS uses, medium-high effort
- Key decision: accept FP32 promotion or add soft-float FP16?

**B3. 64-bit warp shuffle** (`warp_func.cpp`)
- i32/f32 shuffles already work, need i64/f64 variants
- Split into two 32-bit shuffles — low effort

### Priority 3 — Test Infrastructure

**C1. Fix run_stress_tests.sh false negatives**
- multi_kernel and kernel_chain falsely reported as compile failures
- The "Kernel compilation completed!" marker falls outside last-30-lines window
- Fix: search entire log, not just tail

**C2. NUM_WARPS=128 investigation**
- simx produces wrong results with NUM_WARPS=128 (even OpenCL fails)
- Root cause unknown — may be related to LMEM addressing or barrier limits

---

## Key Files Modified

| File | Changes |
|------|---------|
| `compilation/KernelTranslation/src/tool.cpp` | +40 NVVM intrinsic replacements, PTX asm handler, fmin/fmax inline, fabs fix |
| `runtime/src/vortex/host/cudaRuntimeImpl.cpp` | blockDim check → warning instead of abort |
| `examples/*/kjrun_llvm18.sh` (11 files) | Removed `-save-temps -v` from kernel_wrapper compilation |
| `docs/NVVM_INTRINSICS.md` | Complete intrinsic replacement reference |
| `docs/REMAINING_ISSUES_PLAN.md` | Implementation plan with challenges |
| `examples/BENCHMARK_CONFIGS.md` | simx config and per-benchmark requirements |

---

## Test Results Summary

| Category | Count | Status |
|----------|-------|--------|
| Original CI benchmarks (blockDim≤256) | 11/11 | PASS |
| Stress tests (round 1) | 20/20 | PASS |
| Stress tests (round 2) | 10/10 | PASS |
| Atomic test — int | 1/1 | PASS |
| Atomic test — float | 0/1 | CRASH (Vortex divergent branch bug) |
| **Total** | **42/43** | |
