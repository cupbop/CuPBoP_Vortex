#ifndef __CUPBOP_LIFT_OPT__
#define __CUPBOP_LIFT_OPT__

#include "llvm/IR/Module.h"
#include <string>

// Is this module lifted from machine code by CuLifter? Module-level answer for what must never run on CUDA source input
// (lifted_ir.cpp only looks at one function's names). `why`: the deciding fact.
bool is_lifted_module(llvm::Module *M, std::string *why = nullptr);

// CUPBOP_LIFT_OPT=1 (default 0): the lift optimisation of experiments/p3 (src/lift_opt) on a lifted module, first thing in the
// translation. Returns the module to go on with. See lift_opt_driver.cpp.
llvm::Module *run_lift_opt(llvm::Module *M);

#endif
