# Partner outreach email (copy/paste)

Use after the public repo is live and tagged `v0.1.0`.

---

**Subject:** Akeyless native vault backend for Kong Gateway Enterprise — submission package ready for review

**To:** Kong account manager / partner team (cc: your Akeyless BD or alliances contact)

---

Hi [Name],

Akeyless has built a **native Kong Gateway Enterprise vault backend** for Secrets Management — the same integration class as CyberArk Conjur, HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, and GCP Secret Manager.

We would like to begin **joint technical validation** so Akeyless can be listed on [Supported Vault backends](https://developer.konghq.com/gateway/entities/vault/#supported-vault-backends).

**Submission package:** https://github.com/akeyless-community/kong-akeyless-integration  
**Reference integration:** [CyberArk Conjur how-to](https://developer.konghq.com/how-to/configure-cyberark-as-a-vault-backend/)

### What we are proposing

| Item | Value |
|------|-------|
| Vault entity `name` | `akeyless` |
| Reference syntax | `{vault://akeyless-vault/<path>[/<json-key>]}` |
| Implementation | `kong/vaults/akeyless/init.lua` + `schema.lua` |
| License tier | Enterprise (`license_required`) |
| Konnect | Target: Supported (match Conjur) |

### What is in the repo

- Lua vault strategy implementing Kong's `get(conf, resource, version)` contract
- Docker Compose + decK examples
- One-command validation: `./scripts/validate-vault.sh`
- Draft Kong how-to for your docs team

### What we can provide for QA

- Dedicated Akeyless test tenant with read-only auth scoped to `/kong/*`
- Engineering contact for auth methods: API key, Kubernetes, AWS IAM, Azure AD, GCP
- Call to walk through the submission and answer API questions

### Ask

1. Route this to the **Gateway Enterprise / Secrets Management** engineering owner  
2. Schedule a **30-minute technical review** of the vault strategy  
3. Confirm the path to **bundle in Enterprise** and publish on developer.konghq.com  

We have also applied via the [Kong Partner Program](https://konghq.com/partners/become-a-partner) under Technology Integration.

Happy to align on timeline and any schema or `kong.conf` naming conventions (`vault_akeyless_*`) before you port the module.

Best,  
[Your name]  
[Title], Akeyless  
[email]

---

## Follow-up (if no reply in 5 business days)

**Subject:** Re: Akeyless Kong vault backend — engineering handoff

Hi [Name],

Following up on the Akeyless vault backend submission for Kong Gateway Enterprise.

Repo: https://github.com/akeyless-community/kong-akeyless-integration  
E2E validation: `./scripts/validate-vault.sh` (requires Kong Enterprise license + Akeyless credentials)

Could you point us to the right engineering contact for native vault backend integrations?

Thanks,  
[Your name]
