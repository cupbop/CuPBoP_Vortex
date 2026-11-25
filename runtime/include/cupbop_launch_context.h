#pragma once
#include <stdint.h>

constexpr uint32_t CUPBOP_LAUNCH_SIMX_CLC = 1u;
// Bits 1..5 encode the launch-private raw multicast DXA slot plus one.
constexpr uint32_t CUPBOP_RAW_DXA_SLOT_SHIFT = 1;
constexpr uint32_t CUPBOP_RAW_DXA_SLOT_MASK = 31;
constexpr uint32_t CUPBOP_RAW_DXA_TILE_BYTES = 16;

// Preserve the offsets of the legacy printf fields for existing device binaries.
// CTA-loop launches reuse these words for loop geometry and cannot use cluster barriers.
template <class DeviceAddress> struct cupbop_launch_context {
  uint32_t num_groups[3], global_offset[3], local_size[3];
  DeviceAddress cluster_barriers;
  uint32_t cluster_shape, cluster_stride;
  union {
    uint32_t work_dim;
    uint32_t direct_launch_flags;
  };
  uint32_t dyn_shared_mem_size;
};
