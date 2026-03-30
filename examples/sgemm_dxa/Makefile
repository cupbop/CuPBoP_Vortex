KERNEL_CU = sgemm_dxa.cu
RUN_ARGS  = 16

# sm_70 for consistent compilation
DEVICE_BC = sgemm_dxa-cuda-nvptx64-nvidia-cuda-sm_70.bc
HOST_BC   = sgemm_dxa-host-x86_64-unknown-linux-gnu.bc

EXTRA_CLANG_FLAGS += -DTILE_SIZE=8 -DMATRIX_SIZE=16

include ../common.mk

# Override bitcode generation to use sm_70
$(DEVICE_BC): $(KERNEL_CU)
	@echo "--- Generate bitcode files (sm_70)"
	$(LLVM_BIN)/clang++ -O0 -g -std=c++11 $(EXTRA_CLANG_FLAGS) \
		./$(KERNEL_CU) --sysroot=/ --target=x86_64-linux-gnu \
		-L$(CUDA_PATH)/lib64 --cuda-gpu-arch=sm_70 \
		-lcudart_static -ldl -lrt -pthread -save-temps -v 2>&1 || true
