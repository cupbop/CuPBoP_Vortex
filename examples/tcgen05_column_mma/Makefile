KERNEL_CU = tcgen05_column_mma.cu
EXTRA_NVCC_FLAGS = -arch=sm_100a
ifneq ($(filter -DVX_CFG_TCU_TF32_ENABLE,$(VORTEX_CONFIGS)),)
override EXTRA_CLANG_FLAGS += -DCUPBOP_TEST_MIXED_TF32
EXTRA_NVCC_FLAGS += -DCUPBOP_TEST_MIXED_TF32
endif
include ../common.mk
