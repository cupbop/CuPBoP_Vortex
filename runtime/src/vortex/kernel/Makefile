all: cudaKernelImpl.o
#	/data/ahnch/toolchain_install/bin/riscv32-unknown-elf-g++ -I ../../../include -lm -I ../../../threadPool/include -o cudaKernelImpl.o -c cudaKernelImpl.cpp
#	/data/ahnch/toolchain_install/bin/riscv32-unknown-elf-objdump -d cudaKernelImpl.o > cudaKernelImpl.dump

# MARK: compilation including the new math library libm.a
	${LLVM_PREFIX}/bin/clang++ -v -O3 -march=rv32imf -mabi=ilp32f -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -fdata-sections -ffunction-sections --gcc-toolchain=${RISCV_TOOLCHAIN_PATH} -I${VORTEX_PATH}/kernel/include -I${VORTEX_PATH}/kernel/../hw -I${CuPBoP_PATH}/runtime/include -I${CuPBoP_PATH}/runtime/threadPool/include -L/data/ahnch/riscv-gnu-toolchain_working/build-newlib/riscv32-unknown-elf/newlib/libm/libm.a -Xclang -target-feature -Xclang +vortex -o cudaKernelImpl.o -c cudaKernelImpl.cpp


	${LLVM_PREFIX}/bin/llvm-objdump -mattr=+m,+f,+vortex -D cudaKernelImpl.o > cudaKernelImpl.dump

#MARK: PREVIOUS APPROCH, commented out since it doesn't include vortex digergence
#	${RISCV_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-g++ -I ../../../include -lm -I ../../../threadPool/include -o cudaKernelImpl.o -c cudaKernelImpl.cpp
#	${RISCV_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-objdump -d cudaKernelImpl.o > cudaKernelImpl.dump
clean:
	rm *.o../