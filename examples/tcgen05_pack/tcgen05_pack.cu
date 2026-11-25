#include "../tcgen05_test.h"
#include <vector>

constexpr unsigned columns = 48, loads = 9, outputs = columns + loads;

__host__ __device__ static unsigned initial(unsigned row, unsigned col) {
  return 0xa5100000u + row * 128 + 3 * col + 1;
}
__host__ __device__ static unsigned source(unsigned lane, unsigned reg) {
  return ((0x8123u + 5 * lane + reg) << 16) | (0x3421u + 3 * lane + reg);
}

__global__ void pack(unsigned *out) {
  __shared__ unsigned slot;
  unsigned tid = threadIdx.x, warp = tid / 32;
  if (!warp)
    asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0], 128;"
                 :: "r"(smem_u32(&slot)) : "memory");
  __syncthreads();
  tcgen_after_sync();
  unsigned addr = slot + (32 * warp << 16);
  unsigned half = addr + ((warp & 1) << 20);
#pragma unroll
  for (unsigned col = 0; col < columns; col += 4) {
    asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0], {%1,%2,%3,%4};"
                 :: "r"(addr+col), "r"(initial(tid,col)), "r"(initial(tid,col+1)),
                    "r"(initial(tid,col+2)), "r"(initial(tid,col+3)) : "memory");
  }
  asm volatile("tcgen05.wait::st.sync.aligned;" ::: "memory");
  unsigned *dst = out + tid * outputs;
  unsigned a,b,c,d;
  asm volatile("tcgen05.ld.sync.aligned.32x32b.x1.pack::16b.b32 {%0}, [%1]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a) : "r"(addr+1) : "memory");
  dst[0] = a;
  asm volatile("tcgen05.ld.sync.aligned.16x32bx2.x1.pack::16b.b32 {%0}, [%1], 1048581; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a) : "r"(addr+1) : "memory");
  dst[1] = a;
  asm volatile("tcgen05.ld.sync.aligned.16x64b.x1.pack::16b.b32 {%0}, [%1]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a) : "r"(half+8) : "memory");
  dst[2] = a;
  asm volatile("tcgen05.ld.sync.aligned.16x128b.x1.pack::16b.b32 {%0,%1}, [%2]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a), "=r"(b) : "r"(half+16) : "memory");
  dst[3] = a; dst[4] = b;
  asm volatile("tcgen05.ld.sync.aligned.16x256b.x1.pack::16b.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(a), "=r"(b), "=r"(c), "=r"(d) : "r"(half+32) : "memory");
  dst[5] = a; dst[6] = b; dst[7] = c; dst[8] = d;

  a = source(tid,0); b = source(tid,1); c = source(tid,2); d = source(tid,3);
  asm volatile("tcgen05.st.sync.aligned.32x32b.x1.b32 [%0], {%1};" :: "r"(addr+3), "r"(c) : "memory");
  asm volatile("tcgen05.st.sync.aligned.16x32bx2.x1.b32 [%0], 1048578, {%1};" :: "r"(addr+1), "r"(d) : "memory");
  asm volatile("tcgen05.st.sync.aligned.32x32b.x2.unpack::16b.b32 [%0], {%1,%2};"
               :: "r"(addr+8), "r"(a), "r"(b) : "memory");
  asm volatile("tcgen05.st.sync.aligned.16x32bx2.x1.unpack::16b.b32 [%0], 1048579, {%1};"
               :: "r"(addr+12), "r"(c) : "memory");
  asm volatile("tcgen05.st.sync.aligned.16x64b.x1.unpack::16b.b32 [%0], {%1};"
               :: "r"(half+20), "r"(d) : "memory");
  asm volatile("tcgen05.st.sync.aligned.16x128b.x1.unpack::16b.b32 [%0], {%1,%2};"
               :: "r"(half+24), "r"(a), "r"(b) : "memory");
  asm volatile("tcgen05.st.sync.aligned.16x256b.x1.unpack::16b.b32 [%0], {%1,%2,%3,%4}; tcgen05.wait::st.sync.aligned;"
               :: "r"(half+32), "r"(a), "r"(b), "r"(c), "r"(d) : "memory");
#pragma unroll
  for (unsigned col = 0; col < columns; col += 4) {
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                 : "=r"(a), "=r"(b), "=r"(c), "=r"(d) : "r"(addr+col) : "memory");
    dst[loads+col] = a; dst[loads+col+1] = b; dst[loads+col+2] = c; dst[loads+col+3] = d;
  }
  tcgen_before_sync();
  __syncthreads();
  if (!warp)
    asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0, 128;" :: "r"(slot) : "memory");
}

// Compute expectations directly in logical (row, column) coordinates.
static unsigned expectedLoad(unsigned tid, unsigned reg) {
  unsigned lane = tid % 32, base = tid - lane, row = tid, col = 1;
  unsigned half = 16 * (tid / 32 % 2);
  if (reg == 1) {
    col += lane >= 16 ? 5 : 0;
  } else if (reg == 2) {
    row = base + half + lane / 4 + 8 * (lane % 2);
    col = 8 + 2 * (lane / 2 % 2);
  } else if (reg == 3 || reg == 4) {
    row = base + half + lane / 4 + 8 * (reg - 3);
    col = 16 + 2 * (lane % 4);
  } else if (reg >= 5) {
    row = base + half + lane / 4 + 8 * ((reg - 5) / 2);
    col = 32 + 2 * (2 * (lane % 4) + (reg - 5) % 2);
  }
  return (initial(row,col) & 0xffffu) | (initial(row,col+1) << 16);
}

static unsigned expectedStore(unsigned tid, unsigned col) {
  unsigned init = initial(tid,col), lane = tid % 32, row = lane % 16;
  if (col == 3) return source(tid, lane < 16 ? 2 : 3);
  if (col == 1 && lane < 16) return source(tid,3);
  unsigned word, part;
  if (col >= 8 && col < 12) {
    word = source(tid,(col-8)/2); part = (col-8)%2;
  } else if (lane < 16 ? (col == 12 || col == 13) : (col == 15 || col == 16)) {
    word = source(tid,2); part = col - (lane < 16 ? 12 : 15);
  } else if (lane / 16 == tid / 32 % 2 && col >= 20) {
    unsigned src = tid - lane + 4 * (row % 8);
    if (col < 24) {
      src += row/8 + 2 * ((col-20)/2);
      word = source(src,3);
    } else if (col < 32) {
      src += (col-24)/2;
      word = source(src,row/8);
    } else {
      unsigned chunk = (col-32)/2;
      src += chunk/2;
      word = source(src,2*(row/8)+chunk%2);
    }
    part = col % 2;
  } else {
    return init;
  }
  return (init & 0xffff0000u) | ((word >> (16 * part)) & 0xffffu);
}

int main() {
  std::vector<unsigned> out(128 * outputs);
  unsigned *device;
  ASYNC_CHECK(cudaMalloc(&device, out.size() * sizeof(unsigned)));
  pack<<<1,128>>>(device);
  ASYNC_CHECK(cudaMemcpy(out.data(), device, out.size() * sizeof(unsigned), cudaMemcpyDeviceToHost));
  ASYNC_CHECK(cudaFree(device));
  unsigned errors = 0;
  for (unsigned tid = 0; tid < 128; ++tid) {
    for (unsigned i = 0; i < outputs; ++i) {
      unsigned expected = i < loads ? expectedLoad(tid,i) : expectedStore(tid,i-loads);
      if (out[tid*outputs+i] != expected && ++errors <= 8)
        printf("thread=%u output=%u got=%08x expected=%08x\n", tid,i,out[tid*outputs+i],expected);
    }
  }
  printf("TMEM single column and pack: %u mismatches in %zu values\n", errors,out.size());
  return errors != 0;
}
