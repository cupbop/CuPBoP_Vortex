#!/bin/bash
TARGET=one_thread_kernel
## TARGET
clang++ -std=c++11  ./$TARGET.cu -I../.. --cuda-path=$CuPBoP_PATH/cuda-10.1 --cuda-gpu-arch=sm_50 -L$CuPBoP_PATH/cuda-10.1/lib64  -lcudart_static -ldl -lrt -pthread -save-temps -v  || true
$CuPBoP_PATH/build/compilation/kernelTranslator $TARGET-cuda-nvptx64-nvidia-cuda-sm_50.bc kernel.bc
$CuPBoP_PATH/build/compilation/hostTranslator $TARGET-host-x86_64-unknown-linux-gnu.bc host.bc
llc --relocation-model=pic --filetype=obj  kernel.bc
llc --relocation-model=pic --filetype=obj  host.bc
llvm-dis kernel.bc 
llvm-dis host.bc
#g++ -Wall -L../../build/runtime  -L../../build/runtime/threadPool  -L${VORTEX_PATH}/driver/simx/ -o ${TARGET}.out -fPIC -no-pie host.o kernel.o  -lc -lx86Runtime    -lvortex  -lthreadPool -lpthread 
#g++ -Wall -L../../build/runtime  -L../../build/runtime/threadPool  -L -o mcpy.out -fPIC -no-pie host.o kernel.o  -lc -lx86Runtime    -L/usr/local/hyesoon/vortex_public/vortex/driver/stub/libvortex.so  -lthreadPool -lpthread 
#$ g++ -o mcpy -fPIC -no-pie  -I$CuPBoP_PATH/runtime/threadPool/include  -L$CuPBoP_PATH/build/runtime   -L$CuPBoP_PATH/build/runtime/threadPool  host.o kernel.o  -lpthread -lc -lx86Runtime -lthreadPool
g++ -Wall -L../../build/runtime  -L../../build/runtime/threadPool  -L${VORTEX_PATH}/driver/simx/ -o ${TARGET}.out -fPIC -no-pie host.o kernel.o  -lc -lx86Runtime    -lvortex -lvortexrt   -lthreadPool -lpthread 
#g++ -Wall -L../../build/runtime  -L../../build/runtime/threadPool  -L${VORTEX_PATH}/driver/simx/ -o ${TARGET}.out -fPIC -no-pie host.o   -lc -lx86Runtime    -lvortex  -lthreadPool -lpthread 

./${TARGET}.out -q -v





