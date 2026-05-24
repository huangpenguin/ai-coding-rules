# AI Coding Rules

**Language:** English | [Simplified Chinese](README.zh-CN.md)

Reusable AI coding rules and project bootstrap files for Python projects. The goal is to keep Cursor, Claude Code, local hooks, and CI aligned so that AI-generated changes follow the same engineering rules every time.

This repository is intentionally small. It works as a template that you clone once, keep updated, and inject into new or existing projects with one command.

## What It Includes

- Cursor rules in `.cursor/rules/`
- Project-specific agent notes in `.cursor/project-context/`
- Debugging lessons in `.cursor/lessons-learned/`
- Cross-agent guidance in `CLAUDE.md`
- Legacy Cursor compatibility through `.cursorrules`
- Ruff, Pyright, and pre-commit configuration
- GitHub PR template and CI workflow
- GitLab CI templates for quality checks and GPU Runner training dispatch
- Docker and devcontainer templates for reproducible GPU development
- `docs/` for supplementary guides, including the MLOps acceptance checklist
- `inject-ai.sh`, a script that copies the template into the current project
- `install.sh`, a one-time bootstrap script that clones the template and configures the `init-ai` alias

The default rules are biased toward modern Python projects that use `uv`, type hints, Ruff, and Pyright. Reinforcement learning conventions are included as an optional, scoped rule instead of a global assumption.

## Setup

Run this once on a new machine. It clones the template to `~/.ai-coding-rules` and adds the `init-ai` alias to your shell config:

```bash
curl -fsSL https://raw.githubusercontent.com/huangpenguin/ai-coding-rules/main/install.sh | bash
```

Then reload your shell:

```bash
source ~/.zshrc   # or source ~/.bashrc
```

After that, use `init-ai` from any project directory. You do not need to run the curl command again when the template changes.

### Update the template later

When this repository changes, update your local template copy with Git:

```bash
cd ~/.ai-coding-rules
git pull
```

Then sync an existing project:

```bash
cd your-project
init-ai --update --dry-run
init-ai --update --apply
```

### Manual setup (optional)

If you prefer not to use `install.sh`:

```bash
git clone https://github.com/huangpenguin/ai-coding-rules.git ~/.ai-coding-rules
bash ~/.ai-coding-rules/install.sh
```

You can also run the injector directly without an alias:

```bash
bash ~/.ai-coding-rules/inject-ai.sh
```

## Usage

### Start a New Project

Use this when you are creating a new Python project from scratch.

```bash
mkdir my-new-python
cd my-new-python
uv init
git init
init-ai
```

What happens:

- AI rules are copied into `.cursor/rules/`, `CLAUDE.md`, and `.cursorrules`.
- Ruff, Pyright, pre-commit, GitHub/GitLab CI, Docker, devcontainer, and PR templates are copied in.
- Because `pyproject.toml` exists, `uv add --dev ruff pyright pre-commit` is run.
- Because `.git` exists, `uv run pre-commit install` is run.

Then open the project in Cursor or Claude Code and ask the agent to follow the local rules.

### Add Rules to a Modern Project

Use this when a cloned project already has a `pyproject.toml`.

```bash
git clone https://github.com/someone/cool-python.git
cd cool-python
init-ai
uv sync
```

This keeps the upstream project dependencies managed by `uv` while adding your local AI engineering rules and checks.

### Safely Update an Existing Project

Use update mode after you have already run `init-ai` once in a project.

Preview the changes first:

```bash
init-ai --update --dry-run
```

The preview uses simple status labels instead of raw diffs:

- `ADD`: the file does not exist and would be created.
- `UPDATE`: the managed template file differs and would be replaced.
- `SKIP`: the file is already up to date.
- `PRESERVE`: project-specific content exists and will not be overwritten.

Apply the update only after the preview looks right:

```bash
init-ai --update --apply
```

Update mode preserves `MEMORY.md`, `.cursor/project-context/`, `.cursor/lessons-learned/`, and an existing project `train.py`. It updates managed template files such as `.cursor/rules/*.mdc`, `CLAUDE.md`, `.cursorrules`, Ruff, Pyright, pre-commit, GitHub/GitLab workflow files, Dockerfile, and devcontainer files.

### Add Rules to a Legacy Project

Use this when an older project only has `requirements.txt` or has no modern Python metadata.

```bash
git clone https://github.com/old/legacy-rl.git
cd legacy-rl
uv venv
uv pip install -r requirements.txt
init-ai
```

If there is no `pyproject.toml`, the script skips `uv add --dev ...` so it does not rewrite the old project's dependency metadata. It still copies the AI rule files and shared configuration files.

### Daily Workflow

Ask the AI agent to make a change, then commit normally:

```bash
git add .
git commit -m "feat: add value network"
```

If pre-commit fails, copy the full error output back into Cursor or Claude Code and ask it to fix the reported issues. The local rules are designed to make those fixes consistent instead of relying on repeated manual prompts.

### Reinforcement Learning Projects

RL conventions live in `.cursor/rules/rl-conventions.mdc` and are not always-on. They apply when the task or files are clearly RL-related, such as PPO/DQN/SAC code, rollout/replay logic, training scripts, policies, value networks, or similar files.

For an RL project, write that fact in `.cursor/project-context/overview.md`, for example:

```markdown
This is a reinforcement learning project. Apply `.cursor/rules/rl-conventions.mdc` when working on training, models, rollout, replay, evaluation, or logging.
```

Non-RL projects can keep the rule file without deleting it; it should stay inactive unless the task becomes RL-related.

### MLOps / GPU Runner Projects

The template includes a minimal GPU training scaffold: `Dockerfile`, `.devcontainer/`, GitLab CI (`.gitlab-ci.yml`, `.gitlab/ci/`), and `train.py`. Training is dispatched to a self-hosted Runner tagged `gpu-server` via manual Play in GitLab or a commit message containing `[run train]`.

For setup, acceptance, Runner registration, Docker smoke tests, and devcontainer steps, see [docs/MLOPS-CHECKLIST.md](docs/MLOPS-CHECKLIST.md).

## Configuration

The main configurable parts are:

- `.cursor/rules/*.mdc`: Cursor project rules. Use these for focused behavior such as Python, optional RL conventions, communication language, and README structure.
- `.cursor/project-context/`: short project-specific notes for agents, such as architecture, active plans, and stable decisions.
- `.cursor/lessons-learned/`: short notes about bugs, failed attempts, root causes, and fixes that future agents should check.
- `CLAUDE.md`: portable instructions for Claude Code and other agents that read repository-level guidance.
- `.cursorrules`: compatibility file for older Cursor workflows.
- `ruff.toml`: Ruff linting and formatting rules.
- `pyrightconfig.json`: Pyright type-checking rules.
- `.pre-commit-config.yaml`: local commit-time checks.
- `.github/workflows/ci.yml`: GitHub CI checks.
- `.gitlab-ci.yml`, `.gitlab/ci/quality.yml`, and `.gitlab/ci/train.yml`: GitLab quality checks and GPU Runner training dispatch.
- `docs/`: supplementary documentation, including the MLOps acceptance checklist.
- `Dockerfile` and `.devcontainer/devcontainer.json`: shared GPU development and training environment.
- `.github/PULL_REQUEST_TEMPLATE.md`: PR description template.

The injection script assumes it is run from the target project root. Use plain `init-ai` for first-time setup, and use `init-ai --update --dry-run` before applying updates in an existing project.

Keep project memory files concise. They are for agent recall, not long documentation or transcripts. Never store secrets or credentials there.

## Maintaining This Template Repository

This repo is mirrored on **GitHub** (`origin`) and **GitLab** (`gitlab`). After you commit on `main`, push to **both** remotes unless you explicitly want a single-remote update:

```bash
git push origin main
git push gitlab main
```

One-liner:

```bash
git push origin main && git push gitlab main
```

If you ask an AI agent to push changes for this repository, say **“push to both GitHub and GitLab”** (or name the remotes). Do not assume a single `git push` is enough—`main` may track only one remote, and the other mirror can drift.

If remotes have diverged and you have confirmed which side is canonical, use `git push --force-with-lease <remote> main` on the outdated remote only after reviewing the diff.


