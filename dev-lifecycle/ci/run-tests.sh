#!/usr/bin/env bash
set -euo pipefail

# Reusable test runner — called by CI and available for local use.
# Usage: bash dev-lifecycle/ci/run-tests.sh [pytest-args...]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

echo "==> Running tests"
uv run pytest tests/ -v --cov --cov-report=term-missing "$@"
