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

define void @grid_bytes128(ptr byval([128 x i8]) align 64 "nvvm.grid_constant" %record, ptr %out) {
  %field = getelementptr inbounds i8, ptr %record, i64 120
  %value = load i64, ptr %field, align 8
  store i64 %value, ptr %out, align 8
  ret void
}

define void @triton_map(ptr byval([128 x i8]) align 64 "nvvm.grid_constant" %record, ptr %out) {
  %src = ptrtoint ptr addrspace(3) @shared_mem to i64
  %map = getelementptr inbounds i8, ptr %record, i64 0
  %map_addr = ptrtoint ptr %map to i64
  call void asm sideeffect "cp.async.bulk.tensor.1d.global.shared::cta.bulk_group [$0, {0}], [$1];", "l,l,~{memory}"(i64 %map_addr, i64 %src)
  store i64 1, ptr %out, align 8
  ret void
}

define void @publish_map(ptr %dst) {
  %src = ptrtoint ptr addrspace(3) @shared_mem to i32
  %addr = ptrtoint ptr %dst to i64
  call void asm sideeffect "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r,~{memory}"(i64 %addr, i32 %src)
  call void asm sideeffect "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l,~{memory}"(i64 %addr)
  ret void
}

declare void @llvm.nvvm.fence.proxy.tensormap_generic.release.gpu()
declare void @llvm.nvvm.fence.proxy.tensormap_generic.acquire.gpu(ptr, i32 immarg)

define void @nvvm_map_fences(ptr %map, ptr %signal) {
  call void @llvm.nvvm.fence.proxy.tensormap_generic.release.gpu()
  store volatile i32 1, ptr %signal, align 4
  call void @llvm.nvvm.fence.proxy.tensormap_generic.acquire.gpu(ptr %map, i32 128)
  ret void
}

!nvvm.annotations = !{!0, !1, !3, !4, !5, !6}
!nvvmir.version = !{!2}
!0 = !{ptr @maps, !"kernel", i32 1}
!1 = !{ptr @packed, !"kernel", i32 1}
!2 = !{i32 2, i32 0}
!3 = !{ptr @grid_bytes128, !"kernel", i32 1}
!4 = !{ptr @triton_map, !"kernel", i32 1}
!5 = !{ptr @publish_map, !"kernel", i32 1}
!6 = !{ptr @nvvm_map_fences, !"kernel", i32 1}
IR

llvm-as maps.ll -o maps.bc
if ! env -u CUPBOP_NARROW_VECTOR_ARGS VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 \
  VORTEX_NUM_THREADS=32 "$translator" maps.bc kernel.bc > translation.log 2>&1; then
  cat translation.log
  exit 1
fi
opt -passes=verify -disable-output kernel.bc
llvm-dis kernel.bc -o kernel.ll
sed -n '/^define .*@nvvm_map_fences(/,/^}/p' kernel.ll > nvvm_fences.ll
grep -F 'fence release' nvvm_fences.ll
grep -F 'fence acquire' nvvm_fences.ll
grep -F 'parameter 0 (128 bytes) narrowed to its first 8 bytes' translation.log
grep -F 'parameter 1 (128 bytes) narrowed to its first 8 bytes' translation.log
grep -E 'define void @packed\(ptr [^,]*"cupbop-arg-slots"="96"' kernel.ll
grep -Fx 'packed 2 768 0 lifted-slots' cupbop_byval_args.txt
grep -Fx 'grid_bytes128 2 128 0' cupbop_byval_args.txt
if grep -q '^triton_map ' cupbop_byval_args.txt; then
  echo 'The Triton tensor map lost its one-slot launch ABI.' >&2
  exit 1
fi
sed -n '/^define .*@packed(/,/^}/p' kernel.ll | grep -F 'call void @__cupbop_tma_store('
sed -n '/^define .*@triton_map(/,/^}/p' kernel.ll | grep -F 'call void @__cupbop_tma_store('
sed -n '/^define .*@publish_map(/,/^}/p' kernel.ll | grep -F 'call void @__cupbop_tensormap_publish('
sed -n '/^define .*@publish_map(/,/^}/p' kernel.ll | grep -F 'fence acquire'

sed 's/\[\$1\], 128;/[$1], 64;/' maps.ll > bad_size.ll
llvm-as bad_size.ll -o bad_size.bc
if VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 VORTEX_NUM_THREADS=32 \
    "$translator" bad_size.bc rejected.bc > bad_size.log 2>&1; then
  echo 'Tensor map publication accepted an invalid size.' >&2
  exit 1
fi
grep -F 'tensor-map proxy operation requires immediate size 128' bad_size.log

sed 's/acquire.gpu(ptr %map, i32 128)/acquire.gpu(ptr %map, i32 64)/' maps.ll > bad_nvvm_size.ll
if llvm-as bad_nvvm_size.ll -o bad_nvvm_size.bc > bad_nvvm_size.log 2>&1; then
  if VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 VORTEX_NUM_THREADS=32 \
      "$translator" bad_nvvm_size.bc rejected.bc > bad_nvvm_size.log 2>&1; then
    echo 'NVVM tensor map acquire accepted an invalid size.' >&2
    exit 1
  fi
fi
grep -E 'only supported value for size operand is 128|tensor-map proxy operation requires immediate size 128' bad_nvvm_size.log
