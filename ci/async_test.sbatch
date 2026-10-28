#!/bin/bash
#SBATCH -J async-test
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash3
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH -t 01:30:00
#SBATCH -o ci/logs_v3/async_test_%j.out
# Async PTX in software mode (lower_async_ptx; mbarrier, TMA, bulk copy): examples/async_* (the async design
# corpus with host programs and CPU references) must PASS on the 1:1 schedule and on a de facto 1:1 core
# mapping, and be refused on the flat schedule (translation), on a real core mapping (launch) and for the §5.3
# cases the translator cannot order (an arrive.expect_tx with a wait before its copy, or whose copy another
# thread issues). The control run (CUPBOP_ASYNC_NO_MOVE=1: the arrive is not moved after the copy) must FAIL,
# i.e. the test can tell.
export CuPBoP_PATH=$SLURM_SUBMIT_DIR
SIF=/projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif
apptainer exec -B /projects/ci-runners,/net/netscratch,/nethome $SIF /bin/bash <<'INNER'
set -u
cd $CuPBoP_PATH && source ./ci/rg-ci-setup-v3.sh
export VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}   # a deadlocked barrier aborts the run instead of spinning
mkdir -p ci/logs_v3
cupbop_v3_ensure_simx $VORTEX_PATH "$VORTEX_CONFIGS" > /dev/null || { echo "SIMX BUILD FAILED"; exit 1; }
if [ ! -x build/compilation/kernelTranslator ]; then
  XCFG=$(python3 $VORTEX_HOME/ci/gen_config.py --config=$VORTEX_HOME/VX_config.toml --cflags="$VORTEX_CONFIGS -DVX_CFG_XLEN=64")
  mkdir -p build && ( cd build && cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$XCFG" > cmake.log 2>&1 ) || { echo "CMAKE FAILED"; exit 1; }
fi
make -C build kernelTranslator hostTranslator vortexRuntime ThreadPool -j8 > ci/logs_v3/async_test_build_$SLURM_JOB_ID.log 2>&1 || { echo BUILD FAILED; grep -n error ci/logs_v3/async_test_build_$SLURM_JOB_ID.log | head; exit 1; }
OUT=$CuPBoP_PATH/ci/logs_v3/async_test_$SLURM_JOB_ID; mkdir -p $OUT
run() { # tag example sched [make vars...]
  local tag=$1 ex=$2 sched=$3; shift 3
  ( cd examples/$ex && make clean > /dev/null 2>&1; rm -f ci_output.txt cupbop_async_kernels.txt
    make ci SCHEDULE=$sched "$@" > $OUT/$tag.log 2>&1; cp -f ci_output.txt $OUT/$tag.out 2>/dev/null )
}
expect_pass() { run "$@"; grep -q '^PASSED!' $OUT/$1.out 2>/dev/null && echo "$1: PASS" || echo "$1: FAIL (unexpected; see $OUT/$1.log)"; }
expect_fail() { run "$@"; grep -q '^PASSED!' $OUT/$1.out 2>/dev/null && echo "$1: PASSED (unexpected: the control should fail)" || echo "$1: FAIL (expected)"; }
expect_refused() { # tag pattern example sched [make vars...]
  local tag=$1 pat=$2; shift 2
  run $tag "$@"; grep -q "$pat" $OUT/$tag.log $OUT/$tag.out 2>/dev/null && echo "$tag: REFUSED (expected)" || echo "$tag: NOT REFUSED (unexpected)"
}
for ex in async_mbar_ws async_tma2d async_bulk1d async_tma_store async_cpasync_mbar async_misc; do
  expect_pass s2_$ex $ex 2
done
expect_pass    s2_async_mbar_ws_nolto async_mbar_ws 2 CUPBOP_LTO=0
expect_pass    s1_async_mbar_ws  async_mbar_ws 1        # CUPBOP_VIRT_WARPS unset: one physical warp per CUDA warp
expect_pass    s1_async_tma2d    async_tma2d 1
expect_refused s1v1_async_mbar_ws 'uses mbarrier waits' async_mbar_ws 1 CUPBOP_VIRT_WARPS=1
expect_refused s0_async_mbar_ws   'only supported on the 1:1 schedule' async_mbar_ws 0
expect_refused s0_async_tma2d     'only supported on the 1:1 schedule' async_tma2d 0
expect_refused s2_neg_wait_before_copy '5.3)' async_tma2d 2 EXTRA_CLANG_FLAGS=-DASYNC_NEG_WAIT_BEFORE_COPY
expect_refused s2_neg_other_thread     '5.3)' async_tma2d 2 EXTRA_CLANG_FLAGS=-DASYNC_NEG_OTHER_THREAD
expect_fail    s2_control_no_move async_tma2d 2 CUPBOP_ASYNC_NO_MOVE=1
INNER
