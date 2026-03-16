#!/bin/bash

# exit when any command fails
set -e

######################### Default Varaibles #################################
DEVICE=vortex
KERNEL_CU=atomic_test.cu
ARCH=64
#############################################################################

# default: 1:1 mapping(2), can change it to thread mapping (0)
export VORTEX_SCHEDULE_FLAG=${VORTEX_SCHEDULE_FLAG:-2}

show_usage()
{
    echo "CuPBoP Compiling Script"
    echo "Usage: [--cuda_input=[cu filename]] [--device_target=[x86|simx|vortex] [--help]]"
}

if [ -z "$VORTEX_PATH" ]
then
    echo "You need to set "\$VORTEX_PATH" environment variable"
    exit -1
fi

if [ -z "$CuPBoP_PATH" ]
then
    echo "You need to set "\$CuPBoP_PATH" environment variable"
    exit -1
fi

if [ $ARCH = 32 ]
then
    RISCV_TOOLCHAIN_PREFIX=$RISCV_TOOLCHAIN/riscv32-unknown-elf-
    RISCV_TOOLCHAIN_FOLDER=$RISCV_TOOLCHAIN
elif [ $ARCH = 64 ]
then
    RISCV_TOOLCHAIN_PREFIX=$RISCV_TOOLCHAIN/riscv64-unknown-elf-
    RISCV_TOOLCHAIN_FOLDER=$RISCV_TOOLCHAIN
else
    echo "ARCH is setup to a wrong number, check your bash file"
    exit -1
fi

CUDA_PATH=$CuPBoP_PATH/cuda-12.1
DEBUG_LEVEL=0

DPRINT()
{
  if [ $DEBUG_LEVEL -eq 1 ]; then
      echo $@
  fi
}

for i in "$@"
do
case $i in
    --cuda_input=*)
        KERNEL_CU=atomic_test.cu
        shift
        ;;
    --device_target=*)
        DEVICE=${i#*=}
        shift
        ;;
    --help)
        show_usage
        exit 0
        ;;
    *)
    show_usage
    exit -1
    ;;
esac
done

case $DEVICE in
    x86)
        DRIVER_PATH=$VORTEX_PATH/driver/rtlsim
        ;;
    simx)
        DRIVER_PATH=$VORTEX_PATH/driver/simx
        ;;
    vortex)
        DRIVER_PATH=$VORTEX_PATH/driver/simx
        ;;
    *)
        echo "invalid device: $DEVICE"
        exit -1
        ;;
esac

# delete all generated files
rm -f *.out *.o *.dump *.log *.ll *.bc *.elf

KERNEL=`basename $KERNEL_CU .cu`

echo "--- Generate bitcode files(.bc) for host and device by using clang++"
${LLVM_PREFIX}/bin/clang++ -O0 -g -std=c++11  ./$KERNEL_CU --sysroot=/ --target=x86_64-linux-gnu -L$CUDA_PATH/lib64 --cuda-gpu-arch=sm_50 -lcudart_static -ldl -lrt -pthread -save-temps -v  || true

echo "--- Generate LLVM IR files(.ll) for host and device"
llvm-dis $KERNEL-cuda-nvptx64-nvidia-cuda-sm_50.bc
llvm-dis $KERNEL-host-x86_64-unknown-linux-gnu.bc

echo "--- Translate the kernel bitcode by using CuPBoP's kernel translator"
$CuPBoP_PATH/build/compilation/kernelTranslator $KERNEL-cuda-nvptx64-nvidia-cuda-sm_50.bc kernel.bc
llvm-dis kernel.bc

echo "--- Translate the host bitcode by using CuPBoP's host translator"
$CuPBoP_PATH/build/compilation/hostTranslator $KERNEL-host-x86_64-unknown-linux-gnu.bc host.bc
llvm-dis host.bc
llc --relocation-model=pic --filetype=obj host.bc -o host.o

g++ -g -O0 host_vortexrt.cpp -c -o host_vortexrt.o

echo "--- Compile the translated bc code for $DEVICE"
if [ $DEVICE = "vortex" ]
then

    VX_VXFLAGS="-Xclang -target-feature -Xclang +vortex -Xclang -target-feature -Xclang +zicond -mllvm -disable-loop-idiom-all"

    if [ $ARCH = 64 ]
    then
        VX_CFLAGS="-O3 --sysroot=${RISCV_TOOLCHAIN}/riscv64-unknown-elf --gcc-toolchain=${TOOLDIR}/riscv64-gnu-toolchain -march=rv64imafd -mabi=lp64d -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -nostdlib -fdata-sections -ffunction-sections -I${VORTEX_HOME}/kernel/include -I${VORTEX_PATH}/kernel/../hw -DXLEN_64 -DNDEBUG"
        VX_LDFLAGS="-Wl,-Bstatic,--gc-sections,-T,${VORTEX_HOME}/kernel/scripts/link64.ld,--defsym=STARTUP_ADDR=0x080000000 ${VORTEX_HOME}/build/kernel/libvortex.a -L${TOOLDIR}/libc64/lib -lm -lc ${TOOLDIR}/libcrt64/lib/baremetal/libclang_rt.builtins-riscv64.a"
    fi

    echo "--- compiling kernel.bc"
    ${LLVM_PREFIX}/bin/clang++ ${VX_CFLAGS} ${VX_VXFLAGS} kernel.bc -c -o kernel.o > kernel.log 2>&1
    echo "--- compiling kernel_wrapper.cpp"
    ${LLVM_PREFIX}/bin/clang++ ${VX_CFLAGS} ${VX_VXFLAGS} --gcc-toolchain=${RISCV_TOOLCHAIN_FOLDER} ./kernel_wrapper.cpp -c -o kernel_wrapper.o  || true
    ${LLVM_PREFIX}/bin/llvm-objdump -D kernel_wrapper.o > kernel_wrapper.dump

    echo "--- compiling kernel.elf"
    ${LLVM_PREFIX}/bin/clang++ ${VX_CFLAGS} ${VX_VXFLAGS} --gcc-toolchain=${RISCV_TOOLCHAIN_FOLDER} kernel_wrapper.o kernel.o ${CuPBoP_PATH}/runtime/src/vortex/kernel/cudaKernelImpl_64.o -lm ${VX_LDFLAGS} -o kernel.elf

    nm -C --defined-only -g kernel.elf > lookup_global_symbols.txt
    OBJCOPY=${LLVM_PREFIX}/bin/llvm-objcopy ${VORTEX_HOME}/kernel/scripts/vxbin.py kernel.elf kernel.vxbin
    ${LLVM_PREFIX}/bin/llvm-objdump -D kernel.elf > kernel.dump

    echo "--- Kernel compilation completed!"

    g++ -g -O0 -Wall -L../../build/runtime -L../../build/runtime/threadPool -L${VORTEX_PATH}/runtime/ -I${VORTEX_PATH}/kernel/include -o host.out -fPIC -no-pie host.o host_vortexrt.o  -lc -lvortexRuntime -lvortex -lThreadPool -lpthread
    echo "--- Host compilation completed!"

    # simx performance counter settings
    export PERF_CLASS=2
    LD_LIBRARY_PATH=../../build/runtime/threadPool:${VORTEX_PATH}/runtime/simx:../../build/runtime:${LD_LIBRARY_PATH} ./host.out > Batch_vortex_test1.log
    echo "--- Execution completed!"
    exit -1
fi
