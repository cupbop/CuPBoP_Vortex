// mma.sync.aligned.m8n8k4.<la>.<lb>.f32.f16.f16.f32 (Volta quad-pair MMA) for all four layouts (bugfix12 bug 2).
// golden_m884.txt: per layout and lane the inputs (a0 a1 b0 b1 c0..c7, hex words) and the outputs d0..d7 of an
// NVIDIA A100 running the PTX instruction (experiments/bugfix12/mma884/m884_gpu.cu). The values are small multiples
// of 1/8 and 1/16, so every product and sum is exact and the results must match bit for bit; a CPU model of the
// PTX fragment layouts is checked as well.
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <cuda_runtime.h>
#define MMA(LA, LB) asm volatile("mma.sync.aligned.m8n8k4." LA "." LB ".f32.f16.f16.f32 {%0,%1,%2,%3,%4,%5,%6,%7}, {%8,%9}, {%10,%11}, {%12,%13,%14,%15,%16,%17,%18,%19};" \
  : "=f"(d[0]), "=f"(d[1]), "=f"(d[2]), "=f"(d[3]), "=f"(d[4]), "=f"(d[5]), "=f"(d[6]), "=f"(d[7]) \
  : "r"(in[0]), "r"(in[1]), "r"(in[2]), "r"(in[3]), "f"(c[0]), "f"(c[1]), "f"(c[2]), "f"(c[3]), "f"(c[4]), "f"(c[5]), "f"(c[6]), "f"(c[7]))
__global__ void mma884(const uint32_t *io, float *out, int lay) {
  const int l = threadIdx.x; uint32_t in[4]; float c[8], d[8];
  for (int i = 0; i < 4; ++i) in[i] = io[l * 12 + i];
  for (int i = 0; i < 8; ++i) c[i] = __uint_as_float(io[l * 12 + 4 + i]);
  if (lay == 0) MMA("row", "col"); else if (lay == 1) MMA("row", "row"); else if (lay == 2) MMA("col", "row"); else MMA("col", "col");
  for (int i = 0; i < 8; ++i) out[l * 8 + i] = d[i];
}
static float h2f(uint32_t h) {
  h &= 0xffff; uint32_t s = (h & 0x8000) << 16, e = (h >> 10) & 31, m = h & 0x3ff, b;
  if (e == 0) { float f = m * (1.0f / 16777216.0f); memcpy(&b, &f, 4); b |= s; } else b = s | ((e + 112) << 23) | (m << 13);
  float f; memcpy(&f, &b, 4); return f;
}
static void cpu(const uint32_t *io, float *out, int la_row, int lb_row) {
  float A[4][8][4], B[4][4][8], C[4][8][8];
  for (int l = 0; l < 32; ++l) {
    const int q = (l >> 2) & 3, hi = l >= 16, r4 = l % 4;
    for (int e = 0; e < 4; ++e) {
      float a = h2f(io[l * 12 + (e >> 1)] >> (16 * (e & 1))), b = h2f(io[l * 12 + 2 + (e >> 1)] >> (16 * (e & 1)));
      if (la_row) A[q][r4 + 4 * hi][e] = a; else A[q][e + 4 * hi][r4] = a;
      if (lb_row) B[q][r4][e + 4 * hi] = b; else B[q][e][r4 + 4 * hi] = b;
    }
    for (int i = 0; i < 8; ++i) { float cv; memcpy(&cv, &io[l * 12 + 4 + i], 4); C[q][(l & 1) + (i & 2) + 4 * hi][(i & 4) + (l & 2) + (i & 1)] = cv; }
  }
  for (int l = 0; l < 32; ++l) {
    const int q = (l >> 2) & 3, hi = l >= 16;
    for (int i = 0; i < 8; ++i) {
      int row = (l & 1) + (i & 2) + 4 * hi, col = (i & 4) + (l & 2) + (i & 1);
      double s = C[q][row][col]; for (int k = 0; k < 4; ++k) s += (double)A[q][row][k] * B[q][k][col];
      out[l * 8 + i] = (float)s;
    }
  }
}
int main(int argc, char **argv) {
  FILE *g = fopen(argc > 1 ? argv[1] : "golden_m884.txt", "r");
  if (!g) { printf("FAILED: no golden_m884.txt\n"); return 1; }
  static uint32_t io[4][32 * 12], gold[4][32 * 8];
  for (int n = 0; n < 128; ++n) {
    int lay, l; if (fscanf(g, "%d %d", &lay, &l) != 2 || lay < 0 || lay > 3 || l < 0 || l > 31) { printf("FAILED: bad golden\n"); return 1; }
    for (int i = 0; i < 12; ++i) if (fscanf(g, "%x", &io[lay][l * 12 + i]) != 1) { printf("FAILED: bad golden\n"); return 1; }
    for (int i = 0; i < 8; ++i) if (fscanf(g, "%x", &gold[lay][l * 8 + i]) != 1) { printf("FAILED: bad golden\n"); return 1; }
  }
  fclose(g);
  uint32_t *dio; float *dout; cudaMalloc(&dio, sizeof(io[0])); cudaMalloc(&dout, 32 * 8 * 4);
  const char *names[4] = {"row.col", "row.row", "col.row", "col.col"};
  int bad = 0;
  for (int lay = 0; lay < 4; ++lay) {
    float out[256], ref[256];
    cudaMemcpy(dio, io[lay], sizeof(io[0]), cudaMemcpyHostToDevice);
    mma884<<<1, 32>>>(dio, dout, lay);
    cudaDeviceSynchronize();
    cudaMemcpy(out, dout, sizeof(out), cudaMemcpyDeviceToHost);
    cpu(io[lay], ref, lay < 2, lay == 1 || lay == 2);
    int ng = 0, nc = 0;
    for (int i = 0; i < 256; ++i) { uint32_t u; memcpy(&u, &out[i], 4); ng += u != gold[lay][i]; nc += out[i] != ref[i];
      if (u != gold[lay][i] && ng <= 3) printf("  %s lane %d d%d: got %g, GPU %g\n", names[lay], i / 8, i % 8, out[i], *(float *)&gold[lay][i]); }
    printf("m8n8k4.%s.f32.f16.f16.f32: %d of 256 differ from the A100 golden, %d from the CPU model\n", names[lay], ng, nc);
    bad += ng + nc;
  }
  if (bad) printf("FAILED\n"); else printf("PASSED\n");
  return bad != 0;
}
