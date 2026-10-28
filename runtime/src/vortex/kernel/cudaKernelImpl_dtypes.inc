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
#endif // VX_CFG_NUM_THREADS (Vortex 3.0)
