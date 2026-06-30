# Python Quality Pack

`python-quality` 添加 **Python 专用** 本地/CI 质量工具配置与 Cursor 规则（Ruff、Pyright）。

**警告：仅用于 Python 项目。** 会对非 Python 仓库执行 `uv init`、`uv add --dev ruff pyright`。Vue / 前端 / 文档仓库请只用 `init-ai`（core），不要运行本 pack。

**独立 pack**：不含 pre-commit Git hook、不含 `ci-quality`、不含 `mlops-gpu`。需要本地 hook 时请 `init-ai add pre-commit-hooks`；需要 CI 时请 `init-ai add ci-quality`。

包含：

- Cursor rules: `python-uv.mdc`、`bilingual-comments.mdc`
- `ruff.toml`
- `pyrightconfig.json`（CI 与手动检查用 strict）
- `.gitignore`
- 可选 preserve：`ruff.legacy-excludes.snippet.toml`、`pyrightconfig.legacy-excludes.snippet.json`

命令：

```bash
init-ai add python-quality --dry-run
init-ai add python-quality --apply
```

## 三环境分工

| 环境 | 装什么 | 用什么 |
|------|--------|--------|
| **宿主机**（可选） | 仅 dev 工具（ruff / pyright） | `.venv/bin/ruff`、`.venv/bin/pyright`（勿 `uv run` on GPU 项目） |
| **Docker Compose** | runtime + dev in container | `docker compose run --rm train ...`（mlops-gpu pack） |
| **CI quality** | dev（+ runtime 若 lock 含） | `ci-quality` pack 的 GitLab/GitHub job |
| **CI train** | runtime + dev | `mlops-gpu` pack 的 `train.yml` |

**宿主机禁止**（GPU 项目完整迁移后）：

- `uv sync --dev` — 会装 torch 等 runtime
- `uv run ...` — 会隐式 sync 全量依赖

## 本地 Git hooks（可选，另加 pack）

本 pack **不包含** pre-commit。需要 commit/push hook 时：

```bash
init-ai add pre-commit-hooks --apply
bash scripts/setup-local-hooks.sh
```

## 依赖与环境文件

- 若目标项目**已有** `pyproject.toml`：执行 `uv add --dev ruff pyright`（不自动 sync）。
- 若目标项目**没有** `pyproject.toml`：先用 `uv init` 生成最小 `pyproject.toml`，再安装上述 dev 依赖。
- 若只有 `requirements.txt` / `setup.py`：这些文件**不会被修改**。
- **半迁移状态**（空 `dependencies` + `requirements.txt`）：宿主机勿 `uv sync --dev`；runtime 由 Docker Compose 或 CI 的 `uv-bootstrap.sh` 处理。

## Legacy 老代码

老目录难通过 ruff 时，可合并 preserve 里的 exclude snippet，或**不加**本 pack。

## 与其他 pack 组合

- 要 CI lint：`init-ai add ci-quality --apply`（会自动带上本 pack）
- 要本地 Git hook：`init-ai add pre-commit-hooks --apply`
- 要 GPU 环境：`init-ai add mlops-gpu --apply`（不含本 pack；需要时再 add）
