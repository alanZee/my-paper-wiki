#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

pass() { printf "PASS %s\n" "$1"; }
fail() { printf "FAIL %s\n" "$1"; exit 1; }

for s in wiki-init wiki-ingest wiki-query wiki-audit wiki-lint wiki-survey wiki-update-page; do
  grep -q "$s" "$ROOT/README.md" || fail "D1 missing $s in README"
  grep -q "$s" "$ROOT/SKILL.md" || fail "D1 missing $s in SKILL"
done
pass "D1"

grep -q "draft -> audit(pass) -> stable" "$ROOT/README.md" || fail "D2 missing state machine in README"
grep -q "draft -> audit(pass) -> stable" "$ROOT/SKILL.md" || fail "D2 missing state machine in SKILL"
pass "D2"

grep -q "仅消费 stable" "$ROOT/README.md" || fail "D3 missing stable-only in README"
grep -q "仅消费 stable" "$ROOT/SKILL.md" || fail "D3 missing stable-only in SKILL"
grep -q "仅可消费 stable" "$ROOT/references/audit-rules.md" || fail "D3 missing stable-only in audit-rules"
pass "D3"

grep -q "workspace_root" "$ROOT/README.md" || fail "D4 missing workspace_root in README"
grep -q "不得改写本 skill 源码目录" "$ROOT/SKILL.md" || fail "D4 missing source-dir protection in SKILL"
pass "D4"

grep -q '^source_file: "../../raw/papers/<file>.<ext>"' "$ROOT/references/paper-template.md" || fail "D5 source_file mismatch in paper-template"
pass "D5"

for f in '`level`:' '`skill`:' '`code`:' '`message`:' '`action`:' '`trace_id`:'; do
  grep -q "$f" "$ROOT/SKILL.md" || fail "D6 missing field $f"
done

grep -q 'error|warn|info' "$ROOT/SKILL.md" || fail "D6 missing level enum error|warn|info"
pass "D6"

printf "ALL PASS\n"
