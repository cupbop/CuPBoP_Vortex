#include <cstdlib>
#include <string>
#include <iostream>

#ifdef VORTEX_ARCHITECTURE_64
    #define KERNEL_ARG_BASE_ADDR 0x17ffff000
#else
    #define KERNEL_ARG_BASE_ADDR 0x7ffff000
#endif
