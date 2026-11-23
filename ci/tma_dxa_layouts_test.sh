#!/usr/bin/env bash
# Check CUDA and NVVM tensor copies through the software and DXA paths.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP environment first}"
: "${VORTEX_PATH:?select a DXA-enabled Vortex build first}"

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-dxa-layouts.XXXXXXXX")
echo "DXA regression artifacts: $work"
mkdir -p "$work/examples" "$work/vortex/tests/regression"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$repo/examples/"{common.mk,async_common.h} "$work/examples/"
cp "$VORTEX_PATH/tests/regression/common.mk" "$work/vortex/tests/regression/"

export LD_LIBRARY_PATH="$CuPBoP_PATH/build/runtime:$CuPBoP_PATH/build/runtime/threadPool:$VORTEX_PATH/sw/runtime${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1

run_test() (
  name=$1 expected_result=$2 launches=$3 transfers=$4
  shift 4
  mkdir "$work/examples/$name"
  cd "$work/examples/$name"
  for source in Makefile "$name.cu" "$@"; do cp "$repo/examples/$name/$source" .; done

  if ! make build SCHEDULE=2 LOCALMEM=1 ROOT_DIR="$VORTEX_PATH" \
      VX3_CELL="$work/vortex/tests/regression/$name" > build.log 2>&1; then
    tail -n 50 build.log
    exit 1
  fi
  for dxa in 0 1; do
    if ! CUPBOP_TMA_DXA=$dxa CUPBOP_PERF_KERNEL_FILE="$PWD/perf-$dxa.jsonl" \
        ./host.out > "run-$dxa.log" 2>&1; then
      cat "run-$dxa.log"
      exit 1
    fi
    grep -Fx "$expected_result" "run-$dxa.log"
  done
  python3 - "$launches" "$transfers" <<'PY'
import json
from pathlib import Path
import sys

launches, per_launch = map(int, sys.argv[1:])
for offload in (0, 1):
    records = [json.loads(line) for line in Path(f"perf-{offload}.jsonl").read_text().splitlines()]
    transfers = [record["val"]["dxa.transfers"] for record in records]
    assert transfers == [offload * per_launch] * launches, transfers
    print(f"CUPBOP_TMA_DXA={offload}: DXA transfers per launch {transfers}")
PY
)

run_test tma_dxa_layouts 'PASSED!' 5 2
run_test tma_nvvm_3d 'PASSED!: 512/512' 1 1 tma_nvvm_3d.ll.in
