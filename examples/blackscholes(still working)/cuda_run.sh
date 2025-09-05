#!/bin/bash
# Simple build script for the CUDA Black-Scholes port

APP=cuda_blackscholes
NVCC=${NVCC:-nvcc}
ARCH=${ARCH:--arch=sm_70}

SRCS="cuda_blackscholes_all.cu"
HDRS="cuda_utils.h cudaBlackScholes_common.h"

CXXFLAGS="-O3 -std=c++11"
NVCCFLAGS="$ARCH $CXXFLAGS"

# Clean target
if [[ "$1" == "clean" ]]; then
  echo "[CLEAN] Removing $APP"
  rm -f "$APP"
  exit 0
fi

# Build target
echo "[BUILD] Compiling $APP with $NVCC"
$NVCC $NVCCFLAGS -o $APP $SRCS
status=$?

if [[ $status -eq 0 ]]; then
  echo "[DONE] Build successful: $APP"
else
  echo "[ERROR] Build failed"
fi
exit $status

./cuda_blackscholes -n 8192