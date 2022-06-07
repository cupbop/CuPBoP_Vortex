#ifndef C_API_H
#define C_API_H

#include "structures.h"

cu_kernel *create_kernel(const void *func, dim3 gridDim, dim3 blockDim,
                         void **args, size_t sharedMem, cudaStream_t stream);
int getWorkItem(struct kernel_queue **qu, cu_kernel *ker,
                struct argument *kernel_arg, int **blockId);
int create_KernelQueue(kernel_queue **q);

int dequeKernelLL(struct kernel_queue **qu);

int dequeKernel(struct kernel_queue **qu, cu_kernel *ker);
int enqueueKernel(struct kernel_queue **qu, cu_kernel **ker);

int scheduler_init(cu_device device);
void scheduler_uninit();
void cuSynchronizeBarrier();

int set_kernel_arguments(cu_kernel **k, unsigned int arg_num, void **arg_value);

int setKernelDimensions(cu_kernel *k, struct argument **arg,
                        void **totalBlockSize, void *blockId);

int init_device();
int cuLaunchKernel(cu_kernel **k);

#endif
