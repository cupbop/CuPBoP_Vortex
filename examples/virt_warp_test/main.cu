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
  int k1 = t, k2 = t;                                 // GEMM shape: uniform loop around staged ops, divergent if inside
  for (int a = 0; a < 3; a++) { k1 = wsum(k1) & 1023; if (lane < 8) k1 += a; }
  for (int a = 0; a < (lane & 1) + 1; a++) k2 = wsum(k2) & 1023; // divergent trip count around staged ops
  out[o + 10] = k1; out[o + 11] = k2;
  // 16-lane sub-pass shapes (nt16s1, 11/3): branches whose arm differs between the two halves of a CUDA warp
  int q = t * 3 + __shfl_xor_sync(full, t, 16);       // after a staged shuffle, store only in the lower half
  int f12 = -5;
  if (lane < 16) f12 = q;                             // (lifted backprop: `if (tid.y == 0) store`)
  int f13;                                            // both arms hold a warp op, each with its own half
  if (lane < 16) f13 = __ballot_sync(0x0000ffffu, t & 1);
  else f13 = __ballot_sync(0xffff0000u, (t % 3) == 0);
  int f14 = -3;                                       // only the upper half runs a shuffle loop (sub-pass 0 is idle)
  if (lane >= 16) {
    f14 = t;
    for (int off = 8; off > 0; off >>= 1) f14 += __shfl_xor_sync(0xffff0000u, f14, off, 16);
  }
  int f15 = -4;                                       // nested arms inside the upper half
  if (lane >= 16) { if (lane & 1) f15 = __ballot_sync(0xaaaa0000u, (t % 5) == 0); else f15 = lane; }
  out[o + 12] = f12; out[o + 13] = f13; out[o + 14] = f14; out[o + 15] = f15;
}

// Third kernel: lifted backprop's shape in a 2-D block (16 x 4): the guard around the shuffle and the store behind it test
// threadIdx.y, which differs between the two 16-lane halves of a CUDA warp. Rows t + 2000: fields 0 and 1, the rest 0.
__global__ void warp_test3(int *out) {
  int tx = threadIdx.x, ty = threadIdx.y, t = ty * 16 + tx;
  if (ty >= 2) return;                                // (both early exits: one merge in front of the return, as lifted)
  int v = tx + 100 * ty + 1;
  int x = __shfl_xor_sync(0xffffffffu, v, 16);
  int s = v + (ty == 0 ? x : 0);
  out[t * NF + 0] = s;
  if (ty != 0) return;
  out[(32 + tx) * NF + 1] = s;
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
  for (int i = 0; i < NTHREADS * NF; i++) h[i] = 0;
  cudaMemcpy(d, h, sz, cudaMemcpyHostToDevice);
  warp_test3<<<1, dim3(16, 4)>>>(d);
  cudaMemcpy(h, d, sz, cudaMemcpyDeviceToHost);
  for (int t = 0; t < NTHREADS; t++) {
    printf("%d:", 2000 + t);
    for (int f = 0; f < NF; f++) printf(" %d", h[t * NF + f]);
    printf("\n");
  }
  printf("done\n");
  return 0;
}
