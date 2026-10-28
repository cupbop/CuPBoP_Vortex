#include "cudaRuntimeImpl.h"
#include "base_address.h"
#include "api.h"
#include "cuda_runtime.h"
#include "def.h"
#include "macros.h"
#include "structures.h"
#include <bits/stdint-uintn.h>
#include <cstddef>
#include <algorithm>
#include <iostream>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <vortex.h>
#include <fstream>
#include <limits>
#include <vector>
#include <map>
#include <set>
#include <sstream>

// DepthFlexGPU rt_num_warps knob: VX_RT_NUM_WARPS=<k> caps the warps the Vortex CTA dispatcher uses
// per core (a runtime DCR, see vortex sw/runtime/common/queue.cpp). The launch checks below must use
// the effective count, or a block/CTA that needs more warps than the cap would never be admitted.
static uint32_t cupbop_rt_num_warps() {   // 0 = no cap
  static const uint32_t v = []() -> uint32_t {
    if (const char *e = getenv("VX_RT_NUM_WARPS")) { int k = atoi(e); if (k > 0) return (uint32_t)k; }
    return 0;
  }();
  return v;
}
#define CUPBOP_EFF_NUM_WARPS() ((cupbop_rt_num_warps() > 0 && cupbop_rt_num_warps() < (uint32_t)NUM_WARPS_VX) ? cupbop_rt_num_warps() : (uint32_t)NUM_WARPS_VX)
// DepthFlexGPU rt_simd_width knob ("as-if NT=k"): VX_RT_SIMD_WIDTH=<k> makes the Vortex CTA dispatcher split a
// CTA into warps of k lanes (vortex VX_DCR_KMU_SIMD_WIDTH), so the launch geometry below uses k as the warp
// width. The kernel must be translated and compiled for NT=k (VORTEX_NUM_THREADS=k) on the wider bitstream.
static uint32_t cupbop_rt_simd_width() {   // 0 = full width
  static const uint32_t v = []() -> uint32_t {
    if (const char *e = getenv("VX_RT_SIMD_WIDTH")) { int k = atoi(e); if (k > 0) return (uint32_t)k; }
    return 0;
  }();
  return v;
}
#define CUPBOP_EFF_NUM_THREADS() ((cupbop_rt_simd_width() > 0 && cupbop_rt_simd_width() < (uint32_t)NUM_THREADS_VX) ? cupbop_rt_simd_width() : (uint32_t)NUM_THREADS_VX)


// Global variable to support CudaMemcpytoSymbol
//NOTE: old approach used staging device buffer — replaced with inline args
//std::vector<std::vector<uint64_t> >  memcpy_symbol;
//std::vector<uint64_t> memcpy_symbol_single;
struct MemcpySymbolEntry {
  uint64_t dst_addr;   // symbol device address
  size_t   size;       // data size in bytes
  std::vector<uint8_t> data; // raw host bytes
};
std::vector<MemcpySymbolEntry> memcpy_symbol;
//create string vector
std::vector<std::string> symbol_name_vector;

// ── DXA descriptors (programmed into the DXA DCRs before each kernel launch) ─────────────────────────
// Field layout: vortex sw/runtime/include/dxa.h (VX_DCR_DXA_DESC_* offsets, META = rank | log2(elem)<<3 |
// layout<<5). Rank 1-5; sizes in elements; strides in bytes for dims 1..rank-1; box = elements per dim of
// one transfer; layout 0 = row-major box in shared memory, 1 = K-major (transposed, rank <= 2);
// smem_stride = multicast shared-memory stride between CTAs; fill = 32-bit pattern written for
// out-of-bounds elements (lane-replicated per 4 bytes).
struct DxaDescEntry {
  uint32_t slot;
  uint64_t base_addr;
  uint32_t rank;
  uint32_t size[5];
  uint32_t stride[4];
  uint32_t box[5];
  uint32_t elem_bytes;
  uint32_t layout;
  uint32_t smem_stride;
  uint32_t fill;
};
std::vector<DxaDescEntry> dxa_descriptors;

// returns an error message, or "" when the descriptor can be programmed
static std::string dxa_desc_check(const DxaDescEntry &d) {
  if (d.slot >= 16) return "slot must be 0..15";
  if (d.rank < 1 || d.rank > 5) return "rank must be 1..5";
  if (d.elem_bytes != 1 && d.elem_bytes != 2 && d.elem_bytes != 4 && d.elem_bytes != 8) return "elem_bytes must be 1, 2, 4 or 8";
  if (d.layout > 1) return "layout must be 0 (row-major) or 1 (K-major)";
  if (d.layout == 1 && d.rank > 2) return "K-major layout needs rank <= 2";
  for (uint32_t i = 0; i < d.rank; ++i)
    if (d.box[i] < 1 || d.box[i] > 0xffff) return "box sizes must be 1..65535";
  return "";
}

static void dxa_fill_dense_strides(DxaDescEntry &d) {
  uint64_t st = d.elem_bytes;
  for (uint32_t i = 0; i + 1 < d.rank; ++i) { st *= d.size[i]; d.stride[i] = (uint32_t)st; }
}

static int dxa_queue(DxaDescEntry d, const char *api) {
  std::string err = dxa_desc_check(d);
  if (!err.empty()) {
    fprintf(stderr, "%s: invalid DXA descriptor for slot %u: %s\n", api, d.slot, err.c_str());
    return 1;
  }
  dxa_descriptors.push_back(d);
  return 0;
}

static void dxa_program(vx_device_h dev, const DxaDescEntry &d) {
  // SimX (vortex 3.0 sim/simx/dxa) decides out-of-bounds per <= 64-byte span from the span's first element:
  // when the dim-0 end of the tensor is not on a 64-byte line, a box crossing it copies the bytes after the
  // end instead of the fill value. Say so for descriptors whose boxes can cross it.
  if (d.size[0] % d.box[0] != 0 && (d.base_addr + (uint64_t)d.size[0] * d.elem_bytes) % 64 != 0) {
    static std::set<std::pair<uint32_t, uint64_t>> warned;
    if (warned.insert({d.slot, d.base_addr}).second)
      fprintf(stderr, "warning: DXA slot %u: size0=%u is not a multiple of box0=%u and the dim-0 end is not 64-byte "
                      "aligned; this SimX fills out-of-bounds elements only from the next 64-byte line on\n",
              d.slot, d.size[0], d.box[0]);
  }
  const uint32_t dcr = 0x100 + d.slot * 24; // VX_DCR_DXA_DESC_BASE + slot * VX_DCR_DXA_DESC_STRIDE
  uint32_t esz = 0;
  for (uint32_t b = d.elem_bytes; b > 1; b >>= 1) esz++;
  const uint32_t meta = (d.rank & 7) | (esz << 3) | ((d.layout & 3) << 5);
  vx_dcr_write(dev, dcr + 0, (uint32_t)(d.base_addr & 0xFFFFFFFF)); // BASE_LO
  vx_dcr_write(dev, dcr + 1, (uint32_t)(d.base_addr >> 32));        // BASE_HI
  for (uint32_t i = 0; i < d.rank; ++i) vx_dcr_write(dev, dcr + 2 + i, d.size[i]);       // SIZE0..4
  for (uint32_t i = 0; i + 1 < d.rank; ++i) vx_dcr_write(dev, dcr + 7 + i, d.stride[i]); // STRIDE0..3
  vx_dcr_write(dev, dcr + 11, meta);                                                     // META
  for (uint32_t i = 0; i < d.rank; ++i) vx_dcr_write(dev, dcr + 12 + i, 1);              // ESTRIDE0..4
  vx_dcr_write(dev, dcr + 17, (d.box[0] & 0xFFFF) | ((d.rank > 1 ? d.box[1] & 0xFFFF : 0) << 16)); // TILESIZE01
  if (d.rank > 2)
    vx_dcr_write(dev, dcr + 18, (d.box[2] & 0xFFFF) | ((d.rank > 3 ? d.box[3] & 0xFFFF : 0) << 16)); // TILESIZE23
  if (d.rank > 4) vx_dcr_write(dev, dcr + 19, d.box[4] & 0xFFFF);                        // TILESIZE4
  vx_dcr_write(dev, dcr + 20, d.fill);                                                   // CFILL
  vx_dcr_write(dev, dcr + 21, d.smem_stride);                                            // SMEM_STRIDE
}

// API for host code to program DXA descriptors before kernel launch (they apply to the next launch)
extern "C" void cudaDxaProgramDesc2D(uint32_t slot, uint64_t base_addr,
                                      uint32_t size0, uint32_t size1,
                                      uint32_t stride0_bytes,
                                      uint32_t tile0, uint32_t tile1,
                                      uint32_t elem_bytes) {
  DxaDescEntry d{};
  d.slot = slot; d.base_addr = base_addr; d.rank = 2;
  d.size[0] = size0; d.size[1] = size1; d.stride[0] = stride0_bytes;
  d.box[0] = tile0; d.box[1] = tile1; d.elem_bytes = elem_bytes;
  if (elem_bytes != 1 && elem_bytes != 2 && elem_bytes != 4 && elem_bytes != 8) {
    // pre-2026-10-28 encoding: META = 2 | log2(elem_bytes) << 3 let a larger power of two spill into the
    // LAYOUT field (elem_bytes = 64 -> 4-byte elements, K-major); keep that meaning, prefer cudaDxaProgramDescNd
    uint32_t esz = 0;
    for (uint32_t b = elem_bytes; b > 1; b >>= 1) esz++;
    d.elem_bytes = 1u << (esz & 3);
    d.layout = (esz >> 2) & 3;
  }
  if (dxa_queue(d, "cudaDxaProgramDesc2D")) exit(1);
}

// General form: rank 1-5. strides_bytes (rank-1 entries) may be NULL for a dense tensor.
extern "C" int cudaDxaProgramDescNd(uint32_t slot, uint64_t base_addr, uint32_t rank,
                                    const uint32_t *sizes, const uint32_t *strides_bytes,
                                    const uint32_t *box, uint32_t elem_bytes, uint32_t layout,
                                    uint32_t smem_stride_bytes, uint32_t fill) {
  DxaDescEntry d{};
  d.slot = slot; d.base_addr = base_addr; d.rank = rank;
  d.elem_bytes = elem_bytes; d.layout = layout; d.smem_stride = smem_stride_bytes; d.fill = fill;
  if (rank < 1 || rank > 5 || !sizes || !box) {
    fprintf(stderr, "cudaDxaProgramDescNd: rank must be 1..5 and sizes/box non-NULL\n");
    return 1;
  }
  for (uint32_t i = 0; i < rank; ++i) { d.size[i] = sizes[i]; d.box[i] = box[i]; }
  if (strides_bytes) for (uint32_t i = 0; i + 1 < rank; ++i) d.stride[i] = strides_bytes[i];
  else dxa_fill_dense_strides(d);
  return dxa_queue(d, "cudaDxaProgramDescNd");
}

extern "C" int cudaDxaProgramDesc1D(uint32_t slot, uint64_t base_addr, uint32_t size0, uint32_t tile0,
                                    uint32_t elem_bytes) {
  return cudaDxaProgramDescNd(slot, base_addr, 1, &size0, nullptr, &tile0, elem_bytes, 0, 0, 0);
}

extern "C" int cudaDxaProgramDesc3D(uint32_t slot, uint64_t base_addr, uint32_t size0, uint32_t size1,
                                    uint32_t size2, uint32_t stride0_bytes, uint32_t stride1_bytes,
                                    uint32_t tile0, uint32_t tile1, uint32_t tile2, uint32_t elem_bytes) {
  const uint32_t sz[3] = {size0, size1, size2}, st[2] = {stride0_bytes, stride1_bytes}, bx[3] = {tile0, tile1, tile2};
  return cudaDxaProgramDescNd(slot, base_addr, 3, sz, st, bx, elem_bytes, 0, 0, 0);
}

// ── TMA tensor maps: CUDA driver API shim (software mode) ──────────────────────────────────────────
// cuTensorMapEncodeTiled writes a cupbop_tmap record (runtime/include/cupbop_async.h) into the 128-byte
// CUtensorMap and uploads a copy to device memory; record.self (the first 8 bytes) is that copy's device
// address, which is what reaches the kernel for a by-value CUtensorMap argument (8 bytes per argument).
// The device helpers (cudaKernelImpl_async.inc) copy boxes in software. Refused with an error (returned
// CUDA_ERROR_INVALID_VALUE = 1 and a message), never encoded approximately: swizzle, interleave, element
// strides other than 1, misaligned addresses or strides. Signature as in cuda.h (enums are int-sized).
#include "cupbop_async.h"
static_assert(sizeof(cupbop_tmap) <= 128, "cupbop_tmap must fit in a CUtensorMap");
extern "C" int cuTensorMapEncodeTiled(void *tensorMap, int tensorDataType, uint32_t tensorRank, void *globalAddress,
                                      const uint64_t *globalDim, const uint64_t *globalStrides,
                                      const uint32_t *boxDim, const uint32_t *elementStrides, int interleave,
                                      int swizzle, int l2Promotion, int oobFill) {
  (void)l2Promotion; // a cache hint
  auto bad = [](const std::string &why) {
    fprintf(stderr, "cuTensorMapEncodeTiled (CuPBoP): %s\n", why.c_str());
    return 1; // CUDA_ERROR_INVALID_VALUE
  };
  static const uint32_t elem_of[13] = {1, 2, 4, 4, 8, 8, 2, 4, 8, 2, 4, 4, 4};
  if (!tensorMap || ((uintptr_t)tensorMap & 63)) return bad("tensorMap must be a 64-byte aligned CUtensorMap");
  if (tensorDataType < 0 || tensorDataType > 12)
    return bad("data type " + std::to_string(tensorDataType) + " is not supported (1/2/4/8-byte types only)");
  if (tensorRank < 1 || tensorRank > 5) return bad("rank must be 1..5");
  if (!globalAddress || ((uintptr_t)globalAddress & 15)) return bad("globalAddress must be 16-byte aligned");
  if (!globalDim || !boxDim || (tensorRank > 1 && !globalStrides)) return bad("NULL globalDim / globalStrides / boxDim");
  if (interleave != 0) return bad("interleave other than CU_TENSOR_MAP_INTERLEAVE_NONE is not supported");
  if (swizzle != 0)
    return bad("swizzle other than CU_TENSOR_MAP_SWIZZLE_NONE is not supported yet (async design stage 4)");
  if (oobFill != 0 && oobFill != 1) return bad("unknown oobFill");
  cupbop_tmap r;
  memset(&r, 0, sizeof(r));
  r.magic = CUPBOP_TMAP_MAGIC;
  r.rank = tensorRank;
  r.gaddr = (uint64_t)(uintptr_t)globalAddress;
  r.elem = elem_of[tensorDataType];
  r.dtype = (uint32_t)tensorDataType;
  r.mode = CUPBOP_TMAP_MODE_SW;
  const bool is_float = tensorDataType >= 6; // FLOAT16 .. TFLOAT32_FTZ
  r.oob_nan = (oobFill == 1 && is_float) ? 1u : 0u;
  for (uint32_t i = 0; i < tensorRank; ++i) {
    if (globalDim[i] < 1 || globalDim[i] > (1ull << 32)) return bad("globalDim must be 1..2^32");
    if (boxDim[i] < 1 || boxDim[i] > 256) return bad("boxDim must be 1..256");
    if (elementStrides && elementStrides[i] != 1)
      return bad("elementStrides other than 1 are not supported (software tensor maps)");
    r.dim[i] = (uint32_t)std::min<uint64_t>(globalDim[i], 0xFFFFFFFFull);
    r.box[i] = boxDim[i];
  }
  if ((uint64_t)boxDim[0] * r.elem % 16) return bad("boxDim[0] * element size must be a multiple of 16 bytes");
  for (uint32_t i = 0; i + 1 < tensorRank; ++i) {
    if (globalStrides[i] % 16 || globalStrides[i] >= (1ull << 40))
      return bad("globalStrides must be multiples of 16 below 2^40");
    r.stride[i] = globalStrides[i];
  }
  void *dev = nullptr;
  if (cudaMalloc(&dev, 128) != cudaSuccess || !dev) return bad("cudaMalloc of the device record failed");
  r.self = (uint64_t)(uintptr_t)dev;
  uint8_t img[128];
  memset(img, 0, sizeof(img));
  memcpy(img, &r, sizeof(r));
  if (cudaMemcpy(dev, img, sizeof(img), cudaMemcpyHostToDevice) != cudaSuccess) return bad("upload of the record failed");
  memcpy(tensorMap, img, sizeof(img));
  return 0; // CUDA_SUCCESS
}
extern "C" int cuTensorMapEncodeIm2col(void *, int, uint32_t, void *, const uint64_t *, const uint64_t *, const int *,
                                       const int *, uint32_t, uint32_t, const uint32_t *, int, int, int, int) {
  fprintf(stderr, "cuTensorMapEncodeIm2col (CuPBoP): im2col tensor maps are not supported\n");
  return 1;
}

// Kernels that use mbarrier waits / TMA / bulk copies (warp-specialized synchronization) are listed by the
// translator in cupbop_async_kernels.txt. The core mapping (schedule 1) runs them only as a de facto 1:1
// mapping, one logical warp per physical warp (P == the CTA's warps); anything else is refused at launch.
static bool cupbop_async_kernel(const std::string &kname) {
  static const std::vector<std::string> names = []() {
    std::vector<std::string> v;
    std::ifstream f("cupbop_async_kernels.txt");
    std::string s;
    while (f >> s) v.push_back(s);
    return v;
  }();
  for (auto &n : names)
    if (!kname.empty() && (kname.find(n) != std::string::npos || n.find(kname) != std::string::npos)) return true;
  return false;
}

// ── dxa_descriptors.txt sidecar (read from the working directory at the first launch) ──
// Legacy line (the automatic cp.async conversion): kernel slot ptr_arg dim0_arg dim1_arg tile0 tile1 elem_bytes
//   -> rank 2, sizes from the integer arguments, dense row stride.
// v2 line (kernelTranslator from !vx.dxa.desc, or by hand):
//   desc <kernel> slot=S base=argK[+B] size=v,.. [stride=v,..] box=t,.. elem=E [rank=R] [layout=row|kmajor]
//        [smem_stride=B] [fill=P | fillf=F]
//   v = integer literal, argK (kernel argument K, read as 32 bits) or a '*' product of those;
//   base = argK (64-bit pointer argument) plus an optional byte offset.
struct DxaAutoDescEntry {
  std::string kernel_name;
  bool v2 = false;
  // legacy
  uint32_t slot = 0;
  int ptr_arg_idx = -1, dim0_arg_idx = -1, dim1_arg_idx = -1;
  uint32_t tile0 = 0, tile1 = 0, elem_bytes = 0;
  // v2
  std::map<std::string, std::string> kv;
  std::string line;
};
static std::vector<DxaAutoDescEntry> dxa_auto_descriptors;
static bool dxa_auto_loaded = false;

static void load_dxa_auto_descriptors() {
  if (dxa_auto_loaded) return;
  dxa_auto_loaded = true;
  std::ifstream ifs("dxa_descriptors.txt");
  if (!ifs.is_open()) return;
  std::string line;
  while (std::getline(ifs, line)) {
    if (line.empty() || line[0] == '#') continue;
    DxaAutoDescEntry e;
    std::istringstream iss(line);
    std::string first;
    iss >> first;
    if (first == "desc") {
      e.v2 = true;
      e.line = line;
      iss >> e.kernel_name;
      std::string tok;
      while (iss >> tok) {
        size_t eq = tok.find('=');
        if (eq == std::string::npos) {
          fprintf(stderr, "dxa_descriptors.txt: bad token `%s` in: %s\n", tok.c_str(), line.c_str());
          exit(1);
        }
        e.kv[tok.substr(0, eq)] = tok.substr(eq + 1);
      }
      dxa_auto_descriptors.push_back(e);
      continue;
    }
    e.kernel_name = first;
    iss >> e.slot >> e.ptr_arg_idx
        >> e.dim0_arg_idx >> e.dim1_arg_idx
        >> e.tile0 >> e.tile1 >> e.elem_bytes;
    if (!iss.fail()) dxa_auto_descriptors.push_back(e);
  }
}

// v2 value: product of integer literals and argK terms (32-bit argument values)
static bool dxa_eval(const std::string &v, void **args, int num_args, uint64_t &out) {
  out = 1;
  std::stringstream ss(v);
  std::string term;
  bool any = false;
  while (std::getline(ss, term, '*')) {
    any = true;
    if (term.rfind("arg", 0) == 0) {
      char *end = nullptr;
      long k = std::strtol(term.c_str() + 3, &end, 10);
      if (*end || k < 0 || k >= num_args) return false;
      uint32_t a = 0;
      memcpy(&a, args[k], sizeof(uint32_t));
      out *= a;
    } else {
      char *end = nullptr;
      long long c = std::strtoll(term.c_str(), &end, 0);
      if (term.empty() || *end) return false;
      out *= (uint64_t)c;
    }
  }
  return any;
}

static bool dxa_v2_resolve(const DxaAutoDescEntry &e, void **args, int num_args, DxaDescEntry &d, std::string &err) {
  auto get = [&](const char *k) -> const std::string * { auto it = e.kv.find(k); return it == e.kv.end() ? nullptr : &it->second; };
  auto list = [](const std::string &v) { std::vector<std::string> o; std::stringstream ss(v); std::string t; while (std::getline(ss, t, ',')) o.push_back(t); return o; };
  d = DxaDescEntry{};
  for (const char *k : {"slot", "base", "size", "box", "elem"})
    if (!get(k)) { err = std::string("missing ") + k + "="; return false; }
  d.slot = (uint32_t)std::strtoul(get("slot")->c_str(), nullptr, 0);
  {
    const std::string &b = *get("base");
    size_t plus = b.find('+');
    std::string a = b.substr(0, plus);
    char *end = nullptr;
    long k = a.rfind("arg", 0) == 0 ? std::strtol(a.c_str() + 3, &end, 10) : -1;
    if (k < 0 || k >= num_args || (end && *end)) { err = "base must be argK[+bytes] with K < " + std::to_string(num_args); return false; }
    memcpy(&d.base_addr, args[k], sizeof(uint64_t));
    if (plus != std::string::npos) {
      uint64_t off;
      if (!dxa_eval(b.substr(plus + 1), args, num_args, off)) { err = "bad base offset"; return false; }
      d.base_addr += off;
    }
  }
  auto sz = list(*get("size")), bx = list(*get("box"));
  d.rank = get("rank") ? (uint32_t)std::strtoul(get("rank")->c_str(), nullptr, 0) : (uint32_t)sz.size();
  if (d.rank < 1 || d.rank > 5 || sz.size() != d.rank || bx.size() != d.rank) { err = "rank / size= / box= mismatch"; return false; }
  d.elem_bytes = (uint32_t)std::strtoul(get("elem")->c_str(), nullptr, 0);
  for (uint32_t i = 0; i < d.rank; ++i) {
    uint64_t v;
    if (!dxa_eval(sz[i], args, num_args, v)) { err = "bad size entry `" + sz[i] + "`"; return false; }
    d.size[i] = (uint32_t)v;
    d.box[i] = (uint32_t)std::strtoul(bx[i].c_str(), nullptr, 0);
  }
  if (const std::string *st = get("stride")) {
    auto l = list(*st);
    if (l.size() + 1 != d.rank) { err = "stride= needs rank-1 entries"; return false; }
    for (uint32_t i = 0; i + 1 < d.rank; ++i) {
      uint64_t v;
      if (!dxa_eval(l[i], args, num_args, v)) { err = "bad stride entry `" + l[i] + "`"; return false; }
      d.stride[i] = (uint32_t)v;
    }
  } else {
    dxa_fill_dense_strides(d);
  }
  if (const std::string *l = get("layout")) {
    if (*l == "row") d.layout = 0;
    else if (*l == "kmajor") d.layout = 1;
    else { err = "layout must be row or kmajor"; return false; }
  }
  if (const std::string *v = get("smem_stride")) d.smem_stride = (uint32_t)std::strtoul(v->c_str(), nullptr, 0);
  if (const std::string *v = get("fill")) d.fill = (uint32_t)std::strtoll(v->c_str(), nullptr, 0);
  if (const std::string *v = get("fillf")) { float f = std::strtof(v->c_str(), nullptr); memcpy(&d.fill, &f, 4); }
  err = dxa_desc_check(d);
  return err.empty();
}

// Debug print macros — enabled by setting CUPBOP_DEBUG=1 environment variable
static bool cupbop_debug_enabled() {
    static bool enabled = (std::getenv("CUPBOP_DEBUG") != nullptr);
    return enabled;
}
#define DBG_PRINT(...) do { if (cupbop_debug_enabled()) printf(__VA_ARGS__); } while(0)
#define DBG_COUT(x) do { if (cupbop_debug_enabled()) std::cout << x; } while(0)

#define RT_CHECK(_expr)                                         \
   do {                                                         \
     int _ret = _expr;                                          \
     if (0 == _ret)                                             \
       break;                                                   \
     printf("Error: '%s' returned %d!\n", #_expr, (int)_ret);   \
     std::abort();                                              \
   } while (false)


// Different structure based on the architecture
#ifdef VORTEX_ARCHITECTURE_64
  struct alignas(4) context_t {
    uint32_t num_groups[3];
    uint32_t global_offset[3];
    uint32_t local_size[3];
    char * printf_buffer;
    uint32_t printf_buffer_position;
    uint32_t printf_buffer_capacity;
    uint32_t work_dim;
    uint32_t dyn_shared_mem_size;
  };

#else
  struct alignas(4) context_t {
    uint32_t num_groups[3];
    uint32_t global_offset[3];
    uint32_t local_size[3];
    uint32_t printf_buffer;
    uint32_t printf_buffer_position;
    uint32_t printf_buffer_capacity;
    uint32_t work_dim;
    uint32_t dyn_shared_mem_size;
  };
#endif


struct alignas(64) kernel_arg_t {
  context_t ctx;
  int kernel_idx;
  int num_args;
  uint64_t  args[0];
};

typedef void (*pfn_workgroup_func) (
  const void* args,
  const context_t* context,
  uint32_t group_x,
  uint32_t group_y,
  uint32_t group_z
);

class DeviceContext {
private:
  DeviceContext()
    : device_(nullptr)
    , staging_buf_(std::vector<uint8_t>())
    , staging_size_(0)
    , krnl_buffer_(nullptr)
    , args_buffer_(nullptr)
    , module_(nullptr)
    , kernel_(nullptr)
    , queue_(nullptr)
  {
    RT_CHECK(vx_dev_open(&device_));
    // CUPBOP_LAUNCH2: one in-order queue for kernel launches (vx_enqueue_launch).
    vx_queue_info_t qi = { sizeof(qi), nullptr, VX_QUEUE_PRIORITY_NORMAL, 0 };
    RT_CHECK((int)vx_queue_create(device_, &qi, &queue_));
  }

  ~DeviceContext() {
    if (device_ != nullptr) {
      // Cleanup buffers
      if (krnl_buffer_ != nullptr)
	vx_mem_free(krnl_buffer_);
      if (args_buffer_ != nullptr)
	vx_mem_free(args_buffer_);
      if (kernel_) vx_kernel_release(kernel_);
      if (module_) vx_module_release(module_);
      if (queue_)  vx_queue_release(queue_);
      vx_dev_close(device_);
    }
  }

public:
  void cleanup_args() {
    if (args_buffer_ != nullptr) {
      vx_mem_free(args_buffer_);
      args_buffer_ = nullptr;
    }
  }

  void cleanup_krnl() {
    if (krnl_buffer_ != nullptr) {
      vx_mem_free(krnl_buffer_);
      krnl_buffer_ = nullptr;
    }
    if (kernel_) { vx_kernel_release(kernel_); kernel_ = nullptr; }
    if (module_) { vx_module_release(module_); module_ = nullptr; }
    last_krnl_path_.clear();
  }

  // CUPBOP_LAUNCH2: load kernel.vxbin as a module and resolve the single CuPBoP
  // entry (generated kernel_main, exposed by the vxbin symbol footer as "main").
  void load_module(const std::string& path) {
    RT_CHECK((int)vx_module_load_file(device_, path.c_str(), &module_));
    RT_CHECK((int)vx_module_get_kernel(module_, "main", &kernel_));
  }
  vx_module_h module() const { return module_; }
  vx_kernel_h kernel() const { return kernel_; }
  vx_queue_h  queue()  const { return queue_; }

  const std::string& last_krnl_path() const { return last_krnl_path_; }
  void set_last_krnl_path(const std::string& p) { last_krnl_path_ = p; }
private:

  vx_device_h device_;
  std::vector<uint8_t> staging_buf_;
  size_t staging_size_;

  // Buffers
  vx_buffer_h krnl_buffer_;
  vx_buffer_h args_buffer_;
  std::string last_krnl_path_;
  vx_module_h module_;
  vx_kernel_h kernel_;
  vx_queue_h  queue_;

  // Pointer manager
  struct MemoryInfo {
    vx_buffer_h buffer_handle;
    size_t size;
    uint64_t base_addr;

    MemoryInfo() : buffer_handle(nullptr), size(0), base_addr(0) {}
    MemoryInfo(vx_buffer_h handle, size_t sz, uint64_t base)
        : buffer_handle(handle), size(sz), base_addr(base) {}
  };
  std::map<void*, MemoryInfo> ptr_map;
  
public:
  static DeviceContext* instance() {
    static DeviceContext s_inst;
    return &s_inst;
  }

  vx_device_h device() {    
    return device_;
  }

  vx_buffer_h* krnl_buffer() {
    return &krnl_buffer_;
  }

  vx_buffer_h* args_buffer() {
    return &args_buffer_;
  }

  vx_buffer_h get_krnl_buf() {
    return krnl_buffer_;
  }

  vx_buffer_h get_args_buf() {
    return args_buffer_;
  }
  
  std::vector<uint8_t> staging_alloc(size_t size) {
    staging_buf_.resize(size);
    staging_size_ = size;
    return staging_buf_;
  }

  void dev_mem_alloc(int size, int flag, uint64_t* mem_addr) {
    vx_buffer_h mem_buffer = nullptr;

    // Allocate memory on device
    RT_CHECK(vx_mem_alloc(this->device(), size, flag, &mem_buffer));
    RT_CHECK(vx_mem_address(mem_buffer, mem_addr));  

    // Register pointer with its handler
    ptr_map[(void*)(*mem_addr)] = MemoryInfo(mem_buffer, size, *mem_addr);
  }

  void dev_mem_free(void* mem_addr) {
    if (ptr_map.find(mem_addr) != ptr_map.end()) {
      MemoryInfo& info = ptr_map[mem_addr];
      vx_mem_free(info.buffer_handle);
      ptr_map.erase(mem_addr);
    }
  }

  void copy_to_dev(uint64_t mem_addr, void* host_ptr, int count) {
    // 정확한 주소 매칭
    auto it = ptr_map.find((void*)mem_addr);
    if (it != ptr_map.end()) {
      RT_CHECK(vx_copy_to_dev(it->second.buffer_handle, host_ptr, 0, count));
      return;
    }
    // 오프셋 기반 검색 (Triton: 할당 블록 내부 주소)
    for (auto& pair : ptr_map) {
      const MemoryInfo& info = pair.second;
      if (mem_addr >= info.base_addr && mem_addr < (info.base_addr + info.size)) {
        size_t offset = mem_addr - info.base_addr;
        if (offset + count <= info.size) {
          RT_CHECK(vx_copy_to_dev(info.buffer_handle, host_ptr, offset, count));
          return;
        }
      }
    }
    printf("copy_to_dev: ERROR - mem_addr=0x%lx not found!\n", mem_addr);
    std::abort();
  }

  void copy_from_dev(uint64_t mem_addr, void* host_ptr, int count) {
    // 정확한 주소 매칭
    if (ptr_map.find((void*)mem_addr) != ptr_map.end()) {
      auto& info = ptr_map[(void*)mem_addr];
      RT_CHECK(vx_copy_from_dev(host_ptr, info.buffer_handle, 0, count));
      return;
    }
    // 오프셋 기반 검색 (Triton: 할당 블록 내부 주소)
    for (auto& pair : ptr_map) {
      const MemoryInfo& info = pair.second;
      if (mem_addr >= info.base_addr && mem_addr < (info.base_addr + info.size)) {
        size_t offset = mem_addr - info.base_addr;
        if (offset + count <= info.size) {
          RT_CHECK(vx_copy_from_dev(host_ptr, info.buffer_handle, offset, count));
          return;
        }
      }
    }
    printf("copy_from_dev: ERROR - mem_addr=0x%lx not found!\n", mem_addr);
    std::abort();
  }

  void cleanup() {
    if (device_ != nullptr) { 
      if (krnl_buffer_ != nullptr)
	vx_mem_free(krnl_buffer_);
      if (args_buffer_ != nullptr)
	vx_mem_free(args_buffer_);

      vx_dev_close(device_);
      device_ = nullptr;
    }
  }
};

auto DC_init = DeviceContext::instance();

uint64_t NUM_THREADS_VX, NUM_WARPS_VX, NUM_CORES_VX;
int caps_return1 = vx_dev_caps(DC_init->device(), VX_CAPS_NUM_THREADS, &NUM_THREADS_VX);
int caps_return2 = vx_dev_caps(DC_init->device(), VX_CAPS_NUM_WARPS, &NUM_WARPS_VX);
int caps_return3 = vx_dev_caps(DC_init->device(), VX_CAPS_NUM_CORES, &NUM_CORES_VX);

// ─── CUPBOP_LAUNCH2 helpers (Vortex 3.0 KMU launch path) ──────────────────────
// The device wrapper exposes one entry (kernel_main). A launch with
// kernel_arg_t.kernel_idx >= 0 runs CUDA kernel #idx with the hardware CTA
// dispatcher placing the grid; kernel_idx == -1 / -2 are single-thread service
// launches (apply cudaMemcpyToSymbol list / device->device copies) used instead
// of host-side writes into the module image.
static int cupbop_schedule_flag() {
  if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) return std::stoi(std::string(env));
  return 2;
}
static std::string cupbop_strip_prefix(const std::string &s) {
  size_t i = 0;
  if (s.size() > 2 && s[0] == '_' && s[1] == 'Z') i = 2;
  while (i < s.size() && (s[i] == 'L' || (s[i] >= '0' && s[i] <= '9'))) i++;
  return s.substr(i);
}
// Per-kernel static __shared__ bytes, written by mem_share2local into kernel_lmem.log.
static uint32_t cupbop_static_lmem_bytes(const std::string &func_stripped) {
  static std::map<std::string, uint32_t> table;
  static bool loaded = false;
  if (!loaded) {
    loaded = true;
    std::ifstream f("kernel_lmem.log");
    std::string name; uint32_t bytes;
    while (f >> name >> bytes) {
      std::string k = cupbop_strip_prefix(name);
      if (table[k] < bytes) table[k] = bytes;
    }
  }
  auto it = table.find(func_stripped);
  return it == table.end() ? 0u : it->second;
}
static void cupbop_launch_blob(DeviceContext *DC, const void *blob, size_t size, uint32_t ndim,
                               const uint32_t grid[3], const uint32_t block[3], uint32_t lmem_bytes) {
  vx_launch_info_t li = {};
  li.struct_size = sizeof(li);
  li.kernel      = DC->kernel();
  li.args_host   = blob;
  li.args_size   = size;
  li.ndim        = ndim;
  for (int i = 0; i < 3; ++i) { li.grid_dim[i] = grid[i]; li.block_dim[i] = block[i]; li.cluster_dim[i] = 1; }
  li.lmem_size   = lmem_bytes;
  vx_event_h ev = nullptr;
  RT_CHECK((int)vx_enqueue_launch(DC->queue(), &li, 0, nullptr, &ev));
  RT_CHECK((int)vx_event_wait_value(ev, 1, VX_TIMEOUT_INFINITE));
  vx_event_release(ev);
}
// Service launch (grid 1, block 1): kernel_idx -1 or -2 with the op list after the header.
static void cupbop_service_launch(DeviceContext *DC, int kind, const std::vector<uint64_t> &list) {
  std::vector<uint8_t> blob(sizeof(kernel_arg_t) + list.size() * sizeof(uint64_t), 0);
  auto *ka = (kernel_arg_t *)blob.data();
  ka->kernel_idx = kind;
  ka->num_args = 0;
  memcpy(ka->args, list.data(), list.size() * sizeof(uint64_t));
  uint32_t one[3] = {1, 1, 1};
  cupbop_launch_blob(DC, blob.data(), blob.size(), 1, one, one, 0);
}
// Read device memory that lives inside the module image (BSS / __device__ vars):
// the service kernel copies each range into a host-visible staging buffer.
static void cupbop_read_device_ranges(DeviceContext *DC, const std::vector<std::pair<uint64_t, size_t>> &ranges,
                                      const std::vector<void *> &dsts) {
  if (ranges.empty()) return;
  size_t total = 0;
  for (auto &r : ranges) total += (r.second + 7) & ~size_t(7);
  static uint64_t staging_addr = 0; static size_t staging_cap = 0;
  if (total > staging_cap) {
    if (staging_addr) DC->dev_mem_free((void *)staging_addr);
    DC->dev_mem_alloc((int)total, VX_MEM_READ_WRITE, &staging_addr);
    staging_cap = total;
  }
  std::vector<uint64_t> list; list.push_back(ranges.size());
  uint64_t off = 0;
  for (auto &r : ranges) { list.push_back(staging_addr + off); list.push_back(r.first); list.push_back(r.second); off += (r.second + 7) & ~size_t(7); }
  cupbop_service_launch(DC, -2, list);
  std::vector<uint8_t> host(total);
  DC->copy_from_dev(staging_addr, host.data(), (int)total);
  off = 0;
  for (size_t i = 0; i < ranges.size(); ++i) { memcpy(dsts[i], host.data() + off, ranges[i].second); off += (ranges[i].second + 7) & ~size_t(7); }
}


extern "C" {

cudaError_t cudaGetDevice(int *devPtr) { 
  *devPtr = 0;
  return cudaSuccess;
}

const char *cudaGetErrorName(cudaError_t error) { 
  return "SUCCESS\n";
}

cudaError_t cudaDeviceReset(void) { 
  scheduler_uninit(); 
  return cudaSuccess;
}

cudaError_t cudaDeviceSynchronize(void) { 
  cuSynchronizeBarrier(); 
  return cudaSuccess;
}

cudaError_t cudaThreadSynchronize(void) { 
  cuSynchronizeBarrier(); 
  return cudaSuccess;
}

cudaError_t cudaFreeHost(void *devPtr) { 
  free(devPtr);
  return cudaSuccess;
}

cudaError_t cudaMalloc(void **devPtr, size_t size) {
  auto DC = DeviceContext::instance();
  uint64_t mem_addr;  
  // RT_CHECK(vx_mem_alloc(DC->device(), size, VX_MEM_TYPE_GLOBAL, &mem_addr));
  // RT_CHECK(vx_mem_alloc(DC->device(), size, VX_MEM_READ_WRITE, (void** )&mem_addr));
  DC->dev_mem_alloc(size, VX_MEM_READ_WRITE, &mem_addr);
  
  DBG_PRINT("cudaMalloc: size=%ld, mem_addr=%p\n", size, mem_addr);
  *devPtr = (void*)mem_addr;
   return cudaSuccess;
}

cudaError_t cudaFree(void *devPtr) {
  auto DC = DeviceContext::instance(); 
  uint64_t mem_addr = (uint64_t)devPtr;  
  // vx_mem_free(DC->device(), mem_addr);
  DC->dev_mem_free(devPtr);
  
  DBG_PRINT("cudaFree: mem_addr=%lu\n", mem_addr);
  return cudaSuccess;
}

cudaError_t cudaMemset(void *devPtr, int value, size_t count) {  
  void* tmp_ptr;
  tmp_ptr = (void *) malloc(count);
  memset(tmp_ptr, value, count);

  auto DC = DeviceContext::instance();
  auto staging_buf = DC->staging_alloc(count);
  auto host_ptr = staging_buf.data();

  memcpy((char *)host_ptr, tmp_ptr, count);
  uint64_t mem_addr = (uint64_t)devPtr;
  // RT_CHECK(vx_copy_to_dev(DC->device(), mem_addr, host_ptr, count));
  DC->copy_to_dev(mem_addr, host_ptr, count);
  
  DBG_PRINT("cudaMemset: value=%d, dst=%lu, count=%ld\n", value, mem_addr, count);
  free(tmp_ptr);
  return cudaSuccess;
}

// cudaError_t cudaMemset(void *devPtr, int value, size_t count) {
//   auto DC = DeviceContext::instance();
//   auto staging_buf = DC->staging_alloc(count);
//   auto host_ptr = staging_buf.data();

//   // 정수 단위로 4바이트 정렬된 메모리에만 동작하는 memset 대체
//   if (count % sizeof(int) != 0) {
//     printf("cudaMemset: count (%lu) is not aligned to sizeof(int)\n", count);
//     return cudaErrorInvalidValue;
//   }

//   size_t num_ints = count / sizeof(int);
//   for (size_t i = 0; i < num_ints; ++i) {
//     host_ptr[i] = value;
//   }

//   uint64_t mem_addr = (uint64_t)devPtr;
//   DC->copy_to_dev(mem_addr, host_ptr, count);

//   printf("cudaMemset: int_value=%d, dst=%lu, count=%lu\n", value, mem_addr, count);
//   return cudaSuccess;
// }

cudaError_t cudaMemcpy(void *dst, const void *src, size_t count, cudaMemcpyKind kind) {
  int vx_err; 
  if (kind == cudaMemcpyHostToHost) {
    memcpy(dst, src, count);
  } else if (kind == cudaMemcpyDeviceToHost) {
    auto DC = DeviceContext::instance();
    auto staging_buf = DC->staging_alloc(count);
    auto host_ptr = staging_buf.data();
    uint64_t mem_addr = (uint64_t)src;
    //  RT_CHECK(vx_copy_from_dev(DC->device(), host_ptr, mem_addr, count));
    DC->copy_from_dev(mem_addr, host_ptr, count);
    memcpy(dst, (char*)host_ptr, count);
    DBG_PRINT("cudamemcpyDeviceToHost: src=%lu, dst=%p, count=%ld\n", mem_addr, dst, count);
  } else if (kind == cudaMemcpyHostToDevice) {
    auto DC = DeviceContext::instance();
    auto staging_buf = DC->staging_alloc(count);
    auto host_ptr = staging_buf.data();
    memcpy((char *)host_ptr, src, count);
    uint64_t mem_addr = (uint64_t)dst;
    DBG_PRINT("(memcpy_) host_ptr value: %d %d, addr: %ld\n", *(char *)src, *(char *)host_ptr, host_ptr);
    // RT_CHECK(vx_copy_to_dev(DC->device(), mem_addr, host_ptr, count));
    DC->copy_to_dev(mem_addr, host_ptr, count);

    DBG_PRINT("cudaMemcpyHostToDevice: src=%p, dst=%lu, count=%ld\n", src, mem_addr, count);
  } else if (kind == cudaMemcpyDeviceToDevice) {
    auto DC = DeviceContext::instance();
    auto staging_buf = DC->staging_alloc(count);
    auto host_ptr = staging_buf.data();
    uint64_t mem_src_addr = (uint64_t)src;
    // RT_CHECK(vx_copy_from_dev(DC->device(), host_ptr, mem_src_addr, count));
    DC->copy_from_dev(mem_src_addr, host_ptr, count);
    RT_CHECK(vx_ready_wait(DC->device(), 1000));
    uint64_t mem_dst_addr = (uint64_t)dst;
    // RT_CHECK(vx_copy_to_dev(DC->device(), mem_dst_addr, host_ptr, count));
    DC->copy_to_dev(mem_dst_addr, host_ptr, count);
    
    DBG_PRINT("cudaMemcpyDeviceToDevice: src=%lu, dst=%lu, count=%ld\n", mem_src_addr, mem_dst_addr, count);
  } else if (kind == cudaMemcpyDefault) {
    std::abort(); // not supported!
  }
  return cudaSuccess;
}


cudaError_t cudaMemcpyFromSymbol(void *dst, 
                                 const void *symbol, 
                                 size_t count, 
                                 size_t offset, 
                                 cudaMemcpyKind kind) {

// 2026 Feb 26, Currently not working!!!
    if (kind != cudaMemcpyDeviceToHost) {
        return cudaErrorInvalidValue;
    }

    std::string symbolName((char*)symbol);
    DBG_PRINT("cudaMemcpyFromSymbol: Looking for symbol '%s'\n", symbolName.c_str());

    std::fstream readfile;
    readfile.open("lookup_global_symbols.txt", std::ios::in);
    if (!readfile.is_open()) {
        printf("Error: Could not open lookup_global_symbols.txt\n");
        return cudaErrorFileNotFound;
    }

    std::string symbol_addr_str;
    std::string symbol_type_tmp;
    std::string symbol_name_tmp;
    uint64_t device_symbol_address = 0;
    bool found = false;

    while(readfile >> symbol_addr_str) {
        readfile >> symbol_type_tmp;
        std::getline(readfile, symbol_name_tmp);
        if (!symbol_name_tmp.empty() && symbol_name_tmp[0] == ' ') {
            symbol_name_tmp = symbol_name_tmp.substr(1);
        }

        if(symbolName == symbol_name_tmp) {
            device_symbol_address = std::stoull(symbol_addr_str, nullptr, 16);
            found = true;
            break;
        }
    }
    readfile.close();

    if (!found) {
        printf("Error: Symbol '%s' not found in lookup_global_symbols.txt\n", symbolName.c_str());
        return cudaErrorInvalidSymbol;
    }

    auto DC = DeviceContext::instance();
    uint64_t source_address = device_symbol_address + offset;

    DBG_PRINT("cudaMemcpyFromSymbol: Copying %zu bytes from device address 0x%llx to host address %p\n",
           count, source_address, dst);
    
    cupbop_read_device_ranges(DC, {{source_address, (size_t)count}}, {dst});

    return cudaSuccess;
}


cudaError_t cudaMemcpyToSymbol_host(void *dst, 
                                    const void *src, 
                                    size_t count,
                                    size_t offset, 
                                    cudaMemcpyKind kind,
                                    void *symbol) {
                                      
  assert(offset == 0 && "DO not support offset !=0\n");

  //symbol is a pointer to a string 
  //print the string that symbol points to
  DBG_PRINT("(CudaMemcpytoSymbol) symbol name: %s\n", symbol);

  // if vector length of symbol_name_vector == 0
  //printf("symbol_name_vector.size(): %lu\n", symbol_name_vector.size());
  if(symbol_name_vector.size() == 0)
  {
    // cast symbol to string
    std::string symbol_name((char*)symbol);
    //split the string by space
    std::string delimiter = " ";
    std::string token;
    size_t pos = 0;
    while ((pos = symbol_name.find(delimiter)) != std::string::npos) {
      token = symbol_name.substr(0, pos);
      symbol_name_vector.push_back(token);
      symbol_name.erase(0, pos + delimiter.length());
    }
  }

  //pop first element in symbol_name_vector
  std::string symbol_name_looking = symbol_name_vector[0];
  DBG_PRINT("symbol name looking: %s\n", symbol_name_looking);  
  
  //open file lookup_global_symbols.txt to read
  std::fstream readfile;
  readfile.open("lookup_global_symbols.txt", std::ios::in);
  std::string symbol_type_tmp;
  std::string symbol_name_tmp;
  std::string symbol_addr_tmp;
  
  //print src value
  DBG_PRINT("src value at initial memcpytosymbol, addr: %p\n", src);
  DBG_PRINT("src value at initial memcpytosymbol %f\n", *((float*)src+1));

  while(readfile >> symbol_addr_tmp)
  {
    readfile >> symbol_type_tmp;
    std::getline(readfile, symbol_name_tmp);
    symbol_name_tmp = symbol_name_tmp.substr(1, symbol_name_tmp.size()-1);  
  
    DBG_COUT("debug : " << symbol_name_looking << " vs " << symbol_name_tmp << std::endl);

    if(symbol_name_looking == symbol_name_tmp)
    {
      DBG_COUT("found the symbol name in the lookup file, it is " << symbol_name_looking << " with the address of " << symbol_addr_tmp << std::endl);
      readfile.close();
      symbol_name_vector.erase(symbol_name_vector.begin());
      break;
    }
  }

  int vx_err;
  //cast string(in hex) to uint64_t
  uint64_t symbol_addr = std::stoull(symbol_addr_tmp, nullptr, 16);

  // print symbol_addr_tmp, and compare it with dst
  DBG_PRINT("symbol_addr_tmp: %p, dst: %p\n", symbol_addr, dst);

  //NOTE: old approach — allocate staging device memory and copy host data there
  //auto DC = DeviceContext::instance();
  //uint64_t mem_addr;
  //DC->dev_mem_alloc(count, VX_MEM_READ_WRITE, &mem_addr);
  //auto staging_buf = DC->staging_alloc(count);
  //auto host_ptr = staging_buf.data();
  //memcpy((char *)host_ptr, src, count);
  //DC->copy_to_dev(mem_addr, host_ptr, count);
  //memcpy_symbol_single.push_back(std::stoull(symbol_addr_tmp, nullptr, 16));
  //memcpy_symbol_single.push_back((uint64_t)mem_addr);
  //memcpy_symbol_single.push_back((uint64_t)count);
  //memcpy_symbol_single.push_back((uint64_t)offset);
  //memcpy_symbol.push_back(memcpy_symbol_single);
  //memcpy_symbol_single.clear();

  // New approach: store raw bytes in host memory, inline into args at launch
  // Update existing entry for same dst_addr (dedup), or add new entry.
  // Entries persist across kernel launches so BSS zeroing doesn't lose data.
  bool found_existing = false;
  for (auto &existing : memcpy_symbol) {
    if (existing.dst_addr == symbol_addr && existing.size == count) {
      memcpy(existing.data.data(), src, count);
      found_existing = true;
      DBG_PRINT("(cudamemcpytosymbol) updated existing: dst=0x%lx, size=%ld\n", symbol_addr, count);
      break;
    }
  }
  if (!found_existing) {
    MemcpySymbolEntry entry;
    entry.dst_addr = symbol_addr;
    entry.size = count;
    entry.data.resize(count);
    memcpy(entry.data.data(), src, count);
    memcpy_symbol.push_back(std::move(entry));
    DBG_PRINT("(cudamemcpytosymbol) saved inline: dst=0x%lx, size=%ld\n", symbol_addr, count);
  }
              
  return cudaSuccess;
}

cudaError_t cudaSetDevice(int device) {
  init_device();  
  return cudaSuccess;
}

cudaError_t cudaStreamCopyAttributes(cudaStream_t dst, cudaStream_t src) {
  cstreamData *dst_stream = (cstreamData *)dst;
  cstreamData *src_stream = (cstreamData *)src;

  if (dst_stream == NULL || src_stream == NULL) {
    return cudaErrorInvalidValue; // 1
  }

  dst_stream->stream_priority = src_stream->stream_priority;
  dst_stream->stream_flags = src_stream->stream_flags;

  return cudaSuccess; // 0
}

static int stream_counter = 1;
/*
  cudaStream_t is a Opaque Structure

  Overwrites cudaStream_t into custom cstreamData structure
  (does hardware uses the cudaStream_t stream)

*/
cudaError_t cudaStreamCreate(cudaStream_t *pStream) {
  cstreamData *s = (cstreamData *)calloc(1, sizeof(cstreamData));
  if (s == NULL)
    return cudaErrorMemoryAllocation;
  s->ev.status = C_RUN;
  s->id = stream_counter;
  stream_counter++;
  s->stream_priority = DEFAULT;
  create_KernelQueue(&(s->kernelQueue));

  INIT_LOCK(s->stream_lock);
  *pStream = (cudaStream_t)(s);

  return cudaSuccess;
}

cudaError_t cudaStreamDestroy(cudaStream_t stream) {
  cstreamData *s = (cstreamData *)(stream);

  free(s->kernelQueue);

  DESTROY_LOCK(s->stream_lock);

  free(s);

  return cudaSuccess;
}

cudaError_t cudaStreamSynchronize(cudaStream_t stream) {
  cstreamData *e = ((cstreamData *)(stream));
  MUTEX_LOCK(e->stream_lock);

  e->ev.status = C_SYNCHRONIZE;
  e->ev.numKernelsToWait = e->kernelQueue->waiting_count;
  MUTEX_UNLOCK(e->stream_lock);

  return cudaSuccess;
}

cudaError_t cudaGetDeviceCount(int *count) {
  // dummy value
  *count = 1;

  return cudaSuccess;
}

cudaError_t cudaGetDeviceProperties(cudaDeviceProp *deviceProp, int device) {

  // dummy values
  if (device == 0) {
    strcpy(deviceProp->name, "pthread");
    deviceProp->totalGlobalMem = 0;
    deviceProp->sharedMemPerBlock = 0;
    deviceProp->regsPerBlock = 0;
    deviceProp->warpSize = 0;
    deviceProp->memPitch = 0;
    deviceProp->maxThreadsPerBlock = 0;
    deviceProp->maxThreadsDim[0] = 1;
    deviceProp->maxThreadsDim[1] = 1;
    deviceProp->maxThreadsDim[2] = 1;

    deviceProp->maxGridSize[0] = 1;
    deviceProp->maxGridSize[1] = 1;
    deviceProp->maxGridSize[2] = 1;

    deviceProp->totalConstMem = 0;
    deviceProp->major = 0;
    deviceProp->minor = 0;
    deviceProp->clockRate = 0;
    deviceProp->textureAlignment = 0;
    deviceProp->deviceOverlap = false;
    deviceProp->multiProcessorCount = 0;
  }
  return cudaSuccess;
}

#ifndef cudaGetDeviceProperties
// Only define _v2 separately when CUDA headers don't macro-expand it
cudaError_t cudaGetDeviceProperties_v2(cudaDeviceProp *deviceProp, int device) {
  return cudaGetDeviceProperties(deviceProp, device);
}
#endif


static cudaError_t lastError = cudaSuccess;
const char *cudaGetErrorString(cudaError_t error) {
  if (error == cudaSuccess) {
    return "cudaSuccess";
  }
  return "unknown";
}

cudaError_t cudaGetLastError(void) { 
  return lastError; 
}

static callParams callParamTemp;

/*
  Internal Cuda Library Functions
*/
extern "C" {

extern cudaError_t CUDARTAPI __cudaPopCallConfiguration(dim3 *gridDim,
                                                        dim3 *blockDim,
                                                        size_t *sharedMem,
                                                        void **stream) {
  //  printf("__cudaPopCallConfiguration: Grid: x:%d y:%d z:%d Block: %d, %d, %d
  //  ShMem: %lu\n",
  // gridDim->x, gridDim->y, gridDim->z, blockDim->x, blockDim->y, blockDim->z,
  // *sharedMem);

  *gridDim = callParamTemp.gridDim;
  *blockDim = callParamTemp.blockDim;
  *sharedMem = callParamTemp.shareMem;
  *stream = callParamTemp.stream;

  // printf("__cudaPopCallConfiguration After : Grid: x:%d y:%d z:%d Block: %d,
  // %d, %d ShMem: %lu\n", gridDim->x, gridDim->y, gridDim->z, blockDim->x,
  // blockDim->y, blockDim->z, *sharedMem);

  // exit(1);

  return cudaSuccess;
}

extern __host__ __device__ unsigned CUDARTAPI __cudaPushCallConfiguration(
    dim3 gridDim, dim3 blockDim, size_t sharedMem = 0, void *stream = 0) {

  // printf("__cudaPushCallConfiguration Grid: x:%d y:%d z:%d Block: %d, %d, %d
  // "
  //        "ShMem: %lu\n ",
  //        gridDim.x, gridDim.y, gridDim.z, blockDim.x, blockDim.y, blockDim.z,
  //        sharedMem);

  // memory checks allocations
  callParamTemp.gridDim = gridDim;

  // std::cout << "assign gridDim" << std::endl;

  callParamTemp.blockDim = blockDim;
  //  std::cout << "assign blockDim" << std::endl;
  callParamTemp.shareMem = sharedMem;
  //  std::cout << "assign shareMem" << std::endl;
  (callParamTemp.stream) = stream;

  //  printf("__cudaPushCallConfiguration After Grid: x:%d y:%d z:%d Block: %d,
  //  %d, %d ShMem: %lu\n",
  //   gridDim.x, gridDim.y, gridDim.z, blockDim.x, blockDim.y, blockDim.z,
  //   sharedMem);

  // return 0 continues the Pop
  return cudaSuccess;

  // return ne 0 skips the Pop
}
} // extern C

cudaError_t cudaLaunchKernel_vortex(                          
                             const char *func, //-> kernel_name
                             dim3 gridDim, 
                             dim3 blockDim,
                             void **args, 
                             size_t sharedMem,
                             cudaStream_t stream,
                             const int num_args
                             ) {

  //open the file lookup.txt and load the content in the memory
  //cpp hash table, look for the kernel name, and retrieve the kerenl index
  
  //DEBUG PURPOSE
  DBG_COUT("RUNTIME FUNCTION" << std::endl);
  DBG_COUT("kernel_name: " << func << std::endl);
  DBG_COUT("number of arguments: " << num_args << std::endl);
  //reading lookup.txt
  std::fstream readfile;
  readfile.open("lookup.txt", std::ios::in);
  std::string kernel_idx_tmp;
  std::string kernel_name_tmp;

  // Strip mangling prefix to get the bare function name for matching.
  // Host func: _ZL19initiPKiS0_Pi → strip _Z, L, digits → initiPKiS0_Pi
  // Lookup:    L4initiPKiS0_Pi   → strip L, digits → initiPKiS0_Pi
  auto stripPrefix = [](const std::string &s) -> std::string {
    size_t i = 0;
    if (s.size() > 2 && s[0] == '_' && s[1] == 'Z') i = 2;
    while (i < s.size() && (s[i] == 'L' || (s[i] >= '0' && s[i] <= '9'))) i++;
    return s.substr(i);
  };
  std::string func_stripped = stripPrefix(std::string(func));
  DBG_COUT("func_stripped: " << func_stripped << std::endl);

  while(readfile >> kernel_idx_tmp) {
    readfile >> kernel_name_tmp;
    readfile.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    std::string lookup_stripped = stripPrefix(kernel_name_tmp);
    DBG_COUT("debug : " << func_stripped << " vs " << lookup_stripped << std::endl);
    if(func_stripped == lookup_stripped) {
      DBG_COUT("found the kernel name in the lookup file, it is " << func << " with the index of " << std::stoi(kernel_idx_tmp) << std::endl);
      break;
    }
  }
  readfile.close();                    
                      
  DBG_PRINT("cudaLaunchKernel: gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), sharedMem=%lu, num_args = %d\n",
    gridDim.x, gridDim.y, gridDim.z, blockDim.x, blockDim.y, blockDim.z, sharedMem, num_args);

  auto DC = DeviceContext::instance();
  DC->cleanup_args();

  int status = C_RUN;
  // upload kernel to device (reload when binary path changes)
  {
    // Use func as path if it looks like a file path (absolute or relative with /), else fallback
    std::string krnl_path = (strchr(func, '/') != nullptr) ? std::string(func) : "./kernel.vxbin";
    if (DC->module() == nullptr || krnl_path != DC->last_krnl_path()) {
      DC->cleanup_krnl();
      DC->load_module(krnl_path);
      DC->set_last_krnl_path(krnl_path);
    }
  }


  // Allocate context pool and set __ctx_pool pointer
  {
    static uint64_t ctx_pool_addr = 0;
    if (!ctx_pool_addr) {
      void *p = nullptr;
      // 32MB pool — score-cuda has ~320 shfl_res allocas × 32KB = 10MB
      cudaMalloc(&p, 32 * 1024 * 1024);
      ctx_pool_addr = (uint64_t)p;
      DBG_PRINT("ctx_pool: 0x%lx\n", ctx_pool_addr);
    }
    // Find __ctx_pool symbol address in ELF
    std::fstream sf("lookup_global_symbols.txt", std::ios::in);
    std::string sa, st, sn;
    while (sf >> sa >> st) {
      std::getline(sf, sn);
      if (!sn.empty() && sn[0] == ' ') sn = sn.substr(1);
      if (sn == "__ctx_pool") {
        uint64_t sym = std::stoull(sa, nullptr, 16);
        MemcpySymbolEntry e;
        e.dst_addr = sym;
        e.size = sizeof(uint64_t);
        e.data.resize(sizeof(uint64_t));
        memcpy(e.data.data(), &ctx_pool_addr, sizeof(uint64_t));
        bool found = false;
        for (auto &x : memcpy_symbol) {
          if (x.dst_addr == sym) { x = std::move(e); found = true; break; }
        }
        if (!found) memcpy_symbol.push_back(std::move(e));
        break;
      }
    }
    sf.close();
  }

  // allocate staging buffer for kernel arguments
  size_t abuf_size = sizeof(kernel_arg_t) + ((num_args > 1) ? (sizeof(uint64_t) * (num_args - 1)) : 0);
  DBG_PRINT("(debug) abuf_size = %ld\n", abuf_size);

  //NOTE: old size calculation — 3 uint64_t per symbol (dst_addr, staging_addr, size)
  //size_t abuf_size_additional = (1 + memcpy_symbol.size() * 3) * sizeof(uint64_t);
  // New: count + per symbol (dst_addr, size, inline data padded to uint64_t)
  size_t abuf_size_additional = sizeof(uint64_t); // count field
  for (auto &entry : memcpy_symbol) {
    size_t data_slots = (entry.size + sizeof(uint64_t) - 1) / sizeof(uint64_t);
    abuf_size_additional += (2 + data_slots) * sizeof(uint64_t); // dst_addr + size + data
  }

  auto staging_buf = DC->staging_alloc(abuf_size+abuf_size_additional);

  auto abuf_ptr = (kernel_arg_t*)staging_buf.data();
  //auto abuf_ptr = (kernel_arg_t*)vx_host_ptr(staging_buf);
  assert(abuf_ptr);

  DBG_PRINT("*** kernel arg=%p, size=%ld\n", abuf_ptr, abuf_size);

  // write context
  context_t ctx;
  memset(&ctx, 0, sizeof(ctx));
  ctx.num_groups[0] = gridDim.x;
  ctx.num_groups[1] = gridDim.y; 
  ctx.num_groups[2] = gridDim.z; 
  ctx.local_size[0] = blockDim.x;
  ctx.local_size[1] = blockDim.y;
  ctx.local_size[2] = blockDim.z;
  ctx.global_offset[0] = 0;
  ctx.global_offset[1] = 0;
  ctx.global_offset[2] = 0;
  ctx.dyn_shared_mem_size = sharedMem;

  memcpy(&abuf_ptr->ctx, &ctx, sizeof(context_t));
  
  // write the kerenel index here it retrives
  abuf_ptr->kernel_idx = std::stoi(kernel_idx_tmp);
  abuf_ptr->num_args = num_args;
  
  // Mark Debug Check 
  //printf("test:: kernel_idx %d sizes: %d %d \n", abuf_ptr->kernel_idx, sizeof(kernel_arg_t), sizeof(context_t));
  //printf("address_check 0x%x, 0x%x, %d\n", &(ctx.num_groups[2]), &(ctx.global_offset[0]), &(ctx.global_offset[0])-&(ctx.num_groups[2]));
  //printf("address_check 0x%x, 0x%x, %d\n", &(ctx.global_offset[1]), &(ctx.global_offset[2]), &(ctx.global_offset[0])-&(ctx.num_groups[2]));
  //printf("global_offset 0x%x, 0x%x, %x\n", ctx.global_offset[0], ctx.global_offset[1], ctx.global_offset[2]);

  DBG_PRINT("*** kernel ctx: num_groups[0]=%d, num_groups[1]=%d\n", abuf_ptr->ctx.num_groups[0],abuf_ptr->ctx.num_groups[1]);

  // write arguments
  for (int i = 0; i < num_args; ++i) {    
    memcpy(&abuf_ptr->args[i], args[i], sizeof(uint64_t)); // 여기 체크 필요
    DBG_PRINT("*** cuda kernel args[%d]=0x%llx\n", i, (uint64_t)abuf_ptr->args[i]);
  }  

  //NOTE: old packing — 3 uint64_t per symbol (dst_addr, staging_dev_addr, size)
  //abuf_ptr->args[num_args] = memcpy_symbol.size();
  //int memcpy_symbol_idx = 0;
  //for (int i=num_args+1; i < num_args + (1 + memcpy_symbol.size() * 3); i+=3)
  //{
  //  memcpy(&abuf_ptr->args[i], &memcpy_symbol[memcpy_symbol_idx][0], sizeof(uint64_t));
  //  memcpy(&abuf_ptr->args[i+1], &memcpy_symbol[memcpy_symbol_idx][1], sizeof(uint64_t));
  //  memcpy(&abuf_ptr->args[i+2], &memcpy_symbol[memcpy_symbol_idx][2], sizeof(uint64_t));
  //  memcpy_symbol_idx++;
  //}

  // New packing: [count | dst_addr, size, inline_data... | dst_addr, size, inline_data... | ...]
  abuf_ptr->args[num_args] = memcpy_symbol.size();
  int slot = num_args + 1;
  for (auto &entry : memcpy_symbol) {
    abuf_ptr->args[slot++] = entry.dst_addr;
    abuf_ptr->args[slot++] = entry.size;
    size_t data_slots = (entry.size + sizeof(uint64_t) - 1) / sizeof(uint64_t);
    abuf_ptr->args[slot + data_slots - 1] = 0; // zero-pad last slot
    memcpy(&abuf_ptr->args[slot], entry.data.data(), entry.size);
    slot += data_slots;
  }
  // NOTE: Do NOT clear memcpy_symbol here. Vortex's vx_start.S zeroes the BSS
  // section on every kernel launch, which wipes device-side __device__ globals.
  // By keeping the symbol data, we re-send it with every kernel launch so that
  // the device-side memcpy in the wrapper restores the symbol values after BSS
  // zeroing. This fixes cfd and any other benchmark using cudaMemcpyToSymbol
  // with multiple kernel launches.
  // memcpy_symbol.clear();
  // upload additional information for cudaMemcpytoSymbol
  
  
  // auto staging_buf_additional = DC->staging_alloc(abuf_size_additional);
  // auto abuf_ptr_additional = (uint64_t*)staging_buf_additional.data();
  // abuf_ptr_additional[0] = memcpy_symbol.size();
  // printf("memcpy_symbol.size(): %lu\n", memcpy_symbol.size());
  // int abuf_ptr_additional_idx = 1;
  // while (abuf_ptr_additional_idx < memcpy_symbol.size()+1)
  // {
  //   memcpy(&abuf_ptr_additional[abuf_ptr_additional_idx*3-2], &memcpy_symbol[abuf_ptr_additional_idx-1][0], sizeof(uint64_t));
  //   memcpy(&abuf_ptr_additional[abuf_ptr_additional_idx*3-1], &memcpy_symbol[abuf_ptr_additional_idx-1][1], sizeof(uint64_t));
  //   memcpy(&abuf_ptr_additional[abuf_ptr_additional_idx*3], &memcpy_symbol[abuf_ptr_additional_idx-1][2], sizeof(uint64_t));
  //   abuf_ptr_additional_idx++;
  // }

  
  // upload kernel arguments
  // RT_CHECK(vx_copy_to_dev(DC->device(), KERNEL_ARG_BASE_ADDR, abuf_ptr, abuf_size));
  const size_t abuf_total = abuf_size + abuf_size_additional; // host blob handed to vx_enqueue_launch
  DBG_PRINT("args_buffer: %p\n", DC->args_buffer());
  


  //RT_CHECK(vx_copy_to_dev(DC->device(), KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR, abuf_ptr_additional, abuf_size_additional));
  //DC->copy_to_dev(KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR, abuf_ptr_additional, abuf_size_additional);
  //RT_CHECK(vx_upload_bytes(DC->device(), abuf_ptr_additional, abuf_size_additional, (void**)KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR));
  

  DBG_PRINT("uploaded args\n");

  // ── DXA descriptor programming (before kernel launch) ──────────────────
  // Host API calls (cudaDxaProgramDesc*) queued since the previous launch, then the sidecar's entries
  // for this kernel (resolved against this launch's arguments).
  for (auto &desc : dxa_descriptors) {
    DBG_PRINT("[DXA] slot=%u base=0x%lx rank=%u size=(%u,%u,%u) stride=(%u,%u) box=(%u,%u,%u) elem=%u layout=%u fill=0x%x\n",
              desc.slot, desc.base_addr, desc.rank, desc.size[0], desc.size[1], desc.size[2], desc.stride[0],
              desc.stride[1], desc.box[0], desc.box[1], desc.box[2], desc.elem_bytes, desc.layout, desc.fill);
    dxa_program(DC->device(), desc);
  }
  dxa_descriptors.clear();

  load_dxa_auto_descriptors();
  for (auto &adesc : dxa_auto_descriptors) {
    // Match kernel name
    if (kernel_name_tmp.find(adesc.kernel_name) == std::string::npos &&
        adesc.kernel_name.find(kernel_name_tmp) == std::string::npos)
      continue;
    DxaDescEntry d{};
    if (adesc.v2) {
      std::string err;
      if (!dxa_v2_resolve(adesc, args, num_args, d, err)) {
        fprintf(stderr, "dxa_descriptors.txt: %s\n  in: %s\n", err.c_str(), adesc.line.c_str());
        exit(1);
      }
    } else {
      if (adesc.ptr_arg_idx < 0 || adesc.ptr_arg_idx >= num_args) continue;
      d.slot = adesc.slot; d.rank = 2; d.elem_bytes = adesc.elem_bytes;
      memcpy(&d.base_addr, args[adesc.ptr_arg_idx], sizeof(uint64_t));
      if (adesc.dim0_arg_idx >= 0 && adesc.dim0_arg_idx < num_args)
        memcpy(&d.size[0], args[adesc.dim0_arg_idx], sizeof(uint32_t));
      if (adesc.dim1_arg_idx >= 0 && adesc.dim1_arg_idx < num_args)
        memcpy(&d.size[1], args[adesc.dim1_arg_idx], sizeof(uint32_t));
      d.stride[0] = d.size[0] * adesc.elem_bytes;
      d.box[0] = adesc.tile0; d.box[1] = adesc.tile1;
    }
    DBG_PRINT("[DXA-auto] slot=%u base=0x%lx rank=%u size=(%u,%u,%u) stride=(%u,%u) box=(%u,%u,%u) elem=%u layout=%u fill=0x%x\n",
              d.slot, d.base_addr, d.rank, d.size[0], d.size[1], d.size[2], d.stride[0], d.stride[1],
              d.box[0], d.box[1], d.box[2], d.elem_bytes, d.layout, d.fill);
    dxa_program(DC->device(), d);
  }


  // ── CUPBOP_LAUNCH2: hardware CTA dispatch via vx_enqueue_launch ─────────────
  {
    const int schedule = cupbop_schedule_flag();
    const int kernel_idx = abuf_ptr->kernel_idx;
    // 1) restore cudaMemcpyToSymbol / __device__ variables (single-thread service launch)
    if (!memcpy_symbol.empty()) {
      abuf_ptr->kernel_idx = -1;
      uint32_t one[3] = {1, 1, 1};
      cupbop_launch_blob(DC, abuf_ptr, abuf_total, 1, one, one, 0);
      abuf_ptr->kernel_idx = kernel_idx;
    }
    // 2) the kernel itself
    uint32_t grid[3], block[3], ndim, lmem = 0;
    if (schedule == 2) {
      // 1:1 mapping: CUDA block == Vortex CTA (must fit one core), __shared__ in CTA local memory
      const uint64_t block_threads = (uint64_t)blockDim.x * blockDim.y * blockDim.z;
      const uint64_t core_threads = (uint64_t)CUPBOP_EFF_NUM_WARPS() * CUPBOP_EFF_NUM_THREADS();   // VX_RT_NUM_WARPS/SIMD_WIDTH-aware
      if (block_threads > core_threads) {
        printf("Error: block_size %lu exceeds threads_per_core %lu (NUM_WARPS*NUM_THREADS); a CUDA block must fit one core in the 1:1 schedule\n",
               (unsigned long)block_threads, (unsigned long)core_threads);
        std::abort();
      }
      grid[0] = gridDim.x; grid[1] = gridDim.y; grid[2] = gridDim.z;
      block[0] = blockDim.x; block[1] = blockDim.y; block[2] = blockDim.z;
      ndim = 3;
      lmem = cupbop_static_lmem_bytes(func_stripped) + (uint32_t)sharedMem;
      uint64_t lmem_cap = 0;
      if (vx_dev_caps(DC->device(), VX_CAPS_LOCAL_MEM_SIZE, &lmem_cap) == 0 && lmem > lmem_cap) {
        printf("Error: kernel needs %u bytes of local memory per block, device has %lu\n", lmem, (unsigned long)lmem_cap);
        std::abort();
      }
    } else if (schedule == 1) {
      // core mapping (virt): CTA == CUDA block, but only P physical warps
      // (CUPBOP_VIRT_WARPS, default = all block warps). The kernel loops over
      // the logical warps; __shared__ in CTA local memory as in 1:1.
      const uint64_t block_threads = (uint64_t)blockDim.x * blockDim.y * blockDim.z;
      const uint32_t nt = CUPBOP_EFF_NUM_THREADS();
      // Lane gating: use only L of the NT lanes of each physical warp
      // (CUPBOP_VIRT_LANES, default NT). Emulates a narrower issue width on a wider
      // bitstream; TCU tile geometry, LSU lanes and the memory side stay the bitstream's.
      uint32_t L = std::min<uint32_t>(nt, 32u); // a wider warp runs one 32-lane logical warp at a time
      if (char *env = std::getenv("CUPBOP_VIRT_LANES")) { int v = std::stoi(std::string(env)); if (v > 0 && (uint32_t)v < L) L = (uint32_t)v; }
      while (32 % L) L >>= 1;
      // Every physical warp must own at least one logical thread (its lanes leave
      // early otherwise and the CTA barrier would wait for it): P <= ceil(block/L).
      // Every physical warp must own a logical thread in whichever form the kernel took
      // (chunk of L per pass, or a 32-lane logical warp per pass when it stages warp ops),
      // so with L < 32 the cap is the number of CUDA warps.
      const uint32_t block_warps = (uint32_t)((block_threads + (L < 32 ? 32 : L) - 1) / (L < 32 ? 32 : L));
      uint32_t P = block_warps;
      // CUPBOP_VIRT_TRIPS=k (translation-time constant, single-loop form with 32 lanes): every warp loop
      // runs exactly k passes of P*32 logical threads, so the default P is ceil(block / (32*k)).
      uint32_t virt_trips = 0;
      if (char *env = std::getenv("CUPBOP_VIRT_TRIPS")) { int v = std::atoi(env); if (v > 0 && L == 32) virt_trips = (uint32_t)v; }
      if (virt_trips) { uint32_t p = (uint32_t)((block_threads + 32ull * virt_trips - 1) / (32ull * virt_trips)); P = std::max<uint32_t>(1u, std::min(P, p)); }
      if (char *env = std::getenv("CUPBOP_VIRT_WARPS")) { int v = std::stoi(std::string(env)); if (v > 0 && (uint32_t)v < P) P = (uint32_t)v; }
      if (P > CUPBOP_EFF_NUM_WARPS()) P = CUPBOP_EFF_NUM_WARPS();   // VX_RT_NUM_WARPS cap: fold the block onto the warps the core actually offers
      if ((P != block_warps || L != 32) && (cupbop_async_kernel(kernel_name_tmp) || cupbop_async_kernel(func_stripped))) {
        printf("Error: kernel %s uses mbarrier waits / TMA / bulk copies (warp-specialized synchronization); the core "
               "mapping runs it only with one logical warp per physical warp of 32 lanes (CUPBOP_VIRT_WARPS = the "
               "block's %u warps, no trips / lane gating), got %u physical warps of %u lanes. Use SCHEDULE=2.\n",
               func_stripped.c_str(), block_warps, P, L);
        std::abort();
      }
      const char *virt_exact_env = std::getenv("CUPBOP_VIRT_TRIPS_EXACT");
      if (virt_trips && virt_exact_env && std::atoi(virt_exact_env) && (uint64_t)P * 32ull * virt_trips != block_threads) {
        printf("Error: CUPBOP_VIRT_TRIPS_EXACT needs physical warps x 32 x trips == threads per block (%u x 32 x %u != %lu)\n",
               P, virt_trips, (unsigned long)block_threads);
        std::abort();
      }
      if (virt_trips && (uint64_t)P * 32ull * virt_trips < block_threads) {
        printf("Error: CUPBOP_VIRT_TRIPS=%u with %u physical warps covers %llu of %lu threads per block; raise the trips or the warps\n",
               virt_trips, P, (unsigned long long)P * 32ull * virt_trips, (unsigned long)block_threads);
        std::abort();
      }
      if ((uint64_t)P * nt > (uint64_t)CUPBOP_EFF_NUM_WARPS() * nt) {
        printf("Error: block_size %lu exceeds threads_per_core %lu even with CUPBOP_VIRT_WARPS=%u\n",
               (unsigned long)((uint64_t)P * nt), (unsigned long)(NUM_WARPS_VX * NUM_THREADS_VX), P);
        std::abort();
      }
      // L reaches the kernel at translation time (CUPBOP_VIRT_LANES is a recipe knob: the
      // Vortex backend needs a memory-free lane count); the host only sizes the CTA.
      grid[0] = gridDim.x; grid[1] = gridDim.y; grid[2] = gridDim.z;
      // Never more hardware threads than logical ones: hardware thread h owns the
      // logical threads h, h+P*nt, ... and the kernel's uniform control flow
      // (loop exits between the region loops) reads per-hardware-thread scalars
      // that only an owned logical thread writes. With a CTA of P*nt threads a
      // 16-thread block (lud_diagonal) left lanes 16..31 without any logical
      // thread; their uninitialized copies split the warp on a uniform branch and
      // the CTA barriers deadlocked. min() keeps every hardware thread busy and
      // is what the 1:1 schedule does for partial warps anyway.
      // Lane gating needs the full warps dispatched (the kernel entry retires lanes >= L).
      block[0] = (L == nt) ? (uint32_t)std::min<uint64_t>((uint64_t)P * nt, block_threads) : P * nt; block[1] = 1; block[2] = 1;
      ndim = 3;
      lmem = cupbop_static_lmem_bytes(func_stripped) + (uint32_t)sharedMem;
      DBG_PRINT("virt: block_warps=%u physical_warps=%u lanes=%u cta_threads=%u\n", block_warps, P, L, block[0]);
    } else {
      // flat schedule: one CUDA block per hardware thread; the device entry recovers
      // the block index from (CTA, thread). __shared__ lives in global memory.
      const uint64_t total_blocks = (uint64_t)gridDim.x * gridDim.y * gridDim.z;
      const uint32_t nt = CUPBOP_EFF_NUM_THREADS();
      grid[0] = (uint32_t)((total_blocks + nt - 1) / nt); grid[1] = 1; grid[2] = 1;
      block[0] = nt; block[1] = 1; block[2] = 1;
      ndim = 1;
    }
    DBG_PRINT("launch2: sched=%d grid=(%u,%u,%u) block=(%u,%u,%u) lmem=%u args=%zu\n",
              schedule, grid[0], grid[1], grid[2], block[0], block[1], block[2], lmem, abuf_total);
    cupbop_launch_blob(DC, abuf_ptr, abuf_total, ndim, grid, block, lmem);
  }

  // Read back __device__ variables from device memory after kernel execution.
  // These are registered as memcpy_symbol entries so they get restored
  // before the next kernel launch (surviving BSS zeroing).
  {
    static bool device_vars_registered = false;
    if (!device_vars_registered) {
      // Parse kernel_meta.log for DeviceVariables section
      std::ifstream meta("kernel_meta.log");
      DBG_PRINT("[device_var] meta file open=%d\n", meta.is_open());
      if (meta.is_open()) {
        std::string line;
        bool in_section = false;
        while (std::getline(meta, line)) {
          if (line == "DeviceVariables") { in_section = true; continue; }
          if (line == "END_DeviceVariables") { in_section = false; continue; }
          if (in_section) {
            std::istringstream iss(line);
            std::string name;
            uint64_t size;
            iss >> name >> size;
            // Strip C++ mangling prefix from kernel_meta.log name
            // e.g. _ZL4topL → topL (to match nm -C demangled names)
            auto stripMangle = [](const std::string &s) -> std::string {
              size_t i = 0;
              if (s.size() > 2 && s[0] == '_' && s[1] == 'Z') i = 2;
              while (i < s.size() && (s[i] == 'L' || (s[i] >= '0' && s[i] <= '9'))) i++;
              return s.substr(i);
            };
            std::string name_stripped = stripMangle(name);
            // Look up device address from lookup_global_symbols.txt
            std::ifstream sym("lookup_global_symbols.txt");
            std::string addr_s, type_s, sym_name;
            while (sym >> addr_s >> type_s) {
              std::getline(sym, sym_name);
              if (!sym_name.empty() && sym_name[0] == ' ')
                sym_name = sym_name.substr(1);
              if (sym_name == name_stripped) {
                uint64_t addr = std::stoull(addr_s, nullptr, 16);
                // Register as memcpy_symbol entry with current device value
                MemcpySymbolEntry entry;
                entry.dst_addr = addr;
                entry.size = size;
                entry.data.resize(size, 0);
                memcpy_symbol.push_back(std::move(entry));
                DBG_PRINT("[device_var] registered: %s (stripped=%s) addr=0x%lx size=%ld\n",
                          name.c_str(), name_stripped.c_str(), addr, size);
                break;
              }
            }
          }
        }
        device_vars_registered = true;
      }
    }
    // Read back only __device__ variable entries (not cudaMemcpyToSymbol ones).
    // device_var entries are appended at the end of memcpy_symbol by the
    // registration code above. Only read back those entries.
    static size_t device_var_start_idx = 0;
    if (device_vars_registered && device_var_start_idx == 0 && !memcpy_symbol.empty()) {
      // device vars were just registered — they're at the end
      // Find where they start by checking kernel_meta.log count
      std::ifstream meta2("kernel_meta.log");
      std::string line2;
      size_t dv_count = 0;
      bool in_sec = false;
      while (std::getline(meta2, line2)) {
        if (line2 == "DeviceVariables") { in_sec = true; continue; }
        if (line2 == "END_DeviceVariables") break;
        if (in_sec) dv_count++;
      }
      device_var_start_idx = memcpy_symbol.size() - dv_count;
    }
    if (device_vars_registered) {
      // Read back device vars using the kernel buffer handle.
      // BSS globals reside within the kernel binary's memory region.
      // CUPBOP_LAUNCH2: the module image is not a host-visible buffer; a service
      // launch copies the variables into a staging buffer we can read.
      std::vector<std::pair<uint64_t, size_t>> ranges; std::vector<void *> dsts;
      for (size_t i = device_var_start_idx; i < memcpy_symbol.size(); i++) {
        auto &entry = memcpy_symbol[i];
        ranges.push_back({entry.dst_addr, (size_t)entry.size}); dsts.push_back(entry.data.data());
        DBG_PRINT("[device_var] read-back[%ld]: addr=0x%lx size=%ld\n", i, entry.dst_addr, entry.size);
      }
      cupbop_read_device_ranges(DC, ranges, dsts);
    }
  }

  DBG_PRINT("sync device\n");

  // dump performance counters for every kernel to a file
  
  int schedule = 0;
  int local_mem_use = 1;
    if (char *env = std::getenv("VORTEX_SCHEDULE_FLAG")) {
      schedule = std::stoi(std::string(env));
    }
    if (char *env = std::getenv("VORTEX_LOCALMEM_FLAG")) {
      local_mem_use = std::stoi(std::string(env));
    }
  
  std::string filename;
  if(schedule == 2)
  {
    filename = "Perf_counter_" + std::to_string(NUM_CORES_VX) + "C_" + std::to_string(NUM_WARPS_VX) + "W_" + std::to_string(NUM_THREADS_VX) + "T_SCHE_"+ std::to_string(schedule) +"_LOCAL_MEM_"+ std::to_string(local_mem_use) + ".txt";
  }
  else
  {
    filename = "Perf_counter_" + std::to_string(NUM_CORES_VX) + "C_" + std::to_string(NUM_WARPS_VX) + "W_" + std::to_string(NUM_THREADS_VX) + "T_SCHE_"+ std::to_string(schedule) + ".txt";
  }

  std::cout << "output file: " << filename << std::endl;
  //convert filename to char* with its content
  char filename_char[filename.size() + 1];
  strcpy(filename_char, filename.c_str());
  
  FILE *outputFile = fopen(filename_char, "a");
  if (outputFile == NULL) {
    perror("Error opening the output file");
  }
  vx_dump_perf(DC->device(), outputFile);
  
  return cudaSuccess;
}

}