#!/usr/bin/env bash
# End-to-end validation: Akeyless API + Kong vault reference (requires running demo stack).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/examples/.env}"
COMPOSE_FILE="$ROOT/examples/docker-compose.yml"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

# Derive Kong vault resource from Akeyless path + optional path_prefix
derive_vault_resource() {
  local secret_path="${AKEYLESS_DEMO_SECRET_PATH:-/kong/demo/api-key}"
  local prefix="${AKEYLESS_PATH_PREFIX:-/kong}"

  if [[ "$secret_path" != /* ]]; then
    secret_path="/$secret_path"
  fi
  if [[ "$prefix" != /* ]]; then
    prefix="/$prefix"
  fi
  prefix="${prefix%/}"

  if [[ -n "$prefix" && "$secret_path" == "$prefix"/* ]]; then
    echo "${secret_path#"$prefix"/}"
  else
    echo "${secret_path#/}"
  fi
}

echo "==> Step 1: Akeyless API smoke test (Kong license not required)"
"$ROOT/scripts/test-akeyless-api.sh"

if [[ -z "${KONG_LICENSE_DATA:-}" ]]; then
  echo ""
  echo "==> KONG_LICENSE_DATA is not set — skipping Kong steps"
  echo "    Step 1 passed: Akeyless API works with your credentials."
  echo ""
  echo "    To test Kong vault references:"
  echo "      1. Add KONG_LICENSE_DATA to examples/.env (see comments in .env.example)"
  echo "      2. docker compose -f examples/docker-compose.yml up -d"
  echo "      3. make validate"
  exit 0
fi

if ! docker compose -f "$COMPOSE_FILE" ps --status running 2>/dev/null | grep -q kong-gateway; then
  echo ""
  echo "==> Kong gateway not running"
  echo "    Start with: docker compose -f examples/docker-compose.yml up -d"
  echo "    (requires KONG_LICENSE_DATA in examples/.env or your shell)"
  exit 0
fi

PREFIX="${AKEYLESS_VAULT_PREFIX:-akeyless-vault}"
RESOURCE="${AKEYLESS_VAULT_RESOURCE:-$(derive_vault_resource)}"
REFERENCE="{vault://${PREFIX}/${RESOURCE}}"

echo "==> Step 2: Apply Vault entity with decK (if deck is installed)"
if command -v deck >/dev/null 2>&1; then
  set -a
  # shellcheck disable=SC1090
  [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
  set +a
  deck gateway apply "$ROOT/examples/kong.yaml" 2>/dev/null || true
else
  echo "    deck not installed — create the Vault entity manually via Admin API"
fi

echo "==> Step 3: kong vault get $REFERENCE"
echo "    (maps to Akeyless path: ${AKEYLESS_DEMO_SECRET_PATH})"
docker compose -f "$COMPOSE_FILE" exec -T kong-gateway \
  kong vault get "$REFERENCE"

echo "OK: Kong resolved the Akeyless vault reference"
