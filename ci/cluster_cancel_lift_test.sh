#!/usr/bin/env bash
set -euo pipefail
if [[ $# -gt 1 || ($# -eq 1 && $1 != --expect-decline) ]]; then
  echo "usage: $0 [--expect-decline]" >&2
  exit 1
fi
replay_args=("$@")
: "${CuPBoP_PATH:?source the CuPBoP environment}"
: "${CULIFTER_HOME:?set the CuLifter checkout}"
: "${CULIFTER_ENV:?set the CuLifter Python environment}"
: "${VORTEX_PATH:?select the SimX build}"
work=$(mktemp -d "${TMPDIR:-/tmp}/cluster-cancel-lift.XXXXXXXX")
echo "Cluster cancellation regression artifacts: $work"
mkdir "$work/examples"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,v3_cell.mk} "$work/examples/"
export VORTEX_DRIVER=simx VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1
export LD_LIBRARY_PATH="$work/build/runtime/threadPool:$VORTEX_PATH/sw/runtime:$work/build/runtime:${LD_LIBRARY_PATH:-}"
run_case() (
  arch=$1 multicast=$2
  app="$work/examples/clc-$arch-$multicast-$(basename "$work")"
  mkdir "$app"
  cd "$app"
  src="$CuPBoP_PATH/examples/cluster_cancel"
  cp "$src/replay.cu" .
  cpp -P -DMULTICAST="$multicast" -DCLUSTER_TARGET="$arch" "$src/probe.ptx" > probe.ptx
  "${PTXAS:-ptxas}" -arch="$arch" probe.ptx -o probe.cubin
  "${CUOBJDUMP:-cuobjdump}" -sass probe.cubin > probe.sass
  scope=SELFCAST
  if (( multicast )); then scope=BROADCAST; fi
  grep -F "UGETNEXTWORKID.$scope" probe.sass
  "$CULIFTER_ENV/bin/python" "$CULIFTER_HOME/main.py" -i probe.sass probe.cubin \
    --lifter nvvm --linkable-nvvm -o lifted > lift.log 2>&1
  grep -F 'clusterlaunchcontrol.try_cancel.async' lifted.ll > /dev/null
  if grep -iE 'unsupported instruction|placeholder' lift.log; then exit 1; fi
  "$LLVM_PREFIX/bin/llvm-as" lifted.ll -o lifted.bc
  cat > Makefile <<'MK'
KERNEL_CU = replay.cu
DEVICE_BC = lifted.bc
DEVICE_BC_SRC = unused.bc
include ../common.mk
MK
  extended=0 expected=2
  if [[ $arch == sm_100a && $multicast == 1 ]]; then extended=1; expected=8; fi
  if ! make build SCHEDULE=2 LOCALMEM=1 EXTRA_CLANG_FLAGS="-DMULTICAST=$multicast -DEXTENDED_MULTICAST=$extended" > build.log 2>&1; then
    tail -40 build.log >&2
    exit 1
  fi
  # An eager software implementation can also produce correct tiles. Verify
  # that this particular device binary actually submits the asynchronous request.
  async_csr=$(awk '$2 == "VX_SIMX_CSR_CANCEL_ASYNC" { print $3 }' "$VORTEX_PATH/sw/VX_types.h")
  if [[ -n "$async_csr" ]]; then
    grep -Eq "csrrwi?[[:space:]]+[^,]+, $async_csr," kernel.dump || {
      echo "Missing asynchronous CLC submit instruction in $app/kernel.dump" >&2
      exit 1
    }
  fi
  echo "$arch $scope"
  timeout "${CUPBOP_TEST_TIMEOUT:-180}" ./host.out "${replay_args[@]}" 2>&1 | tee run.log
  test "$(grep -c '^PASSED!' run.log)" = "$expected"
)
for arch in sm_100 sm_100a sm_120 sm_120a; do
  run_case "$arch" 0
  if [[ $arch == *a ]]; then run_case "$arch" 1; fi
done
