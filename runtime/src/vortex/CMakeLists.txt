add_custom_target(
    vortexRuntimeKernel ALL
    COMMAND ${CMAKE_COMMAND} -E env
        "LLVM_PREFIX=$ENV{LLVM_VORTEX}"
        "TOOLDIR=$ENV{TOOLDIR}"
        "VORTEX_HOME=$ENV{VORTEX_HOME}"
        "CuPBoP_PATH=$ENV{CuPBoP_PATH}"
        "RISCV_TOOLCHAIN=$ENV{RISCV_TOOLCHAIN}"
        ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_CURRENT_SOURCE_DIR}/kernel
    COMMENT "Building kernel object files (cudaKernelImpl.o / cudaKernelImpl_64.o)"
    VERBATIM
)