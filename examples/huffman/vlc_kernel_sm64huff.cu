#ifndef _VLC_SM64HUFF_KERNEL_H_
#define _VLC_SM64HUFF_KERNEL_H_

#include "pabio_kernels_v2.cu"
#include "parameters.h"
#include <cstdio>

#ifdef SMATOMICS

/* HUFFMAN-FRIENDLY PAVLE
   CHARACTERISTICS:
   1. CACHE CW_LUT INTO SM, LOAD AS 2 INT ARRAYS
   2. PARALLEL PREFIX SUM
   3. PARALLEL BIT I/O USING SHARED-MEMORY ATOMIC OPERATIONS (COMAPTIBLE WITH
   CUDA1.3+)

   NOTES & ASSUMPTIONS:
   -	HUFFMAN-CODING FRIENDLY, SUPPORTS CODEWORDS OF 2X SIZE OF ORIGINAL
   SYMBOLS (BYTES). -	NUMBER OF THREADS PER BLOCK IS 256; IF YOU WANT TO PLAY
   WITH DIFFERENT NUMBERS, THE CW CACHING SHOULD BE MODIFIED (SEE DPT* KERNELS)
   -	SM usage: 1x size of the input data (REUSE) + size of CWLUT
                TURN ON CACHING FOR HIGH ENTROPY DATA!
*/

__global__ static void
vlc_encode_kernel_sm64huff(unsigned int *data, const unsigned int *gm_codewords,
                           const unsigned int *gm_codewordlens,
#ifdef TESTING
                           unsigned int *cw32, unsigned int *cw32len,
                           unsigned int *cw32idx,
#endif
                           unsigned int *out, unsigned int *outidx) {

  unsigned int kn = blockIdx.x * blockDim.x + threadIdx.x;
  unsigned int k = threadIdx.x;
  unsigned int kc, startbit, wrbits;

  unsigned long long cw64 = 0;
  unsigned int val32, codewordlen = 0;
  unsigned char tmpbyte, tmpcwlen;
  unsigned int tmpcw32;

  __shared__ unsigned int sm[3072];
  __shared__ unsigned int kcmax;

#ifdef CACHECWLUT
  unsigned int *codewords = (unsigned int *)sm;
  unsigned int *codewordlens = (unsigned int *)(sm + NUM_SYMBOLS);
  unsigned int *as = (unsigned int *)(sm + 2 * NUM_SYMBOLS);

  /* Load the codewords and the original data*/
  codewords[k] = gm_codewords[k];
  codewordlens[k] = gm_codewordlens[k];
  val32 = data[kn];
  __syncthreads();
  for (unsigned int i = 0; i < 4; i++) {
    tmpbyte = (unsigned char)(val32 >> ((3 - i) * 8));
    tmpcw32 = codewords[tmpbyte];
    tmpcwlen = codewordlens[tmpbyte];
    cw64 = (cw64 << tmpcwlen) | tmpcw32;
    codewordlen += tmpcwlen;
  }
#else
  unsigned int *as = (unsigned int *)sm;
  val32 = data[kn];
  for (unsigned int i = 0; i < 4; i++) {
    tmpbyte = (unsigned char)(val32 >> ((3 - i) * 8));
    tmpcw32 = gm_codewords[tmpbyte];
    tmpcwlen = gm_codewordlens[tmpbyte];
    cw64 = (cw64 << tmpcwlen) | tmpcw32;
    codewordlen += tmpcwlen;
  }
#endif
  as[k] = codewordlen;
  __syncthreads();

  /* Prefix sum of codeword lengths (denoted in bits) [inplace implementation]
   */
  unsigned int offset = 1;

  /* Build the sum in place up the tree */
  for (unsigned int d = (blockDim.x) >> 1; d > 0; d >>= 1) {
    __syncthreads();
    if (k < d) {
      unsigned char ai = offset * (2 * k + 1) - 1;
      unsigned char bi = offset * (2 * k + 2) - 1;
      as[bi] += as[ai];
    }
    offset *= 2;
  }

  /* scan back down the tree */
  /* clear the last element */
  if (k == 0)
    as[blockDim.x - 1] = 0;

  // traverse down the tree building the scan in place
  for (unsigned int d = 1; d < blockDim.x; d *= 2) {
    offset >>= 1;
    __syncthreads();
    if (k < d) {
      unsigned char ai = offset * (2 * k + 1) - 1;
      unsigned char bi = offset * (2 * k + 2) - 1;
      unsigned int t = as[ai];
      as[ai] = as[bi];
      as[bi] += t;
    }
  }
  __syncthreads();

  if (k == blockDim.x - 1) {
    outidx[blockIdx.x] = as[k] + codewordlen;
    kcmax = (as[k] + codewordlen) / 32;
    // printf("kcmax: %d\n", kcmax);
  }

  /* Write the codes */
  kc = as[k] / 32;
  startbit = as[k] % 32;
  as[k] = 0U;
  __syncthreads();

  /* Part 1*/
  wrbits = codewordlen > (32 - startbit) ? (32 - startbit) : codewordlen;
  tmpcw32 = (unsigned int)(cw64 >> (codewordlen - wrbits));
  // if (wrbits == 32) as[kc] = tmpcw32;
  // //unnecessary overhead; increases number of branches else
  atomicOr(&as[kc], tmpcw32 << (32 - startbit -
                                wrbits)); // shift left in case it's shorter
                                          // then the available space
  codewordlen -= wrbits;

  /*Part 2*/
  if (codewordlen) {
    wrbits = codewordlen > 32 ? 32 : codewordlen;
    tmpcw32 =
        (unsigned int)(cw64 >> (codewordlen - wrbits)) & ((1 << wrbits) - 1);
    // if (wrbits == 32) as[kc+1] = tmpcw32;
    // else
    atomicOr(&as[kc + 1], tmpcw32 << (32 - wrbits));
    codewordlen -= wrbits;
  }

  /*Part 3*/
  if (codewordlen) {
    tmpcw32 = (unsigned int)(cw64 & ((1 << codewordlen) - 1));
    // if (wrbits == 32) as[kc+2] = tmpcw32;
    // else
    atomicOr(&as[kc + 2], tmpcw32 << (32 - codewordlen));
  }

  __syncthreads();

  if (k <= kcmax)
    out[kn] = as[k];
}
//////////////////////////////////////////////////////////////////////////////
#endif

#if defined(VORTEX_SCHE) && VORTEX_SCHE == 2
// SCHE_2 source workaround: parallel vlc_encode_kernel_sm64huff produces
// corruption in late dwords of some blocks (e.g., block 9 positions 70-73).
// Likely cause: prefix-sum in shared mem or cross-warp atomicOr to shared mem.
// This sequential single-thread-per-block fallback bypasses both — thread 0
// of each block does CPU-style bit-packing directly into out[]. Slow but
// correct. Each block writes to out[blockIdx.x*blockDim.x .. +outidx_words).
__global__ static void
vlc_encode_kernel_seq_per_block(unsigned int *data,
                                const unsigned int *gm_codewords,
                                const unsigned int *gm_codewordlens,
#ifdef TESTING
                                unsigned int *cw32, unsigned int *cw32len,
                                unsigned int *cw32idx,
#endif
                                unsigned int *out, unsigned int *outidx) {
  if (threadIdx.x != 0) return;
  unsigned int kn_base = blockIdx.x * blockDim.x;
  unsigned int *out_block = &out[kn_base];
  for (unsigned int i = 0; i < blockDim.x; i++) out_block[i] = 0;

  unsigned int startbit = 0;
  unsigned int as_idx = 0;
  for (unsigned int i = 0; i < blockDim.x; i++) {
    unsigned int val32 = data[kn_base + i];
    for (unsigned int j = 0; j < 4; j++) {
      unsigned char tmpbyte = (unsigned char)(val32 >> ((3 - j) * 8));
      unsigned int cw32_v = gm_codewords[tmpbyte];
      unsigned int cwlen = gm_codewordlens[tmpbyte];
      while (cwlen > 0) {
        unsigned int writebits = (32 - startbit < cwlen) ? 32 - startbit : cwlen;
        unsigned int mask32;
        if (cwlen == writebits)
          mask32 = (cw32_v & ((1u << cwlen) - 1)) << (32 - startbit - cwlen);
        else
          mask32 = cw32_v >> (cwlen - writebits);
        out_block[as_idx] |= mask32;
        cwlen -= writebits;
        startbit = (startbit + writebits) & 31;
        if (startbit == 0) as_idx++;
      }
    }
  }
  outidx[blockIdx.x] = as_idx * 32 + startbit;
}
#endif

#endif
