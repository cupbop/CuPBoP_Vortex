// SM100 instruction descriptor rules used by the translator for constants
// and by the issuing lane for descriptors supplied by the kernel.
#pragma once
namespace cupbop_tcgen05 {
enum class Kind : unsigned { F16, TF32, F8F6F4, I8, MXF8F6F4, MXF4, MXF4NVF4, LegacyI8 };
enum Feature : unsigned { Fp16 = 1, Tf32 = 2, Int8 = 4, Mx = 8, Fp8 = 16, Fp4 = 32, MxFp4 = 64, NvFp4 = 128 };

inline bool small_float(unsigned type) { return type <= 1 || (type >= 3 && type <= 5); }

inline const char *descriptor_error(unsigned bits, Kind kind, bool pair, bool sparse,
                                    bool tmem_a, unsigned vec, unsigned features) {
  if (kind == Kind::LegacyI8)
    return bits == (pair ? 0x104004a0u : 0x084004a0u) ? nullptr : "unsupported i8 MMA instruction descriptor";

  const unsigned a = (bits >> 7) & 7, b = (bits >> 10) & 7;
  const unsigned n = ((bits >> 17) & 63) * 8;
  if (vec) {
    const bool wide = kind == Kind::MXF8F6F4, nv = kind == Kind::MXF4NVF4;
    const unsigned sf = (bits >> 23) & 3, aid = (bits >> 29) & 3, bid = (bits >> 4) & 3;
    unsigned valid = (3u << 29) | (3u << 27) | (1u << 23) | (63u << 17) |
                     (3u << 13) | (7u << 7) | (7u << 10) | (3u << 4) | 4u;
    if (wide) valid |= 3u << 15;
    if ((bits & ~valid) || bool(bits & 4) != sparse)
      return "unsupported layout, K dimension or sparsity in SM100 block-scaled MMA descriptor";
    if (((bits >> 27) & 3) != (pair ? 2u : 1u) || !n || n > 256 || (pair && n % 16))
      return "unsupported M or N dimension for this block-scaled MMA CTA group";
    if ((aid % vec) || (bid % vec)) return "misaligned scale-factor byte selector";
    if (wide ? vec != 1 || sf != 1 || !small_float(a) || !small_float(b)
             : a != 1 || b != 1 || (vec == 4 && !nv) || (!sf && !(nv && vec == 4)))
      return "unsupported input format, scale format or vector length for this SM100 MMA kind";
    if (tmem_a && (bits & (1u << 15))) return "TMEM-source MX MMA requires K-major A";
    if (pair && wide && (bits & (1u << 16)) && n % 32)
      return "paired MN-major MXFP8 B requires N divisible by 32";
    const unsigned required = Mx | (wide ? Fp8 : Fp4 | (sf ? MxFp4 : NvFp4));
    return (features & required) == required ? nullptr : "block-scaled MMA input type disabled in the Vortex target configuration";
  }

  const bool half = kind == Kind::F16, fp8 = kind == Kind::F8F6F4, tf32 = kind == Kind::TF32;
  unsigned allowed = tf32 ? (15u << 13) :
      (fp8 ? 0x1f80 : 0x480) | (3u << 15) | ((half || fp8) ? 3u << 13 : 0);
  if (sparse && (half || tf32)) allowed |= 1u;
  const unsigned required = (tf32 ? 0x910u : (half || fp8) ? 0x10u : 0x20u) | (sparse ? 4u : 0u);
  const unsigned step = pair && !half && !tf32 && (!fp8 || (bits & (1u << 16))) ? 32 : 16;
  if ((bits & ~((63u << 17) | allowed)) != ((pair ? 0x10000000u : 0x08000000u) | required) ||
      n < step || n > 256 || n % step)
    return "unsupported column MMA instruction descriptor";
  if (fp8 && (!small_float(a) || !small_float(b))) return "invalid FP8/FP6/FP4 MMA input type";
  if (tmem_a && (bits & (1u << 15))) return "TMEM-source MMA requires K-major A";
  if (tf32) return (features & Tf32) ? nullptr : "TF32 MMA requires -DVX_CFG_TCU_TF32_ENABLE";
  if (half && a != b) return (features & Tf32) ? nullptr : "mixed F16/BF16 inputs require TF32 for lossless widening";
  return (features & ((half || fp8) ? Fp16 : Int8)) ? nullptr : "column MMA input type disabled in the Vortex target configuration";
}
} // namespace cupbop_tcgen05
