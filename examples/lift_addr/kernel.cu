// lift_addr: the kernel of raw.ll.xz (written by hand in the form of the sm_5x lifts, see the head of that file): out[i] = base[i - shift] with base = in + shift, so out = in.
// The lower half of the threads use a negative 32-bit index. With LIFT_STRADDLE=1 the input lies across the 2^32 address.
#include "../lift_host.h"
static const char *K = "_Z9addr_unitPfS_i";
int main() {
  const int n = 1 << 16, shift = n / 2, block = 256; std::vector<float> in(n), out(n, -1.f);
  for (int i = 0; i < n; ++i) in[i] = lift_uni(i, 1);
  float *dI = (float *)lift_dev(in.data(), n * 4), *dO = (float *)lift_dev(out.data(), n * 4);
  static uint8_t cb[LIFT_CBANK];
  lift_put<float *>(cb, 320, dI + shift); lift_put<float *>(cb, 328, dO); lift_put<int>(cb, 336, shift);
  lift_launch(K, dim3(n / block), dim3(block), 0, "320:8 328:8 336:4", cb);
  LIFT_CHECK(cudaMemcpy(out.data(), dO, n * 4, cudaMemcpyDeviceToHost));
  long bad = 0;
  for (int i = 0; i < n; ++i) if (memcmp(&in[i], &out[i], 4)) { if (bad < 5) printf("  out[%d] = %g, want %g\n", i, out[i], in[i]); ++bad; }
  printf("addr unit: %ld of %d differ\n", bad, n);
  return lift_finish(bad);
}
