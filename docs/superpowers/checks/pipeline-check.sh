#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

pass() { printf "PASS %s\n" "$1"; }
fail() { printf "FAIL %s\n" "$1"; exit 1; }

: "${WORKSPACE_ROOT:?WORKSPACE_ROOT not set}"
: "${SOURCE_PATH:?SOURCE_PATH not set}"

if [ -z "$WORKSPACE_ROOT" ] || [ -z "$SOURCE_PATH" ]; then
  fail "missing WORKSPACE_ROOT or SOURCE_PATH"
fi

if [ "$WORKSPACE_ROOT" = "$ROOT" ] || [ "$WORKSPACE_ROOT" = "$ROOT/" ]; then
  fail "WORKSPACE_ROOT points to skill root"
fi

if [ ! -f "$SOURCE_PATH" ]; then
  fail "SOURCE_PATH not found"
fi

pass "ENV"

mkdir -p "$WORKSPACE_ROOT/raw/papers"
mkdir -p "$WORKSPACE_ROOT/wiki/papers/_pending"
mkdir -p "$WORKSPACE_ROOT/wiki/topics"
mkdir -p "$WORKSPACE_ROOT/wiki/surveys"
mkdir -p "$WORKSPACE_ROOT/outputs/survey"

[ -f "$WORKSPACE_ROOT/refs.bib" ] || : > "$WORKSPACE_ROOT/refs.bib"
[ -f "$WORKSPACE_ROOT/wiki/index.md" ] || : > "$WORKSPACE_ROOT/wiki/index.md"
[ -f "$WORKSPACE_ROOT/wiki/log.md" ] || : > "$WORKSPACE_ROOT/wiki/log.md"
[ -f "$WORKSPACE_ROOT/outputs/citations.jsonl" ] || : > "$WORKSPACE_ROOT/outputs/citations.jsonl"

pass "INIT"

BASE_NAME="$(basename "$SOURCE_PATH")"
EXT="${BASE_NAME##*.}"
if [ "$EXT" != "pdf" ] && [ "$EXT" != "tex" ]; then
  fail "unsupported source extension"
fi

STAMP="${FIXED_DATE:-$(date +%Y%m%d)}"
HASH="$(sha256sum "$SOURCE_PATH" | awk '{print $1}')"
PDF_HASH8="${HASH:0:8}"
PROVISIONAL="pending-${STAMP}-${PDF_HASH8}"

cp -n "$SOURCE_PATH" "$WORKSPACE_ROOT/raw/papers/$BASE_NAME" || true

PENDING_PAGE="$WORKSPACE_ROOT/wiki/papers/_pending/${PROVISIONAL}.md"
if [ ! -f "$PENDING_PAGE" ]; then
  cat <<EOF > "$PENDING_PAGE"
---
type: paper
title: ""
bibkey: ""
year: 2026
status: draft
source_file: "../../raw/papers/$BASE_NAME"
source_text: "../../raw/papers/${BASE_NAME%.*}.md"
updated: $(date +%Y-%m-%d)
tags: []
---

## Problem

## Method

## Key Results

## Assumptions & Limits

## Repro Notes

## Citations

## Links
EOF
fi

if ! grep -q "$PROVISIONAL" "$WORKSPACE_ROOT/wiki/index.md"; then
  printf -- "- papers/_pending/%s.md\n" "$PROVISIONAL" >> "$WORKSPACE_ROOT/wiki/index.md"
fi

printf "## [%s] wiki-ingest | ingest_raw %s\n" "$(date +%Y-%m-%d)" "$PROVISIONAL" >> "$WORKSPACE_ROOT/wiki/log.md"

pass "INGEST_RAW"

TITLE_STEM="${BASE_NAME%.*}"
TITLE_CLEAN="$(printf "%s" "$TITLE_STEM" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9' | cut -c1-12)"
if [ -z "$TITLE_CLEAN" ]; then
  TITLE_CLEAN="paper"
fi
FINAL_BIBKEY="smith2026${TITLE_CLEAN}"

FINAL_PAGE="$WORKSPACE_ROOT/wiki/papers/${FINAL_BIBKEY}.md"
if [ ! -f "$FINAL_PAGE" ]; then
  cat <<EOF > "$FINAL_PAGE"
---
type: paper
title: "${TITLE_STEM}"
bibkey: "${FINAL_BIBKEY}"
year: 2026
status: draft
source_file: "../../raw/papers/$BASE_NAME"
source_text: "../../raw/papers/${BASE_NAME%.*}.md"
updated: $(date +%Y-%m-%d)
tags: []
---

## Problem

## Method

## Key Results

## Assumptions & Limits

## Repro Notes

## Citations

- [@${FINAL_BIBKEY}]

## Links
EOF
fi

if ! grep -q "$FINAL_BIBKEY" "$WORKSPACE_ROOT/refs.bib"; then
  cat <<EOF >> "$WORKSPACE_ROOT/refs.bib"
@article{${FINAL_BIBKEY},
  title = {${TITLE_STEM}},
  author = {Smith, Placeholder},
  year = {2026},
  journal = {Placeholder Journal}
}
EOF
fi

if ! grep -q "papers/${FINAL_BIBKEY}.md" "$WORKSPACE_ROOT/wiki/index.md"; then
  printf -- "- papers/%s.md\n" "$FINAL_BIBKEY" >> "$WORKSPACE_ROOT/wiki/index.md"
fi

printf "## [%s] wiki-ingest | ingest_finalize %s -> %s\n" "$(date +%Y-%m-%d)" "$PROVISIONAL" "$FINAL_BIBKEY" >> "$WORKSPACE_ROOT/wiki/log.md"

pass "INGEST_FINALIZE"

python - <<PY
import pathlib
page = pathlib.Path("$WORKSPACE_ROOT/wiki/papers/$FINAL_BIBKEY.md")
text = page.read_text(encoding="utf-8")
if "status: stable" not in text:
    page.write_text(text.replace("status: draft", "status: stable", 1), encoding="utf-8")
PY

printf "## [%s] wiki-audit | pass %s\n" "$(date +%Y-%m-%d)" "$FINAL_BIBKEY" >> "$WORKSPACE_ROOT/wiki/log.md"

pass "AUDIT"

SURVEY_SLUG="pipeline-smoke"
SURVEY_PAGE="$WORKSPACE_ROOT/wiki/surveys/${SURVEY_SLUG}.md"
if [ ! -f "$SURVEY_PAGE" ]; then
  cat <<EOF > "$SURVEY_PAGE"
---
type: survey
title: "Pipeline Smoke"
status: draft
updated: $(date +%Y-%m-%d)
source_papers:
  - ../papers/${FINAL_BIBKEY}.md
target_output: "../../outputs/survey/${SURVEY_SLUG}.tex"
---

## Summary

- [@${FINAL_BIBKEY}]
EOF
fi

TEX_OUT="$WORKSPACE_ROOT/outputs/survey/${SURVEY_SLUG}.tex"
if [ ! -f "$TEX_OUT" ]; then
  cat <<EOF > "$TEX_OUT"
% auto-generated
\section*{Pipeline Smoke}
This survey cites \cite{${FINAL_BIBKEY}}.
EOF
fi

printf "## [%s] wiki-survey | ${SURVEY_SLUG}\n" "$(date +%Y-%m-%d)" >> "$WORKSPACE_ROOT/wiki/log.md"

TS="$(date -Iseconds)"
printf '{"timestamp":"%s","source_page":"wiki/surveys/%s.md","bibkeys":["%s"],"claim_span":"pipeline smoke test","trace_id":"trace-%s"}\n' "$TS" "$SURVEY_SLUG" "$FINAL_BIBKEY" "${PDF_HASH8}" >> "$WORKSPACE_ROOT/outputs/citations.jsonl"

pass "SURVEY"

printf "ALL PASS\n"
