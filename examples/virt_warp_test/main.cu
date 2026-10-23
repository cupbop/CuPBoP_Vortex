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
  printf("done\n");
  return 0;
}
