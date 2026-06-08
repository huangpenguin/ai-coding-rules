# Project Decisions

## Template Pack Architecture

- Use a single repository with composable `templates/<pack>/` packs, not a monorepo.
- Default `init-ai` applies only the `core` pack so legacy or research repositories can receive AI rules without Docker/CI/MLOps files.
- Optional packs:
  - `core`: Cursor / Claude rules and project memory.
  - `python-quality`: Ruff, Pyright, pre-commit, and `.gitignore`.
  - `ci-quality`: GitHub Actions and GitLab quality CI.
  - `mlops-gpu`: Docker, devcontainer, GitLab GPU Runner training, and smoke test.
  - `mlflow-experimental`: reserved for future MLflow tracking experiments.
- Root-level Docker/MLOps files are template material and should live under `templates/mlops-gpu/`, not at repository root.

## Documentation Layout

- Keep root `README.md` / `README.zh-CN.md` as entry points.
- Keep operational docs under `docs/`.
- Keep stable architecture and workflow decisions in `.cursor/project-context/`.
- Keep reusable bug or failure lessons in `.cursor/lessons-learned/`.

## GPU / Docker Defaults

- GitLab GPU training jobs require a self-hosted Runner with `executor = "shell"` and tag `gpu-server`.
- Docker executor runs inside a temporary job container and cannot call the host Docker/GPU setup reliably.
- For GPU Docker defaults, prefer a stable PyTorch CUDA 12.4 image for Ubuntu 24.04 + NVIDIA `570-server` or newer.
- BasicSR first-stage finetuning should usually use `init-ai` core-only first; add Docker/CI packs after the training command and environment needs are clearer.
