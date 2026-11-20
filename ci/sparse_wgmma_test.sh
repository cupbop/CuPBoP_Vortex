#!/usr/bin/env bash
# Exercise CUDA sparse WGMMA on the selected Vortex build.
# CUPBOP_HOPPER_LIFTED=1 also exercises the original SM90a cubin if a
# CUDA 12.2+ toolkit (CUPBOP_SPARSE_NVCC), or CUPBOP_SPARSE_CUBIN, is available.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP environment first}"
: "${VORTEX_PATH:?select a Vortex build first}"
: "${LLVM_PREFIX:?select the Vortex LLVM toolchain first}"

work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-sparse-wgmma.XXXXXXXX")
echo "Sparse WGMMA regression artifacts: $work"
mkdir -p "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,v3_cell.mk,async_common.h} "$work/examples/"

config=" ${VORTEX_CONFIGS:-} "
has_flag() {
  [[ $config =~ [[:space:]]-D$1(=[^[:space:]]+)?[[:space:]] ]]
}
native=0
if [[ ${CUPBOP_MMA_LOWERING:-auto} != sw ]] &&
    has_flag VX_CFG_EXT_TCU_ENABLE && has_flag VX_CFG_EXT_A_ENABLE &&
    has_flag VX_CFG_TCU_WGMMA_ENABLE && has_flag VX_CFG_TCU_SPARSE_ENABLE; then
  native=1
fi
expected=$native
if has_flag VX_CFG_TCU_FP16_DISABLE; then expected=0; fi

run_dtypes() (
  local app="$work/examples/sparse-dtypes-$(basename "$work")"
  mkdir "$app"
  cp "$CuPBoP_PATH/examples/sgemm_wgmma_sparse_dtypes/"{Makefile,sgemm_wgmma_sparse_dtypes.cu} "$app/"
  cd "$app"
  export VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
  export VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1
  export CUPBOP_PERF_KERNEL_FILE="$app/kernels.jsonl"
  export LD_LIBRARY_PATH="$work/build/runtime/threadPool:$VORTEX_PATH/sw/runtime:$work/build/runtime${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  local flags="${EXTRA_CLANG_FLAGS:-} -DCUPBOP_SPARSE_DTYPE_MASK=63"
  if ! make build SCHEDULE=2 LOCALMEM=1 EXTRA_CLANG_FLAGS="$flags" > build.log 2>&1; then
    tail -40 build.log
    exit 1
  fi
  PERF_CLASS=2 ./host.out > ci_output.txt 2>&1 || { cat ci_output.txt; exit 1; }
  cat ci_output.txt
  grep -Fxq 'PASSED!' ci_output.txt

  local tf32=0 fp8=0 int8=0
  if ((native)) && has_flag VX_CFG_TCU_TF32_ENABLE; then tf32=1; fi
  if ((native)) && has_flag VX_CFG_TCU_FP8_ENABLE; then fp8=1; fi
  if ((native)) && has_flag VX_CFG_TCU_INT8_ENABLE; then int8=1; fi
  python3 - "$tf32" "$fp8" "$int8" "$expected" <<'PY'
import json
from pathlib import Path
import re
import sys

tf32, fp8, int8, fp16 = map(int, sys.argv[1:])
specs = [
    ("TF32×TF32", 4, 1024, tf32),
    ("E4M3×E4M3", 2, 1024, fp8),
    ("E4M3×E5M2", 2, 1024, fp16),
    ("E5M2×E4M3", 2, 1024, fp16),
    ("E5M2×E5M2", 2, 1024, fp8),
    ("S8×S8", 2, 1024, int8),
    ("U8×U8", 2, 1024, int8),
    ("S8×S8 satfinite", 2, 512, int8),
    ("S8×U8", 2, 1024, fp16),
    ("U8×S8", 2, 1024, fp16),
    ("FP16×FP16→FP16", 1, 512, fp16),
    ("E4M3×E5M2→FP16", 1, 512, fp16),
]
cases = [(label, str(values), use_tcu) for label, count, values, use_tcu in specs for _ in range(count)]
actual = re.findall(r"^(.+?) (?:SS|RS|packed SS)(?: selector=[01])?: (512|1024) values, 0 mismatches$",
                    Path("ci_output.txt").read_text(encoding="utf-8"), re.M)
assert actual == [(label, values) for label, values, _ in cases], actual
records = [json.loads(line) for line in Path("kernels.jsonl").read_text().splitlines()]
assert len(records) == len(cases), len(records)
for (label, _, use_tcu), record in zip(cases, records):
    reads = record["val"].get("tcu.lmem_reads", 0)
    assert (reads > 0) == bool(use_tcu), (label, reads, use_tcu)
print(f"Sparse WGMMA dtypes: {len(cases)} exact cases, native TCU reads in "
      f"{sum(r['val'].get('tcu.lmem_reads', 0) > 0 for r in records)} launches")
PY
)

run_sparse() (
  local mode=$1 input=$2
  local app="$work/examples/sparse-$mode-$input-$(basename "$work")"
  mkdir "$app"
  cp "$CuPBoP_PATH/examples/sgemm_wgmma_sparse/"{Makefile,sgemm_wgmma_sparse.cu} "$app/"
  cd "$app"
  if [[ $input == lifted ]]; then
    if [[ -n $cubin ]]; then
      cp "$cubin" sparse.cubin
    else
      "$nvcc" --allow-unsupported-compiler -O3 -gencode=arch=compute_90a,code=sm_90a --cubin \
        sgemm_wgmma_sparse.cu -o sparse.cubin
    fi
    if [[ -n $sass ]]; then
      cp "$sass" sparse.sass
    else
      "$cuobjdump" -sass sparse.cubin > sparse.sass
    fi
    test "$(grep -c 'HGMMA\.SP\.' sparse.sass)" -eq 32
    "$CULIFTER_ENV/bin/python" "$CULIFTER_HOME/main.py" \
      -i sparse.sass sparse.cubin -o raw --lifter nvvm > lift.log 2>&1
    if grep -qi 'unsupported instruction\|placeholder' lift.log; then cat lift.log; exit 1; fi
    test "$(grep -c 'asm sideeffect "wgmma\.mma_async\.sp\.' raw.ll)" -eq 32
    "$LLVM_PREFIX/bin/opt" -passes=verify -disable-output raw.ll
    xz -k raw.ll
    sed -i 's|include ../common.mk|include ../lift.mk|' Makefile
  fi
  export VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
  export CUPBOP_PERF_KERNEL_FILE="$app/kernels.jsonl"
  local flags="${EXTRA_CLANG_FLAGS:-} -DCUPBOP_SPARSE_WGMMA_SWIZZLE=$mode"
  if ! make ci SCHEDULE=2 LOCALMEM=1 EXTRA_CLANG_FLAGS="$flags" > run.log 2>&1; then
    tail -40 run.log
    exit 1
  fi
  cat ci_output.txt
  grep -Fx 'PASSED! 16 sparse warpgroup cases' ci_output.txt
  test "$(grep -Ec '^(FP16|BF16) (SS|RS) N(8|24) selector=[01]: [0-9]+ values, 0 mismatches$' ci_output.txt)" -eq 16
  "$LLVM_PREFIX/bin/llvm-objdump" -d --section=.text kernel.elf > text.dump
  python3 - "$expected" "$input" <<'PY'
import json
from pathlib import Path
import re
import sys

by_addr = {int(addr, 16): int(word, 16) for addr, word in re.findall(
    r"^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s", Path("text.dump").read_text(), re.M)}
words = by_addr.values()
tcu = [word for word in words if word & 0x7F == 0x0B and word >> 25 == 2]
sparse = [word for word in tcu if (word >> 12) & 7 == 3 and (word >> 20) & 1]
if int(sys.argv[1]):
    assert sparse, "native sparse WGMMA issue missing"
    assert any((word >> 12) & 7 == 2 for word in tcu), "TCU_LD for sparse metadata missing"
    controls = {(word >> 15) & 31 for word in tcu if (word >> 12) & 7 == 4}
    assert {0, 1, 2} <= controls, "native WGMMA fence, commit or wait missing"
    if sys.argv[2] == "lifted":
        # Each of the 32 HGMMA.SP instructions commits gsb0 before its
        # result is shuffled back into the NVIDIA lane fragment.
        paired = sum(issue in sparse and by_addr.get(addr + 4) == 0x0400c08b
                     for addr, issue in by_addr.items())
        assert paired == 32, f"expected 32 adjacent sparse issue/gsb0 commits, saw {paired}"
    launches = [json.loads(line) for line in Path("kernels.jsonl").read_text().splitlines()]
    assert len(launches) == 16, launches
    assert all(launch["val"]["tcu.lmem_reads"] > 0 for launch in launches), launches
    print(f"Found {len(sparse)} native sparse WGMMA issue sites and TCU reads in all 16 launches")
else:
    assert not sparse, "sparse WGMMA instruction on a Vortex configuration without sparse TCU"
    print("Sparse WGMMA software path matched the CPU reference")
PY
)

for mode in 0 32 64 128; do
  run_sparse "$mode" source
done
run_dtypes
if [[ ${CUPBOP_HOPPER_LIFTED:-0} == 1 ]]; then
  cubin=${CUPBOP_SPARSE_CUBIN:-}
  sass=${CUPBOP_SPARSE_SASS:-}
  nvcc=${CUPBOP_SPARSE_NVCC:-${CUPBOP_HOPPER_NVCC:-${CUDA_PATH:-/usr/local/cuda}/bin/nvcc}}
  if [[ -z $cubin ]]; then
    if [[ -n $sass ]]; then
      echo 'CUPBOP_SPARSE_SASS requires the matching CUPBOP_SPARSE_CUBIN.' >&2
      exit 1
    fi
    nvcc=$(realpath -e "$(command -v "$nvcc")")
    version=$("$nvcc" --version | sed -nE 's/.*release ([0-9]+)\.([0-9]+),.*/\1 \2/p')
    if [[ $version =~ ^([0-9]+)[[:space:]]+([0-9]+)$ ]] &&
       (( BASH_REMATCH[1] < 12 || (BASH_REMATCH[1] == 12 && BASH_REMATCH[2] < 2) )); then
      message='Sparse cubin replay needs CUDA 12.2+. Set CUPBOP_SPARSE_NVCC or CUPBOP_SPARSE_CUBIN.'
      if [[ -n ${CUPBOP_SPARSE_NVCC:-} ]]; then
        echo "$message" >&2
        exit 1
      fi
      echo "$message Skipping the optional sparse cubin run."
      exit 0
    fi
  else
    cubin=$(realpath -e "$cubin")
  fi
  if [[ -n $sass ]]; then sass=$(realpath -e "$sass"); fi
  : "${CULIFTER_HOME:?set the CuLifter source directory}"
  : "${CULIFTER_ENV:?set the CuLifter Python environment}"
  cuobjdump=${CUPBOP_SPARSE_CUOBJDUMP:-$(dirname "$nvcc")/cuobjdump}
  if [[ -z $sass ]]; then
    cuobjdump=$(command -v "$cuobjdump" || printf '%s' "${CUDA_PATH:-/usr/local/cuda}/bin/cuobjdump")
    cuobjdump=$(realpath -e "$cuobjdump")
  fi
  ln -s "$CuPBoP_PATH/examples/"{lift.mk,lift_d2h.c} "$work/examples/"
  run_sparse 0 lifted
fi
