// cublas_test.cu: a CUDA program that calls cuBLAS next to a kernel of its own. The same source builds with nvcc against
// NVIDIA's cuBLAS (the golden run on a GPU) and through CuPBoP against libvxblas on Vortex.
//   cublas_test [-o values.txt]
// Prints one line per call (status, max error against a CPU fp64 reference in units of its error bound, PASS/FAIL) and
// writes every result element to values.txt ("<case> <index> <value>"), for compare_golden.py to set the two runs side by side.
#include <cuda_runtime.h>
#include <cublas_v2.h>

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#define CHECK_CUDA(x)                                                                    \
  do {                                                                                   \
    cudaError_t e_ = (x);                                                                \
    if (e_ != cudaSuccess) {                                                             \
      fprintf(stderr, "CUDA error %d at %s:%d\n", (int)e_, __FILE__, __LINE__);          \
      exit(2);                                                                           \
    }                                                                                    \
  } while (0)

// The program's own kernel, on the same buffers as the library calls: x[i] = scale * x[i] + shift
__global__ void affine(float* x, int n, float scale, float shift) {
  const int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) x[i] = scale * x[i] + shift;
}

static uint32_t g_seed = 12345u;
static float frand() {  // deterministic on every platform
  g_seed = g_seed * 1664525u + 1013904223u;
  return (float)((g_seed >> 8) & 0xffff) / 32768.0f - 1.0f;
}

static uint32_t as_u(float f) { uint32_t u; memcpy(&u, &f, 4); return u; }
static float as_f(uint32_t u) { float f; memcpy(&f, &u, 4); return f; }
static uint16_t f2b(float x) { const uint32_t f = as_u(x); return (uint16_t)((f + 0x7fffu + ((f >> 16) & 1u)) >> 16); }
static float b2f(uint16_t b) { return as_f((uint32_t)b << 16); }
static float h2f(uint16_t h) {
  const uint32_t s = (h & 0x8000u) << 16, e = (h >> 10) & 0x1f, m = h & 0x3ff;
  if (e == 0) return (s ? -1.0f : 1.0f) * ldexpf((float)m, -24);
  if (e == 31) return as_f(s | 0x7f800000u | (m << 13));
  return as_f(s | ((e + 112) << 23) | (m << 13));
}
static uint16_t f2h(float x) {  // round to nearest even (inputs here are small normal numbers)
  const uint32_t f = as_u(x), s = (f >> 16) & 0x8000u, a = f & 0x7fffffffu;
  if (a < 0x38800000u) return (uint16_t)(s | (uint32_t)nearbyintf(as_f(a) * 16777216.0f));
  return (uint16_t)(s | ((a + ((15u - 127u) << 23) + 0xfffu + ((a >> 13) & 1u)) >> 13));
}

static FILE* g_out = nullptr;
static int g_fail = 0;

// Compare got (n x m column-major in ld) with ref, bound per element; dump the values.
static void verdict(const char* name, cublasStatus_t st, const std::vector<float>& got, const std::vector<double>& ref,
                    const std::vector<double>& mag, int k, double out_ulp) {
  double worst = 0.0;
  bool finite = true;
  for (size_t i = 0; i < ref.size(); ++i) {
    if (!std::isfinite(got[i])) finite = false;
    const double bound = 4.0 * (k + 2) * ldexp(1.0, -24) * mag[i] + out_ulp * fabs(ref[i]) + 1e-30;
    worst = fmax(worst, fabs(got[i] - ref[i]) / bound);
    fprintf(g_out, "%s %zu %.9g\n", name, i, got[i]);
  }
  const bool ok = st == CUBLAS_STATUS_SUCCESS && finite && worst <= 1.0;
  if (!ok) ++g_fail;
  printf("%-28s status=%d err/bound=%.3g %s\n", name, (int)st, worst, ok ? "PASS" : "FAIL");
}

template <typename T>
static T* to_dev(const std::vector<T>& h) {
  T* d = nullptr;
  CHECK_CUDA(cudaMalloc((void**)&d, h.size() * sizeof(T)));
  CHECK_CUDA(cudaMemcpy(d, h.data(), h.size() * sizeof(T), cudaMemcpyHostToDevice));
  return d;
}
template <typename T>
static std::vector<T> to_host(const T* d, size_t n) {
  std::vector<T> h(n);
  CHECK_CUDA(cudaMemcpy(h.data(), d, n * sizeof(T), cudaMemcpyDeviceToHost));
  return h;
}

// op(X)(i, j), X column-major with leading dimension ld
static double opel(const std::vector<float>& X, cublasOperation_t t, int ld, size_t off, int i, int j) {
  return t == CUBLAS_OP_N ? X[off + i + (size_t)j * ld] : X[off + j + (size_t)i * ld];
}

static void reference(const std::vector<float>& A, const std::vector<float>& B, const std::vector<float>& C0,
                      cublasOperation_t ta, cublasOperation_t tb, int m, int n, int k, float alpha, float beta, int lda,
                      int ldb, int ldc, size_t sa, size_t sb, size_t sc, int batch, std::vector<double>& ref,
                      std::vector<double>& mag) {
  ref.assign((size_t)ldc * n + sc * (batch - 1), 0.0);
  mag = ref;
  for (int b = 0; b < batch; ++b)
    for (int j = 0; j < n; ++j)
      for (int i = 0; i < m; ++i) {
        double s = 0.0, a = 0.0;
        for (int p = 0; p < k; ++p) {
          const double x = opel(A, ta, lda, b * sa, i, p) * opel(B, tb, ldb, b * sb, p, j);
          s += x;
          a += fabs(x);
        }
        const size_t ci = b * sc + i + (size_t)j * ldc;
        ref[ci] = alpha * s + (beta != 0.0f ? beta * (double)C0[ci] : 0.0);
        mag[ci] = fabs(alpha) * a + (beta != 0.0f ? fabs(beta * (double)C0[ci]) : 0.0);
      }
}

int main(int argc, char** argv) {
  const char* out_path = "values.txt";
  for (int i = 1; i + 1 < argc; ++i)
    if (!strcmp(argv[i], "-o")) out_path = argv[i + 1];
  g_out = fopen(out_path, "w");
  if (!g_out) return 2;
  cublasHandle_t h;
  if (cublasCreate(&h) != CUBLAS_STATUS_SUCCESS) { printf("cublasCreate failed\n"); return 2; }
  cublasSetMathMode(h, CUBLAS_DEFAULT_MATH);

  // ─── Sgemm, every transpose pair, padded leading dimensions; C starts as NaN (cudaMemset 0xff) with beta = 0 ───
  const int m = 37, n = 29, k = 23, pad = 3;
  const cublasOperation_t ops[2] = {CUBLAS_OP_N, CUBLAS_OP_T};
  std::vector<float> A(64 * 64), B(64 * 64);
  for (auto& x : A) x = frand();
  for (auto& x : B) x = frand();
  // the program's own kernel prepares A on the device before the library reads it: A = 0.5 A + 0.25
  float* dA = to_dev(A);
  affine<<<(A.size() + 127) / 128, 128>>>(dA, (int)A.size(), 0.5f, 0.25f);
  CHECK_CUDA(cudaDeviceSynchronize());
  for (auto& x : A) x = 0.5f * x + 0.25f;
  float* dB = to_dev(B);
  const int ldc = m + pad;
  float* dC = nullptr;
  CHECK_CUDA(cudaMalloc((void**)&dC, sizeof(float) * ldc * n));
  for (auto ta : ops)
    for (auto tb : ops) {
      const int lda = (ta == CUBLAS_OP_N ? m : k) + pad, ldb = (tb == CUBLAS_OP_N ? k : n) + pad;
      CHECK_CUDA(cudaMemset(dC, 0xff, sizeof(float) * ldc * n));
      const float alpha = 1.5f, beta = 0.0f;
      const cublasStatus_t st = cublasSgemm(h, ta, tb, m, n, k, &alpha, dA, lda, dB, ldb, &beta, dC, ldc);
      std::vector<double> ref, mag;
      reference(A, B, A, ta, tb, m, n, k, alpha, beta, lda, ldb, ldc, 0, 0, 0, 1, ref, mag);
      std::vector<float> got = to_host(dC, (size_t)ldc * n);
      for (int j = 0; j < n; ++j)  // the padding rows are not results
        for (int i = m; i < ldc; ++i) { got[i + (size_t)j * ldc] = 0.0f; ref[i + (size_t)j * ldc] = 0.0; }
      char name[32];
      snprintf(name, sizeof name, "sgemm_%s%s", ta == CUBLAS_OP_N ? "N" : "T", tb == CUBLAS_OP_N ? "N" : "T");
      verdict(name, st, got, ref, mag, k, ldexp(1.0, -23));
    }

  // ─── Sgemm with beta != 0, and SgemmStridedBatched ───
  {
    const int M = 70, N = 45, K = 64, batch = 3;
    std::vector<float> a((size_t)M * K * batch), b((size_t)K * N * batch), c((size_t)M * N * batch);
    for (auto& x : a) x = frand();
    for (auto& x : b) x = frand();
    for (auto& x : c) x = frand();
    float *da = to_dev(a), *db = to_dev(b), *dc = to_dev(c);
    const float alpha = -0.75f, beta = 0.5f;
    cublasStatus_t st = cublasSgemmStridedBatched(h, CUBLAS_OP_N, CUBLAS_OP_N, M, N, K, &alpha, da, M, (long long)M * K, db,
                                                  K, (long long)K * N, &beta, dc, M, (long long)M * N, batch);
    std::vector<double> ref, mag;
    reference(a, b, c, CUBLAS_OP_N, CUBLAS_OP_N, M, N, K, alpha, beta, M, K, M, (size_t)M * K, (size_t)K * N, (size_t)M * N,
              batch, ref, mag);
    verdict("sgemm_strided_batched", st, to_host(dc, c.size()), ref, mag, K, ldexp(1.0, -23));
    cudaFree(da); cudaFree(db); cudaFree(dc);
  }

  // ─── Sgemv N and T, Sdot ───
  {
    const int M = 300, N = 77;
    std::vector<float> a((size_t)M * N), x(M), y(M);
    for (auto& v : a) v = frand();
    for (auto& v : x) v = frand();
    for (auto& v : y) v = frand();
    float *da = to_dev(a), *dx = to_dev(x), *dy = to_dev(y);
    const float alpha = 1.25f, beta = -1.0f;
    for (auto t : ops) {
      const int rows = t == CUBLAS_OP_N ? M : N, cols = t == CUBLAS_OP_N ? N : M;
      CHECK_CUDA(cudaMemcpy(dy, y.data(), sizeof(float) * M, cudaMemcpyHostToDevice));
      const cublasStatus_t st = cublasSgemv(h, t, M, N, &alpha, da, M, dx, 1, &beta, dy, 1);
      std::vector<double> ref(rows), mag(rows);
      for (int i = 0; i < rows; ++i) {
        double s = 0.0, ab = 0.0;
        for (int j = 0; j < cols; ++j) {
          const double v = (t == CUBLAS_OP_N ? a[i + (size_t)j * M] : a[j + (size_t)i * M]) * (double)x[j];
          s += v;
          ab += fabs(v);
        }
        ref[i] = alpha * s + beta * (double)y[i];
        mag[i] = fabs(alpha) * ab + fabs(beta * (double)y[i]);
      }
      verdict(t == CUBLAS_OP_N ? "sgemv_N" : "sgemv_T", st, to_host(dy, rows), ref, mag, cols, ldexp(1.0, -23));
    }
    float r = 0.0f;
    const cublasStatus_t st = cublasSdot(h, M, dx, 1, dy, 1, &r);
    std::vector<float> yv = to_host(dy, M);
    double s = 0.0, ab = 0.0;
    for (int i = 0; i < M; ++i) { s += (double)x[i] * yv[i]; ab += fabs((double)x[i] * yv[i]); }
    verdict("sdot", st, std::vector<float>{r}, std::vector<double>{s}, std::vector<double>{ab}, M, ldexp(1.0, -23));
    cudaFree(da); cudaFree(dx); cudaFree(dy);
  }

  // ─── GemmEx / GemmStridedBatchedEx: fp16 and bf16 inputs, fp32 compute, fp32 or 16-bit outputs ───
  {
    const int M = 48, N = 40, K = 96, batch = 2;
    struct T { cudaDataType ab, c; const char* name; } types[] = {
        {CUDA_R_16F, CUDA_R_32F, "gemmex_h_s"}, {CUDA_R_16F, CUDA_R_16F, "gemmex_h_h"},
        {CUDA_R_16BF, CUDA_R_32F, "gemmex_b_s"}, {CUDA_R_16BF, CUDA_R_16BF, "gemmex_b_b"}};
    for (const T& t : types) {
      const bool bf = t.ab == CUDA_R_16BF, c16 = t.c != CUDA_R_32F;
      std::vector<float> a((size_t)K * M * batch), b((size_t)K * N * batch), c((size_t)M * N * batch);
      std::vector<uint16_t> a16(a.size()), b16(b.size()), c16v(c.size());
      for (size_t i = 0; i < a.size(); ++i) { a16[i] = bf ? f2b(frand()) : f2h(frand()); a[i] = bf ? b2f(a16[i]) : h2f(a16[i]); }
      for (size_t i = 0; i < b.size(); ++i) { b16[i] = bf ? f2b(frand()) : f2h(frand()); b[i] = bf ? b2f(b16[i]) : h2f(b16[i]); }
      for (size_t i = 0; i < c.size(); ++i) {
        const float v = frand();
        c16v[i] = bf ? f2b(v) : f2h(v);
        c[i] = c16 ? (bf ? b2f(c16v[i]) : h2f(c16v[i])) : v;
      }
      uint16_t *da = to_dev(a16), *db = to_dev(b16);
      void* dc = c16 ? (void*)to_dev(c16v) : (void*)to_dev(c);
      const float alpha = 1.0f, beta = 0.5f;
      // A stored K x M (op T), B K x N (op N): the row-major X W^T of a Linear layer
      cublasStatus_t st = cublasGemmStridedBatchedEx(h, CUBLAS_OP_T, CUBLAS_OP_N, M, N, K, &alpha, da, t.ab, K,
                                                     (long long)K * M, db, t.ab, K, (long long)K * N, &beta, dc, t.c, M,
                                                     (long long)M * N, batch, CUBLAS_COMPUTE_32F, CUBLAS_GEMM_DEFAULT);
      std::vector<double> ref, mag;
      reference(a, b, c, CUBLAS_OP_T, CUBLAS_OP_N, M, N, K, alpha, beta, K, K, M, (size_t)K * M, (size_t)K * N,
                (size_t)M * N, batch, ref, mag);
      std::vector<float> got(c.size());
      if (c16) {
        std::vector<uint16_t> g = to_host((uint16_t*)dc, c.size());
        for (size_t i = 0; i < g.size(); ++i) got[i] = bf ? b2f(g[i]) : h2f(g[i]);
      } else {
        got = to_host((float*)dc, c.size());
      }
      verdict(t.name, st, got, ref, mag, K, c16 ? (bf ? ldexp(1.0, -8) : ldexp(1.0, -11)) : ldexp(1.0, -23));
      // single GemmEx on batch 0 with op N on A (A^T stored: lda = M) as well
      cudaFree(da); cudaFree(db); cudaFree(dc);
    }
    // cublasGemmEx, fp16 in, fp32 out, A not transposed
    std::vector<float> a((size_t)M * K), b((size_t)K * N);
    std::vector<uint16_t> a16(a.size()), b16(b.size());
    for (size_t i = 0; i < a.size(); ++i) { a16[i] = f2h(frand()); a[i] = h2f(a16[i]); }
    for (size_t i = 0; i < b.size(); ++i) { b16[i] = f2h(frand()); b[i] = h2f(b16[i]); }
    uint16_t *da = to_dev(a16), *db = to_dev(b16);
    float* dc = nullptr;
    CHECK_CUDA(cudaMalloc((void**)&dc, sizeof(float) * M * N));
    const float alpha = 2.0f, beta = 0.0f;
    cublasStatus_t st = cublasGemmEx(h, CUBLAS_OP_N, CUBLAS_OP_N, M, N, K, &alpha, da, CUDA_R_16F, M, db, CUDA_R_16F, K,
                                     &beta, dc, CUDA_R_32F, M, CUBLAS_COMPUTE_32F, CUBLAS_GEMM_DEFAULT);
    std::vector<double> ref, mag;
    reference(a, b, a, CUBLAS_OP_N, CUBLAS_OP_N, M, N, K, alpha, beta, M, K, M, 0, 0, 0, 1, ref, mag);
    verdict("gemmex_h_s_NN", st, to_host(dc, (size_t)M * N), ref, mag, K, ldexp(1.0, -23));
    cudaFree(da); cudaFree(db); cudaFree(dc);
  }

  cudaFree(dA); cudaFree(dB); cudaFree(dC);
  cublasDestroy(h);
  fclose(g_out);
  printf("cublas_test: %s (%d failed)\n", g_fail ? "FAIL" : "PASS", g_fail);
  return g_fail ? 1 : 0;
}
