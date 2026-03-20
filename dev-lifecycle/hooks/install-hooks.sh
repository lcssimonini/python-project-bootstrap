#!/usr/bin/env bash
set -euo pipefail

# Installs the project's git hooks by symlinking into .git/hooks/.
# Usage: bash dev-lifecycle/hooks/install-hooks.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

if [ ! -d "$GIT_HOOKS_DIR" ]; then
  echo "Error: .git/hooks not found. Are you inside a git repository?" >&2
  exit 1
fi

HOOK_SRC="$SCRIPT_DIR/pre-commit"
HOOK_DST="$GIT_HOOKS_DIR/pre-commit"

# Back up existing hook if it's not already our symlink
if [ -e "$HOOK_DST" ] && [ ! -L "$HOOK_DST" ]; then
  echo "Backing up existing pre-commit hook to pre-commit.bak"
  mv "$HOOK_DST" "$HOOK_DST.bak"
fi

ln -sf "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_SRC"

echo "Pre-commit hook installed successfully."
