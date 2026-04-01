#!/usr/bin/env python3
"""Render Jinja2 templates for project generation."""

import json
import sys
from pathlib import Path

from jinja2 import Environment, FileSystemLoader


# Files to skip when include_docker is False
DOCKER_FILES = {"Dockerfile", "docker-compose.yml", ".dockerignore"}


def should_skip(output_name: str, context: dict) -> bool:
    """Determine if a file should be skipped based on context flags."""
    if not context.get("include_docker") and output_name in DOCKER_FILES:
        return True
    if not context.get("include_api") and (
        "api/" in output_name or output_name.endswith("test_api.py")
    ):
        return True
    if not context.get("include_cli") and output_name.endswith("cli.py"):
        return True
    return False


def resolve_output_path(output_name: str, package_name: str) -> str:
    """Replace __package__ placeholder with actual package name."""
    return output_name.replace("__package__", package_name)


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: render_templates.py <target-directory>", file=sys.stderr)
        sys.exit(1)

    context = json.load(sys.stdin)
    target_dir = Path(sys.argv[1])
    templates_dir = Path(__file__).parent / "templates"

    env = Environment(
        loader=FileSystemLoader(str(templates_dir)),
        keep_trailing_newline=True,
    )

    package_name = context.get("package_name", "")

    for template_path in sorted(templates_dir.rglob("*.j2")):
        rel = template_path.relative_to(templates_dir)
        # Remove .j2 suffix to get the output filename
        output_name = str(rel).removesuffix(".j2")

        if should_skip(output_name, context):
            continue

        output_name = resolve_output_path(output_name, package_name)

        template = env.get_template(str(rel))
        rendered = template.render(**context)

        output_path = target_dir / output_name
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(rendered)


if __name__ == "__main__":
    main()
