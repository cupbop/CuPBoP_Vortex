# CuPBoP-Vortex CI/CD Infrastructure

This repository utilizes a distributed CI/CD pipeline that bridges GitHub Actions with the CRNCH (HPC) Cluster. It is designed to run Vortex simulations using Slurm and Apptainer.

## CI Overview
* Execution begins at ```CuPBoP_Vortex/.github/workflows/ci.yml```
    * This CI is executed on pushes and pull requests and is configured to only use self-hosted runners
    * Phase 1: Build
        * Checks out repository
        * Runs automated SBATCH-based build script ```CuPBoP_Vortex/ci/run-crnch-cuda.sh```
    * Phase 2: Tests
        * Matrix "name" lists all currect tests in the testing suite
        * Matrix "scheduler" lists all supported Vortex schedulers
        * Runs automated testing script ```CuPBoP_Vortex/ci/run-crnch-cuda-test.sh```
    * Phase 3: Verification (future improvement)
    * Automated test scripts use ```CuPBoP_Vortex/ci/rg-ci-setup.sh``` to set environment variables
      
A job is only marked as Passed in GitHub if the Slurm job exits with code 0 AND the last 10 lines of the log file contain the following markers:

    --- Kernel compilation completed!

    --- Host compilation completed!

    --- Execution completed!

## Self-Hosted Runner File Structure
* Everything is located at ```/projects/ci-runners/CuPBoP-Vortex```
* GitHub runner is in the ```/projects/ci-runners/CuPBoP-Vortex/temp-runner``` directory
    * its work directory is at ```/projects/ci-runners/CuPBoP-Vortex/temp-runner/_work/CuPBoP-Vortex/CuPBoP-Vortex``` (this is where the repository will be cloned)
* Tools are in the ```/projects/ci-runners/CuPBoP-Vortex/tools``` directory
    * LLVM-vortex is in the ```/projects/ci-runners/CuPBoP-Vortex/tools/llvm``` directory
    * Vortex is in ```/projects/ci-runners/CuPBoP-Vortex/tools/vortex```
    * Other libraries are in ```/projects/ci-runners/CuPBoP-Vortex/tools/tooldir```
    * Apptainer files (cupbop_env.sif and cupbop_env.def) are in ```/projects/ci-runners/CuPBoP-Vortex/tools```
## Manual Testing & Reproduction

If a CI job fails, maintainers should reproduce the environment manually on a compute node. Do not run tests on the login node.

1. Start an Interactive Session

Request a node with the same specs used by the CI:

```
srun -p rg-nextgen-hpc -w dash[1-4] -N 1 --cpus-per-task=4 --mem=32G --gres=gpu:1 -t 00:30:00 --pty /bin/bash
```
2. Enter the Apptainer Environment and set environment variables

The CI environment is immutable and stored in a .sif file. Enter it using:
Bash
```
apptainer shell --nv -B /projects/ci-runners/CuPBoP-Vortex/:/projects/ci-runners/CuPBoP-Vortex cupbop_env.sif
source /projects/ci-runners/CuPBoP-Vortex/temp-runner/_work/CuPBoP_Vortex/CuPBoP_Vortex/ci/rg-ci-setup.sh
export VORTEX_SCHEDULE_FLAG=0 # or 2 if testing different scheduler algorithm
```
3. Build CuPBoP-Vortex
```
cd /projects/ci-runners/CuPBoP-Vortex/temp-runner/_work/CuPBoP_Vortex/CuPBoP_Vortex/
rm -rf build; mkdir build; cd build
cmake .. -DLLVM_CONFIG_PATH=`which llvm-config` # need path to llvm-config
make
```
4. Executing Tests:
```
cd /projects/ci-runners/CuPBoP-Vortex/temp-runner/_work/CuPBoP_Vortex/CuPBoP_Vortex/examples/YOUR_EXAMPLE
./kjrun_llvm18.sh
```
## Miscelaneous Notes
* Supporting libraries (i.e. Vortex and LLVM-Vortex) can be recompiled/updated using regular instructions, but this recompilation has to happen in the Apptainer environment (see above for how to enter Apptainer manually)
* **CI needs to run at least once every 2 weeks or Self-Hosted runner will need to be reactivated**
## Troubleshooting
* Log output can be found at ```/projects/ci-runners/CuPBoP-Vortex/logs/CuPBoP-cuda-test-SLURM_NUMBER.out``` for tests and ```/projects/ci-runners/CuPBoP-Vortex/logs/CuPBoP-cuda-SLURM_NUMBER.out``` for builds
    * SLURM_NUMBER can be found in the GitHub Actions console log
## Future Improvements
* Parallelize running tests by adding more runners
* Output test data to GitHub Actions (currently we only record whether the run succeeded or failed)
* Verify test data is correct (Could be done by running kernels using CUDA and recording those results)
* Update CuPBoP-Vortex to support entire test suite
