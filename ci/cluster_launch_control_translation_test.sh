#!/usr/bin/env bash
# Check Blackwell cluster launch control through the normal device translator.
set -euo pipefail
translator=$(realpath "$1")
llvm_bin=$(realpath "$2")
export LD_LIBRARY_PATH="$llvm_bin/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CUPBOP_LIFT_OPT=0 VORTEX_ARCHITECTURE=64 VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 VORTEX_NUM_THREADS=32
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

python3 - <<'PY'
from pathlib import Path

lines = ['target triple = "nvptx64-nvidia-cuda"',
         'define ptx_kernel void @probe(i32 %response, i32 %barrier, ptr addrspace(1) %out) {']
for space in ('', '.shared::cta'):
    for multicast in ('', '.multicast::cluster::all'):
        op = 'clusterlaunchcontrol.try_cancel.async' + space + '.mbarrier::complete_tx::bytes' + multicast
        lines.append(f'  call void asm sideeffect "{op}.b128 [$0], [$1];", "r,r,~{{memory}}"(i32 %response, i32 %barrier)')

# CCCL passes the 16-byte response as two b64 input registers. Give each
# coordinate and the reserved bits distinct values so incorrect shifts show up.
x, y, z = 91, 0x4321, 0xabcf
low = x | (y << 32) | (z << 48)
high = 0xa5a5a5a500000003
pack = '.reg .b128 resp; mov.b128 resp, {$1, $2}; '
query = 'clusterlaunchcontrol.query_cancel.'
for tag, bits in [('succeeded', high), ('declined', high - 1)]:
    asm = '{ .reg .pred p; ' + pack + query + 'is_canceled.pred.b128 p, resp; selp.b32 $0, 1, 0, p; }'
    lines.append(f'  %{tag} = call i32 asm "{asm}", "=r,l,l"(i64 {low}, i64 {bits})')
    lines.append(f'  store volatile i32 %{tag}, ptr addrspace(1) %out')
for axis in 'xyz':
    asm = '{ ' + pack + query + 'get_first_ctaid::' + axis + '.b32.b128 $0, resp; }'
    lines.append(f'  %{axis} = call i32 asm "{asm}", "=r,l,l"(i64 {low}, i64 {high})')
    lines.append(f'  store volatile i32 %{axis}, ptr addrspace(1) %out')

pack4 = '.reg .b128 resp; mov.b128 resp, {$4, $5, $6, $7}; '
vector = '{ ' + pack4 + query + 'get_first_ctaid.v4.b32.b128 {$0, $1, $2, $3}, resp; }'
lines.append(f'  %v = call {{i32,i32,i32,i32}} asm "{vector}", "=r,=r,=r,=r,r,r,r,r"(i32 {x}, i32 {y | z << 16}, i32 1, i32 0)')
for i in range(3):
    lines.append(f'  %v{i} = extractvalue {{i32,i32,i32,i32}} %v, {i}')
    lines.append(f'  store volatile i32 %v{i}, ptr addrspace(1) %out')
lines += ['  ret void', '}', '!nvvm.annotations = !{!0}', '!0 = !{ptr @probe, !"kernel", i32 1}']
Path('input.ll').write_text('\n'.join(lines) + '\n')
PY

"$llvm_bin/llvm-as" input.ll -o input.bc
"$translator" input.bc output.bc >translation.log 2>&1 || { cat translation.log; exit 1; }
"$llvm_bin/opt" -passes='verify,instcombine' -S output.bc -o output.ll
python3 - <<'PY'
from pathlib import Path
import re

ir = Path('output.ll').read_text()
flags = re.findall(r'call void @__cupbop_cluster_try_cancel\([^\n]*?, i32 ([01])\)', ir)
values = re.findall(r'store volatile i32 (\d+),', ir)
assert flags == ['0', '1', '0', '1'], flags
assert list(map(int, values)) == [1, 0, 91, 0x4321, 0xabcf, 91, 0x4321, 0xabcf], values
assert 'clusterlaunchcontrol.' not in ir
PY

# A CLC request targets a physical KMU grid. Even a kernel with no other
# cluster helpers or mbarriers must retain one hardware CTA per logical block.
cat > physical.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"
define ptx_kernel void @physical(ptr addrspace(3) %r, ptr addrspace(3) %b) {
  call void asm sideeffect "clusterlaunchcontrol.try_cancel.async.mbarrier::complete_tx::bytes.b128 [$0], [$1];", "l,l,~{memory}"(ptr addrspace(3) %r, ptr addrspace(3) %b)
  ret void
}
!nvvm.annotations = !{!0}
!0 = !{ptr @physical, !"kernel", i32 1}
IR
"$llvm_bin/llvm-as" physical.ll -o physical.bc
env -u CUPBOP_SREG_TLS CUPBOP_CTA_LOOP=x CUPBOP_FAST_ENTRY=1 \
  "$translator" physical.bc output.bc >translation.log 2>&1
grep -Fq 'physical: refused: cluster (__cupbop_cluster_try_cancel)' translation.log

# A shared::cluster address, or a partial multicast mask, is not a legal CLC form.
for replacement in 'shared::cluster.mbarrier' 'multicast::cluster::mask.b128'; do
  if [[ $replacement == shared* ]]; then pattern='shared::cta.mbarrier'; else pattern='multicast::cluster::all.b128'; fi
  sed "s/$pattern/$replacement/g" input.ll > invalid.ll
  "$llvm_bin/llvm-as" invalid.ll -o invalid.bc
  if "$translator" invalid.bc output.bc >translation.log 2>&1; then exit 1; fi
  grep -q 'unsupported cluster launch control operation' translation.log
done
echo "Cluster launch control translation passed."
