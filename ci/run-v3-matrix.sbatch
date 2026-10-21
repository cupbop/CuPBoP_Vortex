#!/bin/bash
#SBATCH -J cupbop-v3-ci
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash3
#SBATCH -c 16
#SBATCH --mem=64G
#SBATCH -t 04:00:00
#SBATCH -o ci/logs_v3/matrix_%j.out
# The ci.yml matrix (35 examples x SCHE 2/0, minus TCU/DXA at SCHE_0, plus 10 LOCALMEM=0 entries = 77 runs) on
# Vortex 3.0 as ONE Slurm job, with the same environment (ci/rg-ci-setup-v3.sh), build steps (ci/run-crnch-cuda.sh)
# and checker (ci/check_correctness.sh) as the GitHub workflow. Submit from the repository root:
#   sbatch --export=ALL,PAR=6 ci/run-v3-matrix.sbatch                     # whole matrix, 6 examples in parallel
#   sbatch --export=ALL,TESTS="vecadd saxpy" ci/run-v3-matrix.sbatch       # subset
# Override VORTEX_HOME / TOOLDIR / VORTEX_CONFIGS with --export to test another tree or configuration.
# Results: ci/logs_v3/run_<jobid>/results.csv plus one log per run; a summary is printed at the end of the job log.
set -u
export PATH=$HOME/.local/bin:/usr/bin:/bin:/usr/local/bin
export CuPBoP_PATH=$SLURM_SUBMIT_DIR
export TESTS=${TESTS:-"backprop dotproduct pathfinder psum bfs btree conv3 nn saxpy sgemm stencil transpose vecadd bh-cuda blackscholes cc-cuda cfd gauss hotspot huffman jaccard-cuda jacobi-cuda lud marchingCubes-cuda nw psort score-cuda sfilter spmv srad_v2 streamcluster wedford-cuda sgemm_tcu sgemm_dxa sgemm_tcu_dxa"}
export PAR=${PAR:-4}
export RUN_TAG=${SLURM_JOB_ID:-manual}
SIF=/projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif
echo "start $(date) host=$(hostname) repo=$CuPBoP_PATH tests=[$TESTS] par=$PAR"
apptainer exec -B /projects/ci-runners,/net/netscratch,/nethome $SIF /bin/bash <<'INNER'
set -u
cd $CuPBoP_PATH
source ./ci/rg-ci-setup-v3.sh
LOGS=$CuPBoP_PATH/ci/logs_v3/run_$RUN_TAG; mkdir -p $LOGS
echo "inside: $(head -1 /etc/os-release) clang=$(clang --version | head -1 | cut -c1-40) cuda=$(ls $CUDA_PATH/include/cuda_runtime.h 2>/dev/null && echo ok)"
echo "vortex: $VORTEX_HOME ($(git -C $VORTEX_HOME describe --tags --always 2>/dev/null)) tooldir: $TOOLDIR configs: $VORTEX_CONFIGS"
# --- build CuPBoP (translators + host runtime), same steps as ci/run-crnch-cuda.sh ---
XCFG=$(python3 $VORTEX_HOME/ci/gen_config.py --config=$VORTEX_HOME/VX_config.toml --cflags="$VORTEX_CONFIGS -DVX_CFG_XLEN=64")
rm -rf build && mkdir build && cd build
cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$XCFG" > cmake.log 2>&1 || { echo "CMAKE FAILED"; tail -15 cmake.log; exit 1; }
make -j${SLURM_CPUS_PER_TASK:-8} kernelTranslator hostTranslator vortexRuntime ThreadPool > make.log 2>&1 || { echo "BUILD FAILED"; grep -n "error" make.log | head -10 | cut -c1-200; exit 1; }
cd $CuPBoP_PATH; echo "cupbop built $(date +%H:%M:%S)"
# --- SimX drivers: main config, plus the TCU+DXA config for the tensor examples (rebuilt when the recorded config differs)
cupbop_v3_ensure_simx $VORTEX_PATH "$VORTEX_CONFIGS" || exit 1
cupbop_v3_ensure_simx $VORTEX_PATH_TCU "$VORTEX_CONFIGS_TCU" || exit 1
echo "simx ready $(date +%H:%M:%S)"
# --- matrix ---
RES=$LOGS/results.csv; echo "test,schedule,localmem,make_rc,kernel_ok,host_ok,exec_ok,result,seconds" > $RES
run_one() { # test sched lmem
  local t=$1 s=$2 l=$3
  local log=$LOGS/${t}_s${s}_l${l}.log t0=$SECONDS   # separate line: a single `local` expands ${s} before assigning it
  ( cd examples && make -C $t clean > /dev/null 2>&1; rm -f $t/ci_status_*.txt $t/ci_output.txt
    timeout 1800 make -C $t ci SCHEDULE=$s LOCALMEM=$l > $log 2>&1 ); local rc=$?
  local k=0 h=0 e=0; grep -q "Kernel compilation completed!" $log && k=1; grep -q "Host compilation completed!" $log && h=1; grep -q "Execution completed!" $log && e=1
  local r; r=$(./ci/check_correctness.sh $t $s $l 2>&1 | tee -a $log | sed -n 's/^RESULT=//p')
  echo "$t,$s,$l,$rc,$k,$h,$e,$r,$((SECONDS-t0))" >> $RES
  printf "%-20s sched=%s lmem=%s make=%-3s k/h/e=%s%s%s  %s  %ss\n" $t $s $l $rc $k $h $e $r $((SECONDS-t0))
}
export -f run_one; export LOGS RES
run_test() { # all configurations of one test, sequentially (shared example dir)
  local t=$1
  case $t in
    sgemm_tcu|sgemm_dxa|sgemm_tcu_dxa) export VORTEX_PATH=$VORTEX_PATH_TCU VORTEX_CONFIGS="$VORTEX_CONFIGS_TCU"; run_one $t 2 1 ;;   # SCHE_2 only (ci.yml exclude)
    *) run_one $t 2 1; run_one $t 0 1 ;;
  esac
  case $t in bh-cuda|cc-cuda|hotspot|jaccard-cuda|jacobi-cuda|marchingCubes-cuda|score-cuda|wedford-cuda|sgemm_dxa|sgemm_tcu_dxa) run_one $t 2 0 ;; esac   # ci.yml include: list
}
export -f run_test
echo "$TESTS" | tr ' ' '\n' | grep -v '^$' | xargs -P $PAR -I{} bash -c 'run_test {}'
echo; echo "=== summary"; python3 - "$RES" <<'PY'
import csv,sys,collections
rows=list(csv.DictReader(open(sys.argv[1])))
c=collections.Counter(r['result'] for r in rows); print("total",len(rows),dict(c))
bad=[r for r in rows if r['result']!='PASS']
for r in bad: print(f"  {r['test']:20s} s{r['schedule']} l{r['localmem']}: result={r['result']} make_rc={r['make_rc']} kernel={r['kernel_ok']} host={r['host_ok']} exec={r['exec_ok']}")
PY
INNER
echo "done $(date)"
