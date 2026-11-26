KERNEL_CU = main.cu
EXTRA_CLANG_FLAGS += -DJACOBI_N=16 -DMAX_ITERS=10
EXTRA_NVCC_FLAGS += -DJACOBI_N=16 -DMAX_ITERS=10
# The ten-iteration golden run reaches its cap before convergence and returns -1.
CI_EXPECTED_EXIT = 255
include ../common.mk
