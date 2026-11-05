#!/bin/bash
#SBATCH -J determinism-test
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash[1-4]
#SBATCH -N 1
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH -t 00:20:00
#SBATCH -o ci/logs_v3/determinism_test_%j.out
# ci/determinism_test.sh as one Slurm job, about two minutes on 8 cores after the translator is built. Submit from the repository root: sbatch ci/determinism_test.sbatch
export CuPBoP_PATH=${SLURM_SUBMIT_DIR:-$PWD}
SIF=/projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif
apptainer exec -B /projects/ci-runners${CI_EXTRA_BINDS:+,$CI_EXTRA_BINDS} $SIF /bin/bash <<'INNER'
set -u
cd $CuPBoP_PATH && source ./ci/rg-ci-setup-v3.sh
mkdir -p ci/logs_v3
if [ ! -x build/compilation/kernelTranslator ]; then
  XCFG=$(python3 $VORTEX_HOME/ci/gen_config.py --config=$VORTEX_HOME/VX_config.toml --cflags="$VORTEX_CONFIGS -DVX_CFG_XLEN=64")
  mkdir -p build && ( cd build && cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$XCFG" > cmake.log 2>&1 ) || { echo "CMAKE FAILED"; exit 1; }
fi
make -C build kernelTranslator -j${SLURM_CPUS_PER_TASK:-8} > ci/logs_v3/determinism_build_${SLURM_JOB_ID:-manual}.log 2>&1 || { echo "BUILD FAILED"; exit 1; }
PAR=${PAR:-${SLURM_CPUS_PER_TASK:-8}} ./ci/determinism_test.sh
INNER
