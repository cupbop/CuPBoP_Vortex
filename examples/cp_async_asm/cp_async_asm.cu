// cp_async_asm.cu -- the inline-PTX forms of cp.async that lower_cp_async handles:
//   cp.async.ca.shared.global [dst], [src], 8;                 (no src-size)
//   cp.async.ca.shared.global [dst], [src], 4, src_size;       (runtime src-size 4 / 2 / 0: copy, partial, zero-fill)
//   cp.async.cg.shared.global [dst], [src], 16, src_size;      (src-size 16 or 0)
//   cp.async.commit_group; cp.async.wait_group 1; cp.async.wait_all;
// Each thread reads other threads' copies after __syncthreads.   usage: ./host.out [-n elements]
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <cuda_runtime.h>

#define THREADS 128

__device__ __forceinline__ unsigned smem_addr(const void *p) {
  return static_cast<unsigned>(__cvta_generic_to_shared(p));
}
__device__ __forceinline__ void cp8(void *smem, const void *g) {
  asm volatile("cp.async.ca.shared.global [%0], [%1], 8;\n" ::"r"(smem_addr(smem)), "l"(g) : "memory");
}
__device__ __forceinline__ void cp4(void *smem, const void *g, unsigned src_size) {
  asm volatile("cp.async.ca.shared.global [%0], [%1], 4, %2;\n" ::"r"(smem_addr(smem)), "l"(g), "r"(src_size) : "memory");
}
__device__ __forceinline__ void cp16(void *smem, const void *g, unsigned src_size) {
  asm volatile("cp.async.cg.shared.global [%0], [%1], 16, %2;\n" ::"r"(smem_addr(smem)), "l"(g), "r"(src_size) : "memory");
}

// out[0 .. 2*THREADS):        a 8-byte copy per thread, read back rotated by one thread
// out[2*THREADS .. 3*THREADS): a 4-byte copy with src-size 4 (g < n), 2 (g == n: low half only) or 0 (g > n)
// out[3*THREADS .. 7*THREADS): a 16-byte copy with src-size 16 (in bounds) or 0
__global__ void asm_copies(const uint32_t *__restrict__ in, uint32_t *__restrict__ out, int n) {
  __shared__ __align__(16) uint32_t a[2 * THREADS];
  __shared__ __align__(16) uint32_t b[THREADS];
  __shared__ __align__(16) uint32_t c[4 * THREADS];
  const int tid = threadIdx.x;
  const int base = blockIdx.x * 7 * THREADS;
  cp8(&a[2 * tid], &in[base + 2 * tid]);
  asm volatile("cp.async.commit_group;\n" ::);
  const int g = base + 2 * THREADS + tid;
  unsigned ss = g < n ? 4u : (g == n ? 2u : 0u);
  cp4(&b[tid], &in[g < n + 1 ? g : 0], ss);
  const int g4 = base + 3 * THREADS + 4 * tid;
  cp16(&c[4 * tid], &in[g4 + 3 < n ? g4 : 0], g4 + 3 < n ? 16u : 0u);
  asm volatile("cp.async.commit_group;\n" ::);
  asm volatile("cp.async.wait_group 1;\n" ::: "memory"); // the 8-byte group
  asm volatile("cp.async.wait_all;\n" ::: "memory");
  __syncthreads();
  const int o = (tid + 1) % THREADS;
  out[base + 2 * tid] = a[2 * o];
  out[base + 2 * tid + 1] = a[2 * o + 1];
  out[base + 2 * THREADS + tid] = b[o];
  for (int j = 0; j < 4; ++j) out[base + 3 * THREADS + 4 * tid + j] = c[4 * o + j];
}

int main(int argc, char **argv) {
  int blocks = 3;
  int n = (blocks - 1) * 7 * THREADS + 2 * THREADS + 77; // the last block's 4-byte part straddles n (thread 77: 2 bytes)
  for (int i = 1; i + 1 < argc; i += 2)
    if (!strcmp(argv[i], "-n")) n = atoi(argv[i + 1]);
  const int total = blocks * 7 * THREADS;
  printf("cp_async_asm: blocks=%d n=%d\n", blocks, n);
  uint32_t *h_in = (uint32_t *)malloc(total * 4), *h_out = (uint32_t *)malloc(total * 4);
  for (int i = 0; i < total; ++i) h_in[i] = 0x10000u * (uint32_t)(i + 1) + 0x1234u + (uint32_t)i;
  uint32_t *d_in, *d_out;
  cudaMalloc(&d_in, total * 4);
  cudaMalloc(&d_out, total * 4);
  cudaMemcpy(d_in, h_in, total * 4, cudaMemcpyHostToDevice);
  cudaMemset(d_out, 0xff, total * 4);
  asm_copies<<<blocks, THREADS>>>(d_in, d_out, n);
  cudaMemcpy(h_out, d_out, total * 4, cudaMemcpyDeviceToHost);
  int errors = 0;
#define check(idx, want)                                                                              \
  do {                                                                                                \
    if (h_out[idx] != (want)) {                                                                       \
      if (errors < 10) printf("MISMATCH out[%d]: got 0x%08x, expected 0x%08x\n", idx, h_out[idx], (want)); \
      errors++;                                                                                       \
    }                                                                                                 \
  } while (0)
  for (int bk = 0; bk < blocks; ++bk) {
    const int base = bk * 7 * THREADS;
    for (int t = 0; t < THREADS; ++t) {
      const int o = (t + 1) % THREADS;
      check(base + 2 * t, h_in[base + 2 * o]);
      check(base + 2 * t + 1, h_in[base + 2 * o + 1]);
      const int g = base + 2 * THREADS + o;
      check(base + 2 * THREADS + t, g < n ? h_in[g] : (g == n ? (h_in[g] & 0xffffu) : 0u));
      const int g4 = base + 3 * THREADS + 4 * o;
      for (int j = 0; j < 4; ++j) check(base + 3 * THREADS + 4 * t + j, g4 + 3 < n ? h_in[g4 + j] : 0u);
    }
  }
  printf("%d errors\n%s\n", errors, errors ? "FAILED!" : "PASSED!");
  return errors ? 1 : 0;
}
