// Ampere: per-thread cp.async whose completion is tracked by an mbarrier (cp.async.mbarrier.arrive.noinc),
// waited with mbarrier.test_wait (async design corpus `cpasync_mbar`, sm_80). The CUDA source form is
// supported; CuLifter's lift of the sm_80 SASS is refused by the translator (see async_ptx.cpp).
#include "../async_common.h"
__global__ void cpasync_mbar(const float *__restrict__ in, float *__restrict__ out) {
  __shared__ __align__(16) float buf[128];
  __shared__ __align__(8) uint64_t bar;
  const int t = threadIdx.x; // 128 threads
  if (t == 0) mbar_init(&bar, 128);
  __syncthreads();
  asm volatile("cp.async.ca.shared.global [%0], [%1], 4;" ::"r"(smem_u32(&buf[t])), "l"(in + blockIdx.x * 128 + t) : "memory");
  asm volatile("cp.async.mbarrier.arrive.noinc.shared.b64 [%0];" ::"r"(smem_u32(&bar)) : "memory");
  mbar_wait_test(&bar, 0);
  out[blockIdx.x * 128 + t] = buf[(t + 1) & 127] + buf[t];
}

int main(int argc, char **argv) {
  int blocks = 8;
  for (int i = 1; i + 1 < argc; i += 2)
    if (!strcmp(argv[i], "-b")) blocks = atoi(argv[i + 1]);
  printf("async_cpasync_mbar: blocks=%d\n", blocks);
  const size_t n = (size_t)blocks * 128;
  float *h_in = (float *)malloc(n * 4), *h_out = (float *)malloc(n * 4);
  for (size_t i = 0; i < n; ++i) h_in[i] = async_val((int)i);
  float *d_in, *d_out;
  ASYNC_CHECK(cudaMalloc(&d_in, n * 4));
  ASYNC_CHECK(cudaMalloc(&d_out, n * 4));
  ASYNC_CHECK(cudaMemcpy(d_in, h_in, n * 4, cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemset(d_out, 0, n * 4));
  cpasync_mbar<<<blocks, 128>>>(d_in, d_out);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(h_out, d_out, n * 4, cudaMemcpyDeviceToHost));
  int errors = 0;
  for (int b = 0; b < blocks; ++b)
    for (int t = 0; t < 128; ++t) {
      const float want = h_in[b * 128 + ((t + 1) & 127)] + h_in[b * 128 + t];
      if (h_out[b * 128 + t] != want) {
        if (errors < 10) printf("MISMATCH out[%d][%d]: got %f, expected %f\n", b, t, h_out[b * 128 + t], want);
        errors++;
      }
    }
  printf("%d errors\n%s\n", errors, errors ? "FAILED!" : "PASSED!");
  return errors ? 1 : 0;
}
