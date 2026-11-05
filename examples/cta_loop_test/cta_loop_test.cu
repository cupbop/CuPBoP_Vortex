// Conformance test of CUPBOP_CTA_LOOP (experiments/ctaloop): launch shapes and the cases the block loop must keep: every block once, the
// CUDA grid in gridDim, blocks that leave early, shared memory between blocks of one hardware CTA (a read after the block's last barrier),
// dynamic shared memory, blocks of very different lengths, the last-block-done pattern, atomics. Passes with and without the switch.
// k_spin, k_spin_vol, k_ticket_spin: a block waits for another block; the translator refuses them (cupbop_launch_fix.txt has no line for them).
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
__global__ void k_ids(int *out) {
  const int b = (blockIdx.z * gridDim.y + blockIdx.y) * gridDim.x + blockIdx.x, t = (threadIdx.z * blockDim.y + threadIdx.y) * blockDim.x + threadIdx.x;
  const int bs = blockDim.x * blockDim.y * blockDim.z;
  out[b * bs + t] = 7 * b + 3 * t + (int)gridDim.x + 1000 * (int)gridDim.y + 100000 * (int)gridDim.z;
}
__global__ void k_once(int *cnt) {
  const int b = (blockIdx.z * gridDim.y + blockIdx.y) * gridDim.x + blockIdx.x;
  if (threadIdx.x == 0 && threadIdx.y == 0 && threadIdx.z == 0) atomicAdd(&cnt[b], 1);
}
__global__ void k_1d(float *o, const float *a, int n) { int i = blockIdx.x * blockDim.x + threadIdx.x; if (i < n) o[i] = 2.f * a[i] + 1.f; }
__global__ void k_stride(int *o, int n) { for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += gridDim.x * blockDim.x) o[i] += i + 1; }
__global__ void k_early(int *o) {   // a whole block leaves; warps of a block leave; both are decided by the block index
  const int b = blockIdx.x, t = threadIdx.x;
  if (b % 3 == 1) return;
  if (b % 3 == 2 && t >= 40) return;
  o[b * blockDim.x + t] = b + t;
}
__global__ void k_rev(int *o, const int *in) {   // the read after the barrier is the block's last use of shared memory
  __shared__ int s[512];
  const int t = threadIdx.x, n = blockDim.x, i = blockIdx.x * n + t;
  s[t] = in[i];
  __syncthreads();
  int v = s[n - 1 - t];
  for (int r = 0; r < (t & 7); ++r) v = v * 3 + s[(t + r) % n];   // warps finish at different times
  o[i] = v;
}
__global__ void k_dyn(int *o, const int *in) {
  extern __shared__ int d[];
  const int t = threadIdx.x, n = blockDim.x, i = blockIdx.x * n + t;
  d[t] = in[i] + (int)blockIdx.x;
  __syncthreads();
  o[i] = d[(t + 1) % n] - d[t];
}
__global__ void k_red(float *o, const float *in, int n) {   // the tree of block reductions: several barriers per block
  __shared__ float s[256];
  const int t = threadIdx.x; int i = blockIdx.x * blockDim.x + t;
  s[t] = i < n ? in[i] : 0.f;
  __syncthreads();
  for (int h = blockDim.x / 2; h > 0; h >>= 1) { if (t < h) s[t] += s[t + h]; __syncthreads(); }
  if (t == 0) o[blockIdx.x] = s[0];
}
__global__ void k_long(int *o, const int *len) {   // block lengths differ by orders of magnitude
  const int b = blockIdx.x; int v = threadIdx.x;
  for (int k = 0; k < len[b]; ++k) v = v * 5 + k;
  o[b * blockDim.x + threadIdx.x] = v;
}
// Vortex L1 caches are not coherent between cores: what one block reads of another block's writes goes through atomics (L2)
__global__ void k_last(int *o, const int *in, int *part, unsigned *done) {   // no block waits; the last one to finish sums
  __shared__ bool last;
  const int t = threadIdx.x;
  if (t == 0) atomicExch(&part[blockIdx.x], in[blockIdx.x]);
  __threadfence();
  if (t == 0) { unsigned v = atomicAdd(done, 1u); last = v == gridDim.x - 1; }
  __syncthreads();
  if (last && t == 0) { int s = 0; for (int b = 0; b < (int)gridDim.x; ++b) s += atomicAdd(&part[b], 0); o[0] = s; }
}
__global__ void k_ticket(int *o, int *ctr) {   // block numbers from an atomic ticket: order free, each ticket once
  __shared__ int id;
  if (threadIdx.x == 0) id = atomicAdd(ctr, 1);
  __syncthreads();
  o[id * blockDim.x + threadIdx.x] = id;
  __syncthreads();   // the value is read before the next block's thread 0 may write it
}
__global__ void k_exit_bar(int *o) {   // a whole block leaves before its barrier
  __shared__ int s;
  if (blockIdx.x % 4 == 1) return;
  if (threadIdx.x == 0) s = (int)blockIdx.x * 3;
  __syncthreads();
  o[blockIdx.x * blockDim.x + threadIdx.x] = s;
}
__global__ void k_spin(int *flag, int *o) {   // refused: block b waits for block b - 1
  const int b = blockIdx.x;
  if (threadIdx.x == 0) { if (b) while (atomicAdd(&flag[b - 1], 0) == 0) { } atomicExch(&o[b], b); __threadfence(); atomicExch(&flag[b], 1); }
}
__global__ void k_spin_vol(volatile int *flag, int *o, int spin) {   // refused: the same wait with a volatile load; the launch runs no spin (no coherent L1)
  const int b = blockIdx.x;
  if (threadIdx.x == 0) { if (spin && b) while (flag[b - 1] == 0) { } o[b] = b; }
}
__global__ void k_ticket_spin(int *lock, int *o) {   // refused: a spin lock
  if (threadIdx.x == 0) { o[blockIdx.x] = 0; while (atomicCAS(lock, 0, 1) != 0) { } atomicAdd(&o[blockIdx.x], 1); atomicExch(lock, 0); }
}
static int fails = 0;
#define CHECK(c, ...) do { if (!(c)) { if (fails++ < 20) { printf("FAIL: "); printf(__VA_ARGS__); printf("\n"); } } } while (0)
template <class T> static T *dev(size_t n, int fill) { T *d; cudaMalloc((void **)&d, n * sizeof(T)); std::vector<T> h(n, (T)fill); cudaMemcpy(d, h.data(), n * sizeof(T), cudaMemcpyHostToDevice); return d; }
template <class T> static T *put(const std::vector<T> &h) { T *d; cudaMalloc((void **)&d, h.size() * sizeof(T)); cudaMemcpy(d, h.data(), h.size() * sizeof(T), cudaMemcpyHostToDevice); return d; }
template <class T> static std::vector<T> get(T *d, size_t n) { std::vector<T> h(n); cudaMemcpy(h.data(), d, n * sizeof(T), cudaMemcpyDeviceToHost); return h; }
int main(int argc, char **argv) {
  struct S { int gx, gy, gz, bx, by, bz; };
  const S shapes[] = {{37, 1, 1, 64, 1, 1}, {300, 1, 1, 32, 1, 1}, {129, 1, 1, 33, 1, 1}, {13, 7, 1, 64, 1, 1}, {7, 13, 1, 16, 16, 1}, {5, 3, 4, 32, 2, 1}, {1, 129, 1, 96, 1, 1},
                      {1, 1, 65, 128, 1, 1}, {2, 2, 2, 8, 8, 2}, {64, 64, 1, 32, 1, 1}, {1, 1, 1, 256, 1, 1}, {3, 1, 1, 512, 1, 1}, {100, 3, 1, 100, 1, 1}};
  for (const S &s : shapes) {
    const dim3 g(s.gx, s.gy, s.gz), b(s.bx, s.by, s.bz); const int B = s.gx * s.gy * s.gz, T = s.bx * s.by * s.bz;
    int *o = dev<int>((size_t)B * T, -1); k_ids<<<g, b>>>(o); cudaDeviceSynchronize(); auto h = get(o, (size_t)B * T);
    for (int i = 0; i < B * T; ++i) CHECK(h[i] == 7 * (i / T) + 3 * (i % T) + s.gx + 1000 * s.gy + 100000 * s.gz, "k_ids grid %d %d %d block %d %d %d [%d] = %d", s.gx, s.gy, s.gz, s.bx, s.by, s.bz, i, h[i]);
    int *c = dev<int>(B, 0); k_once<<<g, b>>>(c); cudaDeviceSynchronize(); auto hc = get(c, B);
    for (int i = 0; i < B; ++i) CHECK(hc[i] == 1, "k_once grid %d %d %d block %d: %d", s.gx, s.gy, s.gz, i, hc[i]);
  }
  for (int n : {1, 31, 32, 33, 1000, 4097, 65537}) {
    std::vector<float> a(n); for (int i = 0; i < n; ++i) a[i] = (float)(i % 251);
    float *da = put(a), *o = dev<float>(n, 0); k_1d<<<(n + 127) / 128, 128>>>(o, da, n); cudaDeviceSynchronize(); auto h = get(o, n);
    for (int i = 0; i < n; ++i) CHECK(h[i] == 2.f * a[i] + 1.f, "k_1d n=%d [%d]", n, i);
    int *q = dev<int>(n, 0); k_stride<<<37, 64>>>(q, n); cudaDeviceSynchronize(); auto hq = get(q, n);
    for (int i = 0; i < n; ++i) CHECK(hq[i] == i + 1, "k_stride n=%d [%d] = %d", n, i, hq[i]);
  }
  { const int G = 301, T = 96; int *o = dev<int>(G * T, -1); k_early<<<G, T>>>(o); cudaDeviceSynchronize(); auto h = get(o, G * T);
    for (int b = 0; b < G; ++b) for (int t = 0; t < T; ++t) { int w = b % 3 == 1 || (b % 3 == 2 && t >= 40) ? -1 : b + t; CHECK(h[b * T + t] == w, "k_early %d %d = %d", b, t, h[b * T + t]); } }
  for (int T : {64, 128, 256, 512}) { const int G = 263; std::vector<int> in(G * T); for (int i = 0; i < G * T; ++i) in[i] = i * 2654435 + 7;
    int *di = put(in), *o = dev<int>(G * T, 0); k_rev<<<G, T>>>(o, di); cudaDeviceSynchronize(); auto h = get(o, G * T);
    for (int b = 0; b < G; ++b) for (int t = 0; t < T; ++t) { int v = in[b * T + T - 1 - t]; for (int r = 0; r < (t & 7); ++r) v = v * 3 + in[b * T + (t + r) % T]; CHECK(h[b * T + t] == v, "k_rev T=%d %d %d", T, b, t); }
    int *o2 = dev<int>(G * T, 0); k_dyn<<<G, T, T * 4>>>(o2, di); cudaDeviceSynchronize(); auto h2 = get(o2, G * T);
    for (int b = 0; b < G; ++b) for (int t = 0; t < T; ++t) CHECK(h2[b * T + t] == in[b * T + (t + 1) % T] - in[b * T + t], "k_dyn T=%d %d %d", T, b, t); }
  { const int G = 200, T = 256, n = G * T - 37; std::vector<float> a(n); for (int i = 0; i < n; ++i) a[i] = (float)(i % 17);
    float *da = put(a), *o = dev<float>(G, 0); k_red<<<G, T>>>(o, da, n); cudaDeviceSynchronize(); auto h = get(o, G);
    for (int b = 0; b < G; ++b) { float s = 0; for (int t = 0; t < T; ++t) { int i = b * T + t; if (i < n) s += a[i]; } CHECK(h[b] == s, "k_red %d: %f %f", b, h[b], s); } }
  { const int G = 150, T = 64; std::vector<int> len(G); for (int b = 0; b < G; ++b) len[b] = b % 16 == 3 ? 400 : b % 5;
    int *dl = put(len), *o = dev<int>(G * T, 0); k_long<<<G, T>>>(o, dl); cudaDeviceSynchronize(); auto h = get(o, G * T);
    for (int b = 0; b < G; ++b) for (int t = 0; t < T; ++t) { int v = t; for (int k = 0; k < len[b]; ++k) v = v * 5 + k; CHECK(h[b * T + t] == v, "k_long %d %d", b, t); } }
  { const int G = 97; std::vector<int> a(G); int s = 0; for (int i = 0; i < G; ++i) { a[i] = i; s += a[i]; }
    int *da = put(a), *p = dev<int>(G, 0), *o = dev<int>(1, 0); unsigned *dn = dev<unsigned>(1, 0); k_last<<<G, 32>>>(o, da, p, dn); cudaDeviceSynchronize(); CHECK(get(o, 1)[0] == s, "k_last %d %d", get(o, 1)[0], s); }
  { const int G = 211, T = 64; int *o = dev<int>(G * T, -1), *c = dev<int>(1, 0); k_ticket<<<G, T>>>(o, c); cudaDeviceSynchronize(); auto h = get(o, G * T);
    for (int i = 0; i < G * T; ++i) CHECK(h[i] == i / T, "k_ticket [%d] = %d", i, h[i]);
    int *e = dev<int>(G * T, -1); k_exit_bar<<<G, T>>>(e); cudaDeviceSynchronize(); auto he = get(e, G * T);
    for (int i = 0; i < G * T; ++i) { int b = i / T; CHECK(he[i] == (b % 4 == 1 ? -1 : b * 3), "k_exit_bar [%d] = %d", i, he[i]); } }
  { const int G = 40; int *f = dev<int>(G, 0), *o = dev<int>(G, -1); k_spin<<<G, 32>>>(f, o); cudaDeviceSynchronize(); auto h = get(o, G); for (int b = 0; b < G; ++b) CHECK(h[b] == b, "k_spin %d", b); }
  { const int G = 40; int *f = dev<int>(G, 0), *o = dev<int>(G, -1); k_spin_vol<<<G, 32>>>(f, o, 0); cudaDeviceSynchronize(); auto h = get(o, G); for (int b = 0; b < G; ++b) CHECK(h[b] == b, "k_spin_vol %d", b); }
  { const int G = 40; int *l = dev<int>(1, 0), *o = dev<int>(G, -1); k_ticket_spin<<<G, 32>>>(l, o); cudaDeviceSynchronize(); auto h = get(o, G); for (int b = 0; b < G; ++b) CHECK(h[b] == 1, "k_ticket_spin %d", b); }
  printf(fails ? "FAILED: %d checks\n" : "PASSED\n", fails);
  return fails != 0;
}
