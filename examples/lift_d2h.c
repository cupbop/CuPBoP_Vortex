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
