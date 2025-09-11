// stencil_parboil_cuda.cu — CUDA port with Parboil-style file I/O & gold check
// Build: nvcc -O2 -std=c++17 -arch=sm_70 -o stencil_cuda stencil_parboil_cuda.cu
// Run  : ./stencil_cuda nx ny nz t -i input.bin [-o out.bin]
//
// Semantics match the OpenCL kernel:
//   Anext[idx] = c0 * A0[idx] + c1 * (6-neighborhood of A0[idx])
// Update domain: interior (1..nx-2, 1..ny-2, 1..nz-2)
// Launch mirrors OpenCL rounding on X (tx=128), with +1 offset emulated.

#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <chrono>
#include <vector>
#include <string>
#include <cmath>
#include <unistd.h>   // getopt

#define CUDA_CHECK(call)                                                 \
  do {                                                                   \
    cudaError_t _err = (call);                                           \
    if (_err != cudaSuccess) {                                           \
      fprintf(stderr, "CUDA Error: %s (%d) at %s:%d\n",                  \
              cudaGetErrorString(_err), (int)_err, __FILE__, __LINE__);  \
      exit(1);                                                           \
    }                                                                    \
  } while (0)

// ---------- I/O helpers (Parboil-style) ----------
static int read_data(float *A0, int nx, int ny, int nz, FILE *fp) {
  const size_t total = (size_t)nx * ny * nz;
  size_t got = fread(A0, sizeof(float), total, fp);
  return (got == total) ? 0 : -1;
}
static std::string replace_ext(const std::string& path, const char* ext) {
  size_t p = path.find_last_of('.');
  if (p == std::string::npos) return path + ext;
  return path.substr(0, p) + ext;
}
static float* read_gold_file(const char* filename, int* out_size) {
  FILE* file = fopen(filename, "rb");
  if (!file) return nullptr;
  int size = 0;
  if (fread(&size, sizeof(int), 1, file) != 1) { fclose(file); return nullptr; }
  float* buf = (float*)malloc(sizeof(float) * size);
  if (!buf) { fclose(file); return nullptr; }
  if ((int)fread(buf, sizeof(float), size, file) != size) {
    free(buf); fclose(file); return nullptr;
  }
  fclose(file);
  if (out_size) *out_size = size;
  return buf;
}
static int write_bin_with_size(const char* filename, const float* y, int N){
  FILE* f = fopen(filename, "wb"); if(!f) return -1;
  if (fwrite(&N, sizeof(int), 1, f) != 1) { fclose(f); return -1; }
  if ((int)fwrite(y, sizeof(float), N, f) != N) { fclose(f); return -1; }
  fclose(f); return 0;
}
static int compare_floats(const float* src, const float* gold, int count) {
  int num_errors = 0;
  float max_value = 0.0f;
  for (int i = 0; i < count; ++i) max_value = fmaxf(max_value, fabsf(gold[i]));
  const float abstol = 1e-4f * max_value; // same rule as OpenCL code
  for (int i = 0; i < count; ++i) {
    float diff = fabsf(gold[i] - src[i]);
    if (!(diff <= abstol || diff < 0.002f * fabsf(gold[i]))) {
      if (num_errors < 10)
        printf("Fail at row %d: (gold) %f != %f (computed)\n", i, gold[i], src[i]);
      ++num_errors;
    }
  }
  return num_errors;
}

// ---------- CUDA kernel (1:1 with OpenCL naive_kernel) ----------
__global__ void naive_kernel_cuda(float *Anext,
                                  const float *A0,
                                  int nx, int ny, int nz,
                                  float c0, float c1)
{
  int i = blockIdx.x * blockDim.x + threadIdx.x + 1;
  int j = blockIdx.y * blockDim.y + threadIdx.y + 1;  // ← Y도 일반화
  int k = blockIdx.z + 1;

  if (i < nx-1 && j < ny-1) {  // j 가드 추가
    int plane = nx * ny;
    int idx   = i + j * nx + k * plane;

    // OpenCL 과 동일: c1*이웃합 - c0*A0
    Anext[idx] =
        c1 * ( A0[idx-1] + A0[idx+1]
             + A0[idx-nx] + A0[idx+nx]
             + A0[idx-plane] + A0[idx+plane] )
      - c0 * A0[idx];
  }
}

static void usage() {
  printf("Usage: ./stencil_cuda nx ny nz t -i input.bin [-o out.bin]\n");
}

int main(int argc, char** argv) {
  if (argc < 6) { usage(); return 1; }

  int nx = atoi(argv[1]);
  int ny = atoi(argv[2]);
  int nz = atoi(argv[3]);
  int iteration = atoi(argv[4]);

  std::string in_path, out_path;
  int opt;
  // parse -i, -o
  while ((opt = getopt(argc-4, argv+4, "i:o:h")) != -1) {
    switch (opt) {
      case 'i': in_path = optarg; break;
      case 'o': out_path = optarg; break;
      case 'h': usage(); return 0;
      default : usage(); return 1;
    }
  }

  if (nx < 3 || ny < 3 || nz < 3 || iteration < 1 || in_path.empty()) {
    usage(); return 1;
  }

  float c0 = 1.0f/6.0f;
  float c1 = 1.0f/6.0f/6.0f;

  const size_t total_elems = (size_t)nx * ny * nz;
  const size_t nbytes = total_elems * sizeof(float);

  // Host buffers
  std::vector<float> h_A0(total_elems);
  std::vector<float> h_Anext(total_elems, 0.0f);

  // Read input.bin (raw floats) like the OpenCL code
  {
    FILE* fp = fopen(in_path.c_str(), "rb");
    if (!fp) { perror("fopen input"); return 1; }
    if (read_data(h_A0.data(), nx, ny, nz, fp) != 0) {
      fprintf(stderr, "Error: input size mismatch for %s\n", in_path.c_str());
      fclose(fp); return 1;
    }
    fclose(fp);
    // Anext 초기값은 A0로 복사(원본과 동일)
    memcpy(h_Anext.data(), h_A0.data(), nbytes);
  }

  // Device buffers
  float *d_A0 = nullptr, *d_Anext = nullptr;
  CUDA_CHECK(cudaMalloc(&d_A0, nbytes));
  CUDA_CHECK(cudaMalloc(&d_Anext, nbytes));

  // Copy initial data
  CUDA_CHECK(cudaMemcpy(d_A0,   h_A0.data(),   nbytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_Anext,h_Anext.data(),nbytes, cudaMemcpyHostToDevice));

  // Launch config mirroring OpenCL grid rounding (tx=128) and offsets (+1,+1,+1)
  const int tx = 128;
  dim3 block(tx, 1, 1);
  dim3 grid((nx - 2 + tx - 1) / tx, ny - 2, nz - 2);

  printf("grid=(%d,%d,%d), block=(%d,%d,%d)\n", grid.x, grid.y, grid.z, block.x, block.y, block.z);

  CUDA_CHECK(cudaDeviceSynchronize());
  auto t0 = std::chrono::high_resolution_clock::now();

  for (int t = 0; t < iteration; ++t) {
    naive_kernel_cuda<<<grid, block>>>(d_Anext, d_A0, nx, ny, nz, c0, c1);
    CUDA_CHECK(cudaGetLastError());
    // swap like OpenCL host
    float* tmp = d_A0; d_A0 = d_Anext; d_Anext = tmp;
  }

  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double ms = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  printf("Elapsed time: %.3f ms (for %d iterations)\n", ms, iteration);

  // In OpenCL code, they swapped one extra time after loop to make d_Anext the latest.
  // We mirror that here for parity:
  {
    float* tmp = d_A0; d_A0 = d_Anext; d_Anext = tmp;
  }

  CUDA_CHECK(cudaMemcpy(h_Anext.data(), d_Anext, nbytes, cudaMemcpyDeviceToHost));

  // Optional output file (Parboil style: int N + float[N])
  if (!out_path.empty()) {
    if (write_bin_with_size(out_path.c_str(), h_Anext.data(), (int)total_elems) != 0) {
      fprintf(stderr, "Failed to write %s\n", out_path.c_str());
    } else {
      printf("Wrote %s\n", out_path.c_str());
    }
  }

  // Gold compare: input.bin -> input.gold (int N; float[N])
  {
    std::string gold_path = replace_ext(in_path, ".gold");
    int gold_size = 0;
    float* gold = read_gold_file(gold_path.c_str(), &gold_size);
    if (gold) {
      if (gold_size != (int)total_elems) {
        printf("error: gold data size mismatch: current=%zu, expected=%d\n", total_elems, gold_size);
      } else {
        int errors = compare_floats(h_Anext.data(), gold, gold_size);
        if (errors > 0) printf("FAILED!\n"); else printf("PASSED!\n");
      }
      free(gold);
    } else {
      printf("(gold '%s' not found — skipping check)\n", gold_path.c_str());
    }
  }

  CUDA_CHECK(cudaFree(d_A0));
  CUDA_CHECK(cudaFree(d_Anext));
  return 0;
}