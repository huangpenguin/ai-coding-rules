# Template Packs

Files here are injected into **target projects** by `init-ai`. Edit pack content under `templates/<pack>/`, not at the repository root.

## Layout

```text
templates/<pack>/
  managed/    # Updated on init-ai --update (overwrites target)
  preserve/   # Created only when missing in target (never overwritten)
```

## Packs

| Pack | Purpose | Standalone? |
|------|---------|-------------|
| [core](core/) | Default: Cursor rules, `CLAUDE.md`, `.cursorrules`, memory | Yes |
| [python-quality](python-quality/) | Ruff, Pyright, python-uv rules | Yes |
| [pre-commit-hooks](pre-commit-hooks/) | Optional local Git hooks (Ruff + Pyright pre-push) | Pulls in python-quality only |
| [ci-quality](ci-quality/) | GitHub/GitLab **quality** CI | Pulls in python-quality only |
| [mlops-gpu](mlops-gpu/) | Docker, devcontainer, **train** CI, uv-bootstrap | Yes |
| [hf-space](hf-space/) | Hugging Face Space deploy | Yes |
| [mlflow-experimental](mlflow-experimental/) | Reserved / experimental MLflow docs | Yes |

There are **no profiles**. Users add packs manually; see root README for composition examples and GitLab CI merge instructions.

## Commands

```bash
init-ai                              # core only
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
init-ai add ci-quality --apply       # also applies python-quality
init-ai add pre-commit-hooks --apply # also applies python-quality; optional git hooks
init-ai add mlops-gpu --update --apply
```

Pack docs (injected into target `docs/`): see each pack under `managed/docs/`.
