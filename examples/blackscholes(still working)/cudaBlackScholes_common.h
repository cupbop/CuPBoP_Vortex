
#pragma once
#include <cmath>
#include <cstdint>

// Match the OpenCL naming where practical; we keep the float version.
inline float cnd_approx(float x) {
    // Using erf-based CND to stay simple and stable
    // CND(x) = 0.5 * erfc(-x / sqrt(2))
    const float inv_sqrt2 = 0.70710678118654752440f;
    return 0.5f * erfcf(-x * inv_sqrt2);
}

// Golden CPU implementation (single option, float)
inline void black_scholes_cpu_one(
    float S, float K, float T, float R, float V,
    float& call, float& put)
{
    float sqrtT = std::sqrt(T);
    float d1 = (std::log(S / K) + (R + 0.5f * V * V) * T) / (V * sqrtT);
    float d2 = d1 - V * sqrtT;
    float CNDD1 = cnd_approx(d1);
    float CNDD2 = cnd_approx(d2);
    float expRT = std::exp(-R * T);
    call = S * CNDD1 - K * expRT * CNDD2;
    put  = K * expRT * (1.0f - CNDD2) - S * (1.0f - CNDD1);
}

// Vector CPU for convenience
inline void black_scholes_cpu(
    float* call, float* put,
    const float* S, const float* K, const float* T,
    float R, float V, int n)
{
    for (int i = 0; i < n; ++i) {
        black_scholes_cpu_one(S[i], K[i], T[i], R, V, call[i], put[i]);
    }
}
