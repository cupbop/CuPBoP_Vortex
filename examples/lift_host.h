// lift_host.h: host side of the lift examples without a CUDA source: launch of a lifted kernel by name, inputs, verdict. The device code is the IR file of the
// example (examples/lift.mk); a __global__ kernel in the host file would be dropped.
// Launch ABI of lifted kernels (translator pass_wide_kernel_args_by_slot): the parameters are named arg_<constant bank offset>; in signature order every parameter
// "<offset>:<bytes>" starts a new 8-byte launch slot and takes ceil(bytes / 8) slots, filled from the parameter bank image at that offset.
#pragma once
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <cuda_runtime.h>

extern "C" cudaError_t cudaLaunchKernel_vortex(const char *func, dim3 gridDim, dim3 blockDim, void **args, size_t sharedMem, cudaStream_t stream, const int num_args);
// Called through a pointer: hostTranslator rewrites every direct call whose callee name starts with "cudaLaunchKernel" and expects a kernel stub as first operand.
typedef cudaError_t (*lift_launch_fn)(const char *, dim3, dim3, void **, size_t, cudaStream_t, const int);
static lift_launch_fn volatile lift_vx_launch = &cudaLaunchKernel_vortex;
#define LIFT_CBANK 4096   // parameter bank image, c[0x0][0x0 .. 0xfff]
#define LIFT_CHECK(x) do { cudaError_t e_ = (x); if (e_ != cudaSuccess) { printf("FAIL: CUDA error %d at %s:%d\n", (int)e_, __FILE__, __LINE__); exit(1); } } while (0)
template <class T> static inline void lift_put(uint8_t *cb, size_t off, T v) { memcpy(cb + off, &v, sizeof(T)); }

// dyn_smem: dynamic shared bytes; CuPBoP's CTA area = the IR's @shared_mem + this. Env LIFT_DYN_SMEM replaces it (a row whose input has the whole CTA area in
// @shared_mem after p2c-fold: 0).
static void lift_launch(const char *name, dim3 grid, dim3 block, size_t dyn_smem, const char *params, const uint8_t *cb) {
  auto strip = [](const std::string &x) {   // cudaLaunchKernel_vortex's name match; it runs the LAST kernel on no match
    size_t i = (x.size() > 2 && x[0] == '_' && x[1] == 'Z') ? 2 : 0;
    while (i < x.size() && (x[i] == 'L' || (x[i] >= '0' && x[i] <= '9'))) ++i;
    return x.substr(i);
  };
  { std::ifstream lf("lookup.txt"); std::string idx, nm, rest; bool hit = false;
    while (lf >> idx >> nm) { std::getline(lf, rest); if (strip(nm) == strip(name)) hit = true; }
    if (!hit) { printf("FAIL: kernel %s not in lookup.txt\n", name); exit(1); } }
  if (const char *e = getenv("LIFT_DYN_SMEM")) dyn_smem = (size_t)atol(e);
  std::vector<uint64_t> slots; std::istringstream is(params); std::string tok;
  while (is >> tok) {
    size_t c = tok.find(':'), off = std::stoul(tok.substr(0, c)), n = std::stoul(tok.substr(c + 1)), s0 = slots.size();
    if (off + n > LIFT_CBANK) { printf("FAIL: parameter %s outside the bank image\n", tok.c_str()); exit(1); }
    slots.resize(s0 + (n + 7) / 8, 0); memcpy(&slots[s0], cb + off, n);
  }
  std::vector<void *> argv(slots.size());
  for (size_t i = 0; i < slots.size(); ++i) argv[i] = &slots[i];
  printf("[lift] launch %.60s grid=(%u,%u,%u) block=(%u,%u,%u) slots=%zu dyn_smem=%zu\n", name, grid.x, grid.y, grid.z, block.x, block.y, block.z, slots.size(), dyn_smem);
  cudaError_t r = lift_vx_launch(name, grid, block, argv.data(), dyn_smem, 0, (int)slots.size());
  if (r != cudaSuccess) { printf("FAIL: cudaLaunchKernel_vortex(%s) -> %d\n", name, (int)r); exit(1); }
  LIFT_CHECK(cudaDeviceSynchronize());
}
static inline uint32_t lift_hash(uint32_t i, uint32_t which) {
  uint32_t x = i * 2654435761u ^ (which * 0x9E3779B9u + 0x7f4a7c15u);
  x ^= x >> 15; x *= 0x2c1b3c6du; x ^= x >> 12; x *= 0x297a2d39u; x ^= x >> 15;
  return x;
}
static inline float lift_uni(uint32_t i, uint32_t which) { return (float)(lift_hash(i, which) >> 8) * (2.0f / 16777215.0f) - 1.0f; }   // uniform(-1, 1)
static inline float lift_k64(uint32_t i, uint32_t which) { return (float)((int)((lift_hash(i, which) >> 8) % 64u) - 32) / 64.f; }       // k / 64, |k| <= 32: exact f16, exact f32 sums
static void *lift_dev(const void *h, size_t n) { void *d; LIFT_CHECK(cudaMalloc(&d, n)); if (h) LIFT_CHECK(cudaMemcpy(d, h, n, cudaMemcpyHostToDevice)); return d; }
static std::vector<uint8_t> lift_file(const char *p) {
  std::ifstream f(p, std::ios::binary); if (!f) { printf("FAIL: no file %s\n", p); exit(1); }
  return std::vector<uint8_t>((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}
static int lift_finish(long bad) { if (bad == 0) { printf("PASSED\n"); return 0; } printf("FAIL: %ld mismatches\n", bad); return 1; }
static inline float lift_h2f(uint16_t h) {   // IEEE half bits -> float
  uint32_t s = (h & 0x8000u) << 16, e = (h >> 10) & 0x1f, m = h & 0x3ff, o;
  if (e == 0) { if (m == 0) o = s; else { int k = -1; do { ++k; m <<= 1; } while (!(m & 0x400)); m &= 0x3ff; o = s | ((127 - 15 - k) << 23) | (m << 13); } }
  else if (e == 31) o = s | 0x7f800000u | (m << 13);
  else o = s | ((e - 15 + 127) << 23) | (m << 13);
  float f; memcpy(&f, &o, 4); return f;
}
static inline uint16_t lift_f2h(float v) {   // float -> half bits, round to nearest even
  uint32_t x; memcpy(&x, &v, 4);
  uint32_t s = (x >> 16) & 0x8000; int e = (int)((x >> 23) & 0xff) - 127 + 15; uint32_t m = x & 0x7fffff;
  if (e <= 0) { if (e < -10) return (uint16_t)s; m |= 0x800000; uint32_t sh = 14 - e, r = m >> sh, rem = m & ((1u << sh) - 1), half = 1u << (sh - 1);
    if (rem > half || (rem == half && (r & 1))) ++r; return (uint16_t)(s | r); }
  if (e >= 31) return (uint16_t)(s | 0x7c00);
  uint16_t o = (uint16_t)(s | (e << 10) | (m >> 13)); uint32_t rem = m & 0x1fff;
  if (rem > 0x1000 || (rem == 0x1000 && (o & 1))) ++o;
  return o;
}
