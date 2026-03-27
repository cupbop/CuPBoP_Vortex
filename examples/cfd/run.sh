# # #!/bin/bash
clang++ euler3d.cu -I/usr/local/cuda-10.1/samples/common/inc --cuda-path=/usr/local/cuda-10.1 --cuda-gpu-arch=sm_50 -L/usr/local/cuda-10.1/lib64 -lcudart_static -ldl -lrt -pthread -save-temps -v

../../build/compilation/kernelTranslator euler3d-cuda-nvptx64-nvidia-cuda-sm_50.bc kernel.bc
../../build/compilation/hostTranslator euler3d-host-x86_64-unknown-linux-gnu.bc  host.bc

llc --relocation-model=pic --filetype=obj  kernel.bc
llc --relocation-model=pic --filetype=obj  host.bc

g++ -Wall -L/../../build/runtime  -L/../../build/runtime/threadPool -o a.out -fPIC -no-pie host.o kernel.o -lc -lx86Runtime -lthreadPool -lpthread

./a.out ../rodinia-data/cfd/fvcorr.domn.097K
# ./demo 1024
# # # ./demo -f ../../data/matrix3.txt
# # # run -f ../../data/gaussian/matrix3.txt
