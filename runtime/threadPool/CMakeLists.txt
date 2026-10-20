cmake_minimum_required(VERSION 3.10)

# C project
project(
  ThreadPool
  DESCRIPTION "Using pthread to implement ThreadPool"
  LANGUAGES CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(LIB_NAME ThreadPool)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_BUILD_TYPE Debug)
include_directories(./include)
# CUDA toolkit headers (dim3, cudaError_t, ...) or the bundled minimal stub when CUDA_PATH is unset
if(DEFINED ENV{CUDA_PATH} AND EXISTS "$ENV{CUDA_PATH}/include/cuda_runtime.h")
  include_directories($ENV{CUDA_PATH}/include)
else()
  message(STATUS "CUDA_PATH not set or has no headers: using runtime/include/cuda_stub")
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../include/cuda_stub)
endif()

file(GLOB proj_SOURCES "src/*.cpp")
add_library(${LIB_NAME} SHARED ${proj_SOURCES})
