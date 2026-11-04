// cudaKernelImpl_dtypes.inc -- included at the end of cudaKernelImpl.cpp (Vortex 3.0 trees only).
//
// Tensor-core data types beyond f16 (and the original bf16 mma.sync): CUDA wmma and PTX mma.sync for
//   bf16 -> f32       wmma m16n16k16
//   tf32 -> f32       wmma m16n16k8,  mma.sync m16n8k8 / m16n8k4
//   s8/u8 -> s32      wmma m16n16k16, mma.sync m16n8k16 / m16n8k32 (+ .satfinite, mixed s8.u8 / u8.s8)
//   e4m3/e5m2 -> f32  mma.sync m16n8k32 (+ mixed e4m3.e5m2 / e5m2.e4m3)
// plus a software wmma for f16. Every operation has three symbols, as the mma.sync f16/bf16 helpers:
//   <name>_sw   software reference (fp32 / int32 arithmetic over hardware index shuffles), any 3.0 build, NT=32
//   <name>_tcu  Vortex TCU, defined only when the kernel is built for a TCU build that enables the type
//               (VX_CFG_EXT_TCU_ENABLE and VX_CFG_TCU_{FP16 (bf16), TF32, INT8, FP8}_ENABLE), NT=32
//   <name>      dispatch: _tcu when defined, else _sw (CUPBOP_MMA_LOWERING=auto). Never picks the TCU for a
//               type the build does not enable, or for an operation the TCU cannot do exactly (satfinite,
//               mixed signedness / fp8 formats): those dispatch symbols do not exist, the translator emits _sw.
// kernelTranslator picks the suffix from CUPBOP_MMA_LOWERING=auto|sw|tcu (replace_nvvm_mma_intrinsics,
// replace_nvvm_wmma_intrinsics, inline-asm mma.sync in replace_asm_call).
//
// Numerics (both lowerings; the TCU follows SimX tcu_unit.cpp FEDP):
//   bf16/f16/e4m3/e5m2 products are exact in fp32; tf32 products too (11+11 significand bits). Only the
//   order of the fp32 sums differs between _sw (k-ordered, starting from C) and the TCU (per 32-bit word,
//   then per 4-word block, C added per block), so sw/tcu agree bit for bit whenever the partial sums are
//   exact and to a few fp32 ulps of sum|a*b| otherwise.
//   tf32: NVIDIA tensor cores use the top 19 bits of each fp32 operand (the low 13 mantissa bits are
//   ignored = truncation; cvt.rna.tf32.f32 / __float_to_tf32 rounds beforehand). _sw masks the low 13
//   bits; _tcu shifts them out into the Vortex 19-bit tf32 encoding (sign at bit 18), the same value.
//   int: products exact; the sum wraps modulo 2^32 like the TCU's int32 accumulator. .satfinite (exact
//   sum clamped to int32) is software only (int64 sum); the TCU would wrap.
//   e4m3 = OCP E4M3FN (no infinities, S.1111.111 = NaN), e5m2 = IEEE-style; NVIDIA and Vortex agree.
#if defined(VX_CFG_NUM_THREADS)

// ---- element decoders ------------------------------------------------------------------------------
static inline float __cupbop_bits_f32(uint32_t u) { float f; __builtin_memcpy(&f, &u, 4); return f; }
static inline uint32_t __cupbop_f32_bits(float f) { uint32_t u; __builtin_memcpy(&u, &f, 4); return u; }
// Branch-free on purpose (see __cupbop_f16_to_f32: data-dependent loops were miscompiled under LTO).
static inline float __cupbop_e4m3_to_f32(uint32_t b) {
  b &= 0xffu;
  const uint32_t sign = (b & 0x80u) << 24, e = (b >> 3) & 0xfu, m = b & 7u;
  const uint32_t normal = ((e + 120u) << 23) | (m << 20);
  float f = (e == 0u) ? (float)m * 0x1p-9f : __cupbop_bits_f32(normal); // subnormal m/8 * 2^-6
  uint32_t bits = __cupbop_f32_bits(f) | sign;
  bits = (e == 15u && m == 7u) ? 0x7fc00000u : bits; // the only NaN encoding, no infinities
  return __cupbop_bits_f32(bits);
}
static inline float __cupbop_e5m2_to_f32(uint32_t b) {
  b &= 0xffu;
  const uint32_t sign = (b & 0x80u) << 24, e = (b >> 2) & 0x1fu, m = b & 3u;
  const uint32_t normal = ((e + 112u) << 23) | (m << 21);
  const uint32_t infnan = 0x7f800000u | (m << 21);
  float f = (e == 0u) ? (float)m * 0x1p-16f : __cupbop_bits_f32(e == 31u ? infnan : normal); // subnormal m/4 * 2^-14
  return __cupbop_bits_f32(__cupbop_f32_bits(f) | sign);
}
struct __cupbop_el_f16  { static constexpr int n = 2; static constexpr bool is_int = false; static float get(uint32_t w, int i) { return __cupbop_f16_to_f32(w >> (16 * i)); } };
struct __cupbop_el_bf16 { static constexpr int n = 2; static constexpr bool is_int = false; static float get(uint32_t w, int i) { return __cupbop_bf16_to_f32(w >> (16 * i)); } };
struct __cupbop_el_tf32 { static constexpr int n = 1; static constexpr bool is_int = false; static float get(uint32_t w, int) { return __cupbop_bits_f32(w & 0xffffe000u); } };
struct __cupbop_el_e4m3 { static constexpr int n = 4; static constexpr bool is_int = false; static float get(uint32_t w, int i) { return __cupbop_e4m3_to_f32(w >> (8 * i)); } };
struct __cupbop_el_e5m2 { static constexpr int n = 4; static constexpr bool is_int = false; static float get(uint32_t w, int i) { return __cupbop_e5m2_to_f32(w >> (8 * i)); } };
struct __cupbop_el_s8   { static constexpr int n = 4; static constexpr bool is_int = true;  static int32_t get(uint32_t w, int i) { return (int32_t)(int8_t)(uint8_t)(w >> (8 * i)); } };
struct __cupbop_el_u8   { static constexpr int n = 4; static constexpr bool is_int = true;  static int32_t get(uint32_t w, int i) { return (int32_t)((w >> (8 * i)) & 0xffu); } };

// cvt.rna.tf32.f32 / __nvvm_f2tf32_rna / wmma::__float_to_tf32: round to the top 19 bits, ties away from
// zero, result in fp32 layout (low 13 bits zero); NaN -> canonical NaN, infinities kept, overflow -> inf.
extern "C" __attribute__((always_inline)) uint32_t __cupbop_cvt_rna_tf32(uint32_t x) {
  const bool special = (x & 0x7f800000u) == 0x7f800000u;
  const uint32_t r = (x + 0x1000u) & 0xffffe000u;
  const uint32_t s = (x & 0x007fffffu) ? 0x7fffffffu : x;
  return special ? s : r;
}

// ---- mma.sync m16n8kK, software reference ------------------------------------------------------------
// PTX fragments, lane l, g = l>>2, t = l&3. A row-major 16xK, B column-major Kx8, packed in 32-bit words
// of n = 4/sizeof(element) consecutive k. KW = words of K per row (8: m16n8k16 f16/bf16, k8 tf32, k32
// int8/fp8, A a0..a3 / B b0,b1; 4: the half shapes, A a0,a1 / B b0). Word w of row g sits in lane
// (g<<2)|(w&3), register a0/a1 (w<4) or a2/a3 (w>=4) for rows g/g+8; word w of column n in lane
// (n<<2)|(w&3), b0 (w<4) or b1. C/D: c0=(g,2t) c1=(g,2t+1) c2=(g+8,2t) c3=(g+8,2t+1).
template <class EA, class EB, int KW, bool SAT>
static inline void __cupbop_mma16n8_sw(const uint32_t *A, const uint32_t *B, const uint32_t *C, uint32_t *D) {
  static_assert(EA::is_int == EB::is_int && EA::n == EB::n, "mixed int/float operands");
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const int la = g << 2, lb0 = (2 * t) << 2, lb1 = (2 * t + 1) << 2;
  if constexpr (EA::is_int) {
    int64_t s0 = (int32_t)C[0], s1 = (int32_t)C[1], s2 = (int32_t)C[2], s3 = (int32_t)C[3]; // SAT: exact sum
    uint32_t u0 = C[0], u1 = C[1], u2 = C[2], u3 = C[3];                                      // else: wraps
    for (int kk = 0; kk < KW; ++kk) {
      const int q = kk & 3;
      const uint32_t xa = __cupbop_shfl32(kk < 4 ? A[0] : A[2], la | q);
      const uint32_t ya = __cupbop_shfl32(kk < 4 ? A[1] : A[3], la | q);
      const uint32_t ub = __cupbop_shfl32(kk < 4 ? B[0] : B[1], lb0 | q);
      const uint32_t vb = __cupbop_shfl32(kk < 4 ? B[0] : B[1], lb1 | q);
      for (int i = 0; i < EA::n; ++i) {
        const int32_t ag = EA::get(xa, i), ag8 = EA::get(ya, i), b0 = EB::get(ub, i), b1 = EB::get(vb, i);
        if constexpr (SAT) { s0 += ag * b0; s1 += ag * b1; s2 += ag8 * b0; s3 += ag8 * b1; }
        else { u0 += (uint32_t)(ag * b0); u1 += (uint32_t)(ag * b1); u2 += (uint32_t)(ag8 * b0); u3 += (uint32_t)(ag8 * b1); }
      }
    }
    if constexpr (SAT) {
      auto sat = [](int64_t v) -> uint32_t { return (uint32_t)(int32_t)(v > 2147483647LL ? 2147483647LL : (v < -2147483648LL ? -2147483648LL : v)); };
      D[0] = sat(s0); D[1] = sat(s1); D[2] = sat(s2); D[3] = sat(s3);
    } else {
      D[0] = u0; D[1] = u1; D[2] = u2; D[3] = u3;
    }
  } else {
    float d0 = __cupbop_bits_f32(C[0]), d1 = __cupbop_bits_f32(C[1]), d2 = __cupbop_bits_f32(C[2]), d3 = __cupbop_bits_f32(C[3]);
    for (int kk = 0; kk < KW; ++kk) {
      const int q = kk & 3;
      const uint32_t xa = __cupbop_shfl32(kk < 4 ? A[0] : A[2], la | q);
      const uint32_t ya = __cupbop_shfl32(kk < 4 ? A[1] : A[3], la | q);
      const uint32_t ub = __cupbop_shfl32(kk < 4 ? B[0] : B[1], lb0 | q);
      const uint32_t vb = __cupbop_shfl32(kk < 4 ? B[0] : B[1], lb1 | q);
      for (int i = 0; i < EA::n; ++i) {
        const float ag = EA::get(xa, i), ag8 = EA::get(ya, i), b0 = EB::get(ub, i), b1 = EB::get(vb, i);
        d0 += ag * b0; d1 += ag * b1; d2 += ag8 * b0; d3 += ag8 * b1;
      }
    }
    D[0] = __cupbop_f32_bits(d0); D[1] = __cupbop_f32_bits(d1); D[2] = __cupbop_f32_bits(d2); D[3] = __cupbop_f32_bits(d3);
  }
}

// ---- mma.sync m16n8kK on the TCU (NT=32 m16n16 tile, k = 16 words) --------------------------------
// Same register correspondence as __cupbop_mma_m16n8k16_tcu_impl for every element width: Vortex A reg
// r = (row g + 8(r>>2), word 4(r&3)+t), B reg r = (word 4(r>>1)+t, col g + 8(r&1)), so the PTX words map
// register for register (full: fa = {a0,a2,0,0,a1,a3,0,0}, fb = {b0,0,b1,0,...}; half: fa = {a0,..,a1,..},
// fb = {b0,...}); the zero words contribute nothing. tf32 operands move to the 19-bit Vortex encoding.
#if defined(CUPBOP_MMA_TCU_AVAILABLE)
template <class CTX, int KW, bool TF32>
static inline void __cupbop_mma16n8_tcu(const uint32_t *A, const uint32_t *B, const uint32_t *C, uint32_t *D) {
  auto in = [](uint32_t w) { return __cupbop_bits_f32(TF32 ? (w >> 13) : w); };
  typename CTX::fragment_a fa; typename CTX::fragment_b fb; typename CTX::fragment_acc fc, fd;
  if constexpr (KW == 8) {
    fa.data = {{in(A[0]), in(A[2]), 0.f, 0.f, in(A[1]), in(A[3]), 0.f, 0.f}};
    fb.data = {{in(B[0]), 0.f, in(B[1]), 0.f, 0.f, 0.f, 0.f, 0.f}};
  } else {
    fa.data = {{in(A[0]), 0.f, 0.f, 0.f, in(A[1]), 0.f, 0.f, 0.f}};
    fb.data = {{in(B[0]), 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f}};
  }
  __cupbop_acc_nv_to_vx<CTX>(__cupbop_bits_f32(C[0]), __cupbop_bits_f32(C[1]), __cupbop_bits_f32(C[2]), __cupbop_bits_f32(C[3]), fc);
  CTX::mma_sync(fd, fa, fb, fc);
  float d[4];
  __cupbop_acc_vx_to_nv<CTX>(fd, d);
  for (int i = 0; i < 4; ++i) D[i] = __cupbop_f32_bits(d[i]);
}
namespace {
using tcu_ctx_tf32 = vt::wmma_context<VX_CFG_NUM_THREADS, vt::tf32, vt::fp32>;
using tcu_ctx_s8   = vt::wmma_context<VX_CFG_NUM_THREADS, vt::int8, vt::int32>;
using tcu_ctx_u8   = vt::wmma_context<VX_CFG_NUM_THREADS, vt::uint8, vt::int32>;
using tcu_ctx_e4m3 = vt::wmma_context<VX_CFG_NUM_THREADS, vt::fp8, vt::fp32>;
using tcu_ctx_e5m2 = vt::wmma_context<VX_CFG_NUM_THREADS, vt::bf8, vt::fp32>;
} // namespace
#if !defined(VX_CFG_TCU_FP16_DISABLE)
#define CUPBOP_TCU_BF16 1
#endif
#if defined(VX_CFG_TCU_TF32_ENABLE)
#define CUPBOP_TCU_TF32 1
#endif
#if defined(VX_CFG_TCU_INT8_ENABLE)
#define CUPBOP_TCU_INT8 1
#endif
#if defined(VX_CFG_TCU_FP8_ENABLE)
#define CUPBOP_TCU_FP8 1
#endif
#endif // CUPBOP_MMA_TCU_AVAILABLE

// Symbol generators. Full shapes: (a0..a3, b0, b1, c0..c3, d*); half shapes: (a0, a1, b0, c0..c3, d*).
// Accumulators are passed as their bit pattern type (float for f32, int32 for s32).
#define CUPBOP_MMA_ARGS_FULL(ACC) uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t b0, uint32_t b1, ACC c0, ACC c1, ACC c2, ACC c3, ACC *d
#define CUPBOP_MMA_ARGS_HALF(ACC) uint32_t a0, uint32_t a1, uint32_t b0, ACC c0, ACC c1, ACC c2, ACC c3, ACC *d
#define CUPBOP_MMA_PACK_FULL const uint32_t A[4] = {a0, a1, a2, a3}, B[2] = {b0, b1}
#define CUPBOP_MMA_PACK_HALF const uint32_t A[4] = {a0, a1, 0u, 0u}, B[2] = {b0, 0u}
#define CUPBOP_MMA_PACK_C(ACC) uint32_t C[4]; { ACC cc[4] = {c0, c1, c2, c3}; __builtin_memcpy(C, cc, 16); } uint32_t D[4]
#define CUPBOP_GEN_MMA_SW(NAME, KIND, ACC, EA, EB, KW, SAT)                                                       \
  extern "C" __attribute__((always_inline, convergent)) void NAME##_sw(CUPBOP_MMA_ARGS_##KIND(ACC)) {         \
    CUPBOP_MMA_PACK_##KIND; CUPBOP_MMA_PACK_C(ACC);                                                          \
    __cupbop_mma16n8_sw<EA, EB, KW, SAT>(A, B, C, D); __builtin_memcpy(d, D, 16);                           \
  }
#define CUPBOP_GEN_MMA_TCU(NAME, KIND, ACC, CTX, KW, TF32)                                                        \
  extern "C" __attribute__((always_inline, convergent)) void NAME##_tcu(CUPBOP_MMA_ARGS_##KIND(ACC)) {        \
    CUPBOP_MMA_PACK_##KIND; CUPBOP_MMA_PACK_C(ACC);                                                          \
    __cupbop_mma16n8_tcu<CTX, KW, TF32>(A, B, C, D); __builtin_memcpy(d, D, 16);                            \
  }

// tf32 -> f32
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k8_tf32f32, FULL, float, __cupbop_el_tf32, __cupbop_el_tf32, 8, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k4_tf32f32, HALF, float, __cupbop_el_tf32, __cupbop_el_tf32, 4, false)
// s8/u8 -> s32 (plain, satfinite, mixed signedness)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_s8s32,      FULL, int32_t, __cupbop_el_s8, __cupbop_el_s8, 8, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_u8s32,      FULL, int32_t, __cupbop_el_u8, __cupbop_el_u8, 8, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_s8u8s32,    FULL, int32_t, __cupbop_el_s8, __cupbop_el_u8, 8, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_u8s8s32,    FULL, int32_t, __cupbop_el_u8, __cupbop_el_s8, 8, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_s8s32sat,   FULL, int32_t, __cupbop_el_s8, __cupbop_el_s8, 8, true)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_u8s32sat,   FULL, int32_t, __cupbop_el_u8, __cupbop_el_u8, 8, true)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_s8u8s32sat, FULL, int32_t, __cupbop_el_s8, __cupbop_el_u8, 8, true)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_u8s8s32sat, FULL, int32_t, __cupbop_el_u8, __cupbop_el_s8, 8, true)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k16_s8s32,      HALF, int32_t, __cupbop_el_s8, __cupbop_el_s8, 4, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k16_u8s32,      HALF, int32_t, __cupbop_el_u8, __cupbop_el_u8, 4, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k16_s8u8s32,    HALF, int32_t, __cupbop_el_s8, __cupbop_el_u8, 4, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k16_u8s8s32,    HALF, int32_t, __cupbop_el_u8, __cupbop_el_s8, 4, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k16_s8s32sat,   HALF, int32_t, __cupbop_el_s8, __cupbop_el_s8, 4, true)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k16_u8s32sat,   HALF, int32_t, __cupbop_el_u8, __cupbop_el_u8, 4, true)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k16_s8u8s32sat, HALF, int32_t, __cupbop_el_s8, __cupbop_el_u8, 4, true)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k16_u8s8s32sat, HALF, int32_t, __cupbop_el_u8, __cupbop_el_s8, 4, true)
// e4m3/e5m2 -> f32
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_e4m3f32,     FULL, float, __cupbop_el_e4m3, __cupbop_el_e4m3, 8, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_e5m2f32,     FULL, float, __cupbop_el_e5m2, __cupbop_el_e5m2, 8, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_e4m3e5m2f32, FULL, float, __cupbop_el_e4m3, __cupbop_el_e5m2, 8, false)
CUPBOP_GEN_MMA_SW(__cupbop_mma_m16n8k32_e5m2e4m3f32, FULL, float, __cupbop_el_e5m2, __cupbop_el_e4m3, 8, false)

#if defined(CUPBOP_TCU_TF32)
CUPBOP_GEN_MMA_TCU(__cupbop_mma_m16n8k8_tf32f32, FULL, float, tcu_ctx_tf32, 8, true)
CUPBOP_GEN_MMA_TCU(__cupbop_mma_m16n8k4_tf32f32, HALF, float, tcu_ctx_tf32, 4, true)
#endif
#if defined(CUPBOP_TCU_INT8)
CUPBOP_GEN_MMA_TCU(__cupbop_mma_m16n8k32_s8s32, FULL, int32_t, tcu_ctx_s8, 8, false)
CUPBOP_GEN_MMA_TCU(__cupbop_mma_m16n8k32_u8s32, FULL, int32_t, tcu_ctx_u8, 8, false)
CUPBOP_GEN_MMA_TCU(__cupbop_mma_m16n8k16_s8s32, HALF, int32_t, tcu_ctx_s8, 4, false)
CUPBOP_GEN_MMA_TCU(__cupbop_mma_m16n8k16_u8s32, HALF, int32_t, tcu_ctx_u8, 4, false)
#endif
#if defined(CUPBOP_TCU_FP8)
CUPBOP_GEN_MMA_TCU(__cupbop_mma_m16n8k32_e4m3f32, FULL, float, tcu_ctx_e4m3, 8, false)
CUPBOP_GEN_MMA_TCU(__cupbop_mma_m16n8k32_e5m2f32, FULL, float, tcu_ctx_e5m2, 8, false)
#endif

// dispatch symbols (CUPBOP_MMA_LOWERING=auto) for the operations the TCU can do exactly
#define CUPBOP_MMA_DISPATCH_FULL(NAME, ACC, TCU_OK)                                                           \
  extern "C" __attribute__((always_inline, convergent)) void NAME(CUPBOP_MMA_ARGS_FULL(ACC)) {                \
    CUPBOP_MMA_DISPATCH_BODY_##TCU_OK(NAME, (a0, a1, a2, a3, b0, b1, c0, c1, c2, c3, d))                      \
  }
#define CUPBOP_MMA_DISPATCH_HALF(NAME, ACC, TCU_OK)                                                           \
  extern "C" __attribute__((always_inline, convergent)) void NAME(CUPBOP_MMA_ARGS_HALF(ACC)) {                \
    CUPBOP_MMA_DISPATCH_BODY_##TCU_OK(NAME, (a0, a1, b0, c0, c1, c2, c3, d))                                  \
  }
#define CUPBOP_MMA_DISPATCH_BODY_1(NAME, ARGS) NAME##_tcu ARGS;
#define CUPBOP_MMA_DISPATCH_BODY_0(NAME, ARGS) NAME##_sw ARGS;
#if defined(CUPBOP_TCU_TF32) && !defined(CUPBOP_MMA_SW)
#define CUPBOP_D_TF32 1
#else
#define CUPBOP_D_TF32 0
#endif
#if defined(CUPBOP_TCU_INT8) && !defined(CUPBOP_MMA_SW)
#define CUPBOP_D_INT8 1
#else
#define CUPBOP_D_INT8 0
#endif
#if defined(CUPBOP_TCU_FP8) && !defined(CUPBOP_MMA_SW)
#define CUPBOP_D_FP8 1
#else
#define CUPBOP_D_FP8 0
#endif
#define CUPBOP_XD_FULL(NAME, ACC, OK) CUPBOP_MMA_DISPATCH_FULL(NAME, ACC, OK)
#define CUPBOP_XD_HALF(NAME, ACC, OK) CUPBOP_MMA_DISPATCH_HALF(NAME, ACC, OK)
#define CUPBOP_EXPAND(x) x
CUPBOP_EXPAND(CUPBOP_XD_FULL(__cupbop_mma_m16n8k8_tf32f32, float, CUPBOP_D_TF32))
CUPBOP_EXPAND(CUPBOP_XD_HALF(__cupbop_mma_m16n8k4_tf32f32, float, CUPBOP_D_TF32))
CUPBOP_EXPAND(CUPBOP_XD_FULL(__cupbop_mma_m16n8k32_s8s32, int32_t, CUPBOP_D_INT8))
CUPBOP_EXPAND(CUPBOP_XD_FULL(__cupbop_mma_m16n8k32_u8s32, int32_t, CUPBOP_D_INT8))
CUPBOP_EXPAND(CUPBOP_XD_HALF(__cupbop_mma_m16n8k16_s8s32, int32_t, CUPBOP_D_INT8))
CUPBOP_EXPAND(CUPBOP_XD_HALF(__cupbop_mma_m16n8k16_u8s32, int32_t, CUPBOP_D_INT8))
CUPBOP_EXPAND(CUPBOP_XD_FULL(__cupbop_mma_m16n8k32_e4m3f32, float, CUPBOP_D_FP8))
CUPBOP_EXPAND(CUPBOP_XD_FULL(__cupbop_mma_m16n8k32_e5m2f32, float, CUPBOP_D_FP8))

// ---- CUDA wmma: compact fragments ---------------------------------------------------------------------
// The NVVM wmma intrinsics fix the per-lane register count of each fragment: bf16 A/B 4 x i32 (m16n16k16),
// tf32 A/B 4 x i32 (m16n16k8), s8/u8 A/B 2 x i32 (m16n16k16), C/D 8 x 32-bit. These are exactly the
// non-zero registers of the Vortex NT=32 m16n16 tile restricted to the CUDA K, so the fragments hold the
// Vortex layout (lane l, g = l>>2, t = l&3; KW = K in 32-bit words: 8 for bf16/f16/tf32, 4 for s8/u8):
//   A compact i:  row g + 8*(i>>1), word 4*(i&1) + t      (KW=8, i < 4; Vortex regs 0,1,4,5)
//                 row g + 8*i,      word t                (KW=4, i < 2; Vortex regs 0,4)
//   B compact i:  col g + 8*(i&1),  word 4*(i>>1) + t     (KW=8, i < 4; Vortex regs 0..3)
//                 col g + 8*i,      word t                (KW=4, i < 2; Vortex regs 0,1)
//   C/D reg r:    row g + 8*(r>>2), col t + 4*(r&3)       (Vortex acc layout)
// Every fragment element is a distinct matrix element (no padding, no duplicates), so element-wise code on
// fragments (fill_fragment, __float_to_tf32 over x[]) is layout independent. f16 keeps the 8-register
// fragment of the existing TCU wrappers (16 halves): the same words in Vortex regs {0,1,4,5} (A) and
// {0..3} (B), the other registers zero (the existing __vx_wmma_* f16 loaders zero them as well).
template <int ES>
static inline uint32_t __cupbop_wmma_gather(const char *p, uint32_t stride_bytes) { // 4/ES elements, stride apart
  if constexpr (ES == 4) return *(const uint32_t *)p;
  else if constexpr (ES == 2) return __cupbop_f32_bits(vx_packlh_f(p, stride_bytes));
  else return __cupbop_f32_bits(vx_packlb_f(p, stride_bytes));
}
template <int ES, int KW, bool ROW> // A 16xK, ROW: A[r][k] at p[r*ldm + k], else at p[k*ldm + r]
static inline void __cupbop_wmma_ld_a(uint32_t *f, const void *p, int32_t ldm) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const char *pc = (const char *)p;
  constexpr int NE = 4 / ES, NA = KW / 2;
  for (int i = 0; i < NA; ++i) {
    const int row = g + 8 * (KW == 8 ? (i >> 1) : i), w = (KW == 8 ? 4 * (i & 1) : 0) + t, k0 = w * NE;
    if constexpr (ROW) f[i] = *(const uint32_t *)(pc + ((uint32_t)row * (uint32_t)ldm + k0) * ES);
    else f[i] = __cupbop_wmma_gather<ES>(pc + ((uint32_t)k0 * (uint32_t)ldm + row) * ES, (uint32_t)ldm * ES);
  }
}
template <int ES, int KW, bool ROW> // B Kx16, ROW: B[k][n] at p[k*ldm + n], else at p[n*ldm + k]
static inline void __cupbop_wmma_ld_b(uint32_t *f, const void *p, int32_t ldm) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const char *pc = (const char *)p;
  constexpr int NE = 4 / ES, NB = KW / 2;
  for (int i = 0; i < NB; ++i) {
    const int col = g + 8 * (KW == 8 ? (i & 1) : i), w = (KW == 8 ? 4 * (i >> 1) : 0) + t, k0 = w * NE;
    if constexpr (ROW) f[i] = __cupbop_wmma_gather<ES>(pc + ((uint32_t)k0 * (uint32_t)ldm + col) * ES, (uint32_t)ldm * ES);
    else f[i] = *(const uint32_t *)(pc + ((uint32_t)col * (uint32_t)ldm + k0) * ES);
  }
}
template <bool ROW> // C/D 16x16 of 32-bit elements
static inline void __cupbop_wmma_ld_c(uint32_t *f, const void *p, int32_t ldm) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const uint32_t *pu = (const uint32_t *)p;
  for (int r = 0; r < 8; ++r) {
    const uint32_t row = g + 8 * (r >> 2), col = t + 4 * (r & 3);
    f[r] = ROW ? pu[row * (uint32_t)ldm + col] : pu[col * (uint32_t)ldm + row];
  }
}
template <bool ROW>
static inline void __cupbop_wmma_st_d(void *p, const uint32_t *f, int32_t ldm) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  uint32_t *pu = (uint32_t *)p;
  for (int r = 0; r < 8; ++r) {
    const uint32_t row = g + 8 * (r >> 2), col = t + 4 * (r & 3);
    if (ROW) pu[row * (uint32_t)ldm + col] = f[r]; else pu[col * (uint32_t)ldm + row] = f[r];
  }
}

// software wmma mma on compact fragments: D(16x16) = A(16xK) B(Kx16) + C, KW words of K. Word w of
// A row g: lane (g<<2)|(w&3), compact reg (w>>2) [row g] / 2+(w>>2) [row g+8] (KW=8; KW=4: 0 / 1). Word
// w of B column t+4j: lane ((t+4(j&1))<<2)|(w&3), compact reg 2(w>>2)+(j>>1) (KW=4: j>>1).
template <class EA, class EB, int KW, bool SAT>
static inline void __cupbop_wmma_mma_sw(uint32_t *D, const uint32_t *A, const uint32_t *B, const uint32_t *C) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  if constexpr (EA::is_int) {
    int64_t s[8]; uint32_t u[8];
    for (int r = 0; r < 8; ++r) { s[r] = (int32_t)C[r]; u[r] = C[r]; }
    for (int w = 0; w < KW; ++w) {
      const int ow = w & 3, hw = w >> 2;
      const uint32_t xa = __cupbop_shfl32(A[KW == 8 ? hw : 0], (g << 2) | ow);
      const uint32_t ya = __cupbop_shfl32(A[KW == 8 ? 2 + hw : 1], (g << 2) | ow);
      uint32_t vb[4];
      for (int j = 0; j < 4; ++j) vb[j] = __cupbop_shfl32(B[KW == 8 ? 2 * hw + (j >> 1) : (j >> 1)], ((t + 4 * (j & 1)) << 2) | ow);
      for (int i = 0; i < EA::n; ++i) {
        const int32_t ag = EA::get(xa, i), ag8 = EA::get(ya, i);
        for (int j = 0; j < 4; ++j) {
          const int32_t b = EB::get(vb[j], i);
          if constexpr (SAT) { s[j] += ag * b; s[4 + j] += ag8 * b; }
          else { u[j] += (uint32_t)(ag * b); u[4 + j] += (uint32_t)(ag8 * b); }
        }
      }
    }
    for (int r = 0; r < 8; ++r) {
      if constexpr (SAT) D[r] = (uint32_t)(int32_t)(s[r] > 2147483647LL ? 2147483647LL : (s[r] < -2147483648LL ? -2147483648LL : s[r]));
      else D[r] = u[r];
    }
  } else {
    float d[8];
    for (int r = 0; r < 8; ++r) d[r] = __cupbop_bits_f32(C[r]);
    for (int w = 0; w < KW; ++w) {
      const int ow = w & 3, hw = w >> 2;
      const uint32_t xa = __cupbop_shfl32(A[KW == 8 ? hw : 0], (g << 2) | ow);
      const uint32_t ya = __cupbop_shfl32(A[KW == 8 ? 2 + hw : 1], (g << 2) | ow);
      uint32_t vb[4];
      for (int j = 0; j < 4; ++j) vb[j] = __cupbop_shfl32(B[KW == 8 ? 2 * hw + (j >> 1) : (j >> 1)], ((t + 4 * (j & 1)) << 2) | ow);
      for (int i = 0; i < EA::n; ++i) {
        const float ag = EA::get(xa, i), ag8 = EA::get(ya, i);
        for (int j = 0; j < 4; ++j) { const float b = EB::get(vb[j], i); d[j] += ag * b; d[4 + j] += ag8 * b; }
      }
    }
    for (int r = 0; r < 8; ++r) D[r] = __cupbop_f32_bits(d[r]);
  }
}
#if defined(CUPBOP_MMA_TCU_AVAILABLE)
template <class CTX, int KW, bool TF32>
static inline void __cupbop_wmma_mma_tcu(uint32_t *D, const uint32_t *A, const uint32_t *B, const uint32_t *C) {
  auto in = [](uint32_t w) { return __cupbop_bits_f32(TF32 ? (w >> 13) : w); };
  typename CTX::fragment_a fa; typename CTX::fragment_b fb; typename CTX::fragment_acc fc, fd;
  if constexpr (KW == 8) {
    fa.data = {{in(A[0]), in(A[1]), 0.f, 0.f, in(A[2]), in(A[3]), 0.f, 0.f}};
    fb.data = {{in(B[0]), in(B[1]), in(B[2]), in(B[3]), 0.f, 0.f, 0.f, 0.f}};
  } else {
    fa.data = {{in(A[0]), 0.f, 0.f, 0.f, in(A[1]), 0.f, 0.f, 0.f}};
    fb.data = {{in(B[0]), in(B[1]), 0.f, 0.f, 0.f, 0.f, 0.f, 0.f}};
  }
  for (int r = 0; r < 8; ++r) fc.data[r] = __cupbop_bits_f32(C[r]);
  CTX::mma_sync(fd, fa, fb, fc);
  for (int r = 0; r < 8; ++r) D[r] = __cupbop_f32_bits(fd.data[r]);
}
#endif

#if VX_CFG_NUM_THREADS == 32
#define CUPBOP_WMMA_LD(TAG, ES, KW)                                                                                                                \
  extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_a_##TAG##_row(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_a<ES, KW, true>((uint32_t *)f, p, ldm); }  \
  extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_a_##TAG##_col(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_a<ES, KW, false>((uint32_t *)f, p, ldm); } \
  extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_b_##TAG##_row(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_b<ES, KW, true>((uint32_t *)f, p, ldm); }  \
  extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_b_##TAG##_col(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_b<ES, KW, false>((uint32_t *)f, p, ldm); }
CUPBOP_WMMA_LD(bf16, 2, 8)
CUPBOP_WMMA_LD(tf32, 4, 8)
CUPBOP_WMMA_LD(s8, 1, 4)
CUPBOP_WMMA_LD(u8, 1, 4)
// f16: compact words placed in the 8-register TCU fragment (A regs 0,1,4,5 ; B regs 0..3), rest zero
static inline void __cupbop_wmma_f16_expand_a(uint32_t *f) { f[5] = f[3]; f[4] = f[2]; f[2] = f[3] = f[6] = f[7] = 0u; }
static inline void __cupbop_wmma_f16_expand_b(uint32_t *f) { f[4] = f[5] = f[6] = f[7] = 0u; }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_a_f16_row(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_a<2, 8, true>((uint32_t *)f, p, ldm); __cupbop_wmma_f16_expand_a((uint32_t *)f); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_a_f16_col(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_a<2, 8, false>((uint32_t *)f, p, ldm); __cupbop_wmma_f16_expand_a((uint32_t *)f); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_b_f16_row(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_b<2, 8, true>((uint32_t *)f, p, ldm); __cupbop_wmma_f16_expand_b((uint32_t *)f); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_b_f16_col(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_b<2, 8, false>((uint32_t *)f, p, ldm); __cupbop_wmma_f16_expand_b((uint32_t *)f); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_c_f32_row(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_c<true>((uint32_t *)f, p, ldm); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_c_f32_col(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_c<false>((uint32_t *)f, p, ldm); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_c_s32_row(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_c<true>((uint32_t *)f, p, ldm); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_load_c_s32_col(void *f, const void *p, int32_t ldm) { __cupbop_wmma_ld_c<false>((uint32_t *)f, p, ldm); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_store_d_f32_row(void *p, const void *f, int32_t ldm) { __cupbop_wmma_st_d<true>(p, (const uint32_t *)f, ldm); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_store_d_f32_col(void *p, const void *f, int32_t ldm) { __cupbop_wmma_st_d<false>(p, (const uint32_t *)f, ldm); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_store_d_s32_row(void *p, const void *f, int32_t ldm) { __cupbop_wmma_st_d<true>(p, (const uint32_t *)f, ldm); }
extern "C" __attribute__((always_inline)) void __cupbop_wmma_store_d_s32_col(void *p, const void *f, int32_t ldm) { __cupbop_wmma_st_d<false>(p, (const uint32_t *)f, ldm); }

#define CUPBOP_WMMA_MMA_SW(TAG, EA, EB, KW, SAT)                                                                                   \
  extern "C" __attribute__((always_inline, convergent)) void __cupbop_wmma_mma_##TAG##_sw(void *d, const void *a, const void *b, const void *c) { \
    __cupbop_wmma_mma_sw<EA, EB, KW, SAT>((uint32_t *)d, (const uint32_t *)a, (const uint32_t *)b, (const uint32_t *)c);            \
  }
CUPBOP_WMMA_MMA_SW(bf16, __cupbop_el_bf16, __cupbop_el_bf16, 8, false)
CUPBOP_WMMA_MMA_SW(tf32, __cupbop_el_tf32, __cupbop_el_tf32, 8, false)
CUPBOP_WMMA_MMA_SW(s8, __cupbop_el_s8, __cupbop_el_s8, 4, false)
CUPBOP_WMMA_MMA_SW(u8, __cupbop_el_u8, __cupbop_el_u8, 4, false)
CUPBOP_WMMA_MMA_SW(s8sat, __cupbop_el_s8, __cupbop_el_s8, 4, true)
CUPBOP_WMMA_MMA_SW(u8sat, __cupbop_el_u8, __cupbop_el_u8, 4, true)
// f16 on the 8-register fragment: gather the K=16 words (A regs 0,1,4,5 ; B regs 0..3)
extern "C" __attribute__((always_inline, convergent)) void __cupbop_wmma_mma_f16_sw(void *d, const void *a, const void *b, const void *c) {
  const uint32_t *ap = (const uint32_t *)a;
  const uint32_t A[4] = {ap[0], ap[1], ap[4], ap[5]};
  __cupbop_wmma_mma_sw<__cupbop_el_f16, __cupbop_el_f16, 8, false>((uint32_t *)d, A, (const uint32_t *)b, (const uint32_t *)c);
}
#if defined(CUPBOP_MMA_TCU_AVAILABLE)
#define CUPBOP_WMMA_MMA_TCU(TAG, CTX, KW, TF32)                                                                                     \
  extern "C" __attribute__((always_inline, convergent)) void __cupbop_wmma_mma_##TAG##_tcu(void *d, const void *a, const void *b, const void *c) { \
    __cupbop_wmma_mma_tcu<CTX, KW, TF32>((uint32_t *)d, (const uint32_t *)a, (const uint32_t *)b, (const uint32_t *)c);              \
  }
#if defined(CUPBOP_TCU_BF16)
CUPBOP_WMMA_MMA_TCU(bf16, tcu_ctx_bf16, 8, false)
// f16 TCU on the 8-register fragment with the upper-k registers forced to zero (robust to fill_fragment on A/B)
extern "C" __attribute__((always_inline, convergent)) void __cupbop_wmma_mma_f16_tcu(void *d, const void *a, const void *b, const void *c) {
  const uint32_t *ap = (const uint32_t *)a;
  const uint32_t A[4] = {ap[0], ap[1], ap[4], ap[5]};
  __cupbop_wmma_mma_tcu<tcu_ctx, 8, false>((uint32_t *)d, A, (const uint32_t *)b, (const uint32_t *)c);
}
#endif
#if defined(CUPBOP_TCU_TF32)
CUPBOP_WMMA_MMA_TCU(tf32, tcu_ctx_tf32, 8, true)
#endif
#if defined(CUPBOP_TCU_INT8)
CUPBOP_WMMA_MMA_TCU(s8, tcu_ctx_s8, 4, false)
CUPBOP_WMMA_MMA_TCU(u8, tcu_ctx_u8, 4, false)
#endif
#endif // CUPBOP_MMA_TCU_AVAILABLE
#define CUPBOP_WMMA_MMA_DISPATCH(TAG, OK)                                                                                         \
  extern "C" __attribute__((always_inline, convergent)) void __cupbop_wmma_mma_##TAG(void *d, const void *a, const void *b, const void *c) { \
    CUPBOP_WMMA_DISPATCH_BODY_##OK(TAG)                                                                                           \
  }
#define CUPBOP_WMMA_DISPATCH_BODY_1(TAG) __cupbop_wmma_mma_##TAG##_tcu(d, a, b, c);
#define CUPBOP_WMMA_DISPATCH_BODY_0(TAG) __cupbop_wmma_mma_##TAG##_sw(d, a, b, c);
#if defined(CUPBOP_TCU_BF16) && !defined(CUPBOP_MMA_SW)
#define CUPBOP_D_BF16 1
#else
#define CUPBOP_D_BF16 0
#endif
#define CUPBOP_XWD(TAG, OK) CUPBOP_WMMA_MMA_DISPATCH(TAG, OK)
CUPBOP_EXPAND(CUPBOP_XWD(bf16, CUPBOP_D_BF16))
CUPBOP_EXPAND(CUPBOP_XWD(tf32, CUPBOP_D_TF32))
CUPBOP_EXPAND(CUPBOP_XWD(s8, CUPBOP_D_INT8))
CUPBOP_EXPAND(CUPBOP_XWD(u8, CUPBOP_D_INT8))

// ---- wgmma.mma_async (Hopper warpgroup MMA): software reference for every type, TCU for tf32/fp8/int8 ----
// m64nNk{16 f16/bf16, 8 tf32, 32 e4m3/e5m2/s8/u8}: K is 32 bytes = 8 words per row for every type, so A (64xK)
// and B (NxK) use the canonical no-swizzle K-major core-matrix layout with word w of row r at
// (r>>3)*SBO + (w>>2)*LBO + (r&7)*16 + (w&3)*4 (the f16 __cupbop_core_ld in word units). Warp w of the
// warpgroup owns rows 16w..16w+15; acc: N/2 32-bit accumulators per thread (f32 or s32), PTX layout
//   acc[4j+0] = (g, 8j+2t)  acc[4j+1] = (g, 8j+2t+1)  acc[4j+2] = (g+8, 8j+2t)  acc[4j+3] = (g+8, 8j+2t+1)
// scale_d = 0: D = A*B. Swizzled descriptors are not modelled: trap rather than compute from the wrong bytes.
struct __cupbop_wg_desc { const char *base; uint32_t lbo, sbo, swz; };
static inline __cupbop_wg_desc __cupbop_wg_decode(uint64_t d) {
  __cupbop_wg_desc m;
  const uintptr_t lmem = (uintptr_t)csr_read(VX_CSR_LOCAL_MEM_BASE);
  m.base = (const char *)(lmem + ((((d & 0x3FFFu) << 4) - (lmem & 0x3FFFFu)) & 0x3FFFFu)); // window addr -> pointer
  m.lbo = (uint32_t)((d >> 16) & 0x3FFFu) << 4;
  m.sbo = (uint32_t)((d >> 32) & 0x3FFFu) << 4;
  m.swz = (uint32_t)(d >> 62);
  if (m.swz) __builtin_trap();
  return m;
}
static inline uint32_t __cupbop_wg_word(const __cupbop_wg_desc &m, int r, int w) {
  return *(const uint32_t *)(m.base + (r >> 3) * m.sbo + (w >> 2) * m.lbo + (r & 7) * 16 + (w & 3) * 4);
}
template <class EA, class EB, bool SAT>
static inline void __cupbop_wgmma_sw(int n_cols, uint64_t desc_a, uint64_t desc_b, int scale_d, int warp_in_wg, uint32_t *acc) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const __cupbop_wg_desc A = __cupbop_wg_decode(desc_a), B = __cupbop_wg_decode(desc_b);
  const int row0 = 16 * warp_in_wg;
  for (int j = 0; j < n_cols / 8; ++j)
    for (int s = 0; s < 4; ++s) {
      const int r = row0 + g + 8 * (s >> 1), c = 8 * j + 2 * t + (s & 1);
      if constexpr (EA::is_int) {
        int64_t sum = scale_d ? (int64_t)(int32_t)acc[4 * j + s] : 0; uint32_t u = scale_d ? acc[4 * j + s] : 0u;
        for (int w = 0; w < 8; ++w) {
          const uint32_t aw = __cupbop_wg_word(A, r, w), bw = __cupbop_wg_word(B, c, w);
          for (int i = 0; i < EA::n; ++i) {
            const int32_t p = EA::get(aw, i) * EB::get(bw, i);
            if constexpr (SAT) sum += p; else u += (uint32_t)p;
          }
        }
        acc[4 * j + s] = SAT ? (uint32_t)(int32_t)(sum > 2147483647LL ? 2147483647LL : (sum < -2147483648LL ? -2147483648LL : sum)) : u;
      } else {
        float d = scale_d ? __cupbop_bits_f32(acc[4 * j + s]) : 0.f;
        for (int w = 0; w < 8; ++w) {
          const uint32_t aw = __cupbop_wg_word(A, r, w), bw = __cupbop_wg_word(B, c, w);
          for (int i = 0; i < EA::n; ++i) d += EA::get(aw, i) * EB::get(bw, i);
        }
        acc[4 * j + s] = __cupbop_f32_bits(d);
      }
    }
}
#if defined(CUPBOP_MMA_TCU_AVAILABLE)
// TCU: same decomposition as __cupbop_wgmma_m64nNk16_impl (N/16 m16n16 ops per warp, the upper-k half of the
// tile zero), word loads, tf32 moved to the 19-bit Vortex encoding, accumulators handled as 32-bit patterns.
template <class CTX, bool TF32>
static inline void __cupbop_wgmma_tcu(int n_cols, uint64_t desc_a, uint64_t desc_b, int scale_d, int warp_in_wg, uint32_t *acc) {
  auto in = [](uint32_t w) { return __cupbop_bits_f32(TF32 ? (w >> 13) : w); };
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const __cupbop_wg_desc A = __cupbop_wg_decode(desc_a), B = __cupbop_wg_decode(desc_b);
  const int row0 = 16 * warp_in_wg;
  typename CTX::fragment_a fa;
  fa.data = {{in(__cupbop_wg_word(A, row0 + g, t)), in(__cupbop_wg_word(A, row0 + g, 4 + t)), 0.f, 0.f,
              in(__cupbop_wg_word(A, row0 + g + 8, t)), in(__cupbop_wg_word(A, row0 + g + 8, 4 + t)), 0.f, 0.f}};
  const bool odd = t & 1, hi = t >> 1;
  for (int nb = 0; nb < n_cols / 16; ++nb) {
    const int n0 = 16 * nb;
    typename CTX::fragment_b fb;
    fb.data = {{in(__cupbop_wg_word(B, n0 + g, t)), in(__cupbop_wg_word(B, n0 + g + 8, t)),
                in(__cupbop_wg_word(B, n0 + g, 4 + t)), in(__cupbop_wg_word(B, n0 + g + 8, 4 + t)), 0.f, 0.f, 0.f, 0.f}};
    typename CTX::fragment_acc fc, fd;
    for (int r = 0; r < 8; ++r) {
      if (scale_d) {
        const int jl = (r & 3) >> 1, q = (r & 3) & 1;
        const int src = (g << 2) | ((t >> 1) + 2 * q);
        const int base = 4 * (2 * nb + jl) + 2 * (r >> 2);
        const float v0 = __cupbop_shflf(__cupbop_bits_f32(acc[base]), src), v1 = __cupbop_shflf(__cupbop_bits_f32(acc[base + 1]), src);
        fc.data[r] = odd ? v1 : v0;
      } else {
        fc.data[r] = 0.f;
      }
    }
    CTX::mma_sync(fd, fa, fb, fc);
    for (int jl = 0; jl < 2; ++jl) {
      const int j = 2 * nb + jl;
      for (int s = 0; s < 4; ++s) {
        const int c = 8 * jl + 2 * t + (s & 1);
        const int src = (g << 2) | (c & 3), rb = 4 * (s >> 1) + 2 * jl;
        const float p0 = __cupbop_shflf(fd.data[rb], src), p1 = __cupbop_shflf(fd.data[rb + 1], src);
        acc[4 * j + s] = __cupbop_f32_bits(hi ? p1 : p0);
      }
    }
  }
}
#endif
#define CUPBOP_WG_ARGS(ACC) int n_cols, uint64_t desc_a, uint64_t desc_b, int scale_d, int warp_in_wg, ACC *acc
#define CUPBOP_GEN_WG_SW(NAME, ACC, EA, EB, SAT) \
  extern "C" __attribute__((always_inline, convergent)) void NAME##_sw(CUPBOP_WG_ARGS(ACC)) { __cupbop_wgmma_sw<EA, EB, SAT>(n_cols, desc_a, desc_b, scale_d, warp_in_wg, (uint32_t *)acc); }
#define CUPBOP_GEN_WG_TCU(NAME, ACC, CTX, TF32) \
  extern "C" __attribute__((always_inline, convergent)) void NAME##_tcu(CUPBOP_WG_ARGS(ACC)) { __cupbop_wgmma_tcu<CTX, TF32>(n_cols, desc_a, desc_b, scale_d, warp_in_wg, (uint32_t *)acc); }
#define CUPBOP_GEN_WG_DISPATCH(NAME, ACC, OK) \
  extern "C" __attribute__((always_inline, convergent)) void NAME(CUPBOP_WG_ARGS(ACC)) { CUPBOP_WG_DISPATCH_BODY_##OK(NAME) }
#define CUPBOP_WG_DISPATCH_BODY_1(NAME) NAME##_tcu(n_cols, desc_a, desc_b, scale_d, warp_in_wg, acc);
#define CUPBOP_WG_DISPATCH_BODY_0(NAME) NAME##_sw(n_cols, desc_a, desc_b, scale_d, warp_in_wg, acc);
#define CUPBOP_XWG(NAME, ACC, OK) CUPBOP_GEN_WG_DISPATCH(NAME, ACC, OK)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk16_f16f32, float, __cupbop_el_f16, __cupbop_el_f16, false)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk16_bf16f32, float, __cupbop_el_bf16, __cupbop_el_bf16, false)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk8_tf32f32, float, __cupbop_el_tf32, __cupbop_el_tf32, false)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk32_e4m3f32, float, __cupbop_el_e4m3, __cupbop_el_e4m3, false)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk32_e5m2f32, float, __cupbop_el_e5m2, __cupbop_el_e5m2, false)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk32_e4m3e5m2f32, float, __cupbop_el_e4m3, __cupbop_el_e5m2, false)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk32_e5m2e4m3f32, float, __cupbop_el_e5m2, __cupbop_el_e4m3, false)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk32_s8s32, int32_t, __cupbop_el_s8, __cupbop_el_s8, false)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk32_u8s32, int32_t, __cupbop_el_u8, __cupbop_el_u8, false)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk32_s8s32sat, int32_t, __cupbop_el_s8, __cupbop_el_s8, true)
CUPBOP_GEN_WG_SW(__cupbop_wgmma_m64nNk32_u8s32sat, int32_t, __cupbop_el_u8, __cupbop_el_u8, true)
#if defined(CUPBOP_TCU_TF32)
CUPBOP_GEN_WG_TCU(__cupbop_wgmma_m64nNk8_tf32f32, float, tcu_ctx_tf32, true)
#endif
#if defined(CUPBOP_TCU_FP8)
CUPBOP_GEN_WG_TCU(__cupbop_wgmma_m64nNk32_e4m3f32, float, tcu_ctx_e4m3, false)
CUPBOP_GEN_WG_TCU(__cupbop_wgmma_m64nNk32_e5m2f32, float, tcu_ctx_e5m2, false)
#endif
#if defined(CUPBOP_TCU_INT8)
CUPBOP_GEN_WG_TCU(__cupbop_wgmma_m64nNk32_s8s32, int32_t, tcu_ctx_s8, false)
CUPBOP_GEN_WG_TCU(__cupbop_wgmma_m64nNk32_u8s32, int32_t, tcu_ctx_u8, false)
#endif
CUPBOP_EXPAND(CUPBOP_XWG(__cupbop_wgmma_m64nNk8_tf32f32, float, CUPBOP_D_TF32))
CUPBOP_EXPAND(CUPBOP_XWG(__cupbop_wgmma_m64nNk32_e4m3f32, float, CUPBOP_D_FP8))
CUPBOP_EXPAND(CUPBOP_XWG(__cupbop_wgmma_m64nNk32_e5m2f32, float, CUPBOP_D_FP8))
CUPBOP_EXPAND(CUPBOP_XWG(__cupbop_wgmma_m64nNk32_s8s32, int32_t, CUPBOP_D_INT8))
CUPBOP_EXPAND(CUPBOP_XWG(__cupbop_wgmma_m64nNk32_u8s32, int32_t, CUPBOP_D_INT8))

#if !defined(VX_CFG_EXT_TCU_ENABLE)
// Builds without the TCU: the existing f16 wmma symbols (what CUPBOP_MMA_LOWERING=auto emits for f16)
// run the software path on the same 8-register fragments instead of failing to link.
extern "C" void __vx_wmma_load_a_m16n16k16_row_f16(void *frag, const void *p, int32_t ldm) { __cupbop_wmma_load_a_f16_row(frag, p, ldm); }
extern "C" void __vx_wmma_load_a_m16n16k16_col_f16(void *frag, const void *p, int32_t ldm) { __cupbop_wmma_load_a_f16_col(frag, p, ldm); }
extern "C" void __vx_wmma_load_b_m16n16k16_row_f16(void *frag, const void *p, int32_t ldm) { __cupbop_wmma_load_b_f16_row(frag, p, ldm); }
extern "C" void __vx_wmma_load_b_m16n16k16_col_f16(void *frag, const void *p, int32_t ldm) { __cupbop_wmma_load_b_f16_col(frag, p, ldm); }
extern "C" void __vx_wmma_load_c_m16n16k16_row_f32(void *frag, const void *p, int32_t ldm) { __cupbop_wmma_load_c_f32_row(frag, p, ldm); }
extern "C" void __vx_wmma_store_d_m16n16k16_f32(float *p, const float *frag, int32_t ldm, WmmaLayout layout) {
  if (layout == WMMA_LAYOUT_ROW) __cupbop_wmma_store_d_f32_row(p, frag, ldm); else __cupbop_wmma_store_d_f32_col(p, frag, ldm);
}
extern "C" void __vx_wmma_mma_m16n16k16_row_row_f16_f16_f32(float *d, const uint32_t *a, const uint32_t *b, const float *c) { __cupbop_wmma_mma_f16_sw(d, a, b, c); }
#endif
#endif // NT=32 wmma

// ---- mma.sync with f16 accumulators: m16n8k16 / m16n8k8 .row.col.f16.f16 (HMMA.16816.F16 / HMMA.1688.F16) -------
// C/D are two f16x2 registers per lane: c0 = {C[g][2t], C[g][2t+1]}, c1 = {C[g+8][2t], C[g+8][2t+1]} (low half =
// lower column), i.e. the f32-accumulator fragment's (c0,c1) and (c2,c3) packed. Model: the f32-accumulator helper
// (exact f16 products, fp32 sums starting from C) and one round-to-nearest-even to f16 per element at the end.
// PTX leaves the internal precision of f16 accumulation unspecified; NVIDIA tensor cores keep at least fp16 per
// partial sum, so results can differ from a GPU by an f16 ulp or so when the k-sum is not exact.
// Symbols: __cupbop_mma_m16n8k{16,8}_f16f16{,_sw,_tcu}(a.., b.., uint32 c0, uint32 c1, uint32 *d2); _tcu runs the f32
// TCU helper (built only when the f16 one is), dispatch as for f16f32.
// f32 -> f16 bits, round to nearest even, branch-free (selects; cf. __cupbop_f16_to_f32). NaN -> 0x7e00 (quiet).
static inline uint32_t __cupbop_f32_to_f16_rne(float f) {
  const uint32_t x = __cupbop_f32_bits(f), sign = (x >> 16) & 0x8000u, ax = x & 0x7fffffffu;
  // subnormal / zero result (|f| < 2^-14): the fp32 add rounds |f| to a multiple of 2^-24 (RNE)
  const float magic = __cupbop_bits_f32(0x3f000000u); // 0.5f: ((127-15)+(23-10)+1) << 23
  const uint32_t sub = __cupbop_f32_bits(__cupbop_bits_f32(ax) + magic) - 0x3f000000u;
  // normal result: rebias, add 0xfff + lsb (ties to even), shift; overflow carries into 0x7c00 (inf)
  const uint32_t nrm = (ax + 0xc8000fffu + ((ax >> 13) & 1u)) >> 13; // 0xc8000000 = (15-127) << 23
  uint32_t h = ax < 0x38800000u ? sub : nrm;
  h = ax >= 0x47800000u ? 0x7c00u : h;   // >= 65536: inf
  h = ax > 0x7f800000u ? 0x7e00u : h;    // NaN
  return (h & 0x7fffu) | sign;
}
static inline uint32_t __cupbop_pack_f16x2_rne(float lo, float hi) {
  return __cupbop_f32_to_f16_rne(lo) | (__cupbop_f32_to_f16_rne(hi) << 16);
}
#define CUPBOP_F16ACC_UNPACK float e0 = __cupbop_f16_to_f32(c0), e1 = __cupbop_f16_to_f32(c0 >> 16), e2 = __cupbop_f16_to_f32(c1), e3 = __cupbop_f16_to_f32(c1 >> 16); float dd[4]
#define CUPBOP_F16ACC_PACK d[0] = __cupbop_pack_f16x2_rne(dd[0], dd[1]); d[1] = __cupbop_pack_f16x2_rne(dd[2], dd[3])
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m16n8k16_f16f16_sw(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3,
    uint32_t b0, uint32_t b1, uint32_t c0, uint32_t c1, uint32_t *d) {
  CUPBOP_F16ACC_UNPACK;
  __cupbop_mma_m16n8k16_f16f32_sw(a0, a1, a2, a3, b0, b1, e0, e1, e2, e3, dd);
  CUPBOP_F16ACC_PACK;
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m16n8k8_f16f16_sw(uint32_t a0, uint32_t a1, uint32_t b0,
    uint32_t c0, uint32_t c1, uint32_t *d) {
  CUPBOP_F16ACC_UNPACK;
  __cupbop_mma_m16n8k8_f16f32_sw(a0, a1, b0, e0, e1, e2, e3, dd);
  CUPBOP_F16ACC_PACK;
}
#if defined(VX_CFG_NUM_THREADS) && defined(VX_CFG_EXT_TCU_ENABLE) && VX_CFG_NUM_THREADS == 16
// NT=16 sub-pass form: f16 accumulators through the f32 glue, same model as the f32 helper above. Slots per pass:
// c / d[2 * pass + i] = the two f16x2 registers of logical lane L = h + 16 pass.
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m16n8k16_f16f16_glue16(const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) {
  float fc[8], fd[8];
  for (int p = 0; p < 2; p++) {
    fc[4 * p + 0] = __cupbop_f16_to_f32(c[2 * p]);     fc[4 * p + 1] = __cupbop_f16_to_f32(c[2 * p] >> 16);
    fc[4 * p + 2] = __cupbop_f16_to_f32(c[2 * p + 1]); fc[4 * p + 3] = __cupbop_f16_to_f32(c[2 * p + 1] >> 16);
  }
  __cupbop_mma_m16n8k16_glue16_impl<tcu_ctx>(a, b, fc, fd);
  for (int p = 0; p < 2; p++) {
    d[2 * p] = __cupbop_pack_f16x2_rne(fd[4 * p], fd[4 * p + 1]);
    d[2 * p + 1] = __cupbop_pack_f16x2_rne(fd[4 * p + 2], fd[4 * p + 3]);
  }
}
#endif
#if defined(CUPBOP_MMA_TCU_AVAILABLE)
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m16n8k16_f16f16_tcu(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3,
    uint32_t b0, uint32_t b1, uint32_t c0, uint32_t c1, uint32_t *d) {
  CUPBOP_F16ACC_UNPACK;
  __cupbop_mma_m16n8k16_f16f32_tcu(a0, a1, a2, a3, b0, b1, e0, e1, e2, e3, dd);
  CUPBOP_F16ACC_PACK;
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m16n8k8_f16f16_tcu(uint32_t a0, uint32_t a1, uint32_t b0,
    uint32_t c0, uint32_t c1, uint32_t *d) {
  CUPBOP_F16ACC_UNPACK;
  __cupbop_mma_m16n8k8_f16f32_tcu(a0, a1, b0, e0, e1, e2, e3, dd);
  CUPBOP_F16ACC_PACK;
}
#endif
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m16n8k16_f16f16(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3,
    uint32_t b0, uint32_t b1, uint32_t c0, uint32_t c1, uint32_t *d) {
#if defined(CUPBOP_MMA_TCU_AVAILABLE) && !defined(CUPBOP_MMA_SW)
  __cupbop_mma_m16n8k16_f16f16_tcu(a0, a1, a2, a3, b0, b1, c0, c1, d);
#else
  __cupbop_mma_m16n8k16_f16f16_sw(a0, a1, a2, a3, b0, b1, c0, c1, d);
#endif
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m16n8k8_f16f16(uint32_t a0, uint32_t a1, uint32_t b0,
    uint32_t c0, uint32_t c1, uint32_t *d) {
#if defined(CUPBOP_MMA_TCU_AVAILABLE) && !defined(CUPBOP_MMA_SW)
  __cupbop_mma_m16n8k8_f16f16_tcu(a0, a1, b0, c0, c1, d);
#else
  __cupbop_mma_m16n8k8_f16f16_sw(a0, a1, b0, c0, c1, d);
#endif
}

// ---- mma.sync m8n8k4 .row.col.f64 (DMMA.884) ---------------------------------------------------------------------
// Fragments (PTX ISA, g = lane>>2, t = lane&3): a0 = A[g][t] (8x4 row), b0 = B[t][g] (4x8 col), c0/c1 = C[g][2t],
// C[g][2t+1]. D = A*B + C as k-ordered fp64 fused multiply-adds starting from C (the order DMMA uses is not
// specified; this is exact whenever the products and partial sums are). Software only: the Vortex TCU has no fp64.
static inline double __cupbop_shfl_f64(double v, int src) {
  uint64_t u; __builtin_memcpy(&u, &v, 8);
  const uint32_t lo = __cupbop_shfl32((uint32_t)u, src), hi = __cupbop_shfl32((uint32_t)(u >> 32), src);
  u = ((uint64_t)hi << 32) | lo; double r; __builtin_memcpy(&r, &u, 8); return r;
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m8n8k4_f64f64_sw(double a0, double b0, double c0, double c1, double *d) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  double d0 = c0, d1 = c1;
  for (int k = 0; k < 4; ++k) {
    const double a = __cupbop_shfl_f64(a0, (g << 2) | k);             // A[g][k]
    const double x = __cupbop_shfl_f64(b0, ((2 * t) << 2) | k);       // B[k][2t]
    const double y = __cupbop_shfl_f64(b0, ((2 * t + 1) << 2) | k);   // B[k][2t+1]
    d0 = __builtin_fma(a, x, d0); d1 = __builtin_fma(a, y, d1);
  }
  d[0] = d0; d[1] = d1;
}

// ---- mma.sync m8n8k4 .<la>.<lb>.f32.f16.f16.f32 (Volta HMMA.884.F32.F32, STEP0..3) ----------------------------
// Four independent 8x8x4 products per warp, one per quad pair q: lanes 4q..4q+3 (low group, hi = 0) and
// 16+4q..19+4q (high group, hi = 1); r4 = lane % 4. PTX ISA fragments (f16 element e = 0..3 is a0.lo a0.hi a1.lo
// a1.hi, likewise for b):
//   A .row: A[r4 + 4hi][e]          A .col: A[e + 4hi][r4]
//   B .row: B[r4][e + 4hi]          B .col: B[e][r4 + 4hi]
//   C/D (f32, i = 0..7): row = (lane & 1) + (i & 2) + 4hi, col = (i & 4) + (lane & 2) + (i & 1)
// (checked bit-exactly against an A100 running the PTX instruction, experiments/bugfix12/mma884). D = A*B + C as
// k-ordered fp32 FMAs starting from C (f16 products are exact in fp32; the hardware's summation order is not
// specified). CuLifter lifts each HMMA.884 STEPs to one such call (the other six C inputs zero, two outputs used).
// Software only, on the 1:1 hardware warp (32 lanes, all active): the Vortex TCU tile has no quad-pair form.
static inline void __cupbop_mma_m8n8k4_f16f32_impl(const int a_row, const int b_row, uint32_t a0, uint32_t a1,
    uint32_t b0, uint32_t b1, float c0, float c1, float c2, float c3, float c4, float c5, float c6, float c7, float *d) {
  const int l = vx_thread_id(), q4 = l & 12, hi16 = l & 16, x = l & 1, y = l & 2;
  float A[2][4], B[4][4]; // A[j][k]: row x + 2j (+4hi); B[cc][k]: column 4 * (cc >> 1) + y + (cc & 1)
  if (a_row) {
    for (int j = 0; j < 2; ++j) {
      const int src = q4 + x + 2 * j + hi16;
      const uint32_t u0 = __cupbop_shfl32(a0, src), u1 = __cupbop_shfl32(a1, src);
      A[j][0] = __cupbop_f16_to_f32(u0); A[j][1] = __cupbop_f16_to_f32(u0 >> 16);
      A[j][2] = __cupbop_f16_to_f32(u1); A[j][3] = __cupbop_f16_to_f32(u1 >> 16);
    }
  } else {
    for (int k = 0; k < 4; ++k) {
      const int src = q4 + k + hi16;
      const uint32_t u0 = __cupbop_shfl32(a0, src), u1 = __cupbop_shfl32(a1, src);
      A[0][k] = __cupbop_f16_to_f32(x ? u0 >> 16 : u0); A[1][k] = __cupbop_f16_to_f32(x ? u1 >> 16 : u1);
    }
  }
  if (b_row) {
    for (int k = 0; k < 4; ++k)
      for (int h = 0; h < 2; ++h) {
        const int src = q4 + k + 16 * h;
        const uint32_t u0 = __cupbop_shfl32(b0, src), u1 = __cupbop_shfl32(b1, src), u = y ? u1 : u0;
        B[2 * h][k] = __cupbop_f16_to_f32(u); B[2 * h + 1][k] = __cupbop_f16_to_f32(u >> 16);
      }
  } else {
    for (int cc = 0; cc < 4; ++cc) {
      const int src = q4 + y + (cc & 1) + 16 * (cc >> 1);
      const uint32_t u0 = __cupbop_shfl32(b0, src), u1 = __cupbop_shfl32(b1, src);
      B[cc][0] = __cupbop_f16_to_f32(u0); B[cc][1] = __cupbop_f16_to_f32(u0 >> 16);
      B[cc][2] = __cupbop_f16_to_f32(u1); B[cc][3] = __cupbop_f16_to_f32(u1 >> 16);
    }
  }
  const float c[8] = {c0, c1, c2, c3, c4, c5, c6, c7};
  for (int i = 0; i < 8; ++i) {
    const int j = (i >> 1) & 1, cc = ((i >> 1) & 2) | (i & 1);
    float acc = c[i];
    for (int k = 0; k < 4; ++k) acc = __builtin_fmaf(A[j][k], B[cc][k], acc);
    d[i] = acc;
  }
}
#define CUPBOP_MMA884_F32(LA, LB, AR, BR)                                                                              \
  extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m8n8k4_f16f32_##LA##_##LB##_sw(            \
      uint32_t a0, uint32_t a1, uint32_t b0, uint32_t b1, float c0, float c1, float c2, float c3, float c4, float c5,   \
      float c6, float c7, float *d) {                                                                                   \
    __cupbop_mma_m8n8k4_f16f32_impl(AR, BR, a0, a1, b0, b1, c0, c1, c2, c3, c4, c5, c6, c7, d);                        \
  }
CUPBOP_MMA884_F32(row, col, 1, 0)
CUPBOP_MMA884_F32(row, row, 1, 1)
CUPBOP_MMA884_F32(col, row, 0, 1)
CUPBOP_MMA884_F32(col, col, 0, 0)
#undef CUPBOP_MMA884_F32


// ---- ldmatrix / stmatrix .m8n8 .b16 (inline asm of CuLifter-lifted kernels and CUTLASS-style CUDA code) ---------
// ldmatrix.sync.aligned.m8n8.x{1,2,4}[.trans].shared.b16 {d0..}, [a]: lanes 8j..8j+7 give the row addresses of
// matrix j (row r from lane 8j+r); lane l (g = l>>2, t = l&3) receives d_j = {M_j[g][2t], M_j[g][2t+1]} (low half =
// lower column), with .trans {M_j[2t][g], M_j[2t+1][g]}. stmatrix is the inverse (lane l holds d_j, the rows' lanes
// give the addresses). The address operand is a 32-bit shared-window value: CuLifter's ptrtoint of @shared_mem + off
// (32 or 64 bits, truncated here) or __cupbop_cvta_to_shared's offset; both decode to the local-memory pointer
// lmem + ((a - lmem) mod 2^18), as the wgmma descriptors do (local memory < 256 KB). Software: index shuffles over the
// hardware warp (1:1 / core mapping with 32 hardware lanes), all 32 lanes active as .sync requires.
static inline char *__cupbop_smem_ptr(uint32_t a) {
  const uintptr_t lmem = (uintptr_t)csr_read(VX_CSR_LOCAL_MEM_BASE);
  return (char *)(lmem + ((a - (uint32_t)lmem) & 0x3FFFFu));
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_ldmatrix_m8n8_b16(uint32_t a, int num, int trans, uint32_t *d) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  for (int j = 0; j < num; ++j) {
    if (!trans) {
      const uint32_t row = __cupbop_shfl32(a, 8 * j + g);
      d[j] = *(volatile uint32_t *)(__cupbop_smem_ptr(row) + 4 * t);
    } else {
      const uint32_t r0 = __cupbop_shfl32(a, 8 * j + 2 * t), r1 = __cupbop_shfl32(a, 8 * j + 2 * t + 1);
      const uint32_t lo = *(volatile uint16_t *)(__cupbop_smem_ptr(r0) + 2 * g), hi = *(volatile uint16_t *)(__cupbop_smem_ptr(r1) + 2 * g);
      d[j] = lo | (hi << 16);
    }
  }
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_stmatrix_m8n8_b16(uint32_t a, int num, int trans, const uint32_t *v) {
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  for (int j = 0; j < num; ++j) {
    if (!trans) {
      const uint32_t row = __cupbop_shfl32(a, 8 * j + g);
      *(volatile uint32_t *)(__cupbop_smem_ptr(row) + 4 * t) = v[j];
    } else {
      const uint32_t r0 = __cupbop_shfl32(a, 8 * j + 2 * t), r1 = __cupbop_shfl32(a, 8 * j + 2 * t + 1);
      *(volatile uint16_t *)(__cupbop_smem_ptr(r0) + 2 * g) = (uint16_t)v[j];
      *(volatile uint16_t *)(__cupbop_smem_ptr(r1) + 2 * g) = (uint16_t)(v[j] >> 16);
    }
  }
}
// 16-lane sub-pass form (S = 2): st[pass] holds each lane's address, out / v[4 * pass + j] the registers of logical lane
// L = h + 16 pass (replaceLdStMatrixStaged). Matrix j's row r comes from logical lane 8j + r: hardware lane 8(j&1) + r of
// slot j>>1. Runs once per CUDA warp on all 16 hardware lanes, num and trans are constants after inlining.
extern "C" __attribute__((always_inline, convergent)) void __cupbop_ldmatrix_m8n8_b16_glue16(const uint32_t *st, int num, int trans, uint32_t *out) {
  const int h = vx_thread_id(), t = h & 3;
  for (int j = 0; j < num; ++j) {
    const uint32_t as = st[j >> 1];
    const int base = 8 * (j & 1);
    if (!trans) {
      for (int p = 0; p < 2; ++p) {
        const uint32_t row = (uint32_t)vx_shfl_idx((size_t)as, base + (h >> 2) + 4 * p, 15, 0);
        out[4 * p + j] = *(volatile uint32_t *)(__cupbop_smem_ptr(row) + 4 * t);
      }
    } else {
      const uint32_t r0 = (uint32_t)vx_shfl_idx((size_t)as, base + 2 * t, 15, 0), r1 = (uint32_t)vx_shfl_idx((size_t)as, base + 2 * t + 1, 15, 0);
      for (int p = 0; p < 2; ++p) {
        const int g = (h >> 2) + 4 * p;
        const uint32_t lo = *(volatile uint16_t *)(__cupbop_smem_ptr(r0) + 2 * g), hi = *(volatile uint16_t *)(__cupbop_smem_ptr(r1) + 2 * g);
        out[4 * p + j] = lo | (hi << 16);
      }
    }
  }
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_stmatrix_m8n8_b16_glue16(const uint32_t *st, int num, int trans, const uint32_t *v) {
  const int h = vx_thread_id(), t = h & 3;
  for (int j = 0; j < num; ++j) {
    const uint32_t as = st[j >> 1];
    const int base = 8 * (j & 1);
    if (!trans) {
      for (int p = 0; p < 2; ++p) {
        const uint32_t row = (uint32_t)vx_shfl_idx((size_t)as, base + (h >> 2) + 4 * p, 15, 0);
        *(volatile uint32_t *)(__cupbop_smem_ptr(row) + 4 * t) = v[4 * p + j];
      }
    } else {
      const uint32_t r0 = (uint32_t)vx_shfl_idx((size_t)as, base + 2 * t, 15, 0), r1 = (uint32_t)vx_shfl_idx((size_t)as, base + 2 * t + 1, 15, 0);
      for (int p = 0; p < 2; ++p) {
        const int g = (h >> 2) + 4 * p;
        *(volatile uint16_t *)(__cupbop_smem_ptr(r0) + 2 * g) = (uint16_t)v[4 * p + j];
        *(volatile uint16_t *)(__cupbop_smem_ptr(r1) + 2 * g) = (uint16_t)(v[4 * p + j] >> 16);
      }
    }
  }
}


// ---- redux.sync.<op>.b32 v, membermask (sm_80+): reduction over the mask's lanes (index shuffles, any mask) ----------
// op: 0 add, 1 umin, 2 umax, 3 min (s32), 4 max (s32), 5 and, 6 or, 7 xor
extern "C" __attribute__((always_inline, convergent)) uint32_t __cupbop_redux_sync(uint32_t v, uint32_t mask, int op) {
  uint32_t r = (op == 1 || op == 5) ? 0xffffffffu : (op == 3) ? 0x7fffffffu : (op == 4) ? 0x80000000u : 0u;
  for (int l = 0; l < 32; ++l) {
    const uint32_t x = __cupbop_shfl32(v, l);
    if (!((mask >> l) & 1u)) continue;
    switch (op) {
      case 0: r += x; break;
      case 1: r = x < r ? x : r; break;
      case 2: r = x > r ? x : r; break;
      case 3: r = (int32_t)x < (int32_t)r ? x : r; break;
      case 4: r = (int32_t)x > (int32_t)r ? x : r; break;
      case 5: r &= x; break;
      case 6: r |= x; break;
      default: r ^= x; break;
    }
  }
  return r;
}

// ---- fused mma.sync groups (kernelTranslator CUPBOP_MMA_FUSE=n|k|nk, fuse_mma_sync_groups in tool.cpp) --------------
// The NT=32 WMMA tile is m16n16k32 (fp16 elements); one PTX m16n8k16 op fills a quarter of it, m16n8k8 an eighth, and
// the rest is zero padding. The translator proves a group of mma.sync ops of one form in one basic block legal to
// run as one WMMA:
//   NN n-halves (1|2): ops with the same A operands and independent accumulators -> tile columns 0..7 / 8..15
//   L k-steps (KPS*L <= 4 k-blocks of 8 elements): a chain D_s = mma(A_s, B_s, D_{s-1}) -> tile k-blocks in order
// Arguments (arrays): a[L][nA] (PTX order a0.. of step s), b[NN][L][nB], c[NN][nC], d[NN][nC]; nA = 2*KPS, nB = KPS,
// nC = 4 (f32 accumulators) or 2 (packed f16x2 accumulators). Tile k-block j = KPS*s + q of step s: A regs j (rows g:
// PTX a[2q]) and 4+j (rows g+8: a[2q+1]), B reg 2j+u (n-half u: PTX b[q]), cf. __cupbop_mma_m16n8k16_tcu_impl;
// accumulator n-half u: Vortex regs 2u, 2u+1 (rows g) and 4+2u, 5+2u (rows g+8), converted with the same shuffles
// as __cupbop_acc_nv_to_vx / __cupbop_acc_vx_to_nv.
// Numerics (SimX FEDP, fp32 accumulators): every micro-op adds one k-block's word products to its accumulator and the
// k-blocks run in order, so n-fusion is bit-exact, and k-fusion differs from the unfused ops only where an all-zero
// padded k-block would have turned a -0 accumulator into +0. f16 accumulators: k-fusion drops the intermediate f16
// rounding between the steps (more precise, not bit-identical). _sw runs the unfused software ops in sequence.
// Inlining: the symbols take arrays (the translator's allocas) and are always_inline, so the arrays become SSA values;
// they pass the operands as scalars to __cupbop_mmaf_impl_*, which the optimizer inlines or not by its cost model, as
// it does __cupbop_mma_m16n8k16_tcu_impl for the unfused ops (out of line, the arrays would sit in the kernel frame:
// per-lane stack traffic, lifted g12 s2 2.2x slower). -DCUPBOP_MMAF_INLINE (CUPBOP_VX_EXTRA_CFLAGS) forces inlining.
using __cupbop_mma_k16_fn = void (*)(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, float, float, float, float, float *);
using __cupbop_mma_k8_fn = void (*)(uint32_t, uint32_t, uint32_t, float, float, float, float, float *);
using __cupbop_mma_k16h_fn = void (*)(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t *);
using __cupbop_mma_k8h_fn = void (*)(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t *);
template <int NN, int L, __cupbop_mma_k16_fn F>
static inline void __cupbop_mmaf_seq_k16(const uint32_t *a, const uint32_t *b, const float *c, float *d) {
  for (int u = 0; u < NN; ++u) {
    float acc[4] = {c[4 * u], c[4 * u + 1], c[4 * u + 2], c[4 * u + 3]};
    for (int s = 0; s < L; ++s) {
      const uint32_t *as = a + 4 * s, *bs = b + 2 * (u * L + s);
      F(as[0], as[1], as[2], as[3], bs[0], bs[1], acc[0], acc[1], acc[2], acc[3], acc);
    }
    for (int i = 0; i < 4; ++i) d[4 * u + i] = acc[i];
  }
}
template <int NN, int L, __cupbop_mma_k8_fn F>
static inline void __cupbop_mmaf_seq_k8(const uint32_t *a, const uint32_t *b, const float *c, float *d) {
  for (int u = 0; u < NN; ++u) {
    float acc[4] = {c[4 * u], c[4 * u + 1], c[4 * u + 2], c[4 * u + 3]};
    for (int s = 0; s < L; ++s) F(a[2 * s], a[2 * s + 1], b[u * L + s], acc[0], acc[1], acc[2], acc[3], acc);
    for (int i = 0; i < 4; ++i) d[4 * u + i] = acc[i];
  }
}
template <int NN, int L, __cupbop_mma_k16h_fn F>
static inline void __cupbop_mmaf_seq_k16h(const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) {
  for (int u = 0; u < NN; ++u) {
    uint32_t acc[2] = {c[2 * u], c[2 * u + 1]};
    for (int s = 0; s < L; ++s) {
      const uint32_t *as = a + 4 * s, *bs = b + 2 * (u * L + s);
      F(as[0], as[1], as[2], as[3], bs[0], bs[1], acc[0], acc[1], acc);
    }
    d[2 * u] = acc[0]; d[2 * u + 1] = acc[1];
  }
}
template <int NN, int L, __cupbop_mma_k8h_fn F>
static inline void __cupbop_mmaf_seq_k8h(const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) {
  for (int u = 0; u < NN; ++u) {
    uint32_t acc[2] = {c[2 * u], c[2 * u + 1]};
    for (int s = 0; s < L; ++s) F(a[2 * s], a[2 * s + 1], b[u * L + s], acc[0], acc[1], acc);
    d[2 * u] = acc[0]; d[2 * u + 1] = acc[1];
  }
}
#if defined(CUPBOP_MMA_TCU_AVAILABLE) && VX_CFG_NUM_THREADS == 32
// PTX accumulator of n-half u -> Vortex regs 2u, 2u+1, 4+2u, 5+2u; the shuffles of __cupbop_acc_nv_to_vx (own always_inline
// copies, so that the unfused helpers' inlining is unchanged)
template <class CTX, int U>
static inline __attribute__((always_inline)) void __cupbop_mmaf_acc_in(const float *c, typename CTX::fragment_acc &fc) {
#ifdef CUPBOP_MMAF_NOSHFL // measurement only (wrong results): no accumulator layout change, the cost bound of keeping it
  fc.data[2 * U] = c[0]; fc.data[2 * U + 1] = c[1]; fc.data[4 + 2 * U] = c[2]; fc.data[5 + 2 * U] = c[3]; return;
#endif
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const int s0 = (g << 2) | (t >> 1), s1 = (g << 2) | ((t >> 1) + 2);
  const bool odd = t & 1;
  const float x0 = __cupbop_shflf(c[0], s0), x1 = __cupbop_shflf(c[1], s0);
  const float y0 = __cupbop_shflf(c[0], s1), y1 = __cupbop_shflf(c[1], s1);
  const float z0 = __cupbop_shflf(c[2], s0), z1 = __cupbop_shflf(c[3], s0);
  const float w0 = __cupbop_shflf(c[2], s1), w1 = __cupbop_shflf(c[3], s1);
  fc.data[2 * U] = odd ? x1 : x0; fc.data[2 * U + 1] = odd ? y1 : y0;
  fc.data[4 + 2 * U] = odd ? z1 : z0; fc.data[5 + 2 * U] = odd ? w1 : w0;
}
// Vortex regs of n-half u -> PTX d0..d3 (the shuffles of __cupbop_acc_vx_to_nv)
template <class CTX, int U>
static inline __attribute__((always_inline)) void __cupbop_mmaf_acc_out(const typename CTX::fragment_acc &fd, float *d) {
#ifdef CUPBOP_MMAF_NOSHFL
  d[0] = fd.data[2 * U]; d[1] = fd.data[2 * U + 1]; d[2] = fd.data[4 + 2 * U]; d[3] = fd.data[5 + 2 * U]; return;
#endif
  const int lane = vx_thread_id(), g = lane >> 2, t = lane & 3;
  const int u0 = (g << 2) | ((2 * t) & 3), u1 = u0 + 1;
  const bool hi = t >> 1;
  const float p0 = __cupbop_shflf(fd.data[2 * U], u0), p1 = __cupbop_shflf(fd.data[2 * U + 1], u0);
  const float q0 = __cupbop_shflf(fd.data[2 * U], u1), q1 = __cupbop_shflf(fd.data[2 * U + 1], u1);
  const float r0 = __cupbop_shflf(fd.data[4 + 2 * U], u0), r1 = __cupbop_shflf(fd.data[5 + 2 * U], u0);
  const float v0 = __cupbop_shflf(fd.data[4 + 2 * U], u1), v1 = __cupbop_shflf(fd.data[5 + 2 * U], u1);
  d[0] = hi ? p1 : p0; d[1] = hi ? q1 : q0; d[2] = hi ? r1 : r0; d[3] = hi ? v1 : v0;
}
template <class CTX, int KPS, int NN, int L>
static inline __attribute__((always_inline)) void __cupbop_mmaf_tcu_f32(const uint32_t *a, const uint32_t *b, const float *c, float *d) {
  static_assert((NN == 1 || NN == 2) && L >= 1 && KPS * L <= 4 && NN * L >= 2, "one WMMA tile: 2 n-halves x 4 k-blocks");
  constexpr int nA = 2 * KPS, nB = KPS;
  typename CTX::fragment_a fa; typename CTX::fragment_b fb; typename CTX::fragment_acc fc, fd;
#pragma unroll
  for (int r = 0; r < 8; ++r) { fa.data[r] = 0.f; fb.data[r] = 0.f; fc.data[r] = 0.f; }
#pragma unroll
  for (int s = 0; s < L; ++s)
#pragma unroll
    for (int q = 0; q < KPS; ++q) {
      const int j = KPS * s + q;
      fa.data[j] = __cupbop_u32_as_f32(a[s * nA + 2 * q]);
      fa.data[4 + j] = __cupbop_u32_as_f32(a[s * nA + 2 * q + 1]);
#pragma unroll
      for (int u = 0; u < NN; ++u) fb.data[2 * j + u] = __cupbop_u32_as_f32(b[(u * L + s) * nB + q]);
    }
  __cupbop_mmaf_acc_in<CTX, 0>(c, fc);
  if constexpr (NN == 2) __cupbop_mmaf_acc_in<CTX, 1>(c + 4, fc);
  CTX::mma_sync(fd, fa, fb, fc);
  __cupbop_mmaf_acc_out<CTX, 0>(fd, d);
  if constexpr (NN == 2) __cupbop_mmaf_acc_out<CTX, 1>(fd, d + 4);
}
template <class CTX, int KPS, int NN, int L>
static inline __attribute__((always_inline)) void __cupbop_mmaf_tcu_f16acc(const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) {
  float e[4 * NN], dd[4 * NN];
#pragma unroll
  for (int u = 0; u < NN; ++u) {
    e[4 * u] = __cupbop_f16_to_f32(c[2 * u]); e[4 * u + 1] = __cupbop_f16_to_f32(c[2 * u] >> 16);
    e[4 * u + 2] = __cupbop_f16_to_f32(c[2 * u + 1]); e[4 * u + 3] = __cupbop_f16_to_f32(c[2 * u + 1] >> 16);
  }
  __cupbop_mmaf_tcu_f32<CTX, KPS, NN, L>(a, b, e, dd);
#pragma unroll
  for (int u = 0; u < NN; ++u) {
    d[2 * u] = __cupbop_pack_f16x2_rne(dd[4 * u], dd[4 * u + 1]);
    d[2 * u + 1] = __cupbop_pack_f16x2_rne(dd[4 * u + 2], dd[4 * u + 3]);
  }
}
#if defined(CUPBOP_MMAF_INLINE)
#define CUPBOP_MMAF_IMPL_ATTR __attribute__((always_inline, convergent))
#else
#define CUPBOP_MMAF_IMPL_ATTR __attribute__((convergent))
#endif
static inline __attribute__((always_inline)) uint32_t __cupbop_mmaf_bits(uint32_t x) { return x; }
static inline __attribute__((always_inline)) uint32_t __cupbop_mmaf_bits(float x) { return __cupbop_f32_bits(x); }
// scalar boundary: w = A words, B words, C (f32 values or packed f16x2 words)
template <class CTX, int KPS, int NN, int L, class... W>
static inline CUPBOP_MMAF_IMPL_ATTR void __cupbop_mmaf_impl_f32(float *d, W... w) {
  constexpr int nA = L * 2 * KPS, nB = NN * L * KPS;
  static_assert(sizeof...(W) == nA + nB + 4 * NN, "operand count");
  const uint32_t u[] = {__cupbop_mmaf_bits(w)...};
  float c[4 * NN];
#pragma unroll
  for (int i = 0; i < 4 * NN; ++i) c[i] = __cupbop_bits_f32(u[nA + nB + i]);
  __cupbop_mmaf_tcu_f32<CTX, KPS, NN, L>(u, u + nA, c, d);
}
template <class CTX, int KPS, int NN, int L, class... W>
static inline CUPBOP_MMAF_IMPL_ATTR void __cupbop_mmaf_impl_f16acc(uint32_t *d, W... w) {
  constexpr int nA = L * 2 * KPS, nB = NN * L * KPS;
  static_assert(sizeof...(W) == nA + nB + 2 * NN, "operand count");
  const uint32_t u[] = {w...};
  __cupbop_mmaf_tcu_f16acc<CTX, KPS, NN, L>(u, u + nA, u + nA + nB, d);
}
template <class CTX, int KPS, int NN, int L, class ACCT, size_t... IA, size_t... IB, size_t... IC>
static inline __attribute__((always_inline)) void __cupbop_mmaf_unpack(const uint32_t *a, const uint32_t *b, const ACCT *c, ACCT *d,
                                                                      std::index_sequence<IA...>, std::index_sequence<IB...>, std::index_sequence<IC...>) {
  if constexpr (std::is_same<ACCT, float>::value) __cupbop_mmaf_impl_f32<CTX, KPS, NN, L>(d, a[IA]..., b[IB]..., c[IC]...);
  else __cupbop_mmaf_impl_f16acc<CTX, KPS, NN, L>(d, a[IA]..., b[IB]..., c[IC]...);
}
#if defined(CUPBOP_MMA_SW)
#define CUPBOP_MMAF_PICK(NAME) NAME##_sw
#else
#define CUPBOP_MMAF_PICK(NAME) NAME##_tcu
#endif
#define CUPBOP_MMAF_TCU(NAME, ACCT, IMPL, CTX, KPS, NN, L)                                                             \
  extern "C" __attribute__((always_inline, convergent)) void NAME##_tcu(const uint32_t *a, const uint32_t *b, const ACCT *c, ACCT *d) { \
    __cupbop_mmaf_unpack<CTX, KPS, NN, L, ACCT>(a, b, c, d, std::make_index_sequence<L * 2 * KPS>{},                   \
                                                std::make_index_sequence<NN * L * KPS>{},                             \
                                                std::make_index_sequence<NN * (std::is_same<ACCT, float>::value ? 4 : 2)>{}); \
  }
#else
#define CUPBOP_MMAF_PICK(NAME) NAME##_sw
#define CUPBOP_MMAF_TCU(NAME, ACCT, IMPL, CTX, KPS, NN, L)
#endif
// one symbol triple per group shape: NAME = __cupbop_mmaf_<geom>_<tag>_n<NN>k<L> {_sw, _tcu, dispatch}
#define CUPBOP_MMAF_DEF(NAME, ACCT, SEQ, SWFN, IMPL, CTX, KPS, NN, L)                                                   \
  extern "C" __attribute__((always_inline, convergent)) void NAME##_sw(const uint32_t *a, const uint32_t *b, const ACCT *c, ACCT *d) { \
    SEQ<NN, L, SWFN>(a, b, c, d);                                                                                     \
  }                                                                                                                   \
  CUPBOP_MMAF_TCU(NAME, ACCT, IMPL, CTX, KPS, NN, L)                                                                  \
  extern "C" __attribute__((always_inline, convergent)) void NAME(const uint32_t *a, const uint32_t *b, const ACCT *c, ACCT *d) { \
    CUPBOP_MMAF_PICK(NAME)(a, b, c, d);                                                                               \
  }
#define CUPBOP_MMAF_K16(TAG, ACCT, SEQ, IMPL, CTX)                                                                     \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k16_##TAG##_n2k1, ACCT, SEQ, __cupbop_mma_m16n8k16_##TAG##_sw, IMPL, CTX, 2, 2, 1) \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k16_##TAG##_n1k2, ACCT, SEQ, __cupbop_mma_m16n8k16_##TAG##_sw, IMPL, CTX, 2, 1, 2) \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k16_##TAG##_n2k2, ACCT, SEQ, __cupbop_mma_m16n8k16_##TAG##_sw, IMPL, CTX, 2, 2, 2)
#define CUPBOP_MMAF_K8(TAG, ACCT, SEQ, IMPL, CTX)                                                                      \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k8_##TAG##_n2k1, ACCT, SEQ, __cupbop_mma_m16n8k8_##TAG##_sw, IMPL, CTX, 1, 2, 1)  \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k8_##TAG##_n1k2, ACCT, SEQ, __cupbop_mma_m16n8k8_##TAG##_sw, IMPL, CTX, 1, 1, 2)  \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k8_##TAG##_n1k3, ACCT, SEQ, __cupbop_mma_m16n8k8_##TAG##_sw, IMPL, CTX, 1, 1, 3)  \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k8_##TAG##_n1k4, ACCT, SEQ, __cupbop_mma_m16n8k8_##TAG##_sw, IMPL, CTX, 1, 1, 4)  \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k8_##TAG##_n2k2, ACCT, SEQ, __cupbop_mma_m16n8k8_##TAG##_sw, IMPL, CTX, 1, 2, 2)  \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k8_##TAG##_n2k3, ACCT, SEQ, __cupbop_mma_m16n8k8_##TAG##_sw, IMPL, CTX, 1, 2, 3)  \
  CUPBOP_MMAF_DEF(__cupbop_mmaf_m16n8k8_##TAG##_n2k4, ACCT, SEQ, __cupbop_mma_m16n8k8_##TAG##_sw, IMPL, CTX, 1, 2, 4)
CUPBOP_MMAF_K16(f16f32, float, __cupbop_mmaf_seq_k16, __cupbop_mmaf_tcu_f32, tcu_ctx)
CUPBOP_MMAF_K16(bf16f32, float, __cupbop_mmaf_seq_k16, __cupbop_mmaf_tcu_f32, tcu_ctx_bf16)
CUPBOP_MMAF_K16(f16f16, uint32_t, __cupbop_mmaf_seq_k16h, __cupbop_mmaf_tcu_f16acc, tcu_ctx)
CUPBOP_MMAF_K8(f16f32, float, __cupbop_mmaf_seq_k8, __cupbop_mmaf_tcu_f32, tcu_ctx)
CUPBOP_MMAF_K8(bf16f32, float, __cupbop_mmaf_seq_k8, __cupbop_mmaf_tcu_f32, tcu_ctx_bf16)
CUPBOP_MMAF_K8(f16f16, uint32_t, __cupbop_mmaf_seq_k8h, __cupbop_mmaf_tcu_f16acc, tcu_ctx)
#undef CUPBOP_MMAF_K16
#undef CUPBOP_MMAF_K8
#undef CUPBOP_MMAF_DEF
#undef CUPBOP_MMAF_TCU
#undef CUPBOP_MMAF_PICK

// ---- NT=16 sub-pass form (S = 2): software glue --------------------------------------------------------------------
// The CUDA warp's 32 lanes are two passes of a 16-lane hardware warp. The translator stages every pass's registers in
// per-thread slots (replaceMmaStaged, replaceReduxStaged: A stride 4 words, B 2, C/D the form's register count) and every
// hardware lane runs the glue once per CUDA warp, for both logical lanes L = h + 16 pass. Same arithmetic as the 32-lane
// _sw helpers above; only the source of a lane's register differs: __cupbop_g16 reads word r of logical lane src, hardware
// lane src & 15, slot src >> 4. Any NT=16 build (no TCU needed). Numerics as the _sw helpers.
#if VX_CFG_NUM_THREADS == 16
static inline uint32_t __cupbop_g16(const uint32_t *st, int stride, int r, int src) {
  const uint32_t x0 = (uint32_t)vx_shfl_idx((size_t)st[r], src & 15, 15, 0), x1 = (uint32_t)vx_shfl_idx((size_t)st[stride + r], src & 15, 15, 0);
#ifdef CUPBOP_GLUE16_SWAP_PASSES // negative control of the tests only (wrong results)
  return (src >> 4) ? x0 : x1;
#endif
  return (src >> 4) ? x1 : x0;
}
// mma.sync m16n8kK: __cupbop_mma16n8_sw for the two logical lanes of this hardware lane
template <class EA, class EB, int KW, bool SAT>
static inline void __cupbop_mma16n8_sw16(const uint32_t *stA, const uint32_t *stB, const uint32_t *stC, uint32_t *stD) {
  static_assert(EA::is_int == EB::is_int && EA::n == EB::n, "mixed int/float operands");
  const int h = vx_thread_id();
  for (int p = 0; p < 2; ++p) {
    const int lane = h + 16 * p, g = lane >> 2, t = lane & 3;
    const int la = g << 2, lb0 = (2 * t) << 2, lb1 = (2 * t + 1) << 2;
    const uint32_t *C = stC + 4 * p;
    uint32_t *D = stD + 4 * p;
    if constexpr (EA::is_int) {
      int64_t s0 = (int32_t)C[0], s1 = (int32_t)C[1], s2 = (int32_t)C[2], s3 = (int32_t)C[3];
      uint32_t u0 = C[0], u1 = C[1], u2 = C[2], u3 = C[3];
      auto clamp = [](int64_t v) { return v > 2147483647LL ? 2147483647LL : (v < -2147483648LL ? -2147483648LL : v); };
      for (int kk = 0; kk < KW; ++kk) {
        // .satfinite: the hardware saturates after every 4 words of K (A100, experiments/nt16cov/cases/mma_forms), not only at the end
        if (SAT && kk == 4) { s0 = clamp(s0); s1 = clamp(s1); s2 = clamp(s2); s3 = clamp(s3); }
        const int q = kk & 3, hiA = kk < 4 ? 0 : 2, hiB = kk < 4 ? 0 : 1;
        const uint32_t xa = __cupbop_g16(stA, 4, hiA, la | q), ya = __cupbop_g16(stA, 4, hiA + 1, la | q);
        const uint32_t ub = __cupbop_g16(stB, 2, hiB, lb0 | q), vb = __cupbop_g16(stB, 2, hiB, lb1 | q);
        for (int i = 0; i < EA::n; ++i) {
          const int32_t ag = EA::get(xa, i), ag8 = EA::get(ya, i), b0 = EB::get(ub, i), b1 = EB::get(vb, i);
          if constexpr (SAT) { s0 += ag * b0; s1 += ag * b1; s2 += ag8 * b0; s3 += ag8 * b1; }
          else { u0 += (uint32_t)(ag * b0); u1 += (uint32_t)(ag * b1); u2 += (uint32_t)(ag8 * b0); u3 += (uint32_t)(ag8 * b1); }
        }
      }
      if constexpr (SAT) {
        D[0] = (uint32_t)(int32_t)clamp(s0); D[1] = (uint32_t)(int32_t)clamp(s1); D[2] = (uint32_t)(int32_t)clamp(s2); D[3] = (uint32_t)(int32_t)clamp(s3);
      } else {
        D[0] = u0; D[1] = u1; D[2] = u2; D[3] = u3;
      }
    } else {
      float d0 = __cupbop_bits_f32(C[0]), d1 = __cupbop_bits_f32(C[1]), d2 = __cupbop_bits_f32(C[2]), d3 = __cupbop_bits_f32(C[3]);
      for (int kk = 0; kk < KW; ++kk) {
        const int q = kk & 3, hiA = kk < 4 ? 0 : 2, hiB = kk < 4 ? 0 : 1;
        const uint32_t xa = __cupbop_g16(stA, 4, hiA, la | q), ya = __cupbop_g16(stA, 4, hiA + 1, la | q);
        const uint32_t ub = __cupbop_g16(stB, 2, hiB, lb0 | q), vb = __cupbop_g16(stB, 2, hiB, lb1 | q);
        for (int i = 0; i < EA::n; ++i) {
          const float ag = EA::get(xa, i), ag8 = EA::get(ya, i), b0 = EB::get(ub, i), b1 = EB::get(vb, i);
          d0 += ag * b0; d1 += ag * b1; d2 += ag8 * b0; d3 += ag8 * b1;
        }
      }
      D[0] = __cupbop_f32_bits(d0); D[1] = __cupbop_f32_bits(d1); D[2] = __cupbop_f32_bits(d2); D[3] = __cupbop_f32_bits(d3);
    }
  }
}
#define CUPBOP_GLUE16_SW(NAME, EA, EB, KW, SAT)                                                                          \
  extern "C" __attribute__((always_inline, convergent)) void NAME##_sw_glue16(const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) { \
    __cupbop_mma16n8_sw16<EA, EB, KW, SAT>(a, b, c, d);                                                                  \
  }
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k16_f16f32,  __cupbop_el_f16,  __cupbop_el_f16,  8, false)
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k8_f16f32,   __cupbop_el_f16,  __cupbop_el_f16,  4, false)
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k16_bf16f32, __cupbop_el_bf16, __cupbop_el_bf16, 8, false)
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k8_bf16f32,  __cupbop_el_bf16, __cupbop_el_bf16, 4, false)
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k8_tf32f32,  __cupbop_el_tf32, __cupbop_el_tf32, 8, false)
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k4_tf32f32,  __cupbop_el_tf32, __cupbop_el_tf32, 4, false)
#define CUPBOP_GLUE16_INT(GEOM, KW)                                                                                       \
  CUPBOP_GLUE16_SW(__cupbop_mma_##GEOM##_s8s32,      __cupbop_el_s8, __cupbop_el_s8, KW, false)                           \
  CUPBOP_GLUE16_SW(__cupbop_mma_##GEOM##_u8s32,      __cupbop_el_u8, __cupbop_el_u8, KW, false)                           \
  CUPBOP_GLUE16_SW(__cupbop_mma_##GEOM##_s8u8s32,    __cupbop_el_s8, __cupbop_el_u8, KW, false)                           \
  CUPBOP_GLUE16_SW(__cupbop_mma_##GEOM##_u8s8s32,    __cupbop_el_u8, __cupbop_el_s8, KW, false)                           \
  CUPBOP_GLUE16_SW(__cupbop_mma_##GEOM##_s8s32sat,   __cupbop_el_s8, __cupbop_el_s8, KW, true)                            \
  CUPBOP_GLUE16_SW(__cupbop_mma_##GEOM##_u8s32sat,   __cupbop_el_u8, __cupbop_el_u8, KW, true)                            \
  CUPBOP_GLUE16_SW(__cupbop_mma_##GEOM##_s8u8s32sat, __cupbop_el_s8, __cupbop_el_u8, KW, true)                            \
  CUPBOP_GLUE16_SW(__cupbop_mma_##GEOM##_u8s8s32sat, __cupbop_el_u8, __cupbop_el_s8, KW, true)
CUPBOP_GLUE16_INT(m16n8k32, 8)
CUPBOP_GLUE16_INT(m16n8k16, 4)
#undef CUPBOP_GLUE16_INT
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k32_e4m3f32,     __cupbop_el_e4m3, __cupbop_el_e4m3, 8, false)
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k32_e5m2f32,     __cupbop_el_e5m2, __cupbop_el_e5m2, 8, false)
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k32_e4m3e5m2f32, __cupbop_el_e4m3, __cupbop_el_e5m2, 8, false)
CUPBOP_GLUE16_SW(__cupbop_mma_m16n8k32_e5m2e4m3f32, __cupbop_el_e5m2, __cupbop_el_e4m3, 8, false)
#undef CUPBOP_GLUE16_SW
// f16 accumulators: c / d[2 * pass + i] = the two f16x2 registers, the model of the f32-accumulator helper (one rounding)
template <int KW>
static inline void __cupbop_mma16n8_f16acc_sw16(const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) {
  uint32_t fc[8], fd[8];
  for (int p = 0; p < 2; p++) {
    fc[4 * p + 0] = __cupbop_f32_bits(__cupbop_f16_to_f32(c[2 * p]));     fc[4 * p + 1] = __cupbop_f32_bits(__cupbop_f16_to_f32(c[2 * p] >> 16));
    fc[4 * p + 2] = __cupbop_f32_bits(__cupbop_f16_to_f32(c[2 * p + 1])); fc[4 * p + 3] = __cupbop_f32_bits(__cupbop_f16_to_f32(c[2 * p + 1] >> 16));
  }
  __cupbop_mma16n8_sw16<__cupbop_el_f16, __cupbop_el_f16, KW, false>(a, b, fc, fd);
  for (int p = 0; p < 2; p++) {
    d[2 * p] = __cupbop_pack_f16x2_rne(__cupbop_bits_f32(fd[4 * p]), __cupbop_bits_f32(fd[4 * p + 1]));
    d[2 * p + 1] = __cupbop_pack_f16x2_rne(__cupbop_bits_f32(fd[4 * p + 2]), __cupbop_bits_f32(fd[4 * p + 3]));
  }
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m16n8k16_f16f16_sw_glue16(const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) {
  __cupbop_mma16n8_f16acc_sw16<8>(a, b, c, d);
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m16n8k8_f16f16_sw_glue16(const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) {
  __cupbop_mma16n8_f16acc_sw16<4>(a, b, c, d);
}
// m8n8k4 f64 (DMMA.884): a double is two words of its slot (A word 0,1 of stride 4; B of stride 2; C/D two doubles)
static inline double __cupbop_g16_f64(const uint32_t *st, int stride, int src) {
  const uint64_t u = ((uint64_t)__cupbop_g16(st, stride, 1, src) << 32) | __cupbop_g16(st, stride, 0, src);
  double r; __builtin_memcpy(&r, &u, 8); return r;
}
extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m8n8k4_f64f64_sw_glue16(const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) {
  const int h = vx_thread_id();
  for (int p = 0; p < 2; ++p) {
    const int lane = h + 16 * p, g = lane >> 2, t = lane & 3;
    double acc[2];
    __builtin_memcpy(acc, c + 4 * p, 16);
    for (int k = 0; k < 4; ++k) {
      const double x = __cupbop_g16_f64(a, 4, (g << 2) | k);                // A[g][k]
      const double y0 = __cupbop_g16_f64(b, 2, ((2 * t) << 2) | k);         // B[k][2t]
      const double y1 = __cupbop_g16_f64(b, 2, ((2 * t + 1) << 2) | k);     // B[k][2t+1]
      acc[0] = __builtin_fma(x, y0, acc[0]); acc[1] = __builtin_fma(x, y1, acc[1]);
    }
    __builtin_memcpy(d + 4 * p, acc, 16);
  }
}
// m8n8k4 f16 -> f32 (Volta HMMA.884): __cupbop_mma_m8n8k4_f16f32_impl for both logical lanes; C/D 8 registers per pass
template <int A_ROW, int B_ROW>
static inline void __cupbop_mma884_sw16(const uint32_t *stA, const uint32_t *stB, const uint32_t *stC, uint32_t *stD) {
  const int h = vx_thread_id();
  for (int p = 0; p < 2; ++p) {
    const int l = h + 16 * p, q4 = l & 12, hi16 = l & 16, x = l & 1, y = l & 2;
    float A[2][4], B[4][4]; // A[j][k]: row x + 2j (+4hi); B[cc][k]: column 4 * (cc >> 1) + y + (cc & 1)
    if (A_ROW) {
      for (int j = 0; j < 2; ++j) {
        const int src = q4 + x + 2 * j + hi16;
        const uint32_t u0 = __cupbop_g16(stA, 4, 0, src), u1 = __cupbop_g16(stA, 4, 1, src);
        A[j][0] = __cupbop_f16_to_f32(u0); A[j][1] = __cupbop_f16_to_f32(u0 >> 16);
        A[j][2] = __cupbop_f16_to_f32(u1); A[j][3] = __cupbop_f16_to_f32(u1 >> 16);
      }
    } else {
      for (int k = 0; k < 4; ++k) {
        const int src = q4 + k + hi16;
        const uint32_t u0 = __cupbop_g16(stA, 4, 0, src), u1 = __cupbop_g16(stA, 4, 1, src);
        A[0][k] = __cupbop_f16_to_f32(x ? u0 >> 16 : u0); A[1][k] = __cupbop_f16_to_f32(x ? u1 >> 16 : u1);
      }
    }
    if (B_ROW) {
      for (int k = 0; k < 4; ++k)
        for (int hh = 0; hh < 2; ++hh) {
          const int src = q4 + k + 16 * hh;
          const uint32_t u0 = __cupbop_g16(stB, 2, 0, src), u1 = __cupbop_g16(stB, 2, 1, src), u = y ? u1 : u0;
          B[2 * hh][k] = __cupbop_f16_to_f32(u); B[2 * hh + 1][k] = __cupbop_f16_to_f32(u >> 16);
        }
    } else {
      for (int cc = 0; cc < 4; ++cc) {
        const int src = q4 + y + (cc & 1) + 16 * (cc >> 1);
        const uint32_t u0 = __cupbop_g16(stB, 2, 0, src), u1 = __cupbop_g16(stB, 2, 1, src);
        B[cc][0] = __cupbop_f16_to_f32(u0); B[cc][1] = __cupbop_f16_to_f32(u0 >> 16);
        B[cc][2] = __cupbop_f16_to_f32(u1); B[cc][3] = __cupbop_f16_to_f32(u1 >> 16);
      }
    }
    for (int i = 0; i < 8; ++i) {
      const int j = (i >> 1) & 1, cc = ((i >> 1) & 2) | (i & 1);
      float acc = __cupbop_bits_f32(stC[8 * p + i]);
      for (int k = 0; k < 4; ++k) acc = __builtin_fmaf(A[j][k], B[cc][k], acc);
      stD[8 * p + i] = __cupbop_f32_bits(acc);
    }
  }
}
#define CUPBOP_MMA884_GLUE16(LA, LB, AR, BR)                                                                             \
  extern "C" __attribute__((always_inline, convergent)) void __cupbop_mma_m8n8k4_f16f32_##LA##_##LB##_sw_glue16(       \
      const uint32_t *a, const uint32_t *b, const uint32_t *c, uint32_t *d) {                                            \
    __cupbop_mma884_sw16<AR, BR>(a, b, c, d);                                                                            \
  }
CUPBOP_MMA884_GLUE16(row, col, 1, 0)
CUPBOP_MMA884_GLUE16(row, row, 1, 1)
CUPBOP_MMA884_GLUE16(col, row, 0, 1)
CUPBOP_MMA884_GLUE16(col, col, 0, 0)
#undef CUPBOP_MMA884_GLUE16
// redux.sync: one result per pass, each from its lane's own mask (__cupbop_redux_sync)
extern "C" __attribute__((always_inline, convergent)) void __cupbop_redux_sync_glue16(const uint32_t *v, const uint32_t *mask, int op, uint32_t *out) {
  const uint32_t init = (op == 1 || op == 5) ? 0xffffffffu : (op == 3) ? 0x7fffffffu : (op == 4) ? 0x80000000u : 0u;
  uint32_t r[2] = {init, init};
  const uint32_t m[2] = {mask[0], mask[1]};
  for (int l = 0; l < 32; ++l) {
    const uint32_t x0 = (uint32_t)vx_shfl_idx((size_t)v[0], l & 15, 15, 0), x1 = (uint32_t)vx_shfl_idx((size_t)v[1], l & 15, 15, 0), x = (l >> 4) ? x1 : x0;
    for (int p = 0; p < 2; ++p) {
      uint32_t n;
      switch (op) {
        case 0: n = r[p] + x; break;
        case 1: n = x < r[p] ? x : r[p]; break;
        case 2: n = x > r[p] ? x : r[p]; break;
        case 3: n = (int32_t)x < (int32_t)r[p] ? x : r[p]; break;
        case 4: n = (int32_t)x > (int32_t)r[p] ? x : r[p]; break;
        case 5: n = r[p] & x; break;
        case 6: n = r[p] | x; break;
        default: n = r[p] ^ x; break;
      }
      r[p] = ((m[p] >> l) & 1u) ? n : r[p];
    }
  }
  out[0] = r[0]; out[1] = r[1];
}
#endif // NT=16 software glue

#endif // VX_CFG_NUM_THREADS (Vortex 3.0)
