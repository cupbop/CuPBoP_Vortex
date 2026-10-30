#!/usr/bin/env python3
"""stack_frames.py <kernel.dump> [--over N]: static stack frame of every kernel function in a Vortex kernel dump
(llvm-objdump -d). Per function, the stack-pointer decrements of the prologue (addi sp,sp,-N; sub sp,sp,reg with reg
from lui/addiw/li) are summed until the first increment. Runtime functions (kernel_main, vx_*, __*, memcpy, libm)
are skipped. Without --over: '<bytes> <function>' per function. With --over N: the names of the functions whose frame
exceeds N bytes, comma-separated, on one line (empty if none). Used by common.mk's fixed-trips fallback
(virt_trips_fallback.sh): the hardware thread's stack is 8 KB (VX_MEM_STACK_LOG2_SIZE=13)."""
import re, sys
SKIP = ('kernel_main', 'memcpy', 'memset', 'memmove', '_start', 'vx_', '__', 'exp', 'log', 'sin', 'cos', 'pow', 'fma')

def imm(s):
    return int(s, 16) if s.startswith(('0x', '-0x')) else int(s)

def frames(path):
    out, fn, regs, cur, done = {}, None, {}, 0, True
    for line in open(path, errors='replace'):
        m = re.match(r'^[0-9a-f]+ <(.*)>:$', line)
        if m:
            fn = m.group(1); regs = {}; cur = 0; done = fn.startswith(SKIP)
            if not done: out.setdefault(fn, 0)
            continue
        if done: continue
        t = line.rstrip()
        m = re.search(r'\taddi\tsp, sp, (-?(?:0x)?[0-9a-f]+)$', t)
        if m:
            v = imm(m.group(1))
            if v < 0: cur += -v; out[fn] = max(out[fn], cur)
            else: done = True
            continue
        m = re.search(r'\tlui\t(\w+), (0x[0-9a-f]+|\d+)$', t)
        if m: regs[m.group(1)] = imm(m.group(2)) << 12; continue
        m = re.search(r'\taddiw?\t(\w+), (\w+), (-?(?:0x)?[0-9a-f]+)$', t)
        if m and m.group(2) in regs and m.group(1) == m.group(2): regs[m.group(1)] += imm(m.group(3)); continue
        m = re.search(r'\tli\t(\w+), (-?(?:0x)?[0-9a-f]+)$', t)
        if m: regs[m.group(1)] = imm(m.group(2)); continue
        m = re.search(r'\tsub\tsp, sp, (\w+)$', t)
        if m and m.group(1) in regs: cur += regs[m.group(1)]; out[fn] = max(out[fn], cur); continue
        if re.search(r'\tadd\tsp, sp, (\w+)$', t): done = True
    return out

if __name__ == '__main__':
    f = frames(sys.argv[1])
    if len(sys.argv) > 3 and sys.argv[2] == '--over':
        n = int(sys.argv[3])
        print(','.join(k for k, v in f.items() if v > n))
    else:
        for k, v in sorted(f.items(), key=lambda kv: -kv[1]): print(v, k)
