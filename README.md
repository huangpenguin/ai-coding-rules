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

- [Documentation index](docs/README.md)
- [Core pack](docs/packs/core.zh-CN.md)
- [Python quality pack](docs/packs/python-quality.zh-CN.md)
- [CI quality pack](docs/packs/ci-quality.zh-CN.md)
- [MLOps GPU pack](docs/packs/mlops-gpu.zh-CN.md)
- [Docker quickstart](docs/docker/quickstart.zh-CN.md)
- [BasicSR first-stage finetune](docs/use-cases/basicsr-finetune.zh-CN.md)

## Template Repository Maintenance

This repo is mirrored on **GitHub** (`origin`) and **GitLab** (`gitlab`). After commits on `main`, push to both remotes unless you explicitly want only one remote updated:

```bash
git push origin main && git push gitlab main
```
