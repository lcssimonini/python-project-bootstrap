# python-project-bootstrap Makefile
# Run 'make help' to see available targets

PREFIX ?= $(HOME)/.local/bin
EXE_NAME := python-project-bootstrap

.DEFAULT_GOAL := help

# ============================================================================
# Help
# ============================================================================

.PHONY: help
help: ## Show available targets
	@echo "Usage: make <target>"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*##"}; {printf "  %-18s %s\n", $$1, $$2}'

# ============================================================================
# Installation
# ============================================================================

.PHONY: install uninstall

install: ## Install as editable uv tool (recommended for development)
	uv tool install --force --editable .
	@echo "✓ Installed $(EXE_NAME) via uv tool"

uninstall: ## Remove uv tool installation
	uv tool uninstall $(EXE_NAME) || true
	@echo "✓ Removed $(EXE_NAME)"

# ============================================================================
# Build
# ============================================================================

.PHONY: build-exe install-exe clean

build-exe: ## Build standalone executable via PyInstaller
	uv run pyinstaller --onefile \
		--name $(EXE_NAME) \
		--add-data "src/python_project_bootstrap/templates:templates" \
		src/python_project_bootstrap/cli.py
	@echo "✓ Built dist/$(EXE_NAME)"

install-exe: build-exe ## Build and install standalone executable to PREFIX
	@mkdir -p "$(PREFIX)"
	cp dist/$(EXE_NAME) "$(PREFIX)/$(EXE_NAME)"
	chmod +x "$(PREFIX)/$(EXE_NAME)"
	@echo "✓ Installed to $(PREFIX)/$(EXE_NAME)"

clean: ## Remove build artifacts (dist/, build/, *.spec)
	rm -rf dist/ build/
	rm -f *.spec
	@echo "✓ Cleaned build artifacts"

# ============================================================================
# Development
# ============================================================================

.PHONY: setup-hooks dev

setup-hooks: ## Install git pre-commit hooks
	@bash dev-lifecycle/hooks/install-hooks.sh

dev: setup-hooks ## Setup development environment
	uv sync
	@echo "✓ Development environment ready"

# ============================================================================
# Quality Assurance
# ============================================================================

.PHONY: lint format typecheck test secrets check

lint: ## Run ruff linter
	uv run ruff check .

format: ## Format code with ruff
	uv run ruff format .

typecheck: ## Run mypy type checker
	uv run mypy .

test: ## Run test suite
	@bash dev-lifecycle/ci/run-tests.sh

secrets: ## Scan for leaked secrets
	@bash dev-lifecycle/secrets/detect-secrets.sh

check: lint typecheck test ## Run all quality checks (lint + typecheck + test)
	@echo "✓ All checks passed"

# ============================================================================
# CI/CD
# ============================================================================

.PHONY: ci

ci: ## Run full CI pipeline via Earthly
	earthly +ci

# ============================================================================
# Documentation
# ============================================================================

.PHONY: docs-serve docs-build

docs-serve: ## Serve documentation locally
	uv run mkdocs serve

docs-build: ## Build documentation site
	uv run mkdocs build
