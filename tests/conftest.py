"""Shared fixtures for property-based tests."""

import os
import shutil
import subprocess
import sys

import pytest


@pytest.fixture
def tmp_workdir(tmp_path):
    """Provide a temporary working directory and change to it."""
    original = os.getcwd()
    os.chdir(tmp_path)
    yield tmp_path
    os.chdir(original)


def _has_docker() -> bool:
    """Check if docker and docker compose are available."""
    if not shutil.which("docker"):
        return False
    try:
        subprocess.run(
            ["docker", "compose", "version"],
            capture_output=True,
            check=True,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


# Cache docker availability check
_DOCKER_AVAILABLE = _has_docker()


@pytest.fixture
def run_bootstrap(tmp_workdir):
    """Return a helper to run the bootstrap CLI with given args.

    Automatically adds --no-docker if docker is not available.
    """

    def _run(*args, env=None):
        args_list = list(args)

        # Auto-add --no-docker if docker isn't available and we're creating a project
        # (not dry-run, not --help, not update-config)
        if not _DOCKER_AVAILABLE:
            is_dry_run = "--dry-run" in args_list or "-d" in args_list
            is_help = "--help" in args_list
            is_subcommand = "update-config" in args_list
            is_version = "--version" in args_list

            should_add_no_docker = (
                not is_dry_run
                and not is_help
                and not is_subcommand
                and not is_version
                and "--no-docker" not in args_list
            )
            if should_add_no_docker:
                args_list.insert(0, "--no-docker")

        cmd = [sys.executable, "-m", "python_project_bootstrap.cli"] + args_list
        run_env = os.environ.copy()
        if env:
            run_env.update(env)
        return subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(tmp_workdir),
            env=run_env,
        )

    return _run
