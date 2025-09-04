#ifndef __VX_SPAWN_H__
#define __VX_SPAWN_H__

#ifdef __cplusplus
extern "C" {
#endif

typedef union {
  struct {
    uint32_t x;
    uint32_t y;
    uint32_t z;
  };
  uint32_t m[3];
} dim3_t;

extern __device__ __thread dim3_t blockIdx_vx;
extern __device__ __thread dim3_t threadIdx_vx;
extern __device__ dim3_t gridDim_vx;
extern __device__ dim3_t blockDim_vx;

extern __device__ __thread uint32_t __local_group_id;
extern __device__ uint32_t __warps_per_group;

#ifdef __cplusplus
}
#endif

#endif 
