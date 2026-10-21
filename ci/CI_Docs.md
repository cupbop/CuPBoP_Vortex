# CuPBoP-Vortex CI/CD Infrastructure

This repository utilizes a distributed CI/CD pipeline that bridges GitHub Actions with the CRNCH (HPC) Cluster. It is designed to run Vortex simulations using Slurm and Apptainer.

**Target: Vortex 3.0** (release tag `v3.0`) with toolchain v3.0.1 (Vortex LLVM 20). The 2.0 flow (`tools/vortex_bugfix_branch`, LLVM 18, `ci/rg-ci-setup.sh`) is no longer used by the workflow.

## CI Overview
* Execution begins at `CuPBoP_Vortex/.github/workflows/ci.yml`
    * This CI is executed on pushes and pull requests and is configured to only use self-hosted runners
    * Phase 1: Build — `ci/run-crnch-cuda.sh` (Slurm job, 16 CPUs)
        * Checks out the repository
        * Builds the CuPBoP translators and host runtime against the Vortex LLVM 20 (`cmake` + `make`); the host runtime is compiled with the `VX_CFG_*` flags of the SimX configuration (`gen_config.py`)
        * Makes sure the two SimX drivers exist: `$VORTEX_HOME/build64_cupbop` (main configuration) and `$VORTEX_HOME/build64_cupbop_tcu` (TCU + DXA, for `sgemm_tcu`, `sgemm_dxa`, `sgemm_tcu_dxa`). `cupbop_v3_ensure_simx` records the flags in `<build>/.cupbop_simx_configs` and only rebuilds when `VORTEX_CONFIGS` changed
    * Phase 2: Tests — `ci/run-crnch-cuda-test.sh`, one Slurm job per matrix entry
        * Matrix "name" lists all current tests, "scheduler" the CuPBoP schedulers (2 = one CUDA thread per hardware thread, 0 = FLAT/one block per hardware thread), "localmem" whether `__shared__` goes to the Vortex local memory
        * `make -C examples/<name> ci SCHEDULE=<s> LOCALMEM=<l>` translates the example, builds the kernel ELF in a Vortex regression cell (`$VORTEX_PATH/tests/regression/cupbop_<name>_s<s>_l<l>`, see `examples/v3_cell.mk`) and runs it on SimX
    * Phase 3: Verification — `ci/check_correctness.sh <name> <scheduler> <localmem>`
        * Program verdict (`PASSED`, huffman: `PASS! vectors are matching!`) and no `FAIL` line, or `ci/compare_golden.py` against the golden file (tolerance 1e-4), or an exact diff, depending on the example
        * Writes `examples/<name>/ci_status_SCHE_<s>_LMEM_<l>.txt`; `perf_summary.py` / `perf_summary_all.py` add the `Perf_counter_*` numbers to the GitHub step summary
    * All scripts source `ci/rg-ci-setup-v3.sh` for the environment (paths, `VORTEX_CONFIGS`, helper functions)

A matrix entry is marked Passed in GitHub only if the Slurm job log contains the three markers below **and** the correctness check passes:

    --- Kernel compilation completed!

    --- Host compilation completed!

    --- Execution completed!

### Vortex 3.0 configuration (`ci/rg-ci-setup-v3.sh`)
`VORTEX_CONFIGS = -DVX_CFG_NUM_CORES=4 -DVX_CFG_NUM_WARPS=16 -DVX_CFG_NUM_THREADS=32 -DVX_CFG_EXT_A_ENABLE -DVX_CFG_EXT_ZACAS_ENABLE -DVX_CFG_L2_ENABLE` (the tensor examples add `-DVX_CFG_EXT_TCU_ENABLE -DVX_CFG_EXT_DXA_ENABLE`). The three extension flags are required, not tuning: 3.0 ships with the A extension off (SimX aborts silently on the first atomic), `atomicCAS` lowered to an lr/sc loop livelocks across the lanes of a warp (Zacas gives a single `amocas`), and without an L2 every core's private L1 is the last-level cache where atomics commit, so cross-core atomics lose updates. Changing `VORTEX_CONFIGS` is enough; the next build job rebuilds SimX.

### Known state (Vortex 3.0, 2026-10-20)
73 of the 77 matrix entries pass (jobs 174318/174324 on a scratch tree, 174326 on the installed tools tree). Expected failures, all SCHE_0 (FLAT): `wedford-cuda` (translation under LLVM 20), `score-cuda` (3.0 runtime side), `jaccard-cuda` (also failed on 2.0), `huffman` (timeout on 2.0 and 3.0). `btree` SCHE_2 segfaulted once in four runs.

## Self-Hosted Runner File Structure
* Everything is located at `/projects/ci-runners/CuPBoP-Vortex`
* GitHub runner is in the `/projects/ci-runners/CuPBoP-Vortex/temp-runner` directory
    * its work directory is at `/projects/ci-runners/CuPBoP-Vortex/temp-runner/_work/CuPBoP_Vortex/CuPBoP_Vortex` (this is where the repository will be cloned)
* Tools are in the `/projects/ci-runners/CuPBoP-Vortex/tools` directory
    * **Vortex 3.0 source + builds: `tools/vortex_v3.0`** (checkout of tag `v3.0` plus the patches listed in `ci/patches/README.md`; `build64_cupbop*` are created by the build job)
    * **Toolchain v3.0.1: `tools/tools-v3.0.1`** (`llvm-vortex`, `riscv64-gnu-toolchain`, `libc64`, `libcrt64`, ...)
    * Apptainer files (`cupbop_env.sif`, `cupbop_env.def`: Ubuntu 22.04 + CUDA 12.1) are in `tools`
    * Legacy 2.0 tools (`vortex`, `vortex_bugfix_branch`, `llvm`, `llvm_edited`, `tooldir`) are kept but unused
* The directory is group-writable (`coc-rg-login`, setgid). The runner account must be able to write `tools/vortex_v3.0/build64_cupbop*` (regression cells are built there); keep `g+rwX` when reinstalling.

## Manual Testing & Reproduction

If a CI job fails, maintainers should reproduce the environment manually on a compute node. Do not run tests on the login node.

1. Start an Interactive Session

```
srun -p rg-nextgen-hpc -w dash[1-4] -N 1 --cpus-per-task=4 --mem=32G -t 00:30:00 --pty /bin/bash
```
2. Enter the Apptainer Environment and set environment variables (from the repository root)

```
apptainer shell -B /projects/ci-runners/CuPBoP-Vortex/:/projects/ci-runners/CuPBoP-Vortex /projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif
source ./ci/rg-ci-setup-v3.sh
```
3. Build CuPBoP-Vortex (what the build job does)
```
XCFG=$(python3 $VORTEX_HOME/ci/gen_config.py --config=$VORTEX_HOME/VX_config.toml --cflags="$VORTEX_CONFIGS -DVX_CFG_XLEN=64")
rm -rf build; mkdir build; cd build
cmake .. -DLLVM_CONFIG_PATH=$LLVM_CONFIG_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$XCFG"
make -j8 kernelTranslator hostTranslator vortexRuntime ThreadPool   # not `make all`: vortexRuntimeKernel is a 2.0-era target
cd ..
cupbop_v3_ensure_simx $VORTEX_PATH "$VORTEX_CONFIGS"            # idempotent
cupbop_v3_ensure_simx $VORTEX_PATH_TCU "$VORTEX_CONFIGS_TCU"
```
4. Run one example and check it:
```
cupbop_v3_select_simx <name>           # only needed for sgemm_tcu / sgemm_dxa / sgemm_tcu_dxa
make -C examples/<name> ci SCHEDULE=2 LOCALMEM=1
./ci/check_correctness.sh <name> 2 1
```
5. Whole matrix as a single Slurm job (77 runs, ~40 min with `PAR=6`), from the repository root:
```
sbatch --export=ALL,PAR=6 ci/run-v3-matrix.sbatch      # results: ci/logs_v3/run_<jobid>/results.csv
```
A dry run of the exact workflow scripts from a fresh clone (`GITHUB_WORKSPACE=<clone>`, `CI_EXTRA_BINDS=/net/netscratch,/nethome`, `CI_LOG_DIR=<writable dir>`, then `bash ci/run-crnch-cuda.sh` and `TEST_NAME=... VORTEX_SCHEDULE_FLAG=... VORTEX_LOCALMEM_FLAG=... bash ci/run-crnch-cuda-test.sh`) is how the 3.0 scripts were validated.

## Miscellaneous Notes
* Supporting libraries (Vortex 3.0 and its toolchain) can be reinstalled with the regular Vortex instructions; `tools/vortex_v3.0` is a plain git checkout and the toolchain is the v3.0.1 tarball set. Rebuilding SimX must happen in the Apptainer environment (the build job does it automatically when `VORTEX_CONFIGS` changes).
* **CI needs to run at least once every 2 weeks or the self-hosted runner will need to be reactivated** (`.github/workflows/heartbeat.yml`).
## Troubleshooting
* Log output can be found at `/tools/ci-reports/CuPBoP_logs/CuPBoP-cuda-test-SLURM_NUMBER.out` for tests and builds (`<name>.out` links to the latest run of that example)
    * SLURM_NUMBER can be found in the GitHub Actions console log
* `[VXDRV] Warning: CP has not retired a command in 10s` is SimX's poll warning on long kernels, not the failure
* A kernel that aborts on the first atomic, hangs in `atomicCAS` or gets wrong counts across cores means the SimX was built without the A / Zacas / L2 flags — check `<build>/.cupbop_simx_configs`
## Future Improvements
* Parallelize running tests by adding more runners
* Fix the four remaining SCHE_0 failures listed above
