KERNEL_CU = dxa_desc_test.cu
# DXA kernels need hardware lanes: keep them off the flat schedule (as sgemm_tcu_dxa)
ifeq ($(SCHEDULE),0)
override SCHEDULE = 2
endif
override EXTRA_CLANG_FLAGS += -I$(CuPBoP_PATH)/runtime/include
RUN_ARGS  =
include ../common.mk
