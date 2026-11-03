// ldmatrix / stmatrix conformance for CuPBoP's core mapping: every form (x1, x2, x4, .trans) on 2 CUDA warps, checked on the
// host against the PTX fragment layout (lane l, g = l >> 2, t = l & 3: d_j = {M_j[g][2t], M_j[g][2t+1]}, with .trans
// {M_j[2t][g], M_j[2t+1][g]}; row r of matrix j from lane 8j + r). Sub-pass form: both 16-lane passes give addresses.
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#define NTHREADS 64
#define RS 24   // row stride in halves (48 B: rows are 16-byte aligned, not contiguous)
#define NF 24   // results per thread
__device__ __forceinline__ unsigned short code(int w, int m, int r, int c) { return (unsigned short)(w * 4096 + m * 512 + r * 16 + c + 1); }
__global__ void ldsm_test(unsigned *out) {
  __shared__ __align__(16) unsigned short tile[2][4][8][RS];
  __shared__ __align__(16) unsigned short dst[2][4][8][RS];
  int t = threadIdx.x, lane = t & 31, w = t >> 5;
  for (int i = lane; i < 4 * 8 * 8; i += 32) {
    int m = i >> 6, r = (i >> 3) & 7, c = i & 7;
    tile[w][m][r][c] = code(w, m, r, c);
  }
  for (int i = lane; i < 4 * 8 * RS; i += 32) (&dst[w][0][0][0])[i] = 0;
  __syncthreads();
  unsigned a = (unsigned)__cvta_generic_to_shared(&tile[w][lane >> 3][lane & 7][0]);
  unsigned b = (unsigned)__cvta_generic_to_shared(&dst[w][lane >> 3][lane & 7][0]);
  unsigned d0, d1, d2, d3, *o = out + t * NF;
  asm volatile("ldmatrix.sync.aligned.m8n8.x4.shared.b16 {%0,%1,%2,%3}, [%4];" : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3) : "r"(a));
  o[0] = d0; o[1] = d1; o[2] = d2; o[3] = d3;
  asm volatile("ldmatrix.sync.aligned.m8n8.x4.trans.shared.b16 {%0,%1,%2,%3}, [%4];" : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3) : "r"(a));
  o[4] = d0; o[5] = d1; o[6] = d2; o[7] = d3;
  asm volatile("ldmatrix.sync.aligned.m8n8.x2.shared.b16 {%0,%1}, [%2];" : "=r"(d0), "=r"(d1) : "r"(a));
  o[8] = d0; o[9] = d1;
  asm volatile("ldmatrix.sync.aligned.m8n8.x2.trans.shared.b16 {%0,%1}, [%2];" : "=r"(d0), "=r"(d1) : "r"(a));
  o[10] = d0; o[11] = d1;
  asm volatile("ldmatrix.sync.aligned.m8n8.x1.shared.b16 {%0}, [%1];" : "=r"(d0) : "r"(a));
  o[12] = d0;
  asm volatile("ldmatrix.sync.aligned.m8n8.x1.trans.shared.b16 {%0}, [%1];" : "=r"(d0) : "r"(a));
  o[13] = d0;
  // stmatrix: the fragment each lane computed by hand goes back to memory; the host checks dst through the fields below
  unsigned s0 = (unsigned)code(w, 0, lane >> 2, 2 * (lane & 3)) | ((unsigned)code(w, 0, lane >> 2, 2 * (lane & 3) + 1) << 16);
  unsigned s1 = s0 + 0x02000200u, s2 = s0 + 0x04000400u, s3 = s0 + 0x06000600u;
  asm volatile("stmatrix.sync.aligned.m8n8.x4.shared.b16 [%0], {%1,%2,%3,%4};" :: "r"(b), "r"(s0), "r"(s1), "r"(s2), "r"(s3) : "memory");
  __syncwarp();
  for (int j = 0; j < 4; j++) o[14 + j] = *(unsigned *)&dst[w][j][lane >> 2][2 * (lane & 3)];
  __syncwarp();
  asm volatile("stmatrix.sync.aligned.m8n8.x2.trans.shared.b16 [%0], {%1,%2};" :: "r"(b), "r"(s0), "r"(s1) : "memory");
  __syncwarp();
  for (int j = 0; j < 2; j++) o[18 + j] = *(unsigned *)&dst[w][j][lane >> 2][2 * (lane & 3)];
  __syncwarp();
  asm volatile("stmatrix.sync.aligned.m8n8.x1.shared.b16 [%0], {%1};" :: "r"(b), "r"(s3) : "memory");
  __syncwarp();
  o[20] = *(unsigned *)&dst[w][0][lane >> 2][2 * (lane & 3)];
  o[21] = o[22] = o[23] = 0;
}
static unsigned short hcode(int w, int m, int r, int c) { return (unsigned short)(w * 4096 + m * 512 + r * 16 + c + 1); }
static unsigned frag(int w, int m, int lane) { int g = lane >> 2, t = lane & 3; return hcode(w, m, g, 2 * t) | ((unsigned)hcode(w, m, g, 2 * t + 1) << 16); }
static unsigned fragT(int w, int m, int lane) { int g = lane >> 2, t = lane & 3; return hcode(w, m, 2 * t, g) | ((unsigned)hcode(w, m, 2 * t + 1, g) << 16); }
int main() {
  unsigned *d = NULL; size_t sz = NTHREADS * NF * sizeof(unsigned);
  static unsigned h[NTHREADS * NF];
  cudaMalloc((void **)&d, sz);
  for (int i = 0; i < NTHREADS * NF; i++) h[i] = 0xdeadbeefu;
  cudaMemcpy(d, h, sz, cudaMemcpyHostToDevice);
  ldsm_test<<<1, NTHREADS>>>(d);
  cudaMemcpy(h, d, sz, cudaMemcpyDeviceToHost);
  int bad[6] = {0, 0, 0, 0, 0, 0}, sbad[3] = {0, 0, 0};
  for (int t = 0; t < NTHREADS; t++) {
    int l = t & 31, w = t >> 5; unsigned *o = h + t * NF;
    for (int j = 0; j < 4; j++) { bad[0] += o[j] != frag(w, j, l); bad[1] += o[4 + j] != fragT(w, j, l); }
    for (int j = 0; j < 2; j++) { bad[2] += o[8 + j] != frag(w, j, l); bad[3] += o[10 + j] != fragT(w, j, l); }
    bad[4] += o[12] != frag(w, 0, l); bad[5] += o[13] != fragT(w, 0, l);
    // stmatrix x4: dst matrix j row g holds what lane (g, t) stored
    for (int j = 0; j < 4; j++) sbad[0] += o[14 + j] != frag(w, 0, l) + (unsigned)j * 0x02000200u;
    // stmatrix x2 .trans: lane (g, t) stored {M[2t][g], M[2t+1][g]} = s; reading M[g][2t..2t+1] gives the transposed pairs
    for (int j = 0; j < 2; j++) {
      int g = l >> 2, t2 = l & 3;
      unsigned lo = 0, hi = 0;
      { int l0 = (2 * t2) * 4 + (g >> 1), l1 = (2 * t2 + 1) * 4 + (g >> 1); // lanes holding M[g][2t], M[g][2t+1]: M[r][c] is in lane (c * 4 + r / 2), half r & 1
        unsigned v0 = frag(w, 0, l0) + (unsigned)j * 0x02000200u, v1 = frag(w, 0, l1) + (unsigned)j * 0x02000200u;
        lo = (g & 1) ? v0 >> 16 : v0 & 0xffffu; hi = (g & 1) ? v1 >> 16 : v1 & 0xffffu; }
      sbad[1] += o[18 + j] != (lo | (hi << 16));
    }
    sbad[2] += o[20] != frag(w, 0, l) + 3u * 0x02000200u;
  }
  const char *n[6] = {"x4", "x4.trans", "x2", "x2.trans", "x1", "x1.trans"};
  for (int i = 0; i < 6; i++) printf("ldmatrix %s %s\n", n[i], bad[i] ? "FAIL" : "PASS");
  const char *sn[3] = {"x4", "x2.trans", "x1"};
  for (int i = 0; i < 3; i++) printf("stmatrix %s %s\n", sn[i], sbad[i] ? "FAIL" : "PASS");
  printf("done\n");
  return 0;
}
