#include "../tcgen05_test.h"
#include <vector>

#ifdef CUPBOP_TEST_COLUMN_PAIR
#include <cooperative_groups.h>
#define CTA_GROUP "cta_group::2"
#define MMA_CLUSTER __cluster_dims__(2,1,1)
constexpr unsigned groupSize = 2;
#else
#define CTA_GROUP "cta_group::1"
#define MMA_CLUSTER
constexpr unsigned groupSize = 1;
#endif

// Each CTA supplies 128 rows of A and 16 columns of B. Each paired CTA
// has its own A, B and sparse metadata, and receives all 32 output columns.
constexpr unsigned M = 128, localN = 16, N = groupSize * localN;
constexpr unsigned aBytes = M * 64;
#ifdef CUPBOP_TEST_TF32
constexpr unsigned bBytes = 32 * 64;  // MN-major TF32 atoms pad N=16 to 32
#else
constexpr unsigned bBytes = localN * 64;
#endif
constexpr unsigned wordsPerCTA = (aBytes + bBytes) / 4 + M * 2;

__host__ __device__ unsigned value_bytes(unsigned op) { return (op & 0x21ff0) == 0x910 ? 4 : (op & 0x20010) == 0x10 ? 2 : 1; }
__host__ __device__ unsigned b_subview(unsigned op) {
#ifdef CUPBOP_TEST_TF32_SUBVIEW
  return value_bytes(op) == 4 && (op & (1u << 16)) ? 32 : 0;
#else
  return 0;
#endif
}
__host__ __device__ unsigned inner(unsigned op) { return (32 / value_bytes(op)) * (op & 4 ? 2 : 1); }

__device__ uint64_t descriptor(const void *ptr, unsigned rows, unsigned k, unsigned bytes, bool mn) {
  unsigned leading = mn ? rows * bytes * 8 : 128;
  unsigned stride = mn ? 128 : 8 * k * bytes;
  uint64_t mode = 0;
  if (mn && bytes == 4) {
    leading = k * 128;
    stride = 4 * 128;
    mode = 1ull << 61;
  }
  return (uint64_t(smem_u32(ptr) >> 4) & 0x3fff) | (uint64_t(leading / 16) << 16) |
         (uint64_t(stride / 16) << 32) | (1ull << 46) | mode;
}

template <unsigned F>
__global__ void MMA_CLUSTER mma_case(const unsigned *input, unsigned *out) {
  __shared__ __align__(128) unsigned a[aBytes/4], b[bBytes/4];
  __shared__ uint64_t barrier;
  __shared__ unsigned slot;
  const unsigned r = threadIdx.x;
#ifdef CUPBOP_TEST_COLUMN_PAIR
  auto cluster = cooperative_groups::this_cluster();
  const unsigned rank = cluster.block_rank();
#else
  constexpr unsigned rank = 0;
#endif
  input += rank * wordsPerCTA;
  for (unsigned i = r; i < aBytes/4; i += M) a[i] = input[i];
  for (unsigned i = r; i < bBytes/4; i += M) b[i] = input[aBytes/4+i];
  if (!r) {
    mbar_init(&barrier, 1);
#ifdef CUPBOP_TEST_COLUMN_PAIR
    mbar_init_fence();
#endif
  }
  if (r < 32)
    asm volatile("tcgen05.alloc." CTA_GROUP ".sync.aligned.shared::cta.b32 [%0], %1;"
                 :: "r"(smem_u32(&slot)), "n"(2 * N) : "memory");
  __syncthreads();
  unsigned meta = slot + N;
  // Each CTA addresses its own 128-row TMEM array.
  unsigned addr = slot + ((r & ~31u) << 16);
  if (F & 4) {
    const unsigned *word = input + (aBytes+bBytes)/4 + 2*r;
    asm volatile("tcgen05.st.sync.aligned.32x32b.x4.b32 [%0], {%1,%2,%3,%3}; tcgen05.wait::st.sync.aligned;"
                 :: "r"(addr+N),"r"(word[0]),"r"(word[1]),"r"(0) : "memory");
  }
  __syncthreads();
  tcgen_after_sync();
  asm volatile("fence.proxy.async.shared::cta;" ::: "memory");
#ifdef CUPBOP_TEST_COLUMN_PAIR
  cluster.sync();
#endif
  if (!r && !rank) {
    const uint64_t ad = descriptor(a,M,inner(F)/(F & 4 ? 2 : 1),value_bytes(F),F & (1u<<15));
    const uint64_t bd = descriptor(reinterpret_cast<const char *>(b) + b_subview(F),localN,inner(F),value_bytes(F),F & (1u<<16));
    constexpr unsigned idesc = ((groupSize * M / 16) << 24) | ((N / 8) << 17) | (F & 0x1ffff);
#ifdef CUPBOP_TEST_TMEM_A
    // All 128 rows store eight packed words. Leave the sparse metadata at N.
    const unsigned a_col = slot + N + 8;
    asm volatile("tcgen05.cp." CTA_GROUP ".128x256b [%0], %1;" :: "r"(a_col), "l"(ad) : "memory");
#define A_OPERAND "[%1]"
#define A_INPUT "r"(a_col)
#else
#define A_OPERAND "%1"
#define A_INPUT "l"(ad)
#endif
#define RUN_DENSE(kind) asm volatile("{ .reg .pred p; setp.ne.u32 p, 0, 0; tcgen05.mma." CTA_GROUP ".kind::" kind " [%0], " A_OPERAND ", %2, %3, p; }" :: "r"(slot),A_INPUT,"l"(bd),"r"(idesc) : "memory")
#define RUN_SPARSE(kind) asm volatile("{ .reg .pred p; setp.ne.u32 p, 0, 0; tcgen05.mma.sp." CTA_GROUP ".kind::" kind " [%0], " A_OPERAND ", %2, [%3], %4, p; }" :: "r"(slot),A_INPUT,"l"(bd),"r"(meta),"r"(idesc) : "memory")
    if (F & 4) {
      if ((F & 0x21ff0) == 0x910) RUN_SPARSE("tf32");
      else if (F & 0x20000) RUN_SPARSE("f8f6f4"); else if (F & 0x10) RUN_SPARSE("f16"); else RUN_SPARSE("i8");
    } else {
      if ((F & 0x21ff0) == 0x910) RUN_DENSE("tf32");
      else if (F & 0x20000) RUN_DENSE("f8f6f4"); else if (F & 0x10) RUN_DENSE("f16"); else RUN_DENSE("i8");
    }
#undef RUN_SPARSE
#undef RUN_DENSE
#undef A_OPERAND
#undef A_INPUT
#ifdef CUPBOP_TEST_COLUMN_PAIR
    asm volatile("tcgen05.commit.cta_group::2.mbarrier::arrive::one.shared::cluster.multicast::cluster.b64 [%0], %1;"
                 :: "r"(smem_u32(&barrier)), "h"(uint16_t(3)) : "memory");
#else
    asm volatile("tcgen05.commit.cta_group::1.mbarrier::arrive::one.shared::cluster.b64 [%0];"
                 :: "r"(smem_u32(&barrier)) : "memory");
#endif
  }
  __syncthreads();
#ifdef CUPBOP_TEST_COLUMN_PAIR
  if (!r) mbar_wait(&barrier, 0);
  __syncthreads();
#else
  mbar_wait(&barrier, 0);
#endif
  tcgen_after_sync();
  for (unsigned j=0;j<N;j+=4) {
    unsigned x,y,z,w;
    asm volatile("tcgen05.ld.sync.aligned.32x32b.x4.b32 {%0,%1,%2,%3}, [%4]; tcgen05.wait::ld.sync.aligned;"
                 : "=r"(x),"=r"(y),"=r"(z),"=r"(w) : "r"(addr+j) : "memory");
    unsigned v[] = {x,y,z,w};
    for (unsigned i=0;i<4;++i) out[(rank*M+r)*N+j+i] = v[i];
  }
  __syncthreads();
#ifdef CUPBOP_TEST_COLUMN_PAIR
  cluster.sync();
#endif
  if (r < 32)
    asm volatile("tcgen05.dealloc." CTA_GROUP ".sync.aligned.b32 %0,%1;" :: "r"(slot), "n"(2 * N) : "memory");
}

static constexpr unsigned selections[] = {4,8,12,9,13,14};
static unsigned indices(unsigned r, unsigned g) { return selections[(r+g*5) % 6]; }

static int source_value(unsigned row, unsigned k, unsigned f, bool b, unsigned &bits) {
  unsigned v = row * (b ? 13 : 17) + k * (b ? 37 : 53) + (b ? 71 : 127);
  bool alt = f & (1u << (b ? 10 : 7));
  if (!(f & 0x10)) {
    bits = v & 255;
    return alt && bits >= 128 ? int(bits)-256 : int(bits);
  }
  if (value_bytes(f) == 4) {
    const int values[] = {33,-131,259,1001};
    unsigned index = (v ^ (row >> 2) ^ (row >> 3) ^ (k >> (b ? 2 : 1))) & 3;
    float x = float(values[index]);
    memcpy(&bits, &x, 4);
    return values[index];
  }
  const unsigned half[] = {0x3c00,0xc000,0x4400,0x4800};
  const unsigned bf16[] = {0x3f80,0xc000,0x4080,0x4100};
  const int values[] = {1,-2,4,8};
  bits = (alt ? bf16 : half)[v % 4];
  if (f & 0x20000) {
    const unsigned e4m3[] = {0x38,0xc0,0x48,0x50}, e5m2[] = {0x3c,0xc0,0x44,0x48};
    bits = (alt ? e5m2 : e4m3)[v % 4];
  }
  return values[v % 4];
}

template <unsigned F>
static int check(unsigned *device, unsigned *result) {
  std::vector<unsigned> in(groupSize * wordsPerCTA), got(groupSize * M * N);
  const unsigned bytes = value_bytes(F), ksize = inner(F);
  for (unsigned rank = 0; rank < groupSize; ++rank) {
    unsigned *tile = in.data() + rank * wordsPerCTA;
    for (unsigned b=0;b<2;++b) {
      unsigned rows = b ? localN : M;
      unsigned extent = !b && (F&4) ? ksize/2 : ksize;
      unsigned vec = 16/bytes;
      for (unsigned row=0;row<rows;++row) for (unsigned k=0;k<extent;++k) {
        unsigned offset = F & (1u << (15+b))
            ? (k/8)*rows*bytes*8 + (row/vec)*128 + (k%8)*16 + (row%vec)*bytes
            : (row/8)*extent*bytes*8 + (k/vec)*128 + (row%8)*16 + (k%vec)*bytes;
        if (bytes == 4 && (F & (1u << (15 + b)))) {
          unsigned column = (row & 31u) * 4 + (b ? b_subview(F) : 0);
          unsigned swizzled = column ^ ((k & 3) * 32);
          offset = ((row / 32) * extent + k) * 128 + swizzled;
        }
        unsigned bits;
        source_value(rank * rows + row,k,F,b,bits);
        memcpy(reinterpret_cast<char *>(tile) + b*aBytes + offset,&bits,bytes);
      }
    }
    if (F & 4) for (unsigned r=0;r<M;++r) for (unsigned k=0;k<ksize;k+=4) {
      if (bytes == 4) {
        unsigned word = 2 * ((r & ~8u) | (k & 8)) + (F & 1);
        unsigned shift = (r & 8) * 2 + (k & 4) * 2;
        unsigned lo = ((r + k / 4) & 1) ? 14 : 4;
        unsigned hi = ((r / 2 + k / 4) & 1) ? 14 : 4;
        tile[(aBytes+bBytes)/4+word] |= (lo | (hi << 4)) << shift;
        continue;
      }
      unsigned word = value_bytes(F) == 2 ? 2*((r & ~8u)|((k&16)>>1)) + (F&1) : 2*r + k/32;
      unsigned shift = value_bytes(F) == 2 ? ((r&8)*2) + (k&12) : k & 28;
      tile[(aBytes+bBytes)/4+word] |= indices(rank * M + r,k/4) << shift;
    }
  }
  ASYNC_CHECK(cudaMemcpy(device,in.data(),in.size()*4,cudaMemcpyHostToDevice));
  mma_case<F><<<groupSize,M>>>(device,result);
  ASYNC_CHECK(cudaMemcpy(got.data(),result,got.size()*4,cudaMemcpyDeviceToHost));
  unsigned errors = 0;
  for (unsigned r=0;r<groupSize*M;++r) for (unsigned n=0;n<N;++n) {
    int sum = 0;
    for (unsigned k=0;k<ksize;++k) {
      unsigned a = k, unused;
      if ((F & 4) && bytes == 4) {
        unsigned select = (((k % 4) < 2 ? r : r / 2) + k / 4) & 1;
        if ((k & 1) != select) continue;
        a = k / 2;
      } else if (F & 4) {
        unsigned pos = indices(r,k/4);
        if ((k%4) != (pos&3) && (k%4) != (pos>>2)) continue;
        a = k/4*2 + ((k%4)==(pos>>2));
      }
      sum += source_value(r,a,F,false,unused)*source_value(n,k,F,true,unused);
    }
    if (((F >> 13) ^ (F >> 14)) & 1) sum = -sum;
    unsigned expected = unsigned(sum);
    if (F & 0x10) {
      float x = float(sum);
      memcpy(&expected,&x,4);
    }
    if (got[r*N+n] != expected && ++errors < 3)
      printf("format=%x row=%u col=%u expected=%x got=%x\n",F,r,n,expected,got[r*N+n]);
  }
  printf("format=%x mismatches=%u/%u\n",F,errors,groupSize*M*N);
  return errors != 0;
}
int main() {
  unsigned *in,*out;
  ASYNC_CHECK(cudaMalloc(&in,groupSize*wordsPerCTA*sizeof(unsigned)));
  ASYNC_CHECK(cudaMalloc(&out,groupSize*M*N*sizeof(unsigned)));
#ifdef CUPBOP_TEST_TF32
  int failed = check<0x00910>(in,out);       // dense, positive and negative TF32 with fractional mantissas
  failed |= check<0x02915>(in,out);          // 1:2 sparsity, selector 1, negate A
#ifdef CUPBOP_TEST_TMEM_A
  failed |= check<0x10910>(in,out);          // K-major TMEM A, MN-major TF32 B
  failed |= check<0x10420>(in,out);          // U8 TMEM A with signed transposed B
  failed |= check<0x10090>(in,out);          // BF16 TMEM A with FP16 B, widened to TF32
  failed |= check<0x00410>(in,out);          // FP16 TMEM A with BF16 B, widened to TF32
#else
  failed |= check<0x18910>(in,out);          // independent SW128-32B layouts for both operands
#endif
#elif defined(CUPBOP_TEST_TMEM_A)
  int failed = check<0x004a0>(in,out);       // S8, A from TMEM
  failed |= check<0x100a0>(in,out);          // S8/U8, transpose B
  failed |= check<0x12490>(in,out);          // BF16, negate A and transpose B
  failed |= check<0x004a4>(in,out);          // sparse S8, A and metadata in TMEM
#elif defined(CUPBOP_TEST_COLUMN_PAIR)
  int failed = check<0x004a4>(in,out);       // sparse S8 M256 N32 K64
#else
  int failed = check<0x180a0>(in,out);       // signed A, unsigned B, transpose both
  failed |= check<0x08420>(in,out);           // unsigned A, signed B, transpose A
  failed |= check<0x18015>(in,out);           // sparse F16, selector 1, transpose both
  failed |= check<0x004a4>(in,out);           // sparse S8
  failed |= check<0x100a4>(in,out);           // sparse mixed S8/U8, transpose B
  failed |= check<0x38410>(in,out);           // mixed E4M3/E5M2 transpose both
  failed |= check<0x20094>(in,out);           // sparse E5M2/E4M3
#ifdef CUPBOP_TEST_MIXED_TF32
  failed |= check<0x10090>(in,out);           // BF16/F16, transpose B
  failed |= check<0x08410>(in,out);           // F16/BF16, transpose A
#endif
#endif
  ASYNC_CHECK(cudaFree(in));
  ASYNC_CHECK(cudaFree(out));
  return failed;
}
