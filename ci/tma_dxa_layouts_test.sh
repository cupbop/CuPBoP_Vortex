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
  cases=(off on)
  if [[ $name == tma_multicast_native ]]; then
    cases+=(partial full)
  fi
  for scenario in "${cases[@]}"; do
    dxa=1
    if [[ $scenario == off ]]; then
      dxa=0
    elif [[ $scenario == partial || $scenario == full ]]; then
      # Leave two non-reserved slots for the raw descriptor and tensor map in
      # the partial case. A full table must preserve the software copy.
      awk -v scenario="$scenario" '{
        for (slot = 0; slot < 16; ++slot) {
          if (scenario == "partial" && (slot == 13 || slot == 14)) continue
          print "desc", $2, "slot=" slot, "base=arg1 size=32 box=4 elem=4"
        }
      }' lookup.txt > dxa_descriptors.txt
    fi
    if ! CUPBOP_TMA_DXA=$dxa CUPBOP_PERF_KERNEL_FILE="$PWD/perf-$scenario.jsonl" \
        ./host.out > "run-$scenario.log" 2>&1; then
      cat "run-$scenario.log"
      exit 1
    fi
    grep -Fx "$expected_result" "run-$scenario.log"
  done
  python3 - "$launches" "$transfers" "${cases[@]}" <<'PY'
import json
from pathlib import Path
import sys

launches = int(sys.argv[1])
expected = list(map(int, sys.argv[2].split(",")))
if len(expected) == 1:
    expected *= launches
assert len(expected) == launches
for scenario in sys.argv[3:]:
    records = [json.loads(line) for line in Path(f"perf-{scenario}.jsonl").read_text().splitlines()]
    transfers = [record["val"]["dxa.transfers"] for record in records]
    assert transfers == (expected if scenario in ("on", "partial") else [0] * launches), transfers
    print(f"{scenario}: DXA transfers per launch {transfers}")
PY
)

run_test tma_dxa_layouts 'PASSED!' 5 2
run_test tma_nvvm_3d 'PASSED!: 512/512' 1 1 tma_nvvm_3d.ll.in

# The multicast issue packs its operands with the 32-lane warp ABI.
if [[ " ${VORTEX_CONFIGS:-} " == *" -DVX_CFG_NUM_THREADS=32 "* ]]; then
  run_test tma_multicast_native 'PASSED! multicast to four blocks' 8 2,16,2,16,16,2,16,2
fi
