# CUDA C++ cluster and asynchronous copy support on Vortex

## Device API coverage

The CUDA 12.1 frontend can build the following source APIs for the direct CTA mapping
(`SCHEDULE=2 LOCALMEM=1`, 32 hardware lanes). CPU references in
`examples/cuda_async_api` and `examples/cluster_queries` check values copied back from SimX.

| Source interface | Regression |
| --- | --- |
| `cooperative_groups::memcpy_async(thread_block, ...)` and `wait(group)` | Two CTAs copy seven tiles and read a neighbor's values after the wait |
| `cuda::memcpy_async(group, ..., barrier)` and `barrier.arrive_and_wait()` | Static shared block barrier, 64 arrivals per phase |
| Block-scope `cuda::pipeline` | Three stages with seven tiles, both a unified group and distinct producer and consumer warps |
| Thread-scope `cuda::pipeline` | Each thread enqueues three stages, waits for its own copies, then shares the tile after a CTA barrier |
| `this_cluster()` | Block and thread ranks, both dimensions and sizes, DSM mapping and ownership, `sync()`, split arrival with both wait overloads |
| Grid cluster queries | `cluster_index()`, `cluster_rank()`, `dim_clusters()`, `num_clusters()`, and implicit versus explicit singleton launches |

The copy regressions build separately for the SM80 and SM90 CUDA frontend targets.
Each run compares 3,584 device words with the CPU. The cluster tests use an SM90 frontend.
The dimensions under test include (1,1,1), (1,2,1), (2,1,1), (2,2,1), (1,4,1), (4,1,1)
and (1,2,2). At launch each CUDA cluster must fit within the warp and local-memory capacity
of one Vortex core. A grid can distribute different CUDA clusters to different cores.

## Launch interfaces and limits

- Both `__cluster_dims__` and `cudaLaunchKernelEx[C]` with `cudaLaunchAttributeClusterDimension`
  supply launch geometry. The runtime accepts the three CUDA 12.1 cluster scheduling preferences
  as hints. Its placement policy keeps the member CTAs on one core.
- `cudaDeviceGetAttribute(cudaDevAttrClusterLaunch)` and `cudaGetDeviceProperties().clusterLaunch`
  report cluster-launch availability for the selected mapping.
- The Vortex runtime has no implementation of `cudaOccupancyMaxPotentialClusterSize`,
  `cudaOccupancyMaxActiveClusters`, per-function cluster attributes via
  `cudaFuncGetAttributes` / `cudaFuncSetAttribute`, or cluster attributes on CUDA Graph nodes.
- The tested block pipelines use 32-lane warps with uniform arrival counts.
  The ordinary Vortex mbarrier counts warp arrivals and has a finite pool of hardware barrier IDs.
  Uneven participation, arbitrary stage counts and deadline-based `try_wait_for` / `try_wait_until`
  have no general conformance guarantee. Some PTX wait forms lower to a blocking Vortex wait.
- The C++ copy tests use functional synchronous transfers. Their results establish completion,
  visibility and safe reuse in the tested patterns. Transfer/compute overlap needs separate timing tests.
- With multiple SimX hardware clusters and private L2 caches, simultaneous bulk reductions into a
  common global word require a shared coherence point. In the PortCompass `cluster_topology` regression,
  two four-CTA CUDA clusters each update four common words. With L3 off, remote shared reads matched
  8/8 and global sums matched 0/4 (first sum 15,573, expected 16,896). With shared L3, both
  checks matched (8/8 and 4/4). Two sockets sharing L2 also passed.

## Blackwell cluster launch control

CuPBoP lowers `clusterlaunchcontrol.try_cancel` from CUDA inline PTX and
CuLifter-recovered kernels. On a directly mapped SimX launch, each issuing thread
can claim a whole cluster that the kernel management unit has yet to dispatch.
A successful claim removes that cluster from normal dispatch. The claimant uses
`query_cancel.is_canceled` and `query_cancel.get_first_ctaid` to obtain its first
CTA's three-dimensional ID and compute its tiles. The existing placement policy
keeps every CUDA cluster's CTAs on one Vortex core.

An ordinary request publishes a 16-byte response and completes 16 transaction
bytes on the issuing CTA's mbarrier. With `.multicast::cluster::all` every CTA in
the issuing cluster receives the same response and completion at the same two
shared-memory offsets. Both success and decline complete the transaction. The
tests check either ordering of the request and `arrive.expect_tx`. On a SimX
build with asynchronous publication, the issuing lane returns after submitting
the request. SimX writes each recipient's response to local memory and updates
that recipient's barrier independently of the issuing warp. See the
[PTX cluster launch control specification](https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-clusterlaunchcontrol-try-cancel).

Use matching SimX driver and device headers from Vortex `vx-l1fix` at
`654639361` for asynchronous publication. The first
mailbox-only revision (`f3157ab64988`) supports claims with a blocking poll on
the issuing lane. Builds predating the mailbox and other backends decline the
request and complete its mbarrier. The translator disables CTA-loop coalescing
for kernels that issue CLC requests.

From the configured CuPBoP environment, exercise two issuing lanes in one warp
and both mbarrier orderings with:

```sh
make -C "$CuPBoP_PATH/examples/cluster_cancel" ci SCHEDULE=2 LOCALMEM=1
```

For the cubin-to-SimX test, set `CULIFTER_HOME` and `CULIFTER_ENV` to the
CuLifter checkout and its Python environment. Put Blackwell-capable `ptxas`,
`cuobjdump` and `nvdisasm` on `PATH` (tested with CUDA 13.3), then run:

```sh
bash "$CuPBoP_PATH/ci/cluster_cancel_lift_test.sh"
```

This builds ordinary requests for `sm_100`, `sm_100a`, `sm_120` and `sm_120a`,
plus multicast requests for the two architecture-specific targets. Each cubin
runs on a single-cluster grid and a 128-CTA grid. The `sm_100a` multicast
probe runs with 2×1, 1×2, 2×2 and 1×4 clusters. The CPU checks ordinary
and claimed tile values, unique tile ownership, response delivery and mbarrier
completion. The script prints the directory containing the cubins, disassembly,
lifted bitcode and SimX output. To test a build with older device headers, select
its `VORTEX_PATH` and pass `--expect-decline`.

## Reproduction

From a Vortex 3 build environment with the CUDA 12.1 toolkit, build `kernelTranslator`,
`hostTranslator`, `vortexRuntime` and `ThreadPool`, then run:

```sh
"$CuPBoP_PATH/ci/cluster_api_test.sh"
```

The script prints a fresh directory containing each build log, device binary and runtime output.
It runs five copy variants per frontend target, the cluster query regression and the existing
cluster group, multicast and bulk-reduction examples. The separate cross-hardware-cluster stress
test lives under `experiments/motivation/kernel_sweep/blackwell_full/tcgen_cluster/cluster_topology`
in the PortCompass artifact.
