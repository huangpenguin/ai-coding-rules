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

**Editor machine** (exactly one): keep a normal git checkout and push to both configured remotes. Consumers only pull.

This applies only the language-agnostic `core` pack: a concise `AGENTS.md`, a Claude import of that file, scoped Cursor rules, project memory, and an optional skills installer. It needs no Node.js or network access beyond the template pull.

`init-ai --update --apply` refreshes managed rules and removes obsolete rules only when their contents exactly match the former template. Custom versions stay untouched.

**Optional skills:** run `bash scripts/install-matt-pocock-skills.sh` inside a project only when those workflows help. This needs Node.js/`npx` and network access. It refreshes `.agents/skills/` and `.claude/skills/` from upstream; review local edits before rerunning it. `init-ai` does not install or refresh skills automatically.

## Matt Pocock skills (optional)

Source: [mattpocock/skills](https://github.com/mattpocock/skills). Install is project-local. Use a relevant skill when its workflow helps; ordinary edits do not need the full sequence.

### Main feature flow (idea → ship)

| Skill | When | What it does |
|-------|------|----------------|
| `/setup-matt-pocock-skills` | When the project needs shared issue and domain conventions | Configure issue tracker, triage labels, domain doc layout (`docs/agents/`) |
| `/grill-with-docs` | Requirements are unclear in an existing codebase | Clarify requirements and capture shared language (`CONTEXT.md` / ADRs) |
| `/grill-me` | No codebase / non-code plans | Same interview as above, but **stateless** (no local docs) |
| `/to-spec` | After grilling, when the thread is ready | Synthesize a **spec** (business logic; no implementation code) onto the issue tracker |
| `/to-tickets` | Right before coding | Split plan/spec into tracer-bullet tickets with blocking edges |
| `/implement` | Per ticket (fresh context each time) | TDD via `/tdd`, then `/code-review`, then commit |

Use only the steps the task needs; a small change can go directly to implementation.

### On-ramps & maintenance

| Skill | When | What it does |
|-------|------|----------------|
| `/ask-matt` | Unsure which skill/flow | Router over the user-invoked skills |
| `/triage` | Incoming bugs/requests you didn't create | Move issues through triage roles → agent-ready |
| `/diagnosing-bugs` | Hard / intermittent / regression bugs | Reproduce → minimise → hypothesise → instrument → fix → regression test |
| `/improve-codebase-architecture` | When intentionally reviewing architecture | Scan for shallow modules → HTML report → deepen |
| `/wayfinder` | Huge foggy work spanning many sessions | Shared map of investigation tickets until the path is clear → then `/to-spec` |
| `/tdd` | Build one behaviour test-first without a full spec | Red-green-refactor loop |
| `/code-review` | Review a branch/PR since a fixed point | Standards + Spec axes (parallel) |
| `/handoff` | Context full or need a fresh session | Compact thread to a markdown file for the next agent |

Full reference and philosophy: upstream [README](https://github.com/mattpocock/skills/blob/main/README.md).

## Packs

| Pack | Command | What it adds | Does **not** add |
|------|---------|--------------|------------------|
| **core** | `init-ai` | Agent rules, project memory, optional skills installer | Python, CI, Docker |
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
| `AGENTS.md`, `CLAUDE.md`, `.cursor/` | Maintainer instructions for this repo |
| `pyproject.toml`, `ruff.toml`, `.gitlab-ci.yml`, `.github/` | **This repo's own CI** — not injected |

Docker Compose, GPU training, and pack docs belong under `templates/mlops-gpu/`, not at the repository root.

Template hygiene check:

```bash
bash scripts/check-template-clean.sh
```

## Template Repository Maintenance

This repo is mirrored on **GitHub** and **GitLab**. Configure both remotes once:

```bash
git remote add github git@github.com:huangpenguin/ai-coding-rules.git   # skip if github exists
git remote add gitlab git@gitlab.com:jil_atr/ai-coding-rules.git        # GitLab canonical path
git fetch --all
```

After commits on `main`, push to both:

```bash
git push github main && git push gitlab main
```

`main` tracks `gitlab/main` by default on this maintainer checkout; use `git pull gitlab main` or `git pull github main` after fetching both.
