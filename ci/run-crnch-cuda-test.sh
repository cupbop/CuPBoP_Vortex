#!/bin/bash
#SBATCH --job-name="CuPBoP-Vortex-ci-cuda"
#SBATCH -t 00:45:00                              # Duration of the job
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash[1-4]
#SBATCH -N 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
# GPU not needed: Vortex simx is a pure CPU emulator. Removing --gres=gpu:1
# lets multiple matrix jobs share a node (allocated by CPU/memory only)
# instead of serializing on the 1 GPU per node.
#SBATCH -o /projects/ci-runners/CuPBoP-Vortex/logs/CuPBoP-cuda-test-%j.out   # default only: ci.yml passes -o $CI_LOG_DIR/... (dir writable by the runner account)
#SBATCH -W                                       # Do not exit until the submitted job terminates.

# ci.yml "tests" job on Vortex 3.0: one matrix entry (TEST_NAME, VORTEX_SCHEDULE_FLAG, VORTEX_LOCALMEM_FLAG).
# `make ci` translates the example with the CuPBoP build of the build job, builds the kernel ELF in a Vortex
# regression cell and runs it on the SimX of ci/rg-ci-setup-v3.sh (the TCU+DXA SimX for the tensor examples).

set -e
cd "${GITHUB_WORKSPACE:-$SLURM_SUBMIT_DIR}/${CI_RUN_SUBDIR:-.}"
hostname

# Keep the human-facing latest log. The workflow checks the immutable job log.
if [[ -n ${SLURM_JOB_ID:-} ]]; then
    log_dir=${CI_LOG_DIR:-/projects/ci-runners/CuPBoP-Vortex/logs}
    log="$log_dir/CuPBoP-cuda-test-$SLURM_JOB_ID.out"
    if [[ -f $log ]]; then ln -sfn "$log" "$log_dir/${TEST_NAME}.out"; fi
fi

apptainer exec -B /projects/ci-runners/CuPBoP-Vortex/:/projects/ci-runners/CuPBoP-Vortex/ ${CI_EXTRA_BINDS:+-B $CI_EXTRA_BINDS} /projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif /bin/bash << 'EOF_IN'
    set -e
    source "./ci/rg-ci-setup-v3.sh"
    cupbop_v3_select_simx "$TEST_NAME"
    echo "test=$TEST_NAME schedule=$VORTEX_SCHEDULE_FLAG localmem=${VORTEX_LOCALMEM_FLAG:-1} simx=$VORTEX_PATH"

    cd ./examples
    make -C ${TEST_NAME} clean
    LMEM_FLAG=${VORTEX_LOCALMEM_FLAG:-1}
    rm -f ${TEST_NAME}/Perf_counter_*SCHE_${VORTEX_SCHEDULE_FLAG}*LOCAL_MEM_${LMEM_FLAG}*.txt
    rm -f ${TEST_NAME}/Perf_counter_*SCHE_${VORTEX_SCHEDULE_FLAG}.txt
    rm -f ${TEST_NAME}/ci_status_SCHE_${VORTEX_SCHEDULE_FLAG}_LMEM_${LMEM_FLAG}.txt
    cell=$(mktemp -d "$VORTEX_PATH/tests/regression/cupbop_ci_${SLURM_JOB_ID:-manual}_XXXXXXXX")
    trap 'rm -rf -- "$cell"' EXIT
    make -C "$TEST_NAME" ci SCHEDULE="$VORTEX_SCHEDULE_FLAG" LOCALMEM="$LMEM_FLAG" VX3_CELL="$cell"
EOF_IN
