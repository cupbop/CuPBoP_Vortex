// ── async family, software mode (translator lower_async_ptx, compilation/KernelTranslation/src/async_ptx.cpp)
// Included by cudaKernelImpl.cpp.
//
// mbarrier: the 8-byte mbarrier word in shared memory holds a record (runtime/include/cupbop_async.h) and
// the barrier itself is Vortex hardware barrier (id << 8) + CTA. A Vortex arrive counts one arrival per
// warp instruction whatever the thread mask, so a warp whose p active threads arrive counts N / p of the
// N expected thread arrivals (every arriving warp of a phase must have the same p: a p that does not
// divide N traps, unequal p that do divide N deadlock, which the launch timeout catches). Phase parity is
// relative to the hardware phase sampled at init. Copies (TMA, bulk) are synchronous: the translator moves
// an arrive that precedes them in the same thread to after them (async design §5.3), so the transaction
// count needs no hardware support.
#ifndef VX_CFG_NUM_BARRIERS
#define VX_CFG_NUM_BARRIERS 8
#endif
#include "cupbop_async.h"

// Stops the simulation (SimX: "invalid CSR read addr=0xc00" -- `unimp` is csrrw x0, cycle, x0). Deliberately
// not __builtin_trap(): the compiler would mark this function noreturn and put `unreachable` after every call,
// and the Vortex back end inserts no split/join for a divergent branch whose post-dominator is unreachable, so
// the warp would never reconverge. To the compiler this function returns.
static __attribute__((noinline)) void cupbop_async_fail(const char *what, uint32_t a, uint32_t b) {
  (void)what; (void)a; (void)b; // (vx_printf from many lanes at once did not come out before the stop)
  __asm__ volatile("unimp" ::: "memory");
}
static __attribute__((always_inline)) inline uint32_t cupbop_mbar_hw(uint32_t rec) {
  return ((rec & 7u) << 8) + (uint32_t)csr_read_nv(VX_CSR_CTA_ID);
}
// current phase bit of a hardware barrier: an expect_tx of 0 events returns it and changes nothing
// (SimX wctl_unit: BAR.ARRIVE with rs2[31] writes back the phase, then attaches rs2[30:0] = 0 events)
static __attribute__((always_inline)) inline uint32_t cupbop_bar_phase(uint32_t hw) {
  uint32_t ph, rs2 = 0x80000000u;
  __asm__ volatile(".insn r %1, 6, 0, %0, %2, %3" : "=r"(ph) : "i"(RISCV_CUSTOM0), "r"(hw), "r"(rs2) : "memory");
  return ph & 1u;
}
static __attribute__((always_inline)) inline uint32_t cupbop_mbar_rec(const void *bar) {
  uint32_t rec = *(volatile const uint32_t *)bar;
  if ((rec >> 24) != CUPBOP_MBAR_MAGIC)
    cupbop_async_fail("mbarrier used before mbarrier.init (no record in its shared-memory word)",
                      (uint32_t)(uintptr_t)bar, rec);
  return rec;
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mbar_init(void *bar, uint32_t count, uint32_t id) {
  if (id == 0 || id >= VX_CFG_NUM_BARRIERS) cupbop_async_fail("mbarrier id out of range", id, count);
  if (count == 0 || count > 0xFFFFFu) cupbop_async_fail("mbarrier count out of range", id, count);
  const uint32_t ph = cupbop_bar_phase((id << 8) + (uint32_t)csr_read_nv(VX_CSR_CTA_ID));
  volatile uint32_t *w = (volatile uint32_t *)bar;
  w[0] = id | (ph << 3) | (count << 4) | (CUPBOP_MBAR_MAGIC << 24);
  w[1] = CUPBOP_MBAR_TAG;
}
// arrive (cnt thread arrivals per active thread); returns the hardware phase before the arrival (the state)
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_mbar_arrive(void *bar, uint32_t cnt) {
  const uint32_t rec = cupbop_mbar_rec(bar);
  const uint32_t n = (rec >> 4) & 0xFFFFFu;
  const uint32_t p = (uint32_t)__builtin_popcount((uint32_t)vx_active_threads()) * cnt;
  if (p == 0 || n % p) cupbop_async_fail("mbarrier arrivals of a warp do not divide the expected count", n, p);
  return (uint32_t)vx_barrier_arrive((int)cupbop_mbar_hw(rec), (int)(n / p)) & 1u;
}
// arrive.expect_tx: the copies completing the transaction already ran (synchronous, before this call)
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_mbar_arrive_tx(void *bar, uint32_t bytes) {
  (void)bytes;
  return __cupbop_mbar_arrive(bar, 1);
}
// try_wait.parity, or a spin on test_wait.parity: block until the phase with this parity has completed
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_mbar_wait_parity(void *bar, uint32_t parity) {
  const uint32_t rec = cupbop_mbar_rec(bar);
  vx_barrier_wait((int)cupbop_mbar_hw(rec), (int)((parity ^ (rec >> 3)) & 1u));
  return 1;
}
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_mbar_test_parity(void *bar, uint32_t parity) {
  const uint32_t rec = cupbop_mbar_rec(bar);
  const uint32_t cur = cupbop_bar_phase(cupbop_mbar_hw(rec)) ^ ((rec >> 3) & 1u); // current CUDA phase parity
  return cur != (parity & 1u) ? 1u : 0u;
}
// try_wait / test_wait with the state an arrive returned (the raw hardware phase of that arrival)
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_mbar_wait_state(void *bar, uint64_t state) {
  const uint32_t rec = cupbop_mbar_rec(bar);
  vx_barrier_wait((int)cupbop_mbar_hw(rec), (int)(state & 1u));
  return 1;
}
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_mbar_test_state(void *bar, uint64_t state) {
  const uint32_t rec = cupbop_mbar_rec(bar);
  return cupbop_bar_phase(cupbop_mbar_hw(rec)) != (uint32_t)(state & 1u) ? 1u : 0u;
}
// elect.sync: the lowest active hardware lane of membermask
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_elect_lane(uint32_t membermask) {
  const uint32_t m = (uint32_t)vx_active_threads() & membermask;
  return m ? (uint32_t)__builtin_ctz(m) : 0xFFFFFFFFu;
}
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_elect_sync(uint32_t membermask) {
  return __cupbop_elect_lane(membermask) == (uint32_t)vx_thread_id() ? 1u : 0u;
}
// clusters of one CTA: a cluster rank other than 0 cannot occur
extern "C" __attribute__((noinline)) void __cupbop_cluster_rank_fail(uint32_t rank) {
  cupbop_async_fail("cluster rank != 0 (clusters of more than one CTA are not supported)", rank, 0);
}

static __attribute__((always_inline)) inline const cupbop_tmap *cupbop_tmap_of(const void *desc, uint32_t rank) {
  const cupbop_tmap *t = *(const cupbop_tmap *const *)desc;
  if (!t || t->magic != CUPBOP_TMAP_MAGIC)
    cupbop_async_fail("tensor map was not made by cuTensorMapEncodeTiled (CuPBoP shim)", (uint32_t)(uintptr_t)desc,
                      t ? t->magic : 0);
  if (t->rank != rank) cupbop_async_fail("tensor map rank differs from the instruction's", t->rank, rank);
  if (t->mode != CUPBOP_TMAP_MODE_SW && t->mode != CUPBOP_TMAP_MODE_DXA)
    cupbop_async_fail("unknown tensor map mode", t->mode, 0);
  return t;
}
// One DXA box transfer (async design stage 3): the operands are gathered from lane 0 into lanes 0-3 of x31 (x30
// for rank > 2) whatever the thread mask (vortex vx_dxa.h), so lane 0 issues; completion releases one event on
// the barrier. Unlike __vx_dxa_issue_* (a CTA-collective call) this is the calling thread's own transfer.
static __attribute__((always_inline)) inline void cupbop_tma_dxa_issue(uint32_t slot, uint32_t bar, void *smem,
                                                                      uint32_t rank, uint32_t c0, uint32_t c1,
                                                                      uint32_t c2, uint32_t c3, uint32_t c4) {
  const uint32_t meta = (bar << 4) | slot;
  const uint32_t a0 = (uint32_t)vx_wgather((size_t)(uintptr_t)smem, (size_t)meta, (size_t)c0, (size_t)c1);
  if (rank <= 2) {
    register uint32_t rs1 __asm__("x31") = a0;
    __asm__ volatile(".insn r %0, 0, %1, x0, %2, x0\n\t" : : "i"(RISCV_CUSTOM0), "i"(0x3), "r"(rs1) : "memory");
  } else {
    const uint32_t a1 = (uint32_t)__VX_WGATHER_IN("x30", 0, (size_t)c2, (size_t)c3, (size_t)c4, (size_t)0u);
    register uint32_t rs1 __asm__("x31") = a0;
    register uint32_t rs2 __asm__("x30") = a1;
    __asm__ volatile(".insn r %0, 0, %1, x0, %2, %3\n\t" : : "i"(RISCV_CUSTOM0), "i"(0x3), "r"(rs1), "r"(rs2)
                     : "memory");
  }
}
static __attribute__((always_inline)) inline void cupbop_copy_elem(void *d, const void *s, uint32_t e) {
  switch (e) {
  case 1: *(uint8_t *)d = *(const uint8_t *)s; break;
  case 2: *(uint16_t *)d = *(const uint16_t *)s; break;
  case 4: *(uint32_t *)d = *(const uint32_t *)s; break;
  default: *(uint64_t *)d = *(const uint64_t *)s; break;
  }
}
static __attribute__((always_inline)) inline void cupbop_fill_elem(void *d, uint32_t e, uint32_t nan) {
  switch (e) {
  case 1: *(uint8_t *)d = 0; break;
  case 2: *(uint16_t *)d = nan ? 0x7FFFu : 0; break;
  case 4: *(uint32_t *)d = nan ? 0x7FFFFFFFu : 0; break;
  default: *(uint64_t *)d = nan ? 0x7FFFFFFFFFFFFFFFull : 0; break;
  }
}
// One box of the tensor <-> a dense box in shared memory (innermost dimension first, no swizzle). Load: out-of-
// bounds elements are filled (0, or NaN); store: out-of-bounds elements are not written.
static __attribute__((noinline)) void cupbop_tma_box(void *smem, const void *desc, uint32_t rank, int32_t c0,
                                                    int32_t c1, int32_t c2, int32_t c3, int32_t c4, int store) {
  const cupbop_tmap *t = cupbop_tmap_of(desc, rank);
  const int32_t c[5] = {c0, c1, c2, c3, c4};
  uint32_t b[5], dm[5];
  for (int i = 0; i < 5; ++i) {
    b[i] = i < (int)rank ? t->box[i] : 1u;
    dm[i] = i < (int)rank ? t->dim[i] : 1u;
  }
  const uint32_t e = t->elem;
  char *s = (char *)smem;
  for (uint32_t j4 = 0; j4 < b[4]; ++j4)
    for (uint32_t j3 = 0; j3 < b[3]; ++j3)
      for (uint32_t j2 = 0; j2 < b[2]; ++j2)
        for (uint32_t j1 = 0; j1 < b[1]; ++j1) {
          const int64_t g1 = (int64_t)c[1] + j1, g2 = (int64_t)c[2] + j2, g3 = (int64_t)c[3] + j3,
                        g4 = (int64_t)c[4] + j4;
          const bool row_in = g1 >= 0 && g1 < (int64_t)dm[1] && g2 >= 0 && g2 < (int64_t)dm[2] && g3 >= 0 &&
                              g3 < (int64_t)dm[3] && g4 >= 0 && g4 < (int64_t)dm[4];
          const char *row = (const char *)(uintptr_t)t->gaddr;
          if (row_in) {
            if (rank > 1) row += (uint64_t)g1 * t->stride[0];
            if (rank > 2) row += (uint64_t)g2 * t->stride[1];
            if (rank > 3) row += (uint64_t)g3 * t->stride[2];
            if (rank > 4) row += (uint64_t)g4 * t->stride[3];
          }
          for (uint32_t j0 = 0; j0 < b[0]; ++j0, s += e) {
            const int64_t g0 = (int64_t)c[0] + j0;
            const bool in = row_in && g0 >= 0 && g0 < (int64_t)dm[0];
            if (store) {
              if (in) cupbop_copy_elem((void *)(row + (uint64_t)g0 * e), s, e);
            } else if (in) {
              cupbop_copy_elem(s, row + (uint64_t)g0 * e, e);
            } else {
              cupbop_fill_elem(s, e, t->oob_nan);
            }
          }
        }
}
// cp.async.bulk.tensor.<rank>d global -> shared: one copy by each calling thread (the elected one). DXA mode
// (the host gave the tensor map a DXA slot at launch): an asynchronous DXA transfer completing on the mbarrier's
// hardware barrier, when the caller is lane 0 and no coordinate is negative (the DXA takes unsigned coordinates);
// otherwise, and in software mode, a synchronous copy.
extern "C" __attribute__((always_inline, convergent)) void __cupbop_tma_load(void *smem, const void *desc,
                                                                           void *mbar, uint32_t rank, int32_t c0,
                                                                           int32_t c1, int32_t c2, int32_t c3,
                                                                           int32_t c4) {
#if defined(VX_CFG_EXT_DXA_ENABLE) || defined(VX_CFG_EXT_DXA_ENABLED)
  const cupbop_tmap *t = cupbop_tmap_of(desc, rank);
  if (t->mode == CUPBOP_TMAP_MODE_DXA && t->dxa_slot < 16 && vx_thread_id() == 0 && (c0 | c1 | c2 | c3 | c4) >= 0) {
    const uint32_t hw = cupbop_mbar_hw(cupbop_mbar_rec(mbar));
    vx_barrier_expect_tx((int)hw, 1);
    cupbop_tma_dxa_issue(t->dxa_slot, hw, smem, rank, (uint32_t)c0, (uint32_t)c1, (uint32_t)c2, (uint32_t)c3,
                         (uint32_t)c4);
    return;
  }
#endif
  (void)mbar;
  cupbop_tma_box(smem, desc, rank, c0, c1, c2, c3, c4, 0);
}
// The DXA releases its event on the barrier when its last shared-memory write is sent, and those writes take
// the LMEM port first, so a transfer can complete before the issuing thread's following arrive (which reads the
// mbarrier record from shared memory): with no arrival yet the release flips the phase, the arrive flips it
// back, and the waiters hang. A copy the translator knows is followed by a moved arrive (async design §5.3)
// therefore only registers its event here and queues the issue; that arrive arrives first and then issues the
// queue (__cupbop_mbar_arrive*_q): every expect_tx, then the arrival, then the transfers. The queue is a
// per-thread stack object the translator allocates; a full queue falls back to the synchronous copy.
#define CUPBOP_TXQ_N 4
typedef struct cupbop_txq {
  uint32_t n, pad;
  struct { void *smem; uint32_t slot, bar, rank; int32_t c[5]; } e[CUPBOP_TXQ_N];
} cupbop_txq;
extern "C" __attribute__((always_inline, convergent)) void __cupbop_tma_load_q(void *q_, void *smem, const void *desc,
                                                                             void *mbar, uint32_t rank, int32_t c0,
                                                                             int32_t c1, int32_t c2, int32_t c3,
                                                                             int32_t c4) {
#if defined(VX_CFG_EXT_DXA_ENABLE) || defined(VX_CFG_EXT_DXA_ENABLED)
  cupbop_txq *q = (cupbop_txq *)q_;
  const cupbop_tmap *t = cupbop_tmap_of(desc, rank);
  if (t->mode == CUPBOP_TMAP_MODE_DXA && t->dxa_slot < 16 && vx_thread_id() == 0 && (c0 | c1 | c2 | c3 | c4) >= 0 &&
      q->n < CUPBOP_TXQ_N) {
    const uint32_t hw = cupbop_mbar_hw(cupbop_mbar_rec(mbar));
    vx_barrier_expect_tx((int)hw, 1);
    const uint32_t k = q->n;
    q->e[k].smem = smem; q->e[k].slot = t->dxa_slot; q->e[k].bar = hw; q->e[k].rank = rank;
    q->e[k].c[0] = c0; q->e[k].c[1] = c1; q->e[k].c[2] = c2; q->e[k].c[3] = c3; q->e[k].c[4] = c4;
    q->n = k + 1;
    return;
  }
#endif
  (void)q_; (void)mbar;
  cupbop_tma_box(smem, desc, rank, c0, c1, c2, c3, c4, 0);
}
static __attribute__((always_inline)) inline void cupbop_txq_flush(void *q_) {
#if defined(VX_CFG_EXT_DXA_ENABLE) || defined(VX_CFG_EXT_DXA_ENABLED)
  cupbop_txq *q = (cupbop_txq *)q_;
  for (uint32_t k = 0; k < q->n; ++k)
    cupbop_tma_dxa_issue(q->e[k].slot, q->e[k].bar, q->e[k].smem, q->e[k].rank, (uint32_t)q->e[k].c[0],
                         (uint32_t)q->e[k].c[1], (uint32_t)q->e[k].c[2], (uint32_t)q->e[k].c[3], (uint32_t)q->e[k].c[4]);
  q->n = 0;
#else
  (void)q_;
#endif
}
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_mbar_arrive_q(void *q, void *bar, uint32_t cnt) {
  const uint32_t r = __cupbop_mbar_arrive(bar, cnt);
  cupbop_txq_flush(q);
  return r;
}
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_mbar_arrive_tx_q(void *q, void *bar,
                                                                                        uint32_t bytes) {
  const uint32_t r = __cupbop_mbar_arrive_tx(bar, bytes);
  cupbop_txq_flush(q);
  return r;
}
// cp.async.bulk.tensor.<rank>d shared -> global
extern "C" __attribute__((always_inline)) void __cupbop_tma_store(const void *desc, void *smem, uint32_t rank,
                                                                int32_t c0, int32_t c1, int32_t c2, int32_t c3,
                                                                int32_t c4) {
  cupbop_tma_box(smem, desc, rank, c0, c1, c2, c3, c4, 1);
}
// cp.async.bulk (non-tensor, any direction): size a multiple of 16, both addresses 16-byte aligned
extern "C" __attribute__((noinline)) void __cupbop_bulk_copy(void *dst, const void *src, uint32_t bytes) {
  if ((bytes & 15u) || (((uintptr_t)dst | (uintptr_t)src) & 15u))
    cupbop_async_fail("cp.async.bulk needs 16-byte aligned addresses and a multiple of 16 bytes",
                      (uint32_t)(uintptr_t)dst, bytes);
  uint64_t *d = (uint64_t *)dst;
  const uint64_t *s = (const uint64_t *)src;
  for (uint32_t i = 0; i < bytes / 8; ++i) d[i] = s[i];
}
