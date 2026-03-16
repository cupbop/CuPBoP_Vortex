# CuPBoP-Vortex Benchmark simx Configuration Reference

Minimum simx configuration needed for each benchmark (with NUM_THREADS=4).

## simx Configuration

Current simx config that runs ALL benchmarks:
```
NUM_WARPS=64        # supports up to 256 threads/block (64 warps x 4 threads)
NUM_THREADS=4       # default
NUM_CORES=1         # default
LMEM_ENABLE         # required for benchmarks with shared memory
LMEM_LOG_SIZE=17    # workaround for Vortex LMEM addressing bug (see below)
```

**Note:** NUM_WARPS=128 is NOT supported by the current Vortex simx (produces incorrect results).

### Rebuild command:
```bash
make -C /projects/ci-runners/CuPBoP-Vortex/tools/vortex/build/runtime/simx \
  CONFIGS='-DNUM_WARPS=64 -DLMEM_ENABLE -DLMEM_LOG_SIZE=17'
```

### Known Vortex simx bug: LMEM addressing wraps too early

In `sim/simx/local_mem.cpp`, `to_local_addr()` uses `log2(capacity/line_size)` bits
instead of `log2(capacity)` bits, causing LMEM addresses to wrap at
`capacity / LSU_WORD_SIZE` bytes instead of `capacity` bytes.

With the default LMEM_LOG_SIZE=14 (16KB) and LSU_WORD_SIZE=8, only 2048 bytes
are addressable. Shared memory allocations >2048 bytes see address aliasing
(offset 2048 maps to the same location as offset 0).

**Workaround:** Use LMEM_LOG_SIZE=17 so the addressable range is 2^14=16384 bytes.

**Proper fix (in Vortex):** In `local_mem.cpp:32`, change:
```cpp
return bit_getw(addr, 0, line_bits_-1);
```
to:
```cpp
uint32_t addr_bits = log2ceil(config_.capacity);
return bit_getw(addr, 0, addr_bits-1);
```

## Per-Benchmark Requirements

| Benchmark  | blockDim         | Threads/Block | Min NUM_WARPS | Shared Mem (bytes) | Notes |
|------------|------------------|---------------|---------------|-------------------|-------|
| backprop   | 16 x 16 x 1     | 256           | 64            | 1088 (static)     | 2 kernels; 2nd has no shared mem |
| bfs        | 256 x 1 x 1     | 256           | 64            | 0                 | reduced from 512 |
| btree      | 256 x 1 x 1     | 256           | 64            | 0                 | order-dependent; 256 for mil.txt |
| conv3      | 16 x 16 x 1     | 256           | 64            | 0                 | reduced from 32x16; set by -bx/-by |
| dotproduct | 256 x 1 x 1     | 256           | 64            | 1024 (static)     | BLOCK_SIZE=256 |
| nn         | 64 x 1 x 1      | 64            | 16            | 0                 | |
| pathfinder | 64 x 1 x 1      | 64            | 16            | 512 (static)      | BLOCK_SIZE=64 |
| psum       | 256 x 1 x 1     | 256           | 64            | dynamic           | size = blockDim * sizeof(float) |
| saxpy      | 256 x 1 x 1     | 256           | 64            | 0                 | reduced from 512 |
| sgemm      | 16 x 16 x 1     | 256           | 64            | 0                 | |
| stencil    | 128 x 1 x 1     | 128           | 32            | 0                 | |
| transpose  | 16 x 16 x 1     | 256           | 64            | 0                 | |
| vecadd     | 256 x 1 x 1     | 256           | 64            | 0                 | reduced from 512; set by -b arg |

## Benchmarks by NUM_WARPS Tier

- **NUM_WARPS=16** (64 threads): nn, pathfinder
- **NUM_WARPS=32** (128 threads): stencil
- **NUM_WARPS=64** (256 threads): all others (backprop, bfs, btree, conv3, dotproduct, psum, saxpy, sgemm, transpose, vecadd)
