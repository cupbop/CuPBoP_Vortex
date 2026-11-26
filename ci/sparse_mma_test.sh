#!/usr/bin/env bash
# Check CUDA sparse MMA against a dense CPU oracle and verify the selected ISA path.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP environment first}"
: "${VORTEX_PATH:?select a Vortex build first}"
: "${LLVM_PREFIX:?select the Vortex LLVM toolchain first}"

work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-sparse-mma.XXXXXXXX")
echo "Sparse MMA regression artifacts: $work"
mkdir -p "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,v3_cell.mk,async_common.h} "$work/examples/"
app="$work/examples/mma_sparse-$(basename "$work")"
mkdir "$app"
cp "$CuPBoP_PATH/examples/mma_sparse/"{Makefile,mma_sparse.cu} "$app/"
cd "$app"

export CUPBOP_MMA_LOWERING=auto VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
export CUPBOP_PERF_KERNEL_FILE="$PWD/perf.jsonl"
source "$CuPBoP_PATH/ci/tf32_target.sh"
flavors=10
if ! cupbop_target_has_tf32; then
  export EXTRA_CLANG_FLAGS="${EXTRA_CLANG_FLAGS:-} -DCUPBOP_TEST_NO_TF32"
  flavors=8
fi
if ! make ci SCHEDULE=2 LOCALMEM=1 > run.log 2>&1; then
  tail -40 run.log
  exit 1
fi
grep -Fx 'PASSED!' ci_output.txt
test "$(grep -Ec '^(f16|bf16|tf32|s8|u8)( satfinite)? selector [01]: 512/512 match$' ci_output.txt)" -eq "$flavors"

"$LLVM_PREFIX/bin/llvm-objdump" -d --section=.text kernel.elf > text.dump
python3 - "$flavors" <<'PY'
import json
import os
from pathlib import Path
import re
import sys

flags = {option.split('=', 1)[0] for option in os.environ.get('VORTEX_CONFIGS', '').split()}
formats = {}
if {'-DVX_CFG_EXT_TCU_ENABLE', '-DVX_CFG_TCU_SPARSE_ENABLE'} <= flags:
    if '-DVX_CFG_TCU_FP16_DISABLE' not in flags:
        formats.update({2: 2, 3: 2})  # fp16 and bf16, two selector cases each
    if int(sys.argv[1]) == 10:
        formats[1] = 2
    if '-DVX_CFG_TCU_INT8_ENABLE' in flags:
        formats.update({17: 3, 18: 3})  # one plain MMA and two saturated K-half MMAs per integer type

words = [int(word, 16) for word in re.findall(
    r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s', Path('text.dump').read_text(), re.M)]
assert words, 'missing Vortex instructions in the disassembly'
wmma = [word for word in words if word & 0x7f == 0x0b and word >> 25 == 2
        and (word >> 12) & 7 == 0 and (word >> 20) & 1]
metadata = [word for word in words if word & 0x7f == 0x0b and word >> 25 == 2
            and (word >> 12) & 7 == 2 and not (word >> 11) & 1]

assert {word >> 15 & 31 for word in wmma} == set(formats), wmma
assert {word >> 20 & 31 for word in metadata} == set(formats), metadata
assert len(wmma) == len(metadata) == sum(formats.values()), (wmma, metadata)
rows = [json.loads(line) for line in Path('perf.jsonl').read_text().splitlines()]
assert len(rows) == 1, rows
retired = rows[0]['val'].get('core.instr_tcu', 0)
assert (retired > 0) == bool(formats), retired
print(f'{len(wmma)} WMMA_SP, {len(metadata)} TCU_LD sites, {retired} dynamic TCU instructions')
PY
