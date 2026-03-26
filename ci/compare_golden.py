#!/usr/bin/env python3
"""Compare golden output against test output with floating-point tolerance.

Usage:
    compare_golden.py <golden_file> <test_file> [--tolerance=1e-4]

Checks that every line in golden_file can be found in test_file.
Numeric values are compared with tolerance, non-numeric lines are matched exactly.
Test file may contain extra lines (e.g. Vortex debug logs) which are ignored.
"""
import sys
import re
import argparse

def extract_numbers(line):
    """Extract all numbers (int or float) from a line."""
    return re.findall(r'-?\d+\.?\d*(?:[eE][+-]?\d+)?', line)

def lines_match(golden_line, test_line, tolerance):
    """Check if two lines match (exact text or float tolerance)."""
    g_nums = extract_numbers(golden_line)
    t_nums = extract_numbers(test_line)

    if len(g_nums) == 0 and len(t_nums) == 0:
        return golden_line.strip() == test_line.strip()

    if len(g_nums) != len(t_nums):
        return False

    for g_val, t_val in zip(g_nums, t_nums):
        try:
            gf = float(g_val)
            tf = float(t_val)
            if abs(gf - tf) > tolerance and abs(gf - tf) / max(abs(gf), 1e-10) > tolerance:
                return False
        except ValueError:
            if g_val != t_val:
                return False
    return True

def compare_files(golden_path, test_path, tolerance):
    with open(golden_path, 'r') as f:
        golden_lines = [l.strip() for l in f.readlines() if l.strip()]
    with open(test_path, 'r') as f:
        test_lines = [l.strip() for l in f.readlines() if l.strip()]

    missing = []
    for g_line in golden_lines:
        found = False
        for t_line in test_lines:
            if lines_match(g_line, t_line, tolerance):
                found = True
                break
        if not found:
            missing.append(g_line)

    if not missing:
        print(f"PASS: all {len(golden_lines)} golden lines found in test output (tolerance={tolerance})")
        return True
    else:
        print(f"FAIL: {len(missing)}/{len(golden_lines)} golden lines not found in test output")
        for line in missing:
            print(f"  MISSING: {line}")
        return False

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('golden')
    parser.add_argument('test')
    parser.add_argument('--tolerance', type=float, default=1e-4)
    args = parser.parse_args()

    success = compare_files(args.golden, args.test, args.tolerance)
    sys.exit(0 if success else 1)
