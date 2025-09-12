### Installation (Vortex)

  

1. Setup Vortex Environment

  

Refer to the [Vortex Repo](https://github.com/vortexgpgpu/vortex) for instructions on setting up the Vortex environment. While CuPBoP supports both 32-bit and 64-bit architectures, **(we recommend building Vortex in 64-bit.)**

*(If you are part of HParch and have access to the Kia server, you can use the Vortex toolchain/pocl in the shared directory.)*

  

2. Install Vortex-llvm for CuPBoP (LLVM 18)

  

The original Vortex LLVM supports only the RISC-V backend. CuPBoP (Vortex) requires RISC-V, PTX, and x86, so rebuilding LLVM is necessary. You can install LLVM in any directory. *(Set `$LLVM_VORTEX` to define the build directory.)*

```bash

git clone --recursive --branch vortex_2.x https://github.com/vortexgpgpu/llvm.git llvm-vortex-with-cuda

cd llvm

mkdir build && cd  build

export  LLVM_VORTEX="USER DEFINED DIRECTORY"

cmake -G "Unix Makefiles"  -DLLVM_ABI_BREAKING_CHECKS=FORCE_OFF  -DLLVM_INCLUDE_EXAMPLES=OFF  -DLLVM_INCLUDE_TESTS=OFF  -DCMAKE_BUILD_TYPE=Release  -DLLVM_ENABLE_PROJECTS="clang"  -DCMAKE_INSTALL_PREFIX=$LLVM_VORTEX  -DDEFAULT_SYSROOT=$RISCV_TOOLCHAIN_PATH/riscv32-unknown-elf  -DLLVM_DEFAULT_TARGET_TRIPLE="riscv32-unknown-elf"  -DLLVM_TARGETS_TO_BUILD="X86;RISCV;NVPTX"  ../llvm

make -j`nproc`

make  install

```

  

### Installation (CuPBoP)

  
  
  

1. Clone from github

  

```bash

git clone https://github.com/cupbop/CuPBoP_Vortex.git

cd CuPBoP_Vortex

export  CuPBoP_PATH=`pwd`

export  LD_LIBRARY_PATH=$CuPBoP_PATH/build/runtime:$CuPBoP_PATH/build/runtime/threadPool:$LD_LIBRARY_PATH

```

2. As CuPBoP relies on CUDA structures, we need to download the CUDA header file

  

```bash

wget "https://dl.dropboxusercontent.com/scl/fi/m9ap1tiybau4zk720t2z7/cuda-header.tar.gz?rlkey=zmdpst5l66t48ywrbtkj426nu&st=luao6zy7" -O cuda-header.tar.gz

tar -xzf 'cuda-header.tar.gz'

cp -r include/* runtime/threadPool/include/

```

  

3. Other CUDA files are also required for compiling CUDA source code to LLVM IR

  

```bash

wget https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda_12.1.1_530.30.02_linux.run

sh cuda_12.1.1_530.30.02_linux.run --silent --toolkit --toolkitpath=$CuPBoP_PATH/cuda-12.1

```

  

4. Setup environment.

  

Use the CuPBoP_env_setup.sh file to set up the environment variables:
If you're planning to use Cuda only (not OpenCL), you can execute CuPBoP_env_setup_wo_PoCL.sh.

```bash

$CuPBoP_PATH/CuPBoP_env_setup.sh

```

  

5. Build CuPBoP

  

```bash

export  VORTEX_ARCHITECTUE = 64  # 64 if using 64-bit vortex

mkdir build && cd  build

cmake .. -DLLVM_CONFIG_PATH=`which llvm-config`  # need path to llvm-config

make

```