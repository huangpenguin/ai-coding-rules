# AI Coding Rules

**Language / 语言:** [English](README.md) | 简体中文

本仓库提供可组合的 AI 工程 **pack**：默认 `init-ai` 只注入语言无关的 **core**；其余能力需手动 `init-ai add <pack>`，**没有** profile。

定位：服务 **普通 Python** 与 **DL / GPU** 两条路径。领域框架（如 mjlab 等 RL 模板）用上游仓库，本仓库只插 `core`。

## 快速开始

新机器上安装一次：

```bash
curl -fsSL https://raw.githubusercontent.com/huangpenguin/ai-coding-rules/main/install.sh | bash
source ~/.zshrc   # 或 source ~/.bashrc
```

在任意项目中使用：

```bash
cd your-project
init-ai
```

默认只应用 `core`：`.cursor/rules/`、`CLAUDE.md`、`AGENTS.md`、`.cursorrules`、`MEMORY.md`、项目上下文目录，并安装 [mattpocock/skills](https://github.com/mattpocock/skills)（需 Node.js/`npx` + 网络）。core **语言无关**，不含 Python/uv 工具链。

每个仓库若还没有 `docs/agents/`，在 agent 里跑一次 `/setup-matt-pocock-skills`。规则要求 agent 在非琐碎代码生成前先用这些 skill 做对齐与设计。

## Pack 一览

| Pack | 命令 | 注入内容 | **不包含** |
|------|------|----------|------------|
| **core** | `init-ai` | Cursor/Claude 规则、项目记忆、Matt Pocock skills 安装 | Python、CI、Docker |
| **python-quality** | `init-ai add python-quality` | Ruff、Pyright、python-uv 规则 | CI、GPU、pre-commit hook |
| **pre-commit-hooks** | `init-ai add pre-commit-hooks` | 可选本地 Git hook（commit Ruff / push Pyright） | CI、GPU（自动带上 python-quality） |
| **ci-quality** | `init-ai add ci-quality` | GitHub/GitLab **quality** CI | GPU train（自动带上 python-quality，不含 pre-commit） |
| **mlops-gpu** | `init-ai add mlops-gpu` | Docker Compose、薄 Dev Container、**train** CI、uv-bootstrap | quality CI、ruff（独立 pack） |

唯一自动依赖：`ci-quality` → `python-quality`；`pre-commit-hooks` → `python-quality`。均**不会**自动安装 Git hook。

建议先预览：

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## 两条主路径

| 路径 | 步骤 |
|------|------|
| **普通 Python** | `init-ai` → `add python-quality` →（可选）`pre-commit-hooks` / `ci-quality` |
| **DL / GPU** | `init-ai` → `add mlops-gpu`；需要 lint/CI 时再加 `python-quality` / `ci-quality` |

其他常见场景：

| 场景 | 步骤 |
|------|------|
| Vue / 前端 / 文档 | 仅 `init-ai` |
| 外部 RL（如 mjlab） | 仅 `init-ai`（用上游训练栈；不要默认加 `mlops-gpu`） |
| Legacy GPU（如 BasicSR） | `init-ai` → `add mlops-gpu` |

**Legacy GPU 提示：** `docker compose run --rm train uv run python ...`（宿主机禁止 ML）。细节见 inject 后 `docs/packs/mlops-gpu.zh-CN.md`。

## 三环境分工

| 环境 | 装什么 | 用什么 |
|------|--------|--------|
| **宿主机**（可选） | 仅 dev 工具，无 torch | `.venv/bin/ruff` / `.venv/bin/pyright`；hook 见 `pre-commit-hooks` pack |
| **Docker Compose / IDE** | 容器内 GPU + `.venv` | `docker compose run --rm train uv run python ...` 或 Reopen in Container |
| **CI train** | runtime + dev | mlops-gpu 的 `train.yml` |
| **CI quality** | dev（+ runtime 若 lock 含） | ci-quality job；默认 manual + 不阻塞 |

宿主机上对 GPU 项目 **不要用** `uv run`（会隐式 sync 全量依赖含 torch）。

## 合并 GitLab CI（quality + train）

`ci-quality` 与 `mlops-gpu` 各自 inject **仅含本 pack job** 的根 `.gitlab-ci.yml`。若 **两个都加**，后 inject 的会覆盖前者——需手动合并：

```yaml
stages:
  - quality
  - deploy

variables:
  FF_USE_FASTZIP: "true"
  UV_LINK_MODE: copy
  QUALITY_CI_BLOCKING: "false"   # true = 严格 quality 门禁

include:
  - local: .gitlab/ci/quality.yml
  - local: .gitlab/ci/train.yml
```

## GPU 快速落地

`init-ai add mlops-gpu --apply` 后，本地与 CI 使用同一镜像栈 `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`。操作细节见 inject 后的 **`docs/packs/mlops-gpu.zh-CN.md`**。

## 文档入口

- [文档索引](docs/README.md)
- [BasicSR 第一阶段微调](docs/use-cases/basicsr-finetune.zh-CN.md)

## 仓库结构

本仓库是 **模板分发器**，不是普通应用项目。

| 路径 | 作用 |
|------|------|
| `templates/<pack>/` | inject 唯一来源 |
| `inject-ai.sh` | inject 入口 |
| 根目录 `pyproject.toml`、`.gitlab-ci.yml` | **本仓库自身 CI**，不会 inject |

模板质量检查：

```bash
bash scripts/check-template-clean.sh
```

## 维护本模板仓库

```bash
git push origin main && git push gitlab main
```
