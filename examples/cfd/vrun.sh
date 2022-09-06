#!/bin/bash

# exit when any command fails
set -e

######################### Default Varaibles #################################
DEVICE=vortex
KERNEL_CU=euler3d.cu
#############################################################################

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

if [ -z "$RISCV_TOOLCHAIN" ]
then
    echo "You need to set "\$RISCV_TOOLCHAIN" environment variable"
    exit -1
fi
RISCV_TOOLCHAIN_PREFIX=$RISCV_TOOLCHAIN/riscv32-unknown-elf-
CUDA_PATH=$CuPBoP_PATH/cuda-10.1

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

DPRINT "--- Generate bitcode files(.bc) for host and device by using clang++"
#clang++ -g -std=c++11  ./$KERNEL_CU -I../.. --cuda-path=$CUDA_PATH --cuda-gpu-arch=sm_50 -L$CUDA_PATH/lib64  -lcudart_static -ldl -lrt -pthread -save-temps -v  || true
clang++ euler3d.cu -I$CUDA_PATH/samples/common/inc --cuda-path=$CUDA_PATH --cuda-gpu-arch=sm_50 -L$CUDA_PATH/lib64 -lcudart_static -ldl -lrt -pthread -save-temps -v


DPRINT "--- Generate LLVM IR files(.ll) for host and device"
llvm-dis $KERNEL-cuda-nvptx64-nvidia-cuda-sm_50.bc
llvm-dis $KERNEL-host-x86_64-unknown-linux-gnu.bc

DPRINT "--- Translate the kernel bitcode by using CuPBoP's kernel translator"

#$CuPBoP_PATH/build/compilation/kernelTranslator.x86 $KERNEL-cuda-nvptx64-nvidia-cuda-sm_50.bc kernel_host.bc 
$CuPBoP_PATH/build/compilation/kernelTranslator $KERNEL-cuda-nvptx64-nvidia-cuda-sm_50.bc kernel.bc 
llvm-dis kernel.bc

DPRINT "--- Translate the host bitcode by using CuPBoP's host translator"
$CuPBoP_PATH/build/compilation/hostTranslator $KERNEL-host-x86_64-unknown-linux-gnu.bc host.bc
llvm-dis host.bc 
llc --relocation-model=pic --filetype=obj  host.bc

DPRINT "--- Copy  kernel bitcode  for host link"
#llc --relocation-model=pic --filetype=obj  kernel_host.bc
llc --relocation-model=pic --filetype=obj  kernel.bc
g++ -g -O0 -o host_vortexrt.o -c host_vortexrt.cpp 

DPRINT "--- Compile the translated bc code for $DEVICE"
if [ $DEVICE = "x86" ]
then
    llc --relocation-model=pic --filetype=obj  kernel.bc
    llc --relocation-model=pic --filetype=obj  host.bc
    g++ -Wall -L../../build/runtime  -L../../build/runtime/threadPool  -L${VORTEX_PATH}/driver/simx/ -o ${KERNEL}.out -fPIC -no-pie host.o kernel.o  -lc -lx86Runtime    -lvortex  -lthreadPool -lpthread 
    DPRINT "--- Run the executable file."
    ./${KERNEL}.out -q -v
elif [ $DEVICE = "simx" ]
then
    clang++ -std=c++11 --target=riscv32 -march=rv32imf -mabi=ilp32f kernel.bc -c -o kernel.o 
    ${RISCV_TOOLCHAIN_PREFIX}gcc -march=rv32imf -mabi=ilp32f -Wstack-usage=1024 -mcmodel=medany -ffreestanding -nostartfiles -fdata-sections -ffunction-sections -I${VORTEX_PATH}/runtime/include -I${VORTEX_PATH}/runtime/../hw main.cc kernel.o -lm -Wl,-Bstatic,-T,${VORTEX_PATH}/runtime/linker/vx_link32.ld -Wl,--gc-sections ${VORTEX_PATH}/runtime/libvortexrt.a -o kernel.elf 
    ${RISCV_TOOLCHAIN_PREFIX}objcopy -O binary kernel.elf kernel.bin
    ${RISCV_TOOLCHAIN_PREFIX}objdump -D kernel.elf > kernel.dump
    DPRINT "--- Run the kernel on simx"
    ${VORTEX_PATH}/sim/simx/simx -r -c 1 -i kernel.bin -s
elif [ $DEVICE = "vortex" ]
then
    echo "!!!!!" 
    clang++ -std=c++11 --target=riscv32 -march=rv32imf -mabi=ilp32f kernel.bc -c -o kernel.o
    ${RISCV_TOOLCHAIN_PREFIX}g++ -o kernel_wrapper.o -march=rv32imf -mabi=ilp32f -Wstack-usage=1024 -mcmodel=medany -ffreestanding -nostartfiles -fdata-sections -ffunction-sections -I${VORTEX_PATH}/runtime/include -I${VORTEX_PATH}/runtime/../hw -c kernel_wrapper.cpp  -Wl,--gc-sections
    ${RISCV_TOOLCHAIN_PREFIX}g++ -march=rv32imf -mabi=ilp32f -Wstack-usage=1024 -mcmodel=medany -ffreestanding -nostartfiles -fdata-sections -ffunction-sections -I${VORTEX_PATH}/runtime/include -I${VORTEX_PATH}/runtime/../hw kernel_wrapper.o kernel.o -lm -Wl,-Bstatic,-T,${VORTEX_PATH}/runtime/linker/vx_link32.ld -Wl,--gc-sections ${VORTEX_PATH}/runtime/libvortexrt.a -o kernel.elf 
    ${RISCV_TOOLCHAIN_PREFIX}objcopy -O binary kernel.elf kernel.out
    ${RISCV_TOOLCHAIN_PREFIX}objdump -D kernel.elf > kernel.dump
    echo "!!!!"
    g++ -g -O0 -Wall -L../../build/runtime  -L../../build/runtime/threadPool  -L${VORTEX_PATH}/driver/stub -I${VORTEX_PATH}/runtime/include -o host.out -fPIC -no-pie host.o host_vortexrt.o  -lc -lvortexRuntime -lvortex -lThreadPool -lpthread 
    DPRINT "--- Run the kernel on vortex"
    LD_LIBRARY_PATH=../../build/runtime/threadPool:${VORTEX_PATH}/driver/simx:../../build/runtime:${LD_LIBRARY_PATH} 
    ./host.out -f ../../data/rodinia-data/gaussian/matrix4.txt
    #./host.out -q -v
    
    echo "finished"
    #echo "$DEVICE is invalid"
    #exit -1
fi
