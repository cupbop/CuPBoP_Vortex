// named_barrier_test: PTX named barriers with a thread count -- the warp-specialized producer/consumer
// handshake of CUTLASS and FlashAttention-3 (CuLifter lifts BAR.ARV / BAR.SYNC <id>, <count> to the same
// inline asm). Warps 0-3 fill a shared buffer and arrive on barrier 1 ("full"), warps 4-7 wait on it,
// consume, sync among themselves on barrier 3 (128 threads) and arrive on barrier 2 ("empty"), which the
// producers wait on before the next round. The producers' delay loop makes a dropped barrier visible.
// Supported on the 1:1 schedule (SCHEDULE=2); the warp-loop schedules refuse it at translation.
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

#define BLOCK 256 // 8 warps
#define HALF 128  // producers: threads 0..127, consumers: 128..255
#define NBLOCKS 4
#define ROUNDS 3

__device__ __forceinline__ void named_arrive(int id, int n) {
  asm volatile("bar.arrive %0, %1;" ::"r"(id), "r"(n) : "memory");
}
__device__ __forceinline__ void named_sync(int id, int n) {
  asm volatile("bar.sync %0, %1;" ::"r"(id), "r"(n) : "memory");
}

__host__ __device__ unsigned produce(unsigned x) {
  for (unsigned k = 0; k < 64; k++) x = x * 3u + k;
  return x;
}

__global__ void nbar_kernel(const unsigned *in, unsigned *out, int rounds) {
  __shared__ unsigned buf[HALF];
  __shared__ unsigned part[4];
  const int tid = threadIdx.x, base = blockIdx.x * HALF;
  for (int r = 0; r < rounds; r++) {
    if (tid < HALF) {
      if (r > 0) named_sync(2, BLOCK); // consumers are done with the previous round's buffer
      buf[tid] = produce(in[base + tid] + r);
      named_arrive(1, BLOCK);          // buffer full
    } else {
      const int c = tid - HALF;
      named_sync(1, BLOCK);            // wait until the buffer is full
      unsigned v = buf[HALF - 1 - c];  // written by another warp
      if ((c & 31) == 0) part[c / 32] = v;
#ifdef NBAR_BUILTIN
      __nvvm_barrier_sync_cnt(3, 128); // consumers only (llvm.nvvm.barrier.sync.cnt)
#else
      asm volatile("bar.sync 3, 128;" ::: "memory"); // consumers only (immediate operands)
#endif
      unsigned w = part[(c / 32 + 1) & 3];
      out[(r * gridDim.x + blockIdx.x) * HALF + c] = v + w;
      if (r + 1 < rounds) named_arrive(2, BLOCK); // buffer may be refilled
    }
  }
}

int main() {
  const int n_in = NBLOCKS * HALF, n_out = ROUNDS * NBLOCKS * HALF;
  unsigned *h_in = (unsigned *)malloc(n_in * sizeof(unsigned));
  unsigned *h_out = (unsigned *)malloc(n_out * sizeof(unsigned));
  for (int i = 0; i < n_in; i++) h_in[i] = 7u * i + 1u;
  unsigned *d_in, *d_out;
  cudaMalloc(&d_in, n_in * sizeof(unsigned));
  cudaMalloc(&d_out, n_out * sizeof(unsigned));
  cudaMemcpy(d_in, h_in, n_in * sizeof(unsigned), cudaMemcpyHostToDevice);
  cudaMemset(d_out, 0, n_out * sizeof(unsigned));
  nbar_kernel<<<NBLOCKS, BLOCK>>>(d_in, d_out, ROUNDS);
  cudaMemcpy(h_out, d_out, n_out * sizeof(unsigned), cudaMemcpyDeviceToHost);
  int bad = 0;
  for (int r = 0; r < ROUNDS; r++)
    for (int b = 0; b < NBLOCKS; b++)
      for (int c = 0; c < HALF; c++) {
        unsigned v = produce(h_in[b * HALF + HALF - 1 - c] + r);
        int c2 = ((c / 32 + 1) & 3) * 32;
        unsigned w = produce(h_in[b * HALF + HALF - 1 - c2] + r);
        unsigned got = h_out[(r * NBLOCKS + b) * HALF + c];
        if (got != v + w && bad++ < 5)
          printf("mismatch r=%d b=%d c=%d: got %u expected %u\n", r, b, c, got, v + w);
      }
  printf("named_barrier_test: %d/%d wrong -> %s\n", bad, n_out, bad ? "FAILED" : "PASSED");
  cudaFree(d_in);
  cudaFree(d_out);
  free(h_in);
  free(h_out);
  return bad ? 1 : 0;
}
