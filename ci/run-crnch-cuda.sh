#!/bin/bash
#SBATCH --job-name="CuPBoP-Vortex-ci-cuda"
#SBATCH -t 00:10:00                              # Duration of the job
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash[1-4]
#SBATCH -N 1
#SBATCH --gres=gpu:1
#SBATCH -o /tools/ci-reports/CuPBoP_logs/CuPBoP-cuda-test-%j.out   # Combined output and error messages file
#SBATCH -W                                       # Do not exit until the submitted job terminates.

cd $GITHUB_WORKSPACE
hostname

rm -rf build

apptainer exec --nv -B /projects/ci-runners/CuPBoP-Vortex/:/projects/ci-runners/CuPBoP-Vortex/ /projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif /bin/bash << 'EOF'
    source "./ci/rg-ci-setup.sh"
    export VORTEX_SCHEDULE_FLAG=2
    
    # Installing CUDA headers for CuPBoP
    cd $CuPBoP_PATH
    wget "https://dl.dropboxusercontent.com/scl/fi/m9ap1tiybau4zk720t2z7/cuda-header.tar.gz?rlkey=zmdpst5l66t48ywrbtkj426nu&st=luao6zy7" -O cuda-header.tar.gz
    tar -xzf 'cuda-header.tar.gz'
    cp -r include/* runtime/threadPool/include/
    rm -r 'cuda-header.tar.gz'

    mkdir -p $CuPBoP_PATH/build && cd $CuPBoP_PATH/build
    cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH
    make

    # Vortex sanity check
    $VORTEX_PATH/ci/blackbox.sh --cores=4 --warps=16 --threads=32 --app=demo
EOF
