#!/usr/bin/env python3
r"""Check same-warp user arithmetic during native DXA transfers in cp_async_groups.

Use a 32-lane flat DXA SimX and the matching CuPBoP environment. Build the
default native example once, then trace the same ELF with two memory profiles.

  set -e -o pipefail
  cd "$CuPBoP_PATH/examples/cp_async_groups"
  unset CUPBOP_CP_ASYNC_COALESCED_DXA
  export VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1
  make build SCHEDULE=2 LOCALMEM=1
  traces=$(mktemp -d)
  for latency in 0 512; do
    d="$traces/latency-$latency"
    mkdir "$d"
    make -C "$VORTEX_PATH/sim/simx" -j8 DESTDIR="$d" DEBUG=3 PERF=1 \
        CONFIGS="$VORTEX_CONFIGS -DVX_CFG_PLATFORM_MEMORY_LATENCY=$latency" "$d/libsimx.so"
    for mode in early late; do
      LD_LIBRARY_PATH="$d:$CuPBoP_PATH/build/runtime:$CuPBoP_PATH/build/runtime/threadPool:$VORTEX_PATH/sw/runtime:$LD_LIBRARY_PATH" \
          CUPBOP_PERF_KERNEL_FILE="$d/$mode.jsonl" ./host.out "$mode" 2>&1 | gzip > "$d/$mode.gz"
    done
  done
  analyzer="$CuPBoP_PATH/ci/cp_async_overlap_trace.py"
  "$analyzer" kernel.elf "$traces/latency-0/early.gz" "$traces/latency-0/late.gz" --expect none
  "$analyzer" kernel.elf "$traces/latency-512/early.gz" "$traces/latency-512/late.gz" --expect overlap

These expectations apply to the measured 1-core/8-warp profile. Omit --expect
to report the observed deferred-wait overlap on another configuration.
"""

import argparse
from collections import Counter
import gzip
import os
from pathlib import Path
import re
import subprocess


def user_multiplications(objdump, elf, early):
    symbol = f"__vx_kentry__Z8timelineILb{int(early)}EEvPKjPj"
    dump = subprocess.check_output(
        [objdump, "-d", "-M", "no-aliases", "--no-show-raw-insn",
         "--disassemble-symbols=" + symbol, elf], text=True)
    code = re.findall(r"^\s*([0-9a-f]+):\s+(\S+)\s*([^\n]*)$", dump, re.M)
    # STEP(x) always multiplies by 1664525. Identify its constant register
    # from the function prologue so the runtime's geometry MUL is excluded.
    constants = {"zero": 0}
    for _, op, operands in code:
        if op.startswith(("b", "j")):
            break
        args = operands.strip().split(", ")
        if op == "lui":
            constants[args[0]] = int(args[1], 0) << 12
        elif op in ("addi", "addiw") and args[1] in constants:
            constants[args[0]] = constants[args[1]] + int(args[2], 0)
        elif op not in ("sd", "sw", "sh", "sb"):
            constants.pop(args[0], None)
    registers = {reg for reg, value in constants.items() if value == 1664525}
    pcs = {int(pc, 16) for pc, op, operands in code if op in ("mul", "mulw")
           and registers.intersection(operands.strip().split(", ")[1:])}
    if len(pcs) != 16:
        raise ValueError(f"{symbol}: found {len(pcs)} linked STEP multiplies, expected 16")
    return pcs


START = re.compile(r"TRACE\s+(\d+): (\S*dxa-core\[\d+\]) start: core=(\d+), wid=(\d+),")
COMPLETE = re.compile(r"TRACE\s+(\d+): (\S*dxa-core\[\d+\]) complete: core=(\d+),")
ISSUE = re.compile(r"TRACE\s+(\d+): \S+-pipeline issue: cid=(\d+), wid=(\d+),.*? PC=0x([0-9a-f]+),")


def count_overlap(path, mode, pcs):
    active = {}
    intervals = []
    issues = []
    passed = False
    open_trace = gzip.open if path.suffix == ".gz" else open
    with open_trace(path, "rt") as stream:
        for line in stream:
            if match := START.match(line):
                cycle, worker, core, warp = match.groups()
                if worker in active:
                    raise ValueError(f"{path}: duplicate start for {worker}")
                active[worker] = (int(cycle), core, warp)
            elif match := COMPLETE.match(line):
                cycle, worker, core = match.groups()
                start, origin, warp = active.pop(worker)
                if origin != core or start >= int(cycle):
                    raise ValueError(f"{path}: malformed DXA interval for {worker}")
                intervals.append((start, int(cycle), core, warp))
            elif match := ISSUE.match(line):
                cycle, core, warp, pc = match.groups()
                if int(pc, 16) in pcs:
                    issues.append((int(cycle), core, warp, int(pc, 16)))
            elif line.strip() == f"PASSED {mode} (32 words)":
                passed = True
    counts = Counter(pc for _, _, _, pc in issues)
    if not passed or active or len(intervals) != 16 or any(counts[pc] != 16 for pc in pcs):
        raise ValueError(f"{path}: expected numerical PASS, 16 completed transfers and 16 issues per STEP MUL")
    overlap = sum(any(start <= cycle < end and (core, warp) == (src_core, src_warp)
                      for start, end, src_core, src_warp in intervals)
                  for cycle, core, warp, _ in issues)
    durations = [end - start for start, end, _, _ in intervals]
    print(f"{mode}: {len(intervals)} DXAs, {min(durations)}..{max(durations)} cycles each, "
          f"{overlap}/{len(issues)} user MULs issued during same-warp DXA")
    return overlap


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("elf", type=Path)
    parser.add_argument("early_trace", type=Path)
    parser.add_argument("late_trace", type=Path)
    parser.add_argument("--expect", choices=("none", "overlap"))
    default_objdump = Path(os.environ["LLVM_PREFIX"]) / "bin/llvm-objdump" if "LLVM_PREFIX" in os.environ else "llvm-objdump"
    parser.add_argument("--objdump", default=default_objdump)
    args = parser.parse_args()
    early = count_overlap(args.early_trace, "early", user_multiplications(args.objdump, args.elf, True))
    late = count_overlap(args.late_trace, "late", user_multiplications(args.objdump, args.elf, False))
    if early or (args.expect == "none" and late) or (args.expect == "overlap" and not late):
        parser.exit(1, "Unexpected instruction/copy overlap\n")
