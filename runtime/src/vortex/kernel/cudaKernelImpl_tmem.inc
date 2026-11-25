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
extern "C" void __cupbop_column_alloc(uint32_t *dst, uint32_t cols) {
  if (cols * cupbop_column_ratio > VX_CFG_TCU_TMEM_COLS) cupbop_async_fail("TMEM allocation exceeds core capacity", cols, VX_CFG_TCU_TMEM_COLS);
  if (vx_thread_id() == 0) *dst = vortex::tmem::alloc(cols * cupbop_column_ratio) / cupbop_column_ratio;
}
extern "C" void __cupbop_column_free(uint32_t col, uint32_t cols) {
  if (vx_thread_id() == 0) vortex::tmem::dealloc(col * cupbop_column_ratio, cols * cupbop_column_ratio);
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
  uint32_t leading, stride, swizzle;
};

static inline TcgenOperand tcgen_operand(uint64_t desc) {
  const unsigned mode = desc >> 61;
  // Relative K-major, base-offset zero; version 1. The archived DGEMM
  // uses 128B swizzling (mode 2). Reject absolute-stride and other layouts.
  if (((desc >> 46) & 0x7fff) != 1 || (mode != 0 && mode != 2))
    cupbop_async_fail("unsupported TCGEN SMEM descriptor", uint32_t(desc >> 32), uint32_t(desc));
  const uintptr_t lmem = csr_read_nv(VX_CSR_CTA_LMEM_ADDR);
  const uintptr_t start = lmem + ((((desc & 0x3fff) << 4) - lmem) & 0x3ffff);
  return {start, uint32_t((desc >> 16) & 0x3fff) * 16, uint32_t((desc >> 32) & 0x3fff) * 16, mode};
}

static inline const int8_t *tcgen_chunk(const TcgenOperand &a, unsigned row, unsigned half) {
  // PTX canonical K-major layout, in 16-byte core vectors. In swizzle
  // mode 2 XOR row bits [2:0] into byte-address bits [6:4].
  uintptr_t offset = (row >> 3) * a.stride;
  if (a.swizzle) return (const int8_t *)((a.start + offset + (row & 7) * 128 + half * 16) ^ ((row & 7) << 4));
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
  if (!vx_thread_id()) {
    if (__cupbop_cluster_register(1,0) != 2 || cols * 4 > VX_CFG_TCU_TMEM_COLS)
      cupbop_async_fail("paired runs exceed resident core capacity", cols, VX_CFG_TCU_TMEM_COLS);
    auto &run = pairRun(cluster_rank() & 1);
    if (run.size) cupbop_async_fail("paired column run already allocated", cols, run.size);
    unsigned base = tmcol::alloc(cols * 2);
    run.base = base / 2;
    run.size = cols;
    vx_fence();
    *dst = columnPairTag;
  }
}
extern "C" void __cupbop_column_pair_free(unsigned addr, unsigned cols) {
  if (!vx_thread_id()) {
    auto &run = pairRun(cluster_rank() & 1);
    if (addr != columnPairTag || run.size != cols)
      cupbop_async_fail("invalid paired run", addr, cols);
    tmcol::dealloc(run.base * 2, cols * 2);
    run.size = 0;
  }
}
// A separate shared slab per issuing warp keeps one producer from
// overwriting another's descriptors before its tc.commit has retired.
template <typename Input, typename Output>
static void column_mma(uint32_t col, uint64_t desc_a, uint64_t desc_b,
                                     uint32_t use_d, uint8_t *scratch, unsigned columns, int side = -1) {
  using ColumnGeometry = tensor::wgmma_config_t<32, Input, Output>;
  unsigned warp = csr_read_nv(VX_CSR_CTA_RANK);
  if (warp >= 4 || (col & 15) || col + columns > VX_CFG_TCU_TMEM_COLS / 2 || vx_num_barriers() < 5)
    cupbop_async_fail("unsupported column MMA destination or issuer", col, warp);
  auto a = tcgen_operand(desc_a);
  auto b = tcgen_operand(desc_b);
  TcgenOperand b_other = b;
  if (side >= 0) {
    a.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(a.start), side));
    b_other.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(b.start), 1));
    b.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(b.start), 0));
  }
  constexpr unsigned rows = 128, kbytes = 32;
  // Only thread zero can issue a column job. The scratch operand is a
  // CTA-shared symbol placed by mem_share2local in the launch allocation.
  if (vx_thread_id() != 0) cupbop_async_fail("column MMA needs lane zero", col, warp);
  scratch += warp * ((rows + 256) * kbytes);
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
}

template <typename Input, typename Output>
static void column_pair_mma(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                         uint8_t *scratch, unsigned n) {
  unsigned offset = addr - columnPairTag;
  for (unsigned side = 0; side < 2; ++side) {
    auto &run = pairRun(side);
    if (offset > run.size || n > run.size - offset || (run.base + offset + n) * 2 > 1024)
      cupbop_async_fail("paired destination outside addressable column run", addr, side);
    column_mma<Input, Output>(run.base + offset, a, b, use_d, scratch, n, side);
  }
}
template <typename Input, typename Output, bool Pair>
static void column_issue(unsigned addr, uint64_t a, uint64_t b, unsigned use_d, uint8_t *scratch, unsigned n) {
  if constexpr (Pair) column_pair_mma<Input, Output>(addr, a, b, use_d, scratch, n);
  else column_mma<Input, Output>(addr, a, b, use_d, scratch, n);
}

template <bool Pair>
static void column_mma_format(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                              uint8_t *scratch, unsigned n, unsigned format) {
  // Low PTX instruction descriptor bits specify A, B and accumulator types.
  switch (format) {
    case 0x10: return column_issue<tensor::fp16, tensor::fp32, Pair>(addr, a, b, use_d, scratch, n);
    case 0x490: return column_issue<tensor::bf16, tensor::fp32, Pair>(addr, a, b, use_d, scratch, n);
    case 0x20: return column_issue<tensor::uint8, tensor::int32, Pair>(addr, a, b, use_d, scratch, n);
    case 0x4a0: return column_issue<tensor::int8, tensor::int32, Pair>(addr, a, b, use_d, scratch, n);
    default: cupbop_async_fail("invalid column MMA format", format, n);
  }
}

extern "C" void __cupbop_column_pair_mma(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                         uint8_t *scratch, unsigned n, unsigned format) {
  column_mma_format<true>(addr, a, b, use_d, scratch, n, format);
}
extern "C" void __cupbop_column_mma(unsigned addr, uint64_t a, uint64_t b, unsigned use_d,
                                    uint8_t *scratch, unsigned n, unsigned format) {
  column_mma_format<false>(addr, a, b, use_d, scratch, n, format);
}

static void column_copy(unsigned col, TcgenOperand src, unsigned cols, uint8_t *scratch) {
  unsigned warp = csr_read_nv(VX_CSR_CTA_RANK);
  if (warp >= 4 || vx_thread_id() || col % 4 || col + cols > VX_CFG_TCU_TMEM_COLS / 2 || vx_num_barriers() < 5)
    cupbop_async_fail("unsupported column copy destination or issuer", col, warp);
  scratch += warp * (128 + 256) * 32;
  constexpr uintptr_t bankRow = VX_CFG_LMEM_NUM_BANKS * (VX_CFG_XLEN / 8);
  scratch = reinterpret_cast<uint8_t *>((uintptr_t(scratch) + bankRow - 1) & ~(bankRow - 1));
  for (unsigned group = 0; group < cols / 4; ++group) {
    for (unsigned half = 0; half < 2; ++half) {
      auto *stage = scratch + (2 * group + half) * 1024;
      for (unsigned row = 0; row < 64; ++row) {
        unsigned logical = (row / 16) * 32 + half * 16 + row % 16;
        __builtin_memcpy(stage + row * 16, tcgen_chunk(src, logical, group), 16);
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
extern "C" void __cupbop_column_pair_cp(unsigned addr, uint64_t descriptor, unsigned cols, uint8_t *scratch) {
  unsigned offset = addr - columnPairTag;
  for (unsigned side = 0; side < 2; ++side) {
    auto &run = pairRun(side);
    if (offset > run.size || cols > run.size - offset)
      cupbop_async_fail("paired copy outside allocation", addr, cols);
    auto src = tcgen_operand(descriptor);
    src.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(src.start), side));
    column_copy(run.base + offset, src, cols, scratch);
  }
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

extern "C" void __cupbop_column_st4(unsigned addr, unsigned a, unsigned b, unsigned c, unsigned d) {
  unsigned col = column_transfer(addr, 0, 4);
  if (col % 4) cupbop_async_fail("unaligned column store", addr, col);
  unsigned lane = vx_thread_id();
  for (unsigned half = 0; half < 2; ++half) {
    unsigned source = lane % 16 + half * 16;
    unsigned x = vx_shfl_idx(a, source, 31, 0), y = vx_shfl_idx(b, source, 31, 0);
    unsigned z = vx_shfl_idx(c, source, 31, 0), w = vx_shfl_idx(d, source, 31, 0);
    register float f0 __asm__("f0") = __builtin_bit_cast(float, lane < 16 ? x : y);
    register float f1 __asm__("f1") = __builtin_bit_cast(float, lane < 16 ? z : w);
    unsigned dest = tmcol::make_taddr(tmcol::warp_lane(), column_panel(col, half) + col % 16);
    __asm__ volatile(".insn r %0, 1, 5, x0, %1, x1" :: "i"(RISCV_CUSTOM0), "r"(dest), "f"(f0), "f"(f1) : "memory");
  }
}
extern "C" void __cupbop_column_wait_st() { tmcol::wait_st(); }

extern "C" uint32_t __cupbop_column_ld32(uint32_t address, uint32_t displacement) {
  unsigned col = column_transfer(address, displacement, 1);
  const unsigned lane = vx_thread_id();
  uint32_t parts[2];
  for (unsigned half = 0; half < 2; ++half) {
    ColumnWords words;
    tmcol::load(words, tmcol::make_taddr(tmcol::warp_lane(), column_panel(col, half)));
    uint32_t bits;
    __builtin_memcpy(&bits, &words.data[(col & 15) / 2], sizeof(bits));
    parts[half] = vx_shfl_idx(bits, (lane % 16) + (col & 1) * 16, 31, 0);
  }
  return parts[lane / 16];
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
extern "C" __attribute__((convergent)) void __cupbop_tma_multicast_warp(
    unsigned issue, void *dst, const void *desc, void *mbar, unsigned rank,
    int c0, int c1, int c2, int c3, int c4, unsigned mask) {
#if defined(VX_CFG_EXT_DXA_ENABLE) && VX_CFG_NUM_THREADS == 32
  if (vx_active_threads() == UINT32_MAX && vx_vote_ballot(issue) == 1 &&
      csr_read_nv(VX_CSR_CTA_RANK) == 0 && vx_num_barriers() > __cupbop_cluster_register(1, 0)) {
    unsigned peers = vx_shfl_idx(mask, 0, 31, 0);
    unsigned slot = UINT32_MAX, bytes = 0;
    bool valid = false;
    if (vx_thread_id() == 0 && (peers & (peers - 1)) &&
        !(peers >> __cupbop_cluster_register(1, 0))) {
      const auto *map = cupbop_tmap_of(desc, rank);
      slot = cupbop_tma_slot(map);
      valid = cupbop_tma_dxa_ok(slot, dst, c0, c1, c2, c3, c4) &&
              (!map->swizzle || !(cluster_context().cluster_stride & 127));
      bytes = map->elem;
      for (unsigned i = 0; i < rank; ++i) bytes *= map->box[i];
    }
    if (vx_vote_ballot(valid) == 1) {
      const unsigned issuer = cluster_rank();
      const unsigned base = ((vx_num_barriers() - 1 - issuer) << 8) | (csr_read_nv(VX_CSR_CTA_ID) - issuer);
      void *first_page = reinterpret_cast<void *>(uintptr_t(dst) - issuer * cluster_context().cluster_stride);
      unsigned phases = 0;
      for (unsigned pending = peers; pending; pending &= pending - 1) {
        unsigned peer = __builtin_ctz(pending);
        vx_barrier_expect_tx(base + peer, 1);
        phases |= unsigned(vx_barrier_arrive(base + peer, 1) & 1) << peer;
      }
      cupbop_tma_dxa_issue_meta((base << 4) | (slot & 15u), first_page, rank, c0, c1, c2, c3, c4, peers);
      for (unsigned pending = peers; pending; pending &= pending - 1) {
        unsigned peer = __builtin_ctz(pending);
        vx_barrier_wait(base + peer, (phases >> peer) & 1);
      }
      if (vx_thread_id() == 0) for (; peers; peers &= peers - 1)
        __cupbop_tcgen_arrive(static_cast<uint64_t *>(__cupbop_cluster_map(mbar, __builtin_ctz(peers))),
                              0, -int32_t(bytes));
      return;
    }
  }
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
