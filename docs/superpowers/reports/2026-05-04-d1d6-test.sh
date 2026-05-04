#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../checks/d1d6-check.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL test: d1d6-check.sh does not exist"
  exit 1
fi

bash "$SCRIPT"
