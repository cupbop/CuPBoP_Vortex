// A sparse PTX source row has eight compressed 32-bit words. Four lanes
// own those words in each K half, with four registers per lane in RS mode.
#if defined(VX_CFG_NUM_THREADS)
template <int Elements>
static inline uint32_t sparse_wg_indices(uint32_t meta, unsigned selector, int row, int half) {
  if constexpr (Elements == 4)
    return __cupbop_shfl32(meta, 4 * (row & 7) + 2 * half + (row >> 3));
  return __cupbop_shfl32(meta, 4 * (row & 7) + 2 * selector + half) >> (16 * (row >> 3));
}

// Map one element of a compressed word to its position in the two dense
// words. TF32 encodes a 1:2 selection with the nibbles 4 and 14. The other
// types encode one pair of 2-bit indices per group of four input values.
template <int Elements>
static inline unsigned sparse_wg_position(uint32_t indices, int word, int elem) {
  if constexpr (Elements == 1) return (indices >> (4 * word + 3)) & 1;
  const int group = (word * Elements + elem) / 2;
  return (elem / 2) * 4 + ((indices >> (4 * group + 2 * (elem & 1))) & 3);
}

// Hopper IGMMA.SP.SAT clips once after the full K64 dot product.
static inline uint32_t sparse_wg_sat_add(uint32_t dot, uint32_t c) {
  int64_t value = static_cast<int64_t>(static_cast<int32_t>(dot)) + static_cast<int32_t>(c);
  return value > INT32_MAX ? INT32_MAX : value < INT32_MIN ? INT32_MIN : static_cast<int32_t>(value);
}

template <class A, class B>
static inline void sparse_wg_scalar(int n, uint64_t da, uint64_t db, int scale, int warp, uint32_t *acc,
                                     unsigned flags, uint32_t meta, const uint32_t (&regs)[4]) {
  constexpr int elems = A::n;
  using sum_type = typename std::conditional<A::is_int, uint32_t, float>::type;
  const auto a = __cupbop_decode_desc(da), b = __cupbop_decode_desc(db);
  const int lane = vx_thread_id(), quad = lane / 4;
  for (int block = 0; block < n / 8; ++block) {
    for (int s = 0; s < 4; ++s) {
      int row = quad + 8 * (s / 2), col = 8 * block + 2 * (lane % 4) + (s & 1);
      sum_type sum = 0;
      if (scale && !(flags & 128)) __builtin_memcpy(&sum, &acc[4 * block + s], 4);
      for (int half = 0; half < 2; ++half) {
        uint32_t indices = sparse_wg_indices<elems>(meta, (flags >> 2) & 1, row, half);
        for (int i = 0; i < 4; ++i) {
          uint32_t aw = (flags & 32) ? __cupbop_shfl32(regs[2 * half + s / 2], 4 * quad + i)
                                     : __cupbop_wg_half_word(a, 16 * warp + row, 4 * half + i, flags & 1);
          for (int e = 0; e < elems; ++e) {
            int k = (8 * half + 2 * i) * elems + sparse_wg_position<elems>(indices, i, e);
            uint32_t bw = __cupbop_wg_half_word(b, col, k / elems, flags & 2);
            auto av = A::get(aw, e), bv = B::get(bw, k % elems);
            sum += ((flags & 8) ? -av : av) * ((flags & 16) ? -bv : bv);
          }
        }
      }
      if constexpr (A::is_int)
        if ((flags & 128) && scale) sum = sparse_wg_sat_add(sum, acc[4 * block + s]);
      __builtin_memcpy(&acc[4 * block + s], &sum, 4);
    }
  }
}

// Packed .f16 accumulators use one 32-bit register per pair of adjacent
// columns. The caller reserves the full FP32 fragment so expansion in
// descending order cannot overwrite an input pair still needed by this lane.
static inline void sparse_wg_expand_acc(int n, bool scale, unsigned flags, uint32_t *acc) {
  if ((flags & 64) && scale) {
    for (int i = n / 4 - 1; i >= 0; --i) {
      uint32_t word = acc[i];
      acc[2 * i] = __cupbop_f32_bits(__cupbop_f16_to_f32(word));
      acc[2 * i + 1] = __cupbop_f32_bits(__cupbop_f16_to_f32(word >> 16));
    }
  }
}
static inline void sparse_wg_pack_acc(int n, unsigned flags, uint32_t *acc) {
  if (flags & 64)
    for (int i = 0; i < n / 4; ++i)
      acc[i] = __cupbop_pack_f16x2_rne(__cupbop_bits_f32(acc[2 * i]), __cupbop_bits_f32(acc[2 * i + 1]));
}

#define SPARSE_WG_ARGS int n, uint64_t da, uint64_t db, int scale, int warp, uint32_t *acc, unsigned flags, \
                       uint32_t meta, uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3
#define SPARSE_WG_SW(name, A, B) \
extern "C" __attribute__((always_inline, convergent)) void __cupbop_sparse_wgmma_##name##_sw(SPARSE_WG_ARGS) { \
  const uint32_t regs[] = {a0, a1, a2, a3}; \
  sparse_wg_expand_acc(n, scale, flags, acc); \
  sparse_wg_scalar<__cupbop_el_##A, __cupbop_el_##B>(n, da, db, scale, warp, acc, flags, meta, regs); \
  sparse_wg_pack_acc(n, flags, acc); \
}
SPARSE_WG_SW(f16, f16, f16)
SPARSE_WG_SW(bf16, bf16, bf16)
SPARSE_WG_SW(tf32, tf32, tf32)
SPARSE_WG_SW(e4m3, e4m3, e4m3)
SPARSE_WG_SW(e5m2, e5m2, e5m2)
SPARSE_WG_SW(e4m3e5m2, e4m3, e5m2)
SPARSE_WG_SW(e5m2e4m3, e5m2, e4m3)
SPARSE_WG_SW(s8, s8, s8)
SPARSE_WG_SW(u8, u8, u8)
SPARSE_WG_SW(s8u8, s8, u8)
SPARSE_WG_SW(u8s8, u8, s8)
#undef SPARSE_WG_SW

#if defined(VX_CFG_TCU_WGMMA_ENABLE) && defined(VX_CFG_TCU_SPARSE_ENABLE) && defined(VX_CFG_EXT_A_ENABLE) && VX_CFG_NUM_THREADS == 32
// Mixed FP8 inputs share a native FP16 operation after exact widening.
template <int Source, int Native>
static inline uint32_t sparse_wg_slice_indices(uint32_t meta, unsigned selector, int row, int slice) {
  constexpr int slices = Source / Native;
  return sparse_wg_indices<Source>(meta, selector, row, slice / slices) >> ((slice % slices) * 16);
}

// TCU_LD deposits lane l into SRAM[bank=l%banks][word=l/banks]. For each
// compressed word it keeps the selection bits for the first B candidate
// word in the lower half of the row, and the second in the upper half.
template <class WG, int Source, int Elements>
static inline uint32_t sparse_wg_meta_word(uint32_t meta, unsigned selector, int half) {
  using cfg = vt::wmma_config_t<32>;
  constexpr int k_banks = cfg::k_steps / 2, banks = cfg::m_steps * k_banks;
  constexpr int row_bits = WG::wg_meta_row_bits, rows_per_word = 32 / row_bits;
  static_assert(WG::tcM == 8 && WG::tcK == 4 && row_bits == 8 * Elements);
  const int lane = vx_thread_id(), bank = lane % banks, word = lane / banks;
  uint32_t result = 0;
  for (int j = 0; j < rows_per_word; ++j) {
    int row = ((bank / k_banks) * 8 + rows_per_word * word + j) & 15;
    uint32_t indices = sparse_wg_slice_indices<Source, Elements>(meta, selector, row, half);
    for (int i = 0; i < 4; ++i)
      for (int e = 0; e < Elements; ++e) {
        unsigned pos = sparse_wg_position<Elements>(indices, i, e);
        unsigned bit = (pos / Elements) * (4 * Elements) + i * Elements + (pos % Elements);
        result |= 1u << (row_bits * j + bit);
      }
  }
  return bank % k_banks == 0 && word * rows_per_word < 8 ? result : 0;
}

template <int Elements>
static inline uint32_t sparse_wg_sort_word(uint32_t aw, uint32_t indices, int i) {
  if constexpr (Elements > 1) {
    constexpr int bits = 32 / Elements;
    for (int e = 0; e < Elements; e += 2) {
      if (sparse_wg_position<Elements>(indices, i, e) > sparse_wg_position<Elements>(indices, i, e + 1)) {
        uint32_t diff = ((aw >> (bits * e)) ^ (aw >> (bits * (e + 1)))) & ((1u << bits) - 1);
        aw ^= (diff << (bits * e)) | (diff << (bits * (e + 1)));
      }
    }
  }
  return aw;
}

template <class A, class B, class It, class Ot>
static inline void sparse_wg_native(SPARSE_WG_ARGS, uint32_t *scratch, unsigned commit_queue) {
  using WG = vt::wgmma_context<32, It, Ot, true>;
  constexpr int elems = WG::i_ratio, slices = A::n / elems;
  static_assert(slices == 1 || (A::n == 4 && elems == 2));
  // Mixed signedness also widens. Its complete K64 dot fits exactly in
  // FP32. Keep the original S32 accumulator out of the float conversion.
  constexpr bool widened_integer = A::is_int && slices > 1;
  constexpr uint32_t sign = elems == 4 ? 0x80808080u : elems == 2 ? 0x80008000u : 0x80000000u;
  static_assert(WG::xtileM == 16 && WG::xtileN == 16 && WG::tileK == 8 * elems);
  const uint32_t regs[] = {a0, a1, a2, a3};
  const unsigned __UNIFORM__ rank = csr_read_nv(VX_CSR_CTA_RANK);
  scratch += 256 * rank;
  const uintptr_t __UNIFORM__ off = (uintptr_t)scratch - csr_read_nv(VX_CSR_LOCAL_MEM_BASE);
  if (off > 65536 - 1024) {
    sparse_wg_scalar<A, B>(n, da, db, scale, warp, acc, flags, meta, regs);
    if (commit_queue) __cupbop_wgmma_commit_completed_group(commit_queue);
    return;
  }
  const auto a = __cupbop_decode_desc(da), b = __cupbop_decode_desc(db);
  const int lane = vx_thread_id(), g = lane / 4, t = lane % 4;
  const unsigned selector = (flags >> 2) & 1;
  uint32_t *staged_meta = scratch + 64, *staged_b = scratch + 128;
  for (int col = 0; col < n; col += 16) {
    const unsigned width = n - col >= 16 ? 16 : 8;
    typename WG::fragment_acc c;
    for (int r = 0; r < 8; ++r) {
      int column = 4 * (r / 2) + t;
      c.data[r] = 0.f;
      if (scale && !widened_integer && !(flags & 128) && 4 * (r / 2) < width) {
        int idx = 4 * (col / 8 + column / 8) + 2 * (r % 2);
        int src = 4 * g + (column % 8) / 2;
        uint32_t even = __cupbop_shfl32(acc[idx], src), odd = __cupbop_shfl32(acc[idx + 1], src);
        c.data[r] = __cupbop_bits_f32((t & 1) ? odd : even);
      }
    }
    for (int slice = 0; slice < 2 * slices; ++slice) {
      const int half = slice / slices, sub = slice % slices;
      for (int h = 0; h < 2; ++h) {
        int row = g + 8 * h;
        int source_word = (sub * 4 + t) / slices;
        uint32_t aw;
        if (flags & 32) {
          aw = regs[2 * half + h];
          if constexpr (slices > 1) aw = __cupbop_shfl32(aw, 4 * g + source_word);
        } else aw = __cupbop_wg_half_word(a, 16 * warp + row, 4 * half + source_word, flags & 1);
        if constexpr (slices > 1)
          aw = __cupbop_pack_f16x2_rne(A::get(aw, 2 * (t & 1)), A::get(aw, 2 * (t & 1) + 1));
        uint32_t indices = sparse_wg_slice_indices<A::n, elems>(meta, selector, row, slice);
        aw = sparse_wg_sort_word<elems>(aw, indices, t);
        if (flags & 8) aw ^= sign;
        // PTX TF32 occupies the high 19 bits, Vortex consumes the low 19.
        scratch[4 * row + t] = elems == 1 ? aw >> 13 : aw;
      }
      staged_meta[lane] = sparse_wg_meta_word<WG, A::n, elems>(meta, selector, slice);
      for (int i = lane; i < 128; i += 32) {
        int source_word = (8 * slice + i % 8) / slices;
        uint32_t bw = i / 8 < width ? __cupbop_wg_half_word(b, col + i / 8, source_word, flags & 2) : 0;
        if constexpr (slices > 1)
          bw = __cupbop_pack_f16x2_rne(B::get(bw, 2 * (i & 1)), B::get(bw, 2 * (i & 1) + 1));
        if (flags & 16) bw ^= sign;
        staged_b[i] = elems == 1 ? bw >> 13 : bw;
      }
      vx_fence();
      vx_wsync();
      typename WG::fragment_a frag;
      WG::load_sp_metadata(frag, staged_meta);
      const auto native_a = vt::vx_make_smem_desc(scratch, 16);
      const auto native_b = vt::vx_make_smem_desc(staged_b, 32);
      if (commit_queue && col + 16 >= n && slice + 1 == 2 * slices) {
        __cupbop_wgmma_dispatch_queue(commit_queue, [&](auto q) {
          WG::template wgmma_async_commit<decltype(q)::value>(c, native_a, native_b, c);
        });
      } else {
        WG::wgmma_async(c, native_a, native_b, c);
      }
      // All lanes reuse their shared tile in the next K slice. Consume the
      // result first. A lifted scoreboard tag commits at the final issue.
      asm volatile("" : : "f"(c.data[7]) : "memory");
      vx_wsync();
    }
    for (int j = 0; j < width / 8; ++j) {
      for (int s = 0; s < 4; ++s) {
        int column = 8 * j + 2 * t + (s & 1);
        int src = 4 * g + column % 4, reg = 4 * j + s / 2;
        float lo = __cupbop_shflf(c.data[reg], src), hi = __cupbop_shflf(c.data[reg + 2], src);
        int idx = 4 * (col / 8 + j) + s;
        float result = (t >> 1) ? hi : lo;
        uint32_t value = __cupbop_f32_bits(result);
        if constexpr (widened_integer) value = static_cast<int32_t>(result);
        if constexpr (A::is_int) {
          if ((flags & 128) && scale) value = sparse_wg_sat_add(value, acc[idx]);
          else if (widened_integer && scale) value += acc[idx];
        }
        acc[idx] = value;
      }
    }
  }
}
#define SPARSE_WG_NATIVE(type, A, B, It, Ot) \
extern "C" __attribute__((always_inline, convergent)) void __cupbop_sparse_wgmma_##type##_native(SPARSE_WG_ARGS, uint32_t *scratch, unsigned commit_queue) { \
  sparse_wg_expand_acc(n, scale, flags, acc); \
  sparse_wg_native<__cupbop_el_##A, __cupbop_el_##B, vt::It, vt::Ot>(n, da, db, scale, warp, acc, flags, meta, a0, a1, a2, a3, scratch, commit_queue); \
  sparse_wg_pack_acc(n, flags, acc); \
}
SPARSE_WG_NATIVE(f16, f16, f16, fp16, fp32)
SPARSE_WG_NATIVE(e4m3e5m2, e4m3, e5m2, fp16, fp32)
SPARSE_WG_NATIVE(e5m2e4m3, e5m2, e4m3, fp16, fp32)
SPARSE_WG_NATIVE(s8u8, s8, u8, fp16, fp32)
SPARSE_WG_NATIVE(u8s8, u8, s8, fp16, fp32)
SPARSE_WG_NATIVE(bf16, bf16, bf16, bf16, fp32)
#ifdef VX_CFG_TCU_TF32_ENABLE
SPARSE_WG_NATIVE(tf32, tf32, tf32, tf32, fp32)
#endif
#ifdef VX_CFG_TCU_FP8_ENABLE
SPARSE_WG_NATIVE(e4m3, e4m3, e4m3, fp8, fp32)
SPARSE_WG_NATIVE(e5m2, e5m2, e5m2, bf8, fp32)
#endif
#ifdef VX_CFG_TCU_INT8_ENABLE
SPARSE_WG_NATIVE(s8, s8, s8, int8, int32)
SPARSE_WG_NATIVE(u8, u8, u8, uint8, int32)
#endif
#undef SPARSE_WG_NATIVE
#endif
#undef SPARSE_WG_ARGS
#endif // VX_CFG_NUM_THREADS
