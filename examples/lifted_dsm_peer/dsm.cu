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
    if(got[i]!=40+((i/2)^1)) {printf("FAIL %d got %d expected %d\n",i,got[i],40+((i/2)^1)); return 1;}
  }
  puts("PASSED! peer generic load/store, two clusters");
  return 0;
}
