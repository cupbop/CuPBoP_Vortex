#include "../async_common.h"
extern "C" __global__ void dsm(int *out) {}
int main() {
  int *p, got[8];
  ASYNC_CHECK(cudaMalloc(&p,sizeof(got)));
  cudaLaunchAttribute a{};
  a.id=cudaLaunchAttributeClusterDimension;
  a.val.clusterDim={2,1,1};
  cudaLaunchConfig_t cfg{};
  cfg.gridDim=dim3(4); cfg.blockDim=dim3(1); cfg.attrs=&a; cfg.numAttrs=1;
  void *args[]={&p};
  ASYNC_CHECK(cudaLaunchKernelExC(&cfg,(const void*)dsm,args));
  ASYNC_CHECK(cudaMemcpy(got,p,sizeof(got),cudaMemcpyDeviceToHost));
  for(int i=0;i<8;i++) {
    int expected = 40 + ((i / 2) ^ 1) + (i % 2);
    if (got[i] != expected) {
      printf("FAIL %d got %d expected %d\n", i, got[i], expected);
      return 1;
    }
  }
  puts("PASSED! remote atomics through reloaded shared-window addresses");
  return 0;
}
