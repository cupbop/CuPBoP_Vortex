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
VX_SRCS := $(CUPBOP_WORK)/kernel.bc $(CUPBOP_WORK)/kernel_wrapper.cpp $(CuPBoP_PATH)/runtime/src/vortex/kernel/cudaKernelImpl.cpp \
           $(CuPBoP_PATH)/runtime/src/vortex/kernel/nv_libdevice_compat.cpp
KERNEL_LIB := vortex

include ../common.mk

VX_CFLAGS += -I$(CuPBoP_PATH)/runtime/include -I$(CuPBoP_PATH)/runtime/threadPool/include \
             -I$(CuPBoP_PATH)/runtime/include/cuda_stub -I$(CuPBoP_PATH)/compilation/KernelTranslation/include
VX_CFLAGS += -DXLEN_64 -DNUM_CORES=$(VORTEX_NUM_CORES) -DNUM_WARPS=$(VORTEX_NUM_WARPS) -DNUM_THREADS=$(VORTEX_NUM_THREADS)
# CuPBoP's generated wrapper and device runtime are not warning-clean under Vortex's -Wall -Werror.
VX_CFLAGS += -Wno-error -w -mllvm -disable-loop-idiom-all
