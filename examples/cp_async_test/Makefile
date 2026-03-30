KERNEL_CU = cp_async_test.cu
RUN_ARGS  = 16

# sm_80 required for cp.async intrinsics
DEVICE_BC = cp_async_test-cuda-nvptx64-nvidia-cuda-sm_80.bc
HOST_BC   = cp_async_test-host-x86_64-unknown-linux-gnu.bc

EXTRA_CLANG_FLAGS += -DTILE_SIZE=8 -DMATRIX_SIZE=16

include ../common.mk

# Override bitcode generation to use sm_80
$(DEVICE_BC): $(KERNEL_CU)
	@echo "--- Generate bitcode files (sm_80 for cp.async)"
	$(LLVM_BIN)/clang++ -O0 -g -std=c++11 $(EXTRA_CLANG_FLAGS) \
		./$(KERNEL_CU) --sysroot=/ --target=x86_64-linux-gnu \
		-L$(CUDA_PATH)/lib64 --cuda-gpu-arch=sm_80 \
		-lcudart_static -ldl -lrt -pthread -save-temps -v 2>&1 || true
