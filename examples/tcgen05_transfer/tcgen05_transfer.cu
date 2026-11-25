#include "../tcgen05_test.h"
#include <vector>

// PTX fragment figures 187-189. Use unique values for each row, column,
// register and issuing lane so a symmetric mistake in ld and st is visible.
__global__ void transfer(unsigned *out) {
  __shared__ unsigned slot;
  unsigned tid = threadIdx.x, warp = tid / 32;
  if (!warp)
    asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0], 128;"
                 :: "r"(smem_u32(&slot)) : "memory");
  __syncthreads();
  tcgen_after_sync();
  unsigned addr = slot + ((32 * warp) << 16);
  for (unsigned col = 0; col < 32; col += 4) {
    unsigned x = 1000 * tid + col;
    asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0], {%1,%2,%3,%4};"
                 :: "r"(addr + col), "r"(x), "r"(x+1), "r"(x+2), "r"(x+3) : "memory");
  }
  asm volatile("tcgen05.wait::st.sync.aligned;" ::: "memory");
  unsigned half = addr + ((warp % 2) << 20);
  unsigned *dst = out + tid * 50;
  unsigned a, b, c, d, e, f, g, h;
  asm volatile("tcgen05.ld.sync.aligned.16x64b.x2.b32 {%0,%1}, [%2]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a), "=r"(b) : "r"(half + 4) : "memory");
  dst[0] = a; dst[1] = b;
  asm volatile("tcgen05.ld.sync.aligned.16x128b.x2.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a), "=r"(b), "=r"(c), "=r"(d) : "r"(half + 8) : "memory");
  dst[2] = a; dst[3] = b; dst[4] = c; dst[5] = d;
  asm volatile("tcgen05.ld.sync.aligned.16x256b.x2.b32 {%0,%1,%2,%3,%4,%5,%6,%7}, [%8]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a), "=r"(b), "=r"(c), "=r"(d), "=r"(e), "=r"(f), "=r"(g), "=r"(h)
               : "r"(half + 16) : "memory");
  dst[6] = a; dst[7] = b; dst[8] = c; dst[9] = d;
  dst[10] = e; dst[11] = f; dst[12] = g; dst[13] = h;
  // Threads 16..31 gather columns 4,5 in the upper half of this warp.
  asm volatile("tcgen05.ld.sync.aligned.16x32bx2.x2.b32 {%0,%1}, [%2], 1048580; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a), "=r"(b) : "r"(addr) : "memory");
  dst[14] = a; dst[15] = b;
  unsigned v = 200000 + tid * 16;
  asm volatile("tcgen05.st.sync.aligned.16x64b.x1.b32 [%0], {%1};"
               :: "r"(half), "r"(v) : "memory");
  asm volatile("tcgen05.st.sync.aligned.16x64b.x2.b32 [%0], {%1,%2};"
               :: "r"(half + 4), "r"(v), "r"(v+1) : "memory");
  asm volatile("tcgen05.st.sync.aligned.16x128b.x2.b32 [%0], {%1,%2,%3,%4};"
               :: "r"(half + 8), "r"(v), "r"(v+1), "r"(v+2), "r"(v+3) : "memory");
  asm volatile("tcgen05.st.sync.aligned.16x256b.x2.b32 [%0], {%1,%2,%3,%4,%5,%6,%7,%8}; tcgen05.wait::st.sync.aligned;"
               :: "r"(half + 16), "r"(v), "r"(v+1), "r"(v+2), "r"(v+3),
                  "r"(v+4), "r"(v+5), "r"(v+6), "r"(v+7) : "memory");
  for (unsigned col = 0; col < 32; col += 4) {
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                 : "=r"(a), "=r"(b), "=r"(c), "=r"(d) : "r"(addr + col) : "memory");
    dst[16+col] = a; dst[17+col] = b; dst[18+col] = c; dst[19+col] = d;
  }
  asm volatile("tcgen05.st.sync.aligned.16x32bx2.x2.b32 [%0], 1048580, {%1,%2}; tcgen05.wait::st.sync.aligned;"
               :: "r"(addr), "r"(v+8), "r"(v+9) : "memory");
  unsigned upper0, upper1;
  asm volatile("tcgen05.ld.sync.aligned.32x32b.x2.b32 {%0,%1}, [%2]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a), "=r"(b) : "r"(addr) : "memory");
  asm volatile("tcgen05.ld.sync.aligned.32x32b.x2.b32 {%0,%1}, [%2]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(upper0), "=r"(upper1) : "r"(addr + 4) : "memory");
  dst[48] = tid % 32 < 16 ? a : upper0;
  dst[49] = tid % 32 < 16 ? b : upper1;
  tcgen_before_sync();
  __syncthreads();
  if (!warp)
    asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0,128;" :: "r"(slot) : "memory");
}

int main() {
  std::vector<unsigned> out(128 * 50);
  unsigned *device;
  ASYNC_CHECK(cudaMalloc(&device, out.size() * sizeof(unsigned)));
  transfer<<<1,128>>>(device);
  ASYNC_CHECK(cudaMemcpy(out.data(), device, out.size() * sizeof(unsigned), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device));
  unsigned errors = 0;
  for (unsigned tid = 0; tid < 128; ++tid) {
    const unsigned lane = tid % 32, base = tid - lane, firstRow = ((tid / 32) % 2) * 16;
    for (unsigned reg = 0; reg < 14; ++reg) {
      unsigned row = firstRow + lane / 4, col;
      if (reg < 2) {
        row += (lane % 2) * 8;
        col = 4 + reg * 2 + (lane % 4) / 2;
      } else if (reg < 6) {
        unsigned i = reg - 2;
        row += (i % 2) * 8;
        col = 8 + (i / 2) * 4 + lane % 4;
      } else {
        unsigned i = reg - 6;
        row += ((i / 2) % 2) * 8;
        col = 16 + (i / 4) * 8 + (lane % 4) * 2 + i % 2;
      }
      unsigned actual = out[tid * 50 + reg], expected = (base + row) * 1000 + col;
      if (actual != expected && ++errors <= 8)
        printf("ld thread=%u reg=%u got=%u expected=%u\n", tid, reg, actual, expected);
    }
    for (unsigned r = 0; r < 2; ++r) {
      errors += out[tid * 50 + 14 + r] != tid * 1000 + (lane < 16 ? 0 : 4) + r;
      errors += out[tid * 50 + 48 + r] != 200000 + tid * 16 + 8 + r;
    }
    for (unsigned col = 0; col < 32; ++col) {
      unsigned expected = tid * 1000 + col;
      if (lane / 16 == firstRow / 16 && (col < 2 || col >= 4)) {
        unsigned src = base + lane % 8 * 4, reg;
        if (col < 8) {
          src += lane % 16 / 8 + (col % 2) * 2;
          reg = (col % 4) / 2;
        } else if (col < 16) {
          src += col % 4;
          reg = ((col - 8) / 4) * 2 + lane % 16 / 8;
        } else {
          src += (col % 8) / 2;
          reg = ((col - 16) / 8) * 4 + (lane % 16 / 8) * 2 + col % 2;
        }
        expected = 200000 + src * 16 + reg;
      }
      unsigned actual = out[tid * 50 + 16 + col];
      if (actual != expected && ++errors <= 8)
        printf("st row=%u col=%u got=%u expected=%u\n", tid, col, actual, expected);
    }
  }
  printf("TMEM transfer: %u mismatches in %u values\n", errors, 128 * 50);
  return errors != 0;
}
