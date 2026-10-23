// Warp-level primitive conformance test for CuPBoP's core mapping (virt).
// One block of 64 threads = 2 CUDA warps; every thread records 16 values that
// depend on ballots, votes, shuffles (all modes, widths, float) and
// __activemask under divergence. The golden is the 1:1 schedule at NT=32.
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#define NTHREADS 64
#define NF 16
__global__ void warp_test(int *out) {
  int t = threadIdx.x;
  int lane = t & 31;
  unsigned full = 0xffffffffu;
  int o = t * NF;
  out[o + 0] = __ballot_sync(full, (t % 3) == 0);
  out[o + 1] = __any_sync(full, lane == 7) ? 1 : 0;
  out[o + 2] = __all_sync(full, t < 100) ? 1 : 0;
  out[o + 3] = __shfl_sync(full, t, 5);
  out[o + 4] = __shfl_down_sync(full, t, 1);
  out[o + 5] = __shfl_up_sync(full, t, 3);
  out[o + 6] = __shfl_xor_sync(full, t, 16);
  out[o + 7] = (int)(__shfl_down_sync(full, (float)t * 0.5f, 2) * 2.0f);
  int r = t;
  for (int off = 16; off > 0; off >>= 1) r += __shfl_down_sync(full, r, off);
  out[o + 8] = r;
  int am = 0, b2 = 0;
  if ((t % 4) < 2) { am = (int)__activemask(); b2 = __ballot_sync(am, (t % 8) == 0); }
  out[o + 9] = am;
  out[o + 10] = b2;
  out[o + 11] = __shfl_sync(full, t, lane ^ 1, 16);
  out[o + 12] = __shfl_up_sync(full, t, 1, 8);
  int v = t; if (lane >= 16) v += 100;
  out[o + 13] = __shfl_down_sync(full, v, 8);
  out[o + 14] = __ballot_sync(full, lane >= 16); // (no __popc: libdevice __nv_popc does not legalize in the Vortex backend)
  out[o + 15] = t;
}

// Second kernel: control-flow shapes around staged warp ops (sub-pass form).
// Same 64 threads; rows are printed with t + 1000.
__device__ __forceinline__ int wsum(int v) {
  for (int off = 16; off > 0; off >>= 1) v += __shfl_down_sync(0xffffffffu, v, off);
  return v;
}
__global__ void warp_test2(int *out) {
  __shared__ int s[2];
  __shared__ int sh[NTHREADS];
  int t = threadIdx.x, lane = t & 31, wid = t >> 5;
  unsigned full = 0xffffffffu;
  int o = t * NF;
  int f0 = -1, f1 = -7, f3 = -1, f4 = 0, f5 = 0, f6 = 0, f7 = 0, f8 = 0;
  if (blockDim.x > 32) f0 = wsum(t);                 // uniform if around a shfl loop
  if (wid == 0) f1 = wsum(t + 1);                    // warp-uniform if around a shfl loop
  int v = wsum(t);                                   // welford shape: warp sum, lane 0 -> smem, block barrier, warp 0 reduces
  if (blockDim.x > 32) {
    if (lane == 0) s[wid] = v;
    __syncthreads();
    if (wid == 0) v = (t < (int)(blockDim.x / 32)) ? s[lane] : 0;
  }
  if (wid == 0) v = wsum(v);
  if (lane < 16) { f3 = t; for (int off = 8; off > 0; off >>= 1) f3 += __shfl_down_sync(full, f3, off); } // half-warp (jacobi shape)
  unsigned m = __ballot_sync(full, true);
  if (t & 1) f4 = __ballot_sync(m, (t % 3) == 0);    // ballot inside a divergent if, mask from before
  if (t & 1) { f5 = __ballot_sync(full, t > 10); if (t & 2) f6 = __ballot_sync(full, t > 20); } // nested
  for (int i = 0; i < (lane % 3) + 1; i++) f7 ^= __ballot_sync(__activemask(), i == 1) + i; // divergent loop
  sh[t] = t * 3;
  __syncwarp();
  f8 = sh[wid * 32 + ((lane + 1) & 31)];             // native warp sync as a boundary
  out[o + 0] = f0; out[o + 1] = f1; out[o + 2] = v; out[o + 3] = f3; out[o + 4] = f4;
  out[o + 5] = f5; out[o + 6] = f6; out[o + 7] = f7; out[o + 8] = f8;
  out[o + 9] = (t == 0) ? 777 : 1;                   // final store under a thread-0 test
  for (int f = 10; f < NF; f++) out[o + f] = t;
}
int main() {
  int *d = NULL; size_t sz = NTHREADS * NF * sizeof(int);
  static int h[NTHREADS * NF];
  for (int i = 0; i < NTHREADS * NF; i++) h[i] = -1;
  cudaMalloc((void **)&d, sz);
  cudaMemcpy(d, h, sz, cudaMemcpyHostToDevice);
  warp_test<<<1, NTHREADS>>>(d);
  cudaMemcpy(h, d, sz, cudaMemcpyDeviceToHost);
  for (int t = 0; t < NTHREADS; t++) {
    printf("%d:", t);
    for (int f = 0; f < NF; f++) printf(" %d", h[t * NF + f]);
    printf("\n");
  }
  for (int i = 0; i < NTHREADS * NF; i++) h[i] = -1;
  cudaMemcpy(d, h, sz, cudaMemcpyHostToDevice);
  warp_test2<<<1, NTHREADS>>>(d);
  cudaMemcpy(h, d, sz, cudaMemcpyDeviceToHost);
  for (int t = 0; t < NTHREADS; t++) {
    printf("%d:", 1000 + t);
    for (int f = 0; f < NF; f++) printf(" %d", h[t * NF + f]);
    printf("\n");
  }
  printf("done\n");
  return 0;
}
