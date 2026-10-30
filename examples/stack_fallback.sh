#!/bin/bash
# stack_fallback.sh <kernelTranslator> <device bitcode> <cell dir> <make args for the cell...>
# Called by common.mk (VORTEX_VER=3, SCHEDULE 1 or 2) in the example directory after kernel.elf/vxbin/dump were built;
# MAKE = the make program. Nothing happens unless a kernel function's static stack frame exceeds
# CUPBOP_FRAME_LIMIT (default 7168 bytes) of the 8 KB per-hardware-thread stack (VX_MEM_STACK_LOG2_SIZE=13): a larger
# frame writes into the next hardware thread's stack (misaligned accesses, IPDOM / range-check crashes, wrong data).
#  1. Core mapping with fixed trips (CUPBOP_VIRT_TRIPS=k): every warp loop is unrolled k times, so in a large kernel
#     the k logical warps' barrier-crossing values are all live at once and become register spills (lifted CUTLASS /
#     cuBLAS GEMMs at s1p1t4/t8: 10-20 KB frames). The offending functions are translated again with the dynamic trip
#     count (CUPBOP_VIRT_TRIPS_DYN_FUNCS, insert_warp_loop.cpp virt_trips_of); kept if no frame grew and the largest
#     offending frame shrank. CUPBOP_VIRT_TRIPS_FALLBACK=0 skips this step.
#  2. If a frame still exceeds the limit (register spills of the kernel itself: conv2d / mlp / tensor-op GEMMs at s2),
#     the kernel runs on a software stack in device memory (CUPBOP_BIG_STACK=<bytes per hardware thread>,
#     generate_wrapper.cpp; the host reads cupbop_big_stack.txt). Bytes = largest frame + 8 KB (callees, dynamic
#     allocas), rounded up to 4 KB, plus 64 bytes of stride skew. CUPBOP_BIG_STACK_FALLBACK=0 skips this step.
set -u
KT=$1; DEV=$2; CELL=$3; shift 3
LIM=${CUPBOP_FRAME_LIMIT:-7168}
HERE=$(dirname $0)
OVER=$(python3 $HERE/stack_frames.py kernel.dump --over $LIM)
[ -n "$OVER" ] || exit 0
maxf() { python3 $HERE/stack_frames.py kernel.dump | awk -v l="$1" 'BEGIN{n=split(l,a,",");for(i=1;i<=n;i++)w[a[i]]=1} {if($2 in w && $1>m)m=$1; if($1>all)all=$1} END{print m+0, all+0}'; }
B=.stack_fallback; rm -rf $B; mkdir -p $B
FILES="kernel.bc kernel.ll kernel_wrapper.cpp kernel_meta.log cupbop_ctx_scratch.txt cupbop_big_stack.txt kernel.elf kernel.vxbin kernel.dump"
save() { rm -rf $B/keep; mkdir -p $B/keep; for f in $FILES; do [ -f $f ] && cp -p $f $B/keep/; done; }
restore() { for f in $FILES; do if [ -f $B/keep/$f ]; then cp -p $B/keep/$f .; else rm -f $f; fi; done; }
rebuild() { # <log tag> <make args...>: translate (env set by the caller) + rebuild the cell + copy back; 1 on failure
  local tag=$1; shift
  $KT $DEV kernel.bc > $B/$tag.translate.log 2>&1 || return 1
  llvm-dis kernel.bc
  rm -f $CELL/kernel.elf $CELL/kernel.vxbin $CELL/kernel.dump
  $MAKE -C $CELL kernel.vxbin kernel.dump "$@" > $B/$tag.rebuild.log 2>&1 || return 1
  cp $CELL/kernel.elf $CELL/kernel.vxbin $CELL/kernel.dump .
}
# --- 1. fixed trips -> dynamic trip count for the offending functions
case "${CUPBOP_VIRT_TRIPS:-}" in ''|*[!0-9]*) K=0 ;; *) K=$CUPBOP_VIRT_TRIPS ;; esac
if [ "$K" -gt 0 ] && [ "$VORTEX_SCHEDULE_FLAG" = 1 ] && [ "${CUPBOP_VIRT_TRIPS_FALLBACK:-1}" != 0 ] && [ -z "${CUPBOP_VIRT_TRIPS_DYN_FUNCS:-}" ]; then
  read OLD OLDALL <<< "$(maxf $OVER)"
  echo "--- [stack] fixed trips $K: stack frame $OLD bytes > $LIM in: $OVER; rebuilding them with the dynamic trip count"
  save
  if ! CUPBOP_VIRT_TRIPS_DYN_FUNCS=$OVER rebuild trips "$@"; then
    echo "--- [stack] dynamic-trips rebuild failed ($B/trips.*.log): keeping the fixed-trips build"; restore
  elif ! cmp -s kernel_wrapper.cpp $B/keep/kernel_wrapper.cpp; then
    echo "--- [stack] dynamic-trips rebuild changed the wrapper: keeping the fixed-trips build"; restore
  else
    read NEW NEWALL <<< "$(maxf $OVER)"
    if [ "$NEW" -ge "$OLD" ] || [ "$NEWALL" -gt "$OLDALL" ]; then
      echo "--- [stack] dynamic trips: frame $NEW bytes (largest $NEWALL), no smaller: keeping the fixed-trips build"; restore
    else
      echo "--- [stack] dynamic trip count for $OVER: stack frame $OLD -> $NEW bytes"
      export CUPBOP_VIRT_TRIPS_DYN_FUNCS=$OVER   # for step 2's translation
    fi
  fi
  OVER=$(python3 $HERE/stack_frames.py kernel.dump --over $LIM)
  [ -n "$OVER" ] || exit 0
fi
# --- 2. software stack
[ "${CUPBOP_BIG_STACK_FALLBACK:-1}" = 0 ] && exit 0
[ -n "${CUPBOP_BIG_STACK:-}" ] && exit 0   # set by hand: honour it as it is
read OLD OLDALL <<< "$(maxf $OVER)"
BYTES=$(( (OLDALL + 8192 + 4095) / 4096 * 4096 ))
# stride between the hardware threads' stacks: one 64-byte line more than a multiple of 4 KB, so that the same frame
# slot of neighbouring lanes falls into different cache sets and banks (a 4 KB multiple put a warp's 32 accesses to
# one spill slot into a single L1 set)
STRIDE=$((BYTES + 64))
echo "--- [stack] stack frame $OLDALL bytes > $LIM in: $OVER; the kernel runs on a $BYTES-byte software stack per hardware thread"
save
if ! CUPBOP_BIG_STACK=$STRIDE rebuild bigstack "$@"; then
  echo "--- [stack] software-stack rebuild failed ($B/bigstack.*.log): keeping the hardware-stack build"; restore; exit 0
fi
read NEW NEWALL <<< "$(maxf $OVER)"
if [ "$NEWALL" -gt $((BYTES - 4096)) ]; then
  echo "--- [stack] software-stack build has a $NEWALL-byte frame (> $BYTES - 4 KB): keeping the hardware-stack build"; restore; exit 0
fi
echo $STRIDE > cupbop_big_stack.txt
nm -C --defined-only -g kernel.elf > lookup_global_symbols.txt 2>/dev/null
echo "--- [stack] software stack: $BYTES bytes per hardware thread, stride $STRIDE (cupbop_big_stack.txt)"
