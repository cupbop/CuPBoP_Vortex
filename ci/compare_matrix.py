#!/usr/bin/env python3
"""compare_matrix.py <baseline results.csv> <results.csv>: what changed between two runs of ci/run-v3-matrix.sbatch (ci/logs_v3/run_<job>/).
Lists every run whose verdict changed and every run whose cycles moved by more than 0.5% (SimX is deterministic: the same binary gives
the same cycles, so any move is the code). Exit 1 when a verdict got worse (PASS -> FAIL). Run with python3 -I.
Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"""
import csv, sys

def load(p):
    return {(r["test"], r["schedule"], r["localmem"]): r for r in csv.DictReader(open(p))}

a, b = load(sys.argv[1]), load(sys.argv[2])
worse, rows = 0, []
for k in sorted(set(a) | set(b)):
    x, y = a.get(k), b.get(k)
    name = f"{k[0]} s{k[1]} l{k[2]}"
    if not x or not y:
        rows.append(f"  {name}: {'new' if y else 'gone'}")
        continue
    if x["result"] != y["result"]:
        rows.append(f"  {name}: {x['result']} -> {y['result']}")
        worse += x["result"] == "PASS" and y["result"] == "FAIL"
        continue
    cx, cy = x.get("cycles"), y.get("cycles")
    if cx and cy and int(cx) and abs(int(cy) / int(cx) - 1) > 0.005:
        rows.append(f"  {name}: cycles {int(cx):,} -> {int(cy):,} ({100 * (int(cy) / int(cx) - 1):+.1f}%)")
print(f"{len(b)} runs against {len(a)}: {len(rows)} changed, {worse} got worse")
print("\n".join(rows) if rows else "  nothing changed")
sys.exit(1 if worse else 0)
