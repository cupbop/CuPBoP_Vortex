// lift_strsm: cuBLAS kernel_trsm_l_mul32<float, 8, false, false, false, false> (closed library, sm_90 lift): solve A X = alpha B, A m x m lower triangular, non-unit diagonal, column-major,
// X overwrites B. 32 IEEE divisions in the lifted code. Parameters: 0x210 m, 0x214 n, 0x218 device pointer (0), 0x220 A, 0x228 lda, 0x230 B, 0x238 ldb, 0x23c alpha, 0x240 flag (0). grid ceil(n / 8), block (32, 8).
#include "../lift_host.h"
#include "strsm_task.h"
static const char *K0 = "_Z19kernel_trsm_l_mul32IfLi8ELb0ELb0ELb0ELb0EEviiPKT_S2_iPS0_iS0_i";
int main(int argc, char **argv) {
  trsmt::Shape s{96, 20, 0, 0, 1, 1.5f};
  for (int i = 1; i + 1 < argc; i += 2) { std::string a = argv[i]; int v = atoi(argv[i + 1]);
    if (a == "-m") s.m = v; else if (a == "-n") s.n = v; else if (a == "-lda") s.lda = v; else if (a == "-ldb") s.ldb = v; else if (a == "-alpha") s.alpha = (float)atof(argv[i + 1]);
    else { printf("FAIL: unknown argument %s\n", a.c_str()); return 1; } }
  if (s.lda == 0) s.lda = s.m;
  if (s.ldb == 0) s.ldb = s.m;
  std::vector<float> A, B; std::vector<double> ref; trsmt::make_inputs(s, A, B); trsmt::reference(s, A, B, ref);
  void *dA = lift_dev(A.data(), s.na() * 4), *dB = lift_dev(B.data(), s.nb() * 4);
  static uint8_t cb[LIFT_CBANK];
  lift_put<int>(cb, 0x210, s.m); lift_put<int>(cb, 0x214, s.n); lift_put<void *>(cb, 0x220, dA); lift_put<int>(cb, 0x228, s.lda); lift_put<void *>(cb, 0x230, dB); lift_put<int>(cb, 0x238, s.ldb); lift_put<float>(cb, 0x23c, s.alpha);
  lift_launch(K0, dim3((s.n + 7) / 8, 1, 1), dim3(32, 8, 1), 0, "528:4 532:4 536:8 544:8 552:4 560:8 568:4 572:4 576:4", cb);
  std::vector<float> Ao(s.na()), Bo(s.nb());
  LIFT_CHECK(cudaMemcpy(Ao.data(), dA, s.na() * 4, cudaMemcpyDeviceToHost)); LIFT_CHECK(cudaMemcpy(Bo.data(), dB, s.nb() * 4, cudaMemcpyDeviceToHost));
  long bad = trsmt::check("vortex vs CPU reference (double)", s, Bo.data(), ref.data());
  bad += trsmt::untouched_a(Ao.data(), A.data(), s.na()); bad += trsmt::untouched_b(s, Bo.data(), B.data());
  return lift_finish(bad);
}
