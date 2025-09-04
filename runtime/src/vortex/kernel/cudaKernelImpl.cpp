#include "cudaKernelImpl.h"
#include <vx_intrinsics.h>
#include <vx_print.h>
#include <math.h>
#include <atomic>

__attribute__((always_inline)) double __nv_exp(double base) { return exp(base); }
__attribute__((always_inline)) double __nv_sqrt(double v) { return sqrt(v); }
__attribute__((always_inline)) float __nv_sqrtf(float v) { return sqrt(v); }
__attribute__((always_inline)) float __nv_powif(float base, int exp) { return pow(base, exp); }
__attribute__((always_inline)) float __nv_logf(float v) { return logf(v); }
__attribute__((always_inline)) float __nv_expf(float v) { return expf(v); }
__attribute__((always_inline)) float __nv_log10f(float v) { return log10f(v); }
__attribute__((always_inline)) float __nv_fast_log2f(float v) { return log2f(v); }
__attribute__((always_inline)) double __nv_powi(double base, int exp) { return pow(base, exp); }
__attribute__((always_inline)) float __nv_powf(float base, float exp) { return pow(base, exp); }
__attribute__((always_inline)) float __nv_fast_powf(float base, float exp) { return pow(base, exp); }
__attribute__((always_inline)) float __nv_fmodf(float x, float y) { return fmod(x, y); }
__attribute__((always_inline)) int __nv_isnanf(float v) { return isnan(v); }
__attribute__((always_inline)) int __nv_isinff(float v) { return isinf(v); }
__attribute__((always_inline)) float __nv_fabsf(float v) { return fabs(v); }
__attribute__((always_inline)) int __nvvm_mul24_i(int a, int b) { return a * b; }
__attribute__((always_inline)) double _ZL3expd(double base) { return exp(base); }
__attribute__((always_inline)) int __nv_ffs(int x) { return __builtin_ffs(x); }
__attribute__((always_inline)) int __nv_popc(int x) { return __builtin_popcount(x); }
__attribute__((always_inline)) float __nvvm_fmin_ftz_f(int a, int b) { return __builtin_fmin(a, b); }
__attribute__((always_inline)) float __nvvm_fmin_f(float a, float b) { return __builtin_fmin(a, b); }
__attribute__((always_inline)) float __nvvm_fmax_ftz_f(float a, float b) { return __builtin_fmax(a, b); }
__attribute__((always_inline)) float __nvvm_fmax_f(float a, float b) { return __builtin_fmax(a, b); }
__attribute__((always_inline)) void __nvvm_membar_gl() { vx_fence(); }
__attribute__((always_inline)) int __nvvm_atomic_load_inc_32(int *addr, int val) { return __atomic_fetch_add(addr, val, __ATOMIC_SEQ_CST); }
__attribute__((always_inline)) float __nv_rsqrtf(float f) { return 1.0f / sqrtf(f); }
__attribute__((always_inline)) int __nvvm_reflect(int *) { return 0; }
__attribute__((always_inline)) float __nvvm_div_approx_ftz_f(float a, float b) { return a / b; }
__attribute__((always_inline)) float __nvvm_div_approx_f(float a, float b) { return a / b; }


__attribute__((always_inline))
bool __all_sync(int mask, bool predicate) {
    int in_mask = ((vx_active_threads() & mask) != 0);
    int effective = in_mask ? predicate : 1;
    return vx_vote_all(effective);
}

__attribute__((always_inline))
bool __any_sync(int mask, bool predicate) {
    int in_mask = ((vx_active_threads() & mask) != 0);
    int effective = in_mask ? predicate : 0;
    return vx_vote_any(effective);
}

__attribute__((always_inline))
int __ballot_sync(int mask, bool predicate) {
    int in_mask = ((vx_active_threads() & mask) != 0);
    int bits = (int)vx_vote_ballot(in_mask ? predicate : 0);
    return bits & mask;
}

__attribute__((always_inline))
bool __uniform_sync(int mask, bool predicate) {
    auto b = __ballot_sync(mask, predicate);
    return (b == 0u) || (b == mask);
}

__attribute__((always_inline))
int __activemask(void) {
    return (int)vx_active_threads();
}

__attribute__((always_inline))
int __shfl_sync(int mem_mask, int var, int srcLane, int c) {
    int mask = ~c;
    return vx_shfl_idx((size_t)var, srcLane, c, mask);
}

__attribute__((always_inline))
float __shfl_sync(int mem_mask, float var, int srcLane, int c) {
    int mask = ~c;
    int vali = *reinterpret_cast<int*>(&var);
    int ri = vx_shfl_idx(vali, srcLane, c, mask);
    return *reinterpret_cast<float*>(&ri);
}

__attribute__((always_inline))
int __shfl_up_sync(int mem_mask, int var, int delta, int c) {
    int mask = ~c;
    return vx_shfl_up((size_t)var, delta, c, mask);
}

__attribute__((always_inline))
float __shfl_up_sync(int mem_mask, float var, int delta, int c) {
    int mask = ~c;
    int vali = *reinterpret_cast<int*>(&var);
    int ri = vx_shfl_up(vali, delta, c, mask);
    return *reinterpret_cast<float*>(&ri);
}

__attribute__((always_inline))
int __shfl_down_sync(int mem_mask, int var, int delta, int c) {
    int mask = ~c;
    return vx_shfl_down((size_t)var, delta, c, mask);
}

__attribute__((always_inline))
float __shfl_down_sync(int mem_mask, float var, int delta, int c) {
    int mask = ~c;
    int vali = *reinterpret_cast<int*>(&var);
    int ri = vx_shfl_down(vali, delta, c, mask);
    return *reinterpret_cast<float*>(&ri);
}

__attribute__((always_inline))
int __shfl_xor_sync(int mem_mask, int var, int laneMask, int c) {
    int mask = ~c;
    return vx_shfl_bfly((size_t)var, laneMask, c, mask);
}

__attribute__((always_inline))
float __shfl_xor_sync(int mem_mask, float var, int laneMask, int c) {
    int mask = ~c;
    int vali = *reinterpret_cast<int*>(&var);
    int ri = vx_shfl_bfly(vali, laneMask, c, mask);
    return *reinterpret_cast<float*>(&ri);
}