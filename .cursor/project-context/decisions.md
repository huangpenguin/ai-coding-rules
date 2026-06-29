# Project Decisions

## Template Pack Architecture

- Use a single repository with composable `templates/<pack>/` packs, not a monorepo.
- Default `init-ai` applies only the `core` pack so legacy or research repositories can receive AI rules without Docker/CI/MLOps files.
- **No profiles** (e.g. no `research-gpu`). Users add packs manually; root README documents each pack and common composition paths.
- Optional packs (each addable via `init-ai add <pack>` unless noted):
  - `core`: Language-agnostic Cursor / Claude rules and project memory. Safe for Vue, frontend, docs, and mixed repos.
  - `python-quality`: Python-only. Adds `python-uv.mdc`, `bilingual-comments.mdc`, Ruff, Pyright, and `.gitignore`. Does **not** add pre-commit. May run `uv init` and `uv add --dev ruff pyright` — do not use on non-Python projects.
  - `pre-commit-hooks`: Optional local Git hooks. Auto-includes `python-quality`. Adds `.pre-commit-config.yaml`, `setup-local-hooks.sh`, and `uv add --dev pre-commit`. Does **not** auto-install hooks.
  - `ci-quality`: GitHub Actions and GitLab **quality** CI. Auto-includes `python-quality` only. Root `.gitlab-ci.yml` is quality-only; default `QUALITY_CI_BLOCKING=false` (manual + allow_failure).
  - `mlops-gpu`: Docker, devcontainer, GitLab **train** CI, `uv-bootstrap.sh`. **Standalone** — does not auto-include ci-quality or python-quality.
  - `hf-space`: Hugging Face Space deploy via `git archive` + orphan repo + force push.
  - `mlflow-experimental`: reserved for future MLflow tracking experiments.
- When both `ci-quality` and `mlops-gpu` are injected, the user merges root `.gitlab-ci.yml` manually (both `quality.yml` and `train.yml` includes). Later inject overwrites earlier root file.
- When `python-quality` runs and the target has no `pyproject.toml`, `init-ai` scaffolds a minimal one with `uv init` before `uv add --dev ruff pyright`. Legacy `requirements.txt` / `setup.py` files are left unchanged. `pre-commit-hooks` adds `pre-commit` separately.
- Python-specific Cursor rules live in `python-quality`, not `core`.
- Root-level Docker/MLOps files are template material under `templates/mlops-gpu/`, not at repository root.

## Three-Environment Model (Python + GPU)

- **Host (optional)**: `uv sync --only-dev --no-install-project` via `scripts/setup-local-hooks.sh` when `pre-commit-hooks` pack is used; use `.venv/bin/pre-commit` / `.venv/bin/pyright`. Do not use `uv run` on host for GPU projects (implicit full sync including torch).
- **Dev Container / CI train**: `scripts/uv-bootstrap.sh` — full runtime + dev.
- **CI quality**: `ci-quality` jobs; optional strict gate via `QUALITY_CI_BLOCKING=true`.

## Documentation Layout

- Keep root `README.md` / `README.zh-CN.md` as entry points with pack table and manual composition.
- **`templates/<pack>/managed/docs/`** is the canonical source for pack docs; `init-ai` copies them into target projects.
- Root `docs/README.md` is an index only, plus guides that are not injected.
- Keep stable architecture and workflow decisions in `.cursor/project-context/`.
- Keep reusable bug or failure lessons in `.cursor/lessons-learned/`.

## GPU / Docker Defaults

- GitLab GPU training jobs default to a self-hosted Runner with `executor = "docker"` and tags `linux,docker,gpu`.
- The Docker executor GPU Runner must set `[runners.docker] gpus = "all"` and should mount shared datasets through runner volumes such as `/mnt/data:/data:ro`.
- `mlops-gpu` defaults to a GPU job container image (`MLOPS_GPU_IMAGE`) instead of running `docker build` / `docker run` inside CI.
- The default GPU job image is `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`.
- Python package management should live in target project files (`pyproject.toml` + `uv.lock` preferred; `requirements.txt` only as a migration path) and be synced by `uv-bootstrap.sh` inside devcontainer and train jobs.
- Current validated GPU stack: `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`, `torch 2.6.x + cu124`, cuDNN 9.x, NVIDIA V100 (`sm_70`, 32GB).
- Target project Python dependencies should pin torch to the validated minor series, e.g. `torch>=2.6.0,<2.7.0`; legacy installs use cu124 index via `uv-bootstrap.sh`.
- **Single bootstrap script**: `templates/mlops-gpu/managed/scripts/uv-bootstrap.sh` for devcontainer postCreate and GitLab GPU before_script.
- BasicSR / legacy GPU: `init-ai` then `init-ai add mlops-gpu`; add `ci-quality` and `python-quality` only when needed.

## Git Remotes (maintainer checkout)

- `origin` → `git@github.com:huangpenguin/ai-coding-rules.git`
- `gitlab` → `git@gitlab.com:jil_atr/ai-coding-rules.git`
- After commits: `git push origin main && git push gitlab main`
