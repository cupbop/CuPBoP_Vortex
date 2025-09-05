// kmeans_cuda.cu
//
// CUDA port that mirrors the common OpenCL k-means benchmark (Rodinia-style).
// It provides drop-in equivalents for the two main kernels:
//  1) find_nearest_cluster: assigns each point to the closest cluster and produces
//     per-block partial sums & counts
//  2) sum_reduce_new_centers: reduces per-block partials into the final new centers
//
// Host helpers are also provided to allocate/launch kernels and to copy results.
//
// Expected memory layout (matches the typical OpenCL version):
// - features: [npoints][nfeatures]   (row-major, contiguous)
// - clusters: [nclusters][nfeatures] (row-major, contiguous)
// - membership: [npoints]
// - partial_new_centers: [nblocks][nclusters][nfeatures]
// - partial_new_centers_len: [nblocks][nclusters]
//
// Build (example):
//   nvcc -O3 -arch=sm_70 -o kmeans_cuda kmeans_cuda.cu
//
// Minimal usage example (host side):
//   See the runKMeansCUDA(...) function below; adapt to your project as needed.
//
// NOTE: If your OpenCL code used local memory tiling sizes or specific NDRange
//       geometry, adjust BLOCK_SIZE and grid sizing to match 1:1 semantics.
//
// (c) CUDA port for parity with OpenCL benchmark.

#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <limits>
#include <algorithm>

#ifndef CUDA_CHECK
#define CUDA_CHECK(expr)                                                    \
  do {                                                                      \
    cudaError_t _e = (expr);                                                \
    if (_e != cudaSuccess) {                                                \
      fprintf(stderr, "CUDA Error %s:%d: %s -> %s\n",                       \
              __FILE__, __LINE__, #expr, cudaGetErrorString(_e));           \
      std::abort();                                                         \
    }                                                                       \
  } while (0)
#endif

// Tunable launch parameter (mirrors typical OpenCL local size of 256)
#ifndef BLOCK_SIZE
#define BLOCK_SIZE 256
#endif

// Compute squared distance between two feature vectors of length nfeatures
__device__ inline float distance_sq(const float* __restrict__ p,
                                    const float* __restrict__ c,
                                    int nfeatures) {
  float dist = 0.f;
  for (int f = 0; f < nfeatures; ++f) {
    float d = p[f] - c[f];
    dist += d * d;
  }
  return dist;
}

// Kernel 1: assign each point to nearest cluster and accumulate per-block partial sums
// Layouts:
//   features: [npoints][nfeatures]
//   clusters: [nclusters][nfeatures]
//   membership: [npoints]
//   partial_new_centers: [gridDim.x][nclusters][nfeatures]
//   partial_new_centers_len: [gridDim.x][nclusters]
__global__ void find_nearest_cluster_kernel(const float* __restrict__ features,
                                            const float* __restrict__ clusters,
                                            int npoints,
                                            int nfeatures,
                                            int nclusters,
                                            int* __restrict__ membership,
                                            float* __restrict__ partial_new_centers,
                                            int* __restrict__ partial_new_centers_len) {
  extern __shared__ unsigned char smem[];
  float* s_clusters = reinterpret_cast<float*>(smem); // size = nclusters*nfeatures floats

  // Load clusters into shared memory (all threads cooperate)
  int tid = threadIdx.x;
  int tcount = blockDim.x;
  int total_cf = nclusters * nfeatures;
  for (int i = tid; i < total_cf; i += tcount) {
    s_clusters[i] = clusters[i];
  }
  __syncthreads();

  int global_id = blockIdx.x * blockDim.x + threadIdx.x;
  if (global_id >= npoints) return;

  // Pointer to this point
  const float* p = features + (size_t)global_id * nfeatures;

  // Find nearest cluster
  float min_dist = FLT_MAX;
  int   idx = -1;
  for (int c = 0; c < nclusters; ++c) {
    const float* sc = s_clusters + (size_t)c * nfeatures;
    float d = distance_sq(p, sc, nfeatures);
    if (d < min_dist) {
      min_dist = d;
      idx = c;
    }
  }

  // Update membership
  membership[global_id] = idx;

  // Accumulate into per-block partial sums
  // Compute base pointers for this block
  float* block_partials = partial_new_centers
                        + (size_t)blockIdx.x * nclusters * nfeatures;
  int* block_counts = partial_new_centers_len
                    + (size_t)blockIdx.x * nclusters;

  // Atomically add features into the cluster's partial sum
  float* dst = block_partials + (size_t)idx * nfeatures;
  for (int f = 0; f < nfeatures; ++f) {
    atomicAdd(&dst[f], p[f]);
  }
  // Atomically increment count
  atomicAdd(&block_counts[idx], 1);
}

// Kernel 2: reduce partials across blocks into final new_centers and new_centers_len
// Option A: single-block kernel per cluster (simple + robust)
// new_centers: [nclusters][nfeatures]
// new_centers_len: [nclusters]
__global__ void sum_reduce_new_centers_kernel(const float* __restrict__ partial_new_centers,
                                              const int*   __restrict__ partial_new_centers_len,
                                              int nblocks,
                                              int nclusters,
                                              int nfeatures,
                                              float* __restrict__ new_centers,
                                              int*   __restrict__ new_centers_len) {
  // Each cluster handled by one block (launch with <<<nclusters, BLOCK_SIZE>>>)
  int c = blockIdx.x;
  if (c >= nclusters) return;

  // Reduce counts
  int count_sum = 0;
  for (int b = threadIdx.x; b < nblocks; b += blockDim.x) {
    count_sum += partial_new_centers_len[(size_t)b * nclusters + c];
  }
  __shared__ int s_count;
  // Reduce within block (naive reduction)
  __shared__ int s_counts[BLOCK_SIZE];
  s_counts[threadIdx.x] = count_sum;
  __syncthreads();

  // Parallel reduction for counts
  for (int s = blockDim.x >> 1; s > 0; s >>= 1) {
    if (threadIdx.x < s) {
      s_counts[threadIdx.x] += s_counts[threadIdx.x + s];
    }
    __syncthreads();
  }
  if (threadIdx.x == 0) s_count = s_counts[0];
  __syncthreads();

  if (threadIdx.x == 0) {
    new_centers_len[c] = s_count;
  }

  // Reduce feature sums per feature dimension
  for (int f = 0; f < nfeatures; ++f) {
    float sum = 0.f;
    for (int b = threadIdx.x; b < nblocks; b += blockDim.x) {
      sum += partial_new_centers[((size_t)b * nclusters + c) * nfeatures + f];
    }
    __shared__ float sdata[BLOCK_SIZE];
    sdata[threadIdx.x] = sum;
    __syncthreads();
    for (int s = blockDim.x >> 1; s > 0; s >>= 1) {
      if (threadIdx.x < s) {
        sdata[threadIdx.x] += sdata[threadIdx.x + s];
      }
      __syncthreads();
    }
    if (threadIdx.x == 0) {
      new_centers[(size_t)c * nfeatures + f] = sdata[0];
    }
    __syncthreads();
  }
}

// Host wrapper that mirrors OpenCL flow.
// Inputs:
//   d_features  : device pointer [npoints * nfeatures]
//   d_clusters  : device pointer [nclusters * nfeatures]
// Outputs:
//   d_membership: device pointer [npoints]
//   d_new_centers: device pointer [nclusters * nfeatures]  (sums, not divided)
//   d_new_centers_len: device pointer [nclusters]
//
// The function allocates/clears per-block partials internally (or you can pass your own).
extern "C" void kmeansCUDAAssignAndReduce(const float* d_features,
                                          const float* d_clusters,
                                          int npoints,
                                          int nfeatures,
                                          int nclusters,
                                          int* d_membership,
                                          float* d_new_centers,
                                          int* d_new_centers_len) {
  // Grid sizing similar to typical OpenCL NDRange (global = ceil(npoints/BLOCK_SIZE)*BLOCK_SIZE)
  int blocks = (npoints + BLOCK_SIZE - 1) / BLOCK_SIZE;
  dim3 grid(blocks);
  dim3 block(BLOCK_SIZE);

  // Allocate per-block partials
  float* d_partial_new_centers = nullptr;
  int*   d_partial_new_centers_len = nullptr;
  size_t partial_centers_bytes = (size_t)blocks * nclusters * nfeatures * sizeof(float);
  size_t partial_counts_bytes  = (size_t)blocks * nclusters * sizeof(int);

  CUDA_CHECK(cudaMalloc(&d_partial_new_centers, partial_centers_bytes));
  CUDA_CHECK(cudaMalloc(&d_partial_new_centers_len, partial_counts_bytes));

  CUDA_CHECK(cudaMemset(d_partial_new_centers, 0, partial_centers_bytes));
  CUDA_CHECK(cudaMemset(d_partial_new_centers_len, 0, partial_counts_bytes));
  CUDA_CHECK(cudaMemset(d_new_centers, 0, (size_t)nclusters * nfeatures * sizeof(float)));
  CUDA_CHECK(cudaMemset(d_new_centers_len, 0, (size_t)nclusters * sizeof(int)));

  // Shared memory size for clusters
  size_t smem_bytes = (size_t)nclusters * nfeatures * sizeof(float);

  // Kernel 1: assign + partial accumulate
  find_nearest_cluster_kernel<<<grid, block, smem_bytes>>>(
      d_features, d_clusters, npoints, nfeatures, nclusters,
      d_membership, d_partial_new_centers, d_partial_new_centers_len);
  CUDA_CHECK(cudaGetLastError());

  // Kernel 2: reduce partials (launch one block per cluster)
  dim3 grid2(nclusters);
  dim3 block2(BLOCK_SIZE);
  sum_reduce_new_centers_kernel<<<grid2, block2>>>(
      d_partial_new_centers, d_partial_new_centers_len,
      blocks, nclusters, nfeatures,
      d_new_centers, d_new_centers_len);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());

  CUDA_CHECK(cudaFree(d_partial_new_centers));
  CUDA_CHECK(cudaFree(d_partial_new_centers_len));
}

// Convenience CPU helper to finalize new cluster centers by dividing sums by counts.
// This mirrors the OpenCL host step that normalizes sums into means.
extern "C" void kmeansFinalizeCenters(float* h_new_centers, int* h_new_centers_len,
                                      int nclusters, int nfeatures) {
  for (int c = 0; c < nclusters; ++c) {
    int len = std::max(h_new_centers_len[c], 1); // guard against zero
    float inv = 1.0f / float(len);
    for (int f = 0; f < nfeatures; ++f) {
      h_new_centers[(size_t)c * nfeatures + f] *= inv;
    }
  }
}

// A simple end-to-end demo main (optional).
// Define BUILD_STANDALONE=1 to compile a small runnable example that
// creates random data and runs one assignment+reduce iteration.
#ifdef BUILD_STANDALONE
#include <vector>
int main() {
  const int npoints = 1<<14;     // 16K
  const int nfeatures = 32;
  const int nclusters = 16;

  std::vector<float> h_features((size_t)npoints * nfeatures);
  std::vector<float> h_clusters((size_t)nclusters * nfeatures);
  std::vector<int>   h_membership(npoints, -1);
  std::vector<float> h_new_centers((size_t)nclusters * nfeatures);
  std::vector<int>   h_new_centers_len(nclusters);

  // init random
  for (auto& v : h_features) v = (float)rand() / RAND_MAX;
  for (auto& v : h_clusters) v = (float)rand() / RAND_MAX;

  float *d_features=nullptr, *d_clusters=nullptr, *d_new_centers=nullptr;
  int *d_membership=nullptr, *d_new_centers_len=nullptr;
  CUDA_CHECK(cudaMalloc(&d_features, h_features.size()*sizeof(float)));
  CUDA_CHECK(cudaMalloc(&d_clusters, h_clusters.size()*sizeof(float)));
  CUDA_CHECK(cudaMalloc(&d_membership, h_membership.size()*sizeof(int)));
  CUDA_CHECK(cudaMalloc(&d_new_centers, h_new_centers.size()*sizeof(float)));
  CUDA_CHECK(cudaMalloc(&d_new_centers_len, h_new_centers_len.size()*sizeof(int)));

  CUDA_CHECK(cudaMemcpy(d_features, h_features.data(), h_features.size()*sizeof(float), cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_clusters, h_clusters.data(), h_clusters.size()*sizeof(float), cudaMemcpyHostToDevice));

  kmeansCUDAAssignAndReduce(d_features, d_clusters, npoints, nfeatures, nclusters,
                            d_membership, d_new_centers, d_new_centers_len);

  CUDA_CHECK(cudaMemcpy(h_new_centers.data(), d_new_centers, h_new_centers.size()*sizeof(float), cudaMemcpyDeviceToHost));
  CUDA_CHECK(cudaMemcpy(h_new_centers_len.data(), d_new_centers_len, h_new_centers_len.size()*sizeof(int), cudaMemcpyDeviceToHost));

  // finalize (divide sums by counts)
  kmeansFinalizeCenters(h_new_centers.data(), h_new_centers_len.data(), nclusters, nfeatures);

  printf("Done. Example first center dims: ");
  for (int f = 0; f < min(5, nfeatures); ++f) {
    printf("%g ", h_new_centers[f]);
  }
  printf("\n");

  cudaFree(d_features); cudaFree(d_clusters); cudaFree(d_membership);
  cudaFree(d_new_centers); cudaFree(d_new_centers_len);
  return 0;
}
#endif
