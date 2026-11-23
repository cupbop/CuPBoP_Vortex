#include "cupbop_reduce.h"

// dtype uses CUtensorMapDataType, so tensor and linear bulk reductions share
// the same element operations. CAS preserves concurrent element updates.
template <class W, class S> static inline W reduce_integer(W dst, W src, unsigned op, bool sign) {
  switch (op) {
  case ReduceAdd:
    return dst + src;
  case ReduceMin:
    return (sign ? S(dst) < S(src) : dst < src) ? dst : src;
  case ReduceMax:
    return (sign ? S(dst) > S(src) : dst > src) ? dst : src;
  case ReduceInc:
    return dst >= src ? 0 : dst + 1;
  case ReduceDec:
    return (!dst || dst > src) ? src : dst - 1;
  case ReduceAnd:
    return dst & src;
  case ReduceOr:
    return dst | src;
  default:
    return dst ^ src;
  }
}
static inline uint16_t reduce_half(uint16_t a, uint16_t b, unsigned dtype, unsigned op) {
  float x, y;
  if (dtype == 6) {
    x = float(__builtin_bit_cast(_Float16, a));
    y = float(__builtin_bit_cast(_Float16, b));
  } else {
    x = __builtin_bit_cast(float, uint32_t(a) << 16);
    y = __builtin_bit_cast(float, uint32_t(b) << 16);
  }
  float z = op == ReduceAdd ? x + y : op == ReduceMin ? __builtin_fminf(x, y) : __builtin_fmaxf(x, y);
  if (dtype == 6)
    return __builtin_bit_cast(uint16_t, (_Float16)z);
  uint32_t bits = __builtin_bit_cast(uint32_t, z);
  if ((bits & 0x7fffffffu) > 0x7f800000u)
    return uint16_t(bits >> 16) | 64;
  return (bits + 0x7fffu + ((bits >> 16) & 1)) >> 16;
}
static inline void cupbop_reduce_element(void *dest, const void *source, unsigned dtype, unsigned op) {
  if (dtype == 4 || dtype == 5 || dtype == 8) {
    auto *ptr = static_cast<uint64_t *>(dest);
    uint64_t src = *static_cast<const uint64_t *>(source);
    uint64_t old = __atomic_load_n(ptr, __ATOMIC_RELAXED), next;
    do {
      next = dtype == 8
                 ? __builtin_bit_cast(uint64_t, __builtin_bit_cast(double, old) + __builtin_bit_cast(double, src))
                 : reduce_integer<uint64_t, int64_t>(old, src, op, dtype == 5);
    } while (!__atomic_compare_exchange_n(ptr, &old, next, false, __ATOMIC_RELAXED, __ATOMIC_RELAXED));
    return;
  }
  auto *ptr = reinterpret_cast<uint32_t *>(uintptr_t(dest) & ~uintptr_t(3));
  uint32_t old = __atomic_load_n(ptr, __ATOMIC_RELAXED), next;
  if (dtype == 6 || dtype == 9) {
    unsigned shift = (uintptr_t(dest) & 2) * 8;
    auto src = *static_cast<const uint16_t *>(source);
    do {
      uint32_t val = reduce_half(old >> shift, src, dtype, op);
      next = (old & ~(0xffffu << shift)) | (val << shift);
    } while (!__atomic_compare_exchange_n(ptr, &old, next, false, __ATOMIC_RELAXED, __ATOMIC_RELAXED));
  } else {
    uint32_t src = *static_cast<const uint32_t *>(source);
    do {
      next = dtype == 7 ? __builtin_bit_cast(uint32_t, __builtin_bit_cast(float, old) + __builtin_bit_cast(float, src))
                        : reduce_integer<uint32_t, int32_t>(old, src, op, dtype == 3);
    } while (!__atomic_compare_exchange_n(ptr, &old, next, false, __ATOMIC_RELAXED, __ATOMIC_RELAXED));
  }
}
extern "C" void __cupbop_bulk_reduce(void *dst, const void *src, unsigned bytes, unsigned dtype, unsigned op) {
  if ((bytes | uintptr_t(dst) | uintptr_t(src)) & 15)
    cupbop_async_fail("unaligned bulk reduction", uint32_t(uintptr_t(dst)), bytes);
  unsigned width = dtype == 6 || dtype == 9 ? 2 : dtype == 4 || dtype == 5 || dtype == 8 ? 8 : 4;
  for (unsigned i = 0; i < bytes; i += width)
    cupbop_reduce_element(static_cast<char *>(dst) + i, static_cast<const char *>(src) + i, dtype, op);
}
