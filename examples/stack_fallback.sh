#!/bin/bash
# stack_fallback.sh <kernelTranslator> <device bitcode> <cell dir> <make args for the cell...>
# Called by common.mk (VORTEX_VER=3, every schedule) in the example directory after kernel.elf/vxbin/dump were built;
# MAKE = the make program. Three post-build steps, in this order:
#  A. frame fallback (schedules 1 and 2; steps 1-2 below)
#  B. sp skew modulus (CUPBOP_SP_SKEW, generate_wrapper.cpp kabi_prelude): when kernel_wrapper.cpp has a
#     __CUPBOP_SP_SKEW_M line, M is lowered to the largest of 8, 4, 2, 1 (not above the translated one) with
#     largest frame + (M-1) x __CUPBOP_SP_SKEW_STEP <= CUPBOP_FRAME_LIMIT, i.e. the same 1 KB of the 8 KB stack stays
#     for kernel_main and the callees as with the frame limit alone. A kernel with run-time sized allocas (core-mapping
#     context arrays on the stack) keeps that M when their worst case over all launches fits too, else M becomes an
#     upper bound that kernel_main lowers per launch so that frame + arrays + (M-1) x STEP <= CUPBOP_FRAME_LIMIT (the
#     translator's cupbop_dyn_stack.txt; see skew_fit). A change rewrites that line (and the threshold defines) and
#     rebuilds the cell
#     (the kernel code is the same; only kernel_main's skew mask changes). A software-stack build has M = 1 already.
#  C. kernel ABI check (CUPBOP_KABI): when the translator wrote cupbop_kabi.txt, examples/abi_check.py checks the final
#     kernel ELF (abi_check.log); UNSAFE removes kernel.elf/vxbin/dump and fails the build.
# Frame fallback: nothing happens unless a kernel function's static stack frame exceeds
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
# --build-failed: common.mk's first ELF build failed. With fixed trips the k-way unrolled warp loops can exhaust the
# register allocator ("ran out of registers": conv2d s1p1t4 with the core-mapping deadlock guard); translate every
# function with the dynamic trip count and build again (exit status = that build's). Otherwise fail as before.
if [ "${1:-}" = --build-failed ]; then
  shift; KT=$1; DEV=$2; CELL=$3; shift 3
  case "${CUPBOP_VIRT_TRIPS:-}" in ''|*[!0-9]*) exit 1 ;; esac
  [ "$CUPBOP_VIRT_TRIPS" -gt 0 ] && [ "$VORTEX_SCHEDULE_FLAG" = 1 ] && [ "${CUPBOP_VIRT_TRIPS_FALLBACK:-1}" != 0 ] || exit 1
  [ -z "${CUPBOP_VIRT_TRIPS_DYN_FUNCS:-}" ] || exit 1
  mkdir -p .stack_fallback
  echo "--- [stack] fixed trips $CUPBOP_VIRT_TRIPS: the kernel ELF build failed; building with the dynamic trip count"
  CUPBOP_VIRT_TRIPS_DYN_FUNCS='*' $KT $DEV kernel.bc > .stack_fallback/buildfail.translate.log 2>&1 || exit 1
  llvm-dis kernel.bc
  touch .stack_fallback/dyn_all
  exec $MAKE -C $CELL kernel.vxbin kernel.dump "$@"
fi
KT=$1; DEV=$2; CELL=$3; shift 3
LIM=${CUPBOP_FRAME_LIMIT:-7168}
HERE=$(dirname $0)
B=.stack_fallback
FILES="kernel.bc kernel.ll kernel_wrapper.cpp kernel_meta.log cupbop_ctx_scratch.txt cupbop_big_stack.txt cupbop_kabi.txt cupbop_dyn_stack.txt kernel.elf kernel.vxbin kernel.dump"
maxf() { python3 $HERE/stack_frames.py kernel.dump | awk -v l="$1" 'BEGIN{n=split(l,a,",");for(i=1;i<=n;i++)w[a[i]]=1} {if($2 in w && $1>m)m=$1; if($1>all)all=$1} END{print m+0, all+0}'; }
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
# --- A. frame fallback (schedules 1 and 2)
frame_fallback() {
case "${VORTEX_SCHEDULE_FLAG:-}" in 1|2) ;; *) return 0 ;; esac
OVER=$(python3 $HERE/stack_frames.py kernel.dump --over $LIM)
[ -n "$OVER" ] || return 0
DYN_ALL=0; [ -f .stack_fallback/dyn_all ] && DYN_ALL=1   # set by --build-failed: every function is dynamic already
rm -rf $B; mkdir -p $B
[ $DYN_ALL = 1 ] && export CUPBOP_VIRT_TRIPS_DYN_FUNCS='*' 
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
  [ -n "$OVER" ] || return 0
fi
# --- 2. software stack
[ "${CUPBOP_BIG_STACK_FALLBACK:-1}" = 0 ] && return 0
[ -n "${CUPBOP_BIG_STACK:-}" ] && return 0   # set by hand: honour it as it is
read OLD OLDALL <<< "$(maxf $OVER)"
BYTES=$(( (OLDALL + 8192 + 4095) / 4096 * 4096 ))
# stride between the hardware threads' stacks: one 64-byte line more than a multiple of 4 KB, so that the same frame
# slot of neighbouring lanes falls into different cache sets and banks (a 4 KB multiple put a warp's 32 accesses to
# one spill slot into a single L1 set)
STRIDE=$((BYTES + 64))
echo "--- [stack] stack frame $OLDALL bytes > $LIM in: $OVER; the kernel runs on a $BYTES-byte software stack per hardware thread"
save
if ! CUPBOP_BIG_STACK=$STRIDE rebuild bigstack "$@"; then
  echo "--- [stack] software-stack rebuild failed ($B/bigstack.*.log): keeping the hardware-stack build"; restore; return 0
fi
read NEW NEWALL <<< "$(maxf $OVER)"
if [ "$NEWALL" -gt $((BYTES - 4096)) ]; then
  echo "--- [stack] software-stack build has a $NEWALL-byte frame (> $BYTES - 4 KB): keeping the hardware-stack build"; restore; return 0
fi
echo $STRIDE > cupbop_big_stack.txt
nm -C --defined-only -g kernel.elf > lookup_global_symbols.txt 2>/dev/null
echo "--- [stack] software stack: $BYTES bytes per hardware thread, stride $STRIDE (cupbop_big_stack.txt)"
}

# --- B. sp skew modulus that fits the frame (CUPBOP_SP_SKEW)
# C(B) of cupbop_dyn_stack.txt ("thresholds B:C ..."; 0 below the first point and for B < 0)
skew_c() { awk -v B=$1 '$1 == "thresholds" { c = 0; for (i = 2; i <= NF; i++) { split($i, a, ":"); if (B >= a[1] + 0) c = a[2] } print c + 0 }' cupbop_dyn_stack.txt; }
skew_fit() {
  local M STEP F NEW WHY RT OLDC SMAX MAXBS NS C8 C4 C2 DEFS
  M=$(sed -n 's/^#define __CUPBOP_SP_SKEW_M \([0-9][0-9]*\).*/\1/p' kernel_wrapper.cpp 2>/dev/null)
  [ -n "$M" ] && [ "$M" -gt 1 ] || return 0
  STEP=$(sed -n 's/^#define __CUPBOP_SP_SKEW_STEP \([0-9][0-9]*\).*/\1/p' kernel_wrapper.cpp)
  F=$(python3 $HERE/stack_frames.py kernel.dump | awk 'NR==1{print $1+0}'); F=${F:-0}
  NEW=$M; WHY="largest frame $F bytes + ($M-1) x $STEP > $LIM"
  while [ $NEW -gt 1 ] && [ $((F + (NEW - 1) * STEP)) -gt $LIM ]; do NEW=$((NEW / 2)); done
  # Run-time sized allocas (the core-mapping context arrays kept on the stack: alloca <ty>, i64 %n slots) are not in
  # the static frame and their size is known only at launch: with M = 8 on top of them CUTLASS basic_gemm s1p1
  # (624 B frame + 4.7 KB of arrays at 256 threads, 1 warp) and prod curlcurl s1p2 (3568 B + 105 arrays) overflowed
  # the 8 KB stack. The translator (generate_wrapper.cpp describe_dyn_stack) evaluates their bytes for every legal
  # launch (block_size <= max_block, P CTA warps) into cupbop_dyn_stack.txt:
  #  * static_max: the worst case. If largest frame + that still allows the modulus above, it stays an immediate mask
  #    (no run-time code; the same kernel_main as without such allocas).
  #  * thresholds: C(B), the largest C with dyn <= B for every launch with block_size <= C x P. For each level M' in
  #    {8, 4, 2} up to the modulus above, B = limit - frame - (M'-1) x STEP; the C values go into kernel_wrapper.cpp
  #    (__CUPBOP_SP_SKEW_C8/_C4/_C2/_MAXBS after the M line) and kernel_main takes per launch the largest M' whose test
  #    block_size <= C_M' x P holds, else 1 (the M line stays the static bound).
  #  * helper none (an array size it could not recompute) or no level ever fits: M = 1.
  # Without kernel.ll any variable sp decrement in the dump counts as such an alloca (M = 1).
  RT=0; DEFS=
  if { [ -f kernel.ll ] && grep -q -E '= alloca [^,]+, i(32|64) %' kernel.ll; } ||
     { [ ! -f kernel.ll ] && grep -q -P '\tsub\tsp, sp, ' kernel.dump; }; then
    SMAX=$(sed -n 's/^static_max \([0-9][0-9]*\)$/\1/p' cupbop_dyn_stack.txt 2>/dev/null)
    MAXBS=$(sed -n 's/^max_block \([0-9][0-9]*\)$/\1/p' cupbop_dyn_stack.txt 2>/dev/null)
    if [ $NEW -gt 1 ] && [ -f kernel.ll ] && [ -n "$SMAX" ] && [ -n "$MAXBS" ] && grep -q '^thresholds' cupbop_dyn_stack.txt; then
      NS=$NEW; while [ $NS -gt 1 ] && [ $((F + SMAX + (NS - 1) * STEP)) -gt $LIM ]; do NS=$((NS / 2)); done
      C8=$(skew_c $((LIM - F - 7 * STEP))); C4=$(skew_c $((LIM - F - 3 * STEP))); C2=$(skew_c $((LIM - F - STEP)))
      if [ $NS = $NEW ]; then
        WHY="run-time sized allocas on the stack fit every launch (frame $F + at most $SMAX bytes + ($NEW-1) x $STEP <= $LIM)"
      elif [ "$C2" -gt 0 ]; then
        RT=1; DEFS="#define __CUPBOP_SP_SKEW_FRAME $F /* + run-time arrays + (M-1) x STEP <= $LIM */"
        [ $NEW -gt 4 ] && DEFS="$DEFS\n#define __CUPBOP_SP_SKEW_C8 $C8"
        [ $NEW -gt 2 ] && DEFS="$DEFS\n#define __CUPBOP_SP_SKEW_C4 $C4"
        DEFS="$DEFS\n#define __CUPBOP_SP_SKEW_C2 $C2\n#define __CUPBOP_SP_SKEW_MAXBS $MAXBS"
        WHY="run-time sized allocas on the stack (frame $F + up to $SMAX bytes): modulus <= $NEW chosen at launch, block_size <= C x CTA warps with C8/C4/C2 = $C8/$C4/$C2 (max block $MAXBS)"
      else
        WHY="run-time sized allocas on the stack (frame $F + at least the arrays of a 1-thread block exceed $LIM - $STEP)"; NEW=1
      fi
    elif [ $NEW -gt 1 ]; then
      WHY="run-time sized allocas on the stack (frame $F bytes + launch-time arrays; $(sed -n 's/^helper //p' cupbop_dyn_stack.txt 2>/dev/null | head -1))"
      NEW=1
    fi
  fi
  OLDC=$(grep '^#define __CUPBOP_SP_SKEW_\(FRAME\|C[842]\|MAXBS\) ' kernel_wrapper.cpp)
  if [ $NEW = $M ] && [ "$OLDC" = "$(printf "$DEFS")" ]; then
    [ $RT = 0 ] && [ $NEW -gt 1 ] && [ "$WHY" != "${WHY#run-time}" ] && echo "--- [stack] sp skew: $WHY"
    return 0
  fi
  echo "--- [stack] sp skew: $WHY; rebuilding with skew modulus $NEW$([ $RT = 1 ] && echo ' (upper bound)')"
  mkdir -p $B
  sed -i -e "s/^#define __CUPBOP_SP_SKEW_M .*/#define __CUPBOP_SP_SKEW_M $NEW/" \
         -e '/^#define __CUPBOP_SP_SKEW_\(FRAME\|C[842]\|MAXBS\) /d' kernel_wrapper.cpp
  [ $RT = 1 ] && sed -i "/^#define __CUPBOP_SP_SKEW_M /a $DEFS" kernel_wrapper.cpp
  rm -f $CELL/kernel.elf $CELL/kernel.vxbin $CELL/kernel.dump
  if ! $MAKE -C $CELL kernel.vxbin kernel.dump "$@" > $B/skew.rebuild.log 2>&1; then
    echo "--- [stack] sp-skew rebuild failed ($B/skew.rebuild.log)"; rm -f kernel.elf kernel.vxbin kernel.dump; return 1
  fi
  cp $CELL/kernel.elf $CELL/kernel.vxbin $CELL/kernel.dump .
  skew_fit "$@"   # the kernel frames do not depend on M or the defines; this only confirms it
}

# --- C. kernel ABI check (CUPBOP_KABI)
abi_gate() {
  [ -f cupbop_kabi.txt ] || return 0
  if python3 $HERE/abi_check.py kernel.dump cupbop_kabi.txt > abi_check.log 2>&1; then
    echo "--- [abi] $(tail -1 abi_check.log)"
    return 0
  fi
  cat abi_check.log
  echo "--- [abi] the kernel ABI calls are not safe (abi_check.log): build failed; CUPBOP_KABI=0 builds with the ordinary ABI"
  rm -f kernel.elf kernel.vxbin kernel.dump
  return 1
}

frame_fallback "$@"
skew_fit "$@" || exit 1
abi_gate || exit 1
exit 0
