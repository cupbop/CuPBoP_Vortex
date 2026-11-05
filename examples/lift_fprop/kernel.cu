// lift_fprop: cuDNN sm80_xmma_fprop_implicit_gemm_f16f16_f16f32_f32_nhwckrsc_nhwc_tilesize64x32x64_stage5 (closed library, sm_80 lift): 1x1 convolution, NHWC, stride 1, pad 0, alpha 1, beta 0.
// cp.async ring of 5 stages, mma.sync, a 1488-byte parameter block read with a run-time index (the case of the variable index parameter forward). Params: params_tmpl.bin + the size fields
// (experiments/closed_tcu/tools/mkcase.cpp). Inputs k / 64: bit compare against the CPU reference. CTA area 61440 B = @shared_mem 32768 + dyn_smem 28672 (0 after p2c-fold: LIFT_DYN_SMEM).
#include "../lift_host.h"
static const char *K0 = "sm80_xmma_fprop_implicit_gemm_f16f16_f16f32_f32_nhwckrsc_nhwc_tilesize64x32x64_stage5_warpsize2x2x1_g1_tensor16x8x16_execute_kernel__5x_cudnn";
static void magic(int d, uint32_t &mul, uint32_t &sh) { int l = 0; while ((1ull << l) < (uint64_t)d) ++l; sh = l ? l - 1 : 0; if (d == 1) { mul = 0; sh = 0; return; } mul = (uint32_t)(((1ull << (32 + sh)) + d - 1) / d); }
int main(int argc, char **argv) {
  int N = 1, C = 512, H = 8, W = 8, K = 32;
  for (int i = 1; i + 1 < argc; i += 2) { std::string a = argv[i]; int v = atoi(argv[i + 1]); if (a == "-n") N = v; else if (a == "-c") C = v; else if (a == "-h") H = v; else if (a == "-w") W = v; else if (a == "-k") K = v; else { printf("FAIL: unknown argument %s\n", a.c_str()); return 1; } }
  if (C % 64 || K % 32) { printf("FAIL: C must be a multiple of 64, K of 32\n"); return 1; }
  const int P = H, Q = W, npq = N * P * Q, gM = (npq + 63) / 64, gK = (K + 31) / 32; uint32_t m, s;
  static uint8_t cb[LIFT_CBANK]; std::vector<uint8_t> tm = lift_file("params_tmpl.bin"); memcpy(cb + 0x160, tm.data(), tm.size());
  const int zero[] = {0x160, 0x164, 0x168, 0x16c, 0x170, 0x174, 0x178, 0x17c, 0x2a8, 0x2ac, 0x2b8, 0x2bc, 0x2c0, 0x2c4};
  for (int o : zero) lift_put<int>(cb, o, 0);
  lift_put<int>(cb, 0x198, N); lift_put<int>(cb, 0x1a0, H); lift_put<int>(cb, 0x1a4, W); lift_put<int>(cb, 0x1a8, C); lift_put<int>(cb, 0x1b0, P); lift_put<int>(cb, 0x1b4, Q); lift_put<int>(cb, 0x1b8, K);
  lift_put<int>(cb, 0x230, H * W * C); lift_put<int>(cb, 0x234, H * W * C); lift_put<int>(cb, 0x238, W * C); lift_put<int>(cb, 0x23c, C);
  lift_put<int>(cb, 0x244, P * Q * K); lift_put<int>(cb, 0x248, P * Q * K); lift_put<int>(cb, 0x24c, Q * K); lift_put<int>(cb, 0x250, K);
  lift_put<int>(cb, 0x340, gM); lift_put<int>(cb, 0x344, gK); lift_put<int>(cb, 0x34c, gK); lift_put<int>(cb, 0x350, gM);
  lift_put<int>(cb, 0x3b8, H * W * C); lift_put<int>(cb, 0x3bc, H * W * C); lift_put<int>(cb, 0x3c0, W * C); lift_put<int>(cb, 0x3c4, npq); lift_put<int>(cb, 0x3c8, P * Q); lift_put<int>(cb, 0x3cc, P * Q); lift_put<int>(cb, 0x3d0, C);
  magic(P * Q, m, s); lift_put<uint32_t>(cb, 0x3d8, m); lift_put<uint32_t>(cb, 0x3dc, s); lift_put<uint32_t>(cb, 0x3e0, m); lift_put<uint32_t>(cb, 0x3e4, s); magic(Q, m, s); lift_put<uint32_t>(cb, 0x3e8, m); lift_put<uint32_t>(cb, 0x3ec, s);
  lift_put<int>(cb, 0x630, C / 64 - 1); lift_put<int>(cb, 0x638, C - 64); lift_put<int>(cb, 0x6f0, K);
  std::vector<uint16_t> X((size_t)N * H * W * C), Wt((size_t)K * C), Y((size_t)npq * K, 0);
  for (size_t i = 0; i < X.size(); ++i) X[i] = lift_f2h(lift_k64(i, 1));
  for (size_t i = 0; i < Wt.size(); ++i) Wt[i] = lift_f2h(lift_k64(i, 2));
  std::vector<uint8_t> ws(4096, 0);
  void *dX = lift_dev(X.data(), X.size() * 2), *dW = lift_dev(Wt.data(), Wt.size() * 2), *dY = lift_dev(Y.data(), Y.size() * 2), *dS = lift_dev(ws.data(), ws.size());
  lift_put<void *>(cb, 0x160 + 0, dX); lift_put<void *>(cb, 0x160 + 8, dW); lift_put<void *>(cb, 0x160 + 16, dY); lift_put<void *>(cb, 0x160 + 24, dY);
  for (int o : {328, 344, 352}) lift_put<void *>(cb, 0x160 + o, dS);
  lift_launch(K0, dim3(gK, gM, 1), dim3(128), 28672, "352:1488", cb);
  LIFT_CHECK(cudaMemcpy(Y.data(), dY, Y.size() * 2, cudaMemcpyDeviceToHost));
  long bad = 0;
  for (int r = 0; r < npq; ++r) for (int k = 0; k < K; ++k) {
    double a = 0; for (int e = 0; e < C; ++e) a += (double)lift_h2f(X[(size_t)r * C + e]) * lift_h2f(Wt[(size_t)k * C + e]);
    const uint16_t e = lift_f2h((float)a), g = Y[(size_t)r * K + k];
    if (e != g) { if (bad < 5) printf("  Y[%d,%d] = %04x, reference %04x\n", r, k, g, e); ++bad; }
  }
  printf("fprop n %d c %d h %d w %d k %d: %ld of %zu differ from the reference (bit compare)\n", N, C, H, W, K, bad, Y.size());
  return lift_finish(bad);
}
