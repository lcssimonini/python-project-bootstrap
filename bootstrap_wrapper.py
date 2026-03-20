#!/usr/bin/env python3
"""Thin wrapper to run python-project-bootstrap.sh via PyInstaller."""

import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


def _find_bash() -> str:
    """Locate a usable bash executable across platforms."""
    # Check PATH first (works on Unix, Git Bash, and WSL-exposed bash)
    bash = shutil.which("bash")
    if bash:
        return bash

    # Common Windows locations for Git Bash / WSL
    if platform.system() == "Windows":
        candidates = [
            Path(os.environ.get("PROGRAMFILES", r"C:\Program Files"))
            / "Git"
            / "bin"
            / "bash.exe",
            Path(os.environ.get("LOCALAPPDATA", ""))
            / "Programs"
            / "Git"
            / "bin"
            / "bash.exe",
            Path(r"C:\Windows\System32\bash.exe"),  # WSL
        ]
        for candidate in candidates:
            if candidate.exists():
                return str(candidate)

    print(
        "Error: bash not found. On Windows, install Git for Windows "
        "(https://gitforwindows.org) or enable WSL.",
        file=sys.stderr,
    )
    sys.exit(1)


def main():
    base_path = Path(getattr(sys, "_MEIPASS", None) or Path(__file__).parent)
    script = base_path / "python-project-bootstrap.sh"

    if not script.exists():
        print(f"Error: {script} not found", file=sys.stderr)
        sys.exit(1)

    bash = _find_bash()
    result = subprocess.run([bash, str(script)] + sys.argv[1:])
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
