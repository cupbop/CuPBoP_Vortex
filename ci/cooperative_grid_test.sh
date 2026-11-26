#!/usr/bin/env bash
# Direct-mapping SimX with 32 lanes, atomics and room for four resident CTAs.
# CUPBOP_GRID_LIFTED=1 replays SM80 and SM90 cubins with CUDA SDK's original
# counter-based grid protocol in addition to the source overlay.
set -euo pipefail
: "${CuPBoP_PATH:?source the CuPBoP environment first}"
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-grid.XXXXXXXX")
echo "Cooperative grid logs: $work"
mkdir "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,lift.mk,lift_d2h.c} "$work/examples/"
export VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-60}
variants=(source)
if [[ ${CUPBOP_GRID_LIFTED:-0} == 1 ]]; then variants+=(sm_80 sm_90); fi
for variant in "${variants[@]}"; do
  dir="$work/examples/$variant-$(basename "$work")"
  mkdir "$dir"
  cp "$CuPBoP_PATH/examples/cooperative_grid_sync/"{Makefile,cooperative_grid_sync.cu} "$dir/"
  (
    cd "$dir"
    if [[ $variant != source ]]; then
      "${CUPBOP_GRID_NVCC:-$CUDA_PATH/bin/nvcc}" --allow-unsupported-compiler -O3 -arch="$variant" --cubin cooperative_grid_sync.cu -o grid.cubin
      "$CUDA_PATH/bin/cuobjdump" -sass grid.cubin > grid.sass
      "$CULIFTER_ENV/bin/python" "$CULIFTER_HOME/main.py" -i grid.sass grid.cubin -o raw --lifter nvvm > lift.log 2>&1
      grep -q 'mov.u32 \$0, %envreg1;' raw.ll
      grep -q 'mov.u32 \$0, %envreg2;' raw.ll
      grep -q 'atomicrmw add' raw.ll
      xz -k raw.ll
      sed -i 's@/common.mk@/lift.mk@' Makefile
    fi
    make build SCHEDULE=2 LOCALMEM=1 > build.log 2>&1
    CUPBOP_DEBUG=1 make ci-run SCHEDULE=2 LOCALMEM=1 > run.log 2>&1
    grep -F 'PASSED! concurrent cooperative launches' run.log
    grep -F 'PASSED! cooperative launch, grid validity and 1056 cross-CTA values' run.log
    if [[ $variant == source ]]; then
      grep -q '__cupbop_grid_sync' kernel.ll
      "${CXX:-c++}" -shared -fPIC -I"$VORTEX_HOME/sw/runtime/include" "$CuPBoP_PATH/ci/cooperative_grid_faults.cpp" -ldl -o faults.so
      for fault in alloc init enqueue lost; do
        CUPBOP_TEST_GRID_FAULT=$fault LD_PRELOAD="$PWD/faults.so${LD_PRELOAD:+:$LD_PRELOAD}" ./host.out > "fault-$fault.log" 2>&1
        grep -F "PASSED! cooperative workspace failure: $fault" "fault-$fault.log"
      done
    fi
  )
done
