## Tools

Although this can be run on any Linux based environment, it's recommended you use VSCode's Remote SSH feature if you're using the Kia or Volvo server. Following the instructions using VSCode with access to a server should ensure you don't run into errors. 

When looking at the `/examples` folder, use the `makefile` to speed up the execution as it requires less manual effort. Refer to a summary of the [Makefile](./Makefile_Guide.md).

If trying to support some benchmarks in the `/examples` folder, refer to the table and the Rodinia benchmarks in [README](../README.md), which is what our benchmarks are based on.

Also `/samples/common` folder has some file relating to cfd benchmark that wasn't there. Use  `cd cuda-12.1`, `git clone https://github.com/NVIDIA/cuda-samples/tree/master`, and rename it to samples. The folder relevant should be under samples/common. 