// lift_hgemm: cutlass_80_tensorop_h16816gemm_64x64_64x3_nn_align8 (cuBLAS / CUTLASS GemmUniversal, sm_80 lift): C = 2.5 A B + 1.5 C, f16, column-major, M, N, K multiples of 64.
// cp.async ring of 3 stages, ldmatrix, mma.sync. grid (N / 64, M / 64), block 128. CTA area 49152 B = @shared_mem 32768 + dyn_smem 16384 (0 after p2c-fold: LIFT_DYN_SMEM).
#include "../lift_host.h"
#include "hg_params.h"
static const char *K0 = "_ZN7cutlass7Kernel2I51cutlass_80_tensorop_h16816gemm_64x64_64x3_nn_align8EEvNT_6ParamsE";
int main(int argc, char **argv) {
  int M = 128, N = 64, K = 320; const float alpha = 2.5f, beta = 1.5f;
  for (int i = 1; i + 1 < argc; i += 2) { std::string a = argv[i]; int v = atoi(argv[i + 1]); if (a == "-m") M = v; else if (a == "-n") N = v; else if (a == "-k") K = v; else { printf("FAIL: unknown argument %s\n", a.c_str()); return 1; } }
  std::vector<uint16_t> hA((size_t)M * K), hB((size_t)K * N), hC((size_t)M * N), out((size_t)M * N);
  for (size_t i = 0; i < hA.size(); ++i) hA[i] = lift_f2h(0.125f * lift_uni(i, 11));
  for (size_t i = 0; i < hB.size(); ++i) hB[i] = lift_f2h(0.125f * lift_uni(i, 12));
  for (size_t i = 0; i < hC.size(); ++i) hC[i] = lift_f2h(lift_uni(i, 13));
  void *dA = lift_dev(hA.data(), hA.size() * 2), *dB = lift_dev(hB.data(), hB.size() * 2), *dC = lift_dev(hC.data(), hC.size() * 2);
  static uint8_t cb[LIFT_CBANK];
  hgp::fill(cb + hgp::BASE, M, N, K, lift_f2h(alpha), lift_f2h(beta), dA, dB, dC);
  lift_launch(K0, dim3(N / 64, M / 64, 1), dim3(128), 16384, "352:368", cb);
  LIFT_CHECK(cudaMemcpy(out.data(), dC, out.size() * 2, cudaMemcpyDeviceToHost));
  long bad = 0; double maxe = 0;
  for (int j = 0; j < N; ++j) for (int i = 0; i < M; ++i) {
    double s = 0; for (int k = 0; k < K; ++k) s += (double)lift_h2f(hA[i + (size_t)k * M]) * lift_h2f(hB[k + (size_t)j * K]);
    double ref = alpha * s + beta * lift_h2f(hC[i + (size_t)j * M]), e = std::fabs(lift_h2f(out[i + (size_t)j * M]) - ref) / std::fmax(std::fabs(ref), 1.0);
    if (!(e <= 5e-3)) { if (bad < 5) printf("  C[%d,%d] = %g, reference %g\n", i, j, lift_h2f(out[i + (size_t)j * M]), ref); ++bad; }
    if (e > maxe) maxe = e;
  }
  printf("hgemm M %d N %d K %d: max |d| / max(|ref|, 1) %.3g, mismatches %ld (limit 5e-3)\n", M, N, K, maxe, bad);
  return lift_finish(bad);
}
