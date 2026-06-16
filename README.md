# Kong Gateway Akeyless Vault Backend

Native [Kong Gateway](https://konghq.com) Secrets Management integration for [Akeyless](https://www.akeyless.io). Resolve `{vault://...}` references in `kong.conf`, declarative config, plugin fields, and certificates — without storing plaintext secrets in Kong.

**Target listing:** [Kong Supported Vault backends](https://developer.konghq.com/gateway/entities/vault/#supported-vault-backends) on developer.konghq.com.

> **Ready for Kong partner review.** See **[docs/YOUR-ACTION-CHECKLIST.md](docs/YOUR-ACTION-CHECKLIST.md)** for what to do next (publish repo, validate, contact Kong).

## What this provides

| Component | Description |
|-----------|-------------|
| **Vault strategy** | Lua module (`kong.vaults.akeyless`) implementing Kong's vault `get(conf, resource, version)` contract |
| **LuaRocks package** | Install into Kong Gateway Enterprise for joint QA before native bundling |
| **decK examples** | Declarative Vault entity + plugin secret references |
| **Docker Compose demo** | Kong Gateway + PostgreSQL with mounted vault strategy |
| **Kong-format docs** | Draft how-to for developer.konghq.com |
| **Partner playbook** | Steps to land on Kong's official vault backends page |

## How it works

```
┌─────────────────┐     {vault://akeyless-vault/demo/api-key}     ┌──────────────┐
│  Kong Gateway   │ ──────────────────────────────────────────────► │   Akeyless   │
│  (Enterprise)   │         POST /auth  →  POST /get-secret-value │  SaaS / GW   │
└─────────────────┘                                               └──────────────┘
```

1. Create a **Vault entity** with `name: akeyless` and your gateway credentials.
2. Store secrets in Akeyless under a path prefix (e.g. `/kong/...`).
3. Reference secrets anywhere Kong supports vault references.

### Example references

| Akeyless path | `path_prefix` | Kong reference |
|---------------|---------------|----------------|
| `/kong/demo/api-key` | `/kong` | `{vault://akeyless-vault/demo/api-key}` |
| `/kong/pg` (JSON `username`/`password`) | `/kong` | `{vault://akeyless-vault/pg/username}` |

## Quick start

### 1. Prerequisites

- Kong Gateway **Enterprise** license
- Akeyless Access ID + Access Key (or Kubernetes / cloud IAM auth)
- [decK](https://developer.konghq.com/deck/) (optional)
- Docker (for local demo)

See [docs/troubleshooting.md](docs/troubleshooting.md) if `make validate` fails.

### 2. Create a demo secret in Akeyless

```bash
cp examples/.env.example examples/.env
# Edit examples/.env with your credentials

./scripts/setup-demo-secrets.sh   # requires Akeyless CLI
```

Or create `/kong/demo/api-key` manually in the Akeyless console.

### 3. Test Akeyless API (no Kong)

```bash
./scripts/test-akeyless-api.sh
```

### 4. Run Kong demo stack

```bash
export KONG_LICENSE_DATA='...'   # or add to examples/.env
docker compose -f examples/docker-compose.yml up -d
```

### 5. Apply Vault entity and validate

```bash
set -a && source examples/.env && set +a
deck gateway apply examples/kong.yaml

docker compose -f examples/docker-compose.yml exec kong-gateway \
  kong vault get '{vault://akeyless-vault/demo/api-key}'
```

Or run the full validation script:

```bash
./scripts/validate-vault.sh
```

## Install vault strategy

Until Kong bundles Akeyless natively:

**Option A — mount files (demo)**

```yaml
volumes:
  - ./vault-strategy/kong/vaults/akeyless:/usr/local/share/lua/5.1/kong/vaults/akeyless:ro
```

**Option B — LuaRocks**

```bash
luarocks make kong-vault-akeyless-0.1.0-1.rockspec
```

## Configuration

### Vault entity (decK / Admin API)

```yaml
vaults:
  - name: akeyless
    prefix: akeyless-vault
    config:
      gateway_url: "https://api.akeyless.io"
      auth_method: api_key
      access_id: "p-xxxxxxxx"
      access_key: "your-access-key"
      path_prefix: "/kong"
      ttl: 60
```

### Authentication methods

| Method | Fields | Notes |
|--------|--------|-------|
| `api_key` | `access_id`, `access_key` | Default |
| `token` | `token` | Skip `/auth` |
| `kubernetes` | `access_id`, `k8s_auth_config_name` | Reads SA token from file |
| `aws_iam` | `access_id` | EC2/EKS instance metadata |
| `azure_ad` | `access_id` | Azure IMDS |
| `gcp` | `access_id`, `gcp_audience` | GCE/GKE metadata |
| `universal_identity` | `uid_token` | Universal Identity |

See [docs/configure-akeyless-as-vault-backend.md](docs/configure-akeyless-as-vault-backend.md) for the full parameter table.

## Appearing on developer.konghq.com

Native listing requires Kong to **bundle** the vault strategy in Gateway Enterprise (not a community plugin).

| Doc | Purpose |
|-----|---------|
| [YOUR-ACTION-CHECKLIST.md](docs/YOUR-ACTION-CHECKLIST.md) | **Start here** — your to-do list |
| [publish-to-github.md](docs/publish-to-github.md) | Push to `akeyless-community` |
| [partner-outreach-email.md](docs/partner-outreach-email.md) | Copy/paste Kong email |
| [kong-engineering-handoff.md](docs/kong-engineering-handoff.md) | One-pager for Kong engineers |
| [kong-partner-submission.md](docs/kong-partner-submission.md) | Full partner playbook |

## Repository layout

```
kong-akeyless-integration/
├── vault-strategy/kong/vaults/akeyless/   # Lua vault backend
├── kong-vault-akeyless-0.1.0-1.rockspec   # LuaRocks (repo root)
├── examples/                              # docker-compose, kong.yaml, .env
├── scripts/                               # validate, setup, API smoke test
├── .github/workflows/ci.yml               # lint + preflight
└── docs/                                  # how-to, partner email, your checklist
```

## Security notes

- Scope Akeyless auth to `/kong/*` (or your prefix) with read-only access.
- Use Kubernetes or cloud IAM auth on Kong data planes when possible instead of long-lived access keys.
- Kong never logs resolved secret values when vault references are used correctly.

## Related projects

- [Jenkins Akeyless Credentials Provider](https://github.com/akeyless-community/JenkinsSecretsManagerProvider)
- [Buildkite Akeyless Plugin](https://github.com/akeyless-community/buildkite-akeyless-plugin)
- [Octopus Deploy Akeyless Step Templates](https://github.com/akeyless-community/octopus-akeyless-plugin)

## License

Apache-2.0
