// Direct CTA mapping: KMU delivers the members consecutively on one core.
#include "cupbop_launch_context.h"
static inline const cupbop_launch_context<uintptr_t> &cluster_context() {
  return *reinterpret_cast<const cupbop_launch_context<uintptr_t> *>(csr_read_nv(VX_CSR_MSCRATCH));
}
static inline unsigned cluster_dim(unsigned axis) {
  unsigned d = (cluster_context().cluster_shape >> (8 * axis)) & 255;
  return d ? d : 1;
}
static inline unsigned cluster_block(unsigned axis) {
  if (axis == 0)
    return csr_read_nv(VX_CSR_CTA_BLOCK_ID_X);
  if (axis == 1)
    return csr_read_nv(VX_CSR_CTA_BLOCK_ID_Y);
  return csr_read_nv(VX_CSR_CTA_BLOCK_ID_Z);
}
static inline unsigned cluster_rank() {
  unsigned x = cluster_dim(0), y = cluster_dim(1);
  return cluster_block(0) % x + x * (cluster_block(1) % y + y * (cluster_block(2) % cluster_dim(2)));
}
extern "C" unsigned __cupbop_cluster_register(unsigned reg, unsigned axis) {
  switch (reg) {
  case 0:
    return cluster_rank();
  case 1:
    return cluster_dim(0) * cluster_dim(1) * cluster_dim(2);
  case 2:
    return cluster_block(axis) % cluster_dim(axis);
  case 3:
    return cluster_dim(axis);
  case 4:
    return cluster_block(axis) / cluster_dim(axis);
  case 5:
    return cluster_context().num_groups[axis] / cluster_dim(axis);
  default:
    return cluster_context().cluster_shape >> 24;
  }
}
extern "C" void *__cupbop_cluster_shared_ptr(uint32_t low) {
  uintptr_t base = csr_read_nv(VX_CSR_LOCAL_MEM_BASE);
  return reinterpret_cast<void *>(base + uint32_t(low - uint32_t(base)));
}
extern "C" void *__cupbop_cluster_map(void *address, unsigned rank) {
  const unsigned k = __cupbop_cluster_register(1, 0);
  if (rank >= k)
    cupbop_async_fail("invalid cluster rank", rank, k);
  if (k == 1)
    return address;
  uintptr_t stride = cluster_context().cluster_stride;
  if (!stride)
    cupbop_async_fail("cluster address without LMEM", rank, k);
  uintptr_t local = csr_read_nv(VX_CSR_CTA_LMEM_ADDR);
  uintptr_t memory = csr_read_nv(VX_CSR_LOCAL_MEM_BASE);
  // mapa also accepts an address already mapped to a different member.
  uintptr_t offset = (uintptr_t(address) - memory) % stride;
  return reinterpret_cast<void *>(local - cluster_rank() * stride + rank * stride + offset);
}

static inline uintptr_t cluster_base() {
  return csr_read_nv(VX_CSR_CTA_LMEM_ADDR) - cluster_rank() * cluster_context().cluster_stride;
}
extern "C" unsigned __cupbop_is_cta_shared(const void *ptr) {
  return uintptr_t(ptr) - csr_read_nv(VX_CSR_CTA_LMEM_ADDR) < cluster_context().cluster_stride;
}
// KMU places per-hart stacks immediately below LMEM; device allocations and
// the program image occupy the ordinary user address range below those stacks.
extern "C" unsigned __cupbop_is_global(const void *ptr) {
  constexpr unsigned sockets = (VX_CFG_NUM_CORES + VX_CFG_SOCKET_SIZE - 1) / VX_CFG_SOCKET_SIZE;
  constexpr uintptr_t harts = uintptr_t(VX_CFG_NUM_CLUSTERS) * sockets * VX_CFG_SOCKET_SIZE *
                              VX_CFG_NUM_WARPS * VX_CFG_NUM_THREADS;
  const uintptr_t bottom = uintptr_t(VX_MEM_STACK_BASE_ADDR) - (harts << VX_MEM_STACK_LOG2_SIZE);
  return uintptr_t(ptr) >= VX_MEM_USER_BASE_ADDR && uintptr_t(ptr) < bottom;
}

extern "C" __attribute__((convergent)) unsigned __cupbop_match_any(unsigned members, uint64_t value) {
  unsigned active = uint32_t(vx_active_threads()) & members;
  unsigned matches = 0;
  while (active) {
    unsigned lane = __builtin_ctz(active);
    uint32_t lo = vx_shfl_idx(uint32_t(value), lane, 31, 0);
    uint32_t hi = vx_shfl_idx(uint32_t(value >> 32), lane, 31, 0);
    if (value == (uint64_t(hi) << 32 | lo))
      matches |= 1u << lane;
    active &= active - 1;
  }
  return matches;
}
extern "C" unsigned __cupbop_cluster_query_rank(const void *ptr) {
  return cluster_context().cluster_stride ? (uintptr_t(ptr) - cluster_base()) / cluster_context().cluster_stride : 0;
}
extern "C" unsigned __cupbop_cluster_contains(const void *ptr) {
  return uintptr_t(ptr) - cluster_base() <
         uintptr_t(cluster_context().cluster_stride) * __cupbop_cluster_register(1, 0);
}
// State per grid cluster avoids aliasing across waves or concurrently resident
// clusters. Track live participants and each thread's last arrived generation:
// a thread may exit on either side of arrive without stranding its peers.
extern "C" __attribute__((convergent, noduplicate, noinline)) void __cupbop_cluster_sync(unsigned op) {
  const auto &ctx = cluster_context();
  unsigned k = __cupbop_cluster_register(1, 0);
  unsigned threads = ctx.local_size[0] * ctx.local_size[1] * ctx.local_size[2];
  unsigned total = threads * k;
  unsigned gx = ctx.num_groups[0] / cluster_dim(0), gy = ctx.num_groups[1] / cluster_dim(1);
  size_t group = cluster_block(0) / cluster_dim(0) +
                 gx * (size_t(cluster_block(1) / cluster_dim(1)) + gy * size_t(cluster_block(2) / cluster_dim(2)));
  size_t bytes = (8 + size_t(total) * 4 + 7) & ~size_t(7);
  auto *state = reinterpret_cast<uint64_t *>(ctx.cluster_barriers + group * bytes);
  unsigned tid = csr_read_nv(VX_CSR_CTA_THREAD_ID_X) +
                 ctx.local_size[0] *
                     (csr_read_nv(VX_CSR_CTA_THREAD_ID_Y) + ctx.local_size[1] * csr_read_nv(VX_CSR_CTA_THREAD_ID_Z));
  auto *token = reinterpret_cast<uint32_t *>(state + 1) + cluster_rank() * threads + tid;
  if (op == 1) {
    while (uint32_t(__atomic_load_n(state, __ATOMIC_ACQUIRE) >> 32) + 1 == *token) {
    }
    return;
  }
  uint32_t mask = vx_active_threads();
  while (mask) {
    unsigned lane = __builtin_ctz(mask);
    if (vx_thread_id() == lane) {
      uint64_t old = __atomic_load_n(state, __ATOMIC_ACQUIRE);
      for (;;) {
        uint32_t phase = old >> 32, retired = uint32_t(old) >> 16, arrived = old & 65535;
        if (op == 2) {
          ++retired;
          if (*token == phase + 1)
            --arrived;
        } else {
          ++arrived;
        }
        uint32_t next_phase = phase;
        if (arrived + retired == total) {
          ++next_phase;
          arrived = 0;
        }
        uint64_t next = (uint64_t(next_phase) << 32) | (retired << 16) | arrived;
        if (__atomic_compare_exchange_n(state, &old, next, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
          if (op == 0)
            *token = phase + 1;
          break;
        }
      }
    }
    mask &= mask - 1;
  }
}
