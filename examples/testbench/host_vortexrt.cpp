// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z5saxpyifPfS__wrapper(void *) { return 0; }
}
