// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _Z11EstepKernelPKiS0_PKbPKfbifiiPfS5_S5_Pii_wrapper(void *) { return 0; }

}
