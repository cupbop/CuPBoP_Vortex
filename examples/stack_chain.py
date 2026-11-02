#!/usr/bin/env python3
"""stack_chain.py <kernel.dump> <kernel_wrapper.cpp>: static stack bytes of the deepest call chain below each kernel
entry of callbacks[] (kernel_wrapper.cpp), for the stack in local memory (CUPBOP_STACK_IN_LMEM, generate_wrapper.cpp
stack_lmem_prelude; read by the host runtime, cudaRuntimeImpl.cpp cupbop_stack_lmem). Written by
examples/stack_fallback.sh into cupbop_lmem_stack.txt:
    kernel <callbacks index> <chain bytes> <flags> <entry symbol>
flags: ok | indirect (an indirect call jalr is reachable: the chain is not bounded) | recursion | noentry (the entry
is not in the dump; or an indirect jump jr) | stackamo (a reachable function does an atomic on an address derived from one of its allocas, per
kernel.ll next to the dump: an LMEM atomic works in SimX but not in the RTL, VX_lmem_switch asserts) | lmemuse (a
reachable function calls __vx_local_mem / __vx_local_mem_offset, whose local memory is not in the host's shared size). Frame of a function = the largest sum of its sp decrements before the first increment
(addi sp,sp,-N; sub sp,sp,reg with reg from lui/addiw/li), as examples/stack_frames.py, but for every function
(runtime helpers, libm, memcpy, ... included). A variable sub sp,sp,reg (run-time sized alloca) is not counted here:
those bytes come from cupbop_dyn_stack.txt (generate_wrapper.cpp describe_dyn_stack). Edges (parse): jal / j / any
branch into another function (call, tail call or jump: counted like a call, conservative) and the fall-through into the
next symbol (an assembly label that continues a function is merged into it: vx_serial's label_loop holds its jalr, which
the first version of this script missed, so sfilter's printf chain was counted 280 instead of 600+ bytes).
The chain of a function = its frame + the largest chain among its callees. kernel_main itself is not counted: it
stays on the hardware stack (the kernel is called on the new stack)."""
import os, re, sys

KENTRY = '__vx_kentry_'


def imm(s):
    return int(s, 16) if s.lstrip('-').startswith('0x') else int(s)


TERM = ('ret', 'j', 'jr', 'tail', 'mret', 'c.j', 'c.jr')   # no fall-through into the next symbol after these


def parse(path, entries=()):
    """Functions of the .text/.init sections. A symbol that the previous one falls through into (its last instruction is
    not an unconditional transfer: assembly labels such as vx_serial's label_loop / label_join) is merged into it. Edges:
    every jal / j / branch whose target lies in another function (call, tail call, or a jump into it: counted like a
    call, conservative), and the fall-through. jalr with a link register and jr other than ret: indirect."""
    syms = []   # [start, name, [(mnemonic, operands)]]
    code = False
    for line in open(path, errors='replace'):
        if line.startswith('Disassembly of section'):
            code = line.split()[3].rstrip(':') in ('.text', '.init')
            continue
        if not code: continue
        m = re.match(r'^([0-9a-f]+) <(.*)>:$', line)
        if m:
            name = m.group(2)
            if name.startswith(KENTRY): name = name[len(KENTRY):]
            syms.append([int(m.group(1), 16), name, []])
            continue
        if not syms: continue
        f = line.rstrip('\n').split('\t')
        if len(f) < 2 or not re.match(r'^\s*[0-9a-f]+:', f[0]): continue
        syms[-1][2].append((f[1].strip(), f[2].strip() if len(f) >= 3 else ''))
    # merge fall-through continuations, never into a symbol that is called (jal with a link) or a kernel entry
    called = set()
    for _, _, ins in syms:
        for mn, ops in ins:
            m = re.match(r'^(?:ra, )?0x([0-9a-f]+) <', ops)
            if mn == 'jal' and m: called.add(int(m.group(1), 16))
    def ends(ins):
        mn, ops = ins[-1]
        return mn in TERM or (mn == 'jal' and ops.startswith('zero')) or (mn == 'vx_tmc' and ops == 'zero')
    merged = []
    for a, name, ins in syms:
        if merged and merged[-1][2] and not ends(merged[-1][2]) and a not in called and name not in entries:
            merged[-1][2].extend(ins); merged[-1][3].append(name)
        else:
            merged.append([a, name, list(ins), [name]])
    starts = [x[0] for x in merged]
    import bisect
    def owner(addr):
        i = bisect.bisect_right(starts, addr) - 1
        return merged[i][1] if i >= 0 else None
    funcs, by_addr = {}, {}
    for a, name, ins, names in merged:
        cur = {'addr': a, 'frame': 0, 'edges': set(), 'indirect': False, 'name': name, 'aliases': names}
        regs, acc, done = {}, 0, False
        for mn, ops in ins:
            if not done:
                m = re.fullmatch(r'sp, sp, (-?(?:0x)?[0-9a-f]+)', ops) if mn in ('addi', 'c.addi', 'c.addi16sp') else None
                if m:
                    v = imm(m.group(1))
                    if v < 0: acc += -v; cur['frame'] = max(cur['frame'], acc)
                    else: done = True
                elif mn == 'lui' and re.fullmatch(r'(\w+), (0x[0-9a-f]+|\d+)', ops):
                    r, v = ops.split(', '); regs[r] = imm(v) << 12
                elif mn in ('addi', 'addiw') and re.fullmatch(r'(\w+), (\w+), (-?(?:0x)?[0-9a-f]+)', ops):
                    d, s_, v = ops.split(', ')
                    if d == s_ and d in regs: regs[d] += imm(v)
                elif mn == 'li' and re.fullmatch(r'(\w+), (-?(?:0x)?[0-9a-f]+)', ops):
                    r, v = ops.split(', '); regs[r] = imm(v)
                elif mn == 'sub' and ops.startswith('sp, sp, '):
                    r = ops.split(', ')[2]
                    if r in regs: acc += regs[r]; cur['frame'] = max(cur['frame'], acc)
                elif mn == 'add' and ops.startswith('sp, sp, '):
                    done = True
            m = re.search(r'0x([0-9a-f]+) <[^>]*>$', ops)
            if m and (mn in ('jal', 'j', 'tail', 'call') or mn.startswith(('b', 'c.b', 'c.j'))):
                t = owner(int(m.group(1), 16))
                if t is not None and t != name: cur['edges'].add(t)
            elif mn in ('jalr', 'c.jalr') and not ops.startswith('zero'):
                cur['indirect'] = True
            elif mn in ('jr', 'c.jr'):
                cur['indirect'] = True
        if ins and not ends(ins):
            i = starts.index(a)
            if i + 1 < len(merged): cur['edges'].add(merged[i + 1][1])
        funcs[name] = cur
        for n in names: by_addr.setdefault(n, name)
    return funcs, by_addr


def stack_atomics(ll_path):
    """IR functions of kernel.ll -> flag: stackamo (an atomicrmw / cmpxchg / atomic load-store whose pointer comes,
    through GEPs, casts, selects, phis, from an alloca of the same function) or lmemuse (a call of __vx_local_mem /
    __vx_local_mem_offset: local memory outside the shared size the host knows)."""
    out = {}
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
            if from_alloca(v): out[name] = 'stackamo'; break
        # local memory the host does not know about: __vx_local_mem / __vx_local_mem_offset return the CTA's LMEM
        # window but their size is not in kernel_lmem.log (sgemm_dxa: its 16 KB tiles overlapped the stacks)
        if name not in out and re.search(r'call [^@]*@_Z(?:14__vx_local_memv|21__vx_local_mem_offsetj)\b', body):
            out[name] = 'lmemuse'
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
    cbs = callbacks(sys.argv[2])
    funcs, by_addr = parse(sys.argv[1], {c[len(KENTRY):] if c.startswith(KENTRY) else c for c in cbs})
    amo = stack_atomics(os.path.join(os.path.dirname(os.path.abspath(sys.argv[1])), 'kernel.ll'))
    memo = {}

    def chain(name, stack):
        if name in memo: return memo[name]
        if name in stack: return (0, 'recursion')
        f = funcs[name]
        stack.add(name)
        irf = [amo[n] for n in f['aliases'] if n in amo]
        best, flag = 0, ('indirect' if f['indirect'] else irf[0] if irf else 'ok')
        for t in sorted(f['edges']):
            c, fl = chain(t, stack)
            best = max(best, c)
            if fl != 'ok' and flag == 'ok': flag = fl
        stack.discard(name)
        memo[name] = (f['frame'] + best, flag)
        return memo[name]

    for i, cb in enumerate(cbs):
        name = cb[len(KENTRY):] if cb.startswith(KENTRY) else cb
        name = by_addr.get(name, name)
        if name not in funcs:
            print(f'kernel {i} 0 noentry {cb}')
            continue
        c, fl = chain(name, set())
        print(f'kernel {i} {c} {fl} {cb}')


if __name__ == '__main__':
    main()
