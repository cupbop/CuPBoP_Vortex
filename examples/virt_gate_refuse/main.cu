// A shape the 16-lane sub-pass form cannot gate: both arms of a thread-dependent branch hold a warp op and jump into a shared
// block in front of the merge. The translator must refuse it (exit 1, "cannot be gated"); at 32 lanes it runs.
#include <stdio.h>
#include <cuda_runtime.h>
__global__ void k(int *out) {
  int t = threadIdx.x, v = t;
  if (t & 1) {
    v += __ballot_sync(__activemask(), t > 3);
    if (t & 2) goto shared_tail;
    v += 1;
  } else {
    v += __ballot_sync(__activemask(), t > 5);
    if (t & 4) goto shared_tail;
    v += 2;
  }
  goto done;
shared_tail:
  v += __ballot_sync(__activemask(), t > 7);
done:
  out[t] = v;
}
int main() {
  int *d = NULL; static int h[64];
  cudaMalloc((void **)&d, sizeof(h));
  k<<<1, 64>>>(d);
  cudaMemcpy(h, d, sizeof(h), cudaMemcpyDeviceToHost);
  for (int i = 0; i < 64; i++) printf("%d: %d\n", i, h[i]);
  printf("done\n");
  return 0;
}
