// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z6euclidP7latLongPfiff_wrapper(void *) { return 0; }


}
