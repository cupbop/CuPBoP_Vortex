KERNEL_CU    = backprop_cuda.cu
RUN_ARGS     = 64
CI_RUN_ARGS  = 64
EXTRA_C_SRCS = backprop.c facetrain.c imagenet.c
LIFT_MERGE = 1
export LIFT_D2H_SKIP = 2
include ../lift.mk
