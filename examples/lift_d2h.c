// lift_d2h.c: linked into the host program of the lift examples (examples/lift.mk). Wraps cudaMemcpy: every device-to-host copy appends
// "<bytes> <FNV-1a 64 of the bytes>" to lift_d2h.txt, the bit record ci/check_correctness.sh compares with the example's lift_bits.txt. A tolerance
// check alone lets a reduction with a wrong order or a division one ulp off pass; this needs no change in the host programs. LIFT_D2H_SKIP=<k>: leave out the
// k-th copy (backprop reads back a buffer with an element the host never wrote).
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
// LIFT_STRADDLE=<k>: the k-th cudaMalloc lands across the 2^32 address: the lifted 64-bit address arithmetic (two 32-bit halves and a carry) is only observable there.
typedef int (*lift_malloc_fn)(void **, size_t);
int cudaMalloc(void **p, size_t n) {
  static lift_malloc_fn real;
  static int calls;
  if (!real) real = (lift_malloc_fn)dlsym(RTLD_NEXT, "cudaMalloc");
  const char *k = getenv("LIFT_STRADDLE");
  if (k && atoi(k) == ++calls) {
    const uint64_t want = (1ull << 32) - (n / 2 & ~(uint64_t)4095);
    void *at; real(&at, 64);
    uint64_t end = (uint64_t)at + 64;
    while (end + (1ull << 28) < want) { real(&at, (size_t)1 << 28); end = (uint64_t)at + (1ull << 28); }   // the runtime takes int sizes: pads of 256 MB, then the rest
    if (end + 8192 < want) real(&at, (size_t)(want - end - 4096));
    int r = real(p, n);
    const uint64_t a = (uint64_t)*p;
    if (a >= (1ull << 32) || a + n <= (1ull << 32)) printf("\nFAIL: LIFT_STRADDLE: buffer %llx + %zu does not cross 2^32\n", (unsigned long long)a, n);
    else printf("\n[lift] buffer %llx + %zu crosses 2^32\n", (unsigned long long)a, n);
    return r;
  }
  return real(p, n);
}
typedef int (*lift_memcpy_fn)(void *, const void *, size_t, int);
int cudaMemcpy(void *dst, const void *src, size_t n, int kind) {
  static lift_memcpy_fn real;
  if (!real) real = (lift_memcpy_fn)dlsym(RTLD_NEXT, "cudaMemcpy");
  int r = real(dst, src, n, kind);
  static int copies;
  const char *skip = getenv("LIFT_D2H_SKIP");
  if (kind == 2 && !(++copies, skip && atoi(skip) == copies)) {   // cudaMemcpyDeviceToHost
    uint64_t h = 1469598103934665603ull;
    for (size_t i = 0; i < n; ++i) h = (h ^ ((const unsigned char *)dst)[i]) * 1099511628211ull;
    FILE *f = fopen("lift_d2h.txt", "a");
    if (f) { fprintf(f, "%zu %016llx\n", n, (unsigned long long)h); fclose(f); }
  }
  return r;
}
