#!/usr/bin/env bash
set -euo pipefail
tf32_test=$(realpath "$(dirname "$0")/tf32_target_test.py")
translator=$(realpath "$1")
llvm_bin=$(realpath "$2")
export LD_LIBRARY_PATH="$llvm_bin/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 VORTEX_NUM_THREADS=32
export VORTEX_CONFIGS="-DVX_CFG_EXT_TCU_ENABLE -DVX_CFG_TCU_TMEM_ENABLE -DVX_CFG_TCU_TMEM_COLUMN_ENABLE -DVX_CFG_TCU_FP8_ENABLE -DVX_CFG_TCU_INT8_ENABLE -DVX_CFG_TCU_MX_ENABLE -DVX_CFG_TCU_TF32_ENABLE"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

# LLVM's NVPTX cp intrinsic spells multicast and source padding in its name.
python3 - <<'PYTHON'
from pathlib import Path
shapes = ("4x256b", "128x128b", "128x256b", "32x128b_warpx4", "64x128b_warpx2_02_13", "64x128b_warpx2_01_23")
ops = [f"@llvm.nvvm.tcgen05.cp.{shape}{fmt}.cg{group}"
       for shape in shapes for fmt in ("", ".b4x16_p64", ".b6x16_p32") for group in (1, 2)]
ir = ['target triple = "nvptx64-nvidia-cuda"'] + [f"declare void {op}(ptr addrspace(6), i64)" for op in ops]
ir += [f"declare void @llvm.nvvm.tcgen05.shift.down.cg{g}(ptr addrspace(6))" for g in (1, 2)]
ir += ["define ptx_kernel void @copies(i32 %taddr, i64 %descriptor) {", "%dst = inttoptr i32 %taddr to ptr addrspace(6)"]
ir += [f"call void {op}(ptr addrspace(6) %dst, i64 %descriptor)" for op in ops]
ir += [f"call void @llvm.nvvm.tcgen05.shift.down.cg{g}(ptr addrspace(6) %dst)" for g in (1, 2)] + ["ret void", "}"]
Path("copies.ll").write_text("\n".join(ir))
PYTHON
"$llvm_bin/llvm-as" copies.ll -o copies.bc
"$translator" copies.bc kernel.bc > copies.log 2>&1 || { cat copies.log; exit 1; }
"$llvm_bin/opt" -passes=verify -disable-output kernel.bc
"$llvm_bin/llvm-dis" kernel.bc -o copies-lowered.ll
[[ $(grep -Ec 'call void @__cupbop_column_(pair_)?cp[( _]' copies-lowered.ll) == 36 ]]
[[ $(grep -c 'call void @__cupbop_column_shift(' copies-lowered.ll) == 2 ]]
if grep -Eq 'call void @llvm\.nvvm\.tcgen05\.(cp|shift)\.' copies-lowered.ll; then exit 1; fi

# LLVM 22 NVPTX CodeGen/tcgen05-mma.ll puts enable_input_d before sparse
# metadata. Newer LLVM also accepts a collector B immediate after collector A.
cat > source.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"
declare void @llvm.nvvm.tcgen05.mma.shared(ptr addrspace(6), i64, i64, i32, i1, i32, i32, i32)
declare void @llvm.nvvm.tcgen05.mma.sp.tensor(ptr addrspace(6), ptr addrspace(6), i64, i32, i1, ptr addrspace(6), i32, i32, i32, i32)
declare void @llvm.nvvm.tcgen05.mma.shared.mxf8f6f4.block_scale(ptr addrspace(6), i64, i64, i32, i1, ptr addrspace(6), ptr addrspace(6), i32, i32)
define ptx_kernel void @dense(i32 %d, i64 %a, i64 %b, i1 %acc) {
  %dest = inttoptr i32 %d to ptr addrspace(6)
  call void @llvm.nvvm.tcgen05.mma.shared(ptr addrspace(6) %dest, i64 %a, i64 %b, i32 134482192, i1 %acc, i32 1, i32 1, i32 0)
  call void @llvm.nvvm.tcgen05.mma.shared(ptr addrspace(6) %dest, i64 %a, i64 %b, i32 134479888, i1 true, i32 0, i32 1, i32 0)
  call void @llvm.nvvm.tcgen05.mma.shared(ptr addrspace(6) %dest, i64 %a, i64 %b, i32 134484368, i1 true, i32 2, i32 1, i32 0)
  call void @llvm.nvvm.tcgen05.mma.shared(ptr addrspace(6) %dest, i64 %a, i64 %b, i32 134481056, i1 true, i32 3, i32 1, i32 0)
  ret void
}
define ptx_kernel void @dynamic(i32 %d, i64 %a, i64 %b, i32 %desc) {
  %dest = inttoptr i32 %d to ptr addrspace(6)
  call void @llvm.nvvm.tcgen05.mma.shared(ptr addrspace(6) %dest, i64 %a, i64 %b, i32 %desc, i1 false, i32 0, i32 1, i32 0)
  call void @llvm.nvvm.tcgen05.mma.shared.mxf8f6f4.block_scale(ptr addrspace(6) %dest, i64 %a, i64 %b, i32 %desc, i1 false, ptr addrspace(6) %dest, ptr addrspace(6) %dest, i32 1, i32 0)
  ret void
}
define ptx_kernel void @sparse(i32 %d, i32 %a, i64 %b, i32 %meta) {
  %dest = inttoptr i32 %d to ptr addrspace(6)
  %src = inttoptr i32 %a to ptr addrspace(6)
  %metadata = inttoptr i32 %meta to ptr addrspace(6)
  call void @llvm.nvvm.tcgen05.mma.sp.tensor(ptr addrspace(6) %dest, ptr addrspace(6) %src, i64 %b, i32 268962068, i1 false, ptr addrspace(6) %metadata, i32 1, i32 2, i32 0, i32 0)
  ret void
}
define ptx_kernel void @scaled(i32 %d, i64 %a, i64 %b, i32 %sa, i32 %sb) {
  %dest = inttoptr i32 %d to ptr addrspace(6)
  %sfa = inttoptr i32 %sa to ptr addrspace(6)
  %sfb = inttoptr i32 %sb to ptr addrspace(6)
  call void @llvm.nvvm.tcgen05.mma.shared.mxf8f6f4.block_scale(ptr addrspace(6) %dest, i64 %a, i64 %b, i32 142868480, i1 true, ptr addrspace(6) %sfa, ptr addrspace(6) %sfb, i32 1, i32 0)
  ret void
}
IR
"$llvm_bin/llvm-as" source.ll -o source.bc
"$translator" source.bc kernel.bc > translation.log 2>&1 || { cat translation.log; exit 1; }
"$llvm_bin/opt" -passes=verify -disable-output kernel.bc
"$llvm_bin/llvm-dis" kernel.bc -o kernel.ll
for name in mma pair_mma_ts_sp mma_mx; do
  grep -Eq "call void @__cupbop_column_${name}\(" kernel.ll
done
[[ $(grep -c 'call void @__cupbop_tcgen05_check_descriptor(i32 %desc,' kernel.ll) == 2 ]]
if grep -Fq 'call void @llvm.nvvm.tcgen05.mma.' kernel.ll; then exit 1; fi

if VORTEX_CONFIGS="${VORTEX_CONFIGS//-DVX_CFG_TCU_TF32_ENABLE/}" "$translator" source.bc missing.bc > missing.log 2>&1; then
  echo 'Named TF32 MMA unexpectedly translated without TF32 hardware' >&2
  exit 1
fi
grep -Fq 'TF32 MMA requires -DVX_CFG_TCU_TF32_ENABLE' missing.log
# Explicit dynamically predicated TF32 must also fail with the target disabled.
cat > pred-tf32.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"
define ptx_kernel void @pred_tf32(i32 %dest, i64 %a, i64 %b, i32 %desc, i32 %issue) {
  call void asm sideeffect "{ .reg .pred p; setp.ne.u32 p, $4, 0; @p tcgen05.mma.cta_group::1.kind::tf32 [$0], $1, $2, $3, p; }", "r,l,l,r,r,~{memory}"(i32 %dest, i64 %a, i64 %b, i32 %desc, i32 %issue)
  ret void
}
IR
"$llvm_bin/llvm-as" pred-tf32.ll -o pred-tf32.bc
"$translator" pred-tf32.bc kernel.bc > pred-on.log 2>&1
if VORTEX_CONFIGS="${VORTEX_CONFIGS//-DVX_CFG_TCU_TF32_ENABLE/}" "$translator" pred-tf32.bc bad.bc > pred-off.log 2>&1; then
  echo 'Predicated TF32 unexpectedly accepted without TF32 hardware' >&2
  exit 1
fi
grep -Fq 'TF32 MMA requires -DVX_CFG_TCU_TF32_ENABLE' pred-off.log
# PTX collectors permit a reload of the same source. A post-MMA shift is
# semantic: it must reach the runtime for both named and inline input.
sed 's/mma.sp.tensor(/mma.sp.tensor.ashift(/g; s/i32 1, i32 2, i32 0, i32 0)/i32 1, i32 2, i32 1, i32 3)/' source.ll > collector.ll
"$llvm_bin/llvm-as" collector.ll -o collector.bc
"$translator" collector.bc shift.bc > collector.log 2>&1
"$llvm_bin/llvm-dis" shift.bc -o shift.ll
grep -Eq 'call void @__cupbop_column_pair_mma_ts_sp\(.*i32 264468,' shift.ll
for pair in '2, i32 3' '1, i32 4'; do
  sed "s/i32 2, i32 1, i32 3)/i32 2, i32 $pair)/" collector.ll > invalid.ll
  "$llvm_bin/llvm-as" invalid.ll -o invalid.bc
  if "$translator" invalid.bc bad.bc > invalid.log 2>&1; then
    echo 'Invalid named MMA collector accepted' >&2
    exit 1
  fi
  grep -Eq 'discard or lastuse A collector|invalid named TCGEN05 MMA collector mode' invalid.log
done
# Invalid PTX must not silently drop a shift or a collector from an opcode.
for modifier in 'ashift' 'collector::a::unknown' 'collector::b::fill.collector::b::use'; do
  cat > invalid.ll <<IR
target triple = "nvptx64-nvidia-cuda"
define ptx_kernel void @invalid(i32 %d, i64 %a, i64 %b) {
  call void asm sideeffect "{ .reg .pred p; setp.ne.u32 p, 0, 0; tcgen05.mma.cta_group::1.kind::f16.$modifier [\$0], \$1, \$2, \$3, p; }", "r,l,l,r,~{memory}"(i32 %d, i64 %a, i64 %b, i32 134479888)
  ret void
}
IR
  "$llvm_bin/llvm-as" invalid.ll -o invalid.bc
  if "$translator" invalid.bc bad.bc > invalid.log 2>&1; then
    echo "Invalid inline MMA modifier accepted: $modifier" >&2
    exit 1
  fi
  grep -Eq 'ashift requires column TMEM A|invalid or repeated TCGEN MMA collector mode' invalid.log
done
python3 "$tf32_test" "$translator" "$llvm_bin"
echo 'Named TCGEN05 MMA shared, sparse tensor, block-scale, collectors, ashift and diagnostics passed'
