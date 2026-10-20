#!/bin/bash
# Port of the "Verify Correctness" step of .github/workflows/ci.yml, usable outside GitHub Actions.
#   usage: ci/check_correctness.sh <test> <schedule> <localmem>   (run from the repository root)
# Prints "RESULT=PASS|FAIL|SKIP" and writes examples/<test>/ci_status_SCHE_<s>_LMEM_<l>.txt
TEST_NAME=$1; SCHEDULE=$2; LMEM=$3
EXAMPLE_DIR="./examples/${TEST_NAME}"
CI_OUTPUT="${EXAMPLE_DIR}/ci_output.txt"
STATUS_FILE="${EXAMPLE_DIR}/ci_status_SCHE_${SCHEDULE}_LMEM_${LMEM}.txt"
RESULT="FAIL"
cmp_golden() { python3 ./ci/compare_golden.py "$1" "$2" --tolerance=1e-4 > /dev/null 2>&1; }
case $TEST_NAME in
  saxpy|sgemm|sgemm_tcu|sgemm_dxa|sgemm_tcu_dxa|psum|conv3|dotproduct|vecadd|stencil|transpose|atomic_test|bh-cuda|blackscholes|cc-cuda|cfd|huffman|jaccard-cuda|lud|marchingCubes-cuda|psort|score-cuda|sfilter|spmv|wedford-cuda)
    if [ -f "$CI_OUTPUT" ] && grep -q "PASSED" "$CI_OUTPUT" && ! grep -q "^FAIL" "$CI_OUTPUT"; then RESULT="PASS"; fi ;;
  backprop|nn|pathfinder|gauss|srad_v2|jacobi-cuda)
    G="${EXAMPLE_DIR}/golden_output.txt"
    [ -f "$G" ] && [ -f "$CI_OUTPUT" ] && cmp_golden "$G" "$CI_OUTPUT" && RESULT="PASS" ;;
  nw)
    G="${EXAMPLE_DIR}/golden_result_nw.txt"; R="${EXAMPLE_DIR}/result_vortex.txt"
    [ -f "$G" ] && [ -f "$R" ] && diff -q "$G" "$R" > /dev/null 2>&1 && RESULT="PASS" ;;
  hotspot)
    G="${EXAMPLE_DIR}/golden_output_hotspot.txt"; R="${EXAMPLE_DIR}/output.out"
    [ -f "$G" ] && [ -f "$R" ] && cmp_golden "$G" "$R" && RESULT="PASS" ;;
  bfs)
    G="${EXAMPLE_DIR}/golden_result_bfs.txt"; R="${EXAMPLE_DIR}/result_vortex.txt"
    [ -f "$G" ] && [ -f "$R" ] && diff -q "$G" "$R" > /dev/null 2>&1 && RESULT="PASS" ;;
  streamcluster)
    G="${EXAMPLE_DIR}/golden_result_streamcluster.txt"; R="${EXAMPLE_DIR}/output.txt"
    [ -f "$G" ] && [ -f "$R" ] && cmp_golden "$G" "$R" && RESULT="PASS" ;;
  btree)
    G="${EXAMPLE_DIR}/golden_result_btree.txt"; R="${EXAMPLE_DIR}/output.txt"
    [ -f "$G" ] && [ -f "$R" ] && diff -q "$G" "$R" > /dev/null 2>&1 && RESULT="PASS" ;;
  *) RESULT="SKIP" ;;
esac
echo "$RESULT" > "$STATUS_FILE"
echo "RESULT=$RESULT"
