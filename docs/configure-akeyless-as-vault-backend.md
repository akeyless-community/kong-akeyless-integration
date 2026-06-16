# Configure Akeyless as a Kong Gateway vault backend

> **Status:** Reference documentation for the [kong-akeyless-integration](https://github.com/akeyless-community/kong-akeyless-integration) vault strategy. After Kong bundles the backend, this page will appear on [developer.konghq.com](https://developer.konghq.com/gateway/entities/vault/#supported-vault-backends) alongside HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, and CyberArk Conjur.

## TL;DR

Configure a Kong Gateway Vault entity with `name: akeyless`, your Akeyless gateway URL (`config.gateway_url`), Access ID and Access Key (`config.access_id`, `config.access_key`), and an optional path prefix (`config.path_prefix`). Reference secrets like `{vault://akeyless-vault/customer/acme/api-key}` when `akeyless-vault` is your Vault prefix and the secret is stored at `/kong/customer/acme/api-key` with `path_prefix: /kong`.

## Prerequisites

### Kong Gateway Enterprise

Secrets Management vault backends (other than environment variables) require **Kong Gateway Enterprise**. Use the [Kong quickstart](https://developer.konghq.com/gateway/install/) with an enterprise license:

```bash
export KONG_LICENSE_DATA='LICENSE-CONTENTS-GO-HERE'
curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA
```

### Akeyless vault strategy

Install the Akeyless vault strategy into Kong Gateway until it is bundled natively:

```bash
luarocks install kong-vault-akeyless-0.1.0-1.rockspec
```

Or mount the strategy files from this repository into the Kong `lua_package_path`.

### decK v1.62.1+

```bash
deck version
```

### Akeyless account

1. Create an [Akeyless](https://www.akeyless.io) account.
2. Create an Access ID + Access Key auth method scoped to your Kong secret paths.
3. Store a demo secret, for example `/kong/demo/api-key`.

Set credentials in `examples/.env` (or export the same `AKEYLESS_*` variables in your shell before running decK).

## Create a Vault entity for Akeyless

Using decK:

```yaml
_format_version: "3.0"
vaults:
  - name: akeyless
    description: Storing secrets in Akeyless Secrets Manager
    prefix: akeyless-vault
    config:
      gateway_url: "${{ env "AKEYLESS_GATEWAY_URL" }}"
      auth_method: api_key
      access_id: "${{ env "AKEYLESS_ACCESS_ID" }}"
      access_key: "${{ env "AKEYLESS_ACCESS_KEY" }}"
      path_prefix: "/kong"
      ttl: 60
```

```bash
deck gateway apply kong.yaml
```

## Validate

```bash
docker exec kong-quickstart-gateway kong vault get '{vault://akeyless-vault/demo/api-key}'
```

If configured correctly, Kong returns the secret value. Use `{vault://akeyless-vault/demo/api-key}` in any [referenceable field](https://developer.konghq.com/gateway/entities/vault/).

### JSON secrets

Store a JSON object in Akeyless:

```json
{"username":"john","password":"doe"}
```

at path `/kong/pg`. Reference individual keys:

- `{vault://akeyless-vault/pg/username}` → `john`
- `{vault://akeyless-vault/pg/password}` → `doe`

## Authentication methods

| `config.auth_method` | Required fields | Use case |
|----------------------|-----------------|----------|
| `api_key` (default) | `access_id`, `access_key` | Most deployments |
| `token` | `token` | Pre-authenticated token |
| `kubernetes` | `access_id`, `k8s_auth_config_name` | Kong on Kubernetes |
| `aws_iam` | `access_id` | Kong on AWS EC2/EKS |
| `azure_ad` | `access_id` | Kong on Azure VM |
| `gcp` | `access_id` | Kong on GKE/GCE |
| `universal_identity` | `uid_token` | Universal Identity workloads |

## Secret layout in Akeyless

Organize Kong secrets under a dedicated prefix:

```
/kong/<environment>/<service>/<secret-name>
/kong/production/payments/stripe-key
/kong/production/database/credentials   # JSON with username/password keys
```

| Kong reference | `path_prefix` | Akeyless path |
|----------------|---------------|---------------|
| `{vault://akeyless-vault/production/payments/stripe-key}` | `/kong` | `/kong/production/payments/stripe-key` |
| `{vault://akeyless-vault/pg/password}` | `/kong` | `/kong/pg` (JSON key `password`) |

## Configuration parameters

When bundled by Kong, these parameters will be available via Vault entity, `kong.conf`, and environment variables (following the [CyberArk Conjur pattern](https://developer.konghq.com/gateway/entities/vault/)):

| Parameter | Vault entity | kong.conf | Environment variable |
|-----------|--------------|-----------|----------------------|
| Gateway URL | `vaults.config.gateway_url` | `vault_akeyless_gateway_url` | `KONG_VAULT_AKEYLESS_GATEWAY_URL` |
| Auth method | `vaults.config.auth_method` | `vault_akeyless_auth_method` | `KONG_VAULT_AKEYLESS_AUTH_METHOD` |
| Access ID | `vaults.config.access_id` | `vault_akeyless_access_id` | `KONG_VAULT_AKEYLESS_ACCESS_ID` |
| Access key | `vaults.config.access_key` | `vault_akeyless_access_key` | `KONG_VAULT_AKEYLESS_ACCESS_KEY` |
| Path prefix | `vaults.config.path_prefix` | `vault_akeyless_path_prefix` | `KONG_VAULT_AKEYLESS_PATH_PREFIX` |
| TTL | `vaults.config.ttl` | `vault_akeyless_ttl` | `KONG_VAULT_AKEYLESS_TTL` |
| Negative TTL | `vaults.config.neg_ttl` | `vault_akeyless_neg_ttl` | `KONG_VAULT_AKEYLESS_NEG_TTL` |
| Resurrect TTL | `vaults.config.resurrect_ttl` | `vault_akeyless_resurrect_ttl` | `KONG_VAULT_AKEYLESS_RESURRECT_TTL` |

## FAQs

**How do I rotate secrets?**  
Update the value in Akeyless. Configure `config.ttl` on the Vault entity so Kong refreshes periodically (default background rotation is every 60 seconds).

**Can I use this with Konnect?**  
Yes, once the backend is bundled in Kong Gateway Enterprise and supported on your Konnect data plane version.

**Can I configure Vault without a Vault entity?**  
Yes — after Kong bundles the backend, use `kong.conf` or startup environment variables (see table above). Values used before the database is initialized must use `kong.conf`/env, not the Vault entity.

## Related resources

- [Kong Vaults entity](https://developer.konghq.com/gateway/entities/vault/)
- [Kong Secrets management](https://developer.konghq.com/gateway/secrets-management/)
- [Akeyless REST API](https://docs.akeyless.io/docs/rest-api)
