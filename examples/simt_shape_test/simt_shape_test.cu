// Conformance test of the SIMT start-point switches (experiments/p2d): launch shapes around the warp-loop copy of CUPBOP_TRIP_VERSION (partial
// warps, 2D and 3D blocks on a kernel that reads only threadIdx.x, fewer than 4 trips), and the cases CUPBOP_TRIP_HOIST must keep: a null optional pointer behind
// a condition, a load after a store of the same thread, a value written before a barrier, loads on a divergent path. Prints PASSED or FAIL lines.
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <vector>
__global__ void k_x(int *out) { out[threadIdx.x] = 3 * (int)threadIdx.x + 1; }   // threadIdx.x only: same value from every y, z
__global__ void k_gx(int *out, int n) { int i = blockIdx.x * blockDim.x + threadIdx.x; if (i < n) out[i] = 5 * i + 2; }
__global__ void k_xyz(int *out) {
  int t = (threadIdx.z * blockDim.y + threadIdx.y) * blockDim.x + threadIdx.x;
  out[t] = (int)threadIdx.x + 100 * (int)threadIdx.y + 10000 * (int)threadIdx.z + 1000000 * (int)blockDim.x;
}
__global__ void k_opt(float *out, const float *bias, int n) {   // bias may be null
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) { float s = 0; if (bias) s = bias[0] + bias[1] * 2 + bias[2] * 3 + bias[3] * 4 + bias[4] * 5; out[i] = s + i; }
}
__global__ void k_div(float *out, const float *tbl, int n, int m, int r) {    // loads on a path taken by some lanes of some trips, or by none (then tbl may be null)
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) { if (i % m == r) out[i] = tbl[0] + tbl[1] + tbl[2] + tbl[3] + tbl[4]; else out[i] = -1; }
}
__global__ void k_store_first(int *p, int *out) {               // the load follows a store of the same thread: it reads this thread's word
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  p[0 + blockIdx.x * 0] = p[0];                                  // no change of value
  if (threadIdx.x == 0 && blockIdx.x == 0) p[1] = 77;
  __syncthreads();
  out[i] = p[1];
}
__global__ void k_barrier(int *p, int *out) {                   // one thread writes, the barrier orders, all read
  if (threadIdx.x == 0) p[blockIdx.x] = 1000 + blockIdx.x;
  __syncthreads();
  out[blockIdx.x * blockDim.x + threadIdx.x] = p[blockIdx.x];
}
static int fails = 0;
#define CHECK(c, ...) do { if (!(c)) { if (fails++ < 20) { printf("FAIL: "); printf(__VA_ARGS__); printf("\n"); } } } while (0)
template <class T> static T *dev(size_t n, int fill) { T *d; cudaMalloc((void **)&d, n * sizeof(T)); std::vector<T> h(n, (T)fill); cudaMemcpy(d, h.data(), n * sizeof(T), cudaMemcpyHostToDevice); return d; }
template <class T> static std::vector<T> get(T *d, size_t n) { std::vector<T> h(n); cudaMemcpy(h.data(), d, n * sizeof(T), cudaMemcpyDeviceToHost); return h; }
int main(int argc, char **argv) {
  struct S { int x, y, z; };
  const S shapes[] = {{32, 1, 1}, {64, 1, 1}, {96, 1, 1}, {100, 1, 1}, {128, 1, 1}, {160, 1, 1}, {256, 1, 1}, {512, 1, 1}, {33, 1, 1}, {1, 1, 1},
                      {64, 2, 1}, {128, 2, 1}, {32, 4, 1}, {16, 16, 1}, {32, 4, 2}, {8, 8, 2}, {33, 3, 1}, {1, 64, 1}, {128, 1, 2}};
  for (const S &s : shapes) {
    const dim3 b(s.x, s.y, s.z); const int T = s.x * s.y * s.z, G = 5;
    { int *o = dev<int>(T + 64, -7); k_x<<<1, b>>>(o); cudaDeviceSynchronize(); auto h = get(o, T + 64);
      for (int i = 0; i < T + 64; ++i) CHECK(h[i] == (i < s.x ? 3 * i + 1 : -7), "k_x %dx%dx%d at %d: %d", s.x, s.y, s.z, i, h[i]); cudaFree(o); }
    if (s.y == 1 && s.z == 1) { const int n = G * T - 3; int *o = dev<int>(n + 64, -7); k_gx<<<G, b>>>(o, n); cudaDeviceSynchronize(); auto h = get(o, n + 64);
      for (int i = 0; i < n + 64; ++i) CHECK(h[i] == (i < n ? 5 * i + 2 : -7), "k_gx %d at %d: %d", s.x, i, h[i]); cudaFree(o); }
    { int *o = dev<int>(T + 64, -7); k_xyz<<<1, b>>>(o); cudaDeviceSynchronize(); auto h = get(o, T + 64);
      for (int z = 0; z < s.z; ++z) for (int y = 0; y < s.y; ++y) for (int x = 0; x < s.x; ++x) { int t = (z * s.y + y) * s.x + x; CHECK(h[t] == x + 100 * y + 10000 * z + 1000000 * s.x, "k_xyz %dx%dx%d at %d: %d", s.x, s.y, s.z, t, h[t]); }
      CHECK(h[T] == -7, "k_xyz past the end"); cudaFree(o); }
  }
  for (int bs : {64, 128, 256, 512, 100}) {
    const int G = 4, n = G * bs - 5;
    float *o = dev<float>(n, 0); k_opt<<<G, bs>>>(o, nullptr, n); cudaDeviceSynchronize(); auto h = get(o, n);
    for (int i = 0; i < n; ++i) CHECK(h[i] == (float)i, "k_opt null bs %d at %d: %f", bs, i, h[i]);
    float b[5] = {1, 2, 3, 4, 5}, *db = dev<float>(5, 0); cudaMemcpy(db, b, sizeof b, cudaMemcpyHostToDevice);
    k_opt<<<G, bs>>>(o, db, n); cudaDeviceSynchronize(); h = get(o, n);
    for (int i = 0; i < n; ++i) CHECK(h[i] == 55.f + i, "k_opt bs %d at %d: %f", bs, i, h[i]);
    k_div<<<G, bs>>>(o, db, n, 3, 0); cudaDeviceSynchronize(); h = get(o, n);
    for (int i = 0; i < n; ++i) CHECK(h[i] == (i % 3 == 0 ? 15.f : -1.f), "k_div bs %d at %d: %f", bs, i, h[i]);
    k_div<<<G, bs>>>(o, nullptr, n, 3, 5); cudaDeviceSynchronize(); h = get(o, n);
    for (int i = 0; i < n; ++i) CHECK(h[i] == -1.f, "k_div null bs %d at %d: %f", bs, i, h[i]);
    cudaFree(o); cudaFree(db);
    int *p = dev<int>(64, 0), *q = dev<int>(G * bs, 0);
    k_barrier<<<G, bs>>>(p, q); cudaDeviceSynchronize(); auto hq = get(q, G * bs);
    for (int i = 0; i < G * bs; ++i) CHECK(hq[i] == 1000 + i / bs, "k_barrier bs %d at %d: %d", bs, i, hq[i]);
    k_store_first<<<1, bs>>>(p, q); cudaDeviceSynchronize(); hq = get(q, bs);
    for (int i = 0; i < bs; ++i) CHECK(hq[i] == 77, "k_store_first bs %d at %d: %d", bs, i, hq[i]);
    cudaFree(p); cudaFree(q);
  }
  printf(fails ? "FAILED %d\n" : "PASSED\n", fails);
  return fails != 0;
}
