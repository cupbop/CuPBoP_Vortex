// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _Z11jacobi_stepPfPKfS0__wrapper(void *) { return 0; }

}
