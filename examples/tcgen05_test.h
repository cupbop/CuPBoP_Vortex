#pragma once
#include "async_common.h"

static __device__ __forceinline__ void tcgen_after_sync() {
  asm volatile("tcgen05.fence::after_thread_sync;" ::: "memory");
}
static __device__ __forceinline__ void tcgen_before_sync() {
  asm volatile("tcgen05.fence::before_thread_sync;" ::: "memory");
}

static int dump_tcgen_words(const char *path, const int *words, size_t count) {
  if (!getenv("CUPBOP_TCGEN_DUMP")) return 0;
  FILE *f = fopen(path, "wb");
  if (!f) return 1;
  bool ok = fwrite(words, sizeof(*words), count, f) == count;
  return fclose(f) != 0 || !ok;
}
