# Contributing to python-project-bootstrap

Thanks for your interest in contributing! This guide covers how to set up the dev environment, run tests, and submit changes.

## Development Environment Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/lcssimonini/python-project-bootstrap.git
   cd python-project-bootstrap
   ```

2. **Install dependencies** (requires [uv](https://docs.astral.sh/uv/)):

   ```bash
   uv sync --dev
   ```

3. **Install git hooks:**

   ```bash
   make setup-hooks
   ```

   This installs pre-commit hooks that run linting and formatting checks before each commit.

## Running the Test Suite

Run the full test suite locally:

```bash
uv run pytest
```

To run a specific test file:

```bash
uv run pytest tests/test_properties.py
```

To run with verbose output:

```bash
uv run pytest -v
```

## Code Style

This project enforces code style automatically:

- **[ruff](https://docs.astral.sh/ruff/)** — linting and formatting for Python files
- **[mypy](https://mypy-lang.org/)** — static type checking with strict mode enabled

Run linting and type checking locally:

```bash
make lint
make typecheck
```

The pre-commit hooks run ruff checks automatically. CI will reject PRs that fail lint or type checks.

## Branch Strategy and PR Conventions

- Create feature branches from `main` (e.g., `feature/add-flag`, `fix/template-bug`).
- Keep commits focused and atomic.
- PRs are merged via **squash merge** to keep the main branch history clean.
- Write a clear PR title and description. Use the PR template provided.
- Reference any related issues in your PR description (e.g., `Closes #42`).

## Reporting Issues

Use the GitHub issue templates for bug reports and feature requests. Provide as much detail as possible to help us understand and reproduce the issue.
