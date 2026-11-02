// CUPBOP_MMA_FUSE unit test (see mmafuse_kernel.cuh). golden_mmaf.txt holds, per data set, warp and lane, the 40
// input words and the 88 output words an NVIDIA A100 produced (experiments/mmafuse/unit/mmaf_gpu.cu).
//   set 0: small multiples of 1/8 and 1/16, every product and sum exact -> outputs must equal the GPU's bit for bit
//   set 1: random f16 in (-2, 2), random C -> max error vs a double reference, normalized by sum|a*b| + |c|,
//          for this run and the GPU (limit 1e-5); per-test hashes of the output bits compare fusion variants.
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <cuda_runtime.h>
#include "mmafuse_ref.h"
int main(int argc, char **argv) {
  FILE *g = fopen(argc > 1 ? argv[1] : "golden_mmaf.txt", "r");
  if (!g) { printf("FAILED: no golden_mmaf.txt\n"); return 1; }
  static uint32_t in[2][MMAF_LANES][MMAF_NIN], gold[2][MMAF_LANES][MMAF_NOUT], out[MMAF_LANES][MMAF_NOUT];
  for (int n = 0; n < 2 * MMAF_LANES; ++n) {
    int set, w, l;
    if (fscanf(g, "%d %d %d", &set, &w, &l) != 3 || set < 0 || set > 1 || w < 0 || w >= MMAF_WARPS || l < 0 || l > 31) { printf("FAILED: bad golden\n"); return 1; }
    for (int i = 0; i < MMAF_NIN; ++i) if (fscanf(g, "%x", &in[set][32 * w + l][i]) != 1) { printf("FAILED: bad golden\n"); return 1; }
    for (int i = 0; i < MMAF_NOUT; ++i) if (fscanf(g, "%x", &gold[set][32 * w + l][i]) != 1) { printf("FAILED: bad golden\n"); return 1; }
  }
  fclose(g);
  uint32_t *dio, *dout;
  cudaMalloc(&dio, sizeof(in[0])); cudaMalloc(&dout, sizeof(out));
  int bad = 0;
  for (int set = 0; set < 2; ++set) {
    const int flag = set == 0;
    cudaMemcpy(dio, in[set], sizeof(in[0]), cudaMemcpyHostToDevice);
    cudaMemset(dout, 0, sizeof(out));
    mmafuse_kernel<<<1, MMAF_LANES>>>(dio, dout, flag);
    cudaDeviceSynchronize();
    cudaMemcpy(out, dout, sizeof(out), cudaMemcpyDeviceToHost);
    int nbits = 0, nval = 0;
    double maxv[11] = {}, maxg[11] = {};
    uint64_t h[11];
    for (int i = 0; i < 11; ++i) h[i] = 1469598103934665603ull;
    for (int w = 0; w < MMAF_WARPS; ++w) {
      static double ref[32][MMAF_NOUT], mag[32][MMAF_NOUT];
      mmaf_ref_warp((const uint32_t (*)[MMAF_NIN])in[set][32 * w], flag, ref, mag);
      for (int l = 0; l < 32; ++l)
        for (int o = 0; o < 80; ++o) {
          const uint32_t u = out[32 * w + l][o], gu = gold[set][32 * w + l][o];
          float f, gf; memcpy(&f, &u, 4); memcpy(&gf, &gu, 4);
          const int ti = mmaf_test_index(o);
          h[ti] = (h[ti] ^ u) * 1099511628211ull;
          const double m = mag[l][o] > 0 ? mag[l][o] : 1.0;
          const double ev = std::fabs(f - ref[l][o]) / m, eg = std::fabs(gf - ref[l][o]) / m;
          if (!(ev <= maxv[ti])) maxv[ti] = ev;
          if (eg > maxg[ti]) maxg[ti] = eg;
          if (set == 0) {
            nbits += u != gu; nval += f != gf;
            if (f != gf && nval <= 5) printf("  set0 %s warp %d lane %d out %d: got %.9g (0x%08x), GPU %.9g (0x%08x)\n", mmaf_test_name(o), w, l, o, f, u, gf, gu);
          }
        }
    }
    if (set == 0) {
      printf("set 0 (exact): %d of %d words differ from the A100 golden in value, %d in bits\n", nval, MMAF_LANES * 80, nbits);
      bad += nval;
    }
    for (int i = 0; i < 10; ++i) {
      static const char *names[] = {"T1 n2k1", "T2 n1k2", "T3 n2k2", "T4 n2k4(k8)", "T5 n1k3(k8)+1", "T6 dep", "T7 branch", "T8 shfl", "T9 mid-use", "T10 bf16 n2k2"};
      printf("set %d %-14s hash %016llx  max err vortex %.3e  gpu %.3e\n", set, names[i], (unsigned long long)h[i], maxv[i], maxg[i]);
      if (!(maxv[i] <= 1e-5)) { printf("  set %d %s: error above 1e-5\n", set, names[i]); bad++; }
    }
  }
  if (bad) printf("FAILED\n"); else printf("PASSED\n");
  return bad != 0;
}
