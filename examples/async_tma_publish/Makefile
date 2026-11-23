KERNEL_CU = async_tma_publish.cu
RUN_ARGS =
CI_RUN_ARGS =
EXTRA_CLANG_FLAGS += -DCUPBOP_CHECK_PUBLISHED_MAP
EXTRA_NVCC_FLAGS ?= -arch=sm_90a -lcuda
include ../common.mk
