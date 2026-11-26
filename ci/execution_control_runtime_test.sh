#!/usr/bin/env bash
# The source calls directional fences; ptxas may combine fences around the CTA
# barrier. Both the CUDA program and the complete SM90a cubin publish real data.
set -euo pipefail
: "${CuPBoP_PATH:?}" "${LLVM_PREFIX:?}" "${VORTEX_PATH:?}"
translator=${KERNEL_TRANSLATOR:-$CuPBoP_PATH/build/compilation/kernelTranslator}
bash "$CuPBoP_PATH/ci/execution_control_test.sh" "$translator" "$LLVM_PREFIX/bin"
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-execution-control.XXXXXXXX")
echo "Execution control regression artifacts: $work"
mkdir "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,lift.mk,lift_d2h.c,async_common.h,execution_control} "$work/examples/"
for example in execution_control lifted_execution_control; do
  app="$work/examples/$example-$(basename "$work")"
  mkdir "$app"
  cp "$CuPBoP_PATH/examples/$example/Makefile" "$app/"
  if [[ $example == execution_control ]]; then
    cp "$CuPBoP_PATH/examples/$example/execution_control.cu" "$app/"
  else
    cp "$CuPBoP_PATH/examples/$example/raw.ll.xz" "$app/"
  fi
  (
    cd "$app"
    export CUPBOP_LIFT_OPT=1
    make build SCHEDULE=2 LOCALMEM=1 > build.log 2>&1 || { tail -25 build.log; exit 1; }
    CUPBOP_PERF_KERNEL_FILE=perf.jsonl ./host.out > run.log 2>&1 || { cat run.log; exit 1; }
    grep -F 'Directional proxy fences and dependent launches: 0/768 mismatches' run.log
    python3 - <<'PY'
import json
from pathlib import Path
launches = [json.loads(line)["kernel"] for line in Path("perf.jsonl").read_text().splitlines()]
assert len(launches) == 6 and all("publish" in k for k in launches[::2]) and all("consume" in k for k in launches[1::2]), launches
PY
  )
done
