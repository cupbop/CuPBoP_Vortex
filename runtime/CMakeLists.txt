cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
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

include_directories($ENV{VORTEX_PATH}/runtime/include)
file(GLOB proj_SOURCES "./src/vortex/host/*.cpp")
add_library(${LIB_NAME} SHARED ${proj_SOURCES})
