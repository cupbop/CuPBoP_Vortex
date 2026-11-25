KERNEL_CU = ../tcgen05_transpose_tmem_a/tcgen05_transpose_tmem_a.cu
override EXTRA_CLANG_FLAGS += -I$(CuPBoP_PATH)/runtime/include
include ../lift.mk

$(HOST_BC): $(CuPBoP_PATH)/runtime/include/cupbop_tcgen05.cuh
