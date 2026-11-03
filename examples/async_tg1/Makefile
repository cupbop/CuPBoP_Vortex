KERNEL_CU = async_tg1.cu
RUN_ARGS  = -m 512 -n 256 -k 128
CI_RUN_ARGS = -m 512 -n 256 -k 128
# nvcc (make cuda-build): real GPU reference build
EXTRA_NVCC_FLAGS ?= -arch=sm_90a -lcuda
include ../common.mk
