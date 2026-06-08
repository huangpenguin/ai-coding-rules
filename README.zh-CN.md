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
init-ai add ci-quality           # GitHub Actions + GitLab quality CI
init-ai add mlops-gpu            # Docker、devcontainer、GitLab GPU Runner、smoke test
init-ai profile research-gpu     # core + python-quality + ci-quality + mlops-gpu
```

建议先预览：

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## 常见场景

- **BasicSR 第一阶段微调 / legacy 研究仓库**：只运行 `init-ai`，先不要引入 Docker/CI。
- **现代 Python 项目**：先 `init-ai`，再 `init-ai add python-quality`。
- **需要 GitHub/GitLab 质量检查**：添加 `ci-quality`。
- **需要实验室 GPU 服务器训练**：添加 `mlops-gpu`，或直接使用 `profile research-gpu`。

## 文档入口

- [文档索引](docs/README.md)
- [Core pack](docs/packs/core.zh-CN.md)
- [Python quality pack](docs/packs/python-quality.zh-CN.md)
- [CI quality pack](docs/packs/ci-quality.zh-CN.md)
- [MLOps GPU pack](docs/packs/mlops-gpu.zh-CN.md)
- [Docker quickstart](docs/docker/quickstart.zh-CN.md)
- [BasicSR 第一阶段微调](docs/use-cases/basicsr-finetune.zh-CN.md)

## 维护本模板仓库

本仓库同时在 **GitHub**（`origin`）和 **GitLab**（`gitlab`）维护镜像。在 `main` 上提交后，默认同时推送到两个远端：

```bash
git push origin main && git push gitlab main
```
