#!/usr/bin/env bash
set -euo pipefail

# Secret detection via gitleaks (https://github.com/gitleaks/gitleaks).
# - Pre-commit hook context: scans staged changes (git --pre-commit --staged)
# - CI / manual context: scans the working directory (dir)
#
# Install gitleaks:
#   macOS:  brew install gitleaks
#   Linux:  https://github.com/gitleaks/gitleaks/releases
#   Or let the Earthfile handle it in CI.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$SCRIPT_DIR/gitleaks.toml"

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "Error: gitleaks is not installed." >&2
  echo "  macOS:  brew install gitleaks" >&2
  echo "  Linux:  see https://github.com/gitleaks/gitleaks/releases" >&2
  exit 1
fi

CONFIG_FLAG=()
if [ -f "$CONFIG" ]; then
  CONFIG_FLAG=(--config "$CONFIG")
fi

# Detect context: if GIT_INDEX_FILE is set we're inside a pre-commit hook
if [ -n "${GIT_INDEX_FILE:-}" ]; then
  echo "==> Scanning staged changes for secrets..."
  gitleaks git --pre-commit --staged "${CONFIG_FLAG[@]}" --verbose
else
  echo "==> Scanning directory for secrets..."
  gitleaks dir "$REPO_ROOT" "${CONFIG_FLAG[@]}" --verbose
fi

echo "No secrets detected."
