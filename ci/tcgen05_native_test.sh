#!/usr/bin/env bash
# Run on RV64 SimX with 32 lanes, at least eight warps per core, and native TMEM.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP environment first}"
: "${VORTEX_PATH:?select a Vortex build first}"
case " ${VORTEX_CONFIGS:-} " in
  *" -DVX_CFG_TCU_TMEM_ENABLE "*) ;;
  *) echo 'The selected Vortex build needs VX_CFG_TCU_TMEM_ENABLE' >&2; exit 1 ;;
esac

work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-tcgen05.XXXXXXXX")
echo "TCGEN05 regression artifacts: $work"
mkdir -p "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,async_common.h,tcgen05_test.h} "$work/examples/"

run_case() (
  local example=$1 expected=$2
  shift 2
  local app="$work/examples/$example-$(basename "$work")"
  mkdir "$app"
  cp "$CuPBoP_PATH/examples/$example/"{Makefile,"$example.cu"} "$app/"
  cd "$app"
  make build SCHEDULE=2 LOCALMEM=1 > build.log 2>&1
  local index=0 args
  for args in "$@"; do
    CUPBOP_PERF_KERNEL_FILE="perf-$index.jsonl" \
      make ci-run SCHEDULE=2 LOCALMEM=1 CI_RUN_ARGS="$args" > "run-$index.log" 2>&1
    grep -F "$expected" "run-$index.log"
    python3 - "perf-$index.jsonl" <<'PY'
import json
from pathlib import Path
import sys

rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines()]
assert len(rows) == 1 and rows[0]["val"]["core.instr_tcu"] > 0, rows
print(f"Native TCU instructions retired: {rows[0]['val']['core.instr_tcu']}")
PY
    index=$((index + 1))
  done
)

export CUPBOP_MMA_LOWERING=auto VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
run_case tcgen05_i8 'elements=131072 mismatches=0' 0 1
run_case tcgen05_tma_mma 'elements=32768 mismatches=0' ''
run_case tcgen05_i8_pair 'PASSED!: 131072/131072 INT32 results match' ''
