# AI Coding Rules

**Language / 语言:** [English](README.md) | 简体中文

本仓库提供可组合的 AI 工程 **pack**：默认 `init-ai` 只注入语言无关的 **core**；其余能力需手动 `init-ai add <pack>`，**没有** profile。

定位：服务 **普通 Python** 与 **DL / GPU** 两条路径。领域框架（如 mjlab 等 RL 模板）用上游仓库，本仓库只插 `core`。

## 快速开始

**使用端**（除唯一编辑端外的机器）：只装一次，不要改安装目录里的文件，也不要在那里 commit。

```bash
curl -fsSL https://raw.githubusercontent.com/huangpenguin/ai-coding-rules/main/install.sh | bash
source ~/.zshrc   # 或 source ~/.bashrc
```

`init-ai` 会先对 `~/.ai-coding-rules` 执行 `git pull --ff-only`，再注入。

在任意项目中使用：

```bash
cd your-project
init-ai
```

**编辑端**（只保留一台）：用普通 git 工作副本改模板，推送到两个已配置的远端。使用端只 pull。

默认只应用语言无关的 `core`：精简的 `AGENTS.md`、引用它的 `CLAUDE.md`、按需触发的 Cursor 规则、项目记忆及可选的 skills 安装脚本。除拉取模板外，不需要 Node.js 或额外联网。

`init-ai --update --apply` 会更新受管理规则；旧规则只有在内容与原模板完全一致时才会被清理，自定义版本保持不动。

**可选 skills：** 在已注入的项目里按需运行 `bash scripts/install-matt-pocock-skills.sh code-review`（或换成需要的 skill 名称）；确实需要全套时才用 `--all`。这需要 Node.js/`npx` 和网络，重跑前先检查已安装 skill 中的本地修改。`init-ai` 不再自动安装或刷新 skills。

## Matt Pocock skills（可选）

来源：[mattpocock/skills](https://github.com/mattpocock/skills)。按项目安装，任务需要时再用；普通修改不必走完整流程。

### 主流程（想法 → 交付）

| Skill | 时机 | 作用 |
|-------|------|------|
| `/setup-matt-pocock-skills` | 需要共享 issue 与领域约定时 | 配置 issue tracker、triage labels、domain docs（`docs/agents/`） |
| `/grill-with-docs` | 现有代码库中的需求不清楚时 | 澄清需求并沉淀共享语言（`CONTEXT.md` / ADR） |
| `/grill-me` | 无代码库 / 非代码计划 | 同上诘问，但**无状态**（不写本地文档） |
| `/to-spec` | grill 结束后、讨论已收敛 | 合成**规格**（业务逻辑；禁止写实现）到 issue tracker |
| `/to-tickets` | 动手写代码前 | 拆成带阻塞边的 tracer-bullet 票据 |
| `/implement` | 每张票单独开（建议清上下文） | 内部走 `/tdd`，收尾 `/code-review` 再提交 |

只选任务需要的步骤；小改动可以直接实施。

### 入口与维护

| Skill | 时机 | 作用 |
|-------|------|------|
| `/ask-matt` | 不知道该用哪个 | 路由到合适的 user-invoked skill |
| `/triage` | 外部进来的 bug/需求（非本仓库 `/to-tickets` 产出） | 按 triage 角色推进到可给 agent 做 |
| `/diagnosing-bugs` | 难复现 / 间歇 / 回归 | 复现 → 最小化 → 假设 → 埋点 → 修复 → 回归测试 |
| `/improve-codebase-architecture` | 明确要审视架构时 | 扫描浅模块 → HTML 报告 → 加深设计 |
| `/wayfinder` | 跨多会话的巨大模糊工作 | 共享调查票地图，路清后再接 `/to-spec` |
| `/tdd` | 只想对某一行为红绿重构 | 独立 TDD 循环 |
| `/code-review` | 按固定基点审分支/PR | Standards + Spec 双轴 |
| `/handoff` | 上下文将满或要新开会话 | 压缩成 markdown 交给下一个 agent |

完整说明见上游 [README](https://github.com/mattpocock/skills/blob/main/README.md)。

## Pack 一览

| Pack | 命令 | 注入内容 | **不包含** |
|------|------|----------|------------|
| **core** | `init-ai` | Agent 规则、项目记忆、可选 skills 安装脚本 | Python、CI、Docker |
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
git push github main && git push gitlab main
```
