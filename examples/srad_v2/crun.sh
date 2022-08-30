# # #!/bin/bash
set -e

clang++ srad.cu -I$CUDA_PATH/samples/common/inc \
    --cuda-path=$CUDA_PATH --cuda-gpu-arch=sm_61 \
    -L$CUDA_PATH/lib64 -lcudart_static -ldl -lrt -pthread -save-temps -v || true

kernelTranslator srad-cuda-nvptx64-nvidia-cuda-sm_61.bc kernel.bc
hostTranslator srad-host-x86_64-unknown-linux-gnu.bc host.bc



llc --relocation-model=pic --filetype=obj  kernel.bc -o kernel.o
echo "-------------"
llc --relocation-model=pic --filetype=obj  host.bc -o host.o

g++ -Wall -L$CuPBoP_BUILD_PATH/runtime  -L$CuPBoP_BUILD_PATH/runtime/threadPool -o srad \
    -fPIC -no-pie host.o kernel.o -lc -lx86Runtime -lthreadPool -lpthread

time ./srad 8192 8192 0 127 0 127 0.5 2