// Hopper TMA 2D tile load into a 2-stage shared-memory ring (async design corpus `tma2d`): thread 0 arms
// full[s] with arrive.expect_tx and issues the copy; every thread waits on full[s] and sums the tile. The
// tensor is W x H floats with H not a multiple of the box: the last tile reads out-of-bounds rows as zeros.
#include <cuda.h>
#include "../async_common.h"
#define BX 32
#define BY 32
__device__ __forceinline__ void tma_load_2d(void *dst, const CUtensorMap *map, uint64_t *bar, int x, int y) {
  asm volatile("cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [%0], [%1, {%3, %4}], [%2];"
               ::"r"(smem_u32(dst)), "l"((uint64_t)map), "r"(smem_u32(bar)), "r"(x), "r"(y) : "memory");
}
__global__ void tma2d(const __grid_constant__ CUtensorMap tmap, float *__restrict__ out, int ntiles) {
  __shared__ __align__(128) float tile[2][BY * BX];
  __shared__ __align__(8) uint64_t full[2];
  const int t = threadIdx.x;
  if (t == 0) { mbar_init(&full[0], 1); mbar_init(&full[1], 1); mbar_init_fence(); }
  __syncthreads();
  float acc = 0.f;
  for (int k = 0; k < ntiles; ++k) {
    int s = k & 1;
#if defined(ASYNC_NEG_OTHER_THREAD) // refusal test: the copy is issued by another thread than the arrive
    if (t == 0) mbar_arrive_expect_tx(&full[s], BX * BY * 4);
    if (t == 32) tma_load_2d(tile[s], &tmap, &full[s], 0, (blockIdx.x * ntiles + k) * BY);
#else
    if (t == 0) {
      mbar_arrive_expect_tx(&full[s], BX * BY * 4);
#if defined(ASYNC_NEG_WAIT_BEFORE_COPY) // refusal test: a wait between the arrive and its copy
      if (k > 0) mbar_wait(&full[s ^ 1], ((k - 1) >> 1) & 1);
#endif
      tma_load_2d(tile[s], &tmap, &full[s], 0, (blockIdx.x * ntiles + k) * BY);
    }
#endif
    mbar_wait(&full[s], (k >> 1) & 1);
    for (int i = t; i < BX * BY; i += blockDim.x) acc += tile[s][i];
    __syncthreads();
  }
  out[blockIdx.x * blockDim.x + t] = acc;
}

int main(int argc, char **argv) {
  int blocks = 8, ntiles = 4, W = 40;
  for (int i = 1; i + 1 < argc; i += 2) {
    if (!strcmp(argv[i], "-b")) blocks = atoi(argv[i + 1]);
    if (!strcmp(argv[i], "-t")) ntiles = atoi(argv[i + 1]);
  }
  const int H = blocks * ntiles * BY - 5, threads = 128;
  printf("async_tma2d: blocks=%d ntiles=%d tensor %dx%d box %dx%d\n", blocks, ntiles, W, H, BX, BY);
  const size_t nin = (size_t)W * H, nout = (size_t)blocks * threads;
  float *h_in = (float *)malloc(nin * 4), *h_out = (float *)malloc(nout * 4);
  for (size_t i = 0; i < nin; ++i) h_in[i] = async_val((int)i);
  float *d_in, *d_out;
  ASYNC_CHECK(cudaMalloc(&d_in, nin * 4));
  ASYNC_CHECK(cudaMalloc(&d_out, nout * 4));
  ASYNC_CHECK(cudaMemcpy(d_in, h_in, nin * 4, cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemset(d_out, 0, nout * 4));
  CUtensorMap tmap;
  cuuint64_t dims[2] = {(cuuint64_t)W, (cuuint64_t)H}, strides[1] = {(cuuint64_t)W * 4};
  cuuint32_t box[2] = {BX, BY}, estr[2] = {1, 1};
  ASYNC_CHECK(cuTensorMapEncodeTiled(&tmap, CU_TENSOR_MAP_DATA_TYPE_FLOAT32, 2, d_in, dims, strides, box, estr,
                                     CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_NONE,
                                     CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
  tma2d<<<blocks, threads>>>(tmap, d_out, ntiles);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(h_out, d_out, nout * 4, cudaMemcpyDeviceToHost));
  int errors = 0;
  for (int b = 0; b < blocks; ++b)
    for (int t = 0; t < threads; ++t) {
      float acc = 0.f;
      for (int k = 0; k < ntiles; ++k)
        for (int i = t; i < BX * BY; i += threads) {
          const int y = (b * ntiles + k) * BY + i / BX, x = i % BX;
          acc += y < H ? h_in[(size_t)y * W + x] : 0.f;
        }
      if (h_out[b * threads + t] != acc) {
        if (errors < 10) printf("MISMATCH out[%d][%d]: got %f, expected %f\n", b, t, h_out[b * threads + t], acc);
        errors++;
      }
    }
  printf("%d errors\n%s\n", errors, errors ? "FAILED!" : "PASSED!");
  return errors ? 1 : 0;
}
