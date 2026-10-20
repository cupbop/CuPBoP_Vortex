#!/bin/bash
# Vortex 3.0 environment for the CuPBoP CI (CRNCH dash nodes, inside cupbop_env.sif or on the host).
# Every path can be overridden before sourcing. VORTEX_HOME is the Vortex 3.0 SOURCE root (sw/ layout)
# and VORTEX_PATH its configured build dir whose SimX was built with $VORTEX_CONFIGS.
export VORTEX_HOME=${VORTEX_HOME:-/net/netscratch/cahn45/Vortex_Agent/vortex/v3.0}
export VORTEX_PATH=${VORTEX_PATH:-$VORTEX_HOME/build64_cupbop}
export TOOLDIR=${TOOLDIR:-/net/netscratch/cahn45/Vortex_Agent/vortex/tools-v3.0.1}
export LLVM_VORTEX=${LLVM_VORTEX:-$TOOLDIR/llvm-vortex}
export LLVM_PREFIX=$LLVM_VORTEX
export LLVM_POCL=$LLVM_VORTEX
export LLVM_CONFIG_PATH=$LLVM_VORTEX/bin/llvm-config
export RISCV_TOOLCHAIN_PATH=$TOOLDIR/riscv64-gnu-toolchain
export RISCV_TOOLCHAIN=$RISCV_TOOLCHAIN_PATH
export GNU_RISCV_ROOT=$RISCV_TOOLCHAIN_PATH
export CUDA_PATH=${CUDA_PATH:-/usr/local/cuda}
export CuPBoP_PATH=${CuPBoP_PATH:-$PWD}
export VORTEX_ARCHITECTURE=64
export VORTEX_VER=3
export VORTEX_DRIVER=${VORTEX_DRIVER:-simx}
# Vortex 3.0 disables the A (atomics) extension by default and SimX aborts silently on an AMO
# when it is off; the CuPBoP examples use atomics, so enable it in the SimX build and kernels.
# Zacas (amocas.w/d) as well: without it atomicCAS lowers to an lr/sc loop, and lanes of one warp
# retrying on the same cache line in lockstep livelock in SimX 3.0 (line-granular reservations:
# lane 0's sc always wins and kills lane 1's reservation) — bh-cuda SCHE_2 TreeBuildingKernel hung.
export VORTEX_CONFIGS=${VORTEX_CONFIGS:-"-DVX_CFG_NUM_CORES=4 -DVX_CFG_NUM_WARPS=16 -DVX_CFG_NUM_THREADS=32 -DVX_CFG_EXT_A_ENABLE -DVX_CFG_EXT_ZACAS_ENABLE"}
# sgemm_tcu / sgemm_dxa / sgemm_tcu_dxa need the TCU and DXA extensions, which 3.0 also leaves off by
# default; they run against a second SimX build (VORTEX_PATH_TCU) configured with these flags.
export VORTEX_CONFIGS_TCU=${VORTEX_CONFIGS_TCU:-"$VORTEX_CONFIGS -DVX_CFG_EXT_TCU_ENABLE -DVX_CFG_EXT_DXA_ENABLE"}
export VORTEX_PATH_TCU=${VORTEX_PATH_TCU:-$VORTEX_HOME/build64_cupbop_tcu}
export VORTEX_NUM_CORES=${VORTEX_NUM_CORES:-4}
export VORTEX_NUM_WARPS=${VORTEX_NUM_WARPS:-16}
export VORTEX_NUM_THREADS=${VORTEX_NUM_THREADS:-32}
export PATH=$LLVM_VORTEX/bin:$PATH
export LD_LIBRARY_PATH=$CuPBoP_PATH/build/runtime:$CuPBoP_PATH/build/runtime/threadPool:$VORTEX_PATH/sw/runtime:$LLVM_VORTEX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export CC=gcc
export CXX=g++
