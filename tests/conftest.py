"""Shared fixtures for property-based tests."""

import os
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


@pytest.fixture
def run_bootstrap(tmp_workdir):
    """Return a helper to run the bootstrap CLI with given args."""

    def _run(*args, env=None):
        cmd = [sys.executable, "-m", "python_project_bootstrap.cli"] + list(args)
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
