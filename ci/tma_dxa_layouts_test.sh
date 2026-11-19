#!/usr/bin/env bash
# Verify CUDA tensor-map destination layouts through both the software and DXA paths.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP environment first}"
: "${VORTEX_PATH:?select a DXA-enabled Vortex build first}"

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-dxa-layouts.XXXXXXXX")
echo "DXA layout regression artifacts: $work"
mkdir -p "$work/examples/tma_dxa_layouts" "$work/vortex/tests/regression"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$repo/examples/"{common.mk,async_common.h} "$work/examples/"
cp "$repo/examples/tma_dxa_layouts/"{Makefile,tma_dxa_layouts.cu} "$work/examples/tma_dxa_layouts/"
cp "$VORTEX_PATH/tests/regression/common.mk" "$work/vortex/tests/regression/"

cd "$work/examples/tma_dxa_layouts"
export LD_LIBRARY_PATH="$CuPBoP_PATH/build/runtime:$CuPBoP_PATH/build/runtime/threadPool:$VORTEX_PATH/sw/runtime${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1
if ! make build SCHEDULE=2 LOCALMEM=1 ROOT_DIR="$VORTEX_PATH" \
    VX3_CELL="$work/vortex/tests/regression/tma_dxa_layouts" > "$work/build.log" 2>&1; then
  tail -n 50 "$work/build.log"
  exit 1
fi
for dxa in 0 1; do
  if ! CUPBOP_TMA_DXA=$dxa CUPBOP_PERF_KERNEL_FILE="$work/perf-$dxa.jsonl" \
      ./host.out > "$work/run-$dxa.log" 2>&1; then
    cat "$work/run-$dxa.log"
    exit 1
  fi
  grep '^PASSED!$' "$work/run-$dxa.log"
done
python3 - "$work" <<'PY'
import json
from pathlib import Path
import sys

work = Path(sys.argv[1])
for offload, expected in enumerate((0, 2)):
    records = [json.loads(line) for line in (work / f"perf-{offload}.jsonl").read_text().splitlines()]
    transfers = [record["val"]["dxa.transfers"] for record in records]
    assert transfers == [expected] * 5, transfers
    print(f"CUPBOP_TMA_DXA={offload}: DXA transfers per launch {transfers}")
PY
