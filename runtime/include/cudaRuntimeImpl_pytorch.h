#ifndef __RUNTIME_IMPL_PYTORCH__
#define __RUNTIME_IMPL_PYTORCH__
#include <stdint.h>

// Declarations for the _vortex-suffixed symbols exported by libvortexRuntime_torch.so
// Include this header in PyTorch/Triton translation units to call Vortex runtime
// without symbol clashes with NVIDIA libcudart.
// Note: CUDA types (dim3, cudaError_t, cudaStream_t, etc.) are provided by
// cuda_runtime_api.h which PyTorch includes before this header.

extern "C" {
cudaError_t cudaGetDevice_vortex(int *devPtr);
const char *cudaGetErrorname_vortex(cudaError_t);
cudaError_t cudaDeviceReset_vortex(void);
cudaError_t cudaDeviceSynchronize_vortex(void);
cudaError_t cudaThreadSynchronize_vortex(void);
cudaError_t cudaFree_vortex(void *devPtr);
cudaError_t cudaFreeHost_vortex(void *devPtr);
cudaError_t cudaLaunchKernel_vortex(const char *func, dim3 gridDim, dim3 blockDim,
                             void **args, size_t sharedMem,
                             cudaStream_t stream, const int num_args);
cudaError_t cudaMalloc_vortex(void **devPtr, size_t size);
cudaError_t cudaMemcpy_vortex(void *dst, const void *src, size_t count,
                       cudaMemcpyKind kind);
cudaError_t cudaMemcpyToSymbol_host_vortex(void *dst, const void *src, size_t count,
                                    size_t offset, cudaMemcpyKind kind, void *symbol);
cudaError_t cudaMemset_vortex(void *devPtr, int value, size_t count);
cudaError_t cudaSetDevice_vortex(int device);
cudaError_t cudaStreamCopyAttributes_vortex(cudaStream_t dst, cudaStream_t src);
cudaError_t cudaStreamCreate_vortex(cudaStream_t *pStream);
cudaError_t cudaStreamDestroy_vortex(cudaStream_t stream);
cudaError_t cudaStreamSynchronize_vortex(cudaStream_t stream);
cudaError_t cudaGetDeviceCount_vortex(int *count);
cudaError_t cudaGetDeviceProperties_vortex(cudaDeviceProp *deviceProp, int device);
cudaError_t cudaGetDeviceProperties_v2_vortex(cudaDeviceProp *deviceProp, int device);
const char *cudaGetErrorString_vortex(cudaError_t error);
cudaError_t cudaGetLastError_vortex(void);
}
#endif
