VERSION 0.8

# ---------- shared image for all targets ----------
deps:
    FROM python:3.12-slim
    WORKDIR /workspace

    # System deps needed by tests (git, docker CLI)
    RUN apt-get update && \
        apt-get install -y --no-install-recommends git docker.io curl && \
        rm -rf /var/lib/apt/lists/*

    # Install gitleaks
    ARG GITLEAKS_VERSION=8.21.2
    RUN curl -sSfL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" \
        | tar -xz -C /usr/local/bin gitleaks && \
        chmod +x /usr/local/bin/gitleaks

    # Install uv
    RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
        mv /root/.local/bin/uv /usr/local/bin/uv

    # Copy dependency manifests first for layer caching
    COPY pyproject.toml uv.lock ./
    RUN uv sync --frozen --dev

    # Copy everything else
    COPY . .

# ---------- lint ----------
lint:
    FROM +deps
    RUN uv run ruff check .
    RUN uv run ruff format --check .

# ---------- secret scan ----------
secrets:
    FROM +deps
    RUN gitleaks dir . --config dev-lifecycle/secrets/gitleaks.toml --verbose

# ---------- type check ----------
typecheck:
    FROM +deps
    RUN uv run mypy .

# ---------- tests ----------
test:
    FROM +deps
    # git config needed for tests that run git init
    RUN git config --global user.name "CI" && \
        git config --global user.email "ci@test.local" && \
        git config --global init.defaultBranch main
    ENV SKIP_PREREQS=true
    RUN bash dev-lifecycle/ci/run-tests.sh -k "not test_prerequisite_checker"

# ---------- all checks (convenience) ----------
ci:
    BUILD +lint
    BUILD +secrets
    BUILD +typecheck
    BUILD +test
