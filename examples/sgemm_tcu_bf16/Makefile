KERNEL_CU = sgemm_tcu_bf16.cu
# TCU/DXA kernels need hardware lanes: keep them out of the flat schedule, but allow
# schedule 1 (virt / core mapping) as well as the default 1:1.
ifeq ($(SCHEDULE),0)
override SCHEDULE = 2
endif
CUDA_GPU_ARCH = sm_80
RUN_ARGS  = -n 32
include ../common.mk
