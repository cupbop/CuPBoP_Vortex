#include <cooperative_groups.h>
#include <cuda_runtime.h>
#include <cstdio>
#include <vector>

namespace cg = cooperative_groups;

__global__ void validity(unsigned *result) {
  if (threadIdx.x == 0) result[0] = cg::this_grid().is_valid();
}

__global__ void exchange(unsigned *words) {
  const cg::grid_group grid = cg::this_grid();
  const unsigned threads = blockDim.x * blockDim.y * blockDim.z;
  const unsigned lane = threadIdx.x + blockDim.x * (threadIdx.y + blockDim.y * threadIdx.z);
  const unsigned block = blockIdx.x + gridDim.x * (blockIdx.y + gridDim.y * blockIdx.z);
  const unsigned i = block * threads + lane;
  const unsigned count = gridDim.x * gridDim.y * gridDim.z * threads;
  const unsigned peer = (i + threads + 1) % count;
  words[i] = i * 7 + 11;
  grid.sync();
  words[count + i] = words[peer] + 37;
  grid.sync();
  words[2 * count + i] = words[count + peer] ^ 0x5a5a;
}

#define CHECK(expr) do { cudaError_t status = (expr); if (status != cudaSuccess) { \
  std::printf("FAILED %s (%d)\n", #expr, int(status)); return 1; } } while (0)

int main() {
  constexpr unsigned lanes = 32, max_blocks = 4;
  unsigned *dev;
  CHECK(cudaMalloc(&dev, 3 * max_blocks * lanes * sizeof(unsigned)));
  void *args[] = {&dev};
  int supported = 0;
  CHECK(cudaDeviceGetAttribute(&supported, cudaDevAttrCooperativeLaunch, 0));
  if (!supported) return 1;

  unsigned valid;
  validity<<<1, lanes>>>(dev);
  CHECK(cudaMemcpy(&valid, dev, sizeof(valid), cudaMemcpyDeviceToHost));
  if (valid) return 1;
  CHECK(cudaLaunchCooperativeKernel(reinterpret_cast<void *>(validity), 1, lanes, args, 0, nullptr));
  CHECK(cudaMemcpy(&valid, dev, sizeof(valid), cudaMemcpyDeviceToHost));
  if (!valid) return 1;

  const auto too_large = cudaLaunchCooperativeKernel(reinterpret_cast<void *>(exchange), 1000000, lanes, args, 0, nullptr);
  if (too_large != cudaErrorCooperativeLaunchTooLarge) {
    std::printf("FAILED oversubscribed grid (%d)\n", int(too_large));
    return 1;
  }
  struct Shape { dim3 grid, block; };
  const Shape shapes[] = {{1, lanes}, {2, lanes}, {max_blocks, lanes}, {{1, 2, 1}, {16, 2, 2}}};
  unsigned verified = 0;
  for (auto shape : shapes) {
    unsigned blocks = shape.grid.x * shape.grid.y * shape.grid.z;
    unsigned threads = shape.block.x * shape.block.y * shape.block.z;
    unsigned count = blocks * threads;
    CHECK(cudaMemset(dev, 0xff, count * 3 * sizeof(unsigned)));
    CHECK(cudaLaunchCooperativeKernel(reinterpret_cast<void *>(exchange), shape.grid, shape.block, args, 0, nullptr));
    std::vector<unsigned> host(3 * count);
    CHECK(cudaMemcpy(host.data(), dev, host.size() * sizeof(unsigned), cudaMemcpyDeviceToHost));
    for (unsigned i = 0; i < count; ++i) {
      unsigned peer = (i + threads + 1) % count;
      unsigned again = (peer + threads + 1) % count;
      if (host[i] != i * 7 + 11 || host[count + i] != peer * 7 + 48 ||
          host[2 * count + i] != ((again * 7 + 48) ^ 0x5a5a)) {
        std::printf("FAILED blocks=%u lane=%u\n", blocks, i);
        return 1;
      }
    }
    verified += 3 * count;
  }
  CHECK(cudaFree(dev));
  std::printf("PASSED! cooperative launch, grid validity and %u cross-CTA values\n", verified);
}
