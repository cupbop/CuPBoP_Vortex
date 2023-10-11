// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z11srad_cuda_1PfS_S_S_S_S_iif_wrapper(void *) { return 0; }
void * _Z11srad_cuda_2PfS_S_S_S_S_iiff_wrapper(void *) { return 0; }

}
