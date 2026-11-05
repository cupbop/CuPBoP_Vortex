# Several modules in one process (ci/multi_module_test.sbatch). `make ci` builds four modules and runs the three orders of
# host.cpp. Not a common.mk example: its one program launches modules from other directories, as the Triton backend does.
MODULES = mmt_small_s1 mmt_big_s1 mmt_small_s2 mmt_big_s2
ORDERS ?= s1 s2 mixed
RT = ../../build/runtime
RT_LIB ?= $(RT)   # the libvortexRuntime.so the program loads: another tree's for a control run
CUDA_MODULE = $(MAKE) -C $(1) -f ../module.mk SRC=$(2) SCHEDULE=$(3) kernel.vxbin lookup_global_symbols.txt

.PHONY: all ci clean

all: ci

mmt_%/kernel.vxbin: small.cu big.cu module.mk
	mkdir -p mmt_$*
	$(call CUDA_MODULE,mmt_$*,$(word 1,$(subst _, ,$*)),$(patsubst s%,%,$(word 2,$(subst _, ,$*))))

host.out: host.cpp
	g++ -g -O1 -Wall -o $@ host.cpp -L$(RT) -L$(RT)/threadPool -L$(VORTEX_PATH)/sw/runtime -lvortexRuntime -lvortex -lThreadPool -lpthread

ci: host.out $(MODULES:%=%/kernel.vxbin)
	@rm -f ci_output.txt
	@for o in $(ORDERS); do \
	  LD_LIBRARY_PATH=$(RT_LIB):$(RT)/threadPool:$(VORTEX_PATH)/sw/runtime:$(LD_LIBRARY_PATH) PERF_CLASS=2 ./host.out $$o 2>&1 | grep -v '^output file:' | tee -a ci_output.txt; \
	done

clean:
	rm -rf $(MODULES) host.out ci_output.txt
	rm -rf $(VORTEX_PATH)/tests/regression/cupbop_mmt_*
