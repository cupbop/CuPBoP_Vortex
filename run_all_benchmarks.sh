#!/bin/bash
# Run all 13 CI benchmarks and collect pass/fail status
# Usage: bash run_all_benchmarks.sh [scheduler_flag]
# Default scheduler flag: 2

SCHED_FLAG=${1:-2}
CUPBOP_DIR=/nethome/hkim358/project/CuPBoP_Vortex
LOG_DIR=${CUPBOP_DIR}/benchmark_results_flag${SCHED_FLAG}
mkdir -p ${LOG_DIR}

BENCHMARKS="backprop dotproduct pathfinder psum bfs btree conv3 nn saxpy sgemm stencil transpose vecadd"

run_benchmark() {
    local bench=$1
    local logfile="${LOG_DIR}/${bench}.log"
    echo "[$(date '+%H:%M:%S')] Starting: $bench" | tee -a ${LOG_DIR}/summary.log

    apptainer exec \
        --nv \
        -B /projects/ci-runners/CuPBoP-Vortex/:/projects/ci-runners/CuPBoP-Vortex/ \
        /projects/ci-runners/CuPBoP-Vortex/tools/cupbop_env.sif \
        /bin/bash -c "
            set -e
            cd ${CUPBOP_DIR}
            source ./ci/rg-ci-setup.sh 2>/dev/null
            export VORTEX_SCHEDULE_FLAG=${SCHED_FLAG}
            cd ${CUPBOP_DIR}/examples/${bench}
            bash kjrun_llvm18.sh
            exit 0
        " > "${logfile}" 2>&1
    local exit_code=$?

    # Check for success markers in last 20 lines
    local last_lines=$(tail -n 20 "${logfile}" 2>/dev/null)
    local kernel_ok=$(echo "$last_lines" | grep -c "Kernel compilation completed!" || true)
    local host_ok=$(echo "$last_lines" | grep -c "Host compilation completed!" || true)
    local exec_ok=$(echo "$last_lines" | grep -c "Execution completed!" || true)

    if [ "$kernel_ok" -ge 1 ] && [ "$host_ok" -ge 1 ] && [ "$exec_ok" -ge 1 ]; then
        echo "[$(date '+%H:%M:%S')] PASS: $bench" | tee -a ${LOG_DIR}/summary.log
    else
        # Find where it failed
        if [ "$kernel_ok" -lt 1 ]; then
            local fail_stage="kernel_compile"
        elif [ "$host_ok" -lt 1 ]; then
            local fail_stage="host_compile"
        else
            local fail_stage="execution"
        fi
        echo "[$(date '+%H:%M:%S')] FAIL: $bench (stage: $fail_stage, exit: $exit_code)" | tee -a ${LOG_DIR}/summary.log
        echo "  Last 5 lines:" >> ${LOG_DIR}/summary.log
        tail -n 5 "${logfile}" >> ${LOG_DIR}/summary.log
    fi
}

export -f run_benchmark
export LOG_DIR SCHED_FLAG

echo "=== Running all 13 benchmarks with VORTEX_SCHEDULE_FLAG=${SCHED_FLAG} ===" | tee ${LOG_DIR}/summary.log
echo "Start time: $(date)" | tee -a ${LOG_DIR}/summary.log
echo "" | tee -a ${LOG_DIR}/summary.log

# kernelTranslator now writes kernel_wrapper.cpp to each benchmark's own directory.
# Benchmarks can be run sequentially or in parallel (no more shared file race condition).
echo "Running benchmarks sequentially..."
for bench in $BENCHMARKS; do
    run_benchmark "$bench"
done

echo "" | tee -a ${LOG_DIR}/summary.log
echo "=== Final Results ===" | tee -a ${LOG_DIR}/summary.log
echo "End time: $(date)" | tee -a ${LOG_DIR}/summary.log
grep -E "PASS:|FAIL:" ${LOG_DIR}/summary.log | sort

echo ""
echo "Logs saved to: ${LOG_DIR}/"
echo "Summary: ${LOG_DIR}/summary.log"
