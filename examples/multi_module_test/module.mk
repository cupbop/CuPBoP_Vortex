# One module of multi_module_test, built in its own directory: make -f ../module.mk SRC=<small|big> SCHEDULE=<1|2> kernel.vxbin lookup_global_symbols.txt
KERNEL_CU = ../$(SRC).cu
# every context array in the scratch buffer: a module of this size gets __ctx_pool, as the large Triton kernels do
export CUPBOP_CTX_SCRATCH = on
include ../../common.mk
