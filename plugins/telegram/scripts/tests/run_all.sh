#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

overall=0
for t in "$SCRIPT_DIR"/test_*.sh; do
  echo "=== Running $(basename "$t") ==="
  bash "$t"
  status=$?
  if [ "$status" -ne 0 ]; then
    overall=1
    echo "=== FAILED: $(basename "$t") ==="
  fi
done
exit $overall
