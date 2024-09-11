#include "cudaRuntimeImpl.h"
#include "base_address.h"
#include "api.h"
#include "cuda_runtime.h"
#include "def.h"
#include "macros.h"
#include "structures.h"
#include <bits/stdint-uintn.h>
#include <cstddef>
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
#include <vector>
#include <map>

// Global variable to support CudaMemcpytoSymbol
std::vector<std::vector<uint64_t> >  memcpy_symbol;
std::vector<uint64_t> memcpy_symbol_single;
//create string vector
std::vector<std::string> symbol_name_vector;

#define RT_CHECK(_expr)                                         \
   do {                                                         \
     int _ret = _expr;                                          \
     if (0 == _ret)                                             \
       break;                                                   \
     printf("Error: '%s' returned %d!\n", #_expr, (int)_ret);   \
     std::abort();                                              \
   } while (false)


// Different structure based on the architecture
#ifdef VORTEX_ARCHITECTURE_64
  struct alignas(4) context_t {
    uint32_t num_groups[3];
    uint32_t global_offset[3];
    uint32_t local_size[3];
    char * printf_buffer;
    uint32_t printf_buffer_position;
    uint32_t printf_buffer_capacity;
    uint32_t work_dim;
  };
  
#else
  struct alignas(4) context_t {
    uint32_t num_groups[3];
    uint32_t global_offset[3];
    uint32_t local_size[3];
    uint32_t printf_buffer;
    uint32_t printf_buffer_position;
    uint32_t printf_buffer_capacity;
    uint32_t work_dim;
  };
#endif


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
    , staging_buf_(std::vector<uint8_t>())
    , staging_size_(0)
    , krnl_buffer_(nullptr)
    , args_buffer_(nullptr)
  {}

  ~DeviceContext() {
    if (device_ != nullptr) {
      // Cleanup buffers
      if (krnl_buffer_ != nullptr)
	vx_mem_free(krnl_buffer_);
      if (args_buffer_ != nullptr)
	vx_mem_free(args_buffer_);
      
      vx_dev_close(device_);
    }
  }

  void initialize() {
    if (device_ == nullptr) {
      RT_CHECK(vx_dev_open(&device_));
    }
  }

  vx_device_h device_;
  std::vector<uint8_t> staging_buf_;
  size_t staging_size_;

  // Buffers
  vx_buffer_h krnl_buffer_;
  vx_buffer_h args_buffer_;

  // Pointer manager
  std::map<void* , vx_buffer_h > ptr_map;
  
public:
  static DeviceContext* instance() {
    static DeviceContext s_inst;
    s_inst.initialize();
    return &s_inst;
  }

  vx_device_h device() {    
    return device_;
  }

  vx_buffer_h* krnl_buffer() {
    return &krnl_buffer_;
  }

  vx_buffer_h* args_buffer() {
    return &args_buffer_;
  }

  vx_buffer_h get_krnl_buf() {
    return krnl_buffer_;
  }

  vx_buffer_h get_args_buf() {
    return args_buffer_;
  }
  
  std::vector<uint8_t> staging_alloc(size_t size) {
    staging_buf_.resize(size);
    staging_size_ = size;
    return staging_buf_;
  }

  void dev_mem_alloc(int size, int flag, uint64_t* mem_addr) {
    vx_buffer_h mem_buffer = nullptr;

    // Allocate memory on device
    RT_CHECK(vx_mem_alloc(this->device(), size, flag, &mem_buffer));
    RT_CHECK(vx_mem_address(mem_buffer, mem_addr));  

    // Register pointer with its handler
    ptr_map[(void* )(* mem_addr)] = mem_buffer;
  }

  void dev_mem_free(void* mem_addr) {
    if (ptr_map.find(mem_addr) != ptr_map.end()) {
      vx_buffer_h mem_buffer = ptr_map[mem_addr];
      vx_mem_free(mem_buffer);

      // Unregister pointer
      ptr_map.erase(mem_addr);
    }
  }

  void copy_to_dev(uint64_t mem_addr, void* host_ptr, int count) {
    if (ptr_map.find((void* )mem_addr) != ptr_map.end()) {
      // RT_CHECK(vx_copy_to_dev(this->device(), ptr_map[(void* )mem_addr], (uint64_t)host_ptr, count));
      RT_CHECK(vx_copy_to_dev(ptr_map[(void* )mem_addr], host_ptr, 0, count));
    }
  }

  void copy_from_dev(uint64_t mem_addr, void* host_ptr, int count) {
    if (ptr_map.find((void* )mem_addr) != ptr_map.end()) {
      RT_CHECK(vx_copy_from_dev(host_ptr, ptr_map[(void* )mem_addr], 0, count));
    }
  }
};

auto DC_init = DeviceContext::instance();
uint64_t NUM_THREADS, NUM_WARPS, NUM_CORES;
int caps_return1 = vx_dev_caps(DC_init->device(), VX_CAPS_NUM_THREADS, &NUM_THREADS);
int caps_return2 = vx_dev_caps(DC_init->device(), VX_CAPS_NUM_WARPS, &NUM_WARPS);
int caps_return3 = vx_dev_caps(DC_init->device(), VX_CAPS_NUM_CORES, &NUM_CORES);

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
  // RT_CHECK(vx_mem_alloc(DC->device(), size, VX_MEM_TYPE_GLOBAL, &mem_addr));
  // RT_CHECK(vx_mem_alloc(DC->device(), size, VX_MEM_READ_WRITE, (void** )&mem_addr));
  DC->dev_mem_alloc(size, VX_MEM_READ_WRITE, &mem_addr);
  
  printf("cudaMalloc: size=%ld, mem_addr=%lu\n", size, mem_addr);
  *devPtr = (void*)mem_addr;
   return cudaSuccess;
}

cudaError_t cudaFree(void *devPtr) {
  auto DC = DeviceContext::instance(); 
  uint64_t mem_addr = (uint64_t)devPtr;  
  // vx_mem_free(DC->device(), mem_addr);
  DC->dev_mem_free(devPtr);
  
  printf("cudaFree: mem_addr=%lu\n", mem_addr);
  return cudaSuccess;
}

cudaError_t cudaMemset(void *devPtr, int value, size_t count) {  
  void* tmp_ptr;
  tmp_ptr = (void *) malloc(count);
  memset(tmp_ptr, value, count);
  auto DC = DeviceContext::instance();
  auto staging_buf = DC->staging_alloc(count);
  auto host_ptr = staging_buf.data();
  memcpy((char *)host_ptr, tmp_ptr, count);
  uint64_t mem_addr = (uint64_t)devPtr;
  // RT_CHECK(vx_copy_to_dev(DC->device(), mem_addr, host_ptr, count));
  DC->copy_to_dev(mem_addr, host_ptr, count);
  
  printf("cudaMemset: value=%d, dst=%lu, count=%ld\n", value, mem_addr, count);
  free(tmp_ptr);
  return cudaSuccess;
}

cudaError_t cudaMemcpy(void *dst, const void *src, size_t count, cudaMemcpyKind kind) {
  int vx_err; 
  if (kind == cudaMemcpyHostToHost) {
    memcpy(dst, src, count);
  } else if (kind == cudaMemcpyDeviceToHost) {
    auto DC = DeviceContext::instance();
    auto staging_buf = DC->staging_alloc(count);
    auto host_ptr = staging_buf.data();
    uint64_t mem_addr = (uint64_t)src;
    //  RT_CHECK(vx_copy_from_dev(DC->device(), host_ptr, mem_addr, count));
    DC->copy_from_dev(mem_addr, host_ptr, count);
    memcpy(dst, (char*)host_ptr, count);
    printf("cudamemcpyDeviceToHost: src=%lu, dst=%p, count=%ld\n", mem_addr, dst, count);
  } else if (kind == cudaMemcpyHostToDevice) {
    auto DC = DeviceContext::instance();
    auto staging_buf = DC->staging_alloc(count);
    auto host_ptr = staging_buf.data();
    memcpy((char *)host_ptr, src, count);
    uint64_t mem_addr = (uint64_t)dst;
    printf("(memcpy_) host_ptr value: %d %d, addr: %ld\n", *(char *)src, *(char *)host_ptr, host_ptr);
    // RT_CHECK(vx_copy_to_dev(DC->device(), mem_addr, host_ptr, count));
    DC->copy_to_dev(mem_addr, host_ptr, count);

    printf("cudaMemcpyHostToDevice: src=%p, dst=%lu, count=%ld\n", src, mem_addr, count);
  } else if (kind == cudaMemcpyDeviceToDevice) {
    auto DC = DeviceContext::instance();
    auto staging_buf = DC->staging_alloc(count);
    auto host_ptr = staging_buf.data();
    uint64_t mem_src_addr = (uint64_t)src;
    RT_CHECK(vx_copy_from_dev(DC->device(), host_ptr, mem_src_addr, count));
    uint64_t mem_dst_addr = (uint64_t)dst;
    // RT_CHECK(vx_copy_to_dev(DC->device(), mem_dst_addr, host_ptr, count));
    DC->copy_to_dev(mem_dst_addr, host_ptr, count);
    
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
                                    cudaMemcpyKind kind,
                                    void *symbol) {
                                      
  assert(offset == 0 && "DO not support offset !=0\n");

  //symbol is a pointer to a string 
  //print the string that symbol points to
  printf("(CudaMemcpytoSymbol) symbol name: %s\n", symbol);

  // if vector length of symbol_name_vector == 0
  //printf("symbol_name_vector.size(): %lu\n", symbol_name_vector.size());
  if(symbol_name_vector.size() == 0)
  {
    // cast symbol to string
    std::string symbol_name((char*)symbol);
    //split the string by space
    std::string delimiter = " ";
    std::string token;
    size_t pos = 0;
    while ((pos = symbol_name.find(delimiter)) != std::string::npos) {
      token = symbol_name.substr(0, pos);
      symbol_name_vector.push_back(token);
      symbol_name.erase(0, pos + delimiter.length());
    }
  }

  //pop first element in symbol_name_vector
  std::string symbol_name_looking = symbol_name_vector[0];
  printf("symbol name looking: %s\n", symbol_name_looking);  
  
  //open file lookup_global_symbols.txt to read
  std::fstream readfile;
  readfile.open("lookup_global_symbols.txt", std::ios::in);
  std::string symbol_type_tmp;
  std::string symbol_name_tmp;
  std::string symbol_addr_tmp;
  
  //print src value
  printf("src value at initial memcpytosymbol, addr: %p\n", src);
  printf("src value at initial memcpytosymbol %f\n", *((float*)src+1));

  while(readfile >> symbol_addr_tmp)
  {
    readfile >> symbol_type_tmp;
    std::getline(readfile, symbol_name_tmp);
    symbol_name_tmp = symbol_name_tmp.substr(1, symbol_name_tmp.size()-1);  
  
    std::cout << "debug : " << symbol_name_looking << " vs " << symbol_name_tmp << std::endl;

    if(symbol_name_looking == symbol_name_tmp)
    {
      std::cout << "found the symbol name in the lookup file, it is " << symbol_name_looking << " with the address of " << symbol_addr_tmp << std::endl;
      readfile.close();
      symbol_name_vector.erase(symbol_name_vector.begin());
      break;
    }
  }

  int vx_err; 
  //cast string(in hex) to uint64_t
  uint64_t symbol_addr = std::stoull(symbol_addr_tmp, nullptr, 16);

  // allocate a device memory(temporary) and copy the data from host to device
  auto DC = DeviceContext::instance();
  uint64_t mem_addr;  
  // RT_CHECK(vx_mem_alloc(DC->device(), count, VX_MEM_TYPE_GLOBAL, &mem_addr));
  RT_CHECK(vx_mem_alloc(DC->device(), count, VX_MEM_READ_WRITE, (void** )&mem_addr));
  
  printf("(cudamemcpytosymbol) cudaMalloc: size=%ld, mem_addr=%lu\n", count, mem_addr);
    
  // copy the host data to device
  auto staging_buf = DC->staging_alloc(count);
  auto host_ptr = staging_buf.data();

  memcpy((char *)host_ptr, src, count);
  // RT_CHECK(vx_copy_to_dev(DC->device(), mem_addr, host_ptr, count));
  DC->copy_to_dev(mem_addr, host_ptr, count);
  
  printf("(cudamemcpytosymbol) cudaMemcpyHostToDevice: src=%p, dst=%lu, count=%ld\n", src, mem_addr, count);

  memcpy_symbol_single.push_back(std::stoull(symbol_addr_tmp, nullptr, 16));
  memcpy_symbol_single.push_back((uint64_t)mem_addr);
  memcpy_symbol_single.push_back((uint64_t)count);
  memcpy_symbol_single.push_back((uint64_t)offset);
  memcpy_symbol.push_back(memcpy_symbol_single);
  memcpy_symbol_single.clear();
              
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
  
  while(readfile >> kernel_idx_tmp) {
    readfile >> kernel_name_tmp;
    readfile.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    std::cout << "debug : " << std::string(func) << " vs " << kernel_name_tmp << std::endl;
    if(std::string(func) == kernel_name_tmp) {
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
  RT_CHECK(vx_upload_kernel_file(DC->device(), "./kernel.vxbin", DC->krnl_buffer()));
  
  // allocate staging buffer for kernel arguments
  size_t abuf_size = sizeof(kernel_arg_t) + ((num_args > 1) ? (sizeof(uint64_t) * (num_args - 1)) : 0);
  printf("(debug) abuf_size = %ld\n", abuf_size);
  auto staging_buf = DC->staging_alloc(abuf_size);

  auto abuf_ptr = (kernel_arg_t*)staging_buf.data();
  //auto abuf_ptr = (kernel_arg_t*)vx_host_ptr(staging_buf);
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
  //printf("test:: kernel_idx %d sizes: %d %d \n", abuf_ptr->kernel_idx, sizeof(kernel_arg_t), sizeof(context_t));
  //printf("address_check 0x%x, 0x%x, %d\n", &(ctx.num_groups[2]), &(ctx.global_offset[0]), &(ctx.global_offset[0])-&(ctx.num_groups[2]));
  //printf("address_check 0x%x, 0x%x, %d\n", &(ctx.global_offset[1]), &(ctx.global_offset[2]), &(ctx.global_offset[0])-&(ctx.num_groups[2]));
  //printf("global_offset 0x%x, 0x%x, %x\n", ctx.global_offset[0], ctx.global_offset[1], ctx.global_offset[2]);

  printf("*** kernel ctx: num_groups[0]=%d, num_groups[1]=%d\n", abuf_ptr->ctx.num_groups[0],abuf_ptr->ctx.num_groups[1]);

  // write arguments
  for (int i = 0; i < num_args; ++i) {    
    memcpy(&abuf_ptr->args[i], args[i], sizeof(uint64_t)); // 여기 체크 필요
    printf("*** cuda kernel args[%d]=0x%llx\n", i, (uint64_t)abuf_ptr->args[i]);
  }  
  
  // upload kernel arguments
  // RT_CHECK(vx_copy_to_dev(DC->device(), KERNEL_ARG_BASE_ADDR, abuf_ptr, abuf_size));
  RT_CHECK(vx_upload_bytes(DC->device(), abuf_ptr, abuf_size, DC->args_buffer()));

  /*
  // upload additional information for cudaMemcpytoSymbol
  
  int abuf_size_additional = (1 + memcpy_symbol.size() * 3) * sizeof(uint64_t);
  auto staging_buf_additional = DC->staging_alloc(abuf_size_additional);
  auto abuf_ptr_additional = (uint64_t*)staging_buf_additional.data();
  abuf_ptr_additional[0] = memcpy_symbol.size();
  //printf("memcpy_symbol.size(): %lu\n", memcpy_symbol.size());
  int abuf_ptr_additional_idx = 1;
  while (abuf_ptr_additional_idx < memcpy_symbol.size()+1)
  {
    memcpy(&abuf_ptr_additional[abuf_ptr_additional_idx*3-2], &memcpy_symbol[abuf_ptr_additional_idx-1][0], sizeof(uint64_t));
    memcpy(&abuf_ptr_additional[abuf_ptr_additional_idx*3-1], &memcpy_symbol[abuf_ptr_additional_idx-1][1], sizeof(uint64_t));
    memcpy(&abuf_ptr_additional[abuf_ptr_additional_idx*3], &memcpy_symbol[abuf_ptr_additional_idx-1][2], sizeof(uint64_t));
    abuf_ptr_additional_idx++;
  }

  RT_CHECK(vx_copy_to_dev(DC->device(), KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR, abuf_ptr_additional, abuf_size_additional));
  */

  printf("uploaded args\n");
  
  // start execution
  RT_CHECK(vx_start(DC->device(), DC->get_krnl_buf(), DC->get_args_buf()));

  printf("wait device\n");
  // wait for the execution to complete
  RT_CHECK(vx_ready_wait(DC->device(), VX_MAX_TIMEOUT));

  printf("sync device\n");
  
  // dump performance counters for every kernel to a file
    
    std::string filename = "perf_counter_" + std::to_string(NUM_CORES) + "C_" + std::to_string(NUM_WARPS) + "W_" + std::to_string(NUM_THREADS) + "T_thread_map_mem.txt";
    std::cout << "output file: " << filename << std::endl;
    //convert filename to char* with its content
    char filename_char[filename.size() + 1];
    strcpy(filename_char, filename.c_str());
  
    FILE *outputFile = fopen(filename_char, "a");
    if (outputFile == NULL) {
        perror("Error opening the output file");
    }
  vx_dump_perf(DC->device(), outputFile);

  return cudaSuccess;
}
