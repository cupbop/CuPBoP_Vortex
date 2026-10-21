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
#SBATCH -o /tools/ci-reports/CuPBoP_logs/CuPBoP-cuda-test-%j.out   # Combined output and error messages file
#SBATCH -W                                       # Do not exit until the submitted job terminates.

# ci.yml "tests" job on Vortex 3.0: one matrix entry (TEST_NAME, VORTEX_SCHEDULE_FLAG, VORTEX_LOCALMEM_FLAG).
# `make ci` translates the example with the CuPBoP build of the build job, builds the kernel ELF in a Vortex
# regression cell and runs it on the SimX of ci/rg-ci-setup-v3.sh (the TCU+DXA SimX for the tensor examples).

cd $GITHUB_WORKSPACE
hostname

CI_LOG_DIR=${CI_LOG_DIR:-/tools/ci-reports/CuPBoP_logs}
export FINAL_OUTPUT_PATH="$CI_LOG_DIR/CuPBoP-cuda-test-${SLURM_JOB_ID}.out"
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
    make -C ${TEST_NAME} ci SCHEDULE=${VORTEX_SCHEDULE_FLAG} LOCALMEM=${LMEM_FLAG}
    exit 0
EOF_IN

ln -sf "$FINAL_OUTPUT_PATH" "$CI_LOG_DIR/${TEST_NAME}.out"
