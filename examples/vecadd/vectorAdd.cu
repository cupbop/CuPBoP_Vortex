/* nvcc -O2 -std=c++11 vecadd.cu -o vecadd */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>
#include <unistd.h>   // getopt

__global__ void vectorAdd(const float *A, const float *B, float *C,
                          int numElements) {
  int i = blockDim.x * blockIdx.x + threadIdx.x;
  if (i < numElements) {
    C[i] = A[i] + B[i] + 0.0f;
  }
}

static void usage(const char* prog) {
  printf("Usage: %s [-n numElements] [-b blockSize] [-h]\n"
         "  -n  vector length (default 16)\n"
         "  -b  threads per block (default 4)\n"
         "  -h  show this help\n", prog);
}

int main(int argc, char** argv) {
  // ---- CLI ----
  int numElements = 16;   // default as original
  int threadsPerBlock = 4; // default as original

  int opt;
  while ((opt = getopt(argc, argv, "n:b:h")) != -1) {
    switch (opt) {
      case 'n': numElements = atoi(optarg); break;
      case 'b': threadsPerBlock = atoi(optarg); break;
      case 'h': usage(argv[0]); return 0;
      default : usage(argv[0]); return 1;
    }
  }
  if (numElements <= 0 || threadsPerBlock <= 0) {
    fprintf(stderr, "Error: numElements and blockSize must be > 0\n");
    return 1;
  }

  printf("[Vector addition of %d elements] (blockSize=%d)\n",
         numElements, threadsPerBlock);

  size_t size = (size_t)numElements * sizeof(float);

  // ---- Host alloc ----
  float *h_A = (float*)malloc(size);
  float *h_B = (float*)malloc(size);
  float *h_C = (float*)malloc(size);
  if (!h_A || !h_B || !h_C) {
    fprintf(stderr, "Failed to allocate host vectors!\n");
    return 1;
  }

  // ---- Init host data ----
  for (int i = 0; i < numElements; ++i) {
    h_A[i] = rand() / (float)RAND_MAX;
    h_B[i] = rand() / (float)RAND_MAX;
  }

  // ---- Device alloc ----
  float *d_A = NULL, *d_B = NULL, *d_C = NULL;
  cudaError_t err;

  err = cudaMalloc((void**)&d_A, size);
  if (err != cudaSuccess) {
    fprintf(stderr, "Failed to allocate device vector A (%s)\n",
            cudaGetErrorString(err));
    return 1;
  }
  err = cudaMalloc((void**)&d_B, size);
  if (err != cudaSuccess) {
    fprintf(stderr, "Failed to allocate device vector B (%s)\n",
            cudaGetErrorString(err));
    return 1;
  }
  err = cudaMalloc((void**)&d_C, size);
  if (err != cudaSuccess) {
    fprintf(stderr, "Failed to allocate device vector C (%s)\n",
            cudaGetErrorString(err));
    return 1;
  }

  // ---- H2D ----
  printf("Copy input data from host to device\n");
  err = cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
  if (err != cudaSuccess) {
    fprintf(stderr, "H2D A failed: %s\n", cudaGetErrorString(err));
    return 1;
  }
  err = cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);
  if (err != cudaSuccess) {
    fprintf(stderr, "H2D B failed: %s\n", cudaGetErrorString(err));
    return 1;
  }

  // ---- Launch ----
  int blocksPerGrid = (numElements + threadsPerBlock - 1) / threadsPerBlock;
  printf("CUDA kernel launch with %d blocks of %d threads\n",
         blocksPerGrid, threadsPerBlock);

  vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, numElements);
  err = cudaGetLastError();
  if (err != cudaSuccess) {
    fprintf(stderr, "Kernel launch failed: %s\n", cudaGetErrorString(err));
    return 1;
  }
  err = cudaDeviceSynchronize();
  if (err != cudaSuccess) {
    fprintf(stderr, "cudaDeviceSynchronize failed: %s\n",
            cudaGetErrorString(err));
    return 1;
  }

  // ---- D2H ----
  printf("Copy output data from device to host\n");
  err = cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);
  if (err != cudaSuccess) {
    fprintf(stderr, "D2H C failed: %s\n", cudaGetErrorString(err));
    return 1;
  }

  // ---- Verify ----
  for (int i = 0; i < numElements; ++i) {
    if (fabsf(h_A[i] + h_B[i] - h_C[i]) > 1e-5f) {
      fprintf(stderr, "Result verification failed at element %d!\n", i);
      return 1;
    }
  }
  printf("Test PASSED\n");

  // ---- Cleanup ----
  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_C);
  free(h_A);
  free(h_B);
  free(h_C);
  printf("Done\n");
  return 0;
}