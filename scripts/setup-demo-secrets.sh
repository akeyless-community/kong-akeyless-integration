#!/usr/bin/env bash
# Create or update the demo secret in Akeyless (requires akeyless CLI).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/examples/.env}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

: "${AKEYLESS_DEMO_SECRET_PATH:?Set AKEYLESS_DEMO_SECRET_PATH}"
: "${AKEYLESS_DEMO_SECRET_VALUE:?Set AKEYLESS_DEMO_SECRET_VALUE}"

if ! command -v akeyless >/dev/null 2>&1; then
  echo "Install the Akeyless CLI: https://docs.akeyless.io/docs/cli" >&2
  exit 1
fi

echo "==> Creating static secret $AKEYLESS_DEMO_SECRET_PATH"
akeyless create-secret \
  --name "$AKEYLESS_DEMO_SECRET_PATH" \
  --value "$AKEYLESS_DEMO_SECRET_VALUE" \
  --type static

echo "OK: demo secret ready for vault reference {vault://akeyless-vault/demo/api-key}"
