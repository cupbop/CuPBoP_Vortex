// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void * _Z19kernel_compute_costiilP5PointiiPfS1_PiPb_wrapper(void *) { return 0; }
}
