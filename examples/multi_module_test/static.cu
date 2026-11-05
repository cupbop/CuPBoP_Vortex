// A module whose shared memory is static, so only the runtime's tables give the CTA its local memory. WORDS: its size. Lanes touch the
// first blockDim.x words. A CTA with less local memory than this shares it with the other CTAs of its core.
#ifndef WORDS
#define WORDS 1024
#endif

__global__ void static_kernel(const unsigned *x, unsigned *y, int n) {
  __shared__ unsigned t[WORDS];
  const int i = blockIdx.x * blockDim.x + threadIdx.x;
  const unsigned v = x[i] * 3u + 1u;
  t[threadIdx.x] = v;
  __syncthreads();
  y[i] = v + t[(threadIdx.x + 1) % blockDim.x];
}
