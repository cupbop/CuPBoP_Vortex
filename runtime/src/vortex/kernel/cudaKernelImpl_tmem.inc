#include "../../../include/cupbop_tcgen05_desc.h"

// A runtime descriptor must pass the same checks before it can affect D.
extern "C" void __cupbop_tcgen05_check_descriptor(unsigned desc, unsigned kind, unsigned pair,
                                                  unsigned sparse, unsigned tmem_a, unsigned vec,
                                                  unsigned features) {
  if (const char *error = cupbop_tcgen05::descriptor_error(
          desc, static_cast<cupbop_tcgen05::Kind>(kind), pair, sparse, tmem_a, vec, features))
    cupbop_async_fail(error, desc, kind);
}
// Exact floating-point decoders shared with the warp MMA runtime.
static inline float __cupbop_f16_to_f32(uint32_t);
static inline float __cupbop_e4m3_to_f32(uint32_t);
static inline uint32_t __cupbop_f32_to_f16_rne(float);
// Full 512-column TCGEN05 allocations and dense signed INT8 MMA.
#if defined(VX_CFG_EXT_TCU_ENABLE) && defined(VX_CFG_TCU_TMEM_ENABLE)
#include <vx_tmem.h>
#ifdef VX_CFG_TCU_TMEM_COLUMN_ENABLE
// At NT=32 a block has 16 physical rows. Pair two 16-column panels
// for the lower/upper halves of a CUDA warp's 32 logical rows.
#if VX_CFG_NUM_THREADS == 32 && VX_CFG_NUM_TCU_BLOCKS == 4 && VX_CFG_ISSUE_WIDTH == 4
#define CUPBOP_COLUMN_TILE
constexpr unsigned cupbop_column_ratio = 2;
#else
constexpr unsigned cupbop_column_ratio = 1;
#endif
#ifdef CUPBOP_COLUMN_TILE
struct ColumnMetaCell {
  uint32_t bits, generation;
};
struct ColumnMeta {
  uint32_t lock, allocated;
#ifdef VX_CFG_TCU_MX_ENABLE
  uint32_t access_lock, owner[VX_CFG_TCU_TMEM_COLS / 32];
#endif
#if defined(VX_CFG_TCU_MX_ENABLE) || defined(VX_CFG_TCU_TMEM_READBACK_ENABLE)
  uint8_t native_result[VX_CFG_TCU_TMEM_COLS / 2];
#endif
  uint32_t generation[VX_CFG_TCU_TMEM_COLS / 2];
  ColumnMetaCell words[VX_CFG_TCU_TMEM_COLS / 2][128];
};
// Only modules that read back copy/store operands reference this storage.
// Section GC removes its per-core buffer from other binaries, including non-LTO.
extern "C" ColumnMeta *__cupbop_column_meta_storage() {
  static ColumnMeta storage[VX_CFG_NUM_CORES * VX_CFG_NUM_CLUSTERS];
  return storage;
}
extern "C" ColumnMeta *__cupbop_column_meta_table() __attribute__((weak));

static void column_meta_invalidate(unsigned col, unsigned count, bool native_result = true) {
  if (!__cupbop_column_meta_table) return;
  auto &meta = __cupbop_column_meta_table()[vx_core_id()];
  for (unsigned i = col; i < col + count; ++i) {
#if defined(VX_CFG_TCU_MX_ENABLE) || defined(VX_CFG_TCU_TMEM_READBACK_ENABLE)
    meta.native_result[i] = native_result;
#endif
    if (++meta.generation[i] == 0) {
      for (auto &word : meta.words[i]) word.generation = 0;
      meta.generation[i] = 1;
    }
  }
}
static void column_meta_store(unsigned col, unsigned row, uint32_t bits) {
  if (__cupbop_column_meta_table) {
    auto &meta = __cupbop_column_meta_table()[vx_core_id()];
    meta.words[col][row] = {bits, meta.generation[col]};
  }
}
static uint32_t column_meta_word(unsigned col, unsigned row) {
  if (row >= 128 || col >= VX_CFG_TCU_TMEM_COLS / 2)
    cupbop_async_fail("column operand outside TMEM", col, row);
  auto &meta = __cupbop_column_meta_table()[vx_core_id()];
  auto &cell = meta.words[col][row];
#ifdef VX_CFG_TCU_TMEM_READBACK_ENABLE
  if (meta.native_result[col] && cell.generation != meta.generation[col]) {
    unsigned physicalRow = (row / 32) * 16 + row % 16;
    unsigned physicalCol = (col & ~15u) * 2 + (row & 16) + col % 16;
    cell = {vortex::tmem::read_word(physicalRow, physicalCol), meta.generation[col]};
  }
#endif
  if (!cell.generation || cell.generation != meta.generation[col])
    cupbop_async_fail("column operand requires a TMEM copy or store", col, row);
  return cell.bits;
}

#ifdef VX_CFG_TCU_MX_ENABLE
extern "C" bool __cupbop_column_uses_mx() __attribute__((weak));
static bool column_may_borrow() {
  // Older translated modules carry only the optional operand table.
  return __cupbop_column_meta_table && (!__cupbop_column_uses_mx || __cupbop_column_uses_mx());
}
#endif

// An MX instruction can borrow caller-owned columns to hold its scale image.
// CUDA warps may issue unrelated native transfers while the borrower runs.
// Serialize column accesses in modules that can issue MX jobs, including
// the whole warp that reads or writes its own block's physical rows.
struct ColumnAccess {
#ifdef VX_CFG_TCU_MX_ENABLE
  uint32_t *lock;
  explicit ColumnAccess(bool participate = true) : lock(nullptr) {
    if (participate && !vx_thread_id() && column_may_borrow()) {
      lock = &__cupbop_column_meta_table()[vx_core_id()].access_lock;
      while (__atomic_exchange_n(lock, 1u, __ATOMIC_ACQUIRE)) {}
    }
  }
  ~ColumnAccess() {
    if (lock) __atomic_store_n(lock, 0u, __ATOMIC_RELEASE);
  }
#else
  explicit ColumnAccess(bool = true) {}
#endif
};

static void column_publish_store() {
#ifdef VX_CFG_TCU_MX_ENABLE
  if (column_may_borrow()) {
    // All lanes publish their global mirrors and posted TMEM stores before
    // lane zero releases the access lock for a scalar issuer on another warp.
    vx_fence();
    vortex::tmem::wait_st();
  }
#endif
}

// Native alloc waits indefinitely when full. Under the per-core lock, keep
// the same 32-column ownership bitmap for user runs and short-lived sparse
// side columns. Never wait for another CTA's deallocation while locked.
#ifdef VX_CFG_TCU_TMEM_EXT_SIDE_ENABLE
constexpr unsigned column_side_limit = VX_CFG_TCU_TMEM_COLS;
#else
constexpr unsigned column_side_limit = VX_CFG_TCU_TMEM_COLS < 512 ? VX_CFG_TCU_TMEM_COLS : 512;
#endif
static int column_allocate(unsigned count, bool temporary = false) {
  if (!__cupbop_column_meta_table)
    return temporary ? -1 : int(vortex::tmem::alloc(count));
  static_assert(VX_CFG_TCU_TMEM_COLS <= 1024, "TMEM allocator bitmap width");
  auto &meta = __cupbop_column_meta_table()[vx_core_id()];
  const unsigned chunks = count / 32;
  if (!chunks || count > VX_CFG_TCU_TMEM_COLS || (count & (count - 1)))
    cupbop_async_fail("invalid column allocation size", count, 0);
  const uint32_t mask = chunks == 32 ? ~0u : (1u << chunks) - 1;
  const unsigned limit = temporary ? column_side_limit : VX_CFG_TCU_TMEM_COLS;
  for (;;) {
    while (__atomic_exchange_n(&meta.lock, 1u, __ATOMIC_ACQUIRE)) {}
    for (unsigned i = 0; i + chunks <= limit / 32; i += chunks) {
      if (meta.allocated & (mask << i)) continue;
      const unsigned base = vortex::tmem::alloc(count);
      meta.allocated |= mask << (base / 32);
      if (temporary && base + count > limit) {
        vortex::tmem::dealloc(base, count);
        meta.allocated &= ~(mask << (base / 32));
        __atomic_store_n(&meta.lock, 0u, __ATOMIC_RELEASE);
        return -1;
      }
      __atomic_store_n(&meta.lock, 0u, __ATOMIC_RELEASE);
      if (!temporary) {
        ColumnAccess access;
        column_meta_invalidate(base / 2, count / 2, false);
#ifdef VX_CFG_TCU_MX_ENABLE
        for (unsigned j = base / 32; j < (base + count) / 32; ++j)
          meta.owner[j] = 1 + csr_read_nv(VX_CSR_CTA_ID);
#endif
      }
      return int(base);
    }
    __atomic_store_n(&meta.lock, 0u, __ATOMIC_RELEASE);
    if (temporary) return -1;
  }
}
static void column_deallocate(unsigned base, unsigned count, bool temporary = false) {
  if (!__cupbop_column_meta_table) {
    vortex::tmem::dealloc(base, count);
    return;
  }
  ColumnAccess access(!temporary);
  auto &meta = __cupbop_column_meta_table()[vx_core_id()];
  while (__atomic_exchange_n(&meta.lock, 1u, __ATOMIC_ACQUIRE)) {}
  vortex::tmem::dealloc(base, count);
#ifdef VX_CFG_TCU_MX_ENABLE
  if (!temporary)
    for (unsigned j = base / 32; j < (base + count) / 32; ++j) meta.owner[j] = 0;
#endif
  const unsigned chunks = count / 32;
  meta.allocated &= ~((chunks == 32 ? ~0u : (1u << chunks) - 1) << (base / 32));
  __atomic_store_n(&meta.lock, 0u, __ATOMIC_RELEASE);
}
static int column_sparse_side() { return column_allocate(32, true); }
static void column_sparse_release(unsigned base) { column_deallocate(base, 32, true); }
#else
static unsigned column_allocate(unsigned count) { return vortex::tmem::alloc(count); }
static void column_deallocate(unsigned base, unsigned count) { vortex::tmem::dealloc(base, count); }
#endif
static void column_check_size(unsigned cols) {
  if (cols < 32 || cols > 512 || (cols & (cols - 1)))
    cupbop_async_fail("expected 32 to 512 power-of-two TMEM columns", cols, 0);
}
extern "C" void __cupbop_column_alloc(uint32_t *dst, uint32_t cols) {
  column_check_size(cols);
  if (cols * cupbop_column_ratio > VX_CFG_TCU_TMEM_COLS) cupbop_async_fail("TMEM allocation exceeds core capacity", cols, VX_CFG_TCU_TMEM_COLS);
  if (vx_thread_id() == 0) *dst = column_allocate(cols * cupbop_column_ratio) / cupbop_column_ratio;
}
extern "C" void __cupbop_column_free(uint32_t col, uint32_t cols) {
  column_check_size(cols);
  if (col % cols || uint64_t(col) + cols > VX_CFG_TCU_TMEM_COLS / cupbop_column_ratio)
    cupbop_async_fail("invalid TMEM deallocation range", col, cols);
  if (vx_thread_id() == 0) column_deallocate(col * cupbop_column_ratio, cols * cupbop_column_ratio);
}
#else
#define CUPBOP_NATIVE_TMEM
#endif
#endif

// Backing store is indexed by the hardware CTA slot, which the KMU retains
// until the entire block retires. Columns are addressed in 32-bit words.
#if defined(VX_CFG_NUM_THREADS) && VX_CFG_NUM_THREADS == 32
namespace {
#ifndef CUPBOP_NATIVE_TMEM
struct TcgenStore {
  uint32_t word[128][512];
};
static TcgenStore tcgen_slots[VX_CFG_NUM_CLUSTERS * VX_CFG_NUM_CORES][VX_CFG_NUM_WARPS];

static inline TcgenStore &tcgen_store() { return tcgen_slots[vx_core_id()][csr_read_nv(VX_CSR_CTA_ID)]; }
#endif

struct TcgenOperand {
  uintptr_t start;
  uint32_t leading, stride, swizzle, cuda_offset;
};

static inline TcgenOperand tcgen_operand(uint64_t desc, bool tf32_mn = false) {
  const unsigned mode = desc >> 61;
  // Relative leading stride, base offset zero, version 1. MN-major TF32
  // requires SW128 with 32B atomicity (mode 1).
  if (((desc >> 46) & 0x7fff) != 1 || (tf32_mn ? mode != 1 : mode != 0 && mode != 2))
    cupbop_async_fail("unsupported TCGEN SMEM descriptor", uint32_t(desc >> 32), uint32_t(desc));
  const uintptr_t lmem = csr_read_nv(VX_CSR_CTA_LMEM_ADDR);
  const uintptr_t start = lmem + ((((desc & 0x3fff) << 4) - lmem) & 0x3ffff);
  return {start, uint32_t((desc >> 16) & 0x3fff) * 16, uint32_t((desc >> 32) & 0x3fff) * 16, mode, uint32_t(start - lmem)};
}

// Swizzle CUDA addresses within their original CTA. A peer mapping may
// relocate the whole slab to a different alignment. Retain the descriptor's
// low offset bits for a submatrix that begins within a swizzle atom.
static inline uintptr_t tcgen_swizzled_address(const TcgenOperand &a, uintptr_t offset, unsigned mask) {
  return (a.start - a.cuda_offset) + ((a.cuda_offset + offset) ^ mask);
}

static inline const int8_t *tcgen_chunk(const TcgenOperand &a, unsigned row, unsigned half) {
  // PTX canonical K-major layout, in 16-byte core vectors. In swizzle
  // mode 2 XOR row bits [2:0] into byte-address bits [6:4].
  uintptr_t offset = (row >> 3) * a.stride;
  if (a.swizzle) {
    offset += (row & 7) * 128 + half * 16;
    return reinterpret_cast<const int8_t *>(tcgen_swizzled_address(a, offset, (row & 7) << 4));
  }
  return (const int8_t *)(a.start + offset + (row & 7) * 16 + half * a.leading);
}
#ifdef CUPBOP_COLUMN_TILE
namespace tmcol = vortex::tmem;
namespace tensor = vortex::tensor;

struct ColumnWords {
  static constexpr unsigned NR = 8;
  float data[NR];
};

static unsigned column_panel(unsigned col, unsigned half) {
  return (col & ~15u) * 2 + half * 16;
}

// The two resident CTAs each own and release a physical run. CUDA sees
// the same virtual address in both. CTA slots are local to a core.
constexpr unsigned columnPairTag = 0x8000;
struct ColumnPairRun { unsigned base, size; };
static volatile ColumnPairRun pairRuns[VX_CFG_NUM_CORES * VX_CFG_NUM_CLUSTERS][VX_CFG_NUM_WARPS];
static volatile ColumnPairRun &pairRun(unsigned side) {
  unsigned rank = cluster_rank();
  unsigned slot = csr_read_nv(VX_CSR_CTA_ID) - (rank & 1) + side;
  return pairRuns[vx_core_id()][slot];
}
extern "C" void __cupbop_column_pair_alloc(unsigned *dst, unsigned cols) {
  column_check_size(cols);
  if (!vx_thread_id()) {
    if (__cupbop_cluster_register(1,0) != 2 || cols * 4 > VX_CFG_TCU_TMEM_COLS)
      cupbop_async_fail("paired runs exceed resident core capacity", cols, VX_CFG_TCU_TMEM_COLS);
    auto &run = pairRun(cluster_rank() & 1);
    if (run.size) cupbop_async_fail("paired column run already allocated", cols, run.size);
    unsigned base = column_allocate(cols * 2);
    run.base = base / 2;
    run.size = cols;
    vx_fence();
    *dst = columnPairTag;
  }
}
extern "C" void __cupbop_column_pair_free(unsigned addr, unsigned cols) {
  column_check_size(cols);
  if (!vx_thread_id()) {
    auto &run = pairRun(cluster_rank() & 1);
    if (addr != columnPairTag || run.size != cols)
      cupbop_async_fail("invalid paired run", addr, cols);
    column_deallocate(run.base * 2, cols * 2);
    run.size = 0;
  }
}
// PTX canonical 16-byte core matrices. MN-major interleaved and SW128
// layouts transpose the two core coordinates and use different leading strides.
template <typename T>
static T column_element(const TcgenOperand &src, unsigned row, unsigned k, bool transpose) {
  constexpr unsigned vec = 16 / sizeof(T);
  const uint8_t *address;
  if (!transpose) {
    address = reinterpret_cast<const uint8_t *>(tcgen_chunk(src, row, k / vec)) + k % vec * sizeof(T);
  } else {
    uintptr_t p;
    if (src.swizzle == 1) {
      // Swizzle within the CUDA atom before adding the mapped CTA base.
      // Two Vortex CTA scratch slabs need not have the same low address bits.
      uintptr_t offset = row / (8 * vec) * src.leading + k / 4 * src.stride +
          (k % 4) * 128 + (row % (8 * vec)) * sizeof(T);
      p = tcgen_swizzled_address(src, offset, (k % 4) << 5);
    } else if (src.swizzle) {
      uintptr_t offset = row / (8 * vec) * src.leading + k / 8 * src.stride +
          (k % 8) * 128 + (row % (8 * vec)) * sizeof(T);
      p = tcgen_swizzled_address(src, offset, (k % 8) << 4);
    } else {
      p = src.start + row / vec * src.stride + k / 8 * src.leading +
          (k % 8) * 16 + (row % vec) * sizeof(T);
    }
    address = reinterpret_cast<const uint8_t *>(p);
  }
  T value;
  __builtin_memcpy(&value, address, sizeof(T));
  return value;
}

// SM100 K32 f8f6f4 packs a run of 16 FP4 or FP6 values into a
// padded 16-byte core vector. MN-major transposes the packed dimension.
static unsigned column_small_float(const TcgenOperand &src, unsigned row, unsigned k,
                                   unsigned type, bool transpose) {
  if (type <= 1) return column_element<uint8_t>(src, row, k, transpose);
  unsigned width = type == 5 ? 4 : 6;
  unsigned pos = transpose ? row : k;
  unsigned bit = (pos % 16) * width;
  unsigned byte = (pos & ~15u) + bit / 8;
  auto read = [&](unsigned i) {
    return transpose ? column_element<uint8_t>(src, i, k, true)
                     : column_element<uint8_t>(src, row, i, false);
  };
  unsigned bits = read(byte);
  if (bit % 8 + width > 8) bits |= unsigned(read(byte + 1)) << 8;
  return (bits >> (bit % 8)) & ((1u << width) - 1);
}

// Every finite E2M1, E2M3 and E3M2 number (including subnormals) is
// exactly representable in E4M3. Low-precision formats have no NaN/Inf.
static unsigned column_low_to_e4m3(unsigned bits, unsigned type) {
  unsigned mbits = type == 5 ? 1 : type == 3 ? 3 : 2;
  unsigned ebits = type == 4 ? 3 : 2;
  unsigned sign = (bits >> (mbits + ebits)) << 7;
  unsigned e = (bits >> mbits) & ((1u << ebits) - 1);
  unsigned m = bits & ((1u << mbits) - 1);
  int bias = (1 << (ebits - 1)) - 1;
  if (!e) {
    if (!m) return sign;
    unsigned shift = mbits - (31 - __builtin_clz(m));
    m = (m << shift) & ((1u << mbits) - 1);
    return sign | ((8 - bias - shift) << 3) | (m << (3 - mbits));
  }
  return sign | ((e + 7 - bias) << 3) | (m << (3 - mbits));
}

// With dense K32 each FP6/FP4 element occupies one byte in CUDA
// TMEM. E2M1 uses bits 5:2; both FP6 encodings use bits 5:0.
static unsigned column_tmem_small_float(unsigned col, unsigned row, unsigned k, unsigned type) {
  unsigned byte = column_meta_word(col + k / 4, row) >> ((k % 4) * 8) & 255;
  return type == 5 ? (byte >> 2) & 15 : type >= 3 ? byte & 63 : byte;
}

static unsigned column_small_to_half(unsigned raw, unsigned type) {
  if (type == 1) return raw << 8;
  if (type > 1) raw = column_low_to_e4m3(raw, type);
  return __cupbop_f32_to_f16_rne(__cupbop_e4m3_to_f32(raw));
}

// Four adjacent K positions have two stored values. CUDA interleaves the
// F16 row and K-block indices in the two halfwords of the selected column.
static bool column_tf32(unsigned format) { return (format & 0x21ff0u) == 0x910; }

static unsigned column_sparse_indices(unsigned meta, unsigned row, unsigned k, unsigned format) {
  unsigned word, shift;
  if (column_tf32(format)) {
    // TF32 stores a nibble (4 or 14) per pair. Re-express two successive
    // pairs as the two selected indices of one four-element native group.
    word = column_meta_word(meta + (format & 1), (row & ~8u) | (k & 8));
    shift = (row & 8) * 2 + (k & 4) * 2;
    unsigned pairs = (word >> shift) & 255;
    return unsigned((pairs & 15) == 14) | ((2u + unsigned((pairs >> 4) == 14)) << 2);
  }
  if ((format & 0x20010) == 0x10) {
    word = column_meta_word(meta + (format & 1), (row & ~8u) | ((k & 16) >> 1));
    shift = ((row & 8) << 1) + (k & 12);
  } else {
    word = column_meta_word(meta + k / 32, row);
    shift = k & 28;
  }
  return (word >> shift) & 15;
}

template <typename Input>
static typename Input::dtype column_value(const TcgenOperand &src, unsigned row, unsigned k,
                                         unsigned format, bool is_b, unsigned part) {
  const bool transpose = format & (1u << (15 + is_b));
  const bool alt = format & (1u << (is_b ? 10 : 7)); // BF16 or signed I8
  if constexpr (Input::bits == 8) {
    unsigned val = column_element<uint8_t>(src, row, k, transpose);
    // A mixed signed/unsigned dot uses three signed TC jobs. Exactly
    // decompose the unsigned byte into low seven bits + two copies of bit7*64.
    if (Input::id == tensor::int8::id && !alt)
      val = part ? ((val >> 7) << 6) : (val & 127);
    return static_cast<typename Input::dtype>(val);
  } else {
    if (format & (1u << 17)) {
      unsigned type = (format >> (is_b ? 10 : 7)) & 7;
      unsigned byte = column_small_float(src, row, k, type, transpose);
      unsigned half = column_small_to_half(byte, type);
      // Both FP8 encodings widen exactly to binary16. E5M2 already uses
      // binary16's exponent and bias, with two stored fraction bits.
      return half ^ ((format & (1u << (13 + is_b))) ? 0x8000 : 0);
    }
    if constexpr (Input::id == tensor::tf32::id) {
      if (column_tf32(format)) {
        uint32_t word = column_element<uint32_t>(src, row, k, transpose);
        if (format & (1u << (13 + is_b))) word ^= 1u << 31;
        return word >> 13; // Vortex stores sign, exponent and fraction in bits 18:0.
      }
    }
    unsigned val = column_element<uint16_t>(src, row, k, transpose);
    if (format & (1u << (13 + is_b))) val ^= 0x8000;
    if constexpr (Input::id == tensor::tf32::id) {
      // Every binary16 and BF16 value is representable in TF32.
      return (alt ? val << 16 : __builtin_bit_cast(uint32_t, __cupbop_f16_to_f32(val))) >> 13;
    } else {
      return val;
    }
  }
}

static void column_wait(unsigned warp) {
  unsigned barrier = ((vx_num_barriers() - 1 - warp) << 8) | csr_read_nv(VX_CSR_CTA_ID);
  tmcol::commit(barrier, 2);
  vx_barrier(barrier, 2);
}

// A contains 32 bytes in each of four independent 32-row subpartitions.
// Visit rows in increasing order within each subpartition, so the next
// row is still unmodified when read. Each posted copy has a distinct
// staging panel and is retired before the issuer reuses the scratch.
static void column_shift_a(unsigned col, uint8_t *scratch, unsigned warp) {
  constexpr uintptr_t bankRow = VX_CFG_LMEM_NUM_BANKS * (VX_CFG_XLEN / 8);
  auto *image = reinterpret_cast<uint32_t *>((uintptr_t(scratch) + bankRow - 1) & ~(bankRow - 1));
  for (unsigned group = 0; group < 2; ++group) {
    unsigned dst = col + group * 4;
    for (unsigned half = 0; half < 2; ++half) {
      auto *panel = image + (group * 2 + half) * 64 * 4;
      for (unsigned lane = 0; lane < 64; ++lane) {
        unsigned row = lane / 16 * 32 + half * 16 + lane % 16;
        unsigned from = row + (row % 32 != 31);
        for (unsigned j = 0; j < 4; ++j) {
          unsigned word = column_meta_word(dst + j, from);
          panel[lane * 4 + j] = word;
          column_meta_store(dst + j, row, word);
        }
      }
      vx_fence();
      tmcol::cp(column_panel(dst, half) + dst % 16, panel, 4);
    }
  }
  column_wait(warp);
}

// A dense job would evaluate structural zero times NaN/Inf. For an
// exceptional sparse operand, evaluate only the two selected K positions.
// The same path can retire an MX tile when D occupies every encodable side
// column. Cache the four B columns in LMEM and stream groups through tc.cp.
template <typename AValue, typename BValue>
static void column_scalar_dot(unsigned col, unsigned columns, unsigned ksize, unsigned unit,
                              bool sparse, unsigned meta, unsigned format, bool use_d, unsigned warp,
                              uint8_t *scratch, AValue read_a, BValue read_b) {
  auto *bvalues = reinterpret_cast<float *>(scratch);
  constexpr uintptr_t bankRow = VX_CFG_LMEM_NUM_BANKS * (VX_CFG_XLEN / 8);
  auto *image = reinterpret_cast<uint32_t *>((uintptr_t(scratch + 8192) + bankRow - 1) & ~(bankRow - 1));
  for (unsigned base = 0; base < columns; base += 4) {
    for (unsigned k = 0; k < ksize; ++k)
      for (unsigned j = 0; j < 4; ++j) bvalues[4*k+j] = read_b(base+j, k);
    for (unsigned panel = 0; panel < 2; ++panel) {
      for (unsigned lane = 0; lane < 64; ++lane) {
        unsigned row = lane / 16 * 32 + panel * 16 + lane % 16;
        float sums[4] = {};
        if (use_d)
          for (unsigned j = 0; j < 4; ++j)
            sums[j] = __builtin_bit_cast(float, column_meta_word(col+base+j, row));
        for (unsigned group = 0; group < ksize / (4*unit); ++group) {
          unsigned sel = sparse ? column_sparse_indices(meta, row, group*4, format) : 0;
          unsigned count = sparse ? 2 : 4;
          for (unsigned pos = 0; pos < count; ++pos)
            for (unsigned q = 0; q < unit; ++q) {
              unsigned k = (group*4 + (sparse ? (sel >> (2*pos)) & 3 : pos))*unit + q;
              unsigned stored = (group*count + pos)*unit + q;
              float a = read_a(row, stored, k);
              for (unsigned j = 0; j < 4; ++j)
                sums[j] = __builtin_fmaf(a, bvalues[4*k+j], sums[j]);
            }
        }
        for (unsigned j = 0; j < 4; ++j) {
          uint32_t bits = __builtin_bit_cast(uint32_t, sums[j]);
          image[4*lane+j] = bits;
          column_meta_store(col + base + j, row, bits);
        }
      }
      vx_fence();
      tmcol::cp(column_panel(col+base, panel) + (base & 15), image, 4);
      column_wait(warp);
    }
  }
}
template <typename Input>
static float column_float(unsigned bits) {
  if constexpr (Input::id == tensor::tf32::id) return __builtin_bit_cast(float, bits << 13);
  if constexpr (Input::id == tensor::bf16::id) return __builtin_bit_cast(float, bits << 16);
  return __cupbop_f16_to_f32(bits);
}

template <typename Input>
static bool column_convert_tmem_a(unsigned format) {
  return Input::id == tensor::tf32::id || (format & (1u << 17)) ||
         (Input::id == tensor::int8::id && !(format & (1u << 7)));
}

template <typename Input, typename Output>
static bool column_adapted_mma(unsigned col, const TcgenOperand &a, const TcgenOperand &b,
                               const TcgenOperand &peer_b, bool pair, unsigned use_d,
                               uint8_t *scratch, unsigned columns, unsigned format,
                               unsigned meta, int workspace, bool native_sp, unsigned warp, int a_col) {
  using Geometry = tensor::wgmma_config_t<32, Input, Output>;
  using T = typename Input::dtype;
  constexpr unsigned ratio = 4 / sizeof(T);
  constexpr unsigned packedK = Geometry::fedpK * ratio;
  const bool sparse = format & 4;
  const bool mixed_int = Input::bits == 8 && ((format >> 7 ^ format >> 10) & 1);
  const bool tf32 = column_tf32(format);
  const unsigned cudaK = (tf32 ? 8 : (format & 0x20010) == 0x10 ? 16 : 32) * (sparse ? 2 : 1);
  const bool convert_a = column_convert_tmem_a<Input>(format);
  const bool direct_a = a_col >= 0 && !convert_a && (!sparse || native_sp);
  const bool staged_tmem_a = a_col >= 0 && convert_a && workspace >= 0;
  const unsigned stepK = native_sp ? 2 * packedK : packedK;
  const unsigned bstride = stepK * sizeof(T);
  auto *a_stage = reinterpret_cast<T *>(scratch);
  auto *b_stage = reinterpret_cast<T *>(scratch + 4096);
  constexpr uintptr_t bankRow = VX_CFG_LMEM_NUM_BANKS * (VX_CFG_XLEN / 8);
  auto *masks = reinterpret_cast<uint32_t *>((uintptr_t(scratch + 8192) + bankRow - 1) & ~(bankRow - 1));
  const unsigned a_off = tmcol::smem_offset(a_stage), b_off = tmcol::smem_offset(b_stage);
  if (uint64_t(b_off) + 64 * bstride > (1u << tensor::smem_desc_offset_bits))
    cupbop_async_fail("column MMA scratch exceeds descriptor range", a_off, b_off);
  if constexpr (Input::bits != 8) {
    if (sparse && !native_sp) {
      auto read_b = [&](unsigned n, unsigned k) {
        auto &src = pair && n >= columns / 2 ? peer_b : b;
        return column_float<Input>(column_value<Input>(src, pair ? n % (columns / 2) : n, k, format, true, 0));
      };
      bool exceptional = false;
      for (unsigned n = 0; n < columns && !exceptional; ++n)
        for (unsigned k = 0; k < cudaK && !exceptional; ++k)
          exceptional = !__builtin_isfinite(read_b(n, k));
      if (exceptional) {
        auto read_a = [&](unsigned row, unsigned k, unsigned) {
          if (a_col < 0) return column_float<Input>(column_value<Input>(a, row, k, format, false, 0));
          if (format & (1u << 17)) {
            unsigned type = (format >> 7) & 7;
            return __cupbop_f16_to_f32(column_small_to_half(column_tmem_small_float(a_col, row, k, type), type));
          }
          unsigned width = tf32 ? 1 : 2;
          unsigned bits = column_meta_word(a_col + k / width, row) >> ((k % width) * 16);
          if (tf32) return __builtin_bit_cast(float, bits & 0xffffe000u);
          if (format & (1u << 7)) return __builtin_bit_cast(float, bits << 16);
          return __cupbop_f16_to_f32(bits & 65535u);
        };
        column_scalar_dot(col, columns, cudaK, 1, true, meta, format, use_d, warp, scratch, read_a, read_b);
        return true;
      }
    }
  }
  for (unsigned start = 0; start < cudaK; start += stepK) {
    if (native_sp) {
      // Each 64-row panel occupies one 4-column fragment group in the
      // reserved run. Pack low K words followed by high K words per TC_K.
      __builtin_memset(masks, 0, 2 * 64 * 4 * sizeof(*masks));
      for (unsigned row = 0; row < 128; ++row) {
        unsigned pr = (row % 32 / 16) * 64 + (row / 32) * 16 + row % 16;
        for (unsigned x = 0; x < stepK; x += 4) {
          unsigned indices = column_sparse_indices(meta, row, start + x, format);
          for (unsigned z = 0; z < 2; ++z) {
            unsigned pos = x + ((indices >> (2*z)) & 3);
            constexpr unsigned block = Geometry::tcK * 2 * ratio;
            unsigned elt = pos % block, word = elt / (2 * ratio);
            unsigned bit = pos / block * block + word * ratio + pos % ratio;
            if (elt % (2 * ratio) >= ratio) bit += Geometry::tcK * ratio;
            masks[pr * 4 + bit / 32] |= 1u << (bit % 32);
          }
        }
      }
      vx_fence();
      tmcol::cp(workspace, masks, 8);
    }
    for (unsigned part = 0; part < (mixed_int ? 3u : 1u); ++part) {
      for (unsigned row = 0; !direct_a && row < 128; ++row) {
        unsigned pr = (row % 32 / 16) * 64 + (row / 32) * 16 + row % 16;
        for (unsigned x = 0; x < packedK; ++x) {
          unsigned k = native_sp ? start / 2 + x : start + x;
          if (sparse && !native_sp) {
            unsigned indices = column_sparse_indices(meta, row, k, format);
            unsigned p = k % 4;
            if (p != (indices & 3) && p != (indices >> 2)) {
              a_stage[pr * packedK + x] = 0;
              continue;
            }
            k = k / 4 * 2 + unsigned(p == (indices >> 2));
          }
          if (a_col >= 0 && (format & (1u << 17))) {
            unsigned type = (format >> 7) & 7;
            a_stage[pr * packedK + x] = column_small_to_half(column_tmem_small_float(a_col, row, k, type), type);
          } else if (a_col >= 0) {
            // A sparse-to-dense fallback can unpack values supplied by the
            // original TMEM copy/store alongside its CUDA metadata.
            unsigned per_word = Input::id == tensor::tf32::id && !tf32 ? 2 : ratio;
            uint32_t word = column_meta_word(unsigned(a_col) + k / per_word, row);
            uint32_t value = word >> ((k % per_word) * (32 / per_word));
            if constexpr (Input::id == tensor::tf32::id) {
              if (!tf32) {
                uint32_t half = value & 0xffff;
                value = (format & (1u << 7)) ? half << 16 :
                    __builtin_bit_cast(uint32_t, __cupbop_f16_to_f32(half));
              }
              value >>= 13;
            } else if constexpr (Input::id == tensor::int8::id) {
              if (!(format & (1u << 7))) value = part ? ((value & 128) >> 1) : (value & 127);
            }
            a_stage[pr * packedK + x] = T(value);
          } else {
            a_stage[pr * packedK + x] = column_value<Input>(a, row, k, format, false, part);
          }
        }
      }
      if (staged_tmem_a) {
        // Stage the converted TF32 or FP16 words in TMEM before issuing a
        // native TMEM-source job. The two panels are contiguous here.
        if (native_sp) column_wait(warp);
        auto *packed = reinterpret_cast<uint32_t *>((uintptr_t(b_stage) + bankRow - 1) & ~(bankRow - 1));
        const unsigned width = tmcol::frag_cols();
        for (unsigned pr = 0; pr < 128; ++pr)
          for (unsigned x = 0; x < Geometry::fedpK; ++x) {
            unsigned group = (pr / 64 * Geometry::fedpK + x) / width;
            uint32_t word;
            __builtin_memcpy(&word, a_stage + pr * packedK + x * ratio, sizeof(word));
            packed[(group * 64 + pr % 64) * width + x % width] = word;
          }
        vx_fence();
        tmcol::cp(workspace + 8, packed, 2 * Geometry::fedpK);
        column_wait(warp);
      }
      for (unsigned base = 0; base < columns; base += 64) {
        unsigned count = columns - base < 64 ? columns - base : 64;
        for (unsigned i = 0; i < count; ++i) {
          unsigned n = base + i;
          const auto &src = pair && n >= columns / 2 ? peer_b : b;
          unsigned row = pair ? n % (columns / 2) : n;
          for (unsigned x = 0; x < stepK; ++x) {
            T value = column_value<Input>(src, row, start + x, format, true, part);
            b_stage[i * stepK + x] = value;
          }
        }
        vx_fence();
        for (unsigned n = 0; n < count; n += 16) {
          for (unsigned panel = 0; panel < 2; ++panel) {
            unsigned side_col = native_sp ? workspace + panel * 4 : 0;
            auto idesc = tmcol::make_idesc<Input>(16 / tmcol::frag_cols(),
                column_panel(col + base + n, panel), !use_d && !start && !part, native_sp, side_col);
            auto b_desc = tmcol::smem_desc(b_off + n * bstride, bstride);
            if (staged_tmem_a) {
              tmcol::mma(idesc, tmcol::tmem_col{unsigned(workspace) + 8 + panel * Geometry::fedpK}, b_desc);
            } else if (direct_a) {
              unsigned word = unsigned(a_col) + start / (native_sp ? 2 : 1) / ratio;
              unsigned physical = column_panel(word, panel) + word % 16;
              tmcol::mma(idesc, tmcol::tmem_col{physical}, b_desc);
            } else {
              tmcol::mma(idesc, tmcol::smem_desc(a_off + panel * 64 * packedK * sizeof(T),
                                                 packedK * sizeof(T)), b_desc);
            }
          }
        }
        column_wait(warp);
      }
    }
  }
  return false;
}

// A separate shared slab per issuing warp keeps one producer from
// overwriting another's descriptors before its tc.commit has retired.
template <typename Input, typename Output>
static void column_mma(uint32_t col, uint64_t desc_a, uint64_t desc_b,
                                     uint32_t use_d, uint8_t *scratch, unsigned columns, unsigned format, unsigned meta,
                       int side = -1, int a_col = -1) {
  ColumnAccess access;
  bool shift_a = format & (1u << 18);
  format &= ~(1u << 18);
  using ColumnGeometry = tensor::wgmma_config_t<32, Input, Output>;
  unsigned warp = csr_read_nv(VX_CSR_CTA_RANK);
  if (warp >= 4 || (col & 15) || uint64_t(col) + columns > VX_CFG_TCU_TMEM_COLS / 2 || vx_num_barriers() < 5)
    cupbop_async_fail("unsupported column MMA destination or issuer", col, warp);
  if ((format & 4) && meta >= VX_CFG_TCU_TMEM_COLS / 2)
    cupbop_async_fail("sparse metadata base outside TMEM", meta, 0);
  // A contains 32 bytes per CUDA data-path lane, including a compressed
  // 2:4 operand. A Vortex FEDP read must stay within one 16-column panel.
  if (a_col >= 0) {
    if (unsigned(a_col) % ColumnGeometry::fedpK || uint64_t(a_col) + 8 > VX_CFG_TCU_TMEM_COLS / 2 ||
        (unsigned(a_col) < col + columns && col < unsigned(a_col) + 8))
      cupbop_async_fail("invalid TMEM-source MMA address", a_col, col);
    // Negating either multiplicand changes the same product sign. Stage B
    // with the effective sign so A can stay in its original TMEM columns.
    if (format & (1u << 13)) format ^= (1u << 13) | (1u << 14);
  }
  auto a = a_col >= 0 ? TcgenOperand{} : tcgen_operand(desc_a, column_tf32(format) && (format & (1u << 15)));
  auto b = tcgen_operand(desc_b, column_tf32(format) && (format & (1u << 16)));
  TcgenOperand b_other = b;
  if (side >= 0) {
    if (a_col < 0) a.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(a.start), side));
    b_other.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(b.start), 1));
    b.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(b.start), 0));
  }
  constexpr unsigned rows = 128, kbytes = 32;
  // Only thread zero can issue a column job. The scratch operand is a
  // CTA-shared symbol placed by mem_share2local in the launch allocation.
  if (vx_thread_id() != 0) cupbop_async_fail("column MMA needs lane zero", col, warp);
  scratch += warp * ((rows + 256) * kbytes);
  if (a_col >= 0 || (format & ~0x4b0u) || (((format >> 7) ^ (format >> 10)) & 1)) {
    bool native_sp = false;
#ifdef VX_CFG_TCU_SPARSE_ENABLE
    // Mixed F16/BF16 promoted to TF32 retains 2:4 halves, while native
    // TF32 accepts one of each pair. Explicit TF32 already has that layout.
    native_sp = (format & 4) && (Input::bits != 32 || column_tf32(format)) &&
                ColumnGeometry::sp_k_words == ColumnGeometry::fedpK;
#endif
    int workspace = native_sp || (a_col >= 0 && column_convert_tmem_a<Input>(format)) ? column_sparse_side() : -1;
    bool mirrored = column_adapted_mma<Input, Output>(col, a, b, b_other, side >= 0, use_d, scratch, columns,
                                      format, meta, workspace, native_sp && workspace >= 0, warp, a_col);
    if (workspace >= 0) column_sparse_release(workspace);
    if (!mirrored) column_meta_invalidate(col, columns);
    if (shift_a) column_shift_a(unsigned(a_col), scratch, warp);
    return;
  }
  uint8_t *a_stage = scratch;
  uint8_t *b_stage = scratch + rows * kbytes;
  for (unsigned row = 0; row < rows; ++row) {
    const unsigned panel_row = (row % 32 / 16) * 64 + (row / 32) * 16 + row % 16;
    for (unsigned half = 0; half < 2; ++half)
      __builtin_memcpy(a_stage + panel_row * kbytes + half * 16, tcgen_chunk(a, row, half), 16);
  }
  for (unsigned n = 0; n < columns; ++n)
    for (unsigned half = 0; half < 2; ++half)
      __builtin_memcpy(b_stage + n * kbytes + half * 16, tcgen_chunk(side >= 0 && n >= columns/2 ? b_other : b,
                        side >= 0 ? n % (columns/2) : n, half), 16);
  vx_fence();
  const unsigned a_off = tmcol::smem_offset(a_stage), b_off = tmcol::smem_offset(b_stage);
  if (uint64_t(b_off) + columns * kbytes > (1u << tensor::smem_desc_offset_bits))
    cupbop_async_fail("column MMA scratch exceeds descriptor range", a_off, b_off);
  for (unsigned n = 0; n < columns; n += 16)
    for (unsigned panel = 0; panel < 2; ++panel)
      for (unsigned k = 0; k < kbytes; k += ColumnGeometry::fedpK * 4) {
        auto desc = tmcol::make_idesc<Input>(16 / tmcol::frag_cols(), column_panel(col+n, panel),
                                                   !use_d && !k);
        tmcol::mma(desc, tmcol::smem_desc(a_off + panel * 64 * kbytes + k, kbytes),
                        tmcol::smem_desc(b_off + n * kbytes + k, kbytes));
      }
  const unsigned barrier = ((vx_num_barriers() - 1 - warp) << 8) | csr_read_nv(VX_CSR_CTA_ID);
  tmcol::commit(barrier, 2);
  vx_barrier(barrier, 2);
  column_meta_invalidate(col, columns);
}

template <typename Input, typename Output, bool Pair>
static void column_issue(unsigned addr, uint64_t a, uint64_t b, unsigned use_d, uint8_t *scratch,
                         unsigned n, unsigned format, unsigned meta, bool tmem_a) {
  if constexpr (Pair) {
    unsigned offset = addr - columnPairTag;
    for (unsigned side = 0; side < 2; ++side) {
      auto &run = pairRun(side);
      if (offset > run.size || n > run.size - offset || (run.base + offset + n) * 2 > 1024)
        cupbop_async_fail("paired destination outside addressable column run", addr, side);
      unsigned meta_offset = meta - columnPairTag;
      // F16 uses the selected metadata column, while the 8-bit K64 formats
      // read two adjacent columns. Check the actual span in each peer run.
      if (format & 4) {
        unsigned metadata_cols = (format & 0x20010) == 0x10 ? 1 + (format & 1) : 2;
        if (meta_offset > run.size || metadata_cols > run.size - meta_offset)
          cupbop_async_fail("paired metadata outside column run", meta, side);
      }
      unsigned a_offset = unsigned(a) - columnPairTag;
      if (tmem_a && (a_offset > run.size || 8 > run.size - a_offset))
        cupbop_async_fail("paired TMEM-source MMA outside its run", unsigned(a), side);
      column_mma<Input, Output>(run.base + offset, a, b, use_d, scratch, n, format,
                                run.base + meta_offset, side, tmem_a ? int(run.base + a_offset) : -1);
    }
  } else {
    if (tmem_a && a > VX_CFG_TCU_TMEM_COLS / 2) cupbop_async_fail("invalid TMEM-source MMA base", a, 0);
    column_mma<Input, Output>(addr, a, b, use_d, scratch, n, format, meta, -1, tmem_a ? int(a) : -1);
  }
}

template <bool Pair>
static void column_mma_format(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                              uint8_t *scratch, unsigned n, unsigned format, unsigned meta, bool tmem_a = false) {
  // Independent 3-bit A/B type fields and 2-bit accumulator field.
  if (format & (1u << 17))
    return column_issue<tensor::fp16, tensor::fp32, Pair>(addr, a, b, use_d, scratch, n, format, meta, tmem_a);
  switch (format & 0x1ff0u) {
    case 0x10: return column_issue<tensor::fp16, tensor::fp32, Pair>(addr, a, b, use_d, scratch, n, format, meta, tmem_a);
    case 0x490: return column_issue<tensor::bf16, tensor::fp32, Pair>(addr, a, b, use_d, scratch, n, format, meta, tmem_a);
    case 0x910: case 0x90: case 0x410:
      return column_issue<tensor::tf32, tensor::fp32, Pair>(addr, a, b, use_d, scratch, n, format, meta, tmem_a);
    case 0x20: return column_issue<tensor::uint8, tensor::int32, Pair>(addr, a, b, use_d, scratch, n, format, meta, tmem_a);
    case 0xa0: case 0x420: case 0x4a0:
      return column_issue<tensor::int8, tensor::int32, Pair>(addr, a, b, use_d, scratch, n, format, meta, tmem_a);
    default: cupbop_async_fail("invalid column MMA format", format, n);
  }
}

extern "C" void __cupbop_column_pair_mma(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                         uint8_t *scratch, unsigned n, unsigned format) {
  column_mma_format<true>(addr, a, b, use_d, scratch, n, format, 0);
}
extern "C" void __cupbop_column_mma(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                    uint8_t *scratch, unsigned n, unsigned format) {
  column_mma_format<false>(addr, a, b, use_d, scratch, n, format, 0);
}

extern "C" void __cupbop_column_pair_mma_sp(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                         uint8_t *scratch, unsigned n, unsigned format, unsigned meta) {
  column_mma_format<true>(addr, a, b, use_d, scratch, n, format, meta);
}
extern "C" void __cupbop_column_mma_sp(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                    uint8_t *scratch, unsigned n, unsigned format, unsigned meta) {
  column_mma_format<false>(addr, a, b, use_d, scratch, n, format, meta);
}
// The CUDA assembly operand selects TMEM or a shared descriptor. Separate
// entry points preserve the ABI of previously translated shared-source IR.
extern "C" void __cupbop_column_mma_ts(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                       uint8_t *scratch, unsigned n, unsigned format) {
  column_mma_format<false>(addr, a, b, use_d, scratch, n, format, 0, true);
}
extern "C" void __cupbop_column_pair_mma_ts(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                            uint8_t *scratch, unsigned n, unsigned format) {
  column_mma_format<true>(addr, a, b, use_d, scratch, n, format, 0, true);
}
extern "C" void __cupbop_column_mma_ts_sp(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                          uint8_t *scratch, unsigned n, unsigned format, unsigned meta) {
  column_mma_format<false>(addr, a, b, use_d, scratch, n, format, meta, true);
}
extern "C" void __cupbop_column_pair_mma_ts_sp(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                               uint8_t *scratch, unsigned n, unsigned format, unsigned meta) {
  column_mma_format<true>(addr, a, b, use_d, scratch, n, format, meta, true);
}


#include "cudaKernelImpl_column_mx.inc"

static void column_copy(unsigned col, TcgenOperand src, unsigned cols, uint8_t *scratch,
                        unsigned rowMask = 127, unsigned bits = 0) {
  ColumnAccess access;
  unsigned warp = csr_read_nv(VX_CSR_CTA_RANK);
  if (warp >= 4 || vx_thread_id() || col % 4 || uint64_t(col) + cols > VX_CFG_TCU_TMEM_COLS / 2 || vx_num_barriers() < 5)
    cupbop_async_fail("unsupported column copy destination or issuer", col, warp);
  scratch += warp * (128 + 256) * 32;
  constexpr uintptr_t bankRow = VX_CFG_LMEM_NUM_BANKS * (VX_CFG_XLEN / 8);
  scratch = reinterpret_cast<uint8_t *>((uintptr_t(scratch) + bankRow - 1) & ~(bankRow - 1));
  for (unsigned group = 0; group < cols / 4; ++group) {
    for (unsigned half = 0; half < 2; ++half) {
      auto *stage = scratch + (2 * group + half) * 1024;
      for (unsigned row = 0; row < 64; ++row) {
        unsigned logical = (row / 16) * 32 + half * 16 + row % 16;
        // warpx2::02_13 broadcasts the first 32 rows to warps 0/1 and the next 32 to 2/3.
        unsigned sourceRow = rowMask == 95 ? (logical & 31) + ((logical & 64) >> 1) : logical & rowMask;
        const auto *packed = reinterpret_cast<const uint8_t *>(tcgen_chunk(src, sourceRow, group));
        uint8_t *out = stage + row * 16;
        if (bits == 4) {
          for (unsigned j = 0; j < 8; ++j) {
            out[2 * j] = (packed[j] & 15) << 2;
            out[2 * j + 1] = (packed[j] >> 4) << 2;
          }
        } else if (bits == 6) {
          for (unsigned j = 0; j < 4; ++j) {
            unsigned v = packed[3*j] | (packed[3*j+1] << 8) | (packed[3*j+2] << 16);
            for (unsigned k = 0; k < 4; ++k) out[4*j+k] = (v >> (6*k)) & 63;
          }
        } else {
          __builtin_memcpy(out, packed, 16);
        }
        if (__cupbop_column_meta_table) {
          for (unsigned j = 0; j < 4; ++j) {
            uint32_t word;
            __builtin_memcpy(&word, stage + row * 16 + j * 4, sizeof(word));
            column_meta_store(col + group * 4 + j, logical, word);
          }
        }
      }
      vx_fence();
      unsigned dst = col + group * 4;
      tmcol::cp(column_panel(dst, half) + dst % 16, stage, 4);
    }
  }
  unsigned bar = ((vx_num_barriers() - 1 - warp) << 8) | csr_read_nv(VX_CSR_CTA_ID);
  tmcol::commit(bar, 2);
  vx_barrier(bar, 2);
}

extern "C" void __cupbop_column_cp(unsigned col, uint64_t descriptor, unsigned cols, uint8_t *scratch) {
  column_copy(col, tcgen_operand(descriptor), cols, scratch);
}
static void column_pair_copy(unsigned addr, uint64_t descriptor, unsigned cols, uint8_t *scratch,
                             unsigned rowMask, unsigned bits = 0) {
  unsigned offset = addr - columnPairTag;
  for (unsigned side = 0; side < 2; ++side) {
    auto &run = pairRun(side);
    if (offset > run.size || cols > run.size - offset)
      cupbop_async_fail("paired copy outside allocation", addr, cols);
    auto src = tcgen_operand(descriptor);
    src.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(src.start), side));
    column_copy(run.base + offset, src, cols, scratch, rowMask, bits);
  }
}
extern "C" void __cupbop_column_pair_cp(unsigned addr, uint64_t descriptor, unsigned cols, uint8_t *scratch) {
  column_pair_copy(addr, descriptor, cols, scratch, 127);
}
extern "C" void __cupbop_column_cp_warpx4(unsigned addr, uint64_t descriptor, unsigned pair, uint8_t *scratch) {
  if (pair) column_pair_copy(addr, descriptor, 4, scratch, 31);
  else column_copy(addr, tcgen_operand(descriptor), 4, scratch, 31);
}
extern "C" void __cupbop_column_cp_layout(unsigned addr, uint64_t descriptor, unsigned pair, unsigned cols,
                                         unsigned rowMask, unsigned bits, uint8_t *scratch) {
  if (pair) column_pair_copy(addr, descriptor, cols, scratch, rowMask, bits);
  else column_copy(addr, tcgen_operand(descriptor), cols, scratch, rowMask, bits);
}
static unsigned column_transfer(unsigned addr, unsigned displacement, unsigned count) {
  unsigned col = (addr & 0xffff) + displacement;
  unsigned row = addr >> 16;
  if (col & columnPairTag) {
    unsigned side = cluster_rank() & 1;
    auto &run = pairRun(side);
    col -= columnPairTag;
    if (col > run.size || count > run.size - col)
      cupbop_async_fail("paired transfer outside run", addr, displacement);
    col += run.base;
    if (side && row >= 128) row -= 128;
  }
  unsigned warp = csr_read_nv(VX_CSR_CTA_RANK);
  if (warp >= 4 || row != warp * 32 || col + count > VX_CFG_TCU_TMEM_COLS / 2)
    cupbop_async_fail("column transfer outside warp datapath", addr, warp);
  return col;
}

// One native register stores two columns across the block's 16 physical
// rows. rs2 names the last register in the consecutive f0..fN store.
static inline void column_store_words(unsigned dest, unsigned first, unsigned second, bool two_regs) {
  register float f0 __asm__("f0") = __builtin_bit_cast(float, first);
  if (two_regs) {
    register float f1 __asm__("f1") = __builtin_bit_cast(float, second);
    __asm__ volatile(".insn r %0, 1, 5, x0, %1, x1" :: "i"(RISCV_CUSTOM0), "r"(dest), "f"(f0), "f"(f1) : "memory");
  } else {
    __asm__ volatile(".insn r %0, 1, 5, x0, %1, x0" :: "i"(RISCV_CUSTOM0), "r"(dest), "f"(f0) : "memory");
  }
}

extern "C" void __cupbop_column_stsplit(unsigned addr, unsigned delta, unsigned count,
                                        unsigned a, unsigned b, unsigned c, unsigned d) {
  ColumnAccess access;
  unsigned addresses[] = {addr, addr + delta};
  unsigned cols[2];
  for (unsigned h = 0; h < 2; ++h) {
    cols[h] = column_transfer(addresses[h] & ~(16u << 16), 0, count);
    if (cols[h] % 4) cupbop_async_fail("unaligned column store", addresses[h], cols[h]);
  }
  unsigned lane = vx_thread_id();
  for (unsigned h = 0; h < 2; ++h) {
    unsigned half = (addresses[h] >> 20) & 1;
    unsigned col = cols[h];
    unsigned source = lane % 16 + h * 16;
    unsigned x = vx_shfl_idx(a, source, 31, 0), y = vx_shfl_idx(b, source, 31, 0);
    unsigned z = vx_shfl_idx(c, source, 31, 0), w = vx_shfl_idx(d, source, 31, 0);
    unsigned first = lane < 16 ? x : y, second = lane < 16 ? z : w;
    unsigned row = 32 * csr_read_nv(VX_CSR_CTA_RANK) + half * 16 + lane % 16;
    column_meta_store(col + lane / 16, row, first);
    if (count == 4) column_meta_store(col + 2 + lane / 16, row, second);
    unsigned dest = tmcol::make_taddr(tmcol::warp_lane(), column_panel(col, half) + col % 16);
    column_store_words(dest, first, second, count == 4);
  }
  column_publish_store();
}

extern "C" void __cupbop_column_st32(unsigned addr, unsigned count, unsigned a, unsigned b, unsigned c, unsigned d) {
  __cupbop_column_stsplit(addr, 16u << 16, count, a, b, c, d);
}

// Keep the entry point used by existing translated device bitcode.
extern "C" void __cupbop_column_st4(unsigned addr, unsigned a, unsigned b, unsigned c, unsigned d) {
  __cupbop_column_st32(addr, 4, a, b, c, d);
}

// PTX ISA, tcgen05 matrix fragments for .16x64b/.16x128b/.16x256b.
// Convert one source register tuple into the native 16-row lane-per-thread layout.
static inline unsigned column_st16_word(unsigned width, unsigned row, unsigned col,
                                        unsigned a, unsigned b, unsigned c, unsigned d) {
  unsigned source = (row % 8) * 4;
  if (width == 2) {
    source += row / 8 + (col % 2) * 2;
  } else {
    source += width == 4 ? col : col / 2;
  }
  unsigned x = vx_shfl_idx(a, source, 31, 0), y = vx_shfl_idx(b, source, 31, 0);
  if (width == 2) return col < 2 ? x : y;
  if (width == 4) return row < 8 ? x : y;
  unsigned z = vx_shfl_idx(c, source, 31, 0), w = vx_shfl_idx(d, source, 31, 0);
  // All four exchanges need their source lanes active. Keep them above
  // the row-dependent selection when the RISC-V backend introduces branches.
  __asm__ volatile ("" :: "r"(x), "r"(y), "r"(z), "r"(w));
  return row < 8 ? ((col & 1) ? y : x) : ((col & 1) ? w : z);
}

extern "C" void __cupbop_column_st16(unsigned addr, unsigned width, unsigned count,
                                     unsigned a, unsigned b, unsigned c, unsigned d) {
  ColumnAccess access;
  unsigned col = column_transfer(addr & ~(16u << 16), 0, count);
  if (col % 4) cupbop_async_fail("unaligned column store", addr, col);
  unsigned lane = vx_thread_id(), half = (addr >> 20) & 1;
  for (unsigned j = 0; j < count; j += 4) {
    unsigned first = column_st16_word(width, lane % 16, j + lane / 16, a, b, c, d);
    unsigned second = column_st16_word(width, lane % 16, j + 2 + lane / 16, a, b, c, d);
    unsigned dst = col + j;
    unsigned row = 32 * csr_read_nv(VX_CSR_CTA_RANK) + half * 16 + lane % 16;
    column_meta_store(dst + lane / 16, row, first);
    if (count != 2) column_meta_store(dst + 2 + lane / 16, row, second);
    column_store_words(tmcol::make_taddr(tmcol::warp_lane(), column_panel(dst, half) + dst % 16),
                       first, second, count != 2);
  }
  column_publish_store();
}
extern "C" void __cupbop_column_wait_st() { tmcol::wait_st(); }

static inline unsigned column_load_word(unsigned col, unsigned half, unsigned row) {
  ColumnWords words;
  tmcol::load(words, tmcol::make_taddr(tmcol::warp_lane(), column_panel(col, half)));
  unsigned bits;
  __builtin_memcpy(&bits, &words.data[(col & 15) / 2], sizeof(bits));
  return vx_shfl_idx(bits, row + (col & 1) * 16, 31, 0);
}

extern "C" uint32_t __cupbop_column_ld32(uint32_t address, uint32_t displacement) {
  ColumnAccess access;
  unsigned col = column_transfer(address, displacement, 1);
  unsigned lane = vx_thread_id();
  unsigned lo = column_load_word(col, 0, lane % 16), hi = column_load_word(col, 1, lane % 16);
  return lane < 16 ? lo : hi;
}

extern "C" uint32_t __cupbop_column_ldsplit(unsigned addr, unsigned delta) {
  ColumnAccess access;
  unsigned second = addr + delta;
  unsigned c0 = column_transfer(addr & ~(16u << 16), 0, 1);
  unsigned c1 = column_transfer(second & ~(16u << 16), 0, 1);
  unsigned lane = vx_thread_id();
  unsigned lo = column_load_word(c0, (addr >> 20) & 1, lane % 16);
  unsigned hi = column_load_word(c1, (second >> 20) & 1, lane % 16);
  return lane < 16 ? lo : hi;
}

static unsigned column_ld16(unsigned addr, unsigned width, unsigned reg, bool pack) {
  ColumnAccess access;
  unsigned stride = pack ? 2 : 1;
  unsigned col = column_transfer(addr & ~(16u << 16), 0, width * stride);
  unsigned half = (addr >> 20) & 1, lane = vx_thread_id();
  unsigned row = lane / 4 + 8 * (width == 2 ? lane % 2 : (width == 4 ? reg : reg / 2));
  unsigned group = width == 2 ? (lane / 2) % 2 : lane % 4;
  unsigned groups = width == 2 ? 2 : 4;
  unsigned result = 0;
  for (unsigned i = 0; i < groups; ++i) {
    unsigned offset = width == 8 ? 2 * i + reg % 2 : i;
    unsigned at = col + offset * stride;
    unsigned bits = column_load_word(at, half, row);
    if (pack) bits = (bits & 0xffff) | (column_load_word(at + 1, half, row) << 16);
    if (i == group) result = bits;
  }
  return result;
}
extern "C" uint32_t __cupbop_column_ld16(unsigned addr, unsigned width, unsigned reg) {
  return column_ld16(addr, width, reg, false);
}
extern "C" uint32_t __cupbop_column_ldpack(unsigned addr, unsigned delta, unsigned width, unsigned reg) {
  if (width != 1) return column_ld16(addr, width, reg, true);
  unsigned lo = __cupbop_column_ldsplit(addr, delta);
  unsigned hi = __cupbop_column_ldsplit(addr + 1, delta);
  return (lo & 0xffff) | (hi << 16);
}

// The native address is four-column aligned. The CTA warp owns these
// 16 physical rows; another warp's transfers land in a different TCU block
// or a separate CTA allocation. Read and update only this four-column group.
// CP and MMA writes to these rows cover whole aligned groups.
static void column_store_partial(unsigned col, unsigned half, unsigned value, unsigned mask) {
  unsigned dest = tmcol::make_taddr(tmcol::warp_lane(), column_panel(col, half) + (col & 12));
  tmcol::wait_st();
  register float f0 __asm__("f0"), f1 __asm__("f1");
  __asm__ volatile(".insn r %2, 0, 5, x0, %3, x1" : "=f"(f0), "=f"(f1)
                   : "i"(RISCV_CUSTOM0), "r"(dest) : "memory");
  unsigned first = __builtin_bit_cast(unsigned, f0), second = __builtin_bit_cast(unsigned, f1);
  unsigned lane = vx_thread_id(), j = col & 3;
  unsigned &word = j < 2 ? first : second;
  if (lane / 16 == (j & 1)) {
    word = (word & ~mask) | (value & mask);
    unsigned row = 32 * csr_read_nv(VX_CSR_CTA_RANK) + 16 * half + lane % 16;
    column_meta_store(col, row, word);
  }
  column_store_words(dest, first, second, j >= 2);
}

extern "C" void __cupbop_column_st_tile(unsigned addr, unsigned delta, unsigned width, unsigned unpack,
                                        unsigned a, unsigned b, unsigned c, unsigned d) {
  ColumnAccess access;
  unsigned lane = vx_thread_id(), count = width * (unpack ? 2 : 1);
  unsigned halves = width == 1 ? 2 : 1;
  for (unsigned h = 0; h < halves; ++h) {
    unsigned address = addr + h * delta;
    unsigned base = column_transfer(address & ~(16u << 16), 0, count);
    unsigned half = (address >> 20) & 1;
    for (unsigned j = 0; j < width; ++j) {
      unsigned value = width == 1 ? vx_shfl_idx(a, h * 16 + lane % 16, 31, 0)
                                  : column_st16_word(width, lane % 16, j, a, b, c, d);
      if (unpack) {
        column_store_partial(base + 2 * j, half, value, 0xffff);
        column_store_partial(base + 2 * j + 1, half, value >> 16, 0xffff);
      } else {
        column_store_partial(base + j, half, value, ~0u);
      }
    }
  }
  column_publish_store();
}
#endif
#ifdef CUPBOP_NATIVE_TMEM
static unsigned tcgen_pair_peer() {
  unsigned rank = cluster_rank();
  unsigned peer = rank ^ 1u;
  if (peer >= __cupbop_cluster_register(1, 0))
    cupbop_async_fail("TCGEN needs a resident CTA pair", rank, peer);
  return peer;
}

static unsigned tcgen_pair_slot() {
  return csr_read_nv(VX_CSR_CTA_ID) - cluster_rank() + tcgen_pair_peer();
}

template <unsigned Ctas>
static void tcgen_native_mma(uint32_t taddr, const TcgenOperand (&a)[Ctas],
                             const TcgenOperand (&b)[Ctas], unsigned issuer, uint32_t use_d) {
  constexpr unsigned columns_per_cta = 256 / Ctas;
  for (unsigned col = 0; col < 256; ++col) {
    const auto &local_b = b[col / columns_per_cta];
    unsigned local_col = col % columns_per_cta;
    uint64_t b_words[4];
    __builtin_memcpy(b_words, __builtin_assume_aligned(tcgen_chunk(local_b, local_col, 0), 16), 16);
    __builtin_memcpy(b_words + 2, __builtin_assume_aligned(tcgen_chunk(local_b, local_col, 1), 16), 16);
    for (unsigned cta = 0; cta < Ctas; ++cta) {
      uint64_t dest = uint64_t(cta != issuer) << 32;
      for (unsigned row = 0; row < 128; ++row) {
        uint64_t a_words[4];
        __builtin_memcpy(a_words, __builtin_assume_aligned(tcgen_chunk(a[cta], row, 0), 16), 16);
        __builtin_memcpy(a_words + 2, __builtin_assume_aligned(tcgen_chunk(a[cta], row, 1), 16), 16);
        const uint64_t address = dest | (row << 16) | (taddr + col);
        if (use_d)
          vx_tmem_mma_s8_k8<true>(address, a_words[0], b_words[0]);
        else
          vx_tmem_mma_s8_k8<false>(address, a_words[0], b_words[0]);
        for (unsigned k = 1; k < 4; ++k)
          vx_tmem_mma_s8_k8<true>(address, a_words[k], b_words[k]);
      }
    }
  }
  vx_tmem_drain();
}
#endif
} // namespace

#endif

// The hardware initializer in lifted Blackwell SASS uses a 20-bit biased
// expected count at bit 1, a biased pending count at bit 43, and parity at
// bit 63. The remaining 22 bits store our signed expected-minus-copied bytes.
// Software copies can finish before the producer posts its expect_tx.
constexpr uint64_t tcgen_count_mask = (1u << 20) - 1;
constexpr uint64_t tcgen_tx_mask = (1u << 22) - 1;
extern "C" void __cupbop_tcgen_mbar_init(uint64_t *bar, unsigned count) {
  if (!count || count > tcgen_count_mask) cupbop_async_fail("invalid mbarrier count", count, 0);
  uint64_t biased = (0u - count) & tcgen_count_mask;
  __atomic_store_n(bar, (biased << 1) | (biased << 43), __ATOMIC_RELEASE);
}

extern "C" uint64_t __cupbop_tcgen_arrive(uint64_t *bar, unsigned arrivals, int32_t bytes) {
  // Serialize participating lanes of this warp, even if they update different
  // addresses. Other warps race normally using the atomic compare-exchange.
  uint64_t token = 0;
  unsigned mask = vx_active_threads();
  while (mask) {
    unsigned elected = mask & (0u - mask);
    if (elected == (1u << vx_thread_id())) {
      uint64_t old = __atomic_load_n(bar, __ATOMIC_ACQUIRE);
      for (;;) {
        unsigned expected = (old >> 1) & tcgen_count_mask;
        unsigned pending = ((old >> 43) & tcgen_count_mask) + arrivals;
        int32_t tx = int32_t((old >> 21) & tcgen_tx_mask);
        if (tx & (1 << 21)) tx -= 1 << 22;
        tx += bytes;
        const uint64_t phase = old & (1ull << 63);
        // Pending == 2^20 means no arrivals remain. A spare low bit
        // distinguishes this state from a newly initialized count word.
        if (old & 1) pending += 1u << 20;
        if (pending > (1u << 20) || tx < -(1 << 21) || tx >= (1 << 21))
          cupbop_async_fail("invalid mbarrier update", pending, tx);
        bool done = pending == (1u << 20) && tx == 0;
        uint64_t next = (done ? (phase ^ (1ull << 63)) : phase) | (uint64_t(expected) << 1) |
                        (uint64_t(done ? expected : pending & tcgen_count_mask) << 43) |
                        ((uint64_t(tx) & tcgen_tx_mask) << 21) | (!done && pending == (1u << 20));
        if (__atomic_compare_exchange_n(bar, &old, next, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
          token = phase;
          break;
        }
      }
    }
    mask ^= elected;
  }
  return token;
}

#if defined(VX_SIMX_CSR_CANCEL_SUBMIT) && __has_include(<vx_simx_clc.h>)
#include <vx_simx_clc.h>
#define CUPBOP_NATIVE_SIMX_CLC
#endif

static void cluster_cancel_fallback(uint32_t *response, uint64_t *bar, bool multicast, unsigned recipients) {
  uint32_t first[3] = {};
  uint32_t success = 0;
#if defined(CUPBOP_NATIVE_SIMX_CLC) && !defined(VX_SIMX_CSR_CANCEL_ASYNC)
  if (cluster_context().direct_launch_flags & CUPBOP_LAUNCH_SIMX_CLC)
    success = vx_simx_try_cancel(first);
#endif
  // Older SimX builds publish a polled result. Other backends decline the request.
  for (unsigned rank = 0; rank < recipients; ++rank) {
    auto *dst = multicast ? static_cast<uint32_t *>(__cupbop_cluster_map(response, rank)) : response;
    auto *done = multicast ? static_cast<uint64_t *>(__cupbop_cluster_map(bar, rank)) : bar;
    dst[0] = first[0];
    dst[1] = first[1] | (first[2] << 16);
    dst[2] = success;
    dst[3] = 0;
    __cupbop_tcgen_arrive(done, 0, -16);
  }
}

extern "C" __attribute__((convergent, noduplicate)) void
__cupbop_cluster_try_cancel(uint32_t *response, uint64_t *bar, uint32_t multicast) {
  const unsigned recipients = multicast ? __cupbop_cluster_register(1, 0) : 1;
#if defined(CUPBOP_NATIVE_SIMX_CLC) && defined(VX_SIMX_CSR_CANCEL_ASYNC)
  if (cluster_context().direct_launch_flags & CUPBOP_LAUNCH_SIMX_CLC) {
    auto *dst = multicast ? static_cast<uint32_t *>(__cupbop_cluster_map(response, 0)) : response;
    auto *done = multicast ? static_cast<uint64_t *>(__cupbop_cluster_map(bar, 0)) : bar;
    vx_simx_cancel_async(dst, done, cluster_context().cluster_stride, recipients);
    return;
  }
#endif
  // Older SimX mailboxes admit one requesting lane per warp at a time.
  for (uint32_t lanes = vx_active_threads(); lanes; lanes &= lanes - 1) {
    if (vx_thread_id() == __builtin_ctz(lanes))
      cluster_cancel_fallback(response, bar, multicast, recipients);
  }
}

extern "C" unsigned __cupbop_tcgen_wait(uint64_t *bar, unsigned parity, unsigned blocking) {
  do {
    if ((__atomic_load_n(bar, __ATOMIC_ACQUIRE) >> 63) != (parity & 1)) return 1;
  } while (blocking);
  return 0;
}

extern "C" void __cupbop_tcgen_tma_load(void *smem, const void *desc, uint64_t *bar, unsigned rank, int c0, int c1,
                                        int c2, int c3, int c4) {
  const cupbop_tmap *t = cupbop_tmap_of(desc, rank);
  unsigned bytes = t->elem;
  for (unsigned i = 0; i < rank; ++i)
    bytes *= t->box[i];
  cupbop_tma_box(smem, desc, rank, c0, c1, c2, c3, c4, 0);
  __cupbop_tcgen_arrive(bar, 0, -int32_t(bytes));
}

// Complete the selected remote barriers at their matching CTA-relative offset.
extern "C" void __cupbop_cluster_commit(void *bar, unsigned mask) {
  for (unsigned r = 0; mask; ++r, mask >>= 1)
    if (mask & 1) __cupbop_tcgen_arrive(static_cast<uint64_t *>(__cupbop_cluster_map(bar,r)), 1, 0);
}

extern "C" void __cupbop_tma_multicast(void *dst, const void *desc, void *bar, unsigned rank,
                                       int c0,int c1,int c2,int c3,int c4,unsigned mask) {
  if (!mask) return;
  const auto *t = cupbop_tmap_of(desc, rank);
  unsigned bytes = t->elem;
  for (unsigned i = 0; i < rank; ++i) bytes *= t->box[i];
  // Read each source element once. The swizzle phase is local to each receiver.
  auto *first = static_cast<char *>(__cupbop_cluster_map(dst, __builtin_ctz(mask)));
  cupbop_tma_box(first, desc, rank, c0,c1,c2,c3,c4,0);
  for (unsigned peers = mask & (mask - 1); peers; peers &= peers - 1) {
    auto *target = static_cast<char *>(__cupbop_cluster_map(dst, __builtin_ctz(peers)));
    const unsigned row_bytes = t->box[0] * t->elem;
    for (unsigned row = 0; row < bytes; row += row_bytes) {
      const uintptr_t src = uintptr_t(first + row), dest = uintptr_t(target + row);
      const unsigned a = t->swizzle ? ((src >> 7) & 7) << 4 : 0;
      const unsigned b = t->swizzle ? ((dest >> 7) & 7) << 4 : 0;
      if (cupbop_copy_tma_sectors(dest, src, row_bytes, b, a)) continue;
      for (unsigned col = 0; col < row_bytes; col += t->elem)
        cupbop_copy_elem(reinterpret_cast<void *>((dest+col)^b), reinterpret_cast<const void *>((src+col)^a), t->elem);
    }
  }
  for (; mask; mask &= mask-1)
    __cupbop_tcgen_arrive(static_cast<uint64_t *>(__cupbop_cluster_map(bar,__builtin_ctz(mask))),0,-int32_t(bytes));
}

// Each CTA's first producer warp owns a separate reserved barrier in each
// receiver. Attach and arrive before issue so a fast completion cannot
// roll the phase twice. Publish PTX byte completion after all writes land.
#if defined(VX_CFG_EXT_DXA_ENABLE) && VX_CFG_NUM_THREADS == 32
static __attribute__((always_inline, convergent)) inline bool cupbop_multicast_dxa(
    unsigned issue, void *dst, const void *src, void *mbar, unsigned rank,
    int c0, int c1, int c2, int c3, int c4, unsigned mask, unsigned raw_bytes) {
  const unsigned members = __cupbop_cluster_register(1, 0);
  if (vx_active_threads() != UINT32_MAX || csr_read_nv(VX_CSR_CTA_RANK) != 0 ||
      vx_num_barriers() <= members) return false;
  const unsigned issuers = vx_vote_ballot(issue);
  if (!issuers || (issuers & (issuers - 1))) return false;
  const unsigned lane = __builtin_ctz(issuers);
  // WGATHER takes its inputs from hardware lane zero. PTX lets any one lane
  // issue the copy, and operands outside that lane may be undefined.
  const unsigned peers = vx_shfl_idx(mask, lane, 31, 0);
  if (!peers || (peers >> members)) return false;
  dst = reinterpret_cast<void *>(vx_shfl_idx(uintptr_t(dst), lane, 31, 0));
  src = reinterpret_cast<const void *>(vx_shfl_idx(uintptr_t(src), lane, 31, 0));
  mbar = reinterpret_cast<void *>(vx_shfl_idx(uintptr_t(mbar), lane, 31, 0));
  rank = vx_shfl_idx(rank, lane, 31, 0);
  raw_bytes = vx_shfl_idx(raw_bytes, lane, 31, 0);
  c0 = vx_shfl_idx(c0, lane, 31, 0);
  c1 = vx_shfl_idx(c1, lane, 31, 0);
  c2 = vx_shfl_idx(c2, lane, 31, 0);
  c3 = vx_shfl_idx(c3, lane, 31, 0);
  c4 = vx_shfl_idx(c4, lane, 31, 0);
  unsigned slot = UINT32_MAX, bytes = 0, chunks = 1;
  bool valid = false;
  if (vx_thread_id() == 0) {
    if (!rank) {
      const unsigned encoded = (cluster_context().direct_launch_flags >> CUPBOP_RAW_DXA_SLOT_SHIFT)
                             & CUPBOP_RAW_DXA_SLOT_MASK;
      const uintptr_t address = uintptr_t(src);
      valid = encoded && raw_bytes && !((address | uintptr_t(dst) | raw_bytes) & 15) &&
              address <= UINT32_MAX - (raw_bytes - 1);
      slot = encoded - 1;
      c0 = uint32_t(address) / sizeof(uint32_t);
      bytes = raw_bytes;
      chunks = bytes / CUPBOP_RAW_DXA_TILE_BYTES;
    } else {
      const auto *map = cupbop_tmap_of(src, rank);
      slot = cupbop_tma_slot(map);
      valid = cupbop_tma_dxa_ok(slot, dst, c0, c1, c2, c3, c4) &&
              (!map->swizzle || !(cluster_context().cluster_stride & 127));
      bytes = map->elem;
      for (unsigned i = 0; i < rank; ++i) bytes *= map->box[i];
    }
  }
  if (vx_vote_ballot(valid) != 1) return false;
  chunks = vx_shfl_idx(chunks, 0, 31, 0);
  const unsigned issuer = cluster_rank();
  const unsigned base = ((vx_num_barriers() - 1 - issuer) << 8) | (csr_read_nv(VX_CSR_CTA_ID) - issuer);
  // Hardware applies rank strides only for two or more mask bits. For a
  // single recipient, encode its actual page and its own completion barrier.
  const unsigned page_rank = (peers & (peers - 1)) ? 0 : __builtin_ctz(peers);
  const unsigned issue_bar = base + page_rank;
  uintptr_t first_page = uintptr_t(__cupbop_cluster_map(dst, page_rank));
  for (unsigned chunk = 0; chunk < chunks; ++chunk) {
    unsigned phases = 0;
    for (unsigned pending = peers; pending; pending &= pending - 1) {
      unsigned peer = __builtin_ctz(pending);
      vx_barrier_expect_tx(base + peer, 1);
      phases |= unsigned(vx_barrier_arrive(base + peer, 1) & 1) << peer;
    }
    unsigned offset = chunk * CUPBOP_RAW_DXA_TILE_BYTES;
    cupbop_tma_dxa_issue_meta((issue_bar << 4) | (slot & 15u), reinterpret_cast<void *>(first_page + offset),
                              rank ? rank : 1, unsigned(c0) + offset / sizeof(uint32_t), c1, c2, c3, c4, peers);
    for (unsigned pending = peers; pending; pending &= pending - 1) {
      unsigned peer = __builtin_ctz(pending);
      vx_barrier_wait(base + peer, (phases >> peer) & 1);
    }
  }
  if (vx_thread_id() == 0) for (unsigned pending = peers; pending; pending &= pending - 1)
    __cupbop_tcgen_arrive(static_cast<uint64_t *>(__cupbop_cluster_map(mbar, __builtin_ctz(pending))),
                          0, -int32_t(bytes));
  return true;
}
#endif

extern "C" __attribute__((convergent)) void __cupbop_tma_multicast_warp(
    unsigned issue, void *dst, const void *desc, void *mbar, unsigned rank,
    int c0, int c1, int c2, int c3, int c4, unsigned mask) {
#if defined(VX_CFG_EXT_DXA_ENABLE) && VX_CFG_NUM_THREADS == 32
  if (cupbop_multicast_dxa(issue, dst, desc, mbar, rank, c0, c1, c2, c3, c4, mask, 0)) return;
#endif
  if (issue) __cupbop_tma_multicast(dst, desc, mbar, rank, c0, c1, c2, c3, c4, mask);
}

extern "C" void __cupbop_bulk_multicast(void *dst, const void *src, unsigned bytes, void *bar, unsigned mask) {
  if (!mask) return;
  void *first = __cupbop_cluster_map(dst, __builtin_ctz(mask));
  __cupbop_bulk_copy(first,src,bytes);
  for (unsigned peers = mask & (mask-1); peers; peers &= peers-1)
    __cupbop_bulk_copy(__cupbop_cluster_map(dst,__builtin_ctz(peers)),first,bytes);
  for (; mask; mask &= mask-1)
    __cupbop_tcgen_arrive(static_cast<uint64_t *>(__cupbop_cluster_map(bar,__builtin_ctz(mask))),0,-int32_t(bytes));
}

extern "C" __attribute__((convergent)) void __cupbop_bulk_multicast_warp(
    unsigned issue, void *dst, const void *src, unsigned bytes, void *mbar, unsigned mask) {
#if defined(VX_CFG_EXT_DXA_ENABLE) && VX_CFG_NUM_THREADS == 32
  if (cupbop_multicast_dxa(issue, dst, src, mbar, 0, 0, 0, 0, 0, 0, mask, bytes)) return;
#endif
  if (issue) __cupbop_bulk_multicast(dst, src, bytes, mbar, mask);
}

#if defined(VX_CFG_NUM_THREADS) && VX_CFG_NUM_THREADS == 32
extern "C" void __cupbop_tmem_alloc512(uint32_t *dst) {
  // One full allocation per live CTA. Each slot's logical base is zero.
#ifdef CUPBOP_NATIVE_TMEM
  if (vx_thread_id() == 0) *dst = vx_tmem_alloc512();
#else
  if (vx_thread_id() == 0) *dst = 0;
#endif
}

extern "C" void __cupbop_tmem_free512(uint32_t taddr) {
  if (taddr != 0) cupbop_async_fail("invalid full TMEM allocation base", taddr, 512);
#ifdef CUPBOP_NATIVE_TMEM
  if (vx_thread_id() == 0) vx_tmem_dealloc512(taddr);
#endif
}

#ifdef CUPBOP_NATIVE_TMEM
extern "C" void __cupbop_tmem_alloc512_pair(uint32_t *dst) {
  if (vx_thread_id() == 0) {
    vx_tmem_pair_arrive<true>(tcgen_pair_slot());
    *dst = 0;
  }
}

extern "C" void __cupbop_tmem_free512_pair(uint32_t taddr) {
  if (taddr != 0) cupbop_async_fail("invalid full TMEM pair allocation base", taddr, 512);
  if (vx_thread_id() == 0)
    vx_tmem_pair_arrive<false>(tcgen_pair_slot());
}

extern "C" void __cupbop_tmem_mma_s8_256x256x32(uint32_t taddr, uint64_t desc_a,
                                               uint64_t desc_b, uint32_t use_d) {
  if (taddr > 256) cupbop_async_fail("TMEM accumulator outside allocation", taddr, 256);
  unsigned peer = tcgen_pair_peer();
  unsigned issuer = cluster_rank() & 1;
  TcgenOperand a[2], b[2];
  a[issuer] = tcgen_operand(desc_a);
  b[issuer] = tcgen_operand(desc_b);
  a[1 - issuer] = a[issuer];
  b[1 - issuer] = b[issuer];
  a[1 - issuer].start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(a[issuer].start), peer));
  b[1 - issuer].start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(b[issuer].start), peer));
  tcgen_native_mma(taddr, a, b, issuer, use_d);
}
#endif

extern "C" uint32_t __cupbop_tmem_ld32(uint32_t taddr, uint32_t displacement) {
  const uint32_t first_row = taddr >> 16;
  const uint32_t col = (taddr & 0xffff) + displacement;
  const uint32_t lane_base = (csr_read_nv(VX_CSR_CTA_RANK) & 3) * 32;
#ifdef CUPBOP_NATIVE_TMEM
  if (col >= 512 || (first_row != lane_base &&
                    (first_row != lane_base + 128 || (cluster_rank() & 1) == 0)))
    cupbop_async_fail("TMEM load outside warp datapath", taddr, displacement);
  return vx_tmem_ld32((lane_base << 16) | col);
#else
  if (first_row != lane_base || col >= 512)
    cupbop_async_fail("TMEM load outside warp datapath", taddr, displacement);
  return tcgen_store().word[first_row + vx_thread_id()][col];
#endif
}

extern "C" void __cupbop_tmem_mma_s8_128x256x32(uint32_t taddr, uint64_t desc_a, uint64_t desc_b, uint32_t use_d) {
  if (taddr > 256) cupbop_async_fail("TMEM accumulator outside allocation", taddr, 256);
  const auto a = tcgen_operand(desc_a), b = tcgen_operand(desc_b);
#ifdef CUPBOP_NATIVE_TMEM
  const TcgenOperand a_op[] = {a}, b_op[] = {b};
  tcgen_native_mma(taddr, a_op, b_op, 0, use_d);
#else
  auto &tile = tcgen_store();
  // A signed K=32 dot fits in 21 bits even for (-128)*(-128). Pack three
  // independent columns in radix 2^21. The per-digit bias prevents negative
  // final sums from borrowing from the next result. All packed arithmetic is
  // unsigned modulo 2^64; each of the three biased results fits in 21 bits.
  constexpr unsigned shift = 21, bias = 1 << (shift - 1), mask = (1 << shift) - 1;
  constexpr uint64_t biases = uint64_t(bias) | (uint64_t(bias) << shift) | (uint64_t(bias) << (2 * shift));
  for (unsigned col = 0; col < 256; col += 3) {
    const unsigned count = col == 255 ? 1 : 3;
    uint64_t packed[32] = {};
    for (unsigned j = 0; j < count; ++j)
      for (unsigned half = 0; half < 2; ++half) {
        const int8_t *v = tcgen_chunk(b, col + j, half);
        for (unsigned k = 0; k < 16; ++k)
          packed[half * 16 + k] += uint64_t(v[k]) << (shift * j);
      }
    for (unsigned row = 0; row < 128; ++row) {
      uint64_t sum = biases;
      for (unsigned half = 0; half < 2; ++half) {
        const int8_t *v = tcgen_chunk(a, row, half);
#pragma clang loop unroll_count(4)
        for (unsigned k = 0; k < 16; ++k)
          sum += uint64_t(v[k]) * packed[half * 16 + k];
      }
      for (unsigned j = 0; j < count; ++j) {
        auto &dst = tile.word[row][taddr + col + j];
        const uint32_t dot = (uint32_t(sum >> (shift * j)) & mask) - bias;
        dst = dot + (use_d ? dst : 0u);
      }
    }
  }
#endif
}
#endif
