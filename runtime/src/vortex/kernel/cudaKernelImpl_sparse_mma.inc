// NVIDIA warp MMA sparse register fragments on the native Vortex sparse TCU.
#if defined(VX_CFG_NUM_THREADS) && VX_CFG_NUM_THREADS == 32
namespace {

static inline uint32_t sparse_mma_satfinite(uint32_t accumulator, uint32_t addend) {
  const int64_t sum = int64_t(int32_t(accumulator)) + int32_t(addend);
  return uint32_t(sum > INT32_MAX ? INT32_MAX : sum < INT32_MIN ? INT32_MIN : sum);
}

static inline unsigned sparse_mma_tf32_position(uint32_t indices, unsigned pair) {
  // PTX 1:2 metadata encodes the low position as 0x4 and the high as 0xe.
  return ((indices >> (4 * pair)) & 0xf) == 0xe;
}

template <typename Elem, bool Sat>
static inline __attribute__((always_inline)) void sparse_mma_software(
    const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t metadata,
    unsigned selector, uint32_t *d) {
  constexpr unsigned R = Elem::n;
  const unsigned lane = vx_thread_id();
  const unsigned rowOwner = lane & ~3u;
#pragma unroll
  for (unsigned output = 0; output < 4; ++output) {
    const unsigned mHalf = output / 2;
    const unsigned column = 2 * (lane & 3) + output % 2;
    auto sum = [&]() {
      if constexpr (Elem::is_int) return c[output];
      else return __cupbop_bits_f32(c[output]);
    }();
#pragma unroll
    for (unsigned half = 0; half < 2; ++half) {
      decltype(sum) part = 0;
      const unsigned owner = rowOwner + (R <= 2 ? 2 * selector + half : 2 * half + mHalf);
      const uint32_t e = __cupbop_shfl32(metadata, owner) >> (R <= 2 ? 16 * mHalf : 0);
      if constexpr (R == 1) {
#pragma unroll
        for (unsigned g = 0; g < 4; ++g) {
          const unsigned position = sparse_mma_tf32_position(e, g);
          const uint32_t aWord = __cupbop_shfl32(a[2 * half + mHalf], rowOwner + g);
          const uint32_t bWord = __cupbop_shfl32(b[2 * half + g / 2], 4 * column + 2 * (g % 2) + position);
          sum += Elem::get(aWord, 0) * Elem::get(bWord, 0);
        }
      } else {
#pragma unroll
        for (unsigned g = 0; g < 2 * R; ++g) {
          const uint32_t aWord = __cupbop_shfl32(a[2 * half + mHalf], rowOwner + g / (R / 2));
          const unsigned aElement = 2 * (g % (R / 2));
          const unsigned domainGroup = 2 * R * half + g;
          const unsigned bReg = domainGroup / R;
          const unsigned bOwner = 4 * column + (domainGroup % R) * (4 / R);
          const uint32_t bLow = __cupbop_shfl32(b[bReg], bOwner);
          uint32_t bHigh = 0;
          if constexpr (R == 2) bHigh = __cupbop_shfl32(b[bReg], bOwner + 1);
#pragma unroll
          for (unsigned i = 0; i < 2; ++i) {
            const unsigned position = (e >> (4 * g + 2 * i)) & 3;
            const uint32_t bWord = R == 2 && position >= R ? bHigh : bLow;
            const auto product = Elem::get(aWord, aElement + i) * Elem::get(bWord, position % R);
            if constexpr (Sat) part += product;
            else sum += product;
          }
        }
      }
      if constexpr (Sat) sum = sparse_mma_satfinite(sum, part);
    }
    if constexpr (Elem::is_int) d[output] = sum;
    else d[output] = __cupbop_f32_bits(sum);
  }
}

} // namespace

#define CUPBOP_SPARSE_MMA_SW(NAME, TYPE, SAT) \
  extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_sp_##NAME##_sw( \
      const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t metadata, \
      unsigned selector, uint32_t *, uint32_t *d) { \
    sparse_mma_software<__cupbop_el_##TYPE, SAT>(a, b, c, metadata, selector, d); \
  }
CUPBOP_SPARSE_MMA_SW(f16, f16, false)
CUPBOP_SPARSE_MMA_SW(bf16, bf16, false)
CUPBOP_SPARSE_MMA_SW(tf32, tf32, false)
CUPBOP_SPARSE_MMA_SW(s8, s8, false)
CUPBOP_SPARSE_MMA_SW(u8, u8, false)
CUPBOP_SPARSE_MMA_SW(s8_satfinite, s8, true)
CUPBOP_SPARSE_MMA_SW(u8_satfinite, u8, true)
#undef CUPBOP_SPARSE_MMA_SW

#if defined(CUPBOP_MMA_TCU_AVAILABLE) && defined(VX_CFG_TCU_SPARSE_ENABLE)
namespace {

template <int R>
static inline uint32_t sparse_mma_order_pairs(uint32_t values, uint32_t metadata) {
  constexpr unsigned Bits = 32 / R;
  constexpr uint32_t Mask = (uint32_t{1} << Bits) - 1;
  uint32_t ordered = 0;
#pragma unroll
  for (int pair = 0; pair < R / 2; ++pair) {
    const unsigned shift = pair * Bits * 2;
    const uint32_t first = (values >> shift) & Mask;
    const uint32_t second = (values >> (shift + Bits)) & Mask;
    const uint32_t indices = metadata >> (4 * pair);
    // Vortex's mask selects ascending K positions. PTX .sp stores each
    // compressed pair in the order given by its two metadata indices.
    const bool reverse = (indices & 3) > ((indices >> 2) & 3);
    const uint32_t pairWord = reverse ? second | (first << Bits) : first | (second << Bits);
    ordered |= pairWord << shift;
  }
  return ordered;
}

template <int R>
static inline uint32_t sparse_mma_mask(uint32_t indices) {
  uint32_t mask = 0;
#pragma unroll
  for (int g = 0; g < 2 * R; ++g) {
    const uint32_t pair = indices >> (4 * g);
#pragma unroll
    for (int member = 0; member < 2; ++member) {
      const unsigned k = 4 * g + ((pair >> (2 * member)) & 3);
      // Each sparse K-word selects across two dense words, from independent
      // halves of the Vortex metadata row mask.
      const unsigned bit = ((k / (2 * R)) + ((k % (2 * R)) >= R ? 4 : 0)) * R + k % R;
      mask |= uint32_t{1} << bit;
    }
  }
  return mask;
}

template <typename In, typename Out, int R, bool Sat>
static inline __attribute__((always_inline)) void sparse_mma_native(
    const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t e, unsigned selector,
    uint32_t *scratch, uint32_t *d) {
  using Ctx = vt::wmma_context<32, In, Out, true>;
  static_assert(Ctx::tileM == 16 && Ctx::tileN == 16 && Ctx::tileK == 16 * R, "sparse MMA tile");
  static_assert(Ctx::fragment_a::NR == 8 && Ctx::fragment_b::NR == 8 && Ctx::fragment_acc::NR == 8,
                "sparse MMA fragment size");
  typename Ctx::fragment_a fa{};
  typename Ctx::fragment_b fb{};
  typename Ctx::fragment_acc fc, fd;
  const unsigned lane = vx_thread_id();
  const unsigned groupBase = lane & ~3u;
  const unsigned inGroup = lane & 3;
  const unsigned bank = inGroup;
  const unsigned word = lane >> 2;
  const unsigned kHalf = bank & 1;
  const unsigned mHalf = bank >> 1;
  uint32_t meta;

  if constexpr (R == 1) {
    fa.data[0] = __cupbop_bits_f32(a[0] >> 13);
    fa.data[1] = __cupbop_bits_f32(a[2] >> 13);
    fa.data[2] = __cupbop_bits_f32(a[1] >> 13);
    fa.data[3] = __cupbop_bits_f32(a[3] >> 13);

    // Four rows per bank word, with one bit for each of eight dense K
    // positions per row. Vortex stores the two candidates in separate halves.
    const unsigned rowSource = 4 * ((4 * word) & 7) + 2 * selector + kHalf;
    meta = 0;
#pragma unroll
    for (unsigned row = 0; row < 4; ++row) {
      const uint32_t indices = __cupbop_shfl32(e, rowSource + 4 * row) >> (16 * mHalf);
#pragma unroll
      for (unsigned pair = 0; pair < 4; ++pair)
        meta |= 1u << (8 * row + pair + 4 * sparse_mma_tf32_position(indices, pair));
    }
    if (word >= Ctx::sp_meta_cols) meta = 0;
  } else if constexpr (R == 2) {
    const unsigned source = groupBase + 2 * selector;
    const uint32_t eLo = __cupbop_shfl32(e, source) >> (4 * inGroup);
    const uint32_t eHi = __cupbop_shfl32(e, source + 1) >> (4 * inGroup);
    fa.data[0] = __cupbop_bits_f32(sparse_mma_order_pairs<R>(a[0], eLo));
    fa.data[1] = __cupbop_bits_f32(sparse_mma_order_pairs<R>(a[2], eHi));
    fa.data[2] = __cupbop_bits_f32(sparse_mma_order_pairs<R>(a[1], eLo >> 16));
    fa.data[3] = __cupbop_bits_f32(sparse_mma_order_pairs<R>(a[3], eHi >> 16));

    // A word in each metadata bank covers two rows for 16-bit elements.
    const unsigned rowSource = 4 * ((2 * word) & 7) + 2 * selector + kHalf;
    const uint32_t row0 = __cupbop_shfl32(e, rowSource) >> (16 * mHalf);
    const uint32_t row1 = __cupbop_shfl32(e, rowSource + 4) >> (16 * mHalf);
    meta = word < Ctx::sp_meta_cols ? sparse_mma_mask<R>(row0) | (sparse_mma_mask<R>(row1) << 16) : 0;
  } else {
    fa.data[0] = __cupbop_bits_f32(sparse_mma_order_pairs<R>(a[0], __cupbop_shfl32(e, groupBase) >> (8 * inGroup)));
    fa.data[1] = __cupbop_bits_f32(sparse_mma_order_pairs<R>(a[2], __cupbop_shfl32(e, groupBase + 2) >> (8 * inGroup)));
    fa.data[2] = __cupbop_bits_f32(sparse_mma_order_pairs<R>(a[1], __cupbop_shfl32(e, groupBase + 1) >> (8 * inGroup)));
    fa.data[3] = __cupbop_bits_f32(sparse_mma_order_pairs<R>(a[3], __cupbop_shfl32(e, groupBase + 3) >> (8 * inGroup)));

    // An 8-bit metadata row occupies a full word in each bank.
    const uint32_t row = __cupbop_shfl32(e, 4 * word + 2 * kHalf + mHalf);
    meta = sparse_mma_mask<R>(row);
  }

  // Native sparse B uses twice as many lanes per column group as dense B.
  // Gather the two candidate NVIDIA registers before selecting by K half.
#pragma unroll
  for (int reg = 0; reg < 8; ++reg) {
    if (reg % 4 >= 2)
      continue; // The right half of the native 16-column tile is padding.
    const unsigned col = (lane >> 3) + 4 * (reg % 4);
    const unsigned source = 4 * col + inGroup;
    const uint32_t bLo = __cupbop_shfl32(b[2 * (reg / 4)], source);
    const uint32_t bHi = __cupbop_shfl32(b[2 * (reg / 4) + 1], source);
    const uint32_t packed = (lane & 4) ? bHi : bLo;
    fb.data[reg] = __cupbop_bits_f32(R == 1 ? packed >> 13 : packed);
  }
  auto *warpScratch = scratch + 32 * vx_warp_id();
  static_cast<volatile uint32_t *>(warpScratch)[lane] = meta;
  vx_fence();
  vx_wsync();
  if constexpr (Sat) {
    // NVIDIA saturates each K=32 partial going into the INT32 accumulator.
    // Each half-dot fits in INT32. Use a native sparse multiply with a zero
    // accumulator for each half, then clamp each addition in integer code.
    fc = {};
    auto low = fb;
    auto high = fb;
#pragma unroll
    for (unsigned i = 0; i < 4; ++i) {
      low.data[4 + i] = 0.0f;
      high.data[i] = 0.0f;
    }
    Ctx::load_sp_metadata(fa, warpScratch);
    Ctx::mma_sync(fd, fa, low, fc);
    float first[4], second[4];
    __cupbop_acc_vx_to_nv<Ctx>(fd, first);
    Ctx::load_sp_metadata(fa, warpScratch);
    Ctx::mma_sync(fd, fa, high, fc);
    __cupbop_acc_vx_to_nv<Ctx>(fd, second);
#pragma unroll
    for (unsigned i = 0; i < 4; ++i)
      d[i] = sparse_mma_satfinite(sparse_mma_satfinite(c[i], __cupbop_f32_bits(first[i])),
                                  __cupbop_f32_bits(second[i]));
  } else {
    __cupbop_acc_nv_to_vx<Ctx>(__cupbop_bits_f32(c[0]), __cupbop_bits_f32(c[1]),
                               __cupbop_bits_f32(c[2]), __cupbop_bits_f32(c[3]), fc);
    Ctx::load_sp_metadata(fa, warpScratch);
    Ctx::mma_sync(fd, fa, fb, fc);
    float packed[4];
    __cupbop_acc_vx_to_nv<Ctx>(fd, packed);
#pragma unroll
    for (unsigned i = 0; i < 4; ++i)
      d[i] = __cupbop_f32_bits(packed[i]);
  }
  vx_wsync();
}

} // namespace

#define CUPBOP_SPARSE_MMA(NAME, IN, OUT, RATIO, SAT) \
  extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_sp_##NAME##_tcu( \
      const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t metadata, \
      unsigned selector, uint32_t *scratch, uint32_t *d) { \
    sparse_mma_native<vt::IN, vt::OUT, RATIO, SAT>(a, b, c, metadata, selector, scratch, d); \
  }

#if !defined(VX_CFG_TCU_FP16_DISABLE)
CUPBOP_SPARSE_MMA(f16, fp16, fp32, 2, false)
CUPBOP_SPARSE_MMA(bf16, bf16, fp32, 2, false)
#endif
#if defined(VX_CFG_TCU_TF32_ENABLE)
CUPBOP_SPARSE_MMA(tf32, tf32, fp32, 1, false)
#endif
#if defined(VX_CFG_TCU_INT8_ENABLE)
CUPBOP_SPARSE_MMA(s8, int8, int32, 4, false)
CUPBOP_SPARSE_MMA(u8, uint8, int32, 4, false)
CUPBOP_SPARSE_MMA(s8_satfinite, int8, int32, 4, true)
CUPBOP_SPARSE_MMA(u8_satfinite, uint8, int32, 4, true)
#endif
#undef CUPBOP_SPARSE_MMA
#endif
#endif
