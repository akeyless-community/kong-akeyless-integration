#!/usr/bin/env bash
# End-to-end validation: Akeyless API + Kong vault reference (requires running demo stack).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/examples/.env}"
COMPOSE_FILE="$ROOT/examples/docker-compose.yml"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

echo "==> Step 1: Akeyless API smoke test"
"$ROOT/scripts/test-akeyless-api.sh"

if ! docker compose -f "$COMPOSE_FILE" ps --status running 2>/dev/null | grep -q kong-gateway; then
  echo "==> Kong gateway not running — start with: docker compose -f examples/docker-compose.yml up -d"
  echo "    Skipping Kong vault get test."
  exit 0
fi

PREFIX="${AKEYLESS_VAULT_PREFIX:-akeyless-vault}"
RESOURCE="${AKEYLESS_VAULT_RESOURCE:-demo/api-key}"
REFERENCE="{vault://${PREFIX}/${RESOURCE}}"

echo "==> Step 2: Apply Vault entity with decK (if deck is installed)"
if command -v deck >/dev/null 2>&1; then
  export DECK_AKEYLESS_GATEWAY_URL="${AKEYLESS_GATEWAY_URL}"
  export DECK_AKEYLESS_ACCESS_ID="${AKEYLESS_ACCESS_ID}"
  export DECK_AKEYLESS_ACCESS_KEY="${AKEYLESS_ACCESS_KEY}"
  deck gateway apply "$ROOT/examples/kong.yaml" 2>/dev/null || true
else
  echo "    deck not installed — create the Vault entity manually via Admin API"
fi

echo "==> Step 3: kong vault get $REFERENCE"
docker compose -f "$COMPOSE_FILE" exec -T kong-gateway \
  kong vault get "$REFERENCE"

echo "OK: Kong resolved the Akeyless vault reference"
