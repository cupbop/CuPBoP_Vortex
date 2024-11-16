cmake_minimum_required(VERSION 3.1)
# C project
project(
  vortexRuntimeKernel
  DESCRIPTION "Kernel"
  LANGUAGES CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(LIB_NAME vortexRuntimeKernel)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE Debug)
set(RISCV_TOOLCHAIN /opt/riscv-gnu-toolchain/bin)
set(CMAKE_CXX_COMPILER ${RISCV_TOOLCHAIN}/riscv32-unknown-elf-g++)

include_directories(./../../../include)
include_directories(./../../../threadPool/include)
include_directories($ENV{VORTEX_PATH}/runtime/include)
file(GLOB proj_SOURCES "*.cpp")
add_library(${LIB_NAME} SHARED ${proj_SOURCES})

