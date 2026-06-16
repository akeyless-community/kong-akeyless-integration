#!/usr/bin/env bash
# Authenticate to Akeyless and fetch a demo secret (no Kong required).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/examples/.env}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

: "${AKEYLESS_GATEWAY_URL:?Set AKEYLESS_GATEWAY_URL}"
: "${AKEYLESS_ACCESS_ID:?Set AKEYLESS_ACCESS_ID}"
: "${AKEYLESS_ACCESS_KEY:?Set AKEYLESS_ACCESS_KEY}"
: "${AKEYLESS_DEMO_SECRET_PATH:?Set AKEYLESS_DEMO_SECRET_PATH}"

GATEWAY="${AKEYLESS_GATEWAY_URL%/}"

echo "==> Authenticating to Akeyless at $GATEWAY"
TOKEN="$(curl -fsS "$GATEWAY/auth" \
  -H 'Content-Type: application/json' \
  -d "{\"access-id\":\"$AKEYLESS_ACCESS_ID\",\"access-type\":\"api_key\",\"access-key\":\"$AKEYLESS_ACCESS_KEY\"}" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')"

echo "==> Fetching secret $AKEYLESS_DEMO_SECRET_PATH"
VALUE="$(curl -fsS "$GATEWAY/get-secret-value" \
  -H 'Content-Type: application/json' \
  -d "{\"token\":\"$TOKEN\",\"names\":[\"$AKEYLESS_DEMO_SECRET_PATH\"]}" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$AKEYLESS_DEMO_SECRET_PATH') or next(iter(d.values())))")"

if [[ -z "$VALUE" ]]; then
  echo "ERROR: empty secret value" >&2
  exit 1
fi

echo "OK: secret resolved (${#VALUE} bytes)"
