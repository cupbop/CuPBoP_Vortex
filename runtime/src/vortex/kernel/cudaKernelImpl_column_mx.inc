// CUDA stores four replicated 32-lane subpartitions. In each, successive
// groups of 32 logical rows/columns occupy successive TMEM columns. The
// instruction selects a byte within each word as its first scale factor.
#ifdef VX_CFG_TCU_MX_ENABLE
static unsigned column_scale_byte(unsigned addr, unsigned row, unsigned selector) {
  return column_meta_word((addr & 65535) + row / 32, (addr >> 16) + row % 32) >> (selector * 8) & 255;
}

template <typename Input>
static unsigned column_mx_element(const TcgenOperand &src, unsigned row, unsigned k, unsigned desc,
                                  bool is_b, int tmem_col = -1) {
  unsigned sign = (desc >> (13 + is_b)) & 1;
  if constexpr (Input::bits == 4) {
    if (tmem_col >= 0)
      return ((column_meta_word(tmem_col + k / 8, row) >> (4 * (k % 8))) & 15) ^ (sign << 3);
    unsigned byte = column_element<uint8_t>(src, row, k / 2, false);
    return ((byte >> (4 * (k % 2))) & 15) ^ (sign << 3);
  } else {
    unsigned type = desc >> (is_b ? 10 : 7) & 7;
    unsigned raw = tmem_col >= 0 ? column_tmem_small_float(tmem_col, row, k, type)
                                 : column_small_float(src, row, k, type, (desc >> (15 + is_b)) & 1);
    if (type > 1) {
      raw = column_low_to_e4m3(raw, type);
      if constexpr (Input::id == tensor::mxbf8::id)
        raw = __cupbop_f32_to_f16_rne(__cupbop_e4m3_to_f32(raw)) >> 8;
    }
    return raw ^ (sign << 7);
  }
}

template <typename Input>
static void column_mx_tile(unsigned col, TcgenOperand a, TcgenOperand b, TcgenOperand peer_b, bool pair,
                           unsigned desc, unsigned sfa, unsigned sfb, unsigned use_d, uint8_t *scratch,
                           unsigned vec, unsigned meta, unsigned workspace, int aCol) {
  using G = tensor::wgmma_config_t<32, Input, tensor::fp32>;
  constexpr unsigned stepBytes = G::fedpK * 4, stepElements = stepBytes * (8 / Input::bits);
  constexpr unsigned sfCount = tensor::mx_max_fedp_sf(G::fedpK);
  constexpr unsigned packed = 8 / Input::bits;
  const unsigned warp = csr_read_nv(VX_CSR_CTA_RANK);
  scratch += warp * (128 + 256) * 32;
  uint8_t *astage = scratch, *bstage = scratch + 4096;
  constexpr uintptr_t bankRow = VX_CFG_LMEM_NUM_BANKS * (VX_CFG_XLEN / 8);
  auto *image =
      reinterpret_cast<uint32_t *>((uintptr_t(scratch + 8192) + bankRow - 1) & ~(bankRow - 1));
  const unsigned aOffset = tmcol::smem_offset(astage), bOffset = tmcol::smem_offset(bstage);
  if (uint64_t(bOffset) + 16 * stepBytes > (1u << tensor::smem_desc_offset_bits))
    cupbop_async_fail("MX MMA scratch exceeds descriptor range", aOffset, bOffset);
  const unsigned n = (desc >> 17 & 63) * 8;
  const bool sparse = desc & 4;
  const unsigned cudaK = (Input::bits == 4 ? 64 : 32) * (sparse ? 2 : 1);
  const unsigned scaleK = cudaK / vec;
  // Keep a native job within one CUDA scale block, even when its scale
  // vector has a finer granularity than the Vortex input format.
  const unsigned step = stepElements < scaleK ? stepElements : scaleK;
  const bool direct =
      aCol >= 0 && !sparse && step == stepElements && (Input::bits == 4 || ((desc >> 7) & 7) <= 1);
  if (direct && (desc & (1u << 13)))
    desc ^= (1u << 13) | (1u << 14);
  static_assert(sfCount <= 16 && stepBytes * 64 <= 4096, "unsupported MX column geometry");
  // tc.cp streams groups of four columns, one word for each physical lane
  // and column. A row scales occupy group 0. B column scales occupy
  // the second M step in each block of group 1 (vx_tmem.h MX layout).
  auto put = [&](unsigned lane, unsigned c, unsigned byte, unsigned sf) {
    image[(c / 4) * 64 * 4 + lane * 4 + c % 4] |= sf << (8 * byte);
  };
  // In a CUDA subpartition each row half is 16 lanes. Vortex places four
  // such half-warps consecutively in a 64-row physical panel.
  for (unsigned k0 = 0; k0 < cudaK; k0 += step) {
    unsigned sfIndex = k0 / scaleK;
    for (unsigned panel = 0; panel < 2; ++panel) {
      for (unsigned lane = 0; !direct && lane < 64; ++lane) {
        unsigned row = lane / 16 * 32 + panel * 16 + lane % 16;
        for (unsigned i = 0; i < stepBytes; ++i) {
          unsigned byte = 0;
          for (unsigned f = 0; f < packed; ++f) {
            unsigned x = i * packed + f, k = k0 + x;
            if (x >= step)
              continue;
            if (sparse) {
              // FP4 block-scaled uses 4:8 pairwise sparsity; MXFP8 uses 2:4.
              constexpr unsigned unit = Input::bits == 4 ? 2 : 1;
              unsigned groupK = k / unit, sel = column_sparse_indices(meta, row, groupK, 0x20000);
              unsigned pos = groupK % 4;
              if (pos != (sel & 3) && pos != (sel >> 2))
                continue;
              k = (groupK / 4 * 2 + (pos == (sel >> 2))) * unit + k % unit;
            }
            byte |= column_mx_element<Input>(a, row, k, desc, false, aCol) << (f * Input::bits);
          }
          astage[lane * stepBytes + i] = byte;
        }
      }
      unsigned tileA = 0;
      if (direct) {
        unsigned word = unsigned(aCol) + k0 / (32 / Input::bits);
        tileA = column_panel(word, panel) + word % 16;
      } else if (aCol >= 0) {
        // Convert padded CUDA input to the native packed format, then
        // stage it group-by-group in dedicated columns of this same run.
        constexpr unsigned cols = G::fedpK;
        for (unsigned lane = 0; lane < 64; ++lane)
          for (unsigned w = 0; w < cols; ++w) {
            uint32_t word;
            __builtin_memcpy(&word, astage + lane * stepBytes + w * 4, sizeof(word));
            image[(w / 4 * 64 + lane) * 4 + w % 4] = word;
          }
        vx_fence();
        tileA = workspace + 8;
        tmcol::cp(tileA, image, cols);
        column_wait(warp);
      }
      for (unsigned tile = 0; tile < n; tile += 16) {
        unsigned columns = n - tile < 16 ? n - tile : 16;
        __builtin_memset(image, 0, 64 * 8 * sizeof(*image));
        for (unsigned l = 0; l < 64; ++l) {
          unsigned row = l / 16 * 32 + panel * 16 + l % 16;
          unsigned scale = column_scale_byte(sfa, row, ((desc >> 29) & 3) + sfIndex);
          for (unsigned s = 0; s < sfCount; ++s)
            put(l, s / 4, s % 4, scale);
        }
        for (unsigned j = 0; j < columns; ++j) {
          unsigned out = tile + j, row = pair ? out % (n / 2) : out;
          const auto &src = pair && out >= n / 2 ? peer_b : b;
          unsigned scale = column_scale_byte(sfb, out, ((desc >> 4) & 3) + sfIndex);
          for (unsigned s = 0; s < sfCount; ++s) {
            unsigned q = j * sfCount + s, r = q / 128, w = q % 128 / 4;
            put((r % 4) * 16 + 8 + w / 4, (1 + r / 4) * 4 + w % 4, q % 4, scale);
          }
          for (unsigned i = 0; i < stepBytes; ++i) {
            unsigned byte = 0;
            for (unsigned f = 0; f < packed; ++f) {
              unsigned x = i * packed + f;
              if (x >= step)
                continue;
              unsigned v = column_mx_element<Input>(src, row, k0 + x, desc, true);
              if (sparse && Input::bits == 8 &&
                  (Input::id == tensor::mxbf8::id ? ((v & 124) == 124) : ((v & 127) == 127)))
                cupbop_async_fail("expanded sparse MX MMA requires finite B", out, k0 + x);
              byte |= v << (f * Input::bits);
            }
            bstage[j * stepBytes + i] = byte;
          }
        }
        vx_fence();
        tmcol::cp(workspace, image, 8);
        auto idesc = tmcol::make_idesc<Input>(columns / tmcol::frag_cols(), column_panel(col + tile, panel),
                                              !use_d && !k0, false, workspace);
        auto bdesc = tmcol::smem_desc(bOffset, stepBytes);
        if (aCol >= 0)
          tmcol::mma(idesc, tmcol::tmem_col{tileA}, bdesc);
        else
          tmcol::mma(idesc, tmcol::smem_desc(aOffset, stepBytes), bdesc);
        column_wait(warp);
      }
    }
  }
  column_meta_invalidate(col, n);
}

extern "C" void __cupbop_column_mma_mx(unsigned addr, uint64_t ad, uint64_t bd, unsigned desc,
                                       unsigned sfa, unsigned sfb, unsigned use_d, uint8_t *scratch,
                                       unsigned vec, unsigned meta, unsigned tmemA) {
  const bool pair = ((desc >> 27) & 3) == 2;
  const unsigned n = (desc >> 17 & 63) * 8;
  unsigned warp = csr_read_nv(VX_CSR_CTA_RANK);
  if (vx_thread_id())
    cupbop_async_fail("block-scaled MMA must be issued by lane zero", addr, vx_thread_id());
  if (warp >= 4 || vx_num_barriers() < 5)
    cupbop_async_fail("block-scaled MMA issuer lacks a reserved completion barrier", warp,
                      vx_num_barriers());
  int workspace = column_sparse_side();
  if (workspace < 0)
    cupbop_async_fail("MX MMA needs an addressable TMEM scale workspace", addr, n);
  for (unsigned side = 0; side < (pair ? 2u : 1u); ++side) {
    auto a = tmemA ? TcgenOperand{} : tcgen_operand(ad), b = tcgen_operand(bd), peer_b = b;
    auto physical = [&](unsigned taddr, unsigned span) {
      unsigned base = taddr & 65535;
      if (pair) {
        auto &run = pairRun(side);
        unsigned offset = base - columnPairTag;
        if (offset >= run.size || span > run.size - offset)
          cupbop_async_fail("paired MX address outside TMEM run", taddr, span);
        base = run.base + offset;
      }
      if (base + span > VX_CFG_TCU_TMEM_COLS / 2)
        cupbop_async_fail("MX address outside TMEM", taddr, span);
      return (taddr & 0xffff0000u) | base;
    };
    unsigned col = physical(addr, n), sa = physical(sfa, 4), sb = physical(sfb, (n + 31) / 32);
    unsigned metadata = (desc & 4) ? physical(meta, 2) : 0;
    int aCol = -1;
    if (tmemA) {
      unsigned source = physical(unsigned(ad), 8);
      if ((source & 3) || source >> 16 || (source < col + n && col < source + 8))
        cupbop_async_fail("invalid MX TMEM-source address", source, col);
      aCol = int(source);
    }
    if ((col & 15) || col >> 16)
      cupbop_async_fail("unaligned MX destination", col, n);
    if (pair) {
      if (!tmemA)
        a.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(a.start), side));
      peer_b.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(b.start), 1));
      b.start = uintptr_t(__cupbop_cluster_map(reinterpret_cast<void *>(b.start), 0));
    }
#define MX_TILE(T)                                                                                     \
  column_mx_tile<tensor::T>(col, a, b, peer_b, pair, desc, sa, sb, use_d, scratch, vec, metadata,      \
                            workspace, aCol)
    if (vec != 1) {
      if (desc & (1u << 23))
        MX_TILE(mxfp4);
      else
        MX_TILE(nvfp4);
    } else if (((desc >> 7) & 7) == 1 || ((desc >> 10) & 7) == 1)
      MX_TILE(mxbf8);
    else
      MX_TILE(mxfp8);
#undef MX_TILE
  }
  column_sparse_release(workspace);
}
#endif
