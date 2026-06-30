#!/usr/bin/env bash
# Install local git hooks with dev-only deps (no runtime / torch sync on host).
set -euo pipefail

if [[ ! -f pyproject.toml ]]; then
  echo "ERROR: pyproject.toml not found. Run init-ai add python-quality first." >&2
  exit 1
fi

if [[ ! -f .pre-commit-config.yaml ]]; then
  echo "ERROR: .pre-commit-config.yaml not found. Run init-ai add pre-commit-hooks first." >&2
  exit 1
fi

echo "Syncing dev tools only (--only-dev --no-install-project)..."
uv sync --only-dev --no-install-project

if [[ ! -x .venv/bin/pre-commit ]]; then
  echo "ERROR: .venv/bin/pre-commit not found after sync." >&2
  echo "Run init-ai add pre-commit-hooks --apply to add the pre-commit dev dependency." >&2
  exit 1
fi

.venv/bin/pre-commit install
.venv/bin/pre-commit install --hook-type pre-push

echo
echo "Local hooks ready."
echo "  Use .venv/bin/pre-commit — not uv run pre-commit (uv run auto-syncs runtime deps)."
echo "  Docker Compose / CI train: docker compose run for local ML; uv-bootstrap.sh for GitLab."
