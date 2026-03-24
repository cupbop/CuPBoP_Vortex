#ifndef __RUNTIME_IMPL__
#define __RUNTIME_IMPL__
#include "cudaStatus.h"
#include "structures.h"
#include <stdint.h>

/*
 * When building the "torch" variant of the runtime, rename exported CUDA API
 * symbols to *_vortex to avoid clashing with NVIDIA libcudart symbols.
 *
 * IMPORTANT:
 *  - Enable this macro ONLY when compiling libvortexRuntime_torch.so
 *  - Do NOT enable it in PyTorch/Triton translation units.
 */
#ifdef VORTEX_RENAME_CUDA_SYMBOLS
  #define cudaGetDevice              cudaGetDevice_vortex
  #define cudaGetErrorname           cudaGetErrorname_vortex
  #define cudaDeviceReset            cudaDeviceReset_vortex
  #define cudaDeviceSynchronize      cudaDeviceSynchronize_vortex
  #define cudaThreadSynchronize      cudaThreadSynchronize_vortex
  #define cudaFree                   cudaFree_vortex
  #define cudaFreeHost               cudaFreeHost_vortex
  #define cudaMalloc                 cudaMalloc_vortex
  #define cudaMemcpy                 cudaMemcpy_vortex
  #define cudaMemcpyToSymbol_host    cudaMemcpyToSymbol_host_vortex
  #define cudaMemset                 cudaMemset_vortex
  #define cudaSetDevice              cudaSetDevice_vortex
  #define cudaStreamCopyAttributes   cudaStreamCopyAttributes_vortex
  #define cudaStreamCreate           cudaStreamCreate_vortex
  #define cudaStreamDestroy          cudaStreamDestroy_vortex
  #define cudaStreamSynchronize      cudaStreamSynchronize_vortex
  #define cudaGetDeviceCount         cudaGetDeviceCount_vortex
  #define cudaGetDeviceProperties    cudaGetDeviceProperties_vortex
  #define cudaGetDeviceProperties_v2 cudaGetDeviceProperties_v2_vortex
  #define cudaGetErrorString         cudaGetErrorString_vortex
  #define cudaGetLastError           cudaGetLastError_vortex
#endif

extern "C" {
cudaError_t cudaGetDevice(int *devPtr);
const char *cudaGetErrorname(cudaError_t);
cudaError_t cudaDeviceReset(void);
cudaError_t cudaDeviceSynchronize(void);
cudaError_t cudaThreadSynchronize(void);
cudaError_t cudaFree(void *devPtr);
cudaError_t cudaFreeHost(void *devPtr);
cudaError_t cudaLaunchKernel(const void *func, dim3 gridDim, dim3 blockDim,
                             void **args, size_t sharedMem,
                             cudaStream_t stream);
cudaError_t cudaLaunchKernel_vortex(const char *func, dim3 gridDim, dim3 blockDim,
                             void **args, size_t sharedMem,
                             cudaStream_t stream, const int num_args);
cudaError_t cudaMalloc(void **devPtr, size_t size);
cudaError_t cudaMemcpy(void *dst, const void *src, size_t count,
                       cudaMemcpyKind kind);
cudaError_t cudaMemcpyToSymbol_host(void *dst, const void *src, size_t count,
                                    size_t offset, cudaMemcpyKind kind, void *symbol);
cudaError_t cudaMemset(void *devPtr, int value, size_t count);
cudaError_t cudaSetDevice(int device);
cudaError_t cudaStreamCopyAttributes(cudaStream_t dst, cudaStream_t src);
cudaError_t cudaStreamCreate(cudaStream_t *pStream);
cudaError_t cudaStreamDestroy(cudaStream_t stream);
cudaError_t cudaStreamSynchronize(cudaStream_t stream);
cudaError_t cudaGetDeviceCount(int *count);
cudaError_t cudaGetDeviceProperties(cudaDeviceProp *deviceProp, int device);
cudaError_t cudaGetDeviceProperties_v2(cudaDeviceProp *deviceProp, int device);
const char *cudaGetErrorString(cudaError_t error);
cudaError_t cudaGetLastError(void);
}
#endif
