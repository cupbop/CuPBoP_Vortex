// Small module of multi_module_test: its symbols sit where big.cu has code.
__device__ unsigned count;

__global__ void small_kernel(const unsigned *x, unsigned *y, int n) {
  extern __shared__ unsigned t[];
  const int i = blockIdx.x * blockDim.x + threadIdx.x;
  const unsigned v = x[i] * 3u + 1u;   // lives across the barrier: a context array on the core mapping
  t[threadIdx.x] = v;
  __syncthreads();
  y[i] = v + t[(threadIdx.x + 1) % blockDim.x];
  if (i == 0) {
    count += 1;
    y[n] = count;
  }
}
