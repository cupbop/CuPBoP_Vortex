#!/usr/bin/env bash
# Ampere cp.async issue/wait on a flat-addressed 8- or 32-lane DXA SimX.
set -euo pipefail
: "${CuPBoP_PATH:?}" "${VORTEX_PATH:?}" "${LLVM_PREFIX:?}"
repo=$(cd "$(dirname "$0")/.." && pwd)
example="$repo/examples/cp_async_groups"
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-cp-async.XXXXXXXX")
echo "cp.async regression artifacts: $work"
export LD_LIBRARY_PATH="$CuPBoP_PATH/build/runtime:$CuPBoP_PATH/build/runtime/threadPool:$VORTEX_PATH/sw/runtime${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1
unset CUPBOP_CP_ASYNC_COALESCED_DXA

mkdir -p "$work/named" "$work/examples/groups" "$work/vortex/tests/regression"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$repo/examples/"{common.mk,lift.mk,lift_d2h.c} "$work/examples/"
cp "$VORTEX_PATH/tests/regression/common.mk" "$work/vortex/tests/regression/"

# Schedule 1 time-multiplexes CUDA warps (and, on NT8, four sub-passes
# per CUDA warp). Keep copies pending across a real CTA barrier, exercise
# two private warp barriers simultaneously, and force a partial tail warp.
mkdir "$work/examples/replay"
cd "$work/examples/replay"
cp "$example/"{Makefile,main.cu} .
if ! make build SCHEDULE=1 LOCALMEM=1 ROOT_DIR="$VORTEX_PATH" \
    VX3_CELL="$work/vortex/tests/regression/replay" > build.log 2>&1; then
  tail -50 build.log
  exit 1
fi
for mode in groups tail; do
  VORTEX_SCHEDULE_FLAG=1 CUPBOP_PERF_KERNEL_FILE="$PWD/$mode.jsonl" ./host.out "$mode"
done
python3 - "${VORTEX_NUM_THREADS:?}" <<'PY'
import json
from pathlib import Path
import sys

lanes = int(sys.argv[1])
assert lanes in (8, 32), lanes
for mode in ("groups", "tail"):
    (record,) = [json.loads(line) for line in Path(f"{mode}.jsonl").read_text().splitlines()]
    threads = record["cuda_block"][0]
    expected = 4 * record["cuda_grid"][0] * (threads // lanes)
    assert record["sched"] == 1 and (threads % lanes != 0) == (mode == "tail"), (mode, record)
    assert record["val"]["dxa.transfers"] == expected, (mode, record["val"]["dxa.transfers"], expected)
    print(f"schedule 1 {mode}: {threads} CUDA threads per CTA, {expected} DXA transfers")
PY
if [[ $VORTEX_NUM_THREADS == 8 ]]; then
  # The CUDA header case launches 32 threads, requiring four NT8 warps for
  # direct dispatch. Each warp should issue one contiguous 128-byte tile.
  if (( ${VORTEX_NUM_WARPS:-0} >= 4 )); then
    if ! make build SCHEDULE=2 LOCALMEM=1 ROOT_DIR="$VORTEX_PATH" \
        VX3_CELL="$work/vortex/tests/regression/header8" > header8-build.log 2>&1; then
      tail -50 header8-build.log
      exit 1
    fi
    CUPBOP_PERF_KERNEL_FILE="$PWD/header8.jsonl" ./host.out header
    python3 - <<'PY'
import json
from pathlib import Path
record = json.loads(Path("header8.jsonl").read_text())
assert record["sched"] == 2 and record["val"]["dxa.transfers"] == 4, record
PY
  fi
  exit 0
fi

cd "$work/named"
"$LLVM_PREFIX/bin/llvm-as" "$example/ir/groups.ll" -o in.bc
"$CuPBoP_PATH/build/compilation/kernelTranslator" in.bc out.bc
"$LLVM_PREFIX/bin/opt" -passes=verify -disable-output out.bc
"$LLVM_PREFIX/bin/llvm-dis" out.bc -o out.ll

mkdir "$work/examples/lift_cp_async_group"
cd "$work/examples/lift_cp_async_group"
cp "$repo/examples/lift_cp_async_group/"{Makefile,main.cu,raw.ll.xz} .
if ! make build SCHEDULE=2 LOCALMEM=1 ROOT_DIR="$VORTEX_PATH" \
    VX3_CELL="$work/vortex/tests/regression/lifted" > build.log 2>&1; then
  tail -50 build.log
  exit 1
fi
CUPBOP_PERF_KERNEL_FILE="$PWD/perf.jsonl" ./host.out
python3 - <<'PY'
import json
from pathlib import Path
transfers = [json.loads(line)["val"]["dxa.transfers"] for line in Path("perf.jsonl").read_text().splitlines()]
assert transfers == [1], transfers
PY
cd "$work/examples/groups"
cp "$example/Makefile" "$example/main.cu" .
for variant in auto off; do
  if [[ $variant == off ]]; then export CUPBOP_CP_ASYNC_COALESCED_DXA=0; fi
  if ! make build SCHEDULE=2 LOCALMEM=1 ROOT_DIR="$VORTEX_PATH" \
      VX3_CELL="$work/vortex/tests/regression/groups" > "build-$variant.log" 2>&1; then
    tail -50 "build-$variant.log"
    exit 1
  fi
  cp kernel.ll "$variant.ll"
  # CUSTOM0 funct7=3, rs1=x31 packs a rank-1 DXA issue. Inspect executable
  # sections only: objdump -D also disassembles debug records.
  awk '/^Disassembly of section /{code=($4 == ".text:")} code' kernel.dump > "$variant.text"
  for mode in header groups tail occupied exhausted partial early late; do
    if ! CUPBOP_PERF_KERNEL_FILE="$PWD/$variant-$mode.jsonl" ./host.out "$mode" > "$variant-$mode.log" 2>&1; then
      cat "$variant-$mode.log"
      exit 1
    fi
    grep "^PASSED $mode (" "$variant-$mode.log"
  done
done

python3 - "$work/named/out.ll" <<'PY'
import json
from pathlib import Path
import re
import sys

def body(ir, kernel):
    return re.search(r"^define [^\n]*@" + kernel + r"\([^\n]*\{\n(.*?)^\}",
                     ir, flags=re.M | re.S)[1]

def check_groups(body, expected):
    issues, events = [], []
    for line in body.splitlines():
        issue = re.search(r"(%[\w.]+) = .*call i32 @__cupbop_cp_async_issue16\(.*i32 (\d+)\)", line)
        wait = re.search(r"call void @__cupbop_cp_async_wait\(i32 (%[\w.]+)\)", line)
        if issue:
            issues.append(issue[1])
            events.append(("issue", int(issue[2])))
        elif wait:
            events.append(("wait", issues.index(wait[1])))
        elif 'fence syncscope("singlethread")' in line:
            events.append("fence")
    assert events == expected, events

# Check which *actual token* each source wait consumes, including empty
# groups, uncommitted copies, simultaneous reservations and slot reuse.
named = Path(sys.argv[1]).read_text()
check_groups(body(named, "named_groups"), [
    ("issue", 0), ("issue", 1), ("wait", 0), ("wait", 1), "fence",
    ("issue", 0), ("issue", 1), ("wait", 2), "fence", ("wait", 3), "fence"])
assert "@__cupbop_cp_async_issue16" not in body(named, "opaque_branch")
for kernel in ("mbarrier_ptx", "mbarrier_named", "mbarrier_helper"):
    producer = body(named, kernel)
    assert "@__cupbop_cp_async_issue16" not in producer, kernel
    assert "load i128" in producer and "store i128" in producer, kernel
repeat = body(named, "repeat_wait")
issued = re.search(r"(%[\w.]+) = .*call i32 @__cupbop_cp_async_issue16", repeat)[1]
waited = re.findall(r"call void @__cupbop_cp_async_wait\(i32 ([%\w.]+)\)", repeat)
if waited != [issued, "0"]:  # LLVM may peel the first loop iteration.
    assert len(waited) == 1, waited
    phi = re.search(re.escape(waited[0]) + r" = phi i32 ([^\n]+)", repeat)
    assert phi and re.search(r"\[ 0,", phi[1]) and ("[ " + issued + ",") in phi[1], repeat
cuda = Path("auto.ll").read_text()
check_groups(body(cuda, "_Z6groupsPKjPj"), [
    ("issue", 0), ("issue", 1), ("issue", 2), ("wait", 0), ("wait", 1), "fence",
    ("issue", 0), ("wait", 2), ("wait", 3), "fence"])

for early in (0, 1):
    fn = body(cuda, f"_Z8timelineILb{early}EEvPKjPj")
    window = fn.split("call i32 @__cupbop_cp_async_issue16")[1].split("call void @__cupbop_cp_async_wait")[0]
    assert ("store volatile" in window) == (early == 0), window

issue = r"^\s*[0-9a-f]+:\s+060f800b\s"
for variant in ("auto", "off"):
    has_issue = bool(re.search(issue, Path(f"{variant}.text").read_text(), re.M))
    assert has_issue == (variant == "auto"), (variant, has_issue)
    cycles = {}
    for mode, expected in {"header": [1], "groups": [40], "tail": [20], "occupied": [40],
                           "exhausted": [0, 40], "partial": [0], "early": [16], "late": [16]}.items():
        records = [json.loads(line) for line in Path(f"{variant}-{mode}.jsonl").read_text().splitlines()]
        transfers = [r["val"]["dxa.transfers"] for r in records]
        assert transfers == (expected if variant == "auto" else [0] * len(expected)), (variant, mode, transfers)
        if mode in ("early", "late"):
            cycles[mode] = records[0]["cycles"]
        print(f"{variant} {mode}: DXA transfers {transfers}")
    print(f"{variant}: immediate wait {cycles['early']} cycles, deferred wait {cycles['late']} cycles")
PY
