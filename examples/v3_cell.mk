# Vortex 3.0 kernel-ELF cell for CuPBoP examples (used when VORTEX_VER=3 in examples/common.mk).
# Copied into $(VORTEX_PATH)/tests/regression/<cell>/Makefile so that Vortex's own
# tests/regression/common.mk builds kernel.elf/kernel.vxbin: startup code (vx_start.S two-pass link),
# linker script, libvortex.a, libc/libcrt and the generated VX_CFG_* flags all stay upstream's.
# Variables passed on the make command line: CUPBOP_WORK (example dir holding kernel.bc and
# kernel_wrapper.cpp), CuPBoP_PATH, VORTEX_HOME (Vortex source root), CONFIGS (same as the SimX build),
# VORTEX_NUM_CORES/WARPS/THREADS.
ROOT_DIR := $(realpath ../../..)
include $(ROOT_DIR)/config.mk

PROJECT := cupbop_kernel
SRCS := $(CUPBOP_WORK)/dummy_host.cpp
CUPBOP_RT_SRCS := $(CuPBoP_PATH)/runtime/src/vortex/kernel/cudaKernelImpl.cpp \
                  $(CuPBoP_PATH)/runtime/src/vortex/kernel/nv_libdevice_compat.cpp
CUPBOP_LTO ?= 0
ifeq ($(CUPBOP_LTO),1)
# Link-time inlining (lowering-recipe knob): the device runtime is compiled to bitcode with the
# same flags, llvm-linked into the translated kernel and the merged module is optimized as one
# unit, so the __vx_* / __cupbop_* wrappers inline into the kernel and the fragment/accumulator
# arrays the translator passes to them by pointer become registers (SROA) instead of stack
# traffic in DRAM. Separate objects otherwise.
VX_SRCS := $(CUPBOP_WORK)/kernel_lto.bc $(CUPBOP_WORK)/kernel_wrapper.cpp
$(CUPBOP_WORK)/kernel_lto.bc: $(CUPBOP_WORK)/kernel.bc $(CUPBOP_RT_SRCS)
	$(VX_CXX) $(VX_CFLAGS) -emit-llvm -c $(word 1,$(CUPBOP_RT_SRCS)) -o $(CUPBOP_WORK)/cudaKernelImpl.lto.bc
	$(VX_CXX) $(VX_CFLAGS) -emit-llvm -c $(word 2,$(CUPBOP_RT_SRCS)) -o $(CUPBOP_WORK)/nv_libdevice_compat.lto.bc
	$(LLVM_PATH)/bin/llvm-link $(CUPBOP_WORK)/kernel.bc $(CUPBOP_WORK)/cudaKernelImpl.lto.bc $(CUPBOP_WORK)/nv_libdevice_compat.lto.bc -o $@
else
VX_SRCS := $(CUPBOP_WORK)/kernel.bc $(CUPBOP_WORK)/kernel_wrapper.cpp $(CUPBOP_RT_SRCS)
endif
KERNEL_LIB := vortex

include ../common.mk

VX_CFLAGS += -I$(CuPBoP_PATH)/runtime/include -I$(CuPBoP_PATH)/runtime/threadPool/include \
             -I$(CuPBoP_PATH)/runtime/include/cuda_stub -I$(CuPBoP_PATH)/compilation/KernelTranslation/include
VX_CFLAGS += -DXLEN_64 -DNUM_CORES=$(VORTEX_NUM_CORES) -DNUM_WARPS=$(VORTEX_NUM_WARPS) -DNUM_THREADS=$(VORTEX_NUM_THREADS)
# CuPBoP's generated wrapper and device runtime are not warning-clean under Vortex's -Wall -Werror.
VX_CFLAGS += -Wno-error -w -mllvm -disable-loop-idiom-all
