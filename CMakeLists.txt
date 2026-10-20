cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

project(CudaOnX86)
set(CMAKE_PROJECT_DESCRIPTION "Executing CUDA on X86 architecture.")
set(CMAKE_CXX_STANDARD 17)
set(MAJOR_VERSION 0)
set(MINOR_VERSION 1)
set(VERSION_STRING ${MAJOR_VERSION}.${MINOR_VERSION})
set(COX_VERSION ${VERSION_STRING})
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# get LLVM PATH get PATH for head file
if(DEFINED LLVM_CONFIG_PATH)
  if(IS_ABSOLUTE "${LLVM_CONFIG_PATH}")
    if(EXISTS "${LLVM_CONFIG_PATH}")
      set(LLVM_CONFIG "${LLVM_CONFIG_PATH}")
    else()
      message(FATAL_ERROR "llvm-config is not found in ${LLVM_CONFIG_PATH}")
    endif()
    message(STATUS "Using llvm-config: ${LLVM_CONFIG}")
    execute_process(
      COMMAND "${LLVM_CONFIG}" "--cxxflags"
      OUTPUT_VARIABLE LLVM_CXX_FLAG
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(
      COMMAND "${LLVM_CONFIG}" "--libdir"
      OUTPUT_VARIABLE LLVM_LIB_PATH
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(
      COMMAND "${LLVM_CONFIG}" "--libs"
      OUTPUT_VARIABLE LLVM_LINK_FLAG
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()
else()
  message(FATAL_ERROR "llvm-config is required")
endif()

# Check the environment variable
# Vortex 3.0 is 64-bit only: default to the 64-bit argument-block layout unless
# VORTEX_ARCHITECTURE=32 is requested explicitly. (The host runtime's context_t must
# match the device wrapper's; a 32-bit host layout against a 64-bit kernel silently
# shifts kernel_idx/num_args/args and the kernel reads garbage.)
if("$ENV{VORTEX_ARCHITECTURE}" STREQUAL "32")
  message(STATUS "VORTEX_ARCHITECTURE=32: 32-bit argument layout")
else()
  add_definitions(-DVORTEX_ARCHITECTURE_64=1)
  message(STATUS "VORTEX_ARCHITECTURE_64 is set (default)")
endif()

set(CMAKE_CXX_FLAGS "${LLVM_CXX_FLAG} ${CMAKE_CXX_FLAGS}")

set(GCC_COVERAGE_LINK_FLAGS
    "-L${LLVM_LIB_PATH} ${LLVM_LINK_FLAG} -lz -lrt -ldl -ltinfo -lpthread -lm")

add_subdirectory(compilation)
add_subdirectory(runtime)
