#include "../tcgen05_test.h"
#include <vector>

__global__ void column_ops(unsigned *out, unsigned format) {
  __shared__ __align__(128) unsigned a[128][8], b[128][8];
  __shared__ unsigned slot;
  __shared__ uint64_t barrier;
  unsigned row = threadIdx.x;
  if (!row) mbar_init(&barrier, 1);
  for (unsigned j = 0; j < 8; ++j) {
    // K-major 16-byte vectors across groups of eight rows.
    unsigned offset = row / 8 * 64 + j / 4 * 32 + row % 8 * 4 + j % 4;
    reinterpret_cast<unsigned *>(a)[offset] = 1000 * row + j;
    unsigned bword = row % 2 ? 0x40004000u : 0x3c003c00u;
    if (format == 1) bword = row % 2 ? 0x40004000u : 0x3f803f80u;
    if (format == 2) bword = row % 2 ? 0x80808080u : 0x81818181u;
    reinterpret_cast<unsigned *>(b)[offset] = bword;
  }
  if (row < 32)
    asm volatile("tcgen05.alloc.cta_group::1.sync.aligned.shared::cta.b32 [%0], 128;" :: "r"(smem_u32(&slot)) : "memory");
  __syncthreads();
  unsigned address = slot + ((row & ~31u) << 16);
  unsigned long long layout = (8ull << 16) | (16ull << 32) | (1ull << 46);
  auto ad = layout | ((smem_u32(a) >> 4) & 0x3fff);
  auto bd = layout | ((smem_u32(b) >> 4) & 0x3fff);
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  tcgen_after_sync();
  if (!row) {
#ifdef CUPBOP_TEST_WARPX4_COPY
    // The second vector of the eight-row core tile is 128 bytes ahead.
    asm volatile("tcgen05.cp.cta_group::1.32x128b.warpx4 [%0], %1;" :: "r"(slot), "l"(ad) : "memory");
    asm volatile("tcgen05.cp.cta_group::1.32x128b.warpx4 [%0], %1;" :: "r"(slot + 4), "l"(ad + 8) : "memory");
#else
    asm volatile("tcgen05.cp.cta_group::1.128x256b [%0], %1;" :: "r"(slot), "l"(ad) : "memory");
#endif
    asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];" :: "r"(smem_u32(&barrier)) : "memory");
  }
  __syncthreads();
  mbar_wait(&barrier, 0);
  tcgen_after_sync();
  for (unsigned j = 0; j < 8; j += 4) {
    unsigned x,y,z,w;
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                 : "=r"(x),"=r"(y),"=r"(z),"=r"(w) : "r"(address+j) : "memory");
    unsigned v[] = {x,y,z,w};
    for (unsigned i=0;i<4;++i) out[row*16+j+i]=v[i];
  }
  asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0], {%1,%2,%3,%4}; tcgen05.wait::st.sync.aligned;"
               :: "r"(address+12),"r"(row),"r"(row+1),"r"(row+2),"r"(row+3) : "memory");
  unsigned x,y,z,w;
  asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
               : "=r"(x),"=r"(y),"=r"(z),"=r"(w) : "r"(address+12) : "memory");
  unsigned v[] = {x,y,z,w};
  for (unsigned i=0;i<4;++i) out[row*16+8+i]=v[i];
  for (unsigned j=0;j<8;++j) {
    unsigned offset = row / 8 * 64 + j / 4 * 32 + row % 8 * 4 + j % 4;
    unsigned aword = row % 2 ? 0x40004000u : 0x3c003c00u;
    if (format == 1) aword = row % 2 ? 0x40004000u : 0x3f803f80u;
    if (format == 2) aword = row % 2 ? 0xfefefefeu : 0xffffffffu;
    reinterpret_cast<unsigned *>(a)[offset] = aword;
  }
  __syncthreads();
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
  if (!row) {
#define COLUMN_MMA(KIND, IDESC) \
    asm volatile("{ .reg .pred p; setp.ne.u32 p, 0, 0; tcgen05.mma.cta_group::1.kind::" KIND \
                 " [%0], %1, %2, %3, p; }" :: "r"(slot), "l"(ad), "l"(bd), "r"(IDESC) : "memory")
    if (format == 1) COLUMN_MMA("f16", 0x08100490u);
    else if (format == 2) COLUMN_MMA("i8", 0x08100020u);
    else COLUMN_MMA("f16", 0x08100010u);
#undef COLUMN_MMA
    asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];" :: "r"(smem_u32(&barrier)) : "memory");
  }
  __syncthreads();
  mbar_wait(&barrier, 1);
  tcgen_after_sync();
  for (unsigned j=0;j<64;j+=4) {
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                 : "=r"(x),"=r"(y),"=r"(z),"=r"(w) : "r"(address+j) : "memory");
    unsigned fv[] = {x,y,z,w};
    for (unsigned i=0;i<4;++i) out[2048+row*64+j+i]=fv[i];
  }
  __syncthreads();
  if (row<32) asm volatile("tcgen05.dealloc.cta_group::1.sync.aligned.b32 %0, 128;" :: "r"(slot) : "memory");
}

int main() {
  std::vector<unsigned> out(2048+128*64);
  unsigned *dev;
  ASYNC_CHECK(cudaMalloc(&dev,out.size()*sizeof(unsigned)));
  unsigned errors = 0;
  for (unsigned format = 0; format < 3; ++format) {
    column_ops<<<1,128>>>(dev, format);
    ASYNC_CHECK(cudaMemcpy(out.data(),dev,out.size()*sizeof(unsigned),cudaMemcpyDeviceToHost));
    for (unsigned r=0;r<128;++r) {
#ifdef CUPBOP_TEST_WARPX4_COPY
      const unsigned copyRow = r % 32;
#else
      const unsigned copyRow = r;
#endif
      for (unsigned j=0;j<12;++j) errors += out[r*16+j] != (j<8 ? copyRow*1000+j : r+j-8);
      for (unsigned j=0;j<64;++j) {
        float fp = float(16 * (1 + r%2) * (1 + j%2));
        unsigned expected;
        memcpy(&expected, &fp, sizeof(expected));
        if (format == 2) expected = 32 * (255 - r%2) * (129 - j%2);
        errors += out[2048+r*64+j] != expected;
      }
    }
  }
  ASYNC_CHECK(cudaFree(dev));
  printf("column cp/st/fp16/bf16/u8 mismatches=%u\n",errors);
  return errors != 0;
}
