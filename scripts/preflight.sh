#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/examples/.env"
REQUIRED_MISSING=0

check_required() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "OK  $1"
  else
    echo "MISS $1 (required)"
    REQUIRED_MISSING=1
  fi
}

check_optional() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "OK  $1"
  else
    echo "skip $1 (optional)"
  fi
}

echo "==> Required for API smoke test"
check_required curl
check_required python3

echo "==> Optional for full demo"
check_optional docker
check_optional deck
check_optional akeyless
check_optional shellcheck
check_optional luac

if [[ -f "$ENV_FILE" ]]; then
  echo "OK  examples/.env"
else
  echo "MISS examples/.env (copy from examples/.env.example)"
  REQUIRED_MISSING=1
fi

if [[ "$REQUIRED_MISSING" -eq 0 ]]; then
  echo "Preflight passed."
else
  echo "Preflight failed — fix required items above."
  exit 1
fi
