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
# 공통 include (변수로 정리)
set(VORTEX_RUNTIME_INCLUDES
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/threadPool/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/../compilation/KernelTranslation/include"
  "$ENV{CUDA_PATH}/include"
  "$ENV{VORTEX_HOME}/runtime/include"
  "$ENV{VORTEX_HOME}/kernel/include"
  "$ENV{VORTEX_HOME}/build/hw"
)

message(STATUS "VORTEX_PATH: $ENV{VORTEX_PATH}")
message(STATUS "CUDA_PATH: $ENV{CUDA_PATH}")
message(STATUS "VORTEX_HOME: $ENV{VORTEX_HOME}")

file(GLOB proj_SOURCES "./src/vortex/host/*.cpp")

# --- 1) 기본 runtime: 원본 심볼(cudaMalloc, cudaMemcpy, ...)
add_library(vortexRuntime SHARED ${proj_SOURCES})
target_include_directories(vortexRuntime PRIVATE ${VORTEX_RUNTIME_INCLUDES})
target_link_libraries(vortexRuntime PRIVATE ThreadPool)

# --- 2) torch runtime: *_vortex 심볼만 export되도록 컴파일 타임 매크로 켬
add_library(vortexRuntime_torch SHARED ${proj_SOURCES})
target_include_directories(vortexRuntime_torch PRIVATE ${VORTEX_RUNTIME_INCLUDES})
target_link_libraries(vortexRuntime_torch PRIVATE ThreadPool)

# 여기서만 심볼 rename 매크로 ON
target_compile_definitions(vortexRuntime_torch PRIVATE VORTEX_RENAME_CUDA_SYMBOLS=1)

# 출력 디렉터리
set(TORCH_OUTDIR "${CMAKE_CURRENT_BINARY_DIR}/pytorch")
file(MAKE_DIRECTORY "${TORCH_OUTDIR}")

set_target_properties(vortexRuntime_torch PROPERTIES
  OUTPUT_NAME "vortexRuntime_torch"
  LIBRARY_OUTPUT_DIRECTORY "${TORCH_OUTDIR}"
  LIBRARY_OUTPUT_DIRECTORY_DEBUG "${TORCH_OUTDIR}"
  LIBRARY_OUTPUT_DIRECTORY_RELEASE "${TORCH_OUTDIR}"
  LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${TORCH_OUTDIR}"
  LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL "${TORCH_OUTDIR}"
)

add_subdirectory(src/vortex)
