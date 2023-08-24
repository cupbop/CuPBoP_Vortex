#include <stdio.h>
#include <algorithm>


__global__
void saxpy(int n, bool* x, float* y, int* z_first, int* z_second)
{
  int i = blockIdx.x * blockDim.x + threadIdx.x; 
 
  //printf("blkidx: %d", blockIdx.x);
 
  //printf("tid: %d\n", i);
  //if(x[i])
  if(i<n)
  {
    //printf("here! %d", i);
    //for (int k = x[i]; k<x[i]+1; k++)
    {
      //printf("zfirst: %d\n", z_first[i]);
      z_second[i] = z_first[i] - 2.0f;
    }
    //if( i % 2 == 0)
    //  x[i] = true;
  }
  
   //y[i] = x[i]+100;
 
 
}

int main(void)
{
  int N = 512;
  int T = 32;
  // changes to for loop 
  // 4 blocks -> 4threads
  // 32 threads -> 1 for loop

  float *y,  *d_y;
  bool *x, *d_x;
  int *z_first, *d_z_first;
  int *z_second, *d_z_second;
  
  x = (bool*)malloc(N*sizeof(bool));
  y = (float*)malloc(N*sizeof(float));
  z_first = (int*)malloc(N*sizeof(int));
  z_second = (int*)malloc(N*sizeof(int));

  cudaMalloc(&d_x, N*sizeof(bool)); 
  cudaMalloc(&d_y, N*sizeof(float));
  cudaMalloc(&d_z_first, N*sizeof(int));
  cudaMalloc(&d_z_second, N*sizeof(int));

  for (int i = 0; i < N; i++) {
    if(i % 10 == 0)
      x[i] = true;
    else
      x[i] = false;
    y[i] = 2.0f;
    z_first[i] = i;
    z_second[i] = 0;
  }

  

  cudaMemcpy(d_x, x, N*sizeof(bool), cudaMemcpyHostToDevice);
  cudaMemcpy(d_y, y, N*sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_z_first, z_first, N*sizeof(int), cudaMemcpyHostToDevice);
  //cudaMemset(d_z_second, 0, N*sizeof(int));
  cudaMemcpy(d_z_second, z_second, N*sizeof(int), cudaMemcpyHostToDevice);

  // Perform SAXPY on 1M elements
  
  dim3 dimBlock(T);
  dim3 dimGrid(N/T);
  saxpy<<<dimGrid, dimBlock>>>(N, d_x, d_y, d_z_first, d_z_second);
  
  
  cudaMemcpy(x, d_x, N*sizeof(bool), cudaMemcpyDeviceToHost);
  cudaMemcpy(y, d_y, N*sizeof(float), cudaMemcpyDeviceToHost);
  cudaMemcpy(z_first, d_z_first, N*sizeof(int), cudaMemcpyDeviceToHost);
  cudaMemcpy(z_second, d_z_second, N*sizeof(int), cudaMemcpyDeviceToHost);

  float maxError = 0.0f;

  for (int i = 0; i < N; i++)
  {
    maxError += (z_second[i]-i+2.0f);
  }
  printf("Max error: %f\n", maxError);
  printf("Actual values are: \n");

  for (int i = 0; i < 500; i++) 
  {
        if (i%10 == 0)
    {
      printf("\n");
    }
    
    printf("%d ", z_second[i]);

  }
  printf("\n");

  cudaFree(d_x);
  cudaFree(d_y);
  cudaFree(d_z_first);
  cudaFree(d_z_second);
  free(x);
  free(y);
  free(z_first);
  free(z_second);
}
