// Big module of multi_module_test: the same interface as small.cu, more code than small.cu's whole image.
__device__ unsigned count;

#define R1(k) v = (v ^ (k##u * 2654435761u)) * 2246822519u; v ^= v >> 13;
#define R4(k) R1(k##1) R1(k##2) R1(k##3) R1(k##4)
#define R16(k) R4(k##1) R4(k##2) R4(k##3) R4(k##4)
#define R64(k) R16(k##1) R16(k##2) R16(k##3) R16(k##4)
#define R256 R64(1) R64(2) R64(3) R64(4)

__global__ void big_kernel(const unsigned *x, unsigned *y, int n) {
  extern __shared__ unsigned t[];
  const int i = blockIdx.x * blockDim.x + threadIdx.x;
  unsigned v = x[i];
  R256
  R256
  t[threadIdx.x] = v;
  __syncthreads();
  y[i] = v + t[(threadIdx.x + 1) % blockDim.x];
  if (i == 0) {
    count += 2;
    y[n] = count;
  }
}
