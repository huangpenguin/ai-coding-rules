# Project Decisions

## Template Pack Architecture

- Use a single repository with composable `templates/<pack>/` packs, not a monorepo.
- Default `init-ai` applies only the `core` pack so legacy or research repositories can receive AI rules without Docker/CI/MLOps files.
- **No profiles** (e.g. no `research-gpu`). Users add packs manually; root README documents each pack and common composition paths.
- **Scope**: ordinary **Python** and **DL / GPU** tracks. Domain framework templates (RL such as mjlab, Isaac Lab, etc.) stay upstream; inject **core only** into those repos.
- Optional packs (each addable via `init-ai add <pack>` unless noted):
  - `core`: Language-agnostic `AGENTS.md`, Claude import, scoped Cursor rules, project memory, and project-local [mattpocock/skills](https://github.com/mattpocock/skills). Safe for Vue, frontend, docs, and mixed repos. `init-ai` installs the full skill set with Node.js/`npx` and network access.
  - `python-quality`: Python-only. Adds `python-uv.mdc`, `bilingual-comments.mdc`, Ruff, Pyright, and `.gitignore`. Does **not** add pre-commit. May run `uv init` and `uv add --dev ruff pyright` — do not use on non-Python projects.
  - `pre-commit-hooks`: Optional local Git hooks. Auto-includes `python-quality`. Adds `.pre-commit-config.yaml`, `setup-local-hooks.sh`, and `uv add --dev pre-commit`. Does **not** auto-install hooks.
  - `ci-quality`: GitHub Actions and GitLab **quality** CI. Auto-includes `python-quality` only. Root `.gitlab-ci.yml` is quality-only; default `QUALITY_CI_BLOCKING=false` (manual + allow_failure).
  - `mlops-gpu`: `docker-compose.yml` + `Dockerfile` (env source of truth), thin `.devcontainer/devcontainer.json` (IDE attach only), GitLab **train** CI, `uv-bootstrap.sh` + `ci_storage.py` (persistent CI outputs), `mlops-docker-compose.mdc`. **Standalone** — does not auto-include ci-quality or python-quality. Single injected pack doc: `docs/packs/mlops-gpu.zh-CN.md`. No wrapper scripts.
- Removed packs (do not reintroduce without a new decision):
  - `hf-space` (HF Space orphan-repo deploy) — out of Python/DL scope.
  - `mlflow-experimental` — unused stub.
- When both `ci-quality` and `mlops-gpu` are injected, the user merges root `.gitlab-ci.yml` manually (both `quality.yml` and `train.yml` includes). Later inject overwrites earlier root file.
- When `python-quality` runs and the target has no `pyproject.toml`, `init-ai` scaffolds a minimal one with `uv init` before `uv add --dev ruff pyright`. Legacy `requirements.txt` / `setup.py` files are left unchanged. `pre-commit-hooks` adds `pre-commit` separately.
- Python-specific Cursor rules live in `python-quality`, not `core`.
- Root-level Docker/MLOps files are template material under `templates/mlops-gpu/`, not at repository root.

## Recommended composition

- **Ordinary Python**: `init-ai` → `add python-quality` → optional `pre-commit-hooks` / `ci-quality`.
- **DL / GPU**: `init-ai` → `add mlops-gpu`; add `python-quality` / `ci-quality` only when lint/CI is needed.
- **External RL (mjlab, etc.)**: `init-ai` only (core). Do not default to `mlops-gpu` (avoids fighting the upstream training stack).

## Three-Environment Model (Python + GPU)

- **Host (optional)**: `uv sync --only-dev --no-install-project` via `scripts/setup-local-hooks.sh` when `pre-commit-hooks` pack is used; use `.venv/bin/pre-commit` / `.venv/bin/pyright`. Do not use `uv run` on host for GPU projects (implicit full sync including torch).
- **Docker Compose + Dev Container (local)**: `docker compose build` / `docker compose run --rm train uv run ...` or Reopen in Container; `postCreate` runs `uv-bootstrap.sh`. Never run ML Python on bare-metal host.
- **CI train**: `scripts/uv-bootstrap.sh` + `scripts/ci_storage.py` in GitLab GPU jobs; large checkpoints on NFS `/home` (or `.ci_storage/` fallback), small summaries via GitLab Artifacts.
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
- **Single validated image stack** everywhere: `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel` — local `build: .`, CI `MLOPS_GPU_IMAGE`, same Dockerfile `FROM`. No separate NGC/local default.
- Python package management in `pyproject.toml` + `uv.lock` (or legacy `requirements.txt`); synced by `uv-bootstrap.sh` into `/workspace/.venv` in the same container image.
- Current validated GPU stack: `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`, `torch 2.6.x + cu124`, cuDNN 9.x, NVIDIA V100 (`sm_70`, 32GB).
- Target project Python dependencies should pin torch to the validated minor series, e.g. `torch>=2.6.0,<2.7.0`; legacy installs use cu124 index via `uv-bootstrap.sh`.
- **Single bootstrap script**: `templates/mlops-gpu/managed/scripts/uv-bootstrap.sh` for Dev Container postCreate and GitLab GPU before_script.
- BasicSR / legacy GPU: `init-ai` then `init-ai add mlops-gpu`; add `ci-quality` and `python-quality` only when needed.

## Agent instructions and skills

- Keep always-loaded instructions in `AGENTS.md`; `CLAUDE.md` imports it. Cursor `.mdc` rules are reserved for scoped, tool-specific guidance. Do not distribute the legacy `.cursorrules` file.
- The core pack copies and runs `scripts/install-matt-pocock-skills.sh --all` in the target project. The injected script also accepts skill names for later selective refreshes. Installing skills does not require the agent to follow a fixed grill/spec/tickets/implement sequence.
- Existing projects are refreshed with `init-ai --update --apply`. It removes obsolete rules only when they are exact copies of former managed templates; custom versions remain for manual review.
- Per-repo issue and domain conventions may live in `docs/agents/` after `/setup-matt-pocock-skills` when a project needs them. This template repo uses GitHub issues + default triage labels + single-context domain docs.
- On other machines, `init-ai --update --apply` refreshes managed templates and the project-local skills after the wrapper pulls this repository.

## Consumer vs editor installs

- **Editor (one machine only)**: editable git checkout; commit and `git push github main && git push gitlab main`.
- **Consumers (all other machines)**: install with `install.sh` into `~/.ai-coding-rules` only. Do not edit or commit there.
- Consumer `init-ai` is a shell function that runs `git -C ~/.ai-coding-rules pull --ff-only` then `inject-ai.sh`. Re-running `install.sh` upgrades the wrapper and refreshes the clone.
- `--ff-only` fails loudly if a consumer clone was dirtied or diverged; fix by resetting to remote or re-cloning, never by merging on consumers.

## Git Remotes (maintainer checkout)

- `origin` → `git@github.com:huangpenguin/ai-coding-rules.git`
- `gitlab` → `git@gitlab.com:jil_atr/ai-coding-rules.git`
- After commits: `git push github main && git push gitlab main`
