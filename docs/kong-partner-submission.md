# Kong Technology Partner — Akeyless vault backend listing

Goal: appear on [Supported Vault backends](https://developer.konghq.com/gateway/entities/vault/#supported-vault-backends) like CyberArk Conjur, HashiCorp Vault, AWS, Azure, and GCP.

## How Kong lists vault backends

Native vault backends are **built into Kong Gateway Enterprise** as Lua modules under `kong.vaults.<name>`. They are not separate Kong plugins. CyberArk Conjur (`name: conjur`) was added in Kong Gateway 3.11+ as the most recent partner vault backend.

Listing on developer.konghq.com requires:

1. **Engineering integration** — vault strategy merged into Kong Gateway Enterprise
2. **Documentation** — how-to guide + parameter reference on developer.konghq.com
3. **Partner agreement** — Kong Technology Partner / OEM process

## Deliverables in this repository

| Artifact | Purpose |
|----------|---------|
| `vault-strategy/kong/vaults/akeyless/init.lua` | Vault `get()` implementation |
| `vault-strategy/kong/vaults/akeyless/schema.lua` | Vault entity config schema |
| `luarocks/kong-vault-akeyless-0.1.0-1.rockspec` | Installable package for joint testing |
| `docs/configure-akeyless-as-vault-backend.md` | Draft Kong how-to (PR to Kong docs) |
| `examples/docker-compose.yml` | Joint QA environment |
| `scripts/validate-vault.sh` | E2E validation script for Kong QA |

## Proposed Kong integration surface

| Field | Value |
|-------|-------|
| Vault `name` | `akeyless` |
| Example prefix | `akeyless-vault` |
| Reference syntax | `{vault://akeyless-vault/<resource>[/<json-key>]}` |
| License | Enterprise (`license_required = true`) |
| Konnect | Target: Supported (match CyberArk) |

## Submission checklist

### Phase 1 — Joint technical validation

- [ ] Contact Kong Partner team: [Kong Partners](https://konghq.com/partners/become-a-partner) or your Kong account team
- [ ] Send email from [partner-outreach-email.md](partner-outreach-email.md)
- [ ] Share [kong-engineering-handoff.md](kong-engineering-handoff.md) with Kong engineering
- [ ] Share this repository and `scripts/validate-vault.sh` results
- [ ] Provide Kong engineering with test Akeyless tenant + Access ID scoped to `/kong/*`
- [ ] Run joint test matrix: api_key, kubernetes, aws_iam auth on Kong-supported platforms

### Phase 2 — Kong Gateway Enterprise PR

Kong engineering typically integrates:

```
kong/vaults/akeyless/init.lua
kong/vaults/akeyless/schema.lua
kong/conf_loader/constants.lua   # BUNDLED_VAULTS.akeyless = true
kong/templates/kong_defaults.lua # vault_akeyless_* kong.conf keys
```

Reference PR pattern: CyberArk Conjur vault backend (Kong Gateway 3.11+).

### Phase 3 — Kong documentation PR

Submit to [Kong/docs](https://github.com/Kong/docs) (or Kong's internal docs pipeline):

1. **Supported Vault backends** table entry:

   ```markdown
   ### Backend: Akeyless Secrets Manager

   Kong Gateway OSS: Not Supported
   Kong Gateway Enterprise: Supported
   Konnect supported: Supported
   ```

2. **How-to page** — adapt `docs/configure-akeyless-as-vault-backend.md`

3. **Vault entity tab** — configuration parameter table (`vault_akeyless_*`)

4. **Secrets management landing page** — link under third-party vaults

### Phase 4 — Launch

- [ ] Kong release notes (e.g. "Kong Gateway X.Y adds Akeyless vault backend")
- [ ] Akeyless docs cross-link
- [ ] Joint blog / integration page
- [ ] Publish `kong-vault-akeyless` rockspec to LuaRocks (optional; deprecated once bundled)

## Comparison with CyberArk (reference integration)

| Aspect | CyberArk Conjur | Akeyless (proposed) |
|--------|-----------------|---------------------|
| Vault name | `conjur` | `akeyless` |
| Auth | `api_key` (login + api_key) | `api_key`, `kubernetes`, cloud IAM, `token` |
| Secret fetch | Conjur REST API | `/get-secret-value` |
| Path encoding | URL-encode `/` in references | Standard `/` path segments (folder paths) |
| Enterprise only | Yes | Yes |
| Added in | Kong 3.11+ | TBD |

## Contacts and links

- Kong Vaults: https://developer.konghq.com/gateway/entities/vault/
- Kong Secrets management: https://developer.konghq.com/gateway/secrets-management/
- CyberArk how-to (template): https://developer.konghq.com/how-to/configure-cyberark-as-a-vault-backend/
- Akeyless REST API: https://docs.akeyless.io/docs/rest-api
- Akeyless Kong integration repo: `kong-akeyless-integration` in akeyless-community
