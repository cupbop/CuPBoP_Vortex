#!/bin/bash

LLVM_PATH=/software/vortex-toolchain-2024-6-14/llvm-vortex
CuPBoP_PATH=/nethome/hpu8/CuPBoP_dev

"${CuPBoP_PATH}/build/compilation/kernelTranslator" testcase1-cuda-nvptx64-nvidia-cuda-sm_35.bc kernel.bc
# "${CuPBoP_PATH}/build/compilation/hostTranslator" testcase1.bc host.bc
