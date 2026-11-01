// By-value struct kernel arguments (bugfix12 bug 3): a 20-byte float struct between scalar arguments, a struct with
// mixed int / double / char members (padding), a small 8-byte struct and a 1-byte struct. Every thread writes what it
// read; the host checks every field.
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

struct P5 { float a, b, c, d, e; };              // 20 bytes, align 4 (the E10 hotspot HotspotParams shape)
struct Mix { int i; double x; char ch; short s; }; // 24 bytes with padding, align 8
struct Two { int lo, hi; };                       // 8 bytes: one launch slot
struct One { char c; };                           // 1 byte
struct __align__(16) Q { float x, y, z, w; };     // 16 bytes, align 16 (wrapper makes an aligned copy)

__global__ void struct_kernel(float *out, int n, P5 p, int k, Mix m, const float *in, Two t, One o, float last, Q q) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i >= n) return;
  float v = in[i];
  float *r = out + i * 14;
  m.i += i;                                       // writes to a by-value parameter stay private to the thread
  r[0] = p.a * v; r[1] = p.b + v; r[2] = p.c; r[3] = p.d; r[4] = p.e;
  r[5] = (float)k; r[6] = (float)(m.i - i); r[7] = (float)(m.x * 2.0); r[8] = (float)m.ch + (float)m.s;
  r[9] = (float)(t.lo - t.hi); r[10] = (float)o.c; r[11] = last;
  r[12] = q.x + q.y * q.z - q.w; r[13] = (float)m.i;
}

int main() {
  const int n = 100;
  P5 p = {1.5f, -2.25f, 3.125f, 4.0f, -5.5f};
  Mix m = {-7, 1.0e-3, 'Z', -300};
  Two t = {11, 4};
  One o = {'q'};
  int k = 42; float last = 0.75f;
  Q q = {1.0f, 2.0f, 3.0f, 0.5f};
  float *hin = (float *)malloc(n * 4), *hout = (float *)malloc(n * 14 * 4);
  for (int i = 0; i < n; ++i) hin[i] = (float)i * 0.5f;
  float *din, *dout;
  cudaMalloc(&din, n * 4); cudaMalloc(&dout, n * 14 * 4);
  cudaMemcpy(din, hin, n * 4, cudaMemcpyHostToDevice);
  cudaMemset(dout, 0, n * 14 * 4);
  struct_kernel<<<(n + 31) / 32, 32>>>(dout, n, p, k, m, din, t, o, last, q);
  cudaDeviceSynchronize();
  cudaMemcpy(hout, dout, n * 14 * 4, cudaMemcpyDeviceToHost);
  int bad = 0;
  for (int i = 0; i < n; ++i) {
    float v = hin[i];
    float e[14] = {p.a * v, p.b + v, p.c, p.d, p.e, (float)k, (float)m.i, (float)(m.x * 2.0), (float)m.ch + (float)m.s,
                   (float)(t.lo - t.hi), (float)o.c, last, q.x + q.y * q.z - q.w, (float)(m.i + i)};
    for (int j = 0; j < 14; ++j)
      if (hout[i * 14 + j] != e[j]) { if (bad < 10) printf("mismatch i=%d field=%d got %g want %g\n", i, j, hout[i * 14 + j], e[j]); ++bad; }
  }
  if (bad) printf("FAILED: %d mismatches\n", bad); else printf("PASSED\n");
  return bad != 0;
}
