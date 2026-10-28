// dxa_desc_test.cu -- DXA descriptor features through the general host API cudaDxaProgramDescNd:
//   1D box with an out-of-bounds fill value          (__vx_dxa_issue_1d, slot 0)
//   3D box (32x4x2) with explicit strides and a fill  (__vx_dxa_issue_3d, slot 1)
//   2D K-major box: the DXA transposes into shared   (__vx_dxa_issue_2d, slot 2, layout = 1)
// Device stubs: the translator deletes their bodies, the CuPBoP device runtime (cudaKernelImpl.cpp) defines them.
// Every thread calls the issue (a CTA-collective op, one transfer per CTA) and __vx_dxa_wait before __syncthreads.
// Out-of-bounds fill: this SimX decides out-of-bounds per <= 64-byte span from the span's first element, so the
// dim-0 tensor end must fall on a 64-byte line (n1 * 4 and d0 * 4 multiples of 64); rows / planes past the end
// (dims >= 1) are exact anyway.
//   usage: ./host.out [-n n1d] [-d d0 d1 d2] [-w width -H height]
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <cuda_runtime.h>

extern "C" int cudaDxaProgramDescNd(unsigned int slot, unsigned long long base_addr, unsigned int rank,
                                    const unsigned int *sizes, const unsigned int *strides_bytes,
                                    const unsigned int *box, unsigned int elem_bytes, unsigned int layout,
                                    unsigned int smem_stride_bytes, unsigned int fill);
__device__ void __vx_dxa_issue_1d(unsigned int, unsigned int, void *, unsigned int) {}
__device__ void __vx_dxa_issue_2d(unsigned int, unsigned int, void *, unsigned int, unsigned int) {}
__device__ void __vx_dxa_issue_3d(unsigned int, unsigned int, void *, unsigned int, unsigned int, unsigned int) {}
__device__ void __vx_dxa_wait(unsigned int) {}
__device__ unsigned int __vx_dxa_barrier_id(unsigned int) { return 0; }

#define B1 256
#define FILL1 0xC0F00000u // -7.5f
#define FILL3 0xDEADBEEFu

__global__ void dxa1d(uint32_t *__restrict__ out) {
  __shared__ __align__(64) uint32_t tile[B1];
  const unsigned int bar = __vx_dxa_barrier_id(0);
  __vx_dxa_issue_1d(0, bar, tile, blockIdx.x * B1);
  __vx_dxa_wait(bar);
  __syncthreads();
  out[blockIdx.x * B1 + threadIdx.x] = tile[(threadIdx.x + 3) % B1];
}

// box 32 x 4 x 2 (dim 0 innermost); out is the grid-padded volume (gx*32) x (gy*4) x (gz*2)
__global__ void dxa3d(uint32_t *__restrict__ out) {
  __shared__ __align__(64) uint32_t tile[256];
  const unsigned int bar = __vx_dxa_barrier_id(0);
  __vx_dxa_issue_3d(1, bar, tile, blockIdx.x * 32, blockIdx.y * 4, blockIdx.z * 2);
  __vx_dxa_wait(bar);
  __syncthreads();
  const int t = threadIdx.x, i0 = t % 32, i1 = (t / 32) % 4, i2 = t / 128;
  const int p0 = gridDim.x * 32, p1 = gridDim.y * 4;
  out[((blockIdx.z * 2 + i2) * p1 + (blockIdx.y * 4 + i1)) * p0 + (blockIdx.x * 32 + i0)] = tile[t];
}

// transpose through a K-major 16x16 box: element (i0 = column, i1 = row) lands at tile[i0 * 16 + i1]
__global__ void dxakmaj(float *__restrict__ dst, int width, int height) {
  __shared__ __align__(64) float tile[256];
  const unsigned int bar = __vx_dxa_barrier_id(0);
  __vx_dxa_issue_2d(2, bar, tile, blockIdx.x * 16, blockIdx.y * 16);
  __vx_dxa_wait(bar);
  __syncthreads();
  const int tid = threadIdx.y * 16 + threadIdx.x, yo = tid % 16, xo = tid / 16;
  const int xg = blockIdx.x * 16 + xo, yg = blockIdx.y * 16 + yo;
  if (xg < width && yg < height) dst[yg + xg * height] = tile[tid]; // = src(xg, yg) = tile[xo * 16 + yo]
}

int main(int argc, char **argv) {
  int n1 = 1008, d0 = 48, d1 = 10, d2 = 5, w = 40, h = 24;
  for (int i = 1; i < argc; ++i) {
    if (!strcmp(argv[i], "-n") && i + 1 < argc) n1 = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-d") && i + 3 < argc) { d0 = atoi(argv[++i]); d1 = atoi(argv[++i]); d2 = atoi(argv[++i]); }
    else if (!strcmp(argv[i], "-w") && i + 1 < argc) w = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-H") && i + 1 < argc) h = atoi(argv[++i]);
  }
  printf("dxa_desc_test: 1D n=%d, 3D %dx%dx%d, K-major transpose %dx%d\n", n1, d0, d1, d2, w, h);
  int errors = 0, e1 = 0, e3 = 0, ek = 0;

  // ---- 1D with fill
  {
    const int blocks = (n1 + B1 - 1) / B1, tot = blocks * B1;
    uint32_t *hin = (uint32_t *)malloc(n1 * 4), *hout = (uint32_t *)malloc(tot * 4), *din, *dout;
    for (int i = 0; i < n1; ++i) hin[i] = 0x3f800000u + (uint32_t)i * 4097u;
    cudaMalloc(&din, n1 * 4);
    cudaMalloc(&dout, tot * 4);
    cudaMemcpy(din, hin, n1 * 4, cudaMemcpyHostToDevice);
    const unsigned int sz[1] = {(unsigned)n1}, bx[1] = {B1};
    if (cudaDxaProgramDescNd(0, (unsigned long long)(uintptr_t)din, 1, sz, nullptr, bx, 4, 0, 0, FILL1)) return 2;
    dxa1d<<<blocks, B1>>>(dout);
    cudaMemcpy(hout, dout, tot * 4, cudaMemcpyDeviceToHost);
    for (int b = 0; b < blocks; ++b)
      for (int t = 0; t < B1; ++t) {
        const int s = b * B1 + (t + 3) % B1;
        const uint32_t want = s < n1 ? hin[s] : FILL1;
        if (hout[b * B1 + t] != want) {
          if (e1 < 5) printf("1D MISMATCH out[%d]: got 0x%08x, expected 0x%08x\n", b * B1 + t, hout[b * B1 + t], want);
          e1++;
        }
      }
    printf("1D: %d errors\n", e1);
  }
  // ---- 3D with explicit strides and fill
  {
    const int gx = (d0 + 31) / 32, gy = (d1 + 3) / 4, gz = (d2 + 1) / 2;
    const int p0 = gx * 32, p1 = gy * 4, p2 = gz * 2, tot = p0 * p1 * p2, nin = d0 * d1 * d2;
    uint32_t *hin = (uint32_t *)malloc(nin * 4), *hout = (uint32_t *)malloc(tot * 4), *din, *dout;
    for (int i = 0; i < nin; ++i) hin[i] = 0x01000000u + (uint32_t)i;
    cudaMalloc(&din, nin * 4);
    cudaMalloc(&dout, tot * 4);
    cudaMemcpy(din, hin, nin * 4, cudaMemcpyHostToDevice);
    const unsigned int sz[3] = {(unsigned)d0, (unsigned)d1, (unsigned)d2};
    const unsigned int st[2] = {(unsigned)(d0 * 4), (unsigned)(d0 * d1 * 4)};
    const unsigned int bx[3] = {32, 4, 2};
    if (cudaDxaProgramDescNd(1, (unsigned long long)(uintptr_t)din, 3, sz, st, bx, 4, 0, 0, FILL3)) return 2;
    dxa3d<<<dim3(gx, gy, gz), 256>>>(dout);
    cudaMemcpy(hout, dout, tot * 4, cudaMemcpyDeviceToHost);
    for (int z = 0; z < p2; ++z)
      for (int y = 0; y < p1; ++y)
        for (int x = 0; x < p0; ++x) {
          const bool in = x < d0 && y < d1 && z < d2;
          const uint32_t want = in ? hin[(z * d1 + y) * d0 + x] : FILL3;
          const uint32_t got = hout[(z * p1 + y) * p0 + x];
          if (got != want) {
            if (e3 < 5) printf("3D MISMATCH (%d,%d,%d): got 0x%08x, expected 0x%08x\n", x, y, z, got, want);
            e3++;
          }
        }
    printf("3D: %d errors\n", e3);
  }
  // ---- 2D K-major transpose
  {
    float *hin = (float *)malloc(w * h * 4), *hout = (float *)malloc(w * h * 4), *din, *dout;
    for (int i = 0; i < w * h; ++i) hin[i] = (float)i * 0.5f - 3.0f;
    cudaMalloc(&din, w * h * 4);
    cudaMalloc(&dout, w * h * 4);
    cudaMemcpy(din, hin, w * h * 4, cudaMemcpyHostToDevice);
    cudaMemset(dout, 0, w * h * 4);
    const unsigned int sz[2] = {(unsigned)w, (unsigned)h}, st[1] = {(unsigned)(w * 4)}, bx[2] = {16, 16};
    if (cudaDxaProgramDescNd(2, (unsigned long long)(uintptr_t)din, 2, sz, st, bx, 4, 1, 0, 0)) return 2;
    dxakmaj<<<dim3((w + 15) / 16, (h + 15) / 16), dim3(16, 16)>>>(dout, w, h);
    cudaMemcpy(hout, dout, w * h * 4, cudaMemcpyDeviceToHost);
    for (int y = 0; y < h; ++y)
      for (int x = 0; x < w; ++x)
        if (hout[y + x * h] != hin[x + y * w]) {
          if (ek < 5) printf("K-major MISMATCH (%d,%d): got %f, expected %f\n", x, y, hout[y + x * h], hin[x + y * w]);
          ek++;
        }
    printf("K-major: %d errors\n", ek);
  }
  errors = e1 + e3 + ek;
  printf("%s\n", errors ? "FAILED!" : "PASSED!");
  return errors ? 1 : 0;
}
