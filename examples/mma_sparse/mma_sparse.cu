#include "../async_common.h"

#include <string.h>

namespace {

constexpr unsigned Threads = 64;
constexpr unsigned Blocks = 2;
constexpr unsigned Rows = 16;
constexpr unsigned Cols = 8;
#ifdef CUPBOP_TEST_NO_TF32
constexpr unsigned Flavors = 8;
#else
constexpr unsigned Flavors = 10;
#endif
constexpr unsigned Results = Blocks * (Threads / 32) * Rows * Cols;

__host__ __device__ unsigned sparse_positions(unsigned tile, unsigned row, unsigned group) {
  constexpr unsigned pairs[] = {4, 8, 12, 9, 13, 14, 1, 2, 3, 6, 7, 11};
  return pairs[(tile + 3 * row + 5 * group) % 12];
}

__host__ __device__ unsigned tf32_position(unsigned tile, unsigned row, unsigned pair) {
  return (tile + 3 * row + 5 * pair + pair / 3) & 1;
}

__host__ __device__ int a_value(unsigned tile, unsigned row, unsigned k, bool isUnsigned) {
  const int value = 1 + (tile + 5 * row + k + k / 3) % 4;
  return !isUnsigned && ((row + k) & 1) ? -value : value;
}

__host__ __device__ int b_value(unsigned tile, unsigned k, unsigned col, bool isUnsigned) {
  const int value = 1 + (2 * tile + k + k / 5 + 3 * col) % 4;
  return !isUnsigned && ((k + col) & 2) ? -value : value;
}

__host__ __device__ int c_value(unsigned tile, unsigned row, unsigned col, bool saturate = false) {
  if (saturate) return (tile + row + col) & 1 ? INT32_MAX : INT32_MIN;
  return int(2 * tile + row) - int(col);
}

template <unsigned Format>
__device__ unsigned packed_value(int value) {
  if constexpr (Format == 0 || Format == 1) {
    constexpr unsigned f16[] = {0x3c00, 0x4000, 0x4200, 0x4400};
    constexpr unsigned bf16[] = {0x3f80, 0x4000, 0x4040, 0x4080};
    const unsigned magnitude = value < 0 ? -value : value;
    return (Format == 0 ? f16[magnitude - 1] : bf16[magnitude - 1]) | (value < 0 ? 0x8000 : 0);
  } else if constexpr (Format == 4) {
    return __float_as_uint(float(value));
  } else {
    return unsigned(value) & 255;
  }
}

template <unsigned Format, unsigned Selector, bool Sat = false>
__device__ void check_tile(unsigned *output, unsigned tile, unsigned lane) {
  constexpr bool IsFloat = Format < 2 || Format == 4;
  constexpr bool IsUnsigned = Format == 3;
  constexpr unsigned Ratio = Format == 4 ? 1 : IsFloat ? 2 : 4;
  constexpr unsigned Bits = 32 / Ratio;
  const unsigned row = lane / 4;
  const unsigned t = lane % 4;
  unsigned a[4] = {}, b[4] = {};
#pragma unroll
  for (unsigned reg = 0; reg < 4; ++reg) {
    const unsigned aRow = row + 8 * (reg % 2);
    const unsigned aK = 2 * Ratio * (t + 4 * (reg / 2));
    const unsigned bK = Ratio * (t + 4 * reg);
    if constexpr (Format == 4) {
      const unsigned position = tf32_position(tile, aRow, aK / 2);
      a[reg] = packed_value<Format>(a_value(tile, aRow, aK + position, false));
      b[reg] = packed_value<Format>(b_value(tile, bK, row, false));
    } else {
#pragma unroll
      for (unsigned element = 0; element < Ratio; ++element) {
        const unsigned group = aK / 4 + element / 2;
        const unsigned indices = sparse_positions(tile, aRow, group);
        const unsigned pos = (indices >> (2 * (element % 2))) & 3;
        a[reg] |= packed_value<Format>(a_value(tile, aRow, 4 * group + pos, IsUnsigned)) << (Bits * element);
        b[reg] |= packed_value<Format>(b_value(tile, bK + element, row, IsUnsigned)) << (Bits * element);
      }
    }
  }

  unsigned metadata = 0;
  if constexpr (IsFloat) {
    // Populate the unused selector pair with a different valid pattern.
    const unsigned pattern = tile + (t / 2 == Selector ? 0 : 1);
#pragma unroll
    for (unsigned r = 0; r < 2; ++r) {
#pragma unroll
      for (unsigned g = 0; g < 4; ++g) {
        const unsigned pair = 4 * (t % 2) + g;
        const unsigned indices = Format == 4 ? (tf32_position(pattern, row + 8 * r, pair) ? 0xe : 0x4)
                                             : sparse_positions(pattern, row + 8 * r, pair);
        metadata |= indices << (16 * r + 4 * g);
      }
    }
  } else {
#pragma unroll
    for (unsigned g = 0; g < 8; ++g)
      metadata |= sparse_positions(tile, row + 8 * (t % 2), 8 * (t / 2) + g) << (4 * g);
  }

  unsigned d[4];
  if constexpr (IsFloat) {
    float c0 = c_value(tile, row, 2 * t), c1 = c_value(tile, row, 2 * t + 1);
    float c2 = c_value(tile, row + 8, 2 * t), c3 = c_value(tile, row + 8, 2 * t + 1);
#define SP_FLOAT(SHAPE, TYPE) \
    asm volatile("mma.sp.sync.aligned." SHAPE ".row.col.f32." TYPE "." TYPE ".f32 " \
                 "{%0,%1,%2,%3}, {%4,%5,%6,%7}, {%8,%9,%10,%11}, {%0,%1,%2,%3}, %12, %13;" \
                 : "+f"(c0), "+f"(c1), "+f"(c2), "+f"(c3) \
                 : "r"(a[0]), "r"(a[1]), "r"(a[2]), "r"(a[3]), "r"(b[0]), "r"(b[1]), "r"(b[2]), "r"(b[3]), \
                   "r"(metadata), "n"(Selector))
    if constexpr (Format == 0) SP_FLOAT("m16n8k32", "f16");
    else if constexpr (Format == 1) SP_FLOAT("m16n8k32", "bf16");
    else SP_FLOAT("m16n8k16", "tf32");
#undef SP_FLOAT
    d[0] = __float_as_uint(c0);
    d[1] = __float_as_uint(c1);
    d[2] = __float_as_uint(c2);
    d[3] = __float_as_uint(c3);
  } else {
    const int c0 = c_value(tile, row, 2 * t, Sat), c1 = c_value(tile, row, 2 * t + 1, Sat);
    const int c2 = c_value(tile, row + 8, 2 * t, Sat), c3 = c_value(tile, row + 8, 2 * t + 1, Sat);
#define SP_INTEGER(TYPE, SAT) \
    asm volatile("mma.sp.sync.aligned.m16n8k64.row.col" SAT ".s32." TYPE "." TYPE ".s32 " \
                 "{%0,%1,%2,%3}, {%4,%5,%6,%7}, {%8,%9,%10,%11}, {%12,%13,%14,%15}, %16, 0;" \
                 : "=r"(d[0]), "=r"(d[1]), "=r"(d[2]), "=r"(d[3]) \
                 : "r"(a[0]), "r"(a[1]), "r"(a[2]), "r"(a[3]), "r"(b[0]), "r"(b[1]), "r"(b[2]), "r"(b[3]), \
                   "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(metadata))
    if constexpr (Format == 2) {
      if constexpr (Sat) SP_INTEGER("s8", ".satfinite");
      else SP_INTEGER("s8", "");
    } else {
      if constexpr (Sat) SP_INTEGER("u8", ".satfinite");
      else SP_INTEGER("u8", "");
    }
#undef SP_INTEGER
  }
#pragma unroll
  for (unsigned reg = 0; reg < 4; ++reg)
    output[(row + 8 * (reg / 2)) * Cols + 2 * t + reg % 2] = d[reg];
}

__global__ void sparse_mma(unsigned *output) {
  const unsigned tile = blockIdx.x * (Threads / 32) + threadIdx.x / 32;
  const unsigned lane = threadIdx.x % 32;
  unsigned *dst = output + tile * Rows * Cols;
  check_tile<0, 0>(dst + 0 * Results, tile, lane);
  check_tile<0, 1>(dst + 1 * Results, tile, lane);
  check_tile<1, 0>(dst + 2 * Results, tile, lane);
  check_tile<1, 1>(dst + 3 * Results, tile, lane);
  check_tile<2, 0>(dst + 4 * Results, tile, lane);
  check_tile<3, 0>(dst + 5 * Results, tile, lane);
  check_tile<2, 0, true>(dst + 6 * Results, tile, lane);
  check_tile<3, 0, true>(dst + 7 * Results, tile, lane);
  if constexpr (Flavors == 10) {
    check_tile<4, 0>(dst + 8 * Results, tile, lane);
    check_tile<4, 1>(dst + 9 * Results, tile, lane);
  }
}

} // namespace

int main() {
  unsigned result[Flavors * Results] = {};
  unsigned *device;
  ASYNC_CHECK(cudaMalloc(&device, sizeof(result)));
  sparse_mma<<<Blocks, Threads>>>(device);
  ASYNC_CHECK(cudaDeviceSynchronize());
  ASYNC_CHECK(cudaMemcpy(result, device, sizeof(result), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device));

  const char *names[] = {"f16 selector 0", "f16 selector 1", "bf16 selector 0", "bf16 selector 1",
                         "s8 selector 0", "u8 selector 0", "s8 satfinite selector 0", "u8 satfinite selector 0",
                         "tf32 selector 0", "tf32 selector 1"};
  unsigned errors = 0;
  for (unsigned flavor = 0; flavor < Flavors; ++flavor) {
    const bool tf32 = flavor >= 8;
    const bool isFloat = flavor < 4 || tf32, isUnsigned = flavor == 5 || flavor == 7;
    const bool sat = flavor == 6 || flavor == 7;
    const unsigned kSize = tf32 ? 16 : isFloat ? 32 : 64;
    unsigned mismatches = 0;
    for (unsigned tile = 0; tile < Blocks * Threads / 32; ++tile) {
      for (unsigned row = 0; row < Rows; ++row) {
        for (unsigned col = 0; col < Cols; ++col) {
          int64_t expected = c_value(tile, row, col, sat);
          for (unsigned k = 0; k < kSize; ++k) {
            const unsigned indices = sparse_positions(tile, row, k / 4);
            const bool selected = tf32 ? k % 2 == tf32_position(tile, row, k / 2)
                                      : k % 4 == (indices & 3) || k % 4 == (indices >> 2);
            if (selected)
              expected += a_value(tile, row, k, isUnsigned) * b_value(tile, k, col, isUnsigned);
            if (sat && (k + 1) % 32 == 0)
              expected = expected > INT32_MAX ? INT32_MAX : expected < INT32_MIN ? INT32_MIN : expected;
          }
          const unsigned bits = result[flavor * Results + tile * Rows * Cols + row * Cols + col];
          float floating;
          memcpy(&floating, &bits, sizeof(floating));
          const bool mismatch = isFloat ? floating != float(expected) : bits != unsigned(expected);
          if (mismatch && mismatches++ == 0)
            printf("%s first mismatch at tile=%u row=%u col=%u: expected=%d actual=0x%08x\n",
                   names[flavor], tile, row, col, int(expected), bits);
        }
      }
    }
    printf("%s: %u/%u match\n", names[flavor], Results - mismatches, Results);
    errors += mismatches;
  }
  puts(errors ? "FAILED!" : "PASSED!");
  return errors != 0;
}
