# AI Coding Rules

**Language / 语言:** [English](README.md) | 简体中文

这是一个给 Python / AI 项目使用的工程化模板仓库。现在模板按 **pack** 拆分：默认 `init-ai` 只注入核心 Cursor / Claude 规则和项目记忆；Python 质量检查、GitHub/GitLab CI、Docker、GPU Runner 训练和未来的 MLOps 功能都需要显式启用。

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

默认只应用 `core` pack：`.cursor/rules/`、`CLAUDE.md`、`.cursorrules`、`MEMORY.md` 和项目上下文目录。

## 可选 Pack

```bash
init-ai add python-quality       # Ruff、Pyright、pre-commit、.gitignore
init-ai add ci-quality           # GitHub/GitLab 质量 CI（自动带上 python-quality）
init-ai add mlops-gpu            # Docker、devcontainer、GPU Runner（自动带上 ci-quality）
init-ai profile research-gpu     # core + mlops-gpu（自动带上 python-quality 与 ci-quality）
```

Pack 依赖会自动展开：`ci-quality` → `python-quality`；`mlops-gpu` → `ci-quality` → `python-quality`。若目标项目没有 `pyproject.toml`，会先 `uv init` 脚手架再安装 dev 工具；已有的 `requirements.txt` / `setup.py` 不会被修改。

建议先预览：

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## 常见场景

- **BasicSR 第一阶段微调 / legacy 研究仓库**：只运行 `init-ai`，先不要引入 Docker/CI。
- **现代 Python 项目**：先 `init-ai`，再 `init-ai add python-quality`。
- **需要 GitHub/GitLab 质量检查**：添加 `ci-quality`（会自动带上 python-quality 与 CI 所需的 dev 依赖）。
- **需要实验室 GPU 服务器训练**：添加 `mlops-gpu`，或直接使用 `profile research-gpu`。

## 文档入口

- [文档索引](docs/README.md) — 指向 `templates/` 下的 canonical pack 文档
- [BasicSR 第一阶段微调](docs/use-cases/basicsr-finetune.zh-CN.md) — 仅本模板仓库说明，不会 inject

## 仓库结构

本仓库是 **模板分发器**，不是普通应用项目。

| 路径 | 作用 |
|------|------|
| `inject-ai.sh`、`install.sh` | 安装与 inject 入口 |
| `templates/<pack>/` | **inject 唯一来源** — 改 pack 内容在这里 |
| `docs/` | 索引 + 仅留在本仓库的指南 |
| `.cursorrules`、`CLAUDE.md`、`.cursor/` | 维护者在本仓库的 dogfooding |
| `pyproject.toml`、`ruff.toml`、`.gitlab-ci.yml`、`.github/` | **本仓库自身 CI**，不会 inject |

Docker、devcontainer、GPU 训练与 pack 文档应放在 `templates/mlops-gpu/`，不要放在仓库根目录。

## 维护本模板仓库

本仓库在 **GitHub** 与 **GitLab** 双端镜像。一次性配置 remotes：

```bash
git remote add origin git@github.com:huangpenguin/ai-coding-rules.git   # 若已有 origin 则跳过
git remote add gitlab git@gitlab.com:jil_atr/ai-coding-rules.git        # GitLab 当前 canonical 路径
git fetch --all
```

`main` 提交后推送到两边：

```bash
git push origin main && git push gitlab main
```

本维护者 checkout 上 `main` 默认跟踪 `gitlab/main`；`git fetch --all` 后可从任一侧 pull。
