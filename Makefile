PREFIX ?= $(HOME)/.local/bin
SCRIPT := python-project-bootstrap.sh
EXE_NAME := python-project-bootstrap

.DEFAULT_GOAL := help

.PHONY: help install uninstall build-exe install-exe clean ci lint test typecheck secrets setup-hooks

help: ## Show available targets
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Copy script to PREFIX and set executable permission
	@mkdir -p "$(PREFIX)"
	cp $(SCRIPT) $(PREFIX)/$(EXE_NAME)
	chmod +x $(PREFIX)/$(EXE_NAME)
	@echo "Installed $(EXE_NAME) to $(PREFIX)/$(EXE_NAME)"

uninstall: ## Remove script from PREFIX
	rm -f $(PREFIX)/$(EXE_NAME)
	@echo "Removed $(EXE_NAME) from $(PREFIX)/$(EXE_NAME)"

build-exe: ## Build standalone executable via PyInstaller
	@command -v pyinstaller >/dev/null 2>&1 || { echo "Error: pyinstaller is required. Install with: uv tool install pyinstaller"; exit 1; }
	pyinstaller --onefile --add-data "$(SCRIPT):." --name $(EXE_NAME) bootstrap_wrapper.py

install-exe: ## Copy built executable to PREFIX
	@if [ ! -f dist/$(EXE_NAME) ]; then echo "Error: dist/$(EXE_NAME) not found. Run 'make build-exe' first."; exit 1; fi
	@mkdir -p "$(PREFIX)"
	cp dist/$(EXE_NAME) $(PREFIX)/$(EXE_NAME)
	chmod +x $(PREFIX)/$(EXE_NAME)
	@echo "Installed $(EXE_NAME) to $(PREFIX)/$(EXE_NAME)"

clean: ## Remove dist/, build/, and *.spec files
	rm -rf dist/ build/
	rm -f *.spec
	@echo "Cleaned build artifacts."

# ---------- Dev lifecycle ----------

setup-hooks: ## Install git pre-commit hooks
	@bash dev-lifecycle/hooks/install-hooks.sh

lint: ## Run ruff lint + format check
	uv run ruff check .
	uv run ruff format --check .

typecheck: ## Run mypy type checker
	uv run mypy .

secrets: ## Scan for leaked secrets
	@bash dev-lifecycle/secrets/detect-secrets.sh

test: ## Run test suite
	@bash dev-lifecycle/ci/run-tests.sh

ci: ## Run full CI pipeline via Earthly (same as GitHub Actions)
	earthly +ci
