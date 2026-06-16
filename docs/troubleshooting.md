# Troubleshooting `make validate`

## Step 1 failed: HTTP 404 on get-secret-value

**Symptom:** `curl: (56) The requested URL returned error: 404` or `JSONDecodeError`

**Cause:** The secret path in `AKEYLESS_DEMO_SECRET_PATH` does not exist, or your Access ID cannot read it.

**Fix:**

1. List what you have access to:
   ```bash
   akeyless list-items --path /demo
   akeyless list-items --path /kong
   ```

2. Set `AKEYLESS_DEMO_SECRET_PATH` in `examples/.env` to an **existing** static secret path.

3. Or create the default demo secret:
   ```bash
   ./scripts/setup-demo-secrets.sh
   ```
   This creates `/kong/demo/api-key` (requires Akeyless CLI).

**Path alignment:** If your secret is `/demo/dotnet-integration`, set in `examples/.env`:

```bash
AKEYLESS_DEMO_SECRET_PATH=/demo/dotnet-integration
AKEYLESS_PATH_PREFIX=
```

And update `examples/kong.yaml` vault `path_prefix` to empty or `/demo` so Kong references match.

| Akeyless path | `AKEYLESS_PATH_PREFIX` | Kong reference |
|---------------|------------------------|----------------|
| `/kong/demo/api-key` | `/kong` | `{vault://akeyless-vault/demo/api-key}` |
| `/demo/dotnet-integration` | *(empty)* | `{vault://akeyless-vault/demo/dotnet-integration}` |
| `/demo/dotnet-integration` | `/demo` | `{vault://akeyless-vault/dotnet-integration}` |

---

## What is `KONG_LICENSE_DATA`?

Kong Gateway **Enterprise** license JSON. It is **not** an Akeyless credential.

| Step | Needs `KONG_LICENSE_DATA`? |
|------|----------------------------|
| `make test-api` | No |
| `make validate` step 1 (Akeyless) | No |
| `docker compose up` | **Yes** |
| `make validate` Kong steps | **Yes** |

**Where to get it:**

- **Kong Konnect:** Organization → License
- **Kong trial:** [konghq.com/get-started](https://konghq.com/get-started) or your Kong account team
- **Quickstart docs:** `export KONG_LICENSE_DATA='...'` ([Kong CyberArk tutorial](https://developer.konghq.com/how-to/configure-cyberark-as-a-vault-backend/) uses the same pattern)

Add to `examples/.env`:

```bash
KONG_LICENSE_DATA='{"license":{"payload":{...},"signature":"..."}}'
```

Leave empty to run **Akeyless-only** validation (step 1). `make validate` will pass after step 1 and skip Kong.

---

## Auth works but secret is empty

- Confirm the item is a **static secret** (not dynamic/rotated only).
- Check Access ID permissions include **read** on that path.

---

## Kong step: `vault akeyless is not installed`

Mount or install the vault strategy:

```bash
# Docker Compose demo mounts it automatically; or:
luarocks make kong-vault-akeyless-0.1.0-1.rockspec
```

---

## Common `.env` mistakes

| Mistake | Result |
|---------|--------|
| Access ID in `AKEYLESS_ACCESS_KEY` | Auth fails / base64 error |
| Secret path does not exist | 404 on get-secret-value |
| `path_prefix` mismatch | Kong resolves wrong Akeyless path |
