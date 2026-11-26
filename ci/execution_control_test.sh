#!/usr/bin/env bash
# Check CUDA PTX and named NVVM against the resulting LLVM and RISC-V fences.
set -euo pipefail
translator=$(realpath "$1")
llvm=$(realpath "$2")
export LD_LIBRARY_PATH="$llvm/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-exec-control.XXXXXXXX")
trap 'rm -rf "$work"' EXIT
cd "$work"
export VORTEX_SCHEDULE_FLAG=2 VORTEX_ARCHITECTURE=64 VORTEX_NUM_THREADS=32 VORTEX_LOCALMEM_FLAG=1
export CUPBOP_LIFT_OPT=0

cat > input.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"
declare void @llvm.nvvm.griddepcontrol.launch.dependents()
declare void @llvm.nvvm.griddepcontrol.wait()
declare void @llvm.nvvm.fence.proxy.async.shared.cta()
declare void @llvm.nvvm.setmaxnreg.dec.sync.aligned.u32(i32 immarg)
define ptx_kernel void @proxy() {
  call void asm sideeffect "fence.proxy.async::generic.acquire.sync_restrict::shared::cluster.cluster;", "~{memory}"()
  call void asm sideeffect "fence.proxy.async::generic.release.sync_restrict::shared::cta.cluster;", "~{memory}"()
  call void asm sideeffect "membar.proxy.alias;", "~{memory}"()
  ret void
}
define ptx_kernel void @initialization() {
  call void asm sideeffect "fence.mbarrier_init.release.cluster;", "~{memory}"()
  ret void
}
define ptx_kernel void @named_proxy() {
  call void @llvm.nvvm.fence.proxy.async.shared.cta()
  ret void
}
define ptx_kernel void @trigger() {
  call void asm sideeffect "griddepcontrol.launch_dependents;", "~{memory}"()
  ret void
}
define ptx_kernel void @wait() {
  call void @llvm.nvvm.griddepcontrol.wait()
  ret void
}
define ptx_kernel void @named_trigger() {
  call void @llvm.nvvm.griddepcontrol.launch.dependents()
  ret void
}
define ptx_kernel void @hints(ptr %addr) {
  call void asm sideeffect "setmaxnreg.inc.sync.aligned.u32 48;", "~{memory}"()
  call void @llvm.nvvm.setmaxnreg.dec.sync.aligned.u32(i32 48)
  call void asm sideeffect "prefetch.global.L2 [$0+64];", "l,~{memory}"(ptr %addr)
  call void asm sideeffect "prefetch.tensormap [$0];", "l,~{memory}"(ptr %addr)
  call void asm sideeffect "cp.async.bulk.prefetch.L2.global [$0], 256;", "l,~{memory}"(ptr %addr)
  ret void
}
IR
"$llvm/llvm-as" input.ll -o input.bc
"$translator" input.bc kernel.bc > translator.log 2>&1 || { cat translator.log; exit 1; }
"$llvm/opt" -passes=verify -disable-output kernel.bc
"$llvm/llvm-dis" kernel.bc -o out.ll
"$llvm/llc" -mtriple=riscv64 -mattr=+m,+a,+f,+d out.ll -o output.s
python3 - <<'PY'
from pathlib import Path
import re
ir, assembly = Path('out.ll').read_text(), Path('output.s').read_text()
for name, orders in {'proxy': ['acquire','release','seq_cst'], 'initialization': ['release'], 'named_proxy': ['seq_cst'],
                     'trigger': ['release'], 'wait': ['acquire'], 'named_trigger': ['release']}.items():
    body = re.search(r'define [^@\n]+@' + name + r'\(.*?\n}', ir, re.S)[0]
    assert re.findall(r'^\s*fence (acquire|release|seq_cst)', body, re.M) == orders, (name, body)
    native = re.search(r'^' + name + r':.*?^\.Lfunc_end', assembly, re.S | re.M)[0]
    assert re.search(r'^\s*fence\b', native, re.M), name
hints = re.search(r'define [^@\n]+@hints\(.*?\n}', ir, re.S)[0]
assert hints.count('call void @llvm.prefetch.') == 3
assert re.search(r'getelementptr i8, ptr [^,]+, i64 64', ir)
assert 'call void @llvm.nvvm.' not in ir
PY
for invalid in 'setmaxnreg.inc.sync.aligned.u32 17' 'fence.proxy.unknown' 'griddepcontrol.unknown'; do
  sed "s/griddepcontrol.launch_dependents;/$invalid;/" input.ll > invalid.ll
  "$llvm/llvm-as" invalid.ll -o invalid.bc
  if "$translator" invalid.bc unused.bc > invalid.log 2>&1; then echo "unexpected success: $invalid"; exit 1; fi
  grep -Eq 'setmaxnreg requires|unsupported proxy|unsupported grid dependency' invalid.log
done
