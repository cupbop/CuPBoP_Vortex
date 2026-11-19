#!/usr/bin/env bash
# Check standalone tensor maps and a packed CUDA parameter addressed by cvta.param.
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

cat > maps.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"

@shared_mem = external addrspace(3) global [128 x i8], align 128

define void @maps([2 x <8 x i64>] %arg_576, [2 x <8 x i64>] %arg_704) {
EntryBB_maps:
  %param_local = alloca i8
  %base = call i64 asm "{ .reg .b64 t; mov.b64 t, maps_param_0; cvta.param.u64 $0, t; }", "=l"()
  %next = add i64 %base, 128
  %src = ptrtoint ptr addrspace(3) @shared_mem to i64
  call void asm sideeffect "cp.async.bulk.tensor.1d.global.shared::cta.bulk_group [$0, {0}], [$1];", "l,l,~{memory}"(i64 %base, i64 %src)
  call void asm sideeffect "cp.async.bulk.tensor.1d.global.shared::cta.bulk_group [$0, {0}], [$1];", "l,l,~{memory}"(i64 %next, i64 %src)
  ret void
}

define void @packed([12 x <8 x i64>] %arg_576, ptr %arg_1344) {
EntryBB_packed:
  %base = call i64 asm "{ .reg .b64 t; mov.b64 t, packed_param_0; cvta.param.u64 $0, t; }", "=l"()
  %map = add i64 %base, 128
  %guard_address = add i64 %base, 680
  %guard_ptr = inttoptr i64 %guard_address to ptr
  %guard = load i64, ptr %guard_ptr
  %enabled = icmp ne i64 %guard, 0
  br i1 %enabled, label %copy, label %exit
copy:
  %src = ptrtoint ptr addrspace(3) @shared_mem to i64
  call void asm sideeffect "cp.async.bulk.tensor.1d.global.shared::cta.bulk_group [$0, {0}], [$1];", "l,l,~{memory}"(i64 %map, i64 %src)
  store i64 %guard, ptr %arg_1344
  br label %exit
exit:
  ret void
}

!nvvm.annotations = !{!0, !1}
!nvvmir.version = !{!2}
!0 = !{ptr @maps, !"kernel", i32 1}
!1 = !{ptr @packed, !"kernel", i32 1}
!2 = !{i32 2, i32 0}
IR

llvm-as maps.ll -o maps.bc
if ! env -u CUPBOP_NARROW_VECTOR_ARGS VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 \
  VORTEX_NUM_THREADS=32 "$translator" maps.bc kernel.bc > translation.log 2>&1; then
  cat translation.log
  exit 1
fi
opt -passes=verify -disable-output kernel.bc
llvm-dis kernel.bc -o kernel.ll
grep -F 'parameter 0 (128 bytes) narrowed to its first 8 bytes' translation.log
grep -F 'parameter 1 (128 bytes) narrowed to its first 8 bytes' translation.log
grep -E 'define void @packed\(ptr [^,]*"cupbop-arg-slots"="96"' kernel.ll
sed -n '/^define .*@packed(/,/^}/p' kernel.ll | grep -F 'call void @__cupbop_tma_store('
