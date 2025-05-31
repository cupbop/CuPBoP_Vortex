# CuPBoP: Cuda for Parallelized and Broad-range Processors

  

## Introduction

  

CuPBoP is a framework designed to execute unmodified CUDA source code on non-NVIDIA devices. It currently supports several CPU backends, including x86 and AArch64, as well as GPU backends such as AMD GPUs and the open-source RISC-V (Vortex). This repository specifically focuses on enabling CUDA execution on Vortex [GitHub link](https://github.com/vortexgpgpu/vortex).

Please look at the following files to understand the basics of CuPBoP:

[Basic Definitions and Concepts](./docs/README_Defs.md)

[Codebase Overview](./docs/README_Codebase.md)

  

## Install

  

### Prerequisites

  

- Linux: Verified on Ubuntu 18.04 / 20.04

- LLVM 18.1.7 (Vortex extended LLVM)

- NVIDIA CUDA-toolkit (Verified on Cuda 12.1.1)

- x86 CPU

- pthread

- GCC (Verified with 7.5.0, 10.5.0)

- Vortex 2.0 ([Verified with commit on Oct 22, 2024](https://github.com/vortexgpgpu/vortex/tree/3a3bb7b70a395a6f96a2bfe657bc724186565fe0))

  

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

git clone https://github.com/cupbop/CuPBoP_dev CuPBoP

cd CuPBoP

git checkout vortex-llvm18

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

  

6. Test benchmarks (table updated on May 14, 2025)

CuPBoP includes a subset of Rodinia/Hetero-Mark benchmarks to test functionality. Benchmarks supported with Vortex 2.0 are available in the `/example` folder, each with a `kjrun_llvm18.sh` file.

  

<div  align="center">

  

| Benchmark | Supported? | CUDA feature |

|------------------|:----------:|--------------------------|

| microbench (saxpy) | O | |

| gauss | O | Multi-kernel in series |

| bfs | O | |

| nn | O | Math Library (sqrt) |

| nw | O | Shared Mem + syncthreads |

| srad_v2 | O | Shared Mem + syncthreads |

| hotspot | O | Shared Mem + syncthreads |

| StreamCluster | O | Const Mem |

| Myocyte | O | |

| Pathfinder | O | Shared Mem + syncthreads |

| LUD | O | Shared Mem + syncthreads |

| CFD | X | device, inline function |

| Btree | O | |

| Backprop | O | __powf, __log2f |

| Heartwall | X | |

| Huffman | X | Atomics |

  
  

</div>


## Installation Issues

### Vortex

### CuPBoP

- As of 5/30/2025, CuPBoP is a private repo. Even if you have read+write permissions, trying to use the command line to clone the repo might have the terminal to enter your Github username and password (Github key, not password for your username). However, Github Keys seem to work on repos you own. To bypass this issue you have two ways.
	1. Fork the repo to create a copy of it into your own account. Proceed with the original instructions, but replace the website in the git clone command to that of your copy repo.
	2. Manually install the zip file by clicking on the green `Code` button on the top right and unzip it next to the vortex repo. Note: If you're using a server like Kia or Volvo, you can use the scp command to transfer the zip file to your account on the server. The command might look like `scp [address of zip file] [username@kia.cc.gatech.edu:nethome/username/path]`. After this, unzip the file.

   
  
  

## How to contribute?

  

Any kinds of contributions are welcome.

Please refer to [Contribution.md](./docs/CONTRIBUTING.md) for more detail.
