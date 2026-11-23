#include "../async_common.h"

// Generate the CUDA host stub. Device bitcode comes from the archived SM90 cubin.
extern "C" __global__ void kern_imma_sp16864(const signed char *, const signed char *,
                                           const int *, int *, const uint32_t *) {}

static unsigned indices_for(unsigned row, unsigned group) {
  const unsigned codes[] = {4, 8, 12, 9, 13, 14, 1, 2, 3, 6, 7, 11};
  return codes[(3 * row + 5 * group) % 12];
}

int main() {
  constexpr unsigned M = 16, N = 8, K = 64, Warp = 32;
  signed char compressed[M * K / 2], dense[M * K] = {}, b[N * K];
  int c[M * N], output[M * N];
  uint32_t metadata[Warp] = {};
  for (unsigned row = 0; row < M; ++row) {
    for (unsigned group = 0; group < K / 4; ++group) {
      const unsigned indices = indices_for(row, group);
      for (unsigned i = 0; i < 2; ++i) {
        const unsigned k = 4 * group + ((indices >> (2 * i)) & 3);
        const int magnitude = 1 + (5 * row + k + k / 3) % 4;
        const int value = (row + k) & 1 ? -magnitude : magnitude;
        compressed[row * K / 2 + 2 * group + i] = value;
        dense[row * K + k] = value;
      }
    }
  }
  for (unsigned col = 0; col < N; ++col) {
    for (unsigned k = 0; k < K; ++k) {
      const int magnitude = 1 + (k + k / 5 + 3 * col) % 4;
      b[col * K + k] = (k + col) & 2 ? -magnitude : magnitude;
    }
  }
  for (unsigned i = 0; i < M * N; ++i)
    c[i] = ((i / N + i % N) & 1) ? INT32_MAX : INT32_MIN;
  for (unsigned lane = 0; lane < Warp; ++lane)
    for (unsigned group = 0; group < 8; ++group)
      metadata[lane] |= indices_for(lane / 4 + 8 * (lane % 2), 8 * ((lane % 4) / 2) + group) << (4 * group);

  signed char *deviceA, *deviceB;
  int *deviceC, *deviceD;
  uint32_t *deviceMetadata;
  ASYNC_CHECK(cudaMalloc(&deviceA, sizeof(compressed)));
  ASYNC_CHECK(cudaMalloc(&deviceB, sizeof(b)));
  ASYNC_CHECK(cudaMalloc(&deviceC, sizeof(c)));
  ASYNC_CHECK(cudaMalloc(&deviceD, sizeof(output)));
  ASYNC_CHECK(cudaMalloc(&deviceMetadata, sizeof(metadata)));
  ASYNC_CHECK(cudaMemcpy(deviceA, compressed, sizeof(compressed), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(deviceB, b, sizeof(b), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(deviceC, c, sizeof(c), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(deviceMetadata, metadata, sizeof(metadata), cudaMemcpyHostToDevice));
  kern_imma_sp16864<<<1, Warp>>>(deviceA, deviceB, deviceC, deviceD, deviceMetadata);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(output, deviceD, sizeof(output), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(deviceA));
  ASYNC_CHECK(cudaFree(deviceB));
  ASYNC_CHECK(cudaFree(deviceC));
  ASYNC_CHECK(cudaFree(deviceD));
  ASYNC_CHECK(cudaFree(deviceMetadata));

  unsigned errors = 0;
  for (unsigned row = 0; row < M; ++row) {
    for (unsigned col = 0; col < N; ++col) {
      int64_t expected = c[row * N + col];
      for (unsigned k = 0; k < K; ++k) {
        expected += dense[row * K + k] * b[col * K + k];
        if ((k + 1) % 32 == 0)
          expected = expected > INT32_MAX ? INT32_MAX : expected < INT32_MIN ? INT32_MIN : expected;
      }
      if (output[row * N + col] != expected && errors++ == 0)
        printf("first mismatch (%u,%u): got %d expected %d\n", row, col, output[row * N + col], int(expected));
    }
  }
  printf("IMMA.SP.16864.S8.S8.SAT: %u/%u match\n", M * N - errors, M * N);
  return errors != 0;
}
