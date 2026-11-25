#!/bin/bash
# known_failure.sh <test> <schedule> <localmem>: prints the reason and exits 0 when ci/known_failures.txt lists the run, else exits 1.
# Used by ci/check_correctness.sh and the "Run tests" step of .github/workflows/ci.yml. Run from the repository root.
# Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
F="${KNOWN_FAILURES:-./ci/known_failures.txt}"
[ -f "$F" ] || exit 1
awk -v t="$1" -v s="$2" -v l="$3" '!/^#/ && $1 == t && $2 == s && $3 == l { $1 = $2 = $3 = ""; sub(/^ +/, ""); print; found = 1; exit } END { exit !found }' "$F"
