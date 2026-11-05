# Several modules in one process (ci/multi_module_test.sbatch). `make ci` builds the modules and runs the orders of host.cpp.
# Not a common.mk example: its one program launches modules from other directories, as the Triton backend does.
# mmt_<source>_s<schedule>; launchfix and lmemhi are modules of another source that get a side file below.
MODULES = mmt_small_s1 mmt_big_s1 mmt_small_s2 mmt_big_s2 mmt_static_s1 mmt_static_s2 mmt_static2_s2 mmt_launchfix_s2 mmt_lmemhi_s2
SRC_launchfix = small
SRC_lmemhi = static2
ORDERS ?= s1 s2 mixed lmem
RT = ../../build/runtime
# the libvortexRuntime.so the program loads: another tree's for a control run
RT_LIB ?= $(RT)
CUDA_MODULE = $(MAKE) -C $(1) -f ../module.mk SRC=$(2) SCHEDULE=$(3) kernel.vxbin lookup_global_symbols.txt
SOURCE = $(or $(SRC_$(1)),$(1))

.PHONY: all ci clean

all: ci

mmt_%/kernel.vxbin: small.cu big.cu static.cu static2.cu module.mk
	mkdir -p mmt_$*
	$(call CUDA_MODULE,mmt_$*,$(call SOURCE,$(word 1,$(subst _, ,$*))),$(patsubst s%,%,$(word 2,$(subst _, ,$*))))

# What a translator pass leaves for such a kernel, by hand: the launch's dynamic shared size replaced; a kernel that touches less than it declares.
mmt_launchfix_s2/cupbop_launch_fix.txt: mmt_launchfix_s2/kernel.vxbin
	awk '{print $$2, "dyn_smem=512"}' mmt_launchfix_s2/lookup.txt > $@
mmt_lmemhi_s2/kernel_lmem_hi.log: mmt_lmemhi_s2/kernel.vxbin
	awk '{print $$2, 128, 1, 1, 1024}' mmt_lmemhi_s2/lookup.txt > $@

host.out: host.cpp
	g++ -g -O1 -Wall -o $@ host.cpp -L$(RT) -L$(RT)/threadPool -L$(VORTEX_PATH)/sw/runtime -lvortexRuntime -lvortex -lThreadPool -lpthread

ci: host.out $(MODULES:%=%/kernel.vxbin) mmt_launchfix_s2/cupbop_launch_fix.txt mmt_lmemhi_s2/kernel_lmem_hi.log
	@rm -f ci_output.txt
	@for o in $(ORDERS); do \
	  LD_LIBRARY_PATH=$(RT_LIB):$(RT)/threadPool:$(VORTEX_PATH)/sw/runtime:$(LD_LIBRARY_PATH) PERF_CLASS=2 ./host.out $$o 2>&1 | grep -v '^output file:' | tee -a ci_output.txt; \
	done

clean:
	rm -rf $(MODULES) host.out ci_output.txt perf.jsonl
	rm -rf $(VORTEX_PATH)/tests/regression/cupbop_mmt_*
