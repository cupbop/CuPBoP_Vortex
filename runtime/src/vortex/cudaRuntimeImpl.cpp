#include "cudaRuntimeImpl.h"
#include "api.h"
#include "cuda_runtime.h"
#include "def.h"
#include "macros.h"
#include "structures.h"
#include <iostream>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <vortex.h>
#include <fstream>
#include <limits>

#define RT_CHECK(_expr)                                         \
   do {                                                         \
     int _ret = _expr;                                          \
     if (0 == _ret)                                             \
       break;                                                   \
     printf("Error: '%s' returned %d!\n", #_expr, (int)_ret);   \
     std::abort();                                              \
   } while (false)

// location is local memory where to store kernel parameters
#define KERNEL_ARG_BASE_ADDR 0x7ffff000

// kernel number of arguments
//#define num_args 4

struct alignas(4) context_t {
  uint32_t num_groups[3];
  uint32_t global_offset[3];
  uint32_t local_size[3];
  uint32_t printf_buffer;
  uint32_t printf_buffer_position;
  uint32_t printf_buffer_capacity;
  uint32_t work_dim;
};

struct alignas(64) kernel_arg_t {
  context_t ctx;
  int kernel_idx;
  uint64_t  args[0];
};

typedef void (*pfn_workgroup_func) (
  const void* args,
  const context_t* context,
  uint32_t group_x,
  uint32_t group_y,
  uint32_t group_z
);

class DeviceContext {
private:
  DeviceContext() 
    : device_(nullptr)
    , staging_buf_(nullptr)
    , staging_size_(0)
  {}

  ~DeviceContext() {
    if (staging_buf_ != nullptr) {
      vx_buf_free(staging_buf_);
    }
    if (device_ != nullptr) {
      vx_dev_close(device_);
    }
  }

  void initialize() {
    if (device_ == nullptr) {
      RT_CHECK(vx_dev_open(&device_));
    }
  }

  vx_device_h device_;
  vx_buffer_h staging_buf_;
  size_t staging_size_;

public:
  static DeviceContext* instance() {
    static DeviceContext s_inst;
    s_inst.initialize();
    return &s_inst;
  }

  vx_device_h device() {    
    return device_;
  }
  
  vx_buffer_h staging_alloc(size_t size) {
    if (staging_buf_ != nullptr && staging_size_ < size) {
      vx_buf_free(staging_buf_);
      staging_buf_ = nullptr;        
    }
    if (staging_buf_ == nullptr) {
      RT_CHECK(vx_buf_alloc(device_, size, &staging_buf_));
      staging_size_ = size;
    }
    return staging_buf_;
  }
};

cudaError_t cudaGetDevice(int *devPtr) { 
  *devPtr = 0;
  return cudaSuccess;
}

const char *cudaGetErrorName(cudaError_t error) { 
  return "SUCCESS\n";
}

cudaError_t cudaDeviceReset(void) { 
  scheduler_uninit(); 
  return cudaSuccess;
}

cudaError_t cudaDeviceSynchronize(void) { 
  cuSynchronizeBarrier(); 
  return cudaSuccess;
}

cudaError_t cudaThreadSynchronize(void) { 
  cuSynchronizeBarrier(); 
  return cudaSuccess;
}

cudaError_t cudaFreeHost(void *devPtr) { 
  free(devPtr);
  return cudaSuccess;
}

cudaError_t cudaMalloc(void **devPtr, size_t size) {
  auto DC = DeviceContext::instance();
  uint64_t mem_addr;  
  RT_CHECK(vx_mem_alloc(DC->device(), size, &mem_addr));
  printf("cudaMalloc: size=%ld, mem_addr=%lu\n", size, mem_addr);
  *devPtr = (void*)mem_addr;
   return cudaSuccess;
}

cudaError_t cudaFree(void *devPtr) {
  auto DC = DeviceContext::instance(); 
  uint64_t mem_addr = (uint64_t)devPtr;  
  vx_mem_free(DC->device(), mem_addr);
  printf("cudaFree: mem_addr=%lu\n", mem_addr);
   return cudaSuccess;
}

cudaError_t cudaMemset(void *devPtr, int value, size_t count) {  
  memset(devPtr, value, count);
  return cudaSuccess;
}

cudaError_t cudaMemcpy(void *dst, const void *src, size_t count, cudaMemcpyKind kind) {
  int vx_err; 
  if (kind == cudaMemcpyHostToHost) {
    memcpy(dst, src, count);
  } else if (kind == cudaMemcpyDeviceToHost) {
    auto DC = DeviceContext::instance();
    auto staging_buf = DC->staging_alloc(count);
    auto host_ptr = vx_host_ptr(staging_buf);
    uint64_t mem_addr = (uint64_t)src;
    RT_CHECK(vx_copy_from_dev(staging_buf, mem_addr, count, 0));
    memcpy(dst, (char*)host_ptr, count);
    printf("cudamemcpyDeviceToHost: src=%lu, dst=%p, count=%ld\n", mem_addr, dst, count);
  } else if (kind == cudaMemcpyHostToDevice) {
    auto DC = DeviceContext::instance();
    auto staging_buf = DC->staging_alloc(count);
    auto host_ptr = vx_host_ptr(staging_buf);
    memcpy((char *)host_ptr, src, count);
    uint64_t mem_addr = (uint64_t)dst;
    RT_CHECK(vx_copy_to_dev(staging_buf, mem_addr, count, 0));
    printf("cudaMemcpyHostToDevice: src=%p, dst=%lu, count=%ld\n", src, mem_addr, count);
  } else if (kind == cudaMemcpyDeviceToDevice) {
    auto DC = DeviceContext::instance();
    auto staging_buf = DC->staging_alloc(count);
    auto host_ptr = vx_host_ptr(staging_buf);
    uint64_t mem_src_addr = (uint64_t)src;
    RT_CHECK(vx_copy_from_dev(staging_buf, mem_src_addr, count, 0));
    uint64_t mem_dst_addr = (uint64_t)dst;
    RT_CHECK(vx_copy_to_dev(staging_buf, mem_dst_addr, count, 0));
    printf("cudaMemcpyDeviceToDevice: src=%lu, dst=%lu, count=%ld\n", mem_src_addr, mem_dst_addr, count);
  } else if (kind == cudaMemcpyDefault) {
    std::abort(); // not supported!
  }
  return cudaSuccess;
}

cudaError_t cudaMemcpyToSymbol_host(void *dst, 
                                    const void *src, 
                                    size_t count,
                                    size_t offset, 
                                    cudaMemcpyKind kind) {
  assert(offset == 0 && "DO not support offset !=0\n");
  memcpy(dst, src, count);
  return cudaSuccess;
}

cudaError_t cudaSetDevice(int device) {
  init_device();  
  return cudaSuccess;
}

cudaError_t cudaStreamCopyAttributes(cudaStream_t dst, cudaStream_t src) {
  cstreamData *dst_stream = (cstreamData *)dst;
  cstreamData *src_stream = (cstreamData *)src;

  if (dst_stream == NULL || src_stream == NULL) {
    return cudaErrorInvalidValue; // 1
  }

  dst_stream->stream_priority = src_stream->stream_priority;
  dst_stream->stream_flags = src_stream->stream_flags;

  return cudaSuccess; // 0
}

static int stream_counter = 1;
/*
  cudaStream_t is a Opaque Structure

  Overwrites cudaStream_t into custom cstreamData structure
  (does hardware uses the cudaStream_t stream)

*/
cudaError_t cudaStreamCreate(cudaStream_t *pStream) {
  cstreamData *s = (cstreamData *)calloc(1, sizeof(cstreamData));
  if (s == NULL)
    return cudaErrorMemoryAllocation;
  s->ev.status = C_RUN;
  s->id = stream_counter;
  stream_counter++;
  s->stream_priority = DEFAULT;
  create_KernelQueue(&(s->kernelQueue));

  INIT_LOCK(s->stream_lock);
  *pStream = (cudaStream_t)(s);

  return cudaSuccess;
}

cudaError_t cudaStreamDestroy(cudaStream_t stream) {
  cstreamData *s = (cstreamData *)(stream);

  free(s->kernelQueue);

  DESTROY_LOCK(s->stream_lock);

  free(s);

  return cudaSuccess;
}

cudaError_t cudaStreamSynchronize(cudaStream_t stream) {
  cstreamData *e = ((cstreamData *)(stream));
  MUTEX_LOCK(e->stream_lock);

  e->ev.status = C_SYNCHRONIZE;
  e->ev.numKernelsToWait = e->kernelQueue->waiting_count;
  MUTEX_UNLOCK(e->stream_lock);

  return cudaSuccess;
}

cudaError_t cudaGetDeviceCount(int *count) {
  // dummy value
  *count = 1;

  return cudaSuccess;
}

cudaError_t cudaGetDeviceProperties(cudaDeviceProp *deviceProp, int device) {

  // dummy values
  if (device == 0) {
    strcpy(deviceProp->name, "pthread");
    deviceProp->totalGlobalMem = 0;
    deviceProp->sharedMemPerBlock = 0;
    deviceProp->regsPerBlock = 0;
    deviceProp->warpSize = 0;
    deviceProp->memPitch = 0;
    deviceProp->maxThreadsPerBlock = 0;
    deviceProp->maxThreadsDim[0] = 1;
    deviceProp->maxThreadsDim[1] = 1;
    deviceProp->maxThreadsDim[2] = 1;

    deviceProp->maxGridSize[0] = 1;
    deviceProp->maxGridSize[1] = 1;
    deviceProp->maxGridSize[2] = 1;

    deviceProp->totalConstMem = 0;
    deviceProp->major = 0;
    deviceProp->minor = 0;
    deviceProp->clockRate = 0;
    deviceProp->textureAlignment = 0;
    deviceProp->deviceOverlap = false;
    deviceProp->multiProcessorCount = 0;
  }
  return cudaSuccess;
}

static cudaError_t lastError = cudaSuccess;
const char *cudaGetErrorString(cudaError_t error) {
  if (error == cudaSuccess) {
    return "cudaSuccess";
  }
  return "unknown";
}

cudaError_t cudaGetLastError(void) { 
  return lastError; 
}

static callParams callParamTemp;

/*
  Internal Cuda Library Functions
*/
extern "C" {

extern cudaError_t CUDARTAPI __cudaPopCallConfiguration(dim3 *gridDim,
                                                        dim3 *blockDim,
                                                        size_t *sharedMem,
                                                        void **stream) {
  //  printf("__cudaPopCallConfiguration: Grid: x:%d y:%d z:%d Block: %d, %d, %d
  //  ShMem: %lu\n",
  // gridDim->x, gridDim->y, gridDim->z, blockDim->x, blockDim->y, blockDim->z,
  // *sharedMem);

  *gridDim = callParamTemp.gridDim;
  *blockDim = callParamTemp.blockDim;
  *sharedMem = callParamTemp.shareMem;
  *stream = callParamTemp.stream;

  // printf("__cudaPopCallConfiguration After : Grid: x:%d y:%d z:%d Block: %d,
  // %d, %d ShMem: %lu\n", gridDim->x, gridDim->y, gridDim->z, blockDim->x,
  // blockDim->y, blockDim->z, *sharedMem);

  // exit(1);

  return cudaSuccess;
}

extern __host__ __device__ unsigned CUDARTAPI __cudaPushCallConfiguration(
    dim3 gridDim, dim3 blockDim, size_t sharedMem = 0, void *stream = 0) {

  // printf("__cudaPushCallConfiguration Grid: x:%d y:%d z:%d Block: %d, %d, %d
  // "
  //        "ShMem: %lu\n ",
  //        gridDim.x, gridDim.y, gridDim.z, blockDim.x, blockDim.y, blockDim.z,
  //        sharedMem);

  // memory checks allocations
  callParamTemp.gridDim = gridDim;

  // std::cout << "assign gridDim" << std::endl;

  callParamTemp.blockDim = blockDim;
  //  std::cout << "assign blockDim" << std::endl;
  callParamTemp.shareMem = sharedMem;
  //  std::cout << "assign shareMem" << std::endl;
  (callParamTemp.stream) = stream;

  //  printf("__cudaPushCallConfiguration After Grid: x:%d y:%d z:%d Block: %d,
  //  %d, %d ShMem: %lu\n",
  //   gridDim.x, gridDim.y, gridDim.z, blockDim.x, blockDim.y, blockDim.z,
  //   sharedMem);

  // return 0 continues the Pop
  return cudaSuccess;

  // return ne 0 skips the Pop
}
} // extern C

cudaError_t cudaLaunchKernel_vortex(                          
                             const char *func, //-> kernel_name
                             dim3 gridDim, 
                             dim3 blockDim,
                             void **args, 
                             size_t sharedMem,
                             cudaStream_t stream,
                             const int num_args
                             ) {

//open the file lookup.txt and load the content in the memory
//cpp hash table, look for the kernel name, and retrieve the kerenl index

//DEBUG PURPOSE
std::cout << "RUNTIME FUNCTION" << std::endl;
std::cout << "kernel_name: " << func << std::endl;
std::cout << "number of arguments: " << num_args << std::endl;

//reading lookup.txt
std::fstream readfile;
readfile.open("lookup.txt", std::ios::in);
std::string kernel_idx_tmp;
std::string kernel_name_tmp;

while(readfile >> kernel_idx_tmp)
{
  readfile >> kernel_name_tmp;
  readfile.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
  std::cout << "debug : " << std::string(func) << " vs " << kernel_name_tmp << std::endl;
  if(std::string(func) == kernel_name_tmp)
  {
    std::cout << "found the kernel name in the lookup file, it is " << func << " with the index of " << std::stoi(kernel_idx_tmp) << std::endl;
    break;
  }
  
}
readfile.close();                    
                         

  printf("cudaLaunchKernel: gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), sharedMem=%lu, num_args = %d\n",
    gridDim.x, gridDim.y, gridDim.z, blockDim.x, blockDim.y, blockDim.z, sharedMem, num_args);

  auto DC = DeviceContext::instance();
  
  int status = C_RUN;

  // upload kernel to device
  RT_CHECK(vx_upload_kernel_file(DC->device(), "./kernel.out"));
  
  // allocate staging buffer for kernel arguments
  size_t abuf_size = sizeof(kernel_arg_t) + ((num_args > 1) ? (sizeof(uint32_t) * (num_args - 1)) : 0);
  auto staging_buf = DC->staging_alloc(abuf_size);
  auto abuf_ptr = (kernel_arg_t*)vx_host_ptr(staging_buf);
  assert(abuf_ptr);

  printf("*** kernel arg=%p, size=%ld\n", abuf_ptr, abuf_size);

  // write context

  context_t ctx;
  memset(&ctx, 0, sizeof(ctx));
  ctx.num_groups[0] = gridDim.x;
  ctx.num_groups[1] = gridDim.y; 
  ctx.num_groups[2] = gridDim.z; 
  ctx.local_size[0] = blockDim.x;
  ctx.local_size[1] = blockDim.y;
  ctx.local_size[2] = blockDim.z;
  ctx.global_offset[0] = 0;
  ctx.global_offset[1] = 0;
  ctx.global_offset[2] = 0;

  memcpy(&abuf_ptr->ctx, &ctx, sizeof(context_t));
  
  // write the kerenel index here it retrives
  abuf_ptr->kernel_idx = std::stoi(kernel_idx_tmp);

  // Mark Debug Check 
  //printf("address_check 0x%x, 0x%x, %d\n", &(ctx.num_groups[2]), &(ctx.global_offset[0]), &(ctx.global_offset[0])-&(ctx.num_groups[2]));
  //printf("address_check 0x%x, 0x%x, %d\n", &(ctx.global_offset[1]), &(ctx.global_offset[2]), &(ctx.global_offset[0])-&(ctx.num_groups[2]));
  //printf("global_offset 0x%x, 0x%x, %x\n", ctx.global_offset[0], ctx.global_offset[1], ctx.global_offset[2]);

  printf("*** kernel ctx: num_groups[0]=%d, num_groups[1]=%d\n", abuf_ptr->ctx.num_groups[0],abuf_ptr->ctx.num_groups[1]);

  // write arguments

  for (int i = 0; i < num_args; ++i) {    
    memcpy(&abuf_ptr->args[i], args[i], sizeof(uint64_t));
    printf("*** cuda kernel args[%d]=0x%x\n", i, (uint32_t)abuf_ptr->args[i]);
  }  
 
  // upload kernel arguments
  RT_CHECK(vx_copy_to_dev(staging_buf, KERNEL_ARG_BASE_ADDR, abuf_size, 0));
  
  // start execution
  RT_CHECK(vx_start(DC->device()));

  // wait for the execution to complete
  RT_CHECK(vx_ready_wait(DC->device(), -1));

  return cudaSuccess;
}