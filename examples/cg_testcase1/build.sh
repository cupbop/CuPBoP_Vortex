#!/bin/bash

LLVM_PATH=/software/vortex-toolchain-2024-6-14/llvm-vortex
CuPBoP_PATH=/nethome/hpu8/CuPBoP_dev
CUDA_PATH = /nethome/hpu8/local/cuda-12.6.3

clang++ -g -std=c++11  ./testcase1.cu -I../.. --cuda-path=$CUDA_PATH --cuda-gpu-arch=sm_50 -L$CUDA_PATH/lib64  -lcudart_static -ldl -lrt -pthread -save-temps -v  || true
# "${LLVM_PATH}/bin/clang++" -c -emit-llvm -I. --cuda-path=/nethome/hpu8/local/cuda-12.6.3/ --cuda-gpu-arch=sm_50 testcase1.cu
"${LLVM_PATH}/bin/llvm-dis" testcase1-cuda-nvptx64-nvidia-cuda-sm_35.bc
"${LLVM_PATH}/bin/llvm-dis" testcase1.bc