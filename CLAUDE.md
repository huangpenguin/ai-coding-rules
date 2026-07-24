When working in this repository, follow these tools and conventions strictly.

CRITICAL: Before major architecture, debugging, or planning work, read `.cursor/project-context/` and `.cursor/lessons-learned/` when relevant. Also read root `MEMORY.md` only if it exists in a target project. Store stable project decisions in `.cursor/project-context/` and reusable failure lessons in `.cursor/lessons-learned/`.

# Global AI Coding Rules

- Reuse existing modules, components, configs, and project conventions before introducing new abstractions.
- Keep changes tightly scoped; avoid opportunistic refactors.
- Do not add silent fallbacks unless explicitly requested.
- Keep project memory files concise and agent-readable; never store secrets, credentials, tokens, or long transcripts in them.
- Follow the project's existing package manager and scripts (for example `package.json`, `Makefile`, `uv run`, or documented project commands).

## Matt Pocock AI skills (design before code)

- Skills install **into the project** (`.agents/skills/` / `.claude/skills/`), not user-global. Run `bash scripts/install-matt-pocock-skills.sh` if missing.
- Feature flow: `/setup-matt-pocock-skills` (once) → `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/implement`. Periodic: `/improve-codebase-architecture`.
- See `.cursor/rules/matt-pocock-skills.mdc`.

## Agent skills

### Issue tracker

Issues live in GitHub (`huangpenguin/ai-coding-rules`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `CONTEXT.md` + `docs/adr/`. See `docs/agents/domain.md`.
