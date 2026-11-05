// Several modules in one process, launched by path as the Triton backend launches them (triton_vortex runtime.py): the module's
// directory is the working directory of the launch and the kernel's name comes from its lookup.txt. host.out <order>:
//   s1, s2   the small module, then the big one, then back, on that schedule
//   mixed    the two schedules in one process
//   lmem     modules with different local memory, by the runtime's tables of each module: kernel_lmem.log (static shared memory),
//            cupbop_launch_fix.txt, kernel_lmem_hi.log. Enough CTAs per core that a CTA with too little of it collides with the others
// All images link at the same addresses, and big.cu has code where small.cu has its symbols (check_layout): a symbol address that
// outlives its module overwrites that code. Each launch is checked here, and `count` of each module has to go on from where
// that module left it, however many other modules ran in between. Prints one line per launch; PASSED when all are right.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fstream>
#include <map>
#include <string>
#include <vector>

struct Dim3 { unsigned x, y, z; };
extern "C" int cudaMalloc(void **, size_t);
extern "C" int cudaFree(void *);
extern "C" int cudaMemcpy(void *, const void *, size_t, int);
extern "C" int cudaLaunchKernel_vortex(const char *, Dim3, Dim3, void **, size_t, void *, int);

static const int kBlock = 128;
static int kGrid = 4, kN = kBlock * kGrid;

static uint32_t small_value(uint32_t x) { return x * 3u + 1u; }
static uint32_t big_round(uint32_t v, uint32_t k) { v = (v ^ (k * 2654435761u)) * 2246822519u; return v ^ (v >> 13); }
static uint32_t big_value(uint32_t v) {
  for (int rep = 0; rep < 2; ++rep)
    for (int a = 1; a <= 4; ++a) for (int b = 1; b <= 4; ++b) for (int c = 1; c <= 4; ++c) for (int d = 1; d <= 4; ++d)
      v = big_round(v, a * 1000 + b * 100 + c * 10 + d);
  return v;
}

static std::map<std::string, uint64_t> symbols(const std::string &module) {
  std::map<std::string, uint64_t> m;
  std::ifstream f(module + "/lookup_global_symbols.txt");
  std::string addr, type, name;
  while (f >> addr >> type && std::getline(f, name)) m[name.substr(1)] = std::stoull(addr, nullptr, 16);   // a demangled name has spaces
  return m;
}

// The test can only tell when the small module's symbols are inside the big module's code.
static bool check_layout(const char *small, const char *big, bool want_pool) {
  auto s = symbols(small), b = symbols(big);
  const uint64_t code_end = b["__DATA_BEGIN__"];
  bool ok = code_end && s.count("count") && s["count"] < code_end;
  if (want_pool) ok = ok && s.count("__ctx_pool") && b.count("__ctx_pool") && s["__ctx_pool"] < code_end;
  printf("layout %s in %s: count 0x%lx __ctx_pool 0x%lx, code ends at 0x%lx: %s\n", small, big, (unsigned long)s["count"],
         (unsigned long)s["__ctx_pool"], (unsigned long)code_end, ok ? "ok" : "FAIL, this test no longer covers the overlap");
  return ok;
}

static int failures = 0;
static std::map<std::string, uint32_t> count_of;
static char base[4096];

// The local memory of the last launch, from the runtime's record (CUPBOP_PERF_KERNEL_FILE).
static long last_lmem() {
  std::ifstream f("perf.jsonl");
  std::string line, last;
  while (std::getline(f, line)) if (!line.empty()) last = line;
  const size_t p = last.find("\"lmem\":");
  return p == std::string::npos ? -1 : std::stol(last.substr(p + 7));
}

// want_lmem < 0: not checked. A module with a `count` (small, big) is also checked on it.
static void step(const char *module, int schedule, size_t shared = kBlock * 4, long want_lmem = -1) {
  const bool big = strstr(module, "big") != nullptr, counted = big || strstr(module, "small") || strstr(module, "launchfix");
  std::vector<uint32_t> x(kN), y(kN + 1, 0);
  for (int i = 0; i < kN; ++i) x[i] = (uint32_t)(i * 2246822519u + count_of[module]);
  void *dx, *dy;
  if (cudaMalloc(&dx, kN * 4) || cudaMalloc(&dy, (kN + 1) * 4)) { printf("FAIL cudaMalloc\n"); exit(1); }
  cudaMemcpy(dx, x.data(), kN * 4, 1);
  cudaMemcpy(dy, y.data(), (kN + 1) * 4, 1);
  int n = kN;
  uint64_t a[3] = {(uint64_t)dx, (uint64_t)dy, (uint64_t)(uint32_t)n};
  void *argv[3] = {&a[0], &a[1], &a[2]};
  std::string dir = std::string(base) + "/" + module, path = dir + "/kernel.vxbin";
  setenv("VORTEX_SCHEDULE_FLAG", std::to_string(schedule).c_str(), 1);
  setenv("VORTEX_LOCALMEM_FLAG", "1", 1);
  if (chdir(dir.c_str())) { perror("chdir"); exit(1); }
  const int rc = cudaLaunchKernel_vortex(path.c_str(), Dim3{(unsigned)kGrid, 1, 1}, Dim3{(unsigned)kBlock, 1, 1}, argv, shared, nullptr, 3);
  if (chdir(base)) { perror("chdir"); exit(1); }
  cudaMemcpy(y.data(), dy, (kN + 1) * 4, 2);
  cudaFree(dx); cudaFree(dy);
  int wrong = 0;
  for (int i = 0; i < kN; ++i) {
    const int blk = i / kBlock, nb = blk * kBlock + (i + 1) % kBlock;
    const uint32_t v = big ? big_value(x[i]) : small_value(x[i]), w = big ? big_value(x[nb]) : small_value(x[nb]);
    wrong += y[i] != v + w;
  }
  const uint32_t want = counted ? (count_of[module] += big ? 2 : 1) : 0;
  const long lmem = want_lmem < 0 ? -1 : last_lmem();
  const bool ok = rc == 0 && !wrong && y[kN] == want && lmem == want_lmem;
  failures += !ok;
  printf("%s s%d: %d wrong values of %d, count %u (want %u), local memory %ld (want %ld): %s\n", module, schedule, wrong, kN, y[kN], want, lmem, want_lmem, ok ? "ok" : "FAIL");
  fflush(stdout);
}

int main(int argc, char **argv) {
  const std::string order = argc > 1 ? argv[1] : "s1";
  if (!getcwd(base, sizeof base)) return 1;
  bool ok = true;
  if (order == "s1" || order == "mixed") ok = check_layout("mmt_small_s1", "mmt_big_s1", true) && ok;
  if (order == "s2" || order == "mixed") ok = check_layout("mmt_small_s2", "mmt_big_s2", false) && ok;
  if (!ok) { printf("FAIL layout\n"); return 1; }
  if (order == "s1") {
    for (int i = 0; i < 2; ++i) { step("mmt_small_s1", 1); step("mmt_big_s1", 1); }
    step("mmt_small_s1", 1); step("mmt_small_s1", 1); step("mmt_big_s1", 1);
  } else if (order == "s2") {
    for (int i = 0; i < 2; ++i) { step("mmt_small_s2", 2); step("mmt_big_s2", 2); }
  } else if (order == "lmem") {
    kGrid = 32; kN = kBlock * kGrid;
    setenv("CUPBOP_PERF_KERNEL_FILE", (std::string(base) + "/perf.jsonl").c_str(), 1);
    for (int i = 0; i < 2; ++i) {
      step("mmt_static_s2", 2, 0, 4096);
      step("mmt_static2_s2", 2, 0, 8192);
      step("mmt_static_s1", 1, 0, 4096);
      step("mmt_launchfix_s2", 2, 0, 512);   // the program launches it with no dynamic shared memory: cupbop_launch_fix.txt
      step("mmt_lmemhi_s2", 2, 0, 1024);     // declares 8 KB, touches less: kernel_lmem_hi.log
      step("mmt_static2_s2", 2, 0, 8192);
    }
  } else {
    step("mmt_small_s2", 2); step("mmt_big_s1", 1); step("mmt_small_s1", 1); step("mmt_big_s2", 2);
    step("mmt_big_s1", 1); step("mmt_small_s2", 2); step("mmt_small_s1", 1); step("mmt_big_s2", 2);
  }
  printf("multi_module_test %s: %s\n", order.c_str(), failures ? "FAILED" : "PASSED");
  return failures != 0;
}
