#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$ROOT"/scripts/*.sh
else
  echo "skip shellcheck (not installed)"
fi

echo "==> luac syntax"
if command -v luac >/dev/null 2>&1; then
  luac -p "$ROOT/vault-strategy/kong/vaults/akeyless/init.lua"
  luac -p "$ROOT/vault-strategy/kong/vaults/akeyless/schema.lua"
else
  echo "skip luac (not installed)"
fi

echo "Lint OK"
