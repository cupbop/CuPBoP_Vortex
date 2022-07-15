#include <stdio.h>
#include <vx_print.h>

extern void saxpy(void);
int __thread  block_size=4;
int __thread  block_size_x=4;
int __thread block_index_x=0;
int __modsi3(){return 0;}
int __mulsi3(){return 0;}
int main()
{
    vx_printf("main--hello\n");
    saxpy();
    vx_printf("main--hello\n");
    return 0;
}
