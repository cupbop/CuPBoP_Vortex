#!/bin/bash
#SBATCH -J lift-test
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash[1-4]
#SBATCH -N 1
#SBATCH -c 8
#SBATCH --mem=48G
#SBATCH -t 00:30:00
#SBATCH -o ci/logs_v3/lift_test_%j.out
# Lift tests (examples/lift_*, rows of ci/lift_cases.txt, runner ci/lift_test.sh) as one Slurm job, 3 to 5 minutes on 8 cores after the translators are built. Submit from the repository root:
#   sbatch ci/lift_test.sbatch                                  # needs the two SimX drivers of ci/rg-ci-setup-v3.sh; builds what is missing
#   sbatch --export=ALL,PAR=16,ROWS='hg_.*|sg_.*' ci/lift_test.sbatch
# The job fails when a row does not get what the table says.
export CuPBoP_PATH=${SLURM_SUBMIT_DIR:-$PWD} ROWS=${ROWS:-.}
SIF=/projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif
apptainer exec -B /projects/ci-runners${CI_EXTRA_BINDS:+,$CI_EXTRA_BINDS} $SIF /bin/bash <<'INNER'
set -u
cd $CuPBoP_PATH && source ./ci/rg-ci-setup-v3.sh
mkdir -p ci/logs_v3
cupbop_v3_ensure_simx $VORTEX_PATH "$VORTEX_CONFIGS" > /dev/null || { echo "SIMX BUILD FAILED"; exit 1; }
cupbop_v3_ensure_simx $VORTEX_PATH_TCU "$VORTEX_CONFIGS_TCU" > /dev/null || { echo "SIMX (TCU/DXA) BUILD FAILED"; exit 1; }
if [ ! -x build/compilation/kernelTranslator ]; then
  XCFG=$(python3 $VORTEX_HOME/ci/gen_config.py --config=$VORTEX_HOME/VX_config.toml --cflags="$VORTEX_CONFIGS -DVX_CFG_XLEN=64")
  mkdir -p build && ( cd build && cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$XCFG" > cmake.log 2>&1 ) || { echo "CMAKE FAILED"; exit 1; }
fi
make -C build kernelTranslator hostTranslator vortexRuntime ThreadPool -j${SLURM_CPUS_PER_TASK:-8} > ci/logs_v3/lift_test_build_${SLURM_JOB_ID:-manual}.log 2>&1 || { echo "BUILD FAILED"; grep -n error ci/logs_v3/lift_test_build_${SLURM_JOB_ID:-manual}.log | head; exit 1; }
PAR=${PAR:-${SLURM_CPUS_PER_TASK:-8}} ./ci/lift_test.sh "${ROWS:-.}"
INNER
