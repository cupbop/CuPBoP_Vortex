#!/bin/bash
# Determinism test: the same input must give the same translation wherever the allocator puts the IR (compilation/KernelTranslation/include/stable_order.h). ci/shufmalloc.c hands out
# chunks in random order and reuses freed ones, which moves std::set<T *> order and pointer hashes far more than ASLR alone. A translator that iterates a pointer-keyed container into the
# IR gives several hashes here; plain runs often do not show it.
#   usage (repository root, inside the CI container, ci/rg-ci-setup-v3.sh sourced): ci/determinism_test.sh; Slurm job: ci/determinism_test.sbatch
#   env: DET_RUNS (seeds per row, default 3), PAR (rows at once, default 8), DET_OUT (log dir), KT (translator, default build/compilation/kernelTranslator)
# Rows: lifted kernels that exercise the lift optimisation, and source examples the translator itself once moved on (examples/lift_* raw input; dotproduct, sgemm device bitcode).
# Prints one line per row and schedule; exits 1 unless every row gives one hash in every run and no translation fails.
set -u
RUNS=${DET_RUNS:-3} PAR=${PAR:-8}; KT=$(readlink -f ${KT:-build/compilation/kernelTranslator}); OUT=$(readlink -m ${DET_OUT:-ci/logs_v3/determinism_${SLURM_JOB_ID:-manual}}); mkdir -p $OUT
gcc -shared -fPIC -O2 -w -o $OUT/shufmalloc.so ci/shufmalloc.c -ldl -lpthread || { echo "shufmalloc build failed"; exit 1; }
for e in lift_g32 lift_hgemm lift_sdot lift_strsm; do xz -dc examples/$e/raw.ll.xz > $OUT/$e.ll || exit 1; done
for e in dotproduct sgemm; do d=examples/_det_$e; rm -rf $d; cp -a examples/$e $d
  make -C $d kernel.bc SCHEDULE=2 LOCALMEM=1 > $OUT/$e.make.log 2>&1 || { echo "$e: device bitcode failed ($OUT/$e.make.log)"; exit 1; }
  cp $d/*-cuda-nvptx64-nvidia-cuda-sm_*.bc $OUT/$e.bc || exit 1; rm -rf $d; done
one() { # input schedule run
  local in=$1 s=$2 i=$3 n=$(basename ${1%.*}) d=$OUT/w_$(basename ${1%.*})_s${2}_$3; mkdir -p $d
  ( cd $d; env LD_PRELOAD=$OUT/shufmalloc.so SHUF_REUSE=1 SHUF_SEED=$((i * 7919 + s)) VORTEX_SCHEDULE_FLAG=$s VORTEX_LOCALMEM_FLAG=1 timeout 300 $KT $in kernel.bc > tr.log 2>&1 ) || { echo "$n s$s FAIL"; return; }
  llvm-dis $d/kernel.bc -o $d/kernel.ll 2> /dev/null
  echo "$n s$s $(cat <(grep -vE '^(; ModuleID|source_filename)' $d/kernel.ll) $d/kernel_wrapper.cpp | md5sum | cut -c1-12)"; rm -rf $d
}
export -f one; export KT OUT
for f in $OUT/*.ll $OUT/*.bc; do for s in 2 1; do for i in $(seq 1 $RUNS); do echo "$f $s $i"; done; done; done | xargs -P $PAR -L 1 bash -c 'one "$@"' _ | sort > $OUT/hashes.txt
rc=0
for k in $(awk '{print $1 "/" $2}' $OUT/hashes.txt | sort -u); do n=${k%/*}; s=${k#*/}; h=$(awk -v n=$n -v s=$s '$1 == n && $2 == s {print $3}' $OUT/hashes.txt | sort -u | wc -l); f=$(awk -v n=$n -v s=$s '$1 == n && $2 == s && $3 == "FAIL"' $OUT/hashes.txt | wc -l)
  v=PASS; [ "$h" = 1 ] && [ "$f" = 0 ] || { v=FAIL; rc=1; }; printf "%-14s %-3s runs=%s hashes=%s %s\n" $n $s $RUNS $h $v; done
echo "=== determinism: $(sort -u -k1,2 $OUT/hashes.txt | wc -l) rows, $([ $rc = 0 ] && echo PASS || echo FAIL)"
exit $rc
