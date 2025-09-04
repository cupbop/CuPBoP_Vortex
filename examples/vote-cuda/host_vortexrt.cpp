// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _Z13VoteAnyKernel1PKjS_j_wrapper(void *) { return 0; }
void * _Z13VoteAllKernel2PKjS_j_wrapper(void *) { return 0; }
void * _Z13VoteAnyKernel3Pbii_wrapper(void *) { return 0; }
}
