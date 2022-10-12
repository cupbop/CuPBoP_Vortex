cmake_minimum_required(VERSION 3.1)

# C project
project(
  vortexRuntime
  DESCRIPTION ""
  LANGUAGES CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(LIB_NAME vortexRuntime)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_BUILD_TYPE Debug)

include_directories(./../../include)
include_directories(./../../threadPool/include)
include_directories($ENV{VORTEX_PATH}/driver/include)
file(GLOB proj_SOURCES "./host/*.cpp")
add_library(${LIB_NAME} SHARED ${proj_SOURCES})





