# Codebase Overview:

  

- `.github/workflows`: Define CI/CD implementation and actions
- `pre-commit-config.yaml`: Part of CI/CD implementation used to check if you can commit your changes
- `.gitignore`: Gives list of types of files the system should ignore when committing your changes
    
-   `compilation`: helps transform IR’s into ones that are compatible for  Vortex
    

	-   `HostTranslation`: transforming the Host IR
    

		-   `include`: All header files for files in src folder
    
		-   `src`: Source code for HostTranslation

			-   `vortex`: support for Vortex architecture

				-   `GenerateHostStub.cpp`:
    
				-   `InitializeDevice.cpp`:
    
				-   `RemoveCudeBuiltin.cpp`: Removing all cuda builtin functions (not compatible with CPU’s)
    
				-   `ReplaceConstantMemory.cpp`: Converting CUDA constant memory declarations into CPU compatible ones
    
				-   `ReplaceCudaBuiltin.cpp`: Replace all built-in functions compatible to CUDA with those compatible to CPU
    
				-   `ReplaceKernelArgs.cpp`: Make calls to cudaLaunchKernel compatible with CPU or device
    

			-   `x86`: Support for x86 architecture(files are similar to that in vortex folder)
    

	-   `KernelTranslation`: trasnforming the Kernel IR
    

		-   `include`: All header files for files in src folder
    
		-   `src`: Source code for HostTranslation
    

			-   `vortex`: support for Vortex architecture
    

				-   `generate_wrapper.cpp`: generates a wrapper function around a kernel function
	    
				-   `handle_sync.cpp`: Finds barriers and split blocks using these barriers 
	    
				-   `init.cpp`: Initializes block of components needed before execution for kernel translation
					    
				-   `insert_sync.cpp`: Insert barriers within kernel code to ensure coordination in execution
	    
				-   `insert_warp_loop.cpp`: Inserts warp-level loop and ensures handling at warp-level is correct
	    
				-   `memory_hierarchy.cpp`: Maps different memory hierarchy abstractions (shared, constant, global memory)  to ones LLVM can use
					    
				-   `performance.cpp`: Displays metrics (LAM, FAM, CGAM, MAM) that can be used to analyze and optimize performance
    
				-   `tool.cpp`: Provide helper functions that can be useful for working with the kernel
	    
				-   `warp_func.cpp`: Provide helper functions for warp-level operations
    

			-   `x86`: Support for x86 architecture (files are similar to that in vortex folder)
	- `HostTranslation.cpp`: Combines functions in HostTranslation folder to transform the Host IR
	- `KernelTranslation.cpp`: Combines functions in KernelTranslation folder to transform the Kernel IR

-   `data`: data about some benchmarks in examples folder
    
-   `examples`: benchmarks used in testing
    
-   `runtime`: relates to runtime library used to compile and link files together

	-   `include`: All header files for files in src folder
    
	-   `src`: source code
    

		-   `vortex`: support for Vortex architecture
    

			-   `host`: dealing with the transformed IR for source code
    

				-   `cudaRuntimeImpl.cpp`: managing and interfacing CUDA runtime operations
    

			-   `kernel`: dealing with the transformed IR for kernel code
    

				-   `Makefile`: Lists targets and rules for compiling and linking the kernel sources
    
				-   `cudaKernelImpl.cpp`: Implements basic arithmetic functions Vortex can use in runtime compilation
    
				-   `cudaKernelImpl.o`: Object file from cudaKernelImpl.cpp file
    
				-   `cudaKernelImpl_64.o`: Object file for 64-bit architecture
    

		-   `x86`: Support for x86 architecture
    

	-   `threadPool`: managing thread pool
    

		-   `include`: All header files for files in src folder
		    
		-   `src`: source code
    

			-   `api.cpp`: Implements threads in threadpool
			
- `CuPBoP_env_setup.sh`: Environment setup for CuPBoP
- `CuPBoP_env_setup_wo_PoCL.sh`: Environment setup for CuPBoP if device can't use the Portable Computing Language
- `docs`: folder containing all files for README file documentation