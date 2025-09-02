#include "cudaKernelImpl.h"
#include <vx_intrinsics.h>
#include <math.h>
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

__attribute__((always_inline))
int __all_sync(unsigned mask, int predicate) {
    int in_mask = ((vx_active_threads() & mask) != 0);
    int effective = in_mask ? predicate : 1;
    return vx_vote_all(effective);
}

__attribute__((always_inline))
int __any_sync(unsigned mask, int predicate) {
    int in_mask = ((vx_active_threads() & mask) != 0);
    int effective = in_mask ? predicate : 0;
    return vx_vote_any(effective);
}

__attribute__((always_inline))
unsigned __ballot_sync(unsigned mask, int predicate) {
    int in_mask = ((vx_active_threads() & mask) != 0);
    unsigned bits = (unsigned)vx_vote_ballot(in_mask ? predicate : 0);
    return bits & mask;
}

__attribute__((always_inline))
unsigned __activemask(void) {
    return (unsigned)vx_active_threads();
}

__attribute__((always_inline))
int __uniform_sync(unsigned mask, int predicate) {
    int in_mask = ((vx_active_threads() & mask) != 0);
    unsigned bits_true = (unsigned)vx_vote_ballot(in_mask ? predicate : 0);
    unsigned bits_part = (unsigned)vx_vote_ballot(in_mask ? 1 : 0);
    return (bits_true == 0u) || (bits_true == bits_part);
}

__attribute__((always_inline))
int __shfl_up_sync(unsigned mask, int var, unsigned int delta, int width) {
    return vx_shfl_up((size_t)var, delta, width, mask);
}

__attribute__((always_inline))
int __shfl_down_sync(unsigned mask, int var, unsigned int delta, int width) {
    return vx_shfl_down((size_t)var, delta, width, mask);
}

__attribute__((always_inline))
int __shfl_xor_sync(unsigned mask, int var, int laneMask, int width) {
    return vx_shfl_bfly((size_t)var, laneMask, width, mask);
}

__attribute__((always_inline))
int __shfl_sync(unsigned mask, int var, int srcLane, int width) {
    return vx_shfl_idx((size_t)var, srcLane, width, mask);
}

__attribute__((always_inline))
float __shfl_sync(unsigned mask, float var, int srcLane, int width) {
    int vali = *reinterpret_cast<int*>(&var);
    int ri = vx_shfl_idx(vali, srcLane, width, mask);
    return *reinterpret_cast<float*>(&ri);
}
