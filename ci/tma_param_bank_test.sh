#!/usr/bin/env bash
# Check the CUDA host ABI of two tensor maps sharing one lifted cvta.param root.
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

!nvvm.annotations = !{!0}
!nvvmir.version = !{!1}
!0 = !{ptr @maps, !"kernel", i32 1}
!1 = !{i32 2, i32 0}
IR

llvm-as maps.ll -o maps.bc
if ! env -u CUPBOP_NARROW_VECTOR_ARGS VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 \
  VORTEX_NUM_THREADS=32 "$translator" maps.bc kernel.bc > translation.log 2>&1; then
  cat translation.log
  exit 1
fi
opt -passes=verify -disable-output kernel.bc
grep -F 'parameter 0 (128 bytes) narrowed to its first 8 bytes' translation.log
grep -F 'parameter 1 (128 bytes) narrowed to its first 8 bytes' translation.log
