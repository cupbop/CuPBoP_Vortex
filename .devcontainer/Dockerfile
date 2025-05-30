FROM    ubuntu:22.04
ARG     DEBIAN_FRONTEND=noninteractive
RUN     apt-get update && apt-get install -y lsb-release wget software-properties-common gnupg git cmake zlib1g zlib1g-dev g++ python3 python3-pip
RUN     pip install pre-commit
RUN     wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- 18
RUN     apt-key del -y 7fa2af80 && \
        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && dpkg -i cuda-keyring_1.1-1_all.deb && \
        apt-get update && apt-get install -y nvidia-cuda-toolkit=11.5.1-1ubuntu1
ENV     LLVM_SYS_181_PREFIX=/usr/lib/llvm-18
ENV     PATH=$PATH:/usr/lib/llvm-18/bin
ENV     CUDA_PATH=/usr/lib/cuda
ENV     LLVM_CONFIG_PATH=/usr/lib/llvm-18/bin/llvm-config
RUN     mkdir -p /workspaces &&\
        git clone --depth=1 --recursive https://github.com/vortexgpgpu/vortex.git /workspaces/vortex --branch master
WORKDIR /workspaces/vortex
RUN     ./ci/install_dependencies.sh
RUN     mkdir build && cd build &&\
        ../configure --xlen=64 --tooldir=$HOME/tools --prefix=/usr/vortex &&\
        ./ci/toolchain_install.sh --all
WORKDIR /workspaces/vortex/build
RUN     . ./ci/toolchain_env.sh && \
        unset VERILATOR_ROOT && \
        make -s && \
        make install
ENV     TOOLDIR=$HOME/tools
ENV     POCL_ROOT=/workspaces/pocl
ENV     VORTEX_HOME=/usr/vortex
ENV     LLVM_VORTEX=/usr/lib/llvm-18
ENV     CuPBoP_PATH=/workspaces/cupbop-vx