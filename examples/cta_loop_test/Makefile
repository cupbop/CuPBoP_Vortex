KERNEL_CU = cta_loop_test.cu
RUN_ARGS  = -r 1
CI_RUN_ARGS  = -r 1
# the test of CUPBOP_CTA_LOOP has the loop, whatever the default is; CUPBOP_CTA_LOOP=off in the environment gives the plain translation
export CUPBOP_CTA_LOOP ?= auto
include ../common.mk
