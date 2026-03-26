#!/usr/bin/env python3
"""Parse Perf_counter files and output a markdown summary table.

Usage:
    perf_summary.py <perf_file> <test_name> <schedule>

Reads lines like:
    PERF: instrs=4537, cycles=22987, IPC=0.197372

Outputs a markdown table with per-kernel and total stats.
"""
import sys
import re

def parse_perf(filepath):
    entries = []
    with open(filepath, 'r') as f:
        for line in f:
            if 'PERF: core' in line:
                continue
            m = re.match(r'PERF:\s+instrs=(\d+),\s+cycles=(\d+),\s+IPC=([\d.]+)', line.strip())
            if m:
                entries.append({
                    'instrs': int(m.group(1)),
                    'cycles': int(m.group(2)),
                    'ipc': float(m.group(3)),
                })
    return entries

def main():
    if len(sys.argv) < 4:
        print("Usage: perf_summary.py <perf_file> <test_name> <schedule>")
        sys.exit(1)

    filepath = sys.argv[1]
    test_name = sys.argv[2]
    schedule = sys.argv[3]

    entries = parse_perf(filepath)
    if not entries:
        print(f"No PERF data found in {filepath}")
        sys.exit(0)

    total_instrs = sum(e['instrs'] for e in entries)
    total_cycles = sum(e['cycles'] for e in entries)
    total_ipc = total_instrs / total_cycles if total_cycles > 0 else 0

    print(f"### {test_name} (SCHE_{schedule})")
    print()
    print("| Kernel | Instructions | Cycles | IPC |")
    print("|--------|-------------|--------|-----|")
    for i, e in enumerate(entries):
        print(f"| kernel_{i} | {e['instrs']:,} | {e['cycles']:,} | {e['ipc']:.6f} |")
    if len(entries) > 1:
        print(f"| **Total** | **{total_instrs:,}** | **{total_cycles:,}** | **{total_ipc:.6f}** |")
    print()

if __name__ == '__main__':
    main()
