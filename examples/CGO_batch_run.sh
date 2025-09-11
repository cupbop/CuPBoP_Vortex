#!/usr/bin/env bash
set -uo pipefail

############################
# 설정
############################

# 1) 실행할 벤치마크 폴더들 (순서대로 20초 간격으로 시작, 병렬 동작)
benchmarks=(
  bfs
  backprop
  btree
  conv3
  dotproduct
  gauss
  nn
  pathfinder
  psort
  transpose
  stencil
  sgemm
  saxpy
  vecadd
  psum
)


# 2) 각 벤치마크 실행 전 적용할 환경 설정 명령들 (여러 개 OK, 순서대로 실행)
env_cmds=(
  "source ~/set_env_CuPBoP_Vortex_2.0_cuda_12.1_with_new_pocl.sh"
  "source ~/set_env_CuPBoP_Vortex_2.0_cuda_12.1_with_new_pocl.sh"
  "export VORTEX_SCHEDULE_FLAG=2"
  # 필요하면 아래처럼 추가
  # "module load gcc/13.2"
  # "export OMP_NUM_THREADS=32"
)

# 3) 실행할 스크립트 이름
runner="./kjrun_llvm18.sh"

# 4) 결과 파일명 및 리네임 규칙
out_name="CGO_perf_counter_4C_16W_32T_SCHE_2.txt"
renamed_suffix="_test4"
renamed_name="${out_name/.txt/${renamed_suffix}.txt}"

# 5) 로그 디렉토리
logdir="logs"
mkdir -p "$logdir"

############################
# 함수
############################

sanitize() {
  local s="$1"
  s="${s//\//_}"
  s="${s//+/_}"
  s="${s// /_}"
  printf "%s" "$s"
}

run_one() {
  local d="$1"
  local tag
  tag="$(sanitize "$d")"
  local log="$logdir/${tag}.log"

  {
    echo "[$(date +'%F %T')] >>> start $d"

    if [[ ! -d "$d" ]]; then
      echo "폴더 없음: $d"
      echo "[$(date +'%F %T')] <<< done $d (missing dir)"
      return 1
    fi

    pushd "$d" >/dev/null || { echo "cd 실패: $d"; return 2; }

    # 환경 설정 적용
    for cmd in "${env_cmds[@]}"; do
      echo "ENV: $cmd"
      # shellcheck disable=SC1090,SC1091
      eval "$cmd"
    done

    # 실행
    if [[ ! -x "$runner" ]]; then
      echo "실행 스크립트 없음/실행권한 없음: $runner"
      popd >/dev/null
      echo "[$(date +'%F %T')] <<< done $d (runner missing)"
      return 3
    fi

    echo "RUN: $runner"
    "$runner"
    rc=$?
    echo "RUN RC=$rc"

    # 결과 파일이 이미 생겼으면 그것도 성공 신호로 본다
    local produced=0
    if [[ -f "$out_name" ]] || [[ -f "$renamed_name" ]]; then
      produced=1
    fi

    # 결과 파일 리네임(있으면)
    if [[ -f "$out_name" ]]; then
      mv -f "$out_name" "$renamed_name"
      echo "RENAMED: $out_name -> $renamed_name"
      produced=1
    else
      echo "결과 파일 없음: $out_name"
    fi

    # kjrun_llvm18.sh 가 exit -1(=255)로 끝나는 관례를 성공으로 치환
    if [[ $rc -ne 0 ]]; then
      if [[ $rc -eq 255 ]]; then
        echo "NOTE: runner uses 'exit -1' by design; treating as SUCCESS"
        rc=0
      elif [[ $produced -eq 1 ]]; then
        echo "NOTE: non-zero RC but result file exists; treating as SUCCESS"
        rc=0
      fi
    fi

    popd >/dev/null
    echo "[$(date +'%F %T')] <<< done $d (rc=$rc)"
    return $rc
  } | tee "$log"
}

############################
# 메인: 병렬 실행 + 20초 간격 스타트
############################

pids=()
names=()

for d in "${benchmarks[@]}"; do
  (
    echo "[$(date +'%F %T')] schedule $d (will start after stagger)"
    run_one "$d"
  ) &
  pids+=($!)
  names+=("$d")

  # 다음 벤치마크 시작까지 20초 대기 (백그라운드로 이미 실행 중)
  sleep 20
done

# 모든 작업 대기 & 요약
fail=0
echo
echo "=== WAITING JOBS ==="
for i in "${!pids[@]}"; do
  pid=${pids[$i]}
  name=${names[$i]}
  if wait "$pid"; then
    echo "[OK]  $name"
  else
    echo "[ERR] $name"
    fail=$((fail+1))
  fi
done

echo "=== DONE: ${#pids[@]} jobs, fail=$fail ==="

# 작업이 끝난 후 이메일 전송
python completed_email.py
exit $fail