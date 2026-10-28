KERNEL_CU = tcu_dt_wgmma_tf32.cu
# tensor-core test (experiments/dtype/tests/tcu_dt_wgmma.cu.in): hardware lanes needed -> no flat schedule
ifeq ($(SCHEDULE),0)
override SCHEDULE = 2
endif
CUDA_GPU_ARCH = sm_90a
RUN_ARGS  = -n 64
include ../common.mk
