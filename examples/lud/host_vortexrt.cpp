// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z4Fan1PfS_ii_wrapper(void *) { return 0; }
void * _Z4Fan2PfS_S_iii_wrapper(void *) { return 0; }

}
