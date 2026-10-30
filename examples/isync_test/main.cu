// Core mapping (schedule 1): thread-dependent branches between warp loops (isync, 2026-10-30).
// Shapes: a lane-divergent `if (t < 4)` strided loop between __syncthreads (cuBLAS reduce_1Block), a slot-divergent
// branch (t >= 96: differs between the logical warps a physical warp runs), loops with thread-dependent trip counts,
// (isync_test_exit: plus a CTA-uniform early exit in front of them). Self-checking against a host reference (integer math).
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#define NT 256
#define NB 3
__global__ void k_reduce(const int *in, int *out, int n, int nblk) {
  __shared__ int s[NT];
  __shared__ int part[4];
  int t = threadIdx.x;
  // (the CTA-uniform early exit is in isync_test_exit)
  int acc = 0;
  for (int i = blockIdx.x * NT + t; i < n; i += NT * nblk) acc += in[i];
  s[t] = acc;
  __syncthreads();
  if (t < 4) {                                           // lane-divergent arm, strided loop
    int a = 0;
    for (int i = t; i < NT; i += 4) a += s[i] * (i % 7 + 1);
    part[t] = a;
  }
  __syncthreads();
  if (t >= 96) {                                         // slot-divergent arm with a thread-dependent loop
    int v = 0;
    for (int j = 0; j < (t & 15) + 1; j++) v += s[(t + j) % NT] ^ j;
    out[blockIdx.x * NT + t] = v + part[t & 3];
  } else {
    int v = s[t] * 3;
    while (v > 1000) v -= 997;
    out[blockIdx.x * NT + t] = v - part[(t + 1) & 3];
  }
}
static void ref(const int *in, int *out, int n, int nblk) {
  for (int b = 0; b < nblk; b++) {
    int s[NT], part[4];
    for (int t = 0; t < NT; t++) { int acc = 0; for (int i = b * NT + t; i < n; i += NT * nblk) acc += in[i]; s[t] = acc; }
    for (int t = 0; t < 4; t++) { int a = 0; for (int i = t; i < NT; i += 4) a += s[i] * (i % 7 + 1); part[t] = a; }
    for (int t = 0; t < NT; t++) {
      if (t >= 96) { int v = 0; for (int j = 0; j < (t & 15) + 1; j++) v += s[(t + j) % NT] ^ j; out[b * NT + t] = v + part[t & 3]; }
      else { int v = s[t] * 3; while (v > 1000) v -= 997; out[b * NT + t] = v - part[(t + 1) & 3]; }
    }
  }
}
int main() {
  const int n = 5000, grid = NB, nblk = NB;
  int *h_in = (int *)malloc(n * sizeof(int)), *h_out = (int *)malloc(grid * NT * sizeof(int)), *r = (int *)malloc(grid * NT * sizeof(int));
  for (int i = 0; i < n; i++) h_in[i] = (i * 37 + 11) % 101;
  for (int i = 0; i < grid * NT; i++) { h_out[i] = -1; r[i] = -1; }
  int *d_in, *d_out;
  cudaMalloc(&d_in, n * sizeof(int)); cudaMalloc(&d_out, grid * NT * sizeof(int));
  cudaMemcpy(d_in, h_in, n * sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_out, h_out, grid * NT * sizeof(int), cudaMemcpyHostToDevice);
  k_reduce<<<grid, NT>>>(d_in, d_out, n, nblk);
  cudaDeviceSynchronize();
  cudaMemcpy(h_out, d_out, grid * NT * sizeof(int), cudaMemcpyDeviceToHost);
  ref(h_in, r, n, nblk);
  int bad = 0;
  for (int i = 0; i < grid * NT; i++) if (h_out[i] != r[i]) { if (bad < 5) printf("mismatch %d: %d != %d\n", i, h_out[i], r[i]); bad++; }
  printf(bad ? "FAIL: %d mismatches\n" : "TEST PASSED\n", bad);
  return bad != 0;
}
