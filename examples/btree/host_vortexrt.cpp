// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z10kernel_eccfPfS_iS__wrapper(void *) { return 0; }
void * _Z10kernel_camfPfS_iS_iS_if_wrapper(void *) { return 0; }
void * _Z12kernel_ecc_2fPfS_iS__wrapper(void *) { return 0; }
void * _Z12kernel_cam_2fPfS_iS_iS_if_wrapper(void *) { return 0; }
void * _Z12kernel_fin_2iPfS_iiiiS_S__wrapper(void *) { return 0; }
void * _Z8kernel_2iPfS_S_S__wrapper(void *) { return 0; }
void * _Z23embedded_fehlberg_7_8_2ffPfS_S_S_S_S_S__wrapper(void *) { return 0; }
void * _Z6kerneliPfS_S_S__wrapper(void *) { return 0; }
void * _Z8solver_2iiPfS_S_S_S_S_S_S_S__wrapper(void *) { return 0; }
}
