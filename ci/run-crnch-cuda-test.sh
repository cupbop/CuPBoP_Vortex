#!/bin/bash
#SBATCH --job-name="CuPBoP-Vortex-ci-cuda"
#SBATCH -t 00:45:00                              # Duration of the job
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash[1-4]
#SBATCH -N 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH -o /tools/ci-reports/CuPBoP_logs/CuPBoP-cuda-test-%j.out   # Combined output and error messages file
#SBATCH -W                                       # Do not exit until the submitted job terminates.

cd $GITHUB_WORKSPACE
hostname

export FINAL_OUTPUT_PATH="/tools/ci-reports/CuPBoP_logs/CuPBoP-cuda-test-${SLURM_JOB_ID}.out"
apptainer exec --nv -B /projects/ci-runners/CuPBoP-Vortex/:/projects/ci-runners/CuPBoP-Vortex/ /projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif /bin/bash << 'EOF'
    set -e
    source "./ci/rg-ci-setup.sh"

    cd ./examples
    make -C ${TEST_NAME} clean
    make -C ${TEST_NAME} ci SCHEDULE=${VORTEX_SCHEDULE_FLAG}
    exit 0
EOF

ln -sf /tools/ci-reports/CuPBoP_logs/CuPBoP-cuda-test-${SLURM_JOB_ID}.out /tools/ci-reports/CuPBoP_logs/${TEST_NAME}.out
