# Repository guidance

This repository distributes template packs. Edit `templates/<pack>/` for files injected into other projects; root-level rules are for maintaining this repository.

- For pack behavior or architecture changes, consult `.cursor/project-context/decisions.md`. For a related recurring failure, consult `.cursor/lessons-learned/`. Record durable decisions or reusable failure lessons there when they arise.
- Preserve files under `templates/<pack>/preserve/` in consumer projects. Check template changes with `bash scripts/check-template-clean.sh`.
- Use project-local skills when a task calls for their workflow. No skill sequence is required for ordinary edits.
