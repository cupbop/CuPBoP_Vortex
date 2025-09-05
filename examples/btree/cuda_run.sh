nvcc kernel/kernel_gpu_cuda_all.cu ./util/num/num.o ./util/main.o -o btree_cuda.o
./btree_cuda.o file ../../data/b+tree/mil.txt command ../../data/b+tree/command.txt  # > res_cuda.log