KERNEL_CU = sgemm_tcu.cu
RUN_ARGS  = -n 32

# wmma requires sm_70 (sm_50 does not generate wmma intrinsics)
DEVICE_BC = sgemm_tcu-cuda-nvptx64-nvidia-cuda-sm_70.bc
HOST_BC   = sgemm_tcu-host-x86_64-unknown-linux-gnu.bc

include ../common.mk

# Override bitcode generation to use sm_70
$(DEVICE_BC): $(KERNEL_CU)
	@echo "--- Generate bitcode files (sm_70 for wmma)"
	$(LLVM_BIN)/clang++ -O0 -g -std=c++11 $(EXTRA_CLANG_FLAGS) \
		./$(KERNEL_CU) --sysroot=/ --target=x86_64-linux-gnu \
		-L$(CUDA_PATH)/lib64 --cuda-gpu-arch=sm_70 \
		-lcudart_static -ldl -lrt -pthread -save-temps -v 2>&1 || true
