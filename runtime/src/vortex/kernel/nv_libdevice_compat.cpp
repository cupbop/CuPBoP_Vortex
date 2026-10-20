// Generated for the Vortex 3.0 build (ci/gen_nv_compat.py idea; kept checked in).
// With `-nocudalib` the CUDA device bitcode keeps libdevice calls (__nv_*) as external symbols;
// kernelTranslator maps ~20 of them to libm and cudaKernelImpl.cpp defines a few, this file supplies
// the rest from newlib libm / builtins. Prototypes follow clang 20 __clang_cuda_libdevice_declares.h.
// Weak so that cudaKernelImpl.cpp / translator-provided definitions take precedence.
// Rounding functions go through a volatile function pointer: at -O3 clang folds floorf() & co. into
// llvm.floor/ceil/rint/round/trunc, and the Vortex LLVM (tools-v3.0.1) backend aborts on those with
// "unimplemented divergent codegen"; the indirect call keeps newlib's implementation.
#include <math.h>
#include <stdint.h>
#define NV_COMPAT extern "C" __attribute__((weak))

NV_COMPAT int __nv_abs(int a) { return a < 0 ? -a : a; }
NV_COMPAT double __nv_acos(double a) { return acos(a); }
NV_COMPAT float __nv_acosf(float a) { return acosf(a); }
NV_COMPAT double __nv_acosh(double a) { return acosh(a); }
NV_COMPAT float __nv_acoshf(float a) { return acoshf(a); }
NV_COMPAT double __nv_asin(double a) { return asin(a); }
NV_COMPAT float __nv_asinf(float a) { return asinf(a); }
NV_COMPAT double __nv_asinh(double a) { return asinh(a); }
NV_COMPAT float __nv_asinhf(float a) { return asinhf(a); }
NV_COMPAT double __nv_atan2(double a, double b) { return atan2(a, b); }
NV_COMPAT float __nv_atan2f(float a, float b) { return atan2f(a, b); }
NV_COMPAT double __nv_atan(double a) { return atan(a); }
NV_COMPAT float __nv_atanf(float a) { return atanf(a); }
NV_COMPAT double __nv_atanh(double a) { return atanh(a); }
NV_COMPAT float __nv_atanhf(float a) { return atanhf(a); }
NV_COMPAT int __nv_brev(int a) { return __builtin_bitreverse32(a); }
NV_COMPAT long long __nv_brevll(long long a) { return __builtin_bitreverse64(a); }
NV_COMPAT int __nv_byte_perm(int a, int b, int c) { unsigned r = 0; for (int i = 0; i < 4; ++i) { unsigned s = (c >> (4 * i)) & 7; unsigned v = s < 4 ? (a >> (8 * s)) & 0xff : (b >> (8 * (s - 4))) & 0xff; r |= v << (8 * i); } return r; }
NV_COMPAT double __nv_cbrt(double a) { return cbrt(a); }
NV_COMPAT float __nv_cbrtf(float a) { return cbrtf(a); }
static double (*volatile __nv_p_ceil)(double) = ceil;  // indirect: keep the libm call, see header note
NV_COMPAT double __nv_ceil(double a) { return __nv_p_ceil(a); }
static float (*volatile __nv_p_ceilf)(float) = ceilf;  // indirect: keep the libm call, see header note
NV_COMPAT float __nv_ceilf(float a) { return __nv_p_ceilf(a); }
NV_COMPAT int __nv_clz(int a) { return a ? __builtin_clz(a) : 32; }
NV_COMPAT int __nv_clzll(long long a) { return a ? __builtin_clzll(a) : 64; }
NV_COMPAT double __nv_copysign(double a, double b) { return copysign(a, b); }
NV_COMPAT float __nv_copysignf(float a, float b) { return copysignf(a, b); }
NV_COMPAT double __nv_cos(double a) { return cos(a); }
NV_COMPAT float __nv_cosf(float a) { return cosf(a); }
NV_COMPAT double __nv_cosh(double a) { return cosh(a); }
NV_COMPAT float __nv_coshf(float a) { return coshf(a); }
NV_COMPAT double __nv_cospi(double a) { return cos(3.14159265358979323846 * a); }
NV_COMPAT float __nv_cospif(float a) { return cosf(3.14159265358979323846f * a); }
NV_COMPAT double __nv_dadd_rd(double a, double b) { return a + b; }
NV_COMPAT double __nv_dadd_rn(double a, double b) { return a + b; }
NV_COMPAT double __nv_dadd_ru(double a, double b) { return a + b; }
NV_COMPAT double __nv_dadd_rz(double a, double b) { return a + b; }
NV_COMPAT double __nv_ddiv_rd(double a, double b) { return a / b; }
NV_COMPAT double __nv_ddiv_rn(double a, double b) { return a / b; }
NV_COMPAT double __nv_ddiv_ru(double a, double b) { return a / b; }
NV_COMPAT double __nv_ddiv_rz(double a, double b) { return a / b; }
NV_COMPAT double __nv_dmul_rd(double a, double b) { return a * b; }
NV_COMPAT double __nv_dmul_rn(double a, double b) { return a * b; }
NV_COMPAT double __nv_dmul_ru(double a, double b) { return a * b; }
NV_COMPAT double __nv_dmul_rz(double a, double b) { return a * b; }
NV_COMPAT float __nv_double2float_rd(double a) { return (float)a; }
NV_COMPAT float __nv_double2float_rn(double a) { return (float)a; }
NV_COMPAT float __nv_double2float_ru(double a) { return (float)a; }
NV_COMPAT float __nv_double2float_rz(double a) { return (float)a; }
NV_COMPAT int __nv_double2hiint(double a) { long long r; __builtin_memcpy(&r, &a, 8); return (int)(r >> 32); }
NV_COMPAT int __nv_double2int_rd(double a) { return (int)floor(a); }
NV_COMPAT int __nv_double2int_rn(double a) { return (int)rint(a); }
NV_COMPAT int __nv_double2int_ru(double a) { return (int)ceil(a); }
NV_COMPAT int __nv_double2int_rz(double a) { return (int)trunc(a); }
NV_COMPAT long long __nv_double2ll_rd(double a) { return (long long)floor(a); }
NV_COMPAT long long __nv_double2ll_rn(double a) { return (long long)rint(a); }
NV_COMPAT long long __nv_double2ll_ru(double a) { return (long long)ceil(a); }
NV_COMPAT long long __nv_double2ll_rz(double a) { return (long long)trunc(a); }
NV_COMPAT int __nv_double2loint(double a) { long long r; __builtin_memcpy(&r, &a, 8); return (int)r; }
NV_COMPAT unsigned int __nv_double2uint_rd(double a) { return (unsigned)floor(a); }
NV_COMPAT unsigned int __nv_double2uint_rn(double a) { return (unsigned)rint(a); }
NV_COMPAT unsigned int __nv_double2uint_ru(double a) { return (unsigned)ceil(a); }
NV_COMPAT unsigned int __nv_double2uint_rz(double a) { return (unsigned)trunc(a); }
NV_COMPAT unsigned long long __nv_double2ull_rd(double a) { return (unsigned long long)floor(a); }
NV_COMPAT unsigned long long __nv_double2ull_rn(double a) { return (unsigned long long)rint(a); }
NV_COMPAT unsigned long long __nv_double2ull_ru(double a) { return (unsigned long long)ceil(a); }
NV_COMPAT unsigned long long __nv_double2ull_rz(double a) { return (unsigned long long)trunc(a); }
NV_COMPAT unsigned long long __nv_double_as_longlong(double a) { long long r; __builtin_memcpy(&r, &a, 8); return r; }
NV_COMPAT double __nv_drcp_rd(double a) { return 1.0 / a; }
NV_COMPAT double __nv_drcp_rn(double a) { return 1.0 / a; }
NV_COMPAT double __nv_drcp_ru(double a) { return 1.0 / a; }
NV_COMPAT double __nv_drcp_rz(double a) { return 1.0 / a; }
NV_COMPAT double __nv_dsqrt_rd(double a) { return sqrt(a); }
NV_COMPAT double __nv_dsqrt_rn(double a) { return sqrt(a); }
NV_COMPAT double __nv_dsqrt_ru(double a) { return sqrt(a); }
NV_COMPAT double __nv_dsqrt_rz(double a) { return sqrt(a); }
NV_COMPAT double __nv_dsub_rd(double a, double b) { return a - b; }
NV_COMPAT double __nv_dsub_rn(double a, double b) { return a - b; }
NV_COMPAT double __nv_dsub_ru(double a, double b) { return a - b; }
NV_COMPAT double __nv_dsub_rz(double a, double b) { return a - b; }
NV_COMPAT double __nv_erfc(double a) { return erfc(a); }
NV_COMPAT double __nv_erf(double a) { return erf(a); }
NV_COMPAT float __nv_erff(float a) { return erff(a); }
NV_COMPAT double __nv_exp10(double a) { return pow(10.0, a); }
NV_COMPAT float __nv_exp10f(float a) { return powf(10.0f, a); }
NV_COMPAT double __nv_exp2(double a) { return exp2(a); }
NV_COMPAT float __nv_exp2f(float a) { return exp2f(a); }
NV_COMPAT double __nv_expm1(double a) { return expm1(a); }
NV_COMPAT float __nv_expm1f(float a) { return expm1f(a); }
NV_COMPAT double __nv_fabs(double a) { return fabs(a); }
NV_COMPAT float __nv_fadd_rd(float a, float b) { return a + b; }
NV_COMPAT float __nv_fadd_rn(float a, float b) { return a + b; }
NV_COMPAT float __nv_fadd_ru(float a, float b) { return a + b; }
NV_COMPAT float __nv_fadd_rz(float a, float b) { return a + b; }
NV_COMPAT float __nv_fast_cosf(float a) { return cosf(a); }
NV_COMPAT float __nv_fast_exp10f(float a) { return powf(10.0f, a); }
NV_COMPAT float __nv_fast_expf(float a) { return expf(a); }
NV_COMPAT float __nv_fast_fdividef(float a, float b) { return a / b; }
NV_COMPAT float __nv_fast_log10f(float a) { return log10f(a); }
NV_COMPAT float __nv_fast_logf(float a) { return logf(a); }
NV_COMPAT void __nv_fast_sincosf(float a, float * b, float * c) { *b = sinf(a); *c = cosf(a); }
NV_COMPAT float __nv_fast_sinf(float a) { return sinf(a); }
NV_COMPAT float __nv_fast_tanf(float a) { return tanf(a); }
NV_COMPAT double __nv_fdim(double a, double b) { return fdim(a, b); }
NV_COMPAT float __nv_fdimf(float a, float b) { return fdimf(a, b); }
NV_COMPAT float __nv_fdiv_rd(float a, float b) { return a / b; }
NV_COMPAT float __nv_fdiv_rn(float a, float b) { return a / b; }
NV_COMPAT float __nv_fdiv_ru(float a, float b) { return a / b; }
NV_COMPAT float __nv_fdiv_rz(float a, float b) { return a / b; }
NV_COMPAT int __nv_ffsll(long long a) { return a ? __builtin_ctzll(a) + 1 : 0; }
NV_COMPAT int __nv_finitef(float a) { return __builtin_isfinite(a); }
NV_COMPAT int __nv_float2int_rd(float a) { return (int)floorf(a); }
NV_COMPAT int __nv_float2int_rn(float a) { return (int)rintf(a); }
NV_COMPAT int __nv_float2int_ru(float a) { return (int)ceilf(a); }
NV_COMPAT int __nv_float2int_rz(float a) { return (int)truncf(a); }
NV_COMPAT long long __nv_float2ll_rd(float a) { return (long long)floorf(a); }
NV_COMPAT long long __nv_float2ll_rn(float a) { return (long long)rintf(a); }
NV_COMPAT long long __nv_float2ll_ru(float a) { return (long long)ceilf(a); }
NV_COMPAT long long __nv_float2ll_rz(float a) { return (long long)truncf(a); }
NV_COMPAT unsigned int __nv_float2uint_rd(float a) { return (unsigned)floorf(a); }
NV_COMPAT unsigned int __nv_float2uint_rn(float a) { return (unsigned)rintf(a); }
NV_COMPAT unsigned int __nv_float2uint_ru(float a) { return (unsigned)ceilf(a); }
NV_COMPAT unsigned int __nv_float2uint_rz(float a) { return (unsigned)truncf(a); }
NV_COMPAT unsigned long long __nv_float2ull_rd(float a) { return (unsigned long long)floorf(a); }
NV_COMPAT unsigned long long __nv_float2ull_rn(float a) { return (unsigned long long)rintf(a); }
NV_COMPAT unsigned long long __nv_float2ull_ru(float a) { return (unsigned long long)ceilf(a); }
NV_COMPAT unsigned long long __nv_float2ull_rz(float a) { return (unsigned long long)truncf(a); }
NV_COMPAT int __nv_float_as_int(float a) { int r; __builtin_memcpy(&r, &a, 4); return r; }
NV_COMPAT unsigned int __nv_float_as_uint(float a) { unsigned r; __builtin_memcpy(&r, &a, 4); return r; }
static double (*volatile __nv_p_floor)(double) = floor;  // indirect: keep the libm call, see header note
NV_COMPAT double __nv_floor(double a) { return __nv_p_floor(a); }
static float (*volatile __nv_p_floorf)(float) = floorf;  // indirect: keep the libm call, see header note
NV_COMPAT float __nv_floorf(float a) { return __nv_p_floorf(a); }
NV_COMPAT double __nv_fma(double a, double b, double c) { return fma(a, b, c); }
NV_COMPAT float __nv_fmaf(float a, float b, float c) { return fmaf(a, b, c); }
NV_COMPAT float __nv_fmaf_rd(float a, float b, float c) { return fmaf(a, b, c); }
NV_COMPAT float __nv_fmaf_rn(float a, float b, float c) { return fmaf(a, b, c); }
NV_COMPAT float __nv_fmaf_ru(float a, float b, float c) { return fmaf(a, b, c); }
NV_COMPAT float __nv_fmaf_rz(float a, float b, float c) { return fmaf(a, b, c); }
NV_COMPAT double __nv_fma_rd(double a, double b, double c) { return fma(a, b, c); }
NV_COMPAT double __nv_fma_rn(double a, double b, double c) { return fma(a, b, c); }
NV_COMPAT double __nv_fma_ru(double a, double b, double c) { return fma(a, b, c); }
NV_COMPAT double __nv_fma_rz(double a, double b, double c) { return fma(a, b, c); }
NV_COMPAT double __nv_fmax(double a, double b) { return fmax(a, b); }
NV_COMPAT float __nv_fmaxf(float a, float b) { return fmaxf(a, b); }
NV_COMPAT double __nv_fmin(double a, double b) { return fmin(a, b); }
NV_COMPAT float __nv_fminf(float a, float b) { return fminf(a, b); }
NV_COMPAT double __nv_fmod(double a, double b) { return fmod(a, b); }
NV_COMPAT float __nv_fmul_rd(float a, float b) { return a * b; }
NV_COMPAT float __nv_fmul_rn(float a, float b) { return a * b; }
NV_COMPAT float __nv_fmul_ru(float a, float b) { return a * b; }
NV_COMPAT float __nv_fmul_rz(float a, float b) { return a * b; }
NV_COMPAT float __nv_frcp_rd(float a) { return 1.0f / a; }
NV_COMPAT float __nv_frcp_rn(float a) { return 1.0f / a; }
NV_COMPAT float __nv_frcp_ru(float a) { return 1.0f / a; }
NV_COMPAT float __nv_frcp_rz(float a) { return 1.0f / a; }
NV_COMPAT double __nv_frexp(double a, int * b) { return frexp(a, b); }
NV_COMPAT float __nv_frexpf(float a, int * b) { return frexpf(a, b); }
NV_COMPAT float __nv_fsqrt_rd(float a) { return sqrtf(a); }
NV_COMPAT float __nv_fsqrt_rn(float a) { return sqrtf(a); }
NV_COMPAT float __nv_fsqrt_ru(float a) { return sqrtf(a); }
NV_COMPAT float __nv_fsqrt_rz(float a) { return sqrtf(a); }
NV_COMPAT float __nv_fsub_rd(float a, float b) { return a - b; }
NV_COMPAT float __nv_fsub_rn(float a, float b) { return a - b; }
NV_COMPAT float __nv_fsub_ru(float a, float b) { return a - b; }
NV_COMPAT float __nv_fsub_rz(float a, float b) { return a - b; }
NV_COMPAT int __nv_hadd(int a, int b) { return (a >> 1) + (b >> 1) + (a & b & 1); }
NV_COMPAT double __nv_hiloint2double(int a, int b) { long long r = ((long long)a << 32) | (unsigned)b; double d; __builtin_memcpy(&d, &r, 8); return d; }
NV_COMPAT double __nv_hypot(double a, double b) { return hypot(a, b); }
NV_COMPAT float __nv_hypotf(float a, float b) { return hypotf(a, b); }
NV_COMPAT int __nv_ilogb(double a) { return ilogb(a); }
NV_COMPAT int __nv_ilogbf(float a) { return ilogbf(a); }
NV_COMPAT double __nv_int2double_rn(int a) { return (double)a; }
NV_COMPAT float __nv_int2float_rd(int a) { return (float)a; }
NV_COMPAT float __nv_int2float_rn(int a) { return (float)a; }
NV_COMPAT float __nv_int2float_ru(int a) { return (float)a; }
NV_COMPAT float __nv_int2float_rz(int a) { return (float)a; }
NV_COMPAT float __nv_int_as_float(int a) { float r; __builtin_memcpy(&r, &a, 4); return r; }
NV_COMPAT int __nv_isfinited(double a) { return __builtin_isfinite(a); }
NV_COMPAT int __nv_isinfd(double a) { return __builtin_isinf(a); }
NV_COMPAT int __nv_isnand(double a) { return a != a; }
NV_COMPAT double __nv_ldexp(double a, int b) { return ldexp(a, b); }
NV_COMPAT float __nv_ldexpf(float a, int b) { return ldexpf(a, b); }
NV_COMPAT double __nv_lgamma(double a) { return lgamma(a); }
NV_COMPAT float __nv_lgammaf(float a) { return lgammaf(a); }
NV_COMPAT double __nv_ll2double_rd(long long a) { return (double)a; }
NV_COMPAT double __nv_ll2double_rn(long long a) { return (double)a; }
NV_COMPAT double __nv_ll2double_ru(long long a) { return (double)a; }
NV_COMPAT double __nv_ll2double_rz(long long a) { return (double)a; }
NV_COMPAT float __nv_ll2float_rd(long long a) { return (float)a; }
NV_COMPAT float __nv_ll2float_rn(long long a) { return (float)a; }
NV_COMPAT float __nv_ll2float_ru(long long a) { return (float)a; }
NV_COMPAT float __nv_ll2float_rz(long long a) { return (float)a; }
NV_COMPAT long long __nv_llabs(long long a) { return a < 0 ? -a : a; }
NV_COMPAT long long __nv_llmax(long long a, long long b) { return a > b ? a : b; }
NV_COMPAT long long __nv_llmin(long long a, long long b) { return a < b ? a : b; }
NV_COMPAT long long __nv_llrint(double a) { return llrint(a); }
NV_COMPAT long long __nv_llrintf(float a) { return llrintf(a); }
NV_COMPAT long long __nv_llround(double a) { return llround(a); }
NV_COMPAT long long __nv_llroundf(float a) { return llroundf(a); }
NV_COMPAT double __nv_log10(double a) { return log10(a); }
NV_COMPAT double __nv_log1p(double a) { return log1p(a); }
NV_COMPAT float __nv_log1pf(float a) { return log1pf(a); }
NV_COMPAT double __nv_log2(double a) { return log2(a); }
NV_COMPAT float __nv_log2f(float a) { return log2f(a); }
NV_COMPAT double __nv_logb(double a) { return logb(a); }
NV_COMPAT float __nv_logbf(float a) { return logbf(a); }
NV_COMPAT double __nv_log(double a) { return log(a); }
NV_COMPAT double __nv_longlong_as_double(long long a) { double r; __builtin_memcpy(&r, &a, 8); return r; }
NV_COMPAT int __nv_max(int a, int b) { return a > b ? a : b; }
NV_COMPAT int __nv_min(int a, int b) { return a < b ? a : b; }
NV_COMPAT double __nv_modf(double a, double * b) { return modf(a, b); }
NV_COMPAT float __nv_modff(float a, float * b) { return modff(a, b); }
NV_COMPAT int __nv_mul24(int a, int b) { return (int)(((unsigned)((a << 8) >> 8)) * ((unsigned)((b << 8) >> 8))); }
NV_COMPAT long long __nv_mul64hi(long long a, long long b) { return (long long)(((__int128)a * (__int128)b) >> 64); }
NV_COMPAT int __nv_mulhi(int a, int b) { return (int)(((long long)a * (long long)b) >> 32); }
NV_COMPAT double __nv_nan(const signed char * a) { (void)a; return __builtin_nan(""); }
NV_COMPAT float __nv_nanf(const signed char * a) { (void)a; return __builtin_nanf(""); }
NV_COMPAT double __nv_nearbyint(double a) { return nearbyint(a); }
NV_COMPAT float __nv_nearbyintf(float a) { return nearbyintf(a); }
NV_COMPAT double __nv_nextafter(double a, double b) { return nextafter(a, b); }
NV_COMPAT float __nv_nextafterf(float a, float b) { return nextafterf(a, b); }
NV_COMPAT int __nv_popcll(unsigned long long a) { return __builtin_popcountll(a); }
NV_COMPAT double __nv_pow(double a, double b) { return pow(a, b); }
NV_COMPAT double __nv_rcbrt(double a) { return 1.0 / cbrt(a); }
NV_COMPAT float __nv_rcbrtf(float a) { return 1.0f / cbrtf(a); }
NV_COMPAT double __nv_remainder(double a, double b) { return remainder(a, b); }
NV_COMPAT float __nv_remainderf(float a, float b) { return remainderf(a, b); }
NV_COMPAT double __nv_remquo(double a, double b, int * c) { return remquo(a, b, c); }
NV_COMPAT float __nv_remquof(float a, float b, int * c) { return remquof(a, b, c); }
NV_COMPAT int __nv_rhadd(int a, int b) { return (a >> 1) + (b >> 1) + ((a | b) & 1); }
static double (*volatile __nv_p_rint)(double) = rint;  // indirect: keep the libm call, see header note
NV_COMPAT double __nv_rint(double a) { return __nv_p_rint(a); }
static float (*volatile __nv_p_rintf)(float) = rintf;  // indirect: keep the libm call, see header note
NV_COMPAT float __nv_rintf(float a) { return __nv_p_rintf(a); }
static double (*volatile __nv_p_round)(double) = round;  // indirect: keep the libm call, see header note
NV_COMPAT double __nv_round(double a) { return __nv_p_round(a); }
static float (*volatile __nv_p_roundf)(float) = roundf;  // indirect: keep the libm call, see header note
NV_COMPAT float __nv_roundf(float a) { return __nv_p_roundf(a); }
NV_COMPAT double __nv_rsqrt(double a) { return 1.0 / sqrt(a); }
NV_COMPAT int __nv_sad(int a, int b, int c) { return (a > b ? (unsigned)(a - b) : (unsigned)(b - a)) + c; }
NV_COMPAT float __nv_saturatef(float a) { return a != a ? 0.0f : (a < 0.0f ? 0.0f : (a > 1.0f ? 1.0f : a)); }
NV_COMPAT double __nv_scalbn(double a, int b) { return scalbn(a, b); }
NV_COMPAT float __nv_scalbnf(float a, int b) { return scalbnf(a, b); }
NV_COMPAT int __nv_signbitd(double a) { return __builtin_signbit(a); }
NV_COMPAT int __nv_signbitf(float a) { return __builtin_signbit(a); }
NV_COMPAT void __nv_sincos(double a, double * b, double * c) { *b = sin(a); *c = cos(a); }
NV_COMPAT void __nv_sincosf(float a, float * b, float * c) { *b = sinf(a); *c = cosf(a); }
NV_COMPAT void __nv_sincospi(double a, double * b, double * c) { *b = sin(3.14159265358979323846 * a); *c = cos(3.14159265358979323846 * a); }
NV_COMPAT void __nv_sincospif(float a, float * b, float * c) { *b = sinf(3.14159265358979323846f * a); *c = cosf(3.14159265358979323846f * a); }
NV_COMPAT double __nv_sin(double a) { return sin(a); }
NV_COMPAT float __nv_sinf(float a) { return sinf(a); }
NV_COMPAT double __nv_sinh(double a) { return sinh(a); }
NV_COMPAT float __nv_sinhf(float a) { return sinhf(a); }
NV_COMPAT double __nv_sinpi(double a) { return sin(3.14159265358979323846 * a); }
NV_COMPAT float __nv_sinpif(float a) { return sinf(3.14159265358979323846f * a); }
NV_COMPAT double __nv_tan(double a) { return tan(a); }
NV_COMPAT float __nv_tanf(float a) { return tanf(a); }
NV_COMPAT double __nv_tanh(double a) { return tanh(a); }
NV_COMPAT float __nv_tanhf(float a) { return tanhf(a); }
NV_COMPAT double __nv_tgamma(double a) { return tgamma(a); }
NV_COMPAT float __nv_tgammaf(float a) { return tgammaf(a); }
static double (*volatile __nv_p_trunc)(double) = trunc;  // indirect: keep the libm call, see header note
NV_COMPAT double __nv_trunc(double a) { return __nv_p_trunc(a); }
static float (*volatile __nv_p_truncf)(float) = truncf;  // indirect: keep the libm call, see header note
NV_COMPAT float __nv_truncf(float a) { return __nv_p_truncf(a); }
NV_COMPAT int __nv_uhadd(unsigned int a, unsigned int b) { return (a >> 1) + (b >> 1) + (a & b & 1); }
NV_COMPAT double __nv_uint2double_rn(unsigned int a) { return (double)a; }
NV_COMPAT float __nv_uint2float_rd(unsigned int a) { return (float)a; }
NV_COMPAT float __nv_uint2float_rn(unsigned int a) { return (float)a; }
NV_COMPAT float __nv_uint2float_ru(unsigned int a) { return (float)a; }
NV_COMPAT float __nv_uint2float_rz(unsigned int a) { return (float)a; }
NV_COMPAT float __nv_uint_as_float(unsigned int a) { float r; __builtin_memcpy(&r, &a, 4); return r; }
NV_COMPAT double __nv_ull2double_rd(unsigned long long a) { return (double)a; }
NV_COMPAT double __nv_ull2double_rn(unsigned long long a) { return (double)a; }
NV_COMPAT double __nv_ull2double_ru(unsigned long long a) { return (double)a; }
NV_COMPAT double __nv_ull2double_rz(unsigned long long a) { return (double)a; }
NV_COMPAT float __nv_ull2float_rd(unsigned long long a) { return (float)a; }
NV_COMPAT float __nv_ull2float_rn(unsigned long long a) { return (float)a; }
NV_COMPAT float __nv_ull2float_ru(unsigned long long a) { return (float)a; }
NV_COMPAT float __nv_ull2float_rz(unsigned long long a) { return (float)a; }
NV_COMPAT unsigned long long __nv_ullmax(unsigned long long a, unsigned long long b) { return a > b ? a : b; }
NV_COMPAT unsigned long long __nv_ullmin(unsigned long long a, unsigned long long b) { return a < b ? a : b; }
NV_COMPAT unsigned int __nv_umax(unsigned int a, unsigned int b) { return a > b ? a : b; }
NV_COMPAT unsigned int __nv_umin(unsigned int a, unsigned int b) { return a < b ? a : b; }
NV_COMPAT unsigned int __nv_umul24(unsigned int a, unsigned int b) { return (a & 0xffffffu) * (b & 0xffffffu); }
NV_COMPAT unsigned long long __nv_umul64hi(unsigned long long a, unsigned long long b) { return (unsigned long long)(((unsigned __int128)a * (unsigned __int128)b) >> 64); }
NV_COMPAT unsigned int __nv_umulhi(unsigned int a, unsigned int b) { return (unsigned)(((unsigned long long)a * (unsigned long long)b) >> 32); }
NV_COMPAT unsigned int __nv_urhadd(unsigned int a, unsigned int b) { return (a >> 1) + (b >> 1) + ((a | b) & 1); }
NV_COMPAT unsigned int __nv_usad(unsigned int a, unsigned int b, unsigned int c) { return (a > b ? a - b : b - a) + c; }
