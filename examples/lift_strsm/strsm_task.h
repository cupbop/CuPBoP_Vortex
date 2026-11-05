// strsm_task.h: inputs, CPU reference (double) and check rule of the strsm task (experiments/e10s).
// Task: the BLAS routine strsm with side = left, uplo = lower, trans = none, diag = non-unit: solve A X = alpha B for X; X overwrites B.
// Column-major: A(i, j) = A[i + j * lda], B(i, j) = B[i + j * ldb]. A is m x m, B is m x n.
// The strictly upper triangle of A, rows m .. lda-1 of A, rows m .. ldb-1 of B and the words after the last column hold NaN: they are not part of the
// problem. A and these words must stay as they are.
#pragma once
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

namespace trsmt {

// check rule (info/RULES_KO.md): |got - ref| <= ATOL + RTOL * |ref| for every element of X
static const double ATOL = 2e-5, RTOL = 2e-5;
static const size_t GUARD = 64;               // NaN words after the last column of A and of B

struct Shape {
  int m, n, lda, ldb, seed; float alpha;
  size_t na() const { return (size_t)lda * m + GUARD; }
  size_t nb() const { return (size_t)ldb * n + GUARD; }
  std::string tag() const { char t[96]; snprintf(t, sizeof t, "m%dn%dla%dlb%da%gs%d", m, n, lda, ldb, alpha, seed); return t; }
};

static inline uint32_t mix(uint32_t x) { x ^= x >> 16; x *= 0x7feb352dU; x ^= x >> 15; x *= 0x846ca68bU; x ^= x >> 16; return x; }
static inline double u01(uint32_t a, uint32_t b, uint32_t c) { return mix(a * 0x9e3779b1U + mix(b * 0x85ebca77U + mix(c + 0x165667b1U))) / 4294967296.0; }   // [0, 1)
static inline float sentinel() { uint32_t b = 0x7fc0dead; float f; memcpy(&f, &b, 4); return f; }

// A: diagonal +-[1.5, 2.5], strictly lower part [-1, 1] / sqrt(m) (every row depends on all earlier rows, the solve stays well conditioned at every m).
// B: [-1, 1]. Every element differs (integer hash of its position and the seed).
static void make_inputs(const Shape &s, std::vector<float> &A, std::vector<float> &B) {
  A.assign(s.na(), sentinel()); B.assign(s.nb(), sentinel());
  const double sc = 1.0 / std::sqrt((double)s.m);
  for (int j = 0; j < s.m; ++j) {
    double h = u01(j, j, 1000 + s.seed);
    A[(size_t)j + (size_t)j * s.lda] = (float)((h < 0.5 ? -1.0 : 1.0) * (1.5 + 2.0 * std::fabs(h - 0.5)));
    for (int i = j + 1; i < s.m; ++i) A[(size_t)i + (size_t)j * s.lda] = (float)((2.0 * u01(i, j, 2000 + s.seed) - 1.0) * sc);
  }
  for (int j = 0; j < s.n; ++j)
    for (int i = 0; i < s.m; ++i) B[(size_t)i + (size_t)j * s.ldb] = (float)(2.0 * u01(i, j, 3000 + s.seed) - 1.0);
}

// X (m x n, leading dimension m), double arithmetic on the same float inputs
static void reference(const Shape &s, const std::vector<float> &A, const std::vector<float> &B, std::vector<double> &X) {
  X.assign((size_t)s.m * s.n, 0.0);
  for (int c = 0; c < s.n; ++c) {
    double *x = &X[(size_t)c * s.m];
    for (int r = 0; r < s.m; ++r) x[r] = (double)s.alpha * B[(size_t)r + (size_t)c * s.ldb];
    for (int k = 0; k < s.m; ++k) {
      const float *a = &A[(size_t)k * s.lda];
      x[k] /= a[k];
      for (int r = k + 1; r < s.m; ++r) x[r] -= (double)a[r] * x[k];
    }
  }
}

// got: the B buffer (leading dimension ldb); ref: m x n, leading dimension m. Returns the number of elements outside the rule.
static int check(const char *what, const Shape &s, const float *got, const double *ref) {
  int bad = 0; double maxd = 0, maxx = 0;
  for (int c = 0; c < s.n; ++c)
    for (int r = 0; r < s.m; ++r) {
      double g = got[(size_t)r + (size_t)c * s.ldb], x = ref[(size_t)r + (size_t)c * s.m], d = std::fabs(g - x);
      if (!(d <= ATOL + RTOL * std::fabs(x))) { if (bad < 5) printf("  X(%d, %d) = %.8g, reference %.8g\n", r, c, g, x); ++bad; }
      if (d > maxd) maxd = d;
      if (std::fabs(x) > maxx) maxx = std::fabs(x);
    }
  printf("check %s: %d x %d, max |d| %.3g, max |x| %.3g, mismatches %d (atol %g, rtol %g)\n", what, s.m, s.n, maxd, maxx, bad, ATOL, RTOL);
  return bad;
}

// words that must not change: bit compare of [0, n) of got and want; for B only the words outside the m x n part are compared
static int untouched_a(const float *got, const float *want, size_t n) {
  size_t bad = 0; for (size_t i = 0; i < n; ++i) bad += memcmp(&got[i], &want[i], 4) != 0;
  printf("check A unchanged: %zu words differ\n", bad);
  return bad ? 1 : 0;
}
static int untouched_b(const Shape &s, const float *got, const float *want) {
  size_t bad = 0;
  for (size_t i = 0; i < s.nb(); ++i) {
    size_t c = i / s.ldb, r = i % s.ldb; if ((int)c < s.n && (int)r < s.m) continue;
    bad += memcmp(&got[i], &want[i], 4) != 0;
  }
  printf("check B outside the m x n part unchanged: %zu words differ\n", bad);
  return bad ? 1 : 0;
}

}  // namespace trsmt
