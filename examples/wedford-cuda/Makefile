KERNEL_CU = main.cu
RUN_ARGS  = 2 2 2 1
include ../common.mk

ifeq ($(SCHEDULE),0)
# Three populated warps reach the shared-memory exchange. Spatial size 33
# also makes lane 0 contribute twice to each first-stage warp reduction.
.PHONY: ci-exchange
ci: ci-exchange
ci-exchange: ci-run
	LD_LIBRARY_PATH=$(LD_LIB_PATH):$(LD_LIBRARY_PATH) PERF_CLASS=2 $(STDBUF_RUN) $(HOST_PREFIX) ./host.out 3 33 2 1
endif
