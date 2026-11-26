#!/usr/bin/env bash
# Replay two independently named queues on SimX. SM90a ptxas emits only gsb0
# for this kernel, so exercise the other queue with an explicit SASS variant.
set -euo pipefail
original=$(realpath "${1:?pass the lifted hopper_wgmma_gsb test directory}")
case_dir=$(mktemp -d -p "$(dirname "$original")" gsb-multiple.XXXXXXXX)
cp "$original/"{Makefile,hopper_wgmma_gsb.cu,hopper.cubin} "$case_dir/"
cd "$case_dir"
python3 - "$original/hopper.sass" <<'PY'
from pathlib import Path
import re
import sys

lines = Path(sys.argv[1]).read_text().splitlines(keepends=True)
issues = [i for i, line in enumerate(lines) if "HGMMA." in line]
waits = [i for i, line in enumerate(lines) if "WARPGROUP.DEPBAR.LE" in line]
assert len(issues) == 3 and len(waits) == 2
# The first and third groups update the same accumulator on gsb2. The
# independent second group, on gsb0, supplies the first store's data.
for index in (issues[0], issues[2], *waits):
    assert "gsb0" in lines[index]
    lines[index] = lines[index].replace("gsb0", "gsb2")
# Keep 1 of the 2 gsb2 groups pending. Drain gsb0 before reading its
# independent result. Keep the final gsb2 wait 0 before reading its result.
partial = waits[0]
assert re.search(r"gsb2, 0x1\s*;", lines[partial])
address = re.search(r"/\*([a-f0-9]+)\*/", lines[partial])
extra = lines[waits[1]].replace("gsb2", "gsb0")
extra = re.sub(r"/\*[a-f0-9]+\*/", f"/*{int(address[1], 16) + 8:04x}*/", extra, count=1)
lines[partial + 2:partial + 2] = [extra, lines[waits[1] + 1]]
Path("multiple.sass").write_text("".join(lines))
PY
"$CULIFTER_ENV/bin/python" "$CULIFTER_HOME/main.py" -i multiple.sass hopper.cubin -o raw --lifter nvvm > lift.log 2>&1
"$LLVM_PREFIX/bin/opt" -passes=verify -disable-output raw.ll
xz -k raw.ll
export CUPBOP_MMA_LOWERING=tcu VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}
make build SCHEDULE=2 LOCALMEM=1 > build.log 2>&1
CUPBOP_PERF_KERNEL_FILE=perf.jsonl make ci-run SCHEDULE=2 LOCALMEM=1 > run.log 2>&1
grep -F 'PASSED!: 1024/1024' run.log
"$LLVM_PREFIX/bin/llvm-objdump" -d --section=.text kernel.elf > text.dump
python3 - <<'PY'
import collections
import json
from pathlib import Path
import re

words = [int(w, 16) for w in re.findall(r"^\s*[a-f0-9]+:\s+([a-f0-9]{8})\s", Path("text.dump").read_text(), re.M)]
ctrl = [(w >> 7 & 31, w >> 15 & 31, w >> 20 & 31) for w in words
        if w & 0x7f == 0x0b and w >> 25 == 2 and w >> 12 & 7 == 4 and w >> 7 & 31]
# Vortex stores (CUDA scoreboard + 1) in rd. Each committed group has one
# native and one mutually exclusive high-local-memory fallback site.
assert collections.Counter(q for q, op, n in ctrl if op == 1) == {1: 2, 3: 4}, ctrl
assert [(q, n) for q, op, n in ctrl if op == 2] == [(3, 1), (1, 0), (3, 0)], ctrl
counts = [json.loads(line)["val"]["tcu.lmem_reads"] for line in Path("perf.jsonl").read_text().splitlines()]
assert len(counts) == 1 and counts[0] > 0, counts
print("gsb2 and gsb0 independent native queues: wait depths (1, 0, 0)")
PY
