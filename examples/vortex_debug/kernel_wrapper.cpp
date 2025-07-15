#include <stdint.h>
#include <vx_print.h>
#include <vx_intrinsics.h>
#include <vx_spawn.h>
#include <stdint.h>
#include <string.h>

#define KERNEL_ARG_BASE_ADDR 6442446848


struct alignas(8) context_t { 
uint32_t num_groups[3]; 
uint32_t global_offset[3]; 
uint32_t local_size[3]; 
char * printf_buffer; 
uint32_t printf_buffer_position; 
uint32_t printf_buffer_capacity; 
uint32_t work_dim; 
}; 

typedef struct {
    context_t ctx;
    int kernel_idx;
    int num_args;
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
int __thread block_index_z;
int __thread thread_id_x;
int __thread thread_id_y;
int __thread thread_id_z;


 extern "C" {
<<<<<<< Updated upstream
    extern void cgkernelv_wrapper(void *args);
}

void cuda_cgkernelv_wrapper(void* args) {
=======
    extern void saxpy2DiiifPfS__wrapper(void *args);
}

void cuda_saxpy2DiiifPfS__wrapper(void* args) {
    block_index_x = blockIdx.x;
    block_index_y = blockIdx.y;
    block_index_z = blockIdx.z;

    thread_id_x = threadIdx.x;
    thread_id_y = threadIdx.y;
    thread_id_z = threadIdx.z;

    saxpy2DiiifPfS__wrapper((void **)args);
}

vx_kernel_func_cb callbacks[] = {
    cuda_saxpy2DiiifPfS__wrapper, 
};

int main() {
    vx_printf("kernel_wrapper: main\n");
    kernel_arg_t* kernel_arg = (kernel_arg_t*)csr_read(VX_CSR_MSCRATCH); 
    auto ctx = &kernel_arg->ctx; 
    auto num_args = kernel_arg->num_args;
    auto args = (uint64_t*)kernel_arg->args;
    auto memcpy_symbol_array = (uint64_t*)kernel_arg->args + num_args;
    grid_size_x = ctx->num_groups[0];
    grid_size_y = ctx->num_groups[1];
    grid_size_z = ctx->num_groups[2];

    block_size_x = ctx->local_size[0];
    block_size_y = ctx->local_size[1];
    block_size_z = ctx->local_size[2];

    block_size = ctx->local_size[0] * ctx->local_size[1];

if (memcpy_symbol_array[0] != 0) {
    vx_printf("CHECK: cudamemcpytosymbol, number of cudamemcpytosymbol=%d \n", memcpy_symbol_array[0]);
    int memcpy_symbol_idx = 0;
    while (memcpy_symbol_idx < memcpy_symbol_array[0]) {
        auto dst_addr = (uint64_t*)memcpy_symbol_array[memcpy_symbol_idx * 3 + 1];
        auto src_addr = (uint64_t*)memcpy_symbol_array[memcpy_symbol_idx * 3 + 2];
        auto size = (size_t)memcpy_symbol_array[memcpy_symbol_idx * 3 + 3];
        memcpy(dst_addr, src_addr, size);
        vx_printf("memcpy_symbol[%d]: dst_addr=0x%p, src_addr=0x%p, size=%lu\n", memcpy_symbol_idx, dst_addr, src_addr, size);
        memcpy_symbol_idx++;}}
    vx_printf("sizeof everything %d %d %d\n", sizeof(*kernel_arg), sizeof(*ctx), sizeof(ctx->printf_buffer)); 
    vx_printf("base: 0x%lx\n", KERNEL_ARG_BASE_ADDR); 
    vx_printf("kernel#%d (callback:0x%lx): gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), args=(0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx)\n", 
        kernel_arg->kernel_idx, callbacks[kernel_arg->kernel_idx], ctx->num_groups[0], ctx->num_groups[1], ctx->num_groups[2], 
        ctx->local_size[0], ctx->local_size[1], ctx->local_size[2],
        args[0], args[1], args[2], args[3], args[4], args[5]);
    vx_printf("workdim=%d\n", ctx->work_dim);
    vx_printf("threadIdx.x=%d threadIdx.y=%d threadIdx.z=%d\n", threadIdx.x, threadIdx.y, threadIdx.z);
vx_printf("execute something\n");
    return vx_spawn_threads(3, ctx->num_groups, ctx->local_size, (vx_kernel_func_cb)callbacks[kernel_arg->kernel_idx], args); 

}

