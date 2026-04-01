# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-06-01

### Added

- Interactive bootstrap script (`python-project-bootstrap.sh`) for generating modern Python projects
- Jinja2-based template system for maintainable file generation (`render_templates.py`)
- Generated project stack: uv, FastAPI, Typer, Makefile, Docker, Docker Compose
- Modern `src/` layout with PEP 561 `py.typed` marker
- Preconfigured `pyproject.toml` with ruff, mypy (strict mode), and pydantic plugin
- Multi-stage Dockerfile with non-root user and uv layer caching
- Makefile with 15 development targets for generated projects
- `.pre-commit-config.yaml` with ruff and mypy hooks (versions fetched dynamically)
- Dry-run mode (`--dry-run`) for safe previewing without side effects
- Interactive mode (`--interactive`) for guided component selection
- Update mode (`--update-config`) to regenerate tooling files in existing projects
- Customization flags: `--no-docker`, `--no-api`, `--no-cli`, `--license`, `--python-version`
- Verbose (`--verbose`) and quiet (`--quiet`) output modes
- Collect-all prerequisite checker with install hints
- Trap-based cleanup on failure or interruption
- Project name validation (lowercase, alphanumeric, hyphens, underscores)
- PyInstaller support via `bootstrap_wrapper.py` for standalone executables
- Cross-platform bash detection (macOS, Linux, Windows via Git Bash/WSL)
- Property-based test suite using Hypothesis (14 properties)
- Earthly-based CI pipeline with parallel lint, secrets, typecheck, and test targets
- GitHub Actions workflows for CI, release, and documentation deployment
- Pre-commit hooks for secret detection (gitleaks), ruff lint, and ruff format
- MkDocs Material documentation site
- GitHub issue templates, PR template, and Dependabot configuration
- CONTRIBUTING guide with development setup instructions
