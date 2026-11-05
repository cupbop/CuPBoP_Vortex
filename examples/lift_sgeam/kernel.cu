// lift_sgeam: cuBLAS geam_kernel (closed library, sm_90 lift), C = 2.5 A + 1.5 B, column-major, any M x N. Parameters: cublasGeamParams at 0x210 (alpha, beta, m, n, lda, ldb, ldc),
// A, B, C at 0x238, 0x240, 0x248, two unused pointer slots. Kept as the regression of the s1 wrong answer with adce in front of the translator.
#include "../lift_host.h"
static const char *K = "_Z11geam_kernelIifLb0ELb0ELb0ELb0ELi6ELi5ELi3ELb1EEv16cublasGeamParamsIT_T0_EPKS2_S5_PS2_S5_S5_";
int main(int argc, char **argv) {
  const int M = argc > 1 ? atoi(argv[1]) : 100, N = argc > 2 ? atoi(argv[2]) : 70; const size_t n = (size_t)M * N;
  std::vector<float> a(n), b(n), c(n, -7.f);
  for (size_t i = 0; i < n; ++i) { a[i] = lift_uni(i, 1); b[i] = lift_uni(i, 2); }
  void *dA = lift_dev(a.data(), n * 4), *dB = lift_dev(b.data(), n * 4), *dC = lift_dev(c.data(), n * 4), *dS = lift_dev(nullptr, 64);
  static uint8_t cb[LIFT_CBANK];
  lift_put<float>(cb, 0x210, 2.5f); lift_put<float>(cb, 0x214, 1.5f); lift_put<int>(cb, 0x218, M); lift_put<int>(cb, 0x21c, N);
  for (int o = 0x220; o <= 0x228; o += 4) lift_put<int>(cb, o, M);
  lift_put<void *>(cb, 0x238, dA); lift_put<void *>(cb, 0x240, dB); lift_put<void *>(cb, 0x248, dC); lift_put<void *>(cb, 0x250, dS); lift_put<void *>(cb, 0x258, dS);
  lift_launch(K, dim3((M + 63) / 64, (N + 31) / 32, 1), dim3(256, 1, 1), 0, "528:36 568:8 576:8 584:8 592:8 600:8", cb);
  LIFT_CHECK(cudaMemcpy(c.data(), dC, n * 4, cudaMemcpyDeviceToHost));
  long bad = 0; double md = 0;
  for (size_t i = 0; i < n; ++i) { double e = 2.5 * a[i] + 1.5 * b[i], d = std::fabs(c[i] - e); if (d > md) md = d; if (!(d <= 1e-5 * (1 + std::fabs(e)))) ++bad; }
  printf("sgeam %d x %d: %ld of %zu bad, max |d| %g\n", M, N, bad, n, md);
  return lift_finish(bad);
}
