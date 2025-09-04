#ifndef __KERNEL_IMPL__
#define __KERNEL_IMPL__
#include "cudaStatus.h"
//#include "structures.h"
#include <stdint.h>

extern "C" {
double __nv_exp(double);
double __nv_sqrt(double);
float __nv_sqrtf(float);
float __nv_powif(float, int);
float __nv_logf(float);
float __nv_expf(float);
float __nv_log10f(float);
float __nv_fast_log2f(float);
double __nv_powi(double, int);
float __nv_powf(float, float);
float __nv_fast_powf(float, float);
float __nv_fmodf(float, float);
int __nv_isnanf(float);
int __nv_isinff(float);
float __nv_fabsf(float);
int __nvvm_mul24_i(int, int);
double _ZL3expd(double);
int __nv_ffs(int);
int __nv_popc(int);
float __nvvm_fmin_ftz_f(int, int);
float __nvvm_fmin_f(float, float);
float __nvvm_fmax_ftz_f(float, float);
float __nvvm_fmax_f(float, float);
void __nvvm_membar_gl();
int __nvvm_atomic_load_inc_32(int*, int);
float __nv_rsqrtf(float);
int __nvvm_reflect(int*);
float __nvvm_div_approx_ftz_f(float, float);
float __nvvm_div_approx_f(float, float);
}

int __all_sync(int, int);
int __any_sync(int, int);
int __ballot_sync(int, int);
int __activemask();
int __uniform_sync(int, int);
int __shfl_up_sync(int, int, int, int);
int __shfl_down_sync(int, int, int, int);
int __shfl_xor_sync(int, int, int, int);
int __shfl_sync(int, int, int, int);
float __shfl_sync(int, float, int, int);
float __shfl_up_sync(int, float, int, int);
float __shfl_down_sync(int, float, int, int);
float __shfl_xor_sync(int, float, int, int);
#endif
