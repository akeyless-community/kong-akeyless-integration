# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | Yes       |

## Reporting a vulnerability

Do **not** open a public GitHub issue for security vulnerabilities.

Email **security@akeyless.io** with:

- Description of the issue
- Steps to reproduce
- Impact assessment (if known)

For Kong Gateway Enterprise deployments, also notify your Kong support channel if the issue affects bundled code after merge.

## Integration security guidance

- Scope Akeyless auth methods to the minimum path prefix (e.g. `/kong/*`) with **read-only** access.
- Prefer Kubernetes or cloud IAM auth on Kong data planes over long-lived API keys.
- Never commit `examples/.env` or Kong license data to version control.
- Rotate Akeyless access keys if they are ever exposed in logs or CI output.
