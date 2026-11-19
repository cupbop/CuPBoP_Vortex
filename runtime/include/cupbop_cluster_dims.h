// Clang 20 parses CUDA cluster builtins but drops the cluster_dims attribute.
// Keep the constant expressions in device bitcode for the launch metadata pass.
#pragma once
#if defined(__clang__) && !__has_attribute(cluster_dims)
#undef __cluster_dims__
#ifdef __CUDA_ARCH__
#define __cluster_dims__(...) __attribute__((annotate("cupbop.cluster_dims", __VA_ARGS__)))
#else
#define __cluster_dims__(...)
#endif
#endif
