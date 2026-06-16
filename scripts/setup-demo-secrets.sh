#!/usr/bin/env bash
# Create or update the demo static secret in Akeyless (requires akeyless CLI).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/examples/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${AKEYLESS_DEMO_SECRET_PATH:?Set AKEYLESS_DEMO_SECRET_PATH in examples/.env}"
: "${AKEYLESS_DEMO_SECRET_VALUE:?Set AKEYLESS_DEMO_SECRET_VALUE in examples/.env}"

if ! command -v akeyless >/dev/null 2>&1; then
  echo "Install the Akeyless CLI: https://docs.akeyless.io/docs/cli" >&2
  exit 1
fi

NAME="$AKEYLESS_DEMO_SECRET_PATH"
VALUE="$AKEYLESS_DEMO_SECRET_VALUE"

echo "==> Creating static secret $NAME"
set +e
CREATE_OUT="$(akeyless create-secret --name "$NAME" --value "$VALUE" 2>&1)"
CREATE_RC=$?
set -e

if [[ "$CREATE_RC" -eq 0 ]]; then
  echo "OK: created $NAME"
elif echo "$CREATE_OUT" | grep -qiE 'already exist|duplicate|conflict'; then
  echo "    Secret already exists — updating value"
  akeyless update-secret-val --name "$NAME" --value "$VALUE"
  echo "OK: updated $NAME"
else
  echo "$CREATE_OUT" >&2
  echo "" >&2
  echo "Failed to create $NAME" >&2
  echo "Note: akeyless create-secret is for static secrets (type generic/password)." >&2
  echo "      Do not pass --type static (invalid). If the path exists as another item type, pick a different path." >&2
  exit 1
fi

echo "    Run: make test-api"
