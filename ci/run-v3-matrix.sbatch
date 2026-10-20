#!/bin/bash
#SBATCH -J cupbop-v3-ci
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash3
#SBATCH -c 16
#SBATCH --mem=64G
#SBATCH -t 04:00:00
#SBATCH -o /net/netscratch/cahn45/Vortex_Agent/CuPBoP_Vortex/ci/logs_v3/matrix_%j.out
# CuPBoP CI matrix on Vortex 3.0, run inside the CI container (CUDA 12.1 headers for clang's CUDA frontend).
#   sbatch --export=ALL,TESTS="vecadd saxpy" ci/run-v3-matrix.sbatch   # subset; default = the ci.yml matrix
#   PAR=<n> tests in parallel (default 4); each test's schedulers run sequentially in its own example dir.
set -u
export PATH=$HOME/.local/bin:/usr/bin:/bin:/usr/local/bin
export CuPBoP_PATH=/net/netscratch/cahn45/Vortex_Agent/CuPBoP_Vortex
export TESTS=${TESTS:-"backprop dotproduct pathfinder psum bfs btree conv3 nn saxpy sgemm stencil transpose vecadd bh-cuda blackscholes cc-cuda cfd gauss hotspot huffman jaccard-cuda jacobi-cuda lud marchingCubes-cuda nw psort score-cuda sfilter spmv srad_v2 streamcluster wedford-cuda sgemm_tcu sgemm_dxa sgemm_tcu_dxa"}
export PAR=${PAR:-4}
export RUN_TAG=${SLURM_JOB_ID:-manual}
SIF=/projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif
echo "start $(date) host=$(hostname) tests=[$TESTS] par=$PAR"
apptainer exec -B /net/netscratch,/nethome,/projects/ci-runners $SIF /bin/bash <<'INNER'
set -u
cd $CuPBoP_PATH
source ./ci/rg-ci-setup-v3.sh
LOGS=$CuPBoP_PATH/ci/logs_v3/run_$RUN_TAG; mkdir -p $LOGS
echo "inside: $(head -1 /etc/os-release) clang=$(clang --version | head -1 | cut -c1-40) cuda=$(ls $CUDA_PATH/include/cuda_runtime.h 2>/dev/null && echo ok)"
# --- build CuPBoP (translators + host runtime) against LLVM 20 / Vortex 3.0 ---
XCFG=$(python3 $VORTEX_HOME/ci/gen_config.py --config=$VORTEX_HOME/VX_config.toml --cflags="$VORTEX_CONFIGS -DVX_CFG_XLEN=64")
rm -rf build && mkdir build && cd build
cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$XCFG" > cmake.log 2>&1 || { echo "CMAKE FAILED"; tail -15 cmake.log; exit 1; }
make -j16 kernelTranslator hostTranslator vortexRuntime ThreadPool > make.log 2>&1 || { echo "BUILD FAILED"; grep -n "error" make.log | head -10 | cut -c1-200; exit 1; }
cd $CuPBoP_PATH; echo "cupbop built $(date +%H:%M:%S)"
# --- SimX driver for exactly $VORTEX_CONFIGS (rebuilt when the recorded config differs) ---
MARK=$VORTEX_PATH/.cupbop_simx_configs
if [ ! -f $VORTEX_PATH/config.mk ]; then mkdir -p $VORTEX_PATH && ( cd $VORTEX_PATH && $VORTEX_HOME/configure --xlen=64 --tooldir=$TOOLDIR > /dev/null ) || { echo "configure failed"; exit 1; }; fi
if [ ! -f $VORTEX_PATH/sw/runtime/libvortex-simx.so ] || [ "$(cat $MARK 2>/dev/null)" != "$VORTEX_CONFIGS" ]; then
  echo "building SimX for: $VORTEX_CONFIGS"
  ( cd $VORTEX_PATH && make -C hw && make -C sw/kernel && make -C sw/runtime/stub && make -C sim/simx clean && make -C sw/runtime/simx clean && \
    CONFIGS="$VORTEX_CONFIGS" make -C sim/simx PERF=1 -j16 && CONFIGS="$VORTEX_CONFIGS" make -C sw/runtime/simx PERF=1 ) > $LOGS/simx_build.log 2>&1 \
    || { echo "SimX build failed"; grep -n error $LOGS/simx_build.log | head; exit 1; }
  echo "$VORTEX_CONFIGS" > $MARK; echo "simx built $(date +%H:%M:%S)"
fi
# --- matrix ---
RES=$LOGS/results.csv; echo "test,schedule,localmem,make_rc,kernel_ok,host_ok,exec_ok,result,seconds" > $RES
run_one() { # test sched lmem
  local t=$1 s=$2 l=$3
  local log=$LOGS/${t}_s${s}_l${l}.log t0=$SECONDS   # separate line: a single `local` expands ${s} before assigning it
  ( cd examples && make -C $t clean > /dev/null 2>&1; rm -f $t/ci_status_*.txt $t/ci_output.txt
    timeout 1800 make -C $t ci SCHEDULE=$s LOCALMEM=$l > $log 2>&1 ); local rc=$?
  local k=0 h=0 e=0; grep -q "Kernel compilation completed!" $log && k=1; grep -q "Host compilation completed!" $log && h=1; grep -q "Execution completed!" $log && e=1
  local r; r=$(./ci/check_correctness.sh $t $s $l | sed 's/RESULT=//')
  echo "$t,$s,$l,$rc,$k,$h,$e,$r,$((SECONDS-t0))" >> $RES
  printf "%-20s sched=%s lmem=%s make=%-3s k/h/e=%s%s%s  %s  %ss\n" $t $s $l $rc $k $h $e $r $((SECONDS-t0))
}
export -f run_one; export LOGS RES
run_test() { # all configurations of one test, sequentially (shared example dir)
  local t=$1
  case $t in sgemm_tcu|sgemm_dxa|sgemm_tcu_dxa) run_one $t 2 1 ;; *) run_one $t 2 1; run_one $t 0 1 ;; esac
  case $t in bh-cuda|cc-cuda|hotspot) run_one $t 2 0 ;; esac
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
