// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z14bcast_shfl_sg8iPi_wrapper(void *) { return 0; }
void * _Z18bcast_shfl_xor_sg8Pi_wrapper(void *) { return 0; }
void * _Z15bcast_shfl_sg16iPi_wrapper(void *) { return 0; }
void * _Z19bcast_shfl_xor_sg16Pi_wrapper(void *) { return 0; }
void * _Z15bcast_shfl_sg32iPi_wrapper(void *) { return 0; }
void * _Z19bcast_shfl_xor_sg32Pi_wrapper(void *) { return 0; }
void * _Z14transpose_shflPfPKf_wrapper(void *) { return 0; }

}
