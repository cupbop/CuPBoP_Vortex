#include <cuda.h>
#include <stdio.h>

#ifdef RD_WG_SIZE_0_0
        #define BLOCK_SIZE RD_WG_SIZE_0_0
#elif defined(RD_WG_SIZE_0)
        #define BLOCK_SIZE RD_WG_SIZE_0
#elif defined(RD_WG_SIZE)
        #define BLOCK_SIZE RD_WG_SIZE
#else
        #define BLOCK_SIZE 16
#endif


__global__ void 
lud_diagonal(float *m, int matrix_dim, int offset)
{
  int i,j;
  __shared__ float shadow[BLOCK_SIZE][BLOCK_SIZE];

  int array_offset = offset*matrix_dim+offset;
  for(i=0; i < BLOCK_SIZE; i++){
    if (array_offset+threadIdx.x < matrix_dim*matrix_dim)
      shadow[i][threadIdx.x]=m[array_offset+threadIdx.x];
    array_offset += matrix_dim;
  }
  __syncthreads();
  for(i=0; i < BLOCK_SIZE-1; i++) {

    if (threadIdx.x>i){
      for(j=0; j < i; j++)
        shadow[threadIdx.x][i] -= shadow[threadIdx.x][j]*shadow[j][i];
      shadow[threadIdx.x][i] /= shadow[i][i];
    }

    __syncthreads();
    if (threadIdx.x>i){

      for(j=0; j < i+1; j++)
        shadow[i+1][threadIdx.x] -= shadow[i+1][j]*shadow[j][threadIdx.x];
    }
    __syncthreads();
  }

  /* 
     The first row is not modified, it
     is no need to write it back to the
     global memory

   */
  array_offset = (offset+1)*matrix_dim+offset;
  for(i=1; i < BLOCK_SIZE; i++){
    if (array_offset+threadIdx.x < matrix_dim*matrix_dim)
      m[array_offset+threadIdx.x]=shadow[i][threadIdx.x];
    array_offset += matrix_dim;
  }
}

__global__ void
lud_perimeter(float *m, int matrix_dim, int offset)
{
  __shared__ float dia[BLOCK_SIZE][BLOCK_SIZE];
  __shared__ float peri_row[BLOCK_SIZE][BLOCK_SIZE];
  __shared__ float peri_col[BLOCK_SIZE][BLOCK_SIZE];

  int i,j, array_offset;
  int idx;

  if (threadIdx.x < BLOCK_SIZE) {
    idx = threadIdx.x;
    
    array_offset = offset*matrix_dim+offset;
    for (i=0; i < BLOCK_SIZE/2; i++){
      if (array_offset+idx < matrix_dim*matrix_dim)
        dia[i][idx]=m[array_offset+idx];
      array_offset += matrix_dim;
    }
    
    array_offset = offset*matrix_dim+offset;
    for (i=0; i < BLOCK_SIZE; i++) {
      if(array_offset+(blockIdx.x+1)*BLOCK_SIZE+idx < matrix_dim*matrix_dim)
        peri_row[i][idx]=m[array_offset+(blockIdx.x+1)*BLOCK_SIZE+idx];
      array_offset += matrix_dim;
    }

  } else {
    idx = threadIdx.x-BLOCK_SIZE;
    
    array_offset = (offset+BLOCK_SIZE/2)*matrix_dim+offset;
    for (i=BLOCK_SIZE/2; i < BLOCK_SIZE; i++){
      if(array_offset+idx < matrix_dim*matrix_dim)
        dia[i][idx]=m[array_offset+idx];
      array_offset += matrix_dim;
    }
    
    array_offset = (offset+(blockIdx.x+1)*BLOCK_SIZE)*matrix_dim+offset;
    for (i=0; i < BLOCK_SIZE; i++) {
      if(array_offset+idx < matrix_dim*matrix_dim)
        peri_col[i][idx] = m[array_offset+idx];
      array_offset += matrix_dim;
    }
  
  }
  __syncthreads();

/* this version works ok on hardware, but not gpgpusim
 **************************************************************
  if (threadIdx.x < BLOCK_SIZE) { //peri-row
    idx=threadIdx.x;
    for(i=1; i < BLOCK_SIZE; i++){
      for (j=0; j < i; j++)
        peri_row[i][idx]-=dia[i][j]*peri_row[j][idx];
    }

    
    array_offset = (offset+1)*matrix_dim+offset;
    for(i=1; i < BLOCK_SIZE; i++){
      m[array_offset+(blockIdx.x+1)*BLOCK_SIZE+idx] = peri_row[i][idx];
      array_offset += matrix_dim;
    }
  } else { //peri-col
    idx=threadIdx.x - BLOCK_SIZE;
    for(i=0; i < BLOCK_SIZE; i++){
      for(j=0; j < i; j++)
        peri_col[idx][i]-=peri_col[idx][j]*dia[j][i];
      peri_col[idx][i] /= dia[i][i];
    }

    __syncthreads();
    
    array_offset = (offset+(blockIdx.x+1)*BLOCK_SIZE)*matrix_dim+offset;
    for(i=0; i < BLOCK_SIZE; i++){
      m[array_offset+idx] =  peri_col[i][idx];
      array_offset += matrix_dim;
    }
  }
***************************************************************/
  if (threadIdx.x < BLOCK_SIZE) { //peri-row
    idx=threadIdx.x;
    for(i=1; i < BLOCK_SIZE; i++){
      for (j=0; j < i; j++)
        peri_row[i][idx]-=dia[i][j]*peri_row[j][idx];
    }
  } else { //peri-col
    idx=threadIdx.x - BLOCK_SIZE;
    for(i=0; i < BLOCK_SIZE; i++){
      for(j=0; j < i; j++)
        peri_col[idx][i]-=peri_col[idx][j]*dia[j][i];
      peri_col[idx][i] /= dia[i][i];
    }
  }

  __syncthreads();
    
  if (threadIdx.x < BLOCK_SIZE) { //peri-row
    idx=threadIdx.x;
    array_offset = (offset+1)*matrix_dim+offset;
    for(i=1; i < BLOCK_SIZE; i++){
      if(array_offset+(blockIdx.x+1)*BLOCK_SIZE+idx < matrix_dim*matrix_dim)
        m[array_offset+(blockIdx.x+1)*BLOCK_SIZE+idx] = peri_row[i][idx];
      array_offset += matrix_dim;
    }
  } else { //peri-col
    idx=threadIdx.x - BLOCK_SIZE;
    array_offset = (offset+(blockIdx.x+1)*BLOCK_SIZE)*matrix_dim+offset;
    for(i=0; i < BLOCK_SIZE; i++){
      if(array_offset+idx < matrix_dim*matrix_dim)
        m[array_offset+idx] =  peri_col[i][idx];
      array_offset += matrix_dim;
    }
  }

}

__global__ void
lud_internal(float *m, const int matrix_dim, const int offset)
{
  __shared__ float peri_row[BLOCK_SIZE][BLOCK_SIZE];
  __shared__ float peri_col[BLOCK_SIZE][BLOCK_SIZE];



  for (int i=0; i < BLOCK_SIZE; i++)
  {
    for (int j=0; j < BLOCK_SIZE; j++)
      {
        peri_row[i][j] = 0.0f;
        peri_col[i][j] = 0.0f;
      }
  }

  __syncthreads();

  int i;
  float sum;
  //int bx = blockIdx.x;
  //int by = blockIdx.y;

  int global_row_id = offset + (blockIdx.x+1)*BLOCK_SIZE;
  int global_col_id = offset + (blockIdx.y+1)*BLOCK_SIZE;

  if (((offset+threadIdx.y)*matrix_dim+global_col_id+threadIdx.x) < matrix_dim*matrix_dim)
    peri_row[threadIdx.y][threadIdx.x] = m[(offset+threadIdx.y)*matrix_dim+global_col_id+threadIdx.x];
  if (((global_row_id+threadIdx.y)*matrix_dim+offset+threadIdx.x) < matrix_dim*matrix_dim)
    peri_col[threadIdx.y][threadIdx.x] = m[(global_row_id+threadIdx.y)*matrix_dim+offset+threadIdx.x];

  __syncthreads();
  //print peri_col if threadidx.x=0 and threadidx.y=0
  /*
  if (threadIdx.x == 0 && threadIdx.y == 0 && blockIdx.x==0 && blockIdx.y==0)
  {
    printf("peri_col\n");
    for (int i=0; i < BLOCK_SIZE; i++)
    {
      
      for (int j=0; j < BLOCK_SIZE; j++)
      {
      printf("%.2f ", peri_col[i][j]);
      }
      printf("\n");
    }
    printf("peri_row\n");
      for (int i=0; i < BLOCK_SIZE; i++)
      {
        for (int j=0; j < BLOCK_SIZE; j++)
        {
        printf("%.2f ", peri_row[i][j]);
        }
        printf("\n");
      }
    }
  */
      


  //if (threadIdx.x > BLOCK_SIZE || threadIdx.y > BLOCK_SIZE || threadIdx.x < 0 || threadIdx.y < 0 )
  //  printf("threadIdx.x=%d, threadIdx.y=%d, global_row_id=%d, global_col_id=%d\n", threadIdx.x, threadIdx.y, global_row_id, global_col_id);
  sum = 0.0f;
  i = 0;
  for (i=0; i < BLOCK_SIZE; i++)
  {
      if(peri_col[threadIdx.y][i] > 0.001 && peri_row[i][threadIdx.x] > 0.001)
      {
      sum += peri_col[threadIdx.y][i] * peri_row[i][threadIdx.x];
      //printf("sum+=%f %f\n", peri_col[threadIdx.y][i], peri_row[i][threadIdx.x]);
      }
  }
      int col_idx = ((global_row_id+threadIdx.y)*matrix_dim+global_col_id+threadIdx.x)/64;
      int row_idx = ((global_row_id+threadIdx.y)*matrix_dim+global_col_id+threadIdx.x)%64;
  //printf("accessing index: %d %d\n", col_idx, row_idx);
  if (((global_row_id+threadIdx.y)*matrix_dim+global_col_id+threadIdx.x) < matrix_dim*matrix_dim)
  {
    m[(global_row_id+threadIdx.y)*matrix_dim+global_col_id+threadIdx.x] -= sum;
    //printf("m[%d] -= %f\n", (global_row_id+threadIdx.y)*matrix_dim+global_col_id+threadIdx.x, sum);
    //printf("matrix_dim=%d global_row_id=%d global_col_id=%d\n", matrix_dim, global_row_id, global_col_id);

  }


}


void lud_cuda(float *m, int matrix_dim)
{
  int i=0;
  dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE);
  //float *m_debug = (float*)malloc(matrix_dim*matrix_dim*sizeof(float));

  //
  for (i=0; i < matrix_dim-BLOCK_SIZE; i += BLOCK_SIZE) {
  //i=0;
      lud_diagonal<<<1, BLOCK_SIZE>>>(m, matrix_dim, i);
      lud_perimeter<<<(matrix_dim-i)/BLOCK_SIZE-1, BLOCK_SIZE*2>>>(m, matrix_dim, i);
      dim3 dimGrid((matrix_dim-i)/BLOCK_SIZE-1, (matrix_dim-i)/BLOCK_SIZE-1);
      lud_internal<<<dimGrid, dimBlock>>>(m, matrix_dim, i); 
  }
  lud_diagonal<<<1,BLOCK_SIZE>>>(m, matrix_dim, i);
}