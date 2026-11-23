#include "../async_common.h"

constexpr unsigned Rows = 8;
constexpr unsigned Columns = 16;
constexpr unsigned K = 96;
constexpr unsigned Outputs = Rows * Columns;

__device__ unsigned load_published(const unsigned *ptr) {
  unsigned value;
  asm volatile("ld.volatile.global.b32 %0, [%1];" : "=r"(value) : "l"(ptr) : "memory");
  return value;
}

__device__ void publish(unsigned *ptr, unsigned value) {
  asm volatile("st.volatile.global.b32 [%0], %1;" :: "l"(ptr), "r"(value) : "memory");
}

__global__ void serial_gemm(const unsigned *a, const unsigned *b, unsigned *c, unsigned *semaphore) {
  const unsigned partition = blockIdx.z;
  const unsigned steps = K / gridDim.z;
  const unsigned element = threadIdx.x;
  const unsigned row = element / Columns;
  const unsigned column = element % Columns;

  unsigned partial = 0;
  for (unsigned k = partition * steps; k < (partition + 1) * steps; ++k)
    partial += a[row * K + k] * b[k * Columns + column];

  // The CTA vote broadcasts lane zero's observation. The global semaphore, not the
  // vote, orders the CTAs that accumulate into this output tile.
  while (__syncthreads_and(element != 0 || load_published(semaphore) != partition)) {}
  if (partition != 0)
    partial += load_published(c + element);
  c[element] = partial;
  __threadfence();
  __syncthreads();
  if (element == 0)
    publish(semaphore, partition + 1);
}

int main() {
  unsigned a[Rows * K], b[K * Columns], expected[Outputs] = {}, actual[Outputs];
  for (unsigned i = 0; i < Rows * K; ++i)
    a[i] = (i * 3 + i / K) % 11 + 1;
  for (unsigned i = 0; i < K * Columns; ++i)
    b[i] = (i * 5 + i / Columns) % 13 + 1;
  for (unsigned row = 0; row < Rows; ++row)
    for (unsigned column = 0; column < Columns; ++column)
      for (unsigned k = 0; k < K; ++k)
        expected[row * Columns + column] += a[row * K + k] * b[k * Columns + column];

  unsigned *device_a, *device_b, *device_c, *semaphore;
  ASYNC_CHECK(cudaMalloc(&device_a, sizeof(a)));
  ASYNC_CHECK(cudaMalloc(&device_b, sizeof(b)));
  ASYNC_CHECK(cudaMalloc(&device_c, sizeof(actual)));
  ASYNC_CHECK(cudaMalloc(&semaphore, sizeof(unsigned)));
  ASYNC_CHECK(cudaMemcpy(device_a, a, sizeof(a), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(device_b, b, sizeof(b), cudaMemcpyHostToDevice));
  for (unsigned partitions = 1; partitions <= 3; ++partitions) {
    ASYNC_CHECK(cudaMemset(device_c, 0, sizeof(actual)));
    ASYNC_CHECK(cudaMemset(semaphore, 0, sizeof(unsigned)));
    serial_gemm<<<dim3(1, 1, partitions), Outputs>>>(device_a, device_b, device_c, semaphore);
    ASYNC_CHECK(cudaDeviceSynchronize());
    ASYNC_CHECK(cudaMemcpy(actual, device_c, sizeof(actual), cudaMemcpyDeviceToHost));
    unsigned completed = 0;
    ASYNC_CHECK(cudaMemcpy(&completed, semaphore, sizeof(completed), cudaMemcpyDeviceToHost));
    unsigned mismatches = 0;
    for (unsigned i = 0; i < Outputs; ++i)
      mismatches += actual[i] != expected[i];
    printf("%u partitions, %u/%u outputs match, semaphore=%u\n",
           partitions, Outputs - mismatches, Outputs, completed);
    if (mismatches || completed != partitions)
      return 1;
  }
  ASYNC_CHECK(cudaFree(device_a));
  ASYNC_CHECK(cudaFree(device_b));
  ASYNC_CHECK(cudaFree(device_c));
  ASYNC_CHECK(cudaFree(semaphore));
  puts("PASSED!");
  return 0;
}
