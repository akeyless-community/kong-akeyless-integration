#!/usr/bin/env bash
# Authenticate to Akeyless and fetch a demo secret (no Kong required).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/examples/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${AKEYLESS_GATEWAY_URL:?Set AKEYLESS_GATEWAY_URL in examples/.env}"
: "${AKEYLESS_ACCESS_ID:?Set AKEYLESS_ACCESS_ID in examples/.env}"
: "${AKEYLESS_ACCESS_KEY:?Set AKEYLESS_ACCESS_KEY in examples/.env}"
: "${AKEYLESS_DEMO_SECRET_PATH:?Set AKEYLESS_DEMO_SECRET_PATH in examples/.env}"

GATEWAY="${AKEYLESS_GATEWAY_URL%/}"
SECRET_PATH="${AKEYLESS_DEMO_SECRET_PATH}"
if [[ "$SECRET_PATH" != /* ]]; then
  SECRET_PATH="/$SECRET_PATH"
fi

http_post() {
  local url="$1"
  local body="$2"
  local tmp
  tmp="$(mktemp)"
  local http_code
  http_code="$(curl -sS -o "$tmp" -w '%{http_code}' "$url" \
    -H 'Content-Type: application/json' \
    -d "$body")"
  if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
    echo "ERROR: HTTP $http_code from $url" >&2
    if [[ -s "$tmp" ]]; then
      echo "Response:" >&2
      cat "$tmp" >&2
    fi
    rm -f "$tmp"
    return 1
  fi
  cat "$tmp"
  rm -f "$tmp"
}

echo "==> Authenticating to Akeyless at $GATEWAY"
AUTH_BODY="$(python3 -c 'import json,os; print(json.dumps({"access-id":os.environ["AKEYLESS_ACCESS_ID"],"access-type":"api_key","access-key":os.environ["AKEYLESS_ACCESS_KEY"]}))' \
  AKEYLESS_ACCESS_ID="$AKEYLESS_ACCESS_ID" AKEYLESS_ACCESS_KEY="$AKEYLESS_ACCESS_KEY")"
AUTH_RESP="$(http_post "$GATEWAY/auth" "$AUTH_BODY")" || {
  echo "" >&2
  echo "Auth failed. Check AKEYLESS_ACCESS_ID and AKEYLESS_ACCESS_KEY in examples/.env" >&2
  echo "Common mistake: putting Access ID (p-...) in the Access Key field." >&2
  exit 1
}

TOKEN="$(printf '%s' "$AUTH_RESP" | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')"

echo "==> Fetching secret $SECRET_PATH"
SECRET_BODY="$(python3 -c 'import json,os; print(json.dumps({"token":os.environ["TOKEN"],"names":[os.environ["SECRET_PATH"]]}))' \
  TOKEN="$TOKEN" SECRET_PATH="$SECRET_PATH")"
SECRET_RESP="$(http_post "$GATEWAY/get-secret-value" "$SECRET_BODY")" || {
  echo "" >&2
  echo "Secret fetch failed for: $SECRET_PATH" >&2
  echo "" >&2
  echo "Fix options:" >&2
  echo "  1. Create the secret in Akeyless (console or: ./scripts/setup-demo-secrets.sh)" >&2
  echo "  2. Set AKEYLESS_DEMO_SECRET_PATH in examples/.env to a path that exists" >&2
  echo "  3. Ensure your Access ID can read that path" >&2
  echo "" >&2
  echo "To list items under a folder:" >&2
  echo "  akeyless list-items --path /demo" >&2
  exit 1
}

VALUE="$(printf '%s' "$SECRET_RESP" | python3 -c "
import json, sys, os
path = os.environ['SECRET_PATH']
data = json.load(sys.stdin)
val = data.get(path) or data.get(path.lstrip('/'))
if val is None and data:
    val = next(iter(data.values()))
if val is None:
    sys.exit('secret key missing in response')
if isinstance(val, dict) and 'value' in val:
    val = val['value']
print(val)
" SECRET_PATH="$SECRET_PATH")"

if [[ -z "$VALUE" ]]; then
  echo "ERROR: empty secret value for $SECRET_PATH" >&2
  exit 1
fi

echo "OK: secret resolved (${#VALUE} bytes)"
