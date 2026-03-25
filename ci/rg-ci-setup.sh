#!/bin/bash

# Loading NVCC
# module use /projects/tools/x86_64/ubuntu-22.04/nvhpc-24.9/modulefiles/
# module load nvhpc/24.9
# export CUDA_LIB_PATH="/projects/tools/x86_64/ubuntu-22.04/nvhpc-24.9/Linux_x86_64/24.9/cuda/lib64" # Hardcoded path for rg servers ONLY
export CUDA_PATH="/usr/local/cuda"

# Setting CuPBoP Paths
export CuPBoP_PATH=$PWD
export LD_LIBRARY_PATH=$CuPBoP_PATH/build/runtime:$CuPBoP_PATH/build/runtime/threadPool:$LD_LIBRARY_PATH

# Setting Vortex Paths
export VORTEX_HOME="/projects/ci-runners/CuPBoP-Vortex/tools/vortex" # Hardcoded path for rg servers ONLY
export VORTEX_PATH=$VORTEX_HOME/build
export VORTEX_DRIVER_INC=$VORTEX_HOME/runtime/include
export VORTEX_DRIVER_LIB=$VORTEX_HOME/runtime/stub/libvortex.so
export LD_LIBRARY_PATH=${VORTEX_PATH}/runtime/:${LD_LIBRARY_PATH}

# Setting Tooldir and Tooldir Paths
export TOOLDIR="/projects/ci-runners/CuPBoP-Vortex/tools/tooldir" # Hardcoded path for rg servers ONLY
export PATH=$TOOLDIR/verilator/bin:$PATH
export SV2V_PATH=$TOOLDIR/sv2v
export YOSYS_PATH=$TOOLDIR/yosys
export PATH=$YOSYS_PATH/bin:$SV2V_PATH/bin:$PATH
export RISCV_TOOLCHAIN_PATH=$TOOLDIR/riscv64-gnu-toolchain
export RISCV_TOOLCHAIN=${TOOLDIR}/riscv64-gnu-toolchain
export GNU_RISCV_ROOT=${TOOLDIR}/riscv64-gnu-toolchain
export LD_LIBRARY_PATH=${GNU_RISCV_ROOT}:$LD_LIBRARY_PATH

# Setting LLVM-Vortex Paths
export LLVM_VORTEX="/projects/ci-runners/CuPBoP-Vortex/tools/llvm/build" # Hardcoded path for rg servers ONLY
export LLVM_PREFIX=${LLVM_VORTEX}
export LLVM_POCL=${LLVM_VORTEX}
export PATH=$LLVM_VORTEX/bin:$PATH
export LD_LIBRARY_PATH=${LLVM_VORTEX}/lib:${LD_LIBRARY_PATH}
export LLVM_CONFIG_PATH=$LLVM_VORTEX/bin/llvm-config

# Setting Necessary Flags
export CC=gcc
export CXX=g++
export VORTEX_ARCHITECTURE=64 
# export VORTEX_SCHEDULE_FLAG=2 # Removed so that we can run examples with different scheduler algorithms

# Running Vortex Configuration
cd $VORTEX_PATH
../configure --xlen=64 --tooldir=$TOOLDIR

cd $CuPBoP_PATH
