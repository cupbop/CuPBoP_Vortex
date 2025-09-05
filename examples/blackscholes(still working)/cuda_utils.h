
#pragma once
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

#define CUDA_CHECK(expr) do {                                           \
    cudaError_t _err = (expr);                                          \
    if (_err != cudaSuccess) {                                          \
        fprintf(stderr, "[CUDA] %s failed at %s:%d: %s\n",              \
                #expr, __FILE__, __LINE__, cudaGetErrorString(_err));   \
        std::exit(EXIT_FAILURE);                                        \
    }                                                                    \
} while (0)
