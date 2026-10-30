#!/usr/bin/env python3
"""abi_check.py <kernel.dump> <cupbop_kabi.txt> [-v]: static check of the Vortex kernel ABI calls (CUPBOP_KABI).

The functions listed in cupbop_kabi.txt (generate_wrapper.cpp annotate_kernel_abi: the translated kernels, their
<name>_wrapper and the schedule 0/1 cuda_* wrappers) carry the "vortex.kernel" calling convention: they save no
callee-saved register (s0-s11, fs0-fs11), so after a call to one of them every callee-saved register holds garbage.
kernel_main (vortex.kernel itself) calls them through a clobber-all inline asm (the callbacks[] table: its indirect
calls). This script reads the kernel ELF disassembly (llvm-objdump -d/-D, sections .init and .text) and checks:
  1. every call site of a clobbering function (a listed one, kernel_main's indirect calls, or a function that tail-jumps
     to a clobbering one): on every path from the instruction after the call to the caller's return, no callee-saved
     register is read before it is written (data-flow over the caller's branches and jumps; another call to a
     clobbering function invalidates them again);
  2. such a caller is itself kernel-ABI (listed, or kernel_main): an ordinary function that made a non-tail call would
     return to its own caller with callee-saved registers it never saved clobbered;
  3. no unresolved indirect jump on those paths (it could not be followed).
Prints UNSAFE lines (every call with -v) and 'RESULT SAFE <calls>' (exit 0) or 'RESULT UNSAFE' (exit 1); exit 2 when the
dump has no kernel_main call to check (unparsable dump). Run by examples/stack_fallback.sh after every kernel ELF build
that has cupbop_kabi.txt; UNSAFE fails the build. Known failures it catches (experiments/stack_native): the annotation
without the asm call (vx_join read s0/s1 after the call: s1 FAIL), and an alloca-based sp skew together with the kernel
ABI (kernel_main restored sp from its frame pointer s0 after the call: hang)."""
import re, sys

KENTRY = '__vx_kentry_'
CS = {'s%d' % i for i in range(12)} | {'fs%d' % i for i in range(12)}
REG = re.compile(r'\b(zero|ra|sp|gp|tp|fp|t[0-6]|s1[01]|s[0-9]|a[0-7]|ft1[01]|ft[0-9]|fs1[01]|fs[0-9]|fa[0-7])\b')
STORES = {'sb', 'sh', 'sw', 'sd', 'fsh', 'fsw', 'fsd', 'c.sw', 'c.sd', 'c.fsd', 'c.swsp', 'c.sdsp', 'c.fsdsp'}
SRC_ONLY = {'vx_join', 'vx_pred', 'vx_pred_n', 'vx_tmc', 'vx_wspawn', 'vx_bar', 'vx_barrier', 'csrw', 'csrs', 'csrc',
            'fence', 'fence.i', 'ecall', 'ebreak', 'nop', 'j', 'jr'}
BRANCHES = {'beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu', 'beqz', 'bnez', 'blez', 'bgez', 'bltz', 'bgtz', 'bgt', 'ble',
            'bgtu', 'bleu', 'c.beqz', 'c.bnez'}


def norm(r):
    return 's0' if r == 'fp' else r


def parse(path):
    """-> list of (pc, mnemonic, operands, function) for the code sections, function start/end pcs"""
    ins, cur, code = [], None, False
    for line in open(path, errors='replace'):
        if line.startswith('Disassembly of section'):
            code = line.split()[-1].rstrip(':') in ('.init', '.text')
            cur = None
            continue
        if not code:
            continue
        m = re.match(r'^([0-9a-f]+) <(.+)>:\s*$', line)
        if m:
            cur = m.group(2)
            if cur.startswith(KENTRY): cur = cur[len(KENTRY):]
            continue
        m = re.match(r'^\s*([0-9a-f]+):\s+[0-9a-f]{4}(?:[0-9a-f]{4})?\s+(\S+)\s*(.*)$', line.rstrip())
        if m and cur:
            ins.append((int(m.group(1), 16), m.group(2), m.group(3), cur))
    rng = {}
    for i, (pc, _m, _a, f) in enumerate(ins):
        lo, hi = rng.get(f, (i, i))
        rng[f] = (min(lo, i), max(hi, i))
    return ins, rng


def target(args):
    m = re.search(r'0x([0-9a-f]+) <([^>+]+)(\+0x[0-9a-f]+)?>', args)
    return (int(m.group(1), 16), m.group(2)[len(KENTRY):] if m.group(2).startswith(KENTRY) else m.group(2)) if m else (None, None)


def kind(mn, args):
    """call | tailcall | jump | branch | ret | ijump | icall | other"""
    regs = [norm(r) for r in REG.findall(args.split('<')[0])]
    if mn == 'ret': return 'ret'
    if mn in ('jal', 'call', 'c.jal'): return 'call' if (not regs or regs[0] == 'ra') else ('jump' if regs[0] == 'zero' else 'call')
    if mn in ('j', 'tail', 'c.j'): return 'jump'
    if mn in BRANCHES: return 'branch'
    if mn in ('jalr', 'c.jalr'):
        if len(regs) == 1: return 'icall'                       # jalr rs  (rd = ra)
        if regs[0] == 'zero': return 'ret' if regs[-1] == 'ra' else 'ijump'
        return 'icall'
    if mn in ('jr', 'c.jr'): return 'ret' if regs and regs[0] == 'ra' else 'ijump'
    return 'other'


def srcs_dsts(mn, args):
    regs = [norm(r) for r in REG.findall(args.split('<')[0])]
    if mn in STORES or mn in BRANCHES or mn in SRC_ONLY or mn.startswith('csrw') or mn.startswith('csrs') or mn.startswith('csrc'):
        return regs, []
    if mn in ('jalr', 'c.jalr'):
        return (regs[-1:], ['ra'] if len(regs) == 1 else regs[:1])
    if mn in ('jal', 'call'): return [], ['ra']
    return regs[1:], regs[:1]


def main():
    dump, lst = sys.argv[1], sys.argv[2]
    verbose = '-v' in sys.argv[3:]
    listed = set()
    for line in open(lst):
        line = line.strip()
        if line and not line.startswith('#'): listed.add(line[len(KENTRY):] if line.startswith(KENTRY) else line)
    ins, rng = parse(dump)
    idx = {pc: i for i, (pc, *_r) in enumerate(ins)}
    kabi = listed | {'kernel_main'}
    for n in sorted(listed - set(rng)):
        if verbose: print(f"note: {n} is not in the ELF (inlined or removed)")

    # clobbering functions: listed ones and, transitively, functions that tail-jump to one
    clob = set(listed)
    changed = True
    while changed:
        changed = False
        for pc, mn, args, f in ins:
            if f in clob: continue
            k = kind(mn, args)
            if k == 'jump':
                t, tn = target(args)
                lo, hi = rng[f]
                if t is not None and not (ins[lo][0] <= t <= ins[hi][0]) and tn in clob:
                    clob.add(f); changed = True

    bad, ncalls = [], 0

    def scan(ci):
        """data flow from the instruction after call ci to the caller's exits; returns problems"""
        f = ins[ci][3]
        lo, hi = rng[f]
        allcs = frozenset(CS)
        state = {}                                           # instruction index -> callee-saved written on all paths
        work = [(ci + 1, frozenset())]
        probs = []
        while work:
            i, w = work.pop()
            if i > hi:
                probs.append(('falls off the end of %s' % f, ins[hi][0])); continue
            old = state.get(i, allcs)
            new = old & w
            if i in state and new == old: continue
            state[i] = new
            pc, mn, args, _f = ins[i]
            s, d = srcs_dsts(mn, args)
            for r in s:
                if r in CS and r not in new: probs.append(('reads %s: %s %s' % (r, mn, args), pc))
            out = new | {r for r in d if r in CS}
            k = kind(mn, args)
            if k in ('call', 'icall'):
                t, tn = target(args)
                if k == 'icall' or tn in clob: out = frozenset()
                work.append((i + 1, out))
            elif k == 'ret':
                continue
            elif k == 'ijump':
                probs.append(('unresolved indirect jump: %s %s' % (mn, args), pc))
            elif k in ('jump', 'branch'):
                t, tn = target(args)
                if t is not None and ins[lo][0] <= t <= ins[hi][0]:
                    work.append((idx[t], out))
                # a jump out of the function is a tail call: the caller's own exit
                if k == 'branch': work.append((i + 1, out))
            else:
                work.append((i + 1, out))
        return probs

    seen_main = False
    for i, (pc, mn, args, f) in enumerate(ins):
        k = kind(mn, args)
        if k == 'icall' and f == 'kernel_main':
            callee = 'indirect (callbacks)'
            seen_main = True
        elif k == 'call':
            t, tn = target(args)
            if tn not in clob: continue
            callee = tn
        else:
            continue
        ncalls += 1
        probs = scan(i)
        if f not in kabi:
            probs.append(('ordinary-ABI caller %s returns with callee-saved registers clobbered by %s' % (f, callee), pc))
        if probs:
            bad.append((f, callee, pc, probs))
            print('UNSAFE %s -> %s @%#x: %s' % (f, callee, pc, '; '.join('%s @%#x' % p for p in probs[:4])))
        elif verbose:
            print('SAFE %s -> %s @%#x' % (f, callee, pc))
    if not seen_main:
        print('RESULT ERROR: no indirect call in kernel_main found in %s' % dump)
        sys.exit(2)
    if bad:
        print('RESULT UNSAFE')
        sys.exit(1)
    print('RESULT SAFE %d calls (%s)' % (ncalls, ' '.join(sorted(listed & set(rng)))))


if __name__ == '__main__':
    main()
