#ifndef __CUPBOP_SIMT_OPT__
#define __CUPBOP_SIMT_OPT__
#include "llvm/IR/Module.h"
// SIMT start-point passes (p2d, 2026-11-04). All off by default; see simt_opt.cpp.
void simt_measure_blockdim(llvm::Module *M);   // CUPBOP_MEASURE_BLOCKDIM=bx,by,bz: measurement only
void simt_trip_hoist(llvm::Module *M);         // CUPBOP_TRIP_HOIST
void simt_trip_version(llvm::Module *M);       // CUPBOP_TRIP_VERSION
void simt_div_restore(llvm::Module *M);        // CUPBOP_DIV_RESTORE
#endif
