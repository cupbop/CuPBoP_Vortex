#!/usr/bin/env python3
"""Parse all Perf_counter files and output a single markdown summary table.

Usage:
    perf_summary_all.py <examples_dir>

Scans examples_dir/*/Perf_counter_*.txt and produces one table per schedule.
Reads ci_status_SCHE_*.txt to show PASS/FAIL status.
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

def read_status(examples_dir, benchmark, schedule):
    status_file = os.path.join(examples_dir, benchmark, f'ci_status_SCHE_{schedule}.txt')
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

    # Group by schedule
    schedule_data = {}
    for f in perf_files:
        m = re.search(r'SCHE_(\d+)', os.path.basename(f))
        if not m:
            continue
        schedule = m.group(1)
        benchmark = os.path.basename(os.path.dirname(f))

        instrs, cycles, ipc = parse_perf(f)
        if instrs == 0:
            continue

        if schedule not in schedule_data:
            schedule_data[schedule] = []
        schedule_data[schedule].append({
            'benchmark': benchmark,
            'instrs': instrs,
            'cycles': cycles,
            'ipc': ipc,
            'status': read_status(examples_dir, benchmark, schedule),
        })

    for schedule in sorted(schedule_data.keys()):
        entries = sorted(schedule_data[schedule], key=lambda e: e['benchmark'])
        pass_entries = [e for e in entries if e['status'] == 'PASS']
        total_instrs = sum(e['instrs'] for e in pass_entries)
        total_cycles = sum(e['cycles'] for e in pass_entries)
        total_ipc = total_instrs / total_cycles if total_cycles > 0 else 0

        print(f"## Performance Summary (SCHE_{schedule})")
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
