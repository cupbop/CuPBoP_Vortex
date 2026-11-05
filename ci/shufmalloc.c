// shufmalloc.c: LD_PRELOAD allocator that hands out chunks of each size class in random order, so std::set<T*> order and
// pointer hashes change from run to run far more than ASLR alone. Determinism stress test of the translator (experiments/determ).
// SHUF_SEED=<n> fixes the sequence; default = pid ^ time. free() is a no-op (the translator is short-lived), unless SHUF_REUSE=1:
// then freed chunks of a size class go to a pool and half of the allocations take a random one, so a stale pointer in a set can meet a new object.
#define _GNU_SOURCE
#include <errno.h>
#include <pthread.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#define MAXCLS 256           // 16-byte classes up to 4 KB
#define SLOTS 8192           // chunks per slab
typedef struct { char *base; uint32_t left; uint32_t *perm; char **pool; uint32_t npool, cap; } Slab;
static int reuse = -1;
static Slab slabs[MAXCLS + 1];
static pthread_mutex_t L = PTHREAD_MUTEX_INITIALIZER;
static uint64_t rs;
static inline uint64_t rnd(void) { rs ^= rs << 13; rs ^= rs >> 7; rs ^= rs << 17; return rs; }
static char *arena, *arena_end;
static void *raw(size_t n) {   // bump from a big reserved region, page aligned
  n = (n + 4095) & ~(size_t)4095;
  if (!arena) { size_t A = (size_t)1 << 38; arena = mmap(0, A, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0); if (arena == MAP_FAILED) abort(); arena_end = arena + A;
    const char *s = getenv("SHUF_SEED"); rs = s ? strtoull(s, 0, 0) * 0x9E3779B97F4A7C15ull + 1 : ((uint64_t)getpid() << 32) ^ (uint64_t)time(0) ^ (uint64_t)(uintptr_t)&s; for (int i = 0; i < 16; i++) rnd(); }
  char *p = arena; arena += n; if (arena > arena_end) abort(); return p;
}
typedef struct { size_t size; size_t pad; } Hdr;  // 16 bytes before every chunk: user size
static void *alloc(size_t n, size_t align) {
  if (align < 16) align = 16;
  size_t need = n + sizeof(Hdr) + (align > 16 ? align : 0); char *c;
  pthread_mutex_lock(&L);
  if (need <= MAXCLS * 16) {
    size_t cl = (need + 15) / 16; Slab *s = &slabs[cl];
    if (s->npool && (rnd() & 1)) { uint32_t j = rnd() % s->npool; c = s->pool[j]; s->pool[j] = s->pool[--s->npool]; goto got; }
    if (!s->left) { s->base = raw(cl * 16 * SLOTS); s->perm = raw(SLOTS * 4); for (uint32_t i = 0; i < SLOTS; i++) s->perm[i] = i; s->left = SLOTS; }
    uint32_t j = rnd() % s->left, v = s->perm[j]; s->perm[j] = s->perm[--s->left]; c = s->base + (size_t)v * cl * 16;
  got:;
  } else c = raw(need + 16);
  pthread_mutex_unlock(&L);
  char *u = (char *)(((uintptr_t)c + sizeof(Hdr) + align - 1) & ~(uintptr_t)(align - 1));
  ((Hdr *)u)[-1].size = n; ((Hdr *)u)[-1].pad = need <= MAXCLS * 16 && align == 16 ? (need + 15) / 16 : 0; return u;
}
void *malloc(size_t n) { return alloc(n, 16); }
void free(void *p) {
  if (!p) return;
  if (reuse < 0) reuse = getenv("SHUF_REUSE") != 0;
  size_t cl = ((Hdr *)p)[-1].pad; if (!reuse || !cl) return;
  pthread_mutex_lock(&L); Slab *s = &slabs[cl];
  if (s->npool == s->cap) { uint32_t nc = s->cap ? s->cap * 2 : 1024; char **q = raw((size_t)nc * 8); if (s->npool) memcpy(q, s->pool, (size_t)s->npool * 8); s->pool = q; s->cap = nc; }
  s->pool[s->npool++] = (char *)p - sizeof(Hdr); pthread_mutex_unlock(&L);
}
void *calloc(size_t a, size_t b) { size_t n = a * b; void *p = alloc(n, 16); memset(p, 0, n); return p; }
void *realloc(void *p, size_t n) { if (!p) return alloc(n, 16); size_t o = ((Hdr *)p)[-1].size; if (n <= o) { ((Hdr *)p)[-1].size = n; return p; } void *q = alloc(n, 16); memcpy(q, p, o); return q; }
void *memalign(size_t a, size_t n) { return alloc(n, a); }
void *aligned_alloc(size_t a, size_t n) { return alloc(n, a); }
int posix_memalign(void **r, size_t a, size_t n) { *r = alloc(n, a); return 0; }
void *valloc(size_t n) { return alloc(n, 4096); }
void *pvalloc(size_t n) { return alloc((n + 4095) & ~(size_t)4095, 4096); }
size_t malloc_usable_size(void *p) { return p ? ((Hdr *)p)[-1].size : 0; }
