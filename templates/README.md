# Template Packs

Files here are injected into **target projects** by `init-ai`. Edit pack content under `templates/<pack>/`, not at the repository root.

## Layout

```text
templates/<pack>/
  managed/    # Updated on init-ai --update (overwrites target)
  preserve/   # Created only when missing in target (never overwritten)
```

## Packs

| Pack | Purpose |
|------|---------|
| [core](core/) | Default: Cursor rules, `CLAUDE.md`, `.cursorrules`, memory scaffolding |
| [python-quality](python-quality/) | Ruff, Pyright, pre-commit, `.gitignore` |
| [ci-quality](ci-quality/) | GitHub Actions + GitLab quality CI (auto-includes python-quality) |
| [mlops-gpu](mlops-gpu/) | Docker, devcontainer, GPU Runner training, smoke test (auto-includes ci-quality) |
| [mlflow-experimental](mlflow-experimental/) | Reserved / experimental MLflow docs |

## Commands

```bash
init-ai                              # core only
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
init-ai profile research-gpu
init-ai add mlops-gpu --update --apply   # refresh managed files in target
```

Pack docs (injected into target `docs/`): see each pack under `managed/docs/`.
