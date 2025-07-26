As of 7/26/2025:

   <div align="center">

   | Benchmark       | Supported? | CUDA feature             |
   |------------------|:----------:|--------------------------|
   | microbench (saxpy) |     O      |                          |
   | gauss           |     O      | Multi-kernel in series    |
   | bfs             |     O      |                          |
   | nn              |     O      | Math Library (sqrt)       |
   | nw              |     O      | Shared Mem + syncthreads  |
   | srad_v2              |     O      | Shared Mem + syncthreads  |
   | hotspot         |     O      | Shared Mem + syncthreads  |
   | StreamCluster   |     O      | Const Mem                |
   | Myocyte         |     O      |                          |
   | Pathfinder      |     O      | Shared Mem + syncthreads  |
   | LUD             |     O      | Shared Mem + syncthreads  |
   | CFD             |     X      | device, inline function   |
   | Btree           |     O      |                          |
   | Backprop        |     O      | __powf, __log2f          |
   | Heartwall       |     X      |                          |
   | Huffman         |     X      | Atomics                  |
   | Hotspot3D         |     ?(might be in loop)      |                   |
   | ParticleFilter         |     ?(inconcistent perf data)      |                  |
   | Testbench         |     O      |                  |
   
   </div>