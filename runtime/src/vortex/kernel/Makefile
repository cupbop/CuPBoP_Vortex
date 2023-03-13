all: cudaKernelImpl.o
#	/data/ahnch/toolchain_install/bin/riscv32-unknown-elf-g++ -I ../../../include -lm -I ../../../threadPool/include -o cudaKernelImpl.o -c cudaKernelImpl.cpp
#	/data/ahnch/toolchain_install/bin/riscv32-unknown-elf-objdump -d cudaKernelImpl.o > cudaKernelImpl.dump
	/data/ahnch/riscv-gnu-toolchain/bin/riscv32-unknown-elf-g++ -I ../../../include -lm -I ../../../threadPool/include -o cudaKernelImpl.o -c cudaKernelImpl.cpp
	/data/ahnch/riscv-gnu-toolchain/bin/riscv32-unknown-elf-objdump -d cudaKernelImpl.o > cudaKernelImpl.dump
clean:
	rm *.o