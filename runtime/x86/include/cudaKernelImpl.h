#ifndef __RUNTIME_IMPL__
#define __KERNEL_IMPL__
#include "cudaStatus.h"
#include "structures.h"
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
}
#endif
