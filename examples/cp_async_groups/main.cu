#include <cuda_runtime.h>
#include <cuda_pipeline.h>
#include <cupbop_dxa.h>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

constexpr unsigned lanes = 32, words = 4, tiles = 16;

// Keep the PTX operations in the kernel in the unoptimized device bitcode.
#define COPY16(dst, src) asm volatile("cp.async.ca.shared.global [%0], [%1], 16;" :: \
    "r"(static_cast<unsigned>(__cvta_generic_to_shared(dst))), "l"(src) : "memory")
#define COMMIT() asm volatile("cp.async.commit_group;" ::: "memory")
#define WAIT(n) asm volatile("cp.async.wait_group " #n ";" ::: "memory")

__global__ void pipeline(const unsigned *src, unsigned *out) {
    __shared__ __align__(16) unsigned tile[lanes][words];
    unsigned lane = threadIdx.x;
    __pipeline_memcpy_async(tile[lane], src + lane * words, 16);
    __pipeline_commit();
    __pipeline_wait_prior(0);
    *reinterpret_cast<uint4 *>(out + lane * words) = *reinterpret_cast<uint4 *>(tile[lane]);
}

__global__ void partial_bytes(const unsigned *src, unsigned *out) {
    __shared__ __align__(16) unsigned tile[lanes][words];
    unsigned lane = threadIdx.x;
    unsigned size = lane % 17;
    const unsigned *input = size ? src + lane * words : nullptr;
    asm volatile("cp.async.ca.shared.global [%0], [%1], 16, %2;" ::
        "r"(static_cast<unsigned>(__cvta_generic_to_shared(tile[lane]))),
        "l"(input), "r"(size) : "memory");
    COMMIT();
    WAIT(0);
    *reinterpret_cast<uint4 *>(out + lane * words) = *reinterpret_cast<uint4 *>(tile[lane]);
}

__global__ void groups(const unsigned *src, unsigned *out) {
    __shared__ __align__(16) unsigned tile[3][2 * lanes][words];
    unsigned lane = threadIdx.x;
    unsigned index = (blockIdx.x * blockDim.x + lane) * words;
    unsigned stride = gridDim.x * blockDim.x * words;
    COPY16(tile[0][lane], src + index);
    COPY16(tile[1][lane], src + index + stride);
    COMMIT();
    COMMIT();  // Empty groups count toward the wait threshold.
    COPY16(tile[2][lane], src + index + 2 * stride);
    COMMIT();
    __syncthreads();  // Outstanding copies have their own barriers across CTA synchronization.
    WAIT(1);
    *reinterpret_cast<uint4 *>(out + index) = *reinterpret_cast<uint4 *>(tile[0][lane]);
    *reinterpret_cast<uint4 *>(out + index + stride) = *reinterpret_cast<uint4 *>(tile[1][lane]);
    // Slot 0 is now reusable. wait_all implicitly commits this final copy.
    COPY16(tile[0][lane], src + index + 3 * stride);
    asm volatile("cp.async.wait_all;" ::: "memory");
    for (unsigned i = 0; i < words; ++i) {
        out[index + i + 2 * stride] = tile[2][lane][i];
        out[index + i + 3 * stride] = tile[0][lane][i];
    }
}

#define STEP(x) ((x) * 1664525u + (1013904223u ^ ((x) >> 16)))
#define FOUR_STEPS(x) do { x = STEP(x); x = STEP(x); x = STEP(x); x = STEP(x); } while (0)

template<bool wait_early> __global__ void timeline(const unsigned *src, unsigned *out) {
    __shared__ __align__(16) unsigned tile[lanes][words];
    __shared__ volatile unsigned checkpoint[lanes];
    unsigned lane = threadIdx.x;
    unsigned state = lane + 1, sum = 0;
    checkpoint[lane] = state;
    for (unsigned i = 0; i < tiles; ++i) {
        COPY16(tile[lane], src + (i * lanes + lane) * words);
        COMMIT();
        if (wait_early) WAIT(0);
        // Keep the same ALU chain between these points in both final ELFs.
        state = checkpoint[lane];
        FOUR_STEPS(state);
        FOUR_STEPS(state);
        FOUR_STEPS(state);
        FOUR_STEPS(state);
        checkpoint[lane] = state;
        if (!wait_early) WAIT(0);
        for (unsigned j = 0; j < words; ++j) sum += tile[lane][j];
    }
    out[lane] = sum ^ state;
}

int main(int argc, char **argv) {
    const char *mode = argc == 2 ? argv[1] : "groups";
    bool early = std::strcmp(mode, "early") == 0;
    bool late = std::strcmp(mode, "late") == 0;
    bool occupied = std::strcmp(mode, "occupied") == 0;
    bool exhausted = std::strcmp(mode, "exhausted") == 0;
    bool tail = std::strcmp(mode, "tail") == 0;
    bool header = std::strcmp(mode, "header") == 0;
    bool partial = std::strcmp(mode, "partial") == 0;
    if (!early && !late && !occupied && !exhausted && !tail && !header && !partial && std::strcmp(mode, "groups"))
        return 2;

    constexpr unsigned blocks = 5;
    unsigned block_threads = tail ? 53 : 2 * lanes;
    unsigned count = (early || late) ? tiles * lanes * words : 4 * blocks * block_threads * words;
    if (header || partial) count = lanes * words;
    std::vector<unsigned> input(count), expected, actual;
    for (unsigned i = 0; i < count; ++i) input[i] = i * 0x12345u + (i >> 3);
    if (early || late) {
        expected.resize(lanes);
        for (unsigned lane = 0; lane < lanes; ++lane) {
            unsigned state = lane + 1, sum = 0;
            for (unsigned i = 0; i < tiles; ++i) {
                for (unsigned k = 0; k < 16; ++k) state = STEP(state);
                for (unsigned j = 0; j < words; ++j) sum += input[(i * lanes + lane) * words + j];
            }
            expected[lane] = sum ^ state;
        }
    } else {
        expected = input;
        if (partial) {
            auto *bytes = reinterpret_cast<unsigned char *>(expected.data());
            for (unsigned lane = 0; lane < lanes; ++lane)
                std::memset(bytes + lane * 16 + lane % 17, 0, 16 - lane % 17);
        }
    }
    actual.resize(expected.size());
    unsigned *src, *dst;
    if (cudaMalloc(&src, count * sizeof(unsigned)) != cudaSuccess ||
        cudaMalloc(&dst, actual.size() * sizeof(unsigned)) != cudaSuccess ||
        cudaMemcpy(src, input.data(), count * sizeof(unsigned), cudaMemcpyHostToDevice) != cudaSuccess)
        return 1;
    for (unsigned slot = 0; slot < 16; ++slot) {
        if (!(exhausted || (occupied && (slot == 0 || slot == 7)))) continue;
        const unsigned box = words;
        if (cudaDxaProgramDescNdTiled(slot, reinterpret_cast<uintptr_t>(src), 1, &count, nullptr,
                                     &box, sizeof(unsigned), 0, 0, 0, 0, 0))
            return 1;
    }
    // Explicit descriptors apply to a single launch. The next launch after
    // exhaustion must be able to use the DXA again.
    for (unsigned launch = 0; launch < (exhausted ? 2u : 1u); ++launch) {
        if (cudaMemset(dst, 0xff, actual.size() * sizeof(unsigned)) != cudaSuccess)
            return 1;
        if (early) timeline<true><<<1, lanes>>>(src, dst);
        else if (late) timeline<false><<<1, lanes>>>(src, dst);
        else if (header) pipeline<<<1, lanes>>>(src, dst);
        else if (partial) partial_bytes<<<1, lanes>>>(src, dst);
        else groups<<<blocks, block_threads>>>(src, dst);
        if (cudaMemcpy(actual.data(), dst, actual.size() * sizeof(unsigned), cudaMemcpyDeviceToHost) != cudaSuccess)
            return 1;
        for (unsigned i = 0; i < actual.size(); ++i) {
            if (actual[i] != expected[i]) {
                std::printf("FAIL %s launch %u word %u: got %u, expected %u\n",
                            mode, launch, i, actual[i], expected[i]);
                return 1;
            }
        }
    }
    cudaFree(dst);
    cudaFree(src);
    std::printf("PASSED %s (%zu words)\n", mode, expected.size());
    return 0;
}
