KERNEL_CU = needle.cu
RUN_ARGS  = 128 10
# BLOCK_SIZE must be >= 32 for SCHE_2 (warps_per_group must be >= 2 for vx_barrier)
EXTRA_CLANG_FLAGS += -DRD_WG_SIZE_0_0=32
EXTRA_NVCC_FLAGS += -DRD_WG_SIZE_0_0=32
include ../common.mk
