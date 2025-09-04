// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _Z9findTopKIiLi256ELi256EEvPiS1_PKifim_wrapper(void *) { return 0; }

}
