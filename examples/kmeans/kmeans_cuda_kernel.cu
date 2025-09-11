#ifndef _KMEANS_CUDA_KERNEL_H_
#define _KMEANS_CUDA_KERNEL_H_

#include <stdio.h>
#include <cuda.h>
#include "kmeans.h"

#ifndef FLT_MAX
#define FLT_MAX 3.40282347e+38f
#endif

// *** texture/constant 메모리 전부 제거 ***

/* ----------------- invert_mapping() --------------------- */
/* Row-major (AoS) → Column-major (SoA) 변환.
   input:  [p0,d0][p0,d1]...[p1,d0][p1,d1]...
   output: [d0,p0][d0,p1]...[d1,p0][d1,p1]...
*/
__global__ void invert_mapping(float *input, float *output,
                               int npoints, int nfeatures)
{
    int point_id = threadIdx.x + blockDim.x * blockIdx.x;
    if (point_id < npoints){
        for (int i=0;i<nfeatures;i++)
            output[point_id + (size_t)npoints * i] =
                input[(size_t)point_id * nfeatures + i];
    }
}

/* ----------------- kmeansPoint() --------------------- */
/* 각 포인트의 최근접 클러스터를 찾아 membership을 갱신
   features: SoA [nfeatures * npoints]
   clusters: Row-major [nclusters * nfeatures]
*/
__global__ void kmeansPoint(float  *features,   // SoA
                            int     nfeatures,
                            int     npoints,
                            int     nclusters,
                            int    *membership,
                            float  *clusters,   // 글로벌 메모리에서 직접 읽음
                            float  *block_clusters, // 그대로 유지(옵션)
                            int    *block_deltas)   // 그대로 유지(옵션)
{
    // block/point id 계산 (Rodinia 원형 유지)
    const unsigned int block_id =
        gridDim.x * blockIdx.y + blockIdx.x;
    const unsigned int point_id =
        block_id * (blockDim.x * blockDim.y) + threadIdx.x;

    int index = -1;

    if (point_id < (unsigned)npoints) {
        float min_dist = FLT_MAX;

        // 모든 클러스터와 거리 비교 (유클리드 제곱거리, sqrt 없음)
        for (int c = 0; c < nclusters; ++c) {
            int cluster_base = c * nfeatures;
            float acc = 0.0f;
            // SoA 인덱싱: features[d * npoints + point_id]
            for (int d = 0; d < nfeatures; ++d) {
                float f = features[(size_t)d * npoints + point_id];
                float diff = f - clusters[cluster_base + d];
                acc += diff * diff;
            }
            if (acc < min_dist) {
                min_dist = acc;
                index = c;
            }
        }
    }

#ifdef GPU_DELTA_REDUCTION
    __shared__ int deltas[THREADS_PER_BLOCK];
    if (threadIdx.x < THREADS_PER_BLOCK) deltas[threadIdx.x] = 0;
#endif

    if (point_id < (unsigned)npoints) {
#ifdef GPU_DELTA_REDUCTION
        if (membership[point_id] != index) deltas[threadIdx.x] = 1;
#endif
        membership[point_id] = index;
    }

#ifdef GPU_DELTA_REDUCTION
    __syncthreads();
    unsigned int live = THREADS_PER_BLOCK / 2;
    for (; live > 1; live >>= 1) {
        if (threadIdx.x < live)
            deltas[threadIdx.x] += deltas[threadIdx.x + live];
        __syncthreads();
    }
    if (threadIdx.x == 0) {
        deltas[0] += deltas[1];
        block_deltas[blockIdx.y * gridDim.x + blockIdx.x] = deltas[0];
    }
#endif

#ifdef GPU_NEW_CENTER_REDUCTION
    // (원형 유지가 필요하면 이 블록 그대로 사용.
    //  여기서는 CPU_CENTER_REDUCE가 기본이라 생략 가능)
    int center_id = threadIdx.x / nfeatures;
    int dim_id    = threadIdx.x - nfeatures * center_id;

    __shared__ int new_center_ids[THREADS_PER_BLOCK];
    new_center_ids[threadIdx.x] = index;
    __syncthreads();

    int new_base = (point_id - threadIdx.x) * nfeatures + dim_id;
    float accumulator = 0.f;

    if (threadIdx.x < nfeatures * nclusters) {
        for (int i = 0; i < THREADS_PER_BLOCK; i++) {
            float val = features[(size_t)dim_id * npoints + (point_id - threadIdx.x + i)];
            if (new_center_ids[i] == center_id) accumulator += val;
        }
        block_clusters[(blockIdx.y * gridDim.x + blockIdx.x)
                       * nclusters * nfeatures + threadIdx.x] = accumulator;
    }
#endif
}
#endif // _KMEANS_CUDA_KERNEL_H_