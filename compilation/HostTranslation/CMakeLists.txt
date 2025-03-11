cmake_minimum_required(VERSION 3.10)

# C project
project(
  HostTranslation
  DESCRIPTION "Translate CUDA host modules to CPU host modules,
    mainly replace CUDA Runtime APIs with CPU Runtime APIs"
  LANGUAGES CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(LIB_NAME cudaRuntime2cpuRuntime)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE Debug)
include_directories(./include)

file(GLOB proj_HEADERS "include/*.h")
file(GLOB proj_SOURCES "src/vortex/*.cpp")

# Add core library.
add_library(${LIB_NAME} SHARED ${proj_HEADERS} ${proj_SOURCES})
