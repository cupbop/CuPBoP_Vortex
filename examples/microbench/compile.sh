## cudamemcpy 

ARCH=compute_50
CODE=sm_50
CUDA_COMMON_INC=$CuPBoP/cuda-10.1/samples/common/inc

/usr/local/cuda/bin/nvcc -ccbin g++-7 -I$CUDA_COMMON_INC  -m64    -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$ARCH -o cudamemcpy_test.o -c cudamemcpy_test.cu

/usr/local/cuda/bin/nvcc -ccbin g++   -m64      -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$ARCH -o cudamemcpy_test cudamemcpy_test.o

# dummy_kernel.cu 
/usr/local/cuda/bin/nvcc -ccbin g++-7 -I$CUDA_COMMON_INC  -m64    -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$ARCH -o dummy_kernel.o -c dummy_kernel.cu

/usr/local/cuda/bin/nvcc -ccbin g++   -m64      -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$ARCH -o dummy_kernel dummy_kernel.o

## kernel_arg.cu 
/usr/local/cuda/bin/nvcc -ccbin g++-7 -I$CUDA_COMMON_INC  -m64    -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$ARCH -o kernel_arg.o -c kernel_arg.cu

/usr/local/cuda/bin/nvcc -ccbin g++   -m64      -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$ARCH -o kernel_arg kernel_arg.o

## one_thread_kernel.cu 

/usr/local/cuda/bin/nvcc -ccbin g++-7 -I$CUDA_COMMON_INC  -m64    -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$ARCH -o one_thread_kernel.o -c one_thread_kernel.cu
/usr/local/cuda/bin/nvcc -ccbin g++   -m64      -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$ARCH -o one_thread_kernel one_thread_kernel.o




## dummy_host.cu 

/usr/local/cuda/bin/nvcc -ccbin g++-7 -I$CUDA_COMMON_INC -m64    -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$CODE -o dummy_host_kernel.o -c dummy_host_kernel.cu
/usr/local/cuda/bin/nvcc -ccbin g++   -m64      -gencode arch=$ARCH,code=$CODE -gencode arch=$ARCH,code=$ARCH -o  dummy_host_kernel  dummy_host_kernel.o 

#/usr/local/cuda/bin/nvcc -ccbin g++-7 -I/usr/local/hyesoon/cupbop/CuPBoP/cuda-10.1/samples/common/inc  -m64    -gencode arch=compute_30,code=sm_30 -gencode arch=compute_30,code=compute_30 -o dummy_host.o -c dummy_host.cu

