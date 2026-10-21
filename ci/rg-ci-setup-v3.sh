#!/bin/bash
# Vortex 3.0 environment for the CuPBoP CI (CRNCH dash nodes, inside cupbop_env.sif or on the host).
# Sourced by ci/run-crnch-cuda.sh (ci.yml build job), ci/run-crnch-cuda-test.sh (ci.yml matrix job) and
# ci/run-v3-matrix.sbatch (the whole matrix as one Slurm job). Every path can be overridden before sourcing.
#
# Defaults point at the self-hosted runner's tool directory (readable and writable by the runner account):
#   $CUPBOP_CI_TOOLS/vortex_v3.0    Vortex source tree: clean checkout of release tag v3.0 (sw/ layout)
#   $CUPBOP_CI_TOOLS/tools-v3.0.1   Vortex toolchain v3.0.1 (llvm-vortex = clang 20, riscv64-gnu-toolchain, libc64, libcrt64)
# VORTEX_PATH is a configured build dir inside VORTEX_HOME whose SimX was built with $VORTEX_CONFIGS
# (cupbop_v3_ensure_simx below builds it and records the flags). The kernel ELF of every example is built in a cell
# under $VORTEX_PATH/tests/regression/ by Vortex's own regression makefile (examples/v3_cell.mk), so the account
# running the tests needs write access to VORTEX_PATH.
CUPBOP_CI_TOOLS=${CUPBOP_CI_TOOLS:-/projects/ci-runners/CuPBoP-Vortex/tools}
export VORTEX_HOME=${VORTEX_HOME:-$CUPBOP_CI_TOOLS/vortex_v3.0}
export VORTEX_PATH=${VORTEX_PATH:-$VORTEX_HOME/build64_cupbop}
export TOOLDIR=${TOOLDIR:-$CUPBOP_CI_TOOLS/tools-v3.0.1}
export LLVM_VORTEX=${LLVM_VORTEX:-$TOOLDIR/llvm-vortex}
export LLVM_PREFIX=$LLVM_VORTEX
export LLVM_POCL=$LLVM_VORTEX
export LLVM_CONFIG_PATH=$LLVM_VORTEX/bin/llvm-config
export RISCV_TOOLCHAIN_PATH=$TOOLDIR/riscv64-gnu-toolchain
export RISCV_TOOLCHAIN=$RISCV_TOOLCHAIN_PATH
export GNU_RISCV_ROOT=$RISCV_TOOLCHAIN_PATH
export CUDA_PATH=${CUDA_PATH:-/usr/local/cuda}   # CUDA 12.1 headers of cupbop_env.sif (clang's CUDA frontend and the host runtime)
export CuPBoP_PATH=${CuPBoP_PATH:-$PWD}          # repository root; the CI scripts cd there before sourcing this file
export VORTEX_ARCHITECTURE=64
export VORTEX_VER=3
export VORTEX_DRIVER=${VORTEX_DRIVER:-simx}
# Vortex 3.0 disables the A (atomics) extension by default and SimX aborts silently on an AMO
# when it is off; the CuPBoP examples use atomics, so enable it in the SimX build and kernels.
# Zacas (amocas.w/d) as well: without it atomicCAS lowers to an lr/sc loop, and lanes of one warp
# retrying on the same cache line in lockstep livelock in SimX 3.0 (line-granular reservations:
# lane 0's sc always wins and kills lane 1's reservation) — bh-cuda SCHE_2 TreeBuildingKernel hung.
# L2: SimX 3.0 commits AMOs at the last-level cache (sim/simx/mem/cache.cpp commitAmo); with L2/L3 off
# every core's private L1 is the LLC (socket.cpp:93), so atomics from different cores update stale private
# copies and lose updates (marchingCubes SCHE_2 counts always low; PASS with 1 core or with L2, job 174316).
export VORTEX_CONFIGS=${VORTEX_CONFIGS:-"-DVX_CFG_NUM_CORES=4 -DVX_CFG_NUM_WARPS=16 -DVX_CFG_NUM_THREADS=32 -DVX_CFG_EXT_A_ENABLE -DVX_CFG_EXT_ZACAS_ENABLE -DVX_CFG_L2_ENABLE"}
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
# The Vortex build dirs under VORTEX_HOME are shared between the runner account and the maintainers who install or
# refresh them (both build SimX and the regression cells there), so make everything created from here group-writable.
umask 002

# cupbop_v3_ensure_simx <build_dir> <VX_CFG flags>
# Configure <build_dir> (once) and build its SimX driver with the given flags: hw (config headers), sw/kernel
# (libvortex.a used by the kernel cells), sw/runtime/stub (libvortex.so), sim/simx and sw/runtime/simx with PERF=1
# (the examples read the Perf_counter_* summary). The flags are recorded in <build_dir>/.cupbop_simx_configs and
# nothing is rebuilt while they match, so changing VORTEX_CONFIGS above is enough to get a matching SimX on the next
# build job. Build log: <build_dir>/cupbop_simx_build.log.
cupbop_v3_ensure_simx() {
  local bdir=$1 cfg=$2
  local mark=$bdir/.cupbop_simx_configs log=$bdir/cupbop_simx_build.log jobs=${SLURM_CPUS_PER_TASK:-8}
  if [ ! -f $bdir/config.mk ]; then
    mkdir -p $bdir && ( cd $bdir && $VORTEX_HOME/configure --xlen=64 --tooldir=$TOOLDIR > /dev/null ) \
      || { echo "cupbop_v3_ensure_simx: configure failed in $bdir"; return 1; }
  fi
  if [ ! -f $bdir/sw/runtime/libvortex-simx.so ] || [ "$(cat $mark 2>/dev/null)" != "$cfg" ]; then
    echo "cupbop_v3_ensure_simx: building SimX in $bdir for: $cfg"
    ( cd $bdir && make -C hw && make -C sw/kernel && make -C sw/runtime/stub && make -C sim/simx clean && make -C sw/runtime/simx clean && \
      CONFIGS="$cfg" make -C sim/simx PERF=1 -j$jobs && CONFIGS="$cfg" make -C sw/runtime/simx PERF=1 ) > $log 2>&1 \
      || { echo "cupbop_v3_ensure_simx: SimX build failed in $bdir (log: $log)"; grep -n "error" $log | head; return 1; }
    echo "$cfg" > $mark
  fi
  echo "cupbop_v3_ensure_simx: $bdir ready ($(cat $mark))"
}

# cupbop_v3_select_simx <test_name>
# The tensor examples run on the TCU+DXA SimX build: switch VORTEX_PATH / VORTEX_CONFIGS for them.
cupbop_v3_select_simx() {
  case $1 in
    sgemm_tcu|sgemm_dxa|sgemm_tcu_dxa)
      export VORTEX_PATH=$VORTEX_PATH_TCU VORTEX_CONFIGS="$VORTEX_CONFIGS_TCU"
      export LD_LIBRARY_PATH=$VORTEX_PATH/sw/runtime:$LD_LIBRARY_PATH ;;
  esac
}
