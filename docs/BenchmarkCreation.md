# Benchmark Creation

Benchmarks in the `CuPBoP/examples` folder are based on the Rodinia benchmarks. Refer to the files in the [Rodinia](https://github.com/yuhc/gpu-rodinia/tree/master/cuda) repo for each benchmarks when creating new benchmarks. Also refer to the following script to serve as the foundation for your script: [General kjrun_llvm18.sh Script](./kjrun_llvm18.sh)

If you look at all benchmarks in the `CuPBoP/examples` folders have similar kjrun_llvm18.sh scripts. 



## Issues

Seeing a divergent branch isn't a main issue of concern. If you see some other issues like not defined errors within a file or executing a script leads to a non-stop loop, it suggests that CuPBoP doesn't support that benchmark.

Some issues in regards to using the Makefile with the benchmarks are reported [here](./CommonIssues.md)
