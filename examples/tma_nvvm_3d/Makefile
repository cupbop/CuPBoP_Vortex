KERNEL_CU = tma_nvvm_3d.cu
# CUDA supplies the host launch stub. The device input exercises the NVVM intrinsic directly.
DEVICE_BC_SRC = cuda_device.bc
include ../common.mk

$(DEVICE_BC): tma_nvvm_3d.ll.in
	$(LLVM_BIN)/llvm-as $< -o $@
