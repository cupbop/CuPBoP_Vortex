#include <cooperative_groups.h>
#include <cuda_runtime.h>
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <thread>
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

static int launch_exchange(unsigned *dev, dim3 grid, dim3 block, cudaStream_t stream) {
  void *args[] = {&dev};
  const unsigned count = grid.x * grid.y * grid.z * block.x * block.y * block.z;
  CHECK(cudaMemset(dev, 0xff, count * 3 * sizeof(unsigned)));
  CHECK(cudaLaunchCooperativeKernel(reinterpret_cast<void *>(exchange), grid, block, args, 0, stream));
  CHECK(cudaStreamSynchronize(stream));
  return 0;
}

static int check_exchange(unsigned *dev, dim3 grid, dim3 block) {
  const unsigned blocks = grid.x * grid.y * grid.z;
  const unsigned threads = block.x * block.y * block.z;
  const unsigned count = blocks * threads;
  std::vector<unsigned> host(3 * count);
  CHECK(cudaMemcpy(host.data(), dev, host.size() * sizeof(unsigned), cudaMemcpyDeviceToHost));
  for (unsigned i = 0; i < count; ++i) {
    unsigned peer = (i + threads + 1) % count;
    unsigned again = (peer + threads + 1) % count;
    if (host[i] != i * 7 + 11 || host[count + i] != peer * 7 + 48 ||
        host[2 * count + i] != ((again * 7 + 48) ^ 0x5a5a)) {
      std::printf("FAILED grid=%u block=%u index=%u: first=%u/%u second=%u/%u third=%u/%u\n",
                  blocks, threads, i, host[i], i * 7 + 11, host[count + i], peer * 7 + 48,
                  host[2 * count + i], (again * 7 + 48) ^ 0x5a5a);
      return 1;
    }
  }
  return 0;
}

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
  if (const char *fault = std::getenv("CUPBOP_TEST_GRID_FAULT")) {
    setenv("CUPBOP_TEST_GRID_ARMED", "1", 1);
    auto launch = [&] { return cudaLaunchCooperativeKernel(reinterpret_cast<void *>(validity), 1, lanes, args, 0, nullptr); };
    const auto status = launch();
    unsetenv("CUPBOP_TEST_GRID_ARMED");
    const bool lost = !std::strcmp(fault, "lost");
    const auto expected = !std::strcmp(fault, "alloc") ? cudaErrorMemoryAllocation : cudaErrorLaunchFailure;
    if (status != expected || launch() != (lost ? cudaErrorLaunchFailure : cudaSuccess)) return 1;
    if (cudaStreamSynchronize(nullptr) != (lost ? cudaErrorLaunchFailure : cudaSuccess)) return 1;
    CHECK(cudaFree(dev));
    std::printf("PASSED! cooperative workspace failure: %s\n", fault);
    return 0;
  }
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
    if (launch_exchange(dev, shape.grid, shape.block, nullptr) || check_exchange(dev, shape.grid, shape.block)) return 1;
    verified += 3 * shape.grid.x * shape.grid.y * shape.grid.z * shape.block.x * shape.block.y * shape.block.z;
  }
  // One host thread dispatches three odd-sized CTAs and the other dispatches
  // two. Verify both grids on distinct streams and device storage.
  unsigned *other;
  CHECK(cudaMalloc(&other, 3 * max_blocks * lanes * sizeof(unsigned)));
  cudaStream_t streams[2];
  CHECK(cudaStreamCreate(&streams[0]));
  CHECK(cudaStreamCreate(&streams[1]));
  int a = -1, b = -1;
  std::atomic<unsigned> ready{0};
  auto launch = [&](int &status, unsigned *data, unsigned blocks, unsigned threads, cudaStream_t stream) {
    ++ready;
    while (ready.load() != 2) std::this_thread::yield();
    status = launch_exchange(data, blocks, threads, stream);
  };
  std::thread first([&] { launch(a, dev, 3, 33, streams[0]); });
  std::thread second([&] { launch(b, other, 2, 39, streams[1]); });
  first.join();
  second.join();
  if (a || b || check_exchange(dev, 3, 33) || check_exchange(other, 2, 39)) return 1;
  CHECK(cudaStreamDestroy(streams[0]));
  CHECK(cudaStreamDestroy(streams[1]));
  CHECK(cudaFree(other));
  std::puts("PASSED! concurrent cooperative launches, 531 cross-CTA values including partial warps");
  CHECK(cudaFree(dev));
  std::printf("PASSED! cooperative launch, grid validity and %u cross-CTA values\n", verified);
}
