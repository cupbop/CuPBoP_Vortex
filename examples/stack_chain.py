#!/usr/bin/env python3
"""stack_chain.py <kernel.dump> <kernel_wrapper.cpp>: static stack bytes of the deepest call chain below each kernel
entry of callbacks[] (kernel_wrapper.cpp), for the stack in local memory (CUPBOP_STACK_IN_LMEM, generate_wrapper.cpp
stack_lmem_prelude; read by the host runtime, cudaRuntimeImpl.cpp cupbop_stack_lmem). Written by
examples/stack_fallback.sh into cupbop_lmem_stack.txt:
    kernel <callbacks index> <chain bytes> <flags> <entry symbol>
flags: ok | indirect (an indirect call jalr is reachable: the chain is not bounded) | recursion | noentry (the entry
is not in the dump) | stackamo (a reachable function does an atomic on an address derived from one of its allocas, per
kernel.ll next to the dump: an LMEM atomic works in SimX but not in the RTL, VX_lmem_switch asserts). Frame of a function = the largest sum of its sp decrements before the first increment
(addi sp,sp,-N; sub sp,sp,reg with reg from lui/addiw/li), as examples/stack_frames.py, but for every function
(runtime helpers, libm, memcpy, ... included). A variable sub sp,sp,reg (run-time sized alloca) is not counted here:
those bytes come from cupbop_dyn_stack.txt (generate_wrapper.cpp describe_dyn_stack). Calls: jal <f> (call), j <f>
to another function's first instruction (tail call, counted like a call: conservative), jalr <reg> (indirect).
The chain of a function = its frame + the largest chain among its callees. kernel_main itself is not counted: it
stays on the hardware stack (the kernel is called on the new stack)."""
import os, re, sys

KENTRY = '__vx_kentry_'


def imm(s):
    return int(s, 16) if s.lstrip('-').startswith('0x') else int(s)


def parse(path):
    funcs = {}    # name -> dict(addr, frame, calls:set(addr), tails:set(addr), indirect:bool)
    by_addr = {}  # start address -> name (first label printed at that address)
    cur = None
    regs = {}
    acc = 0
    done = True
    for line in open(path, errors='replace'):
        m = re.match(r'^([0-9a-f]+) <(.*)>:$', line)
        if m:
            a = int(m.group(1), 16)
            name = m.group(2)
            if name.startswith(KENTRY): name = name[len(KENTRY):]
            cur = {'addr': a, 'frame': 0, 'calls': set(), 'tails': set(), 'indirect': False, 'name': name}
            funcs.setdefault(name, cur)
            cur = funcs[name]
            by_addr.setdefault(a, name)
            regs = {}; acc = 0; done = False
            continue
        if cur is None: continue
        f = line.rstrip('\n').split('\t')
        if len(f) < 2: continue
        mn = f[1].strip() if len(f) >= 2 else ''
        ops = f[2].strip() if len(f) >= 3 else ''
        if not re.match(r'^\s*[0-9a-f]+:', f[0]): continue
        # frame (prologue decrements up to the first increment)
        if not done:
            m = re.fullmatch(r'sp, sp, (-?(?:0x)?[0-9a-f]+)', ops) if mn in ('addi', 'c.addi', 'c.addi16sp') else None
            if m:
                v = imm(m.group(1))
                if v < 0: acc += -v; cur['frame'] = max(cur['frame'], acc)
                else: done = True
            elif mn == 'lui' and re.fullmatch(r'(\w+), (0x[0-9a-f]+|\d+)', ops):
                r, v = ops.split(', '); regs[r] = imm(v) << 12
            elif mn in ('addi', 'addiw') and re.fullmatch(r'(\w+), (\w+), (-?(?:0x)?[0-9a-f]+)', ops):
                d, s, v = ops.split(', ')
                if d == s and d in regs: regs[d] += imm(v)
            elif mn == 'li' and re.fullmatch(r'(\w+), (-?(?:0x)?[0-9a-f]+)', ops):
                r, v = ops.split(', '); regs[r] = imm(v)
            elif mn == 'sub' and ops.startswith('sp, sp, '):
                r = ops.split(', ')[2]
                if r in regs: acc += regs[r]; cur['frame'] = max(cur['frame'], acc)
            elif mn == 'add' and ops.startswith('sp, sp, '):
                done = True
        # calls
        m = re.match(r'^(?:(\w+), )?0x([0-9a-f]+) <([^>]*)>$', ops)
        if mn == 'jal' and m and m.group(1) in (None, 'ra'):
            cur['calls'].add(int(m.group(2), 16))
        elif mn in ('j', 'jal') and m and m.group(1) in (None, 'zero') and '+' not in m.group(3):
            cur['tails'].add(int(m.group(2), 16))
        elif mn == 'jalr' and not ops.startswith('zero'):
            cur['indirect'] = True
    return funcs, by_addr


def stack_atomics(ll_path):
    """IR functions of kernel.ll with an atomicrmw / cmpxchg / atomic load-store whose pointer comes (through GEPs,
    casts, selects, phis) from an alloca of the same function."""
    out = set()
    try:
        txt = open(ll_path, errors='replace').read()
    except OSError:
        return out
    for fm in re.finditer(r'^define [^@]*@("?[^"(]+"?)\((.*?)^}', txt, re.S | re.M):
        name = fm.group(1).strip('"'); body = fm.group(2)
        defs = {}
        for m in re.finditer(r'^\s*(%[\w.$-]+) = (.*)$', body, re.M):
            defs[m.group(1)] = m.group(2)
        def from_alloca(v, depth=0):
            if depth > 32 or v not in defs: return False
            d = defs[v]
            if d.startswith('alloca '): return True
            if re.match(r'(getelementptr|bitcast|addrspacecast|select|phi|freeze)\b', d):
                return any(from_alloca(x, depth + 1) for x in re.findall(r'%[\w.$-]+', d))
            return False
        for m in re.finditer(r'(?:atomicrmw (?:volatile )?\w+ ptr(?: addrspace\(\d+\))? (%[\w.$-]+)|cmpxchg (?:weak )?(?:volatile )?ptr(?: addrspace\(\d+\))? (%[\w.$-]+)|(?:load|store) atomic [^,]*,? ?ptr(?: addrspace\(\d+\))? (%[\w.$-]+))', body):
            v = next(x for x in m.groups() if x)
            if from_alloca(v): out.add(name); break
    return out


def callbacks(path):
    src = open(path, errors='replace').read()
    m = re.search(r'vx_kernel_func_cb callbacks\[\] = \{(.*?)\};', src, re.S)
    if not m: return []
    out = []
    for item in m.group(1).split(','):
        item = item.strip()
        if not item: continue
        item = re.sub(r'^\(vx_kernel_func_cb\)\s*', '', item)
        out.append(item)
    return out


def main():
    funcs, by_addr = parse(sys.argv[1])
    amo = stack_atomics(os.path.join(os.path.dirname(os.path.abspath(sys.argv[1])), 'kernel.ll'))
    memo = {}

    def chain(name, stack):
        if name in memo: return memo[name]
        if name in stack: return (0, 'recursion')
        f = funcs[name]
        stack.add(name)
        best, flag = 0, ('indirect' if f['indirect'] else 'stackamo' if name in amo else 'ok')
        for a in sorted(f['calls'] | f['tails']):
            t = by_addr.get(a)
            if t is None or t == name: continue   # a branch to its own entry, or into the middle of a function
            c, fl = chain(t, stack)
            best = max(best, c)
            if fl != 'ok' and flag == 'ok': flag = fl
        stack.discard(name)
        memo[name] = (f['frame'] + best, flag)
        return memo[name]

    for i, cb in enumerate(callbacks(sys.argv[2])):
        name = cb[len(KENTRY):] if cb.startswith(KENTRY) else cb
        if name not in funcs:
            print(f'kernel {i} 0 noentry {cb}')
            continue
        c, fl = chain(name, set())
        print(f'kernel {i} {c} {fl} {cb}')


if __name__ == '__main__':
    main()
