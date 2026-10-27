#!/bin/bash
#SBATCH -J named-barrier-test
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash3
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH -t 01:00:00
#SBATCH -o ci/logs_v3/named_barrier_test_%j.out
# PTX named barriers (bar.sync / bar.arrive with a thread count; lower_named_barriers): examples/named_barrier_test
# must PASS on the 1:1 schedule (asm and llvm.nvvm.barrier.sync.cnt forms, with and without LTO) and be refused at
# translation on the core-mapping and flat schedules. Optional OLD_CUPBOP=<CuPBoP tree with a build>: the same
# example translated by that tree (which drops the barrier asm) is expected to FAIL, i.e. the test can tell.
export CuPBoP_PATH=$SLURM_SUBMIT_DIR
SIF=/projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif
apptainer exec -B /projects/ci-runners,/net/netscratch,/nethome $SIF /bin/bash <<'INNER'
set -u
cd $CuPBoP_PATH && source ./ci/rg-ci-setup-v3.sh
export VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-180}   # a deadlocked barrier aborts the run instead of spinning
mkdir -p ci/logs_v3
if [ ! -x build/compilation/kernelTranslator ]; then
  XCFG=$(python3 $VORTEX_HOME/ci/gen_config.py --config=$VORTEX_HOME/VX_config.toml --cflags="$VORTEX_CONFIGS -DVX_CFG_XLEN=64")
  mkdir -p build && ( cd build && cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$XCFG" > cmake.log 2>&1 ) || { echo "CMAKE FAILED"; exit 1; }
fi
make -C build kernelTranslator hostTranslator vortexRuntime ThreadPool -j8 > ci/logs_v3/named_barrier_test_build_$SLURM_JOB_ID.log 2>&1 || { echo BUILD FAILED; grep -n error ci/logs_v3/named_barrier_test_build_$SLURM_JOB_ID.log | head; exit 1; }
OUT=$CuPBoP_PATH/ci/logs_v3/named_barrier_test_$SLURM_JOB_ID; mkdir -p $OUT
run() { # tag sched [make vars...]
  local tag=$1 sched=$2; shift 2
  ( cd examples/named_barrier_test && make clean > /dev/null 2>&1; rm -f ci_output.txt
    make ci SCHEDULE=$sched "$@" > $OUT/$tag.log 2>&1; cp -f ci_output.txt $OUT/$tag.out 2>/dev/null )
}
expect_pass() { run "$@"; echo "$1: $(grep -h -o 'named_barrier_test: .*' $OUT/$1.out 2>/dev/null || echo 'NO RESULT (see log)')"; }
expect_refused() { run "$@"; grep -q 'only supported on the 1:1 schedule' $OUT/$1.log && echo "$1: REFUSED (expected)" || echo "$1: NOT REFUSED (unexpected)"; }
expect_pass    s2_asm      2
expect_pass    s2_asm_nolto 2 CUPBOP_LTO=0
expect_pass    s2_builtin  2 EXTRA_CLANG_FLAGS=-DNBAR_BUILTIN
expect_refused s1_refused  1
expect_refused s0_refused  0
if [ -n "${OLD_CUPBOP:-}" ]; then
  expect_pass s2_old_translator 2 CuPBoP_PATH=$OLD_CUPBOP
  grep -h -m1 'unknown PTX InlineAsm: bar' $OUT/s2_old_translator.log | cut -c1-120
fi
INNER
