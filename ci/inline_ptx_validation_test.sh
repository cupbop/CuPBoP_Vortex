#!/usr/bin/env bash
# Keep memory ordering and matrix fragments in the translated device program.
set -euo pipefail
translator=$(realpath "$1")
llvm_bin=$(realpath "$2")
export LD_LIBRARY_PATH="$llvm_bin/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

cat > supported.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"
@a = addrspace(3) global [256 x i16] undef, align 16
@b = addrspace(3) global [128 x i16] undef, align 16
@independent = addrspace(3) global [64 x i16] undef, align 16

define ptx_kernel void @ordered(ptr addrspace(1) %sem, ptr addrspace(1) %in, ptr addrspace(1) %out) {
  %state = call i32 asm sideeffect "ld.acquire.gpu.global.u32 $0, [$1];", "=r,l,~{memory}"(ptr addrspace(1) %sem)
  %value = call i32 asm sideeffect "ld.global.cg.b32 $0, [$1];", "=r,l,~{memory}"(ptr addrspace(1) %in)
  call void asm sideeffect "fence.acq_rel.gpu;", "~{memory}"()
  %prior = call i32 asm sideeffect "atom.acq_rel.gpu.global.add.u32 $0, [$1], $2;", "=r,l,r,~{memory}"(ptr addrspace(1) %sem, i32 %value)
  call void asm sideeffect "red.release.gpu.global.add.u32 [$0], $1;", "l,r,~{memory}"(ptr addrspace(1) %sem, i32 %state)
  call void asm sideeffect "st.release.gpu.global.u32 [$0], $1;", "l,r,~{memory}"(ptr addrspace(1) %out, i32 %prior)
  ret void
}

define ptx_kernel void @fragments(ptr addrspace(1) %out) {
  %other = call i32 asm sideeffect "ldmatrix.sync.aligned.m8n8.x1.shared.b16 {$0}, [$1];", "=r,l,~{memory}"(ptr addrspace(3) @independent)
  %a = call {i32,i32,i32,i32} asm sideeffect "ldmatrix.sync.aligned.m8n8.x4.shared.b16 {$0,$1,$2,$3}, [$4];", "=r,=r,=r,=r,l,~{memory}"(ptr addrspace(3) @a)
  %b = call {i32,i32} asm sideeffect "ldmatrix.sync.aligned.m8n8.x2.trans.shared.b16 {$0,$1}, [$2];", "=r,=r,l,~{memory}"(ptr addrspace(3) @b)
  %a0 = extractvalue {i32,i32,i32,i32} %a, 0
  %a1 = extractvalue {i32,i32,i32,i32} %a, 1
  %a2 = extractvalue {i32,i32,i32,i32} %a, 2
  %a3 = extractvalue {i32,i32,i32,i32} %a, 3
  %b0 = extractvalue {i32,i32} %b, 0
  %b1 = extractvalue {i32,i32} %b, 1
  %mma = call {float,float,float,float} asm sideeffect "mma.sync.aligned.m16n8k16.row.col.f32.f16.f16.f32 {$0,$1,$2,$3}, {$8,$9,$10,$11}, {$12,$13}, {$4,$5,$6,$7};", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float 0.0,float 0.0,float 0.0,float 0.0,i32 %a0,i32 %a1,i32 %a2,i32 %a3,i32 %b0,i32 %b1)
  %value = extractvalue {float,float,float,float} %mma, 0
  store i32 %other, ptr addrspace(1) %out
  %next = getelementptr i32, ptr addrspace(1) %out, i64 1
  store float %value, ptr addrspace(1) %next
  ret void
}
!nvvm.annotations = !{!0,!1}
!0 = !{ptr @ordered, !"kernel", i32 1}
!1 = !{ptr @fragments, !"kernel", i32 1}
IR

export CUPBOP_LIFT_OPT=0 VORTEX_ARCHITECTURE=64 VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 VORTEX_NUM_THREADS=32
"$llvm_bin/llvm-as" supported.ll -o input.bc
"$translator" input.bc kernel.bc
"$llvm_bin/opt" -passes=verify -disable-output kernel.bc
"$llvm_bin/llvm-dis" kernel.bc -o kernel.ll
grep -F 'lr.w.aq' kernel.ll
grep -F 'load volatile i32' kernel.ll
grep -F 'fence acq_rel' kernel.ll
grep -E 'atomicrmw volatile add .* acq_rel' kernel.ll
grep -E 'atomicrmw volatile add .* release' kernel.ll
grep -E 'atomicrmw volatile xchg .* release' kernel.ll
grep -F 'call void @__cupbop_mma_m16n8k16_f16f32' kernel.ll
test "$(grep -c 'call void @__cupbop_ldmatrix_m8n8_b16' kernel.ll)" -ge 3
grep -E 'store i32 %[^,]+, ptr addrspace\(1\) %out' kernel.ll

# A local symbol matching the name of a lifted SWIN helper can also occur in
# ordinary LLVM input. Its result must still depend on the kernel argument.
cat > window.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"
@shared_mem = external addrspace(3) global [32 x i8]
define internal i32 @__culifter_shared_window_hi(i32 %x) noinline {
  ret i32 %x
}
define ptx_kernel void @window(ptr addrspace(1) %out, i32 %x) {
  %word = call i32 @__culifter_shared_window_hi(i32 %x)
  store i32 %word, ptr addrspace(1) %out
  ret void
}
!nvvm.annotations = !{!0}
!0 = !{ptr @window, !"kernel", i32 1}
IR
"$llvm_bin/llvm-as" window.ll -o input.bc
"$translator" input.bc kernel.bc
"$llvm_bin/llvm-dis" kernel.bc -o kernel.ll
grep -E 'store i32 %[^,]+, ptr addrspace\(1\) %out' kernel.ll

check_refused() {
  local name=$1 expected=$2 instruction=$3 helper=${4:-}
  cat > "$name.ll" <<IR
target triple = "nvptx64-nvidia-cuda"
$helper
define ptx_kernel void @reject(ptr addrspace(1) %addr) {
  $instruction
  ret void
}
!nvvm.annotations = !{!0}
!0 = !{ptr @reject, !"kernel", i32 1}
IR
  "$llvm_bin/llvm-as" "$name.ll" -o input.bc
  if "$translator" input.bc kernel.bc > "$name.log" 2>&1; then
    echo "$name unexpectedly translated"
    exit 1
  fi
  grep -F "$expected" "$name.log"
}

check_refused unknown 'unsupported PTX inline asm' 'call void asm sideeffect "unsupported_future_op;", "~{memory}"()'
check_refused sparse 'unsupported sparse PTX MMA' '%v = call {i32,i32,i32,i32} asm sideeffect "mma.sp.sync.aligned.m16n8k64.row.col.s32.s8.u8.s32 {$0,$1,$2,$3}, {$8,$9,$10,$11}, {$12,$13,$14,$15}, {$4,$5,$6,$7}, $16, 0;", "=r,=r,=r,=r,0,1,2,3,r,r,r,r,r,r,r,r,r"(i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0)'
sparse_fp16='%v = call {float,float,float,float} asm sideeffect "mma.sp.sync.aligned.m16n8k32.row.col.f32.f16.f16.f32 {$0,$1,$2,$3}, {$8,$9,$10,$11}, {$12,$13,$14,$15}, {$4,$5,$6,$7}, $16, SELECTOR;", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r,r,r,r"(float 0.0,float 0.0,float 0.0,float 0.0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0,i32 0)'
CUPBOP_MMA_LOWERING=sw check_refused sparse_bad_selector 'invalid compile-time sparsity selector' "${sparse_fp16/SELECTOR/2}"
VORTEX_CONFIGS='-DVX_CFG_EXT_TCU_ENABLE' CUPBOP_MMA_LOWERING=tcu \
  check_refused sparse_disabled 'known Vortex LMEM build with TCU sparse support' "${sparse_fp16/SELECTOR/0}"
check_refused compound_load 'unsupported compound PTX memory asm' '%v = call i32 asm sideeffect "ld.volatile.global.b32 $0, [$1]; red.release.gpu.global.add.u32 [$1], 1;", "=r,l,~{memory}"(ptr addrspace(1) %addr)'
check_refused compound_convert 'unsupported compound PTX memory asm' '%v = call float asm sideeffect "cvt.f32.f16 $0, $1; st.release.gpu.global.u32 [$2], 1;", "=f,h,l,~{memory}"(i16 0,ptr addrspace(1) %addr)'
check_refused reversed_fragments 'ldmatrix asm with unexpected operands' '%v = call {i32,i32} asm sideeffect "ldmatrix.sync.aligned.m8n8.x2.shared.b16 {$1,$0}, [$2];", "=r,=r,r,~{memory}"(i32 0)'

# CuLifter represents unhandled SASS as a weak no-op. Its LDTM output
# registers have already become zeros by the time this IR reaches CuPBoP.
for op in ldtm utcbar; do
  VORTEX_CONFIGS='-DVX_CFG_TCU_TMEM_COLUMN_ENABLE' CUPBOP_LIFT_OPT=1 \
    check_refused "column_$op" "incomplete CuLifter column TMEM input: sass_unsupported_$op" \
      "call void @sass_unsupported_$op()" "define weak void @sass_unsupported_$op() { ret void }"
done

# Paired integer MMA requires N to be a multiple of 32 (PTX tcgen05 shapes).
# 0x100404a4 encodes M256 N16, sparse S8/S8 and S32 accumulation.
VORTEX_CONFIGS='-DVX_CFG_EXT_TCU_ENABLE -DVX_CFG_TCU_TMEM_ENABLE -DVX_CFG_TCU_TMEM_COLUMN_ENABLE -DVX_CFG_TCU_INT8_ENABLE' \
  check_refused paired_sparse_i8_n16 'unsupported column MMA instruction descriptor' \
    'call void asm sideeffect "{ .reg .pred p; setp.ne.u32 p, 0, 0; tcgen05.mma.sp.cta_group::2.kind::i8 [$0], $1, $2, [$3], $4, p; }", "r,l,l,r,r,~{memory}"(i32 0, i64 0, i64 0, i32 0, i32 268698788)'
