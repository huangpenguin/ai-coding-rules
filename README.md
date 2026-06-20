# AI Coding Rules

**Language:** English | [Simplified Chinese](README.zh-CN.md)

Reusable AI engineering template packs for Python projects. The default `init-ai` command installs only the core Cursor / Claude rules and project memory files. Python quality checks, CI, Docker, GPU Runner training, and future MLOps features are opt-in packs.

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

This applies only the `core` pack: `.cursor/rules/`, `CLAUDE.md`, `.cursorrules`, `MEMORY.md`, and project context directories.

## Optional Packs

```bash
init-ai add python-quality       # Ruff, Pyright, pre-commit, .gitignore
init-ai add ci-quality           # GitHub/GitLab quality CI (auto-includes python-quality)
init-ai add mlops-gpu            # Docker, devcontainer, GPU Runner (auto-includes ci-quality)
init-ai add hf-space             # HF Space deploy: clean git archive + force push
init-ai profile research-gpu     # core + mlops-gpu (pulls python-quality and ci-quality)
```

Pack dependencies are applied automatically: `ci-quality` → `python-quality`; `mlops-gpu` → `ci-quality` → `python-quality`. If the target has no `pyproject.toml`, `init-ai` scaffolds one with `uv init` before installing dev tools. Legacy `requirements.txt` / `setup.py` files are left unchanged.

Preview first:

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## Common Use Cases

- **Legacy or research repo, e.g. BasicSR first-stage finetune:** run `init-ai` only. Add Docker/CI later if needed.
- **Modern Python project:** run `init-ai`, then `init-ai add python-quality`.
- **Project with GitHub/GitLab quality checks:** add `ci-quality` (includes python-quality and dev deps for CI).
- **GPU training project on your lab server:** add `mlops-gpu` or use `profile research-gpu`.
- **Hugging Face Space with local-only large files:** add `hf-space`; exclude paths via `DEPLOY_EXCLUDE_PATHS`.

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
