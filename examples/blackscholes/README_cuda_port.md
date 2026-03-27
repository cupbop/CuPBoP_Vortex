
# CUDA Black-Scholes (port from OpenCL sample)

This is a clean-room CUDA implementation that mirrors the structure of NVIDIA's OpenCL
Black-Scholes sample. It keeps a similar split between:

- **`cudaBlackScholes_common.h`**: math helpers and CPU reference (used for QA).
- **`cudaBlackScholes_kernel.cu`**: device kernel and a host launcher `BlackScholesGPU(...)`,
  analogous to the OpenCL "launcher".
- **`main.cu`**: argument parsing, input generation, launching, timing and error checks.

## Build

```bash
make
```

You may override the GPU architecture, e.g.:

```bash
make ARCH="-arch=sm_80"
```

## Run

```bash
./cuda_blackscholes -n 1000000 -b 256 -r 0.05 -v 0.2
```

- `-n`: number of options
- `-b`: CUDA block size
- `-r`: risk-free rate
- `-v`: volatility

The program computes both GPU and CPU results and prints the average absolute error.

## Notes on 1:1 mapping

The original OpenCL sample separated:
- a *common* header with math helpers, and
- a *launcher* that builds the OpenCL program and enqueues the kernel.

In this CUDA port, `BlackScholesGPU(...)` provides the analogous single-call entry point
to run the kernel for a vector of options. If you want an even closer 1:1 API surface,
you can wrap your existing host code to call `BlackScholesGPU(...)` wherever the OpenCL
sample invoked its `BlackScholes(...)` function.
