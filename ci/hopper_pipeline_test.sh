#!/usr/bin/env bash
# Build a Hopper GEMM on a configured 32-lane SimX with TCU, WGMMA and DXA.
# Run after sourcing the CuPBoP build environment and building the translators/runtime.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP environment first}"
: "${VORTEX_PATH:?select a Vortex build first}"
: "${LLVM_PREFIX:?select the Vortex LLVM toolchain first}"
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-hopper.XXXXXXXX")
echo "Hopper regression artifacts: $work"
mkdir -p "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,async_common.h} "$work/examples/"

run_gemm() {
  local tag=$1 swizzle=$2 pipeline=$3 phase=${4:-0}
  local folder="$work/examples/$tag-$(basename "$work")"
  local flags="${EXTRA_CLANG_FLAGS:-} -DCUPBOP_WGMMA_SWIZZLE=$swizzle -DCUPBOP_WGMMA_SWIZZLE_PHASE=$phase"
  if ((pipeline)); then flags+=" -DCUPBOP_HOPPER_TMA_PIPELINE"; fi
  mkdir "$folder"
  cp "$CuPBoP_PATH/examples/sgemm_wgmma/"{Makefile,sgemm_wgmma.cu} "$folder/"
  (
    cd "$folder"
    export CUPBOP_MMA_LOWERING=tcu VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
    make build SCHEDULE=2 LOCALMEM=1 EXTRA_CLANG_FLAGS="$flags" > build.log 2>&1
    local -a offloads=(0)
    if ((pipeline)); then offloads+=(1); fi
    local offload
    for offload in "${offloads[@]}"; do
      CUPBOP_TMA_DXA=$offload CUPBOP_PERF_KERNEL_FILE="perf-$offload.jsonl" \
        make ci-run SCHEDULE=2 LOCALMEM=1 CI_RUN_ARGS="-n 64" EXTRA_CLANG_FLAGS="$flags" > "run-$offload.log" 2>&1
      grep -F 'PASSED!: 4096/4096' "run-$offload.log"
    done
    "$LLVM_PREFIX/bin/llvm-objdump" -d --section=.text kernel.elf > text.dump
    python3 - "$pipeline" <<'PY'
import json
from pathlib import Path
import re
import sys

pipeline = int(sys.argv[1])
words = [int(word, 16) for word in re.findall(
    r"^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s", Path("text.dump").read_text(), re.M)]
custom_words = [word for word in words if word & 0x7F == 0x0B]
custom = {(word >> 25, (word >> 12) & 7) for word in custom_words}
assert (2, 3) in custom, "Vortex WGMMA async issue missing"
controls = {(word >> 15) & 31 for word in custom_words if (word >> 25, (word >> 12) & 7) == (2, 4)}
assert {0, 1, 2} <= controls, "Vortex WGMMA fence, commit or wait missing"
assert not pipeline or (3, 0) in custom, "Vortex DXA issue missing"

for offload in range(pipeline + 1):
    rows = [json.loads(line) for line in Path(f"perf-{offload}.jsonl").read_text().splitlines()]
    assert len(rows) == 1, rows
    counters = rows[0]["val"]
    assert counters["tcu.lmem_reads"] > 0, counters
    assert counters["dxa.transfers"] == 8 * offload, counters
    print(f"native WGMMA with {counters['dxa.transfers']} DXA transfers")
PY
  )
}

run_gemm linear 0 0
run_gemm swizzle32 32 0 3
run_gemm swizzle64 64 0 3
run_gemm swizzle128 128 0 3
run_gemm pipeline 128 1
