cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
project(
  X86runtime
  DESCRIPTION "Implementation CUDA runtime API with vortex"
  LANGUAGES CXX)
set(LIB_NAME Runtime)
set(CMAKE_VERBOSE_MAKEFILE ON)

add_subdirectory(vortex)
add_subdirectory(x86)
