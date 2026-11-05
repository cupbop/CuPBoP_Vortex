// lift_g32: cuBLAS sm80_xmma_gemm_f16f16_f16f32_f32_tn_n_tilesize32x32x64_stage6 (closed library, sm_80 lift): D = 1.5 A^T B + 0.5 C, A K x M ld K, B K x N ld K, C M x N ld M, f16 in and out.
// cp.async ring of 6 stages, ldmatrix, mma.sync. Params: params_tmpl.bin (captured block, pointer slots 0) + the size fields (experiments/closed_tcu/tools/mkcase.cpp). Inputs k / 64, |k| <= 32:
// every sum is exact in f32, so a correct run matches the CPU reference bit for bit in any summation order. CTA area 49152 B = @shared_mem 32768 + dyn_smem 16384 (0 after p2c-fold: LIFT_DYN_SMEM).
#include "../lift_host.h"
static const char *K0 = "sm80_xmma_gemm_f16f16_f16f32_f32_tn_n_tilesize32x32x64_stage6_warpsize2x2x1_tensor16x8x16_execute_kernel__5x_cublas";
int main(int argc, char **argv) {
  int M = 64, N = 96, K = 512; const float al = 1.5f, be = 0.5f;
  for (int i = 1; i + 1 < argc; i += 2) { std::string a = argv[i]; int v = atoi(argv[i + 1]); if (a == "-m") M = v; else if (a == "-n") N = v; else if (a == "-k") K = v; else { printf("FAIL: unknown argument %s\n", a.c_str()); return 1; } }
  if (K % 8 || K < 8) { printf("FAIL: K must be a positive multiple of 8\n"); return 1; }
  static uint8_t cb[LIFT_CBANK]; std::vector<uint8_t> tm = lift_file("params_tmpl.bin"); memcpy(cb + 0x160, tm.data(), tm.size());
  const int kt = (K + 63) / 64 - 1, gN = (N + 31) / 32, gM = (M + 31) / 32;
  const int zero[] = {0x160, 0x164, 0x168, 0x16c, 0x170, 0x174, 0x190, 0x194}, ks[] = {0x204, 0x208, 0x210, 0x230, 0x250}, ms[] = {0x218, 0x220, 0x260, 0x278, 0x394};
  for (int o : zero) lift_put<int>(cb, o, 0);
  lift_put<int>(cb, 0x1fc, N); lift_put<int>(cb, 0x200, M); for (int o : ks) lift_put<int>(cb, o, K); for (int o : ms) lift_put<int>(cb, o, M);
  lift_put<int>(cb, 0x2bc, kt); lift_put<int>(cb, 0x428, kt); lift_put<int>(cb, 0x430, kt * 64); lift_put<int>(cb, 0x3d8, gN); lift_put<int>(cb, 0x3e4, gN); lift_put<int>(cb, 0x3dc, gM); lift_put<int>(cb, 0x3e8, gM); lift_put<int>(cb, 0x410, K * 128); lift_put<int>(cb, 0x420, K * 128);
  std::vector<uint16_t> A((size_t)K * M), B((size_t)K * N), C((size_t)M * N), D((size_t)M * N);
  for (size_t i = 0; i < A.size(); ++i) A[i] = lift_f2h(lift_k64(i, 1));
  for (size_t i = 0; i < B.size(); ++i) B[i] = lift_f2h(lift_k64(i, 2));
  for (size_t i = 0; i < C.size(); ++i) C[i] = lift_f2h(lift_k64(i, 3));
  void *dA = lift_dev(A.data(), A.size() * 2), *dB = lift_dev(B.data(), B.size() * 2), *dC = lift_dev(C.data(), C.size() * 2);
  lift_put<void *>(cb, 0x160 + 8, dA); lift_put<void *>(cb, 0x160 + 0, dB); lift_put<void *>(cb, 0x160 + 16, dC); lift_put<void *>(cb, 0x160 + 48, dC);
  lift_launch(K0, dim3(gN, gM, 1), dim3(128), 16384, "352:736", cb);
  LIFT_CHECK(cudaMemcpy(D.data(), dC, D.size() * 2, cudaMemcpyDeviceToHost));
  long bad = 0;
  for (int j = 0; j < N; ++j) for (int i = 0; i < M; ++i) {
    double s = 0; for (int q = 0; q < K; ++q) s += (double)lift_h2f(A[q + (size_t)i * K]) * lift_h2f(B[q + (size_t)j * K]);
    const uint16_t e = lift_f2h((float)(al * s + be * lift_h2f(C[i + (size_t)j * M]))), g = D[i + (size_t)j * M];
    if (e != g) { if (bad < 5) printf("  D[%d,%d] = %04x, reference %04x\n", i, j, g, e); ++bad; }
  }
  printf("g32 M %d N %d K %d: %ld of %zu differ from the reference (bit compare)\n", M, N, K, bad, D.size());
  return lift_finish(bad);
}
