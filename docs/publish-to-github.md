# Publish to GitHub (akeyless-community)

The integration currently lives inside the `akeyless-mcp` monorepo. Publish it as a **standalone public repository** for Kong review.

## Option A — New repo from this folder (recommended)

```bash
cd /path/to/akeyless-mcp/kong-akeyless-integration

git init
git add .
git commit -m "feat: Kong Gateway Enterprise Akeyless vault backend v0.1.0"

# Create empty repo on GitHub: akeyless-community/kong-akeyless-integration
git remote add origin git@github.com:akeyless-community/kong-akeyless-integration.git
git branch -M main
git push -u origin main
git tag v0.1.0
git push origin v0.1.0
```

## Option B — git subtree split from monorepo

From the `akeyless-mcp` root:

```bash
git subtree split --prefix=kong-akeyless-integration -b kong-akeyless-integration-main
git push git@github.com:akeyless-community/kong-akeyless-integration.git kong-akeyless-integration-main:main
```

## GitHub repo settings

| Setting | Value |
|---------|-------|
| Description | Native Kong Gateway Enterprise vault backend for Akeyless Secrets Management |
| Website | https://www.akeyless.io |
| Topics | `kong`, `kong-gateway`, `akeyless`, `secrets-management`, `vault`, `api-gateway` |
| License | Apache-2.0 (detected from LICENSE file) |
| Default branch | `main` |

## Release v0.1.0

1. GitHub → Releases → **Draft new release**
2. Tag: `v0.1.0`
3. Title: `v0.1.0 — Initial submission for Kong partner review`
4. Body: copy from `CHANGELOG.md`

## Do not commit

- `examples/.env` (gitignored)
- Kong license JSON
- Real Akeyless access keys
