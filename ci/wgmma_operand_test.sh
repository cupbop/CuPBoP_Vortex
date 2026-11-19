#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
translator=$(realpath "${1:-${KERNEL_TRANSLATOR:-$repo/build/compilation/kernelTranslator}}")
llvm_bin=${2:-${LLVM_BIN:-}}
if [[ -n $llvm_bin ]]; then
  llvm_bin=$(realpath "$llvm_bin")
  export PATH="$llvm_bin:$PATH"
  export LD_LIBRARY_PATH="$llvm_bin/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
export VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 CUPBOP_MMA_LOWERING=tcu

cat > reset.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"

define ptx_kernel void @probe(i64 %a, i64 %b, ptr %out) {
entry:
  call void asm sideeffect "wgmma.fence.sync.aligned;", "~{memory}"()
  %tile = call {float,float,float,float,float,float,float,float} asm sideeffect "wgmma.mma_async.sync.aligned.m64n16k16.f32.f16.f16 {$0,$1,$2,$3,$4,$5,$6,$7}, $8, $9, 0, 1, 1, 0, 0;", "=f,=f,=f,=f,=f,=f,=f,=f,l,l,~{memory}"(i64 %a, i64 %b)
  call void asm sideeffect "wgmma.commit_group.sync.aligned; wgmma.wait_group.sync.aligned 0;", "~{memory}"()
  call void asm sideeffect "wgmma.wait_group.sync.aligned $0;", "n,~{memory}"(i32 3)
  %value = extractvalue {float,float,float,float,float,float,float,float} %tile, 0
  store float %value, ptr %out
  ret void
}
IR

llvm-as reset.ll -o reset.bc
"$translator" reset.bc kernel.bc > reset.log 2>&1 || { cat reset.log; exit 1; }
opt -passes=verify -disable-output kernel.bc
llvm-dis kernel.bc -o kernel.ll
rg -q 'call void @__cupbop_wgmma_m64nNk16_f16f32(_native)?\(i32 16, i64 [^,]+, i64 [^,]+, i32 0,' kernel.ll
if rg -q 'call void @__cupbop_wgmma_m64nNk16_f16f32_native' kernel.ll; then
  rg -q '\.insn r 0x0b, 4, 2, x0, x0, x0' kernel.ll
  rg -q '\.insn r 0x0b, 4, 2, x0, x1, x0' kernel.ll
  rg -q '\.insn r 0x0b, 4, 2, x0, x2, x0' kernel.ll
  rg -q '\.insn r 0x0b, 4, 2, x0, x2, x3' kernel.ll
  rg -q 'call void @__cupbop_wgmma_group_init' kernel.ll
  rg -q 'call void @__cupbop_wgmma_group_sync' kernel.ll
fi

sed 's/\$9, 0, 1, 1, 0, 0/\$9, 1, 1, 1, 0, 0/' reset.ll > missing-acc.ll
llvm-as missing-acc.ll -o missing-acc.bc
if "$translator" missing-acc.bc kernel.bc > missing-acc.log 2>&1; then
  echo 'WGMMA accepted scale-D=1 without an incoming accumulator' >&2
  exit 1
fi
rg -q 'error: unsupported wgmma form' missing-acc.log
echo 'WGMMA unbound accumulator tests passed'
