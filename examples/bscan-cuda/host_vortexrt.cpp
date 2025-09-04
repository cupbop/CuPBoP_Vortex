// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _Z11binary_scanPiPKi_wrapper(void *) { return 0; }
}
