#!/bin/bash
# Correctness check of one CI matrix entry: the single source of truth used by the "Verify Correctness" step of
# .github/workflows/ci.yml and by ci/run-v3-matrix.sbatch.
#   usage: ci/check_correctness.sh <test> <schedule> <localmem>      (run from the repository root)
# Prints "Correctness: PASS|FAIL|SKIP" (with the reason and the tail of the output on FAIL) and a final
# "RESULT=..." line, writes examples/<test>/ci_status_SCHE_<s>_LMEM_<l>.txt and exits 1 on FAIL.
TEST_NAME=$1; SCHEDULE=$2; LMEM=$3
EXAMPLE_DIR="${CI_EXAMPLE_DIR:-./examples/${TEST_NAME}}"   # CI_EXAMPLE_DIR: check a copy of the example elsewhere (coadapt trials)
CI_OUTPUT="${EXAMPLE_DIR}/ci_output.txt"
STATUS_FILE="${EXAMPLE_DIR}/ci_status_SCHE_${SCHEDULE}_LMEM_${LMEM}.txt"
RESULT="FAIL"; WHY=""; G=""; R=""

check_marker() { # <marker>: the program's own verdict in ci_output.txt and no line starting with FAIL
  if [ ! -f "$CI_OUTPUT" ]; then WHY="$CI_OUTPUT missing"
  elif ! grep -q "$1" "$CI_OUTPUT"; then WHY="'$1' not found in $CI_OUTPUT"
  elif grep -q "^FAIL" "$CI_OUTPUT"; then WHY="FAIL line in $CI_OUTPUT"
  else RESULT="PASS"; fi
}
check_golden() { # <golden> <result>: ci/compare_golden.py, tolerance 1e-4
  G=$1; R=$2
  if [ ! -f "$G" ] || [ ! -f "$R" ]; then WHY="golden ($G) or result ($R) missing"
  elif python3 ./ci/compare_golden.py "$G" "$R" --tolerance=1e-4; then RESULT="PASS"
  else WHY="compare_golden.py: $R differs from $G"; fi
}
check_bits() { # after a PASS: the bit record of the device-to-host copies against group $LIFT_BITS_GROUP of the example's lift_bits.txt ("-": no record for this row)
  [ "$RESULT" = PASS ] && [ -n "${LIFT_BITS_GROUP:-}" ] && [ "$LIFT_BITS_GROUP" != - ] && [ -z "${LIFT_BITS_RECORD:-}" ] || return 0
  local want got f="${EXAMPLE_DIR}/lift_d2h.txt"
  want=$(sed -n "s/^$LIFT_BITS_GROUP //p" "${EXAMPLE_DIR}/lift_bits.txt" 2>/dev/null)
  [ -f "$f" ] && got="$(cksum < "$f" | cut -d' ' -f1)-$(wc -l < "$f")-$(sha1sum < "$f" | cut -c1-16)" || got=none
  [ "$got" = "$want" ] || { RESULT=FAIL; WHY="bit record $got, group $LIFT_BITS_GROUP wants ${want:-nothing}"; }
}
check_cta_loop() { # after a PASS: the translation has the block loop at schedule 2 and at no other, and not for the kernels that wait for another block. Not checked when a run asks for something else
  [ "$RESULT" = PASS ] && [ -z "${CUPBOP_CTA_LOOP_S1:-}" ] && case "${CUPBOP_CTA_LOOP:-auto}" in off|0) false ;; esac || return 0
  local f="${EXAMPLE_DIR}/cupbop_launch_fix.txt" n; n=$(cat "$f" 2>/dev/null | grep -c ' cta_dims=')
  if [ "$SCHEDULE" = 2 ] && [ "$n" = 0 ]; then RESULT=FAIL; WHY="schedule 2 without the block loop"
  elif [ "$SCHEDULE" != 2 ] && [ "$n" != 0 ]; then RESULT=FAIL; WHY="block loop at schedule $SCHEDULE"
  elif grep -qE 'k_spin|k_ticket_spin' "$f" 2>/dev/null; then RESULT=FAIL; WHY="block loop in a kernel that must be refused"; fi
}
check_diff() { # <golden> <result>: exact match
  G=$1; R=$2
  if [ ! -f "$G" ] || [ ! -f "$R" ]; then WHY="golden ($G) or result ($R) missing"
  elif diff -q "$G" "$R" > /dev/null 2>&1; then RESULT="PASS"
  else WHY="$R differs from $G"; fi
}

case $TEST_NAME in
  simt_shape_test|mufu_approx|saxpy|struct_arg_test|mma884_test|launch_name_test|cp_async_test|cp_async_pipe|cp_async_asm|dxa_desc_test|async_*|sgemm|sgemm_tcu|sgemm_dxa|sgemm_tcu_dxa|sgemm_wgmma|sgemm_wgmma_dxa|sgemm_wgmma_bf16|sgemm_tcu_bf16|tcu_dt_*|psum|conv3|dotproduct|vecadd|stencil|transpose|atomic_test|bh-cuda|blackscholes|cc-cuda|cfd|jaccard-cuda|lud|marchingCubes-cuda|psort|score-cuda|sfilter|spmv|wedford-cuda|mmafuse_test)
    check_marker "PASSED" ;;
  s1_arm_test)
    check_marker "PASSED" ;;
  cta_loop_test)
    check_marker "PASSED"; check_cta_loop ;;
  huffman)  # its checker (comparison_helpers.h) prints "PASS! vectors are matching!" / "FAIL! vectors are NOT matching!", never "PASSED"
    check_marker "PASS! vectors are matching" ;;
  backprop|nn|pathfinder|gauss|srad_v2|jacobi-cuda|virt_warp_test|virt_ldsm_test)
    check_golden "${EXAMPLE_DIR}/golden_output.txt" "$CI_OUTPUT" ;;
  nw)
    check_diff "${EXAMPLE_DIR}/golden_result_nw.txt" "${EXAMPLE_DIR}/result_vortex.txt" ;;
  hotspot)
    check_golden "${EXAMPLE_DIR}/golden_output_hotspot.txt" "${EXAMPLE_DIR}/output.out" ;;
  bfs)
    check_diff "${EXAMPLE_DIR}/golden_result_bfs.txt" "${EXAMPLE_DIR}/result_vortex.txt" ;;
  streamcluster)
    check_golden "${EXAMPLE_DIR}/golden_result_streamcluster.txt" "${EXAMPLE_DIR}/output.txt" ;;
  btree)
    check_diff "${EXAMPLE_DIR}/golden_result_btree.txt" "${EXAMPLE_DIR}/output.txt" ;;
  lift_nn|lift_backprop)   # lift examples (examples/lift.mk, ci/lift_test.sh): as the source example, plus the bit record
    check_golden "${EXAMPLE_DIR}/golden_output.txt" "$CI_OUTPUT"; check_bits ;;
  lift_hotspot)
    check_golden "${EXAMPLE_DIR}/golden_output_hotspot.txt" "${EXAMPLE_DIR}/output.out"; check_bits ;;
  lift_*)
    check_marker "PASSED"; check_bits ;;
  *)
    RESULT="SKIP"; WHY="no correctness check defined for $TEST_NAME" ;;
esac

echo "$RESULT" > "$STATUS_FILE"
echo "Correctness: $RESULT${WHY:+ ($WHY)}"
if [ "$RESULT" = "FAIL" ]; then
  if [ -f "$CI_OUTPUT" ]; then echo "--- tail of $CI_OUTPUT:"; tail -20 "$CI_OUTPUT"; fi
  if [ -n "$G" ] && [ -f "$G" ] && [ -f "$R" ]; then echo "--- diff $G $R (first 20 lines):"; diff "$G" "$R" | head -20; fi
fi
echo "RESULT=$RESULT"
[ "$RESULT" != "FAIL" ]
