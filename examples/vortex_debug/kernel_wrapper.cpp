#include <stdint.h>
#include <vx_print.h>
#include <vx_intrinsics.h>
#include <vx_spawn.h>
#include <stdint.h>
#include <string.h>

#define KERNEL_ARG_BASE_ADDR 6442446848
#define KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR 6442450432

typedef struct {
    context_t ctx;
    int kernel_idx;
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


 extern "C" {
    extern void N3cub11EmptyKernelIvEEvv_wrapper(void *args);
    extern void QueryKernelILi128ELi4EEvPiS0_S0_S0_iPy_wrapper(void *args);
}

void cuda_N3cub11EmptyKernelIvEEvv_wrapper(
    const void * args, 
    const context_t* /*context*/, 
    uint32_t group_x, 
    uint32_t group_y, 
    uint32_t /*group_z*/)
{
    block_index_x = group_x;
    block_index_y = group_y;
    block_index_z = 0;

    vx_printf("kernel_warpper: group=(%d, %d)\n", group_x, group_y);

    N3cub11EmptyKernelIvEEvv_wrapper((void **)args);
}

void cuda_QueryKernelILi128ELi4EEvPiS0_S0_S0_iPy_wrapper(
    const void * args, 
    const context_t* /*context*/, 
    uint32_t group_x, 
    uint32_t group_y, 
    uint32_t /*group_z*/)
{
    block_index_x = group_x;
    block_index_y = group_y;
    block_index_z = 0;

    vx_printf("kernel_warpper: group=(%d, %d)\n", group_x, group_y);

    QueryKernelILi128ELi4EEvPiS0_S0_S0_iPy_wrapper((void **)args);
}

vx_spawn_kernel_cb callbacks[] = {
    cuda_N3cub11EmptyKernelIvEEvv_wrapper, 
    cuda_QueryKernelILi128ELi4EEvPiS0_S0_S0_iPy_wrapper, 
};

int main() {
    auto kernel_arg = (kernel_arg_t*)KERNEL_ARG_BASE_ADDR; 
    auto ctx = &kernel_arg->ctx; 
    auto args = (uint64_t*)kernel_arg->args;

    grid_size_x = ctx->num_groups[0];
    grid_size_y = ctx->num_groups[1];
    grid_size_z = ctx->num_groups[2];

    block_size_x = ctx->local_size[0];
    block_size_y = ctx->local_size[1];
    block_size_z = ctx->local_size[2];

    block_size = ctx->local_size[0] * ctx->local_size[1];

    auto additional_info = (uint64_t*)KERNEL_ARG_ADDITIONAL_INFO_BASE_ADDR; 
    if (additional_info[0] != 0) {
       vx_printf("CHECK: cudamemcpytosymbol");
       int additional_info_idx = 0;
       while (additional_info_idx < additional_info[0]) {
           auto dst_addr = (uint64_t*)additional_info[additional_info_idx * 3 + 1];
           auto src_addr = (uint64_t*)additional_info[additional_info_idx * 3 + 2];
           auto size = (size_t)additional_info[additional_info_idx * 3 + 3];
           memcpy(dst_addr, src_addr, size);
           additional_info_idx++;}}

    vx_printf("sizeof everything %d %d %d\n", sizeof(*kernel_arg), sizeof(*ctx), sizeof(ctx->printf_buffer)); 
    vx_printf("base: 0x%lx\n", KERNEL_ARG_BASE_ADDR); 
    vx_printf("kernel#%d (callback:0x%lx): gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), args=(0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx)\n", 
        kernel_arg->kernel_idx, callbacks[kernel_arg->kernel_idx], ctx->num_groups[0], ctx->num_groups[1], ctx->num_groups[2], 
        ctx->local_size[0], ctx->local_size[1], ctx->local_size[2],
        args[0], args[1], args[2], args[3], args[4], args[5]);
    vx_printf("workdim=%d\n", ctx->work_dim);

    vx_spawn_kernel(ctx, callbacks[kernel_arg->kernel_idx], args);

    // Copy back the additional info (changed by the kernel, Cudamemcpytosymbol)
    if (additional_info[0] != 0) {
       int additional_info_idx = 0;
       while (additional_info_idx < additional_info[0]) {
           auto src_addr = (uint64_t*)additional_info[additional_info_idx * 3 + 1];
           auto dst_addr = (uint64_t*)additional_info[additional_info_idx * 3 + 2];
           auto size = (size_t)additional_info[additional_info_idx * 3 + 3];
           memcpy(dst_addr, src_addr, size);
           additional_info_idx++;}}
    return 0;
}

