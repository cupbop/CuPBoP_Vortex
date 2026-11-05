#!/bin/bash
# Lift tests: examples/lift_* (device code = IR lifted from machine code) on the rows of ci/lift_cases.txt. The regular matrix has source kernels only, and most
# of the lift optimisation (translator switches, passes) acts on lifted IR only.
#   usage (repository root, inside the CI container, ci/rg-ci-setup-v3.sh sourced): ci/lift_test.sh [regex on the row name]; Slurm job: ci/lift_test.sbatch
#   env: PAR (rows at once, default 8), LIFT_OUT (log dir, default ci/logs_v3/lift_<job>), LIFT_CASES (table), LIFT_KEEP=1 (keep the work dirs), LIFT_ENV (VAR=VALUE added to every
#        row), LIFT_BITS_RECORD=1 (write the bit records of the rows into the examples' lift_bits.txt instead of comparing), LIFT_OPT_IN_TRANSLATOR=1 (rows with input pre run
#        as raw with CUPBOP_LIFT_OPT=1: the same test once the translator does the lift optimisation; the pass log then comes from the translator)
# Prints one line per row, a summary, and exits 1 unless every row got what the table says. A row is good when
#   PASS : it builds, ci/check_correctness.sh says PASS (program verdict or golden, and the bit record of its group), every coverage pattern is in the
#          translator log or in the pass log <input>.passes.txt of the input (the transformation under test really acted on this input)
#   XFAIL: it builds and the answer is wrong (a known bug, kept as a regression test); a row that passes is an error too (XPASS: the bug is gone, change the table)
#   XHANG: as XFAIL for a known hang
#   REFUSE: the translator stops with the coverage patterns in its log (an input it must not compile silently)
#   SKIP : a row that needs what this tree does not have (LIFT_NEEDS, hw mufu), printed in the summary
set -u
export PAR=${PAR:-8} RUN_TAG=${SLURM_JOB_ID:-manual}
export LIFT_OUT=${LIFT_OUT:-$PWD/ci/logs_v3/lift_$RUN_TAG} LIFT_CASES=${LIFT_CASES:-$PWD/ci/lift_cases.txt}
mkdir -p $LIFT_OUT; export RES=$LIFT_OUT/results.csv; echo "name,example,sched,hw,input,expect,group,verdict,stage,seconds" > $RES
export VORTEX_CP_POLL_TIMEOUT_S=${VORTEX_CP_POLL_TIMEOUT_S:-300}
LIFT_RAW="CUPBOP_LIFT_OPT=0"   # table macros: %RAW %BASE %ON
LIFT_BASE="CUPBOP_SMEM_RESERVE_DROP=1 CUPBOP_PARAM_FORWARD=all CUPBOP_DXA_CLOBBER=1 CUPBOP_SMEM_SHRINK=1"
LIFT_ON="CUPBOP_DIV_RESTORE=1 CUPBOP_SQRT_RESTORE=1 CUPBOP_ADDR_CARRY=1 CUPBOP_PARAM_SPAN=1 CUPBOP_TRIP_HOIST=1 CUPBOP_TRIP_VERSION=1 CUPBOP_PARAM_DYN=2"
export LIFT_RAW LIFT_BASE LIFT_ON
run_row() { # name example sched hw input expect group covers [VAR=VALUE...]
  local name=$1 ex=$2 sch=$3 hw=$4 input=$5 expect=$6 group=$7 covers=$8; shift 8
  local d=examples/_lit_$name log=$LIFT_OUT/$name.log t0=$SECONDS s stage verdict rc r p passes skip=
  for p in "$@"; do case $p in LIFT_NEEDS=*) grep -aq "${p#LIFT_NEEDS=}" build/compilation/kernelTranslator || skip="translator without ${p#LIFT_NEEDS=}" ;; esac; done
  [ "$hw" = mufu ] && case "$VORTEX_CONFIGS" in *MUFU*) ;; *) skip="SimX without MUFU" ;; esac
  if [ -n "$skip" ]; then printf "%-26s %-14s %-5s %-4s %-6s expect=%-5s SKIP (%s)\n" $name $ex $sch $hw $input $expect "$skip"; echo "$name,$ex,$sch,$hw,$input,$expect,$group,SKIP,-,0" >> $RES; return; fi
  rm -rf $d; cp -a examples/$ex $d; rm -f $d/lift_d2h.txt
  passes=$d/$input.passes.txt
  # the launch rewrite comes from the translator then (cupbop_launch_fix.txt): no LIFT_DYN_SMEM. LIFT_MERGE examples stay pre: a module with source kernels beside the lift is not a lifted module for the translator
  if [ "$input" = pre ] && [ -n "${LIFT_OPT_IN_TRANSLATOR:-}" ] && ! grep -q '^LIFT_MERGE *= *1' $d/Makefile; then
    input=raw; passes=/dev/null; local a=(); for p in "$@"; do case $p in LIFT_DYN_SMEM=*) ;; *) a+=("$p") ;; esac; done; set -- "${a[@]}" CUPBOP_LIFT_OPT=1; fi
  case $sch in s2) s=2 ;; s1) s=1 ;; s1p*) s=1; set -- CUPBOP_VIRT_WARPS=${sch#s1p} "$@" ;; *) echo "$name: bad schedule $sch"; return ;; esac
  [ "$hw" = main ] || [ "$hw" = mufu ] || set -- VORTEX_PATH=$VORTEX_PATH_TCU "VORTEX_CONFIGS=$VORTEX_CONFIGS_TCU" CUPBOP_MMA_LOWERING=tcu LD_LIBRARY_PATH=$VORTEX_PATH_TCU/sw/runtime:$LD_LIBRARY_PATH "$@"
  ( env ${LIFT_ENV:-} "$@" timeout ${LIFT_ROW_TIMEOUT:-600} make -C $d ci SCHEDULE=$s LOCALMEM=1 LIFT_INPUT=$input ) > $log 2>&1; rc=$?
  r=$(CI_EXAMPLE_DIR=$d LIFT_BITS_GROUP=$group ./ci/check_correctness.sh $ex $s 1 2>&1 | tee -a $log | sed -n 's/^RESULT=//p')
  if grep -q 'CP poll timed out' $log || [ $rc -eq 124 ]; then stage=hang; elif grep -q '^--- Execution completed' $log; then stage=run; elif [ -s $d/kernel.bc ]; then stage=build; else stage=translate; fi
  if [ "$stage" = run ] && [ "$r" = PASS ] && [ $rc -eq 0 ]; then
    stage=ok; for p in ${covers//,/ }; do [ "$p" = - ] || cat $log $passes 2>/dev/null | grep -qE "${p//\~/ }" || stage="cover:$p"; done; fi
  case $expect in
    PASS)  [ "$stage" = ok ] && verdict=PASS || verdict=UNEXPECTED ;;
    XFAIL) case $stage in ok) verdict=XPASS ;; run) verdict=XFAIL ;; *) verdict=UNEXPECTED ;; esac ;;
    XHANG) case $stage in ok) verdict=XPASS ;; hang) verdict=XHANG ;; *) verdict=UNEXPECTED ;; esac ;;
    REFUSE) verdict=UNEXPECTED; if [ "$stage" = translate ]; then verdict=REFUSE; for p in ${covers//,/ }; do grep -qE "${p//\~/ }" $log || verdict=UNEXPECTED; done; fi ;;
  esac
  [ -f $d/lift_d2h.txt ] && cp $d/lift_d2h.txt $LIFT_OUT/$name.d2h
  [ -f $d/ci_output.txt ] && cp $d/ci_output.txt $LIFT_OUT/$name.out
  if [ -n "${LIFT_BITS_RECORD:-}" ] && [ -f $d/lift_d2h.txt ] && [ "$group" != - ] && [ "$r" = PASS ]; then
    ( flock 9; sed -i "/^$group /d" examples/$ex/lift_bits.txt 2>/dev/null; echo "$group $(cksum < $d/lift_d2h.txt | cut -d' ' -f1)-$(wc -l < $d/lift_d2h.txt)-$(sha1sum < $d/lift_d2h.txt | cut -c1-16)" >> examples/$ex/lift_bits.txt ) 9> $LIFT_OUT/.bits.lock; fi
  printf "%-26s %-14s %-5s %-4s %-6s expect=%-5s %-10s stage=%-14s %4ss\n" $name $ex $sch $hw $input $expect $verdict $stage $((SECONDS-t0))
  echo "$name,$ex,$sch,$hw,$input,$expect,$group,$verdict,$stage,$((SECONDS-t0))" >> $RES
  [ -n "${LIFT_KEEP:-}" ] || rm -rf $d $VORTEX_PATH/tests/regression/cupbop__lit_${name}_s${s}_l1 $VORTEX_PATH_TCU/tests/regression/cupbop__lit_${name}_s${s}_l1
}
run_line() { # the coverage patterns are regular expressions: no globbing
  set -f; local l=$1; l=${l//%RAW/$LIFT_RAW}; l=${l//%BASE/$LIFT_BASE}; l=${l//%ON/$LIFT_ON}; run_row $l; }
export -f run_row run_line
T0=$SECONDS
grep -vE '^\s*(#|$)' $LIFT_CASES | grep -E "^(${1:-.})" | tr -s ' ' | tr '\n' '\0' | xargs -0 -P $PAR -I{} bash -c 'run_line "$1"' _ {}
echo; echo "=== lift tests: $(($(wc -l < $RES)-1)) rows in $((SECONDS-T0)) s, log dir $LIFT_OUT"
python3 -I - "$RES" <<'PY'
import csv, sys, collections
rows = list(csv.DictReader(open(sys.argv[1])))
print(dict(collections.Counter(r['verdict'] for r in rows)))
bad = [r for r in rows if r['verdict'] not in ('PASS', 'XFAIL', 'XHANG', 'REFUSE', 'SKIP')]
for r in bad: print(f"  {r['name']:28s} {r['verdict']} (expected {r['expect']}, stage {r['stage']})")
sys.exit(1 if bad or not rows else 0)
PY
