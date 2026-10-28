// tcu_dt_wmma_tf32.cu - CUDA wmma test for one element type (generated from experiments/dtype/tests/tcu_dt_wmma.cu.in).
// D = C0 + A*B (A row x B col fragments) + A*B (A col x B row fragments), over K in WK steps; C0 read with
// load_matrix_sync(acc, ..., mem_row_major), D stored row-major and its transpose col-major. 2 warps per block.
//   ./host.out [-n N] [-r] [-s]   -r: random data (float types: tolerance from the fp32 summation bound),
//                                 -s: satfinite with C0 near the int32 limits (int types)
// The CPU reference follows the NVIDIA semantics: bf16/f16 exact products, tf32 operands = __float_to_tf32 (rna) when
// the kernel converts the fragments (flag 1), else the top 19 bits (truncation); int sums wrap, satfinite clamps
// after every mma step.
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cuda_runtime.h>
#include <mma.h>
#include <cuda_fp16.h>
#include <cuda_bf16.h>
using namespace nvcuda;

#define DT_tf32 1
#if defined(DT_bf16)
typedef __nv_bfloat16 in_t; typedef __nv_bfloat16 frag_t; typedef float acc_t; enum { WK = 16 };
#define IS_INT_TEST 0
#elif defined(DT_f16)
typedef __half in_t; typedef __half frag_t; typedef float acc_t; enum { WK = 16 };
#define IS_INT_TEST 0
#elif defined(DT_tf32)
typedef float in_t; typedef wmma::precision::tf32 frag_t; typedef float acc_t; enum { WK = 8 };
#define IS_INT_TEST 0
#elif defined(DT_s8)
typedef signed char in_t; typedef signed char frag_t; typedef int acc_t; enum { WK = 16 };
#define IS_INT_TEST 1
#elif defined(DT_u8)
typedef unsigned char in_t; typedef unsigned char frag_t; typedef int acc_t; enum { WK = 16 };
#define IS_INT_TEST 1
#endif
#define WM 16
#define WN 16

#define CUDA_CHECK(_e) do { cudaError_t _r = (_e); if (_r != cudaSuccess) { fprintf(stderr, "CUDA Error: %s -> %d\n", #_e, (int)_r); exit(-1); } } while (0)

__global__ void tcu_dt_wmma_kernel(const in_t *A, const in_t *At, const in_t *B, const in_t *Bt, const acc_t *C0,
                                   acc_t *D, acc_t *Dt, int M, int N, int K, int flags) {
  const int warp = threadIdx.x / 32;
  const int tile_row = blockIdx.y * WM, tile_col = (blockIdx.x * 2 + warp) * WN;
  wmma::fragment<wmma::matrix_a, WM, WN, WK, frag_t, wmma::row_major> ar;
  wmma::fragment<wmma::matrix_a, WM, WN, WK, frag_t, wmma::col_major> ac;
  wmma::fragment<wmma::matrix_b, WM, WN, WK, frag_t, wmma::row_major> br;
  wmma::fragment<wmma::matrix_b, WM, WN, WK, frag_t, wmma::col_major> bc;
  wmma::fragment<wmma::accumulator, WM, WN, WK, acc_t> acc;
  wmma::load_matrix_sync(acc, C0 + tile_row * N + tile_col, N, wmma::mem_row_major);
  for (int k = 0; k < K; k += WK) {
    wmma::load_matrix_sync(ar, A + tile_row * K + k, K);   // A[r][k] at A[r*K + k]
    wmma::load_matrix_sync(bc, Bt + tile_col * K + k, K);  // B[k][n] at Bt[n*K + k]
    wmma::load_matrix_sync(ac, At + k * M + tile_row, M);  // A[r][k] at At[k*M + r]
    wmma::load_matrix_sync(br, B + k * N + tile_col, N);   // B[k][n] at B[k*N + n]
#if defined(DT_tf32)
    if (flags & 1) {
      for (int i = 0; i < ar.num_elements; i++) ar.x[i] = wmma::__float_to_tf32(ar.x[i]);
      for (int i = 0; i < ac.num_elements; i++) ac.x[i] = wmma::__float_to_tf32(ac.x[i]);
      for (int i = 0; i < br.num_elements; i++) br.x[i] = wmma::__float_to_tf32(br.x[i]);
      for (int i = 0; i < bc.num_elements; i++) bc.x[i] = wmma::__float_to_tf32(bc.x[i]);
    }
#endif
#if IS_INT_TEST
    wmma::mma_sync(acc, ar, bc, acc, (flags & 2) != 0);
    wmma::mma_sync(acc, ac, br, acc, (flags & 2) != 0);
#else
    wmma::mma_sync(acc, ar, bc, acc);
    wmma::mma_sync(acc, ac, br, acc);
#endif
  }
  wmma::store_matrix_sync(D + tile_row * N + tile_col, acc, N, wmma::mem_row_major);
  wmma::store_matrix_sync(Dt + tile_col * M + tile_row, acc, M, wmma::mem_col_major);
}

// ---- host ------------------------------------------------------------------------------------------
static double in_val(in_t v) {
#if defined(DT_bf16)
  return (double)__bfloat162float(v);
#elif defined(DT_f16)
  return (double)__half2float(v);
#else
  return (double)v;
#endif
}
static uint32_t f2u(float f) { uint32_t u; memcpy(&u, &f, 4); return u; }
static float u2f(uint32_t u) { float f; memcpy(&f, &u, 4); return f; }
static double tf32_operand(float x, bool rna) { // value the tensor core multiplies
  uint32_t u = f2u(x);
  if (rna) { if ((u & 0x7f800000u) != 0x7f800000u) u = (u + 0x1000u) & 0xffffe000u; }
  else u &= 0xffffe000u;
  return (double)u2f(u);
}
static in_t make_in(int exact, int i) {
#if defined(DT_bf16)
  return __float2bfloat16(exact ? (float)(rand() % 17 - 8) / 8.0f : (float)rand() / RAND_MAX * 2.f - 1.f);
#elif defined(DT_f16)
  return __float2half(exact ? (float)(rand() % 17 - 8) / 8.0f : (float)rand() / RAND_MAX * 2.f - 1.f);
#elif defined(DT_tf32)
  return exact ? (float)(rand() % 33 - 16) / 16.0f : (float)rand() / RAND_MAX * 2.f - 1.f;
#elif defined(DT_s8)
  (void)exact; (void)i; return (signed char)(rand() % 256 - 128);
#else
  (void)exact; (void)i; return (unsigned char)(rand() % 256);
#endif
}

int main(int argc, char **argv) {
  int n = 32, rnd = 0, sat = 0;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "-n") && i + 1 < argc) n = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-r")) rnd = 1;
    else if (!strcmp(argv[i], "-s")) sat = 1;
  }
  if (n % 32) { fprintf(stderr, "n must be a multiple of 32\n"); return -1; }
  const int M = n, N = n, K = n;
  printf("tcu_dt_wmma tf32: M=N=K=%d random=%d satfinite=%d\n", n, rnd, sat);
  in_t *hA = (in_t *)malloc(sizeof(in_t) * M * K), *hAt = (in_t *)malloc(sizeof(in_t) * M * K);
  in_t *hB = (in_t *)malloc(sizeof(in_t) * K * N), *hBt = (in_t *)malloc(sizeof(in_t) * K * N);
  acc_t *hC = (acc_t *)malloc(sizeof(acc_t) * M * N), *hD = (acc_t *)malloc(sizeof(acc_t) * M * N), *hDt = (acc_t *)malloc(sizeof(acc_t) * M * N);
  srand(1234 + n + 7 * rnd + 13 * sat);
  for (int r = 0; r < M; r++) for (int k = 0; k < K; k++) { hA[r * K + k] = make_in(!rnd, r); hAt[k * M + r] = hA[r * K + k]; }
  for (int k = 0; k < K; k++) for (int c = 0; c < N; c++) { hB[k * N + c] = make_in(!rnd, k); hBt[c * K + k] = hB[k * N + c]; }
  for (int i = 0; i < M * N; i++) {
#if IS_INT_TEST
    hC[i] = sat ? (acc_t)((i & 1) ? 2147483647 - (rand() % 300000) : -2147483647 - 1 + (rand() % 300000)) : (acc_t)(rand() % 2000001 - 1000000);
#else
    hC[i] = rnd ? (float)rand() / RAND_MAX * 2.f - 1.f : (float)(rand() % 9 - 4) / 4.0f;
#endif
  }
  in_t *dA, *dAt, *dB, *dBt; acc_t *dC, *dD, *dDt;
  CUDA_CHECK(cudaMalloc(&dA, sizeof(in_t) * M * K)); CUDA_CHECK(cudaMalloc(&dAt, sizeof(in_t) * M * K));
  CUDA_CHECK(cudaMalloc(&dB, sizeof(in_t) * K * N)); CUDA_CHECK(cudaMalloc(&dBt, sizeof(in_t) * K * N));
  CUDA_CHECK(cudaMalloc(&dC, sizeof(acc_t) * M * N)); CUDA_CHECK(cudaMalloc(&dD, sizeof(acc_t) * M * N)); CUDA_CHECK(cudaMalloc(&dDt, sizeof(acc_t) * M * N));
  CUDA_CHECK(cudaMemcpy(dA, hA, sizeof(in_t) * M * K, cudaMemcpyHostToDevice)); CUDA_CHECK(cudaMemcpy(dAt, hAt, sizeof(in_t) * M * K, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(dB, hB, sizeof(in_t) * K * N, cudaMemcpyHostToDevice)); CUDA_CHECK(cudaMemcpy(dBt, hBt, sizeof(in_t) * K * N, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(dC, hC, sizeof(acc_t) * M * N, cudaMemcpyHostToDevice));
  int errors = 0, total = 0;
#if defined(DT_tf32)
  const int nruns = 2; // flags 1: __float_to_tf32 on the fragments, 0: raw fp32 operands (hardware truncation)
#else
  const int nruns = 1;
#endif
  for (int run = 0; run < nruns; run++) {
#if defined(DT_tf32)
    const int flags = run == 0 ? 1 : 0;
#else
    const int flags = sat ? 2 : 0;
#endif
    CUDA_CHECK(cudaMemset(dD, 0, sizeof(acc_t) * M * N)); CUDA_CHECK(cudaMemset(dDt, 0, sizeof(acc_t) * M * N));
    dim3 grid(N / (2 * WN), M / WM), block(64, 1);
    tcu_dt_wmma_kernel<<<grid, block>>>(dA, dAt, dB, dBt, dC, dD, dDt, M, N, K, flags);
    CUDA_CHECK(cudaDeviceSynchronize());
    CUDA_CHECK(cudaMemcpy(hD, dD, sizeof(acc_t) * M * N, cudaMemcpyDeviceToHost));
    CUDA_CHECK(cudaMemcpy(hDt, dDt, sizeof(acc_t) * M * N, cudaMemcpyDeviceToHost));
    double maxerr = 0;
    for (int r = 0; r < M; r++)
      for (int c = 0; c < N; c++) {
        bool ok;
        double ref, tol = 0, got = (double)hD[r * N + c];
#if IS_INT_TEST
        // two mma steps per K tile, each D = A_tile*B_tile + C (sat: clamped)
        int64_t acc = hC[r * N + c];
        for (int k0 = 0; k0 < K; k0 += WK)
          for (int pass = 0; pass < 2; pass++) {
            int64_t s = 0;
            for (int k = k0; k < k0 + WK; k++) s += (int64_t)(int)hA[r * K + k] * (int64_t)(int)hB[k * N + c];
            acc += s;
            if (flags & 2) acc = acc > 2147483647LL ? 2147483647LL : (acc < -2147483648LL ? -2147483648LL : acc);
            else acc = (int64_t)(int32_t)(uint32_t)(uint64_t)acc;
          }
        ref = (double)acc;
        ok = hD[r * N + c] == (acc_t)acc && hDt[c * M + r] == (acc_t)acc;
#else
        double s = hC[r * N + c], mag = fabs(s);
        for (int k = 0; k < K; k++) {
#if defined(DT_tf32)
          double p = tf32_operand(hA[r * K + k], flags & 1) * tf32_operand(hB[k * N + c], flags & 1);
#else
          double p = in_val(hA[r * K + k]) * in_val(hB[k * N + c]);
#endif
          s += 2 * p; mag += 2 * fabs(p);
        }
        ref = s;
        // exact data: every partial sum is exact in fp32 -> no tolerance. random: |fl(sum) - sum| <= (n-1) u sum|x|
        // for any summation order (n = 2K+1 terms, u = 2^-24); x2 margin.
        if (rnd) tol = 2.0 * (2 * K + 2) * ldexp(1.0, -24) * mag;
        ok = fabs(got - ref) <= tol && fabs((double)hDt[c * M + r] - ref) <= tol;
        if (fabs(got - ref) > maxerr) maxerr = fabs(got - ref);
#endif
        total++;
        if (!ok) {
          if (errors < 10) printf("Mismatch run %d [%d,%d]: got %.9g (col-major %.9g), expected %.9g (tol %.3g)\n", run, r, c, got, (double)hDt[c * M + r], ref, tol);
          errors++;
        }
      }
    printf("run %d flags=%d: max |err| %.3g\n", run, flags, maxerr);
  }
  printf("%s: %d/%d\n", errors ? "FAILED!" : "PASSED!", total - errors, total);
  return errors ? 1 : 0;
}
