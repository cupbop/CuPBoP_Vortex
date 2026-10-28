// Warp-specialized producer/consumer over mbarriers, no TMA (async design corpus `mbar_ws`): warp 0 fills a
// 2-stage shared-memory ring with st.shared and arrives on full[s] (32 arrivals); warps 1-3 wait on full[s],
// consume, and arrive on empty[s] (96 arrivals). ntiles > STAGES reuses each mbarrier phase several times.
#include "../async_common.h"
#define STAGES 2
#define TILE 256
__global__ void mbar_ws(const float *__restrict__ in, float *__restrict__ out, int ntiles) {
  __shared__ float buf[STAGES][TILE];
  __shared__ __align__(8) uint64_t full[STAGES], empty[STAGES];
  const int warp = threadIdx.x / 32, lane = threadIdx.x % 32;
  if (threadIdx.x == 0) {
    for (int s = 0; s < STAGES; ++s) { mbar_init(&full[s], 32); mbar_init(&empty[s], 96); }
    mbar_init_fence();
  }
  __syncthreads();
  const float *src = in + (size_t)blockIdx.x * ntiles * TILE;
  if (warp == 0) {
    for (int k = 0; k < ntiles; ++k) {
      int s = k % STAGES; uint32_t ph = (k / STAGES) & 1;
      if (k >= STAGES) mbar_wait(&empty[s], ph ^ 1);
      for (int i = lane; i < TILE; i += 32) buf[s][i] = src[k * TILE + i];
      mbar_arrive(&full[s]);
    }
  } else {
    float acc = 0.f; int c = threadIdx.x - 32;
    for (int k = 0; k < ntiles; ++k) {
      int s = k % STAGES; uint32_t ph = (k / STAGES) & 1;
      mbar_wait(&full[s], ph);
      for (int i = c; i < TILE; i += 96) acc += buf[s][i] * (float)(k + 1);
      mbar_arrive(&empty[s]);
    }
    out[blockIdx.x * 96 + c] = acc;
  }
}

int main(int argc, char **argv) {
  int blocks = 8, ntiles = 6;
  for (int i = 1; i + 1 < argc; i += 2) {
    if (!strcmp(argv[i], "-b")) blocks = atoi(argv[i + 1]);
    if (!strcmp(argv[i], "-t")) ntiles = atoi(argv[i + 1]);
  }
  printf("async_mbar_ws: blocks=%d ntiles=%d\n", blocks, ntiles);
  const size_t nin = (size_t)blocks * ntiles * TILE, nout = (size_t)blocks * 96;
  float *h_in = (float *)malloc(nin * 4), *h_out = (float *)malloc(nout * 4);
  for (size_t i = 0; i < nin; ++i) h_in[i] = async_val((int)i);
  float *d_in, *d_out;
  ASYNC_CHECK(cudaMalloc(&d_in, nin * 4));
  ASYNC_CHECK(cudaMalloc(&d_out, nout * 4));
  ASYNC_CHECK(cudaMemcpy(d_in, h_in, nin * 4, cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemset(d_out, 0, nout * 4));
  mbar_ws<<<blocks, 128>>>(d_in, d_out, ntiles);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(h_out, d_out, nout * 4, cudaMemcpyDeviceToHost));
  int errors = 0;
  for (int b = 0; b < blocks; ++b)
    for (int c = 0; c < 96; ++c) {
      float acc = 0.f;
      for (int k = 0; k < ntiles; ++k)
        for (int i = c; i < TILE; i += 96) acc += h_in[(size_t)b * ntiles * TILE + k * TILE + i] * (float)(k + 1);
      if (h_out[b * 96 + c] != acc) {
        if (errors < 10) printf("MISMATCH out[%d][%d]: got %f, expected %f\n", b, c, h_out[b * 96 + c], acc);
        errors++;
      }
    }
  printf("%d errors\n%s\n", errors, errors ? "FAILED!" : "PASSED!");
  return errors ? 1 : 0;
}
