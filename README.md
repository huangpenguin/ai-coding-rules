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
init-ai add ci-quality           # GitHub Actions + GitLab quality CI
init-ai add mlops-gpu            # Docker, devcontainer, GitLab GPU Runner, smoke test
init-ai profile research-gpu     # core + python-quality + ci-quality + mlops-gpu
```

Preview first:

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## Common Use Cases

- **Legacy or research repo, e.g. BasicSR first-stage finetune:** run `init-ai` only. Add Docker/CI later if needed.
- **Modern Python project:** run `init-ai`, then `init-ai add python-quality`.
- **Project with GitHub/GitLab quality checks:** add `ci-quality`.
- **GPU training project on your lab server:** add `mlops-gpu` or use `profile research-gpu`.

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

This repo is mirrored on **GitHub** (`origin`) and **GitLab** (`gitlab`). After commits on `main`, push to both remotes unless you explicitly want only one remote updated:

```bash
git push origin main && git push gitlab main
```
