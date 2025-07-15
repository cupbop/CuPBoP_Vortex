#include "cudaKernelImpl.h"
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
