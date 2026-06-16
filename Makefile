.PHONY: help preflight test-api lint validate

help:
	@echo "Targets:"
	@echo "  make preflight  - check local dependencies"
	@echo "  make test-api   - smoke test Akeyless API (requires examples/.env)"
	@echo "  make lint       - shellcheck + luac syntax check"
	@echo "  make validate   - full validation (API + Kong if running)"

preflight:
	@./scripts/preflight.sh

test-api:
	@./scripts/test-akeyless-api.sh

lint:
	@./scripts/lint.sh

validate:
	@./scripts/validate-vault.sh
