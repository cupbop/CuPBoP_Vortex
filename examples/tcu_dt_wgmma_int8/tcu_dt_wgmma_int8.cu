// tcu_dt_wgmma_int8.cu - Hopper wgmma.mma_async test for one input family (generated from
// experiments/dtype/tests/tcu_dt_wgmma.cu.in). One warpgroup (128 threads) per block computes a 64x64 tile
// D = C0 + A(64xK) B(Kx64); A and B^T are staged per k-step (8 words = 32 bytes of K per row) in shared memory
// in the canonical no-swizzle K-major core-matrix layout (8 rows x 16 bytes, LBO 128 B, SBO 256 B). Modes:
//   tf32: 0 m64n64k8 tf32
//   fp8 : 0 e4m3.e4m3, 1 e5m2.e5m2, 2 e4m3.e5m2, 3 e5m2.e4m3 (m64n64k32 -> f32)
//   int8: 0 s8.s8, 1 u8.u8, 2 satfinite s8.s8 (m64n64k32 -> s32; ptxas 12.1 rejects mixed s8.u8 wgmma)
//   ./host.out [-n N] [-r]  (N multiple of 64; K = N words per row)
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cuda_runtime.h>

#define FAM_int8 1
#if defined(FAM_int8)
typedef int acc_t;
#define NMODES 3
#define EPW 4
#elif defined(FAM_tf32)
typedef float acc_t;
#define NMODES 1
#define EPW 1
#else
typedef float acc_t;
#define NMODES 4
#define EPW 4
#endif
#define CUDA_CHECK(_e) do { cudaError_t _r = (_e); if (_r != cudaSuccess) { fprintf(stderr, "CUDA Error: %s -> %d\n", #_e, (int)_r); exit(-1); } } while (0)

__device__ __forceinline__ int core_word(int r, int w) { return (r >> 3) * 64 + (w >> 2) * 32 + (r & 7) * 4 + (w & 3); } // in words
__device__ __forceinline__ uint32_t smem_u32(const void *p) {
  uint32_t a;
  asm volatile("{ .reg .u64 t; cvta.to.shared.u64 t, %1; cvt.u32.u64 %0, t; }" : "=r"(a) : "l"(p));
  return a;
}
__device__ __forceinline__ uint64_t make_desc(const void *smem_ptr) {
  uint64_t d = (uint64_t)((smem_u32(smem_ptr) & 0x3FFFFu) >> 4);
  d |= (uint64_t)(128 >> 4) << 16;
  d |= (uint64_t)(256 >> 4) << 32;
  return d;
}
#define WG_OUT32(T) "+" T(d[0]), "+" T(d[1]), "+" T(d[2]), "+" T(d[3]), "+" T(d[4]), "+" T(d[5]), "+" T(d[6]), "+" T(d[7])
#define D8(c, o) c(d[o + 0]), c(d[o + 1]), c(d[o + 2]), c(d[o + 3]), c(d[o + 4]), c(d[o + 5]), c(d[o + 6]), c(d[o + 7])
#define DREGS "{%0, %1, %2, %3, %4, %5, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, %16, %17, %18, %19, %20, %21, %22, %23, %24, %25, %26, %27, %28, %29, %30, %31}"
#if defined(FAM_int8)
#define WGMMA(OPC) asm volatile("{\n.reg .pred p;\nsetp.ne.b32 p, %34, 0;\n" OPC " " DREGS ", %32, %33, p;\n}\n" \
    : "+r"(d[0]), "+r"(d[1]), "+r"(d[2]), "+r"(d[3]), "+r"(d[4]), "+r"(d[5]), "+r"(d[6]), "+r"(d[7]), "+r"(d[8]), "+r"(d[9]), "+r"(d[10]), "+r"(d[11]), "+r"(d[12]), "+r"(d[13]), "+r"(d[14]), "+r"(d[15]), \
      "+r"(d[16]), "+r"(d[17]), "+r"(d[18]), "+r"(d[19]), "+r"(d[20]), "+r"(d[21]), "+r"(d[22]), "+r"(d[23]), "+r"(d[24]), "+r"(d[25]), "+r"(d[26]), "+r"(d[27]), "+r"(d[28]), "+r"(d[29]), "+r"(d[30]), "+r"(d[31]) \
    : "l"(da), "l"(db), "r"(1))
#else
#define WGMMA(OPC) asm volatile("{\n.reg .pred p;\nsetp.ne.b32 p, %34, 0;\n" OPC " " DREGS ", %32, %33, p, 1, 1;\n}\n" \
    : "+f"(d[0]), "+f"(d[1]), "+f"(d[2]), "+f"(d[3]), "+f"(d[4]), "+f"(d[5]), "+f"(d[6]), "+f"(d[7]), "+f"(d[8]), "+f"(d[9]), "+f"(d[10]), "+f"(d[11]), "+f"(d[12]), "+f"(d[13]), "+f"(d[14]), "+f"(d[15]), \
      "+f"(d[16]), "+f"(d[17]), "+f"(d[18]), "+f"(d[19]), "+f"(d[20]), "+f"(d[21]), "+f"(d[22]), "+f"(d[23]), "+f"(d[24]), "+f"(d[25]), "+f"(d[26]), "+f"(d[27]), "+f"(d[28]), "+f"(d[29]), "+f"(d[30]), "+f"(d[31]) \
    : "l"(da), "l"(db), "r"(1))
#endif

__global__ void __launch_bounds__(128) tcu_dt_wgmma_kernel(const uint32_t *A, const uint32_t *Bt, const acc_t *C0, acc_t *D, int M, int N, int KW, int mode) {
  __shared__ __align__(128) uint32_t sA[64 * 8];
  __shared__ __align__(128) uint32_t sB[64 * 8];
  const int tile_m = blockIdx.y * 64, tile_n = blockIdx.x * 64, tid = threadIdx.x;
  const int warp = tid >> 5, lane = tid & 31, g = lane >> 2, t = lane & 3;
  const int row = tile_m + 16 * warp + g;
  acc_t d[32];
  for (int j = 0; j < 8; j++) {
    const int col = tile_n + 8 * j + 2 * t;
    d[4 * j + 0] = C0[row * N + col]; d[4 * j + 1] = C0[row * N + col + 1];
    d[4 * j + 2] = C0[(row + 8) * N + col]; d[4 * j + 3] = C0[(row + 8) * N + col + 1];
  }
  for (int kw0 = 0; kw0 < KW; kw0 += 8) {
    for (int i = tid; i < 64 * 8; i += 128) {
      const int r = i / 8, w = i % 8;
      sA[core_word(r, w)] = A[(tile_m + r) * KW + kw0 + w];
      sB[core_word(r, w)] = Bt[(tile_n + r) * KW + kw0 + w];
    }
    __syncthreads();
    asm volatile("fence.proxy.async.shared::cta;\n" ::: "memory");
    const uint64_t da = make_desc(sA), db = make_desc(sB);
    asm volatile("wgmma.fence.sync.aligned;\n" ::: "memory");
#if defined(FAM_tf32)
    (void)mode;
    WGMMA("wgmma.mma_async.sync.aligned.m64n64k8.f32.tf32.tf32");
#elif defined(FAM_int8)
    switch (mode) {
    case 0: WGMMA("wgmma.mma_async.sync.aligned.m64n64k32.s32.s8.s8"); break;
    case 1: WGMMA("wgmma.mma_async.sync.aligned.m64n64k32.s32.u8.u8"); break;
    default: WGMMA("wgmma.mma_async.sync.aligned.m64n64k32.satfinite.s32.s8.s8"); break;
    }
#else
    switch (mode) {
    case 0: WGMMA("wgmma.mma_async.sync.aligned.m64n64k32.f32.e4m3.e4m3"); break;
    case 1: WGMMA("wgmma.mma_async.sync.aligned.m64n64k32.f32.e5m2.e5m2"); break;
    case 2: WGMMA("wgmma.mma_async.sync.aligned.m64n64k32.f32.e4m3.e5m2"); break;
    default: WGMMA("wgmma.mma_async.sync.aligned.m64n64k32.f32.e5m2.e4m3"); break;
    }
#endif
    asm volatile("wgmma.commit_group.sync.aligned;\n" ::: "memory");
    asm volatile("wgmma.wait_group.sync.aligned 0;\n" ::: "memory");
    __syncthreads();
  }
  for (int j = 0; j < 8; j++) {
    const int col = tile_n + 8 * j + 2 * t;
    D[row * N + col] = d[4 * j + 0]; D[row * N + col + 1] = d[4 * j + 1];
    D[(row + 8) * N + col] = d[4 * j + 2]; D[(row + 8) * N + col + 1] = d[4 * j + 3];
  }
}

// ---- host (same element codecs as tcu_dt_mma) ---------------------------------------------------------
static double dec_e4m3(unsigned b) { int s = b >> 7, e = (b >> 3) & 15, m = b & 7; double v = e ? ldexp(1.0 + m / 8.0, e - 7) : ldexp(m / 8.0, -6); return s ? -v : v; }
static double dec_e5m2(unsigned b) { int s = b >> 7, e = (b >> 2) & 31, m = b & 3; double v = e ? ldexp(1.0 + m / 4.0, e - 15) : ldexp(m / 4.0, -14); return s ? -v : v; }
static void mode_fmt(int mode, int &fa, int &fb) {
#if defined(FAM_int8)
  static const int A_[3] = {0, 1, 0}, B_[3] = {0, 1, 0};
  fa = A_[mode]; fb = B_[mode];
#elif defined(FAM_fp8)
  static const int A_[4] = {0, 1, 0, 1}, B_[4] = {0, 1, 1, 0};
  fa = A_[mode]; fb = B_[mode];
#else
  (void)mode; fa = fb = 0;
#endif
}
static uint32_t rand_word(int fmt, int rnd) {
#if defined(FAM_tf32)
  (void)fmt;
  float f = rnd ? (float)rand() / RAND_MAX * 2.f - 1.f : (float)(rand() % 33 - 16) / 16.0f; uint32_t u; memcpy(&u, &f, 4); return u;
#else
  uint32_t w = 0;
  for (int i = 0; i < 4; i++) {
    unsigned b;
#if defined(FAM_int8)
    (void)rnd; (void)fmt; b = rand() & 0xff;
#else
    if (rnd) { do { b = rand() & 0xff; } while (fmt == 0 ? ((b & 0x7f) == 0x7f) : (((b >> 2) & 31) == 31)); }
    else { unsigned s = rand() & 1, m = fmt == 0 ? (rand() & 7) : (rand() & 3), e = fmt == 0 ? 5 + rand() % 5 : 13 + rand() % 5;
           b = (s << 7) | (fmt == 0 ? ((e << 3) | m) : ((e << 2) | m)); }
#endif
    w |= b << (8 * i);
  }
  return w;
#endif
}
static double elem(uint32_t w, int i, int fmt) {
#if defined(FAM_tf32)
  (void)i; (void)fmt; uint32_t u = w & 0xffffe000u; float f; memcpy(&f, &u, 4); return (double)f;
#elif defined(FAM_int8)
  unsigned b = (w >> (8 * i)) & 0xff; return fmt == 0 ? (double)(int)(signed char)b : (double)b;
#else
  unsigned b = (w >> (8 * i)) & 0xff; return fmt == 0 ? dec_e4m3(b) : dec_e5m2(b);
#endif
}

int main(int argc, char **argv) {
  int n = 64, rnd = 0;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "-n") && i + 1 < argc) n = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-r")) rnd = 1;
  }
  if (n % 64) { fprintf(stderr, "n must be a multiple of 64\n"); return -1; }
  const int M = n, N = n, KW = n / 4 < 8 ? 8 : n / 4; // words of K per row (16 for n=64)
  printf("tcu_dt_wgmma int8: M=N=%d K=%d random=%d\n", M, KW * EPW, rnd);
  uint32_t *hA = (uint32_t *)malloc(4 * M * KW), *hBt = (uint32_t *)malloc(4 * N * KW);
  acc_t *hC = (acc_t *)malloc(sizeof(acc_t) * M * N), *hD = (acc_t *)malloc(sizeof(acc_t) * M * N);
  uint32_t *dA, *dBt; acc_t *dC, *dD;
  CUDA_CHECK(cudaMalloc(&dA, 4 * M * KW)); CUDA_CHECK(cudaMalloc(&dBt, 4 * N * KW));
  CUDA_CHECK(cudaMalloc(&dC, sizeof(acc_t) * M * N)); CUDA_CHECK(cudaMalloc(&dD, sizeof(acc_t) * M * N));
  int errors = 0, total = 0;
  for (int mode = 0; mode < NMODES; mode++) {
    int fa, fb; mode_fmt(mode, fa, fb);
#if defined(FAM_int8)
    const bool sat = mode == 2;
#endif
    srand(91 + 17 * mode + n + rnd);
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
    dim3 grid(N / 64, M / 64), block(128, 1);
    tcu_dt_wgmma_kernel<<<grid, block>>>(dA, dBt, dC, dD, M, N, KW, mode);
    CUDA_CHECK(cudaDeviceSynchronize());
    CUDA_CHECK(cudaMemcpy(hD, dD, sizeof(acc_t) * M * N, cudaMemcpyDeviceToHost));
    int merr = 0; double maxerr = 0;
    for (int r = 0; r < M; r++)
      for (int c = 0; c < N; c++) {
        double ref, tol = 0; bool ok;
#if defined(FAM_int8)
        int64_t acc = hC[r * N + c];
        for (int kw0 = 0; kw0 < KW; kw0 += 8) { // one wgmma per 8-word k-step
          int64_t s = 0;
          for (int w = kw0; w < kw0 + 8; w++)
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
        if (rnd) tol = 2.0 * (KW * EPW + 2) * ldexp(1.0, -24) * mag;
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
