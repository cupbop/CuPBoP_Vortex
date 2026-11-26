#!/usr/bin/env bash
# Build a Hopper GEMM on a configured 32-lane SimX with TCU, WGMMA and DXA.
# Run after sourcing the CuPBoP build environment and building the translators/runtime.
# CUPBOP_HOPPER_LIFTED=1 also tests NVCC SM90a cubin -> CuLifter -> CuPBoP.
# CUPBOP_HOPPER_NVCC can select an NVCC executable compatible with the host compiler.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP environment first}"
: "${VORTEX_PATH:?select a Vortex build first}"
: "${LLVM_PREFIX:?select the Vortex LLVM toolchain first}"
bash "$CuPBoP_PATH/ci/wgmma_operand_test.sh" "$CuPBoP_PATH/build/compilation/kernelTranslator" "$LLVM_PREFIX/bin"
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-hopper.XXXXXXXX")
echo "Hopper regression artifacts: $work"
mkdir -p "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,async_common.h} "$work/examples/"
if [[ ${CUPBOP_HOPPER_LIFTED:-0} == 1 ]]; then
  : "${CUDA_PATH:?select a CUDA toolkit with SM90a support}"
  : "${CULIFTER_HOME:?set the CuLifter source directory}"
  : "${CULIFTER_ENV:?set the CuLifter Python environment}"
  ln -s "$CuPBoP_PATH/examples/"{lift.mk,lift_d2h.c} "$work/examples/"
fi

lift_hopper() {
  "${CUPBOP_HOPPER_NVCC:-$CUDA_PATH/bin/nvcc}" --allow-unsupported-compiler -O3 -arch=sm_90a --cubin "$@" -o hopper.cubin
  "$CUDA_PATH/bin/cuobjdump" -sass hopper.cubin > hopper.sass
  "$CULIFTER_ENV/bin/python" "$CULIFTER_HOME/main.py" -i hopper.sass hopper.cubin -o raw --lifter nvvm > lift.log 2>&1
  if grep -qi 'unsupported instruction' lift.log; then cat lift.log; exit 1; fi
  "$LLVM_PREFIX/bin/opt" -passes=verify -disable-output raw.ll
  xz -k raw.ll
}

run_gemm() {
  local tag=$1 swizzle=$2 pipeline=$3 phase=${4:-0}
  local width=${5:-64} trans_a=${6:-0} trans_b=${7:-0}
  local input=${8:-source}
  local args="-n 64" expected=4096
  if ((64 % width)); then
    args=
    expected=$((64 * width))
  fi
  local folder="$work/examples/$tag-$(basename "$work")"
  local -a defines=(-DCUPBOP_WGMMA_SWIZZLE="$swizzle" -DCUPBOP_WGMMA_SWIZZLE_PHASE="$phase"
                   -DCUPBOP_WGMMA_N="$width" -DCUPBOP_WGMMA_TRANS_A="$trans_a" -DCUPBOP_WGMMA_TRANS_B="$trans_b")
  if ((pipeline)); then defines+=(-DCUPBOP_HOPPER_TMA_PIPELINE); fi
  local flags="${EXTRA_CLANG_FLAGS:-} ${defines[*]}"
  mkdir "$folder"
  cp "$CuPBoP_PATH/examples/sgemm_wgmma/"{Makefile,sgemm_wgmma.cu} "$folder/"
  (
    cd "$folder"
    export CUPBOP_MMA_LOWERING=tcu VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
    if [[ $input == lifted ]]; then
      lift_hopper "${defines[@]}" sgemm_wgmma.cu
      sed -i 's|include ../common.mk|include ../lift.mk|' Makefile
    fi
    make build SCHEDULE=2 LOCALMEM=1 EXTRA_CLANG_FLAGS="$flags" > build.log 2>&1
    local -a offloads=(0)
    if ((pipeline)); then offloads+=(1); fi
    local offload
    for offload in "${offloads[@]}"; do
      CUPBOP_TMA_DXA=$offload CUPBOP_PERF_KERNEL_FILE="perf-$offload.jsonl" \
        make ci-run SCHEDULE=2 LOCALMEM=1 CI_RUN_ARGS="$args" EXTRA_CLANG_FLAGS="$flags" > "run-$offload.log" 2>&1
      grep -F "PASSED!: $expected/$expected" "run-$offload.log"
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

run_lifted_gsb() (
  folder="$work/examples/gsb-$(basename "$work")"
  mkdir "$folder"
  cp "$CuPBoP_PATH/examples/hopper_wgmma_gsb/"{Makefile,hopper_wgmma_gsb.cu} "$folder/"
  cd "$folder"
  export CUPBOP_MMA_LOWERING=tcu VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
  lift_hopper hopper_wgmma_gsb.cu
  make build SCHEDULE=2 LOCALMEM=1 > build.log 2>&1
  CUPBOP_PERF_KERNEL_FILE=perf.jsonl make ci-run SCHEDULE=2 LOCALMEM=1 > run.log 2>&1
  grep -F 'PASSED!: 1024/1024' run.log
  "$LLVM_PREFIX/bin/llvm-objdump" -d --section=.text kernel.elf > text.dump
  python3 - <<'PY'
import json
from pathlib import Path
import re

words = {int(addr, 16): int(word, 16) for addr, word in re.findall(
    r"^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s", Path("text.dump").read_text(), re.M)}
controls = [(addr, (word >> 15) & 31, (word >> 20) & 31) for addr, word in words.items()
            if word & 0x7f == 0x0b and word >> 25 == 2 and (word >> 12) & 7 == 4 and (word >> 7) & 31 == 1]
commits = [addr for addr, op, pending in controls if op == 1 and pending == 0]
waits = [pending for _, op, pending in controls if op == 2]
def native_wgmma(word):
    return word & 0x7f == 0x0b and word >> 25 == 2 and (word >> 12) & 7 == 3

paired = [addr for addr in commits if native_wgmma(words.get(addr - 4, 0))]
assert len(paired) == 3, (paired, controls)
# Every source group has a native and a mutually exclusive high-LMEM fallback site.
assert len(commits) == 6 and waits == [1, 0], controls
records = [json.loads(line) for line in Path("perf.jsonl").read_text().splitlines()]
assert len(records) == 1 and records[0]["val"]["tcu.lmem_reads"] > 0, records
print("native gsb0: three immediately paired WGMMA/commit sites, waits for one and zero pending groups")
PY

  bash "$CuPBoP_PATH/ci/hopper_named_scoreboards.sh" "$PWD"

  if [[ " ${VORTEX_CONFIGS:-} " =~ [[:space:]]-DVX_CFG_LMEM_LOG_SIZE=([0-9]+)[[:space:]] ]] &&
     (( BASH_REMATCH[1] >= 17 )); then
    high="$work/examples/gsb-high-$(basename "$work")"
    mkdir "$high"
    cp Makefile hopper_wgmma_gsb.cu "$high/"
    # Retain the lifted operand addresses and move only the generated scratch
    # beyond the native 16-bit local-memory descriptor offset.
    python3 - "$high/raw.ll" <<'PY'
from pathlib import Path
import re
import sys

source = Path("raw.ll").read_text()
storage = re.search(r'^@"shared_mem" = external addrspace\(3\) global \[(\d+) x i8\]', source, re.M)
assert storage, "missing lifted static shared storage"
size = int(storage[1])
Path(sys.argv[1]).write_text(source.replace(f"[{size} x i8]", f"[{size + 65536} x i8]"))
PY
    cd "$high"
    xz -k raw.ll
    make build SCHEDULE=2 LOCALMEM=1 > build.log 2>&1
    CUPBOP_PERF_KERNEL_FILE=perf.jsonl make ci-run SCHEDULE=2 LOCALMEM=1 > run.log 2>&1
    grep -F 'PASSED!: 1024/1024' run.log
    python3 - <<'PY'
import json
from pathlib import Path

records = [json.loads(line) for line in Path("perf.jsonl").read_text().splitlines()]
assert len(records) == 1, records
counters = records[0]["val"]
assert counters["tcu.lmem_reads"] == 0 and counters["core.instr_tcu"] > 0, counters
print("high scratch: register MMA, tagged commits, and both waits completed")
PY
  fi
)

run_gemm linear 0 0
run_gemm swizzle32 32 0 3
run_gemm swizzle64 64 0 3
run_gemm swizzle128 128 0 3
run_gemm pipeline 128 1
run_gemm n8-trans-a 128 0 3 8 1 0
run_gemm n24-trans-b 32 0 3 24 0 1
if [[ ${CUPBOP_HOPPER_LIFTED:-0} == 1 ]]; then
  run_gemm lifted-pipeline 128 1 0 64 0 0 lifted
  run_lifted_gsb
  bash "$CuPBoP_PATH/ci/sparse_imma_lift_test.sh"
fi
bash "$CuPBoP_PATH/ci/sparse_wgmma_test.sh"
