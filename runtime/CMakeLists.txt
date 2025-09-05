cmake_minimum_required(VERSION 3.10 FATAL_ERROR)
project(
  Vortexruntime
  DESCRIPTION "Implementation CUDA runtime API with vortex"
  LANGUAGES CXX)
set(LIB_NAME vortexRuntime)
set(CMAKE_VERBOSE_MAKEFILE ON)

# compile threadPool implementation
add_subdirectory(threadPool)

# compile vortex runtime library
include_directories(./include)
include_directories(./threadPool/include)
include_directories(./../compilation/KernelTranslation/include)

include_directories($ENV{CUDA_PATH}/include)
include_directories($ENV{VORTEX_HOME}/runtime/include)
include_directories($ENV{VORTEX_HOME}/kernel/include)
include_directories($ENV{VORTEX_HOME}/build/hw)

message(STATUS "VORTEX_PATH: $ENV{VORTEX_PATH}")
message(STATUS "CUDA_PATH: $ENV{CUDA_PATH}")
message(STATUS "VORTEX_HOME: $ENV{VORTEX_HOME}")


file(GLOB proj_SOURCES "./src/vortex/host/*.cpp")
add_library(${LIB_NAME} SHARED ${proj_SOURCES})

add_subdirectory(src/vortex)