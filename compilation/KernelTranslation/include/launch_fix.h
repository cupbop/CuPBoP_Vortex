#ifndef __CUPBOP_LAUNCH_FIX__
#define __CUPBOP_LAUNCH_FIX__

#include "llvm/IR/Module.h"
#include <cstdint>

// Per-kernel rewrites of the launch, left by the translator for the host runtime: what a kernel transformation changes in
// how the kernel has to be launched, so that the user's own launch stays as written.
//
//   producer (pass, inside the translator or an opt plugin)  !cupbop.launch_fix = !{!{!"<kernel>", !"<key>", i64 <value>}, ...}
//                                                            or launch_fix_note()
//   translator                                               launch_fix_collect() moves the marks out of the module (kernel.bc
//                                                            does not carry them), launch_fix_write() at the end of the translation
//   cupbop_launch_fix.txt                                    <kernel> <key>=<value> ...   one line per kernel
//   host runtime                                             cudaLaunchKernel_vortex (cudaRuntimeImpl.cpp, cupbop_launch_fix)
//
// Keys the runtime knows: see cupbop_apply_launch_fix. An unknown key is an error at launch: a rewrite that a transformed kernel
// needs and the runtime ignores would run the kernel wrongly.
// dyn_smem=<bytes>: the launch's dynamic shared size is replaced (a folded @shared_mem holds the whole CTA area: 0).
// cta_dims=<mask>, cta_inner=<d>, cta_chunk=1: the kernel has the block loop of CUPBOP_CTA_LOOP (cta_loop.cpp); the runtime chooses the
// launched grid and the context word that selects the loop.

void launch_fix_note(llvm::Module *M, llvm::StringRef kernel, llvm::StringRef key, uint64_t value);
void launch_fix_collect(llvm::Module *M);
void launch_fix_write();

#endif
