// hack to silence host.bc referencing missing kernl wrapper
extern "C" {
void* _Z15checkDuplicatesiPKi(int, int*) { return 0; }
void* _Z18checkDuplicateMaskiPKi(int, int*) { return 0; }
}
