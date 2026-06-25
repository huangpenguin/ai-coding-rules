# Python Quality Pack

`python-quality` 添加 **Python 专用** 本地质量检查配置与 Cursor 规则。

**警告：仅用于 Python 项目。** 会对非 Python 仓库执行 `uv init`、`uv add --dev ...` 并创建 `.venv`。Vue / 前端 / 文档仓库请只用 `init-ai`（core），不要运行本 pack。

包含：

- Cursor rules: `python-uv.mdc`、`bilingual-comments.mdc`
- `ruff.toml`
- `pyrightconfig.json`
- `pyrightconfig.pre-push.json`（pre-push hook 用 `basic` 模式；CI 仍用 strict）
- `.pre-commit-config.yaml`
- `.gitignore`

命令：

```bash
init-ai add python-quality --dry-run
init-ai add python-quality --apply
```

## Git hooks

| 阶段 | 工具 | 严格度 |
|------|------|--------|
| `git commit` | Ruff lint + format | 自动修复 |
| `git push` | Pyright | `basic`（见 `pyrightconfig.pre-push.json`） |
| CI | Ruff + Pyright | `strict`（见 `pyrightconfig.json`） |

## 依赖与环境文件

- 若目标项目**已有** `pyproject.toml`：执行 `uv add --dev ruff pyright pre-commit`，并在有 `.git` 时安装 pre-commit 与 pre-push hook。
- 若目标项目**没有** `pyproject.toml`：先用 `uv init` 生成最小 `pyproject.toml`，再安装上述 dev 依赖。
- 若只有 `requirements.txt` / `setup.py`：这些文件**不会被修改**；运行时依赖仍从 `requirements.txt` 安装。
- **半迁移状态**（inject 后有 `pyproject.toml` 但 `dependencies = []`，同时保留 `requirements.txt`）：`uv sync --dev` **只装 dev 工具**，不会装 torch 等运行时包。若已启用 `mlops-gpu`，Rebuild devcontainer 或 GitLab GPU job 会跑 `scripts/uv-bootstrap.sh` 补齐；否则需手动按 requirements 安装。
- 完整迁移：把依赖写入 `pyproject.toml`，GPU 项目合并 `pyproject-uv-pytorch.snippet.toml`（cu124 index），`uv lock`，提交 `uv.lock`。

`ci-quality` 与 `mlops-gpu` 会自动带上本 pack，无需单独再执行一次。

## 已有项目更新

在目标项目根目录执行：

```bash
init-ai add python-quality --update --apply
uv sync --dev
uv run pre-commit install
uv run pre-commit install --hook-type pre-push
```

若未安装 `init-ai`，可手动合并 `.pre-commit-config.yaml` 中 `repo: local` 的 `pyright` hook 段，并复制 `pyrightconfig.pre-push.json`，再运行上述 `uv sync` 与两条 `pre-commit install` 命令。
