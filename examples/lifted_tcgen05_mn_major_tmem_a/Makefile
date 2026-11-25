KERNEL_CU = ../tcgen05_column_mma/tcgen05_column_mma.cu
override EXTRA_CLANG_FLAGS += -I$(CuPBoP_PATH)/runtime/include -DCUPBOP_TEST_TMEM_A -DCUPBOP_TEST_MN_TMEM_A -DCUPBOP_TEST_TF32
include ../lift.mk

$(HOST_BC): $(CuPBoP_PATH)/runtime/include/cupbop_tcgen05.cuh
