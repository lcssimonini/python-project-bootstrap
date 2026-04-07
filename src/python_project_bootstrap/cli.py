#!/usr/bin/env python3
"""CLI entry point for python-project-bootstrap."""

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Annotated

import typer
from jinja2 import Environment, FileSystemLoader
from rich.console import Console

app = typer.Typer(
    name="python-project-bootstrap",
    help="Bootstrap a modern Python project with uv, FastAPI, Typer, and more.",
    add_completion=False,
    invoke_without_command=True,
)


def version_callback(value: bool) -> None:
    """Print version and exit."""
    if value:
        console.print("0.1.0")
        raise typer.Exit()


console = Console()
error_console = Console(stderr=True)

# Files to skip based on flags
DOCKER_FILES = {"Dockerfile", "docker-compose.yml", ".dockerignore"}


def log(msg: str) -> None:
    """Log an info message."""
    console.print(f"[blue][INFO][/blue] {msg}")


def success(msg: str) -> None:
    """Log a success message."""
    console.print(f"[green][SUCCESS][/green] {msg}")


def warn(msg: str) -> None:
    """Log a warning message."""
    console.print(f"[yellow][WARNING][/yellow] {msg}")


def error(msg: str) -> None:
    """Log an error message and exit."""
    error_console.print(f"[red][ERROR][/red] {msg}")
    raise typer.Exit(1)


def validate_project_name(name: str) -> str:
    """Validate project name format."""
    if not re.match(r"^[a-z][a-z0-9_-]*$", name):
        error(
            f"Invalid project name '{name}'. Must start with a lowercase letter "
            "and contain only lowercase letters, digits, underscores, and hyphens."
        )
    return name


def validate_python_version(version: str) -> str:
    """Validate Python version format."""
    if not re.match(r"^3\.[0-9]+$", version):
        error(f"Invalid Python version '{version}'. Must match pattern '3.NN' (e.g., 3.12, 3.13).")
    return version


def validate_license(license_type: str) -> str:
    """Validate license type."""
    valid = {"MIT", "Apache-2.0", "GPL-3.0-only", "BSD-2-Clause", "BSD-3-Clause"}
    if license_type not in valid:
        error(f"Unsupported license '{license_type}'. Supported: {', '.join(sorted(valid))}")
    return license_type


def check_prerequisites(include_docker: bool) -> None:
    """Check that required tools are installed."""
    missing = []
    if not shutil.which("git"):
        missing.append("  - git: install from https://git-scm.com/")
    if include_docker:
        if not shutil.which("docker"):
            missing.append("  - docker: install from https://docs.docker.com/get-docker/")
        try:
            subprocess.run(
                ["docker", "compose", "version"],
                capture_output=True,
                check=True,
            )
        except (subprocess.CalledProcessError, FileNotFoundError):
            missing.append(
                "  - docker compose: install from https://docs.docker.com/compose/install/"
            )
    if not shutil.which("uv"):
        missing.append("  - uv: install from https://github.com/astral-sh/uv")

    if missing:
        error("Missing prerequisites:\n" + "\n".join(missing))
    success("All prerequisites found")


def get_latest_tag(repo_url: str, default: str) -> str:
    """Fetch latest tag from a git repo."""
    try:
        result = subprocess.run(
            ["git", "ls-remote", "--tags", "--sort=-v:refname", repo_url, "refs/tags/v*"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0 and result.stdout:
            first_line = result.stdout.strip().split("\n")[0]
            tag = first_line.split("refs/tags/")[-1]
            return tag
    except Exception:
        pass
    return default


def should_skip(output_name: str, context: dict) -> bool:
    """Determine if a template should be skipped based on context flags."""
    if not context.get("include_docker") and output_name in DOCKER_FILES:
        return True
    if not context.get("include_api") and (
        "api/" in output_name or output_name.endswith("test_api.py")
    ):
        return True
    return not context.get("include_cli") and output_name.endswith("cli.py")


def render_templates(templates_dir: Path, target_dir: Path, context: dict) -> None:
    """Render all Jinja2 templates to target directory."""
    env = Environment(
        loader=FileSystemLoader(str(templates_dir)),
        keep_trailing_newline=True,
    )

    package_name = context.get("package_name", "")

    for template_path in sorted(templates_dir.rglob("*.j2")):
        rel = template_path.relative_to(templates_dir)
        output_name = str(rel).removesuffix(".j2")

        if should_skip(output_name, context):
            continue

        output_name = output_name.replace("__package__", package_name)

        template = env.get_template(str(rel))
        rendered = template.render(**context)

        output_path = target_dir / output_name
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(rendered)


def get_templates_dir() -> Path:
    """Get templates directory, handling both dev and PyInstaller modes."""
    # PyInstaller bundle
    if hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS) / "templates"
    # Development mode
    return Path(__file__).parent / "templates"


def run_cmd(
    cmd: list[str],
    cwd: Path | None = None,
    check: bool = True,
) -> subprocess.CompletedProcess:
    """Run a command and return the result."""
    return subprocess.run(cmd, cwd=cwd, check=check)


@app.callback(invoke_without_command=True)
def main(
    ctx: typer.Context,
    project_name: str = typer.Argument(None, help="Name of the project to create"),
    dry_run: bool = typer.Option(False, "--dry-run", "-d", help="Print actions without executing"),
    no_docker: bool = typer.Option(False, "--no-docker", help="Skip Docker file generation"),
    no_api: bool = typer.Option(False, "--no-api", help="Skip FastAPI scaffolding"),
    no_cli: bool = typer.Option(False, "--no-cli", help="Skip Typer CLI scaffolding"),
    license_type: str = typer.Option(
        "MIT",
        "--license",
        help="License type (MIT, Apache-2.0, GPL-3.0-only, BSD-2-Clause, BSD-3-Clause)",
    ),
    python_version: str = typer.Option(
        "3.12", "--python-version", help="Python version for generated project"
    ),
    interactive: bool = typer.Option(
        False, "--interactive", "-i", help="Prompt for each component"
    ),
    verbose: bool = typer.Option(False, "--verbose", help="Show detailed logging output"),
    quiet: bool = typer.Option(False, "--quiet", "-q", help="Suppress informational output"),
    version: Annotated[
        bool, typer.Option("--version", callback=version_callback, is_eager=True)
    ] = False,
) -> None:
    """Bootstrap a modern Python project."""
    # If a subcommand is being invoked, skip main logic
    if ctx.invoked_subcommand is not None:
        return

    if project_name is None:
        console.print(ctx.get_help())
        raise typer.Exit(0)

    # Validations
    validate_project_name(project_name)
    validate_python_version(python_version)
    validate_license(license_type)

    if verbose and quiet:
        error("Cannot use --verbose and --quiet together")

    include_docker = not no_docker
    include_api = not no_api
    include_cli = not no_cli

    # Interactive prompts
    if interactive:
        include_docker = typer.confirm("Include Docker support?", default=True)
        include_api = typer.confirm("Include FastAPI?", default=True)
        include_cli = typer.confirm("Include Typer CLI?", default=True)
        new_license = typer.prompt("License type", default=license_type)
        license_type = validate_license(new_license)
        new_version = typer.prompt("Python version", default=python_version)
        python_version = validate_python_version(new_version)

    # Check prerequisites
    if not dry_run:
        check_prerequisites(include_docker)

    project_dir = Path.cwd() / project_name
    package_name = project_name.replace("-", "_")

    if project_dir.exists():
        error(f"Directory '{project_name}' already exists")

    # Fetch latest tool versions
    ruff_version = get_latest_tag("https://github.com/astral-sh/ruff-pre-commit.git", "v0.8.6")
    mypy_version = get_latest_tag("https://github.com/pre-commit/mirrors-mypy.git", "v1.14.1")

    context = {
        "project_name": project_name,
        "package_name": package_name,
        "python_version": python_version,
        "include_docker": include_docker,
        "include_api": include_api,
        "include_cli": include_cli,
        "license_type": license_type,
        "ruff_version": ruff_version,
        "mypy_version": mypy_version,
    }

    if dry_run:
        console.print(f"[yellow][DRY-RUN][/yellow] Would create project at: {project_dir}")
        context_json = json.dumps(context, indent=2)
        for line in context_json.splitlines():
            console.print(f"[yellow][DRY-RUN][/yellow] {line}")
        warn("Dry-run mode enabled: no files were actually created")
        return

    try:
        # Create project structure
        log("Creating project structure...")
        run_cmd(["uv", "init", "--name", project_name, str(project_dir)])

        # Remove uv's default files
        (project_dir / "main.py").unlink(missing_ok=True)
        (project_dir / "README.md").unlink(missing_ok=True)

        # Render templates
        log("Rendering project files from templates...")
        templates_dir = get_templates_dir()
        if not templates_dir.exists():
            error(f"Templates directory not found: {templates_dir}")
        render_templates(templates_dir, project_dir, context)

        # Install dependencies
        log("Installing dependencies via uv...")
        run_cmd(["uv", "add", "--directory", str(project_dir), "pydantic"])
        if include_api:
            run_cmd(["uv", "add", "--directory", str(project_dir), "fastapi", "uvicorn[standard]"])
        if include_cli:
            run_cmd(["uv", "add", "--directory", str(project_dir), "typer"])
        run_cmd(["uv", "add", "--directory", str(project_dir), "--dev", "pytest", "ruff", "mypy"])

        # Initialize git
        log("Initializing git repository...")
        run_cmd(["git", "init", str(project_dir)])
        run_cmd(["git", "-C", str(project_dir), "add", "."])

        # Try to commit
        try:
            subprocess.run(
                ["git", "-C", str(project_dir), "config", "user.name"],
                capture_output=True,
                check=True,
            )
            subprocess.run(
                ["git", "-C", str(project_dir), "config", "user.email"],
                capture_output=True,
                check=True,
            )
            run_cmd(["git", "-C", str(project_dir), "commit", "-m", "Initial commit"])
        except subprocess.CalledProcessError:
            warn(
                "Git user not configured. Skipping initial commit. Run: "
                "git config --global user.name 'Your Name' && "
                "git config --global user.email 'you@example.com'"
            )

        success(f"Project '{project_name}' created successfully!")
        console.print()
        console.print("Next steps:")
        console.print(f"  cd {project_name}")
        console.print("  make install")
        if include_api:
            console.print("  make run-api")
        console.print("  make test")

    except Exception:
        # Cleanup on failure
        if project_dir.exists():
            warn(f"Cleaning up partial project directory: {project_dir}")
            shutil.rmtree(project_dir)
        raise


@app.command()
def update_config(
    project_dir: Annotated[Path, typer.Argument(help="Path to existing project directory")],
    no_docker: bool = typer.Option(False, "--no-docker", help="Skip Docker file generation"),
) -> None:
    """Regenerate tooling files in an existing project."""
    if not project_dir.exists():
        error(f"Directory '{project_dir}' does not exist")

    pyproject = project_dir / "pyproject.toml"
    if not pyproject.exists():
        error(f"Not a valid project directory (missing pyproject.toml): {project_dir}")

    # Extract project name from pyproject.toml
    content = pyproject.read_text()
    match = re.search(r'^name\s*=\s*"([^"]+)"', content, re.MULTILINE)
    if match is None:
        error("Could not extract project name from pyproject.toml")
        return  # unreachable but helps type checker

    project_name = match.group(1)
    package_name = project_name.replace("-", "_")
    include_docker = not no_docker

    ruff_version = get_latest_tag("https://github.com/astral-sh/ruff-pre-commit.git", "v0.8.6")
    mypy_version = get_latest_tag("https://github.com/pre-commit/mirrors-mypy.git", "v1.14.1")

    context = {
        "project_name": project_name,
        "package_name": package_name,
        "python_version": "3.12",
        "include_docker": include_docker,
        "include_api": True,
        "include_cli": True,
        "license_type": "MIT",
        "ruff_version": ruff_version,
        "mypy_version": mypy_version,
    }

    log(f"Updating tooling configuration in {project_dir}...")

    tooling_files = ["Makefile", ".pre-commit-config.yaml", ".gitignore"]
    if include_docker:
        tooling_files.extend(["Dockerfile", "docker-compose.yml", ".dockerignore"])

    templates_dir = get_templates_dir()
    env = Environment(
        loader=FileSystemLoader(str(templates_dir)),
        keep_trailing_newline=True,
    )

    for filename in tooling_files:
        template_name = f"{filename}.j2"
        try:
            template = env.get_template(template_name)
            rendered = template.render(**context)
            (project_dir / filename).write_text(rendered)
        except Exception:
            pass  # Skip if template doesn't exist

    success(f"Tooling configuration updated in {project_dir}")


if __name__ == "__main__":
    app()
