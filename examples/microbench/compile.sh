## cudamemcpy 

/usr/local/cuda/bin/nvcc -ccbin g++-7 -I/usr/local/hyesoon/cupbop/CuPBoP/cuda-10.1/samples/common/inc  -m64    -gencode arch=compute_30,code=sm_30 -gencode arch=compute_30,code=compute_30 -o cudamemcpy_test.o -c cudamemcpy_test.cu

/usr/local/cuda/bin/nvcc -ccbin g++   -m64      -gencode arch=compute_30,code=sm_30 -gencode arch=compute_30,code=compute_30 -o cudamemcpy_test cudamemcpy_test.o

# dummy_kernel.cu 
/usr/local/cuda/bin/nvcc -ccbin g++-7 -I/usr/local/hyesoon/cupbop/CuPBoP/cuda-10.1/samples/common/inc  -m64    -gencode arch=compute_30,code=sm_30 -gencode arch=compute_30,code=compute_30 -o dummy_kernel.o -c dummy_kernel.cu

/usr/local/cuda/bin/nvcc -ccbin g++   -m64      -gencode arch=compute_30,code=sm_30 -gencode arch=compute_30,code=compute_30 -o dummy_kernel dummy_kernel.o

## kernel_arg.cu 
/usr/local/cuda/bin/nvcc -ccbin g++-7 -I/usr/local/hyesoon/cupbop/CuPBoP/cuda-10.1/samples/common/inc  -m64    -gencode arch=compute_30,code=sm_30 -gencode arch=compute_30,code=compute_30 -o kernel_arg.o -c kernel_arg.cu

/usr/local/cuda/bin/nvcc -ccbin g++   -m64      -gencode arch=compute_30,code=sm_30 -gencode arch=compute_30,code=compute_30 -o kernel_arg kernel_arg.o

## one_thread_kernel.cu 

/usr/local/cuda/bin/nvcc -ccbin g++-7 -I/usr/local/hyesoon/cupbop/CuPBoP/cuda-10.1/samples/common/inc  -m64    -gencode arch=compute_30,code=sm_30 -gencode arch=compute_30,code=compute_30 -o one_thread_kernel.o -c one_thread_kernel.cu

/usr/local/cuda/bin/nvcc -ccbin g++   -m64      -gencode arch=compute_30,code=sm_30 -gencode arch=compute_30,code=compute_30 -o one_thread_kernel one_thread_kernel.o
