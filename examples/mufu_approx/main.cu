// mufu_approx: every llvm.nvvm.*.approx*.f form CUPBOP_MUFU lowers, over special values and random inputs laid out so
// that the lanes of a warp take different paths (normal next to subnormal next to NaN), checked against a double
// reference on the host. Results feed a divergent branch too (BRANCH): the asm output must count as divergent.
// No argument: the accuracy of any lowering, switch 0 included; the libm path does not flush, so the inputs and results
// where .ftz matters are skipped. -m (run with CUPBOP_MUFU=1 on a -DVX_CFG_EXT_MUFU_ENABLE build): the MUFU contract, with
// the PTX .ftz flushing and special-value table.
#include <cfloat>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cuda_runtime.h>

enum { EX2_FTZ, EX2, LG2_FTZ, LG2, RCP_FTZ, RSQRT_FTZ, RSQRT, NFN, BRANCH = NFN, NOUT };
static const char *NAME[NOUT] = {"ex2.ftz", "ex2", "lg2.ftz", "lg2", "rcp.ftz", "rsqrt.ftz", "rsqrt", "branch"};
#define BLOCK 256

__global__ void approx_kernel(const float *x, float *o, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i >= n) return;
  float v = x[i];
  o[EX2_FTZ * n + i] = __nvvm_ex2_approx_ftz_f(v);
  o[EX2 * n + i] = __nvvm_ex2_approx_f(v);
  o[LG2_FTZ * n + i] = __nvvm_lg2_approx_ftz_f(v);
  o[LG2 * n + i] = __nvvm_lg2_approx_f(v);
  o[RCP_FTZ * n + i] = __nvvm_rcp_approx_ftz_f(v);
  o[RSQRT_FTZ * n + i] = __nvvm_rsqrt_approx_ftz_f(v);
  o[RSQRT * n + i] = __nvvm_rsqrt_approx_f(v);
  if (__nvvm_ex2_approx_ftz_f(v) > 1.0f) o[BRANCH * n + i] = 1.0f;
  else o[BRANCH * n + i] = 2.0f;
}

static uint32_t bits(float f) { uint32_t u; memcpy(&u, &f, 4); return u; }
static float flt(uint32_t u) { float f; memcpy(&f, &u, 4); return f; }
static bool sub(float x) { return x != 0 && fabsf(x) < FLT_MIN; }
static bool ftz(int fn) { return fn == EX2_FTZ || fn == LG2_FTZ || fn == RCP_FTZ || fn == RSQRT_FTZ; }

// true when got is an acceptable value of fn(x)
static bool check(int fn, float x, float got, bool mufu) {
  bool ftz_ = ftz(fn);
  if (ftz_ && !mufu && sub(x)) return true; // old path: no flush of the input
  double xd = (ftz_ && sub(x)) ? copysign(0.0, x) : x, e;
  switch (fn) {
  case EX2_FTZ: case EX2: e = exp2(xd); break;
  case LG2_FTZ: case LG2: e = log2(xd); break;
  case RCP_FTZ: e = 1.0 / xd; break;
  default: e = 1.0 / sqrt(xd); break;
  }
  if (std::isnan(e)) return std::isnan(got);
  if (std::isnan(got)) return false;
  if (std::isinf(e)) return std::isinf(got) && std::signbit(e) == std::signbit(got);
  double ae = fabs(e);
  // tolerance: MUFU ex2 / rcp / rsqrt are good to about 2^-22 relative, lg2 to about 2^-21 absolute near 1
  double tol = ae * ldexp(1.0, -20) + ((fn == LG2_FTZ || fn == LG2) ? ldexp(1.0, -20) : 0.0);
  if (ae >= (double)FLT_MAX * (1 - ldexp(1.0, -19))) return std::isinf(got) || fabs(got - e) <= tol; // at the overflow edge
  if (ae < FLT_MIN * (1 + ldexp(1.0, -19))) { // subnormal result, or at its edge
    if (ftz_) {
      if (!mufu) return true;                                                 // old path: no flush
      if (ae < FLT_MIN * (1 - ldexp(1.0, -19))) return got == 0 && std::signbit(got) == std::signbit(e);
      return got == 0 || fabs(got - e) <= tol;
    }
    return fabs(got - e) <= tol + ldexp(1.0, -149);
  }
  return fabs(got - e) <= tol;
}

int main(int argc, char **argv) {
  bool mufu = argc > 1 && !strcmp(argv[1], "-m");
  const float S[] = {0.0f, -0.0f, INFINITY, -INFINITY, NAN, flt(1), flt(0x80000001), flt(0x00400000), flt(0x80400000), flt(0x007fffff), flt(0x807fffff),
                     FLT_MIN, -FLT_MIN, FLT_MAX, -FLT_MAX, 1, -1, 0.5f, -0.5f, 2, -2, 1e-30f, 1e30f, -1e30f, 126, -126, 127, -127, 128, -128, 126.5f, -126.5f,
                     127.99f, -127.99f, -130.1f, -140, -149, -149.5f, -150, -151, -200, 1.0000001f, 0.99999994f, flt(0x7e800000), flt(0x7f000000), flt(0xfe800000)};
  const int ns = sizeof(S) / sizeof(S[0]), n = 4096;
  static float x[n], o[NOUT * n];
  uint32_t r = 12345;
  for (int i = 0; i < n; i++) { // a special every few lanes, the rest random: uniform exponents-of-two range, then raw bit patterns
    r = r * 1664525u + 1013904223u;
    if (i % 5 == 0) x[i] = S[(i / 5) % ns];
    else if (i % 5 < 3) x[i] = ((r >> 8) / 16777216.0f - 0.5f) * 320.0f;
    else { uint32_t b = r; if ((b & 0x7f800000) == 0x7f800000) b &= 0xbfffffff; x[i] = flt(b); }
  }
  float *dx, *dO;
  cudaMalloc(&dx, sizeof x); cudaMalloc(&dO, sizeof o);
  cudaMemcpy(dx, x, sizeof x, cudaMemcpyHostToDevice);
  approx_kernel<<<n / BLOCK, BLOCK>>>(dx, dO, n);
  cudaMemcpy(o, dO, sizeof o, cudaMemcpyDeviceToHost);
  int bad = 0;
  for (int fn = 0; fn < NFN; fn++) {
    int nb = 0;
    for (int i = 0; i < n; i++)
      if (!check(fn, x[i], o[fn * n + i], mufu) && nb++ < 8)
        printf("FAIL %s(%a = 0x%08x) = %a (0x%08x)\n", NAME[fn], x[i], bits(x[i]), o[fn * n + i], bits(o[fn * n + i]));
    printf("%s: %d/%d bad\n", NAME[fn], nb, n);
    bad += nb;
  }
  int nb = 0;
  for (int i = 0; i < n; i++) { // the same condition on the host, from the value the kernel computed
    float want = o[EX2_FTZ * n + i] > 1.0f ? 1.0f : 2.0f;
    if (o[BRANCH * n + i] != want && nb++ < 8) printf("FAIL branch lane %d: x %a got %g want %g\n", i, x[i], o[BRANCH * n + i], want);
  }
  printf("%s: %d/%d bad\n", NAME[BRANCH], nb, n);
  bad += nb;
  printf(bad ? "FAILED %d\n" : "PASSED\n", bad);
  return bad != 0;
}
