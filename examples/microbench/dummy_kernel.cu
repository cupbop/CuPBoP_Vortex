#include <stdio.h>

__global__
void saxpy(void)
{
  int i = blockIdx.x*blockDim.x + threadIdx.x;
  printf("block_id:%d thread_id:%d \n", i);
}
