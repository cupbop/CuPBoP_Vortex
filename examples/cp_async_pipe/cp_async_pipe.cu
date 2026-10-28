// cp_async_pipe.cu -- 3-stage cp.async ring (CUDA pipeline primitives), the shape of an Ampere multistage
// mainloop: prefetch STAGES-1 tiles, then per tile issue the tile STAGES-1 ahead, commit, wait_prior(STAGES-1),
// __syncthreads, consume (each thread reads ANOTHER thread's copy), __syncthreads. The last tile of the last
// block runs past n: those 16-byte copies zero-fill (src-size 0 via the zfill argument).
// CuPBoP lowers the cp.async family to synchronous copies (lower_cp_async); nvcc -arch=sm_80 compiles the
// same kernel to LDGSTS / LDGDEPBAR / DEPBAR, the input of the lifted-IR test.
//   usage: ./host.out [-n elements] [-t tiles_per_block]
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cuda_runtime.h>
#include <cuda_pipeline.h>

#define THREADS 64
#define TILE (THREADS * 4) // floats per tile: one 16-byte cp.async per thread
#define STAGES 3

__device__ __forceinline__ void issue_tile(float *stage_buf, const float *in, int n, int g0) {
  const int g = g0 + threadIdx.x * 4;
  const bool inb = g < n; // n is a multiple of 4: a 16-byte chunk is all in or all out
  __pipeline_memcpy_async(stage_buf + threadIdx.x * 4, in + (inb ? g : 0), 16, inb ? 0 : 16);
}

__global__ void pipe3(const float *__restrict__ in, float *__restrict__ out, int n, int tiles_per_block) {
  __shared__ __align__(16) float buf[STAGES][TILE];
  const int base = blockIdx.x * tiles_per_block * TILE;
  for (int t = 0; t < STAGES - 1; ++t) {
    if (t < tiles_per_block) issue_tile(buf[t % STAGES], in, n, base + t * TILE);
    __pipeline_commit();
  }
  for (int t = 0; t < tiles_per_block; ++t) {
    const int ahead = t + STAGES - 1;
    if (ahead < tiles_per_block) issue_tile(buf[ahead % STAGES], in, n, base + ahead * TILE);
    __pipeline_commit();
    __pipeline_wait_prior(STAGES - 1); // tile t has landed (this thread's copies)
    __syncthreads();                   // ... and every other thread's
    const float *s = buf[t % STAGES];
    for (int j = 0; j < 4; ++j) {
      const int e = threadIdx.x * 4 + j;
      const int g = base + t * TILE + e;
      const float v = s[(e + 5) % TILE]; // another thread's element
      if (g < n) out[g] = v * 2.0f + (float)t;
    }
    __syncthreads(); // stage t % STAGES is refilled at t + 1
  }
}

int main(int argc, char **argv) {
  int n = 4096 - 64, tiles = 4;
  for (int i = 1; i + 1 < argc; i += 2) {
    if (!strcmp(argv[i], "-n")) n = atoi(argv[i + 1]);
    else if (!strcmp(argv[i], "-t")) tiles = atoi(argv[i + 1]);
  }
  n &= ~3;
  const int per_block = tiles * TILE;
  const int blocks = (n + per_block - 1) / per_block;
  printf("cp_async_pipe: n=%d tiles_per_block=%d blocks=%d stages=%d\n", n, tiles, blocks, STAGES);
  float *h_in = (float *)malloc(n * sizeof(float)), *h_out = (float *)malloc(n * sizeof(float));
  for (int i = 0; i < n; ++i) h_in[i] = (float)((i * 37) % 1000) * 0.25f + 1.0f;
  float *d_in, *d_out;
  cudaMalloc(&d_in, n * sizeof(float));
  cudaMalloc(&d_out, n * sizeof(float));
  cudaMemcpy(d_in, h_in, n * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemset(d_out, 0, n * sizeof(float));
  pipe3<<<blocks, THREADS>>>(d_in, d_out, n, tiles);
  cudaMemcpy(h_out, d_out, n * sizeof(float), cudaMemcpyDeviceToHost);
  int errors = 0;
  for (int b = 0; b < blocks; ++b)
    for (int t = 0; t < tiles; ++t)
      for (int e = 0; e < TILE; ++e) {
        const int g = b * per_block + t * TILE + e;
        if (g >= n) continue;
        const int gs = b * per_block + t * TILE + (e + 5) % TILE;
        const float src = gs < n ? h_in[gs] : 0.0f; // zero-filled past n
        const float want = src * 2.0f + (float)t;
        if (h_out[g] != want) {
          if (errors < 10) printf("MISMATCH out[%d]: got %f, expected %f\n", g, h_out[g], want);
          errors++;
        }
      }
  printf("%d errors\n%s\n", errors, errors ? "FAILED!" : "PASSED!");
  cudaFree(d_in);
  cudaFree(d_out);
  free(h_in);
  free(h_out);
  return errors ? 1 : 0;
}
