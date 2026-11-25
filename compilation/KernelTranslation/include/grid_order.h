#ifndef __CUPBOP_GRID_ORDER__
#define __CUPBOP_GRID_ORDER__

#include "llvm/IR/Module.h"

// Grid order (CUPBOP_GRID_ORDER=1, default 0; schedule 2). See grid_order.cpp.
// Every read of the CUDA block index (x, y) of a kernel that qualifies goes through __cupbop_grid_order_xy, which walks
// the grid in groups of R rows of y, column first (Triton's GROUP_SIZE_M order). R is chosen at launch (the context's
// direct_launch_flags bits 8..15; 0 or 1 = the launch's own order), so one binary serves every R and R = 0 changes
// nothing but the few instructions of the check.
void lower_grid_order(llvm::Module *M);

#endif
