#!/usr/bin/env bash
# A self-arrive recovered from SASS must use the CTA-local DXA path.
set -euo pipefail
translator=$(realpath "$1")
llvm_bin=$(realpath "$2")
export LD_LIBRARY_PATH="$llvm_bin/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

cat > arrive.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"

@shared_mem = external addrspace(3) global [256 x i8], align 128
declare i32 @llvm.nvvm.read.ptx.sreg.cluster.ctarank()
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x()

define void @copy(i64 %map, i32 %peer, i32 %tiles) {
entry:
  %args = alloca [16 x i8], align 8
  %slot = getelementptr inbounds i8, ptr %args, i64 8
  %tid = call i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  store i32 %tile_input, ptr %slot, align 4
  %limit = load i32, ptr %slot, align 4
  %rank = call i32 @llvm.nvvm.read.ptx.sreg.cluster.ctarank()
  %self = and i32 %rank, 255
  %bar = ptrtoint ptr addrspace(3) @shared_mem to i64
  %bar32 = trunc i64 %bar to i32
  %dst = ptrtoint ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @shared_mem, i64 128) to i64
  call void asm sideeffect "mbarrier.init.shared::cta.b64 [$0], 32;", "l,~{memory}"(i64 %bar)
  %has_tiles = icmp sgt i32 %limit, 0
  br i1 %has_tiles, label %loop, label %end

loop:
  %tile = phi i32 [ 0, %entry ], [ %next, %loop ]
  call void asm sideeffect "{.reg .pred p; .reg .u32 r; .reg .u32 m; .reg .b64 s; mov.u32 r, %cluster_ctarank; setp.ne.u32 p, r, $2; @p mapa.shared::cluster.u32 m, $0, $2; @p mbarrier.arrive.expect_tx.release.cluster.shared::cluster.b64 _, [m], $3; @!p mbarrier.arrive.expect_tx.shared::cta.b64 s, [$1], $3;}", "r,l,r,r,~{memory}"(i32 %bar32, i64 %bar, i32 %target, i32 128)
  call void asm sideeffect "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes [$0], [$1, {0, 0, $3}], [$2];", "l,l,l,r,~{memory}"(i64 %dst, i64 %map, i64 %bar, i32 %tile)
  %next = add nuw i32 %tile, 1
  %more = icmp slt i32 %next, %limit
  br i1 %more, label %loop, label %end

end:
  ret void
}

!nvvm.annotations = !{!0}
!0 = !{ptr @copy, !"kernel", i32 1}
IR

for example in self peer varying; do
  rank=self
  tile_input=tiles
  [[ $example != peer ]] || rank=peer
  [[ $example != varying ]] || tile_input=tid
  sed -e "s/%target/%$rank/" -e "s/%tile_input/%$tile_input/" arrive.ll > "$example.ll"
  "$llvm_bin/llvm-as" "$example.ll" -o input.bc
  if ! CUPBOP_LIFT_OPT=0 VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 \
      VORTEX_NUM_THREADS=32 "$translator" input.bc out.bc > "$example.log" 2>&1; then
    cat "$example.log"
    exit 1
  fi
  "$llvm_bin/opt" -passes=verify -disable-output out.bc
  "$llvm_bin/llvm-dis" out.bc -o "$example.out.ll"
done

grep -F '1 converged DXA issue point(s)' self.log
grep -F 'call void @__cupbop_txq_issue' self.out.ll
grep -F 'call ptr @__cupbop_cluster_map' peer.out.ll
grep -F 'call void @__cupbop_tcgen_tma_load' peer.out.ll
grep -F '0 converged DXA issue point(s)' varying.log
