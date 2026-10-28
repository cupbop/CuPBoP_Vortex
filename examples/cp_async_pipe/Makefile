KERNEL_CU = cp_async_pipe.cu
# n = 14.75 tiles: the last 64 elements of tile 14 are past n and zero-filled (read by other threads)
RUN_ARGS  = -n 3776 -t 4
include ../common.mk
