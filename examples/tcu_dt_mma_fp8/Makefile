KERNEL_CU = tcu_dt_mma_fp8.cu
# tensor-core test (experiments/dtype/tests/tcu_dt_mma.cu.in): hardware lanes needed -> no flat schedule
ifeq ($(SCHEDULE),0)
override SCHEDULE = 2
endif
CUDA_GPU_ARCH = sm_89
RUN_ARGS  = -n 32
include ../common.mk
