// Four 8x8 b16 tiles form a 16x16 fragment. Padding the right pair of
// tiles breaks the native address relationship in the fallback cases.
#include "../async_common.h"

constexpr unsigned pitch = 24, words = 16 * pitch;
__host__ __device__ static unsigned element(unsigned row, unsigned col) {
  return 0x7c00u ^ (row * 61u + col * 97u);
}

template<bool Trans>
__global__ void matrix(unsigned *out, unsigned offset) {
  __shared__ __align__(16) unsigned short src[words], dst[words];
  const unsigned lane = threadIdx.x;
  for (unsigned i = lane; i < words; i += 32) {
    src[i] = element(i / pitch, i % pitch);
    dst[i] = 0xdeadu;
  }
  __syncthreads();
  unsigned first = ((lane & 7) + ((lane >> 3 & 1) * 8)) * pitch + (lane >> 4) * offset;
  unsigned a, b, c, d;
#define LDM(mod) asm volatile("ldmatrix.sync.aligned.m8n8.x4" mod ".shared.b16 {%0,%1,%2,%3}, [%4];" \
    : "=r"(a), "=r"(b), "=r"(c), "=r"(d) : "r"(smem_u32(src + first)) : "memory")
#define STM(mod) asm volatile("stmatrix.sync.aligned.m8n8.x4" mod ".shared.b16 [%0], {%1,%2,%3,%4};" \
    :: "r"(smem_u32(dst + first)), "r"(a), "r"(b), "r"(c), "r"(d) : "memory")
  if (Trans) { LDM(".trans"); } else { LDM(""); }
  out[4 * lane] = a; out[4 * lane + 1] = b;
  out[4 * lane + 2] = c; out[4 * lane + 3] = d;
  if (Trans) { STM(".trans"); } else { STM(""); }
  __syncthreads();
  for (unsigned i = lane; i < words; i += 32) out[128 + i] = dst[i];
#undef LDM
#undef STM
}

int main() {
  unsigned *device, host[128 + words], errors = 0;
  ASYNC_CHECK(cudaMalloc(&device, sizeof(host)));
  for (unsigned trans = 0; trans < 2; ++trans) {
    for (unsigned offset = 8; offset <= 16; offset += 8) {
      if (trans) matrix<true><<<1, 32>>>(device, offset);
      else matrix<false><<<1, 32>>>(device, offset);
      ASYNC_CHECK(cudaMemcpy(host, device, sizeof(host), cudaMemcpyDeviceToHost));
      for (unsigned lane = 0; lane < 32; ++lane) {
        for (unsigned j = 0; j < 4; ++j) {
          unsigned row = 8 * (j & 1), col = offset * (j / 2);
          unsigned g = lane / 4, t = 2 * (lane % 4);
          unsigned lo = element(row + (trans ? t : g), col + (trans ? g : t));
          unsigned hi = element(row + (trans ? t + 1 : g), col + (trans ? g : t + 1));
          errors += host[lane * 4 + j] != (lo | (hi << 16));
        }
      }
      for (unsigned i = 0; i < words; ++i) {
        unsigned col = i % pitch;
        unsigned want = (col < 8 || (col >= offset && col < offset + 8))
                            ? element(i / pitch, col) : 0xdead;
        errors += host[128 + i] != want;
      }
    }
  }
  ASYNC_CHECK(cudaFree(device));
  printf("matrix x4 fragment, transpose, store guards: %u/2048 mismatches\n", errors);
  return errors != 0;
}
