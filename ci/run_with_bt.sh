#!/bin/bash
# Run the host program under gdb (batch) so a host-side crash in CI leaves a backtrace in ci_output.txt;
# falls back to a plain run with core dumps enabled when gdb is not available in the container.
# Use: make ci HOST_PREFIX=$CuPBoP_PATH/ci/run_with_bt.sh   (the golden compare will then FAIL on the extra lines; diagnosis only)
if command -v gdb > /dev/null 2>&1; then
  exec gdb -q -batch -ex "set pagination off" -ex run -ex bt -ex "info registers pc sp" -ex quit --args "$@"
else
  echo "[run_with_bt] gdb not found; running plainly with core dumps enabled"; ulimit -c unlimited; exec "$@"
fi
