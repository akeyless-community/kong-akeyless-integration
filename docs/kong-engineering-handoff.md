# Kong engineering handoff (one-pager)

For Kong Gateway Enterprise engineers reviewing the Akeyless vault backend.

## Integration type

**Native vault strategy** — not a Kong plugin, not Kong Hub. See [Kong Vaults](https://developer.konghq.com/gateway/entities/vault/) for how native vault backends are structured.

## Module layout

```
kong/vaults/akeyless/init.lua    # strategy.get(conf, resource, version)
kong/vaults/akeyless/schema.lua  # Vault entity subschema
```

## Runtime flow

1. Kong parses `{vault://akeyless-vault/<resource>[/<json-key>]}`  
2. Calls `strategy.get(config, resource, version)`  
3. Strategy authenticates via `POST {gateway_url}/auth`  
4. Strategy fetches via `POST {gateway_url}/get-secret-value` with `names: [path]`  
5. Returns string value (or JSON string; Kong extracts `key` if present)

## Path mapping

| `config.path_prefix` | `resource` | Akeyless path |
|----------------------|------------|---------------|
| `/kong` | `demo/api-key` | `/kong/demo/api-key` |
| *(empty)* | `kong/demo/api-key` | `/kong/demo/api-key` |

## Proposed `kong.conf` keys (after bundle)

| kong.conf | Environment variable |
|-----------|----------------------|
| `vault_akeyless_gateway_url` | `KONG_VAULT_AKEYLESS_GATEWAY_URL` |
| `vault_akeyless_auth_method` | `KONG_VAULT_AKEYLESS_AUTH_METHOD` |
| `vault_akeyless_access_id` | `KONG_VAULT_AKEYLESS_ACCESS_ID` |
| `vault_akeyless_access_key` | `KONG_VAULT_AKEYLESS_ACCESS_KEY` |
| `vault_akeyless_path_prefix` | `KONG_VAULT_AKEYLESS_PATH_PREFIX` |
| `vault_akeyless_ttl` | `KONG_VAULT_AKEYLESS_TTL` |
| `vault_akeyless_neg_ttl` | `KONG_VAULT_AKEYLESS_NEG_TTL` |
| `vault_akeyless_resurrect_ttl` | `KONG_VAULT_AKEYLESS_RESSURECT_TTL` |

Add `akeyless = true` to `BUNDLED_VAULTS` in Enterprise constants.

## Auth methods

| `auth_method` | Akeyless `access-type` | Notes |
|---------------|------------------------|-------|
| `api_key` | `api_key` | `access-id` + `access-key` |
| `token` | — | Uses `config.token`, skips `/auth` |
| `kubernetes` | `k8s` | SA JWT from file |
| `aws_iam` | `aws_iam` | EC2 IMDS PKCS7 → `cloud-id` |
| `azure_ad` | `azure_ad` | Azure IMDS token → `cloud-id` |
| `gcp` | `gcp` | GCE/GKE metadata JWT → `cloud-id` |
| `universal_identity` | `universal_identity` | `uid-token` |

## QA

```bash
git clone https://github.com/akeyless-community/kong-akeyless-integration.git
cd kong-akeyless-integration
cp examples/.env.example examples/.env   # fill credentials + KONG_LICENSE_DATA
./scripts/setup-demo-secrets.sh          # optional: create /kong/demo/api-key
make validate
```

Or mount strategy into Kong image:

```yaml
volumes:
  - ./vault-strategy/kong/vaults/akeyless:/usr/local/share/lua/5.1/kong/vaults/akeyless:ro
```

```bash
docker compose -f examples/docker-compose.yml exec kong-gateway \
  kong vault get '{vault://akeyless-vault/demo/api-key}'
```

## Docs deliverables (Kong docs team)

- Supported Vault backends table entry
- How-to: adapt `docs/configure-akeyless-as-vault-backend.md`
- Parameter reference tab on Vault entity page

## Akeyless QA contact

*[Fill in before sending to Kong]*

- Engineering: _______________
- Test tenant Access ID (read-only `/kong/*`): _______________
- Calendar link: _______________
