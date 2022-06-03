#include <stdio.h>
#include <vx_print.h>

extern void saxpy(int);
int __thread  block_size=4;
int __thread  block_size_x=4;
int __thread block_index_x=0;
int __modsi3(){return 0;}
int __mulsi3(){return 0;}
int main()
{
    vx_printf("hello");
    saxpy(10);
    vx_printf("hello");
    return 0;
}
