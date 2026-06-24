# Project Decisions

## Template Pack Architecture

- Use a single repository with composable `templates/<pack>/` packs, not a monorepo.
- Default `init-ai` applies only the `core` pack so legacy or research repositories can receive AI rules without Docker/CI/MLOps files.
- Optional packs:
  - `core`: Language-agnostic Cursor / Claude rules and project memory. Safe for Vue, frontend, docs, and mixed repos.
  - `python-quality`: Python-only. Adds `python-uv.mdc`, `bilingual-comments.mdc`, Ruff, Pyright, pre-commit, and `.gitignore`. Git hooks: Ruff on commit; Pyright (`basic`) on pre-push; CI keeps Pyright `strict` via `pyrightconfig.json`. May run `uv init` and create `.venv` — do not use on non-Python projects.
  - `ci-quality`: GitHub Actions and GitLab quality CI. Auto-includes `python-quality`.
  - `mlops-gpu`: Docker, devcontainer, GitLab GPU Runner training, and smoke test. Auto-includes `ci-quality` (and thus `python-quality`).
  - `hf-space`: Hugging Face Space deploy via `git archive` + orphan repo + force push; excludes large local-only paths before push.
  - `mlflow-experimental`: reserved for future MLflow tracking experiments.
- When `python-quality` runs and the target has no `pyproject.toml`, `init-ai` scaffolds a minimal one with `uv init` before `uv add --dev ruff pyright pre-commit`. Legacy `requirements.txt` / `setup.py` files are left unchanged.
- Python-specific Cursor rules (`python-uv.mdc`, `bilingual-comments.mdc`) live in `python-quality`, not `core`. Existing Python repos that only ran `init-ai` before this split should run `init-ai add python-quality --update --apply`.
- Root-level Docker/MLOps files are template material and should live under `templates/mlops-gpu/`, not at repository root.

## Documentation Layout

- Keep root `README.md` / `README.zh-CN.md` as entry points.
- **`templates/<pack>/managed/docs/`** is the canonical source for pack docs; `init-ai` copies them into target projects.
- Root `docs/README.md` is an index only, plus guides that are not injected (e.g. BasicSR finetune).
- Do not duplicate pack docs under root `docs/packs/` or `docs/docker/`.
- Keep stable architecture and workflow decisions in `.cursor/project-context/`.
- Keep reusable bug or failure lessons in `.cursor/lessons-learned/`.

## GPU / Docker Defaults

- GitLab GPU training jobs default to a self-hosted Runner with `executor = "docker"` and tags `linux,docker,gpu`; server-specific runners can add `main_gpu`, `huang`, or another machine tag.
- The Docker executor GPU Runner must set `[runners.docker] gpus = "all"` and should mount shared datasets through runner volumes such as `/mnt/data:/data:ro`.
- `mlops-gpu` defaults to a GPU job container image (`MLOPS_GPU_IMAGE`) instead of running `docker build` / `docker run` inside CI.
- The default GPU job image is `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`.
- Python package management should live in target project files (`pyproject.toml` + `uv.lock` preferred; `requirements.txt` only as a migration path) and be synced by `uv` inside the job container unless a project registry image already bakes dependencies in.
- New DL repositories without environment files should still run the template smoke test on the default PyTorch/CUDA image before adding project-specific dependencies.
- For GPU Docker defaults, prefer a stable PyTorch CUDA 12.4 image for Ubuntu 24.04 + NVIDIA `570-server` or newer.
- Current validated GPU stack: `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`, `torch 2.6.x + cu124`, cuDNN 9.x, NVIDIA V100 (`sm_70`, 32GB).
- Target project Python dependencies should pin torch to the validated minor series, e.g. `torch>=2.6.0,<2.7.0`; avoid broad lower bounds such as `torch>=1.7`.
- BasicSR first-stage finetuning should usually use `init-ai` core-only first; add Docker/CI packs after the training command and environment needs are clearer.

## Git Remotes (maintainer checkout)

- `origin` → `git@github.com:huangpenguin/ai-coding-rules.git`
- `gitlab` → `git@gitlab.com:jil_atr/ai-coding-rules.git` (project moved from `huang.pengbin/ai-coding-rules`)
- After commits: `git push origin main && git push gitlab main`
