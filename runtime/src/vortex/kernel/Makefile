all: cudaKernelImpl.o cudaKernelImpl_64.o

# 32-bit RISC-V kernel object file
cudaKernelImpl.o: cudaKernelImpl.cpp
	${LLVM_PREFIX}/bin/clang++ -v -O3 -march=rv32imf -mabi=ilp32f -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -fdata-sections -ffunction-sections --gcc-toolchain=${RISCV_TOOLCHAIN_PATH} -I${VORTEX_HOME}/kernel/include -I${VORTEX_HOME}/build/hw -I${CuPBoP_PATH}/runtime/include -I${CuPBoP_PATH}/runtime/threadPool/include -Xclang -target-feature -Xclang +vortex -o cudaKernelImpl.o -c cudaKernelImpl.cpp
	${LLVM_PREFIX}/bin/llvm-objdump -D cudaKernelImpl.o > cudaKernelImpl.dump

# 64-bit RISC-V kernel object file
cudaKernelImpl_64.o: cudaKernelImpl.cpp
	${LLVM_PREFIX}/bin/clang++ -v -O3 --sysroot=${RISCV_TOOLCHAIN}/riscv64-unknown-elf --gcc-toolchain=${TOOLDIR}/riscv64-gnu-toolchain -march=rv64imafd -mabi=lp64d -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -nostdlib -fdata-sections -finline-functions -ffunction-sections -I${VORTEX_HOME}/kernel/include -I${VORTEX_HOME}/build/hw -DXLEN_64 -DNDEBUG -I${CuPBoP_PATH}/runtime/include -I${CuPBoP_PATH}/runtime/threadPool/include -Xclang -target-feature -Xclang +vortex -mllvm -disable-loop-idiom-all -o cudaKernelImpl_64.o -c cudaKernelImpl.cpp
# emit llvm
	${LLVM_PREFIX}/bin/clang++ -v -O3 \
	--sysroot=${RISCV_TOOLCHAIN}/riscv64-unknown-elf \
	--gcc-toolchain=${TOOLDIR}/riscv64-gnu-toolchain \
	-march=rv64imafd -mabi=lp64d -mcmodel=medany \
	-fno-rtti -fno-exceptions -nostartfiles -nostdlib \
	-fdata-sections -finline-functions -ffunction-sections \
	-I${VORTEX_HOME}/kernel/include -I${VORTEX_HOME}/build/hw \
	-DXLEN_64 -DNDEBUG \
	-I${CuPBoP_PATH}/runtime/include -I${CuPBoP_PATH}/runtime/threadPool/include \
	-Xclang -target-feature -Xclang +vortex \
	-mllvm -disable-loop-idiom-all \
	-S -emit-llvm -o cudaKernelImpl_64.ll \
	cudaKernelImpl.cpp

	${LLVM_PREFIX}/bin/llvm-objdump -D cudaKernelImpl_64.o > cudaKernelImpl_64.dump

clean:
	rm -f *.o *.dump

.PHONY: all clean