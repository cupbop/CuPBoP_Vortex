// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _Z17computeMinMaxLv1Pf_wrapper(void *) { return 0; }
void * _Z10compactLv1fPKfPjS1__wrapper(void *) { return 0; }
void * _Z17computeMinMaxLv2PKjPf_wrapper(void *) { return 0; }
void * _Z10compactLv2fPKfPKjPjjS2__wrapper(void *) { return 0; }
void * _Z19generatingTrianglesfPKjPKtPKiPK6uchar4PjS6_Py_wrapper(void *) { return 0; }

}
