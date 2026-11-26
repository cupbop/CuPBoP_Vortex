#!/usr/bin/env bash
# Exercise the default and opt-in copy ring handling through kernelTranslator.
# Usage: ci/p2c_fold_guard_test.sh [kernelTranslator] [LLVM bin directory]
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
translator=${1:-${KERNEL_TRANSLATOR:-$repo/build/compilation/kernelTranslator}}
llvm_bin=${2:-${LLVM_BIN:-}}
translator=$(realpath "$translator")
if [[ -n $llvm_bin ]]; then
  llvm_bin=$(realpath "$llvm_bin")
  export LD_LIBRARY_PATH="$llvm_bin/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat > "$work/ring.ll" <<'IR'
target triple = "nvptx64-nvidia-cuda"

@shared_mem = external addrspace(3) global [1536 x i8], align 16

define void @ring(i64 %src, ptr addrspace(1) %source_ptr, i32 %guard_iters) {
EntryBB_ring:
  %param_local = alloca [8 x i8]
  %tid = call i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %thread_offset = shl i32 %tid, 4
  %stage0 = getelementptr [1536 x i8], ptr addrspace(3) @shared_mem, i32 0, i32 %thread_offset
  %dst0 = ptrtoint ptr addrspace(3) %stage0 to i64
  call void asm sideeffect "cp.async.cg.shared.global [$0], [$1], 16, $2;", "l,l,r,~{memory}"(i64 %dst0, i64 %src, i32 16)
  %tile1 = add i32 %thread_offset, 512
  %stage1 = getelementptr [1536 x i8], ptr addrspace(3) @shared_mem, i32 0, i32 %tile1
  %dst1 = ptrtoint ptr addrspace(3) %stage1 to i64
  call void asm sideeffect "cp.async.cg.shared.global [$0], [$1], 16, $2;", "l,l,r,~{memory}"(i64 %dst1, i64 %src, i32 16)
  br label %loop

loop:
  %rd = phi i32 [ 0, %EntryBB_ring ], [ %rd_next, %latch ]
  %wr = phi i32 [ 1024, %EntryBB_ring ], [ %wr_next, %latch ]
  %iter = phi i32 [ 0, %EntryBB_ring ], [ %iter_next, %latch ]
  %read_offset = add i32 %rd, %thread_offset
  %shared = getelementptr [1536 x i8], ptr addrspace(3) @shared_mem, i32 0, i32 %read_offset
  %value = load volatile i32, ptr addrspace(3) %shared
  %enabled = icmp ult i32 %iter, %guard_iters
  br i1 %enabled, label %copy, label %latch

copy:
  %write_offset = add i32 %wr, %thread_offset
  %target = getelementptr [1536 x i8], ptr addrspace(3) @shared_mem, i32 0, i32 %write_offset
  %dst = ptrtoint ptr addrspace(3) %target to i64
  %copy_src = add i64 %src, 64
  %copy_size = select i1 %enabled, i32 16, i32 0
  call void asm sideeffect "cp.async.cg.shared.global [$0], [$1], 16, $2;", "l,l,r,~{memory}"(i64 %dst, i64 %copy_src, i32 %copy_size)
  br label %latch

latch:
  call void @llvm.nvvm.barrier0()
  %rd_add = add i32 %rd, 512
  %rd_wrap = icmp eq i32 %rd_add, 1536
  %rd_next = select i1 %rd_wrap, i32 0, i32 %rd_add
  %wr_add = add i32 %wr, 512
  %wr_wrap = icmp eq i32 %wr_add, 1536
  %wr_next = select i1 %wr_wrap, i32 0, i32 %wr_add
  %iter_next = add i32 %iter, 1
  %more = icmp ult i32 %iter_next, 4
  br i1 %more, label %loop, label %exit

exit:
  ret void
}

declare i32 @llvm.nvvm.read.ptx.sreg.tid.x()
declare void @llvm.nvvm.barrier0()

!nvvm.annotations = !{!0}
!nvvmir.version = !{!1}
!0 = !{ptr @ring, !"kernel", i32 1}
!1 = !{i32 2, i32 0}
IR

sed 's/%copy_src = add i64 %src, 64/%copy_src = load i64, ptr addrspace(1) %source_ptr/' \
  "$work/ring.ll" > "$work/guarded-source.ll"
sed 's/%copy_size = select i1 %enabled, i32 16, i32 0/%copy_size = load i32, ptr addrspace(1) %source_ptr/' \
  "$work/ring.ll" > "$work/guarded-size.ll"

run_lift_opt() {
  local variant=$1
  shift
  "${llvm_bin:+$llvm_bin/}llvm-as" "$work/$variant.ll" -o "$work/$variant.bc"
  if ! (cd "$work" && env -u P2C_DRY -u P2C_STAGES -u CUPBOP_LIFT_OPT_PIPE -u CUPBOP_LIFT_OPT_P2C \
    VORTEX_NUM_THREADS=32 CUPBOP_VIRT_LANES=32 CUPBOP_LIFT_OPT=1 CUPBOP_LIFT_OPT_P4=0 \
    P2C_BLOCK=32 CUPBOP_LIFT_OPT_DUMP="$variant.out.ll" CUPBOP_LIFT_OPT_DUMP_ONLY=1 "$@" \
    "$translator" "$variant.bc" unused.bc) > "$work/$variant.log" 2>&1; then
    cat "$work/$variant.log"
    return 1
  fi
  "${llvm_bin:+$llvm_bin/}opt" -passes=verify -disable-output "$work/$variant.out.ll"
}

run_lift_opt ring CUPBOP_LIFT_OPT_WHY=1
grep -qF '@shared_mem = external addrspace(3) global [1536 x i8]' "$work/ring.out.ll"
[[ $(grep -c 'call void asm sideeffect "cp.async.cg.shared.global' "$work/ring.out.ll") == 3 ]]
if grep -Eq 'p2c-fold|p2c-alias' "$work/ring.log"; then
  cat "$work/ring.log"
  exit 1
fi

# The lifted cuBLAS stage-6 kernel uses a 24 KiB ring within its shared area.
xz -dc "$repo/examples/lift_g32/raw.ll.xz" > "$work/stage6.ll"
run_lift_opt stage6 CUPBOP_LIFT_OPT_WHY=1 P2C_BLOCK=128
grep -qF '@shared_mem = external addrspace(3) global [32768 x i8]' "$work/stage6.out.ll"
if grep -Eq 'p2c-fold|p2c-alias' "$work/stage6.log"; then
  cat "$work/stage6.log"
  exit 1
fi

for variant in guarded-source guarded-size; do
  run_lift_opt "$variant" CUPBOP_LIFT_OPT_PIPE=p2c-fold P2C_STAGES=1
  grep -F 'left as it is: copy source or size is not available at the guard' "$work/$variant.log"
  grep -qF '@shared_mem = external addrspace(3) global [1536 x i8]' "$work/$variant.out.ll"
  sed -n '/^copy:/,/^latch:/p' "$work/$variant.out.ll" | grep -Eq 'load i(32|64), ptr addrspace\(1\) %source_ptr'
done

run_lift_opt ring P2C_STAGES=1
grep -F 'ring S=3 -> 1' "$work/ring.log"
grep -qF '@shared_mem = external addrspace(3) global [512 x i8]' "$work/ring.out.ll"

# Leave explicit CUDA waits in the input. The folded tile may be read before
# those original waits. The sibling kernel keeps its independent DXA issue.
sed -e '/call void asm sideeffect "cp.async./a\  call void @llvm.nvvm.cp.async.wait.all()' \
    -e 's/!nvvm.annotations = !{!0}/!nvvm.annotations = !{!0, !2}/' \
    "$work/ring.ll" > "$work/pair.ll"
cat >> "$work/pair.ll" <<'IR'
declare void @llvm.nvvm.cp.async.wait.all()
define void @sibling(ptr addrspace(3) %dst, ptr addrspace(1) %src) {
EntryBB_sibling:
  %param_local = alloca [8 x i8]
  call void asm sideeffect "cp.async.cg.shared.global [$0], [$1], 16;", "l,l,~{memory}"(ptr addrspace(3) %dst, ptr addrspace(1) %src)
  call void @llvm.nvvm.cp.async.wait.all()
  ret void
}
!2 = !{ptr @sibling, !"kernel", i32 1}
IR
run_lift_opt pair P2C_STAGES=1
grep -F 'ring S=3 -> 1' "$work/pair.log"
grep -q '!cupbop.cp_async.synchronous' "$work/pair.out.ll"
(
  cd "$work"
  # Feed the serialized result back in without running the fold a second time.
  env CUPBOP_LIFT_OPT=0 VORTEX_SCHEDULE_FLAG=2 VORTEX_NUM_THREADS=32 CUPBOP_VIRT_LANES=32 \
    VORTEX_LOCALMEM_FLAG=1 VORTEX_CONFIGS=-DVX_CFG_EXT_DXA_ENABLE CUPBOP_CP_ASYNC_COALESCED_DXA=1 \
    "$translator" pair.out.ll translated.bc > translation.log 2>&1 || { cat translation.log; exit 1; }
  "${llvm_bin:+$llvm_bin/}opt" -passes=verify -disable-output translated.bc
  diff -u <(printf '32\nsibling\n') cupbop_cp_async_dxa.txt
)
