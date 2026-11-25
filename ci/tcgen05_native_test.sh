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
ln -s "$CuPBoP_PATH/examples/"{common.mk,async_common.h,tcgen05_test.h,lift.mk,lift_d2h.c} "$work/examples/"

run_case() (
  local example=$1 expected=$2
  shift 2
  local app="$work/examples/$example${replay_input:+-$replay_input}-$(basename "$work")"
  mkdir "$app"
  cp "$CuPBoP_PATH/examples/$example/Makefile" "$app/"
  if [[ -n ${replay_input:-} ]]; then
    export CUPBOP_LIFT_OPT=1 LIFT_IR_FILE="$CuPBoP_PATH/examples/$example/$replay_input.ll.xz"
  fi
  if [[ -f "$CuPBoP_PATH/examples/$example/$example.cu" ]]; then
    cp "$CuPBoP_PATH/examples/$example/$example.cu" "$app/"
  fi
  cd "$app"
  make build SCHEDULE=2 LOCALMEM=1 > build.log 2>&1
  local index=0 args
  for args in "$@"; do
    CUPBOP_PERF_KERNEL_FILE="perf-$index.jsonl" \
      make ci-run SCHEDULE=2 LOCALMEM=1 CI_RUN_ARGS="$args" > "run-$index.log" 2>&1
    grep -F "$expected" "run-$index.log"
    if grep -Eq 'mismatches=[1-9][0-9]*' "run-$index.log"; then return 1; fi
    python3 - "perf-$index.jsonl" "${expected_launches:-1}" <<'PY'
import json
from pathlib import Path
import sys

rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines()]
assert len(rows) == int(sys.argv[2]) and all(row["val"]["core.instr_tcu"] > 0 for row in rows), rows
print("Native TCU instructions retired:", [row["val"]["core.instr_tcu"] for row in rows])
PY
    index=$((index + 1))
  done
)

# Full-capacity jobs check up to 31,744 live guard words on the simulator.
mx_pressure_timeout=${VORTEX_CP_POLL_TIMEOUT_S:-420}
export CUPBOP_MMA_LOWERING=auto VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
run_case tcgen05_i8 'elements=131072 mismatches=0' 0 1
run_case tcgen05_tma_mma 'elements=32768 mismatches=0' ''
run_case tcgen05_i8_pair 'PASSED!: 131072/131072 INT32 results match' ''
if [[ " ${VORTEX_CONFIGS:-} " == *" -DVX_CFG_TCU_TMEM_COLUMN_ENABLE "* ]]; then
  run_case tcgen05_pack 'TMEM single column and pack: 0 mismatches in 7296 values' ''
  # The column backend needs two physical columns per CUDA column. The
  # M256 N32 example fits both CTA runs and the sparse metadata workspace.
  ln -s "$CuPBoP_PATH/examples/tcgen05_column_mma" "$work/examples/"
  run_case tcgen05_column_mma_pair 'format=4a4 mismatches=0/8192' ''

  # Exercise the actual translator entry point with the TF32 hardware flag removed.
  negative="$work/examples/tf32-disabled"
  mkdir "$negative"
  cp "$CuPBoP_PATH/examples/tcgen05_tf32/Makefile" "$negative/"
  tf32_disabled=" ${VORTEX_CONFIGS//-DVX_CFG_TCU_TF32_ENABLE/} "
  if make -C "$negative" kernel.bc VORTEX_CONFIGS="$tf32_disabled" SCHEDULE=2 LOCALMEM=1 > "$negative/build.log" 2>&1; then
    echo "TF32 translation unexpectedly succeeded with TF32 disabled" >&2
    exit 1
  fi
  grep -F 'TF32 MMA requires -DVX_CFG_TCU_TF32_ENABLE' "$negative/build.log"
  if [[ " ${VORTEX_CONFIGS} " == *" -DVX_CFG_TCU_TF32_ENABLE "* ]]; then
    expected_launches=3 run_case tcgen05_tf32 'format=18910 mismatches=0/2048' ''
    expected_launches=3 run_case tcgen05_tf32_pair 'format=18910 mismatches=0/8192' ''
    expected_launches=6 run_case tcgen05_tf32_tmem_a 'format=410 mismatches=0/2048' ''
    expected_launches=6 run_case tcgen05_mn_major_tmem_a 'mismatches=0/2048' ''
    run_case tcgen05_transpose_tmem_a 'transposed accumulator and packed FP4 mismatches=0/3072' ''
  fi

  ln -s "$CuPBoP_PATH/examples/tcgen05_column_scaled" "$work/examples/"
  if [[ " $VORTEX_CONFIGS " == *" -DVX_CFG_TCU_MX_ENABLE "* && " $VORTEX_CONFIGS " == *" -DVX_CFG_TCU_FP8_ENABLE "* ]]; then
    if [[ " $VORTEX_CONFIGS " == *" -DVX_CFG_TCU_TMEM_COLS=1024 "* ]]; then
      expected_launches=2 run_case tcgen05_full_mx_tmem_a 'case=3 mismatches=0/2048' ''
      for input in cuda129 raw; do
        expected_launches=2 replay_input=$input run_case lifted_tcgen05_full_mx_tmem_a 'case=3 mismatches=0/2048' ''
      done
      if [[ " $VORTEX_CONFIGS " != *" -DVX_CFG_TCU_FP16_DISABLE "* ]]; then
        VORTEX_CP_POLL_TIMEOUT_S=$mx_pressure_timeout expected_launches=2 run_case tcgen05_split_mx_tmem_a 'case=3 mismatches=0/2048' ''
        for input in cuda129 raw; do
          VORTEX_CP_POLL_TIMEOUT_S=$mx_pressure_timeout expected_launches=2 replay_input=$input run_case lifted_tcgen05_split_mx_tmem_a 'case=3 mismatches=0/2048' ''
        done
      fi
      if [[ " $VORTEX_CONFIGS " == *" -DVX_CFG_TCU_TMEM_EXT_SIDE_ENABLE "* && " $VORTEX_CONFIGS " != *" -DVX_CFG_TCU_FP16_DISABLE "* ]]; then
        VORTEX_CP_POLL_TIMEOUT_S=$mx_pressure_timeout expected_launches=2 run_case tcgen05_upper_mx_tmem_a 'case=3 mismatches=0/2048' ''
        for input in cuda129 raw; do
          VORTEX_CP_POLL_TIMEOUT_S=$mx_pressure_timeout expected_launches=2 replay_input=$input run_case lifted_tcgen05_upper_mx_tmem_a 'case=3 mismatches=0/2048' ''
        done
      fi
    fi
    expected_launches=5 run_case tcgen05_mixed_mx 'case=11 mismatches=0/2048' ''
    expected_launches=5 run_case tcgen05_mixed_mx_tmem_a 'case=11 mismatches=0/2048' ''
    if [[ " $VORTEX_CONFIGS " != *" -DVX_CFG_TCU_FP16_DISABLE "* ]]; then
      expected_launches=4 run_case tcgen05_dynamic 'dynamic descriptor mismatches=0/16384' ''
      # The cubin's shared UTCHMMA opcode dispatches to F16 or TF32 and to
      # dense or sparse at issue time. Exercise both recorded ptxas schedules.
      ln -s "$CuPBoP_PATH/examples/tcgen05_dynamic" "$work/examples/"
      for input in cuda129 raw; do
        expected_launches=4 replay_input=$input run_case lifted_tcgen05_dynamic 'dynamic descriptor mismatches=0/16384' ''
      done
    fi
  fi

  # The seven-format suite uses native FP16 for unscaled inputs and each
  # of the MXFP8, MXFP4 and NVFP4 hardware formats for the scaled inputs.
  have_mx_types=1
  for feature in MX FP8 FP4 MXFP4 NVFP4; do
    [[ " $VORTEX_CONFIGS " == *" -DVX_CFG_TCU_${feature}_ENABLE "* ]] || have_mx_types=0
  done
  if (( have_mx_types )) && [[ " $VORTEX_CONFIGS " != *" -DVX_CFG_TCU_FP16_DISABLE "* ]]; then
    expected_launches=7 run_case tcgen05_column_scaled 'case=6 mismatches=0/2048' ''
    expected_launches=7 run_case tcgen05_column_scaled_tmem_a 'case=6 mismatches=0/2048' ''
    expected_launches=2 run_case tcgen05_scale_copy 'case=5 mismatches=0/2048' ''
  fi
fi
