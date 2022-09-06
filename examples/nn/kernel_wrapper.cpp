#include <stdint.h>
#include <vx_print.h>
#include <vx_intrinsics.h>
#include <vx_spawn.h>
#include <stdint.h>

#define KERNEL_ARG_BASE_ADDR 0x7ffff000

typedef struct {
  context_t ctx; 
  uint64_t args[0]; 
} kernel_arg_t; 

int grid_size_x;
int grid_size_y;
int grid_size_z;

int block_size_x;
int block_size_y;
int block_size_z;

int block_size;

int __thread block_index_x;
int __thread block_index_y;

extern  "C" {
 extern void *  _Z6euclidP7latLongPfiff_wrapper(void **args);
}


void cuda__Z6euclidP7latLongPfiff_wrapper(
   const void * args, 
   const context_t* /*context*/, 
   uint32_t group_x, 
   uint32_t group_y, 
   uint32_t /*group_z*/) { 
     block_index_x = group_x;
     block_index_y = group_y;
     _Z6euclidP7latLongPfiff_wrapper((void **)args);
}


 
vx_spawn_kernel_cb callbacks[] = {
 cuda__Z6euclidP7latLongPfiff_wrapper}; 



 
int main() {
   kernel_arg_t* kernel_arg; 
   context_t* ctx; 
   uint32_t* args; 
   for (int i=0; i<1; i++) { 
     kernel_arg = (kernel_arg_t*)KERNEL_ARG_BASE_ADDR + sizeof(kernel_arg_t*) * i; 
     ctx = &kernel_arg->ctx; 
     args = (uint32_t*)kernel_arg->args; 
     grid_size_x = ctx->num_groups[0];
     grid_size_y = ctx->num_groups[1];
     grid_size_z = ctx->num_groups[2];

     block_size_x = ctx->local_size[0];
     block_size_y = ctx->local_size[1];
     block_size_z = ctx->local_size[2];

     block_size = ctx->local_size[0] * ctx->local_size[1]; 
     vx_printf( "gridDim=(0x%x, 0x%x, 0x%x), blockDim=(0x%x, 0x%x, 0x%x), args=(0x%x, 0x%x, 0x%x, 0x%x) " , 
     ctx->num_groups[0], ctx->num_groups[1], ctx->num_groups[2], 
     ctx->local_size[0], ctx->local_size[1], ctx->local_size[2], 
     args[0], args[1], args[2], args[3]); 
     //vx_printf("sth is wrong\n");
     vx_spawn_kernel(ctx, callbacks[i], args); 

 } 
  return 0;
}