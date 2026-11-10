# cuBLAS through libvxblas (Vortex sw/blas): VXBLAS_PATH = a libvxblas build for this hardware configuration.
# make cuda-run on an NVIDIA GPU node (nvcc, -lcublas) gives the golden values; compare_golden.py sets them side by side.
KERNEL_CU    = cublas_test.cu
RUN_ARGS     = -o values.txt
CI_RUN_ARGS  = -o values.txt
STARTUP_ADDR = 0x180000000
include ../common.mk
