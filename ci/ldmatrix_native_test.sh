#!/usr/bin/env bash
# Check the ELF and each CUDA x4 word on the selected 32-lane SimX target.
set -euo pipefail
: "${CuPBoP_PATH:?}" "${VORTEX_PATH:?}" "${LLVM_PREFIX:?}"
work=$(mktemp -d "${TMPDIR:-/tmp}/cupbop-ldmatrix-native.XXXXXXXX")
echo "Matrix regression artifacts: $work"
app="$work/examples/ldmatrix_native-$(basename "$work")"
mkdir -p "$app"
ln -s "$CuPBoP_PATH/build" "$work/build"
ln -s "$CuPBoP_PATH/examples/"{common.mk,async_common.h,lift.mk,lift_d2h.c,ldmatrix_native} "$work/examples/"
cp "$CuPBoP_PATH/examples/ldmatrix_native/"{Makefile,main.cu} "$app/"
replay="$work/examples/lifted_ldmatrix_native-$(basename "$work")"
mkdir "$replay"
cp "$CuPBoP_PATH/examples/lifted_ldmatrix_native/"{Makefile,raw.ll.xz} "$replay/"
for input in "$app" "$replay"; do
  cd "$input"
  make -s build SCHEDULE=2 LOCALMEM=1 > build.log 2>&1 || { tail -40 build.log; exit 1; }
  ./host.out > run.log 2>&1 || { tail -30 run.log; exit 1; }
  grep -F 'matrix x4 fragment, transpose, store guards: 0/2048 mismatches' run.log
  "$LLVM_PREFIX/bin/llvm-objdump" -d --section=.text kernel.elf > text.dump
  python3 - <<'PY'
import os
import re
from pathlib import Path

flags = {f.partition("=")[0] for f in os.environ["VORTEX_CONFIGS"].split()}
native = "-DVX_CFG_EXT_LDST_MATRIX_ENABLE" in flags
text = Path("text.dump").read_text()
for kernel in ("__vx_kentry__Z6matrixILb0EEvPjj", "__vx_kentry__Z6matrixILb1EEvPjj"):
    body = re.search(r"^[0-9a-f]+ <" + kernel + r">:(.*?)(?=\n[0-9a-f]+ <|\Z)", text, re.M | re.S)[1]
    words = [int(op,16) for op in re.findall(r"^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s", body, re.M)]
    assert words
    loads = [op for op in words if op & 0x707f == 0x007b and op >> 20 == 1]
    stores = [op for op in words if op & 0x707f == 0x207b and (op >> 7 & 31 | op >> 25 << 5) == 1]
    assert bool(loads) == native and bool(stores) == native, (kernel, loads, stores, native)
PY
done

# Native NVVM matrix intrinsics and the CUDA PTX spelling reach the same
# fragment helpers even when the input is not a Triton program.
mkdir named && cd named
cat > input.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"
declare {i32,i32,i32,i32} @llvm.nvvm.ldmatrix.sync.aligned.m8n8.x4.trans.b16.p3(ptr addrspace(3))
declare void @llvm.nvvm.stmatrix.sync.aligned.m8n8.x4.trans.b16.p3(ptr addrspace(3), i32,i32,i32,i32)
define ptx_kernel void @named(ptr addrspace(3) %src, ptr addrspace(3) %dst) {
  %f = call {i32,i32,i32,i32} @llvm.nvvm.ldmatrix.sync.aligned.m8n8.x4.trans.b16.p3(ptr addrspace(3) %src)
  %a = extractvalue {i32,i32,i32,i32} %f, 0
  %b = extractvalue {i32,i32,i32,i32} %f, 1
  %c = extractvalue {i32,i32,i32,i32} %f, 2
  %d = extractvalue {i32,i32,i32,i32} %f, 3
  call void @llvm.nvvm.stmatrix.sync.aligned.m8n8.x4.trans.b16.p3(ptr addrspace(3) %dst, i32 %a,i32 %b,i32 %c,i32 %d)
  ret void
}
IR
"$LLVM_PREFIX/bin/llvm-as" input.ll -o input.bc
TRITON_CUPBOP=0 CUPBOP_LIFT_OPT=0 "${KERNEL_TRANSLATOR:-$CuPBoP_PATH/build/compilation/kernelTranslator}" input.bc out.bc
"$LLVM_PREFIX/bin/opt" -passes=verify -disable-output out.bc
"$LLVM_PREFIX/bin/llvm-dis" out.bc -o output.ll
grep -Eq 'call void @__cupbop_ldmatrix_m8n8_b16\(.*i32 4, i32 1,' output.ll
grep -Eq 'call void @__cupbop_stmatrix_m8n8_b16\(.*i32 4, i32 1,' output.ll
