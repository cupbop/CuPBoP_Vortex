#!/bin/bash
#SBATCH -J virt-warp-test
#SBATCH -p rg-nextgen-hpc
#SBATCH -w dash3
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH -t 01:00:00
#SBATCH -o ci/logs_v3/virt_warp_test_%j.out
export CuPBoP_PATH=$SLURM_SUBMIT_DIR
SIF=/projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif
apptainer exec -B /projects/ci-runners,/net/netscratch,/nethome $SIF /bin/bash <<'INNER'
set -u
cd $CuPBoP_PATH && source ./ci/rg-ci-setup-v3.sh
make -C build kernelTranslator hostTranslator vortexRuntime ThreadPool -j8 > ci/logs_v3/virt_warp_test_build_$SLURM_JOB_ID.log 2>&1 || { echo BUILD FAILED; grep -n error ci/logs_v3/virt_warp_test_build_$SLURM_JOB_ID.log | head; exit 1; }
OUT=$CuPBoP_PATH/ci/logs_v3/virt_warp_test_$SLURM_JOB_ID; mkdir -p $OUT
VXH=$VORTEX_HOME
CFG32="$VORTEX_CONFIGS"
CFG16="-DVX_CFG_NUM_CORES=4 -DVX_CFG_NUM_WARPS=16 -DVX_CFG_NUM_THREADS=16 -DVX_CFG_EXT_A_ENABLE -DVX_CFG_EXT_ZACAS_ENABLE -DVX_CFG_L2_ENABLE"
cupbop_v3_ensure_simx $VXH/build64_cupbop_nt16 "$CFG16" || exit 1
run() { # tag sched vortex_path configs nt [env...]
  local tag=$1 sched=$2 vp=$3 cfg=$4 nt=$5; shift 5
  ( cd examples/virt_warp_test && make clean > /dev/null 2>&1; rm -f ci_output.txt
    env VORTEX_PATH=$vp VORTEX_CONFIGS="$cfg" VORTEX_NUM_THREADS=$nt "$@" make ci SCHEDULE=$sched > $OUT/$tag.log 2>&1; cp -f ci_output.txt $OUT/$tag.out 2>/dev/null )
  echo "$tag: $(grep -c '^[0-9]*:' $OUT/$tag.out 2>/dev/null) rows, $(grep -m1 'IWL\] schedule 1' $OUT/$tag.log | cut -c1-90)"
}
run golden_s2_nt32 2 $VORTEX_PATH "$CFG32" 32
run s1_nt32       1 $VORTEX_PATH "$CFG32" 32
run s1_nt32_l16   1 $VORTEX_PATH "$CFG32" 32 CUPBOP_VIRT_LANES=16
run s1_nt32_l16p1 1 $VORTEX_PATH "$CFG32" 32 CUPBOP_VIRT_LANES=16 CUPBOP_VIRT_WARPS=1
run s1_nt16       1 $VXH/build64_cupbop_nt16 "$CFG16" 16
run s1_nt16_p1    1 $VXH/build64_cupbop_nt16 "$CFG16" 16 CUPBOP_VIRT_WARPS=1
cp -f $OUT/golden_s2_nt32.out examples/virt_warp_test/golden_output.txt
python3 - $OUT <<'PY'
import sys,glob,os
d=sys.argv[1]
def load(p):
    rows={}
    for line in open(p):
        if ':' in line and line.split(':')[0].strip().isdigit():
            t,vals=line.split(':',1); rows[int(t)]=[int(x) for x in vals.split()]
    return rows
g=load(d+'/golden_s2_nt32.out')
names=["ballot","any","all","shfl5","down1","up3","xor16","fdown2","redsum","actmask","ballot_am","idx_w16","up1_w8","down8_v","popc_hi","t"]
for f in sorted(glob.glob(d+'/s1_*.out')):
    r=load(f); bad={}
    for t,gv in g.items():
        rv=r.get(t)
        if rv is None: bad.setdefault('missing',[]).append(t); continue
        for i,(a,b) in enumerate(zip(gv,rv)):
            if a!=b: bad.setdefault(names[i],[]).append((t,a,b))
    print(f"== {os.path.basename(f)}: {'PASS' if not bad else 'FAIL'}")
    for k,v in bad.items():
        print(f"   {k}: {len(v)} mismatches, e.g. {v[:4]}")
PY
INNER
