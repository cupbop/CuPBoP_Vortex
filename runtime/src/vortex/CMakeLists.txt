add_custom_target(
    vortexRuntimeKernel ALL
    COMMAND ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_CURRENT_SOURCE_DIR}/kernel
    COMMENT "Building kernel object files using Makefile"
    VERBATIM
)