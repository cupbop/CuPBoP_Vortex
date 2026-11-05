// lift_sdot: cuBLAS sdot (closed library, sm_90 lift): dot_kernel (8 CTAs of 128 threads, partial sums in a workspace) then reduce_1Block_kernel. n = 1024, the captured launch.
// A reduction: the double reference has a loose tolerance, the bit record of ci/lift_test.sh is what sees a change of summation order.
#include "../lift_host.h"
static const char *K0 = "_Z10dot_kernelIfLi128ELi0E15cublasDotParamsI16cublasGemvTensorIKfE30cublasGemvTensorStridedBatchedIfEEEvT2_";
static const char *K1 = "_Z20reduce_1Block_kernelIfLi128ELi7E30cublasGemvTensorStridedBatchedIfE16cublasGemvTensorIfES3_EvPKT_S4_T2_iS6_S4_T3_T4_19cublasPointerMode_t18cublasLtEpilogue_tS0_IKN8biasTypeINS9_10value_typeES4_E4typeEE";
int main() {
  const int n = 1024; std::vector<float> x(n), y(n); double ref = 0, sabs = 0;
  for (int i = 0; i < n; ++i) { x[i] = lift_uni(i, 1); y[i] = lift_uni(i, 2); ref += (double)x[i] * y[i]; sabs += std::fabs((double)x[i] * y[i]); }
  void *dX = lift_dev(x.data(), n * 4), *dY = lift_dev(y.data(), n * 4); std::vector<uint8_t> z(1 << 12, 0); void *dW = lift_dev(z.data(), z.size()), *dR = lift_dev(z.data(), 64);
  static uint8_t cb[LIFT_CBANK];
  lift_put<void *>(cb, 0x210, dX); lift_put<void *>(cb, 0x218, dY); lift_put<void *>(cb, 0x220, dW); lift_put<int64_t>(cb, 0x228, 8); lift_put<int64_t>(cb, 0x230, n); lift_put<int64_t>(cb, 0x238, 1); lift_put<int64_t>(cb, 0x240, 1);
  lift_launch(K0, dim3(8), dim3(128), 0, "528:56", cb);
  memset(cb, 0, sizeof cb);
  lift_put<float>(cb, 0x218, 1.0f); lift_put<void *>(cb, 0x220, dW); lift_put<int64_t>(cb, 0x228, 8); lift_put<int64_t>(cb, 0x230, 8); lift_put<void *>(cb, 0x248, dR); lift_put<void *>(cb, 0x250, dR); lift_put<int>(cb, 0x25c, 1);
  lift_launch(K1, dim3(1), dim3(128), 0, "528:8 536:4 544:16 560:4 568:8 576:4 584:8 592:8 600:4 604:4 608:16", cb);
  float r = 0, part[8]; LIFT_CHECK(cudaMemcpy(part, dW, sizeof part, cudaMemcpyDeviceToHost)); LIFT_CHECK(cudaMemcpy(&r, dR, 4, cudaMemcpyDeviceToHost));   // the partial sums go into the bit record too: one float hides most of a rounding change
  double d = std::fabs(r - ref), tol = 1e-6 * sabs;
  printf("sdot n %d: %.9g, reference %.9g, |d| %.3g (limit %.3g)\n", n, r, ref, d, tol);
  return lift_finish(d <= tol ? 0 : 1);
}
