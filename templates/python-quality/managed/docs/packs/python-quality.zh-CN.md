# Python Quality Pack

`python-quality` 添加 **Python 专用** 本地质量检查配置与 Cursor 规则。

**警告：仅用于 Python 项目。** 会对非 Python 仓库执行 `uv init`、`uv add --dev ...`。Vue / 前端 / 文档仓库请只用 `init-ai`（core），不要运行本 pack。

**独立 pack**：不会自动带上 `ci-quality` 或 `mlops-gpu`；需要 CI 或 GPU 时请分别 `init-ai add ...`。

包含：

- Cursor rules: `python-uv.mdc`、`bilingual-comments.mdc`
- `ruff.toml`
- `pyrightconfig.json`
- `pyrightconfig.pre-push.json`（pre-push hook 用 `basic` 模式；CI 仍用 strict）
- `.pre-commit-config.yaml`
- `scripts/setup-local-hooks.sh`（宿主机可选 hook，不装 torch）
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
| **宿主机**（可选） | 仅 dev 工具（ruff / pyright / pre-commit） | `bash scripts/setup-local-hooks.sh`，之后用 `.venv/bin/pre-commit` |
| **Dev Container** | runtime + dev | `scripts/uv-bootstrap.sh`（mlops-gpu pack） |
| **CI quality** | dev（+ runtime 若 lock 含） | `ci-quality` pack 的 GitLab/GitHub job |
| **CI train** | runtime + dev | `mlops-gpu` pack 的 `train.yml` |

**宿主机禁止**（GPU 项目完整迁移后）：

- `uv sync --dev` — 会装 torch 等 runtime
- `uv run pre-commit ...` — `uv run` 会隐式 sync 全量依赖

## Git hooks（可选，不自动安装）

`init-ai add python-quality` **不会**自动 `pre-commit install`。需要本地 hook 时：

```bash
bash scripts/setup-local-hooks.sh
```

| 阶段 | 工具 | 严格度 |
|------|------|--------|
| `git commit` | Ruff lint + format | 自动修复 |
| `git push` | Pyright | `basic`（见 `pyrightconfig.pre-push.json`） |
| CI | Ruff + Pyright | `strict`（见 `pyrightconfig.json`） |

不需要 hook 时：跳过 `setup-local-hooks.sh`，直接 `git commit` / `git push`。

## 依赖与环境文件

- 若目标项目**已有** `pyproject.toml`：执行 `uv add --dev ruff pyright pre-commit`（写入 dev 组，不自动 sync / 不装 hook）。
- 若目标项目**没有** `pyproject.toml`：先用 `uv init` 生成最小 `pyproject.toml`，再安装上述 dev 依赖。
- 若只有 `requirements.txt` / `setup.py`：这些文件**不会被修改**。
- **半迁移状态**（空 `dependencies` + `requirements.txt`）：宿主机 `uv sync --dev` 只装 dev 工具；runtime 由 Dev Container / CI 的 `uv-bootstrap.sh` 处理。
- 完整迁移：写入 `[project].dependencies`，GPU 项目合并 `pyproject-uv-pytorch.snippet.toml`，`uv lock`。

## Legacy 老代码

老目录难通过 ruff 时，可合并 preserve 里的 exclude snippet，或**不加**本 pack / 不跑 `setup-local-hooks.sh`。

## 已有项目更新

```bash
init-ai add python-quality --update --apply
bash scripts/setup-local-hooks.sh   # 可选
```

## 与其他 pack 组合

- 要 CI lint：`init-ai add ci-quality --apply`（会自动带上本 pack）
- 要 GPU 环境：`init-ai add mlops-gpu --apply`（**不**含本 pack；需要时再 add python-quality）
- 同时有 quality + train CI：见根 README「Combine GitLab CI」手动合并 `.gitlab-ci.yml`
