// Non-tensor bulk copy (cp.async.bulk, 1D) completing on an mbarrier (async design corpus `bulk1d`).
#include "../async_common.h"
#define N 1024
__global__ void bulk1d(const float *__restrict__ in, float *__restrict__ out) {
  __shared__ __align__(128) float buf[N];
  __shared__ __align__(8) uint64_t bar;
  const int t = threadIdx.x;
  if (t == 0) { mbar_init(&bar, 1); mbar_init_fence(); }
  __syncthreads();
  if (t == 0) {
    mbar_arrive_expect_tx(&bar, N * 4);
    asm volatile("cp.async.bulk.shared::cluster.global.mbarrier::complete_tx::bytes [%0], [%1], %2, [%3];"
                 ::"r"(smem_u32(buf)), "l"(in + (size_t)blockIdx.x * N), "r"(N * 4), "r"(smem_u32(&bar)) : "memory");
  }
  mbar_wait(&bar, 0);
  float acc = 0.f;
  for (int i = t; i < N; i += blockDim.x) acc += buf[i];
  out[blockIdx.x * blockDim.x + t] = acc;
}

int main(int argc, char **argv) {
  int blocks = 8;
  for (int i = 1; i + 1 < argc; i += 2)
    if (!strcmp(argv[i], "-b")) blocks = atoi(argv[i + 1]);
  const int threads = 128;
  printf("async_bulk1d: blocks=%d N=%d\n", blocks, N);
  const size_t nin = (size_t)blocks * N, nout = (size_t)blocks * threads;
  float *h_in = (float *)malloc(nin * 4), *h_out = (float *)malloc(nout * 4);
  for (size_t i = 0; i < nin; ++i) h_in[i] = async_val((int)i);
  float *d_in, *d_out;
  ASYNC_CHECK(cudaMalloc(&d_in, nin * 4));
  ASYNC_CHECK(cudaMalloc(&d_out, nout * 4));
  ASYNC_CHECK(cudaMemcpy(d_in, h_in, nin * 4, cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemset(d_out, 0, nout * 4));
  bulk1d<<<blocks, threads>>>(d_in, d_out);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(h_out, d_out, nout * 4, cudaMemcpyDeviceToHost));
  int errors = 0;
  for (int b = 0; b < blocks; ++b)
    for (int t = 0; t < threads; ++t) {
      float acc = 0.f;
      for (int i = t; i < N; i += threads) acc += h_in[(size_t)b * N + i];
      if (h_out[b * threads + t] != acc) {
        if (errors < 10) printf("MISMATCH out[%d][%d]: got %f, expected %f\n", b, t, h_out[b * threads + t], acc);
        errors++;
      }
    }
  printf("%d errors\n%s\n", errors, errors ? "FAILED!" : "PASSED!");
  return errors ? 1 : 0;
}
