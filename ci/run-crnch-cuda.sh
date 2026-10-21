#!/bin/bash
#SBATCH --job-name="CuPBoP-Vortex-ci-cuda"
#SBATCH -t 00:40:00                              # CuPBoP build ~1 min + two SimX builds ~2 min each on 16 CPUs (more on a fresh tree)
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash[1-4]
#SBATCH -N 1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
# GPU not needed: CuPBoP build uses clang (RISC-V target), no CUDA runtime.
# Removing --gres=gpu:1 frees up GPU slots so more matrix jobs can run in
# parallel on the same node.
#SBATCH -o /tools/ci-reports/CuPBoP_logs/CuPBoP-cuda-test-%j.out   # Combined output and error messages file
#SBATCH -W                                       # Do not exit until the submitted job terminates.

# ci.yml "build" job on Vortex 3.0: builds the CuPBoP translators + host runtime against the Vortex LLVM 20 of
# toolchain v3.0.1, then makes sure the two SimX drivers the matrix needs exist for the current VORTEX_CONFIGS
# (environment and helpers: ci/rg-ci-setup-v3.sh).

cd $GITHUB_WORKSPACE
hostname

# Clean previous CI results so summary only shows current run
find examples/ -name "ci_status_*.txt" -delete 2>/dev/null
find examples/ -name "ci_output.txt" -delete 2>/dev/null
find examples/ -name "Perf_counter_*.txt" -delete 2>/dev/null
find examples/ -name "result_vortex.txt" -delete 2>/dev/null

rm -rf build

# CI_EXTRA_BINDS: additional apptainer bind paths (unset in CI; set when the workspace lives outside
# /projects/ci-runners, e.g. for a local dry run of this script).
apptainer exec -B /projects/ci-runners/CuPBoP-Vortex/:/projects/ci-runners/CuPBoP-Vortex/ ${CI_EXTRA_BINDS:+-B $CI_EXTRA_BINDS} /projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif /bin/bash << 'EOF_IN'
    set -e
    source "./ci/rg-ci-setup-v3.sh"
    cd $CuPBoP_PATH
    echo "vortex: $VORTEX_HOME ($(git -C $VORTEX_HOME describe --tags --always 2>/dev/null)), tooldir: $TOOLDIR, $(clang --version | head -1)"

    # The CUDA sources are compiled with the container's CUDA 12.1 headers (CUDA_PATH), both the device side
    # (clang --cuda-device-only) and the host side; the cuda-header tarball of the 2.0 flow is not needed.
    # The host runtime is compiled with the VX_CFG_* flags of the SimX configuration (it sizes launches by them).
    XCFG=$(python3 $VORTEX_HOME/ci/gen_config.py --config=$VORTEX_HOME/VX_config.toml --cflags="$VORTEX_CONFIGS -DVX_CFG_XLEN=64")
    mkdir -p $CuPBoP_PATH/build && cd $CuPBoP_PATH/build
    cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$XCFG"
    make -j${SLURM_CPUS_PER_TASK:-4}
    cd $CuPBoP_PATH

    # SimX drivers for the matrix: the main configuration and the TCU+DXA one used by the tensor examples.
    # Rebuilt only when the recorded configuration differs from VORTEX_CONFIGS / VORTEX_CONFIGS_TCU.
    cupbop_v3_ensure_simx $VORTEX_PATH "$VORTEX_CONFIGS"
    cupbop_v3_ensure_simx $VORTEX_PATH_TCU "$VORTEX_CONFIGS_TCU"
EOF_IN
