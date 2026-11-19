#!/usr/bin/env bash
# Check DXA layout and geometry validation before the host reads the descriptor sidecar.
set -euo pipefail
translator=$(realpath "$1")
llvm_bin=$(realpath "$2")
export LD_LIBRARY_PATH="$llvm_bin/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

write_ir() {
  local refs= separator= i=0
  cat > input.ll <<'IR'
target triple = "nvptx64-nvidia-cuda"
define ptx_kernel void @probe(ptr %buffer, i32 %width) {
  ret void
}
IR
  for spec in "$@"; do
    printf '!%d = !{ptr @probe, !"slot=%d base=arg0 %s"}\n' "$i" "$i" "$spec" >> input.ll
    refs+="${separator}!$i"
    separator=', '
    i=$((i + 1))
  done
  printf '!vx.dxa.desc = !{%s}\n' "$refs" >> input.ll
  "$llvm_bin/llvm-as" input.ll -o input.bc
}

translate() {
  CUPBOP_LIFT_OPT=0 VORTEX_SCHEDULE_FLAG=2 VORTEX_LOCALMEM_FLAG=1 VORTEX_NUM_THREADS=32 \
    "$translator" input.bc out.bc > translation.log 2>&1
}

base='size=arg1,64 box=16,32 elem=2'
write_ir "$base" "$base layout=kmajor" "$base layout=flat tc_n=8" \
         "$base layout=blockmajor tc_n=0x8 block_k=8"
translate || { cat translation.log; exit 1; }
"$llvm_bin/opt" -passes=verify -disable-output out.bc
grep -Fx "desc probe slot=0 base=arg0 $base" dxa_descriptors.txt
grep -Fx "desc probe slot=1 base=arg0 $base layout=kmajor" dxa_descriptors.txt
grep -Fx "desc probe slot=2 base=arg0 $base layout=flat tc_n=8" dxa_descriptors.txt
grep -Fx "desc probe slot=3 base=arg0 $base layout=blockmajor tc_n=0x8 block_k=8" dxa_descriptors.txt

reject() {
  write_ir "$1"
  if translate; then
    echo "unexpectedly accepted: $1" >&2
    exit 1
  fi
  grep -F "error: !vx.dxa.desc entry 0: $2" translation.log
}

reject "$base layout=unknown" 'layout must be row, kmajor, flat or blockmajor'
reject "$base layout=row tc_n=8" 'row and kmajor take no tile geometry'
reject 'size=32,64,2 box=16,32,1 elem=2 layout=flat tc_n=8' 'flat and blockmajor need a rank-2 B tile'
reject "$base layout=flat" 'tc_n and box[0] must be powers of two'
reject "$base layout=flat tc_n=arg1" 'tc_n must be an unsigned 32-bit integer literal'
reject 'size=32,64 box=16,16 elem=2 layout=flat tc_n=8' 'box[1] must contain complete B blocks'
reject "$base layout=blockmajor tc_n=8 block_k=3" 'block_k must be a power of two within 16 bits'
reject "$base layout=blockmajor tc_n=8 block_k=4294967296" 'block_k must be an unsigned 32-bit integer literal'
reject 'size=256,256 box=256,256 elem=2 layout=blockmajor tc_n=256 block_k=256' 'B block geometry exceeds'
