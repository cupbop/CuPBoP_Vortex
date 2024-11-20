#include <stdio.h>
#include <algorithm>

__global__
void saxpy(int n, float a, float *x, float *y)
{
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  
  //if (i < n) 
  printf("i: %d\n", i);
  {y[i] = x[i]-y[i];}
}

int main(void)
{
  int N = 1024;//32*32*32*4;
  int T = 16;

  float *x, *y, *d_x, *d_y;
  x = (float*)malloc(N*sizeof(int));
  y = (float*)malloc(N*sizeof(int));

  cudaMalloc(&d_x, N*sizeof(int)); 
  cudaMalloc(&d_y, N*sizeof(int));

  for (int i = 0; i < N; i++) {
    x[i] = float(i);
    y[i] = 1.0f;
  }

  cudaMemcpy(d_x, x, N*sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_y, y, N*sizeof(int), cudaMemcpyHostToDevice);
  //cudaMemset((void *)d_y, 2, N * sizeof(float));7&
  

  // Perform SAXPY on 1M elements
  saxpy<<<(N/T), T>>>(N, 2.0f, d_x, d_y);

  cudaMemcpy(y, d_y, N*sizeof(int), cudaMemcpyDeviceToHost);

  float maxError = 0.0f;
  
  for (int i = 0; i < N; i++) {
    maxError += std::max(maxError, abs(y[i]-1.0f));
    printf("%f ", y[i]);
  }
  
  printf("Max error: %f\n", maxError);
  //printf("host_x: %ld\n", d_x);

  cudaFree(d_x);
  cudaFree(d_y);
  free(x);
  free(y);
}
