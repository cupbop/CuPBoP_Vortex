all: cudaKernelImpl.o cudaKernelImpl_64.o
#	/data/ahnch/toolchain_install/bin/riscv32-unknown-elf-g++ -I ../../../include -lm -I ../../../threadPool/include -o cudaKernelImpl.o -c cudaKernelImpl.cpp
#	/data/ahnch/toolchain_install/bin/riscv32-unknown-elf-objdump -d cudaKernelImpl.o > cudaKernelImpl.dump

# MARK: compilation including the new math library libm.a 32bit
	${LLVM_PREFIX}/bin/clang++ -v -O3 -march=rv32imf -mabi=ilp32f -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -fdata-sections -ffunction-sections --gcc-toolchain=${RISCV_TOOLCHAIN_PATH} -L${VORTEX_PATH}/kernel/include -I${VORTEX_PATH}/kernel/../hw -I${CuPBoP_PATH}/runtime/include -I${CuPBoP_PATH}/runtime/threadPool/include -L/data/ahnch/riscv-gnu-toolchain_working/build-newlib/riscv32-unknown-elf/newlib/libm/libm.a -Xclang -target-feature -Xclang +vortex -o cudaKernelImpl.o -c cudaKernelImpl.cpp
	
	${LLVM_PREFIX}/bin/llvm-objdump -D cudaKernelImpl.o > cudaKernelImpl.dump

# MARK: compilation including the new math library libm.a 64bit
	${LLVM_PREFIX}/bin/clang++ -v -O3 --sysroot=${RISCV_TOOLCHAIN}/riscv64-unknown-elf --gcc-toolchain=${TOOLDIR}/riscv64-gnu-toolchain -march=rv64imafd -mabi=lp64d -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -nostdlib -fdata-sections  -finline-functions -ffunction-sections -I${VORTEX_HOME}/kernel/include -I${VORTEX_PATH}/kernel/../hw -DXLEN_64 -DNDEBUG -I${CuPBoP_PATH}/runtime/include -I${CuPBoP_PATH}/runtime/threadPool/include -L/data/ahnch/riscv-gnu-toolchain_working/build-newlib/riscv64-unknown-elf/newlib/libm/libm.a -Xclang -target-feature -Xclang +vortex -mllvm -disable-loop-idiom-all -o cudaKernelImpl_64.o -c cudaKernelImpl.cpp

# ${LLVM_PREFIX}/bin/clang++ -v -O3 --sysroot=/opt/riscv64-gnu-toolchain/riscv64-unknown-elf --target=riscv64 -march=rv64imafd -mabi=lp64d -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -fdata-sections -ffunction-sections --gcc-toolchain=/opt/riscv64-gnu-toolchain -I${VORTEX_PATH}/kernel/include -I${VORTEX_PATH}/kernel/../hw -I${CuPBoP_PATH}/runtime/include -I${CuPBoP_PATH}/runtime/threadPool/include -L/data/ahnch/riscv-gnu-toolchain_working/build-newlib/riscv64-unknown-elf/newlib/libm/libm.a -Xclang -target-feature -Xclang +vortex -o cudaKernelImpl_64.o -c cudaKernelImpl.cpp

	${LLVM_PREFIX}/bin/llvm-objdump -D cudaKernelImpl_64.o > cudaKernelImpl_64.dump

#MARK: PREVIOUS APPROCH, commented out since it doesn't include vortex digergence
#	${RISCV_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-g++ -I ../../../include -lm -I ../../../threadPool/include -o cudaKernelImpl.o -c cudaKernelImpl.cpp
#	${RISCV_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-objdump -d cudaKernelImpl.o > cudaKernelImpl.dump
clean:
	rm *.o../