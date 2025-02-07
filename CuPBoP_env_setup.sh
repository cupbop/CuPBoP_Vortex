########## USER DEFINED VARIABLES ##########
export VORTEX_ARCHITECTURE=64     #(32 or 64)
export VORTEX_SCHEDULE_FLAG=0     #(0(TM) or 1(CM)
#############################################

if [ -z "${TOOLDIR}" ]; then
  echo "Error: TOOLDIR(Vortex Toolchain) is not defined. Please check your Vortex environment."
  exit 1
fi

if [ -z "${POCL_ROOT}" ]; then
  echo "Error: POCL_ROOT is not defined. Please check whether POCL is built and installed. (POCL_ROOT should have /compiler, and /runtime)"
  exit 1
fi

if [ -z "${VORTEX_HOME}" ]; then
  echo "Error: VORTEX_HOME is not defined. Please check whether Vortex is built and installed."
  exit 1
fi

if [ -z "${LLVM_VORTEX}" ]; then
  echo "Error: VORTEX_PATH is not defined. Please check whether Vortex LLVM is built and installed."
  exit 1
fi

if [ -z "${CuPBoP_PATH}" ]; then
  echo "Error: CuPBoP_PATH is not defined. Please check whether CuPBoP is built and installed."
  exit 1
fi


# if vortex architecture is 64bit
if [ $VORTEX_ARCHITECTURE -eq 64 ]; then
    export RISCV_TOOLCHAIN_PATH=$TOOLDIR/riscv64-gnu-toolchain
    export RISCV_TOOLCHAIN=${TOOLDIR}/riscv64-gnu-toolchain
    export GNU_RISCV_ROOT=${TOOLDIR}/riscv64-gnu-toolchain
else
    export RISCV_TOOLCHAIN_PATH=$TOOLDIR/riscv32-gnu-toolchain
    export RISCV_TOOLCHAIN=${TOOLDIR}/riscv32-gnu-toolchain
    export GNU_RISCV_ROOT=${TOOLDIR}/riscv32-gnu-toolchain
fi

export VORTEX_DRIVER_INC=$VORTEX_HOME/runtime/include
export VORTEX_DRIVER_LIB=$VORTEX_HOME/runtime/stub/libvortex.so

export LLVM_PREFIX=${LLVM_VORTEX}
export LLVM_POCL=${LLVM_VORTEX}

export POCL_CC_PATH=$POCL_ROOT/compiler
export POCL_RT_PATH=$POCL_ROOT/runtime

export VERILATOR_ROOT=${TOOLDIR}/verilator
export SV2V_PATH=$TOOLDIR/sv2v
export YOSYS_PATH=$TOOLDIR/yosys
export PATH=$YOSYS_PATH/bin:$SV2V_PATH/bin:$VERILATOR_ROOT/bin:$PATH
export LD_LIBRARY_PATH=${GNU_RISCV_ROOT}:$POCL_RT_PATH/lib:$LD_LIBRARY_PATH
export POCL_LEAVE_KERNEL_COMPILER_TEMP_FILE=0

# For CuPBoP
export LD_LIBRARY_PATH=$CuPBoP_PATH/build/runtime:$CuPBoP_PATH/build/runtime/threadPool:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$CuPBoP_PATH/cuda-12.1/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${LLVM_VORTEX}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${VORTEX_PATH}/runtime/:${LD_LIBRARY_PATH}
export CUDA_PATH=$CuPBoP_PATH/cuda-12.1

export LLVM_PATH=${LLVM_VORTEX}
export PATH=$LLVM_PATH/bin:$PATH
export VORTEX_PATH=$VORTEX_HOME/build


