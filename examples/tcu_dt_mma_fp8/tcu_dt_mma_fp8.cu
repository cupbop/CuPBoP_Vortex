// tcu_dt_mma_fp8.cu - PTX mma.sync (inline asm, PTX fragment layouts) test (generated from
// experiments/dtype/tests/tcu_dt_mma.cu.in). One warp per block computes a 16x8 tile D = C0 + A(16xK) B(Kx8),
// A row-major and B column-major as packed 32-bit words (low bits = lower k). Every mode of the family runs in
// turn (one launch each):
//   tf32: 0 m16n8k8 (accumulator tied "+f"), 1 m16n8k4
//   int8: 0 k32 s8.s8, 1 k16 s8.s8, 2 k32 u8.u8, 3 k16 u8.u8, 4 k32 s8.u8, 5 k32 u8.s8, 6 k32 satfinite s8.s8,
//         7 k16 satfinite u8.u8, 8 k16 s8.u8
//   fp8 : 0 k32 e4m3.e4m3, 1 k32 e5m2.e5m2, 2 k32 e4m3.e5m2, 3 k32 e5m2.e4m3
//   ./host.out [-n N] [-r]   -r: random data over the full finite range (float: tolerance from the fp32 sum bound)
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cuda_runtime.h>

#define FAM_fp8 1
#if defined(FAM_int8)
typedef int acc_t;
#define NMODES 9
#elif defined(FAM_tf32) && defined(TF32_K8_ONLY) // lifted path: CuLifter has no HMMA.1684 (m16n8k4)
typedef float acc_t;
#define NMODES 1
#elif defined(FAM_tf32)
typedef float acc_t;
#define NMODES 2
#else
typedef float acc_t;
#define NMODES 4
#endif
#define CUDA_CHECK(_e) do { cudaError_t _r = (_e); if (_r != cudaSuccess) { fprintf(stderr, "CUDA Error: %s -> %d\n", #_e, (int)_r); exit(-1); } } while (0)

// K-words per mma: 8 (full shapes) or 4 (half shapes)
__host__ __device__ static inline int mode_kw(int mode) {
#if defined(FAM_int8)
  return (mode == 1 || mode == 3 || mode == 7 || mode == 8) ? 4 : 8;
#elif defined(FAM_tf32)
  return mode == 1 ? 4 : 8;
#else
  return 8;
#endif
}

__global__ void tcu_dt_mma_kernel(const uint32_t *A, const uint32_t *Bt, const acc_t *C0, acc_t *D, int M, int N, int KW, int mode) {
  const int lane = threadIdx.x, g = lane >> 2, t = lane & 3;
  const int row0 = blockIdx.y * 16, col0 = blockIdx.x * 8;
  acc_t c0 = C0[(row0 + g) * N + col0 + 2 * t], c1 = C0[(row0 + g) * N + col0 + 2 * t + 1];
  acc_t c2 = C0[(row0 + g + 8) * N + col0 + 2 * t], c3 = C0[(row0 + g + 8) * N + col0 + 2 * t + 1];
  const int step = mode_kw(mode);
  for (int kw = 0; kw < KW; kw += step) {
    const uint32_t a0 = A[(row0 + g) * KW + kw + t], a1 = A[(row0 + g + 8) * KW + kw + t];
    const uint32_t b0 = Bt[(col0 + g) * KW + kw + t];
    uint32_t a2 = 0, a3 = 0, b1 = 0;
    if (step == 8) { a2 = A[(row0 + g) * KW + kw + 4 + t]; a3 = A[(row0 + g + 8) * KW + kw + 4 + t]; b1 = Bt[(col0 + g) * KW + kw + 4 + t]; }
#if defined(FAM_tf32)
#if !defined(TF32_K8_ONLY)
    if (mode == 0)
#endif
    {
      asm volatile("mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 {%0,%1,%2,%3}, {%4,%5,%6,%7}, {%8,%9}, {%0,%1,%2,%3};\n"
                   : "+f"(c0), "+f"(c1), "+f"(c2), "+f"(c3) : "r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1));
    }
#if !defined(TF32_K8_ONLY)
    else {
      float d0, d1, d2, d3;
      asm volatile("mma.sync.aligned.m16n8k4.row.col.f32.tf32.tf32.f32 {%0,%1,%2,%3}, {%4,%5}, {%6}, {%7,%8,%9,%10};\n"
                   : "=f"(d0), "=f"(d1), "=f"(d2), "=f"(d3) : "r"(a0), "r"(a1), "r"(b0), "f"(c0), "f"(c1), "f"(c2), "f"(c3));
      c0 = d0; c1 = d1; c2 = d2; c3 = d3;
    }
#endif
#elif defined(FAM_int8)
    int d0, d1, d2, d3;
#define MMA_I8_FULL(OPC) asm volatile(OPC " {%0,%1,%2,%3}, {%4,%5,%6,%7}, {%8,%9}, {%10,%11,%12,%13};\n" \
        : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3) : "r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(c0), "r"(c1), "r"(c2), "r"(c3))
#define MMA_I8_HALF(OPC) asm volatile(OPC " {%0,%1,%2,%3}, {%4,%5}, {%6}, {%7,%8,%9,%10};\n" \
        : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3) : "r"(a0), "r"(a1), "r"(b0), "r"(c0), "r"(c1), "r"(c2), "r"(c3))
    switch (mode) {
    case 0: MMA_I8_FULL("mma.sync.aligned.m16n8k32.row.col.s32.s8.s8.s32"); break;
    case 1: MMA_I8_HALF("mma.sync.aligned.m16n8k16.row.col.s32.s8.s8.s32"); break;
    case 2: MMA_I8_FULL("mma.sync.aligned.m16n8k32.row.col.s32.u8.u8.s32"); break;
    case 3: MMA_I8_HALF("mma.sync.aligned.m16n8k16.row.col.s32.u8.u8.s32"); break;
    case 4: MMA_I8_FULL("mma.sync.aligned.m16n8k32.row.col.s32.s8.u8.s32"); break;
    case 5: MMA_I8_FULL("mma.sync.aligned.m16n8k32.row.col.s32.u8.s8.s32"); break;
    case 6: MMA_I8_FULL("mma.sync.aligned.m16n8k32.row.col.satfinite.s32.s8.s8.s32"); break;
    case 7: MMA_I8_HALF("mma.sync.aligned.m16n8k16.row.col.satfinite.s32.u8.u8.s32"); break;
    default: MMA_I8_HALF("mma.sync.aligned.m16n8k16.row.col.s32.s8.u8.s32"); break;
    }
    c0 = d0; c1 = d1; c2 = d2; c3 = d3;
#else
    float d0, d1, d2, d3;
#define MMA_F8(OPC) asm volatile(OPC " {%0,%1,%2,%3}, {%4,%5,%6,%7}, {%8,%9}, {%10,%11,%12,%13};\n" \
        : "=f"(d0), "=f"(d1), "=f"(d2), "=f"(d3) : "r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "f"(c0), "f"(c1), "f"(c2), "f"(c3))
    switch (mode) {
    case 0: MMA_F8("mma.sync.aligned.m16n8k32.row.col.f32.e4m3.e4m3.f32"); break;
    case 1: MMA_F8("mma.sync.aligned.m16n8k32.row.col.f32.e5m2.e5m2.f32"); break;
    case 2: MMA_F8("mma.sync.aligned.m16n8k32.row.col.f32.e4m3.e5m2.f32"); break;
    default: MMA_F8("mma.sync.aligned.m16n8k32.row.col.f32.e5m2.e4m3.f32"); break;
    }
    c0 = d0; c1 = d1; c2 = d2; c3 = d3;
#endif
  }
  D[(row0 + g) * N + col0 + 2 * t] = c0; D[(row0 + g) * N + col0 + 2 * t + 1] = c1;
  D[(row0 + g + 8) * N + col0 + 2 * t] = c2; D[(row0 + g + 8) * N + col0 + 2 * t + 1] = c3;
}

// ---- host: element codecs (independent of the device runtime) ----------------------------------------
static double dec_e4m3(unsigned b) { int s = b >> 7, e = (b >> 3) & 15, m = b & 7; double v = e ? ldexp(1.0 + m / 8.0, e - 7) : ldexp(m / 8.0, -6); return s ? -v : v; }
static double dec_e5m2(unsigned b) { int s = b >> 7, e = (b >> 2) & 31, m = b & 3; double v = e ? ldexp(1.0 + m / 4.0, e - 15) : ldexp(m / 4.0, -14); return s ? -v : v; }
static float u2f(uint32_t u) { float f; memcpy(&f, &u, 4); return f; }
// operand signedness / format per mode: 0 = signed/e4m3, 1 = unsigned/e5m2
static void mode_fmt(int mode, int &fa, int &fb) {
#if defined(FAM_int8)
  static const int A_[9] = {0, 0, 1, 1, 0, 1, 0, 1, 0}, B_[9] = {0, 0, 1, 1, 1, 0, 0, 1, 1};
  fa = A_[mode]; fb = B_[mode];
#elif defined(FAM_fp8)
  static const int A_[4] = {0, 1, 0, 1}, B_[4] = {0, 1, 1, 0};
  fa = A_[mode]; fb = B_[mode];
#else
  (void)mode; fa = fb = 0;
#endif
}
static bool mode_sat(int mode) {
#if defined(FAM_int8)
  return mode == 6 || mode == 7;
#else
  (void)mode; return false;
#endif
}
static uint32_t rand_word(int fmt, int rnd) {
#if defined(FAM_tf32)
  (void)fmt;
  if (!rnd) { float f = (float)(rand() % 33 - 16) / 16.0f; uint32_t u; memcpy(&u, &f, 4); return u; }
  float f = (float)rand() / RAND_MAX * 2.f - 1.f; uint32_t u; memcpy(&u, &f, 4); return u; // low 13 bits set: truncated by the TCU
#else
  uint32_t w = 0;
  for (int i = 0; i < 4; i++) {
    unsigned b;
#if defined(FAM_int8)
    (void)rnd; (void)fmt; b = rand() & 0xff;
#else
    if (rnd) { // any finite value
      do { b = rand() & 0xff; } while (fmt == 0 ? ((b & 0x7f) == 0x7f) : (((b >> 2) & 31) == 31));
    } else { // exponents in a narrow band: every partial sum exact in fp32
      unsigned s = rand() & 1, m = fmt == 0 ? (rand() & 7) : (rand() & 3);
      unsigned e = fmt == 0 ? 5 + rand() % 5 : 13 + rand() % 5;
      b = (s << 7) | (fmt == 0 ? ((e << 3) | m) : ((e << 2) | m));
    }
#endif
    w |= b << (8 * i);
  }
  return w;
#endif
}
static double elem(uint32_t w, int i, int fmt) {
#if defined(FAM_tf32)
  (void)i; (void)fmt; return (double)u2f(w & 0xffffe000u); // the tensor core uses the top 19 bits
#elif defined(FAM_int8)
  unsigned b = (w >> (8 * i)) & 0xff; return fmt == 0 ? (double)(int)(signed char)b : (double)b;
#else
  unsigned b = (w >> (8 * i)) & 0xff; return fmt == 0 ? dec_e4m3(b) : dec_e5m2(b);
#endif
}
#if defined(FAM_tf32)
#define EPW 1
#else
#define EPW 4
#endif

int main(int argc, char **argv) {
  int n = 32, rnd = 0;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "-n") && i + 1 < argc) n = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-r")) rnd = 1;
  }
  if (n % 32) { fprintf(stderr, "n must be a multiple of 32\n"); return -1; }
  const int M = n, N = n, K = n * (EPW == 1 ? 1 : 2); // K elements; KW words per row
  const int KW = K / EPW;
  printf("tcu_dt_mma fp8: M=N=%d K=%d random=%d\n", M, K, rnd);
  uint32_t *hA = (uint32_t *)malloc(4 * M * KW), *hBt = (uint32_t *)malloc(4 * N * KW);
  acc_t *hC = (acc_t *)malloc(sizeof(acc_t) * M * N), *hD = (acc_t *)malloc(sizeof(acc_t) * M * N);
  uint32_t *dA, *dBt; acc_t *dC, *dD;
  CUDA_CHECK(cudaMalloc(&dA, 4 * M * KW)); CUDA_CHECK(cudaMalloc(&dBt, 4 * N * KW));
  CUDA_CHECK(cudaMalloc(&dC, sizeof(acc_t) * M * N)); CUDA_CHECK(cudaMalloc(&dD, sizeof(acc_t) * M * N));
  int errors = 0, total = 0;
  for (int mode = 0; mode < NMODES; mode++) {
    int fa, fb; mode_fmt(mode, fa, fb);
    const bool sat = mode_sat(mode);
    srand(77 + 31 * mode + n + rnd);
    for (int i = 0; i < M * KW; i++) hA[i] = rand_word(fa, rnd);
    for (int i = 0; i < N * KW; i++) hBt[i] = rand_word(fb, rnd);
    for (int i = 0; i < M * N; i++) {
#if defined(FAM_int8)
      hC[i] = sat ? (acc_t)((i & 1) ? 2147483647 - (rand() % 1000000) : -2147483647 - 1 + (rand() % 1000000)) : (acc_t)(rand() % 2000001 - 1000000);
#else
      hC[i] = rnd ? (float)rand() / RAND_MAX * 2.f - 1.f : (float)(rand() % 9 - 4) / 4.0f;
#endif
    }
    CUDA_CHECK(cudaMemcpy(dA, hA, 4 * M * KW, cudaMemcpyHostToDevice)); CUDA_CHECK(cudaMemcpy(dBt, hBt, 4 * N * KW, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(dC, hC, sizeof(acc_t) * M * N, cudaMemcpyHostToDevice)); CUDA_CHECK(cudaMemset(dD, 0, sizeof(acc_t) * M * N));
    dim3 grid(N / 8, M / 16), block(32, 1);
    tcu_dt_mma_kernel<<<grid, block>>>(dA, dBt, dC, dD, M, N, KW, mode);
    CUDA_CHECK(cudaDeviceSynchronize());
    CUDA_CHECK(cudaMemcpy(hD, dD, sizeof(acc_t) * M * N, cudaMemcpyDeviceToHost));
    int merr = 0; double maxerr = 0;
    const int step = mode_kw(mode);
    for (int r = 0; r < M; r++)
      for (int c = 0; c < N; c++) {
        double ref, tol = 0; bool ok;
#if defined(FAM_int8)
        int64_t acc = hC[r * N + c];
        for (int kw0 = 0; kw0 < KW; kw0 += step) { // one mma per step: D = sat?(A_step B_step + C)
          int64_t s = 0;
          for (int w = kw0; w < kw0 + step; w++)
            for (int i = 0; i < 4; i++) s += (int64_t)elem(hA[r * KW + w], i, fa) * (int64_t)elem(hBt[c * KW + w], i, fb);
          acc += s;
          if (sat) acc = acc > 2147483647LL ? 2147483647LL : (acc < -2147483648LL ? -2147483648LL : acc);
          else acc = (int64_t)(int32_t)(uint32_t)(uint64_t)acc;
        }
        ref = (double)acc; ok = hD[r * N + c] == (acc_t)acc;
#else
        double s = hC[r * N + c], mag = fabs(s);
        for (int w = 0; w < KW; w++)
          for (int i = 0; i < EPW; i++) { double p = elem(hA[r * KW + w], i, fa) * elem(hBt[c * KW + w], i, fb); s += p; mag += fabs(p); }
        ref = s;
        if (rnd) tol = 2.0 * (K + 2) * ldexp(1.0, -24) * mag; // |fl(sum)-sum| <= (n-1) u sum|x|, any order; x2 margin
        ok = fabs((double)hD[r * N + c] - ref) <= tol;
        if (fabs((double)hD[r * N + c] - ref) > maxerr) maxerr = fabs((double)hD[r * N + c] - ref);
#endif
        total++;
        if (!ok) { if (merr < 5) printf("Mismatch mode %d [%d,%d]: got %.9g, expected %.9g (tol %.3g)\n", mode, r, c, (double)hD[r * N + c], ref, tol); merr++; }
      }
    printf("mode %d: %s (%d errors, max |err| %.3g)\n", mode, merr ? "FAIL" : "ok", merr, maxerr);
    errors += merr;
  }
  printf("%s: %d/%d\n", errors ? "FAILED!" : "PASSED!", total - errors, total);
  return errors ? 1 : 0;
}
