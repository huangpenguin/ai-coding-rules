# AI Coding Rules

**Language:** English | [Simplified Chinese](README.zh-CN.md)

Reusable AI engineering template packs for any project. The default `init-ai` command installs only the language-agnostic **core** pack. All other capabilities are **separate packs** you add manually—there are no bundled profiles.

## Quick Start

Install once on a machine:

```bash
curl -fsSL https://raw.githubusercontent.com/huangpenguin/ai-coding-rules/main/install.sh | bash
source ~/.zshrc   # or source ~/.bashrc
```

Use in a project:

```bash
cd your-project
init-ai
```

This applies only the `core` pack: `.cursor/rules/`, `CLAUDE.md`, `.cursorrules`, `MEMORY.md`, and project context directories. Core is language-agnostic (no Python/uv tooling).

## Packs (add manually)

| Pack | Command | What it adds | Does **not** add |
|------|---------|--------------|------------------|
| **core** | `init-ai` | Cursor/Claude rules, project memory | Python, CI, Docker |
| **python-quality** | `init-ai add python-quality` | Ruff, Pyright, python-uv rules | CI, GPU, pre-commit hooks |
| **pre-commit-hooks** | `init-ai add pre-commit-hooks` | Optional local Git hooks (Ruff on commit, Pyright on push) | CI, GPU (auto-includes python-quality) |
| **ci-quality** | `init-ai add ci-quality` | GitHub/GitLab **quality** CI | GPU train (auto-includes python-quality, not pre-commit) |
| **mlops-gpu** | `init-ai add mlops-gpu` | Docker, devcontainer, **train** CI, uv-bootstrap | quality CI, ruff (standalone pack) |
| **hf-space** | `init-ai add hf-space` | HF Space deploy script | — |

Automatic pack dependencies: `ci-quality` → `python-quality`; `pre-commit-hooks` → `python-quality`. Neither installs Git hooks automatically.

Preview before apply:

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## Common paths (manual composition)

| Scenario | Steps |
|----------|--------|
| Vue / frontend / docs | `init-ai` only |
| Legacy research repo | `init-ai` only |
| Legacy GPU (e.g. BasicSR) | `init-ai` → `add mlops-gpu` |
| Modern Python | `init-ai` → `add python-quality` |
| CI lint on MR | … → `add ci-quality` |
| Local commit/push hooks | … → `add pre-commit-hooks` (optional) |
| HF Space deploy | … → `add hf-space` |

**Legacy GPU tip:** use Dev Container for tests/training (`uv-bootstrap.sh` installs torch). On the **host**, skip `uv sync --dev`. Local Git hooks are optional: `init-ai add pre-commit-hooks` then `setup-local-hooks.sh`.

## Three environments (Python + GPU)

| Environment | Install | Commands |
|-------------|---------|----------|
| **Host** (optional) | dev tools only, no torch | `.venv/bin/ruff` / `.venv/bin/pyright`; hooks via `pre-commit-hooks` pack |
| **Dev Container** | full runtime + dev | Rebuild → `scripts/uv-bootstrap.sh` → `uv run ...` |
| **CI train** | full runtime + dev | mlops-gpu `train.yml` |
| **CI quality** | dev (+ runtime if in lock) | ci-quality jobs; default manual + non-blocking |

Do **not** use `uv run` on the host for GPU projects—it triggers a full dependency sync including torch.

## Combine GitLab CI (quality + train)

`ci-quality` and `mlops-gpu` each inject a root `.gitlab-ci.yml` for **their own** jobs only. If you add **both**, the second inject overwrites the first—merge manually:

```yaml
stages:
  - quality
  - deploy

variables:
  FF_USE_FASTZIP: "true"
  UV_LINK_MODE: copy
  QUALITY_CI_BLOCKING: "false"   # true = strict quality gate

include:
  - local: .gitlab/ci/quality.yml
  - local: .gitlab/ci/train.yml
```

Set `QUALITY_CI_BLOCKING: "true"` when you want quality jobs to block MR/main automatically.

## Docs

- [Documentation index](docs/README.md) — links to canonical pack docs under `templates/`
- [BasicSR first-stage finetune](docs/use-cases/basicsr-finetune.zh-CN.md) — template-repo guide only

## Repository Layout

This repo is a **template distributor**, not a typical application project.

| Path | Role |
|------|------|
| `inject-ai.sh`, `install.sh` | Install and inject entrypoints |
| `templates/<pack>/` | **Canonical inject source** — edit here for target projects |
| `docs/` | Index + guides that stay in this repo only |
| `.cursorrules`, `CLAUDE.md`, `.cursor/` | Maintainer dogfooding for this repo |
| `pyproject.toml`, `ruff.toml`, `.gitlab-ci.yml`, `.github/` | **This repo's own CI** — not injected |

Docker, devcontainer, GPU training, and pack docs belong under `templates/mlops-gpu/`, not at the repository root.

## Template Repository Maintenance

This repo is mirrored on **GitHub** and **GitLab**. Configure both remotes once:

```bash
git remote add origin git@github.com:huangpenguin/ai-coding-rules.git   # skip if origin exists
git remote add gitlab git@gitlab.com:jil_atr/ai-coding-rules.git        # GitLab canonical path
git fetch --all
```

After commits on `main`, push to both:

```bash
git push origin main && git push gitlab main
```

`main` tracks `gitlab/main` by default on this maintainer checkout; use `git pull gitlab main` or `git pull origin main` after fetching both.
