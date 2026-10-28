KERNEL_CU = tcu_dt_wmma_f16.cu
# tensor-core test (experiments/dtype/tests/tcu_dt_wmma.cu.in): hardware lanes needed -> no flat schedule
ifeq ($(SCHEDULE),0)
override SCHEDULE = 2
endif
CUDA_GPU_ARCH = sm_80
RUN_ARGS  = -n 32
include ../common.mk
