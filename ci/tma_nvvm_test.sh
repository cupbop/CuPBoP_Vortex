#!/usr/bin/env bash
set -euo pipefail
translator=$(realpath "$1")
llvm_bin=$(realpath "$2")
export LD_LIBRARY_PATH="$llvm_bin/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CUPBOP_LIFT_OPT=0 VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 VORTEX_NUM_THREADS=32
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

cat > input.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"

@shared = external addrspace(3) global [384 x i8], align 128

declare void @llvm.nvvm.cp.async.bulk.tensor.g2s.tile.3d(ptr addrspace(3), ptr addrspace(3), ptr, i32, i32, i32, i16, i64, i1 immarg, i1 immarg)

define ptx_kernel void @same_block(ptr %map) {
entry:
  %bar = ptrtoint ptr addrspace(3) @shared to i64
  %a = getelementptr inbounds i8, ptr addrspace(3) @shared, i64 128
  %b = getelementptr inbounds i8, ptr addrspace(3) @shared, i64 256
  call void asm sideeffect "mbarrier.init.shared::cta.b64 [$0], 1;", "l,~{memory}"(i64 %bar)
  call void asm sideeffect "fence.mbarrier_init.release.cluster;", "~{memory}"()
  call void asm sideeffect "mbarrier.arrive.expect_tx.shared::cta.b64 _, [$0], 256;", "l,~{memory}"(i64 %bar)
  call void @llvm.nvvm.cp.async.bulk.tensor.g2s.tile.3d(ptr addrspace(3) %a, ptr addrspace(3) @shared, ptr %map, i32 0, i32 0, i32 0, i16 0, i64 0, i1 false, i1 false)
  call void @llvm.nvvm.cp.async.bulk.tensor.g2s.tile.3d(ptr addrspace(3) %b, ptr addrspace(3) @shared, ptr %map, i32 0, i32 0, i32 1, i16 0, i64 0, i1 false, i1 false)
  call void asm sideeffect "fence.proxy.async.shared::cta;", "~{memory}"()
  ret void
}

define ptx_kernel void @split_transaction(ptr %map, i1 %copy) {
entry:
  %bar = ptrtoint ptr addrspace(3) @shared to i64
  call void asm sideeffect "mbarrier.init.shared::cta.b64 [$0], 1;", "l,~{memory}"(i64 %bar)
  call void asm sideeffect "mbarrier.expect_tx.shared::cta.b64 [$0], 128;", "l,~{memory}"(i64 %bar)
  br i1 %copy, label %issue, label %arrive
issue:
  %a = getelementptr inbounds i8, ptr addrspace(3) @shared, i64 128
  call void @llvm.nvvm.cp.async.bulk.tensor.g2s.tile.3d(ptr addrspace(3) %a, ptr addrspace(3) @shared, ptr %map, i32 0, i32 0, i32 0, i16 0, i64 0, i1 false, i1 false)
  ret void
arrive:
  call void asm sideeffect "mbarrier.arrive.shared::cta.b64 _, [$0];", "l,~{memory}"(i64 %bar)
  ret void
}
IR

"$llvm_bin/llvm-as" input.ll -o input.bc
"$translator" input.bc kernel.bc > translation.log 2>&1 || { cat translation.log; exit 1; }
"$llvm_bin/opt" -passes=verify -disable-output kernel.bc
"$llvm_bin/llvm-dis" kernel.bc -o kernel.ll
grep -Fq '1 converged DXA issue point(s)' translation.log
grep -Eq 'call void @__cupbop_txq_issue\(ptr[^,]+, i32 2, i32 3\)' kernel.ll
grep -Fq 'call void @__cupbop_tcgen_tma_load' kernel.ll
grep -Fq 'fence release' kernel.ll
grep -Fq 'fence seq_cst' kernel.ll
echo 'NVVM TMA queued load and byte-counted fallback tests passed'
