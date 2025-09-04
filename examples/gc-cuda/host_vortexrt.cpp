// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _Z4initiiPKiS1_PiS2_S2_PVi_wrapper(void *) { return 0; }
void * _Z8runLargeiPKiS1_PiS2_PViS2__wrapper(void *) { return 0; }
void * _Z8runSmalliPKiS1_PViPi_wrapper(void *) { return 0; }

}
