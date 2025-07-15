# general
SCRIPTS = $(wildcard */kjrun_llvm18.sh)


# debugging purposes
# all scripts that need to be executed
# SCRIPTS = bfs/kjrun_llvm18.sh


# directories and tracking file(need this to clean up files that were created by the scripts) 
DIRS = $(foreach f,$(SCRIPTS),$(basename $(dir $(f))))
TRACKING = .tracking_files.txt

# all: run benchmarks that have kjrun_llvm18.sh script
# clean: remove all files that were created by the scripts
# clean-tracking: remove the tracking file (used by clean to determine which files to remove)
# tracking: create a tracking file that contains all files in the current directory and subdirectories

# When wanting to use this makefile, run `make tracking` first to create the tracking file.
# After that, you can run `make` or `make all` to execute the scripts
# and `make clean` to remove files that were created by the scripts but are not tracked
# and `make clean-tracking` to remove the tracking file.
.PHONY: all clean clean-tracking tracking

all: $(foreach d,$(DIRS),$(d)/benchmarkTime.txt)

tracking:
	find . -type f | sort > $(TRACKING)

clean:
	if [ -f $(TRACKING) ]; then \
		bash -c 'comm -13 $(TRACKING) <(find . -type f | sort) | xargs -r rm -f'; \
	else \
		echo "Tracking file missing."; \
		echo "If you ran 'make' or 'make all', do the following:"; \
		echo "  1. Save this Makefile."; \
		echo "  2. Run: rm -rf examples"; \
		echo "  3. Then: git checkout origin/vortex-llvm18 -- examples/"; \
		echo "  4. Copy your Makefile into the restored examples folder."; \
		echo "This will restore the examples directory to its original condition."; \
		echo "If you're not using 'make all', and just want to track new files,"; \
		echo "run: make tracking before your first build."; fi

clean-tracking:
	rm -f $(TRACKING)

# Uses `dir/benchmarkTime.txt` as a target, where `dir/benchmarkTime.txt` displays the time a script was executed.
# Script will only execute if `dir/benchmarkTime.txt` does not exist or is older than the dependencies (DEPS).
# DEPS are the .cpp and .cu files listed in the script, which are extracted using grep and sed.

define EXECUTION

DEPS = $(shell \
    grep -vE '^[[:space:]]*\#' $(1)/kjrun_llvm18.sh | \
    grep -oE '(\S+\.cpp|\S+\.cu)' | \
    sed    's/^[^=]*=//' | \
    sed    "s|^[\\\\\"']*||" | \
    sed 's|^|$(1)/|' | \
    uniq | \
    sed 's|.*/kernel_wrapper.cpp|vortex_debug/kernel_wrapper.cpp|' \
)


$(1)/benchmarkTime.txt: $(1)/kjrun_llvm18.sh $(DEPS)
	-cd $(1) && ./kjrun_llvm18.sh
	echo "Benchmark $(1) finished it's execution at `date`" >> $$@


endef

$(foreach d,$(DIRS),\
	$(eval $(call EXECUTION,$(d)))\
)
