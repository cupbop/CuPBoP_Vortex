// Async design §5.7 forms in software mode (clusters of one CTA): %cluster_ctarank / %cluster_nctarank,
// elect.sync with a lane result, setmaxnreg, griddepcontrol, barrier.cluster.arrive/wait, fence.proxy.async,
// fence.mbarrier_init, a bulk L2 prefetch. Each thread writes what it saw; the host checks against the CUDA meaning.
#include "../async_common.h"
__global__ void misc(const float *__restrict__ in, int *__restrict__ out) {
  const int t = threadIdx.x;
  uint32_t rank, nrank, lane, elected;
  asm volatile("mov.u32 %0, %%cluster_ctarank;" : "=r"(rank));
  asm volatile("mov.u32 %0, %%cluster_nctarank;" : "=r"(nrank));
  asm volatile("{ .reg .pred p; elect.sync %0|p, 0xffffffff; selp.u32 %1, 1, 0, p; }" : "=r"(lane), "=r"(elected));
  asm volatile("setmaxnreg.inc.sync.aligned.u32 232;" ::: "memory");
  asm volatile("griddepcontrol.wait;" ::: "memory");
  asm volatile("cp.async.bulk.prefetch.L2.global [%0], 256;" ::"l"(in + blockIdx.x * 64) : "memory");
  asm volatile("fence.proxy.async.shared::cta; fence.mbarrier_init.release.cluster;" ::: "memory");
  asm volatile("barrier.cluster.arrive.release.aligned; barrier.cluster.wait.acquire.aligned;" ::: "memory");
  asm volatile("griddepcontrol.launch_dependents;" ::: "memory");
  out[blockIdx.x * blockDim.x + t] = (int)(rank * 100000 + nrank * 10000 + lane * 10 + elected);
}

int main(int argc, char **argv) {
  int blocks = 4;
  for (int i = 1; i + 1 < argc; i += 2)
    if (!strcmp(argv[i], "-b")) blocks = atoi(argv[i + 1]);
  const int threads = 96;
  printf("async_misc: blocks=%d threads=%d\n", blocks, threads);
  const size_t n = (size_t)blocks * threads;
  int *h = (int *)malloc(n * 4);
  float *d_in;
  int *d_out;
  ASYNC_CHECK(cudaMalloc(&d_in, (size_t)blocks * 64 * 4));
  ASYNC_CHECK(cudaMalloc(&d_out, n * 4));
  ASYNC_CHECK(cudaMemset(d_out, 0xff, n * 4));
  misc<<<blocks, threads>>>(d_in, d_out);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(h, d_out, n * 4, cudaMemcpyDeviceToHost));
  int errors = 0;
  for (int b = 0; b < blocks; ++b)
    for (int t = 0; t < threads; ++t) {
      const int lane0 = 0; // all 32 lanes of every warp are active: lane 0 is elected
      const int want = 0 * 100000 + 1 * 10000 + lane0 * 10 + ((t % 32) == lane0 ? 1 : 0);
      if (h[b * threads + t] != want) {
        if (errors < 10) printf("MISMATCH out[%d][%d]: got %d, expected %d\n", b, t, h[b * threads + t], want);
        errors++;
      }
    }
  printf("%d errors\n%s\n", errors, errors ? "FAILED!" : "PASSED!");
  return errors ? 1 : 0;
}
