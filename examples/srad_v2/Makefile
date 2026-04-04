KERNEL_CU = srad.cu
RUN_ARGS  = 128 128 0 127 0 127 0.5 2
# -O0 to prevent CFGSimplification from recreating switch instructions
# after lowerswitch, which crashes Vortex's UnifyLoopExits pass.
KERNEL_OPT = -O0
include ../common.mk
