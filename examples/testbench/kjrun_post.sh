    rm kernel.elf kernel.o kernel.bc kernel.dump kernel.out
    llvm-as kernel.ll
    /opt/llvm-riscv/bin/clang++ -std=c++11 --target=riscv32 -march=rv32imf -mabi=ilp32f -Xclang -target-feature -Xclang +vortex kernel.bc -c -o kernel.o
    $RISCV_TOOLCHAIN/riscv32-unknown-elf-g++ -o kernel_wrapper.o -march=rv32imf -mabi=ilp32f -Wstack-usage=1024 -mcmodel=medany -ffreestanding -nostartfiles -fdata-sections -ffunction-sections -I${VORTEX_PATH}/runtime/include -I${VORTEX_PATH}/runtime/../hw -c ../vortex_debug/kernel_wrapper.cpp  -Wl,--gc-sections
    $RISCV_TOOLCHAIN/riscv32-unknown-elf-g++ -march=rv32imf -mabi=ilp32f -Wstack-usage=1024 -mcmodel=medany -ffreestanding -nostartfiles -fdata-sections -ffunction-sections -I${VORTEX_PATH}/runtime/include -I${VORTEX_PATH}/runtime/../hw kernel_wrapper.o kernel.o -lm -Wl,-Bstatic,-T,${VORTEX_PATH}/runtime/linker/vx_link32.ld -Wl,--gc-sections ${VORTEX_PATH}/runtime/libvortexrt.a -o kernel.elf 
    /opt/llvm-riscv/bin/llvm-objcopy -O binary kernel.elf kernel.out
    /opt/llvm-riscv/bin/llvm-objdump -D kernel.elf > kernel.dump
    /opt/llvm-riscv/bin/llvm-objdump -C --line-numbers --no-leading-addr --no-show-raw-insn kernel.o > kernel_src.dump
    
    echo "!!!!"
    g++ -g -O0 -Wall -L../../build/runtime  -L../../build/runtime/threadPool  -L${VORTEX_PATH}/driver/stub -I${VORTEX_PATH}/runtime/include -o host.out -fPIC -no-pie host.o host_vortexrt.o  -lc -lvortexRuntime -lvortex -lThreadPool -lpthread 
    DPRINT "--- Run the kernel on vortex"
    LD_LIBRARY_PATH=../../build/runtime/threadPool:${VORTEX_PATH}/driver/simx:../../build/runtime:${LD_LIBRARY_PATH} ./host.out -q -v