// Kernel naming and launch forms (bugfix12 bugs 4 and 5): an extern "C" (unmangled) kernel launched with <<<>>>,
// a C++ kernel launched with <<<>>>, and a direct host call of a function whose name starts with "cudaLaunchKernel"
// (cudaLaunchKernel_vortex with a kernel name string, as a lifted-kernel host does). The host translator used to take
// every such direct call for a kernel stub (segfault), and the kernel translator cut the first two characters of
// every kernel name for lookup.txt ("e10_..." -> "_..."), so an extern "C" kernel was not found at launch.
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>
extern "C" cudaError_t cudaLaunchKernel_vortex(const char *func, dim3 gridDim, dim3 blockDim, void **args, size_t sharedMem,
                                               cudaStream_t stream, const int num_args);
extern "C" __global__ void e10_scale(float *x, int n, float s) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) x[i] *= s;
}
__global__ void add_one(float *x, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) x[i] += 1.0f;
}
int main() {
  const int n = 200;
  float h[n];
  for (int i = 0; i < n; ++i) h[i] = (float)i;
  float *d; cudaMalloc(&d, n * 4); cudaMemcpy(d, h, n * 4, cudaMemcpyHostToDevice);
  e10_scale<<<(n + 63) / 64, 64>>>(d, n, 2.0f);   // x = 2i
  add_one<<<(n + 63) / 64, 64>>>(d, n);           // x = 2i + 1
  int nn = n; float s = 3.0f; void *args[3] = {&d, &nn, &s};
  cudaLaunchKernel_vortex("e10_scale", dim3((n + 63) / 64), dim3(64), args, 0, 0, 3);   // x = 6i + 3
  cudaDeviceSynchronize();
  cudaMemcpy(h, d, n * 4, cudaMemcpyDeviceToHost);
  int bad = 0;
  for (int i = 0; i < n; ++i) if (h[i] != 6.0f * i + 3.0f) { if (bad < 5) printf("x[%d] = %g, want %g\n", i, h[i], 6.0f * i + 3.0f); ++bad; }
  if (bad) printf("FAILED: %d mismatches\n", bad); else printf("PASSED\n");
  return bad != 0;
}
