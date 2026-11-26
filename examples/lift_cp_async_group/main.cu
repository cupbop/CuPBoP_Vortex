#include <cuda_runtime.h>
#include <cstdio>

extern "C" __global__ void copy_group(const uint4 *src, uint4 *out, unsigned *work) {
    __shared__ uint4 tile[32];
    unsigned lane = threadIdx.x;
    unsigned dst = static_cast<unsigned>(__cvta_generic_to_shared(tile + lane));
    asm volatile("cp.async.ca.shared.global [%0], [%1], 16;" :: "r"(dst), "l"(src + lane) : "memory");
    asm volatile("cp.async.commit_group;" ::: "memory");
    work[lane] = lane * lane + 7;
    asm volatile("cp.async.wait_group 0;" ::: "memory");
    out[lane] = tile[lane];
}

int main() {
    uint4 input[32], output[32];
    unsigned work[32];
    for (unsigned i = 0; i < 32; ++i)
        input[i] = make_uint4(i + 11, i * 5, 31 - i, i ^ 0x12345678u);
    uint4 *src, *out;
    unsigned *dev_work;
    if (cudaMalloc(&src, sizeof(input)) != cudaSuccess ||
        cudaMalloc(&out, sizeof(output)) != cudaSuccess ||
        cudaMalloc(&dev_work, sizeof(work)) != cudaSuccess ||
        cudaMemcpy(src, input, sizeof(input), cudaMemcpyHostToDevice) != cudaSuccess)
        return 1;
    copy_group<<<1, 32>>>(src, out, dev_work);
    if (cudaMemcpy(output, out, sizeof(output), cudaMemcpyDeviceToHost) != cudaSuccess ||
        cudaMemcpy(work, dev_work, sizeof(work), cudaMemcpyDeviceToHost) != cudaSuccess)
        return 1;
    for (unsigned i = 0; i < 32; ++i) {
        if (output[i].x != input[i].x || output[i].y != input[i].y ||
            output[i].z != input[i].z || output[i].w != input[i].w ||
            work[i] != i * i + 7) {
            std::printf("FAIL at lane %u\n", i);
            return 1;
        }
    }
    cudaFree(dev_work);
    cudaFree(out);
    cudaFree(src);
    std::puts("PASSED SM80 copy: 128 copied words, 32 arithmetic results");
}
