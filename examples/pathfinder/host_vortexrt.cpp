// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z14dynproc_kerneliPiS_S_iiii_wrapper(void *) { return 0; }


}
