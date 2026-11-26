# Regenerate raw.ll.xz in this directory with CUDA 12.1 and the CuLifter Python environment:
#   nvcc -arch=sm_80 -cubin main.cu -o sm80.cubin
#   cuobjdump -sass sm80.cubin > sm80.sass
#   python "$CULIFTER_HOME/main.py" -i sm80.sass sm80.cubin -o raw --lifter nvvm --const-mem-linkage internal
#   xz -c raw.ll > raw.ll.xz
KERNEL_CU = main.cu
include ../lift.mk
