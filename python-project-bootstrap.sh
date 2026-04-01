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
VERBOSE=false
QUIET=false
UPDATE_CONFIG=false
SUCCESS_FLAG=false
PROJECT_DIR=""

# Template context defaults
PYTHON_VERSION="3.12"
INCLUDE_DOCKER=true
INCLUDE_API=true
INCLUDE_CLI=true
LICENSE_TYPE="MIT"
INTERACTIVE=false

# Resolve the directory where this script lives (for locating render_templates.py)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------
# Logging
# -----------------------------

log() {
  [[ "$QUIET" == true ]] && return
  echo -e "${BLUE}[INFO]${NC} $1"
}

verbose_log() {
  [[ "$VERBOSE" != true ]] && return
  echo -e "${BLUE}[VERBOSE]${NC} $1"
}

success() {
  [[ "$QUIET" == true ]] && return
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
# Version
# -----------------------------

get_version() {
  grep '^version' "$SCRIPT_DIR/pyproject.toml" | head -1 | sed 's/.*"\(.*\)".*/\1/'
}

# -----------------------------
# Validation
# -----------------------------

validate_python_version() {
  if [[ ! "$1" =~ ^3\.[0-9]+$ ]]; then
    error "Invalid Python version '$1'. Must match pattern '3.NN' (e.g., 3.12, 3.13)."
  fi
}

validate_license() {
  case "$1" in
    MIT|Apache-2.0|GPL-3.0-only|BSD-2-Clause|BSD-3-Clause) ;;
    *) error "Unsupported license '$1'. Supported: MIT, Apache-2.0, GPL-3.0-only, BSD-2-Clause, BSD-3-Clause" ;;
  esac
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
    verbose_log "Executing: $*"
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
# Template context builder
# -----------------------------

build_context_json() {
  cat <<EOF
{
  "project_name": "$PROJECT_NAME",
  "package_name": "$PACKAGE_NAME",
  "python_version": "$PYTHON_VERSION",
  "include_docker": $INCLUDE_DOCKER,
  "include_api": $INCLUDE_API,
  "include_cli": $INCLUDE_CLI,
  "license_type": "$LICENSE_TYPE",
  "ruff_version": "$RUFF_VERSION",
  "mypy_version": "$MYPY_VERSION"
}
EOF
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
  -h, --help                Show this help message
  -d, --dry-run             Print actions without executing
  -v, --version             Print version and exit
  --no-docker               Skip Docker file generation
  --no-api                  Skip FastAPI scaffolding
  --no-cli                  Skip Typer CLI scaffolding
  --license <SPDX>          License type (default: MIT)
                            Supported: MIT, Apache-2.0, GPL-3.0-only,
                            BSD-2-Clause, BSD-3-Clause
  -i, --interactive         Prompt for each component before generating
  --python-version <ver>    Python version for generated project (default: 3.12)
  --verbose                 Show detailed logging output
  -q, --quiet               Suppress informational output (errors only)
  --update-config <dir>     Regenerate tooling files in an existing project

ARGUMENTS:
  project-name      Name of the project directory and package

EXAMPLES:
  $cmd my_project
  $cmd my_project --dry-run
  $cmd my_project --no-docker --no-api
  $cmd my_project --license Apache-2.0 --python-version 3.13
  $cmd --update-config ./my_project

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
    -v|--version)
      echo "$(get_version)"
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    --no-docker)
      INCLUDE_DOCKER=false
      shift
      ;;
    --no-api)
      INCLUDE_API=false
      shift
      ;;
    --no-cli)
      INCLUDE_CLI=false
      shift
      ;;
    --license)
      LICENSE_TYPE="$2"
      validate_license "$LICENSE_TYPE"
      shift 2
      ;;
    -i|--interactive)
      INTERACTIVE=true
      shift
      ;;
    --python-version)
      PYTHON_VERSION="$2"
      validate_python_version "$PYTHON_VERSION"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    -q|--quiet)
      QUIET=true
      shift
      ;;
    --update-config)
      UPDATE_CONFIG=true
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

if [[ "$VERBOSE" == true && "$QUIET" == true ]]; then
  error "Cannot use --verbose and --quiet together"
fi

# -----------------------------
# --update-config mode: regenerate tooling files in an existing project
# -----------------------------

if [[ "$UPDATE_CONFIG" == true ]]; then
  if [ "$#" -ne 1 ]; then
    error "--update-config requires a project directory path"
  fi

  UPDATE_DIR="$1"

  if [[ ! -d "$UPDATE_DIR" ]]; then
    error "Directory '$UPDATE_DIR' does not exist"
  fi

  if [[ ! -f "$UPDATE_DIR/pyproject.toml" ]]; then
    error "Not a valid project directory (missing pyproject.toml): $UPDATE_DIR"
  fi

  # Extract project info from existing pyproject.toml
  PROJECT_NAME=$(grep '^name' "$UPDATE_DIR/pyproject.toml" | head -1 | sed 's/.*"\(.*\)".*/\1/')
  PACKAGE_NAME="${PROJECT_NAME//-/_}"

  # Fetch pre-commit hook versions (fall back to known defaults)
  RUFF_VERSION="v0.8.6"
  MYPY_VERSION="v1.14.1"

  if command -v git >/dev/null 2>&1; then
    _ruff_latest=$(git ls-remote --tags --sort=-v:refname https://github.com/astral-sh/ruff-pre-commit.git 'refs/tags/v*' 2>/dev/null | head -n1 | sed 's|.*refs/tags/||') || true
    [[ -n "${_ruff_latest:-}" ]] && RUFF_VERSION="$_ruff_latest"
    _mypy_latest=$(git ls-remote --tags --sort=-v:refname https://github.com/pre-commit/mirrors-mypy.git 'refs/tags/v*' 2>/dev/null | head -n1 | sed 's|.*refs/tags/||') || true
    [[ -n "${_mypy_latest:-}" ]] && MYPY_VERSION="$_mypy_latest"
  fi

  log "Updating tooling configuration in $UPDATE_DIR..."

  # Only render tooling files
  TOOLING_FILES=("Makefile" ".pre-commit-config.yaml" ".gitignore")
  if [[ "$INCLUDE_DOCKER" == true ]]; then
    TOOLING_FILES+=("Dockerfile" "docker-compose.yml" ".dockerignore")
  fi

  # Determine the Python command that has jinja2 available
  PYTHON_CMD="python3"
  if ! python3 -c "import jinja2" 2>/dev/null; then
    if command -v uv >/dev/null 2>&1; then
      PYTHON_CMD="uv run --directory $SCRIPT_DIR python3"
    else
      error "jinja2 is not installed. Install it with: pip install jinja2"
    fi
  fi

  # Render all templates to a temp dir, then copy only tooling files
  TEMP_DIR=$(mktemp -d)
  build_context_json | $PYTHON_CMD "$SCRIPT_DIR/render_templates.py" "$TEMP_DIR"

  for f in "${TOOLING_FILES[@]}"; do
    if [[ -f "$TEMP_DIR/$f" ]]; then
      cp "$TEMP_DIR/$f" "$UPDATE_DIR/$f"
      verbose_log "Updated: $f"
    fi
  done

  rm -rf "$TEMP_DIR"

  success "Tooling configuration updated in $UPDATE_DIR"
  exit 0
fi

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
  if [[ "$INCLUDE_DOCKER" == true ]]; then
    command -v docker >/dev/null 2>&1 || missing+=("  - docker: install from https://docs.docker.com/get-docker/")
    docker compose version >/dev/null 2>&1 || missing+=("  - docker compose: install from https://docs.docker.com/compose/install/")
  fi
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
# Interactive prompts
# -----------------------------

if [[ "$INTERACTIVE" == true ]]; then
  read -rp "Include Docker support? [Y/n] " ans
  [[ "$ans" =~ ^[Nn] ]] && INCLUDE_DOCKER=false
  read -rp "Include FastAPI? [Y/n] " ans
  [[ "$ans" =~ ^[Nn] ]] && INCLUDE_API=false
  read -rp "Include Typer CLI? [Y/n] " ans
  [[ "$ans" =~ ^[Nn] ]] && INCLUDE_CLI=false
  read -rp "License type [MIT]: " ans
  if [[ -n "$ans" ]]; then
    LICENSE_TYPE="$ans"
    validate_license "$LICENSE_TYPE"
  fi
  read -rp "Python version [3.12]: " ans
  if [[ -n "$ans" ]]; then
    PYTHON_VERSION="$ans"
    validate_python_version "$PYTHON_VERSION"
  fi
fi

# Validate python version (covers default and flag-provided values)
validate_python_version "$PYTHON_VERSION"

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

# -----------------------------
# Fetch pre-commit hook versions (fall back to known defaults)
# -----------------------------

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

# -----------------------------
# Render templates
# -----------------------------

log "Rendering project files from templates..."

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}[DRY-RUN]${NC} Would render templates to $PROJECT_DIR"
else
  verbose_log "Template context: $(build_context_json)"
  # Determine the Python command that has jinja2 available
  PYTHON_CMD="python3"
  if ! python3 -c "import jinja2" 2>/dev/null; then
    if command -v uv >/dev/null 2>&1; then
      PYTHON_CMD="uv run --directory $SCRIPT_DIR python3"
    else
      error "jinja2 is not installed. Install it with: pip install jinja2"
    fi
  fi
  build_context_json | $PYTHON_CMD "$SCRIPT_DIR/render_templates.py" "$PROJECT_DIR"
fi

# -----------------------------
# Dependencies
# -----------------------------

log "Installing dependencies via uv..."

run_cmd uv add --directory "$PROJECT_DIR" pydantic
if [[ "$INCLUDE_API" == true ]]; then
  run_cmd uv add --directory "$PROJECT_DIR" fastapi "uvicorn[standard]"
fi
if [[ "$INCLUDE_CLI" == true ]]; then
  run_cmd uv add --directory "$PROJECT_DIR" typer
fi
run_cmd uv add --directory "$PROJECT_DIR" --dev pytest ruff mypy

# -----------------------------
# Git
# -----------------------------

log "Initializing git repository..."

run_cmd git init "$PROJECT_DIR"

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

if [[ "$QUIET" != true ]]; then
  echo
  echo "Next steps:"
  echo "  cd $PROJECT_NAME"
  echo "  make install"
  echo "  make run-api"
  echo "  make test"
fi

if [ "$DRY_RUN" = true ]; then
  warn "Dry-run mode enabled: no files were actually created"
fi
