KERNEL_CU = tcgen05_transpose_tmem_a.cu
override EXTRA_CLANG_FLAGS += -I$(CuPBoP_PATH)/runtime/include
EXTRA_NVCC_FLAGS = -arch=sm_100a -I$(CuPBoP_PATH)/runtime/include
include ../common.mk

$(DEVICE_BC_SRC) $(HOST_BC): $(CuPBoP_PATH)/runtime/include/cupbop_tcgen05.cuh
