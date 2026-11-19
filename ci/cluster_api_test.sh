#!/usr/bin/env bash
# Run in a configured direct-mapping SimX environment with 32 lanes and room
# for four resident CTAs. A separate example directory gives each run its own
# kernel image, compiler sidecars and captured output.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP build environment}"
export VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1
export CUPBOP_TMA_DXA=0 CUPBOP_CP_ASYNC_COALESCED_DXA=0
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-cluster-api.XXXXXXXX")
echo "Regression logs: $work"
mkdir "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,async_common.h} "$work/examples/"
run() (
  local name=$1 tag=$2 flags=${3:-} arch=${4:-sm_90}
  local folder="$work/examples/$tag-$(basename "$work")"
  mkdir "$folder"
  cp "$CuPBoP_PATH/examples/$name/"{Makefile,"$name.cu"} "$folder/"
  cd "$folder"
  trap 'echo "Failed in $folder" >&2; tail -15 run.log 2>/dev/null || tail -15 build.log' ERR
  make build SCHEDULE=2 LOCALMEM=1 CUDA_GPU_ARCH="$arch" EXTRA_CLANG_FLAGS="$flags" >build.log 2>&1
  if grep -F 'unknown PTX InlineAsm' build.log; then exit 1; fi
  export LD_LIBRARY_PATH="$work/build/runtime/threadPool:$VORTEX_PATH/sw/runtime:$work/build/runtime:${LD_LIBRARY_PATH:-}"
  timeout "${CUPBOP_TEST_TIMEOUT:-180}" ./host.out >run.log 2>&1
  grep '^PASSED!' run.log
)
pids=()
for arch in sm_80 sm_90; do
  for api in CG_COPY BLOCK_BARRIER BLOCK_PIPE THREAD_PIPE PARTITIONED_PIPE; do
    run cuda_async_api "$api-$arch" "-DASYNC_API=$api" "$arch" & pids+=($!)
  done
done
for example in cluster_queries cluster_group cluster_async cluster_reduce; do
  run "$example" "$example" & pids+=($!)
done
status=0
for pid in "${pids[@]}"; do wait "$pid" || status=1; done
exit "$status"
