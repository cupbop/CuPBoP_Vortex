#include "../async_common.h"

#include <string.h>

// These definitions supply host launch stubs. Device code comes from the cubin.
#ifdef CUPBOP_REPLAY_TF32
extern "C" __global__ void kern_hmma_sp16816tf32(const uint32_t *, const uint32_t *, const uint32_t *,
                                                const float *, float *) {}
#else
extern "C" __global__ void kern_hmma_sp16832f16(const uint32_t *, const uint32_t *, const uint32_t *,
                                               const float *, float *) {}
extern "C" __global__ void kern_hmma_sp16832bf16(const uint32_t *, const uint32_t *, const uint32_t *,
                                                const float *, float *) {}
#endif

namespace {

constexpr unsigned Warp = 32, Registers = 4, Selectors = 2;
constexpr unsigned FragmentSize = Warp * Registers;
constexpr unsigned Results = Selectors * FragmentSize;
enum class Format { FP16, BF16, TF32 };

template <Format Type>
unsigned positions(unsigned row, unsigned group, unsigned shift = 0) {
  if constexpr (Type == Format::TF32)
    return (row + group + group / 3 + shift) & 1 ? 0xe : 4;
  const unsigned pairs[] = {4, 8, 12, 9, 13, 14, 1, 2, 3, 6, 7, 11};
  return pairs[(3 * row + 5 * group + shift) % 12];
}

int a_value(unsigned row, unsigned k) {
  return int((row + 3 * k + k / 4) % 9) - 4;
}

int b_value(unsigned k, unsigned col) {
  return int((5 * k + 3 * col + k * col + k / 3) % 7) - 3;
}

template <Format Type>
uint32_t operand_bits(int value) {
  if constexpr (Type == Format::FP16) {
    const uint32_t encoded[] = {0, 0x3c00, 0x4000, 0x4200, 0x4400};
    return encoded[value < 0 ? -value : value] | (value < 0 ? 0x8000 : 0);
  } else {
    const float input = value;
    uint32_t result;
    memcpy(&result, &input, sizeof(result));
    return Type == Format::BF16 ? result >> 16 : result;
  }
}

template <Format Type>
bool run_replay() {
  constexpr bool TF32 = Type == Format::TF32;
  constexpr unsigned GroupSize = TF32 ? 2 : 4;
  uint32_t a[FragmentSize], b[FragmentSize], metadata[Selectors * Warp] = {};
  float c[FragmentSize], out[Results];

  for (unsigned lane = 0; lane < Warp; ++lane) {
    const unsigned rowGroup = lane / 4, inGroup = lane % 4;
    for (unsigned reg = 0; reg < Registers; ++reg) {
      const unsigned row = rowGroup + 8 * (reg % 2), group = inGroup + 4 * (reg / 2);
      const unsigned indices = positions<Type>(row, group);
      const unsigned index = lane * Registers + reg;
      const unsigned kA = GroupSize * group, kB = (GroupSize / 2) * (inGroup + 4 * reg);
      if constexpr (TF32) {
        a[index] = operand_bits<Type>(a_value(row, kA + (indices == 0xe)));
        b[index] = operand_bits<Type>(b_value(kB, rowGroup));
      } else {
        a[index] = operand_bits<Type>(a_value(row, kA + (indices & 3))) |
                   (operand_bits<Type>(a_value(row, kA + (indices >> 2))) << 16);
        b[index] = operand_bits<Type>(b_value(kB, rowGroup)) |
                   (operand_bits<Type>(b_value(kB + 1, rowGroup)) << 16);
      }
      c[index] = int(lane % 6) - int(reg);
    }
    for (unsigned selector = 0; selector < Selectors; ++selector) {
      const unsigned shift = inGroup / 2 != selector;
      for (unsigned rowHalf = 0; rowHalf < 2; ++rowHalf)
        for (unsigned group = 0; group < 4; ++group)
          metadata[selector * Warp + lane] |=
              positions<Type>(rowGroup + 8 * rowHalf, 4 * (inGroup % 2) + group, shift)
              << (16 * rowHalf + 4 * group);
    }
  }

  uint32_t *deviceA, *deviceB, *deviceMetadata;
  float *deviceC, *deviceD;
  ASYNC_CHECK(cudaMalloc(&deviceA, sizeof(a)));
  ASYNC_CHECK(cudaMalloc(&deviceB, sizeof(b)));
  ASYNC_CHECK(cudaMalloc(&deviceMetadata, sizeof(metadata)));
  ASYNC_CHECK(cudaMalloc(&deviceC, sizeof(c)));
  ASYNC_CHECK(cudaMalloc(&deviceD, sizeof(out)));
  ASYNC_CHECK(cudaMemcpy(deviceA, a, sizeof(a), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(deviceB, b, sizeof(b), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(deviceMetadata, metadata, sizeof(metadata), cudaMemcpyHostToDevice));
  ASYNC_CHECK(cudaMemcpy(deviceC, c, sizeof(c), cudaMemcpyHostToDevice));
#ifdef CUPBOP_REPLAY_TF32
  kern_hmma_sp16816tf32<<<1, Warp>>>(deviceA, deviceB, deviceMetadata, deviceC, deviceD);
#else
  if constexpr (Type == Format::BF16)
    kern_hmma_sp16832bf16<<<1, Warp>>>(deviceA, deviceB, deviceMetadata, deviceC, deviceD);
  else
    kern_hmma_sp16832f16<<<1, Warp>>>(deviceA, deviceB, deviceMetadata, deviceC, deviceD);
#endif
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(out, deviceD, sizeof(out), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(deviceA));
  ASYNC_CHECK(cudaFree(deviceB));
  ASYNC_CHECK(cudaFree(deviceMetadata));
  ASYNC_CHECK(cudaFree(deviceC));
  ASYNC_CHECK(cudaFree(deviceD));

  const char *name = TF32 ? "TF32" : Type == Format::BF16 ? "BF16" : "FP16";
  unsigned mismatches = 0;
  for (unsigned selector = 0; selector < Selectors; ++selector) {
    for (unsigned lane = 0; lane < Warp; ++lane) {
      for (unsigned reg = 0; reg < Registers; ++reg) {
        const unsigned index = lane * Registers + reg;
        const unsigned row = lane / 4 + 8 * (reg / 2), col = 2 * (lane % 4) + reg % 2;
        float expected = c[index];
        for (unsigned k = 0; k < 8 * GroupSize; ++k) {
          const unsigned indices = positions<Type>(row, k / GroupSize);
          const unsigned bit = k % GroupSize;
          const bool selected = TF32 ? bit == (indices == 0xe) : bit == (indices & 3) || bit == (indices >> 2);
          if (selected) expected += a_value(row, k) * b_value(k, col);
        }
        const float actual = out[selector * FragmentSize + index];
        if (actual != expected && mismatches++ == 0)
          printf("%s selector %u first mismatch (%u,%u) expected %g got %g\n",
                 name, selector, row, col, expected, actual);
      }
    }
  }
  printf("%s HMMA.SP: %u/%u match\n", name, Results - mismatches, Results);
  return mismatches == 0;
}

} // namespace

int main() {
#ifdef CUPBOP_REPLAY_TF32
  return !run_replay<Format::TF32>();
#else
  const bool fp16 = run_replay<Format::FP16>();
  const bool bf16 = run_replay<Format::BF16>();
  return !(fp16 && bf16);
#endif
}
