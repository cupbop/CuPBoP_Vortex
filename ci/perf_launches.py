#!/usr/bin/env python3
"""perf_launches.py <perf_kernel.jsonl> [--tsv] [--counters a,b,...]: per-launch counters from the CUPBOP_PERF_KERNEL_FILE
record (runtime/src/vortex/host/cudaRuntimeImpl.cpp cupbop_perf_post: one JSON line per kernel launch).

Each line carries every counter's value right after the launch ("raw") and its change over the launch ("delta" = raw
minus the value right before the launch). Whether a counter restarts at a launch depends on the Vortex version (v3.0
SimX: caches, memory, LMEM, TCU, DXA and the operand-stall count restart, the other core counters run free; upstream
master since #435 keeps the memory counters running), so the mode is decided here over every record of one process
(same "pid"): a counter that dropped at any launch restarts ("r": the launch's count is raw), otherwise it runs free
("c": the count is delta). The runtime's own per-line "mode"/"val" fields use only the launches before and at that line.
Prints one line per launch: launch, kernel, cycles, instrs and the requested counters (default: a fixed short list);
--tsv prints tab-separated with a header. Exit 1 when the file has no record."""
import json, sys

DEFAULT = ["core.loads", "core.stores", "dcache.reads", "dcache.writes", "l2.reads", "l2.writes", "mem.reads",
           "mem.writes", "lmem.reads", "lmem.writes"]


def load(path):
    recs = [json.loads(l) for l in open(path) if l.strip().startswith("{")]
    modes = {}
    for pid in {r.get("pid") for r in recs}:
        rs = [r for r in recs if r.get("pid") == pid]
        m = {}
        for r in rs:
            for k, d in r["delta"].items():
                if d < 0: m[k] = "r"
                else: m.setdefault(k, "c")
        modes[pid] = m
    for r in recs:
        m = modes[r.get("pid")]
        r["mode_run"] = m
        r["count"] = {k: (r["raw"][k] if m.get(k) == "r" else r["delta"][k]) for k in r["raw"]}
    return recs


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__); sys.exit(2)
    tsv = "--tsv" in args
    cnt = DEFAULT
    if "--counters" in args:
        cnt = args[args.index("--counters") + 1].split(",")
    recs = load(args[0])
    if not recs:
        sys.exit(1)
    cols = ["launch", "kernel", "grid", "block", "lmem", "cycles", "instrs"] + cnt
    if tsv: print("\t".join(cols))
    for r in recs:
        row = [r["launch"], r["kernel"][:60], "x".join(map(str, r["grid"])), "x".join(map(str, r["block"])), r["lmem"],
               r["cycles"], r["count"]["core.instrs"]] + [r["count"].get(c, "") for c in cnt]
        print(("\t" if tsv else " ").join(str(x) for x in row))
    if not tsv:
        m = recs[-1]["mode_run"]
        print("restarting at each launch:", " ".join(sorted(k for k, v in m.items() if v == "r")) or "-")


if __name__ == "__main__":
    main()
