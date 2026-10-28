// TMA 2D store from shared memory (bulk_group) after a generic-proxy write and a proxy fence (async design
// corpus `tma_store`). The tensor is BX x H with H not a multiple of the box: out-of-bounds rows of the last
// box are not written (the sentinel stays).
#include <cuda.h>
#include "../async_common.h"
#define BX 32
#define BY 32
__global__ void tma_store(const __grid_constant__ CUtensorMap tmap, float scale) {
  __shared__ __align__(128) float tile[BY * BX];
  const int t = threadIdx.x;
  for (int i = t; i < BX * BY; i += blockDim.x) tile[i] = scale * (float)(blockIdx.x * BX * BY + i);
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  __syncthreads();
  if (t == 0) {
    asm volatile("cp.async.bulk.tensor.2d.global.shared::cta.bulk_group [%0, {%1, %2}], [%3];"
                 ::"l"((uint64_t)&tmap), "r"(0), "r"((int)(blockIdx.x * BY)), "r"(smem_u32(tile)) : "memory");
    asm volatile("cp.async.bulk.commit_group;" ::: "memory");
    asm volatile("cp.async.bulk.wait_group.read 0;" ::: "memory");
  }
  __syncthreads();
}

int main(int argc, char **argv) {
  int blocks = 8;
  for (int i = 1; i + 1 < argc; i += 2)
    if (!strcmp(argv[i], "-b")) blocks = atoi(argv[i + 1]);
  const int H = blocks * BY - 7, threads = 128, rows = blocks * BY;
  const float scale = 0.5f, sentinel = -1.0f;
  printf("async_tma_store: blocks=%d tensor %dx%d box %dx%d\n", blocks, BX, H, BX, BY);
  const size_t n = (size_t)BX * rows; // allocation covers whole boxes so a stray write past H would show
  float *h = (float *)malloc(n * 4);
  for (size_t i = 0; i < n; ++i) h[i] = sentinel;
  float *d;
  ASYNC_CHECK(cudaMalloc(&d, n * 4));
  ASYNC_CHECK(cudaMemcpy(d, h, n * 4, cudaMemcpyHostToDevice));
  CUtensorMap tmap;
  cuuint64_t dims[2] = {(cuuint64_t)BX, (cuuint64_t)H}, strides[1] = {(cuuint64_t)BX * 4};
  cuuint32_t box[2] = {BX, BY}, estr[2] = {1, 1};
  ASYNC_CHECK(cuTensorMapEncodeTiled(&tmap, CU_TENSOR_MAP_DATA_TYPE_FLOAT32, 2, d, dims, strides, box, estr,
                                     CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_NONE,
                                     CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
  tma_store<<<blocks, threads>>>(tmap, scale);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(h, d, n * 4, cudaMemcpyDeviceToHost));
  int errors = 0;
  for (int y = 0; y < rows; ++y)
    for (int x = 0; x < BX; ++x) {
      const int b = y / BY, i = (y % BY) * BX + x;
      const float want = y < H ? scale * (float)(b * BX * BY + i) : sentinel;
      if (h[(size_t)y * BX + x] != want) {
        if (errors < 10) printf("MISMATCH [%d][%d]: got %f, expected %f\n", y, x, h[(size_t)y * BX + x], want);
        errors++;
      }
    }
  printf("%d errors\n%s\n", errors, errors ? "FAILED!" : "PASSED!");
  return errors ? 1 : 0;
}
