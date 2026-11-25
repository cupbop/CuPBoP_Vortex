KERNEL_CU = tcgen05_i8_pair.cu
EXTRA_NVCC_FLAGS = -arch=sm_100a
ifneq ($(findstring -DVX_CFG_TCU_TMEM_COLUMN_ENABLE,$(VORTEX_CONFIGS)),)
override EXTRA_CLANG_FLAGS += -DCUPBOP_TEST_COLUMN_PAIR
endif
include ../common.mk
