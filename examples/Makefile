# Top-level Makefile — run all examples in parallel
#
# Usage:
#   make              # build + run all (parallel by default with -j)
#   make -j20         # 20 parallel jobs
#   make build        # build only
#   make run          # run only
#   make clean        # clean all
#   make SCHEDULE=0   # pass options to all examples
#   make -j20 LOG=result_all.txt

EXAMPLES = \
	atomicAggregate-cuda \
	backprop \
	bfs \
	bscan-cuda \
	btree \
	conv3 \
	dotproduct \
	gc-cuda \
	memcpytosymbol_test \
	nn \
	pathfinder \
	psort \
	psum \
	saxpy \
	sgemm \
	shuffle-cuda \
	stencil \
	transpose \
	vecadd \
	vote-cuda

# Forward these variables to sub-makes
FORWARD_VARS = $(if $(ARCH),ARCH=$(ARCH)) \
               $(if $(SCHEDULE),SCHEDULE=$(SCHEDULE)) \
               $(if $(STARTUP_ADDR),STARTUP_ADDR=$(STARTUP_ADDR)) \
               $(if $(LOG),LOG=$(LOG))

.PHONY: all build run clean $(EXAMPLES)

all: $(EXAMPLES)

$(EXAMPLES):
	@echo "=== [$@] ==="
	$(MAKE) -C $@ $(MAKECMDGOALS) $(FORWARD_VARS) 2>&1 | sed "s/^/[$@] /"
	@echo "=== [$@] done ==="

build: $(EXAMPLES)
run: $(EXAMPLES)
clean: $(EXAMPLES)
