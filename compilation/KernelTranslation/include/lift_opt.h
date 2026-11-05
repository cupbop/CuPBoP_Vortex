#ifndef __CUPBOP_LIFT_OPT__
#define __CUPBOP_LIFT_OPT__

#include "llvm/IR/Module.h"
#include <string>

// Is this module lifted from machine code by CuLifter? Module-level answer for what must never run on CUDA source input
// (lifted_ir.cpp only looks at one function's names). `why`: the deciding fact.
bool is_lifted_module(llvm::Module *M, std::string *why = nullptr);

// CUPBOP_LIFT_OPT (default 1, =0 off): the lift optimisation of experiments/p3, p4 (src/lift_opt) and its defaults on a lifted module, first thing in
// the translation; any other module goes on untouched. Returns the module to go on with. See lift_opt_driver.cpp.
llvm::Module *run_lift_opt(llvm::Module *M);

// CUPBOP_TRITON_LOMMA (default 1, =0 off): lo-mma alone on a stock Triton module, after lower_triton_input, on schedule 2. Returns the module to go on with.
llvm::Module *run_triton_lo_mma(llvm::Module *M);

#endif
