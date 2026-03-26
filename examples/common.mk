# common.mk — Shared CuPBoP build pipeline for Vortex examples
#
# Usage in per-example Makefile:
#   KERNEL_CU = mykernel.cu
#   RUN_ARGS  = -n 1024
#   include ../common.mk
#
# Override from command line:
#   make ARCH=32 SCHEDULE=0 STARTUP_ADDR=0x80000000 LOG=result.txt

.PHONY: all build run clean ci ci-run cuda-build cuda-run

# ─── Required env vars ────────────────────────────────────────────────────────
ifndef VORTEX_PATH
  $(error VORTEX_PATH is not set)
endif
ifndef CuPBoP_PATH
  $(error CuPBoP_PATH is not set)
endif
ifndef LLVM_PREFIX
  $(error LLVM_PREFIX is not set)
endif
ifndef VORTEX_HOME
  $(error VORTEX_HOME is not set)
endif

# ─── Defaults ─────────────────────────────────────────────────────────────────
ARCH           ?= 64
SCHEDULE       ?= 2
STARTUP_ADDR   ?= 0x080000000
EXTRA_C_SRCS   ?=
EXTRA_CLANG_FLAGS ?=
RUN_ARGS       ?=

KERNEL          = $(basename $(notdir $(KERNEL_CU)))
CUDA_PATH      ?= $(CuPBoP_PATH)/cuda-12.1

export VORTEX_SCHEDULE_FLAG := $(SCHEDULE)

# ─── Toolchain ────────────────────────────────────────────────────────────────
LLVM_BIN = $(LLVM_PREFIX)/bin

ifeq ($(ARCH),32)
  RISCV_SYSROOT  = $(RISCV_TOOLCHAIN)/riscv32-unknown-elf
  RISCV_FOLDER   = $(RISCV_TOOLCHAIN)
  VX_CFLAGS      = -O3 -std=c++11 --sysroot=$(RISCV_SYSROOT) \
                   --target=riscv32 -march=rv32imf -mabi=ilp32f \
                   -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles \
                   -fdata-sections -ffunction-sections \
                   -I$(VORTEX_HOME)/kernel/include -I$(VORTEX_PATH)/kernel/../hw
  VX_LDFLAGS     = -Wl,-Bstatic,-T,$(VORTEX_HOME)/kernel/linker/vx_link32.ld,--defsym=XLEN=32,--defsym=STARTUP_ADDR=$(STARTUP_ADDR) \
                   -Wl,--gc-sections $(VORTEX_PATH)/kernel/libvortexrt.a
  CUDA_KERNEL_IMPL = $(CuPBoP_PATH)/runtime/src/vortex/kernel/cudaKernelImpl.o
else
  RISCV_SYSROOT  = $(RISCV_TOOLCHAIN)/riscv64-unknown-elf
  RISCV_FOLDER   = $(RISCV_TOOLCHAIN)
  VX_CFLAGS      = -O3 --sysroot=$(RISCV_SYSROOT) \
                   --gcc-toolchain=$(TOOLDIR)/riscv64-gnu-toolchain \
                   -march=rv64imafd -mabi=lp64d \
                   -mcmodel=medany -fno-rtti -fno-exceptions -nostartfiles -nostdlib \
                   -fdata-sections -ffunction-sections \
                   -I$(VORTEX_HOME)/kernel/include -I$(VORTEX_PATH)/kernel/../hw \
                   -DXLEN_64 -DNDEBUG
  VX_LDFLAGS     = -Wl,-Bstatic,--gc-sections,-T,$(VORTEX_HOME)/kernel/scripts/link64.ld,--defsym=STARTUP_ADDR=$(STARTUP_ADDR) \
                   $(VORTEX_HOME)/build/kernel/libvortex.a \
                   -L$(TOOLDIR)/libc64/lib -lm -lc \
                   $(TOOLDIR)/libcrt64/lib/baremetal/libclang_rt.builtins-riscv64.a
  CUDA_KERNEL_IMPL = $(CuPBoP_PATH)/runtime/src/vortex/kernel/cudaKernelImpl_64.o
endif

VX_VXFLAGS = -Xclang -target-feature -Xclang +vortex \
             -Xclang -target-feature -Xclang +zicond \
             -mllvm -disable-loop-idiom-all

# ─── Derived ──────────────────────────────────────────────────────────────────
DEVICE_BC  = $(KERNEL)-cuda-nvptx64-nvidia-cuda-sm_50.bc
HOST_BC    = $(KERNEL)-host-x86_64-unknown-linux-gnu.bc
EXTRA_OBJS = $(patsubst %.c,%.o,$(EXTRA_C_SRCS))

LD_LIB_PATH = ../../build/runtime/threadPool:$(VORTEX_PATH)/runtime:$(VORTEX_PATH)/runtime/lib:../../build/runtime

# ─── Top-level targets ────────────────────────────────────────────────────────
all: build run

ci: build ci-run

ci-run: build
	@echo "--- Running (CI)"
	LD_LIBRARY_PATH=$(LD_LIB_PATH):$(LD_LIBRARY_PATH) PERF_CLASS=2 ./host.out $(CI_RUN_ARGS) | tee ci_output.txt
	@echo "--- Execution completed!"

CI_RUN_ARGS ?= $(RUN_ARGS)

build: host.out kernel.vxbin kernel.dump

ifdef LOG
run: build
	@echo "--- Running (output -> $(LOG))"
	LD_LIBRARY_PATH=$(LD_LIB_PATH):$(LD_LIBRARY_PATH) PERF_CLASS=2 ./host.out $(RUN_ARGS) > $(LOG)
	@echo "--- Execution completed!"
else
run: build
	@echo "--- Running"
	LD_LIBRARY_PATH=$(LD_LIB_PATH):$(LD_LIBRARY_PATH) PERF_CLASS=2 ./host.out $(RUN_ARGS)
	@echo "--- Execution completed!"
endif

# ─── CUDA GPU golden reference ───────────────────────────────────────────────
NVCC ?= nvcc

cuda-build: $(KERNEL_CU) $(EXTRA_C_SRCS)
	$(NVCC) -O2 -ccbin g++-11 -o cuda_$(KERNEL).out $(KERNEL_CU) $(EXTRA_C_SRCS)

cuda-run: cuda-build
	./cuda_$(KERNEL).out $(CI_RUN_ARGS) | tee golden_output.txt
	@echo "--- Golden output saved to golden_output.txt"

clean:
	rm -f *.out *.o *.dump *.log *.ll *.bc *.elf *.vxbin *.bin
	rm -f *.cui *.cubin *.fatbin *.s
	rm -f lookup.txt lookup_global_symbols.txt
	rm -f kernel_wrapper.cpp ci_output.txt
	rm -f $(EXTRA_OBJS)

# ─── Step 1: CUDA source -> bitcode ──────────────────────────────────────────
$(DEVICE_BC): $(KERNEL_CU)
	@echo "--- Generate bitcode files for host and device"
	$(LLVM_BIN)/clang++ -O0 -g -std=c++11 $(EXTRA_CLANG_FLAGS) \
		./$(KERNEL_CU) --sysroot=/ --target=x86_64-linux-gnu \
		-L$(CUDA_PATH)/lib64 --cuda-gpu-arch=sm_50 \
		-lcudart_static -ldl -lrt -pthread -save-temps -v 2>&1 || true

$(HOST_BC): $(DEVICE_BC)
	@true

# ─── Step 2: kernelTranslator -> kernel.bc + kernel_wrapper.cpp ──────────────
kernel.bc kernel_wrapper.cpp kernel_meta.log: $(DEVICE_BC)
	@echo "--- Translate kernel bitcode"
	$(CuPBoP_PATH)/build/compilation/kernelTranslator $< kernel.bc
	llvm-dis kernel.bc

# ─── Step 3: hostTranslator -> host.bc -> host.o ─────────────────────────────
# hostTranslator reads kernel_meta.log (generated by kernelTranslator)
host.bc: $(HOST_BC) kernel_meta.log
	@echo "--- Translate host bitcode"
	$(CuPBoP_PATH)/build/compilation/hostTranslator $< $@
	llvm-dis $@

host.o: host.bc
	llc --relocation-model=pic --filetype=obj $< -o $@

# ─── Step 4: Extra C sources ─────────────────────────────────────────────────
%.o: %.c
	gcc -g -O0 $< -c -o $@

# ─── Step 5: kernel.o ────────────────────────────────────────────────────────
kernel.o: kernel.bc
	@echo "--- Compiling kernel.bc"
	$(LLVM_BIN)/clang++ $(VX_CFLAGS) $(VX_VXFLAGS) $< -c -o $@ > kernel.log 2>&1

# ─── Step 6: kernel_wrapper.o ────────────────────────────────────────────────
kernel_wrapper.o: kernel_wrapper.cpp
	@echo "--- Compiling kernel_wrapper.cpp"
	$(LLVM_BIN)/clang++ $(VX_CFLAGS) $(VX_VXFLAGS) --gcc-toolchain=$(RISCV_FOLDER) $< -c -o $@
	$(LLVM_BIN)/llvm-objdump -D $@ > kernel_wrapper.dump

# ─── Step 7: kernel.elf ──────────────────────────────────────────────────────
kernel.elf: kernel_wrapper.o kernel.o $(CUDA_KERNEL_IMPL)
	@echo "--- Linking kernel.elf"
	$(LLVM_BIN)/clang++ $(VX_CFLAGS) $(VX_VXFLAGS) --gcc-toolchain=$(RISCV_FOLDER) \
		$^ -lm $(VX_LDFLAGS) -o $@
	@echo "--- Kernel compilation completed!"

# ─── Step 8: symbols, vxbin, dump ────────────────────────────────────────────
lookup_global_symbols.txt: kernel.elf
	nm -C --defined-only -g $< > $@

kernel.vxbin: kernel.elf
	OBJCOPY=$(LLVM_BIN)/llvm-objcopy $(VORTEX_HOME)/kernel/scripts/vxbin.py $< $@

kernel.dump: kernel.elf
	$(LLVM_BIN)/llvm-objdump -D $< > $@

# ─── Step 9: host.out ────────────────────────────────────────────────────────
host.out: host.o $(EXTRA_OBJS) kernel.vxbin lookup_global_symbols.txt
	@echo "--- Linking host.out"
	g++ -g -O0 -Wall \
		-L../../build/runtime -L../../build/runtime/threadPool \
		-L$(VORTEX_PATH)/runtime/ -L$(VORTEX_PATH)/runtime/lib/ -I$(VORTEX_PATH)/kernel/include \
		-o $@ -fPIC -no-pie \
		host.o $(EXTRA_OBJS) \
		-lc -lvortexRuntime -lvortex -lThreadPool -lpthread
	@echo "--- Host compilation completed!"
