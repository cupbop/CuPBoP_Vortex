// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z6KernelP4NodePiPbS2_S2_S1_i_wrapper(void *) { return 0; }
void * _Z7Kernel2PbS_S_S_i_wrapper(void *) { return 0; }

}
