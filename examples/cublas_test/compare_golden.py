"""compare_golden.py <golden values.txt> <vortex values.txt>: every result element of cublas_test on both sides.

Elements of a case must match within the case's tolerance (relative to the case's largest magnitude): 1e-5 for fp32
results, 2^-9 for fp16 and 2^-6 for bf16 outputs (a rounding step each side). Exit 0 when every element of every case does.
"""
import collections
import sys


def load(path):
    out = collections.OrderedDict()
    for line in open(path):
        name, i, v = line.split()
        out.setdefault(name, {})[int(i)] = float(v)
    return out


def tol(name):
    if name in ("gemmex_h_h",):
        return 2.0 ** -9
    if name in ("gemmex_b_b",):
        return 2.0 ** -6
    return 1e-5


g, v = load(sys.argv[1]), load(sys.argv[2])
bad = 0
for name in g:
    if name not in v or set(g[name]) != set(v[name]):
        print(f"{name:24s} MISSING on Vortex")
        bad += 1
        continue
    scale = max(abs(x) for x in g[name].values()) or 1.0
    worst = max(abs(g[name][i] - v[name][i]) for i in g[name]) / scale
    ok = worst <= tol(name)
    bad += not ok
    print(f"{name:24s} n={len(g[name]):6d} max|gpu-vortex|/max|gpu|={worst:.3g} tol={tol(name):.3g} {'MATCH' if ok else 'DIFFER'}")
extra = [n for n in v if n not in g]
for n in extra:
    print(f"{n:24s} only on Vortex")
print("compare_golden:", "MATCH" if not bad and not extra else f"{bad} cases differ")
sys.exit(1 if bad or extra else 0)
