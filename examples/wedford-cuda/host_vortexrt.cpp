// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _Z14welford_kernelIfffEvPKT_PT1_S4_iii_wrapper(void *) { return 0; }

}
