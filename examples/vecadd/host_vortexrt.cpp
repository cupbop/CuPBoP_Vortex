// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
    void _Z9vectorAddPKfS0_Pfi_wrapper(void) { }
}