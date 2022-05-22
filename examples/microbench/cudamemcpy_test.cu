#include <stdio.h>

int main(void)
{
  int N = 1<<20;
  float *x, *y, *rx, *ry, *d_x, *d_y;
  x = (float*)malloc(N*sizeof(float));
  y = (float*)malloc(N*sizeof(float));
  rx = (float*)malloc(N*sizeof(float));
  ry = (float*)malloc(N*sizeof(float));

  cudaMalloc(&d_x, N*sizeof(float)); 
  cudaMalloc(&d_y, N*sizeof(float));

  for (int i = 0; i < N; i++) {
    x[i] = 1.0f;
    y[i] = 2.0f;
  }

  cudaMemcpy(d_x, x, N*sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_y, y, N*sizeof(float), cudaMemcpyHostToDevice);

  // Perform SAXPY on 1M elements
  // saxpy<<<(N+255)/256, 256>>>(N, 2.0f, d_x, d_y);

  cudaMemcpy(rx, d_x, N*sizeof(float), cudaMemcpyDeviceToHost);
  cudaMemcpy(ry, d_y, N*sizeof(float), cudaMemcpyDeviceToHost);

  float sumError = 0.0f;
  for (int i = 0; i < N; i++) {
   sumError += abs(rx[i]-1.0f);
   sumError += abs(ry[i]-2.0f);
  }
  printf("Sum error: %f\n", sumError);

  cudaFree(d_x);
  cudaFree(d_y);
  free(x);
  free(y);
  free(rx);
  free(ry); 
}