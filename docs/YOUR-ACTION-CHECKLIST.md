# Your action checklist

Everything the agent prepared is in `kong-akeyless-integration/`. These steps require **you** (Akeyless team) — credentials, GitHub org access, and Kong partner outreach.

## Phase 1 — Publish the repo (today)

- [ ] **Create public repo** `github.com/akeyless-community/kong-akeyless-integration`
- [ ] **Push this folder** as the initial commit (see [publish-to-github.md](publish-to-github.md))
- [ ] Set repo description: `Native Kong Gateway Enterprise vault backend for Akeyless Secrets Management`
- [ ] Add topics: `kong`, `kong-gateway`, `akeyless`, `secrets-management`, `vault`
- [ ] Tag release: `git tag v0.1.0 && git push origin v0.1.0`
- [ ] Enable GitHub Issues (for Kong engineering questions)

## Phase 2 — Validate locally (before contacting Kong)

- [ ] Copy `examples/.env.example` → `examples/.env`
- [ ] Fill in:
  - `AKEYLESS_ACCESS_ID` / `AKEYLESS_ACCESS_KEY`
  - `KONG_LICENSE_DATA` (Enterprise trial or existing license)
- [ ] Run:

```bash
cd kong-akeyless-integration
make preflight
./scripts/setup-demo-secrets.sh    # or create /kong/demo/api-key in console
make test-api                      # Akeyless API only
docker compose -f examples/docker-compose.yml up -d
deck gateway apply examples/kong.yaml
make validate
```

- [ ] Save terminal output from `make validate` — attach to partner email as proof

## Phase 3 — Kong partner outreach (same week as publish)

- [ ] **Apply:** https://konghq.com/partners/become-a-partner  
  - Category: Technology integration  
  - Product: Kong Gateway Enterprise Secrets Management (native vault backend)
- [ ] **Email** Kong using [partner-outreach-email.md](partner-outreach-email.md)
  - To: your Kong AE / partner manager (if you have one)
  - Cc: Akeyless alliances / BD contact
- [ ] **Attach / link:**
  - Repo URL
  - [kong-engineering-handoff.md](kong-engineering-handoff.md)
  - `validate-vault.sh` success output
- [ ] **Prepare for Kong QA** (fill in handoff doc):
  - Dedicated test Access ID scoped to `/kong/*` read-only
  - Named engineering contact + calendar link

## Phase 4 — After Kong responds

- [ ] Joint call with Kong Gateway / Secrets Management engineering
- [ ] Address review feedback on `init.lua` / `schema.lua`
- [ ] Kong merges into Enterprise + publishes docs
- [ ] Confirm listing on https://developer.konghq.com/gateway/entities/vault/#supported-vault-backends
- [ ] Cross-link from Akeyless docs
- [ ] Optional: joint blog post

## What you do NOT need to do

| Action | Why skip |
|--------|----------|
| Open PR to `Kong/kong` (OSS) | Enterprise vaults are bundled separately |
| Submit to Kong Hub as plugin | Vault backends are core Enterprise, not plugins |
| Wait for email reply before publishing repo | Repo should be live **before** outreach |

## Files ready for Kong

| File | Purpose |
|------|---------|
| `vault-strategy/kong/vaults/akeyless/init.lua` | Integration code |
| `vault-strategy/kong/vaults/akeyless/schema.lua` | Config schema |
| `docs/configure-akeyless-as-vault-backend.md` | Draft Kong docs page |
| `docs/kong-engineering-handoff.md` | One-pager for engineers |
| `docs/partner-outreach-email.md` | Copy/paste email |
| `examples/docker-compose.yml` | Reproducible demo |
| `scripts/validate-vault.sh` | E2E proof |

## Questions?

Open an issue in the published repo or contact your Akeyless integrations lead.
