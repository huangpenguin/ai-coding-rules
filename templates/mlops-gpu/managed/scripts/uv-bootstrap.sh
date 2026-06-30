#!/usr/bin/env bash
# Shared project venv bootstrap for GitLab GPU train jobs (local dev uses docker-compose.yml).
# Keeps legacy requirements.txt, semi-migrated pyproject.toml, and uv.lock paths aligned.
set -euo pipefail

MLOPS_PYTORCH_INDEX="${MLOPS_PYTORCH_INDEX:-https://download.pytorch.org/whl/cu124}"
MLOPS_PYPI_INDEX="${MLOPS_PYPI_INDEX:-https://pypi.org/simple}"
MLOPS_TORCH_CONSTRAINT="${MLOPS_TORCH_CONSTRAINT:-torch>=2.6.0,<2.7.0}"
UV_BOOTSTRAP_VERIFY_TORCH="${UV_BOOTSTRAP_VERIFY_TORCH:-1}"
UV_BOOTSTRAP_ENSURE_UV="${UV_BOOTSTRAP_ENSURE_UV:-auto}"

ensure_uv() {
  if command -v uv >/dev/null 2>&1; then
    return 0
  fi

  if [[ "${UV_BOOTSTRAP_ENSURE_UV}" == "0" || "${UV_BOOTSTRAP_ENSURE_UV}" == "false" ]]; then
    echo "ERROR: uv not found and UV_BOOTSTRAP_ENSURE_UV disables auto-install." >&2
    exit 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required to install uv." >&2
    exit 1
  fi

  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="${HOME}/.local/bin:${PATH}"
}

requirements_mentions_torch() {
  [[ -f requirements.txt ]] || return 1
  grep -qiE '(^|[[:space:],[])(torch|torchvision|torchaudio)([=<>!\[]|[[:space:]]|$)' requirements.txt
}

pyproject_runtime_deps_empty() {
  [[ -f pyproject.toml ]] || return 1
  python3 - <<'PY'
import pathlib
import re
import sys

text = pathlib.Path("pyproject.toml").read_text(encoding="utf-8")
match = re.search(r"dependencies\s*=\s*\[(.*?)\]", text, re.S)
if not match:
    sys.exit(1)
inner = re.sub(r"#.*", "", match.group(1)).strip()
sys.exit(0 if not inner else 1)
PY
}

activate_venv_path() {
  if [[ -d .venv ]]; then
    export VIRTUAL_ENV="${PWD}/.venv"
    export PATH="${VIRTUAL_ENV}/bin:${PATH}"
  fi
}

bootstrap_from_requirements() {
  local mode="$1"
  echo "uv-bootstrap: installing runtime deps from requirements.txt (${mode})..."

  rm -rf .venv
  uv venv

  if requirements_mentions_torch; then
    echo "uv-bootstrap: torch detected — using PyTorch cu124 index (${MLOPS_PYTORCH_INDEX})"
    uv pip install "${MLOPS_TORCH_CONSTRAINT}" \
      --index-url "${MLOPS_PYTORCH_INDEX}"
    uv pip install -r requirements.txt \
      --index-url "${MLOPS_PYPI_INDEX}" \
      --extra-index-url "${MLOPS_PYTORCH_INDEX}"
  else
    uv pip install -r requirements.txt
  fi

  if [[ -f setup.py ]]; then
    echo "uv-bootstrap: editable install (setup.py)"
    uv pip install -e .
  fi
}

verify_torch() {
  [[ "${UV_BOOTSTRAP_VERIFY_TORCH}" == "1" || "${UV_BOOTSTRAP_VERIFY_TORCH}" == "true" ]] || return 0

  if ! command -v python >/dev/null 2>&1; then
    echo "uv-bootstrap: skip torch verify (python not on PATH)"
    return 0
  fi

  python - <<'PY'
import sys

try:
    import torch
except ImportError:
    print("uv-bootstrap: no torch in project venv (base image may still provide conda torch)")
    sys.exit(0)

print("torch:", torch.__version__)
print("cuda build:", torch.version.cuda)
print("cuda available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("device count:", torch.cuda.device_count())
PY
}

main() {
  ensure_uv
  uv --version

  if [[ -f pyproject.toml && -f uv.lock ]]; then
    echo "uv-bootstrap: pyproject.toml + uv.lock → uv sync --frozen --dev"
    uv sync --frozen --dev
  elif [[ -f pyproject.toml && -f requirements.txt ]] && pyproject_runtime_deps_empty; then
    echo "uv-bootstrap: semi-migrated project (empty pyproject dependencies + requirements.txt)"
    bootstrap_from_requirements "semi-migrated"
    echo "uv-bootstrap: adding dev tools from pyproject.toml (--inexact keeps runtime packages)"
    UV_PROJECT_ENVIRONMENT=.venv uv sync --dev --no-install-project --inexact
  elif [[ -f requirements.txt ]]; then
    bootstrap_from_requirements "legacy"
  elif [[ -f pyproject.toml ]]; then
    echo "uv-bootstrap: pyproject.toml only → uv sync --dev"
    uv sync --dev
  else
    echo "uv-bootstrap: no dependency files; using base image Python environment only"
  fi

  activate_venv_path
  verify_torch
  echo "uv-bootstrap: done"
}

main "$@"
