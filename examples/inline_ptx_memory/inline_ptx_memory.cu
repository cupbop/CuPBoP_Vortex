#include "../async_common.h"

#ifndef __NVCC__
extern "C" cudaError_t cudaLaunchKernel_vortex(const char *, dim3, dim3, void **,
                                              size_t, cudaStream_t, int);
#endif

namespace {

constexpr unsigned Threads = 32;
constexpr unsigned Values = Threads * 2;
constexpr unsigned Payload = 0x12345678;

__global__ void memory_ops(unsigned *values, unsigned *previous, unsigned *mailbox) {
  const unsigned lane = threadIdx.x;
  const unsigned i = blockIdx.x * blockDim.x + lane;
  unsigned old;
  asm volatile("atom.acq_rel.gpu.global.add.u32 %0, [%1], %2;"
               : "=r"(old) : "l"(values + i), "r"(i + 1) : "memory");
  previous[i] = old;
  if (lane != 0) return;

  unsigned *ready = mailbox;
  unsigned *payload = mailbox + 1;
  if (blockIdx.x == 0) {
    asm volatile("st.global.wb.b32 [%0], %1;" :: "l"(payload), "r"(Payload) : "memory");
    asm volatile("fence.acq_rel.gpu;" ::: "memory");
    asm volatile("red.release.gpu.global.add.u32 [%0], %1;" :: "l"(ready), "r"(1) : "memory");
  } else {
    unsigned state;
    do {
      asm volatile("ld.acquire.gpu.global.u32 %0, [%1];" : "=r"(state) : "l"(ready) : "memory");
    } while (state == 0);
    unsigned data;
    asm volatile("prefetch.global.L2 [%0];" :: "l"(payload));
    asm volatile("ld.global.cg.b32 %0, [%1];" : "=r"(data) : "l"(payload) : "memory");
    mailbox[2] = data;
    asm volatile("st.release.gpu.global.u32 [%0], %1;" :: "l"(ready), "r"(state + 1) : "memory");
  }
}

__global__ void fragment_load(unsigned *output) {
  __shared__ __align__(16) uint16_t tile[64];
  const unsigned lane = threadIdx.x;
  tile[lane] = lane + 1;
  tile[lane + Threads] = lane + Threads + 1;
  __syncthreads();
  unsigned fragment;
  asm volatile("ldmatrix.sync.aligned.m8n8.x1.shared.b16 {%0}, [%1];"
               : "=r"(fragment) : "l"(tile + (lane & 7) * 8) : "memory");
  output[lane] = fragment;
}

} // namespace

int main() {
  unsigned values[Values] = {}, previous[Values] = {}, mailbox[3] = {};
  unsigned *device_values, *device_previous, *device_mailbox;
  ASYNC_CHECK(cudaMalloc(&device_values, sizeof(values)));
  ASYNC_CHECK(cudaMalloc(&device_previous, sizeof(previous)));
  ASYNC_CHECK(cudaMalloc(&device_mailbox, sizeof(mailbox)));
  ASYNC_CHECK(cudaMemset(device_values, 0, sizeof(values)));
  ASYNC_CHECK(cudaMemset(device_previous, 0xff, sizeof(previous)));
  ASYNC_CHECK(cudaMemset(device_mailbox, 0, sizeof(mailbox)));
  memory_ops<<<2, Threads>>>(device_values, device_previous, device_mailbox);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(values, device_values, sizeof(values), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaMemcpy(previous, device_previous, sizeof(previous), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaMemcpy(mailbox, device_mailbox, sizeof(mailbox), cudaMemcpyDeviceToHost));
#ifndef __NVCC__
  void *args[] = {&device_previous};
  if (cudaLaunchKernel_vortex("missing_kernel", dim3(1), dim3(Threads), args, 0, nullptr, 1)
      != cudaErrorInvalidDeviceFunction) {
    puts("FAILED!: missing named kernel was accepted");
    return 1;
  }
#endif
  unsigned fragments[Threads];
  fragment_load<<<1, Threads>>>(device_previous);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(fragments, device_previous, sizeof(fragments), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device_values));
  ASYNC_CHECK(cudaFree(device_previous));
  ASYNC_CHECK(cudaFree(device_mailbox));

  unsigned errors = 0;
  for (unsigned i = 0; i < Values; ++i)
    errors += values[i] != i + 1 || previous[i] != 0;
  printf("atom.add: %u/%u results and prior values match\n", Values - errors, Values);
  printf("publication: state=%u, data=0x%x, observed=0x%x\n", mailbox[0], mailbox[1], mailbox[2]);
  unsigned bad_fragments = 0;
  for (unsigned lane = 0; lane < Threads; ++lane) {
    const unsigned first = (lane / 4) * 8 + (lane % 4) * 2 + 1;
    bad_fragments += fragments[lane] != (first | ((first + 1) << 16));
  }
  printf("ldmatrix: %u/%u fragments match\n", Threads - bad_fragments, Threads);
  const bool passed = errors == 0 && bad_fragments == 0 && mailbox[0] == 2 &&
                      mailbox[1] == Payload && mailbox[2] == Payload;
  puts(passed ? "PASSED!" : "FAILED!");
  return !passed;
}
