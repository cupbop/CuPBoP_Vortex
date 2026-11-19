// Full 512-column TCGEN05 allocations and dense signed INT8 MMA.
#if defined(VX_CFG_EXT_TCU_ENABLE) && defined(VX_CFG_TCU_TMEM_ENABLE)
#include <vx_tmem.h>
#define CUPBOP_NATIVE_TMEM
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

extern "C" void __cupbop_tcgen_decline_cancel(uint32_t *response, uint64_t *bar) {
  // KMU runs every CTA in the grid. Declining each optional work-stealing
  // request is valid; SM100's query checks bit 0 of the third response word.
  // A completed unsuccessful request still supplies 16 bytes to mbarrier.
  unsigned k = __cupbop_cluster_register(1,0);
  for (unsigned r = 0; r < k; ++r) {
    auto *p = static_cast<uint32_t *>(__cupbop_cluster_map(response,r));
    for (unsigned i = 0; i < 4; ++i) p[i] = 0;
    __cupbop_tcgen_arrive(static_cast<uint64_t *>(__cupbop_cluster_map(bar,r)), 0, -16);
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
