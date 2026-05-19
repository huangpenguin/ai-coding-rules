# AI Coding Rules

**Language / 语言:** [English](README.md) | 简体中文

这是一个给 Python 项目使用的 AI 工程化规则模板。它的目标是：把 Cursor、Claude Code、本地代码检查、Git hook 和 CI 尽量统一起来，让 AI 改代码时不需要每次都重复提醒“请用 uv”“请写类型标注”“请遵守 Ruff/Pyright”。

你可以把它理解成一套可复用的项目启动包：先把这个仓库克隆到本地固定位置，之后新建项目或接手旧项目时，运行一个命令就能把规则注入进去。

## 包含内容

- `.cursor/rules/`：Cursor 的项目规则，使用 `.mdc` 文件组织。
- `.cursor/project-context/`：每个项目自己的 Agent 上下文，例如架构、当前计划、稳定决策。
- `.cursor/lessons-learned/`：项目错题本，用来记录 bug、失败尝试、根因和修复方式。
- `CLAUDE.md`：给 Claude Code 或其他支持仓库级说明的 Agent 使用。
- `.cursorrules`：兼容旧版 Cursor 规则读取方式。
- `ruff.toml`：Ruff lint / format 配置。
- `pyrightconfig.json`：Pyright 类型检查配置。
- `.pre-commit-config.yaml`：提交前自动检查。
- `.github/`：GitHub PR 模板和 CI 工作流。
- `inject-ai.sh`：把以上文件复制到当前项目的注入脚本。

这套规则默认偏向现代 Python 项目：使用 `uv` 管理环境和依赖，写明确的 Type Hints，优先用 Ruff 和 Pyright。RL 规则是可选的 scoped rule，不再作为所有项目的全局假设。

## 初始安装

先把这个仓库克隆到一个固定位置，例如：

```bash
git clone https://github.com/huangpenguin/ai-coding-rules.git ~/.ai-coding-rules
```

然后设置一个别名，让你在任意项目目录都能运行 `init-ai`。

如果你当前 Shell 是 `zsh`：

```bash
echo 'alias init-ai="bash ~/.ai-coding-rules/inject-ai.sh"' >> ~/.zshrc
source ~/.zshrc
```

如果你当前 Shell 是 `bash`：

```bash
echo 'alias init-ai="bash ~/.ai-coding-rules/inject-ai.sh"' >> ~/.bashrc
source ~/.bashrc
```

如果你经常在 `bash` 和 `zsh` 之间切换，可以把别名统一写到 `~/.bashrc`，再让 `zsh` 读取它：

```bash
echo '[ -f ~/.bashrc ] && source ~/.bashrc' >> ~/.zshrc
```

这样以后只需要维护一份 `~/.bashrc` 里的别名。

如果是另一台已经配置过别名、且模板仓库路径仍然是 `~/.ai-coding-rules` 的服务器，只需要进入模板仓库执行 `git pull` 更新即可，不需要重复设置别名。新服务器或路径不同的服务器仍然需要先 clone 并设置一次 alias；也可以不设 alias，直接运行 `bash /path/to/ai-coding-rules/inject-ai.sh`。

## 使用场景

### 场景一：从零创建新项目

适合你准备新写一个 Python 项目。

```bash
mkdir my-new-python
cd my-new-python
uv init
git init
init-ai
```

执行后会发生这些事：

- 复制 `.cursor/rules/`、`CLAUDE.md` 和 `.cursorrules`，让 Cursor / Claude Code 读取你的 AI 开发规范。
- 复制 Ruff、Pyright、pre-commit、GitHub CI 和 PR 模板。
- 因为项目里有 `pyproject.toml`，脚本会执行 `uv add --dev ruff pyright pre-commit`。
- 因为项目里有 `.git`，脚本会执行 `uv run pre-commit install`，安装提交前检查。

之后就可以打开 Cursor，直接让 Agent 根据项目规则生成代码，例如：“根据本项目规范，帮我写一个 CLI 工具脚手架。”

### 场景二：接手现代开源项目

适合你克隆了一个比较新的项目，根目录已经有 `pyproject.toml`。

```bash
git clone https://github.com/someone/cool-python.git
cd cool-python
init-ai
uv sync
```

这样会把你的 AI 规则和本地检查工具加入项目，同时仍然使用原项目的 `pyproject.toml` 和 `uv` 工作流管理依赖。

### 场景三：安全更新已有项目

适合你已经执行过 `init-ai`，并且项目里可能已经手动追加过 `.mdc`、计划文件或项目笔记。

先预览，不写入：

```bash
init-ai --update --dry-run
```

预览不会输出难读的完整 diff，而是显示简单状态：

- `ADD`：目标项目没有这个文件，会新增。
- `UPDATE`：模板管理的文件不同，会更新。
- `SKIP`：文件已经一致，不需要处理。
- `PRESERVE`：这是项目私有内容，会保留，不覆盖。

确认没问题后再应用：

```bash
init-ai --update --apply
```

更新模式会保留 `MEMORY.md`、`.cursor/project-context/` 和 `.cursor/lessons-learned/`。它只更新模板管理的内容，例如 `.cursor/rules/*.mdc`、`CLAUDE.md`、`.cursorrules`、Ruff、Pyright、pre-commit 和 GitHub workflow。

注意：首次执行的 `init-ai` 仍然适合新项目或你明确希望套用模板的项目。对已经个性化过的项目，优先使用 `--update --dry-run`。

### 场景四：接手旧项目

适合导师、课程、论文代码或早期 GitHub 项目，可能只有 `requirements.txt`，没有 `pyproject.toml`。

```bash
git clone https://github.com/old/legacy-rl.git
cd legacy-rl
uv venv
uv pip install -r requirements.txt
init-ai
```

如果脚本没有检测到 `pyproject.toml`，它会跳过 `uv add --dev ruff pyright pre-commit`，避免强行改写旧项目的依赖结构。但它仍然会复制 AI 规则文件和共享配置文件，让 Agent 在阅读和修改旧代码时遵守你的开发习惯。

### 场景五：日常 AI 结对编程

平时写代码、改 bug、做 PR 时，可以按这个节奏来：

```bash
git add .
git commit -m "feat: add value network"
```

如果 pre-commit 报错，例如 Ruff 发现未使用的 import，或者 Pyright 发现类型不匹配，不需要自己一点点猜。把完整报错贴回 Cursor 或 Claude Code，并要求它“根据 pre-commit 报错修复”。因为规则已经在项目里，Agent 会更容易按同一套标准修。

### 场景六：强化学习（RL）项目

RL 规则放在 `.cursor/rules/rl-conventions.mdc`，不是 always-on。只有当任务或文件明显和 RL 相关时才应用，例如 PPO/DQN/SAC、rollout/replay、training script、policy、value network、eval、logging 等。

如果当前项目是 RL 项目，建议在 `.cursor/project-context/overview.md` 里写一句：

```markdown
本项目是 reinforcement learning 项目。处理 training、model、rollout、replay、eval、logging 时应用 `.cursor/rules/rl-conventions.mdc`。
```

非 RL 项目不需要删除这个 rule 文件；只要它不是 `alwaysApply`，通常不会影响日常任务。

## Agent 项目记忆

这个模板提供三层项目记忆：

- `MEMORY.md`：项目总体记忆，适合记录架构、里程碑、关键踩坑。
- `.cursor/project-context/`：项目上下文，适合放 `overview.md`、`current-plan.md`、`decisions.md`。
- `.cursor/lessons-learned/`：错题本，适合一事一文件记录 bug 的现象、根因、修复和避免方式。

这些文件是给 Agent 快速读取用的，不是长文档。内容尽量短、清楚、可搜索。不要放密钥、token、账号、长聊天记录或隐私信息。

## 全局规则、项目模板和兼容性建议

比较稳妥的做法是“双层结构”：

- 全局层：只放非常稳定、跨项目都适用的偏好，例如使用中文交流、优先解释风险、不要静默 fallback。
- 项目层：放具体技术栈规则，例如 Python 必须用 `uv`、Ruff/Pyright 配置、CI 和 PR 模板。RL Tensor shape 等规则只在 RL 项目中按需启用。

这样做的好处是迁移成本低。以后如果从 Cursor 迁移到 Claude Code，`CLAUDE.md` 仍然能继续提供主要上下文；如果继续使用 Cursor，`.cursor/rules/*.mdc` 可以提供更细粒度的项目规则。

对于新项目模板，这个仓库就是模板源。推荐做法是先运行项目自己的初始化命令，例如 `uv init`、`git init`，再运行 `init-ai` 注入规则。对于已经 clone 下来的项目，先确认是否能接受覆盖同名配置，再运行 `init-ai`。

## 配置说明

主要配置入口如下：

- `.cursor/rules/*.mdc`：Cursor 规则文件。适合拆分成语言、框架、文档、Agent 行为等小规则。
- `.cursor/project-context/`：项目私有上下文。更新模板时会保留已有内容。
- `.cursor/lessons-learned/`：项目错题本。更新模板时会保留已有内容。
- `CLAUDE.md`：跨 Agent 的仓库级说明，适合放稳定、通用的工程规范。
- `.cursorrules`：旧版 Cursor 兼容入口。
- `ruff.toml`：Ruff 代码风格和 lint 配置。
- `pyrightconfig.json`：Pyright 类型检查配置。
- `.pre-commit-config.yaml`：提交前自动检查配置。
- `.github/workflows/ci.yml`：GitHub CI。
- `.github/PULL_REQUEST_TEMPLATE.md`：PR 描述模板。

`inject-ai.sh` 默认在“当前目录”执行注入，所以请先 `cd` 到目标项目根目录再运行。新项目可以直接运行 `init-ai`；已有项目建议先运行 `init-ai --update --dry-run`，确认摘要后再执行 `init-ai --update --apply`。

## 维护本模板仓库（双远端推送）

本仓库同时在 **GitHub**（`origin`）和 **GitLab**（`gitlab`）维护镜像。在 `main` 上提交后，默认应**同时推送到两个远端**，除非你明确只想更新其中一边：

```bash
git push origin main
git push gitlab main
```

一行命令：

```bash
git push origin main && git push gitlab main
```

若让 AI Agent 代为推送，请明确说明 **「同时 push 到 GitHub 和 GitLab」**（或指定 remote 名称）。不要默认只执行一次 `git push`——`main` 可能只跟踪其中一个远端，另一边会落后。

若两边历史已分叉，请先确认以哪一边为准，再对落后的一方使用 `git push --force-with-lease <remote> main`，并先看过 diff。

