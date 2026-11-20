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

sed 's/"wgmma.commit_group.sync.aligned; wgmma.wait_group.sync.aligned 0;", "~{memory}"()/"wgmma.commit_group.sync.aligned;", "~{memory}"(), !cupbop.wgmma.gsb !0\n  call void asm sideeffect "wgmma.wait_group.sync.aligned 0;", "~{memory}"(), !cupbop.wgmma.gsb !1/' reset.ll > tagged.ll
cat >> tagged.ll <<'IR'
!0 = !{i32 2}
!1 = !{i32 2, i32 1}
IR
llvm-as tagged.ll -o tagged.bc
"$translator" tagged.bc kernel.bc > tagged.log 2>&1 || { cat tagged.log; exit 1; }
opt -passes=verify -disable-output kernel.bc
llvm-dis kernel.bc -o kernel.ll
if rg -q 'call void @__cupbop_wgmma_m64nNk16_f16f32_native' kernel.ll; then
  rg -q '\.insn r 0x0b, 4, 2, x3, x1, x0' kernel.ll
  rg -q '\.insn r 0x0b, 4, 2, x3, x2, x1' kernel.ll
fi

sed 's/\$9, 0, 1, 1, 0, 0/\$9, 1, 1, 1, 0, 0/' reset.ll > missing-acc.ll
llvm-as missing-acc.ll -o missing-acc.bc
if "$translator" missing-acc.bc kernel.bc > missing-acc.log 2>&1; then
  echo 'WGMMA accepted scale-D=1 without an incoming accumulator' >&2
  exit 1
fi
rg -q 'error: unsupported wgmma form' missing-acc.log

sed 's/}, \$8, \$9/}, ${9:l}, $8/' reset.ll > swapped.ll
llvm-as swapped.ll -o swapped.bc
"$translator" swapped.bc kernel.bc > swapped.log 2>&1 || { cat swapped.log; exit 1; }
opt -passes=verify -disable-output kernel.bc
llvm-dis kernel.bc -o kernel.ll
rg -q 'call void @__cupbop_wgmma_m64nNk16_f16f32(_native)?\(i32 16, i64 %b, i64 %a, i32 0,' kernel.ll

sed 's/wgmma.commit_group.sync.aligned; wgmma.wait_group.sync.aligned 0;/{ .reg .b32 m; .reg .pred p; activemask.b32 m; elect.sync _|p, m; wgmma.commit_group.sync.aligned; wgmma.wait_group.sync.aligned 0; }/' reset.ll > mixed.ll
llvm-as mixed.ll -o mixed.bc
if "$translator" mixed.bc kernel.bc > mixed.log 2>&1; then
  echo 'WGMMA accepted controls bundled with elect.sync' >&2
  exit 1
fi
rg -q 'WGMMA control must use unpredicated inline asm' mixed.log

sed -e 's/"wgmma.mma_async/"{ .reg .pred p; setp.ne.b32 p, $10, 0; wgmma.mma_async/' \
    -e 's/\$9, 0, 1, 1, 0, 0;"/\$9, p, 1, 1, 0, 0; }"/' \
    -e 's/l,l,~{memory}"(i64 %a, i64 %b)/l,l,r,0,1,2,3,4,5,6,7,~{memory}"(i64 %a, i64 %b, i32 1, float 0.0, float 0.0, float 0.0, float 0.0, float 0.0, float 0.0, float 0.0, float 0.0)/' \
    reset.ll > predicate.ll
llvm-as predicate.ll -o predicate.bc
"$translator" predicate.bc kernel.bc > predicate.log 2>&1 || { cat predicate.log; exit 1; }
opt -passes=verify -disable-output kernel.bc

expect_bad_mma() {
  local name=$1 diagnostic=$2
  llvm-as "$name.ll" -o "$name.bc"
  if "$translator" "$name.bc" kernel.bc > "$name.log" 2>&1; then
    echo "WGMMA accepted invalid $name asm" >&2
    exit 1
  fi
  grep -Fq "$diagnostic" "$name.log"
}

sed 's/!{i32 2, i32 1}/!{i32 2, i32 8}/' tagged.ll > tagged-count.ll
expect_bad_mma tagged-count 'invalid !cupbop.wgmma.gsb metadata'
sed 's/\$9, 0, 1, 1, 0, 0;"/\$9, 0, 1, 1, 0, 0; st.shared.b32 [$8], 0;"/' reset.ll > mma-store.ll
expect_bad_mma mma-store 'WGMMA MMA requires a single unpredicated instruction'
sed '/wgmma\.mma_async/s/;"/; wgmma.mma_async.sync.aligned.m64n16k16.f32.f16.f16 {$0,$1,$2,$3,$4,$5,$6,$7}, $8, $9, 0, 1, 1, 0, 0;"/' reset.ll > mma-twice.ll
expect_bad_mma mma-twice 'WGMMA MMA inline asm must contain just the MMA'
sed 's/setp.ne.b32 p, \$10, 0/setp.eq.b32 p, $10, 0/' predicate.ll > wrong-predicate.ll
expect_bad_mma wrong-predicate 'WGMMA MMA inline asm must contain just the MMA'
sed 's/{\$0,\$1,/{\$1,\$0,/' reset.ll > permuted-outputs.ll
expect_bad_mma permuted-outputs 'WGMMA MMA accumulator output operands must be in LLVM result order'
sed 's/l,l,r,0,1,/l,l,r,1,0,/' predicate.ll > permuted-ties.ll
expect_bad_mma permuted-ties 'error: unsupported wgmma form'
sed 's/wgmma.mma_async.sync.aligned/wgmma.mma_async.sp.sync.aligned/' reset.ll > sparse.ll
expect_bad_mma sparse 'sparse WGMMA'
sed -e 's/mma_async.sync.aligned.m64n16k16/mma_async.sp.sync.aligned.m64n16k32/' \
    -e 's/}, \$8, \$9, 0, 1, 1, 0, 0/}, \$8, \$9, \$10, 1, 0, -1, 1, 0, 1/' \
    -e 's/l,l,~{memory}"(i64 %a, i64 %b)/l,l,r,~{memory}"(i64 %a, i64 %b, i32 0)/' reset.ll > sparse-valid.ll
llvm-as sparse-valid.ll -o sparse-valid.bc
"$translator" sparse-valid.bc kernel.bc > sparse-valid.log 2>&1 || { cat sparse-valid.log; exit 1; }
opt -passes=verify -disable-output kernel.bc
llvm-dis kernel.bc -o kernel.ll
rg -q 'call void @__cupbop_sparse_wgmma_f16_(native|sw)' kernel.ll
sed 's/\$10, 1, 0, -1/\$10, 2, 0, -1/' sparse-valid.ll > sparse-selector.ll
expect_bad_mma sparse-selector 'invalid sparse WGMMA immediate'
sed 's/\$10, 1, 0, -1/\$10, 1, 1, -1/' sparse-valid.ll > sparse-acc.ll
expect_bad_mma sparse-acc 'sparse WGMMA with scale-D requires incoming accumulators'
echo 'WGMMA operand and control tests passed'
