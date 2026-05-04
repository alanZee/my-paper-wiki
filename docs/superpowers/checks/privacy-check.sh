#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

pass() { printf "PASS %s\n" "$1"; }
fail() { printf "FAIL %s\n" "$1"; exit 1; }

# 仅检查对外发布核心资产，避免历史执行报告影响发布
TARGETS=(
  "$ROOT/README.md"
  "$ROOT/SKILL.md"
  "$ROOT/references"
  "$ROOT/assets"
)

if grep -R -n -E 'X:/0Agents-workspace|X:\\0Agents-workspace|C:/Users|C:\\Users' "${TARGETS[@]}" >/dev/null 2>&1; then
  fail "P1 personal path or user info detected"
fi

pass "P1"
printf "ALL PASS\n"
