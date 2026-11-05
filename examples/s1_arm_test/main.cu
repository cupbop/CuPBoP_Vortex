// Core mapping (schedule 1): conditional branches whose two arms stay inside one parallel region (s1fix, 2026-11-04; see
// s1_two_arm_on in insert_warp_loop.cpp). The region walk stopped at such a branch by the shape of its block alone, and the
// code behind it, in front of it or both ran for the logical warps of slot 0 only: silently wrong at P < warps per CTA.
// Built at -O1 (Makefile): clang's -O0 always leaves a load in front of the branch, optimized (lifted) code does not.
//   k_barrier_branch: [__syncthreads; br c, work, end]     the block of the barrier holds the branch (lifted backprop)
//   k_barrier_branch2: the same with the arms the other way round
//   k_join_branch:    a join that holds only a branch, with work in front of it and behind it (lifted tg sm80, sgeam)
//   k_two_stops:      such a join in a region also entered from the barrier: two stops (refused before: FA2, conv_1x1)
//   k_loop_stops:     branches behind a loop with barriers (the region behind the loop is entered from two barriers)
//   k_thread_loop:    a loop with a thread-dependent trip count right behind a barrier, no barrier in it
//   k_uniform_loop:   a real boundary next to them: a branch with __syncthreads on its arms stays between the warp loops
// Self-checking against a host reference (integer math).
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#define NT 256
#define NB 3
#define N (NT * NB)
__device__ __forceinline__ int mix(int v, int k) { return (v ^ (v >> 3)) * (2 * k + 1) + k; }
__global__ void k_barrier_branch(const int *in, int *out) {
  __shared__ int s[NT];
  int t = threadIdx.x, g = blockIdx.x * NT + t;
  int v = in[g];
  bool c = (v & 1) != 0;
  s[t] = v;
  __syncthreads();
  if (c) out[g] = s[(t + 1) % NT] + 1;
}
__global__ void k_barrier_branch2(const int *in, int *out) {
  __shared__ int s[NT];
  int t = threadIdx.x, g = blockIdx.x * NT + t;
  int v = in[g];
  bool c = (v & 2) == 0;
  s[t] = v;
  __syncthreads();
  if (!c) return;
  out[g] = s[(t + 7) % NT] * 3;
}
__global__ void k_join_branch(const int *in, int *out, int *out2) {
  __shared__ int s[NT];
  int t = threadIdx.x, g = blockIdx.x * NT + t;
  int v = in[g];
  bool c = (v & 1) != 0, d = (v & 4) != 0;
  s[t] = v;
  __syncthreads();
  int w = s[(t + 3) % NT];
  out[g] = mix(w, 1);
  if (c) out[g] = mix(w, 2);
  if (d) out2[g] = mix(w, 3);   // the join in front of this test holds only the branch
  if (c) out2[g] += mix(w, 4);
  __syncthreads();
  if (d) out[g] += s[(t + 5) % NT];
}
__global__ void k_two_stops(const int *in, int *out, int *out2) {
  __shared__ int s[NT];
  int t = threadIdx.x, g = blockIdx.x * NT + t;
  int v = in[g];
  bool c = (v & 1) != 0, d = (v & 2) != 0, e = (v & 4) != 0;
  s[t] = v;
  __syncthreads();
  if (c) {
    int w = s[(t + 11) % NT];
    out[g] = mix(w, 5);
    if (e) out[g] += w;
    if (d) out2[g] = mix(w, 6);   // this join holds only the branch, and the code behind it is also entered from the barrier
  }
}
__global__ void k_loop_stops(const int *in, int *out, int *out2, int n) {
  __shared__ int s[NT];
  int t = threadIdx.x, g = blockIdx.x * NT + t;
  int v = in[g];
  bool c = (v & 1) != 0;
  s[t] = v;
  __syncthreads();
  int acc = 0;
  for (int i = 0; i < n; i++) {   // a barrier in a loop: the code behind it is entered from two barriers
    acc += s[(t + i) % NT];
    __syncthreads();
    s[t] = acc ^ i;
    __syncthreads();
  }
  out[g] = acc;
  if (c) out2[g] = acc + 1;
  if ((v & 8) != 0) out2[g] += s[(t + 9) % NT];
}
__global__ void k_thread_loop(const int *in, int *out) {
  __shared__ int s[NT];
  int t = threadIdx.x, g = blockIdx.x * NT + t;
  int v = in[g];
  int m = v & 3;
  s[t] = v;
  __syncthreads();
  int acc = 1;
  for (int i = 0; i < m; i++) acc = acc * 3 + s[(t + i) % NT];   // no barrier in it: the whole loop is in the region
  if (m) out[g] = acc;
}
__global__ void k_uniform_loop(const int *in, int *out, int n) {
  __shared__ int s[NT];
  int t = threadIdx.x, g = blockIdx.x * NT + t;
  int v = in[g];
  s[t] = v;
  __syncthreads();
  if (n > 2) {                    // __syncthreads on the arm: block-uniform, stays between the warp loops
    v += s[(t + 2) % NT];
    __syncthreads();
    s[t] = v;
    __syncthreads();
  }
  bool c = (v & 1) != 0;
  if (c) out[g] = s[(t + 4) % NT];
}
static int mixh(int v, int k) { return (v ^ (v >> 3)) * (2 * k + 1) + k; }
#define NOUT 10
static void ref(const int *in, int *o[NOUT], int n) {
  for (int b = 0; b < NB; b++) {
    const int *s = in + b * NT;
    for (int t = 0; t < NT; t++) {
      int g = b * NT + t, v = in[g];
      if (v & 1) o[0][g] = s[(t + 1) % NT] + 1;
      if (!(v & 2)) o[1][g] = s[(t + 7) % NT] * 3;
      int w = s[(t + 3) % NT];
      o[2][g] = mixh(w, 1);
      if (v & 1) o[2][g] = mixh(w, 2);
      if (v & 4) o[3][g] = mixh(w, 3);
      if (v & 1) o[3][g] += mixh(w, 4);
      if (v & 4) o[2][g] += s[(t + 5) % NT];
      if (v & 1) {
        w = s[(t + 11) % NT];
        o[4][g] = mixh(w, 5);
        if (v & 4) o[4][g] += w;
        if (v & 2) o[5][g] = mixh(w, 6);
      }
      if (v & 3) {
        int acc = 1;
        for (int i = 0; i < (v & 3); i++) acc = acc * 3 + s[(t + i) % NT];
        o[8][g] = acc;
      }
    }
    int x[NT], acc[NT], x2[NT], v2[NT];
    for (int t = 0; t < NT; t++) { x[t] = s[t]; acc[t] = 0; }
    for (int i = 0; i < n; i++) {
      for (int t = 0; t < NT; t++) acc[t] += x[(t + i) % NT];
      for (int t = 0; t < NT; t++) x[t] = acc[t] ^ i;
    }
    for (int t = 0; t < NT; t++) {
      int g = b * NT + t, v = in[g];
      o[6][g] = acc[t];
      if (v & 1) o[7][g] = acc[t] + 1;
      if (v & 8) o[7][g] += x[(t + 9) % NT];
      x2[t] = v2[t] = s[t];
    }
    if (n > 2) {
      for (int t = 0; t < NT; t++) v2[t] += s[(t + 2) % NT];
      for (int t = 0; t < NT; t++) x2[t] = v2[t];
    }
    for (int t = 0; t < NT; t++) if (v2[t] & 1) o[9][b * NT + t] = x2[(t + 4) % NT];
  }
}
int main() {
  const int n = 3, bytes = N * sizeof(int);
  int *h_in = (int *)malloc(bytes), *h[NOUT], *r[NOUT], *d[NOUT], *d_in;
  unsigned x = 2463534242u;
  for (int i = 0; i < N; i++) { x ^= x << 13; x ^= x >> 17; x ^= x << 5; h_in[i] = x & 0xffff; }   // the logical warps of a physical warp disagree
  for (int j = 0; j < NOUT; j++) {
    h[j] = (int *)malloc(bytes); r[j] = (int *)malloc(bytes);
    for (int i = 0; i < N; i++) r[j][i] = h[j][i] = -7 - j;
    cudaMalloc(&d[j], bytes);
    cudaMemcpy(d[j], h[j], bytes, cudaMemcpyHostToDevice);
  }
  cudaMalloc(&d_in, bytes);
  cudaMemcpy(d_in, h_in, bytes, cudaMemcpyHostToDevice);
  k_barrier_branch<<<NB, NT>>>(d_in, d[0]);
  cudaDeviceSynchronize();
  k_barrier_branch2<<<NB, NT>>>(d_in, d[1]);
  cudaDeviceSynchronize();
  k_join_branch<<<NB, NT>>>(d_in, d[2], d[3]);
  cudaDeviceSynchronize();
  k_two_stops<<<NB, NT>>>(d_in, d[4], d[5]);
  cudaDeviceSynchronize();
  k_loop_stops<<<NB, NT>>>(d_in, d[6], d[7], n);
  cudaDeviceSynchronize();
  k_thread_loop<<<NB, NT>>>(d_in, d[8]);
  cudaDeviceSynchronize();
  k_uniform_loop<<<NB, NT>>>(d_in, d[9], n);
  cudaDeviceSynchronize();
  ref(h_in, r, n);
  int bad = 0;
  for (int j = 0; j < NOUT; j++) {
    cudaMemcpy(h[j], d[j], bytes, cudaMemcpyDeviceToHost);
    int b = 0;
    for (int i = 0; i < N; i++) if (h[j][i] != r[j][i]) { if (b < 3) printf("out%d[%d]: %d != %d\n", j, i, h[j][i], r[j][i]); b++; }
    bad += b;
    printf("out%d: %d mismatches\n", j, b);
  }
  printf(bad ? "FAIL: %d mismatches\n" : "PASSED\n", bad);
  return bad != 0;
}
