KERNEL_CU = main.cu
# The FLAT stack bound is required even when stack-pointer skew is disabled.
export CUPBOP_SP_SKEW = 0
include ../common.mk

$(DEVICE_BC) $(HOST_BC): ../huffman/scanLargeArray_kernel.cu
