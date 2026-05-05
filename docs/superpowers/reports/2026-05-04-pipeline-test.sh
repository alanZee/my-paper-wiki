#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY="$SCRIPT_DIR/../checks/pipeline-verify.py"

pass() { printf "PASS %s\n" "$1"; }
fail() { printf "FAIL %s\n" "$1"; exit 1; }

if [ ! -f "$VERIFY" ]; then
  fail "pipeline-verify.py does not exist"
fi

: "${WORKSPACE_ROOT:?WORKSPACE_ROOT not set}"

if [ ! -d "$WORKSPACE_ROOT/wiki" ]; then
  fail "wiki directory missing - workspace not initialized"
fi

python "$VERIFY" "$WORKSPACE_ROOT"

pass "PIPELINE"
printf "ALL PASS\n"
