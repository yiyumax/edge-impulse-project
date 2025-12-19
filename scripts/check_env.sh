#!/bin/bash
set -e

echo "=== 環境檢查 ==="
echo

FAIL=0

check_cmd () {
  if command -v "$1" >/dev/null 2>&1; then
    echo "✓ $1"
  else
    echo "✗ $1 (not found)"
    FAIL=1
  fi
}

echo "檢查必要指令..."
check_cmd python3
check_cmd curl
check_cmd git
check_cmd jq
check_cmd node
check_cmd edge-impulse-linux-runner

echo
echo "檢查環境變數..."

if [ -n "$EI_API_KEY" ]; then
  echo "✓ EI_API_KEY = ${EI_API_KEY:0:10}..."
else
  echo "✗ EI_API_KEY not set"
  FAIL=1
fi

if [ -n "$PROJECT_ID" ]; then
  echo "✓ PROJECT_ID = $PROJECT_ID"
else
  echo "✗ PROJECT_ID not set"
  FAIL=1
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "所有環境檢查通過"
  exit 0
else
  echo "環境檢查失敗，請依照提示修正"
  exit 1
fi
