// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z22bpnn_layerforward_CUDAPfS_S_S_ii_wrapper(void *) { return 0; }
void * _Z24bpnn_adjust_weights_cudaPfiS_iS_S__wrapper(void *) { return 0; }
}
