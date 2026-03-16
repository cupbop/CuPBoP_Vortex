# CuPBoP-Vortex Benchmark simx Configuration Reference

Minimum simx configuration needed for each benchmark (with NUM_THREADS=4).

## simx Configuration

Current simx config that runs ALL benchmarks:
```
NUM_WARPS=64    # supports up to 256 threads/block (64 warps x 4 threads)
NUM_THREADS=4   # default
NUM_CORES=1     # default
LMEM_ENABLE     # required for benchmarks with shared memory
```

**Note:** NUM_WARPS=128 is NOT supported by the current Vortex simx (produces incorrect results).
Benchmarks that originally used 512 threads/block have been adjusted to 256.

### Rebuild command:
```bash
make -C /projects/ci-runners/CuPBoP-Vortex/tools/vortex/build/runtime/simx \
  CONFIGS='-DNUM_WARPS=64 -DLMEM_ENABLE'
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
