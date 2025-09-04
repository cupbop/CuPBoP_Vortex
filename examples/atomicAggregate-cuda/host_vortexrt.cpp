// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void* _Z1kPii(int*, int) { return 0; }
}
