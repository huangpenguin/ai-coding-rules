# AI Coding Rules

**Language:** English | [Simplified Chinese](README.zh-CN.md)

Composable AI engineering **packs**. Default `init-ai` installs only the language-agnostic **core** pack. Everything else is added manually with `init-ai add <pack>`—no profiles.

Scope: **ordinary Python** and **DL / GPU** tracks. Domain frameworks (e.g. mjlab RL templates) stay upstream; this repo only injects `core` into those projects.

## Quick Start

**Consumer machines** (every host except the single editor): install once; never edit or commit inside the install dir.

```bash
curl -fsSL https://raw.githubusercontent.com/huangpenguin/ai-coding-rules/main/install.sh | bash
source ~/.zshrc   # or source ~/.bashrc
```

`init-ai` auto-runs `git pull --ff-only` on `~/.ai-coding-rules` before injecting.

Use in a project:

```bash
cd your-project
init-ai
```

**Editor machine** (exactly one): keep a normal git checkout and `git push origin main && git push gitlab main`. Consumers only pull.

This applies only the `core` pack: `.cursor/rules/`, `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `MEMORY.md`, project context directories, and installs [mattpocock/skills](https://github.com/mattpocock/skills) (needs Node.js/`npx` + network). Core is language-agnostic (no Python/uv tooling).

After `init-ai`, run `/setup-matt-pocock-skills` once per repo in the agent if `docs/agents/` is missing. Agents are instructed to align/design with these skills before non-trivial code generation.

**Skills update:** re-running `init-ai` / `init-ai --update --apply` (or `bash scripts/install-matt-pocock-skills.sh`) refreshes project-local skills from upstream into `.agents/skills/` and `.claude/skills/` (**overwrite/copy**; does **not** wipe the rest of the project). Local edits inside those skill folders are replaced. Files removed upstream may linger until you delete them manually. `docs/agents/` and other project files are left alone.

## Matt Pocock skills (manual invoke)

Source: [mattpocock/skills](https://github.com/mattpocock/skills). Install is **project-local** (not global). Type the slash command (or name the skill) in Cursor / Claude Code.

### Main feature flow (idea → ship)

| Skill | When | What it does |
|-------|------|----------------|
| `/setup-matt-pocock-skills` | **Once** per repo, before other engineering skills | Configure issue tracker, triage labels, domain doc layout (`docs/agents/`) |
| `/grill-with-docs` | Have a codebase; start of almost every change | Relentless interview + builds shared language (`CONTEXT.md` / ADRs) |
| `/grill-me` | No codebase / non-code plans | Same interview as above, but **stateless** (no local docs) |
| `/to-spec` | After grilling, when the thread is ready | Synthesize a **spec** (business logic; no implementation code) onto the issue tracker |
| `/to-tickets` | Right before coding | Split plan/spec into tracer-bullet tickets with blocking edges |
| `/implement` | Per ticket (fresh context each time) | TDD via `/tdd`, then `/code-review`, then commit |

Keep grill → spec → tickets in **one** session when possible; clear context between each `/implement`.

### On-ramps & maintenance

| Skill | When | What it does |
|-------|------|----------------|
| `/ask-matt` | Unsure which skill/flow | Router over the user-invoked skills |
| `/triage` | Incoming bugs/requests you didn't create | Move issues through triage roles → agent-ready |
| `/diagnosing-bugs` | Hard / intermittent / regression bugs | Reproduce → minimise → hypothesise → instrument → fix → regression test |
| `/improve-codebase-architecture` | Every few days / spare moment | Scan for shallow modules → HTML report → deepen |
| `/wayfinder` | Huge foggy work spanning many sessions | Shared map of investigation tickets until the path is clear → then `/to-spec` |
| `/tdd` | Build one behaviour test-first without a full spec | Red-green-refactor loop |
| `/code-review` | Review a branch/PR since a fixed point | Standards + Spec axes (parallel) |
| `/handoff` | Context full or need a fresh session | Compact thread to a markdown file for the next agent |

Full reference and philosophy: upstream [README](https://github.com/mattpocock/skills/blob/main/README.md).

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
