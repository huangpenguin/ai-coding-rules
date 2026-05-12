# AI Coding Rules

**Language / 语言:** [English](README.md) | 简体中文

这是一个给 Python / 强化学习（RL）项目使用的 AI 工程化规则模板。它的目标是：把 Cursor、Claude Code、本地代码检查、Git hook 和 CI 尽量统一起来，让 AI 改代码时不需要每次都重复提醒“请用 uv”“请写类型标注”“请遵守 Ruff/Pyright”。

你可以把它理解成一套可复用的项目启动包：先把这个仓库克隆到本地固定位置，之后新建项目或接手旧项目时，运行一个命令就能把规则注入进去。

## 包含内容

- `.cursor/rules/`：Cursor 的项目规则，使用 `.mdc` 文件组织。
- `CLAUDE.md`：给 Claude Code 或其他支持仓库级说明的 Agent 使用。
- `.cursorrules`：兼容旧版 Cursor 规则读取方式。
- `ruff.toml`：Ruff lint / format 配置。
- `pyrightconfig.json`：Pyright 类型检查配置。
- `.pre-commit-config.yaml`：提交前自动检查。
- `.github/`：GitHub PR 模板和 CI 工作流。
- `inject-ai.sh`：把以上文件复制到当前项目的注入脚本。

这套规则默认偏向现代 Python 项目：使用 `uv` 管理环境和依赖，写明确的 Type Hints，优先用 Ruff 和 Pyright，并对 RL 项目强调模块拆分、实验可复现和 Tensor shape 注释。

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

## 使用场景

### 场景一：从零创建新项目

适合你准备新写一个 Python / RL 项目，例如 PPO、DQN、SAC 的实验脚手架。

```bash
mkdir my-new-rl
cd my-new-rl
uv init
git init
init-ai
```

执行后会发生这些事：

- 复制 `.cursor/rules/`、`CLAUDE.md` 和 `.cursorrules`，让 Cursor / Claude Code 读取你的 AI 开发规范。
- 复制 Ruff、Pyright、pre-commit、GitHub CI 和 PR 模板。
- 因为项目里有 `pyproject.toml`，脚本会执行 `uv add --dev ruff pyright pre-commit`。
- 因为项目里有 `.git`，脚本会执行 `uv run pre-commit install`，安装提交前检查。

之后就可以打开 Cursor，直接让 Agent 根据项目规则生成代码，例如：“根据本项目规范，帮我写一个 PPO 训练脚手架。”

### 场景二：接手现代开源项目

适合你克隆了一个比较新的项目，根目录已经有 `pyproject.toml`。

```bash
git clone https://github.com/someone/cool-rl.git
cd cool-rl
init-ai
uv sync
```

这样会把你的 AI 规则和本地检查工具加入项目，同时仍然使用原项目的 `pyproject.toml` 和 `uv` 工作流管理依赖。

注意：`init-ai` 会覆盖同名配置文件。如果这个开源项目已经有自己的 Ruff、Pyright、pre-commit 或 GitHub CI 配置，建议先看一下 `git status`，确认覆盖是否符合你的预期。

### 场景三：接手旧项目

适合导师、课程、论文代码或早期 GitHub 项目，可能只有 `requirements.txt`，没有 `pyproject.toml`。

```bash
git clone https://github.com/old/legacy-rl.git
cd legacy-rl
uv venv
uv pip install -r requirements.txt
init-ai
```

如果脚本没有检测到 `pyproject.toml`，它会跳过 `uv add --dev ruff pyright pre-commit`，避免强行改写旧项目的依赖结构。但它仍然会复制 AI 规则文件和共享配置文件，让 Agent 在阅读和修改旧代码时遵守你的开发习惯。

### 场景四：日常 AI 结对编程

平时写代码、改 bug、做 PR 时，可以按这个节奏来：

```bash
git add .
git commit -m "feat: add value network"
```

如果 pre-commit 报错，例如 Ruff 发现未使用的 import，或者 Pyright 发现类型不匹配，不需要自己一点点猜。把完整报错贴回 Cursor 或 Claude Code，并要求它“根据 pre-commit 报错修复”。因为规则已经在项目里，Agent 会更容易按同一套标准修。

## 全局规则、项目模板和兼容性建议

比较稳妥的做法是“双层结构”：

- 全局层：只放非常稳定、跨项目都适用的偏好，例如使用中文交流、优先解释风险、不要静默 fallback。
- 项目层：放具体技术栈规则，例如 Python 必须用 `uv`、Ruff/Pyright 配置、RL Tensor shape 注释、CI 和 PR 模板。

这样做的好处是迁移成本低。以后如果从 Cursor 迁移到 Claude Code，`CLAUDE.md` 仍然能继续提供主要上下文；如果继续使用 Cursor，`.cursor/rules/*.mdc` 可以提供更细粒度的项目规则。

对于新项目模板，这个仓库就是模板源。推荐做法是先运行项目自己的初始化命令，例如 `uv init`、`git init`，再运行 `init-ai` 注入规则。对于已经 clone 下来的项目，先确认是否能接受覆盖同名配置，再运行 `init-ai`。

## 配置说明

主要配置入口如下：

- `.cursor/rules/*.mdc`：Cursor 规则文件。适合拆分成语言、框架、文档、Agent 行为等小规则。
- `CLAUDE.md`：跨 Agent 的仓库级说明，适合放稳定、通用的工程规范。
- `.cursorrules`：旧版 Cursor 兼容入口。
- `ruff.toml`：Ruff 代码风格和 lint 配置。
- `pyrightconfig.json`：Pyright 类型检查配置。
- `.pre-commit-config.yaml`：提交前自动检查配置。
- `.github/workflows/ci.yml`：GitHub CI。
- `.github/PULL_REQUEST_TEMPLATE.md`：PR 描述模板。

`inject-ai.sh` 默认在“当前目录”执行注入，所以请先 `cd` 到目标项目根目录再运行。它会覆盖同名文件，建议在已有项目里先提交或暂存重要改动。

