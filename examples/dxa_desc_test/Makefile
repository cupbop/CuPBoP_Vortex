KERNEL_CU = dxa_desc_test.cu
# DXA kernels need hardware lanes: keep them off the flat schedule (as sgemm_tcu_dxa)
ifeq ($(SCHEDULE),0)
override SCHEDULE = 2
endif
RUN_ARGS  =
include ../common.mk
