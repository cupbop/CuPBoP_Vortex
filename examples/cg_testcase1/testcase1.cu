// Testcase1: Evaluating thread_group and basic synchronization functions
// with tiled partitioning.

#include <cuda_runtime.h>
#include <stdio.h>
#include "cooperative_groups_fake.h"
// #include <cooperative_groups.h>


using namespace cooperative_groups;


// __global__ void cgkernel()
// {
//     printf("%d: A!\n", threadIdx.x);
//     __syncwarp();
//     printf("%d: B!\n", threadIdx.x);
// }


__global__ void cgkernel() {

    bool anyResult = __any_sync(-1, threadIdx.x);

    printf("  any result %s\n", anyResult ? "true" : "false");

    __syncwarp();
}

// __global__ void cgkernel() {
//     int laneId = threadIdx.x % warpSize;

//     // For demonstration, let’s choose a simple predicate:
//     // e.g., whether laneId is less than 16
//     bool predicate = (laneId < 16);

//     bool anyResult = __any_sync(-1, predicate);
//     bool allResult = __all_sync(-1, predicate);

//     // Print results from lane 0 of the warp to avoid too much output.
//     if (laneId == 0) {
//         printf("Within the warp:\n");
//         printf("  Any thread < 16? %s\n", anyResult ? "true" : "false");
//         printf("  All threads < 16? %s\n", allResult ? "true" : "false");
//     }

//     __syncwarp();
// }

// __global__ void cgkernel()
// {
//     thread_block block = this_thread_block();
//     thread_group g = tiled_partition(block, 16);
//     printf("%d => %d\n", block.thread_rank(), g.thread_rank());
//     g.sync();
// }

// __global__ void cgkernel()
// {
//     thread_block block = this_thread_block();
//     printf("%d\n", block.thread_rank());
//     block.sync();
//     __syncthreads();
//     thread_group g = tiled_partition(block, 16);
//     printf("%d => %d\n", block.thread_rank(), g.thread_rank());
//     g.sync();
//     printf(".\n");
// }

int main()
{
    printf("Executing Test Case 1: Testing thread_group and basic synchronization with tiled partitioning.\n");
    cgkernel<<<1, 16>>>();
    cudaDeviceSynchronize();

    cudaError_t error = cudaGetLastError();
    if (error != cudaSuccess)
    {
        printf("CUDA error: %s\n", cudaGetErrorString(error));
        exit(-1);
    }

    printf("Device finished successfully.\n");
    return 0;
}
