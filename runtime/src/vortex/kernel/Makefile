all: cudaKernelImpl.o
	${RISCV_TOOLCHAIN}/riscv32-unknown-elf-g++ -I ../../../include -I ../../../threadPool/include -o cudaKernelImpl.o -c cudaKernelImpl.cpp
clean:
	rm *.o