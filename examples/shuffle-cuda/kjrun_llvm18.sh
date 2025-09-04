#!/bin/bash

# exit when any command fails
set -e

######################### Default Varaibles #################################
DEVICE=vortex
KERNEL_CU=main.cu
ARCH=64
#############################################################################

export VORTEX_SCHEDULE_FLAG=2

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
        KERNEL_CU=${i#*=}
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

# Possible to put -O3 here to generate simpler code
echo "--- Generate bitcode files(.bc) for host and device by using clang++"
${LLVM_PREFIX}/bin/clang++ -O0 -g -std=c++11  ./$KERNEL_CU -I../.. --sysroot=/ --target=x86_64-linux-gnu --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13 --cuda-path=$CUDA_PATH --cuda-gpu-arch=sm_50 -L$CUDA_PATH/lib64  -lcudart_static -ldl -lrt -pthread -save-temps -v  || true
#${LLVM_PREFIX}/bin/clang++ --stdlib=libstdc++ -O0 -g -std=c++11  ./$KERNEL_CU -I../.. --target=x86_64-linux-gnu --gcc-toolchain=/usr/lib/gcc/x86_64-linux-gnu/13 --cuda-path=$CUDA_PATH --cuda-gpu-arch=sm_50 -L$CUDA_PATH/lib64  -lcudart_static -ldl -lrt -pthread -save-temps -v  || true
#/software/vortex-schedule/llvm-vortex/bin/clang++ -O0 -g -std=c++11  ./$KERNEL_CU -I../.. --target=x86_64-linux-gnu --cuda-path=$CUDA_PATH --cuda-gpu-arch=sm_50 -L$CUDA_PATH/lib64  -lcudart_static -ldl -lrt -pthread -save-temps -v  || true
#/software/LLVM_14/bin/clang++ -O0 -g -std=c++11  ./$KERNEL_CU -I../.. --cuda-path=$CUDA_PATH --cuda-gpu-arch=sm_50 -L$CUDA_PATH/lib64  -lcudart_static -ldl -lrt -pthread -save-temps -v  || true

echo "--- Generate LLVM IR files(.ll) for host and device"
llvm-dis $KERNEL-cuda-nvptx64-nvidia-cuda-sm_50.bc
llvm-dis $KERNEL-host-x86_64-unknown-linux-gnu.bc

echo "--- Translate the kernel bitcode by using CuPBoP's kernel translator"
#$CuPBoP_PATH/build/compilation/kernelTranslator.x86 $KERNEL-cuda-nvptx64-nvidia-cuda-sm_50.bc kernel_host.bc 
$CuPBoP_PATH/build/compilation/kernelTranslator $KERNEL-cuda-nvptx64-nvidia-cuda-sm_50.bc kernel.bc 
llvm-dis kernel.bc

echo "--- Translate the host bitcode by using CuPBoP's host translator"
$CuPBoP_PATH/build/compilation/hostTranslator $KERNEL-host-x86_64-unknown-linux-gnu.bc host.bc
llvm-dis host.bc 
llc --relocation-model=pic --filetype=obj host.bc -o host.o

g++ -g -O0 host_vortexrt.cpp -c -o host_vortexrt.o

echo "--- Compile the translated bc code for $DEVICE"
if [ $DEVICE = "x86" ]
then
    llc --relocation-model=pic --filetype=obj kernel.bc
    llc --relocation-model=pic --filetype=obj host.bc
    g++ -Wall -L../../build/runtime  -L../../build/runtime/threadPool  -L${VORTEX_PATH}/driver/simx/ -o ${KERNEL}.out -fPIC -no-pie host.o kernel.o  -lc -lx86Runtime    -lvortex  -lthreadPool -lpthread 
    DPRINT "--- Run the executable file."
    ./${KERNEL}.out -q -v
elif [ $DEVICE = "simx" ]
then
    clang++ -std=c++11 --target=riscv32 -march=rv32imf -mabi=ilp32f kernel.bc -c -o kernel.o 
    $RISCV_TOOLCHAIN_PATH/bin/riscv32-unknown-elf-gcc -march=rv32imf -mabi=ilp32f -Wstack-usage=1024 -mcmodel=medany -ffreestanding -nostartfiles -fdata-sections -ffunction-sections -I${VORTEX_PATH}/runtime/include -I${VORTEX_PATH}/runtime/../hw main.cc kernel.o -lm -Wl,-Bstatic,-T,${VORTEX_PATH}/runtime/linker/vx_link32.ld -Wl,--gc-sections ${VORTEX_PATH}/runtime/libvortex.a -o kernel.elf 
    $RISCV_TOOLCHAIN_PATH/bin/riscv32-unknown-elf-objcopy -O binary kernel.elf kernel.bin
    $RISCV_TOOLCHAIN_PATH/bin/riscv32-unknown-elf-objdump -D kernel.elf > kernel.dump
    DPRINT "--- Run the kernel on simx"
    ${VORTEX_PATH}/sim/simx/simx -r -c 1 -i kernel.bin -s
elif [ $DEVICE = "vortex" ]
then

    VX_VXFLAGS="-Xclang -target-feature -Xclang +vortex -Xclang -target-feature -Xclang +zicond -mllvm -disable-loop-idiom-all"
    
    if [ $ARCH = 32 ]
    then
        VX_CFLAGS="-v -O3 -std=c++11 --sysroot=${RISCV_TOOLCHAIN}/riscv32-unknown-elf --target=riscv32 -march=rv32imf -mabi=ilp32f -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -fdata-sections -ffunction-sections -I${VORTEX_PATH}/kernel/include -I${VORTEX_HOME}/build/hw"
        VX_LDFLAGS="-Wl,-Bstatic,-T,${VORTEX_HOME}/kernel/linker/vx_link32.ld,--defsym=XLEN=32,--defsym=STARTUP_ADDR=0x80000000 -Wl,--gc-sections ${VORTEX_PATH}/kernel/libvortexrt.a"
    else
        VX_CFLAGS="-O3 --sysroot=${RISCV_TOOLCHAIN}/riscv64-unknown-elf --gcc-toolchain=${TOOLDIR}/riscv64-gnu-toolchain -march=rv64imafd -mabi=lp64d -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -nostdlib -fdata-sections -ffunction-sections -I${VORTEX_PATH}/kernel/include -I${VORTEX_HOME}/build/hw -DXLEN_64 -DNDEBUG"
        VX_LDFLAGS="-Wl,-Bstatic,--gc-sections,-T,${VORTEX_HOME}/kernel/scripts/link64.ld,--defsym=STARTUP_ADDR=0x080000000 ${VORTEX_HOME}/build/kernel/libvortex.a -L${TOOLDIR}/libc64/lib -lm -lc ${TOOLDIR}/libcrt64/lib/baremetal/libclang_rt.builtins-riscv64.a"
    fi

    echo "--- compiling kernel.bc"
    ${LLVM_PREFIX}/bin/clang++ ${VX_CFLAGS} ${VX_VXFLAGS} kernel.bc -c -o kernel.o > kernel.log 2>&1    
    echo "--- compiling kernel_wrapper.cpp"
    ${LLVM_PREFIX}/bin/clang++ ${VX_CFLAGS} ${VX_VXFLAGS} --gcc-toolchain=${RISCV_TOOLCHAIN_FOLDER} ../vortex_debug/kernel_wrapper.cpp -c -o kernel_wrapper.o -save-temps -v  || true  
    llvm-dis kernel_wrapper.bc
    ${LLVM_PREFIX}/bin/llvm-objdump -D kernel_wrapper.o > kernel_wrapper.dump

    echo "--- compiling kernel.elf"
    if [ $ARCH = 32 ]
    then
        ${LLVM_PREFIX}/bin/clang++ ${VX_CFLAGS} ${VX_VXFLAGS} --gcc-toolchain=${RISCV_TOOLCHAIN_FOLDER} kernel_wrapper.o kernel.o ${CuPBoP_PATH}/runtime/src/vortex/kernel/cudaKernelImpl.o -lm ${VX_LDFLAGS} -o kernel.elf 
    else
        ${LLVM_PREFIX}/bin/clang++ ${VX_CFLAGS} ${VX_VXFLAGS} --gcc-toolchain=${RISCV_TOOLCHAIN_FOLDER} kernel_wrapper.o kernel.o ${CuPBoP_PATH}/runtime/src/vortex/kernel/cudaKernelImpl_64.o -lm ${VX_LDFLAGS} -o kernel.elf 
    fi

    nm -C --defined-only -g kernel.elf > lookup_global_symbols.txt
    #${LLVM_PREFIX}/bin/llvm-objcopy -O binary kernel.elf kernel.out    
    OBJCOPY=${LLVM_PREFIX}/bin/llvm-objcopy ${VORTEX_HOME}/kernel/scripts/vxbin.py kernel.elf kernel.vxbin
    ${LLVM_PREFIX}/bin/llvm-objdump -D kernel.elf > kernel.dump
    

    echo "--- Kernel compilation completed!"
    
    g++ -g -O0 -Wall -L../../build/runtime -L../../build/runtime/threadPool -L${VORTEX_PATH}/runtime/lib -I${VORTEX_PATH}/kernel/include -o host.out -fPIC -no-pie host.o host_vortexrt.o  -lc -lvortexRuntime -lvortex -lThreadPool -lpthread 
    echo "--- Host compilation completed!"

    # simx performance counter settings
    export PERF_CLASS=2
    LD_LIBRARY_PATH=../../build/runtime/threadPool:${VORTEX_PATH}/runtime/lib:../../build/runtime:${LD_LIBRARY_PATH} ./host.out 1 1 > res_vortex.log
    echo "--- Execution completed!"
    exit -1
fi
