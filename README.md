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

### Installation Procedure

 If you have access to the Kia or Volvo (server that needs GT credentials to access), follow the shared Notion setup guide.
 
If not, follow this guide instead: [Non Kia/Volvo Setup](./docs/NonKiaVolvoSetup.md) 

Please look at  [File Directory Setup](./docs/FinalSetup.md) to understand how your codespace should look like in the end and how to set up environment variables.

  ## Benchmarks (Update)

Test benchmarks (table updated on May 14, 2025)

CuPBoP includes a subset of [Rodinia](https://github.com/yuhc/gpu-rodinia/tree/master/cuda)/Hetero-Mark benchmarks to test functionality. Benchmarks supported with Vortex 2.0 are available in the `/example` folder, each with a `kjrun_llvm18.sh` file.

  While you can run a benchmark by running `cd/Cupbop/examples/[benchmark name] & ./kjrun_llvm18.sh`, you will generate a lot of files and directories in the process. It would take some time to remove all newly generated files and directories and there is a chance one can accidentally delete the wrong file(s). Please use the makefile in the `\examples` folder and you can refer to this guide: [Makefile Guide](./docs/Makefile.md)

Take a look at this [list](.docs/BenchmarkList) to identify which benchmarks are and aren't supported.

If you want to add more RODINIA benchmarks to the `examples/ folder`, please refer to the following guide to help you: [Benchmark Creation](./docs/BenchmarkCreation.md)


## Common Issues

Refer to this guide to figure out some issues you might be facing:  [Common Issues](./docs/CommonIssues.md)

Feel free to add to this guide if you fixed any issues so it can be helpful for anyone in the future! 
 
   
  
  

## How to contribute?

  

Any kinds of contributions are welcome.

Please refer to [Contribution.md](./docs/CONTRIBUTING.md) for more detail.
