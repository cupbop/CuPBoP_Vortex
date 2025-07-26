# Common Issues

## Build issues

When making changes to the `/compilation` folder, make sure that you can execute the build script used to set up the environment variables in the current session. If you receive an error, you should look at the message and understand what change caused it. [General kjrun_llvm18.sh Script](./kjrun_llvm18.sh) FIX


## Makefile Issues

No issues should arise from running a benchmark if you use the makefile, as it ensures a easy cleanup process. However, if you are having trouble removing some newly generated files or directories, here's how you can fix them.

Note: Make sure to save a copy of the files you modified outside the `CuPBoP/` repo.

### Unnecessary Untracked files fix:
Execute the following commands:

`cd CuPBoP/examples`

Remove files by their type:
`find . -type f \( -name "*.log" -o -name "*.o" -o -name "*.out" -o -name "*.ll" -o -name "*.bc" \) -delete; \`

  Remove trace directory:
`find . -type d -name "trace" -exec rm -rf {} +`

  Restore deleted files that were previously committed:
`git restore . `  

### Unnecessary Uncommitted files fix:

Use command: `git clean -fd`

  
  

### Changes to Committed file:

Use command: `git restore .`

## Current Benchmark Issues
(As of 7/26/2025):

`hotspot3D` - taking too long to execute, might be in infinite loop

`particlefilter` - Results after running multiple times aren't consistent. Other benchmarks have same exact or almost same stats for each run, which is in `perf_counter_1C_4W_4T_thread_map_mem.txt` for each benchmark. 
