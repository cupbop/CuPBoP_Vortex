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




/* Maximum kernels occupancy */
#define MAX_KERNELS 16

/* default WG size in each dimension & total WG size.
 * this should be reasonable for CPU */
#define DEFAULT_WG_SIZE 4096

#define CUDA_FILENAME_LENGTH 1024 


// location is local memory where to store kernel parameters
#define KERNEL_ARG_BASE_ADDR 0x7fff0000


#define PRINT_BUFFER_SIZE (1024 * 1024)



/* global data structure */ 
bool g_dev_initialized = false; 
typedef struct vx_device_data_t { 
  vx_device_h vx_device;
  size_t vx_print_buf_d;
  vx_buffer_h vx_print_buf_h;
  cu_kernel *current_kernel;
  uint32_t printf_buffer;
  uint32_t printf_buffer_position;   
}vx_device_data_t;


typedef struct vx_buffer_data_t {
  vx_buffer_h staging_buf;
  size_t dev_mem_addr;
}vx_buffer_data_t;

typedef struct context_t{
  uint32_t num_groups[3];
  uint32_t global_offset[3];
  uint32_t local_size[3];
  char * printf_buffer;
  uint32_t *printf_buffer_position;
  uint32_t printf_buffer_capacity;
  uint32_t work_dim;
}context_t;

typedef void (*pfn_workgroup_func) (
   const void * /* args */,
   const struct context_t * /* context */,
   uint32_t /* group_x */,
   uint32_t /* group_y */,
   uint32_t /* group_z */
 );

static size_t ALIGNED_CTX_SIZE = 4 * ((sizeof(context_t) + 3) / 4);

vx_device_data_t g_vx_device_data; 

cudaError_t cudaGetDevice(int *devPtr) { *devPtr = 0; }
const char *cudaGetErrorName(cudaError_t error) { return "SUCCESS\n"; }
cudaError_t cudaDeviceReset(void) { scheduler_uninit(); }
cudaError_t cudaDeviceSynchronize(void) { cuSynchronizeBarrier(); }
cudaError_t cudaThreadSynchronize(void) { cuSynchronizeBarrier(); }

cudaError_t cudaFreeHost(void *devPtr) { free(devPtr); }
bool VX_init(void); 

cudaError_t cudaLaunchKernel(const void *func, dim3 gridDim, dim3 blockDim,
                             void **args, size_t sharedMem,
                             cudaStream_t stream) {
  // if scheduler is null init device
   printf(
       "cudaLaunchKernel : Grid: x:%d y:%d z:%d Block: %d, %d, %d ShMem:%lu\n", gridDim.x, gridDim.y, gridDim.z, blockDim.x, blockDim.y, blockDim.z, sharedMem);

  if (!g_dev_initialized) g_dev_initialized = VX_init(); 
  cu_kernel *ker =
      create_kernel(func, gridDim, blockDim, args, sharedMem, stream);

  int lstatus = cuLaunchKernel(&ker);



  // std::cout << "ret cudaLKernel" << std::endl;
}





cudaError_t cudaMalloc(void **devPtr, size_t size) {
  printf("g_dev_initialized:%d\n", g_dev_initialized);
  if (!g_dev_initialized) g_dev_initialized = VX_init(); 
  
/*
 auto d = (vx_device_data_t *)device->data;
  void *b = NULL;
  pocl_global_mem_t *mem = device->global_memory;
  int err;

*/

  vx_buffer_h staging_buf;
 
  int err; 
  
  err = vx_alloc_shared_mem(g_vx_device_data.vx_device, size, &staging_buf);
  if (err != 0)
    return cudaErrorMemoryAllocation;


  size_t dev_mem_addr;
  err = vx_alloc_dev_mem(g_vx_device_data.vx_device, size, &dev_mem_addr);
  if (err != 0) {
    vx_buf_release(staging_buf);
    return cudaErrorMemoryAllocation;
  }

  auto buf_data = new vx_buffer_data_t();
  buf_data->staging_buf = staging_buf;
  buf_data->dev_mem_addr = dev_mem_addr;

  *devPtr = buf_data; 

   return cudaSuccess; 
/*
  if (flags & CL_MEM_COPY_HOST_PTR) {
    auto buf_ptr = vx_host_ptr(staging_buf);
    memcpy((void*)buf_ptr, host_ptr, size);
    err = vx_copy_to_dev(staging_buf, dev_mem_addr, size, 0);
    if (err != 0) {
      vx_buf_release(staging_buf);
      return nullptr;
    }
  }

  auto buf_data = new vx_buffer_data_t();
  buf_data->staging_buf = staging_buf;
  buf_data->dev_mem_addr = dev_mem_addr;

  return buf_data;
*/
  /*
  *devPtr = malloc(size);
  if (devPtr == NULL)
    return cudaErrorMemoryAllocation;
  return cudaSuccess; 
  */
}
cudaError_t cudaMemset(void *devPtr, int value, size_t count) {
  memset(devPtr, value, count);
  return cudaSuccess;
}
cudaError_t cudaMemcpy(void *dst, const void *src, size_t count,
                       cudaMemcpyKind kind) {
  int vx_err; 
  if (kind == cudaMemcpyHostToHost) {
    memcpy(dst, src, count);
  } else if (kind == cudaMemcpyDeviceToHost) {
    //// Copy bytes from buffer to device local memory
// int vx_copy_to_dev(vx_buffer_h hbuffer, uint64_t dev_maddr, uint64_t size, uint64_t src_offset);

// Copy bytes from device local memory to buffer
// int vx_copy_from_dev(vx_buffer_h hbuffer, uint64_t dev_maddr, uint64_t size, uint64_t dst_offset);

  auto buf_data = (vx_buffer_data_t *)src; 
  int offset = 0; 
    vx_err = vx_copy_from_dev(buf_data->staging_buf, buf_data->dev_mem_addr, count, 0);
    assert (0 == vx_err); 
    auto buf_ptr = vx_host_ptr(buf_data->staging_buf);
    assert(buf_ptr);
    memcpy(dst, (char *)buf_ptr + offset, count);
    // how does the code know which device accessing the memory
    // memcpy(dst, src, count);
    printf("cdamemcpyDeviceToHost is called src:%p st %p buf_ptr:%p\n", src, dst, buf_data);
  } else if (kind == cudaMemcpyHostToDevice) {
    // how does the code know which device accessing the memory
  int offset = 0; 
    auto buf_data = (vx_buffer_data_t *)dst; 
    auto buf_ptr =  vx_host_ptr(buf_data->staging_buf);
    memcpy((char *)buf_ptr + offset, src, count);
  auto vx_err = vx_copy_to_dev(buf_data->staging_buf, buf_data->dev_mem_addr, count, 0);
  assert(0 == vx_err);
    printf("cdamemcpyHostTodevice is called src:%p dst %p buf_ptr:%p\n", src, dst, buf_data);
    // memcpy(dst, src, count)
  } else if (kind == cudaMemcpyDeviceToDevice) {
// need to implement from device to host and then host to device 
    memcpy(dst, dst, count);
  } else if (kind == cudaMemcpyDefault) {
    memcpy(dst, src, count);
  }
  return cudaSuccess;
}

cudaError_t cudaMemcpyToSymbol_host(void *dst, const void *src, size_t count,
                                    size_t offset, cudaMemcpyKind kind) {
  assert(offset == 0 && "DO not support offset !=0\n");
  memcpy(dst, src + offset, count);
  return cudaSuccess;
}

cudaError_t cudaSetDevice(int device) {
  // error checking
  // std::cout << "cudaSetDevice Called" << std::endl;
  init_device();
  // std::cout << "cudaSetDevice Ret" << std::endl;
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
}

cudaError_t cudaGetDeviceCount(int *count) {
  // dummy value
  *count = 1;
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
    return "Cuda Get Error Success";
  }
}

cudaError_t cudaGetLastError(void) { return lastError; }

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
}


cudaError_t cudaFree(void *devPtr) { 
  
  // free(devPtr); 
  auto buf_data = (vx_buffer_data_t *)devPtr; 
  vx_buf_release(buf_data->staging_buf);
  
  }


/* initialize the Vortex device */ 

bool VX_init(void)
{
  
  vx_device_h vx_device;
  printf("vx_init\n");
  int err = vx_dev_open(&vx_device);

  if (err !=0)
    return 0; 
  printf("VX device is opened\n");

  // probably need to allocate print buffer locations 


  g_vx_device_data.vx_device = vx_device; 
  /*
  if (err != 0) {
    free(d);
    return CL_DEVICE_NOT_FOUND;
  }
  */
// need to copy vx_device contents to a cuda device structure 
return 1; 

}



/*
    Create Kernel

*/
static int kernelIds = 0;
cu_kernel *create_kernel(const void *func, dim3 gridDim, dim3 blockDim,
                         void **args, size_t sharedMem, cudaStream_t stream) {
  cu_kernel *ker = (cu_kernel *)calloc(1, sizeof(cu_kernel));


  // set the function pointer
  ker->start_routine = (void *(*)(void *))func;

  ker->args = args;

  // exit(1);
  ker->gridDim = gridDim;
  ker->blockDim = blockDim;

  ker->shared_mem = sharedMem;

  // std::cout << "stream is null" << std::endl;
  ker->stream = stream;
  // std::cout << "stream is null" << std::endl;

  ker->blockId = 0;

  ker->totalBlocks = gridDim.x * gridDim.y * gridDim.z;

  ker->N = blockDim.x * blockDim.y * blockDim.z;

  ker->kernelId = kernelIds;
  kernelIds += 1;

  ker->blockSize = blockDim.x * blockDim.y * blockDim.z;

  return ker;
}


int cuLaunchKernel(cu_kernel **k) {
  int err; 
  // if (!scheduler) {
    // init_device();
 //  }
  // Calculate Block Size N/numBlocks

  if (!g_dev_initialized) g_dev_initialized = VX_init(); 

  struct vx_device_data_t *d = &g_vx_device_data; 

  cu_kernel *kernel = *k;
  int status = C_RUN;
  
     
    // create data structure to pass device 
    uint32_t args_base_addr = KERNEL_ARG_BASE_ADDR;
    int abuf_size= sizeof(*(kernel->args)) + ALIGNED_CTX_SIZE; 

    vx_buffer_h staging_buf;
    err = vx_alloc_shared_mem(d->vx_device, abuf_size, &staging_buf);

    auto abuf_ptr = (uint8_t*)vx_host_ptr(staging_buf);
    assert(abuf_ptr);

  // num args: 
  // num locals 
 // upload kernel arguments buffer
 // create ctx data structor to pass the information into RT 
      context_t ctx;

  ctx.num_groups[0] = kernel->gridDim.x;
  ctx.num_groups[1] = kernel->gridDim.y; 
  ctx.num_groups[2] = kernel->gridDim.z; 


  memset(abuf_ptr, 0, ALIGNED_CTX_SIZE);
  memcpy(abuf_ptr, &ctx, sizeof(context_t));
  

  // write arguments 

    memcpy(abuf_ptr + ALIGNED_CTX_SIZE, kernel->args, sizeof(*(kernel->args)));

    assert(0 == err);

printf("*** ctx=:%p size:%ld abuf_size:%d\n", abuf_ptr, ALIGNED_CTX_SIZE, abuf_size);

    err = vx_copy_to_dev(staging_buf, args_base_addr, abuf_size, 0);
    assert(0 == err);

 
    // upload kernel to device
    if (NULL == d->current_kernel 
     || d->current_kernel != kernel) {    
       d->current_kernel = kernel;
       // char program_bin_path[CUDA_FILENAME_LENGTH];
      char program_bin_path[15]="./a.out.vortex";
     //  pocl_cache_final_binary_path (program_bin_path, program, dev_i, kernel, NULL, 0);
      err = vx_upload_kernel_file(d->vx_device, program_bin_path);      
      assert(0 == err);
      printf("call vortex binary\n");
    }
  
  err = vx_start(d->vx_device);
  assert(0 == err);

  // wait for the execution to complete
  err = vx_ready_wait(d->vx_device, -1);
  assert(0 == err);


  // flush print buffer 
  /* need to fix this : Hyesoon 
  {
    auto print_ptr = (uint8_t*)vx_host_ptr(d->vx_print_buf_h);
    err = vx_copy_from_dev(d->vx_print_buf_h, d->vx_print_buf_d + PRINT_BUFFER_SIZE, sizeof(uint32_t), PRINT_BUFFER_SIZE);
    assert(0 == err);
    uint32_t print_size = *(uint32_t*)(print_ptr + PRINT_BUFFER_SIZE);
    if (print_size != 0) {
      err = vx_copy_from_dev(d->vx_print_buf_h, d->vx_print_buf_d, print_size, 0);
      assert(0 == err);      
      
      write (STDOUT_FILENO, print_ptr, print_size);
      
      memset(print_ptr + PRINT_BUFFER_SIZE, 0, sizeof(uint32_t));
      err = vx_copy_to_dev(d->vx_print_buf_h, d->vx_print_buf_d, sizeof(uint32_t), PRINT_BUFFER_SIZE);
      assert(0 == err);
    }
  }
*/ 
  /* insert the task to the scheduler queue */ 

  /*
  MUTEX_LOCK(scheduler->work_queue_lock);
  scheduler->num_kernel_queued += 1;
  MUTEX_UNLOCK(scheduler->work_queue_lock);
  */


// copy from void pocl_vortex_run(void *data, _cl_command_node *cmd) {
  // stream == 0 add to the kernelQueue

  /*
  if (ker->stream == 0) {
    // float** t1 = (float**)*(ker->args + 0);
    // printf("cuLaunchKernel Test Args 1: %p \n ", (void *) &t1);
    // printf("cuLaunchKernel Test Args 1: %p \n ", (void *) *(ker->args + 0));
    // float* t2 = *(t1);
    // printf("cuLaunchkernel G Test Args: %p, val: %f\n ",(void *) &t2, *t2);
    schedulerEnqueueKernel(k);
  } else {
    // add to it's stream queue
    // stream queue can be waiting or running with or without tasks
    MUTEX_LOCK(((cstreamData *)(ker->stream))->stream_lock);
    status = ((cstreamData *)(ker->stream))->ev.status;

    // if stream queue status is run (first kernel) (enqueue to the kernel
    // queue)
    cstreamData *e = ((cstreamData *)(ker->stream));
    // synchronized is called after no job in the queue so stream is stuck on
    // synchronize
    // printf("this way sync\n");
    if (e->ev.status == C_SYNCHRONIZE) {
      if ((e->kernelQueue->finish_count) == (e->kernelQueue->kernel_count)) {
        e->ev.status = C_RUN;
      }
    }

    if (e->ev.status == C_RUN) {
      // change the status to wait
      e->ev.status == C_WAIT;
      MUTEX_UNLOCK(((cstreamData *)(ker->stream))->stream_lock);
      // printf("this way enqueue\n");
      schedulerEnqueueKernel(&ker);
    } else {
      // the status of stream queue is wait so just enqueue to the stream
      // printf("this way enqwlijs\n");
      enqueueKernel(&((cstreamData *)(ker->stream))->kernelQueue, &ker);
      MUTEX_UNLOCK(((cstreamData *)(ker->stream))->stream_lock);
    }
  }
  */
}
