#!/bin/bash
#SBATCH -J multi-module-test
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash3
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH -t 00:30:00
#SBATCH -o ci/logs_v3/multi_module_test_%j.out
# Several kernel modules in one process (examples/multi_module_test): the three orders must print PASSED. A symbol address of one
# module must not reach another module's image, and a module's __device__ values must come back with it. Optional
# OLD_CUPBOP=<CuPBoP tree with a build>: the same program on that tree's runtime is expected to fail, i.e. the test can tell.
export CuPBoP_PATH=$SLURM_SUBMIT_DIR
SIF=/projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif
apptainer exec -B /projects/ci-runners,/net/netscratch,/nethome $SIF /bin/bash <<'INNER'
set -u
cd $CuPBoP_PATH && source ./ci/rg-ci-setup-v3.sh
mkdir -p ci/logs_v3
cupbop_v3_ensure_simx $VORTEX_PATH "$VORTEX_CONFIGS" > /dev/null || { echo "SIMX BUILD FAILED"; exit 1; }
if [ ! -x build/compilation/kernelTranslator ]; then
  XCFG=$(python3 $VORTEX_HOME/ci/gen_config.py --config=$VORTEX_HOME/VX_config.toml --cflags="$VORTEX_CONFIGS -DVX_CFG_XLEN=64")
  mkdir -p build && ( cd build && cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$XCFG" > cmake.log 2>&1 ) || { echo "CMAKE FAILED"; exit 1; }
fi
make -C build kernelTranslator hostTranslator vortexRuntime ThreadPool -j8 > ci/logs_v3/multi_module_test_build_$SLURM_JOB_ID.log 2>&1 || { echo BUILD FAILED; grep -n error ci/logs_v3/multi_module_test_build_$SLURM_JOB_ID.log | head; exit 1; }
OUT=$CuPBoP_PATH/ci/logs_v3/multi_module_test_$SLURM_JOB_ID; mkdir -p $OUT
cd examples/multi_module_test
make clean > /dev/null 2>&1
make ci > $OUT/new.log 2>&1
cp -f ci_output.txt $OUT/new.out 2>/dev/null
grep -h '^multi_module_test ' $OUT/new.out || echo "NO RESULT (see $OUT/new.log)"
if [ -n "${OLD_CUPBOP:-}" ]; then
  make ci RT_LIB=$OLD_CUPBOP/build/runtime > $OUT/old.log 2>&1
  cp -f ci_output.txt $OUT/old.out 2>/dev/null
  echo "old runtime (a failure is expected): $(grep -c '^multi_module_test .*PASSED' $OUT/old.out) of 3 orders PASSED; $(grep -m1 -h 'Illegal\|misaligned\|FAILED' $OUT/old.out)"
fi
make clean > /dev/null 2>&1
INNER
