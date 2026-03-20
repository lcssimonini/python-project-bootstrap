#!/usr/bin/env bash

set -euo pipefail

# -----------------------------
# Python Project Bootstrap Script
# Stack: uv + FastAPI + Typer + Makefile + Docker + Docker Compose
# Features: Help, Dry-run, Verbose logging
# -----------------------------

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

DRY_RUN=false
SUCCESS_FLAG=false
PROJECT_DIR=""

# -----------------------------
# Logging
# -----------------------------

log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
  exit 1
}

# -----------------------------
# Cleanup handler
# -----------------------------

cleanup() {
  if [[ "$DRY_RUN" == true ]]; then return; fi
  if [[ "$SUCCESS_FLAG" != true && -n "$PROJECT_DIR" && -d "$PROJECT_DIR" ]]; then
    warn "Cleaning up partial project directory: $PROJECT_DIR"
    rm -rf "$PROJECT_DIR"
  fi
}

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} $*"
  else
    echo -e "${BLUE}[RUN]${NC} $*"
    "$@"
  fi
}

# Write a file: in dry-run mode prints [DRY-RUN], otherwise writes content via cat heredoc
# Usage: write_file <filepath> <<'MARKER' ... MARKER
write_file() {
  local filepath="$1"
  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} Would write $filepath"
    # consume and discard stdin so the heredoc doesn't cause errors
    cat > /dev/null
  else
    cat > "$filepath"
  fi
}

# -----------------------------
# Help
# -----------------------------

show_help() {
  local cmd
  cmd="$(basename "$0")"
  cat <<EOF
Usage: $cmd [OPTIONS] <project-name>

Bootstrap a modern Python project using:
  - uv (dependency management)
  - FastAPI (API)
  - Typer (CLI)
  - Makefile (task runner)
  - Docker + Docker Compose

OPTIONS:
  -h, --help        Show this help message
  -d, --dry-run     Print actions without executing

ARGUMENTS:
  project-name      Name of the project directory and package

EXAMPLES:
  $cmd my_project
  $cmd my_project --dry-run

WHAT WILL BE CREATED:
  - src/ layout (best practice)
  - CLI + API entrypoints (minimal)
  - tests structure (unit + integration)
  - pyproject.toml configured
  - Makefile with common tasks
  - Dockerfile and docker-compose.yml
  - Git repository initialized

PREREQUISITES:
  - git
  - docker
  - docker compose
  - uv (https://github.com/astral-sh/uv)

EOF
}

# -----------------------------
# Parse args
# -----------------------------

POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

if [ "$#" -ne 1 ]; then
  show_help
  error "Invalid arguments"
fi

PROJECT_NAME="$1"

# -----------------------------
# Prerequisite checker (collect-all pattern)
# -----------------------------

check_prerequisites() {
  local missing=()

  command -v git >/dev/null 2>&1 || missing+=("  - git: install from https://git-scm.com/")
  command -v docker >/dev/null 2>&1 || missing+=("  - docker: install from https://docs.docker.com/get-docker/")
  docker compose version >/dev/null 2>&1 || missing+=("  - docker compose: install from https://docs.docker.com/compose/install/")
  command -v uv >/dev/null 2>&1 || missing+=("  - uv: install from https://github.com/astral-sh/uv")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Missing prerequisites:" >&2
    for tool in "${missing[@]}"; do
      echo -e "$tool" >&2
    done
    exit 1
  fi

  success "All prerequisites found"
}

# -----------------------------
# Preconditions
# -----------------------------

if [[ "$DRY_RUN" != true && "${SKIP_PREREQS:-}" != true ]]; then
  check_prerequisites
fi

if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
  error "Invalid project name '$PROJECT_NAME'. Must start with a lowercase letter and contain only lowercase letters, digits, underscores, and hyphens."
fi

if [ -d "$PROJECT_NAME" ]; then
  error "Directory '$PROJECT_NAME' already exists"
fi

PROJECT_DIR="$(pwd)/$PROJECT_NAME"
PACKAGE_NAME="${PROJECT_NAME//-/_}"
trap cleanup EXIT INT TERM

# -----------------------------
# Create structure
# -----------------------------

log "Creating project structure..."

run_cmd mkdir -p "$PROJECT_DIR"

run_cmd uv init --name "$PROJECT_NAME" "$PROJECT_DIR"

# Remove uv's default scaffolding files (we provide our own)
if [ "$DRY_RUN" = false ]; then
  rm -f "$PROJECT_DIR/main.py" "$PROJECT_DIR/README.md"
fi

run_cmd mkdir -p "$PROJECT_DIR/src/$PACKAGE_NAME/api"
run_cmd mkdir -p "$PROJECT_DIR/src/$PACKAGE_NAME/core"
run_cmd mkdir -p "$PROJECT_DIR/tests/unit"
run_cmd mkdir -p "$PROJECT_DIR/tests/integration"

run_cmd touch "$PROJECT_DIR/src/$PACKAGE_NAME/__init__.py"
run_cmd touch "$PROJECT_DIR/src/$PACKAGE_NAME/py.typed"
run_cmd touch "$PROJECT_DIR/src/$PACKAGE_NAME/api/__init__.py"
run_cmd touch "$PROJECT_DIR/src/$PACKAGE_NAME/core/__init__.py"
run_cmd touch "$PROJECT_DIR/tests/__init__.py"
run_cmd touch "$PROJECT_DIR/tests/unit/__init__.py"
run_cmd touch "$PROJECT_DIR/tests/integration/__init__.py"

write_file "$PROJECT_DIR/tests/conftest.py" <<'EOF'
import pytest

@pytest.fixture
def sample_fixture():
    """Placeholder shared fixture."""
    return {}
EOF

write_file "$PROJECT_DIR/tests/unit/test_cli.py" <<EOF
from $PACKAGE_NAME.cli import app
from typer.testing import CliRunner

runner = CliRunner()


def test_hello_default():
    result = runner.invoke(app)
    assert result.exit_code == 0
    assert "Hello, world!" in result.output


def test_hello_with_name():
    result = runner.invoke(app, ["--name", "Alice"])
    assert result.exit_code == 0
    assert "Hello, Alice!" in result.output
EOF

write_file "$PROJECT_DIR/tests/unit/test_api.py" <<EOF
from fastapi.testclient import TestClient
from $PACKAGE_NAME.api.main import app

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()
EOF

write_file "$PROJECT_DIR/.env.example" <<'EOF'
# Environment variables for the project
# Copy this file to .env and fill in the values
# APP_ENV=development
# DATABASE_URL=sqlite:///db.sqlite3
# SECRET_KEY=change-me
EOF

# -----------------------------
# Minimal entrypoints
# -----------------------------

log "Creating minimal entrypoints..."

write_file "$PROJECT_DIR/src/$PACKAGE_NAME/api/main.py" <<EOF
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def root():
    return {"message": "Hello from $PROJECT_NAME"}
EOF

write_file "$PROJECT_DIR/src/$PACKAGE_NAME/cli.py" <<EOF
import typer

app = typer.Typer()


@app.command()
def hello(name: str = "world"):
    """Say hello."""
    typer.echo(f"Hello, {name}!")


if __name__ == "__main__":
    app()
EOF

# -----------------------------
# pyproject
# -----------------------------

log "Generating pyproject.toml..."

write_file "$PROJECT_DIR/pyproject.toml" <<EOF
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = ""
requires-python = ">=3.12"
dependencies = [
    "fastapi",
    "uvicorn[standard]",
    "typer",
    "pydantic",
]

[project.scripts]
"$PROJECT_NAME" = "$PACKAGE_NAME.cli:app"
"$PROJECT_NAME-api" = "$PACKAGE_NAME.api.main:app"

[build-system]
requires = ["setuptools", "wheel"]
build-backend = "setuptools.build_meta"

[tool.uv]
package = true

[dependency-groups]
dev = [
    "pytest",
    "httpx",
    "ruff",
    "mypy",
    "pre-commit",
    "pyinstaller",
]

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM"]

[tool.mypy]
strict = true
plugins = ["pydantic.mypy"]
EOF

# -----------------------------
# Makefile
# -----------------------------

log "Creating Makefile..."

write_file "$PROJECT_DIR/Makefile" <<EOF
.DEFAULT_GOAL := help

.PHONY: help install dev run-api run-cli test lint format type-check docker-build docker-up docker-down pre-commit-install clean build-exe

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' \$(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-20s %s\n", \$\$1, \$\$2}'

install: ## Install dependencies
	uv sync

dev: ## Install dev dependencies and pre-commit hooks
	uv sync --dev
	uv run pre-commit install

run-api: ## Run FastAPI app
	uv run uvicorn $PACKAGE_NAME.api.main:app --reload --host 0.0.0.0 --port 8000

run-cli: ## Run CLI tool
	uv run $PROJECT_NAME

test: ## Run tests
	uv run pytest

lint: ## Run linter
	uv run ruff check .

format: ## Format code
	uv run ruff format .

type-check: ## Run type checker
	uv run mypy src/

docker-build: ## Build Docker image
	docker compose build

docker-up: ## Start containers
	docker compose up

docker-down: ## Stop containers
	docker compose down

pre-commit-install: ## Install pre-commit hooks
	uv run pre-commit install

clean: ## Remove build artifacts and caches
	rm -rf dist/ build/
	rm -f *.spec
	find . -type d -name __pycache__ -exec rm -rf {} +
	rm -rf .pytest_cache/ .mypy_cache/

build-exe: ## Build standalone executable via PyInstaller
	uv run pyinstaller --onefile src/$PACKAGE_NAME/cli.py --name $PROJECT_NAME
EOF


# -----------------------------
# Docker
# -----------------------------

log "Creating Docker setup..."

write_file "$PROJECT_DIR/Dockerfile" <<EOF
# Stage 1: Builder
FROM python:3.12-slim AS builder

WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY . .
RUN uv sync --frozen --no-dev

# Stage 2: Runtime
FROM python:3.12-slim

WORKDIR /app

RUN useradd --create-home appuser

COPY --from=builder /app /app

USER appuser

CMD ["uv", "run", "uvicorn", "$PACKAGE_NAME.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

write_file "$PROJECT_DIR/docker-compose.yml" <<EOF
services:
  app:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    command: uv run uvicorn $PACKAGE_NAME.api.main:app --reload --host 0.0.0.0 --port 8000
EOF

# -----------------------------
# Pre-commit config
# -----------------------------

log "Creating pre-commit configuration..."

# Fetch latest release tags for ruff and mypy (fall back to known versions)
RUFF_VERSION="v0.8.6"
MYPY_VERSION="v1.14.1"

if command -v git >/dev/null 2>&1 && [ "$DRY_RUN" = false ]; then
  _ruff_latest=$(git ls-remote --tags --sort=-v:refname https://github.com/astral-sh/ruff-pre-commit.git 'refs/tags/v*' 2>/dev/null | head -n1 | sed 's|.*refs/tags/||') || true
  if [[ -n "${_ruff_latest:-}" ]]; then
    RUFF_VERSION="$_ruff_latest"
  fi
  _mypy_latest=$(git ls-remote --tags --sort=-v:refname https://github.com/pre-commit/mirrors-mypy.git 'refs/tags/v*' 2>/dev/null | head -n1 | sed 's|.*refs/tags/||') || true
  if [[ -n "${_mypy_latest:-}" ]]; then
    MYPY_VERSION="$_mypy_latest"
  fi
fi

log "Using ruff pre-commit rev: $RUFF_VERSION, mypy rev: $MYPY_VERSION"

write_file "$PROJECT_DIR/.pre-commit-config.yaml" <<EOF
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: $RUFF_VERSION
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: $MYPY_VERSION
    hooks:
      - id: mypy
        additional_dependencies: [pydantic]
EOF

# -----------------------------
# Dependencies
# -----------------------------

log "Installing dependencies via uv..."

run_cmd uv add --directory "$PROJECT_DIR" fastapi uvicorn typer pydantic
run_cmd uv add --directory "$PROJECT_DIR" --dev pytest ruff mypy

# -----------------------------
# Git
# -----------------------------

log "Initializing git repository..."

run_cmd git init "$PROJECT_DIR"

write_file "$PROJECT_DIR/.gitignore" <<'GITIGNORE_EOF'
# Python
__pycache__/
*.pyc
*.pyo
*.egg-info/
dist/
build/

# Virtual environments
.venv/
venv/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env

# Testing
.pytest_cache/
.mypy_cache/
.coverage
htmlcov/

# PyInstaller
*.spec
GITIGNORE_EOF

if [ "$DRY_RUN" = false ]; then
  git -C "$PROJECT_DIR" add .
  if git -C "$PROJECT_DIR" config user.name >/dev/null 2>&1 && git -C "$PROJECT_DIR" config user.email >/dev/null 2>&1; then
    git -C "$PROJECT_DIR" commit -m "Initial commit"
  else
    warn "Git user not configured. Skipping initial commit. Run: git config --global user.name 'Your Name' && git config --global user.email 'you@example.com'"
  fi
else
  echo -e "${YELLOW}[DRY-RUN]${NC} git -C $PROJECT_DIR add ."
  echo -e "${YELLOW}[DRY-RUN]${NC} git -C $PROJECT_DIR commit -m \"Initial commit\""
fi

# -----------------------------
# Done
# -----------------------------

SUCCESS_FLAG=true

success "Project '$PROJECT_NAME' created successfully!"

echo
echo "Next steps:"
echo "  cd $PROJECT_NAME"
echo "  make install"
echo "  make run-api"
echo "  make test"

if [ "$DRY_RUN" = true ]; then
  warn "Dry-run mode enabled: no files were actually created"
fi
