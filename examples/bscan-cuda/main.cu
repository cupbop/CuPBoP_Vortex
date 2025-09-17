//-----------------------------------------------------------------------
// Reference
//
// Harris, M. and Garland, M., 2012.
// Optimizing parallel prefix operations for the Fermi architecture.
// In GPU Computing Gems Jade Edition (pp. 29-38). Morgan Kaufmann.
//-----------------------------------------------------------------------

#include <cstdio>
#include <cstring>
#include <chrono>
#include <cuda.h>

__device__ __inline__ unsigned int lanemask_lt()
{
#ifdef ASM
  unsigned int mask;
  asm("mov.u32 %0, %lanemask_lt;" : "=r"(mask));
  return mask;
#else
  const unsigned int lane = threadIdx.x & (warpSize-1);
  return (1 << (lane)) - 1;
#endif
}

// positive numbers
__host__ __device__ __inline__
bool valid(int x) {
  return x > 0;
}

__device__ __inline__ int block_binary_prefix_sums(int x,
                                                   int* __restrict__ blockCtr,
                                                   int* __restrict__ turnCtr)
{
  const int idx     = threadIdx.x;
  const int lane    = idx & (warpSize - 1);
  const int warpIdx = idx >> 5;

  const bool p = valid(x);
#if (CUDART_VERSION < 9000)
  const unsigned m = __ballot(p);
#else
  const unsigned m = __ballot_sync(0xFFFFFFFFu, p);
#endif
  const int rank       = __popc(m & lanemask_lt());
  const int warpCount  = __popc(m);

  // One atomicAdd per warp, executed in warpIdx order.
  int base = 0;
  if (lane == 0) {
    // spin until it's this warp's turn
    while (atomicAdd(turnCtr, 0) != warpIdx) { }
    base = atomicAdd(blockCtr, warpCount);   // reserve a contiguous block
    atomicAdd(turnCtr, 1);                   // allow next warp
  }
#if (CUDART_VERSION < 9000)
  base = __shfl(base, 0);
#else
  base = __shfl_sync(0xFFFFFFFFu, base, 0);
#endif

  return base + rank; 
}

__global__ void binary_scan(
        int *__restrict__ g_odata,
  const int *__restrict__ g_idata,
        int *__restrict__ blockCtr,
        int *__restrict__ turnCtr)
{
  int i = threadIdx.x;
  g_odata[i] = block_binary_prefix_sums(g_idata[i], blockCtr, turnCtr);
}

template <int N>
void bscan (const int repeat) 
{
  int h_in[N];
  int h_out[N];
  int ref_out[N];

  int *d_in, *d_out;

  // two small per-launch device scalars (per-block counters)
  int *d_blockCtr, *d_turnCtr;

  cudaMalloc((void**)&d_in, N*sizeof(int));
  cudaMalloc((void**)&d_out, N*sizeof(int));
  cudaMalloc((void**)&d_blockCtr, sizeof(int));
  cudaMalloc((void**)&d_turnCtr, sizeof(int));

  bool ok = true;
  double time = 0.0;
  srand(123);

  // size_t grid_size = 12*7*8*9*10;
  size_t grid_size = 1;
  dim3 grids (grid_size);
  dim3 blocks (N);

  int valid_count = 0;

  for (int i = 0; i < repeat; i++) {
    for (int n = 0; n < N; n++) {
      h_in[n] = rand() % N - N/2;
      if (valid(h_in[n])) valid_count++;  // total number of valid elements
    }
    cudaMemcpy(d_in, h_in, N*sizeof(int), cudaMemcpyHostToDevice);

    // reset per-block counters
    cudaMemset(d_blockCtr, 0, sizeof(int));
    cudaMemset(d_turnCtr,  0, sizeof(int));

    cudaDeviceSynchronize();
    auto start = std::chrono::steady_clock::now();

    binary_scan<<<grids, blocks>>>(d_out, d_in, d_blockCtr, d_turnCtr);

    cudaDeviceSynchronize();
    auto end = std::chrono::steady_clock::now();
    time += std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();

    // verify exclusive sum
    cudaMemcpy(h_out, d_out, N*sizeof(int), cudaMemcpyDeviceToHost);

    ref_out[0] = 0;
    ok &= (h_out[0] == ref_out[0]);
    for (int i = 1; i < N; i++) {
      ref_out[i] = ref_out[i-1] + (h_in[i-1] > 0);
      ok &= (ref_out[i] == h_out[i]);
      // printf("i=%d ref=%d out=%d in=%d\n", i, ref_out[i], h_out[i], h_in[i]);
    }
    if (!ok) break;
  } // for

  printf("Block size = %d, ratio of valid elements = %f, verify = %s\n",
         N, valid_count * 1.f / (N * repeat), ok ? "PASS" : "FAIL");

  if (ok) {
    printf("Average execution time: %f (us)\n", (time * 1e-3f) / repeat);
    printf("Billion elements per second: %f\n\n",
            grid_size * N * repeat / time);
  }

  cudaFree(d_in);
  cudaFree(d_out);
  cudaFree(d_blockCtr);
  cudaFree(d_turnCtr);
}

int main(int argc, char* argv[])
{
  if (argc != 2) {
    printf("Usage: %s <repeat>\n", argv[0]);
    return 1;
  }
  const int repeat = atoi(argv[1]);

  // scan over N elements (N = [32, 1024])
  bscan<32>(repeat);
  bscan<64>(repeat);
  bscan<128>(repeat);
  bscan<256>(repeat);
  bscan<512>(repeat);

  return 0;
}
