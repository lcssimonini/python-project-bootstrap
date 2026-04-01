# Python Project Bootstrap

[![CI](https://github.com/lcssimonini/python-project-bootstrap/actions/workflows/ci.yml/badge.svg)](https://github.com/lcssimonini/python-project-bootstrap/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![Coverage](https://img.shields.io/badge/coverage-check%20CI-brightgreen.svg)]()

A production-ready bootstrap tool that generates modern Python project scaffolding using:

* **uv** for dependency management
* **FastAPI** for API development
* **Typer** for CLI tools
* **Makefile** for task automation
* **Docker + Docker Compose** for containerization
* **Pre-commit** hooks for code quality
* **PyInstaller** for standalone executable packaging

---

## Features

* Modern `src/` layout with PEP 561 `py.typed` marker
* CLI + API scaffolding with minimal entrypoints
* Unit and integration test structure with shared `conftest.py`
* Preconfigured `pyproject.toml` (ruff, mypy strict mode, pydantic plugin)
* Makefile with 15 development targets
* Multi-stage Docker build with non-root user
* Pre-commit hooks for ruff and mypy (versions fetched dynamically at generation time)
* Git repository initialization with initial commit
* Dry-run mode for safe previewing
* Trap-based cleanup on failure or interruption
* Collect-all prerequisite checker with install hints
* PyInstaller support for standalone executables (both this tool and generated projects)
* Jinja2 template system for maintainable file generation

---

## Prerequisites

Required tools:

| Tool | Purpose | Install |
|------|---------|---------|
| `git` | Version control | [git-scm.com](https://git-scm.com/) |
| `docker` | Containerization | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| `docker compose` | Container orchestration | [docs.docker.com/compose/install](https://docs.docker.com/compose/install/) |
| `uv` | Python dependency management | [github.com/astral-sh/uv](https://github.com/astral-sh/uv) |

Optional:

| Tool | Purpose | Install |
|------|---------|---------|
| `pyinstaller` | Standalone executable packaging | `uv tool install pyinstaller` |
| `earthly` | Reproducible CI builds locally | [earthly.dev](https://earthly.dev/get-earthly) |
| `gitleaks` | Secret detection | `brew install gitleaks` or [releases](https://github.com/gitleaks/gitleaks/releases) |

The script checks all prerequisites at startup and reports every missing tool in a single message with installation hints.

---

## Installation

### Via Makefile (recommended)

```bash
# Copy script to ~/.local/bin (default, no sudo needed)
make install

# Or specify a custom prefix
make install PREFIX=/usr/local/bin
```

### Via PyInstaller executable

```bash
make build-exe
make install-exe
```

### Uninstall

```bash
make uninstall
```

---

## Usage

```bash
python-project-bootstrap <project-name>
```

Project names must start with a lowercase letter and contain only lowercase letters, digits, underscores, and hyphens. Hyphens are automatically converted to underscores for the Python package name.

### Examples

```bash
python-project-bootstrap my_project
python-project-bootstrap data-pipeline
```

### Dry-run mode

Preview all actions without creating any files:

```bash
python-project-bootstrap my_project --dry-run
```

* No files or directories are created
* No `uv`, `git`, or `docker` commands are executed
* Prerequisite checks are skipped
* Every action line is prefixed with `[DRY-RUN]`

### Customization Flags

Skip components you don't need:

```bash
python-project-bootstrap my_project --no-docker --no-api
python-project-bootstrap my_project --no-cli
python-project-bootstrap my_project --license Apache-2.0
python-project-bootstrap my_project --python-version 3.13
```

### Interactive Mode

Prompt for each component:

```bash
python-project-bootstrap my_project --interactive
```

### Update Existing Project

Regenerate tooling files without touching source code:

```bash
python-project-bootstrap --update-config ./my_project
```

### Verbosity Control

```bash
python-project-bootstrap my_project --verbose   # Detailed logging
python-project-bootstrap my_project --quiet     # Errors only
```

### Version

```bash
python-project-bootstrap --version
```

---

## Generated Project Structure

```
my_project/
├── .env.example
├── .git/
├── .gitignore
├── .pre-commit-config.yaml
├── Dockerfile
├── Makefile
├── docker-compose.yml
├── pyproject.toml
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── py.typed
│       ├── cli.py
│       ├── api/
│       │   ├── __init__.py
│       │   └── main.py
│       └── core/
│           └── __init__.py
└── tests/
    ├── __init__.py
    ├── conftest.py
    ├── unit/
    │   ├── __init__.py
    │   ├── test_cli.py
    │   └── test_api.py
    └── integration/
        └── __init__.py
```

---

## Generated Makefile Targets

| Target | Description |
|--------|-------------|
| `make help` | Show available targets (default) |
| `make install` | Install dependencies |
| `make dev` | Install dev dependencies and pre-commit hooks |
| `make run-api` | Start FastAPI app with hot reload |
| `make run-cli` | Run CLI tool |
| `make test` | Run tests with pytest |
| `make lint` | Run ruff linter |
| `make format` | Format code with ruff |
| `make type-check` | Run mypy type checker |
| `make docker-build` | Build Docker image |
| `make docker-up` | Start containers |
| `make docker-down` | Stop containers |
| `make pre-commit-install` | Install pre-commit hooks |
| `make clean` | Remove build artifacts and caches |
| `make build-exe` | Build standalone executable via PyInstaller |

---

## Development

### Setup

```bash
uv sync --dev
make setup-hooks
```

This installs dev dependencies and sets up the git pre-commit hook, which runs gitleaks (secret detection), ruff lint, and ruff format on every commit.

### Dev lifecycle Makefile targets

| Target | Description |
|--------|-------------|
| `make help` | Show available targets (default) |
| `make install` | Copy bootstrap script to PREFIX |
| `make uninstall` | Remove bootstrap script from PREFIX |
| `make build-exe` | Build standalone executable via PyInstaller |
| `make install-exe` | Copy built executable to PREFIX |
| `make clean` | Remove build artifacts |
| `make setup-hooks` | Install git pre-commit hooks |
| `make lint` | Run ruff lint + format check |
| `make typecheck` | Run mypy type checker |
| `make secrets` | Scan for leaked secrets via gitleaks |
| `make test` | Run test suite |
| `make ci` | Run full CI pipeline via Earthly |

### Project layout

```
dev-lifecycle/
├── ci/
│   └── run-tests.sh            # Reusable test runner
├── hooks/
│   ├── install-hooks.sh         # One-command hook installer
│   └── pre-commit               # Git pre-commit hook
└── secrets/
    ├── detect-secrets.sh        # Gitleaks wrapper script
    └── gitleaks.toml            # Gitleaks configuration
```

### CI/CD

CI runs on GitHub Actions for pushes to `main` and pull requests. The workflow delegates entirely to [Earthly](https://earthly.dev), so what runs in CI is exactly what you get locally:

```bash
# Run the full pipeline locally (identical to CI)
make ci

# Or run individual targets
earthly +lint
earthly +secrets
earthly +typecheck
earthly +test
```

Earthly targets:

| Target | What it does |
|--------|-------------|
| `+lint` | ruff check + format check |
| `+secrets` | gitleaks secret scan |
| `+typecheck` | mypy strict mode |
| `+test` | pytest with Hypothesis property-based tests |
| `+ci` | All of the above in parallel |

### Testing

The project uses pytest with [Hypothesis](https://hypothesis.readthedocs.io/) for property-based testing. Tests validate:

* Dry-run purity (zero side effects)
* Project name validation (valid, invalid, and edge cases)
* Generated file completeness
* pyproject.toml, Dockerfile, Makefile, and pre-commit config correctness
* Cleanup behavior on failure
* Prerequisite checker error reporting

```bash
make test
```

### Secret detection

[Gitleaks](https://github.com/gitleaks/gitleaks) scans for secrets both locally (via the pre-commit hook on staged changes) and in CI (via the Earthly `+secrets` target on the full directory). Configuration is in `dev-lifecycle/secrets/gitleaks.toml`.

---

## Error Handling

* **Cleanup on failure**: If the script fails after creating the project directory, a trap-based cleanup handler removes the partial directory automatically.
* **Signal handling**: SIGINT and SIGTERM trigger cleanup before exit.
* **Collect-all prerequisite checking**: All missing tools are reported in a single error message.
* **Input validation**: Project names are validated against `^[a-z][a-z0-9_-]*$`.
* **Existing directory check**: The script refuses to overwrite an existing directory.

---

## Cross-Platform Notes

The bootstrap script requires a bash environment. On macOS and Linux it works natively. On Windows, the PyInstaller wrapper (`bootstrap_wrapper.py`) automatically searches for bash in Git for Windows and WSL locations. Install [Git for Windows](https://gitforwindows.org) or enable WSL for Windows support.

---

## License

This project is licensed under the [MIT License](LICENSE).
