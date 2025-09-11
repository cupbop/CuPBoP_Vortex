
#!/usr/bin/env python3
import os
import re
import csv
from pathlib import Path

# 실행할 벤치마크 폴더들만 여기 선언
benchmarks = [
    "backprop",
    "bfs",
    "btree",
    "conv3",
    "dotproduct",
    "gauss",
    "nn",
    "pathfinder",
    "psum",
    "saxpy",
    "sgemm",
    "stencil",
    "transpose",
    "vecadd",
    "psort",
]

# 찾을 파일 이름 패턴들
CANDIDATE_FILES = [
    "CGO_perf_counter_4C_16W_32T_SCHE_2_test1.txt",
]

SCHE_RE = re.compile(r"SCHE[_\.](\d+)")
LINE_RE = re.compile(
    r'^PERF:\s*instrs=(?P<instrs>\d+),\s*cycles=(?P<cycles>\d+),\s*IPC=',
    re.IGNORECASE
)

def find_perf_file(d: Path):
    for name in CANDIDATE_FILES:
        p = d / name
        if p.is_file():
            return p
    for p in d.glob("CGO_perf_counter_4C_16W_32T*test1.txt"):
        if p.is_file():
            return p
    return None

def parse_sche_from_filename(fp: Path) -> str:
    m = SCHE_RE.search(fp.name)
    return m.group(1) if m else ""

def sum_global_perf(fp: Path):
    instrs_sum = 0
    cycles_sum = 0
    with fp.open("r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            if "core" in line:
                continue
            m = LINE_RE.match(line.strip())
            if m:
                instrs_sum += int(m.group("instrs"))
                cycles_sum += int(m.group("cycles"))
    return instrs_sum, cycles_sum

def main():
    root = Path.cwd()
    rows = []

    for bench_name in benchmarks:
        folder = root / bench_name
        if not folder.is_dir():
            print(f"[WARN] {bench_name} 폴더 없음, 스킵")
            continue

        perf_file = find_perf_file(folder)
        if not perf_file:
            print(f"[WARN] {bench_name} 안에서 perf 파일 못찾음")
            continue

        sche = parse_sche_from_filename(perf_file)
        instrs, cycles = sum_global_perf(perf_file)

        rows.append((bench_name, sche, instrs, cycles))

    out_csv = root / "perf_summary_test1.csv"
    with out_csv.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["benchmark", "sche", "instrs", "cycles"])
        for r in rows:
            writer.writerow(r)

    print(f"[OK] Wrote {out_csv} ({len(rows)} benchmarks)")

if __name__ == "__main__":
    main()