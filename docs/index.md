# Python Project Bootstrap

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

## Quick Start

```bash
python-project-bootstrap my_project
```

For full documentation, see the [README](https://github.com/lcssimonini/python-project-bootstrap#readme).
