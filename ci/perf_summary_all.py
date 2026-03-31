#!/usr/bin/env python3
"""Parse all Perf_counter files and output a single markdown summary table.

Usage:
    perf_summary_all.py <examples_dir>

Scans examples_dir/*/Perf_counter_*.txt and produces one table per schedule+localmem.
Reads ci_status_SCHE_*_LMEM_*.txt to show PASS/FAIL status.
"""
import sys
import os
import re
import glob

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
                })
    total_instrs = sum(e['instrs'] for e in entries)
    total_cycles = sum(e['cycles'] for e in entries)
    total_ipc = total_instrs / total_cycles if total_cycles > 0 else 0
    return total_instrs, total_cycles, total_ipc

def read_status(examples_dir, benchmark, schedule, lmem):
    status_file = os.path.join(examples_dir, benchmark, f'ci_status_SCHE_{schedule}_LMEM_{lmem}.txt')
    try:
        with open(status_file, 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        return "N/A"

def main():
    if len(sys.argv) < 2:
        print("Usage: perf_summary_all.py <examples_dir>")
        sys.exit(1)

    examples_dir = sys.argv[1]
    perf_files = glob.glob(os.path.join(examples_dir, '*/Perf_counter_*.txt'))

    if not perf_files:
        print("No Perf_counter files found.")
        sys.exit(0)

    # Group by (schedule, localmem)
    group_data = {}
    for f in perf_files:
        basename = os.path.basename(f)
        m_sche = re.search(r'SCHE_(\d+)', basename)
        if not m_sche:
            continue
        schedule = m_sche.group(1)

        m_lmem = re.search(r'LOCAL_MEM_(\d+)', basename)
        lmem = m_lmem.group(1) if m_lmem else "1"

        benchmark = os.path.basename(os.path.dirname(f))

        instrs, cycles, ipc = parse_perf(f)
        if instrs == 0:
            continue

        status = read_status(examples_dir, benchmark, schedule, lmem)
        if status == "N/A":
            continue  # skip stale perf files from previous runs

        key = (schedule, lmem)
        if key not in group_data:
            group_data[key] = []
        group_data[key].append({
            'benchmark': benchmark,
            'instrs': instrs,
            'cycles': cycles,
            'ipc': ipc,
            'status': status,
        })

    for key in sorted(group_data.keys()):
        schedule, lmem = key
        entries = sorted(group_data[key], key=lambda e: e['benchmark'])
        pass_entries = [e for e in entries if e['status'] == 'PASS']
        total_instrs = sum(e['instrs'] for e in pass_entries)
        total_cycles = sum(e['cycles'] for e in pass_entries)
        total_ipc = total_instrs / total_cycles if total_cycles > 0 else 0

        title = f"## Performance Summary (SCHE_{schedule}"
        if schedule == "2" and lmem == "0":
            title += f", LMEM={lmem}"
        title += ")"

        print(title)
        print()
        print("| Status | Benchmark | Instructions | Cycles | IPC |")
        print("|--------|-----------|-------------|--------|-----|")
        for e in entries:
            status_icon = {"PASS": "✅", "FAIL": "❌", "SKIP": "⏭️"}.get(e['status'], "❓")
            print(f"| {status_icon} | {e['benchmark']} | {e['instrs']:,} | {e['cycles']:,} | {e['ipc']:.6f} |")
        print(f"| | **Total (PASS only)** | **{total_instrs:,}** | **{total_cycles:,}** | **{total_ipc:.6f}** |")
        print()

if __name__ == '__main__':
    main()
