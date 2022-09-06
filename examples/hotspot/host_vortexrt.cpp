// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z14calculate_tempiPfS_S_iiiiffffff_wrapper(void *) { return 0; }


}
