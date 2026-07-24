# AI Coding Rules

**Language:** English | [Simplified Chinese](README.zh-CN.md)

Composable AI engineering **packs**. Default `init-ai` installs only the language-agnostic **core** pack. Everything else is added manually with `init-ai add <pack>`—no profiles.

Scope: **ordinary Python** and **DL / GPU** tracks. Domain frameworks (e.g. mjlab RL templates) stay upstream; this repo only injects `core` into those projects.

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

This applies only the `core` pack: `.cursor/rules/`, `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `MEMORY.md`, project context directories, and installs [mattpocock/skills](https://github.com/mattpocock/skills) (needs Node.js/`npx` + network). Core is language-agnostic (no Python/uv tooling).

After `init-ai`, run `/setup-matt-pocock-skills` once per repo in the agent if `docs/agents/` is missing. Agents are instructed to align/design with these skills before non-trivial code generation.

## Packs

| Pack | Command | What it adds | Does **not** add |
|------|---------|--------------|------------------|
| **core** | `init-ai` | Cursor/Claude rules, project memory, Matt Pocock skills install | Python, CI, Docker |
| **python-quality** | `init-ai add python-quality` | Ruff, Pyright, python-uv rules | CI, GPU, pre-commit hooks |
| **pre-commit-hooks** | `init-ai add pre-commit-hooks` | Optional local Git hooks (Ruff on commit, Pyright on push) | CI, GPU (auto-includes python-quality) |
| **ci-quality** | `init-ai add ci-quality` | GitHub/GitLab **quality** CI | GPU train (auto-includes python-quality, not pre-commit) |
| **mlops-gpu** | `init-ai add mlops-gpu` | Docker Compose, thin Dev Container, **train** CI, uv-bootstrap | quality CI, ruff (standalone pack) |

Automatic pack dependencies: `ci-quality` → `python-quality`; `pre-commit-hooks` → `python-quality`. Neither installs Git hooks automatically.

Preview before apply:

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## Two primary tracks

| Track | Steps |
|-------|--------|
| **Ordinary Python** | `init-ai` → `add python-quality` → (optional) `pre-commit-hooks` / `ci-quality` |
| **DL / GPU** | `init-ai` → `add mlops-gpu`; add `python-quality` / `ci-quality` only when you need lint/CI |

Other common scenarios:

| Scenario | Steps |
|----------|--------|
| Vue / frontend / docs | `init-ai` only |
| External RL (e.g. mjlab) | `init-ai` only (use upstream training stack; do not default to `mlops-gpu`) |
| Legacy GPU (e.g. BasicSR) | `init-ai` → `add mlops-gpu` |

**Legacy GPU tip:** `docker compose run --rm train uv run python ...` (never bare-metal ML on the host). See injected `docs/packs/mlops-gpu.zh-CN.md` for full ops.

## Three environments (Python + GPU)

| Environment | Install | Commands |
|-------------|---------|----------|
| **Host** (optional) | dev tools only, no torch | `.venv/bin/ruff` / `.venv/bin/pyright`; hooks via `pre-commit-hooks` pack |
| **Docker Compose / IDE** | GPU runtime + `.venv` in container | `docker compose run --rm train uv run python ...` or Reopen in Container |
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

Docker Compose, GPU training, and pack docs belong under `templates/mlops-gpu/`, not at the repository root.

Template hygiene check:

```bash
bash scripts/check-template-clean.sh
```

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
