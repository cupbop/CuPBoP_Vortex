# lift.mk: examples whose device code is LLVM IR lifted from machine code (CuLifter) instead of CUDA C. The .cu file gives the host program only.
# ci/lift_test.sh runs them with the rows of ci/lift_cases.txt. Usage in an example Makefile:
#   KERNEL_CU = kernel.cu
#   include ../lift.mk
# LIFT_INPUT picks the file <LIFT_INPUT>.ll.xz of the example:
#   raw   the IR as it comes out of the lifter (plus the documented lifter fix-ups)
#   pre   raw through the lift optimisation that still runs outside the translator (experiments/p3/scripts/mkp3.sh). With the translator doing it
#         (CUPBOP_LIFT_OPT, branch integ-lo) the same row runs as LIFT_INPUT=raw CUPBOP_LIFT_OPT=1 and pre.ll.xz can go
#   other a variant kept as a regression input
# LIFT_IR_FILE names a file directly (negative controls). The module goes alone through always-inline, globaldce and kernelTranslator (as the
# library runs do). LIFT_MERGE=1 (a program with more kernels than the lift has): the source kernels stay and the lifted one replaces its namesake,
# which stays under the name __src_<kernel> and is never launched. lift_d2h.c records the bits of every device-to-host copy.
LIFT_INPUT   ?= raw
LIFT_IR_FILE ?= $(LIFT_INPUT).ll.xz
LIFT_MERGE   ?= 0
DEVICE_BC_SRC = lift_src.bc
LIFT_DIR     := $(dir $(lastword $(MAKEFILE_LIST)))
EXTRA_C_SRCS += lift_d2h.c
include $(LIFT_DIR)common.mk
ifeq ($(LIFT_MERGE),1)
$(DEVICE_BC): $(LIFT_IR_FILE) $(DEVICE_BC_SRC)
	@echo "--- Device bitcode: lifted IR $< beside the source kernels"
	xz -dc $< > lift_in.ll
	$(LLVM_BIN)/llvm-as lift_in.ll -o lift_in.bc
	$(LLVM_BIN)/llvm-dis $(DEVICE_BC_SRC) -o lift_src.ll
	k=$$(grep -m1 '^define' lift_in.ll | sed 's/(.*//' | awk '{print $$NF}' | tr -d '@"'); \
	  sed "s/@$${k}\b/@__src_$${k}/g; s/\"$${k}\"/\"__src_$${k}\"/g; s/\$$$${k}\b/\$$__src_$${k}/g" lift_src.ll > lift_src2.ll
	$(LLVM_BIN)/llvm-as lift_src2.ll -o lift_src2.bc
	$(LLVM_BIN)/llvm-link --suppress-warnings lift_src2.bc lift_in.bc -o $@
else
$(DEVICE_BC): $(LIFT_IR_FILE)
	@echo "--- Device bitcode from lifted IR $<"
	xz -dc $< > lift_in.ll
	$(LLVM_BIN)/llvm-as lift_in.ll -o lift_in.bc
	$(LLVM_BIN)/opt -passes=always-inline,globaldce lift_in.bc -o $@
endif
lift_d2h.o: $(LIFT_DIR)lift_d2h.c
	gcc -g -O1 -c $< -o $@
