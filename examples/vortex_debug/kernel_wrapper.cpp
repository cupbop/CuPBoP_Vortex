#include <stdint.h>
#include <vx_print.h>
#include <vx_intrinsics.h>
#include <vx_spawn.h>
#include <stdint.h>

#define KERNEL_ARG_BASE_ADDR 2147479552

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
    extern void _Z6KernelP4NodePiPbS2_S2_S1_i_wrapper(void *args);
    extern void _Z7Kernel2PbS_S_S_i_wrapper(void *args);
}

void cuda__Z6KernelP4NodePiPbS2_S2_S1_i_wrapper(
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

    _Z6KernelP4NodePiPbS2_S2_S1_i_wrapper((void **)args);
}

void cuda__Z7Kernel2PbS_S_S_i_wrapper(
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

    _Z7Kernel2PbS_S_S_i_wrapper((void **)args);
}

vx_spawn_kernel_cb callbacks[] = {
    cuda__Z6KernelP4NodePiPbS2_S2_S1_i_wrapper, 
    cuda__Z7Kernel2PbS_S_S_i_wrapper, 
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

    vx_printf("sizeof everything %d %d %d\n", sizeof(*kernel_arg), sizeof(*ctx), sizeof(ctx->printf_buffer)); 
    vx_printf("base: 0x%lx\n", KERNEL_ARG_BASE_ADDR); 
    vx_printf("kernel#%d (callback:0x%lx): gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), args=(0x%lx, 0x%lx, 0x%lx, 0x%lx)\n", 
        kernel_arg->kernel_idx, callbacks[kernel_arg->kernel_idx], ctx->num_groups[0], ctx->num_groups[1], ctx->num_groups[2], 
        ctx->local_size[0], ctx->local_size[1], ctx->local_size[2],
        args[0], args[1], args[2], args[3]);

    vx_spawn_kernel(ctx, callbacks[kernel_arg->kernel_idx], args);

    return 0;
}

