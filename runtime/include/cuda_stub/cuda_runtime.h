// Minimal stand-in for the CUDA toolkit's cuda_runtime.h, used only when no
// CUDA installation is available (CUDA_PATH unset). It provides the handful of
// host-side types the CuPBoP runtime and thread pool reference. It is NOT a CUDA
// runtime: CuPBoP's own cudaRuntimeImpl implements the API functions.
#ifndef CUPBOP_CUDA_RUNTIME_STUB_H
#define CUPBOP_CUDA_RUNTIME_STUB_H
#include <stddef.h>
#include <stdint.h>

// CUDA source annotations and calling-convention macro: no-ops on the host.
#ifndef CUDARTAPI
#define CUDARTAPI
#endif
#ifndef __host__
#define __host__
#endif
#ifndef __device__
#define __device__
#endif
#ifndef __global__
#define __global__
#endif
#ifndef __shared__
#define __shared__
#endif

struct dim3 {
  unsigned int x, y, z;
#ifdef __cplusplus
  dim3(unsigned int vx = 1, unsigned int vy = 1, unsigned int vz = 1) : x(vx), y(vy), z(vz) {}
#endif
};

enum cudaError {
  cudaSuccess = 0,
  cudaErrorInvalidValue = 1,
  cudaErrorMemoryAllocation = 2,
  cudaErrorInitializationError = 3,
  cudaErrorInvalidDevicePointer = 17,
  cudaErrorInvalidSymbol = 13,
  cudaErrorInvalidResourceHandle = 400,
  cudaErrorNotReady = 600,
  cudaErrorFileNotFound = 301,
  cudaErrorInvalidDevice = 101,
  cudaErrorLaunchFailure = 719,
  cudaErrorUnknown = 999
};
typedef enum cudaError cudaError_t;

enum cudaMemcpyKind {
  cudaMemcpyHostToHost = 0,
  cudaMemcpyHostToDevice = 1,
  cudaMemcpyDeviceToHost = 2,
  cudaMemcpyDeviceToDevice = 3,
  cudaMemcpyDefault = 4
};

typedef struct CUstream_st *cudaStream_t;
typedef struct CUevent_st *cudaEvent_t;

struct cudaDeviceProp {
  char name[256];
  size_t totalGlobalMem;
  size_t sharedMemPerBlock;
  int regsPerBlock;
  int warpSize;
  size_t memPitch;
  int maxThreadsPerBlock;
  int maxThreadsDim[3];
  int maxGridSize[3];
  int clockRate;
  size_t totalConstMem;
  int major;
  int minor;
  size_t textureAlignment;
  int deviceOverlap;
  int multiProcessorCount;
  int kernelExecTimeoutEnabled;
  int integrated;
  int canMapHostMemory;
  int computeMode;
  int concurrentKernels;
  int l2CacheSize;
  int maxThreadsPerMultiProcessor;
  int memoryClockRate;
  int memoryBusWidth;
  int unifiedAddressing;
};
#endif
