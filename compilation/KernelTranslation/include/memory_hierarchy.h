#ifndef __NVVM2x86_MEMORY_HIERARCHY__
#define __NVVM2x86_MEMORY_HIERARCHY__
#include "llvm/IR/Module.h"
#include <fstream>
using namespace llvm;

void mem_share2global(llvm::Module *M);
void mem_share2global_sche_2(llvm::Module *M);
void mem_share2local(llvm::Module *M);
void log_vx_local_mem_requests(llvm::Module *M); // __vx_local_mem_offset(size) -> kernel_lmem.log
void mem_constant2global(llvm::Module *M, std::ofstream &fout);
void mem_device2global(llvm::Module *M, std::ofstream &fout);


#endif
