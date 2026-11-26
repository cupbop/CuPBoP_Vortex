#!/usr/bin/env bash
# Replay CuLifter's archived sparse warp MMA cubins on Vortex.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP environment first}"
: "${VORTEX_PATH:?select a Vortex build first}"
: "${LLVM_PREFIX:?select the Vortex LLVM toolchain first}"
: "${CULIFTER_HOME:?set the CuLifter checkout path}"
: "${CULIFTER_ENV:?set the CuLifter Python environment path}"

work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-sparse-warp-lift.XXXXXXXX")
echo "Sparse warp MMA lift regression artifacts: $work"
mkdir -p "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,v3_cell.mk,async_common.h} "$work/examples/"

int4="$CULIFTER_HOME/test/sm90_synth/imma_sp_s4_k64"
if PYTHONDONTWRITEBYTECODE=1 "$CULIFTER_ENV/bin/python" "$CULIFTER_HOME/main.py" \
    -i "$int4/kernel.sass" "$int4/kernel.cubin" --lifter nvvm -o "$work/int4" > "$work/int4.log" 2>&1; then
  echo 'INT4 sparse IMMA was unexpectedly lifted as INT8'
  exit 1
fi
grep -F 'Unsupported NVVM sparse IMMA form:' "$work/int4.log"

run_replay() (
  local variant=$1 fixture="$CULIFTER_HOME/test/$2" source=$3 flags=$4
  shift 4
  local app="$work/examples/$variant-$(basename "$work")"
  mkdir "$app"
  cp "$CuPBoP_PATH/examples/mma_sparse/$source" "$app/replay.cu"
  cd "$app"

  if ! PYTHONDONTWRITEBYTECODE=1 "$CULIFTER_ENV/bin/python" "$CULIFTER_HOME/main.py" \
      -i "$fixture/kernel.sass" "$fixture/kernel.cubin" "$@" --lifter nvvm --linkable-nvvm -o lifted > lift.log 2>&1; then
    cat lift.log
    exit 1
  fi
  "$LLVM_PREFIX/bin/llvm-as" lifted.ll -o lifted.bc

  cat > Makefile <<'MK'
KERNEL_CU = replay.cu
DEVICE_BC = lifted.bc
DEVICE_BC_SRC = unused.bc
include ../common.mk
MK

  export CUPBOP_MMA_LOWERING=auto VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
  export CUPBOP_PERF_KERNEL_FILE="$PWD/perf.jsonl"
  if [[ $variant == tf32 ]] && ! cupbop_target_has_tf32; then
    if make kernel.bc SCHEDULE=2 LOCALMEM=1 > target.log 2>&1; then return 1; fi
    grep -F 'TF32 MMA requires -DVX_CFG_TCU_TF32_ENABLE' target.log
    return
  fi
  if ! make ci SCHEDULE=2 LOCALMEM=1 EXTRA_CLANG_FLAGS="${EXTRA_CLANG_FLAGS:-} -std=c++17 $flags" > run.log 2>&1; then
    tail -40 run.log
    exit 1
  fi
  "$LLVM_PREFIX/bin/llvm-objdump" -d --section=.text kernel.elf > text.dump
  python3 - "$variant" <<'PY'
from collections import Counter
import json
import os
from pathlib import Path
import re
import sys

variant = sys.argv[1]
cases = {
    'imma': [('kern_imma_sp16864', 17, 'IMMA.SP.16864.S8.S8.SAT: 128/128 match')],
    'half': [('kern_hmma_sp16832f16', 2, 'FP16 HMMA.SP: 256/256 match'),
             ('kern_hmma_sp16832bf16', 3, 'BF16 HMMA.SP: 256/256 match')],
    'tf32': [('kern_hmma_sp16816tf32', 1, 'TF32 HMMA.SP: 256/256 match')],
}[variant]
output = Path('ci_output.txt').read_text().splitlines()
for _, _, expected in cases:
    assert expected in output, '\n'.join(output)
    print(expected)

flags = {option.split('=', 1)[0] for option in os.environ.get('VORTEX_CONFIGS', '').split()}
native = set()
if {'-DVX_CFG_EXT_TCU_ENABLE', '-DVX_CFG_TCU_SPARSE_ENABLE'} <= flags:
    if '-DVX_CFG_TCU_FP16_DISABLE' not in flags:
        native.update({2, 3})
    if '-DVX_CFG_TCU_TF32_ENABLE' in flags:
        native.add(1)
    if '-DVX_CFG_TCU_INT8_ENABLE' in flags:
        native.add(17)

words = [int(word, 16) for word in re.findall(
    r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s', Path('text.dump').read_text(), re.M)]
assert words, 'missing Vortex disassembly'
wmma = Counter((word >> 15) & 31 for word in words if word & 0x7f == 0x0b and word >> 25 == 2
               and (word >> 12) & 7 == 0 and (word >> 20) & 1)
metadata = Counter((word >> 20) & 31 for word in words if word & 0x7f == 0x0b and word >> 25 == 2
                   and (word >> 12) & 7 == 2 and not (word >> 11) & 1)
expected_opcodes = {dtype: 2 for _, dtype, _ in cases if dtype in native}
assert wmma == metadata == expected_opcodes, (wmma, metadata)
rows = [json.loads(line) for line in Path('perf.jsonl').read_text().splitlines()]
assert [row['kernel'] for row in rows] == [name for name, _, _ in cases], rows
for row, (name, dtype, _) in zip(rows, cases):
    retired = row['val'].get('core.instr_tcu', 0)
    assert (retired > 0) == (dtype in native), (name, retired)
    print(f'{name}: {wmma[dtype]} WMMA_SP, {metadata[dtype]} TCU_LD, {retired} dynamic TCU instructions')
PY
)

source "$CuPBoP_PATH/ci/tf32_target.sh"
run_replay imma sm90_synth/imma_sp16864 replay.cu '' --kernel-name kern_imma_sp16864
run_replay half warp_sparse_fp16_bf16 replay_float.cu ''
run_replay tf32 warp_sparse_tf32 replay_float.cu -DCUPBOP_REPLAY_TF32
