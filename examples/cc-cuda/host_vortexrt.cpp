// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _ZL4initiPKiS1_Pi_wrapper(void *) { return 0; }
void * _ZL8compute1iPKiS1_PiS2__wrapper(void *) { return 0; }
void * _ZL8compute2iPKiS1_PiS2__wrapper(void *) { return 0; }
void * _ZL8compute3iPKiS1_PiS2__wrapper(void *) { return 0; }
void * _ZL7flatteniPKiS1_Pi_wrapper(void *) { return 0; }

}
