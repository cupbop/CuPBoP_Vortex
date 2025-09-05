// spmv_jds_cuda.cu — CUDA JDS SpMV (OpenCL Parboil 스타일 1:1 대응)
// Build: nvcc -O3 -std=c++17 -arch=sm_70 -o spmv_jds_cuda spmv_jds_cuda.cu
// Run  : ./spmv_jds_cuda -i matrix.mtx,vector.vec [-o out.bin] [-p 32]
#include <cuda_runtime.h>

#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <cmath>
#include <unistd.h>  // getopt
#include <chrono>

#ifndef TYPE
#define TYPE float
#endif

#define CUDA_CHECK(expr) do {                                         \
  cudaError_t _err = (expr);                                          \
  if (_err != cudaSuccess) {                                          \
    fprintf(stderr, "CUDA Error: %s => %d (%s) at %s:%d\n",           \
            #expr, (int)_err, cudaGetErrorString(_err),               \
            __FILE__, __LINE__);                                      \
    std::abort();                                                     \
  }                                                                   \
} while (0)

// ------------------------ 유틸/입출력 ------------------------
static void usage(const char* prog){
  std::printf("Usage: %s -i <matrix.mtx,vector.vec> [-o out.bin] [-p pad]\n", prog);
}

static std::string replace_ext(const std::string& path, const std::string& ext){
  auto p = path.find_last_of('.');
  if (p == std::string::npos) return path + ext;
  return path.substr(0, p) + ext;
}

// gold: (int N; float N개) 바이너리
static float* read_gold_file(const char* filename, int* outN){
  FILE* f = std::fopen(filename, "rb");
  if (!f) return nullptr;
  int N=0;
  if (std::fread(&N, sizeof(int), 1, f) != 1){ std::fclose(f); return nullptr; }
  float* buf = (float*)std::malloc(sizeof(float)*N);
  if (!buf){ std::fclose(f); return nullptr; }
  if ((int)std::fread(buf, sizeof(float), N, f) != N){
    std::free(buf); std::fclose(f); return nullptr;
  }
  std::fclose(f);
  if (outN) *outN = N;
  return buf;
}

static int write_bin_with_size(const char* filename, const float* y, int N){
  FILE* f = std::fopen(filename, "wb");
  if (!f){ perror("fopen"); return -1; }
  if (std::fwrite(&N, sizeof(int), 1, f) != 1){ std::fclose(f); return -1; }
  if ((int)std::fwrite(y, sizeof(float), N, f) != N){ std::fclose(f); return -1; }
  std::fclose(f);
  return 0;
}

static int compare_floats(const float* src, const float* gold, int count){
  int num_errors = 0;
  float max_abs = 0.0f;
  for (int i=0;i<count;++i) max_abs = std::max(max_abs, std::fabs(gold[i]));
  float abstol = 1e-4f * max_abs; // 원본 로직
  for (int i=0;i<count;++i){
    float diff = std::fabs(gold[i] - src[i]);
    if (!(diff <= abstol || diff < 0.002f * std::fabs(gold[i]))){
      if (num_errors < 10)
        std::printf("Fail at row %d: (gold) %f != %f (computed)\n", i, gold[i], src[i]);
      ++num_errors;
    }
  }
  return num_errors;
}

// .vec: 공백 구분 텍스트 float 벡터
static bool read_vec_text(const std::string& path, std::vector<TYPE>& x, int expectedN){
  std::ifstream ifs(path);
  if (!ifs) return false;
  x.clear(); x.reserve(expectedN);
  double v;
  while (ifs >> v){
    x.push_back((TYPE)v);
  }
  return (int)x.size() == expectedN;
}

// ------------------------ Matrix Market -> COO ------------------------
struct COO {
  int rows=0, cols=0;
  std::vector<int>   I, J;
  std::vector<TYPE>  V;
};

static bool read_matrix_market(const std::string& path, COO& coo){
  std::ifstream ifs(path);
  if (!ifs){
    std::fprintf(stderr, "Cannot open %s\n", path.c_str());
    return false;
  }
  std::string line;
  if (!std::getline(ifs, line)) return false;
  if (line.rfind("%%MatrixMarket", 0) != 0){
    std::fprintf(stderr, "Not a MatrixMarket file\n");
    return false;
  }
  // 스펙 간략 대응: coordinate real general
  // 주석/공백 스킵 후 크기/NNZ 라인
  while (std::getline(ifs, line)){
    if (line.empty() || line[0]=='%') continue;
    std::istringstream iss(line);
    int M,N,NNZ; if (!(iss>>M>>N>>NNZ)){ std::fprintf(stderr,"Bad size line\n"); return false; }
    coo.rows=M; coo.cols=N; coo.I.reserve(NNZ); coo.J.reserve(NNZ); coo.V.reserve(NNZ);
    for (int k=0;k<NNZ;++k){
      if (!std::getline(ifs, line)) return false;
      if (line.empty() || line[0]=='%'){ --k; continue; }
      std::istringstream t(line);
      int i,j; double v;
      if (!(t >> i >> j >> v)) return false;
      coo.I.push_back(i-1);
      coo.J.push_back(j-1);
      coo.V.push_back((TYPE)v);
    }
    break;
  }
  return true;
}

// ------------------------ COO -> CSR ------------------------
struct CSR {
  int rows=0, cols=0;
  std::vector<int>   Ap; // size rows+1
  std::vector<int>   Aj; // size nnz
  std::vector<TYPE>  Ax; // size nnz
};

static void coo_to_csr(const COO& coo, CSR& csr){
  csr.rows = coo.rows; csr.cols = coo.cols;
  int M = csr.rows; size_t NNZ = coo.I.size();
  csr.Ap.assign(M+1, 0);
  csr.Aj.resize(NNZ);
  csr.Ax.resize(NNZ);

  // row counts
  for (size_t k=0;k<NNZ;++k) ++csr.Ap[coo.I[k]];
  // prefix
  int sum=0;
  for (int r=0;r<M;++r){ int c=csr.Ap[r]; csr.Ap[r]=sum; sum+=c; }
  csr.Ap[M]=sum;

  // scatter (stable)
  std::vector<int> next(csr.Ap.begin(), csr.Ap.end());
  for (size_t k=0;k<NNZ;++k){
    int r = coo.I[k];
    int p = next[r]++;
    csr.Aj[p] = coo.J[k];
    csr.Ax[p] = coo.V[k];
  }

  // 각 행 안에서 column 정렬(선택) — 안정성을 위해
  for (int r=0;r<M;++r){
    int s=csr.Ap[r], e=csr.Ap[r+1], len=e-s;
    std::vector<int> idx(len);
    for (int t=0;t<len;++t) idx[t]=s+t;
    std::sort(idx.begin(), idx.end(), [&](int a,int b){ return csr.Aj[a]<csr.Aj[b]; });
    std::vector<int>   newJ; newJ.reserve(len);
    std::vector<TYPE>  newV; newV.reserve(len);
    for (int t=0;t<len;++t){ newJ.push_back(csr.Aj[idx[t]]); newV.push_back(csr.Ax[idx[t]]); }
    for (int t=0;t<len;++t){ csr.Aj[s+t]=newJ[t]; csr.Ax[s+t]=newV[t]; }
  }
}

// ------------------------ CSR -> JDS ------------------------
struct JDS {
  // JDS 배열(Parboil 스타일)
  // data/indices : 대각(diagonal)별 연속 저장, 각 대각 시작은 jds_ptr[k]
  // perm        : 행 재배열(원래 행 idx)
  // sh_zcnt     : 블록별 유효 대각 개수 (크기 = numBlocks = ceil(dim/pad))
  // depth       : 대각 수 = max row nnz
  // len         : data/indices 길이(=nnz after sort)
  int dim=0, depth=0, len=0, nzcnt_len=0; // nzcnt_len = numBlocks
  std::vector<TYPE> data;
  std::vector<int>  indices;
  std::vector<int>  perm;
  std::vector<int>  jds_ptr;   // size = depth
  std::vector<int>  sh_zcnt;   // size = nzcnt_len
};

static void csr_to_jds(const CSR& csr, int pad, JDS& jds){
  const int M = csr.rows;
  jds.dim = M;
  // 행별 nnz
  std::vector<int> row_nnz(M);
  int depth = 0;
  for (int r=0;r<M;++r){
    row_nnz[r] = csr.Ap[r+1]-csr.Ap[r];
    depth = std::max(depth, row_nnz[r]);
  }
  jds.depth = depth;

  // perm: nnz 내림차순으로 행 인덱스 정렬
  jds.perm.resize(M);
  for (int r=0;r<M;++r) jds.perm[r]=r;
  std::stable_sort(jds.perm.begin(), jds.perm.end(),
                   [&](int a,int b){ return row_nnz[a] > row_nnz[b]; });

  // 각 대각의 길이: diag_len[k] = nnz가 k+1 이상인 행의 수
  std::vector<int> diag_len(depth, 0);
  for (int k=0;k<depth;++k){
    int cnt=0;
    for (int p=0;p<M;++p){
      int r = jds.perm[p];
      if (row_nnz[r] > k) ++cnt;
      else break; // 정렬된 상태라 break 가능
    }
    diag_len[k]=cnt;
  }

  // jds_ptr = 각 대각의 시작 오프셋 (누적합)
  jds.jds_ptr.resize(depth);
  int off=0;
  for (int k=0;k<depth;++k){ jds.jds_ptr[k]=off; off += diag_len[k]; }
  jds.len = off;

  jds.data.assign(jds.len, (TYPE)0);
  jds.indices.assign(jds.len, 0);

  // 각 행의 k번째(0-based) 비제로를 찾아 대각 k의 [jds_ptr[k] + p] 위치에 기록
  // CSR 안에서 행의 비제로들은 이미 열 인덱스 오름차순
  // p: permuted row order index(=thread 내 행 순번)
  for (int p=0; p<M; ++p){
    int r = jds.perm[p];
    int s = csr.Ap[r], e = csr.Ap[r+1];
    int nnz = e - s;
    for (int k=0;k<nnz;++k){
      int j = jds.jds_ptr[k] + p; // 해당 대각의 p번째 원소
      jds.data[j]   = csr.Ax[s+k];
      jds.indices[j]= csr.Aj[s+k];
    }
  }

  // sh_zcnt: 블록(=warp)별 유효 대각 수
  int numBlocks = (M + pad - 1) / pad;
  jds.nzcnt_len = numBlocks;
  jds.sh_zcnt.assign(numBlocks, 0);
  for (int b=0;b<numBlocks;++b){
    int row_start = b*pad;
    // 각 대각에서 row_start < diag_len[k] 인 k의 개수
    int bound=0;
    for (int k=0;k<depth;++k){
      if (row_start < diag_len[k]) ++bound; else break;
    }
    jds.sh_zcnt[b]=bound;
  }
}

// ------------------------ CPU 참조 (검증용) ------------------------
static void spmv_jds_cpu(const JDS& jds, const std::vector<TYPE>& x, std::vector<TYPE>& y){
  y.assign(jds.dim, (TYPE)0);
  // 원본 Parboil 커널과 동일한 수식:
  // 각 permuted row i에 대해 sum_k data[jds_ptr[k]+i] * x[indices[jds_ptr[k]+i]]
  // 결과는 원래 행 위치 d_perm[i]에 저장
  for (int i=0;i<jds.dim;++i){
    TYPE sum=0;
    int bound = jds.depth; // 실제로는 유효 대각까지만 보지만, out-of-range는 diag_len으로 비어있음
    for (int k=0;k<bound;++k){
      int j = jds.jds_ptr[k] + i;
      if (j >= jds.len) break; // 안전 가드
      // 유효한지 확인: i가 이 대각의 길이보다 작은지? (j 인덱스가 data 범위 내인지로 충분)
      sum += jds.data[j] * x[jds.indices[j]];
    }
    // perm 역매핑: perm[p]=원행, 여기선 p=i의 원행
    y[jds.perm[i]] = sum;
  }
}

// ------------------------ CUDA 커널 ------------------------
__global__ void spmv_jds_naive_kernel(
    float* __restrict__ d_Ax,        // dim
    const float* __restrict__ d_data,// len
    const int*   __restrict__ d_idx, // len
    const int*   __restrict__ d_perm,// dim
    const float* __restrict__ d_x,   // cols
    int dim,
    const int*   __restrict__ jds_ptr,   // depth
    const int*   __restrict__ sh_zcnt)   // nzcnt_len == numBlocks
{
  int tx = threadIdx.x;
  int bx = blockIdx.x;
  int i  = bx * blockDim.x + tx;  // permuted row
  if (i >= dim) return;

  float sum = 0.0f;
  int bound = sh_zcnt[bx];        // 이 블록에서 유효한 대각 개수
  for (int k=0;k<bound;++k){
    int j = jds_ptr[k] + i;
    sum += d_data[j] * d_x[d_idx[j]];
  }
  d_Ax[d_perm[i]] = sum;
}

// ------------------------ main ------------------------
int main(int argc, char** argv){
  std::string in_pair; // "matrix.mtx,vector.vec"
  std::string out_path;
  int pad = 32;

  int opt;
  while ((opt = getopt(argc, argv, "i:o:p:h")) != -1){
    switch(opt){
      case 'i': in_pair = optarg; break;
      case 'o': out_path = optarg; break;
      case 'p': pad = std::max(1, std::atoi(optarg)); break;
      case 'h': usage(argv[0]); return 0;
      default : usage(argv[0]); return 1;
    }
  }
  if (in_pair.empty()){
    usage(argv[0]); return 1;
  }

  // "mtx,vec" 파싱
  std::string mtx_path, vec_path;
  {
    auto pos = in_pair.find(',');
    if (pos == std::string::npos){
      std::fprintf(stderr, "Expecting -i <matrix.mtx,vector.vec>\n");
      return 1;
    }
    mtx_path = in_pair.substr(0,pos);
    vec_path = in_pair.substr(pos+1);
  }

  // Matrix Market 로드 -> COO -> CSR -> JDS
  COO coo;
  if (!read_matrix_market(mtx_path, coo)) return 1;
  CSR csr; coo_to_csr(coo, csr);
  if (csr.rows != csr.cols){
    std::fprintf(stderr,"Warning: non-square matrix %dx%d; continuing.\n", csr.rows, csr.cols);
  }
  JDS jds; csr_to_jds(csr, pad, jds);

  // x 벡터 로드 (크기 csr.cols)
  std::vector<TYPE> h_x(csr.cols);
  if (!read_vec_text(vec_path, h_x, csr.cols)){
    std::fprintf(stderr, "Failed to read vector '%s' with length %d\n", vec_path.c_str(), csr.cols);
    return 1;
  }

  // 디바이스 버퍼
  float *d_Ax=nullptr, *d_data=nullptr, *d_x=nullptr;
  int   *d_idx=nullptr, *d_perm=nullptr, *d_jds_ptr=nullptr, *d_shzcnt=nullptr;

  CUDA_CHECK(cudaMalloc(&d_Ax,      sizeof(float)*jds.dim));
  CUDA_CHECK(cudaMalloc(&d_data,    sizeof(float)*jds.len));
  CUDA_CHECK(cudaMalloc(&d_idx,     sizeof(int)  *jds.len));
  CUDA_CHECK(cudaMalloc(&d_perm,    sizeof(int)  *jds.dim));
  CUDA_CHECK(cudaMalloc(&d_x,       sizeof(float)*csr.cols));
  CUDA_CHECK(cudaMalloc(&d_jds_ptr, sizeof(int)  *jds.depth));
  CUDA_CHECK(cudaMalloc(&d_shzcnt,  sizeof(int)  *jds.nzcnt_len));

  CUDA_CHECK(cudaMemcpy(d_data,    jds.data.data(),   sizeof(float)*jds.len,      cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_idx,     jds.indices.data(),sizeof(int)  *jds.len,      cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_perm,    jds.perm.data(),   sizeof(int)  *jds.dim,      cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_x,       h_x.data(),        sizeof(float)*csr.cols,     cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_jds_ptr, jds.jds_ptr.data(),sizeof(int)  *jds.depth,    cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_shzcnt,  jds.sh_zcnt.data(),sizeof(int)  *jds.nzcnt_len,cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemset(d_Ax, 0, sizeof(float)*jds.dim));

  // 런치 구성: 원본과 동일 개념 — blockDim.x = pad, gridDim.x = ceil(dim/pad)
  dim3 block(pad, 1, 1);
  dim3 grid((jds.dim + pad - 1) / pad, 1, 1);

  std::printf("grid=%d, block=%d, dim=%d, depth=%d, len=%d\n",
              grid.x, block.x, jds.dim, jds.depth, jds.len);

  auto t0 = std::chrono::high_resolution_clock::now();
  spmv_jds_naive_kernel<<<grid, block>>>(d_Ax, d_data, d_idx, d_perm, d_x,
                                         jds.dim, d_jds_ptr, d_shzcnt);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
  auto t1 = std::chrono::high_resolution_clock::now();
  double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
  std::printf("Elapsed: %.3f ms\n", ms);

  // 결과 수거
  std::vector<float> h_Ax(jds.dim);
  CUDA_CHECK(cudaMemcpy(h_Ax.data(), d_Ax, sizeof(float)*jds.dim, cudaMemcpyDeviceToHost));

  // out.bin 요청시 저장 (Parboil 포맷과 동일: int N + float[N])
  if (!out_path.empty()){
    if (write_bin_with_size(out_path.c_str(), h_Ax.data(), jds.dim) != 0){
      std::fprintf(stderr, "Failed to write %s\n", out_path.c_str());
    } else {
      std::printf("Wrote %s\n", out_path.c_str());
    }
  }

  // gold 비교 (matrix.mtx -> matrix.gold)
  {
    std::string gold_path = replace_ext(mtx_path, ".gold");
    int gN=0; float* gbuf = read_gold_file(gold_path.c_str(), &gN);
    if (gbuf){
      if (gN != jds.dim){
        std::printf("error: gold data size mismatch: current=%d, expected=%d\n", jds.dim, gN);
      } else {
        int errors = compare_floats(h_Ax.data(), gbuf, gN);
        if (errors > 0) std::printf("FAILED!\n"); else std::printf("PASSED!\n");
      }
      std::free(gbuf);
    } else {
      std::printf("(gold '%s' not found — skipping check)\n", gold_path.c_str());
    }
  }

  // 정리
  cudaFree(d_Ax); cudaFree(d_data); cudaFree(d_idx);
  cudaFree(d_perm); cudaFree(d_x);
  cudaFree(d_jds_ptr); cudaFree(d_shzcnt);
  return 0;
}