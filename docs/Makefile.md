# Makefile
## Intro
This makefile provides an easy way for one to execute all benchmarks in the `examples/` folder with a `kjrun_llvm18.sh` script.

As said in the README file, the cleanup process is tedious if done manually. In addition, if you already executed a benchmark and have the results, you shouldn't run it unless a key dependency file is modified. This makefile aims to solve both of these issues.

## Basic Ideas

Most makefiles just have two targets `all` and `clean`. However, we want to keep the files that are in the folder of each benchmark originally. Having a clean command that resembles the `clean.sh` script would remove some original files of some benchmarks, which we want to avoid.

To solve this issue, our team created two new targets: `tracking` and `clean-tracking`. The idea is that before running `make` or `make all`, you should run `make tracking`, which creates a file that stores the name of the files that were there originally. This file will be used in `make clean` to remove the files that were generated from running the benchmarks. You should try not to remove the tracking file unless you generate any new files, didn't run any benchmarks, or the `\examples` folder is updated. If you need to remove the tracking file, you can do so by `make clean-tracking`

## Summary:
`make tracking`: Creates tracking file (stores the names of all original files in `\examples`)
`make all`: Runs all benchmarks with `kjrun_llvm18.sh` script
`make clean`: Cleans all files generated from running benchmarks using tracking file
`make clean-tracking`: Removes tracking file if needed (be careful about removing this file and don't run this if you ran `make all` or `make` but not `make clean` after)

Note:
This makefile doesn't deal with reverting files that were changed to its original form when running `make clean`. This is because of the complexity in determining if a file was edited and reverting it back to it's original form. However, running all the benchmarks will only change a small amount of files (around a dozen) compared to new files that will be generated (100s). The changes to the files aren't significant and you can rerun them again to get the same results. In addition, you can use command `git restore .` to revert the changed files back to normal but not the new files.


