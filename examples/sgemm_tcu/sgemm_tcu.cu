// sgemm_tcu.cu - Simple CUDA wmma test for CuPBoP -> Vortex TCU translation

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cuda_runtime.h>
#include <mma.h>

using namespace nvcuda;

#define WMMA_M 16
#define WMMA_N 16
#define WMMA_K 16

#define CUDA_CHECK(_expr)                                                      \
  do {                                                                         \
    cudaError_t _err = (_expr);                                                \
    if (_err == cudaSuccess)                                                   \
      break;                                                                   \
    fprintf(stderr, "CUDA Error: '%s' returned %d (%s)!\n", #_expr, (int)_err, \
            cudaGetErrorString(_err));                                         \
    exit(-1);                                                                  \
  } while (0)

// GEMM kernel using wmma: C = A * B + C
// A: M x K (fp16, row-major), B: K x N (fp16, row-major), C: M x N (fp32)
__global__ void sgemm_wmma_kernel(const half *A, const half *B, float *C, int M,
                                  int N, int K) {
  int tile_row = blockIdx.y * WMMA_M;
  int tile_col = blockIdx.x * WMMA_N;

  wmma::fragment<wmma::matrix_a, WMMA_M, WMMA_N, WMMA_K, half, wmma::row_major>
      fragA;
  wmma::fragment<wmma::matrix_b, WMMA_M, WMMA_N, WMMA_K, half, wmma::row_major>
      fragB;
  wmma::fragment<wmma::accumulator, WMMA_M, WMMA_N, WMMA_K, float> fragC;

  wmma::fill_fragment(fragC, 0.0f);

  for (int i = 0; i < K; i += WMMA_K) {
    const half *tileA = A + tile_row * K + i;
    const half *tileB = B + i * N + tile_col;

    wmma::load_matrix_sync(fragA, tileA, K);
    wmma::load_matrix_sync(fragB, tileB, N);
    wmma::mma_sync(fragC, fragA, fragB, fragC);
  }

  float *tileC = C + tile_row * N + tile_col;
  wmma::store_matrix_sync(tileC, fragC, N, wmma::mem_row_major);
}

void gemm_cpu(const half *A, const half *B, float *C, int M, int N, int K) {
  for (int i = 0; i < M; i++)
    for (int j = 0; j < N; j++) {
      float sum = 0.0f;
      for (int k = 0; k < K; k++)
        sum += __half2float(A[i * K + k]) * __half2float(B[k * N + j]);
      C[i * N + j] = sum;
    }
}

int main(int argc, char **argv) {
  int M = WMMA_M, N = WMMA_M, K = WMMA_M;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-n") == 0 && i + 1 < argc) {
      int n = atoi(argv[++i]);
      if (n > 0 && n % WMMA_M == 0) {
        M = N = K = n;
      } else {
        fprintf(stderr, "Size must be multiple of %d\n", WMMA_M);
        return -1;
      }
    }
  }
  printf("SGEMM TCU Test: M=%d, N=%d, K=%d\n", M, N, K);

  size_t sizeA = M * K * sizeof(half);
  size_t sizeB = K * N * sizeof(half);
  size_t sizeC = M * N * sizeof(float);

  half *h_A = (half *)malloc(sizeA);
  half *h_B = (half *)malloc(sizeB);
  float *h_C = (float *)malloc(sizeC);
  float *h_C_ref = (float *)malloc(sizeC);

  srand(42);
  for (int i = 0; i < M * K; i++)
    // h_A[i] = __float2half((float)(rand() % 5) / 5.0f);
    h_A[i] = __float2half(1);
  // for (int i = 0; i < K * N; i++)
  //   h_B[i] = __float2half((float)(rand() % 5) / 5.0f);
  for (int i = 0; i < K * N; i++) {
    int k = i / N; // row index in B since B is K x N row-major
    h_B[i] = __float2half(k < 16 ? 1.0f : 0.0f);
  }
  memset(h_C, 0, sizeC);
  memset(h_C_ref, 0, sizeC);
  gemm_cpu(h_A, h_B, h_C_ref, M, N, K);

  half *d_A, *d_B;
  float *d_C;
  CUDA_CHECK(cudaMalloc(&d_A, sizeA));
  CUDA_CHECK(cudaMalloc(&d_B, sizeB));
  CUDA_CHECK(cudaMalloc(&d_C, sizeC));
  CUDA_CHECK(cudaMemcpy(d_A, h_A, sizeA, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_B, h_B, sizeB, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemset(d_C, 0, sizeC));

  dim3 grid(N / WMMA_N, M / WMMA_M);
  dim3 block(32, 1);
  sgemm_wmma_kernel<<<grid, block>>>(d_A, d_B, d_C, M, N, K);
  CUDA_CHECK(cudaDeviceSynchronize());
  CUDA_CHECK(cudaMemcpy(h_C, d_C, sizeC, cudaMemcpyDeviceToHost));

  int errors = 0;
  for (int i = 0; i < M * N; i++) {
    float diff = fabsf(h_C[i] - h_C_ref[i]);
    if (diff / fmaxf(fabsf(h_C_ref[i]), 1.0f) > 1e-2f) {
      if (errors < 10)
        printf("Mismatch [%d]: got %f, expected %f\n", i, h_C[i], h_C_ref[i]);
      errors++;
    }
  }
  printf("%s: %d/%d\n", errors ? "FAILED!" : "PASSED!", M * N - errors, M * N);

  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_C);
  free(h_A);
  free(h_B);
  free(h_C);
  free(h_C_ref);
  return errors ? 1 : 0;
}
