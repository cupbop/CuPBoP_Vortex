#include <cstdio>
#include <cuda_runtime.h>

// With NT8, one physical warp per CTA and coalesced DXA enabled, expect one
// 128-byte DXA transfer per CTA. Other sub-passes exercise zero-fill and
// nonconsecutive source addresses.
__global__ void copy(const unsigned *src, unsigned *dst) {
    __shared__ __align__(16) unsigned tile[32][4];
    const unsigned lane = threadIdx.x;
    const unsigned warp_base = blockIdx.x * 32;
    const unsigned source_lane = lane < 16 ? lane : (lane ^ 7u);
    const unsigned *input = src + 4 * (warp_base + source_lane);
    const unsigned address = static_cast<unsigned>(__cvta_generic_to_shared(tile[lane]));
    if (lane < 8 || lane >= 16) {
        asm volatile("cp.async.ca.shared.global [%0], [%1], 16;" :: "r"(address), "l"(input) : "memory");
    } else {
        const unsigned bytes = lane == 15 ? 0 : 16;
        asm volatile("cp.async.ca.shared.global [%0], [%1], 16, %2;" :: "r"(address), "l"(input), "r"(bytes) : "memory");
    }
    asm volatile("cp.async.commit_group;" ::: "memory");
    asm volatile("cp.async.wait_group 0;" ::: "memory");
    __syncthreads();
    for (unsigned word = 0; word < 4; ++word)
        dst[4 * (warp_base + lane) + word] = tile[lane][word];
}

int main() {
    constexpr unsigned blocks = 4, words = blocks * 32 * 4;
    unsigned input[words], output[words] = {};
    for (unsigned i = 0; i < words; ++i) input[i] = 17 * i + 19;
    unsigned *src, *dst;
    cudaMalloc((void **)&src, sizeof(input));
    cudaMalloc((void **)&dst, sizeof(output));
    cudaMemcpy(src, input, sizeof(input), cudaMemcpyHostToDevice);
    copy<<<blocks, 32>>>(src, dst);
    cudaMemcpy(output, dst, sizeof(output), cudaMemcpyDeviceToHost);
    unsigned errors = 0;
    for (unsigned i = 0; i < words; ++i) {
        const unsigned lane = i / 4 % 32;
        const unsigned source = lane < 16 ? i : (i ^ (7u * 4));
        errors += output[i] != (lane == 15 ? 0 : input[source]);
    }
    printf("%s (%u mismatches)\n", errors ? "FAILED" : "PASSED", errors);
    cudaFree(src);
    cudaFree(dst);
    return errors != 0;
}
